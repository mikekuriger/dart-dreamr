// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dreamr/constants.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- controllers / state ---
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwCtl = TextEditingController();
  final _secure = const FlutterSecureStorage();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Google sign-in
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: kWebClientId,
  );

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwCtl.dispose();
    super.dispose();
  }

  // ===== Email login =====
  Future<void> _handleEmailLogin() async {
    if (_loading) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtl.text.trim();
      final password = _pwCtl.text;

      final user = await ApiService.login(email, password);

      await _secure.write(key: 'login_method', value: 'password');
      await _secure.write(key: 'email', value: email);
      await _secure.write(key: 'password', value: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      if (user['id'] is int) {
        await prefs.setInt('userId', user['id']);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 0)),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Google login =====
  Future<void> _handleGoogleLogin() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _error = 'Google sign-in cancelled');
        return;
      }
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        setState(() => _error = 'Google authentication failed (no token)');
        return;
      }

      await ApiService.googleLogin(token);

      await _secure.write(key: 'login_method', value: 'google');
      // optional: clear any old email/password so you don't accidentally try both paths later
      await _secure.delete(key: 'email');
      await _secure.delete(key: 'password');


      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 1)),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg.isEmpty ? 'Google login failed' : msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Validators =====
  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').isEmpty) return 'Password required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subtle = const Color(0xFFD1B2FF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple950,
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome to Dreamr ✨",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 2),
            Text(
              "Your personal AI-powered dream analysis",
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFD1B2FF)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    border: Border.all(color: Colors.red.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),

              // ===== Login form (prominent) =====
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwCtl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleEmailLogin(),
                      style: const TextStyle(color: Colors.white),
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : () => Navigator.pushNamed(context, '/forgot-password'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: _loading ? null : _handleEmailLogin,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ===== Divider: or continue with =====
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  const SizedBox(width: 8),
                  Text('or', style: TextStyle(color: subtle)),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),

              const SizedBox(height: 16),

              // ===== Social logins =====
              Center(
                child: Column(
                  children: [
                    // Google (your SVG image, clickable)
                    GestureDetector(
                      onTap: _loading ? null : _handleGoogleLogin,
                      child: SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Apple placeholder (disabled for now)
                    // Opacity(
                    //   opacity: 0.4,
                    //   child: OutlinedButton(
                    //     onPressed: null, // disabled
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.white,
                    //       side: const BorderSide(color: Colors.white54),
                    //       minimumSize: const Size(220, 44),
                    //     ),
                    //     child: const Text("Continue with Apple (coming soon)"),
                    //   ),
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== Register prompt (prominent) =====
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('New here?', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Create account',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
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
}
