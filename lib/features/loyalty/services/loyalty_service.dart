import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  Future<LoyaltyMe> getMe() async {
    try {
      final res = await ApiClient.instance.get('/loyalty/me');
      return LoyaltyMe.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to load loyalty';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }

  Future<int> redeem(int points) async {
    try {
      final res = await ApiClient.instance.post(
        '/loyalty/redeem',
        data: <String, dynamic>{'points': points},
      );
      final data = res.data as Map<String, dynamic>;
      return (data['freeMonths'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          'Failed to redeem';
      throw ApiException(e.response?.statusCode ?? 500, msg);
    }
  }
}

