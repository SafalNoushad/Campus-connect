import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';

class AdminAcademicsPage extends StatefulWidget {
  const AdminAcademicsPage({super.key});

  @override
  AdminAcademicsPageState createState() => AdminAcademicsPageState();
}

class AdminAcademicsPageState extends State<AdminAcademicsPage> {
  List<Map<String, dynamic>> _subjects = [];
  Map<String, List<Map<String, dynamic>>> _timetableEntries = {};
  Map<String, List<Map<String, dynamic>>> _notes = {};
  List<Map<String, dynamic>> _departments = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
    });
    if (_token != null) {
      await _fetchDepartments();
      await _fetchSubjects();
      await _fetchTimetable();
      await _fetchNotes();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _departments =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load departments: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching departments: $e')),
      );
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/subjects'),
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

  Future<void> _fetchTimetable() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/timetable'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _timetableEntries = Map<String, List<Map<String, dynamic>>>.from(json
              .decode(response.body)
              .map((key, value) =>
                  MapEntry(key, List<Map<String, dynamic>>.from(value))));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load timetable: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching timetable: $e')),
      );
    }
  }

  Future<void> _fetchNotes() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/notes'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _notes = Map<String, List<Map<String, dynamic>>>.from(json
              .decode(response.body)
              .map((key, value) =>
                  MapEntry(key, List<Map<String, dynamic>>.from(value))));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notes: $e')),
      );
    }
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => SubjectFormDialog(
        token: _token!,
        departments: _departments,
        onSubjectAdded: _fetchSubjects,
      ),
    );
  }

  Future<void> _editSubject(String subjectCode) async {
    final subject =
        _subjects.firstWhere((s) => s['subject_code'] == subjectCode);
    showDialog(
      context: context,
      builder: (context) => SubjectFormDialog(
        token: _token!,
        departments: _departments,
        onSubjectAdded: _fetchSubjects,
        initialSubject: subject,
      ),
    );
  }

  Future<void> _deleteSubject(String subjectCode) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/subjects/$subjectCode'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await _fetchSubjects();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete subject: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting subject: $e')),
      );
    }
  }

  Future<void> _deleteTimetable(int timetableId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/timetable/$timetableId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await _fetchTimetable();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete timetable: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting timetable: $e')),
      );
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/notes/$noteId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await _fetchNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  Widget _buildDepartmentSubjects(String departmentCode) {
    final filteredSubjects = _subjects
        .where((subject) => subject['departmentcode'] == departmentCode)
        .toList();
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
                  subtitle: Text(
                      'Semester: ${subject['semester']} | Credits: ${subject['credits']} | Instructor: ${subject['instructor_id'] ?? 'None'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _editSubject(subject['subject_code']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteSubject(subject['subject_code']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildDepartmentTimetable(String departmentCode) {
    final filteredEntries = _timetableEntries[departmentCode] ?? [];
    return filteredEntries.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No timetable uploaded yet',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredEntries.length,
            itemBuilder: (context, index) {
              final entry = filteredEntries[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    'Timetable: ${entry['filename']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Semester: ${entry['semester']} | Uploaded: ${entry['uploaded_at']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Timetable'),
                        content: Text(
                            'Are you sure you want to delete ${entry['filename']}?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              _deleteTimetable(entry['id']);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildDepartmentNotes(String departmentCode) {
    final filteredNotes = _notes[departmentCode] ?? [];
    return filteredNotes.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No notes uploaded yet',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    'Notes: ${note['filename']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Semester: ${note['semester']} | Uploaded: ${note['uploaded_at']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Note'),
                        content: Text(
                            'Are you sure you want to delete ${note['filename']}?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              _deleteNote(note['id']);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  color: Colors.blueAccent),
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
                      title: const Text('Syllabus',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      children: [
                        ListTile(
                          title: const Text('Add Subjects'),
                          leading: const Icon(Icons.add_circle_outline,
                              color: Colors.green),
                          onTap: _showAddSubjectDialog,
                        ),
                        ..._departments.map((dept) => ExpansionTile(
                              title: Text(dept['departmentname']),
                              children: [
                                _buildDepartmentSubjects(dept['departmentcode'])
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      title: const Text('Timetable',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      leading:
                          const Icon(Icons.schedule, color: Colors.blueAccent),
                      children: [
                        ..._departments.map((dept) => ExpansionTile(
                              title: Text(dept['departmentname']),
                              children: [
                                _buildDepartmentTimetable(
                                    dept['departmentcode'])
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      title: const Text('Notes',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.note, color: Colors.blueAccent),
                      children: [
                        ..._departments.map((dept) => ExpansionTile(
                              title: Text(dept['departmentname']),
                              children: [
                                _buildDepartmentNotes(dept['departmentcode'])
                              ],
                            )),
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

// New SubjectFormDialog widget to handle add/edit logic
class SubjectFormDialog extends StatefulWidget {
  final String token;
  final List<Map<String, dynamic>> departments;
  final VoidCallback onSubjectAdded;
  final Map<String, dynamic>? initialSubject;

  const SubjectFormDialog({
    super.key,
    required this.token,
    required this.departments,
    required this.onSubjectAdded,
    this.initialSubject,
  });

  @override
  SubjectFormDialogState createState() => SubjectFormDialogState();
}

class SubjectFormDialogState extends State<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _semester;
  String? _subjectCode;
  String? _subjectName;
  int? _credits;
  String? _departmentCode;
  String? _instructorId;
  List<Map<String, dynamic>> _staff = [];
  bool _isLoadingStaff = false;
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

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null) {
      _semester = widget.initialSubject!['semester'];
      _subjectCode = widget.initialSubject!['subject_code'];
      _subjectName = widget.initialSubject!['subject_name'];
      _credits = widget.initialSubject!['credits'];
      _departmentCode = widget.initialSubject!['departmentcode'];
      _instructorId = widget.initialSubject!['instructor_id'];
      _fetchStaff(_departmentCode!); // Preload staff for edit mode
    }
  }

  Future<void> _fetchStaff(String departmentCode) async {
    print('Fetching staff for department: $departmentCode');
    setState(() {
      _isLoadingStaff = true;
      _staff = [];
      _instructorId = null; // Reset instructor unless editing
    });
    try {
      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/admin/users_by_department'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _staff = data.containsKey(departmentCode) &&
                  data[departmentCode]['staff'] != null
              ? List<Map<String, dynamic>>.from(data[departmentCode]['staff'])
              : [];
          _isLoadingStaff = false;
          if (widget.initialSubject != null &&
              widget.initialSubject!['instructor_id'] != null) {
            _instructorId = widget
                .initialSubject!['instructor_id']; // Retain instructor for edit
          }
          print('Staff loaded: $_staff');
          if (_staff.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No staff available for $departmentCode')),
            );
          }
        });
      } else {
        setState(() {
          _isLoadingStaff = false;
        });
        print('Failed to load staff: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingStaff = false;
      });
      print('Error fetching staff: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching staff: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final url = widget.initialSubject == null
            ? Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/subjects')
            : Uri.parse(
                '${NetworkConfig.getBaseUrl()}/api/admin/subjects/$_subjectCode');
        final method = widget.initialSubject == null ? http.post : http.put;
        final response = await method(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({
            'semester': _semester,
            'subject_code': _subjectCode,
            'subject_name': _subjectName,
            'credits': _credits,
            'departmentcode': _departmentCode,
            'instructor_id': _instructorId,
          }),
        );
        if (response.statusCode ==
            (widget.initialSubject == null ? 201 : 200)) {
          widget.onSubjectAdded();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Subject ${widget.initialSubject == null ? 'added' : 'updated'} successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to ${widget.initialSubject == null ? 'add' : 'update'} subject: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error ${widget.initialSubject == null ? 'adding' : 'updating'} subject: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initialSubject == null ? 'Add New Subject' : 'Edit Subject'),
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
                    .map(
                        (sem) => DropdownMenuItem(value: sem, child: Text(sem)))
                    .toList(),
                onChanged: (value) => setState(() => _semester = value),
                validator: (value) =>
                    value == null ? 'Please select a semester' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _subjectCode,
                decoration: InputDecoration(
                  labelText: 'Subject Code',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a subject code' : null,
                onSaved: (value) => _subjectCode = value,
                enabled: widget.initialSubject ==
                    null, // Disable editing subject code when updating
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _subjectName,
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
                initialValue: _credits?.toString(),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                value: _departmentCode,
                items: widget.departments
                    .map((dept) => DropdownMenuItem<String>(
                          value: dept['departmentcode'].toString(),
                          child: Text(dept['departmentname']),
                        ))
                    .toList(),
                onChanged: (value) async {
                  print('Department changed to: $value');
                  setState(() {
                    _departmentCode = value;
                    _instructorId = null; // Reset instructor
                  });
                  await _fetchStaff(value!); // Fetch new staff
                },
                validator: (value) =>
                    value == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 10),
              _isLoadingStaff
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Instructor',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      value: _instructorId,
                      items: _staff.isEmpty
                          ? [
                              const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No staff available'))
                            ]
                          : _staff
                              .map((staff) => DropdownMenuItem<String>(
                                    value: staff['admission_number'],
                                    child: Text(staff['username']),
                                  ))
                              .toList(),
                      onChanged: (value) {
                        print('Instructor selected: $value');
                        setState(() => _instructorId = value);
                      },
                      validator: (value) => _staff.isNotEmpty && value == null
                          ? 'Please select an instructor'
                          : null,
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
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(widget.initialSubject == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
