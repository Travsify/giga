import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String login, String password) async {
    try {
      final response = await _dio.post('login', data: {
        'login': login,
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

    String? companyType,
    String? countryCode,
    String? currencyCode,
  }) async {
    try {
      // Build data map - only include optional fields if they have values
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };
      
      // Only add optional fields if they're not null and not empty
      if (ukPhone != null && ukPhone.isNotEmpty) data['uk_phone'] = ukPhone;
      if (companyName != null && companyName.isNotEmpty) data['company_name'] = companyName;
      if (registrationNumber != null && registrationNumber.isNotEmpty) data['registration_number'] = registrationNumber;
      if (companyType != null && companyType.isNotEmpty) data['company_type'] = companyType;
      if (countryCode != null && countryCode.isNotEmpty) data['country_code'] = countryCode;
      if (currencyCode != null && currencyCode.isNotEmpty) data['currency_code'] = currencyCode;
      
      final response = await _dio.post('register', data: data);
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
        // Handle validation errors (Laravel returns 'errors' object)
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          return errors.values.first.toString();
        }
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
