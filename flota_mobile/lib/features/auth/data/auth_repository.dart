import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
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
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      // Even if logout fails on server, we might want to clear local state
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
