import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/chat.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;

    if (_currentUser == null) {
      print("ChatScreen: Error - Current user is null.");
    }

    // Scroll to bottom after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _currentUser == null) return;

    try {
      await _chatService.sendMessage(
        text: text,
        toGov: true,
        citizenNameForConversation: _currentUser!.displayName ?? 'Citizen',
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print("ChatScreen: Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
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
        title: const Text('Chat with Government'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to chat'))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream:
                        _chatService.getConversationStream(_currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyChatMessage();
                      }

                      final messages = snapshot.data!;
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        reverse: true, // New messages at bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(messages[index]);
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInputArea(),
              ],
            ),
    );
  }

  Widget _buildEmptyChatMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No messages yet.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isSentByMe = message.senderId == _currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Text('G', style: TextStyle(color: Colors.black87)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.teal : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isSentByMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isSentByMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp.toDate()),
                    style: TextStyle(
                      color: isSentByMe
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                _currentUser?.displayName?.isNotEmpty == true
                    ? _currentUser!.displayName![0].toUpperCase()
                    : 'C',
                style: TextStyle(color: Colors.teal.shade800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmitted,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_messageController.text),
              tooltip: 'Send message',
            ),
          ),
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
