import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String admissionNumber = "";
  String role = "";
  String email = "";
  String phone = "";
  String name = "User";
  String department = "Unknown";
  String location = "Unknown";
  String profileImagePath = ""; // ✅ Path to profile image

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      admissionNumber = prefs.getString('admission_number') ?? "N/A";
      role = prefs.getString('role') ?? "N/A";
      email = prefs.getString('email') ?? "N/A";
      phone = prefs.getString('phone') ?? "N/A";
      name = prefs.getString('name') ?? "User";
      department = prefs.getString('department') ?? "Unknown";
      location = prefs.getString('location') ?? "Unknown";
      profileImagePath = prefs.getString('profile_image') ?? "";
    });

    nameController.text = name;
    emailController.text = email;
    phoneController.text = phone;
  }

  Future<void> _updateUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('phone', phoneController.text);

    setState(() {
      name = nameController.text;
      email = emailController.text;
      phone = phoneController.text;
    });

    Navigator.pop(context);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ✅ Clear saved user data
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', image.path);

      setState(() {
        profileImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickProfileImage, // ✅ Upload profile picture
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImagePath.isNotEmpty
                    ? FileImage(File(profileImagePath)) as ImageProvider
                    : const AssetImage('assets/default_profile.png'),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 15,
                    child: Icon(Icons.camera_alt,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '$department - ${role.toUpperCase()}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, email),
            const Divider(),
            _buildInfoRow(Icons.phone, phone),
            const Divider(),
            _buildInfoRow(Icons.location_on, location),
            const Divider(),
            _buildInfoRow(Icons.school, 'Admission No: $admissionNumber'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _showEditProfileDialog, // ✅ Edit details
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size(200, 40),
          ),
          child: const Text('Edit Profile'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _logout, // ✅ Logout function
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(200, 40),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _updateUserData, // ✅ Update data
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
