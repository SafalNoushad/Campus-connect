import 'dart:io';
import 'package:flutter/material.dart';
import 'student_academics_page.dart';
import 'announcements_page.dart';
import 'profile_page.dart';
import 'chatbot.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show MultipartRequest;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../utils/network_config.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  late String userName;
  String? _token;

  @override
  void initState() {
    super.initState();
    userName = widget.userData['name'] ?? "User";
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
    });
    if (_token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      await _fetchProfile();
      _initializePages();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Profile Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final profile = json.decode(response.body);
        setState(() {
          userName = profile['username'] ?? userName;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void _initializePages() {
    _widgetOptions = [
      HomeContent(userName: userName, token: _token),
      const ChatbotPage(),
      const StudentAcademicsPage(),
      const AnnouncementsPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Welcome, $userName";
      case 1:
        return "Chatbot";
      case 2:
        return "Academics";
      case 3:
        return "Announcements";
      case 4:
        return "Profile";
      default:
        return "Campus Connect";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications clicked!")),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _token == null
          ? const Center(child: CircularProgressIndicator())
          : _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Academics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.announcement), label: 'Announcements'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String userName;
  final String? token;

  const HomeContent({super.key, required this.userName, required this.token});

  @override
  HomeContentState createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic>? _selectedItem;
  bool _isLoadingSubjects = true;
  bool _isLoadingTeachers = true;
  bool _isLoadingAssignments = false;
  bool _isLoadingRequests = false;
  bool _showSubjects = false;
  bool _showTeachers = false;
  bool _showExams = false;
  bool _showAssignments = false;
  bool _showRequests = false;
  bool _showDetails = false;
  bool _assignmentsFetched = false;
  bool _requestsFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _fetchSubjects();
      _fetchTeachers();
      _fetchAssignments(); // Fetch assignments on init to display on home screen
    } else {
      setState(() {
        _isLoadingSubjects = false;
        _isLoadingTeachers = false;
      });
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/subjects'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      print('Subjects Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _subjects = data is List
              ? List<Map<String, dynamic>>.from(data)
              : List<Map<String, dynamic>>.from(data['subjects'] ?? []);
          _isLoadingSubjects = false;
        });
        if (_subjects.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No subjects found')),
          );
        }
      } else {
        setState(() => _isLoadingSubjects = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subjects: $e')),
      );
    }
  }

  Future<void> _fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/teachers'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      print('Teachers Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _teachers = data is List
              ? List<Map<String, dynamic>>.from(data)
              : List<Map<String, dynamic>>.from(data['teachers'] ?? []);
          _isLoadingTeachers = false;
        });
        if (_teachers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No teachers found')),
          );
        }
      } else {
        setState(() => _isLoadingTeachers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load teachers: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingTeachers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching teachers: $e')),
      );
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoadingAssignments = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/assignments'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      print('Assignments Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> assignmentList;

        // Handle both flat list and wrapped response
        if (data is List) {
          assignmentList = data;
        } else if (data is Map<String, dynamic> &&
            data.containsKey('assignments')) {
          assignmentList = data['assignments'];
          if (assignmentList is! List) {
            throw Exception(
                'Expected "assignments" to be a list, but received: $assignmentList');
          }
        } else {
          throw Exception(
              'Expected a list of assignments or an "assignments" key, but received: $data');
        }

        setState(() {
          _assignments = assignmentList
              .map((item) => item as Map<String, dynamic>)
              .toList();
          _isLoadingAssignments = false;
          _assignmentsFetched = true;
        });

        if (_assignments.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No submitted assignments found')),
          );
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Session expired. Please log in again.')),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() => _isLoadingAssignments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load assignments: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingAssignments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching assignments: $e')),
      );
    }
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/students/requests'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      print('Requests Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data);
          _isLoadingRequests = false;
          _requestsFetched = true;
        });
        if (_requests.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No requests found')),
          );
        }
      } else {
        setState(() => _isLoadingRequests = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingRequests = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching requests: $e')),
      );
    }
  }

  Future<void> _submitAssignment({
    required String subjectCode,
    required String staffName,
    required int assignmentNumber,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        var request = MultipartRequest(
          'POST',
          Uri.parse(
              '${NetworkConfig.getBaseUrl()}/api/students/assignments/create-and-submit'),
        );
        request.headers['Authorization'] = 'Bearer ${widget.token}';
        request.fields['subject_code'] = subjectCode;
        request.fields['staff_name'] = staffName;
        request.fields['assignment_number'] = assignmentNumber.toString();
        request.files
            .add(await http.MultipartFile.fromPath('file', file.path!));
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment submitted successfully!')),
          );
          _fetchAssignments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to submit assignment: $responseBody')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $e')),
      );
    }
  }

  Future<void> _submitRequest() async {
    String? category;
    PlatformFile? requestFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Application Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: category,
                  items: ['Medical Leave', 'Duty Leave']
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => category = value),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
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
                      setDialogState(() => requestFile = result.files.first);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300]),
                  child: Text(requestFile == null
                      ? 'Upload PDF'
                      : 'File: ${requestFile!.name}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (category != null && requestFile != null) {
                  try {
                    var request = MultipartRequest(
                      'POST',
                      Uri.parse(
                          '${NetworkConfig.getBaseUrl()}/api/students/requests/upload'),
                    );
                    request.headers['Authorization'] = 'Bearer ${widget.token}';
                    request.fields['category'] =
                        category!.toLowerCase().replaceAll(' ', '_');
                    request.files.add(await http.MultipartFile.fromPath(
                        'file', requestFile!.path!));
                    final response = await request.send();
                    final responseBody = await response.stream.bytesToString();
                    print(
                        'Upload Request Response: ${response.statusCode} - $responseBody');

                    if (response.statusCode == 201) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Request submitted successfully!')),
                      );
                      _fetchRequests();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to submit request: $responseBody')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error submitting request: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select category and file')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRequest(Map<String, dynamic> request) async {
    String? category = request['category'].replaceAll('_', ' ').toUpperCase();
    PlatformFile? requestFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Application Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: category,
                  items: ['Medical Leave', 'Duty Leave']
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => category = value),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
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
                      setDialogState(() => requestFile = result.files.first);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300]),
                  child: Text(requestFile == null
                      ? 'Replace PDF (Optional)'
                      : 'File: ${requestFile!.name}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (category != null) {
                  try {
                    var requestToSend = MultipartRequest(
                      'PUT',
                      Uri.parse(
                          '${NetworkConfig.getBaseUrl()}/api/students/requests/${request['id']}'),
                    );
                    requestToSend.headers['Authorization'] =
                        'Bearer ${widget.token}';
                    requestToSend.fields['category'] =
                        category!.toLowerCase().replaceAll(' ', '_');
                    if (requestFile != null) {
                      requestToSend.files.add(await http.MultipartFile.fromPath(
                          'file', requestFile!.path!));
                    }
                    final response = await requestToSend.send();
                    final responseBody = await response.stream.bytesToString();
                    print(
                        'Edit Request Response: ${response.statusCode} - $responseBody');

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Request updated successfully!')),
                      );
                      _fetchRequests();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to update request: $responseBody')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating request: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a category')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeRequest(int requestId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.delete(
                  Uri.parse(
                      '${NetworkConfig.getBaseUrl()}/api/students/requests/$requestId'),
                  headers: {'Authorization': 'Bearer ${widget.token}'},
                );
                print(
                    'Delete Request Response: ${response.statusCode} - ${response.body}');
                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Request deleted successfully!')),
                  );
                  _fetchRequests();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to delete request: ${response.body}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting request: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadRequest(String filename) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/students/download/requests/$filename'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request downloaded to $filePath')),
        );
        OpenFile.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download request: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading request: $e')),
      );
    }
  }

  void _toggleSubjects() {
    setState(() {
      _showSubjects = !_showSubjects;
      _showTeachers = false;
      _showExams = false;
      _showAssignments = false;
      _showRequests = false;
      _showDetails = false;
      _selectedItem = null;
    });
  }

  void _toggleTeachers() {
    setState(() {
      _showTeachers = !_showTeachers;
      _showSubjects = false;
      _showExams = false;
      _showAssignments = false;
      _showRequests = false;
      _showDetails = false;
      _selectedItem = null;
    });
  }

  void _toggleExams() {
    setState(() {
      _showExams = !_showExams;
      _showSubjects = false;
      _showTeachers = false;
      _showAssignments = false;
      _showRequests = false;
      _showDetails = false;
      _selectedItem = null;
    });
  }

  void _toggleAssignments() {
    setState(() {
      _showAssignments = !_showAssignments;
      _showSubjects = false;
      _showTeachers = false;
      _showExams = false;
      _showRequests = false;
      _showDetails = false;
      _selectedItem = null;
      if (_showAssignments && !_assignmentsFetched) {
        _fetchAssignments();
      }
    });
  }

  void _toggleRequests() {
    setState(() {
      _showRequests = !_showRequests;
      _showSubjects = false;
      _showTeachers = false;
      _showExams = false;
      _showAssignments = false;
      _showDetails = false;
      _selectedItem = null;
      if (_showRequests && !_requestsFetched) {
        _fetchRequests();
      }
    });
  }

  void _showItemDetails(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _showDetails = true;
    });
  }

  void _hideDetails() {
    setState(() {
      _showDetails = false;
      _selectedItem = null;
    });
  }

  List<String> _getDetails() {
    if (_selectedItem == null) return [];
    if (_selectedItem!.containsKey('subject_code') &&
        !_selectedItem!.containsKey('assignment_number') &&
        !_selectedItem!.containsKey('category')) {
      return [
        'Name: ${_selectedItem!['subject_name']}',
        'Code: ${_selectedItem!['subject_code']}',
        'Semester: ${_selectedItem!['semester']}',
        'Credits: ${_selectedItem!['credits']}',
        'Department: ${_selectedItem!['departmentcode']}',
        'Instructor: ${_selectedItem!['instructor_name']}',
      ];
    } else if (_selectedItem!.containsKey('username')) {
      return [
        'Name: ${_selectedItem!['username']}',
        'Email: ${_selectedItem!['email']}',
        'Phone: ${_selectedItem!['phone_number'] ?? 'N/A'}',
        'Department: ${_selectedItem!['departmentcode']}',
      ];
    } else if (_selectedItem!.containsKey('assignment_number')) {
      return [
        'Subject Code: ${_selectedItem!['subject_code']}',
        'Staff Name: ${_selectedItem!['staff_name']}',
        'Assignment Number: ${_selectedItem!['assignment_number']}',
        'Created At: ${_selectedItem!['created_at'].substring(0, 10)}',
        'Submitted At: ${_selectedItem!['submitted_at']?.substring(0, 10) ?? 'N/A'}',
        'File: ${_selectedItem!['submission_filename']}',
      ];
    } else if (_selectedItem!.containsKey('category')) {
      return [
        'Category: ${_selectedItem!['category'].replaceAll('_', ' ').toUpperCase()}',
        'File: ${_selectedItem!['filename']}',
        'Status: ${_selectedItem!['status']}',
        'Submitted At: ${_selectedItem!['created_at'].substring(0, 10)}',
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.userName}!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Subjects Title Bar
            GestureDetector(
              onTap: _toggleSubjects,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Subjects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _showSubjects
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSubjects) ...[
              const SizedBox(height: 10),
              _isLoadingSubjects
                  ? const Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No subjects available',
                              style: TextStyle(fontSize: 16)),
                        )
                      : Column(
                          children: _subjects.map((subject) {
                            return ListTile(
                              leading:
                                  const Icon(Icons.book, color: Colors.grey),
                              title: Text(subject['subject_name'],
                                  style: const TextStyle(fontSize: 16)),
                              subtitle: Text(
                                  'Instructor: ${subject['instructor_name']}'),
                              onTap: () => _showItemDetails(subject),
                            );
                          }).toList(),
                        ),
            ],
            const SizedBox(height: 20),
            // Teachers Title Bar
            GestureDetector(
              onTap: _toggleTeachers,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Teachers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _showTeachers
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTeachers) ...[
              const SizedBox(height: 10),
              _isLoadingTeachers
                  ? const Center(child: CircularProgressIndicator())
                  : _teachers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No teachers available',
                              style: TextStyle(fontSize: 16)),
                        )
                      : Column(
                          children: _teachers.map((teacher) {
                            return ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.grey),
                              title: Text(teacher['username'],
                                  style: const TextStyle(fontSize: 16)),
                              onTap: () => _showItemDetails(teacher),
                            );
                          }).toList(),
                        ),
            ],
            const SizedBox(height: 20),
            // Assignments Title Bar (for reference, but not primary display)
            GestureDetector(
              onTap: _toggleAssignments,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Assignments ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _showAssignments
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showAssignments) ...[
              const SizedBox(height: 10),
              _isLoadingAssignments
                  ? const Center(child: CircularProgressIndicator())
                  : _assignments.isEmpty && _assignmentsFetched
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No submitted assignments available',
                              style: TextStyle(fontSize: 16)),
                        )
                      : _assignments.isEmpty && !_assignmentsFetched
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Assignments not loaded yet',
                                  style: TextStyle(fontSize: 16)),
                            )
                          : Column(
                              children: _assignments.map((assignment) {
                                return ListTile(
                                  leading: const Icon(Icons.assignment,
                                      color: Colors.grey),
                                  title: Text(
                                      'Assignment ${assignment['assignment_number']} - ${assignment['subject_code']}',
                                      style: const TextStyle(fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Staff: ${assignment['staff_name']}'),
                                      Text(
                                          'Submitted At: ${assignment['submitted_at']?.substring(0, 10) ?? 'N/A'}'),
                                    ],
                                  ),
                                  onTap: () => _showItemDetails(assignment),
                                );
                              }).toList(),
                            ),
            ],
            const SizedBox(height: 20),
            // Requests Title Bar
            GestureDetector(
              onTap: _toggleRequests,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _showRequests
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showRequests) ...[
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Submit New Request'),
                leading: const Icon(Icons.upload_file, color: Colors.green),
                onTap: _submitRequest,
              ),
              _isLoadingRequests
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty && _requestsFetched
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No requests submitted yet',
                              style: TextStyle(fontSize: 16)),
                        )
                      : _requests.isEmpty && !_requestsFetched
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Requests not loaded yet',
                                  style: TextStyle(fontSize: 16)),
                            )
                          : Column(
                              children: _requests.map((request) {
                                return ListTile(
                                  leading: const Icon(Icons.request_page,
                                      color: Colors.grey),
                                  title: Text(
                                      request['category']
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(fontSize: 16)),
                                  subtitle:
                                      Text('Status: ${request['status']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download,
                                            color: Colors.blue),
                                        onPressed: () => _downloadRequest(
                                            request['filename']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () => _editRequest(request),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _removeRequest(request['id']),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showItemDetails(request),
                                );
                              }).toList(),
                            ),
            ],
            const SizedBox(height: 20),
            if (_showDetails && _selectedItem != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _hideDetails,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getDetails()
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(item,
                                  style: const TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
