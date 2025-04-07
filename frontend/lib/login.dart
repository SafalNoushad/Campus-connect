import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/network_config.dart';
import 'student_screens/home.dart';
import 'admin_screens/admin_dashboard.dart';
import 'staff_screens/staff_dashboard.dart';
import 'hod_screens/hod_dashboard.dart';

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
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      String? role = prefs.getString('role');

      debugPrint('Checking stored credentials:');
      debugPrint('  Token: $token');
      debugPrint('  Role: $role');
      debugPrint('  All keys: ${prefs.getKeys()}');

      if (role != null) {
        _navigateBasedOnRole(role, prefs);
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    } finally {
      setState(() => isCheckingRole = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String admissionNumber = admissionNumberController.text.trim();
    String password = passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admission_number': admissionNumber,
          'password': password,
        }),
      );

      debugPrint('Login Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserData(data);
        _navigateBasedOnRole(
            data['user']['role'], await SharedPreferences.getInstance());
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg = errorData['error'] ?? 'Login failed';
        if (response.statusCode == 400) {
          errorMsg = 'Please provide admission number and password';
        } else if (response.statusCode == 401) {
          errorMsg = 'Invalid admission number or password';
        }
        _showMessage(errorMsg, Colors.red);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage('Network error: Check your connection', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', data['token']);
    await prefs.setString('role', data['user']['role']);
    await prefs.setString('username', data['user']['username']);
    await prefs.setString('email', data['user']['email']);
    await prefs.setString('admission_number', data['user']['admission_number']);
    await prefs.setString(
        'departmentcode', data['user']['departmentcode'] ?? 'Unknown');
    await prefs.setString('semester', data['user']['semester'] ?? 'N/A');

    debugPrint('Saved user data:');
    debugPrint('  Token: ${data['token'].substring(0, 10)}...');
    debugPrint('  Role: ${data['user']['role']}');
    debugPrint('  Username: ${data['user']['username']}');
    debugPrint('  Departmentcode: ${data['user']['departmentcode']}');
    debugPrint('  Semester: ${data['user']['semester']}');
  }

  void _navigateBasedOnRole(String role, SharedPreferences prefs) {
    debugPrint('Navigating based on role: $role');
    switch (role) {
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
              'name': prefs.getString('username') ?? 'User',
              'email': prefs.getString('email') ?? 'N/A',
              'phone': prefs.getString('phone_number') ?? 'N/A',
              'admission_number': prefs.getString('admission_number') ?? '',
            }),
          ),
        );
        break;
      default:
        _showMessage('Unknown role: $role', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    admissionNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
