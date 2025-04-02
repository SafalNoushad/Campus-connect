import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../staff_screens/staff_dashboard.dart';
import '../hod_screens/hod_dashboard.dart';

class DepartmentUsersPage extends StatefulWidget {
  final bool isStaffView;

  const DepartmentUsersPage({
    super.key,
    required this.isStaffView,
  });

  @override
  _DepartmentUsersPageState createState() => _DepartmentUsersPageState();
}

class _DepartmentUsersPageState extends State<DepartmentUsersPage> {
  List<Map<String, dynamic>> _users = [];
  String? _departmentCode; // HOD's department from JWT
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    if (!widget.isStaffView) fetchUserDepartment(); // Only for HOD
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final String role = widget.isStaffView ? 'staff' : 'hod';
      final String endpoint = '/api/$role/department/users';
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load students: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching students: $e';
      });
    }
  }

  Future<void> fetchUserDepartment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      // Decode JWT to get departmentcode
      final parts = token!.split('.');
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      setState(() {
        _departmentCode = payload['departmentcode'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching department: $e';
      });
    }
  }

  Future<void> updateUser(
      String admissionNumber, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.put(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/update_user/$admissionNumber'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update student: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating student: $e';
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

      final response = await http.delete(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/delete_user/$admissionNumber'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to delete student: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting student: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void showEditDialog(Map<String, dynamic> user) {
    TextEditingController usernameController =
        TextEditingController(text: user['username']);
    TextEditingController emailController =
        TextEditingController(text: user['email']);
    TextEditingController phoneController =
        TextEditingController(text: user['phone_number'] ?? '');
    TextEditingController batchController =
        TextEditingController(text: user['batch'] ?? '');
    String role = 'student';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Edit Student",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone Number (Optional)",
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchController,
                  decoration: InputDecoration(
                    labelText: "Batch (e.g., 2021-2025)",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (usernameController.text.isEmpty ||
                            emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Please fill all required fields")),
                          );
                          return;
                        }
                        await updateUser(user['admission_number'], {
                          'username': usernameController.text,
                          'email': emailController.text,
                          'phone_number': phoneController.text.isEmpty
                              ? null
                              : phoneController.text,
                          'role': role,
                          'batch': batchController.text,
                          'departmentcode': _departmentCode,
                        });
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) => Colors.orange;
  IconData _getRoleIcon(String role) => Icons.school;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStaffView
            ? "Department Students"
            : "Manage Department Students"),
        backgroundColor: widget.isStaffView ? Colors.green : Colors.blueAccent,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => widget.isStaffView
                    ? const StaffDashboard()
                    : const HodDashboard(),
              ),
            );
          },
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)))
          : _users.isEmpty
              ? const Center(
                  child: Text("No students found in this department"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Icon(_getRoleIcon(user['role']),
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Email: ${user['email'] ?? 'N/A'}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                    ),
                                    Text(
                                      "Role: STUDENT",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _getRoleColor(user['role']),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (user['batch'] != null)
                                      Text(
                                        "Batch: ${user['batch']}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700]),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
