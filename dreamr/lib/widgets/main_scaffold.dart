// widgets/main_scaffold.dart
// import 'package:dreamr/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:dreamr/screens/dashboard_screen.dart';
import 'package:dreamr/screens/dream_journal_screen.dart';
import 'package:dreamr/screens/dream_journal_editor_screen.dart';
import 'package:dreamr/screens/dream_gallery_screen.dart';
import 'package:dreamr/screens/profile_screen.dart';
import 'package:dreamr/constants.dart';
import 'package:dreamr/utils/session_manager.dart';


class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  late final List<Widget> _views;
  bool _navEnabled = true;

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
      // case 3:
      //   title = "Dreamr ✨ Help";
      //   break;
      case 3:
        title = "Dreamr ✨ Manage Journal";
        break;
      case 4:
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
      // DashboardScreen(refreshTrigger: dreamEntryRefreshTrigger), // index 0
      DashboardScreen(
        refreshTrigger: dreamEntryRefreshTrigger,
        onAnalyzingChange: (bool analyzing) {
          setState(() {
            _navEnabled = !analyzing;
          });
        },
      ),
      DreamJournalScreen(refreshTrigger: journalRefreshTrigger), // index 1
      DreamGalleryScreen(refreshTrigger: galleryRefreshTrigger), // index 2
      // HelpScreen(refreshTrigger: profileRefreshTrigger), // index 3
      DreamJournalEditorScreen(refreshTrigger: editorRefreshTrigger), // index 3
      ProfileScreen(
        refreshTrigger: profileRefreshTrigger,
        onDone: () {
          setState(() {
            _selectedIndex = 1; 
          });
          // _loadUserName(); 
        },
      ),
    ];
  }

  void _onBottomNavTapped(int index) {
    // force close keyboard
    FocusScope.of(context).unfocus();

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
      // case 3:
      //   helpRefreshTrigger.value++;
      //   break;
      case 3:
        editorRefreshTrigger.value++;
        break;
      case 4:
        profileRefreshTrigger.value++;
        break;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.purple950,
        elevation: 4,
        automaticallyImplyLeading: false,
        title: _getTitleForIndex(_selectedIndex),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            color: AppColors.purple950,
            onSelected: (String route) async {
              // ✅ force keyboard to close when selecting from menu
              FocusScope.of(context).unfocus();
              
              switch (route) {
                case '/editor':
                  setState(() {
                    editorRefreshTrigger.value++;
                    _selectedIndex = 3; 
                  });
                  break;
                case '/profile':
                  setState(() {
                    _selectedIndex = 4; 
                  });
                  break;
                case '/login':
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  break;
                case 'logout':
                  await performLogout(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: '/profile',
                child: Text('Profile', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: '/editor',
                child: Text('Hide/Delete', style: TextStyle(color: Colors.white)),
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
      bottomNavigationBar: (_selectedIndex == 4 || !_navEnabled)
    ? null // hide nav on profile page OR when analyzing
    : BottomNavigationBar(
        currentIndex: (_selectedIndex == 3) ? 1 : _selectedIndex.clamp(0, 2),
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: AppColors.purple950,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'New Dream',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
