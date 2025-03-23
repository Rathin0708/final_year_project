import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'Edit_screen/edit_profile_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch user data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserData();
    });
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
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
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
                                color: AppColors.primary.withOpacity(0.2),
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
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((result) {
                      // Refresh user data if edit was successful
                      if (result == true) {
                        userProvider.fetchUserData();
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: AppColors.primary),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Login_screen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: AppColors.primary),
                  title: const Text('Settings'),
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    await _authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login_screen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
                icon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getBody(int index, UserProvider userProvider) {
    switch (index) {
      case 0:
        return _buildHomeTab(userProvider);
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
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
            'Open the drawer from the app bar\nto access more features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Text('Search Tab - Coming Soon'),
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(
      child: Text('Notifications Tab - Coming Soon'),
    );
  }

  Widget _buildProfileTab(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
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
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              ).then((result) {
                if (result == true) {
                  userProvider.fetchUserData();
                }
              });
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}