import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/network_config.dart';
import '../admin_screens/departments_page.dart';
import '../admin_screens/users_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Index for bottom navbar

  // Pages for bottom navigation bar
  static const List<Widget> _bottomNavPages = <Widget>[
    AdminHomePage(), // Index 0: Home (Landing Page)
    AcademicsPage(), // Index 1: Academics
    AnnouncementsPage(), // Index 2: Announcements
    StudentsPage(), // Index 3: Students
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
      drawer: _buildDrawer(), // Sidebar (Drawer)
      body: _bottomNavPages[_selectedIndex], // Display selected bottom nav page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Academics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.domain),
            title: const Text('Manage Departments'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DepartmentPage()),
              );
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

// Landing Page (Home Page) for Admin
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome, Admin!",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C6170)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Manage your campus efficiently from here.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.info, size: 40, color: Color(0xFF0C6170)),
                  const SizedBox(height: 10),
                  const Text(
                    "Quick Stats",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Users", "50"), // Placeholder data
                      _buildStatItem("Departments", "5"), // Placeholder data
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}

// Placeholder Pages for Bottom Navigation
class AcademicsPage extends StatelessWidget {
  const AcademicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Academics Section\n(Under Development)",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Announcements Section\n(Under Development)",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

// Updated Students Page with Search and Card Display
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> _students = [];
  dynamic _searchedStudent; // Single student to display after search
  String _searchQuery = '';
  String? _selectedBatch; // For filtering by batch
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final allUsers = json.decode(response.body);
        setState(() {
          _students =
              allUsers.where((user) => user['role'] == 'student').toList();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load students: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching students: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _searchStudent() {
    setState(() {
      _searchedStudent = null; // Reset previous result
      if (_searchQuery.isNotEmpty) {
        _searchedStudent = _students.firstWhere(
          (student) =>
              (student['username']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  student['admission_number']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) &&
              (_selectedBatch == null || student['batch'] == _selectedBatch),
          orElse: () => null,
        );
      }
    });
  }

  List<String> _getBatchOptions() {
    return _students
        .map((student) => student['batch'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Name or Admission Number',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchStudent();
            },
          ),
          const SizedBox(height: 10),
          // Batch Filter Dropdown
          DropdownButtonFormField<String>(
            value: _selectedBatch,
            hint: const Text('Filter by Batch'),
            items: _getBatchOptions().map((batch) {
              return DropdownMenuItem<String>(
                value: batch,
                child: Text(batch),
              );
            }).toList()
              ..add(const DropdownMenuItem<String>(
                value: null,
                child: Text('All Batches'),
              )),
            onChanged: (value) {
              _selectedBatch = value;
              _searchStudent();
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // Student Details Card
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _searchQuery.isEmpty
                        ? const Center(
                            child:
                                Text('Enter a search query to find a student'))
                        : _searchedStudent == null
                            ? const Center(child: Text('No student found'))
                            : Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.school,
                                              size: 30,
                                              color: Color(0xFF0C6170)),
                                          const SizedBox(width: 10),
                                          Text(
                                            _searchedStudent['username'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      _buildDetailRow('Admission No:',
                                          _searchedStudent['admission_number']),
                                      _buildDetailRow('Email:',
                                          _searchedStudent['email'] ?? 'N/A'),
                                      _buildDetailRow('Batch:',
                                          _searchedStudent['batch'] ?? 'N/A'),
                                      _buildDetailRow(
                                          'Department:',
                                          _searchedStudent['departmentcode'] ??
                                              'N/A'),
                                      _buildDetailRow(
                                          'Phone:',
                                          _searchedStudent['phone_number'] ??
                                              'N/A'),
                                    ],
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
