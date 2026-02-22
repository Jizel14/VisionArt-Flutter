import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/models/user_model.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/theme_extensions.dart';
import '../presentation/screens/home/home_tab.dart';
import '../presentation/screens/create/create_art_screen.dart';
import '../presentation/screens/marketplace/marketplace_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';

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
      final user = await widget.authService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } on SessionExpiredException {
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

  UserModel? get _currentUser {
    if (_user == null) return null;

    return UserModel(
      id: _user!['id'] ?? '',
      email: _user!['email'] ?? '',
      name: _user!['name'] ?? '',
      bio: _user!['bio'],
      avatarUrl: _user!['avatarUrl'],
      followersCount: _user!['followersCount'] ?? 0,
      followingCount: _user!['followingCount'] ?? 0,
      publicGenerationsCount: _user!['publicGenerationsCount'] ?? 0,
      isVerified: _user!['isVerified'] ?? false,
      isPrivateAccount: _user!['isPrivateAccount'] ?? false,
      createdAt: _user!['createdAt'] != null
          ? DateTime.parse(_user!['createdAt'])
          : DateTime.now(),
      updatedAt: _user!['updatedAt'] != null
          ? DateTime.parse(_user!['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.surfaceColor,
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            userName: _user?['name'] ?? 'User',
            currentUser: _currentUser,
            isLoading: _loading,
            onToggleTheme: widget.onToggleTheme,
          ),
          const CreateArtScreen(),
          MarketplaceScreen(authService: widget.authService),
          ProfileScreen(
            authService: widget.authService,
            apiClient: null,
            userName: _user?['name'] ?? 'User',
            userEmail: _user?['email'] ?? '',
            avatarUrl: _user?['avatarUrl'],
            userBio: _user?['bio'],
            userPhoneNumber: _user?['phoneNumber'],
            userWebsite: _user?['website'],
            artworksCount: _user?['publicGenerationsCount'] ?? 0,
            followersCount: _user?['followersCount'] ?? 0,
            followingCount: _user?['followingCount'] ?? 0,
            createdAt: _user?['createdAt'] != null
                ? DateTime.tryParse(_user!['createdAt'])
                : null,
            isLoading: _loading,
            onLogout: _logout,
            onProfileUpdated: _loadProfile,
            onToggleTheme: widget.onToggleTheme,
            onThemeChanged: (_) {},
          ),
        ],
      ),
      bottomNavigationBar: _ThemedBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _ThemedBottomNav extends StatelessWidget {
  const _ThemedBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.borderColor.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.add_circle_rounded,
              label: 'Create',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: 'Market',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
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
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = context.textSecondaryColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}