import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/game_provider.dart';

// --- PIXEL THEME CONSTANTS ---
const Color kPixelDarkBlue = Color(0xFF141020);
const Color kPixelCardBg = Color(0xFF2A2636);
const Color kPixelGold = Color(0xFFFFD541);
const Color kPixelRed = Color(0xFFD53C3C);
const Color kPixelGreen = Color(0xFF5DE76F);
const Color kPixelStoneGray = Color(0xFF4E4A4E);
const Color kPixelLightText = Color(0xFFEFEFEF);
const Color kPixelInactiveBg = Color(0xFF1A1626);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchHistory();
  }

  Future<void> _fetchMatchHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('matches')
            .select()
            .eq('user_id', user.id)
            .order('played_at', ascending: false) // Newest first
            .limit(20);

        if (mounted) {
          setState(() {
            _matches = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading matches: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _scale(BuildContext context, double value) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);
    return value * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText);
    final bodyFont = GoogleFonts.vt323(color: kPixelLightText);

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPixelGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("HERO RECORD", style: headerFont.copyWith(fontSize: 16, color: kPixelGold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(_scale(context, 16)),
          child: Column(
            children: [
              // 1. PLAYER CARD
              _buildPlayerCard(context, game, headerFont, bodyFont),

              SizedBox(height: _scale(context, 20)),

              // 2. MATCH HISTORY LABEL
              Align(
                alignment: Alignment.centerLeft,
                child: Text("RECENT BATTLES", style: headerFont.copyWith(fontSize: 12, color: kPixelStoneGray)),
              ),

              SizedBox(height: _scale(context, 10)),

              // 3. MATCH LIST
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPixelGold))
                    : _matches.isEmpty
                    ? Center(child: Text("No battles recorded yet.", style: bodyFont.copyWith(fontSize: 20, color: Colors.white54)))
                    : ListView.separated(
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => SizedBox(height: _scale(context, 10)),
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    return _buildMatchTile(context, match, headerFont, bodyFont);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, GameProvider game, TextStyle headerFont, TextStyle bodyFont) {
    return Container(
      padding: EdgeInsets.all(_scale(context, 16)),
      decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: kPixelGold),
      child: Row(
        children: [
          // Large Avatar
          Container(
            width: _scale(context, 80), height: _scale(context, 80),
            decoration: BoxDecoration(
              color: kPixelStoneGray,
              border: Border.all(color: kPixelLightText, width: 4),
            ),
              child: Image.asset('assets/avatars/Avatars_01.png'),
          ),
          SizedBox(width: _scale(context, 20)),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.username, style: headerFont.copyWith(fontSize: 18)),
                SizedBox(height: 8),
                Text("Total XP: ${game.totalUserXp}", style: bodyFont.copyWith(fontSize: 22, color: kPixelGold)),
                Text("Battles: ${_matches.length}", style: bodyFont.copyWith(fontSize: 18, color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMatchTile(BuildContext context, Map<String, dynamic> match, TextStyle headerFont, TextStyle bodyFont) {
    final bool isVictory = match['result'] == 'Victory';
    final Color statusColor = isVictory ? kPixelGreen : kPixelRed;

    return Container(
      padding: EdgeInsets.all(_scale(context, 12)),
      decoration: _pixelDecoration(
          bgColor: kPixelInactiveBg,
          borderColor: statusColor,
          borderWidth: 2
      ),
      child: Row(
        children: [
          Icon(
              isVictory ? Icons.emoji_events : Icons.heart_broken,
              color: statusColor,
              size: 30
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isVictory ? "VICTORY" : "DEFEAT",
                    style: headerFont.copyWith(fontSize: 12, color: statusColor)
                ),
                Text(
                    "${match['questions_answered']} / ${match['total_questions']} Questions Correct",
                    style: bodyFont.copyWith(fontSize: 18, color: Colors.white70)
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text("+${match['xp_earned']}", style: headerFont.copyWith(color: kPixelGold, fontSize: 12)),
              Text("XP", style: bodyFont.copyWith(color: kPixelGold, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  BoxDecoration _pixelDecoration({required Color bgColor, required Color borderColor, double borderWidth = 4.0}) {
    return BoxDecoration(
      color: bgColor,
      border: Border(
        top: BorderSide(color: borderColor, width: borderWidth),
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
        bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: borderWidth),
      ),
    );
  }
}