import 'package:flutter/material.dart';
import '../services/api_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {

    final loggedIn = await ApiService.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      loggedIn ? '/dashboard' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F023D),
      body: Center(
        child: Image.asset(
          'assets/images/Icon.jpg',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

