import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/models/user_model.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/theme_extensions.dart';
import '../presentation/screens/ai/prompt_enhancer_sheet.dart';
import '../presentation/screens/ai/inpainting_sheet.dart';
import '../presentation/screens/ai/style_transfer_sheet.dart';
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

  void _onNavTap(int i) {
    if (_currentIndex == i && i == 1) {
      _showAIAssistantSheet();
    } else {
      setState(() => _currentIndex = i);
    }
  }

  void _showAIAssistantSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: AppColors.shadowLarge(Colors.black),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: context.textSecondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryPurple, AppColors.lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.shadowMedium(AppColors.primaryPurple.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Assistant IA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Boostez votre créativité avec nos outils intelligents',
                      style: TextStyle(
                        fontSize: 13, 
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
              _AssistantOption(
                icon: Icons.auto_awesome,
                title: 'Assistant de Prompt',
                subtitle: "Génère un prompt détaillé à partir d'une idée simple",
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PromptEnhancerSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AssistantOption(
                icon: Icons.format_paint,
                title: 'Inpainting & Outpainting',
                subtitle: 'Modifie une zone ou étends une image générée',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const InpaintingSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AssistantOption(
                icon: Icons.style,
                title: 'Transfert de Style',
                subtitle: "Applique le style d'un artiste sur ta photo",
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const StyleTransferSheet(),
                  );
                },
              ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.surfaceColor,
        body: Center(
          child: Text(_error!, style: TextStyle(color: AppColors.error)),
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
            onRefreshProfile: _loadProfile,
            onToggleTheme: widget.onToggleTheme,
            onThemeChanged: (_) {},
          ),
        ],
      ),
      bottomNavigationBar: _ThemedBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _ThemedBottomNav extends StatelessWidget {
  const _ThemedBottomNav({required this.currentIndex, required this.onTap});

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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

class _AssistantOption extends StatelessWidget {
  const _AssistantOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowSmall(Colors.black.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: context.cardBackgroundColor.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryPurple.withOpacity(0.2), AppColors.lightBlue.withOpacity(0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: AppColors.lightBlue, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.lightBlue, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
