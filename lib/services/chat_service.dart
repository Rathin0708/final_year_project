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
    
    try {
      return _chatRoomsCollection
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ChatRoom.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            if (kDebugMode) {
              print('Error in chat rooms stream: $error');
            }
            return <ChatRoom>[];
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up chat rooms stream: $e');
      }
      return Stream.value([]);
    }
  }
  
  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    if (kDebugMode) {
      print('Subscribing to messages for chat room $chatRoomId');
    }
    
    // First try with proper sorting using index
    try {
      return _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
            if (kDebugMode) {
              print('Received message update with ${snapshot.docs.length} messages');
              print('From cache: ${snapshot.metadata.isFromCache}');
            }
            
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            
            return messages;
          })
          .handleError((error) {
            if (kDebugMode) {
              print('Error in message stream: $error');
              
              // If it's an index error, we'll fall back to the unordered query
              if (error.toString().contains('failed-precondition') && 
                  error.toString().contains('index')) {
                print('Missing index error in stream. Using fallback query.');
              }
            }
            
            // Return empty list on error but also trigger fallback query
            _useFallbackMessagesQuery(chatRoomId);
            return <ChatMessage>[];
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up message stream: $e');
      }
      return _getFallbackMessagesStream(chatRoomId);
    }
  }
  
  // Fallback method for getting messages without using the index
  Stream<List<ChatMessage>> _getFallbackMessagesStream(String chatRoomId) {
    if (kDebugMode) {
      print('Using fallback message stream for chat room $chatRoomId');
    }
    
    try {
      return _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .snapshots()
          .map((snapshot) {
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
            
            // Sort messages locally
            messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return messages;
          })
          .handleError((error) {
            if (kDebugMode) {
              print('Error in fallback message stream: $error');
            }
            return <ChatMessage>[];
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up fallback message stream: $e');
      }
      return Stream.value([]);
    }
  }
  
  // Switch to fallback query when main query fails
  void _useFallbackMessagesQuery(String chatRoomId) {
    // This is needed to tell the provider to switch to fallback stream
    // if the main stream fails with an index error
    _fallbackQueryNeeded = true;
  }
  
  // Flag to track if we need to use fallback query
  bool _fallbackQueryNeeded = false;
  
  // Get initial messages for a chat room (non-stream version for immediate loading)
  Future<List<ChatMessage>> getInitialMessages(String chatRoomId) async {
    if (kDebugMode) {
      print('Fetching initial messages for chat room $chatRoomId');
    }
    
    try {
      // Try to get messages with proper ordering
      final querySnapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
          
      if (kDebugMode) {
        print('Got ${querySnapshot.docs.length} initial messages');
      }
      
      return querySnapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting initial messages: $e');
        
        if (e.toString().contains('failed-precondition') && 
            e.toString().contains('index')) {
          print('Missing index error. Please create the required index in Firebase console.');
          print('See error message for the direct link to create the index.');
        }
      }
      
      // If we have an index error, try to get messages without sorting
      try {
        final fallbackSnapshot = await _messagesCollection
            .where('chatRoomId', isEqualTo: chatRoomId)
            .get();
            
        if (kDebugMode) {
          print('Got ${fallbackSnapshot.docs.length} fallback messages without sorting');
        }
        
        final messages = fallbackSnapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();
            
        // Sort messages locally as a fallback
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return messages;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Failed to get fallback messages: $fallbackError');
        }
        return [];
      }
    }
  }
  
  // Send a message
  Future<DocumentReference> sendMessage({
    required String chatRoomId,
    required String content,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get user data
      final userDoc = await _usersCollection.doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      // Use server timestamp to ensure consistency
      final serverTimestamp = FieldValue.serverTimestamp();
      
      final messageData = {
        'senderId': user.uid,
        'senderName': userData?['username']?.toString() ?? user.displayName ?? 'User',
        'senderAvatar': userData?['photoUrl']?.toString() ?? user.photoURL,
        'content': content,
        'timestamp': serverTimestamp, // Using server timestamp
        'isRead': false,
        'chatRoomId': chatRoomId,
      };
      
      // Add message to Firestore with server-side timestamp for better consistency
      final messageRef = await _messagesCollection.add(messageData);
      
      // Batch write to update chat room in the same transaction
      final batch = _firestore.batch();
      
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
          'lastMessageTime': serverTimestamp, // Using server timestamp
          'unreadCounts': updatedUnreadCounts,
        });
      }
      
      return messageRef;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      rethrow;
    }
  }
  
  // Clear chat
  Future<void> clearChat(String chatRoomId) async {
    try {
      final messagesSnapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();
      
      final batch = _firestore.batch();
      
      // Delete all messages
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing chat: $e');
      }
      rethrow;
    }
  }
  
  // Delete a message
  Future<void> deleteMessage(String chatRoomId, String messageId, {bool onlyForCurrentUser = false}) async {
    try {
      if (onlyForCurrentUser) {
        final user = currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        final messageDoc = await _messagesCollection.doc(messageId).get();
        if (messageDoc.exists) {
          final message = ChatMessage.fromFirestore(messageDoc);
          if (message.senderId == user.uid) {
            await _messagesCollection.doc(messageId).delete();
          } else {
            await _messagesCollection.doc(messageId).update({
              'isRead': true,
            });
          }
        }
      } else {
        await _messagesCollection.doc(messageId).delete();
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase authentication error: $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
      rethrow;
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      if (kDebugMode) {
        print('Marking messages as read for user ${user.uid} in chat room $chatRoomId');
      }
      
      // First update the unread count for this user
      try {
        await _chatRoomsCollection.doc(chatRoomId).update({
          'unreadCounts.${user.uid}': 0,
        });
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          if (kDebugMode) {
            print('Chat room $chatRoomId not found');
          }
        } else {
          rethrow;
        }
      }
      
      if (kDebugMode) {
        print('Updated unread count for user ${user.uid} in chat room $chatRoomId');
      }
      
      // Then mark all messages as read
      final unreadMessages = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      if (kDebugMode) {
        print('Found ${unreadMessages.docs.length} unread messages in chat room $chatRoomId');
      }
      
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      if (kDebugMode) {
        print('Updated ${unreadMessages.docs.length} messages as read in chat room $chatRoomId');
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('Successfully marked messages as read for user ${user.uid} in chat room $chatRoomId');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase authentication error: $e');
      }
      rethrow;
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
      
      final participantNames = <String, String>{
        user.uid: currentUserData['username']?.toString() ?? 'User',
        otherUserId: otherUserData['username']?.toString() ?? 'User',
      };
      
      final participantAvatars = <String, String>{
        user.uid: currentUserData['photoUrl']?.toString() ?? '',
        otherUserId: otherUserData['photoUrl']?.toString() ?? '',
      };
      
      final unreadCounts = <String, int>{
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
          participantAvatars[userId] = userData['photoUrl']?.toString() ?? '';
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
        final updatedParticipantNames = Map<String, String>.from(chatRoom.participantNames)
          ..remove(user.uid);
        
        Map<String, String>? updatedParticipantAvatars;
        if (chatRoom.participantAvatars != null) {
          updatedParticipantAvatars = Map<String, String>.from(chatRoom.participantAvatars!)
            ..remove(user.uid);
        }
        
        final updatedUnreadCounts = Map<String, int>.from(chatRoom.unreadCounts)
          ..remove(user.uid);
        
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