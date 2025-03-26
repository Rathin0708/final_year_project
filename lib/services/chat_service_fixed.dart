import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../models/employee_model.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  
  // Get chat rooms for current user
  Stream<List<ChatRoom>> getChatRooms() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _chatRoomsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
        });
  }
  
  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _messagesCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 messages
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }
  
  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get user data
      final userDoc = await _usersCollection.doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      final message = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        senderName: userData?['username'] ?? user.displayName ?? 'User',
        senderAvatar: userData?['photoUrl'] ?? user.photoURL,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        chatRoomId: chatRoomId,
      );
      
      // Add message to Firestore
      await _messagesCollection.add(message.toJson());
      
      // Get the chat room
      final chatRoomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
      if (chatRoomDoc.exists) {
        final chatRoom = ChatRoom.fromFirestore(chatRoomDoc);
        
        // Update unread counts for all participants except sender
        final Map<String, int> updatedUnreadCounts = Map.from(chatRoom.unreadCounts);
        for (final participantId in chatRoom.participants) {
          if (participantId != user.uid) {
            updatedUnreadCounts[participantId] = (updatedUnreadCounts[participantId] ?? 0) + 1;
          }
        }
        
        // Update chat room with last message info
        await _chatRoomsCollection.doc(chatRoomId).update({
          'lastMessageText': content,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          'unreadCounts': updatedUnreadCounts,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // First update the unread count for this user
      await _chatRoomsCollection.doc(chatRoomId).update({
        'unreadCounts.${user.uid}': 0,
      });
      
      // Then mark all messages as read
      final unreadMessages = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
      rethrow;
    }
  }
  
  // Create or get a one-to-one chat room
  Future<String> createOrGetDirectChatRoom(String otherUserId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Check if a chat room already exists between these users
      final querySnapshot = await _chatRoomsCollection
          .where('participants', arrayContains: user.uid)
          .where('isGroup', isEqualTo: false)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final chatRoom = ChatRoom.fromFirestore(doc);
        if (chatRoom.participants.length == 2 && 
            chatRoom.participants.contains(otherUserId)) {
          return chatRoom.id;
        }
      }
      
      // If no chat room exists, create one
      // First, get both users' information
      final currentUserDoc = await _usersCollection.doc(user.uid).get();
      final otherUserDoc = await _usersCollection.doc(otherUserId).get();
      
      if (!currentUserDoc.exists || !otherUserDoc.exists) {
        throw Exception('One or both users not found');
      }
      
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
      
      final participants = [user.uid, otherUserId];
      final Map<String, String> participantNames = {
        user.uid: currentUserData['username']?.toString() ?? 'User',
        otherUserId: otherUserData['username']?.toString() ?? 'User',
      };
      
      final Map<String, String> participantAvatars = {
        user.uid: currentUserData['photoUrl']?.toString() ?? '',
        otherUserId: otherUserData['photoUrl']?.toString() ?? '',
      };
      
      final Map<String, int> unreadCounts = {
        user.uid: 0,
        otherUserId: 0,
      };
      
      final newChatRoom = ChatRoom(
        id: '',  // Will be set by Firestore
        participants: participants,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        lastMessageTime: DateTime.now(),
        lastMessageText: null,
        isGroup: false,
        unreadCounts: unreadCounts,
      );
      
      final docRef = await _chatRoomsCollection.add(newChatRoom.toJson());
      return docRef.id;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating chat room: $e');
      }
      rethrow;
    }
  }
  
  // Create a group chat room
  Future<String> createGroupChatRoom({
    required String groupName,
    required List<String> participantIds,
    String? groupAvatar,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Ensure the current user is included
      if (!participantIds.contains(user.uid)) {
        participantIds.add(user.uid);
      }
      
      // Get all participants' information
      final Map<String, String> participantNames = {};
      final Map<String, String> participantAvatars = {};
      final Map<String, int> unreadCounts = {};
      
      for (final userId in participantIds) {
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          participantNames[userId] = userData['username']?.toString() ?? 'User';
          if (userData['photoUrl'] != null) {
            participantAvatars[userId] = userData['photoUrl'].toString();
          }
          unreadCounts[userId] = 0;
        }
      }
      
      final newGroupChat = ChatRoom(
        id: '',  // Will be set by Firestore
        participants: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        lastMessageTime: DateTime.now(),
        lastMessageText: null,
        isGroup: true,
        groupName: groupName,
        groupAvatar: groupAvatar,
        unreadCounts: unreadCounts,
      );
      
      final docRef = await _chatRoomsCollection.add(newGroupChat.toJson());
      return docRef.id;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating group chat: $e');
      }
      rethrow;
    }
  }
  
  // Get users for creating a new chat
  Future<List<Map<String, dynamic>>> getAvailableUsers() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final querySnapshot = await _usersCollection
          .where(FieldPath.documentId, isNotEqualTo: user.uid)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['username'] ?? 'User',
          'avatar': data['photoUrl'],
          'email': data['email'] ?? '',
        };
      }).toList();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available users: $e');
      }
      return [];
    }
  }
  
  // Search for users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get all users except current user
      final querySnapshot = await _usersCollection
          .where(FieldPath.documentId, isNotEqualTo: user.uid)
          .get();
      
      // Filter results by query
      final results = <Map<String, dynamic>>[];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final displayName = (data['username'] as String?) ?? 'User';
        final email = (data['email'] as String?) ?? '';
        
        if (displayName.toLowerCase().contains(query.toLowerCase()) || 
            email.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'uid': doc.id,
            'displayName': displayName,
            'photoUrl': data['photoUrl'],
            'email': email,
          });
        }
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching users: $e');
      }
      return [];
    }
  }
  
  // Get employees for creating a new chat
  Future<List<EmployeeModel>> getAvailableEmployees() async {
    try {
      final employeesSnapshot = await _firestore.collection('employees').get();
      
      return employeesSnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add the document ID to the data
            return EmployeeModel.fromJson(data);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting employees: $e');
      }
      return [];
    }
  }
  
  // Delete a chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages in the chat room
      final messagesSnapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();
      
      final batch = _firestore.batch();
      
      // Delete all messages
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the chat room
      batch.delete(_chatRoomsCollection.doc(chatRoomId));
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting chat room: $e');
      }
      rethrow;
    }
  }
  
  // Leave a group chat
  Future<void> leaveGroupChat(String chatRoomId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final chatRoomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
      if (!chatRoomDoc.exists) throw Exception('Chat room not found');
      
      final chatRoom = ChatRoom.fromFirestore(chatRoomDoc);
      if (!chatRoom.isGroup) throw Exception('Cannot leave a direct chat');
      
      // Remove the user from participants
      final updatedParticipants = chatRoom.participants
          .where((id) => id != user.uid)
          .toList();
      
      if (updatedParticipants.isEmpty) {
        // If no participants left, delete the room
        await deleteChatRoom(chatRoomId);
      } else {
        // Otherwise update the room
        final updatedParticipantNames = Map<String, String>.from(chatRoom.participantNames);
        updatedParticipantNames.remove(user.uid);
        
        Map<String, String>? updatedParticipantAvatars;
        if (chatRoom.participantAvatars != null) {
          updatedParticipantAvatars = Map<String, String>.from(chatRoom.participantAvatars!);
          updatedParticipantAvatars.remove(user.uid);
        } else {
          updatedParticipantAvatars = null;
        }
        
        final updatedUnreadCounts = Map<String, int>.from(chatRoom.unreadCounts);
        updatedUnreadCounts.remove(user.uid);
        
        await _chatRoomsCollection.doc(chatRoomId).update({
          'participants': updatedParticipants,
          'participantNames': updatedParticipantNames,
          'participantAvatars': updatedParticipantAvatars,
          'unreadCounts': updatedUnreadCounts,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving group chat: $e');
      }
      rethrow;
    }
  }
}
