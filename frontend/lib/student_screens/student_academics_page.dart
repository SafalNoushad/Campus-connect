import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show MultipartRequest;

class StudentAcademicsPage extends StatefulWidget {
  const StudentAcademicsPage({super.key});

  @override
  _StudentAcademicsPageState createState() => _StudentAcademicsPageState();
}

class _StudentAcademicsPageState extends State<StudentAcademicsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _token;
  String? _semester;
  String? _departmentCode;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _timetables = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _semester = prefs.getString('semester');
      _departmentCode = prefs.getString('departmentcode');
      print('Token: $_token, Semester: $_semester, Dept: $_departmentCode');
    });
    if (_token != null && _semester != null && _departmentCode != null) {
      _fetchData();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication data missing. Please log in again.';
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch Subjects
    try {
      final subjectsResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/subjects'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Subjects Response: ${subjectsResponse.statusCode} - ${subjectsResponse.body}');
      if (subjectsResponse.statusCode == 200) {
        final subjectsData = jsonDecode(subjectsResponse.body);
        setState(() {
          _subjects = subjectsData is List
              ? List<Map<String, dynamic>>.from(subjectsData)
              : List<Map<String, dynamic>>.from(subjectsData['subjects'] ?? []);
          print('Parsed Subjects: $_subjects');
        });
        if (_subjects.isEmpty) {
          print(
              'No subjects found for semester=$_semester, dept=$_departmentCode');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load subjects: ${subjectsResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching subjects: $e';
      });
      print('Subjects Fetch Error: $e');
    }

    // Fetch Notes
    try {
      final notesResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/notes'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Notes Response: ${notesResponse.statusCode} - ${notesResponse.body}');
      if (notesResponse.statusCode == 200) {
        final notesData = jsonDecode(notesResponse.body);
        setState(() {
          _notes = notesData is List
              ? List<Map<String, dynamic>>.from(notesData)
              : List<Map<String, dynamic>>.from(notesData['notes'] ?? []);
          print('Parsed Notes: $_notes');
        });
        if (_notes.isEmpty) {
          print(
              'No notes found for semester=$_semester, dept=$_departmentCode');
        }
      } else {
        setState(() {
          _errorMessage = _errorMessage != null
              ? '$_errorMessage\nFailed to load notes: ${notesResponse.body}'
              : 'Failed to load notes: ${notesResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _errorMessage != null
            ? '$_errorMessage\nError fetching notes: $e'
            : 'Error fetching notes: $e';
      });
      print('Notes Fetch Error: $e');
    }

    // Fetch Timetables
    try {
      final timetableResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/timetable'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Timetable Response: ${timetableResponse.statusCode} - ${timetableResponse.body}');
      if (timetableResponse.statusCode == 200) {
        final timetableData = jsonDecode(timetableResponse.body);
        setState(() {
          _timetables = timetableData is List
              ? List<Map<String, dynamic>>.from(timetableData)
              : List<Map<String, dynamic>>.from(
                  timetableData['timetables'] ?? []);
          print('Parsed Timetables: $_timetables');
        });
        if (_timetables.isEmpty) {
          print(
              'No timetables found for semester=$_semester, dept=$_departmentCode');
        }
      } else {
        setState(() {
          _errorMessage = _errorMessage != null
              ? '$_errorMessage\nFailed to load timetable: ${timetableResponse.body}'
              : 'Failed to load timetable: ${timetableResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _errorMessage != null
            ? '$_errorMessage\nError fetching timetable: $e'
            : 'Error fetching timetable: $e';
      });
      print('Timetable Fetch Error: $e');
    }

    // Fetch Assignments
    try {
      final assignmentsResponse = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/assignments'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Assignments Response: ${assignmentsResponse.statusCode} - ${assignmentsResponse.body}');
      if (assignmentsResponse.statusCode == 200) {
        final assignmentsData = jsonDecode(assignmentsResponse.body);
        setState(() {
          _assignments = List<Map<String, dynamic>>.from(
              assignmentsData['assignments'] ?? []);
          print('Parsed Assignments: $_assignments');
        });
        if (_assignments.isEmpty) {
          print('No assignments found for dept=$_departmentCode');
        }
      } else {
        setState(() {
          _errorMessage = _errorMessage != null
              ? '$_errorMessage\nFailed to load assignments: ${assignmentsResponse.body}'
              : 'Failed to load assignments: ${assignmentsResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _errorMessage != null
            ? '$_errorMessage\nError fetching assignments: $e'
            : 'Error fetching assignments: $e';
      });
      print('Assignments Fetch Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _downloadFile(String filename, String type) async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }
    }

    try {
      final endpoint = type == 'notes'
          ? '/api/students/download/notes/$filename'
          : type == 'timetable'
              ? '/api/students/download/timetable/$filename'
              : '/api/students/download/assignments/$filename';
      final url = '${NetworkConfig.getBaseUrl()}$endpoint';
      print('Downloading from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        print('Saving to: $filePath');

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('File written successfully');

        final result = await OpenFile.open(filePath);
        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded and opened $filename')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded $filename to $filePath')),
          );
        }
      } else {
        throw Exception(
            'Failed to download file: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Download Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Future<void> _submitAssignment({
    required String subjectCode,
    required String staffName,
    required int assignmentNumber,
    required String semester,
    required PlatformFile file,
  }) async {
    try {
      var request = MultipartRequest(
        'POST',
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/students/assignments/create-and-submit'),
      );
      request.headers['Authorization'] = 'Bearer $_token';
      request.fields['subject_code'] = subjectCode;
      request.fields['staff_name'] = staffName;
      request.fields['assignment_number'] = assignmentNumber.toString();
      // Removed 'semester' field as backend doesn't expect it
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Submission Response: ${response.statusCode} - $responseBody');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
        await _fetchData(); // Refresh assignments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $responseBody')),
        );
      }
    } catch (e) {
      print('Submission Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $e')),
      );
    }
  }

  Widget _buildTabContent(List<Map<String, dynamic>> items, String type) {
    if (type == 'assignments') {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    String? selectedSubjectName;
                    String? selectedSubjectCode;
                    String? selectedStaffName;
                    int? selectedAssignmentNumber;
                    PlatformFile? selectedFile;

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Submit Assignment'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<String>(
                                  value: selectedSubjectName,
                                  hint: const Text('Select Subject'),
                                  isExpanded: true,
                                  items: _subjects.map((subject) {
                                    return DropdownMenuItem<String>(
                                      value: subject['subject_name'],
                                      child: Text(subject['subject_name']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSubjectName = value;
                                      final subject = _subjects.firstWhere(
                                          (s) => s['subject_name'] == value);
                                      selectedSubjectCode =
                                          subject['subject_code'];
                                      selectedStaffName =
                                          subject['instructor_name'];
                                      print(
                                          'Selected: $selectedSubjectName, Code: $selectedSubjectCode, Staff: $selectedStaffName');
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: TextEditingController(
                                      text: selectedSubjectCode),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject Code',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: TextEditingController(
                                      text: selectedStaffName),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Staff Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButton<int>(
                                  value: selectedAssignmentNumber,
                                  hint: const Text('Select Assignment Number'),
                                  isExpanded: true,
                                  items: [1, 2, 3].map((number) {
                                    return DropdownMenuItem<int>(
                                      value: number,
                                      child: Text(number.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAssignmentNumber = value;
                                      print('Assignment Number: $value');
                                    });
                                  },
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
                                      setState(() {
                                        selectedFile = result.files.first;
                                        print('File: ${selectedFile!.name}');
                                      });
                                    }
                                  },
                                  child: Text(selectedFile == null
                                      ? 'Select PDF File'
                                      : 'File: ${selectedFile!.name}'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: selectedSubjectCode != null &&
                                      selectedStaffName != null &&
                                      selectedAssignmentNumber != null &&
                                      selectedFile != null
                                  ? () {
                                      print(
                                          'Submitting: Code=$selectedSubjectCode, Staff=$selectedStaffName, Number=$selectedAssignmentNumber, File=$selectedFile');
                                      Navigator.pop(context);
                                      _submitAssignment(
                                        subjectCode: selectedSubjectCode!,
                                        staffName: selectedStaffName!,
                                        assignmentNumber:
                                            selectedAssignmentNumber!,
                                        semester: _semester!,
                                        file: selectedFile!,
                                      );
                                    }
                                  : null,
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit Assignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No assignments submitted yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            'Assignment ${item['assignment_number']} - ${item['subject_code']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Staff: ${item['staff_name']} | Submitted At: ${item['submitted_at']?.substring(0, 10) ?? 'N/A'}',
                          ),
                          trailing: item['submission_filename'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.download,
                                      color: Colors.blue),
                                  onPressed: () => _downloadFile(
                                      item['submission_filename'], type),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${type == 'subjects' ? 'syllabus' : type} available for Semester $_semester',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            title: Text(
              type == 'subjects'
                  ? '${item['subject_code'] ?? 'Unknown Code'} - ${item['subject_name'] ?? 'Unknown Name'}'
                  : item['filename'] ?? 'Unknown File',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              type == 'subjects'
                  ? 'Credits: ${item['credits'] ?? 'N/A'} | Instructor: ${item['instructor_name'] ?? 'N/A'}'
                  : 'Uploaded: ${item['uploaded_at']?.substring(0, 10) ?? 'N/A'}',
            ),
            trailing: (type == 'notes' || type == 'timetable')
                ? IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: () =>
                        _downloadFile(item['filename'] ?? '', type),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Syllabus'),
            Tab(text: 'Notes'),
            Tab(text: 'Timetable'),
            Tab(text: 'Assignments'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabContent(_subjects, 'subjects'),
                          _buildTabContent(_notes, 'notes'),
                          _buildTabContent(_timetables, 'timetable'),
                          _buildTabContent(_assignments, 'assignments'),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
