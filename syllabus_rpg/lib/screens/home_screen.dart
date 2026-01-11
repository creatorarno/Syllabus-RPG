import 'dart:io';
import 'dart:typed_data' as td;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/game_provider.dart';
import 'auth/login_screen.dart';  // <--- Import this to navigate back
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
const Color kPixelBronze = Color(0xFFCD7F32);
const Color kPixelSilver = Color(0xFFC0C0C0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _selectedTimeframe = 'All Time';

  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).loadUserProfile();
    });
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('username, xp')
          .order('xp', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(data);
          _isLoadingLeaderboard = false;
        });
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      if (mounted) setState(() => _isLoadingLeaderboard = false);
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _signOut() async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPixelCardBg,
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: kPixelStoneGray, width: 3)
        ),
        title: Text("LEAVE GUILD?", style: GoogleFonts.pressStart2p(color: kPixelRed, fontSize: 14)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.vt323(color: Colors.white, fontSize: 24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("STAY", style: GoogleFonts.pressStart2p(color: kPixelGreen, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("LOGOUT", style: GoogleFonts.pressStart2p(color: kPixelRed, fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Perform Logout
    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      // 3. Navigate to Login (Remove all previous routes)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  double _scale(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
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
        final td.Uint8List bytes = await file.readAsBytes();

        if (mounted) {
          await Provider.of<GameProvider>(context, listen: false)
              .generateQuestFromPdf(bytes);

          setState(() => _isLoading = false);

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
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText, fontSize: _scale(context, 12));
    final bodyFont = GoogleFonts.vt323(color: kPixelLightText, fontSize: _scale(context, 20));
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _scale(context, 16),
                  vertical: _scale(context, 12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HERO HUD
                    _buildHeroHUD(context, gameProvider, headerFont, bodyFont),

                    SizedBox(height: _scale(context, 20)),

                    // 2. LEADERBOARD
                    Expanded(
                      child: Container(
                        decoration: _pixelDecoration(
                            bgColor: kPixelInactiveBg,
                            borderColor: kPixelStoneGray
                        ),
                        child: Column(
                          children: [
                            _buildLeaderboardHeader(context, headerFont),
                            _buildTimeframeTabs(context, headerFont),
                            Expanded(
                              child: _isLoadingLeaderboard
                                  ? Center(child: CircularProgressIndicator(color: kPixelGold))
                                  : ListView.separated(
                                padding: EdgeInsets.all(_scale(context, 12)),
                                itemCount: _leaderboard.length,
                                separatorBuilder: (_, __) => SizedBox(height: _scale(context, 8)),
                                itemBuilder: (context, index) {
                                  final player = _leaderboard[index];
                                  return _buildLeaderboardItem(context, player, index + 1, headerFont, bodyFont);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: _scale(context, 20)),

                    // 3. MAIN ACTION
                    SizedBox(
                      height: _scale(context, 80),
                      child: _isLoading
                          ? _buildLoadingState(headerFont)
                          : _buildMainQuestButton(context, headerFont, bodyFont),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildHeroHUD(BuildContext context, GameProvider game, TextStyle headerFont, TextStyle bodyFont) {
    double avatarSize = _scale(context, 45);

    return Container(
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelStoneGray),
      child: Row(
        children: [
          // Avatar
          Container(
            width: avatarSize, height: avatarSize,
            decoration: BoxDecoration(
              color: kPixelStoneGray,
              border: Border.all(color: kPixelGold, width: _scale(context, 3)),
            ),
            child: Icon(Icons.person, color: Colors.white, size: avatarSize * 0.6),
          ),
          SizedBox(width: _scale(context, 15)),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(game.username, style: headerFont.copyWith(fontSize: _scale(context, 12))),
                SizedBox(height: _scale(context, 6)),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: _scale(context, 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5,
                          child: Container(color: kPixelGreen),
                        ),
                      ),
                    ),
                    SizedBox(width: _scale(context, 8)),
                    Text("${game.totalUserXp} XP", style: bodyFont.copyWith(color: kPixelGold)),
                  ],
                ),
              ],
            ),
          ),

          // --- LOGOUT BUTTON ---
          Container(
              width: 1,
              height: 30,
              color: kPixelStoneGray,
              margin: EdgeInsets.symmetric(horizontal: 8)
          ),
          InkWell(
            onTap: _signOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: kPixelRed, size: 20),
                SizedBox(height: 4),
                Text("EXIT", style: headerFont.copyWith(fontSize: 8, color: kPixelRed))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader(BuildContext context, TextStyle headerFont) {
    return Container(
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: BoxDecoration(
        color: kPixelCardBg,
        border: Border(bottom: BorderSide(color: kPixelStoneGray, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: kPixelGold, size: _scale(context, 20)),
          SizedBox(width: _scale(context, 10)),
          Text("HALL OF FAME", style: headerFont.copyWith(color: kPixelGold, fontSize: _scale(context, 14))),
          SizedBox(width: _scale(context, 10)),
          Icon(Icons.emoji_events, color: kPixelGold, size: _scale(context, 20)),
        ],
      ),
    );
  }

  Widget _buildTimeframeTabs(BuildContext context, TextStyle headerFont) {
    final tabs = ['Daily', 'Weekly', 'Monthly', 'All Time'];

    return Container(
      height: _scale(context, 40),
      margin: EdgeInsets.symmetric(vertical: _scale(context, 8)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: _scale(context, 8)),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab == _selectedTimeframe;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTimeframe = tab);
            },
            child: Container(
              margin: EdgeInsets.only(right: _scale(context, 8)),
              padding: EdgeInsets.symmetric(horizontal: _scale(context, 12)),
              alignment: Alignment.center,
              decoration: _pixelDecoration(
                bgColor: isActive ? kPixelGold : kPixelCardBg,
                borderColor: isActive ? Colors.white : kPixelStoneGray,
                borderWidth: 2,
              ),
              child: Text(
                tab.toUpperCase(),
                style: headerFont.copyWith(
                  color: isActive ? kPixelDarkBlue : Colors.white54,
                  fontSize: _scale(context, 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, Map<String, dynamic> player, int rank, TextStyle headerFont, TextStyle bodyFont) {
    Color rankColor;
    double scale = 1.0;

    if (rank == 1) { rankColor = kPixelGold; scale = 1.05; }
    else if (rank == 2) { rankColor = kPixelSilver; }
    else if (rank == 3) { rankColor = kPixelBronze; }
    else { rankColor = kPixelStoneGray; }

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: _scale(context, 8), horizontal: _scale(context, 12)),
        decoration: _pixelDecoration(
            bgColor: rank == 1 ? const Color(0xFF3A3646) : kPixelCardBg,
            borderColor: rankColor,
            borderWidth: 2
        ),
        child: Row(
          children: [
            Container(
              width: _scale(context, 24),
              alignment: Alignment.center,
              child: Text("#$rank", style: headerFont.copyWith(color: rankColor, fontSize: _scale(context, 12))),
            ),
            SizedBox(width: _scale(context, 12)),
            Expanded(
              child: Text(
                player['username'] ?? "Unknown",
                style: bodyFont.copyWith(color: Colors.white, fontSize: _scale(context, 20)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: kPixelGold, size: _scale(context, 14)),
                SizedBox(width: 4),
                Text(
                  "${player['xp']}",
                  style: headerFont.copyWith(color: kPixelGold, fontSize: _scale(context, 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(TextStyle headerFont) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: kPixelGold),
        const SizedBox(height: 10),
        Text("READING SCROLL...", style: headerFont.copyWith(color: kPixelGold, fontSize: 10)),
      ],
    );
  }

  Widget _buildMainQuestButton(BuildContext context, TextStyle headerFont, TextStyle bodyFont) {
    return InkWell(
      onTap: _pickDocument,
      child: Container(
        decoration: _pixelDecoration(
          bgColor: kPixelRed,
          borderColor: kPixelGold,
          borderWidth: _scale(context, 4),
          hasShadow: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: _scale(context, 30), color: kPixelGold),
            SizedBox(width: _scale(context, 16)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NEW QUEST", style: headerFont.copyWith(fontSize: _scale(context, 14), color: Colors.white)),
                Text("Summon from PDF", style: bodyFont.copyWith(fontSize: _scale(context, 18))),
              ],
            ),
          ],
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
          ],
        ),
      ),
    );
  }

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
}