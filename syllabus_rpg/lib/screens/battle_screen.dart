import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the Game Engine
    final game = Provider.of<GameProvider>(context);

    // 1. CHECK GAME STATE (Win/Loss)
    if (game.isGameOver) return _buildEndScreen(context, false, game);
    if (game.isVictory) return _buildEndScreen(context, true, game);
    if (game.currentQuestion == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final q = game.currentQuestion!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildHUD(game), // The Health & XP Bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. ENEMY VISUALIZATION
            Expanded(
              flex: 2,
              child: _buildEnemyStage(q.difficulty),
            ),

            const SizedBox(height: 16),

            // 3. QUESTION CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                q.text,
                style: GoogleFonts.lato(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // 4. BATTLE ACTIONS (Options)
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: List.generate(q.options.length, (index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      side: BorderSide(
                          color: _getDifficultyColor(q.difficulty),
                          width: 1
                      ),
                    ),
                    onPressed: () {
                      bool correct = game.submitAnswer(index);
                      _showFeedback(context, correct);
                    },
                    child: Text(
                      q.options[index],
                      style: GoogleFonts.lato(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHUD(GameProvider game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Health Hearts
        Row(
          children: List.generate(3, (index) {
            return Icon(
              index < game.hp ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFFE94560),
            );
          }),
        ),
        // XP Score
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700)),
            const SizedBox(width: 4),
            Text(
              "${game.xp} XP",
              style: GoogleFonts.cinzel(color: const Color(0xFFFFD700)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEnemyStage(Difficulty difficulty) {
    IconData enemyIcon;
    Color color;
    String label;
    double size;

    switch (difficulty) {
      case Difficulty.troll:
        enemyIcon = Icons.bug_report; // Looks like a little monster
        color = Colors.green;
        label = "Wild Troll (Lvl 1)";
        size = 80;
        break;
      case Difficulty.guard:
        enemyIcon = Icons.security;
        color = Colors.blue;
        label = "Gate Guard (Lvl 5)";
        size = 100;
        break;
      case Difficulty.knight:
        enemyIcon = Icons.shield;
        color = Colors.orange;
        label = "Dark Knight (Lvl 10)";
        size = 120;
        break;
      case Difficulty.boss:
        enemyIcon = Icons.local_fire_department;
        color = const Color(0xFFE94560);
        label = "FINAL BOSS";
        size = 160;
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(enemyIcon, size: size, color: color),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.cinzel(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildEndScreen(BuildContext context, bool victory, GameProvider game) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              victory ? Icons.emoji_events : Icons.heart_broken,
              size: 100,
              color: victory ? const Color(0xFFFFD700) : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              victory ? "VICTORY!" : "YOU DIED",
              style: GoogleFonts.cinzel(
                fontSize: 40,
                color: victory ? const Color(0xFFFFD700) : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              victory ? "Total XP: ${game.xp}" : "Try to study harder...",
              style: GoogleFonts.lato(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to Home
              },
              child: const Text("Return to Camp"),
            )
          ],
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context, bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 500),
        backgroundColor: correct ? Colors.green : Colors.red,
        content: Text(
          correct ? "Hit!" : "Miss!",
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty d) {
    switch(d) {
      case Difficulty.troll: return Colors.green;
      case Difficulty.guard: return Colors.blue;
      case Difficulty.knight: return Colors.orange;
      case Difficulty.boss: return const Color(0xFFE94560);
    }
  }
}