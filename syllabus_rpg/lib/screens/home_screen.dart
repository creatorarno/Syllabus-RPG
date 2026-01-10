import 'dart:io';
// 1. We alias this to 'td' to avoid conflicts with other libraries
import 'dart:typed_data' as td;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Note: Syncfusion import is REMOVED. We don't need it anymore!

import '../providers/game_provider.dart';
import 'battle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _pickDocument() async {
    // 1. Pick the file (PDF only for this mode)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isLoading = true);

      try {
        File file = File(result.files.single.path!);

        // 2. Read the file as Raw Bytes using our alias 'td'
        // This avoids the "Uint8List is defined in..." error.
        final td.Uint8List bytes = await file.readAsBytes();

        if (mounted) {
          // 3. Send the bytes DIRECTLY to Gemini
          // Make sure your GameProvider has the 'generateQuestFromPdf' function!
          await Provider.of<GameProvider>(context, listen: false)
              .generateQuestFromPdf(bytes);

          setState(() => _isLoading = false);

          // 4. Navigate to Battle
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
            SnackBar(content: Text("Failed to read scroll: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_moon, size: 80, color: Color(0xFFFFD700)),
              const SizedBox(height: 20),
              Text(
                "SYLLABUS RPG",
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Turn your boring documents into\nan epic quest.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              if (_isLoading) ...[
                const CircularProgressIndicator(color: Color(0xFFE94560)),
                const SizedBox(height: 20),
                Text(
                    "Gemini is reading your PDF...",
                    style: GoogleFonts.cinzel(color: Colors.white70)
                ),
              ] else ...[
                _buildQuestCard(
                  title: "New Game",
                  subtitle: "Upload PDF directly to Gemini",
                  icon: Icons.upload_file,
                  color: const Color(0xFFE94560),
                  onTap: _pickDocument,
                ),
                const SizedBox(height: 16),
                _buildQuestCard(
                  title: "Load Save",
                  subtitle: "Coming Soon",
                  icon: Icons.history,
                  color: Colors.grey.shade800,
                  onTap: () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 14, color: Colors.white54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}