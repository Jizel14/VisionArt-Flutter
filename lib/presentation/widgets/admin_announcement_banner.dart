import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/app_config.dart';

/// Fetches the active admin announcement from the backend and shows it
/// as a dismissible gradient banner. Subscribes to Socket.IO `/announcements`
/// for instant updates when Annonces change in the backoffice.
///
/// Flutter only supports the **WebSocket** transport for this client; if the
/// TCP/WebSocket handshake is refused (firewall, wrong `HOST` bind, VPN), we
/// still poll [GET /announcements/active] periodically while disconnected.
class AdminAnnouncementBanner extends StatefulWidget {
  const AdminAnnouncementBanner({super.key});

  @override
  State<AdminAnnouncementBanner> createState() =>
      _AdminAnnouncementBannerState();
}

class _AdminAnnouncementBannerState extends State<AdminAnnouncementBanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _message;
  bool _dismissed = false;
  late AnimationController _controller;
  late Animation<double> _slide;
  io.Socket? _socket;
  Timer? _httpFallbackWhileDisconnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _load();
    _connectSocket();
    _httpFallbackWhileDisconnected =
        Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (_socket?.disconnected ?? true) _load();
    });
  }

  @override
  void dispose() {
    _httpFallbackWhileDisconnected?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _socket?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _connectSocket();
    }
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/announcements/active');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'AdminAnnouncementBanner: GET $uri → ${res.statusCode} ${res.body}',
          );
        }
        return;
      }
      if (res.body == 'null' || res.body.isEmpty) {
        if (mounted) {
          setState(() => _message = null);
          await _controller.reverse();
        }
        return;
      }
      final data = json.decode(res.body);
      if (data is! Map) return;
      final rawMsg = data['message'];
      final text = rawMsg == null
          ? null
          : rawMsg is String
              ? (rawMsg.isEmpty ? null : rawMsg)
              : rawMsg.toString().isEmpty
                  ? null
                  : rawMsg.toString();
      if (mounted) {
        setState(() {
          _message = text;
          _dismissed = false;
        });
        if (text != null) {
          await _controller.forward(from: 0);
        } else {
          await _controller.reverse();
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AdminAnnouncementBanner: load failed: $e\n$st');
      }
    }
  }

  void _applySocketPayload(dynamic data) {
    if (!mounted) return;
    if (data is! Map) return;
    final raw = data['message'];
    final String? msg = raw == null
        ? null
        : raw is String
            ? (raw.isEmpty ? null : raw)
            : raw.toString().isEmpty
                ? null
                : raw.toString();
    setState(() {
      _dismissed = false;
      _message = msg;
    });
    if (msg != null) {
      _controller.forward(from: 0);
    } else {
      _controller.reverse();
    }
  }

  void _connectSocket() {
    _socket?.dispose();
    final url = '${AppConfig.apiBaseUrl}/announcements';
    _socket = io.io(
      url,
      io.OptionBuilder()
          // dart:io builds only implement WebSocket; polling is unsupported.
          .setTransports(['websocket'])
          .setTimeout(60000)
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(15000)
          .build(),
    );
    _socket!.on('announcement_update', _applySocketPayload);
    _socket!.onConnect((_) {
      if (kDebugMode) {
        debugPrint('AdminAnnouncementBanner: socket connected');
      }
    });
    _socket!.onConnectError((e) {
      if (kDebugMode) {
        debugPrint(
          'AdminAnnouncementBanner: WebSocket error: $e\n'
          'Hint: "Connection refused" targets ${AppConfig.apiBaseUrl} (server port '
          '3000). The port in the message is usually the phone’s ephemeral port, '
          'not the API port. Bind Nest with HOST=0.0.0.0 and open the same URL in '
          'the phone browser. HTTP banner refresh still runs every 45s while '
          'disconnected.',
        );
      }
      _load();
    });
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
