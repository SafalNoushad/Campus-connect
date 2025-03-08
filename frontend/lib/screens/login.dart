import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'admin_dashboard.dart'; // ✅ Import AdminDashboard
import '../utils/network_config.dart'; // ✅ Import dynamic backend URL

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

  @override
  void dispose() {
    admissionNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ✅ Save user data with proper type conversion
  Future<void> _saveUserData(
      Map<String, dynamic> userData, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ Save each field properly
    await prefs.setString('jwtToken', token);
    await prefs.setString(
        'admission_number', userData['admission_number'] ?? "");
    await prefs.setString('name', userData['name'] ?? "User");
    await prefs.setString('email', userData['email'] ?? "N/A");
    await prefs.setString(
        'phone', userData['phone_number'] ?? "N/A"); // ✅ Handle missing phone
    await prefs.setString('role', userData['role'] ?? "guest");

    debugPrint("✅ User Data Saved: $userData");
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage("Login Failed: Please fill all fields", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${NetworkConfig.getBaseUrl()}/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "admission_number": admissionNumberController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('user')) {
          String token = responseData['token'];
          Map<String, dynamic> userData = responseData['user'];

          await _saveUserData(userData, token);

          debugPrint("✅ Passing User Data to HomeScreen: $userData");

          _showMessage("Login Successful", Colors.green);

          Future.delayed(const Duration(milliseconds: 500), () {
            if (userData['role'] == 'admin') {
              // ✅ Redirect admins to AdminDashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            } else {
              // ✅ Redirect students & teachers to HomeScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HomeScreen(userData: userData.cast<String, String>())),
              );
            }
          });
        } else {
          _showMessage(
              "Login Failed: Invalid response from server", Colors.red);
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _showMessage(
            "Login Failed: ${errorResponse['error'] ?? 'Invalid credentials'}",
            Colors.red);
      }
    } catch (e) {
      _showMessage("Login Failed: Network error", Colors.red);
      debugPrint("❌ Login Exception: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (!admissionNumberController.text
                        .endsWith("admin@mbcpeermade.com")) {
                      // ✅ Hide signup for admins
                      Navigator.pushNamed(context, '/signup');
                    } else {
                      _showMessage(
                          "Admins cannot sign up manually", Colors.red);
                    }
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
