import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_home_page.dart';
import 'admin_academics_page.dart';
import 'admin_announcements_page.dart';
import 'admin_students_page.dart';
import 'departments_page.dart';
import 'users_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _bottomNavPages = <Widget>[
    AdminHomePage(),
    AdminAcademicsPage(),
    AdminAnnouncementsPage(),
    AdminStudentsPage(),
  ];

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: _buildDrawer(),
      body: _bottomNavPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Academics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.announcement), label: 'Announcements'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings,
                      size: 50, color: Color(0xFF0C6170)),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const UsersPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.domain),
            title: const Text('Manage Departments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DepartmentPage()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
