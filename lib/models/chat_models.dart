import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String chatRoomId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.chatRoomId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle server timestamp which might be null if the document was just created
    DateTime timestamp;
    if (data['timestamp'] == null) {
      timestamp = DateTime.now(); // Use local timestamp as fallback
    } else {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    }
    
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      content: data['content'] ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] ?? false,
      chatRoomId: data['chatRoomId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'chatRoomId': chatRoomId,
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String>? participantAvatars;
  final DateTime lastMessageTime;
  final String? lastMessageText;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatar;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantAvatars,
    required this.lastMessageTime,
    this.lastMessageText,
    this.isGroup = false,
    this.groupName,
    this.groupAvatar,
    required this.unreadCounts,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle server timestamp which might be null if the document was just created
    DateTime lastMessageTime;
    if (data['lastMessageTime'] == null) {
      lastMessageTime = DateTime.now(); // Use local timestamp as fallback
    } else {
      lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
    }
    
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantAvatars: data['participantAvatars'] != null
          ? Map<String, String>.from(data['participantAvatars'])
          : null,
      lastMessageTime: lastMessageTime,
      lastMessageText: data['lastMessageText'],
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupAvatar: data['groupAvatar'],
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageText': lastMessageText,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupAvatar': groupAvatar,
      'unreadCounts': unreadCounts,
    };
  }

  // Helper to get the other participant in a one-on-one chat
  String getOtherParticipantId(String currentUserId) {
    if (participants.length != 2 || isGroup) {
      return '';
    }
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // Get display name for the chat
  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    } else {
      final otherParticipantId = getOtherParticipantId(currentUserId);
      return participantNames[otherParticipantId] ?? 'Unknown User';
    }
  }

  // Get avatar for the chat
  String? getAvatar(String currentUserId) {
    if (isGroup) {
      return groupAvatar;
    } else {
      final otherParticipantId = getOtherParticipantId(currentUserId);
      return participantAvatars?[otherParticipantId];
    }
  }

  // Get unread message count for current user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}