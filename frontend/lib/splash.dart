import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_screens/admin_dashboard.dart'; // ✅ Import Admin Dashboard

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');

    // ✅ Debugging: Print role to check stored value
    print("User Role from SharedPreferences: $role");

    await Future.delayed(const Duration(seconds: 3)); // Ensure animation plays

    if (mounted) {
      if (role == 'admin') {
        print("✅ Redirecting to Admin Dashboard");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      } else {
        print("✅ Redirecting to Login Page");
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 20),
                Text(
                  'Campus Connect',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
