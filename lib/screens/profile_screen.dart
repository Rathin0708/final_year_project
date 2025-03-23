import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:final_year_project_test/screens/login_screen.dart';
import 'package:final_year_project_test/screens/Edit_screen/edit_profile_screen.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isSaving = false;
  
  // Controllers for editing
  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  
  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    
    // Fetch user data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      if (userProvider.username.isEmpty) {
        userProvider.fetchUserData();
      } else {
        // Initialize controllers with existing data
        usernameController.text = userProvider.username;
        phoneController.text = userProvider.phoneNumber;
        locationController.text = userProvider.location;
      }
    });
  }
  
  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }
  
  Future<void> saveUserData() async {
    final username = usernameController.text.trim();
    final phoneNumber = phoneController.text.trim();
    final location = locationController.text.trim();
    
    if (username.isEmpty || phoneNumber.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    
    setState(() {
      isSaving = true;
    });
    
    try {
      // Use UserProvider to update data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUserProfile(
        username: username,
        phoneNumber: phoneNumber,
        location: location,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Use consumer to rebuild when UserProvider changes
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Initialize controllers if empty but provider has data
        if (userProvider.username.isNotEmpty && usernameController.text.isEmpty) {
          usernameController.text = userProvider.username;
          phoneController.text = userProvider.phoneNumber;
          locationController.text = userProvider.location;
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: AppColors.primary,
            actions: [
              if (!userProvider.isLoading)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );

                    // Refresh user data if edit was successful
                    if (result == true) {
                      userProvider.fetchUserData();
                    }
                  },
                ),
            ],
          ),
          body: userProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary,))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userProvider.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userProvider.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Profile information section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.phone,
                            title: "Phone",
                            value: userProvider.phoneNumber,
                          ),
                          const Divider(height: 25),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            title: "Location",
                            value: userProvider.location,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Login_screen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
      }
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value.isEmpty ? "Not provided" : value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}