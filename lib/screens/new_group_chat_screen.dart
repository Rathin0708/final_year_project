import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class NewGroupChatScreen extends StatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  State<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends State<NewGroupChatScreen> {
  final _groupNameController = TextEditingController();
  final List<String> _selectedUsers = [];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select Participants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Replace with actual user list
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('User placeholder'), 
                  // Implement user selection functionality here
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement group creation logic
          Navigator.pop(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.check),
      ),
    );
  }
}