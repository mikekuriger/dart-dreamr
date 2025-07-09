import 'package:flutter/material.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:dreamr/screens/dashboard_screen.dart';
import 'package:dreamr/screens/dream_journal_screen.dart';
import 'package:dreamr/screens/dream_gallery_screen.dart';
// import 'package:dreamr/screens/profile_screen.dart';
import 'package:dreamr/constants.dart';



class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  late final List<Widget> _views;

  Widget _getTitleForIndex(int index) {
    String title;
    switch (index) {
      case 0:
        title = "Dreamr ✨";
        break;
      case 1:
        title = "Dreamr ✨ Journal ✍️";
        break;
      case 2:
        title = "Dreamr ✨ Gallery";
        break;
      case 3:
        title = "Dreamr ✨ Profile";
        break;
      default:
        title = "Dreamr";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Your personal AI-powered dream analysis",
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Color(0xFFD1B2FF),
          ),
        ),
      ],
    );
  }



  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _views = [
      DashboardScreen(refreshTrigger: dreamEntryRefreshTrigger),
      DreamJournalScreen(refreshTrigger: journalRefreshTrigger),
      DreamGalleryScreen(refreshTrigger: galleryRefreshTrigger),
      //ProfileScreen(refreshTrigger: profileRefreshTrigger),
    ];
  }

  void _onBottomNavTapped(int index) {
    // Trigger refresh logic based on index
    switch (index) {
      case 0:
        dreamEntryRefreshTrigger.value++;
        break;
      case 1:
        journalRefreshTrigger.value++;
        break;
      case 2:
        galleryRefreshTrigger.value++;
        break;
      case 3:
        profileRefreshTrigger.value++;
        break;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  // void _onBottomNavTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple950,
        elevation: 4,
        automaticallyImplyLeading: false,
        title: _getTitleForIndex(_selectedIndex),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.home, color: Colors.white),
          //   onPressed: () {
          //     final routeName = ModalRoute.of(context)?.settings.name;
          //     if (routeName == '/journal') {
          //     } else {
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(builder: (context) => const MainScaffold(initialIndex: 1)),
          //       );
          //     }
          //   },
          //   tooltip: 'Home',
          // ),
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
              // const PopupMenuItem(
              //   value: '/journal',
              //   child: Text('Dream Journal', style: TextStyle(color: Colors.white)),
              // ),
              // const PopupMenuItem(
              //   value: '/gallery',
              //   child: Text('Dream Gallery', style: TextStyle(color: Colors.white)),
              // ),
              // const PopupMenuItem(
              //   value: '/dashboard',
              //   child: Text('Manage Journal', style: TextStyle(color: Colors.white)),
              // ),
              // const PopupMenuItem(
              //   value: '/profile',
              //   child: Text('Edit Profile', style: TextStyle(color: Colors.white)),
              // ),
              const PopupMenuItem(
                value: '/login',
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      // body: widget.body,
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: AppColors.purple950, // 👈 match AppBar
        type: BottomNavigationBarType.fixed, // 👈 important to keep background color
        showUnselectedLabels: false, // 👈 hide labels for unselected
        showSelectedLabels: true,    // 👈 only show selected label
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Enter Dream',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Gallery',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person),
          //   label: 'Profile',
          // ),
        ],
      ),
    );
  }
}
