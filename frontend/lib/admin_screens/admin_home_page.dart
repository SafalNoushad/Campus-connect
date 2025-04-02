import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _userCount = 0;
  int _departmentCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      // Fetch users count
      final usersResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Fetch departments count
      final departmentsResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (usersResponse.statusCode == 200 &&
          departmentsResponse.statusCode == 200) {
        final usersData = jsonDecode(usersResponse.body) as List<dynamic>;
        final departmentsData =
            jsonDecode(departmentsResponse.body) as List<dynamic>;
        setState(() {
          _userCount = usersData.length;
          _departmentCount = departmentsData.length;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load data: Users(${usersResponse.statusCode}), Departments(${departmentsResponse.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

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
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem("Users", _userCount.toString()),
                                _buildStatItem(
                                    "Departments", _departmentCount.toString()),
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
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
