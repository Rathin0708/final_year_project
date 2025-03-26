import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';
import '../services/user_status_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;
  final UserStatusService _userStatusService = UserStatusService();
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _setupStatusListener();
  }

  void _setupStatusListener() {
    _userStatusService.getUserStatus(widget.userId).listen((statusData) {
      if (mounted && statusData != null) {
        setState(() {
          _isOnline = statusData['isOnline'] ?? false;
          _lastSeen = statusData['lastSeen'];
        });
      }
    });
  }

  Future<void> _startChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatRoomId = await Provider.of<ChatProvider>(context, listen: false)
          .createOrGetDirectChat(widget.userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoomId: chatRoomId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.userData['photoUrl'];
    final displayName = widget.userData['displayName'] ?? 'User';
    final email = widget.userData['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Email
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Online status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOnline 
                          ? 'Online' 
                          : _lastSeen != null 
                              ? 'Last seen ${_formatLastSeen(_lastSeen!)}'
                              : 'Offline',
                        style: TextStyle(
                          color: _isOnline ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Message Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startChat,
                    icon: _isLoading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(4.0),
                            child: const CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.chat, size: 18),
                    label: Text(_isLoading ? 'Starting Chat...' : 'Message'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // User information
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoItem(
                    icon: Icons.email,
                    title: 'Email',
                    content: email.isNotEmpty ? email : 'Not provided',
                  ),
                  
                  _buildInfoItem(
                    icon: Icons.person,
                    title: 'User ID',
                    content: widget.userId,
                  ),
                  
                  // Add more user information here if available
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}