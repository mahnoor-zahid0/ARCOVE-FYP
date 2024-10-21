
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('professionalId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatDoc = chatDocs[index];
              String customerId = chatDoc.id.split('_').first; // Assuming chatId format is "customerId_professionalId"

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('customers').doc(customerId).get(),
                builder: (context, customerSnapshot) {
                  if (!customerSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var customerData = customerSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                          customerData['avatarUrl'] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(customerData['name'] ?? 'Customer'),
                    subtitle: Text('Tap to view messages'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfessionalConsultationPage(
                            customerId: customerId,
                            customerName: customerData['name'] ?? 'Customer',
                            customerAvatarUrl: customerData['avatarUrl'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class ProfessionalConsultationPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerAvatarUrl;

  const ProfessionalConsultationPage({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.customerAvatarUrl,
  }) : super(key: key);

  @override
  _ProfessionalConsultationPageState createState() => _ProfessionalConsultationPageState();
}

class _ProfessionalConsultationPageState extends State<ProfessionalConsultationPage> {
  List<Map<String, String>> professionals = [];
  List<String> contactedProfessionals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactedProfessionals();
    _fetchProfessionals();
  }

  // Load contacted professionals from SharedPreferences
  Future<void> _loadContactedProfessionals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    contactedProfessionals = prefs.getStringList('consultedProfessionals') ?? [];
  }

  // Fetch professionals from Firebase Storage
  Future<void> _fetchProfessionals() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('Professionals');
      final ListResult result = await storageRef.listAll();
      List<Map<String, String>> fetchedProfessionals = [];

      for (var emailFolder in result.prefixes) {
        final email = emailFolder.name;
        final nameFolders = await emailFolder.listAll(); // Get subfolders (names)

        for (var nameFolder in nameFolders.prefixes) {
          final name = nameFolder.name;
          if (contactedProfessionals.contains('$email/$name')) continue;

          String profileImageUrl = await _getProfileImageUrl(email, name);
          fetchedProfessionals.add({
            'email': email,
            'name': name,
            'profileImageUrl': profileImageUrl,
          });
        }
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

  // Fetch profile image for professional
  Future<String> _getProfileImageUrl(String email, String name) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('Professionals/$email/$name/profile.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return 'https://via.placeholder.com/150'; // Default image if not available
    }
  }

  // Store consulted professional in SharedPreferences and navigate to chat
  void _startChatWithProfessional(String email, String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> consultedProfessionals = prefs.getStringList('consultedProfessionals') ?? [];
    consultedProfessionals.add('$email/$name');
    await prefs.setStringList('consultedProfessionals', consultedProfessionals);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(professionalEmail: email, professionalName: name),
      ),
    );
  }

  // Build UI for listing professionals
  Widget _buildProfessionalList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (professionals.isEmpty) {
      return const Center(child: Text('No professionals available for consultation.'));
    }

    return ListView.builder(
      itemCount: professionals.length,
      itemBuilder: (context, index) {
        var professional = professionals[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(professional['profileImageUrl']!),
          ),
          title: Text(professional['name']!),
          subtitle: Text(professional['email']!),
          onTap: () => _startChatWithProfessional(professional['email']!, professional['name']!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consult Professionals'),
      ),
      body: _buildProfessionalList(),
    );
  }
}


class ChatPage extends StatefulWidget {
  final String professionalEmail;
  final String professionalName;

  const ChatPage({Key? key, required this.professionalEmail, required this.professionalName})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool isSending = false;

  // Send message logic here (connect to Firebase)
  Future<void> _sendMessage({String? textMessage, String? imageUrl}) async {
    setState(() {
      isSending = true;
    });

    try {
      // Placeholder: Add logic to send message to Firebase (using Realtime Database or Firestore)
      await Future.delayed(const Duration(seconds: 1)); // Simulate message sending

      // Clear input field
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() {
        isSending = false;
      });
      _scrollToBottom();
    }
  }

  // Scroll to the bottom of the chat
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

  // Pick image and send as message
  Future<void> _pickAndSendImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _sendMessage(imageUrl: pickedFile.path); // Placeholder for image sending
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.photo), onPressed: _pickAndSendImage),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Type a message...'),
            ),
          ),
          IconButton(
            icon: isSending ? const CircularProgressIndicator() : const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage(textMessage: _messageController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.professionalName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 10, // Placeholder: replace with actual messages
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Message $index'),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
