import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
import 'new_chat_screen.dart';
import 'new_group_chat_screen.dart';
import 'chat_screen.dart';
import '../services/user_status_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  TextEditingController searchController = TextEditingController();
  final UserStatusService _userStatusService = UserStatusService();
  Map<String, bool> _onlineStatus = {};

  @override
  void initState() {
    super.initState();
    // Make sure chat data is loaded when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<ChatProvider>(context, listen: false).init();
      } catch (e) {
        // Gracefully handle initialization error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load chats: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _checkUserOnlineStatus(String userId) {
    _userStatusService.getUserStatus(userId).listen((statusData) {
      if (mounted && statusData != null) {
        setState(() {
          _onlineStatus[userId] = statusData['isOnline'] ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, UserProvider>(
      builder: (context, chatProvider, userProvider, _) {
        final currentUserId = userProvider.userData['uid'];
        
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chats"),
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewGroupChatScreen(),
                    ),
                  );
                },
                tooltip: 'New Group Chat',
              ),
              IconButton(
                icon: const Icon(Icons.add_comment),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewChatScreen(),
                    ),
                  );
                },
                tooltip: 'New Chat',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search conversations",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                  onChanged: (value) {
                    // Implement searching functionality
                    setState(() {});
                  },
                ),
              ),
              
              // Chat list
              Expanded(
                child: _buildChatList(
                  chatProvider, 
                  currentUserId,
                  searchController.text.trim(),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Navigate to new chat screen
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const NewChatScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.chat),
          ),
        );
      },
    );
  }
  
  Widget _buildChatList(ChatProvider chatProvider, String? currentUserId, String searchQuery) {
    if (chatProvider.isLoadingChatRooms) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatProvider.chatRoomsError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(chatProvider.chatRoomsError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh chat rooms
                Provider.of<ChatProvider>(context, listen: false).init();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final chatRooms = chatProvider.chatRooms;
    
    // Filter by search query if provided
    final filteredRooms = searchQuery.isEmpty
        ? chatRooms
        : chatRooms.where((room) {
            final String displayName = room.getDisplayName(currentUserId ?? '').toLowerCase();
            final String query = searchQuery.toLowerCase();
            return displayName.contains(query) || 
                  (room.lastMessageText?.toLowerCase().contains(query) ?? false);
          }).toList();

    if (filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              chatRooms.isEmpty ? 'No conversations yet' : 'No results found',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            if (chatRooms.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const NewChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Start a conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = filteredRooms[index];
        return _buildChatRoomItem(context, chatRoom, currentUserId);
      },
    );
  }

  Widget _buildChatRoomItem(BuildContext context, ChatRoom chatRoom, String? currentUserId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Skip if current user ID is null
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }
    
    // Get chat info
    final displayName = chatRoom.getDisplayName(currentUserId);
    final lastMessage = chatRoom.lastMessageText ?? 'No messages yet';
    final lastMessageTime = chatRoom.lastMessageTime;
    final unreadCount = chatRoom.getUnreadCount(currentUserId);

    // Check online status for direct chats
    bool isOnline = false;
    if (!chatRoom.isGroup && chatRoom.participants.isNotEmpty) {
      final otherUserId = chatRoom.participants.firstWhere(
        (uid) => uid != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty && !_onlineStatus.containsKey(otherUserId)) {
        _checkUserOnlineStatus(otherUserId);
      }

      isOnline = _onlineStatus[otherUserId] ?? false;
    }

    // Format time
    String formattedTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(lastMessageTime.year, lastMessageTime.month, lastMessageTime.day);
    
    if (messageDate == today) {
      formattedTime = DateFormat('h:mm a').format(lastMessageTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      formattedTime = 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      formattedTime = DateFormat('EEEE').format(lastMessageTime); // Day name
    } else {
      formattedTime = DateFormat('MM/dd/yy').format(lastMessageTime);
    }
    
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: chatRoom.isGroup ? AppColors.primary.withAlpha(51) : Colors.grey.shade300,
            child: chatRoom.isGroup
                ? const Icon(Icons.group, color: AppColors.primary)
                : const Icon(Icons.person, color: Colors.grey),
          ),
          if (!chatRoom.isGroup)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0 ? AppColors.primary : Colors.grey,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        try {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoomId: chatRoom.id),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to navigate to chat: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onLongPress: () {
        // Show options menu
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, chatRoom, chatProvider);
                },
              ),
              if (chatRoom.isGroup)
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Leave Group'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveGroupConfirmation(context, chatRoom, chatProvider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, ChatRoom chatRoom, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${chatRoom.isGroup ? 'Group' : 'Conversation'}'),
        content: Text(
          'Are you sure you want to delete this ${chatRoom.isGroup ? 'group' : 'conversation'}? '
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await chatProvider.deleteChatRoom(chatRoom.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${chatRoom.isGroup ? 'Group' : 'Conversation'} deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showLeaveGroupConfirmation(BuildContext context, ChatRoom chatRoom, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text(
          'Are you sure you want to leave "${chatRoom.groupName}"? '
          'You will no longer receive messages from this group.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await chatProvider.leaveGroupChat(chatRoom.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Left group chat'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to leave group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}