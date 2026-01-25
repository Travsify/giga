import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

class DeliveryRepository {
  final Dio _dio;

  DeliveryRepository(this._dio);

  Future<DeliveryEstimationResponse> estimateFare(DeliveryEstimationRequest request) async {
    try {
      final response = await _dio.post('/deliveries/estimate', data: request.toJson());
      return DeliveryEstimationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDelivery(DeliveryRequest request) async {
    try {
      final response = await _dio.post('/deliveries', data: request.toJson());
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDeliveries({List<String>? statuses}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['status'] = statuses.join(',');
      }
      final response = await _dio.get('/deliveries', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeliveryRepository(apiClient.dio);
});
