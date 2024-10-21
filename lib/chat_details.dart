import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final String otherUserId; // The ID of the other user (professional or customer)
  final String otherUserName; // Name of the other user (for display purposes)
  final String otherUserAvatarUrl; // Avatar URL for display purposes

  const ChatDetailPage({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  bool isSending = false;
  String? chatId;

  @override
  void initState() {
    super.initState();
    _initializeChatId();
  }

  // Initialize chat ID based on the current user and other user IDs
  void _initializeChatId() {
    if (currentUser != null) {
      List<String> ids = [currentUser!.uid, widget.otherUserId];
      ids.sort(); // Sort to ensure the same chat ID regardless of who is the sender or receiver
      chatId = ids.join('_'); // Combine the IDs to form the chat ID
    }
  }

  // Send Message (either text or image)
  Future<void> _sendMessage({String? textMessage, String? imageUrl}) async {
    if (chatId == null || currentUser == null) return;

    setState(() {
      isSending = true;
    });

    try {
      // Message data
      Map<String, dynamic> messageData = {
        'senderId': currentUser!.uid,
        'receiverId': widget.otherUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': imageUrl != null ? 'image' : 'text',
      };

      if (textMessage != null) {
        messageData['text'] = textMessage;
      } else if (imageUrl != null) {
        messageData['imageUrl'] = imageUrl;
      }

      // Store the message in the shared "chats" collection for both users
      await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);

      _scrollToBottom();
    } catch (error) {
      print("Error sending message: $error");
    } finally {
      setState(() {
        isSending = false;
      });
      _messageController.clear();
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

  // Pick an image and send it as a message
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _sendImageMessage(pickedFile);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  // Upload the image and send it as a message
  Future<void> _sendImageMessage(XFile imageFile) async {
    try {
      final ref = _storage.ref().child('chats/$chatId/${imageFile.name}');
      await ref.putFile(File(imageFile.path));
      final imageUrl = await ref.getDownloadURL();
      _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // Build the message input field
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.photo), onPressed: _pickImage),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: isSending ? const CircularProgressIndicator() : const Icon(Icons.send),
            onPressed: () {
              if (!isSending && _messageController.text.isNotEmpty) {
                _sendMessage(textMessage: _messageController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  // Build a text message widget
  Widget _buildTextMessage(String message, bool isSentByCurrentUser) {
    return Align(
      alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSentByCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(message, style: TextStyle(color: isSentByCurrentUser ? Colors.white : Colors.black)),
      ),
    );
  }

  // Build an image message widget
  Widget _buildImageMessage(String imageUrl, bool isSentByCurrentUser) {
    return Align(
      alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.network(imageUrl, height: 200, width: 200, fit: BoxFit.cover),
        ),
      ),
    );
  }

  // Build the chat UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.otherUserAvatarUrl)),
            const SizedBox(width: 10),
            Text(widget.otherUserName, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isSentByCurrentUser = messageData['senderId'] == currentUser?.uid;

                    if (messageData['type'] == 'text') {
                      return _buildTextMessage(messageData['text'], isSentByCurrentUser);
                    } else if (messageData['type'] == 'image') {
                      return _buildImageMessage(messageData['imageUrl'], isSentByCurrentUser);
                    }
                    return Container();
                  },
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
