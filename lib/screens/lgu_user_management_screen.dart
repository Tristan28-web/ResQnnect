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

  Color _getRoleBg(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.retroLilac;
      case 'pnp':
        return const Color(0xFFDBEAFE);
      case 'bfp':
        return AppColors.retroPeach;
      case 'rescue':
      case 'responder':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF6D28D9);
      case 'pnp':
        return const Color(0xFF1D4ED8);
      case 'bfp':
        return const Color(0xFFDC2626);
      case 'rescue':
      case 'responder':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'USER MANAGEMENT (RBAC)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.retroDarkBorder),
      ),
      body: Column(
        children: [
          // Search & Role Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              children: [
                // Retro Pill Search Bar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.retroDarkBorder,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search user name, email, or role...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Retro Role Filter Pills (Edge-to-Edge scrolling)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: -20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildRoleFilterPill('All'),
                        const SizedBox(width: 8),
                        _buildRoleFilterPill('Administrator', value: 'admin'),
                        const SizedBox(width: 8),
                        _buildRoleFilterPill('PNP Personnel', value: 'pnp'),
                        const SizedBox(width: 8),
                        _buildRoleFilterPill('BFP Personnel', value: 'bfp'),
                        const SizedBox(width: 8),
                        _buildRoleFilterPill('Rescue Team', value: 'rescue'),
                        const SizedBox(width: 8),
                        _buildRoleFilterPill('Citizens', value: 'citizen'),
                      ],
                    ),
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
                  return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
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
                        Icon(
                          Icons.people_outline_rounded,
                          size: 54,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users matching criteria',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _buildRetroUserCard(context, user, firestore);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterPill(String label, {String? value}) {
    final effectiveVal = value ?? label;
    final isSelected = _selectedRoleFilter.toLowerCase() == effectiveVal.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = effectiveVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.retroMint
              : (isDark ? AppColors.retroDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.retroDarkBorder
                : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.12),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.retroDarkBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroUserCard(BuildContext context, UserModel user, FirestoreService firestore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleBg = _getRoleBg(user.role);
    final roleTextColor = _getRoleTextColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withOpacity(0.08),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
            ),
            child: Center(
              child: Icon(Icons.person_rounded, color: roleTextColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.retroDarkBorder,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                  ),
                  child: Text(
                    _formatRoleName(user.role),
                    style: TextStyle(
                      color: roleTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status & Role Switch Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: user.isActive ? const Color(0xFF16A34A) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch.adaptive(
                    value: user.isActive,
                    activeColor: AppColors.retroMint,
                    onChanged: (val) {
                      firestore.toggleUserStatus(user.userId, user.isActive);
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showRoleSwitchDialog(context, user, firestore),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.retroLilac,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                  ),
                  child: const Text(
                    'CHANGE ROLE',
                    style: TextStyle(
                      color: AppColors.retroDarkBorder,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
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
          backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.retroDarkBorder, width: 2),
          ),
          title: Text(
            'CHANGE ROLE: ${user.name}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.retroDarkBorder,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: ['admin', 'pnp', 'bfp', 'rescue', 'responder', 'citizen'].contains(selectedRole)
                    ? selectedRole
                    : 'citizen',
                dropdownColor: isDark ? AppColors.retroDarkCard : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrator (LGU Command)')),
                  DropdownMenuItem(value: 'pnp', child: Text('PNP Personnel (Police)')),
                  DropdownMenuItem(value: 'bfp', child: Text('BFP Personnel (Fire)')),
                  DropdownMenuItem(value: 'rescue', child: Text('Rescue Team (CDRRMO)')),
                  DropdownMenuItem(value: 'responder', child: Text('General Field Responder')),
                  DropdownMenuItem(value: 'citizen', child: Text('Citizen Account')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRole = val);
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.retroMint,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.retroDarkBorder, width: 1.4),
                ),
              ),
              onPressed: () async {
                await firestore.updateUserRole(user.userId, selectedRole);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role updated to ${_formatRoleName(selectedRole)}')),
                  );
                }
              },
              child: const Text('SAVE ROLE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
