import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/network_config.dart';
import '../screens/admin_dashboard.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  List<dynamic> _departments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchDepartments();
  }

  Future<void> fetchUsers() async {
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
        setState(() {
          _users = json.decode(response.body);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load users: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching users: $e';
      });
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/departments/departments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _departments = json.decode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load departments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching departments: $e';
      });
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.post(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/register_user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to register user: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error registering user: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void showRegisterDialog() {
    TextEditingController admissionController = TextEditingController();
    TextEditingController usernameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController batchController = TextEditingController();
    String role = 'student';
    String? departmentcode =
        _departments.isNotEmpty ? _departments[0]['departmentcode'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Register User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: admissionController,
                      decoration:
                          const InputDecoration(labelText: "Admission Number"),
                    ),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: "Username"),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                          labelText: "Phone Number (Optional)"),
                    ),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ['admin', 'hod', 'staff', 'student']
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          role = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: "Role"),
                    ),
                    if (role == 'student')
                      TextField(
                        controller: batchController,
                        decoration: const InputDecoration(
                            labelText: "Batch (e.g., 2021-2025)"),
                      ),
                    _departments.isEmpty
                        ? const Text("Loading departments...",
                            style: TextStyle(color: Colors.grey))
                        : DropdownButtonFormField<String>(
                            value: departmentcode,
                            items: _departments.map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept['departmentcode'],
                                child: Text(dept['departmentname']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                departmentcode = value;
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: "Department"),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (admissionController.text.isEmpty ||
                        usernameController.text.isEmpty ||
                        departmentcode == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please fill all required fields")),
                      );
                      return;
                    }
                    await registerUser({
                      'admission_number': admissionController.text,
                      'username': usernameController.text,
                      'phone_number': phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      'role': role,
                      'batch': role == 'student' ? batchController.text : null,
                      'departmentcode': departmentcode,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Register"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showRegisterDialog,
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: Icon(
                        user['role'] == 'student' ? Icons.school : Icons.person,
                      ),
                      title: Text(user['username'] ?? 'Unknown'),
                      subtitle: Text(
                        "Email: ${user['email'] ?? 'N/A'}\nRole: ${user['role']}\nBatch: ${user['batch'] ?? 'N/A'}",
                      ),
                    );
                  },
                ),
    );
  }
}
