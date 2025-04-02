import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/network_config.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  RequestsPageState createState() => RequestsPageState();
}

class RequestsPageState extends State<RequestsPage> {
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _approvedRequests = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchRequests();
  }

  Future<void> _loadTokenAndFetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token');
    });
    print('Token loaded: $_token');
    if (_token != null) {
      await _fetchRequests();
    } else {
      print('No token found, redirecting to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.getBaseUrl()}/api/hod/requests'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print(
          'Fetch Requests Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pendingRequests = List<Map<String, dynamic>>.from(data['pending']);
          _approvedRequests = List<Map<String, dynamic>>.from(data['approved']);
          _isLoading = false;
        });
        if (_pendingRequests.isEmpty && _approvedRequests.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No requests found')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching requests: $e')),
      );
    }
  }

  Future<void> _updateRequestStatus(int applicationId, String status) async {
    print('Starting update for request $applicationId to status: $status');
    try {
      final updateResponse = await http.put(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/hod/requests/$applicationId/update'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );
      print(
          'Update Request Response: ${updateResponse.statusCode} - ${updateResponse.body}');

      if (updateResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully!')),
        );
        await _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update request: ${updateResponse.body}')),
        );
      }
    } catch (e) {
      print('Error updating request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: $e')),
      );
    }
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      print('Storage permission already granted');
    } else if (await Permission.storage.request().isGranted) {
      print('Storage permission granted');
    } else {
      print('Storage permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  Future<void> _downloadAndOpenRequest(String filename) async {
    await _requestStoragePermission();
    print('Attempting to download file: $filename');
    try {
      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.getBaseUrl()}/api/hod/download/requests/$filename'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      print('Download Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded to: $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request downloaded to $filePath')),
        );
        final result = await OpenFile.open(filePath);
        print('Open file result: ${result.message}');
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file: ${result.message}')),
          );
        }
      } else {
        print('Download failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download request: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error downloading request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading request: $e')),
      );
    }
  }

  Widget _buildRequestList(
      List<Map<String, dynamic>> requests, bool isPending) {
    if (requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No requests in this category',
            style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.request_page, color: Colors.grey),
            title: Text(
              request['category'].replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${request['admission_number']}'),
                Text('Status: ${request['status']}'),
                Text('Submitted: ${request['created_at'].substring(0, 10)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () => _downloadAndOpenRequest(request['filename']),
                ),
                if (isPending) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _updateRequestStatus(
                        request['application_id'] ?? 0, 'approved'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _updateRequestStatus(
                        request['application_id'] ?? 0, 'rejected'),
                  ),
                ],
              ],
            ),
            onTap: () {
              // Optionally show more details if needed
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
            tooltip: 'Refresh Requests',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Requests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildRequestList(_pendingRequests, true),
                  const SizedBox(height: 20),
                  const Text(
                    'Approved/Rejected Requests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildRequestList(_approvedRequests, false),
                ],
              ),
            ),
    );
  }
}
