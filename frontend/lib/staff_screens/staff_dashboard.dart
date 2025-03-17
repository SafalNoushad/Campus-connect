import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/department_users_page.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  String? username; // Add variable to store username

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Load username on initialization
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ??
          'Staff'; // Default to 'Staff' if username not found
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all preferences
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $username!', // Updated to display username
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DepartmentUsersPage(isStaffView: true),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text("View Department Students"),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Staff feature coming soon!")),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text("View Reports"),
            ),
          ],
        ),
      ),
    );
  }
}
