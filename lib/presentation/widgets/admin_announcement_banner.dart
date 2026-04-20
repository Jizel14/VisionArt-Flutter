import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_config.dart';

/// Fetches the active admin announcement from the backend and shows it
/// as a dismissible gradient banner at the top of the screen.
class AdminAnnouncementBanner extends StatefulWidget {
  const AdminAnnouncementBanner({super.key});

  @override
  State<AdminAnnouncementBanner> createState() =>
      _AdminAnnouncementBannerState();
}

class _AdminAnnouncementBannerState extends State<AdminAnnouncementBanner>
    with SingleTickerProviderStateMixin {
  String? _message;
  bool _dismissed = false;
  late AnimationController _controller;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/announcements/active');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        final data = json.decode(res.body);
        if (data is Map && data['message'] != null) {
          if (mounted) {
            setState(() => _message = data['message'] as String);
            _controller.forward();
          }
        }
      }
    } catch (_) {}
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _message == null) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _slide,
      axisAlignment: -1,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.campaign_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white70, size: 18),
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
