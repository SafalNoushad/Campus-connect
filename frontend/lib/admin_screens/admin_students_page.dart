import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  _AdminStudentsPageState createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  List<dynamic> _students = [];
  dynamic _searchedStudent;
  String _searchQuery = '';
  String? _selectedBatch;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
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
        final allUsers = json.decode(response.body);
        setState(() {
          _students =
              allUsers.where((user) => user['role'] == 'student').toList();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load students: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching students: $e';
      });
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _searchStudent() {
    setState(() {
      _searchedStudent = null;
      if (_searchQuery.isNotEmpty) {
        _searchedStudent = _students.firstWhere(
          (student) =>
              (student['username']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  student['admission_number']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) &&
              (_selectedBatch == null || student['batch'] == _selectedBatch),
          orElse: () => null,
        );
      }
    });
  }

  List<String> _getBatchOptions() {
    return _students
        .map((student) => student['batch'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Name or Admission Number',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _searchStudent();
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedBatch,
            hint: const Text('Filter by Batch'),
            items: _getBatchOptions().map((batch) {
              return DropdownMenuItem<String>(value: batch, child: Text(batch));
            }).toList()
              ..add(const DropdownMenuItem<String>(
                  value: null, child: Text('All Batches'))),
            onChanged: (value) {
              _selectedBatch = value;
              _searchStudent();
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _searchQuery.isEmpty
                        ? const Center(
                            child:
                                Text('Enter a search query to find a student'))
                        : _searchedStudent == null
                            ? const Center(child: Text('No student found'))
                            : Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.school,
                                              size: 30,
                                              color: Color(0xFF0C6170)),
                                          const SizedBox(width: 10),
                                          Text(
                                            _searchedStudent['username'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      _buildDetailRow('Admission No:',
                                          _searchedStudent['admission_number']),
                                      _buildDetailRow('Email:',
                                          _searchedStudent['email'] ?? 'N/A'),
                                      _buildDetailRow('Batch:',
                                          _searchedStudent['batch'] ?? 'N/A'),
                                      _buildDetailRow(
                                          'Department:',
                                          _searchedStudent['departmentcode'] ??
                                              'N/A'),
                                      _buildDetailRow(
                                          'Phone:',
                                          _searchedStudent['phone_number'] ??
                                              'N/A'),
                                    ],
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
