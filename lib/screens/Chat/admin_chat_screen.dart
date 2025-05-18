import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/chat.dart';

class GovernmentChatDetailScreen extends StatefulWidget {
  final String citizenId;
  final String citizenName;

  const GovernmentChatDetailScreen({
    Key? key,
    required this.citizenId,
    required this.citizenName,
  }) : super(key: key);

  @override
  State<GovernmentChatDetailScreen> createState() =>
      _GovernmentChatDetailScreenState();
}

class _GovernmentChatDetailScreenState
    extends State<GovernmentChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    final user = _authService.currentUser;

    if (text.isEmpty || user == null) return;

    try {
      await _chatService.sendMessage(
        text: text,
        toGov: false,
        conversationCitizenId: widget.citizenId,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print("GovernmentChatDetailScreen: Error sending message: $e");
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
        title: Text('Chat with ${widget.citizenName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getConversationStream(widget.citizenId),
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
              'Send a message to start the conversation with ${widget.citizenName}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isSentByMe = message.senderId == 'government';

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
              child: Text(
                widget.citizenName.isNotEmpty
                    ? widget.citizenName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.black87),
              ),
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
                'G',
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
              onSubmitted: (_) => _sendMessage(),
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
              onPressed: _sendMessage,
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
