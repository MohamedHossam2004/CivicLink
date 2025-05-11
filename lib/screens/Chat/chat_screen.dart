import 'package:flutter/material.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Simulated AI responses
  final List<String> _aiResponses = [
    "How can I help you today?",
    "I'm here to assist with any civic issues you might have.",
    "Feel free to ask me about city services or how to report problems.",
    "How can I make your community experience better?",
    "I'm your CivicLink assistant. What information do you need?",
    "I can help you navigate government services. What do you need?",
    "How can I assist you with your community concerns?",
    "I'm here to help with any questions about local services.",
    "What civic matters can I help you with today?",
    "I'm your virtual assistant for all city-related questions.",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _messageController.clear();

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI typing delay
    Future.delayed(Duration(milliseconds: 500 + Random().nextInt(2000)), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: _aiResponses[Random().nextInt(_aiResponses.length)],
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the list has updated
    Future.delayed(const Duration(milliseconds: 100), () {
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
        title: const Text('CivicLink Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about the assistant
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About CivicLink Assistant'),
                  content: const Text(
                      'The CivicLink Assistant helps you navigate city services, '
                      'report issues, and find information about your community. '
                      'This is a simulated version for demonstration purposes.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeMessage()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Typing...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _handleSubmitted(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 40,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CivicLink Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask me anything about city services, reporting issues, or community resources.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _handleSubmitted('Hello');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Start a conversation'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.teal),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.teal : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color:
                          isUser ? Colors.white.withOpacity(0.7) : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
