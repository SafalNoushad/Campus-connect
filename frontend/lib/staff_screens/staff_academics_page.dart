import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show MultipartRequest;
import '../utils/network_config.dart';

class StaffAcademicsPage extends StatefulWidget {
  const StaffAcademicsPage({super.key});

  @override
  _StaffAcademicsPageState createState() => _StaffAcademicsPageState();
}

class _StaffAcademicsPageState extends State<StaffAcademicsPage> {
  final _notesFormKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _timetableEntries = [];
  List<Map<String, dynamic>> _notes = [];
  String? _token;
  String? _departmentCode;
  String? _notesSemester;
  String? _notesSubjectName;
  String? _notesModuleNumber;
  PlatformFile? _notesFile;
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
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _departmentCode = prefs.getString('departmentcode');
      print('Token: $_token, Department Code: $_departmentCode');
    });
    if (_token != null && _departmentCode != null) {
      _fetchSubjects();
      _fetchTimetable();
      _fetchNotes();
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/subjects'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Subjects Response: ${response.statusCode} - ${response.body}');
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/timetable'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Timetable Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _timetableEntries =
              List<Map<String, dynamic>>.from(json.decode(response.body));
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/notes'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Notes Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(json.decode(response.body));
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

  Future<void> _addNotesFile() async {
    if (_notesFormKey.currentState!.validate() && _notesFile != null) {
      _notesFormKey.currentState!.save();
      try {
        var request = MultipartRequest(
          'POST',
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/notes/upload'),
        );
        request.headers['Authorization'] = 'Bearer $_token';
        request.fields['semester'] = _notesSemester!;
        request.fields['subject_name'] = _notesSubjectName!;
        request.fields['module_number'] = _notesModuleNumber!;
        request.files.add(
          await http.MultipartFile.fromPath('file', _notesFile!.path!),
        );
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        print('Upload Notes Response: ${response.statusCode} - $responseBody');
        if (response.statusCode == 201) {
          _fetchNotes();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notes uploaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload notes: $responseBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading notes: $e')),
        );
      }
    } else if (_notesFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/staff/notes/$noteId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Delete Note Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _fetchNotes();
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

  void _showAddNotesDialog() {
    _notesSemester = null;
    _notesSubjectName = null;
    _notesModuleNumber = null;
    _notesFile = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload Notes'),
          content: Form(
            key: _notesFormKey,
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
                    value: _notesSemester,
                    items: _semesters
                        .map((sem) =>
                            DropdownMenuItem(value: sem, child: Text(sem)))
                        .toList(),
                    onChanged: (value) => setDialogState(() {
                      _notesSemester = value;
                      _notesSubjectName = null;
                    }),
                    validator: (value) =>
                        value == null ? 'Please select a semester' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    value: _notesSubjectName,
                    items: _notesSemester == null
                        ? []
                        : _subjects
                            .where((subject) =>
                                subject['semester'] == _notesSemester)
                            .map<DropdownMenuItem<String>>((subject) =>
                                DropdownMenuItem<String>(
                                  value: subject['subject_name'] as String,
                                  child:
                                      Text(subject['subject_name'] as String),
                                ))
                            .toList(),
                    onChanged: (value) =>
                        setDialogState(() => _notesSubjectName = value),
                    validator: (value) =>
                        value == null ? 'Please select a subject' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Module Number',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0
                        ? 'Please enter a valid module number'
                        : null,
                    onSaved: (value) => _notesModuleNumber = value,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        setDialogState(() => _notesFile = result.files.first);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300]),
                    child: Text(_notesFile == null
                        ? 'Select PDF File'
                        : 'File: ${_notesFile!.name}'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _addNotesFile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSemesterTimetable(String semester) {
    final filteredEntries = _timetableEntries
        .where((entry) => entry['semester'] == semester)
        .toList();
    return filteredEntries.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No timetable available',
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
                      'Uploaded: ${entry['uploaded_at'].substring(0, 10)}'),
                ),
              );
            },
          );
  }

  Widget _buildSemesterNotes(String semester) {
    final filteredNotes =
        _notes.where((note) => note['semester'] == semester).toList();
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
                  subtitle:
                      Text('Uploaded: ${note['uploaded_at'].substring(0, 10)}'),
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
                            child: const Text('Cancel'),
                          ),
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
                      title: const Text('Syllabus',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      children: [
                        ExpansionTile(
                          title: const Text('1st Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 1 (S1)'),
                                children: [_buildSemesterSubjects('S1')]),
                            ExpansionTile(
                                title: const Text('Semester 2 (S2)'),
                                children: [_buildSemesterSubjects('S2')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('2nd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 3 (S3)'),
                                children: [_buildSemesterSubjects('S3')]),
                            ExpansionTile(
                                title: const Text('Semester 4 (S4)'),
                                children: [_buildSemesterSubjects('S4')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('3rd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 5 (S5)'),
                                children: [_buildSemesterSubjects('S5')]),
                            ExpansionTile(
                                title: const Text('Semester 6 (S6)'),
                                children: [_buildSemesterSubjects('S6')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('4th Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 7 (S7)'),
                                children: [_buildSemesterSubjects('S7')]),
                            ExpansionTile(
                                title: const Text('Semester 8 (S8)'),
                                children: [_buildSemesterSubjects('S8')]),
                          ],
                        ),
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
                        ExpansionTile(
                          title: const Text('1st Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 1 (S1)'),
                                children: [_buildSemesterTimetable('S1')]),
                            ExpansionTile(
                                title: const Text('Semester 2 (S2)'),
                                children: [_buildSemesterTimetable('S2')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('2nd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 3 (S3)'),
                                children: [_buildSemesterTimetable('S3')]),
                            ExpansionTile(
                                title: const Text('Semester 4 (S4)'),
                                children: [_buildSemesterTimetable('S4')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('3rd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 5 (S5)'),
                                children: [_buildSemesterTimetable('S5')]),
                            ExpansionTile(
                                title: const Text('Semester 6 (S6)'),
                                children: [_buildSemesterTimetable('S6')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('4th Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 7 (S7)'),
                                children: [_buildSemesterTimetable('S7')]),
                            ExpansionTile(
                                title: const Text('Semester 8 (S8)'),
                                children: [_buildSemesterTimetable('S8')]),
                          ],
                        ),
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
                        ListTile(
                          title: const Text('Upload Notes'),
                          leading: const Icon(Icons.upload_file,
                              color: Colors.green),
                          onTap: _showAddNotesDialog,
                        ),
                        ExpansionTile(
                          title: const Text('1st Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 1 (S1)'),
                                children: [_buildSemesterNotes('S1')]),
                            ExpansionTile(
                                title: const Text('Semester 2 (S2)'),
                                children: [_buildSemesterNotes('S2')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('2nd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 3 (S3)'),
                                children: [_buildSemesterNotes('S3')]),
                            ExpansionTile(
                                title: const Text('Semester 4 (S4)'),
                                children: [_buildSemesterNotes('S4')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('3rd Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 5 (S5)'),
                                children: [_buildSemesterNotes('S5')]),
                            ExpansionTile(
                                title: const Text('Semester 6 (S6)'),
                                children: [_buildSemesterNotes('S6')]),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('4th Year'),
                          children: [
                            ExpansionTile(
                                title: const Text('Semester 7 (S7)'),
                                children: [_buildSemesterNotes('S7')]),
                            ExpansionTile(
                                title: const Text('Semester 8 (S8)'),
                                children: [_buildSemesterNotes('S8')]),
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
