import 'package:flutter/material.dart';
import '../../../core/services/notifications_service.dart';
import '../../theme/theme_extensions.dart';
import 'package:visionart_mobile/presentation/screens/splash/widgets/app_background_wrapper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsService _notificationsService = NotificationsService();

  List<AppNotificationItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _notificationsService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markOneAsRead(AppNotificationItem item) async {
    if (item.isRead) return;

    try {
      await _notificationsService.markAsRead(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (e) => e.id == item.id
                  ? AppNotificationItem(
                      id: e.id,
                      type: e.type,
                      title: e.title,
                      message: e.message,
                      isRead: true,
                      createdAt: e.createdAt,
                      actorName: e.actorName,
                      actorAvatarUrl: e.actorAvatarUrl,
                      artworkId: e.artworkId,
                      artworkTitle: e.artworkTitle,
                      artworkImageUrl: e.artworkImageUrl,
                    )
                  : e,
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (e) => AppNotificationItem(
                id: e.id,
                type: e.type,
                title: e.title,
                message: e.message,
                isRead: true,
                createdAt: e.createdAt,
                actorName: e.actorName,
                actorAvatarUrl: e.actorAvatarUrl,
                artworkId: e.artworkId,
                artworkTitle: e.artworkTitle,
                artworkImageUrl: e.artworkImageUrl,
              ),
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _openNotification(AppNotificationItem item) async {
    await _markOneAsRead(item);

    if (!mounted) return;
    if (item.artworkId == null || item.artworkId!.isEmpty) return;

    Navigator.pop(context, item.artworkId);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final unreadCount = _items.where((item) => !item.isRead).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Notifications'),
      ),
      body: AppBackgroundWrapper(
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppThemeColors.cardBackgroundColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeColors.borderColor(context).withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity updates',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unreadCount > 0
                                  ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                                  : 'Everything is up to date',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: unreadCount == 0 ? null : _markAllAsRead,
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = _items[index];
                            return InkWell(
                              onTap: () => _openNotification(item),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppThemeColors.cardBackgroundColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: item.isRead
                                        ? AppThemeColors.borderColor(context).withOpacity(0.3)
                                        : Theme.of(context).colorScheme.primary
                                              .withOpacity(0.6),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          item.actorAvatarUrl != null
                                          ? NetworkImage(item.actorAvatarUrl!)
                                          : null,
                                      child: item.actorAvatarUrl == null
                                          ? const Icon(
                                              Icons.notifications_rounded,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.message,
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatTime(item.createdAt),
                                            style: TextStyle(
                                              color: textSecondary.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
