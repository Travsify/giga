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
      return response.data['data'];
    } catch (e) {
      debugPrint('GetCategories Error: $e');
      throw 'Failed to load bill categories';
    }
  }

  static Future<Map<String, dynamic>> validateCustomer(String itemCode, String code, String customer) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      debugPrint('Validating Bill: itemCode=$itemCode, code=$code, customer=$customer');
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
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Validation failed';
      }
      throw 'Network error during validation';
    }
  }

  static Future<Map<String, dynamic>> payBill({
    required double amount,
    required String type,
    required String customer,
    String country = 'NG',
    String? billerName,
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
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint('PayBill Error: ${e.response?.data}');
      if (e.response != null) {
        throw e.response!.data['error'] ?? 'Payment failed';
      }
      throw 'Network error during payment';
    }
  }
}
