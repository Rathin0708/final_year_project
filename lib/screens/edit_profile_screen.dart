import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';
import '../widgets/text_field_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _usernameController = TextEditingController(text: userProvider.username);
    _phoneController = TextEditingController(text: userProvider.phoneNumber);
    _locationController = TextEditingController(text: userProvider.location);
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSuccess = false;
    });
    
    try {
      await _authService.updateUserProfile(
        username: _usernameController.text.trim(),
        phoneNo: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );
      
      setState(() {
        _isSuccess = true;
        _errorMessage = 'Profile updated successfully!';
      });
      
      if (mounted) {
        // Wait a moment to show success message
        await Future.delayed(const Duration(seconds: 1));
        
        // No need to explicitly refresh data, the real-time listener will handle it
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _errorMessage = 'Failed to update profile: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 30),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPhoneField(),
                const SizedBox(height: 16),
                _buildLocationField(),
                const SizedBox(height: 30),
                _buildMessageDisplay(),
                const SizedBox(height: 20),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(
              alpha: AppColors.primary.alpha * 0.2,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Edit Your Profile',
            style: AppTypography.h4,
          ),
          Text(
            'Update your information below',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFieldInput(
      textEditingController: _usernameController,
      hintText: 'Enter your username',
      labelText: 'Username',
      textInputType: TextInputType.text,
      prefixIcon: const Icon(Icons.person),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a username';
        } else if (value.length < 3) {
          return 'Username must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFieldInput(
      textEditingController: _phoneController,
      hintText: 'Enter your phone number',
      labelText: 'Phone Number',
      textInputType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        } else if (!RegExp(r'^\d{10,15}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
          return 'Please enter a valid phone number (10-15 digits)';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFieldInput(
      textEditingController: _locationController,
      hintText: 'Enter your location',
      labelText: 'Location',
      textInputType: TextInputType.text,
      prefixIcon: const Icon(Icons.location_on),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your location';
        }
        return null;
      },
    );
  }

  Widget _buildMessageDisplay() {
    if (_errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSuccess ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            color: _isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Changes',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}