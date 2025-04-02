import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash.dart';
import 'login.dart';
import 'student_screens/home.dart';
import 'student_screens/chatbot.dart';
import 'admin_screens/admin_dashboard.dart';
import 'staff_screens/staff_dashboard.dart';
import 'hod_screens/hod_dashboard.dart';
import 'admin_screens/departments_page.dart';

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
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      debugPrint(
          'Starting _loadUserData - All SharedPreferences keys: ${prefs.getKeys()}');
      debugPrint(
          'Raw user_role from SharedPreferences: ${prefs.getString('user_role')}');
      debugPrint(
          'Raw jwt_token from SharedPreferences: ${prefs.getString('jwt_token')}');

      // Ensure splash screen is visible for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        jwtToken = prefs.getString('jwt_token');
        String? rawRole = prefs.getString('user_role');
        userData = {
          "name": prefs.getString('username') ?? "Guest",
          "email": prefs.getString('email') ?? "N/A",
          "phone": prefs.getString('phone') ?? "N/A",
          "admission_number": prefs.getString('admission_number') ?? "N/A",
          "role": rawRole ?? "N/A",
        };
        debugPrint('After setState - userData[role]: ${userData['role']}');
        isLoading = false;
      });

      debugPrint("✅ Loaded User Data: $userData");
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false; // Proceed to login screen on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp - isLoading: $isLoading, jwtToken: $jwtToken');
    if (isLoading) {
      return MaterialApp(
        title: 'Campus Connect',
        theme: ThemeData(
          primaryColor: const Color(0xFF0C6170),
          hintColor: const Color(0xFF37BEB0),
          scaffoldBackgroundColor: const Color(0xFFDBF5F0),
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      );
    }

    Widget homeScreen =
        jwtToken == null ? LoginScreen() : _getHomeScreenBasedOnRole();

    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primaryColor: const Color(0xFF0C6170),
        hintColor: const Color(0xFF37BEB0),
        scaffoldBackgroundColor: const Color(0xFFDBF5F0),
      ),
      debugShowCheckedModeBanner: false,
      home: homeScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(
              userData: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, String>?) ??
                  {"name": "Guest"},
            ),
        '/chatbot': (context) => ChatbotPage(),
        '/departments': (context) => const DepartmentPage(),
      },
    );
  }

  Widget _getHomeScreenBasedOnRole() {
    debugPrint("Navigating based on role: ${userData['role']}");
    switch (userData['role']) {
      case 'admin':
        return AdminDashboard();
      case 'staff':
        return const StaffDashboard();
      case 'hod':
        return const HodDashboard();
      case 'student':
        return HomeScreen(userData: userData);
      default:
        return LoginScreen();
    }
  }
}
