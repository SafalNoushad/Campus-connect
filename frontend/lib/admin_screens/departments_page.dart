import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/network_config.dart';

class DepartmentPage extends StatefulWidget {
  const DepartmentPage({super.key});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    setState(() => _isLoading = true);
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

      print(
          'Fetch Departments Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);
        print('Fetched Departments: $fetchedData');
        setState(() {
          _departments = fetchedData.cast<Map<String, dynamic>>();
          _errorMessage = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = 'Admin access required to view departments.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch departments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching departments: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addDepartment(String code, String name) async {
    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department code and name are required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print('No JWT token found, redirecting to login');
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/departments/departments');
      print('Adding department at: $url with code: $code, name: $name');
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

      print(
          'Add Department Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          _departments.add({'departmentcode': code, 'departmentname': name});
          _errorMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department added successfully')),
          );
        }
      } else {
        String errorMsg;
        if (response.statusCode == 400) {
          errorMsg = 'Missing department code or name.';
        } else if (response.statusCode == 403) {
          errorMsg = 'Admin access required to add departments.';
        } else if (response.statusCode == 409) {
          errorMsg = 'Department code $code already exists.';
        } else {
          errorMsg =
              'Failed to add department: ${response.statusCode} - ${response.body}';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
        print('Add error: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      String errorMsg = 'Error adding department: $e';
      setState(() {
        _errorMessage = errorMsg;
      });
      print('Add exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateDepartment(
      String departmentcode, String code, String name) async {
    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department code and name are required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print('No JWT token found, redirecting to login');
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/departments/departments/$departmentcode');
      print(
          'Updating department at: $url with original code: $departmentcode, new code: $code, name: $name');
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

      print(
          'Update Department Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          final index = _departments
              .indexWhere((dept) => dept['departmentcode'] == departmentcode);
          if (index != -1) {
            _departments[index] = {
              'departmentcode': code,
              'departmentname': name
            };
          }
          _errorMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department updated successfully')),
          );
        }
      } else {
        String errorMsg;
        if (response.statusCode == 400) {
          errorMsg = 'Missing department code or name.';
        } else if (response.statusCode == 403) {
          errorMsg = 'Admin access required to update departments.';
        } else if (response.statusCode == 404) {
          errorMsg = 'Department $departmentcode not found on server.';
          await fetchDepartments();
        } else if (response.statusCode == 409) {
          errorMsg = 'New department code $code already exists.';
        } else {
          errorMsg =
              'Failed to update department: ${response.statusCode} - ${response.body}';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
        print('Update error: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      String errorMsg = 'Error updating department: $e';
      setState(() {
        _errorMessage = errorMsg;
      });
      print('Update exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteDepartment(String departmentcode) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print('No JWT token found, redirecting to login');
        _redirectToLogin();
        return;
      }

      final url = Uri.parse(
          '${NetworkConfig.getBaseUrl()}/api/departments/departments/$departmentcode');
      print('Deleting department at: $url with code: $departmentcode');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Delete Department Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _departments
              .removeWhere((dept) => dept['departmentcode'] == departmentcode);
          _errorMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department deleted successfully')),
          );
        }
      } else {
        String errorMsg;
        if (response.statusCode == 403) {
          errorMsg = 'Admin access required to delete departments.';
        } else if (response.statusCode == 404) {
          errorMsg = 'Department $departmentcode not found on server.';
          await fetchDepartments();
        } else {
          errorMsg =
              'Failed to delete department: ${response.statusCode} - ${response.body}';
        }
        setState(() {
          _errorMessage = errorMsg;
        });
        print('Delete error: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      String errorMsg = 'Error deleting department: $e';
      setState(() {
        _errorMessage = errorMsg;
      });
      print('Delete exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
            tooltip: 'Add Department',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
              ? const Center(child: Text('No departments available'))
              : Column(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _departments.length,
                        itemBuilder: (context, index) {
                          final dept = _departments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            elevation: 2,
                            child: ListTile(
                              title: Text(
                                dept['departmentname'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Code: ${dept['departmentcode']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _showUpdateDialog(
                                        dept['departmentcode'],
                                        dept['departmentname']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(
                                        dept['departmentcode']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showAddDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    String? codeError;
    String? nameError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.add_circle, color: Color(0xFF0C6170)),
                  const SizedBox(width: 8),
                  Text(
                    'Add Department',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300, // Wider dialog for better usability
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'Department Code',
                        hintText: 'e.g., CS',
                        labelStyle: const TextStyle(color: Color(0xFF0C6170)),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                              color: Color(0xFF0C6170), width: 2),
                        ),
                        errorText: codeError,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          codeError = value.isEmpty ? 'Code is required' : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Department Name',
                        hintText: 'e.g., Computer Science',
                        labelStyle: const TextStyle(color: Color(0xFF0C6170)),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                              color: Color(0xFF0C6170), width: 2),
                        ),
                        errorText: nameError,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          nameError = value.isEmpty ? 'Name is required' : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: (codeError == null &&
                          nameError == null &&
                          codeController.text.isNotEmpty &&
                          nameController.text.isNotEmpty)
                      ? () {
                          Navigator.pop(context);
                          addDepartment(codeController.text.trim(),
                              nameController.text.trim());
                        }
                      : null, // Disabled if validation fails
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C6170),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdateDialog(String currentCode, String currentName) {
    final codeController = TextEditingController(text: currentCode);
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Department Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateDepartment(
                  currentCode,
                  codeController.text.trim(),
                  nameController.text.trim(),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String departmentcode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text('Are you sure you want to delete $departmentcode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                deleteDepartment(departmentcode);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
