import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth_service.dart';
import '../../../core/api_client.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/preference_storage.dart';
import '../../../core/services/artwork_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/social_share_sheet.dart';
import '../preferences/preferences_screen.dart';
import '../report/report_screen.dart';
import 'package:visionart_mobile/presentation/screens/splash/widgets/app_background_wrapper.dart';
import '../signature/signature_editor_screen.dart';
import 'artwork_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_inspect_screen.dart';
import 'widgets/sonic_universe_section.dart';

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
class ProfileScreen extends StatefulWidget {
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
    required this.userId,
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
  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ArtworkService _artworkService;
  bool _isLoadingMyArtworks = false;
  List<ArtworkModel> _myArtworks = const <ArtworkModel>[];

  @override
  void initState() {
    super.initState();
    _artworkService = ArtworkService();
    _loadMyArtworks();
  }

  UserModel get _currentUser => UserModel(
    id: widget.userId,
    name: widget.userName,
    email: widget.userEmail,
    bio: widget.userBio,
    avatarUrl: widget.avatarUrl,
    isVerified: false,
    isPrivateAccount: false,
    followersCount: widget.followersCount,
    followingCount: widget.followingCount,
    publicGenerationsCount: widget.artworksCount,
    createdAt: widget.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<void> _loadMyArtworks() async {
    if (_isLoadingMyArtworks) return;

    setState(() => _isLoadingMyArtworks = true);
    try {
      final result = await _artworkService.getMyArtworks(page: 1, limit: 6);
      if (!mounted) return;
      setState(() {
        _myArtworks = result.data;
        _isLoadingMyArtworks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMyArtworks = false);
    }
  }

  String _artworkLink(ArtworkModel artwork) =>
      'https://visionart.app/artworks/${artwork.id}';

  Future<void> _copyArtworkLink(ArtworkModel artwork) async {
    final link = _artworkLink(artwork);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Artwork link copied')));
  }

  Future<void> _shareArtwork(ArtworkModel artwork) async {
    final title = artwork.title?.trim().isNotEmpty == true
        ? artwork.title!.trim()
        : 'Untitled artwork';
    final link = _artworkLink(artwork);
    final caption = '$title\n$link';

    if (!mounted) return;
    showSocialShareSheet(
      context: context,
      link: link,
      caption: caption,
      subject: '$title – VisionArt',
    );
  }

  Future<void> _downloadArtwork(ArtworkModel artwork) async {
    final uri = Uri.tryParse(artwork.imageUrl);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openFollowers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileInspectScreen(
          userId: widget.userId,
          initialUser: _currentUser,
          initialTabIndex: 1,
        ),
      ),
    );
  }

