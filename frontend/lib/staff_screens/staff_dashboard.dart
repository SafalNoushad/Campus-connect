import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'staff_home.dart';
import 'staff_academics_page.dart';
import 'staff_announcements_page.dart';
import 'staff_students_page.dart';
import 'staff_settings_page.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
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
      username = prefs.getString('username') ?? 'Staff';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      StaffHome(username: username ?? 'Staff'), // Pass username to StaffHome
      const StaffAcademicsPage(),
      const StaffAnnouncementsPage(),
      const StaffStudentsPage(),
      const StaffSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Dynamic title based on tab
        backgroundColor: Colors.green,
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
