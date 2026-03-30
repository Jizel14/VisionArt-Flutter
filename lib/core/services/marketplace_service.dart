import '../api_client.dart';
import '../models/wallet_balance_model.dart';

class MarketplaceService {
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
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/wallet/withdraw',
      data: {
        'amount': amount,
        if (destinationAddress != null)
          'destinationAddress': destinationAddress,
        if (reference != null) 'reference': reference,
        if (txHash != null) 'txHash': txHash,
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
  }) async {
    final response = await ApiClient.instance.get(
      '/marketplace/my/listings',
      queryParameters: {'page': page, 'limit': limit},
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

  Future<Map<String, dynamic>> buyListing(
    String listingId, {
    String? txHash,
  }) async {
    final response = await ApiClient.instance.post(
      '/marketplace/listings/$listingId/buy',
      data: {if (txHash != null) 'txHash': txHash},
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

  Future<Map<String, dynamic>> getBlockchainProof() async {
    final response = await ApiClient.instance.get(
      '/marketplace/blockchain/proof',
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
