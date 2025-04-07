import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> _students = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print('StudentsPage: Token = $token');
      if (token == null) {
        print('StudentsPage: No token found, redirecting to login');
        _redirectToLogin();
        return;
      }

      final url = Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/users');
      print('StudentsPage: Full URL = $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'StudentsPage: Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        print('StudentsPage: Users fetched: ${users.length}');
        setState(() {
          _students = users.where((user) => user['role'] == 'student').toList();
          _errorMessage = null;
          print('StudentsPage: Students filtered: ${_students.length}');
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load students: ${response.statusCode}';
          print('StudentsPage: Error: $_errorMessage');
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching students: $e';
        print('StudentsPage: Exception: $e');
      });
    }
  }

  Future<void> deleteUser(String admissionNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/admin/delete_user/$admissionNumber');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _students.removeWhere(
              (student) => student['admission_number'] == admissionNumber);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to delete student: ${response.statusCode}';
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting student: $e';
      });
    }
  }

  Future<void> updateUser(String admissionNumber, String username, String email,
      String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/admin/update_user/$admissionNumber');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"username": username, "email": email, "role": role}),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
      } else {
        setState(() {
          _errorMessage = 'Failed to update student: ${response.statusCode}';
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating student: $e';
      });
    }
  }

  void showEditDialog(Map<String, dynamic> student) {
    TextEditingController usernameController =
        TextEditingController(text: student['username']);
    TextEditingController emailController =
        TextEditingController(text: student['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Student"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await updateUser(
                  student['admission_number'],
                  usernameController.text,
                  emailController.text,
                  'student',
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Students")),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _students.isEmpty
              ? const Center(child: Text("No students found"))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(student['username'] ?? 'Unknown'),
                      subtitle: Text("Email: ${student['email'] ?? 'N/A'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showEditDialog(student),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                deleteUser(student['admission_number']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
