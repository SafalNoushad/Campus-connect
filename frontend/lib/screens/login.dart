import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
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

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'admission_number', userData['admission_number'] ?? "");
    await prefs.setString('role', userData['role'] ?? "");
    await prefs.setString('email', userData['email'] ?? "N/A");
    await prefs.setString('phone', userData['phone'] ?? "N/A");
    await prefs.setString('name', userData['name'] ?? "User");
    await prefs.setString('department', userData['department'] ?? "Unknown");
    await prefs.setString('location', userData['location'] ?? "Unknown");
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage("Login Failed: Please fill all fields", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String admissionNumber = admissionNumberController.text;
    final String password = passwordController.text;
    final String baseUrl = NetworkConfig.getBaseUrl(); // ✅ Get correct API URL

    print("Sending login request to: $baseUrl/api/auth/login");

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/api/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "admission_number": admissionNumber,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 8)); // ✅ Prevent infinite waiting

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user =
            responseData['user'] ?? {}; // ✅ Ensure user data is present

        await _saveUserData(user); // ✅ Save user details safely

        String userName = user['name'] ?? "User"; // ✅ Use default value if null

        _showMessage("Login Successful", Colors.green);

        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(userName: userName), // ✅ Pass safely
            ),
          );
        });
      } else {
        final responseData = jsonDecode(response.body);
        _showMessage(
            "Login Failed: ${responseData['error'] ?? 'Unknown error'}",
            Colors.red);
      }
    } catch (e) {
      print("Login error: $e");
      _showMessage("Login Failed: Network error", Colors.red);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showMessage(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                    color: Theme.of(context)
                        .primaryColor, // ✅ Old color theme restored
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your admission number';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).primaryColor, // ✅ Old theme applied
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
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
