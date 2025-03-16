import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatSessions = [];
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  int _selectedChatIndex = -1;
  String _chatTitle = "New Chat";

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatData = prefs.getString('chat_sessions');
    if (chatData != null) {
      setState(() {
        _chatSessions = List<Map<String, dynamic>>.from(jsonDecode(chatData));
        for (var session in _chatSessions) {
          if (session['messages'] != null) {
            session['messages'] = List<Map<String, String>>.from(
                (session['messages'] as List)
                    .map((msg) => Map<String, String>.from(msg)));
          }
        }
        if (_chatSessions.isNotEmpty && _selectedChatIndex == -1) {
          _selectedChatIndex = 0;
          _chatTitle = _chatSessions[0]['name'] ?? "Chat 1";
          _messages = List<Map<String, String>>.from(
              _chatSessions[0]['messages'] ?? []);
        }
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsToSave = _chatSessions.map((session) {
      return {
        'name': session['name'],
        'messages': List<Map<String, String>>.from(session['messages'] ?? [])
      };
    }).toList();
    await prefs.setString('chat_sessions', jsonEncode(sessionsToSave));
  }

  Future<void> _sendMessage({PlatformFile? file}) async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty && file == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in first")),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      if (userMessage.isNotEmpty) {
        _messages.add({"sender": "user", "text": userMessage});
      }
      if (file != null) {
        _messages.add({"sender": "user", "text": "Uploaded: ${file.name}"});
      }
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:5001/api/chatbot/chat"),
      );
      request.headers['Authorization'] = 'Bearer $token';

      if (userMessage.isNotEmpty) request.fields['message'] = userMessage;
      if (file != null) {
        if (file.size > 10 * 1024 * 1024) {
          // 10MB limit
          throw Exception("File size exceeds 10MB limit");
        }
        request.files
            .add(await http.MultipartFile.fromPath('file', file.path!));
      }

      final response =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody.body);
        setState(() {
          if (responseData.containsKey("summary")) {
            _messages.add({
              "sender": "bot",
              "text": "Summary: ${responseData['summary']}"
            });
            _messages.add({
              "sender": "bot",
              "text": "Description: ${responseData['description']}"
            });
          } else {
            final botResponse =
                responseData["response"] ?? "No response from server";
            _messages.add({"sender": "bot", "text": botResponse});
          }
        });
      } else {
        final errorData = jsonDecode(responseBody.body);
        setState(() {
          _messages.add({
            "sender": "bot",
            "text":
                "Error: ${errorData['error'] ?? 'Status ${response.statusCode}'}"
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "bot", "text": "Error: ${e.toString()}"});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      _updateChatSessions();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _renameChat() {
    TextEditingController _renameController =
        TextEditingController(text: _chatTitle);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Chat"),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(hintText: "Enter new chat name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _chatTitle = _renameController.text;
                  if (_selectedChatIndex != -1) {
                    _chatSessions[_selectedChatIndex]["name"] = _chatTitle;
                  } else if (_messages.isNotEmpty) {
                    _chatSessions
                        .add({"name": _chatTitle, "messages": _messages});
                    _selectedChatIndex = _chatSessions.length - 1;
                  }
                });
                _saveChatHistory();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _updateChatSessions() {
    if (_selectedChatIndex == -1 && _messages.isNotEmpty) {
      _chatSessions.add({
        "name": _chatTitle,
        "messages": List<Map<String, String>>.from(_messages)
      });
      _selectedChatIndex = _chatSessions.length - 1;
    } else if (_selectedChatIndex != -1) {
      _chatSessions[_selectedChatIndex]["messages"] =
          List<Map<String, String>>.from(_messages);
    }
    _saveChatHistory();
  }

  Future<void> _showUploadDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload PDF"),
          content:
              const Text("Please upload a PDF file (max 10MB) to summarize."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadFile();
              },
              child: const Text("Upload"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf'],
      type: FileType.custom,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      await _sendMessage(file: file);
    }
  }

  void _deleteChat(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Chat"),
          content: const Text("Are you sure you want to delete this chat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _chatSessions.removeAt(index);
                  if (_selectedChatIndex == index) {
                    _messages.clear();
                    _chatTitle = "New Chat";
                    _selectedChatIndex = -1;
                  } else if (_selectedChatIndex > index) {
                    _selectedChatIndex--;
                  }
                });
                _saveChatHistory();
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Column(
        children: [
          ListTile(
            title: const Text("Chat History"),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatSessions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title:
                      Text(_chatSessions[index]["name"] ?? "Chat ${index + 1}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteChat(index),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedChatIndex = index;
                      _messages = List<Map<String, String>>.from(
                          _chatSessions[index]["messages"] ?? []);
                      _chatTitle =
                          _chatSessions[index]["name"] ?? "Chat ${index + 1}";
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("New Chat"),
            onTap: () {
              setState(() {
                _messages.clear();
                _chatTitle = "New Chat";
                _selectedChatIndex = -1;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['sender'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
            onPressed: _showUploadDialog,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSidebar(),
      appBar: AppBar(
        title: Text(_chatTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _renameChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatArea()),
          if (_isLoading) const LinearProgressIndicator(),
          _buildInputField(),
        ],
      ),
    );
  }
}
