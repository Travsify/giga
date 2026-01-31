import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data, {String? imagePath}) async {
    try {
      dynamic requestData;
      
      if (imagePath != null) {
        requestData = FormData.fromMap({
          ...data,
          'profile_image': await MultipartFile.fromFile(imagePath),
          '_method': 'PATCH', // Helper for Laravel multipart PATCH
        });
      } else {
        requestData = data;
      }

      // If we have an image, we use POST with _method override for Laravel compatibility
      final response = await (imagePath != null 
          ? _dio.post('/profile', data: requestData)
          : _dio.patch('/profile', data: requestData));
          
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLoyaltyInfo() async {
    try {
      final response = await _dio.get('/loyalty');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitReferralCode(String code) async {
    try {
      final response = await _dio.post('/referral/submit', data: {'code': code});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscription/status');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> subscribe({bool useWallet = false}) async {
    try {
      final response = await _dio.post('/subscription/subscribe', data: {
        'use_wallet': useWallet,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await _dio.post('/subscription/cancel');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data != null && data is Map) {
      return data['error'] ?? data['message'] ?? 'An unexpected error occurred';
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient.dio);
});
