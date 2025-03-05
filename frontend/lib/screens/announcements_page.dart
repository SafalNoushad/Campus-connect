import 'package:flutter/material.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        children: [
          _buildAnnouncement(
            context,
            'Campus Closure',
            'The campus will be closed on May 25th for maintenance.',
            Icons.warning,
            Colors.red,
          ),
          _buildAnnouncement(
            context,
            'New Course Offerings',
            'Registration for fall semester courses is now open.',
            Icons.school,
            Colors.blue,
          ),
          _buildAnnouncement(
            context,
            'Student Council Elections',
            'Vote for your student representatives on June 1st.',
            Icons.how_to_vote,
            Colors.green,
          ),
          _buildAnnouncement(
            context,
            'Library Hours Extended',
            'The library will now be open until midnight during exam week.',
            Icons.access_time,
            Colors.orange,
          ),
          _buildAnnouncement(
            context,
            'Career Fair',
            'Don\'t miss the annual career fair on July 10th in the main hall.',
            Icons.work,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncement(BuildContext context, String title,
      String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        onTap: () {
          // Show full announcement details
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(title),
                content: Text(description),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
