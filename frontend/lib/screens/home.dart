import 'package:flutter/material.dart';
import 'academics_page.dart';
import 'announcements_page.dart';
import 'profile_page.dart';
import 'chatbot.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String> userData; // Accept full user data

  const HomeScreen({super.key, required this.userData});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;
  late String userName;

  @override
  void initState() {
    super.initState();
    userName = widget.userData['name'] ?? "User"; // Use 'name' from backend
    _initializePages();
  }

  void _initializePages() {
    _widgetOptions = [
      HomeContent(userData: widget.userData),
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

  // ✅ Function to dynamically update the title based on the selected page
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Welcome, $userName"; // ✅ Home Screen
      case 1:
        return "Chatbot"; // ✅ Chatbot Page
      case 2:
        return "Academics"; // ✅ Academics Page
      case 3:
        return "Announcements"; // ✅ Announcements Page
      case 4:
        return "Profile"; // ✅ Profile Page
      default:
        return "Campus Connect";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(), // ✅ Dynamic title updates
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications), // ✅ Notification Icon
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications clicked!")),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
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

// ✅ Home Content Section with Welcome Message
class HomeContent extends StatelessWidget {
  final Map<String, String> userData;

  const HomeContent({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    String userName = userData['name'] ?? "Guest"; // Use 'name' from backend

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName!', // ✅ Dynamic welcome message
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
