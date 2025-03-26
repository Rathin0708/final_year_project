import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  // Chat rooms
  List<ChatRoom> _chatRooms = [];
  bool _isLoadingChatRooms = false;
  String _chatRoomsError = '';
  StreamSubscription? _chatRoomsSubscription;

  // Messages
  Map<String, List<ChatMessage>> _messages = {};
  Map<String, bool> _isLoadingMessages = {};
  Map<String, String> _messagesError = {};
  Map<String, StreamSubscription> _messagesSubscriptions = {};

  // Current chat room
  String? _currentChatRoomId;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoadingChatRooms => _isLoadingChatRooms;
  String get chatRoomsError => _chatRoomsError;
  String? get currentChatRoomId => _currentChatRoomId;

  // Get current chat room
  ChatRoom? get currentChatRoom {
    if (_currentChatRoomId == null) return null;
    try {
      return _chatRooms.firstWhere((room) => room.id == _currentChatRoomId);
    } catch (_) {
      return null;
    }
  }

  // Get messages for current chat room
  List<ChatMessage> get currentMessages {
    return _currentChatRoomId != null 
        ? _messages[_currentChatRoomId] ?? [] 
        : [];
  }

  // Check if messages are loading
  bool isLoadingMessages(String chatRoomId) {
    return _isLoadingMessages[chatRoomId] ?? false;
  }

  // Get error for messages
  String getMessagesError(String chatRoomId) {
    return _messagesError[chatRoomId] ?? '';
  }

  // Initialize
  ChatProvider({ChatService? chatService}) : _chatService = chatService ?? ChatService() {
    init();
  }

  void init() {
    try {
      _loadChatRooms();
    } catch (e) {
      _isLoadingChatRooms = false;
      _chatRoomsError = 'Failed to initialize chat: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    for (final subscription in _messagesSubscriptions.values) {
      subscription.cancel();
    }
    _messagesSubscriptions.clear();
    clearCurrentChatRoomSilently();
    super.dispose();
  }

  // Load chat rooms
  void _loadChatRooms() {
    _isLoadingChatRooms = true;
    _chatRoomsError = '';
    notifyListeners();

    try {
      // Check if user is authenticated
      if (_chatService.currentUserId == null) {
        _isLoadingChatRooms = false;
        _chatRoomsError = 'Please sign in to access chats';
        notifyListeners();
        return;
      }

      _chatRoomsSubscription?.cancel();
      _chatRoomsSubscription = _chatService.getChatRooms().listen(
        (chatRooms) {
          _chatRooms = chatRooms;
          _isLoadingChatRooms = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoadingChatRooms = false;
          _chatRoomsError = error.toString();
          notifyListeners();
          debugPrint('Error loading chat rooms: $error');
        }
      );
    } catch (e) {
      _isLoadingChatRooms = false;
      _chatRoomsError = e.toString();
      notifyListeners();
      debugPrint('Exception loading chat rooms: $e');
    }
  }

  // Set current chat room
  Future<void> setCurrentChatRoom(String chatRoomId) async {
    print('Setting current chat room to $chatRoomId');
    _currentChatRoomId = chatRoomId;
    notifyListeners();

    // Load messages for this chat room if not already loaded
    print('Loading messages for chat room $chatRoomId');
    await loadMessages(chatRoomId);

    // Mark messages as read
    print('Marking messages as read for chat room $chatRoomId');
    await _chatService.markMessagesAsRead(chatRoomId);
    print('Finished setting current chat room to $chatRoomId');
  }

  // Clear current chat room
  void clearCurrentChatRoom() {
    _currentChatRoomId = null;
    notifyListeners();
  }

  // Clear current chat room without notification (safe for dispose)
  void clearCurrentChatRoomSilently() {
    _currentChatRoomId = null;
  }

  // Load messages for a chat room
  Future<void> loadMessages(String chatRoomId) async {
    // Cancel existing subscription if any
    if (_messagesSubscriptions.containsKey(chatRoomId)) {
      await _messagesSubscriptions[chatRoomId]?.cancel();
      _messagesSubscriptions.remove(chatRoomId);
    }

    _isLoadingMessages[chatRoomId] = true;
    _messagesError[chatRoomId] = '';
    notifyListeners();

    try {
      // Initialize messages list if not exists
      if (!_messages.containsKey(chatRoomId)) {
        _messages[chatRoomId] = [];
      }
      
      print('Setting up real-time listener for chat room $chatRoomId');
      
      try {
        // First fetch the latest messages right away for immediate display
        final initialMessages = await _chatService.getInitialMessages(chatRoomId);
        _messages[chatRoomId] = initialMessages;
        _isLoadingMessages[chatRoomId] = false;
        notifyListeners();
      } catch (e) {
        print('Error loading initial messages: $e');
        // Continue with empty messages list
        _messages[chatRoomId] = [];
        _isLoadingMessages[chatRoomId] = false;
        notifyListeners();
      }
      
      // Then set up real-time listener for continuous updates
      _messagesSubscriptions[chatRoomId] = _chatService.getMessages(chatRoomId).listen(
        (messages) {
          // Get existing local message IDs (for messages we've added optimistically)
          final existingLocalIds = _messages[chatRoomId]!
              .where((msg) => msg.id.startsWith('local_'))
              .map((msg) => msg.content + msg.timestamp.toString())
              .toSet();
          
          // Merge messages: add server messages but keep local ones that haven't arrived yet
          final updatedMessages = [...messages];
          
          // Keep local messages that aren't in the server response yet
          for (var localMsg in _messages[chatRoomId] ?? []) {
            if (localMsg.id.startsWith('local_')) {
              // Check if this message exists in server response based on content+timestamp
              final contentTimestamp = localMsg.content + localMsg.timestamp.toString();
              final exists = messages.any((m) => 
                m.senderId == localMsg.senderId && 
                m.content == localMsg.content &&
                (m.timestamp.difference(localMsg.timestamp).inSeconds).abs() < 5);
                
              if (!exists) {
                updatedMessages.add(localMsg);
              }
            }
          }
          
          // Sort by timestamp, newest first (for reversed ListView)
          updatedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          // Debug print for message ordering
          if (updatedMessages.isNotEmpty && updatedMessages.length > 1) {
            print('First message timestamp: ${updatedMessages.first.timestamp}');
            print('Last message timestamp: ${updatedMessages.last.timestamp}');
          }
          
          _messages[chatRoomId] = updatedMessages;
          _isLoadingMessages[chatRoomId] = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoadingMessages[chatRoomId] = false;
          _messagesError[chatRoomId] = error.toString();
          notifyListeners();
        }
      );
    } catch (e) {
      _isLoadingMessages[chatRoomId] = false;
      _messagesError[chatRoomId] = e.toString();
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    if (_currentChatRoomId == null) return;

    try {
      // Get current user info
      final user = _chatService.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get current chat room to find user name from participant list
      final chatRoom = currentChatRoom;
      String senderName = 'Me';
      String? senderAvatar;
      
      if (chatRoom != null && user.uid != null) {
        senderName = chatRoom.participantNames[user.uid] ?? user.displayName ?? 'Me';
        if (chatRoom.participantAvatars != null) {
          senderAvatar = chatRoom.participantAvatars![user.uid];
        }
      }
      
      // Create message locally first for immediate display
      final now = DateTime.now();
      final localId = 'local_${now.millisecondsSinceEpoch}';
      final localMessage = ChatMessage(
        id: localId,
        senderId: user.uid,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        timestamp: now,
        isRead: false,
        chatRoomId: _currentChatRoomId!,
      );
      
      // Add to local messages list for immediate display
      if (!_messages.containsKey(_currentChatRoomId!)) {
        _messages[_currentChatRoomId!] = [];
      }
      
      // Insert the new message at the beginning (since the list is sorted newest first)
      _messages[_currentChatRoomId!] = [localMessage, ..._messages[_currentChatRoomId]!];
      print('Added local message: ${localMessage.content} at ${localMessage.timestamp}');
      notifyListeners();
      
      // Send to server and get document reference
      final messageRef = await _chatService.sendMessage(
        chatRoomId: _currentChatRoomId!,
        content: content,
      );
      
      // Map local ID to server ID for future reference
      // This helps us match local messages with server responses
      print('Message sent: Local ID $localId mapped to server ID ${messageRef.id}');
      
    } catch (e) {
      _messagesError[_currentChatRoomId!] = e.toString();
      notifyListeners();
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatRoomId, String messageId, {bool onlyForCurrentUser = false}) async {
    try {
      await _chatService.deleteMessage(chatRoomId, messageId, onlyForCurrentUser: onlyForCurrentUser);

      // Update local messages
      if (_messages.containsKey(chatRoomId)) {
        _messages[chatRoomId] = _messages[chatRoomId]!.where((message) => message.id != messageId).toList();
        notifyListeners();
      }
    } catch (e) {
      _messagesError[chatRoomId] = e.toString();
      notifyListeners();
    }
  }

  // Clear chat
  Future<void> clearChat(String chatRoomId) async {
    try {
      await _chatService.clearChat(chatRoomId);

      // Update local messages
      if (_messages.containsKey(chatRoomId)) {
        _messages[chatRoomId] = [];
        notifyListeners();
      }
    } catch (e) {
      _messagesError[chatRoomId] = e.toString();
      notifyListeners();
    }
  }

  // Create or get a direct chat room
  Future<String> createOrGetDirectChat(String userId) async {
    try {
      return await _chatService.createOrGetDirectChatRoom(userId);
    } catch (e) {
      _chatRoomsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Create a group chat
  Future<String> createGroupChat({
    required String name,
    required List<String> participants,
    String? groupAvatar,
  }) async {
    try {
      return await _chatService.createGroupChatRoom(
        groupName: name,
        participantIds: participants,
        groupAvatar: groupAvatar,
      );
    } catch (e) {
      _chatRoomsError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get available users for chat
  Future<List<Map<String, dynamic>>> getAvailableUsers() async {
    return await _chatService.getAvailableUsers();
  }

  // Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    return await _chatService.searchUsers(query);
  }

  // Delete a chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await _chatService.deleteChatRoom(chatRoomId);

      // If this was the current chat room, clear it
      if (_currentChatRoomId == chatRoomId) {
        clearCurrentChatRoom();
      }

      // Clear any cached data
      _messages.remove(chatRoomId);
      _isLoadingMessages.remove(chatRoomId);
      _messagesError.remove(chatRoomId);
      _messagesSubscriptions[chatRoomId]?.cancel();
      _messagesSubscriptions.remove(chatRoomId);

    } catch (e) {
      _chatRoomsError = e.toString();
      notifyListeners();
    }
  }

  // Leave a group chat
  Future<void> leaveGroupChat(String chatRoomId) async {
    try {
      await _chatService.leaveGroupChat(chatRoomId);

      // If this was the current chat room, clear it
      if (_currentChatRoomId == chatRoomId) {
        clearCurrentChatRoom();
      }

      // Clear any cached data
      _messages.remove(chatRoomId);
      _isLoadingMessages.remove(chatRoomId);
      _messagesError.remove(chatRoomId);
      _messagesSubscriptions[chatRoomId]?.cancel();
      _messagesSubscriptions.remove(chatRoomId);

    } catch (e) {
      _chatRoomsError = e.toString();
      notifyListeners();
    }
  }

  // Get total unread message count
  int get totalUnreadCount {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return 0;

    return _chatRooms.fold(0, (total, room) {
      return total + (room.unreadCounts[currentUserId] ?? 0);
    });
  }
}