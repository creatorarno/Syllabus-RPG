import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Screen Imports
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- Import Supabase
import 'package:syllabus_rpg/screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 1. INITIALIZE SUPABASE (Put your real keys here)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const DungeonQuizApp());
}

class DungeonQuizApp extends StatelessWidget {
  const DungeonQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'Syllabus RPG',
        debugShowCheckedModeBanner: false,

        // --- THEME CONFIGURATION ---
        theme: _buildRPGTheme(),

        // 2. SESSION CHECK LOGIC
        // If the user is logged in (session exists), go to Home.
        // Otherwise, go to Login.
        home: Supabase.instance.client.auth.currentSession != null
            ? const HomeScreen()
            : const LoginScreen(),

        // Note: I removed initialRoute: '/' because 'home:' handles the entry point now.
        routes: {
          // You can keep other named routes here if needed
          // '/battle': (context) => const BattleScreen(),
        },
      ),
    );
  }

  ThemeData _buildRPGTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF141020), // Updated to Pixel Dark Blue

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700),    // Gold
        secondary: Color(0xFFE94560),  // Red
        surface: Color(0xFF2A2636),    // Pixel Card Bg
        onSurface: Color(0xFFEFEFEF),  // Pixel Light Text
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.pressStart2p(
            fontSize: 24, // Smaller font size for Pixel font
            color: const Color(0xFFFFD700)
        ),
        headlineMedium: GoogleFonts.pressStart2p(
            fontSize: 16,
            fontWeight: FontWeight.w600
        ),
        bodyLarge: GoogleFonts.vt323(
            fontSize: 22, // VT323 needs to be larger to be readable
            color: const Color(0xFFEFEFEF)
        ),
      ),
    );
  }
}