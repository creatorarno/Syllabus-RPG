import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

// --- PIXEL THEME CONSTANTS (Matching Home Screen) ---
const Color kPixelDarkBlue = Color(0xFF141020);
const Color kPixelCardBg = Color(0xFF2A2636);
const Color kPixelStoneGray = Color(0xFF4E4A4E);
const Color kPixelGold = Color(0xFFFFD541);
const Color kPixelRed = Color(0xFFD53C3C);
const Color kPixelGreen = Color(0xFF5DE76F);
const Color kPixelLightText = Color(0xFFEFEFEF);

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  // Helper to scale sizes for responsiveness
  double _scale(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);
    return value * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    // Define Pixel Fonts
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText);
    final bodyFont = GoogleFonts.vt323(color: kPixelLightText);

    // 1. CHECK GAME STATE
    if (game.isGameOver) return _buildPixelEndScreen(context, false, game, headerFont, bodyFont);
    if (game.isVictory) return _buildPixelEndScreen(context, true, game, headerFont, bodyFont);
    if (game.currentQuestion == null) {
      return const Scaffold(
          backgroundColor: kPixelDarkBlue,
          body: Center(child: CircularProgressIndicator(color: kPixelGold)));
    }

    final q = game.currentQuestion!;
    final difficultyColor = _getDifficultyColor(q.difficulty);

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.all(_scale(context, 16.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TOP BAR (Back & HUD) ---
                    _buildTopBar(context, game, headerFont),

                    const Spacer(flex: 1),

                    // --- 2. ENEMY STAGE ---
                    _buildPixelEnemyStage(context, q.difficulty, headerFont),

                    const Spacer(flex: 1),

                    // --- 3. QUESTION "DIALOGUE BOX" ---
                    _buildPixelQuestionBox(context, q.text, bodyFont),

                    SizedBox(height: _scale(context, 20)),

                    // --- 4. BATTLE ACTIONS (Options Grid) ---
                    Expanded(
                      flex: 4,
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: _scale(context, 12),
                        mainAxisSpacing: _scale(context, 12),
                        children: List.generate(q.options.length, (index) {
                          return _buildPixelAnswerButton(
                            context,
                            text: q.options[index],
                            color: difficultyColor,
                            font: bodyFont,
                            onTap: () {
                              bool correct = game.submitAnswer(index);
                              _showPixelFeedback(context, correct);
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  // --- PIXEL WIDGET HELPERS ---

  Widget _buildTopBar(BuildContext context, GameProvider game, TextStyle headerFont) {
    return Row(
      children: [
        // Pixel Back Button
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(_scale(context, 8)),
            decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
            child: Icon(Icons.arrow_back, color: kPixelLightText, size: _scale(context, 20)),
          ),
        ),
        SizedBox(width: _scale(context, 16)),
        // The HUD
        Expanded(child: _buildPixelHUD(context, game, headerFont)),
      ],
    );
  }

  Widget _buildPixelHUD(BuildContext context, GameProvider game, TextStyle headerFont) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _scale(context, 12), vertical: _scale(context, 8)),
      decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pixel Hearts
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  index < game.hp ? Icons.favorite : Icons.favorite_border,
                  color: kPixelRed,
                  size: _scale(context, 24),
                ),
              );
            }),
          ),
          // Pixel XP
          Row(
            children: [
              Icon(Icons.monetization_on, color: kPixelGold, size: _scale(context, 20)),
              SizedBox(width: _scale(context, 8)),
              Text(
                "${game.xp}",
                style: headerFont.copyWith(color: kPixelGold, fontSize: _scale(context, 16)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPixelEnemyStage(BuildContext context, Difficulty difficulty, TextStyle headerFont) {
    IconData enemyIcon;
    Color color;
    String label;
    double size = _scale(context, 100);

    switch (difficulty) {
      case Difficulty.troll:
        enemyIcon = Icons.bug_report; color = kPixelGreen; label = "Troll (Lvl 1)"; break;
      case Difficulty.guard:
        enemyIcon = Icons.security; color = Colors.blue; label = "Guard (Lvl 5)"; break;
      case Difficulty.knight:
        enemyIcon = Icons.shield; color = Colors.orange; label = "Knight (Lvl 10)"; break;
      case Difficulty.boss:
        enemyIcon = Icons.local_fire_department; color = kPixelRed; label = "FINAL BOSS"; size = _scale(context, 130); break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("VS", style: headerFont.copyWith(color: kPixelStoneGray, fontSize: _scale(context, 14))),
        SizedBox(height: _scale(context, 10)),
        // Add a pixel glow effect behind the icon
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)]
          ),
          child: Icon(enemyIcon, size: size, color: color),
        ),
        SizedBox(height: _scale(context, 16)),
        FittedBox(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: _scale(context, 12), vertical: _scale(context, 6)),
            decoration: _pixelDecoration(bgColor: kPixelDarkBlue, borderColor: color),
            child: Text(
              label.toUpperCase(),
              style: headerFont.copyWith(fontSize: _scale(context, 16), color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPixelQuestionBox(BuildContext context, String text, TextStyle bodyFont) {
    return Container(
      padding: EdgeInsets.all(_scale(context, 16)),
      decoration: _pixelDecoration(
        bgColor: kPixelCardBg,
        borderColor: kPixelLightText,
        borderWidth: 3,
      ),
      child: Text(
        text,
        style: bodyFont.copyWith(fontSize: _scale(context, 22), height: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPixelAnswerButton(BuildContext context, {
    required String text,
    required Color color,
    required TextStyle font,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: _scale(context, 6), vertical: _scale(context, 4)),
        decoration: _pixelDecoration(
          bgColor: kPixelCardBg,
          borderColor: color, // Border matches enemy difficulty
          hasShadow: true,
        ),
        // CHANGED: Replaced FittedBox with Flexible text handling
        child: Text(
          text,
          style: font.copyWith(fontSize: _scale(context, 18), height: 1.1),
          textAlign: TextAlign.center,
          maxLines: 3, // Allow up to 3 lines of text
          overflow: TextOverflow.ellipsis, // Add '...' if it's still too long
        ),
      ),
    );
  }

  Widget _buildPixelEndScreen(BuildContext context, bool victory, GameProvider game, TextStyle headerFont, TextStyle bodyFont) {
    Color statusColor = victory ? kPixelGold : kPixelRed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we actually played a game (simple check)
      if (!game.isLoading) {
        game.recordMatchResult();
      }
    });
    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                victory ? Icons.emoji_events : Icons.heart_broken,
                size: 100,
                color: statusColor,
              ),
              const SizedBox(height: 30),
              Text(
                victory ? "VICTORY!" : "YOU DIED",
                style: headerFont.copyWith(fontSize: 32, color: statusColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                victory ? "Loot gained: ${game.xp} XP" : "The dungeon claimed your soul.",
                style: bodyFont.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: _pixelDecoration(bgColor: kPixelRed, borderColor: kPixelGold, hasShadow: true),
                  child: Text("RETURN TO CAMP", style: headerFont.copyWith(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showPixelFeedback(BuildContext context, bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 600),
        backgroundColor: correct ? kPixelGreen : kPixelRed,
        // Using a pixel-style border for the snackbar
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 3)
        ),
        content: Text(
          correct ? "CRITICAL HIT!" : "MISS!",
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  // Custom Painter for the Pixel Art borders and shadows (Same as Home Screen)
  BoxDecoration _pixelDecoration({
    required Color bgColor,
    required Color borderColor,
    double borderWidth = 3.0,
    bool hasShadow = false,
  }) {
    return BoxDecoration(
      color: bgColor,
      border: Border(
        top: BorderSide(color: borderColor, width: borderWidth),
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
        bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
      ),
      boxShadow: hasShadow ? [
        const BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
      ] : null,
    );
  }

  Color _getDifficultyColor(Difficulty d) {
    switch(d) {
      case Difficulty.troll: return kPixelGreen;
      case Difficulty.guard: return Colors.blue;
      case Difficulty.knight: return Colors.orange;
      case Difficulty.boss: return kPixelRed;
    }
  }
}