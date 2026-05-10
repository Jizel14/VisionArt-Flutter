import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  // ── Fetch current subscription ────────────────────────────────────────────

  Future<SubscriptionModel> getMySubscription() async {
    try {
      final response =
          await ApiClient.instance.get('/subscriptions/me');
      return SubscriptionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load subscription';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }

  // ── Create Stripe checkout session ────────────────────────────────────────

  Future<({String sessionId, String checkoutUrl})>
      createCheckoutSession({String? promoCode}) async {
    try {
      final response = await ApiClient.instance.post(
        '/subscriptions/create-checkout-session',
        data: promoCode == null || promoCode.trim().isEmpty
            ? <String, dynamic>{}
            : <String, dynamic>{'promoCode': promoCode.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      return (
        sessionId: data['sessionId'] as String,
        checkoutUrl: data['checkoutUrl'] as String,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to create checkout session';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }

  Future<({bool valid, int discountPct, double basePrice, double finalPrice})>
      validatePromoCode(String promoCode) async {
    try {
      final response = await ApiClient.instance.post(
        '/subscriptions/validate-promo',
        data: <String, dynamic>{'promoCode': promoCode.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      return (
        valid: data['valid'] == true,
        discountPct: (data['discountPct'] as num?)?.toInt() ?? 0,
        basePrice: (data['basePrice'] as num?)?.toDouble() ?? 9.99,
        finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 9.99,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to validate promo code';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }

  // ── Cancel subscription ───────────────────────────────────────────────────

  Future<String> cancelSubscription() async {
    try {
      final response =
          await ApiClient.instance.post('/subscriptions/cancel');
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Subscription canceled';
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to cancel subscription';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }
}
