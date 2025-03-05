import 'package:flutter/material.dart';
import 'academics_page.dart';
import 'announcements_page.dart';
import 'profile_page.dart';
import 'chatbot_page.dart'; // ✅ Added ChatbotPage

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      const HomeContent(),
      const ChatbotPage(), // ✅ Added ChatbotPage
      const AcademicsPage(),
      const AnnouncementsPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _widgetOptions.length) {
      // ✅ Prevents RangeError
      setState(() {
        _selectedIndex = index;
      });
    } else {
      print("Invalid index: $index"); // ✅ Debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Connect'),
        actions: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColorLight,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : "?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _selectedIndex < _widgetOptions.length
          ? _widgetOptions[_selectedIndex]
          : const Center(child: Text("Page Not Found")), // ✅ Prevents crash
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat), label: 'Chatbot'), // ✅ Chatbot fixed
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Campus Connect!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildFeatureCard(context, 'Subjects', Icons.book),
                _buildFeatureCard(context, 'Exam Details', Icons.assignment),
                _buildFeatureCard(context, 'Teachers Info', Icons.person),
                _buildFeatureCard(context, 'Assignments', Icons.description),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You tapped on $title')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
