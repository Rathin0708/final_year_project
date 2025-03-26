import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../widgets/text_field_input.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';
import '../utils/app_dimensions.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Register with Firebase
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (userCredential != null && mounted) {
        // Update user provider with new user data
        await Provider.of<UserProvider>(context, listen: false).fetchUserData();
        
        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please provide a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email/Password accounts are not enabled.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  // Google Sign-up
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in/up with Firebase using AuthService
      final userCredential = await _authService.signInWithCredential(credential);

      // User creation is handled by the AuthService

      // Check that we're still logged in
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        // Use direct navigation instead of named routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Google sign-in was successful, but session failed to persist. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Google sign-up error: $e");
      }
      setState(() {
        _errorMessage = 'Google sign-up failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Apple Sign-up
  Future<void> _signUpWithApple() async {
    if (!Platform.isIOS && !kIsWeb) {
      setState(() {
        _errorMessage = 'Apple Sign-in is only available on iOS and web platforms.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Apple sign in process
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Create OAuthCredential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase using AuthService
      final userCredential = await _authService.signInWithCredential(oauthCredential);
      
      // User creation is handled by the AuthService

      // Check that we're still logged in
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        try {
          // Add a short delay to ensure Firebase completes its internal processes
          await Future.delayed(const Duration(milliseconds: 500));
          // await Provider.of<UserProvider>(context, listen: false).fetchUserData();
        } catch (e) {
          print("Provider update error (non-fatal): $e");
          // Continue anyway
        }
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Apple sign-in was successful, but session failed to persist. Please try again.';
        });
      }
    } catch (e) {
      print("Apple sign-up error: $e");
      setState(() {
        _errorMessage = 'Apple sign-up failed. Please try again.';
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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
        
                  Text(
                    'Create an account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
        
                  Text(
                    'Enter your details to sign up',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
        
                  // Status message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
        
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
        
                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
        
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
        
                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Password and confirm password do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
        
                  // Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register'),
                  ),
                  const SizedBox(height: 24),
        
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 14),
        
                  // Social login buttons
                  Column(
                    children: [
                      const Text('Or sign up with'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google sign-in
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _signUpWithGoogle,
                              icon: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                                    ),
                              label: const Text('Google'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                backgroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
          
                          // Apple sign-in (conditionally displayed)
                          if (Platform.isIOS || kIsWeb)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signUpWithApple,
                                icon: _isLoading 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.apple, color: Colors.white),
                                label: const Text('Apple'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
        
                  // Login option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to login screen
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}