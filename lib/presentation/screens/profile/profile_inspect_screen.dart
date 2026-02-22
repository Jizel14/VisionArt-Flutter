import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/follow_model.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/artwork_service.dart';
import 'user_gallery_screen.dart';

class ProfileInspectScreen extends StatefulWidget {
  final String userId;
  final UserModel? initialUser;

  const ProfileInspectScreen({Key? key, required this.userId, this.initialUser})
    : super(key: key);

  @override
  State<ProfileInspectScreen> createState() => _ProfileInspectScreenState();
}

class _ProfileInspectScreenState extends State<ProfileInspectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FollowService _followService;
  late ArtworkService _artworkService;

  UserModel? _user;
  FollowStatusModel? _followStatus;
  List<FollowerModel> _followers = [];
  List<FollowerModel> _following = [];
  bool _isLoading = true;
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _followService = FollowService();
    _artworkService = ArtworkService();

    if (widget.initialUser != null) {
      _user = widget.initialUser;
    }

    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final status = await _followService.getFollowStatus(widget.userId);
      setState(() {
        _followStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading follow status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followStatus == null) return;

    try {
      if (_followStatus!.isFollowing) {
        await _followService.unfollowUser(widget.userId);
      } else {
        await _followService.followUser(widget.userId);
      }

      // Reload follow status
      await _loadProfileData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loadFollowers() async {
    if (_isLoadingFollowers || _followers.isNotEmpty) return;

    setState(() => _isLoadingFollowers = true);

    try {
      final result = await _followService.getFollowers(
        userId: widget.userId,
        limit: 50,
      );
      setState(() {
        _followers = result.data;
        _isLoadingFollowers = false;
      });
    } catch (e) {
      print('Error loading followers: $e');
      setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    if (_isLoadingFollowing || _following.isNotEmpty) return;

    setState(() => _isLoadingFollowing = true);

    try {
      final result = await _followService.getFollowing(
        userId: widget.userId,
        limit: 50,
      );
      setState(() {
        _following = result.data;
        _isLoadingFollowing = false;
      });
    } catch (e) {
      print('Error loading following: $e');
      setState(() => _isLoadingFollowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _user == null
          ? _buildErrorState()
          : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('User not found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _user!;
    final theme = Theme.of(context);

    return NestedScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            expandedHeight: 500,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: const BackButton(),
            title: innerBoxIsScrolled
                ? Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(user),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: theme
                    .scaffoldBackgroundColor, // Ensure tab bar has background when pinned
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                    0.6,
                  ),
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: 'Gallery (${user.publicGenerationsCount})'),
                    Tab(
                      text: 'Followers (${_followStatus?.followerCount ?? 0})',
                    ),
                    Tab(
                      text: 'Following (${_followStatus?.followingCount ?? 0})',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGalleryTab(user),
          _buildFollowersTab(),
          _buildFollowingTab(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48), // Space for status bar/AppBar
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Name and Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ],
              ),
              if (user.bio != null && user.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              if (_followStatus != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildRelationshipChips(theme),
                ),
              const SizedBox(height: 24),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Artworks',
                    user.publicGenerationsCount,
                    onTap: () => _handleStatTap(0),
                  ),
                  _buildStatItem(
                    'Followers',
                    _followStatus?.followerCount ?? 0,
                    onTap: () => _handleStatTap(1),
                  ),
                  _buildStatItem(
                    'Following',
                    _followStatus?.followingCount ?? 0,
                    onTap: () => _handleStatTap(2),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _followStatus?.isFollowing ?? false
                          ? theme.colorScheme.primary.withOpacity(0.14)
                          : theme.colorScheme.primary,
                      foregroundColor: _followStatus?.isFollowing ?? false
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimary,
                      side: _followStatus?.isFollowing ?? false
                          ? BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            )
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _followStatus?.isFollowing ?? false
                        ? const Text(
                            'Following',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Follow',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 48), // Space for TabBar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipChips(ThemeData theme) {
    final isFollowing = _followStatus?.isFollowing ?? false;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (isFollowing)
          _buildStatusChip(theme, Icons.check_circle, 'You follow', true),
        if (!isFollowing)
          _buildStatusChip(theme, Icons.add_circle, 'Not following', false),
      ],
    );
  }

  Widget _buildStatusChip(
    ThemeData theme,
    IconData icon,
    String label,
    bool isPositive,
  ) {
    final color = isPositive
        ? theme.colorScheme.primary
        : theme.textTheme.bodySmall?.color ?? Colors.grey;
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }

  Widget _buildStatItem(String label, int count, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
      ),
    );
  }

  Widget _buildGalleryTab(UserModel user) {
    return UserGalleryScreen(userId: user.id, userName: user.name);
  }

  Widget _buildFollowersTab() {
    if (_isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_followers.isEmpty) {
      return _buildEmptyState('No followers yet');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index];
        return _buildUserListTile(follower, label: 'Follower');
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_following.isEmpty) {
      return _buildEmptyState('Not following anyone');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final user = _following[index];
        return _buildUserListTile(user, label: 'Following');
      },
    );
  }

  void _handleStatTap(int tabIndex) {
    _tabController.animateTo(tabIndex);
    if (tabIndex == 1) {
      _loadFollowers();
    } else if (tabIndex == 2) {
      _loadFollowing();
    }
  }

  Widget _buildUserListTile(FollowerModel user, {required String label}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Row(
        children: [
          Text(user.name),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blue),
          ],
        ],
      ),
      subtitle: Text('${user.followersCount} followers'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileInspectScreen(
              userId: user.id,
              initialUser: UserModel(
                id: user.id,
                name: user.name,
                email: '',
                avatarUrl: user.avatarUrl,
                isVerified: user.isVerified,
                isPrivateAccount: false,
                followersCount: user.followersCount,
                followingCount: 0,
                publicGenerationsCount: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
