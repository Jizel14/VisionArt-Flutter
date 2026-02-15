import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/models/user_model.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/theme_extensions.dart';
import '../presentation/screens/home/home_tab.dart';
import '../presentation/screens/create/create_art_screen.dart';
import '../presentation/screens/marketplace/marketplace_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';

/// Shell with bottom nav: Home tab + Profile tab. Loads user once and passes to both.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final AuthService authService;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // Token is already set in main.dart via ApiClient.setToken()

      final user = await widget.authService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } on SessionExpiredException {
      // Session expired, automatically logout and navigate to login
      if (mounted) {
        await widget.authService.logout();
        widget.onLogout();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (mounted) widget.onLogout();
  }

  /// Handle theme changes from preferences
  void _handleThemeChanged(String theme) {
    // The theme preference has been saved to the backend and SharedPreferences by PreferencesUI
    // For immediate theme change, you could implement app-level state management (Provider, Riverpod, etc.)
    // For now, the theme will be applied on the next app restart
    // or you can show a message to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Theme preference saved. Will apply on next app restart.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?['name'] as String? ?? 'User';
    final userEmail = _user?['email'] as String? ?? '';
    final userBio = _user?['bio'] as String?;
    final userAvatarUrl = _user?['avatarUrl'] as String?;
    final userPhoneNumber = _user?['phoneNumber'] as String?;
    final userWebsite = _user?['website'] as String?;

    if (_error != null) {
      return Scaffold(
        backgroundColor: context.surfaceColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _logout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            userName: userName,
            isLoading: _loading,
            onToggleTheme: widget.onToggleTheme,
            currentUser: _user != null
                ? UserModel(
                    id: _user!['id'] ?? '',
                    email: _user!['email'] ?? '',
                    name: _user!['name'] ?? '',
                    bio: _user!['bio'],
                    avatarUrl: _user!['avatarUrl'],
                    followersCount: _user!['followersCount'] ?? 0,
                    followingCount: _user!['followingCount'] ?? 0,
                    publicGenerationsCount:
                        _user!['publicGenerationsCount'] ?? 0,
                    isVerified: _user!['isVerified'] ?? false,
                    isPrivateAccount: _user!['isPrivateAccount'] ?? false,
                    createdAt: _user!['createdAt'] != null
                        ? DateTime.parse(_user!['createdAt'] as String)
                        : DateTime.now(),
                    updatedAt: _user!['updatedAt'] != null
                        ? DateTime.parse(_user!['updatedAt'] as String)
                        : DateTime.now(),
                  )
                : null,
          ),
          const CreateArtScreen(),
          const MarketplaceScreen(),
          ProfileScreen(
            authService: widget.authService,
            apiClient: null,
            userName: userName,
            userEmail: userEmail,
            avatarUrl: userAvatarUrl,
            userBio: userBio,
            userPhoneNumber: userPhoneNumber,
            userWebsite: userWebsite,
            artworksCount: _user != null
                ? (_user!['publicGenerationsCount'] ?? 0)
                : 0,
            followersCount: _user != null ? (_user!['followersCount'] ?? 0) : 0,
            followingCount: _user != null ? (_user!['followingCount'] ?? 0) : 0,
            createdAt: _user != null && _user!['createdAt'] != null
                ? DateTime.tryParse(_user!['createdAt'].toString())
                : null,
            isLoading: _loading,
            onLogout: _logout,
            onProfileUpdated: _loadProfile,
            onToggleTheme: widget.onToggleTheme,
            onThemeChanged: _handleThemeChanged,
          ),
        ],
      ),
      bottomNavigationBar: _ThemedBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        itemCount: 4,
      ),
    );
  }
}

class _ThemedBottomNav extends StatelessWidget {
  const _ThemedBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.itemCount,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final surface = context.surfaceColor;
    final border = context.borderColor;
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? surface.withOpacity(0.92) : surface,
        border: Border(
          top: BorderSide(
            color: context.isDark
                ? AppColors.primaryBlue.withOpacity(0.25)
                : border.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                textColor: context.textPrimaryColor,
                secondaryColor: context.textSecondaryColor,
              ),
              _NavItem(
                icon: Icons.add_circle_rounded,
                label: 'Create',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                textColor: context.textPrimaryColor,
                secondaryColor: context.textSecondaryColor,
              ),
              _NavItem(
                icon: Icons.storefront_rounded,
                label: 'Market',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                textColor: context.textPrimaryColor,
                secondaryColor: context.textSecondaryColor,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                textColor: context.textPrimaryColor,
                secondaryColor: context.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
    required this.secondaryColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? AppColors.shadowSmall(AppColors.primaryPurple)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? Colors.white : secondaryColor,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
