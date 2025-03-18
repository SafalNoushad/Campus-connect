import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';

class StaffAcademicsPage extends StatefulWidget {
  const StaffAcademicsPage({super.key});

  @override
  _StaffAcademicsPageState createState() => _StaffAcademicsPageState();
}

class _StaffAcademicsPageState extends State<StaffAcademicsPage> {
  List<Map<String, dynamic>> _subjects = [];
  String? _token;
  String? _departmentCode;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _departmentCode = prefs.getString('departmentcode');
    });
    if (_token != null && _departmentCode != null) {
      _fetchSubjects();
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/subjects'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _subjects =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subjects: $e')),
      );
    }
  }

  Widget _buildSemesterSubjects(String semester) {
    final filteredSubjects =
        _subjects.where((subject) => subject['semester'] == semester).toList();
    return filteredSubjects.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No subjects available',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSubjects.length,
            itemBuilder: (context, index) {
              final subject = filteredSubjects[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    '${subject['subject_code']} - ${subject['subject_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Credits: ${subject['credits']}'),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      title: const Text(
                        'Syllabus',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      children: [
                        ExpansionTile(
                          title: const Text('1st Year'),
                          children: [
                            ExpansionTile(
                              title: const Text('Semester 1 (S1)'),
                              children: [_buildSemesterSubjects('S1')],
                            ),
                            ExpansionTile(
                              title: const Text('Semester 2 (S2)'),
                              children: [_buildSemesterSubjects('S2')],
                            ),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('2nd Year'),
                          children: [
                            ExpansionTile(
                              title: const Text('Semester 3 (S3)'),
                              children: [_buildSemesterSubjects('S3')],
                            ),
                            ExpansionTile(
                              title: const Text('Semester 4 (S4)'),
                              children: [_buildSemesterSubjects('S4')],
                            ),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('3rd Year'),
                          children: [
                            ExpansionTile(
                              title: const Text('Semester 5 (S5)'),
                              children: [_buildSemesterSubjects('S5')],
                            ),
                            ExpansionTile(
                              title: const Text('Semester 6 (S6)'),
                              children: [_buildSemesterSubjects('S6')],
                            ),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('4th Year'),
                          children: [
                            ExpansionTile(
                              title: const Text('Semester 7 (S7)'),
                              children: [_buildSemesterSubjects('S7')],
                            ),
                            ExpansionTile(
                              title: const Text('Semester 8 (S8)'),
                              children: [_buildSemesterSubjects('S8')],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
