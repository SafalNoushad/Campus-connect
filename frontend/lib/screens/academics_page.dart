import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/network_config.dart';

class StudentAcademicsPage extends StatefulWidget {
  const StudentAcademicsPage({super.key});

  @override
  _StudentAcademicsPageState createState() => _StudentAcademicsPageState();
}

class _StudentAcademicsPageState extends State<StudentAcademicsPage> {
  List<Map<String, dynamic>> _subjects = [];
  String? _token;
  String? _departmentCode;
  String? _batch;
  String? _currentSemester;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
      _departmentCode = prefs.getString('departmentcode');
      _batch = prefs.getString('batch');
      _currentSemester = _calculateCurrentSemester(); // Initial fallback
      _isLoading = true;
    });
    if (_token != null && _departmentCode != null && _batch != null) {
      await _fetchSubjects();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication data missing. Please log in again.')),
      );
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/student/subjects'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Fetched data: $data'); // Debug log
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(data['subjects'] ?? []);
          _currentSemester = data['semester'] ?? _calculateCurrentSemester();
          _isLoading = false;
        });
      } else {
        print('Failed response: ${response.body}'); // Debug log
        setState(() {
          _isLoading = false;
          _currentSemester = _calculateCurrentSemester(); // Fallback on failure
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error fetching subjects: $e'); // Debug log
      setState(() {
        _isLoading = false;
        _currentSemester = _calculateCurrentSemester(); // Fallback on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subjects: $e')),
      );
    }
  }

  String _calculateCurrentSemester() {
    if (_batch == null) return 'S1';
    final currentDate = DateTime.now();
    final currentYear = currentDate.year;
    final batchStartYear = int.tryParse(_batch!.split('-')[0]) ?? currentYear;
    final yearsElapsed = currentYear - batchStartYear; // 0-based
    final isSecondHalf = currentDate.month >= 7;
    final semestersCompleted = yearsElapsed * 2;
    final currentSemester = semestersCompleted + (isSecondHalf ? 2 : 1);
    final semesterNumber = currentSemester > 8 ? 8 : currentSemester;
    print('Frontend Calc - Batch: $_batch, Years Elapsed: $yearsElapsed, '
        'Is Second Half: $isSecondHalf, Semester: S$semesterNumber');
    return 'S$semesterNumber';
  }

  Widget _buildSubjects() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _subjects.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No subjects available',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    '${subject['subject_code']} - ${subject['subject_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Credits: ${subject['credits']}'),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      title: Text(
                        'Current Semester ($_currentSemester)',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      children: [
                        _buildSubjects(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
          });
          _fetchSubjects();
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
