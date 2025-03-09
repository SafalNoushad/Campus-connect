import 'package:flutter/material.dart';

class AcademicsPage extends StatelessWidget {
  const AcademicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildSection(context, 'Courses', Icons.book, [
          'Mathematics',
          'Physics',
          'Computer Science',
          'Literature',
        ]),
        _buildSection(context, 'Assignments', Icons.assignment, [
          'Math Homework - Due 05/15',
          'Physics Lab Report - Due 05/18',
          'CS Project - Due 05/20',
          'Literature Essay - Due 05/22',
        ]),
        _buildSection(context, 'Exams', Icons.event, [
          'Midterm Exams - 06/01 to 06/05',
          'Final Exams - 07/15 to 07/20',
        ]),
        _buildSection(context, 'Resources', Icons.folder, [
          'Online Library',
          'Study Groups',
          'Tutoring Services',
          'Academic Calendar',
        ]),
      ],
    );
  }

  Widget _buildSection(
      BuildContext context, String title, IconData icon, List<String> items) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items
            .map((item) => ListTile(
                  title: Text(item),
                  onTap: () {
                    // Handle item tap
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You tapped: $item')),
                    );
                  },
                ))
            .toList(),
      ),
    );
  }
}
