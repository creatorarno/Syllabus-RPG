import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// We will link this to the logic provider later
import '../providers/game_provider.dart';
import 'battle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  // Function to handle File Upload
  Future<void> _pickDocument() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'], // Limit to text-readable formats
    );

    if (result != null) {
      setState(() => _isLoading = true);

      File file = File(result.files.single.path!);

      // 2. Simulate "Reading the Ancient Scroll" (Processing)
      // In the next step, we will actually send this file content to Gemini here.
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // 1. Read file text (For now, we mock it or use read_pdf_text package)
        // Since we didn't add the PDF reader logic yet, let's use a dummy text for the Hackathon Demo:
        String mockText = "Photosynthesis is the process used by plants... [Imagine 5 pages of text]";

        // 2. Call the AI
        await Provider.of<GameProvider>(context, listen: false).generateQuestFromText(mockText);

        setState(() => _isLoading = false);

        // 3. Navigate to Battle
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BattleScreen())
        );
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
              // --- HERO HEADER ---
              const Icon(
                Icons.shield_moon, // RPG-style icon
                size: 80,
                color: Color(0xFFFFD700),
              ),
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

              // --- ACTION AREA ---
              if (_isLoading) ...[
                // Custom RPG Loading State
                const CircularProgressIndicator(color: Color(0xFFE94560)),
                const SizedBox(height: 20),
                Text(
                  "Summoning Monsters from Text...",
                  style: GoogleFonts.cinzel(color: Colors.white70),
                ),
              ] else ...[
                // The "Start Game" Button
                _buildQuestCard(
                  title: "New Game",
                  subtitle: "Upload PDF or Txt to generate enemies",
                  icon: Icons.upload_file,
                  color: const Color(0xFFE94560),
                  onTap: _pickDocument,
                ),

                const SizedBox(height: 16),

                // Optional: A "Load Save" button for later
                _buildQuestCard(
                  title: "Load Save",
                  subtitle: "Continue previous campaign (Coming Soon)",
                  icon: Icons.history,
                  color: Colors.grey.shade800,
                  onTap: () {}, // Disabled for now
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to make the buttons look like "Quest Cards"
  Widget _buildQuestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
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