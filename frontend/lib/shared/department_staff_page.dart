import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../hod_screens/hod_dashboard.dart';

class DepartmentStaffPage extends StatefulWidget {
  const DepartmentStaffPage({super.key});

  @override
  _DepartmentStaffPageState createState() => _DepartmentStaffPageState();
}

class _DepartmentStaffPageState extends State<DepartmentStaffPage> {
  List<Map<String, dynamic>> _staff = [];
  String? _departmentCode; // HOD's department from JWT
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStaff();
    fetchUserDepartment(); // Get HOD's department
  }

  Future<void> fetchStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/staff/list'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _staff = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load staff: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching staff: $e';
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

      // Decode JWT to get departmentcode (assuming it's in the token)
      final parts = token.split('.');
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

  Future<void> updateStaff(
      String admissionNumber, Map<String, dynamic> staffData) async {
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
        body: jsonEncode(staffData),
      );

      if (response.statusCode == 200) {
        await fetchStaff();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff updated successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update staff: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating staff: $e';
      });
    }
  }

  Future<void> deleteStaff(String admissionNumber) async {
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
        await fetchStaff();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff deleted successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to delete staff: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting staff: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void showEditDialog(Map<String, dynamic> staff) {
    TextEditingController usernameController =
        TextEditingController(text: staff['username']);
    TextEditingController emailController =
        TextEditingController(text: staff['email']);
    TextEditingController phoneController =
        TextEditingController(text: staff['phone_number'] ?? '');
    String role = 'staff';

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
                    const Text("Edit Staff",
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
                        await updateStaff(staff['admission_number'], {
                          'username': usernameController.text,
                          'email': emailController.text,
                          'phone_number': phoneController.text.isEmpty
                              ? null
                              : phoneController.text,
                          'role': role,
                          'departmentcode':
                              _departmentCode, // Use HOD's department
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

  Color _getRoleColor(String role) => Colors.green;
  IconData _getRoleIcon(String role) => Icons.person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Department Staff"),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HodDashboard()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text("Add staff functionality not implemented yet")),
              );
            },
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)))
          : _staff.isEmpty
              ? const Center(child: Text("No staff found in this department"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _staff.length,
                    itemBuilder: (context, index) {
                      final staff = _staff[index];
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
                                backgroundColor: _getRoleColor(staff['role']),
                                child: Icon(_getRoleIcon(staff['role']),
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Email: ${staff['email'] ?? 'N/A'}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                    ),
                                    Text(
                                      "Role: STAFF",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _getRoleColor(staff['role']),
                                        fontWeight: FontWeight.w500,
                                      ),
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
