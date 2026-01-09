import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
  // 1. GAME STATS
  int _hp = 3; // 3 Hearts
  int _xp = 0;
  bool _isLoading = false;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  // Getters for UI
  int get hp => _hp;
  int get xp => _xp;
  bool get isLoading => _isLoading;
  List<Question> get questions => _questions;
  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  bool get isGameOver => _hp <= 0;
  bool get isVictory => _currentQuestionIndex >= _questions.length && _hp > 0;

  // 2. GEMINI CONFIGURATION
  // REPLACE WITH YOUR API KEY
  static const String _apiKey = 'AIzaSyAz9YLYVc4h6Wa6OhYKDzSFmr-0A4LqFpI';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash', // Flash is faster for JSON tasks
    apiKey: _apiKey,
  );

  // 3. THE "GENERATE QUEST" FUNCTION
  Future<void> generateQuestFromText(String documentText) async {
    _isLoading = true;
    notifyListeners();

    try {
      // The Prompt: Forces JSON output strictly
      final prompt = '''
        You are a Game Master API. Analyze the following text and generate a quiz RPG JSON.
        The JSON must strictly follow this structure with NO markdown formatting:
        {
          "trolls": [3 questions (easy fact retrieval)],
          "guards": [3 questions (moderate comparison)],
          "knights": [3 questions (hard logic)],
          "final_boss": {1 question (very hard synthesis)}
        }
        
        Each question object must look like:
        {"q": "question text", "opts": ["A", "B", "C", "D"], "a": 0} 
        (where 'a' is the index of the correct option 0-3).

        TEXT TO ANALYZE:
        $documentText
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) throw Exception("AI returned empty text");

      // Clean the output (Gemini sometimes adds ```json ... ```)
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '');

      _parseGameData(cleanJson);

    } catch (e) {
      print("Error summoning monsters: $e");
      // Handle error (maybe add a dummy question for testing)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. PARSING LOGIC (JSON -> Dart Objects)
  void _parseGameData(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    List<Question> newQuest = [];

    // Helper to map difficulty
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

    // Add Trolls (Easy - 10 XP)
    if (data['trolls'] != null) addQuestions(data['trolls'], Difficulty.troll, 10);

    // Add Guards (Medium - 20 XP)
    if (data['guards'] != null) addQuestions(data['guards'], Difficulty.guard, 20);

    // Add Knights (Hard - 50 XP)
    if (data['knights'] != null) addQuestions(data['knights'], Difficulty.knight, 50);

    // Add Final Boss (Expert - 500 XP)
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
    _hp = 3; // Reset HP
    _xp = 0; // Reset XP
  }

  // 5. BATTLE LOGIC
  // Returns true if correct, false if wrong
  bool submitAnswer(int selectedIndex) {
    if (currentQuestion == null) return false;

    bool isCorrect = selectedIndex == currentQuestion!.correctIndex;

    if (isCorrect) {
      _xp += currentQuestion!.xpReward;
      // Move to next enemy
      _currentQuestionIndex++;
    } else {
      // Take Damage
      _hp -= 1;
    }

    notifyListeners();
    return isCorrect;
  }

  void restartGame() {
    _currentQuestionIndex = 0;
    _hp = 3;
    _xp = 0;
    notifyListeners();
  }
}