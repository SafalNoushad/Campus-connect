import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  _AdminAnnouncementsPageState createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _category = 'general';
  String? _selectedDepartment; // For department announcements
  List<String> departments = []; // List of department codes
  List generalAnnouncements = [];
  List deptAnnouncements = [];
  bool isLoading = true;
  String? jwtToken;
  bool sendEmail = false;
  bool sendToStudents = false;
  bool sendToStaff = false;
  bool sendToHod = false;
  bool isDeptAnnouncement =
      false; // Toggle between general and dept announcements

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        jwtToken = prefs.getString('jwt_token');
      });
      if (jwtToken != null) {
        await _fetchDepartments();
        await _fetchGeneralAnnouncements();
        await _fetchDeptAnnouncements();
      }
    } catch (e) {
      debugPrint('Error loading token or data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/admin/departments'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          departments = List<String>.from(
              json.decode(response.body).map((d) => d['departmentcode']));
        });
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _fetchGeneralAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/announcements'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          generalAnnouncements = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching general announcements: $e');
    }
  }

  Future<void> _fetchDeptAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/department_announcements'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          deptAnnouncements = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching department announcements: $e');
    }
  }

  Future<void> _createAnnouncement() async {
    try {
      final url = isDeptAnnouncement
          ? '${NetworkConfig.getBaseUrl()}/api/department_announcements'
          : '${NetworkConfig.getBaseUrl()}/api/announcements';
      final body = isDeptAnnouncement
          ? {
              'title': _titleController.text,
              'message': _messageController.text,
              'category': _category,
              'departmentcode': _selectedDepartment,
              'send_email': sendEmail,
              'email_recipients': {
                'students': sendToStudents,
                'staff': sendToStaff,
              },
            }
          : {
              'title': _titleController.text,
              'message': _messageController.text,
              'category': _category,
              'send_email': sendEmail,
              'email_recipients': {
                'students': sendToStudents,
                'staff': sendToStaff,
                'hod': sendToHod,
              },
            };
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        _titleController.clear();
        _messageController.clear();
        setState(() {
          sendEmail = false;
          sendToStudents = false;
          sendToStaff = false;
          sendToHod = false;
          _selectedDepartment = null;
          isDeptAnnouncement = false;
        });
        await _fetchGeneralAnnouncements();
        await _fetchDeptAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Error creating announcement: $e');
    }
  }

  Future<void> _updateAnnouncement(int announcementId) async {
    try {
      final url = isDeptAnnouncement
          ? '${NetworkConfig.getBaseUrl()}/api/department_announcements/$announcementId'
          : '${NetworkConfig.getBaseUrl()}/api/announcements/$announcementId';
      final body = isDeptAnnouncement
          ? {
              'title': _titleController.text,
              'message': _messageController.text,
              'category': _category,
              'departmentcode': _selectedDepartment,
            }
          : {
              'title': _titleController.text,
              'message': _messageController.text,
              'category': _category,
            };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        _titleController.clear();
        _messageController.clear();
        setState(() {
          sendEmail = false;
          sendToStudents = false;
          sendToStaff = false;
          sendToHod = false;
          _selectedDepartment = null;
          isDeptAnnouncement = false;
        });
        await _fetchGeneralAnnouncements();
        await _fetchDeptAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Error updating announcement: $e');
    }
  }

  Future<void> _deleteAnnouncement(int announcementId, bool isDept) async {
    try {
      final url = isDept
          ? '${NetworkConfig.getBaseUrl()}/api/department_announcements/$announcementId'
          : '${NetworkConfig.getBaseUrl()}/api/announcements/$announcementId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );
      if (response.statusCode == 200) {
        await _fetchGeneralAnnouncements();
        await _fetchDeptAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
    }
  }

  void _showAnnouncementDialog({Map<String, dynamic>? announcement}) {
    if (announcement != null) {
      _titleController.text = announcement['title'];
      _messageController.text = announcement['message'];
      _category = announcement['category'];
      isDeptAnnouncement = announcement.containsKey('departmentcode');
      _selectedDepartment = announcement['departmentcode'];
    } else {
      _titleController.clear();
      _messageController.clear();
      _category = 'general';
      _selectedDepartment = null;
      isDeptAnnouncement = false;
    }
    setState(() {
      sendEmail = false;
      sendToStudents = false;
      sendToStaff = false;
      sendToHod = false;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              announcement == null ? 'New Announcement' : 'Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Department Announcement'),
                  value: isDeptAnnouncement,
                  onChanged: announcement == null
                      ? (value) =>
                          setDialogState(() => isDeptAnnouncement = value)
                      : null,
                ),
                if (isDeptAnnouncement && departments.isNotEmpty)
                  DropdownButton<String>(
                    value: _selectedDepartment ?? departments.first,
                    hint: const Text('Select Department'),
                    onChanged: (value) =>
                        setDialogState(() => _selectedDepartment = value),
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                  ),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
                DropdownButton<String>(
                  value: _category,
                  onChanged: (value) =>
                      setDialogState(() => _category = value!),
                  items: [
                    'bus',
                    'placement',
                    'class_suspension',
                    'event',
                    'general'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                if (announcement == null) ...[
                  SwitchListTile(
                    title: const Text('Send Email'),
                    value: sendEmail,
                    onChanged: (value) =>
                        setDialogState(() => sendEmail = value),
                  ),
                  if (sendEmail) ...[
                    SwitchListTile(
                      title: const Text('To Students'),
                      value: sendToStudents,
                      onChanged: (value) =>
                          setDialogState(() => sendToStudents = value),
                    ),
                    SwitchListTile(
                      title: const Text('To Staff'),
                      value: sendToStaff,
                      onChanged: (value) =>
                          setDialogState(() => sendToStaff = value),
                    ),
                    if (!isDeptAnnouncement)
                      SwitchListTile(
                        title: const Text('To HOD'),
                        value: sendToHod,
                        onChanged: (value) =>
                            setDialogState(() => sendToHod = value),
                      ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (isDeptAnnouncement && _selectedDepartment == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a department')),
                  );
                  return;
                }
                if (announcement == null) {
                  _createAnnouncement();
                } else {
                  _updateAnnouncement(announcement['id']);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (jwtToken == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view and manage announcements'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _showAnnouncementDialog(),
              child: const Text('Create Announcement'),
            ),
            const SizedBox(height: 16),
            const Text('General Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: generalAnnouncements.isEmpty && deptAnnouncements.isEmpty
                  ? const Center(child: Text('No announcements available'))
                  : ListView(
                      children: [
                        ...generalAnnouncements
                            .map((a) => _buildAnnouncementTile(a, false))
                            ,
                        if (deptAnnouncements.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Department Announcements',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ...deptAnnouncements
                              .map((a) => _buildAnnouncementTile(a, true))
                              ,
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(
      Map<String, dynamic> announcement, bool isDept) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(announcement['category']),
          child: Icon(_getIcon(announcement['category']), color: Colors.white),
        ),
        title: Text(announcement['title']),
        subtitle: Text(
          '${announcement['message']}${isDept ? '\nDepartment: ${announcement['departmentcode']}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  _showAnnouncementDialog(announcement: announcement),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteAnnouncement(announcement['id'], isDept),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(announcement['title']),
              content: Text(
                '${announcement['message']}\n\nCategory: ${announcement['category']}\nCreated: ${announcement['created_at']}${isDept ? '\nDepartment: ${announcement['departmentcode']}' : ''}',
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
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'bus':
        return Colors.orange;
      case 'placement':
        return Colors.purple;
      case 'class_suspension':
        return Colors.red;
      case 'event':
        return Colors.green;
      case 'general':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'bus':
        return Icons.directions_bus;
      case 'placement':
        return Icons.work;
      case 'class_suspension':
        return Icons.warning;
      case 'event':
        return Icons.event;
      case 'general':
        return Icons.info;
      default:
        return Icons.help;
    }
  }
}
