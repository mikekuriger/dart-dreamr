import 'package:flutter/material.dart';
// import 'screens/splash_screen.dart';
import 'package:dreamr/screens/login_screen.dart';
import 'package:dreamr/screens/register_screen.dart';
import 'package:dreamr/screens/dashboard_screen.dart';
import 'package:dreamr/screens/dream_journal_screen.dart';
import 'package:dreamr/screens/dream_gallery_screen.dart';
import 'services/dio_client.dart';
import 'package:dreamr/theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.init();
  runApp(const DreamrApp());
}

class DreamrApp extends StatelessWidget {
  const DreamrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dreamr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.purple850,        // main background color
      ),
      // home: const SplashScreen(),  // 🚀 Start here
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/journal': (context) => const DreamJournalScreen(),
        '/gallery': (context) => const DreamGalleryScreen(),
        '/image': (context) => const Placeholder(), // temporary

      },
    );
  }
}

