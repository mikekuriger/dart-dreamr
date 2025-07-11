import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ignore: unused_field
  String _errorMessage = '';
  bool _loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '846080686597-61d3v0687vomt4g4tl7rueu7rv9qrari.apps.googleusercontent.com',
  );
  
  Future<void> _handleGoogleLogin() async {
    try {
      final account = await _googleSignIn.signIn();
      final storage = FlutterSecureStorage();
      await storage.write(key: 'login_method', value: 'google');
      // await storage.write(key: 'email', value: user.email);

      if (account == null) {
        setState(() {
          _errorMessage = "Login cancelled";
        });
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = "Google authentication failed";
        });
        return;
      }

      await ApiService.googleLogin(idToken);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScaffold(initialIndex: 1)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Google login failed";
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final user = await ApiService.login(email, password);

      // 🔐 Save session state to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setInt('userId', user['id']);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScaffold(initialIndex: 1)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Invalid login";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple950, // use your darkest shade
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome to Dreamr ✨",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Your personal AI-powered dream analysis",
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFFD1B2FF), // soft lavender/purple for subtext
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white), // Label
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.white), // Label
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),

    // login button
            // ElevatedButton(
            //   onPressed: _loading ? null : _handleLogin,
            //   child: _loading
            //       ? const CircularProgressIndicator()
            //       : const Text("Login"),
            // ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, // 🟢 text/icon color
                    backgroundColor: Colors.white, // optional, in case you want white button
                  ),
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Login"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text("Register"),
                ),
              ],
            ),


    // google login
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _handleGoogleLogin,
              child: SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

