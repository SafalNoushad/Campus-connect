import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController admissionNumberController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    admissionNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      _showMessage("Login Failed: Please fill all fields", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String admissionNumber = admissionNumberController.text;
    final String password = passwordController.text;

    print(
        "Sending login request: admission_number=$admissionNumber, password=$password");

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.181:5001/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "admission_number": admissionNumber,
          "password": password,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _showMessage("Login Successful", Colors.green);
        Future.delayed(const Duration(milliseconds: 500), () {
          print(
              "Redirecting to HomeScreen with username: ${responseData['user']['username']}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userName: responseData['user']['username'],
              ),
            ),
          );
        });
      } else {
        // Log the error without assuming JSON
        _showMessage(
            "Login Failed: ${response.statusCode} - ${response.reasonPhrase}",
            Colors.red);
        print("Error details: ${response.body}");
      }
    } catch (e) {
      print("Login exception: $e");
      _showMessage("Login Failed: $e", Colors.red);
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
        child: FadeTransition(
          opacity: _fadeAnimation,
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
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
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
      ),
    );
  }
}
