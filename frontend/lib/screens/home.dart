import 'package:flutter/material.dart';
import 'academics_page.dart';
import 'announcements_page.dart';
import 'profile_page.dart';
import 'chatbot_page.dart';

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
      const AcademicsPage(),
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
        return "Welcome, $userName!"; // ✅ Home Screen
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
              // ✅ Navigate to notifications page (You can add a notifications screen later)
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

class HomeContent extends StatelessWidget {
  final Map<String, String> userData;

  const HomeContent({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    String userName = userData['name'] ?? "Guest"; // Use 'name' from backend

    return Center(
      child: Text(
        "Welcome, $userName!",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
