import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pixel_theme.dart';
import '../providers/game_provider.dart'; // Adjust path as needed


// --- 1. TOP BAR & HUD ---
class PixelTopBar extends StatelessWidget {
  final GameProvider game;
  const PixelTopBar({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText);

    return Row(
      children: [
        // Back Button
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(scale(context, 8)),
            decoration: pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
            child: Icon(Icons.arrow_back, color: kPixelLightText, size: scale(context, 20)),
          ),
        ),
        SizedBox(width: scale(context, 16)),

        // HUD (Hearts & XP)
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scale(context, 12), vertical: scale(context, 8)),
            decoration: pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        index < game.hp ? Icons.favorite : Icons.favorite_border,
                        color: kPixelRed,
                        size: scale(context, 24),
                      ),
                    );
                  }),
                ),
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: kPixelGold, size: scale(context, 20)),
                    SizedBox(width: scale(context, 8)),
                    Text(
                      "${game.xp}",
                      style: headerFont.copyWith(color: kPixelGold, fontSize: scale(context, 16)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- 2. ENEMY STAGE ---
class PixelEnemyStage extends StatelessWidget {
  final Difficulty difficulty;
  const PixelEnemyStage({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText);
    IconData enemyIcon;
    Color color;
    String label;
    double size = scale(context, 100);

    switch (difficulty) {
      case Difficulty.troll:
        enemyIcon = Icons.bug_report; color = kPixelGreen; label = "Troll (Lvl 1)"; break;
      case Difficulty.guard:
        enemyIcon = Icons.security; color = Colors.blue; label = "Guard (Lvl 5)"; break;
      case Difficulty.knight:
        enemyIcon = Icons.shield; color = Colors.orange; label = "Knight (Lvl 10)"; break;
      case Difficulty.boss:
        enemyIcon = Icons.local_fire_department; color = kPixelRed; label = "FINAL BOSS"; size = scale(context, 130); break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("VS", style: headerFont.copyWith(color: kPixelStoneGray, fontSize: scale(context, 14))),
        SizedBox(height: scale(context, 10)),
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)]
          ),
          child: Icon(enemyIcon, size: size, color: color),
        ),
        SizedBox(height: scale(context, 16)),
        FittedBox(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scale(context, 12), vertical: scale(context, 6)),
            decoration: pixelDecoration(bgColor: kPixelDarkBlue, borderColor: color),
            child: Text(
              label.toUpperCase(),
              style: headerFont.copyWith(fontSize: scale(context, 16), color: color),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 3. QUESTION & ANSWERS ---
class PixelQuestionBox extends StatelessWidget {
  final String text;
  const PixelQuestionBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(scale(context, 16)),
      decoration: pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelLightText, borderWidth: 3),
      child: Text(
        text,
        style: GoogleFonts.vt323(color: kPixelLightText, fontSize: scale(context, 22), height: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class PixelAnswerButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const PixelAnswerButton({super.key, required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: scale(context, 6), vertical: scale(context, 4)),
        decoration: pixelDecoration(bgColor: kPixelCardBg, borderColor: color, hasShadow: true),
        child: Text(
          text,
          style: GoogleFonts.vt323(color: kPixelLightText, fontSize: scale(context, 18), height: 1.1),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// --- 4. END SCREEN ---
class PixelEndScreen extends StatelessWidget {
  final bool victory;
  final int xp;
  final VoidCallback onReturn;

  const PixelEndScreen({super.key, required this.victory, required this.xp, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    Color statusColor = victory ? kPixelGold : kPixelRed;
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText);

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(victory ? Icons.emoji_events : Icons.heart_broken, size: 100, color: statusColor),
              const SizedBox(height: 30),
              Text(victory ? "VICTORY!" : "YOU DIED", style: headerFont.copyWith(fontSize: 32, color: statusColor), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(victory ? "Loot gained: $xp XP" : "The dungeon claimed your soul.", style: GoogleFonts.vt323(color: kPixelLightText, fontSize: 24), textAlign: TextAlign.center),
              const SizedBox(height: 60),
              InkWell(
                onTap: onReturn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: pixelDecoration(bgColor: kPixelRed, borderColor: kPixelGold, hasShadow: true),
                  child: Text("RETURN TO CAMP", style: headerFont.copyWith(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}