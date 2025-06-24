import 'package:flutter/material.dart';
import 'package:dreamr/theme/colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget title;
  final Widget body;
  final Widget? floatingActionButton;
  final VoidCallback? onHomePressed;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onHomePressed,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple950,
        elevation: 4,
        automaticallyImplyLeading: false,   // hides the back button
        title: title,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            // onPressed: () {
            //   Navigator.pushNamed(context, '/dashboard');
            // },
            onPressed: () {
              final routeName = ModalRoute.of(context)?.settings.name;
              if (routeName == '/journal') {
                onHomePressed?.call(); // 👈 scroll to top
              } else {
                Navigator.pushNamed(context, '/dashboard');
              }
            },
            tooltip: 'Home',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            color: AppColors.purple900,
            onSelected: (String route) {
              if (route == '/login') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              } else {
                Navigator.pushNamed(context, route);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: '/journal',
                child: Text('Dream Journal', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: '/gallery',
                child: Text('Dream Gallery', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: '/dashboard',
                child: Text('Manage Journal', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: '/profile',
                child: Text('Edit Profile', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: '/login',
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
