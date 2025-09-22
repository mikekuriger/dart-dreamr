// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dreamr/screens/splash_screen.dart';
import 'package:dreamr/screens/login_screen.dart';
import 'package:dreamr/screens/register_screen.dart';
import 'package:dreamr/screens/dashboard_screen.dart';
import 'package:dreamr/screens/dream_journal_screen.dart';
import 'package:dreamr/screens/dream_journal_editor_screen.dart';
import 'package:dreamr/screens/dream_gallery_screen.dart';
import 'package:dreamr/screens/profile_screen.dart';

import 'package:dreamr/services/dio_client.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:dreamr/constants.dart';

import 'package:dreamr/repository/dream_repository.dart';
import 'package:dreamr/state/dream_list_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DreamRepository>(create: (_) => DreamRepository()),
        ChangeNotifierProvider<DreamListModel>(
          // includeHidden: true if you want hidden entries in the list model
          create: (ctx) => DreamListModel(repo: ctx.read<DreamRepository>())..init(),
        ),
      ],
      child: const DreamrApp(),
    ),
  );
}

class DreamrApp extends StatelessWidget {
  const DreamrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dreamr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(refreshTrigger: dreamEntryRefreshTrigger),
        '/journal': (context) => DreamJournalScreen(refreshTrigger: journalRefreshTrigger),
        '/editor': (context) => DreamJournalEditorScreen(refreshTrigger: journalRefreshTrigger),
        '/gallery': (context) => DreamGalleryScreen(refreshTrigger: galleryRefreshTrigger),
        '/image': (context) => const Placeholder(),
        '/profile': (context) => ProfileScreen(refreshTrigger: profileRefreshTrigger),
      },
    );
  }
}
