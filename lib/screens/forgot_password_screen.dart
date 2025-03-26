import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/text_field_input.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _isSuccess = false;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      
      setState(() {
        _message = 'Password reset email sent! Please check your inbox.';
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getErrorMessage(e.code);
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again.';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Forgot Password?',
                    style: AppTypography.h4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email and we\'ll send you a link to reset your password',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildEmailField(),
                  const SizedBox(height: 24),
                  _buildResetButton(),
                  const SizedBox(height: 16),
                  _buildBackToLoginButton(),
                  const SizedBox(height: 24),
                  _buildMessageDisplay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFieldInput(
      textEditingController: _emailController,
      hintText: 'Enter your email',
      textInputType: TextInputType.emailAddress,
      labelText: 'Email',
      prefixIcon: const Icon(Icons.email),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Email is required';
        } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : Text(
                'Reset Password',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'Back to Login',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMessageDisplay() {
    if (_message.isEmpty) {
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
              _message,
              style: TextStyle(
                color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}