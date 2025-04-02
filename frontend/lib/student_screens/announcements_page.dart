import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/network_config.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List generalAnnouncements = [];
  List deptAnnouncements = [];
  bool isLoading = true;
  String? jwtToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load general announcements: ${response.body}')),
        );
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load department announcements: ${response.body}')),
        );
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view announcements'),
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
            const Text('General Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: generalAnnouncements.isEmpty && deptAnnouncements.isEmpty
                  ? const Center(child: Text('No announcements available'))
                  : ListView(
                      children: [
                        if (generalAnnouncements.isNotEmpty)
                          ...generalAnnouncements
                              .map((announcement) => _buildAnnouncementTile(
                                  announcement, 'General'))
                              .toList(),
                        if (deptAnnouncements.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Department Announcements',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ...deptAnnouncements
                              .map((announcement) => _buildAnnouncementTile(
                                  announcement, 'Department'))
                              .toList(),
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
      Map<String, dynamic> announcement, String type) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(announcement['category']),
          child: Icon(_getIcon(announcement['category']), color: Colors.white),
        ),
        title: Text(announcement['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${announcement['message']}\n${type}'),
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
