import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome, Admin!",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C6170)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Manage your campus efficiently from here.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.info, size: 40, color: Color(0xFF0C6170)),
                  const SizedBox(height: 10),
                  const Text(
                    "Quick Stats",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Users", "50"),
                      _buildStatItem("Departments", "5"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}
