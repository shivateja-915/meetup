import 'package:flutter/material.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        _profile = await SupabaseService.getProfile(userId);
      }
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name'] ?? 'User';
    final email = SupabaseService.currentUser?.email ?? '';
    final avatarUrl = _profile?['avatar_url'];

    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.warmGradient),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.warmGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),

              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) => _buildAvatarFallback(name),
                        ),
                      )
                    : _buildAvatarFallback(name),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Menu items
              _ProfileMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: _profile),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
