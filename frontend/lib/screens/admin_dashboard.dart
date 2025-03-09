import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_screens/academics_page.dart';
import '../admin_screens/announcements_page.dart';
import '../admin_screens/profile_page.dart';
import '../admin_screens/departments_page.dart';
import 'login.dart';
import 'staffs_page.dart';
import 'students_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  Widget _selectedPage = DashboardPage();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _selectedPage = DashboardPage();
          break;
        case 1:
          _selectedPage = AcademicsPage();
          break;
        case 2:
          _selectedPage = AnnouncementsPage();
          break;
        case 3:
          _selectedPage = ProfilePage();
          break;
      }
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToStaffs() {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StaffsPage()),
    );
  }

  void _navigateToStudents() {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentsPage()),
    );
  }

  void _navigateToDepartments() {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DepartmentsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.admin_panel_settings,
                      size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Admin Panel",
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Staffs"),
              onTap: _navigateToStaffs,
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Students"),
              onTap: _navigateToStudents,
            ),
            ListTile(
              leading: const Icon(Icons.domain),
              title: const Text("Departments"),
              onTap: _navigateToDepartments,
            ),
          ],
        ),
      ),
      body: _selectedPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Academics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.announcement), label: 'Announcements'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Admin Dashboard",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
