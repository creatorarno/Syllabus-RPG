import 'dart:io';
// 1. We alias this to 'td' to avoid conflicts with other libraries
import 'dart:typed_data' as td;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'battle_screen.dart';

// --- THEME CONSTANTS ---
const Color kPixelDarkBlue = Color(0xFF141020);
const Color kPixelCardBg = Color(0xFF2A2636);
const Color kPixelInactiveBg = Color(0xFF1A1626);
const Color kPixelStoneGray = Color(0xFF4E4A4E);
const Color kPixelGold = Color(0xFFFFD541);
const Color kPixelRed = Color(0xFFD53C3C);
const Color kPixelGreen = Color(0xFF5DE76F);
const Color kPixelLightText = Color(0xFFEFEFEF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  // Helper to scale sizes slightly based on screen width (Base width 375)
  double _scale(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Cap the scaling factor so tablets don't look ridiculously huge
    double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);
    return value * scaleFactor;
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isLoading = true);

      try {
        File file = File(result.files.single.path!);

        // Read file as Raw Bytes using our alias 'td'
        final td.Uint8List bytes = await file.readAsBytes();

        if (mounted) {
          // Send bytes DIRECTLY to Gemini via provider
          await Provider.of<GameProvider>(context, listen: false)
              .generateQuestFromPdf(bytes);

          setState(() => _isLoading = false);

          // Navigate to Battle
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BattleScreen()),
          );
        }
      } catch (e) {
        print("Error parsing file: $e");
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to read scroll: $e"),
              backgroundColor: kPixelRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define Pixel Fonts
    final headerFont = GoogleFonts.pressStart2p(
        color: kPixelLightText,
        fontSize: _scale(context, 12)
    );
    final bodyFont = GoogleFonts.vt323(
        color: kPixelLightText,
        fontSize: _scale(context, 20) // Slightly larger for VT323 readability
    );

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: SafeArea(
        // LayoutBuilder for responsive constraints
        child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = constraints.maxWidth * 0.05;
              final double verticalPadding = constraints.maxHeight * 0.03;
              final double mainAreaHeight = constraints.maxHeight * 0.20; // 20% height for main action area

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. THE HERO HUD (Top Banner)
                    _buildHeroHUD(context, headerFont, bodyFont),

                    const Spacer(flex: 1),

                    // 2. MAIN ACTION AREA (Loading OR Start Button)
                    SizedBox(
                      height: mainAreaHeight,
                      child: _isLoading
                          ? _buildLoadingState(headerFont)
                          : _buildMainQuestButton(context, headerFont, bodyFont),
                    ),

                    const Spacer(flex: 1),

                    // 3. GUILD GRID (Bottom Buttons)
                    Expanded(
                      flex: 3,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: _scale(context, 15),
                        mainAxisSpacing: _scale(context, 15),
                        // Dynamic aspect ratio based on available space
                        childAspectRatio: (constraints.maxWidth / 2) / (constraints.maxHeight * 0.22),
                        children: [
                          _buildPixelGridCard(
                            context: context,
                            title: "Quest Log",
                            subtitle: "Redo battles",
                            icon: Icons.map_outlined,
                            headerFont: headerFont,
                            bodyFont: bodyFont,
                            isActive: true,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Quest Log opening..."))
                              );
                            },
                          ),
                          _buildPixelGridCard(
                            context: context,
                            title: "Hall of Fame",
                            subtitle: "Rankings",
                            icon: Icons.emoji_events_outlined,
                            headerFont: headerFont,
                            bodyFont: bodyFont,
                            isActive: true,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Connecting to Leaderboard..."))
                              );
                            },
                          ),
                          _buildPixelGridCard(
                            context: context,
                            title: "Party Quests",
                            subtitle: "Coming Soon...",
                            icon: Icons.group_outlined,
                            headerFont: headerFont,
                            bodyFont: bodyFont,
                            isActive: false,
                            onTap: () {},
                          ),
                          // Placeholder for future feature or empty slot
                          Container(),
                        ],
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

  // ================= HELPER WIDGETS =================

  Widget _buildLoadingState(TextStyle headerFont) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: kPixelGold),
        const SizedBox(height: 20),
        FittedBox(
          child: Text(
            "READING ANCIENT SCROLL...",
            style: headerFont.copyWith(color: kPixelGold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHUD(BuildContext context, TextStyle headerFont, TextStyle bodyFont) {
    double avatarSize = _scale(context, 50);

    return Container(
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
      child: Row(
        children: [
          // Avatar Box
          Container(
            width: avatarSize, height: avatarSize,
            decoration: BoxDecoration(
              color: kPixelStoneGray,
              border: Border.all(color: kPixelGold, width: _scale(context, 3)),
            ),
            child: Icon(Icons.person, color: Colors.white, size: avatarSize * 0.6),
          ),
          SizedBox(width: _scale(context, 15)),

          // Stats Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text("Sir Coder Lvl. 5", style: headerFont),
                ),
                SizedBox(height: _scale(context, 8)),

                // XP Bar Row
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: _scale(context, 12), color: Colors.black),
                          FractionallySizedBox(
                            widthFactor: 0.7, // Example: 70% XP
                            child: Container(
                              height: _scale(context, 12),
                              decoration: BoxDecoration(
                                  color: kPixelGreen,
                                  border: Border(right: BorderSide(color: Colors.white, width: _scale(context, 2)))
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: _scale(context, 8)),
                    FittedBox(
                      child: Text("2,450 XP", style: bodyFont.copyWith(color: kPixelGold)),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainQuestButton(BuildContext context, TextStyle headerFont, TextStyle bodyFont) {
    return InkWell(
      onTap: _pickDocument, // Connects to the logic func
      child: Container(
        decoration: _pixelDecoration(
          bgColor: kPixelRed,
          borderColor: kPixelGold,
          borderWidth: _scale(context, 4),
          hasShadow: true,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _scale(context, 16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, size: _scale(context, 40), color: kPixelGold),
              SizedBox(width: _scale(context, 16)),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("START NEW QUEST", style: headerFont.copyWith(fontSize: _scale(context, 16), color: Colors.white))
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("Summon Monsters from PDF", style: bodyFont.copyWith(fontSize: _scale(context, 18)))
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPixelGridCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required TextStyle headerFont,
    required TextStyle bodyFont,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final double iconSize = _scale(context, 28);

    return InkWell(
      onTap: isActive ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(_scale(context, 8)),
        decoration: _pixelDecoration(
          bgColor: isActive ? kPixelCardBg : kPixelInactiveBg,
          borderColor: isActive ? kPixelStoneGray : kPixelCardBg,
          hasShadow: isActive,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: isActive ? kPixelLightText : Colors.white24),
            SizedBox(height: _scale(context, 8)),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, style: headerFont.copyWith(fontSize: _scale(context, 14), color: isActive ? Colors.white : Colors.white54))
            ),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(subtitle, style: bodyFont.copyWith(fontSize: _scale(context, 16), color: isActive ? kPixelGold : Colors.white24))
            ),
            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Icon(Icons.lock, size: _scale(context, 12), color: Colors.white24),
              )
          ],
        ),
      ),
    );
  }

  // Custom Painter for the Pixel Art borders and shadows
  BoxDecoration _pixelDecoration({
    required Color bgColor,
    required Color borderColor,
    double borderWidth = 3.0,
    bool hasShadow = false,
  }) {
    return BoxDecoration(
      color: bgColor,
      // Chunky block border - No rounded corners allowed in pixel art!
      border: Border(
        top: BorderSide(color: borderColor, width: borderWidth),
        left: BorderSide(color: borderColor, width: borderWidth),
        // Faux shadow on right and bottom borders for depth
        right: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
        bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
      ),
      boxShadow: hasShadow ? [
        // Hard pixel shadow drop (no blur)
        const BoxShadow(
          color: Colors.black,
          offset: Offset(4, 4),
          blurRadius: 0,
        )
      ] : null,
    );
  }
}