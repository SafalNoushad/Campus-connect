import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/chatbot.dart';
import 'screens/admin_dashboard.dart';
import 'staff_screens/staff_dashboard.dart'; // Add StaffDashboard import
import 'hod_screens/hod_dashboard.dart'; // Add HodDashboard import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool isLoading = true;
  String? jwtToken;
  Map<String, String> userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      jwtToken = prefs.getString('jwt_token');
      userData = {
        "name": prefs.getString('name') ?? "Guest",
        "email": prefs.getString('email') ?? "N/A",
        "phone": prefs.getString('phone') ?? "N/A",
        "admission_number": prefs.getString('admission_number') ?? "N/A",
        "role": prefs.getString('role') ?? "N/A",
      };
      isLoading = false;
    });

    debugPrint("✅ Loaded User Data: $userData");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primaryColor: const Color(0xFF0C6170),
        hintColor: const Color(0xFF37BEB0),
        scaffoldBackgroundColor: const Color(0xFFDBF5F0),
      ),
      debugShowCheckedModeBanner: false,
      home: isLoading
          ? const SplashScreen()
          : jwtToken == null
              ? LoginScreen()
              : _getHomeScreenBasedOnRole(), // Updated to handle all roles
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(
              userData: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, String>?) ??
                  {"name": "Guest"},
            ),
        '/chatbot': (context) => ChatbotPage(),
      },
    );
  }

  // New method to determine the home screen based on role
  Widget _getHomeScreenBasedOnRole() {
    switch (userData['role']) {
      case 'admin':
        return AdminDashboard();
      case 'staff':
        return const StaffDashboard();
      case 'hod':
        return const HodDashboard();
      case 'student': // Explicitly handle student role
        return HomeScreen(userData: userData);
      default:
        return LoginScreen(); // Fallback to login for unknown roles
    }
  }
}
