import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration Failed.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/Password accounts are not enabled in Firebase Console.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: isDark ? Colors.white : AppColors.retroDarkBorder,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'JOIN GIS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.retroMint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.retroDarkBorder,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'CITIZEN REGISTRATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create an official verified account for GIS reporting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              // Retro Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.retroDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.12),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: _isLoading ? null : _register,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.retroMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.retroDarkBorder, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.retroDarkBorder,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : AppColors.retroPeach,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withOpacity(0.1),
                        offset: const Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 16, color: isDark ? Colors.white : AppColors.retroDarkBorder),
                        const SizedBox(width: 8),
                        Text(
                          'ALREADY HAVE AN ACCOUNT? LOGIN',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.retroDarkBorder,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppColors.retroMint, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF262C38) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.retroMint, width: 2.0),
        ),
      ),
    );
  }
}
