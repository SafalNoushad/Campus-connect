import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const storage = FlutterSecureStorage();
  String? jwtToken;
  bool isLoading = true; // ✅ Used to control splash screen loading

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(
        const Duration(seconds: 2)); // ✅ Simulating splash delay
    String? token = await storage.read(key: "jwt_token");
    debugPrint("JWT Token from storage: $token");

    setState(() {
      jwtToken = token;
      isLoading = false; // ✅ Stop showing splash
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primaryColor: const Color(0xFF0C6170),
        hintColor: const Color(0xFF37BEB0),
        scaffoldBackgroundColor: const Color(0xFFDBF5F0),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0C6170)),
          bodyMedium: TextStyle(color: Color(0xFF0C6170)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF566160),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: isLoading
          ? const SplashScreen() // ✅ Show splash while loading
          : (jwtToken == null
              ? const LoginScreen()
              : const HomeScreen(userName: "User")), // ✅ Check login state
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) {
          final String userName =
              ModalRoute.of(context)?.settings.arguments as String? ?? "User";
          debugPrint("Building HomeScreen with userName: $userName");
          return HomeScreen(userName: userName);
        },
      },
    );
  }
}
