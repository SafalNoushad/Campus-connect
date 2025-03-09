import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../screens/admin_dashboard.dart';

class DepartmentsPage extends StatefulWidget {
  @override
  _DepartmentsPageState createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  List<dynamic> _departments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url =
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Fetch Departments Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _departments = json.decode(response.body);
          _errorMessage = null;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _redirectToLogin();
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

  Future<void> createDepartment(String code, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url =
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'departmentcode': code,
          'departmentname': name,
        }),
      );

      if (response.statusCode == 201) {
        await fetchDepartments();
      } else {
        setState(() {
          _errorMessage = 'Failed to create department: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating department: $e';
      });
    }
  }

  Future<void> updateDepartment(int id, String code, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url =
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments/$id');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'departmentcode': code,
          'departmentname': name,
        }),
      );

      if (response.statusCode == 200) {
        await fetchDepartments();
      } else {
        setState(() {
          _errorMessage = 'Failed to update department: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating department: $e';
      });
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _redirectToLogin();
        return;
      }

      final url =
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments/$id');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _departments.removeWhere((dept) => dept['id'] == id);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to delete department: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting department: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void showCreateDialog() {
    TextEditingController codeController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Department"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Department Code"),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Department Name"),
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
                await createDepartment(
                    codeController.text, nameController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void showEditDialog(Map<String, dynamic> department) {
    TextEditingController codeController =
        TextEditingController(text: department['departmentcode']);
    TextEditingController nameController =
        TextEditingController(text: department['departmentname']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Department"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Department Code"),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Department Name"),
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
                await updateDepartment(
                    department['id'], codeController.text, nameController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Departments"),
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
            onPressed: showCreateDialog,
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _departments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _departments.length,
                  itemBuilder: (context, index) {
                    final department = _departments[index];
                    return ListTile(
                      leading: const Icon(Icons.domain),
                      title: Text(department['departmentname'] ?? 'Unknown'),
                      subtitle: Text(
                          "Code: ${department['departmentcode'] ?? 'N/A'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showEditDialog(department),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteDepartment(department['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
