import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? ukPhone,
    String? companyName,
    String? registrationNumber,
    String? companyName,
    String? registrationNumber,
    String? companyType,
    String? countryCode,
    String? currencyCode,
  }) async {
    try {
      final response = await _dio.post('register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'uk_phone': ukPhone,
        'company_name': companyName,
        'registration_number': registrationNumber,
        'company_type': companyType,
        'country_code': countryCode,
        'currency_code': currencyCode,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('logout');
    } catch (e) {
      // Even if logout fails on server, we might want to clear local state
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data != null) {
      // Show full error details for debugging
      if (data is Map) {
        if (data['error'] != null) {
          return data['error'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      // Return entire response as string for debugging
      return data.toString();
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient.dio);
});
