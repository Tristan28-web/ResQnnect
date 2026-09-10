import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../widgets/profile_image.dart';

class LGUUserManagementScreen extends StatefulWidget {
  const LGUUserManagementScreen({super.key});

  @override
  State<LGUUserManagementScreen> createState() => _LGUUserManagementScreenState();
}

class _LGUUserManagementScreenState extends State<LGUUserManagementScreen> {
  String _selectedRole = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.retroDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.5),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: isDark ? Colors.white : AppColors.retroDarkBorder),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'USER MANAGEMENT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.retroMint));
          }

          final allUsers = snapshot.data ?? [];
          final filtered = allUsers.where((u) {
            // Role filter (Strictly Admin and Citizen)
            if (_selectedRole == 'Admins' && u.role != AppConstants.roleAdmin) return false;
            if (_selectedRole == 'Citizens' && u.role != AppConstants.roleCitizen) return false;

            // Search query
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final nameMatch = u.name.toLowerCase().contains(q);
              final emailMatch = u.email.toLowerCase().contains(q);
              final phoneMatch = u.phone.toLowerCase().contains(q);
              if (!nameMatch && !emailMatch && !phoneMatch) return false;
            }

            return true;
          }).toList();

          final adminCount = allUsers.where((u) => u.role == AppConstants.roleAdmin).length;
          final citizenCount = allUsers.where((u) => u.role == AppConstants.roleCitizen).length;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Protocol Banner
                _buildRetroProtocolBanner(allUsers.length, adminCount, citizenCount, isDark),
                const SizedBox(height: 18),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.retroDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : AppColors.retroDarkBorder.withValues(alpha: 0.1),
                        offset: const Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search user by Name, Email, or Phone...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white54 : AppColors.retroDarkBorder),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Role Filter Pills (All, Admins, Citizens)
                Row(
                  children: [
                    _buildRoleFilterPill('All', isDark),
                    const SizedBox(width: 8),
                    _buildRoleFilterPill('Admins', isDark),
                    const SizedBox(width: 8),
                    _buildRoleFilterPill('Citizens', isDark),
                  ],
                ),
                const SizedBox(height: 18),

                // Users List
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.retroDarkCard : AppColors.retroPeach,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 1.8),
                            ),
                            child: Icon(Icons.group_off_rounded, size: 36, color: isDark ? Colors.white38 : AppColors.retroDarkBorder),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No users found matching query',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : AppColors.retroDarkBorder,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((user) => _buildUserCard(context, user, firestoreService, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetroProtocolBanner(int total, int admins, int citizens, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2421) : AppColors.retroPeach,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C38) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withValues(alpha: 0.12),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white24 : AppColors.retroDarkBorder,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF6D28D9), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '10. USER MANAGEMENT & RBAC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: isDark ? Colors.white : AppColors.retroDarkBorder,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Text(
                  '$total REGISTERED',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Administer GIS platform accounts. All users operate strictly as System Administrators or Verified Citizens.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF4B5563),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricChip('Admins: $admins', AppColors.retroLilac, isDark),
              const SizedBox(width: 8),
              _buildMetricChip('Citizens: $citizens', const Color(0xFFDCFCE7), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text, Color bg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262C38) : bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.retroDarkBorder,
        ),
      ),
    );
  }

  Widget _buildRoleFilterPill(String role, bool isDark) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.retroLilac
              : (isDark ? AppColors.retroDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.retroDarkBorder
                : (isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder.withValues(alpha: 0.4)),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          role.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: isDark ? (isSelected ? AppColors.retroDarkBorder : Colors.white70) : AppColors.retroDarkBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, FirestoreService firestoreService, bool isDark) {
    final isAdmin = user.role == AppConstants.roleAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.retroDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.retroDarkBorder.withValues(alpha: 0.12),
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Avatar, Info, Role Tag
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.8),
                ),
                child: ClipOval(
                  child: ProfileImage(
                    radius: 23,
                    source: user.profileImage,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'Citizen User',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.retroDarkBorder,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Registered: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdmin ? AppColors.retroLilac : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.retroDarkBorder, width: 1.2),
                ),
                child: Text(
                  isAdmin ? 'ADMIN' : 'CITIZEN',
                  style: TextStyle(
                    color: isAdmin ? const Color(0xFF6D28D9) : const Color(0xFF16A34A),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Divider(height: 1, color: isDark ? Colors.white10 : AppColors.retroDarkBorder.withValues(alpha: 0.1)),
          const SizedBox(height: 12),

          // Bottom Controls: Role Selector & Status Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Role Switcher Button
              GestureDetector(
                onTap: () => _showRoleDialog(context, user, firestoreService, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.retroPeach,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.published_with_changes_rounded, size: 14, color: AppColors.retroDarkBorder),
                      const SizedBox(width: 4),
                      Text(
                        'ROLE: ${isAdmin ? "ADMIN" : "CITIZEN"}',
                        style: const TextStyle(
                          color: AppColors.retroDarkBorder,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status Toggle (Active / Suspended)
              GestureDetector(
                onTap: () async {
                  final newStatus = !user.isActive;
                  await firestoreService.toggleUserStatus(user.userId, newStatus);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user.name} is now ${newStatus ? "Active" : "Suspended"}'),
                        backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.retroDarkBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : AppColors.retroDarkBorder,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                        size: 14,
                        color: user.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'ACTIVE' : 'SUSPENDED',
                        style: TextStyle(
                          color: user.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, UserModel user, FirestoreService firestoreService, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.retroDarkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: isDark ? const Color(0xFF3E4556) : AppColors.retroDarkBorder, width: 2.0),
        ),
        elevation: 0,
        title: Text(
          'ASSIGN SYSTEM ROLE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.retroDarkBorder,
            letterSpacing: 0.8,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select role for ${user.name}:',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.retroDarkBorder),
            ),
            const SizedBox(height: 14),
            _buildRoleOptionTile(
              label: 'Verified Citizen',
              desc: 'Submits geo-referenced incidents & SOS alerts',
              isSelected: user.role == AppConstants.roleCitizen,
              color: const Color(0xFF16A34A),
              onTap: () async {
                await firestoreService.updateUserRole(user.userId, AppConstants.roleCitizen);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildRoleOptionTile(
              label: 'System Administrator',
              desc: 'Full GIS mapping, monitoring, and command privileges',
              isSelected: user.role == AppConstants.roleAdmin,
              color: const Color(0xFF6D28D9),
              onTap: () async {
                await firestoreService.updateUserRole(user.userId, AppConstants.roleAdmin);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOptionTile({
    required String label,
    required String desc,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF262C38) : AppColors.retroPeach)
              : (isDark ? Colors.black26 : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.retroDarkBorder : (isDark ? const Color(0xFF3E4556) : Colors.black12),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDark ? Colors.white : AppColors.retroDarkBorder)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