  void _openFollowing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileInspectScreen(
          userId: widget.userId,
          initialUser: _currentUser,
          initialTabIndex: 2,
        ),
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileInspectScreen(
          userId: widget.userId,
          initialUser: _currentUser,
          initialTabIndex: 0,
        ),
      ),
    );
  }

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
    return AppBackgroundWrapper(
      child: SafeArea(
        child: widget.isLoading
            ? _buildShimmerLoading(context)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final border = AppThemeColors.borderColor(context);
    final secondary = AppThemeColors.textSecondaryColor(context);
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
      baseColor: AppThemeColors.borderColor(context),
      highlightColor: AppThemeColors.textSecondaryColor(context).withOpacity(0.3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemeColors.cardBackgroundColor(context).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
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
            child: ClipOval(
              child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userEmail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 24),
          // Bio card
          if (widget.userBio != null && widget.userBio!.isNotEmpty)
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
                        widget.userBio!,
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
                  value: '${widget.artworksCount}',
                  label: 'Artworks',
                  icon: Icons.brush_rounded,
                  onTap: _openGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${widget.followersCount}',
                  label: 'Followers',
                  icon: Icons.people_rounded,
                  onTap: _openFollowers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${widget.followingCount}',
                  label: 'Following',
                  icon: Icons.person_add_rounded,
                  onTap: _openFollowing,
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
                'Member since ${_formatDate(widget.createdAt)}',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My creations hub',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _openGallery,
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  Text(
                    'Manage your artworks: view, copy link, share, and download.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingMyArtworks)
                    const Center(child: CircularProgressIndicator())
                  else if (_myArtworks.isEmpty)
                    Text(
                      'No artworks yet. Create your first piece from the Create tab.',
                      style: TextStyle(color: textSecondary),
                    )
                  else
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _myArtworks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final artwork = _myArtworks[index];
                          return _MyArtworkCard(
                            artwork: artwork,
                            onView: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArtworkDetailScreen(artwork: artwork),
                                ),
                              );
                            },
                            onCopyLink: () => _copyArtworkLink(artwork),
                            onShare: () => _shareArtwork(artwork),
                            onDownload: () => _downloadArtwork(artwork),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GlassCard(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: SonicUniverseSection(),
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
                      authService: widget.authService,
                      initialName: widget.userName,
                      initialEmail: widget.userEmail,
                      initialBio: widget.userBio,
                      initialAvatarUrl: widget.avatarUrl,
                      initialPhoneNumber: widget.userPhoneNumber,
                      initialWebsite: widget.userWebsite,
                      onSaved: widget.onProfileUpdated ?? () {},
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
                color: AppThemeColors.textSecondaryColor(context),
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
              onTap: widget.onToggleTheme,
            ),
          ),
          _GlassCard(
            child: ListTile(
              leading: Icon(Icons.settings_rounded, color: AppThemeColors.textSecondaryColor(context)),
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
                      apiClient: widget.apiClient,
                      onPreferencesUpdated: () {
                        widget.onProfileUpdated?.call();
                      },
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GlassCard(
            child: ListTile(
              leading: Icon(
                Icons.flag_rounded,
                color: AppColors.error.withOpacity(0.8),
              ),
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
                    builder: (_) =>
                        ReportScreen(authService: widget.authService),
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
              onPressed: widget.onLogout,
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
            onPressed: () => _showDeleteAccountDialog(
              context,
              widget.authService,
              widget.onLogout,
            ),
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
            color: AppThemeColors.cardBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primaryBlue.withOpacity(0.25)
                  : AppThemeColors.borderColor(context).withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.12),
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
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
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
      ),
    );
  }
}

class _MyArtworkCard extends StatelessWidget {
  const _MyArtworkCard({
    required this.artwork,
    required this.onView,
    required this.onCopyLink,
    required this.onShare,
    required this.onDownload,
  });

  final ArtworkModel artwork;
  final VoidCallback onView;
  final VoidCallback onCopyLink;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);

    return SizedBox(
      width: 220,
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: artwork.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: (_, __, ___) => Container(
                          color: AppThemeColors.surfaceColor(context),
                          child: const Icon(Icons.image_not_supported_rounded),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            artwork.isPublic ? 'Public' : 'Private',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artwork.title?.trim().isNotEmpty == true
                    ? artwork.title!.trim()
                    : 'Untitled artwork',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${artwork.likesCount} likes • ${artwork.commentsCount} comments',
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _QuickAction(
                    label: 'View',
                    icon: Icons.visibility_rounded,
                    onTap: onView,
                  ),
                  _QuickAction(
                    label: 'Copy',
                    icon: Icons.link_rounded,
                    onTap: onCopyLink,
                  ),
                  _QuickAction(
                    label: 'Share',
                    icon: Icons.share_rounded,
                    onTap: onShare,
                  ),
                  _QuickAction(
                    label: 'Download',
                    icon: Icons.download_rounded,
                    onTap: onDownload,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppThemeColors.surfaceColor(context).withOpacity(0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppThemeColors.textSecondaryColor(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppThemeColors.textSecondaryColor(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
