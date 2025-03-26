import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_colors.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';
import '../services/user_status_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserStatusService _userStatusService = UserStatusService();
  Map<String, bool> _onlineStatus = {};
  String _query = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Provider.of<ChatProvider>(context, listen: false)
          .searchUsers(_query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching users: $e';
        _isLoading = false;
      });
    }
  }

  void _checkOnlineStatus(String userId) {
    _userStatusService.getUserStatus(userId).listen((statusData) {
      if (mounted && statusData != null) {
        setState(() {
          _onlineStatus[userId] = statusData['isOnline'] ?? false;
        });
      }
    });
  }

  void _viewUserProfile(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userData['uid'],
          userData: userData,
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context, String userId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get chat room
      final chatRoomId = await Provider.of<ChatProvider>(context, listen: false)
          .createOrGetDirectChat(userId);
      
      // Close loading indicator
      Navigator.pop(context);

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoomId: chatRoomId),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users by name or email",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_query.isEmpty) {
      return const Center(
        child: Text('Search for users by name or email'),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index];
        final userId = userData['uid'];
        
        // Check online status for this user
        if (!_onlineStatus.containsKey(userId)) {
          _checkOnlineStatus(userId);
        }
        
        final isOnline = _onlineStatus[userId] ?? false;
        
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: userData['photoUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          userData['photoUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
              // Online status indicator
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            userData['displayName'] ?? 'User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(userData['email'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.chat, color: AppColors.primary),
            onPressed: () => _startChat(context, userData['uid']),
          ),
          onTap: () => _viewUserProfile(userData),
        );
      },
    );
  }
}