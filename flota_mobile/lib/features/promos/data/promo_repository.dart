import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class PromoRepository {
  final Dio _dio;

  PromoRepository(this._dio);

  Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      final response = await _dio.get('/promos');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> validateCode(String code, double amount) async {
    try {
      final response = await _dio.post('/promos/validate', data: {
        'code': code,
        'order_amount': amount,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.toString();
  }
}

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PromoRepository(apiClient.dio);
});
