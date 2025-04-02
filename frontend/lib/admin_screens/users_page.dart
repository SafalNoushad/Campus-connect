import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  Map<String, Map<String, List<Map<String, dynamic>>>> _departmentUsers = {};
  List<Map<String, dynamic>> _departments = [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _redirectToLogin();
        return;
      }

      // Fetch departments
      final deptResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (deptResponse.statusCode == 200) {
        _departments =
            List<Map<String, dynamic>>.from(jsonDecode(deptResponse.body));
      } else if (deptResponse.statusCode == 401) {
        _handleTokenExpiration();
        return;
      } else {
        setState(() {
          _errorMessage =
              'Failed to load departments: ${deptResponse.statusCode} - ${deptResponse.body}';
        });
      }

      // Fetch users grouped by department
      final usersResponse = await http.get(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/users_by_department'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (usersResponse.statusCode == 200) {
        setState(() {
          _departmentUsers =
              Map<String, Map<String, List<Map<String, dynamic>>>>.from(
            jsonDecode(usersResponse.body).map(
              (key, value) => MapEntry(
                key,
                {
                  'staff': List<Map<String, dynamic>>.from(value['staff']),
                  'students':
                      List<Map<String, dynamic>>.from(value['students']),
                },
              ),
            ),
          );
          _errorMessage = null;
        });
      } else if (usersResponse.statusCode == 401) {
        _handleTokenExpiration();
        return;
      } else {
        setState(() {
          _errorMessage =
              'Failed to load users: ${usersResponse.statusCode} - ${usersResponse.body}';
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

  Future<void> _addUser(Map<String, dynamic> userData) async {
    setState(() => _isLoadingAction = true);
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
        await _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
      } else if (response.statusCode == 401) {
        _handleTokenExpiration();
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'Failed to add user: ${error['error'] ?? response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding user: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _updateUser(
      String admissionNumber, Map<String, dynamic> userData) async {
    setState(() => _isLoadingAction = true);
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
        await _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      } else if (response.statusCode == 401) {
        _handleTokenExpiration();
      } else {
        setState(() {
          _errorMessage =
              'Failed to update user: ${response.statusCode} - ${response.body}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _deleteUser(String admissionNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoadingAction = true);
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
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Delete Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } else if (response.statusCode == 401) {
        _handleTokenExpiration();
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'Failed to delete user: ${error['error'] ?? response.statusCode} - ${response.body}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting user: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _handleTokenExpiration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please log in again.')),
    );
    SharedPreferences.getInstance().then((prefs) => prefs.remove('jwt_token'));
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final admissionNumberController =
        TextEditingController(text: user?['admission_number'] ?? '');
    final usernameController =
        TextEditingController(text: user?['username'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    final phoneController =
        TextEditingController(text: user?['phone_number'] ?? '');
    final batchController = TextEditingController(text: user?['batch'] ?? '');
    String? role = user?['role'] ?? 'student';
    String? departmentcode = user?['departmentcode'];
    String? semester = user?['semester'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.95,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user == null ? 'Add New User' : 'Edit User',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    TextField(
                      controller: admissionNumberController,
                      decoration:
                          _inputDecoration('Admission Number', Icons.badge),
                      enabled: user == null,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usernameController,
                      decoration:
                          _inputDecoration('Username', Icons.person_outline),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      decoration:
                          _inputDecoration('Email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 6),
                    if (user == null)
                      TextField(
                        controller: passwordController,
                        decoration: _inputDecoration('Password', Icons.lock),
                        obscureText: true,
                      ),
                    if (user == null) const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      decoration: _inputDecoration(
                          'Phone Number (Optional)', Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: ['student', 'staff', 'hod']
                          .map((r) => DropdownMenuItem(
                              value: r, child: Text(r.toUpperCase())))
                          .toList(),
                      onChanged: (value) => setDialogState(() {
                        role = value;
                        if (role != 'student') {
                          semester = null;
                          batchController.clear();
                        }
                      }),
                      decoration: _inputDecoration('Role', Icons.person),
                    ),
                    if (role == 'student') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: batchController,
                        decoration: _inputDecoration(
                            'Batch (e.g., 2021-2025)', Icons.calendar_today),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: semester,
                        items: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => semester = value),
                        decoration: _inputDecoration('Semester', Icons.numbers),
                      ),
                    ],
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: departmentcode,
                      items: _departments
                          .map((dept) => DropdownMenuItem<String>(
                                value: dept['departmentcode'].toString(),
                                child: Text(dept['departmentname']),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => departmentcode = value),
                      decoration: _inputDecoration('Department', Icons.domain),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () async {
                            if (admissionNumberController.text.isEmpty ||
                                usernameController.text.isEmpty ||
                                emailController.text.isEmpty ||
                                (user == null &&
                                    passwordController.text.isEmpty) ||
                                role == null ||
                                departmentcode == null ||
                                (role == 'student' &&
                                    (batchController.text.isEmpty ||
                                        semester == null))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please fill all required fields')),
                              );
                              return;
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(emailController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter a valid email')),
                              );
                              return;
                            }
                            if (phoneController.text.isNotEmpty &&
                                phoneController.text.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Phone number must be at least 10 digits')),
                              );
                              return;
                            }
                            final userData = {
                              'admission_number':
                                  admissionNumberController.text,
                              'username': usernameController.text,
                              'email': emailController.text,
                              if (user == null)
                                'password': passwordController.text,
                              'role': role,
                              'departmentcode': departmentcode,
                              'phone_number': phoneController.text.isEmpty
                                  ? null
                                  : phoneController.text,
                              if (role == 'student')
                                'batch': batchController.text,
                              if (role == 'student') 'semester': semester,
                            };
                            if (user == null) {
                              await _addUser(userData);
                            } else {
                              await _updateUser(
                                  user['admission_number'], userData);
                            }
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(user == null ? 'Add' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Manage Users'),
            backgroundColor: Theme.of(context).primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _isLoadingAction ? null : () => _showUserDialog(),
                tooltip: 'Add User',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _departmentUsers.isEmpty
                  ? const Center(child: Text('No users available'))
                  : Column(
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _departmentUsers.keys.length,
                            itemBuilder: (context, index) {
                              final deptCode =
                                  _departmentUsers.keys.elementAt(index);
                              final deptName = _departments.firstWhere((d) =>
                                  d['departmentcode'] ==
                                  deptCode)['departmentname'];
                              return ExpansionTile(
                                title: Text(deptName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                children: [
                                  ListTile(
                                    title: const Text('Staff (including HODs)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle:
                                        _departmentUsers[deptCode]!['staff']!
                                                .isEmpty
                                            ? const Text('No staff available')
                                            : Column(
                                                children: _departmentUsers[
                                                        deptCode]!['staff']!
                                                    .map((user) =>
                                                        _buildUserTile(user))
                                                    .toList(),
                                              ),
                                  ),
                                  ListTile(
                                    title: const Text('Students',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: _departmentUsers[deptCode]![
                                                'students']!
                                            .isEmpty
                                        ? const Text('No students available')
                                        : Column(
                                            children: _departmentUsers[
                                                    deptCode]!['students']!
                                                .map((user) =>
                                                    _buildUserTile(user))
                                                .toList(),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
        if (_isLoadingAction) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            user['username']?[0].toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user['username'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user['email'] ?? 'N/A'}'),
            Text('Role: ${user['role'].toUpperCase()}'),
            if (user['batch'] != null) Text('Batch: ${user['batch']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed:
                  _isLoadingAction ? null : () => _showUserDialog(user: user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoadingAction
                  ? null
                  : () => _deleteUser(user['admission_number']),
            ),
          ],
        ),
      ),
    );
  }
}
