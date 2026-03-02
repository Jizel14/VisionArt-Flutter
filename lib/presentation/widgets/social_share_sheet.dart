import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a bottom sheet with dedicated social-sharing targets.
///
/// [link]    – the URL to share (profile / artwork / etc.)
/// [caption] – text that accompanies the link (auto-composed per platform)
/// [subject] – optional email-style subject when using system share
void showSocialShareSheet({
  required BuildContext context,
  required String link,
  required String caption,
  String? subject,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        _SocialShareSheet(link: link, caption: caption, subject: subject),
  );
}

class _SocialShareSheet extends StatelessWidget {
  const _SocialShareSheet({
    required this.link,
    required this.caption,
    this.subject,
  });

  final String link;
  final String caption;
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF1A1A2E)
        : theme.colorScheme.surface;
    final dividerColor = theme.dividerColor.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share via',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Social targets grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SocialTarget(
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () => _shareWhatsApp(context),
                  ),
                  _SocialTarget(
                    label: 'X',
                    icon: Icons.alternate_email_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    onTap: () => _shareX(context),
                  ),
                  _SocialTarget(
                    label: 'Telegram',
                    icon: Icons.send_rounded,
                    color: const Color(0xFF0088CC),
                    onTap: () => _shareTelegram(context),
                  ),
                  _SocialTarget(
                    label: 'Instagram',
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFE1306C),
                    onTap: () => _shareInstagram(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: dividerColor, height: 1),
            // Copy link & System share
            _ActionTile(
              icon: Icons.link_rounded,
              label: 'Copy link',
              onTap: () => _copyLink(context),
            ),
            Divider(color: dividerColor, height: 1, indent: 56),
            _ActionTile(
              icon: Icons.ios_share_rounded,
              label: 'More options…',
              onTap: () => _systemShare(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── platform launchers ─────────────────────────────────

  Future<void> _shareWhatsApp(BuildContext context) async {
    Navigator.pop(context);
    final encoded = Uri.encodeComponent(caption);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _fallbackShare(context);
    }
  }

  Future<void> _shareX(BuildContext context) async {
    Navigator.pop(context);
    final encoded = Uri.encodeComponent(caption);
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _fallbackShare(context);
    }
  }

  Future<void> _shareTelegram(BuildContext context) async {
    Navigator.pop(context);
    final encoded = Uri.encodeComponent(caption);
    final uri = Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _fallbackShare(context);
    }
  }

  Future<void> _shareInstagram(BuildContext context) async {
    Navigator.pop(context);
    // Instagram doesn't support text share via URL scheme – copy caption
    await Clipboard.setData(ClipboardData(text: caption));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Caption copied! Paste it in your Instagram post or story.',
          ),
        ),
      );
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    Navigator.pop(context);
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
    }
  }

  Future<void> _systemShare(BuildContext context) async {
    Navigator.pop(context);
    await Share.share(caption, subject: subject);
  }

  Future<void> _fallbackShare(BuildContext context) async {
    await Share.share(caption, subject: subject);
  }
}

// ─── Private widgets ──────────────────────────────────────

class _SocialTarget extends StatelessWidget {
  const _SocialTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
