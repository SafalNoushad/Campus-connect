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

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Read the JWT token from secure storage
    String? token = await storage.read(key: "jwt_token");
    debugPrint("JWT Token from storage: $token");
    setState(() {
      jwtToken = token;
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
            backgroundColor: const Color.fromARGB(255, 86, 97, 96),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Set initial route based on whether a JWT token exists
      initialRoute: jwtToken == null ? '/' : '/home',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        // Handle /home route with a fallback userName
        '/home': (context) {
          // Check for arguments passed during navigation (optional)
          final String userName =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          debugPrint("Building HomeScreen with userName: $userName");
          return HomeScreen(userName: userName);
        },
      },
    );
  }
}
