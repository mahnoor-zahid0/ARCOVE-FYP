// professional_chat.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Import the intl package

class ProfessionalChatPage extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ProfessionalChatPage({super.key, required this.name, required this.imageUrl});

  @override
  _ProfessionalChatPageState createState() => _ProfessionalChatPageState();
}

class _ProfessionalChatPageState extends State<ProfessionalChatPage> {
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hello, how can I help you?', 'isMe': false, 'time': '6:54 PM'},
    {'text': 'I need some assistance with my project.', 'isMe': true, 'time': '6:55 PM'},
    {'text': 'Sure, what do you need help with?', 'isMe': false, 'time': '6:56 PM'},
    {'text': 'Can you guide me through the initial setup?', 'isMe': true, 'time': '6:57 PM'},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.imageUrl),
            ),
            const SizedBox(width: 10),
            Text(widget.name),
          ],
        ),
        backgroundColor: const Color(0xFFB46146),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['isMe'];
                final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                final color = isMe ? Colors.green[100] : Colors.white;
                final textColor = isMe ? Colors.black : Colors.black;
                final borderRadius = isMe
                    ? const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                )
                    : const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                );

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    crossAxisAlignment: alignment,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: borderRadius,
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message['time'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFB46146)),
                  onPressed: () {
                    final text = _controller.text;
                    if (text.isNotEmpty) {
                      setState(() {
                        messages.add({
                          'text': text,
                          'isMe': true,
                          'time': DateFormat.jm().format(DateTime.now()), // Get current time
                        });
                        _controller.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
