import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

const String kApiBaseUrl = 'https://giga-ytn0.onrender.com/api';

class BillPaymentService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  static const _storage = FlutterSecureStorage();

  static Future<List<dynamic>> getCategories() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '/bills/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['data'] != null) {
        return response.data['data'];
      }
      return [];
    } on DioException catch (e) {
      debugPrint('GetCategories Error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to load bill categories';
    } catch (e) {
      debugPrint('GetCategories unexpected error: $e');
      throw 'An unexpected error occurred';
    }
  }

  static Future<List<dynamic>> getDataPlans(int networkId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '/bills/plans/$networkId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data['data'] != null) {
        return response.data['data'];
      }
      return [];
    } on DioException catch (e) {
      debugPrint('GetDataPlans Error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to load data plans';
    } catch (e) {
      debugPrint('GetDataPlans unexpected error: $e');
      throw 'An unexpected error occurred';
    }
  }

  static Future<Map<String, dynamic>> validateCustomer(String itemCode, String code, String customer) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.post(
        '/bills/validate',
        data: {
          'item_code': itemCode,
          'code': code,
          'customer': customer,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['data'];
    } on DioException catch (e) {
      debugPrint('Validation Error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Validation failed';
    } catch (e) {
      debugPrint('Validation unexpected error: $e');
      throw 'An unexpected error occurred during validation';
    }
  }

  static Future<Map<String, dynamic>> payBill({
    required double amount,
    required String type,
    required String customer,
    String country = 'NG',
    String? billerName,
    String? plan,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.post(
        '/bills/pay',
        data: {
          'amount': amount,
          'type': type,
          'customer': customer,
          'country': country,
          'biller_name': billerName,
          'plan': plan,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint('PayBill Error: ${e.response?.data}');
      throw e.response?.data['error'] ?? e.response?.data['message'] ?? 'Payment failed';
    } catch (e) {
      debugPrint('PayBill unexpected error: $e');
      throw 'An unexpected error occurred during payment';
    }
  }
}
