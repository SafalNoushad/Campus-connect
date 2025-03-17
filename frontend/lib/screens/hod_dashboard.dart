import 'package:flutter/material.dart';

class HODDashboard extends StatelessWidget {
  final VoidCallback logout;
  HODDashboard({required this.logout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HOD Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("HOD Panel",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text("Manage Results"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ResultsApprovalPage())),
            ),
            ListTile(
              title: Text("Manage Events"),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => EventsPage())),
            ),
            ListTile(title: Text("Logout"), onTap: logout),
          ],
        ),
      ),
      body: Center(child: Text("Welcome to HOD Dashboard")),
    );
  }
}

class ResultsApprovalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Results")),
      body: Center(child: Text("Results Approval - TBD")),
    );
  }
}

class EventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Events")),
      body: Center(child: Text("Events Management - TBD")),
    );
  }
}
