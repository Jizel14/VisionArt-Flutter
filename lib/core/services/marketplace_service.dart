// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api_client.dart';
import '../models/wallet_balance_model.dart';

class MarketplaceService {
  static final Map<String, DateTime> _seenNegotiationAt = <String, DateTime>{};
  static const String _seenNegotiationsStorageKey =
      'marketplace_seen_negotiations_v1';
  static bool _seenLoaded = false;

  static Future<void> _loadSeenFromStorage() async {
    if (_seenLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_seenNegotiationsStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (key.trim().isEmpty) return;
          final seenAt = DateTime.tryParse('$value')?.toUtc();
          if (seenAt != null) {
            _seenNegotiationAt[key] = seenAt;
          }
        });
      } catch (_) {
        // Ignore malformed cache.
      }
    }

    _seenLoaded = true;
  }

  static Future<void> _persistSeenToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, String>{
      for (final entry in _seenNegotiationAt.entries)
        entry.key: entry.value.toUtc().toIso8601String(),
    };
    await prefs.setString(_seenNegotiationsStorageKey, jsonEncode(payload));
  }

  static Future<void> ensureSeenLoaded() async {
    await _loadSeenFromStorage();
  }

  static DateTime? getSeenNegotiationAt(String negotiationId) {
    return _seenNegotiationAt[negotiationId];
  }

  static Future<void> markNegotiationSeen(
    String negotiationId, {
    String? updatedAtIso,
  }) async {
    await _loadSeenFromStorage();

    if (negotiationId.trim().isEmpty) return;

    final parsed = updatedAtIso == null
        ? null
        : DateTime.tryParse(updatedAtIso)?.toUtc();

    _seenNegotiationAt[negotiationId] = parsed ?? DateTime.now().toUtc();
    await _persistSeenToStorage();
  }

  static Future<void> markNegotiationsBaseline(
    List<Map<String, dynamic>> rows,
  ) async {
    await _loadSeenFromStorage();

    var changed = false;
    for (final row in rows) {
      final negotiationId = (row['id'] ?? '').toString();
      if (negotiationId.isEmpty) continue;
      if (_seenNegotiationAt.containsKey(negotiationId)) continue;

      final updatedAtIso = (row['updatedAt'] ?? '').toString();
      final parsed = updatedAtIso.isEmpty
          ? null
          : DateTime.tryParse(updatedAtIso)?.toUtc();
      _seenNegotiationAt[negotiationId] = parsed ?? DateTime.now().toUtc();
      changed = true;
    }

    if (changed) {
      await _persistSeenToStorage();
    }
  }

  static Future<void> markAllNegotiationsSeen(
    List<Map<String, dynamic>> rows, {
    bool includeClosed = false,
  }) async {
    await _loadSeenFromStorage();

    var changed = false;
    for (final row in rows) {
      final negotiationId = (row['id'] ?? '').toString();
      if (negotiationId.isEmpty) continue;

      final status = (row['status'] ?? '').toString().toLowerCase();
      if (!includeClosed && (status == 'closed' || status == 'denied')) {
        continue;
      }

      final updatedAtIso = (row['updatedAt'] ?? '').toString();
      final parsed = updatedAtIso.isEmpty
          ? null
          : DateTime.tryParse(updatedAtIso)?.toUtc();
      final nextSeen = parsed ?? DateTime.now().toUtc();

      final current = _seenNegotiationAt[negotiationId];
      if (current != null && !nextSeen.isAfter(current)) {
        continue;
      }

      _seenNegotiationAt[negotiationId] = nextSeen;
      changed = true;
    }

    if (changed) {
      await _persistSeenToStorage();
    }
  }

  static bool isNegotiationUnread(Map<String, dynamic> row) {
    final negotiationId = (row['id'] ?? '').toString();
    if (negotiationId.isEmpty) return false;

    final status = (row['status'] ?? '').toString().toLowerCase();
    if (status == 'closed' || status == 'denied') return false;

    final updatedAtIso = (row['updatedAt'] ?? '').toString();
    final updatedAt = DateTime.tryParse(updatedAtIso)?.toUtc();
    if (updatedAt == null) return false;

    final seenAt = getSeenNegotiationAt(negotiationId);
    if (seenAt == null) return false;

    return updatedAt.isAfter(seenAt);
  }

  Future<Map<String, dynamic>> getMyWallet() async {
    final response = await ApiClient.instance.get('/marketplace/wallet/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> connectWallet(String walletAddress) async {
    final response = await ApiClient.instance.post(
      '/marketplace/wallet/connect',
      data: {'walletAddress': walletAddress},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> topup({
    required double amount,
    String? reference,
    String? txHash,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/wallet/topup',
      data: {
        'amount': amount,
        if (reference != null) 'reference': reference,
        if (txHash != null) 'txHash': txHash,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> withdraw({
    required double amount,
    String? destinationAddress,
    String? reference,
    String? txHash,
    String tokenType = 'POL',
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/wallet/withdraw',
      data: {
        'amount': amount,
        if (destinationAddress != null)
          'destinationAddress': destinationAddress,
        if (reference != null) 'reference': reference,
        if (txHash != null) 'txHash': txHash,
        'tokenType': tokenType,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getListings({
    int page = 1,
    int limit = 20,
    String status = 'active',
  }) async {
    final response = await ApiClient.instance.get(
      '/marketplace/listings',
      queryParameters: {'page': page, 'limit': limit, 'status': status},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getMyListings({
    int page = 1,
    int limit = 20,
    String role = 'seller',
  }) async {
    final response = await ApiClient.instance.get(
      '/marketplace/my/listings',
      queryParameters: {'page': page, 'limit': limit, 'role': role},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createListing({
    required String artworkId,
    required double price,
    String currency = 'USDC',
    bool negotiable = false,
    String? paymentToken,
    String? txHash,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/listings',
      data: {
        'artworkId': artworkId,
        'price': price,
        'currency': currency,
        'negotiable': negotiable,
        if (paymentToken != null) 'paymentToken': paymentToken,
        if (txHash != null) 'txHash': txHash,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateListing({
    required String listingId,
    double? price,
    bool? negotiable,
  }) async {
    final response = await ApiClient.instance.patch(
      '/marketplace/listings/$listingId',
      data: {
        if (price != null) 'price': price,
        if (negotiable != null) 'negotiable': negotiable,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> buyListing(
    String listingId, {
    String? negotiationId,
    String? txHash,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/listings/$listingId/buy',
      data: {
        if (negotiationId != null) 'negotiationId': negotiationId,
        if (txHash != null) 'txHash': txHash,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> requestNegotiation({
    required String listingId,
    required double amount,
    String? message,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/negotiations/request',
      data: {
        'listingId': listingId,
        'amount': amount,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> respondNegotiation({
    required String negotiationId,
    required String action,
    String? message,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/negotiations/$negotiationId/respond',
      data: {
        'action': action,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getMyNegotiations({
    int page = 1,
    int limit = 20,
    String status = 'all',
  }) async {
    final response = await ApiClient.instance.get(
      '/marketplace/negotiations',
      queryParameters: {'page': page, 'limit': limit, 'status': status},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getNegotiationMessages(
    String negotiationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiClient.instance.get(
      '/marketplace/negotiations/$negotiationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> sendNegotiationMessage({
    required String negotiationId,
    String? message,
    double? offerAmount,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/negotiations/$negotiationId/messages',
      data: {
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (offerAmount != null) 'offerAmount': offerAmount,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> cancelListing(String listingId) async {
    final response = await ApiClient.instance.post(
      '/marketplace/listings/$listingId/cancel',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<WalletBalanceModel> getWalletBalance(String address) async {
    final response = await ApiClient.instance.get(
      '/marketplace/wallet/$address/balance',
    );
    return WalletBalanceModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> getMarketplaceConfig() async {
    final response = await ApiClient.instance.get('/marketplace/config');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getSellerAnalytics() async {
    final response = await ApiClient.instance.get(
      '/marketplace/analytics/seller',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getBlockchainProof() async {
    final response = await ApiClient.instance.get(
      '/marketplace/blockchain/proof',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> mintArtworkNft({
    required String artworkId,
    String? recipientAddress,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/nfts/mint',
      data: {
        'artworkId': artworkId,
        if (recipientAddress != null && recipientAddress.trim().isNotEmpty)
          'recipientAddress': recipientAddress.trim(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> verifyTransaction(String txHash) async {
    final response = await ApiClient.instance.get(
      '/marketplace/transactions/$txHash/verify',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> reconcileTransaction(String txHash) async {
    final response = await ApiClient.instance.post(
      '/marketplace/transactions/reconcile',
      data: {'txHash': txHash},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
