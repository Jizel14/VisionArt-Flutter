import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/auth_service.dart';
import '../../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import '../signature/signature_editor_screen.dart';
import 'edit_profile_screen.dart';

Future<void> _showDeleteAccountDialog(
  BuildContext context,
  AuthService authService,
  VoidCallback onLogout,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: const Text(
        'Cette action supprimera définitivement votre compte et toutes vos données. Elle est irréversible.\n\nVoulez-vous vraiment continuer ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;
  try {
    await authService.deleteAccount();
    await PreferenceStorage.clear();
    if (!context.mounted) return;
    onLogout();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Profile screen: avatar, name, email, mock stats, logout. Themed with glassmorphism.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    this.apiClient,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    this.userBio,
    this.userPhoneNumber,
    this.userWebsite,
    required this.onLogout,
    this.onProfileUpdated,
    required this.onToggleTheme,
    this.onThemeChanged,
    this.isLoading = false,
    this.artworksCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.createdAt,
  });

  final AuthService authService;
  final ApiClient? apiClient;
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final String? userBio;
  final String? userPhoneNumber;
  final String? userWebsite;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;
  final VoidCallback onToggleTheme;
  final Function(String)? onThemeChanged;
  final bool isLoading;
  final int artworksCount;
  final int followersCount;
  final int followingCount;
  final DateTime? createdAt;

  // Mock data for profile
  // static const int mockArtworksCount = 12; // Removed
  // static const int mockFavoritesCount = 8; // Removed
  // static const String mockMemberSince = 'Feb 2025'; // Removed
  // static const String mockBio = 'Creating art from context. Love abstract & landscape.'; // Removed

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SmokeBackground(
      child: SafeArea(
        child: isLoading
            ? _buildShimmerLoading(context)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final border = context.borderColor;
    final secondary = context.textSecondaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(color: border, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 16,
              width: 220,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _shimmerCard(context),
          const SizedBox(height: 16),
          _shimmerCard(context),
        ],
      ),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.borderColor,
      highlightColor: context.textSecondaryColor.withOpacity(0.3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor.withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: AppColors.shadowMedium(AppColors.primaryPurple),
              border: Border.all(
                color: AppColors.lightBlue.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 24),
          // Bio card
          if (userBio != null && userBio!.isNotEmpty)
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.accentPink,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userBio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$artworksCount',
                  label: 'Artworks',
                  icon: Icons.brush_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$followersCount',
                  label: 'Followers',
                  icon: Icons.people_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$followingCount',
                  label: 'Following',
                  icon: Icons.person_add_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.lightBlue,
                size: 22,
              ),
              title: Text(
                'Member since ${_formatDate(createdAt)}',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Edit profile (mock)
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
              title: Text(
                'Edit profile',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      authService: authService,
                      initialName: userName,
                      initialEmail: userEmail,
                      initialBio: userBio,
                      initialAvatarUrl: avatarUrl,
                      initialPhoneNumber: userPhoneNumber,
                      initialWebsite: userWebsite,
                      onSaved: onProfileUpdated ?? () {},
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.palette_rounded, color: AppColors.primaryBlue),
              title: Text(
                'Mes préférences',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Sujets, styles, couleurs, ambiance',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: () async {
                final prefs = await PreferenceStorage.load();
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PreferencesOnboardingScreen(
                      authService: authService,
                      initialPreferences: prefs,
                      onComplete: () {
                        Navigator.of(context).pop();
                        onProfileUpdated?.call();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.draw_rounded, color: AppColors.nftAccent),
              title: Text(
                'My signature',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Personal logo on splash',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignatureEditorScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: textSecondary,
              ),
              title: Text(
                Theme.of(context).brightness == Brightness.dark
                    ? 'Light mode'
                    : 'Dark mode',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: onToggleTheme,
            ),
          ),
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.settings_rounded, color: textSecondary),
              title: Text(
                'Preferences',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PreferencesScreen(
                      apiClient: apiClient,
                      onPreferencesUpdated: () {
                        onProfileUpdated?.call();
                      },
                      onThemeChanged: onThemeChanged,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.flag_rounded, color: AppColors.error.withOpacity(0.8)),
              title: Text(
                'Signaler un problème',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Bug, abus, contenu inapproprié',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportScreen(authService: authService),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          // Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentPink,
                side: BorderSide(color: AppColors.accentPink.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delete account
          TextButton(
            onPressed: () => _showDeleteAccountDialog(context, authService, onLogout),
            child: Text(
              'Supprimer mon compte',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.25)
                  : context.borderColor.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
