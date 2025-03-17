import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/admin_dashboard.dart'; // Replace with your actual admin dashboard path
import '../utils/network_config.dart'; // Replace with your actual network config path

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _departments = [];
  String? _errorMessage;
  bool _isLoadingDepartments = true; // Added to track department loading state

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchDepartments().then((_) {
      setState(() {
        _isLoadingDepartments = false; // Update loading state when done
      });
    });
  }

  // Fetch all users from the backend and filter out admins
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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(jsonDecode(response.body))
              .where((user) => user['role'] != 'admin')
              .toList();
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

  // Fetch departments for the dropdown
  // Fetch departments for the dropdown
  Future<void> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/departments/departments');
      print('Fetching departments from: $url'); // Log URL
      print('Using token: $token'); // Log token

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print(
          'Departments Response: ${response.statusCode} - ${response.body}'); // Log response

      if (response.statusCode == 200) {
        setState(() {
          _departments =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _errorMessage =
              _departments.isEmpty ? 'No departments available' : null;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load departments: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching departments: $e';
      });
    }
  }

  // Update a user's details
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
          const SnackBar(content: Text('User updated successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to update user: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user: $e';
      });
    }
  }

  // Delete a user
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
          const SnackBar(content: Text('User deleted successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to delete user: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting user: $e';
      });
    }
  }

  // Add a new user
  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      final response = await http.post(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/add_user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to add user: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding user: $e';
      });
    }
  }

  // Redirect to login if token is missing
  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Show dialog to edit user details with enhanced UI
  void showEditDialog(Map<String, dynamic> user) {
    TextEditingController usernameController =
        TextEditingController(text: user['username']);
    TextEditingController emailController =
        TextEditingController(text: user['email']);
    TextEditingController phoneController =
        TextEditingController(text: user['phone_number'] ?? '');
    TextEditingController batchController =
        TextEditingController(text: user['batch'] ?? '');
    String role = user['role'];
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
                        const Text(
                          "Edit User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ['hod', 'staff', 'student']
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          role = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Role",
                        prefixIcon: Icon(_getRoleIcon(role)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    if (role == 'student') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: batchController,
                        decoration: InputDecoration(
                          labelText: "Batch (e.g., 2021-2025)",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _departments.isEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Failed to load departments",
                                style: TextStyle(color: Colors.red),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    _isLoadingDepartments = true;
                                  });
                                  fetchDepartments().then((_) {
                                    setDialogState(() {
                                      _isLoadingDepartments = false;
                                    });
                                  });
                                },
                                child: const Text("Retry"),
                              ),
                            ],
                          )
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
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              'batch': role == 'student'
                                  ? batchController.text
                                  : null,
                              'departmentcode': departmentcode,
                            });
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  // Show dialog to add a new user
  void showAddUserDialog() async {
    // Ensure departments are loaded before showing the dialog
    if (_departments.isEmpty && _isLoadingDepartments) {
      await fetchDepartments();
      setState(() {
        _isLoadingDepartments = false;
      });
    }

    TextEditingController admissionNumberController = TextEditingController();
    TextEditingController usernameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController batchController = TextEditingController();
    String role = 'student'; // Default role
    String? departmentcode;

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
                        const Text(
                          "Add New User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: admissionNumberController,
                      decoration: InputDecoration(
                        labelText: "Admission Number",
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ['hod', 'staff', 'student']
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          role = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Role",
                        prefixIcon: Icon(_getRoleIcon(role)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    if (role == 'student') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: batchController,
                        decoration: InputDecoration(
                          labelText: "Batch (e.g., 2021-2025)",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _isLoadingDepartments
                        ? const Center(child: CircularProgressIndicator())
                        : _departments.isEmpty
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Failed to load departments",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        _isLoadingDepartments = true;
                                      });
                                      fetchDepartments().then((_) {
                                        setDialogState(() {
                                          _isLoadingDepartments = false;
                                        });
                                      });
                                    },
                                    child: const Text("Retry"),
                                  ),
                                ],
                              )
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                          onPressed: _isLoadingDepartments
                              ? null
                              : () async {
                                  if (admissionNumberController.text.isEmpty ||
                                      usernameController.text.isEmpty ||
                                      emailController.text.isEmpty ||
                                      passwordController.text.isEmpty ||
                                      departmentcode == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Please fill all required fields")),
                                    );
                                    return;
                                  }
                                  await addUser({
                                    'admission_number':
                                        admissionNumberController.text,
                                    'username': usernameController.text,
                                    'email': emailController.text,
                                    'phone_number': phoneController.text.isEmpty
                                        ? null
                                        : phoneController.text,
                                    'password': passwordController.text,
                                    'role': role,
                                    'batch': role == 'student'
                                        ? batchController.text
                                        : null,
                                    'departmentcode': departmentcode,
                                  });
                                  Navigator.pop(dialogContext);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Add",
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

  // Helper method to get role-specific color
  Color _getRoleColor(String role) {
    switch (role) {
      case 'hod':
        return Colors.blueAccent;
      case 'staff':
        return Colors.green;
      case 'student':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get role-specific icon
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'hod':
        return Icons.supervisor_account;
      case 'staff':
        return Icons.person;
      case 'student':
        return Icons.school;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddUserDialog(),
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)))
          : _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Icon(
                                  _getRoleIcon(user['role']),
                                  color: Colors.white,
                                ),
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Email: ${user['email'] ?? 'N/A'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      "Role: ${user['role'].toUpperCase()}",
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
                                          color: Colors.grey[700],
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
                                    onPressed: () => showEditDialog(user),
                                    tooltip: 'Edit User',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        deleteUser(user['admission_number']),
                                    tooltip: 'Delete User',
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
