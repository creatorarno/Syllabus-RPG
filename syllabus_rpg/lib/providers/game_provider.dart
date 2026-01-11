import 'dart:convert';
import 'dart:typed_data' as td;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// ... (Keep Enum Difficulty and Class Question as they are) ...
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

class GameProvider extends ChangeNotifier {
  // --- USER PROFILE DATA ---
  String _username = "Hero";
  int _totalUserXp = 0; // The stored XP from Database

  // --- GAME SESSION DATA ---
  int _hp = 3;
  int _sessionXp = 0; // XP earned in THIS specific battle
  bool _isLoading = false;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  // Getters
  String get username => _username;
  int get totalUserXp => _totalUserXp;
  int get hp => _hp;
  int get xp => _sessionXp; // Current session XP
  bool get isLoading => _isLoading;
  List<Question> get questions => _questions;

  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  bool get isGameOver => _hp <= 0;
  bool get isVictory => _currentQuestionIndex >= _questions.length && _hp > 0;

  // AI Model
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  // ==========================================
  // 1. SUPABASE INTEGRATION
  // ==========================================

  // Call this when HomeScreen loads
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

  // Call this when Battle Ends (Victory or Defeat)
  Future<void> saveScoreToDatabase() async {
    if (_sessionXp == 0) return; // No need to save 0

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Update local total
      _totalUserXp += _sessionXp;

      // 2. Push to Supabase
      // Note: In a real app, use an RPC function to increment atomically.
      // For hackathon, direct update is fine.
      await Supabase.instance.client
          .from('profiles')
          .update({'xp': _totalUserXp})
          .eq('id', user.id);

      // Reset session XP so we don't double save
      _sessionXp = 0;
      notifyListeners();
    } catch (e) {
      print("Error saving score: $e");
    }
  }

  // ==========================================
  // 2. GAME LOGIC
  // ==========================================

  Future<void> generateQuestFromPdf(td.Uint8List pdfBytes) async {
    _isLoading = true;
    notifyListeners();

    try {
      final promptText = '''
        You are a Game Master API. Analyze the attached PDF document and generate a quiz RPG JSON.
        The JSON must strictly follow this structure with NO markdown formatting:
        {
          "trolls": [3 questions (easy fact retrieval)],
          "guards": [3 questions (moderate comparison)],
          "knights": [3 questions (hard logic)],
          "final_boss": {1 question (very hard synthesis)}
        }
        Each question object must look like:
        {"q": "question text", "opts": ["A", "B", "C", "D"], "a": 0} 
      ''';

      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart('application/pdf', pdfBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      if (response.text == null) throw Exception("AI returned empty text");

      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '');
      _parseGameData(cleanJson);

    } catch (e) {
      print("Error summoning monsters: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseGameData(String jsonString) {
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
      var boss = data['final_boss'];
      newQuest.add(Question(
        text: boss['q'],
        options: List<String>.from(boss['opts']),
        correctIndex: boss['a'],
        difficulty: Difficulty.boss,
        xpReward: 500,
      ));
    }

    _questions = newQuest;
    _currentQuestionIndex = 0;
    _hp = 3;
    _sessionXp = 0; // Reset SESSION xp, not total user XP
  }

  bool submitAnswer(int selectedIndex) {
    if (currentQuestion == null) return false;

    bool isCorrect = selectedIndex == currentQuestion!.correctIndex;

    if (isCorrect) {
      _sessionXp += currentQuestion!.xpReward;
      _currentQuestionIndex++;
    } else {
      _hp -= 1;
    }

    notifyListeners();
    return isCorrect;
  }

  void restartGame() {
    _currentQuestionIndex = 0;
    _hp = 3;
    _sessionXp = 0;
    notifyListeners();
  }
}