import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  void _attemptAutoLogin() async {
    try {
      final loginMethod = await _storage.read(key: 'login_method');

      if (loginMethod == 'google') {
        try {
          final googleUser = await GoogleSignIn().signInSilently();

          if (googleUser != null) {
            final auth = await googleUser.authentication;
            final idToken = auth.idToken;

            if (idToken != null) {
              await ApiService.googleLogin(idToken);

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScaffold()),
              );
              return;
            }
          }
        } catch (e) {
          // ignore and fall back to manual login
        }
      }

      final email = await _storage.read(key: 'email');
      final password = await _storage.read(key: 'password');
      if (email != null && password != null) {
        try {
          await ApiService.login(email, password);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScaffold()),
          );
          return;
        } catch (e) {
          // Login failed, fall through to login screen
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // 🔥 this catches BAD_DECRYPT or any other secure storage read failure
      debugPrint('❌ Secure storage error: $e');
      await _storage.deleteAll(); // wipe corrupted entries
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
