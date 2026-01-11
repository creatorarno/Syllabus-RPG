import 'dart:convert';
import 'dart:typed_data' as td;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- DATA MODELS ---

enum Difficulty { troll, guard, knight, boss }

class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final Difficulty difficulty;
  final int xpReward;

  Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.xpReward,
  });
}

// --- PROVIDER LOGIC ---

class GameProvider extends ChangeNotifier {
  // ==========================================
  // 1. STATE VARIABLES
  // ==========================================

  // User Profile (From Database)
  String _username = "Hero";
  int _totalUserXp = 0;

  // Game Session (Current Match)
  int _hp = 3;
  int _sessionXp = 0;
  int _correctAnswersCount = 0;
  bool _isLoading = false;

  // NEW: Safety Lock to prevent duplicate saves
  bool _isMatchSaved = false;

  // Quest Data
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  // ==========================================
  // 2. GETTERS
  // ==========================================

  String get username => _username;
  int get totalUserXp => _totalUserXp;
  int get hp => _hp;
  int get xp => _sessionXp;
  int get correctAnswersCount => _correctAnswersCount;
  bool get isLoading => _isLoading;
  List<Question> get questions => _questions;

  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  bool get isGameOver => _hp <= 0;
  bool get isVictory => _currentQuestionIndex >= _questions.length && _hp > 0;

  // ==========================================
  // 3. AI CONFIGURATION
  // ==========================================

  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  // ==========================================
  // 4. SUPABASE ACTIONS
  // ==========================================

  // Load User Profile
  Future<void> loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('username, xp')
          .eq('id', user.id)
          .single();

      _username = data['username'] as String;
      _totalUserXp = (data['xp'] as num).toInt();
      notifyListeners();
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  // Records match result
  Future<void> recordMatchResult() async {
    // 1. SAFETY CHECK: If already saved, stop immediately.
    if (_isMatchSaved) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      _isMatchSaved = true; // Lock it
      String result = isVictory ? "Victory" : "Defeat";

      print("--- STARTING SAVE ---"); // Debug Print

      // 2. OPTIMISTIC UPDATE: Update local app state immediately so user sees points
      if (_sessionXp > 0) {
        _totalUserXp += _sessionXp;
        notifyListeners(); // HUD updates instantly
      }

      // 3. DATABASE: Insert Match History
      await Supabase.instance.client.from('matches').insert({
        'user_id': user.id,
        'result': result,
        'xp_earned': _sessionXp,
        'questions_answered': _correctAnswersCount,
        'total_questions': _questions.length,
      });

      // 4. DATABASE: Update Profile XP
      if (_sessionXp > 0) {
        await Supabase.instance.client
            .from('profiles')
            .update({'xp': _totalUserXp}) // Use the new total
            .eq('id', user.id);
      }

      print("--- SAVE SUCCESSFUL ---");

    } catch (e) {
      print("CRITICAL ERROR RECORDING MATCH: $e");
      // Optional: Revert local XP if DB fails, or just keep it for this session
      _isMatchSaved = false; // Unlock so we can try again if needed
    }
  }

  // ==========================================
  // 5. GAMEPLAY LOGIC
  // ==========================================

  Future<void> generateQuestFromPdf(td.Uint8List pdfBytes) async {
    _isLoading = true;
    notifyListeners();

    try {
      final promptText = '''
        You are a Game Master API. Analyze the attached PDF content density.
        Generate a quiz RPG JSON. 
        
        CRITICAL RULE: The number of questions must depend on the length of the content.
        - If the content is short/simple: Generate exactly 10 questions.
        - If the content is long/complex: Generate up to 20 questions.
        
        Distribution:
        - "trolls": ~30% (Easy fact retrieval)
        - "guards": ~30% (Moderate comparison)
        - "knights": ~30% (Hard logic)
        - "final_boss": {1 question (Expert synthesis)}

        Strict JSON Structure (No Markdown, pure JSON):
        {
          "trolls": [{"q": "...", "opts": ["A","B","C","D"], "a": 0}, ...],
          "guards": [...],
          "knights": [...],
          "final_boss": {"q": "...", "opts": [...], "a": 0}
        }
      ''';

      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart('application/pdf', pdfBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      if (response.text == null) throw Exception("AI returned empty text");

      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      _parseGameData(cleanJson);

    } catch (e) {
      print("Error summoning monsters: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseGameData(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      List<Question> newQuest = [];

      void addQuestions(List<dynamic> list, Difficulty diff, int xp) {
        for (var q in list) {
          newQuest.add(Question(
            text: q['q'],
            options: List<String>.from(q['opts']),
            correctIndex: q['a'],
            difficulty: diff,
            xpReward: xp,
          ));
        }
      }

      if (data['trolls'] != null) addQuestions(data['trolls'], Difficulty.troll, 10);
      if (data['guards'] != null) addQuestions(data['guards'], Difficulty.guard, 20);
      if (data['knights'] != null) addQuestions(data['knights'], Difficulty.knight, 50);

      if (data['final_boss'] != null) {
        if (data['final_boss'] is List) {
          addQuestions(data['final_boss'], Difficulty.boss, 500);
        } else {
          var boss = data['final_boss'];
          newQuest.add(Question(
            text: boss['q'],
            options: List<String>.from(boss['opts']),
            correctIndex: boss['a'],
            difficulty: Difficulty.boss,
            xpReward: 500,
          ));
        }
      }

      _questions = newQuest;

      // Reset Session State
      _currentQuestionIndex = 0;
      _correctAnswersCount = 0;
      _hp = 3;
      _sessionXp = 0;
      _isMatchSaved = false; // <--- RESET LOCK FOR NEW GAME

    } catch (e) {
      print("JSON Parsing Error: $e");
    }
  }

  bool submitAnswer(int selectedIndex) {
    if (currentQuestion == null) return false;

    bool isCorrect = selectedIndex == currentQuestion!.correctIndex;

    if (isCorrect) {
      _sessionXp += currentQuestion!.xpReward;
      _correctAnswersCount++;
      _currentQuestionIndex++;
    } else {
      _hp -= 1;
    }

    notifyListeners();
    return isCorrect;
  }

  void restartGame() {
    _currentQuestionIndex = 0;
    _correctAnswersCount = 0;
    _hp = 3;
    _sessionXp = 0;
    _isMatchSaved = false; // Reset lock
    notifyListeners();
  }
}