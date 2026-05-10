// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/marketplace_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

class MarketplaceNegotiationsScreen extends StatefulWidget {
  const MarketplaceNegotiationsScreen({super.key, required this.service});

  final MarketplaceService service;

  @override
  State<MarketplaceNegotiationsScreen> createState() =>
      _MarketplaceNegotiationsScreenState();
}

class _MarketplaceNegotiationsScreenState
    extends State<MarketplaceNegotiationsScreen> {
  List<Map<String, dynamic>> _allRows = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _rows = const <Map<String, dynamic>>[];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> rows) {
    if (_statusFilter == 'all') return rows;

    if (_statusFilter == 'closed') {
      return rows.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return status == 'closed' || status == 'denied';
      }).toList();
    }

    return rows.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == _statusFilter;
    }).toList();
  }

  int _countForFilter(String filter) {
    if (filter == 'all') return _allRows.length;

    if (filter == 'closed') {
      return _allRows.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return status == 'closed' || status == 'denied';
      }).length;
    }

    return _allRows.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == filter;
    }).length;
  }

  int _unreadForFilter(String filter) {
    final rows = filter == 'all'
        ? _allRows
        : _allRows.where((item) {
            final status = (item['status'] ?? '').toString().toLowerCase();
            if (filter == 'closed') {
              return status == 'closed' || status == 'denied';
            }
            return status == filter;
          }).toList();

    return rows.where(MarketplaceService.isNegotiationUnread).length;
  }

  String _chipLabel(String filter, String label) {
    final total = _countForFilter(filter);
    final unread = _unreadForFilter(filter);
    if (unread > 0) {
      return '$label ($total • $unread new)';
    }
    return '$label ($total)';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await MarketplaceService.ensureSeenLoaded();

      final result = await widget.service.getMyNegotiations(limit: 50);
      final data = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      await MarketplaceService.markNegotiationsBaseline(data);
      if (!mounted) return;
      setState(() {
        _allRows = data;
        _rows = _applyFilter(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _respond(String negotiationId, String action) async {
    final messageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action == 'accept' ? 'Accept request' : 'Deny request'),
          content: TextField(
            controller: messageController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await widget.service.respondNegotiation(
                    negotiationId: negotiationId,
                    action: action,
                    message: messageController.text.trim().isEmpty
                        ? null
                        : messageController.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        action == 'accept'
                            ? 'Negotiation accepted'
                            : 'Negotiation denied',
                      ),
                    ),
                  );
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to respond: $e')),
                  );
                }
              },
              child: Text(action == 'accept' ? 'Accept' : 'Deny'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _buyNegotiated(
    String listingId,
    String negotiationId,
    dynamic latestAmount,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buy at negotiated price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price: ${_money(latestAmount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ethGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await widget.service.buyListing(
                    listingId,
                    negotiationId: negotiationId,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase completed')),
                  );
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchase failed: $e')),
                  );
                }
              },
              child: const Text('Buy now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    await MarketplaceService.markAllNegotiationsSeen(_allRows);
    if (!mounted) return;
    setState(() {
      _rows = _applyFilter(_allRows);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked all as read')));
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Negotiations'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _allRows.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: _chipLabel('all', 'All'),
                          selected: _statusFilter == 'all',
                          onTap: () {
                            setState(() {
                              _statusFilter = 'all';
                              _rows = _applyFilter(_allRows);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _chipLabel('pending', 'Pending'),
                          selected: _statusFilter == 'pending',
                          onTap: () {
                            setState(() {
                              _statusFilter = 'pending';
                              _rows = _applyFilter(_allRows);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _chipLabel('accepted', 'Accepted'),
                          selected: _statusFilter == 'accepted',
                          onTap: () {
                            setState(() {
                              _statusFilter = 'accepted';
                              _rows = _applyFilter(_allRows);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _chipLabel('closed', 'Closed'),
                          selected: _statusFilter == 'closed',
                          onTap: () {
                            setState(() {
                              _statusFilter = 'closed';
                              _rows = _applyFilter(_allRows);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          'No negotiations in this filter',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._rows.map((item) {
                      final listing =
                          (item['listing'] as Map<String, dynamic>?) ??
                          <String, dynamic>{};
                      final artwork =
                          (listing['artwork'] as Map<String, dynamic>?) ??
                          <String, dynamic>{};

                      final status = (item['status'] ?? '')
                          .toString()
                          .toLowerCase();
                      final isRequester = item['isRequester'] == true;
                      final messagingOpen = item['messagingOpen'] == true;
                      final listingActive = listing['isActive'] == true;
                      final negotiationId = (item['id'] ?? '').toString();
                      final listingId = (item['listingId'] ?? '').toString();
                      final isUnread = MarketplaceService.isNegotiationUnread(
                        item,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.chainCyan.withValues(alpha: 0.08),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (artwork['title'] ?? 'Artwork').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${status.toUpperCase()} · Amount: ${_money(item['latestAmount'])}',
                            ),
                            if (isUnread) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'New activity',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (status == 'pending' && !isRequester)
                                  OutlinedButton(
                                    onPressed: () =>
                                        _respond(negotiationId, 'accept'),
                                    child: const Text('Accept'),
                                  ),
                                if (status == 'pending' && !isRequester)
                                  OutlinedButton(
                                    onPressed: () =>
                                        _respond(negotiationId, 'deny'),
                                    child: const Text('Deny'),
                                  ),
                                if (messagingOpen)
                                  FilledButton.tonal(
                                    onPressed: () async {
                                      await MarketplaceService.markNegotiationSeen(
                                        negotiationId,
                                        updatedAtIso: (item['updatedAt'] ?? '')
                                            .toString(),
                                      );
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MarketplaceNegotiationChatScreen(
                                                service: widget.service,
                                                negotiation: item,
                                              ),
                                        ),
                                      );
                                      await _load();
                                    },
                                    child: const Text('Open chat'),
                                  ),
                                if (messagingOpen &&
                                    isRequester &&
                                    listingActive)
                                  FilledButton(
                                    onPressed: () => _buyNegotiated(
                                      listingId,
                                      negotiationId,
                                      item['latestAmount'],
                                    ),
                                    child: const Text('Buy at this price'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class MarketplaceNegotiationChatScreen extends StatefulWidget {
  const MarketplaceNegotiationChatScreen({
    super.key,
    required this.service,
    required this.negotiation,
  });

  final MarketplaceService service;
  final Map<String, dynamic> negotiation;

  @override
  State<MarketplaceNegotiationChatScreen> createState() =>
      _MarketplaceNegotiationChatScreenState();
}

class _MarketplaceNegotiationChatScreenState
    extends State<MarketplaceNegotiationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();

  List<Map<String, dynamic>> _messages = const <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(2);
  }

  String get _negotiationId => (widget.negotiation['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await widget.service.getNegotiationMessages(
        _negotiationId,
        limit: 100,
      );
      final rows = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _send() async {
    if (_isSending) return;

    final offerText = _offerController.text.trim();
    final offerAmount = offerText.isEmpty ? null : double.tryParse(offerText);
    final message = _messageController.text.trim();

    if (offerText.isNotEmpty && offerAmount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer amount is invalid')));
      return;
    }
    if (offerAmount == null && message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write message or offer amount')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.service.sendNegotiationMessage(
        negotiationId: _negotiationId,
        message: message.isEmpty ? null : message,
        offerAmount: offerAmount,
      );
      _messageController.clear();
      _offerController.clear();
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negotiation Chat'),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final sender =
                          (item['sender'] as Map<String, dynamic>?) ??
                          <String, dynamic>{};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.chainCyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (sender['name'] ?? 'User').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((item['message'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text((item['message'] ?? '').toString()),
                              ),
                            if (item['offerAmount'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Offer: ${_money(item['offerAmount'])}',
                                  style: const TextStyle(
                                    color: AppColors.ethGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Type message...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _offerController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'New offer amount (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
