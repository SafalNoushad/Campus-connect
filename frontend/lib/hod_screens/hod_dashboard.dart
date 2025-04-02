import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hod_home.dart';
import 'academics_page.dart';
import 'announcements_page.dart';
import '../shared/department_users_page.dart';
import 'settings_page.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  _HodDashboardState createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  int _selectedIndex = 0; // Default to "Home" tab
  String? username; // Store username for display

  // Define pages for each tab (non-const to allow dynamic username)
  late List<Widget> _pages;

  // Define titles for each tab
  static const List<String> _titles = <String>[
    'Home', // Tab 0
    'Academics', // Tab 1
    'Announcements', // Tab 2
    'Students', // Tab 3
    'Settings', // Tab 4
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Load username on initialization
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'HOD';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('departmentcode');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize pages with username dynamically
    _pages = [
      HodHome(username: username ?? 'HOD'), // Pass username to HodHome
      const AcademicsPage(),
      const HodAnnouncementsPage(),
      const DepartmentUsersPage(isStaffView: false),
      const HodSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Dynamic title based on tab
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Academics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
