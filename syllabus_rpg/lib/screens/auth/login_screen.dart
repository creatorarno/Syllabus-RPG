import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home_screen.dart';

// --- PIXEL THEME CONSTANTS ---
const Color kPixelDarkBlue = Color(0xFF141020);
const Color kPixelCardBg = Color(0xFF2A2636);
const Color kPixelGold = Color(0xFFFFD541);
const Color kPixelRed = Color(0xFFD53C3C);
const Color kPixelLightText = Color(0xFFEFEFEF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Added Username Controller
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;

  // REPLACE YOUR _handleAuth FUNCTION WITH THIS:
  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Username and Password required");
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      if (_isSignUp) {
        // --- SIGN UP LOGIC (Remains the same) ---
        if (email.isEmpty) {
          _showError("Email required for Sign Up");
          setState(() => _isLoading = false);
          return;
        }

        // Check Unique Username
        final data = await supabase
            .from('profiles')
            .select('username')
            .eq('username', username)
            .maybeSingle();

        if (data != null) throw const AuthException("Username already taken!");

        // Sign Up
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (res.user == null) throw const AuthException("Sign up failed");

        // Save Profile
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'username': username,
          'email': email,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Hero Created! Please Log In.")),
          );
          setState(() => _isSignUp = false); // Switch user to Login mode
        }

      } else {
        // --- LOGIN LOGIC ---

        // 1. Lookup Email from Username
        final data = await supabase
            .from('profiles')
            .select('email')
            .eq('username', username)
            .maybeSingle();

        if (data == null) {
          throw const AuthException("Hero not found (Check username)");
        }

        final foundEmail = data['email'] as String;

        // 2. Sign In
        await supabase.auth.signInWithPassword(
          email: foundEmail,
          password: password,
        );

        // 3. NAVIGATE TO HOME (THE FIX)
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError("Connection Failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPixelRed,
        content: Text(msg, style: GoogleFonts.vt323(fontSize: 20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerFont = GoogleFonts.pressStart2p(color: kPixelLightText, fontSize: 20);
    final bodyFont = GoogleFonts.vt323(color: kPixelLightText, fontSize: 24);

    return Scaffold(
      backgroundColor: kPixelDarkBlue,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 200, width: 200,),
              const SizedBox(height: 40),

              // --- USERNAME (Always Visible) ---
              _buildPixelInput("USERNAME", _usernameController, false),
              const SizedBox(height: 20),

              // --- EMAIL (Only for Sign Up) ---
              if (_isSignUp) ...[
                _buildPixelInput("EMAIL", _emailController, false),
                const SizedBox(height: 20),
              ],

              // --- PASSWORD (Always Visible) ---
              _buildPixelInput("PASSWORD", _passwordController, true),

              const SizedBox(height: 40),

              // --- ACTION BUTTON ---
              if (_isLoading)
                const CircularProgressIndicator(color: kPixelGold)
              else
                InkWell(
                  onTap: _handleAuth,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: _pixelDecoration(bgColor: kPixelRed, borderColor: kPixelGold),
                    child: Text(
                      _isSignUp ? "CREATE HERO" : "ENTER WORLD",
                      style: headerFont.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // --- TOGGLE MODE ---
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? "Already have a hero? Login" : "New here? Create Account",
                  style: bodyFont.copyWith(color: Colors.white54),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPixelInput(String label, TextEditingController controller, bool obscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          decoration: _pixelDecoration(bgColor: kPixelCardBg, borderColor: Colors.white24),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: GoogleFonts.vt323(color: Colors.white, fontSize: 24),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _pixelDecoration({required Color bgColor, required Color borderColor}) {
    return BoxDecoration(
      color: bgColor,
      border: Border(
        top: BorderSide(color: borderColor, width: 4),
        left: BorderSide(color: borderColor, width: 4),
        right: BorderSide(color: Colors.black.withOpacity(0.5), width: 4),
        bottom: BorderSide(color: Colors.black.withOpacity(0.5), width: 4),
      ),
    );
  }
}