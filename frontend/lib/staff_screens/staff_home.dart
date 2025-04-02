import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';
import '../shared/department_users_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class StaffHome extends StatelessWidget {
  final String username;

  const StaffHome({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Welcome, $username!",
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DepartmentUsersPage(isStaffView: true),
                ),
              );
            },
            icon: const Icon(Icons.school),
            label: const Text("View Department Students"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Timetable feature coming soon!")),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text("View Timetable"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StaffAssignmentsPage(username: username),
                ),
              );
            },
            icon: const Icon(Icons.assignment),
            label: const Text("Manage Assignments"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffAssignmentsPage extends StatefulWidget {
  final String username;

  const StaffAssignmentsPage({super.key, required this.username});

  @override
  _StaffAssignmentsPageState createState() => _StaffAssignmentsPageState();
}

class _StaffAssignmentsPageState extends State<StaffAssignmentsPage> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchAssignments();
  }

  Future<void> _loadTokenAndFetchAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      print('JWT Token: $_token'); // Debug JWT token
    });
    if (_token != null) {
      _fetchAssignments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAssignments() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/assignments'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Assignments Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(data['assignments']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load assignments: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching assignments: $e')),
      );
    }
  }

  Future<void> _downloadAssignment(String filename) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/staff/assignments/download/$filename'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Download Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        print('Download Directory: ${dir.path}');
        final filePath = '${dir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded to $filePath')),
        );
        OpenFile.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: ${response.body}')),
        );
      }
    } catch (e, stackTrace) {
      print('Error downloading file: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(
                  child: Text(
                    'No assignments found for you yet.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    return ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.grey),
                      title: Text(
                          'Assignment ${assignment['assignment_number']} - ${assignment['subject_code']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Staff: ${assignment['staff_name']}'),
                          Text(
                              'Submitted By: ${assignment['submitted_by'] ?? 'Not Submitted'}'),
                          if (assignment['submitted_at'] != null)
                            Text(
                                'Submitted At: ${assignment['submitted_at'].substring(0, 10)}'),
                        ],
                      ),
                      trailing: assignment['submission_filename'] != null
                          ? IconButton(
                              icon: const Icon(Icons.download,
                                  color: Colors.blue),
                              onPressed: () => _downloadAssignment(
                                  assignment['submission_filename']),
                            )
                          : null,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Assignment Details'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${assignment['id']}'),
                                  Text(
                                      'Subject Code: ${assignment['subject_code']}'),
                                  Text(
                                      'Staff Name: ${assignment['staff_name']}'),
                                  Text(
                                      'Assignment Number: ${assignment['assignment_number']}'),
                                  Text(
                                      'Instructor ID: ${assignment['instructor_id']}'),
                                  Text(
                                      'Department Code: ${assignment['departmentcode']}'),
                                  Text(
                                      'Created At: ${assignment['created_at'].substring(0, 10)}'),
                                  Text(
                                      'Submitted: ${assignment['submitted_by'] != null ? 'Yes' : 'No'}'),
                                  if (assignment['submitted_by'] != null) ...[
                                    Text(
                                        'Submitted By: ${assignment['submitted_by']}'),
                                    Text(
                                        'Submitted At: ${assignment['submitted_at'].substring(0, 10)}'),
                                    Text(
                                        'File: ${assignment['submission_filename']}'),
                                  ],
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
