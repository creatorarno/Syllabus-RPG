import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pixel_theme.dart';
import '../providers/game_provider.dart';
import '../widgets/battle_widgets.dart';


class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool _hasRecordedResult = false;

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    // 1. GAME OVER / VICTORY CHECK
    if (game.isGameOver || game.isVictory) {
      if (!_hasRecordedResult) {
        _hasRecordedResult = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!game.isLoading) game.recordMatchResult();
        });
      }

      return PixelEndScreen(
        victory: game.isVictory,
        xp: game.xp,
        // --- FIX IS HERE ---
        // We use popUntil to remove ALL battle screens from the stack
        onReturn: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }

    // Reset flag if starting new game
    if (game.currentQuestion != null && _hasRecordedResult) {
      _hasRecordedResult = false;
    }

    // 2. LOADING STATE
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
                padding: EdgeInsets.all(scale(context, 16.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TOP BAR ---
                    PixelTopBar(game: game),

                    const Spacer(flex: 1),

                    // --- ENEMY STAGE ---
                    PixelEnemyStage(difficulty: q.difficulty),

                    const Spacer(flex: 1),

                    // --- QUESTION BOX ---
                    PixelQuestionBox(text: q.text),

                    SizedBox(height: scale(context, 20)),

                    // --- OPTIONS GRID ---
                    Expanded(
                      flex: 4,
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: scale(context, 12),
                        mainAxisSpacing: scale(context, 12),
                        children: List.generate(q.options.length, (index) {
                          return PixelAnswerButton(
                            text: q.options[index],
                            color: difficultyColor,
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

  void _showPixelFeedback(BuildContext context, bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 600),
        backgroundColor: correct ? kPixelGreen : kPixelRed,
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 3)
        ),
        content: Text(
          correct ? "CRITICAL HIT!" : "MISS!",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, color: Colors.black),
        ),
      ),
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