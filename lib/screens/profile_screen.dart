import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:final_year_project_test/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'professional_development_screen.dart';
import '../providers/user_provider.dart';
import '../providers/professional_development_provider.dart';
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
    
    // Initialize the real-time data connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserData();
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
    // Use consumers to rebuild when providers change
    return Consumer2<UserProvider, ProfessionalDevelopmentProvider>(
      builder: (context, userProvider, devProvider, child) {
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    // No need to manually refresh data
                    // The real-time listener will handle updates
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
                    
                    // Online status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: userProvider.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          userProvider.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: userProvider.isOnline ? Colors.green : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
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
                    
                    const SizedBox(height: 20),
                    
                    // Professional Development Summary Section
                    Container(
                      width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Professional Development",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfessionalDevelopmentScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Skills section
                          _buildDevelopmentSection(
                            title: "Skills",
                            icon: Icons.lightbulb_outline,
                            count: devProvider.skills.length,
                            emptyText: "No skills added yet",
                            items: devProvider.skills.take(3).map((skill) {
                              return _buildSkillItem(
                                name: skill.name,
                                proficiency: skill.proficiencyLevel,
                                maxProficiency: 5,
                              );
                            }).toList(),
                          ),
                          
                          const Divider(height: 30),
                          
                          // Goals section
                          _buildDevelopmentSection(
                            title: "Goals",
                            icon: Icons.flag_outlined,
                            count: devProvider.goals.length,
                            emptyText: "No goals set yet",
                            items: devProvider.goals.take(2).map((goal) {
                              return _buildGoalItem(
                                title: goal.title,
                                completed: goal.completed,
                                daysRemaining: goal.targetDate.difference(DateTime.now()).inDays,
                              );
                            }).toList(),
                          ),
                          
                          const Divider(height: 30),
                          
                          // Certifications section
                          _buildDevelopmentSection(
                            title: "Certifications",
                            icon: Icons.badge_outlined,
                            count: devProvider.certifications.length,
                            emptyText: "No certifications added yet",
                            items: devProvider.certifications.take(2).map((cert) {
                              return _buildCertItem(
                                name: cert.name,
                                organization: cert.issuingOrganization,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Professional Development Card (Call to action)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfessionalDevelopmentScreen(),
                          ),
                        );
                      },
                      child: Container(
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
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Professional Development",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Track skills, goals & certifications",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
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
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  Widget _buildDevelopmentSection({
    required String title,
    required IconData icon,
    required int count,
    required String emptyText,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        count == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  emptyText,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              children: items,
            ),
      ],
    );
  }

  Widget _buildSkillItem({
    required String name,
    required int proficiency,
    required int maxProficiency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$proficiency/$maxProficiency',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: proficiency / maxProficiency,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGoalItem({
    required String title,
    required bool completed,
    required int daysRemaining,
  }) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.flag_outlined,
          color: completed ? AppColors.success : AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          completed ? 'Completed' : 
            (daysRemaining > 0 ? '$daysRemaining days left' : 
            '${daysRemaining.abs()} days overdue'),
          style: TextStyle(
            fontSize: 12,
            color: completed ? AppColors.success : 
                  (daysRemaining < 0 ? Colors.red : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildCertItem({
    required String name,
    required String organization,
  }) {
    return Row(
      children: [
        const Icon(
          Icons.badge_outlined,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                organization,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}