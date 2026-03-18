import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/profile_image.dart';

class ManageRespondersScreen extends StatefulWidget {
  const ManageRespondersScreen({super.key});

  @override
  State<ManageRespondersScreen> createState() => _ManageRespondersScreenState();
}

class _ManageRespondersScreenState extends State<ManageRespondersScreen> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every minute to update shift timers
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  String _calculateShift(DateTime? clockIn) {
    if (clockIn == null) return '0m';
    final diff = DateTime.now().difference(clockIn);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MANAGE RESPONDERS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppConstants.primaryRed),
            onPressed: () => _showAddResponderDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getResponders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No responders found.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
          }

          final responders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: responders.length,
            itemBuilder: (context, index) {
              final responder = responders[index];
              final shiftTime = _calculateShift(responder.lastClockIn);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: isDark ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E2841), Color(0xFF161E31)],
                  ) : null,
                  color: isDark ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  boxShadow: isDark 
                      ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] 
                      : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: ProfileImage(
                    source: responder.profileImage,
                    radius: 20,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(responder.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                      if (responder.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 10, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                shiftTime,
                                style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(responder.email, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: responder.isActive,
                        activeColor: AppConstants.primaryRed,
                        onChanged: (value) {
                          firestoreService.toggleResponderActive(responder.userId, !value);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
                        onPressed: () => _showEditResponderDialog(context, responder),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddResponderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool _isLoading = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
        backgroundColor: const Color(0xFF1E2841),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Responder', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _buildTextField(context, nameController, 'Full Name', Icons.person_outline, enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildTextField(context, emailController, 'Email', Icons.email_outlined, enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildTextField(context, phoneController, 'Phone', Icons.phone_outlined, enabled: !_isLoading),
              const SizedBox(height: 16),
              _buildTextField(context, passwordController, 'Password', Icons.lock_outline, obscure: true, enabled: !_isLoading),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : () async {
                      if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) return;
                      
                      setState(() => _isLoading = true);
                      
                      final authService = Provider.of<AuthService>(context, listen: false);
                      try {
                        final creds = await authService.register(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          nameController.text.trim(),
                          phoneController.text.trim(),
                        );
                        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                        await firestoreService.updateResponderProfile(UserModel(
                          userId: creds.user!.uid,
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          profileImage: '',
                          role: 'responder',
                          isActive: true,
                          createdAt: DateTime.now(),
                        ));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responder added successfully')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                          final errorStr = e.toString();
                          if (!errorStr.contains('email-already-in-use')) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errorStr')));
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responder added successfully')));
                          }
                        }
                      }
                    },
                    child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ADD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showEditResponderDialog(BuildContext context, UserModel responder) {
    final nameController = TextEditingController(text: responder.name);
    final phoneController = TextEditingController(text: responder.phone);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2841),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Responder', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _buildTextField(context, nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(context, phoneController, 'Phone', Icons.phone_outlined),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                      await firestoreService.updateResponderProfile(UserModel(
                        userId: responder.userId,
                        name: nameController.text,
                        email: responder.email,
                        phone: phoneController.text,
                        profileImage: responder.profileImage,
                        role: responder.role,
                        isActive: responder.isActive,
                        createdAt: responder.createdAt,
                      ));
                      Navigator.pop(context);
                    },
                    child: const Text('SAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, IconData icon, {bool obscure = false, bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        prefixIcon: Icon(icon, color: AppConstants.primaryRed, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.primaryRed)),
        filled: !isDark,
        fillColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
      ),
    );
  }
}
