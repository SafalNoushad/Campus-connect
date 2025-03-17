import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/network_config.dart';
import 'home.dart';
import 'admin_dashboard.dart';
import '../staff_screens/staff_dashboard.dart';
import '../hod_screens/hod_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController admissionNumberController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isCheckingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? role =
        prefs.getString('user_role'); // Updated to 'user_role' to match backend

    if (token != null) {
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else if (role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StaffDashboard()),
        );
      } else if (role == 'hod') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HodDashboard()),
        );
      } else if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userData: {
              'name': prefs.getString('username') ??
                  "User", // Updated to 'username'
              'email': prefs.getString('email') ?? "N/A",
              'phone': prefs.getString('phone_number') ??
                  "N/A", // Updated to 'phone_number'
              'admission_number': prefs.getString('admission_number') ?? "",
            }),
          ),
        );
      }
    }

    setState(() {
      isCheckingRole = false;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String admissionNumber = admissionNumberController.text;
    String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admission_number': admissionNumber,
          'password': password,
        }),
      );

      print('Login Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString(
            'user_role', data['user']['role']); // Updated to 'user_role'
        await prefs.setString(
            'username', data['user']['username']); // Updated to 'username'
        await prefs.setString('email', data['user']['email']);
        await prefs.setString('phone_number',
            data['user']['phone_number'] ?? 'N/A'); // Updated to 'phone_number'
        await prefs.setString(
            'admission_number', data['user']['admission_number']);
        await prefs.setString(
            'departmentcode',
            data['user']['departmentcode'] ??
                ''); // Already present, kept for consistency

        switch (data['user']['role']) {
          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
            break;
          case 'staff':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StaffDashboard()),
            );
            break;
          case 'hod':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HodDashboard()),
            );
            break;
          case 'student':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userData: {
                  'name': data['user']['username'],
                  'email': data['user']['email'],
                  'phone': data['user']['phone_number'] ?? 'N/A',
                  'admission_number': data['user']['admission_number'],
                }),
              ),
            );
            break;
          default:
            _showMessage('Unknown role: ${data['user']['role']}', Colors.red);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(errorData['error'] ?? 'Login failed', Colors.red);
      }
    } catch (e) {
      _showMessage('Login failed: $e', Colors.red);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCheckingRole
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Campus Connect',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: admissionNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Admission Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your admission number'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Login',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
