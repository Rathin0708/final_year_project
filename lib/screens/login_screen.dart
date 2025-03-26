import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/text_field_input.dart';
import '../utils/app_dimensions.dart';
import '../utils/app_typography.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'forgot_password_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  // Email/Password Login
  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Call the sign in method from auth service
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text,
      );
      
      // Check if we got a valid user
      if (userCredential.user != null && mounted) {
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
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      debugPrint('Login Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Start the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
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
      
      // Sign in with Firebase
      final userCredential = await _authService.signInWithCredential(credential);
      
      if (userCredential.user != null && mounted) {
        // Update user provider after successful login
        await Provider.of<UserProvider>(context, listen: false).fetchUserData();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Apple Sign-In
  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Request Apple Sign-In credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Create OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      // Sign in with Firebase
      final userCredential = await _authService.signInWithCredential(oauthCredential);
      
      if (userCredential.user != null) {
        // Update user display name if it's null and we have first/last name
        if (userCredential.user!.displayName == null && 
            (appleCredential.givenName != null || appleCredential.familyName != null)) {
          await userCredential.user!.updateDisplayName(
            [appleCredential.givenName, appleCredential.familyName]
                .whereType<String>()
                .join(' ')
          );
        }
        
        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).fetchUserData();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-in failed. Please try again.';
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
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: AppDimensions.paddingXXL,
              ),
              Text("Welcome Back", style: AppTypography.h3),
              const SizedBox(
                height: 64,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
                      child: TextFieldInput(
                        textEditingController: emailController,
                        hintText: "Enter your email",
                        textInputType: TextInputType.emailAddress,
                        labelText: "Email",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a valid email address';
                          } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                            return 'Please enter a valid email format';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
                      child: TextFieldInput(
                        textEditingController: passController,
                        hintText: "Enter your password",
                        isPass: true,
                        textInputType: TextInputType.visiblePassword,
                        labelText: "Password",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                      child: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          )
                        : const Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text('Forgot Password?', style: AppTypography.bodyMedium),
                    ),
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account?', style: AppTypography.bodyMedium),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text('Register', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google sign-in
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png', // Make sure to add this to your assets
                            height: 24,
                          ),
                          label: Text('Google'),
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
                        const SizedBox(width: 16),
                        
                        // Apple sign-in (iOS only)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithApple,
                          icon: Icon(Icons.apple, color: Colors.white),
                          label: Text('Apple'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}