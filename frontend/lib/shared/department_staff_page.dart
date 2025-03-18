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
  List<Map<String, dynamic>> _departments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStaff();
    fetchDepartments();
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/department/staff'),
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
    String role = 'staff'; // Fixed to staff since this page is for staff only
    String? departmentcode = staff['departmentcode'];

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
                            await updateStaff(staff['admission_number'], {
                              'username': usernameController.text,
                              'email': emailController.text,
                              'phone_number': phoneController.text.isEmpty
                                  ? null
                                  : phoneController.text,
                              'role': role,
                              'batch': null, // No batch for staff
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
    return Colors.green; // Fixed to green for staff
  }

  IconData _getRoleIcon(String role) {
    return Icons.person; // Fixed to person icon for staff
  }

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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => showEditDialog(staff),
                                    tooltip: 'Edit Staff',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        deleteStaff(staff['admission_number']),
                                    tooltip: 'Delete Staff',
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
