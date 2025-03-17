import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../staff_screens/staff_dashboard.dart';
import '../hod_screens/hod_dashboard.dart';

class DepartmentUsersPage extends StatefulWidget {
  final bool isStaffView; // Controls edit/delete visibility

  const DepartmentUsersPage({
    super.key,
    required this.isStaffView,
  });

  @override
  _DepartmentUsersPageState createState() => _DepartmentUsersPageState();
}

class _DepartmentUsersPageState extends State<DepartmentUsersPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _departments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    if (!widget.isStaffView)
      fetchDepartments(); // Only fetch departments for HOD
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final String endpoint = widget.isStaffView
          ? '/api/staff/department/users'
          : '/api/hod/department/users';

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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _departments =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
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
    String role =
        'student'; // Fixed to student since this page is for students only
    String? departmentcode = user['departmentcode'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Container(
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
                    const SizedBox(height: 12),
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
                            decoration: InputDecoration(
                              labelText: "Department",
                              prefixIcon: const Icon(Icons.domain),
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
                                emailController.text.isEmpty ||
                                departmentcode == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please fill all required fields")),
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
                              'departmentcode': departmentcode,
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
              );
            },
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    return Colors.orange; // Fixed to orange for students
  }

  IconData _getRoleIcon(String role) {
    return Icons.school; // Fixed to school icon for students
  }

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
        actions: widget.isStaffView
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Add student functionality not implemented yet")),
                    );
                  },
                ),
              ],
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
                              widget.isStaffView
                                  ? const SizedBox.shrink()
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => showEditDialog(user),
                                          tooltip: 'Edit Student',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => deleteUser(
                                              user['admission_number']),
                                          tooltip: 'Delete Student',
                                        ),
                                      ],
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
