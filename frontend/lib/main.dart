import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/home.dart';

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

    // Simulate a delay to ensure SplashScreen is visible
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      jwtToken = prefs.getString('jwtToken');
      userData = {
        "name": prefs.getString('name') ?? "Guest",
        "email": prefs.getString('email') ?? "N/A",
        "phone": prefs.getString('phone') ?? "N/A",
        "admission_number": prefs.getString('admission_number') ?? "N/A",
        "role": prefs.getString('role') ?? "N/A",
        "department": prefs.getString('department') ?? "N/A",
        "location": prefs.getString('location') ?? "N/A",
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
          : const LoginScreen(), // Always go to LoginScreen after splash
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => HomeScreen(
              userData: (ModalRoute.of(context)?.settings.arguments
                      as Map<String, String>?) ??
                  {"name": "Guest"},
            ),
      },
    );
  }
}
