import 'package:final_year_project_test/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'edit_profile_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';
import '../screens/add_employee_screen.dart';
import '../screens/employee_list_screen.dart';
import '../screens/chat_list_screen.dart'; // Import ChatListScreen
import '../screens/user_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  int _currentIndex = 0;

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop(); // Close dialog first
                  
                  // Show loading indicator
                  _showLoadingDialog();
                  
                  // Delete account
                  await _authService.deleteAccount();
                  
                  // Show notification 
                  await _notificationService.showAccountDeletionNotification();
                  
                  if (mounted) {
                    // Remove loading indicator
                    Navigator.of(context).pop();
                    
                    // Navigate to login screen
                    _navigateToLogin();
                  }
                } catch (e) {
                  if (mounted) {
                    // Remove loading indicator if still showing
                    Navigator.of(context).pop();
                    
                    // Show error dialog
                    _showErrorDialog('Failed to delete account: ${e.toString()}');
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fetch user data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUserData();
      
      // After user data is loaded, update FCM token in database
      final userId = _authService.currentUserId;
      if (userId != null) {
        await _notificationService.saveTokenToDatabase(userId);
        
        // Subscribe to user topics
        await _notificationService.subscribeToUserTopics(userId);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // Don't rethrow - allow app to continue even if there's an error with notifications
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Dashboard'),
            backgroundColor: AppColors.primary,
          ),
          endDrawer: _buildDrawer(userProvider),
          body: _getBody(_currentIndex, userProvider),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Job Post',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(UserProvider userProvider) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(userProvider),
          _buildDrawerItems(userProvider),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(UserProvider userProvider) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: AppColors.primary),
      accountName: Text(
        userProvider.isLoading ? 'Loading...' : userProvider.username,
        style: const TextStyle(
          color: AppColors.textLight,
        ),
      ),
      accountEmail: Text(
        userProvider.email.isEmpty ? 'No email' : userProvider.email,
        style: const TextStyle(
          color: AppColors.textLight,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppColors.textLight,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textLight, width: 2),
            image: userProvider.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(userProvider.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: userProvider.photoUrl == null
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(AppColors.primary.alpha * 20),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDrawerItems(UserProvider userProvider) {
    return Expanded(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('My Profile'),
            onTap: () => _navigateToProfile(userProvider),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppColors.primary),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              setState(() {
                _currentIndex = 0; // Switch to home tab
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts, color: AppColors.primary),
            title: const Text('Account '),
            onTap: () {
              // TODO: Implement settings navigation
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: _handleLogout,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showDeleteAccountConfirmation(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _navigateToProfile(UserProvider userProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    ).then((result) {
      // Refresh user data if edit was successful
      if (result == true) {
        userProvider.fetchUserData();
        _notificationService.showProfileUpdateNotification();
      }
      Navigator.pop(context); // Close drawer
    });
  }

  Future<void> _handleLogout() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;

    // If user didn't confirm, do nothing
    if (!confirmed) return;
    
    // Create a BuildContext variable that will be used throughout the process
    BuildContext? dialogContext;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Store the dialog context for later use
        dialogContext = context;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    
    try {
      // Perform logout
      await _authService.signOut();
      
      // Close loading dialog if it's showing
      if (dialogContext != null && mounted) {
        Navigator.pop(dialogContext!);
      }
      
      // Navigate to login screen with a completely new route
      if (mounted) {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Close loading dialog if it's showing
      if (dialogContext != null && mounted) {
        Navigator.pop(dialogContext!);
      }
      
      if (mounted) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to logout: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _getBody(int index, UserProvider userProvider) {
    switch (index) {
      case 0:
        return _buildHomeTab(userProvider);
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildJobPostTab();
      case 3:
        return _buildChatTab();
      case 4:
        return _buildProfileTab(userProvider);
      default:
        return _buildHomeTab(userProvider);
    }
  }

  Widget _buildHomeTab(UserProvider userProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Your App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hello, ${userProvider.isLoading ? 'Loading...' : userProvider.username}!',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          const Text(
            'Quick Actions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickActionButton(
                icon: Icons.people,
                label: 'Employee List',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmployeeListScreen())
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildQuickActionButton(
                icon: Icons.person_add,
                label: 'Add Employee',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(AppColors.primary.alpha * 20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primary.withAlpha(AppColors.primary.alpha * 60),
              ),
            ),
            child: Icon(
              icon,
              size: 35,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Search header
          const Text(
            'Find Users',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(Colors.grey.alpha * 50),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Search for users by name or email',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories section
          const Text(
            'Chat Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Chat categories
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                title: 'Find Users',
                icon: Icons.search,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserSearchScreen()),
                  );
                },
              ),
              _buildFeatureCard(
                title: 'My Conversations',
                icon: Icons.chat_bubble_outline,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                },
              ),
              _buildFeatureCard(
                title: 'Group Chats',
                icon: Icons.group,
                color: Colors.orange,
                onTap: () {
                  setState(() {
                    _currentIndex = 3; // Switch to Chat tab
                  });
                },
              ),
              _buildFeatureCard(
                title: 'My Profile',
                icon: Icons.person,
                color: Colors.purple,
                onTap: () {
                  setState(() {
                    _currentIndex = 4; // Switch to Profile tab
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(Colors.grey.alpha * 50),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(color.alpha * 50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobPostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Employees',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Options card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.people,
                    title: 'View All Employees',
                    subtitle: 'Manage your team members',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
                      );
                    },
                  ),
                  const Divider(height: 20),
                  _buildOptionItem(
                    icon: Icons.person_add,
                    title: 'Add New Employee',
                    subtitle: 'Create a new team member profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats section
          const Text(
            'Team Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', '24', Icons.group)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('New', '3', Icons.person_add)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Active', '22', Icons.check_circle)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Department distribution
          const Text(
            'Department Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDepartmentItem('Engineering', 8),
                  const SizedBox(height: 12),
                  _buildDepartmentItem('Marketing', 5),
                  const SizedBox(height: 12),
                  _buildDepartmentItem('Finance', 4),
                  const SizedBox(height: 12),
                  _buildDepartmentItem('HR', 3),
                  const SizedBox(height: 12),
                  _buildDepartmentItem('Sales', 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(AppColors.primary.alpha * 20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentItem(String department, int count) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            department,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: count / 24,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count employees',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    try {
      return const ChatListScreen();
    } catch (e) {
      return Center(
        child: Text('Error loading chat tab: ${e.toString()}'),
      );
    }
  }

  Widget _buildProfileTab(UserProvider userProvider) {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        radius: 50,
                        backgroundColor: Colors.white.withAlpha(50),
                        child: userProvider.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  userProvider.photoUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      userProvider.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Email
                    Text(
                      userProvider.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('View Full Profile'),
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
              
              // Info section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact info
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      icon: Icons.phone,
                      title: 'Phone',
                      content: userProvider.phoneNumber.isEmpty ? 'Not provided' : userProvider.phoneNumber,
                    ),
                    _buildInfoItem(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: userProvider.location.isEmpty ? 'Not provided' : userProvider.location,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account options
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {},
                    ),
                    _buildActionItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildActionItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    _buildActionItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      color: AppColors.error,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
              color: AppColors.primary.withAlpha(AppColors.primary.alpha * 20),
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

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final iconColor = color ?? AppColors.primary;
    final textColor = color ?? Colors.black87;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(iconColor.alpha * 20),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}