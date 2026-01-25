import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class BusinessRepository {
  final Dio _dio;

  BusinessRepository(this._dio);

  Future<Map<String, dynamic>> enrollBusiness(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/business/enroll', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBusinessProfile() async {
    try {
      final response = await _dio.get('/business/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> bulkBook(List<Map<String, dynamic>> batch) async {
    try {
      final response = await _dio.post('/business/bulk-book', data: {'batch': batch});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTeam() async {
    try {
      final response = await _dio.get('/business/team');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBilling() async {
    try {
      final response = await _dio.get('/business/billing');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['errors'] != null) {
          return data['errors'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BusinessRepository(apiClient.dio);
});
