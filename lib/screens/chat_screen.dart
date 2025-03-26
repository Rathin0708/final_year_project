import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  
  const ChatScreen({
    super.key, 
    required this.chatRoomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  List<ChatMessage> _previousMessages = [];
  late ChatProvider _chatProvider;
  
  @override
  void initState() {
    super.initState();
    print('Initializing ChatScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Setting current chat room to ${widget.chatRoomId}');
      try {
        Provider.of<ChatProvider>(context, listen: false).setCurrentChatRoom(widget.chatRoomId);
      } catch (e) {
        print('Error setting current chat room: $e');
        // You can also display an error message to the user here
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get initial messages and store provider reference
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _previousMessages = Provider.of<ChatProvider>(context).currentMessages;
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider.clearCurrentChatRoomSilently();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // For reversed ListView, minimum extent is the bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _shouldAutoScroll = true;
      Provider.of<ChatProvider>(context, listen: false).sendMessage(message);
      _messageController.clear();
      // Add a small delay before scrolling to make sure the UI has updated
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  void _showDeleteMessageDialog(ChatMessage message) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUserId = Provider.of<UserProvider>(context, listen: false).userData['uid'];
    final bool isMyMessage = message.senderId == currentUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete for me'),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message.id, onlyForCurrentUser: true);
            },
          ),
          if (isMyMessage)
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete for everyone'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message.id, onlyForCurrentUser: false);
              },
            ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId, {required bool onlyForCurrentUser}) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.deleteMessage(widget.chatRoomId, messageId, onlyForCurrentUser: onlyForCurrentUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearChatDialog() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUserId = Provider.of<UserProvider>(context, listen: false).userData['uid'];
    final chatRoom = chatProvider.currentChatRoom;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Clear'),
            onPressed: () async {
              try {
                await chatProvider.clearChat(widget.chatRoomId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, UserProvider>(
      builder: (context, chatProvider, userProvider, _) {
        final currentUserId = userProvider.userData['uid'];
        final chatRoom = chatProvider.currentChatRoom;
        final messages = chatProvider.currentMessages;
        
        // Check if we have new messages to handle scrolling appropriately
        if (messages.isNotEmpty) {
          // Check for new messages
          if (_previousMessages.isEmpty || 
              _previousMessages.length != messages.length ||
              _previousMessages.first.id != messages.first.id) {
            
            // Check if the new message is from current user or if user is already at bottom
            bool hasNewMessage = _previousMessages.isEmpty || messages.length > _previousMessages.length;
            // For reversed ListView, being at bottom means offset is near zero
            bool isAtBottom = _scrollController.hasClients && 
                              _scrollController.offset <= 50;
            
            // Auto-scroll if:
            // 1. It's the user's own new message
            // 2. User is already scrolled to bottom
            // 3. User has explicitly set shouldAutoScroll to true
            if (_shouldAutoScroll || isAtBottom || 
                (hasNewMessage && messages.last.senderId == currentUserId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            }
            
            // Update previous messages
            _previousMessages = List.from(messages);
          }
        }
        
        if (chatRoom == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chat'),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(
              child: Text('Chat room not found'),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(chatRoom.getDisplayName(currentUserId ?? '') ?? 'Chat'),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showClearChatDialog(),
                tooltip: 'Clear chat',
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: chatProvider.isLoadingMessages(widget.chatRoomId)
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              // Detect manual scrolling
                              if (notification is ScrollUpdateNotification) {
                                if (notification.dragDetails != null) {
                                  _shouldAutoScroll = false;
                                }
                              }
                              // Detect when user manually scrolls to bottom
                              if (notification is ScrollEndNotification) {
                                // For reversed ListView, being at bottom means offset is near zero
                                if (_scrollController.hasClients && 
                                    _scrollController.offset <= 50) {
                                  _shouldAutoScroll = true;
                                }
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: messages.length,
                              padding: const EdgeInsets.all(16.0),
                              reverse: true,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId == currentUserId;
                                
                                return _buildMessageBubble(message, isMe);
                              },
                            ),
                ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            ...[
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 16,
                child: message.senderAvatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          message.senderAvatar!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, size: 16, color: Colors.green),
              ),
              const SizedBox(width: 8),
            ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                _showDeleteMessageDialog(message);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18.0),
                    topRight: const Radius.circular(18.0),
                    bottomLeft: isMe ? const Radius.circular(18.0) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(18.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white.withOpacity(0.8) : Colors.black54,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}