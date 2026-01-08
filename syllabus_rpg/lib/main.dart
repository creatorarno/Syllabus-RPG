import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// We will create these files next, but I'm importing them now so you see the structure
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';

void main() {
  runApp(const DungeonQuizApp());
}

class DungeonQuizApp extends StatelessWidget {
  const DungeonQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // This is the brain of the app (Handles HP, Questions, Logic)
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'Syllabus RPG',
        debugShowCheckedModeBanner: false,

        // --- THE RPG THEME CONFIGURATION ---
        theme: _buildRPGTheme(),

        // Define Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          // We will add '/battle_screen' later
        },
      ),
    );
  }

  ThemeData _buildRPGTheme() {
    return ThemeData(
      useMaterial3: true,
      // Dark Mode Base
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Deep Void Blue

      // Color Palette
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700),    // Gold (for buttons/loot)
        secondary: Color(0xFFE94560),  // Red (for danger/Trolls)
        surface: Color(0xFF16213E),    // Card Backgrounds
        onSurface: Colors.white,
      ),

      // Text Styling (Cinzel is a great fantasy font)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700)
        ),
        headlineMedium: GoogleFonts.cinzel(
            fontSize: 24,
            fontWeight: FontWeight.w600
        ),
        bodyLarge: GoogleFonts.lato(
            fontSize: 18,
            color: Colors.white70
        ),
      ),

      // Button Styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560), // Red Battle Button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2), // Gold Border
          ),
          textStyle: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}