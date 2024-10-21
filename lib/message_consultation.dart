import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({Key? key}) : super(key: key);

  @override
  _ConsultPageState createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  User? currentUser;
  List<Map<String, dynamic>> contactedProfessionals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadContactedProfessionals();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadContactedProfessionals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? consultedProfessionalsIds = prefs.getStringList('consultedProfessionals');
    List<Map<String, dynamic>> fetchedProfessionals = [];

    if (consultedProfessionalsIds != null) {
      for (String professionalId in consultedProfessionalsIds) {
        DatabaseReference ref = FirebaseDatabase.instance.ref('professionals/$professionalId');
        final snapshot = await ref.get();

        if (snapshot.exists) {
          var professionalData = snapshot.value as Map<dynamic, dynamic>;
          fetchedProfessionals.add({
            'avatarUrl': professionalData['avatarUrl'] ?? 'https://via.placeholder.com/150',
            'name': professionalData['name'] ?? 'Professional',
            'professionalId': professionalId,
          });
        }
      }
    }

    setState(() {
      contactedProfessionals = fetchedProfessionals;
      isLoading = false;
    });
  }

  Widget _buildContactedProfessionalsList() {
    return ListView.builder(
      itemCount: contactedProfessionals.length,
      itemBuilder: (context, index) {
        var professional = contactedProfessionals[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(professional['avatarUrl']),
          ),
          title: Text(professional['name']),
          onTap: () {
            // Generate a unique chatId using the customer and professional IDs
            String chatId = "${currentUser!.uid}_${professional['professionalId']}";
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatId: chatId,
                  otherUserName: professional['name'],
                  otherUserId: professional['professionalId'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentUser == null
          ? const Center(child: Text('Create an account to consult with professionals'))
          : contactedProfessionals.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No contacts yet'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectProfessionalPage(
                      currentUserId: currentUser!.uid,
                    ),
                  ),
                );
              },
              child: const Text('Click to Consult'),
            ),
          ],
        ),
      )
          : _buildContactedProfessionalsList(),
    );
  }
}

class SelectProfessionalPage extends StatefulWidget {
  final String currentUserId;

  const SelectProfessionalPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _SelectProfessionalPageState createState() => _SelectProfessionalPageState();
}

class _SelectProfessionalPageState extends State<SelectProfessionalPage> {
  List<Map<String, String>> professionals = [];
  List<String> contactedProfessionals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactedProfessionals();
    _fetchProfessionals();
  }

  Future<void> _loadContactedProfessionals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    contactedProfessionals = prefs.getStringList('consultedProfessionals') ?? [];
  }

  Future<void> _fetchProfessionals() async {
    try {
      final storageRef = FirebaseDatabase.instance.ref().child('Professionals');
      final snapshot = await storageRef.get();

      List<Map<String, String>> fetchedProfessionals = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> professionalsData = snapshot.value as Map<dynamic, dynamic>;

        professionalsData.forEach((email, professionalData) {
          final name = professionalData['name'] ?? 'Unknown';
          final profileImageUrl = professionalData['avatarUrl'] ?? 'https://via.placeholder.com/150';
          if (!contactedProfessionals.contains(email)) {
            fetchedProfessionals.add({
              'email': email,
              'name': name,
              'profileImageUrl': profileImageUrl,
            });
          }
        });
      }

      setState(() {
        professionals = fetchedProfessionals;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching professionals: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToChat(String email, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> consultedProfessionals = prefs.getStringList('consultedProfessionals') ?? [];
    consultedProfessionals.add(email);
    await prefs.setStringList('consultedProfessionals', consultedProfessionals);

    setState(() {
      professionals.removeWhere((professional) => professional['email'] == email);
    });

    String chatId = "${widget.currentUserId}_$email";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          otherUserName: name,
          otherUserId: email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Professionals'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          var professional = professionals[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(professional['profileImageUrl']!),
            ),
            title: Text(professional['name']!),
            subtitle: Text(professional['email']!),
            onTap: () => _navigateToChat(professional['email']!, professional['name']!),
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref().child('chats');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isSending = false;

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    String senderId = _auth.currentUser!.uid;
    String text = _messageController.text.trim();
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> message = {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': 'text',
    };

    await _chatRef.child(widget.chatId).child('messages').push().set(message);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatRef.child(widget.chatId).child('messages').orderByChild('timestamp').onValue,
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> messagesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<MessageWidget> messageWidgets = [];

                  messagesMap.forEach((key, messageData) {
                    final messageText = messageData['text'];
                    final senderId = messageData['senderId'];
                    final isMe = senderId == _auth.currentUser!.uid;

                    messageWidgets.add(MessageWidget(
                      text: messageText,
                      isMe: isMe,
                    ));
                  });

                  return ListView(
                    controller: _scrollController,
                    children: messageWidgets,
                  );
                } else {
                  return const Center(child: Text('No messages yet'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: isSending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isMe;

  const MessageWidget({
    Key? key,
    required this.text,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
