import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class LGUUserManagementScreen extends StatefulWidget {
  const LGUUserManagementScreen({super.key});

  @override
  State<LGUUserManagementScreen> createState() => _LGUUserManagementScreenState();
}

class _LGUUserManagementScreenState extends State<LGUUserManagementScreen> {
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _formatRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'pnp':
        return 'PNP Personnel';
      case 'bfp':
        return 'BFP Personnel';
      case 'rescue':
        return 'Rescue Team';
      case 'responder':
        return 'Field Responder';
      default:
        return 'Citizen';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purpleAccent;
      case 'pnp':
        return Colors.blueAccent;
      case 'bfp':
        return AppConstants.primaryRed;
      case 'rescue':
      case 'responder':
        return Colors.orangeAccent;
      default:
        return Colors.tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'USER MANAGEMENT (RBAC)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Role Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search user name, email, or role...',
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRoleFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Administrator', value: 'admin'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('PNP Personnel', value: 'pnp'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('BFP Personnel', value: 'bfp'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Rescue Team', value: 'rescue'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Citizens', value: 'citizen'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Accounts List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: firestore.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppConstants.primaryRed));
                }

                final users = snapshot.data ?? [];
                final filtered = users.where((u) {
                  if (_selectedRoleFilter != 'All') {
                    if (u.role.toLowerCase() != _selectedRoleFilter.toLowerCase()) return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final matchName = u.name.toLowerCase().contains(q);
                    final matchEmail = u.email.toLowerCase().contains(q);
                    final matchRole = u.role.toLowerCase().contains(q);
                    if (!matchName && !matchEmail && !matchRole) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 54, color: (isDark ? Colors.white : Colors.black).withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text('No users matching criteria', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _buildUserCard(context, user, firestore);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, {String? value}) {
    final effectiveVal = value ?? label;
    final isSelected = _selectedRoleFilter.toLowerCase() == effectiveVal.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54))),
      selected: isSelected,
      selectedColor: AppConstants.primaryRed,
      backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.black.withOpacity(0.04),
      onSelected: (val) => setState(() => _selectedRoleFilter = effectiveVal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2841) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.15),
            child: Icon(Icons.person_rounded, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Unknown User',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatRoleName(user.role),
                    style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          // Status & Role Switch Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Active toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: user.isActive ? Colors.greenAccent : Colors.grey),
                  ),
                  Switch.adaptive(
                    value: user.isActive,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) {
                      firestore.toggleUserStatus(user.userId, user.isActive);
                    },
                  ),
                ],
              ),
              // Role Edit Button
              InkWell(
                onTap: () => _showRoleSwitchDialog(context, user, firestore),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    'CHANGE ROLE',
                    style: TextStyle(color: AppConstants.primaryRed, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoleSwitchDialog(BuildContext context, UserModel user, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2841) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('CHANGE ROLE: ${user.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: ['admin', 'pnp', 'bfp', 'rescue', 'responder', 'citizen'].contains(selectedRole)
                    ? selectedRole
                    : 'citizen',
                dropdownColor: isDark ? const Color(0xFF161E31) : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrator (LGU)')),
                  DropdownMenuItem(value: 'pnp', child: Text('PNP Personnel (Police)')),
                  DropdownMenuItem(value: 'bfp', child: Text('BFP Personnel (Fire)')),
                  DropdownMenuItem(value: 'rescue', child: Text('Rescue Team (CDRRMO)')),
                  DropdownMenuItem(value: 'responder', child: Text('General Field Responder')),
                  DropdownMenuItem(value: 'citizen', child: Text('Citizen Account')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
              onPressed: () async {
                await firestore.updateUserRole(user.userId, selectedRole);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role updated to ${_formatRoleName(selectedRole)}')),
                  );
                }
              },
              child: const Text('SAVE ROLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
