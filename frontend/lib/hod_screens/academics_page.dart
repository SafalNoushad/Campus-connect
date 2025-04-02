import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show MultipartRequest;
import '../utils/network_config.dart';

class AcademicsPage extends StatefulWidget {
  const AcademicsPage({super.key});

  @override
  _AcademicsPageState createState() => _AcademicsPageState();
}

class _AcademicsPageState extends State<AcademicsPage> {
  final _subjectFormKey = GlobalKey<FormState>();
  final _timetableFormKey = GlobalKey<FormState>();
  final _notesFormKey = GlobalKey<FormState>();

  String? _semester;
  String? _subjectCode;
  String? _subjectName;
  int? _credits;
  String? _instructorId; // New field for selected instructor
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _staff =
      []; // List to hold staff members including HOD

  String? _timetableSemester;
  PlatformFile? _timetableFile;
  List<Map<String, dynamic>> _timetableEntries = [];

  String? _notesSemester;
  String? _notesSubjectName;
  String? _notesModuleNumber;
  PlatformFile? _notesFile;
  List<Map<String, dynamic>> _notes = [];

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

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() {
      _token = token;
    });
    _fetchSubjects();
    _fetchTimetable();
    _fetchNotes();
    _fetchStaff(); // Fetch staff members including HOD
  }

  Future<void> _fetchStaff() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/staff/list'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Staff Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _staff = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching staff: $e')),
      );
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/subjects'),
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/timetable'),
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/notes'),
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

  Future<void> _addSubject() async {
    if (_subjectFormKey.currentState!.validate()) {
      _subjectFormKey.currentState!.save();
      try {
        final response = await http.post(
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/subjects'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: json.encode({
            'semester': _semester,
            'subject_code': _subjectCode,
            'subject_name': _subjectName,
            'credits': _credits,
            'instructor_id': _instructorId, // Include instructor_id
          }),
        );
        print(
            'Add Subject Response: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 201) {
          _fetchSubjects();
          _subjectFormKey.currentState!.reset();
          setState(() {
            _instructorId = null; // Reset instructor selection
          });
          Navigator.of(context).pop();
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

  Future<void> _deleteSubject(String subjectCode) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/hod/subjects/$subjectCode'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Delete Subject Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _fetchSubjects();
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

  Future<void> _addTimetableFile() async {
    if (_timetableFormKey.currentState!.validate() && _timetableFile != null) {
      _timetableFormKey.currentState!.save();
      try {
        var request = MultipartRequest(
          'POST',
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/timetable/upload'),
        );
        request.headers['Authorization'] = 'Bearer $_token';
        request.fields['semester'] = _timetableSemester!;
        request.files.add(
          await http.MultipartFile.fromPath('file', _timetableFile!.path!),
        );
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        print(
            'Upload Timetable Response: ${response.statusCode} - $responseBody');
        if (response.statusCode == 201) {
          _fetchTimetable();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timetable uploaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to upload timetable: $responseBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading timetable: $e')),
        );
      }
    } else if (_timetableFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Excel file')),
      );
    }
  }

  Future<void> _deleteTimetable(int timetableId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/hod/timetable/$timetableId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Delete Timetable Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _fetchTimetable();
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

  Future<void> _addNotesFile() async {
    if (_notesFormKey.currentState!.validate() && _notesFile != null) {
      _notesFormKey.currentState!.save();
      try {
        var request = MultipartRequest(
          'POST',
          Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/notes/upload'),
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
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/notes/$noteId'),
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

  void _showAddSubjectDialog() {
    _semester = null; // Reset fields
    _subjectCode = null;
    _subjectName = null;
    _credits = null;
    _instructorId = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Subject'),
          content: Form(
            key: _subjectFormKey,
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
                    onChanged: (value) =>
                        setDialogState(() => _semester = value),
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
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Instructor',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    value: _instructorId,
                    items: _staff.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['admission_number'] as String,
                        child: Text(staff['username'] as String),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => _instructorId = value),
                    validator: (value) =>
                        value == null ? 'Please select an instructor' : null,
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
              onPressed: _addSubject,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTimetableDialog() {
    _timetableSemester = null;
    _timetableFile = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload Timetable'),
          content: Form(
            key: _timetableFormKey,
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
                    value: _timetableSemester,
                    items: _semesters
                        .map((sem) =>
                            DropdownMenuItem(value: sem, child: Text(sem)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => _timetableSemester = value),
                    validator: (value) =>
                        value == null ? 'Please select a semester' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['xlsx']);
                      if (result != null) {
                        setDialogState(
                            () => _timetableFile = result.files.first);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300]),
                    child: Text(_timetableFile == null
                        ? 'Select Excel File'
                        : 'File: ${_timetableFile!.name}'),
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
              onPressed: _addTimetableFile,
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
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf']);
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
            child: Text('No subjects added yet',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSubjects.length,
            itemBuilder: (context, index) {
              final subject = filteredSubjects[index];
              final instructor = _staff.firstWhere(
                (staff) =>
                    staff['admission_number'] == subject['instructor_id'],
                orElse: () => {'username': 'Not Assigned'},
              );
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
                      'Credits: ${subject['credits']} | Instructor: ${instructor['username']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Subject'),
                        content: Text(
                            'Are you sure you want to delete ${subject['subject_name']} (${subject['subject_code']})?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              _deleteSubject(subject['subject_code']);
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

  Widget _buildSemesterTimetable(String semester) {
    final filteredEntries = _timetableEntries
        .where((entry) => entry['semester'] == semester)
        .toList();
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
                      'Uploaded: ${entry['uploaded_at'].substring(0, 10)}'),
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
                        ListTile(
                          title: const Text('Upload Timetable'),
                          leading: const Icon(Icons.upload_file,
                              color: Colors.green),
                          onTap: _showAddTimetableDialog,
                        ),
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
