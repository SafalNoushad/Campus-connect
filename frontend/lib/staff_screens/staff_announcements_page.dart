import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/network_config.dart';

class StaffAnnouncementsPage extends StatefulWidget {
  const StaffAnnouncementsPage({super.key});

  @override
  _StaffAnnouncementsPageState createState() => _StaffAnnouncementsPageState();
}

class _StaffAnnouncementsPageState extends State<StaffAnnouncementsPage> {
  List generalAnnouncements = [];
  List deptAnnouncements = [];
  bool isLoading = true;
  String? jwtToken;

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
        await _fetchGeneralAnnouncements();
        await _fetchDeptAnnouncements();
      }
    } catch (e) {
      debugPrint('Error loading token: $e');
    } finally {
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (jwtToken == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('General Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: generalAnnouncements.isEmpty && deptAnnouncements.isEmpty
                  ? const Center(child: Text('No announcements available'))
                  : ListView(
                      children: [
                        ...generalAnnouncements
                            .map((a) => _buildAnnouncementTile(a))
                            ,
                        if (deptAnnouncements.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Department Announcements',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ...deptAnnouncements
                              .map((a) => _buildAnnouncementTile(a))
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

  Widget _buildAnnouncementTile(Map<String, dynamic> announcement) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(announcement['category']),
          child: Icon(_getIcon(announcement['category']), color: Colors.white),
        ),
        title: Text(announcement['title']),
        subtitle: Text(announcement['message']),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(announcement['title']),
              content: Text(
                  '${announcement['message']}\n\nCategory: ${announcement['category']}\nCreated: ${announcement['created_at']}'),
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
