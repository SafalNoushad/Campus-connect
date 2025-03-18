import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AcademicsPage extends StatefulWidget {
  const AcademicsPage({super.key});

  @override
  _AcademicsPageState createState() => _AcademicsPageState();
}

class _AcademicsPageState extends State<AcademicsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _semester;
  String? _subjectCode;
  String? _subjectName;
  int? _credits;
  List<Map<String, dynamic>> _subjects = [];
  final List<String> _semesters = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
    'S7',
    'S8'
  ];
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
        Uri.parse('http://localhost:5001/api/hod/subjects'),
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

  Future<void> _addSubject() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5001/api/hod/subjects'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: json.encode({
            'semester': _semester,
            'subject_code': _subjectCode,
            'subject_name': _subjectName,
            'credits': _credits,
          }),
        );
        if (response.statusCode == 201) {
          _fetchSubjects(); // Refresh the list
          _formKey.currentState!.reset();
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject added successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add subject: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subject: $e')),
        );
      }
    }
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _semester,
                  items: _semesters
                      .map((sem) =>
                          DropdownMenuItem(value: sem, child: Text(sem)))
                      .toList(),
                  onChanged: (value) => setState(() => _semester = value),
                  validator: (value) =>
                      value == null ? 'Please select a semester' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Subject Code',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a subject code' : null,
                  onSaved: (value) => _subjectCode = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a subject name' : null,
                  onSaved: (value) => _subjectName = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Credits',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty || int.tryParse(value) == null
                          ? 'Please enter valid credits'
                          : null,
                  onSaved: (value) => _credits = int.parse(value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addSubject,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSubjects(String semester) {
    final filteredSubjects =
        _subjects.where((subject) => subject['semester'] == semester).toList();
    return filteredSubjects.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No subjects added yet',
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
                        ListTile(
                          title: const Text('Add Subjects'),
                          leading: const Icon(Icons.add_circle_outline,
                              color: Colors.green),
                          onTap: _showAddSubjectDialog,
                        ),
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
