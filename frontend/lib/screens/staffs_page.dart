import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';

class StaffsPage extends StatefulWidget {
  @override
  _StaffsPageState createState() => _StaffsPageState();
}

class _StaffsPageState extends State<StaffsPage> {
  List<dynamic> _teachers = [];
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
      print('StaffsPage: Token = $token');
      if (token == null) {
        print('StaffsPage: No token found, redirecting to login');
        _redirectToLogin();
        return;
      }

      final url = Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/users');
      print('StaffsPage: Full URL = $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('StaffsPage: Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        print('StaffsPage: Users fetched: ${users.length}');
        setState(() {
          _teachers = users.where((user) => user['role'] == 'teacher').toList();
          _errorMessage = null;
          print('StaffsPage: Teachers filtered: ${_teachers.length}');
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load teachers: ${response.statusCode}';
          print('StaffsPage: Error: $_errorMessage');
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching teachers: $e';
        print('StaffsPage: Exception: $e');
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
          _teachers.removeWhere(
              (teacher) => teacher['admission_number'] == admissionNumber);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to delete teacher: ${response.statusCode}';
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting teacher: $e';
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
          _errorMessage = 'Failed to update teacher: ${response.statusCode}';
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating teacher: $e';
      });
    }
  }

  void showEditDialog(Map<String, dynamic> teacher) {
    TextEditingController usernameController =
        TextEditingController(text: teacher['username']);
    TextEditingController emailController =
        TextEditingController(text: teacher['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Teacher"),
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
                  teacher['admission_number'],
                  usernameController.text,
                  emailController.text,
                  'teacher',
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
      appBar: AppBar(title: const Text("Teachers")),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _teachers.isEmpty
              ? const Center(child: Text("No teachers found"))
              : ListView.builder(
                  itemCount: _teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _teachers[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(teacher['username'] ?? 'Unknown'),
                      subtitle: Text("Email: ${teacher['email'] ?? 'N/A'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showEditDialog(teacher),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                deleteUser(teacher['admission_number']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
