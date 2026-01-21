import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out. Please check your internet.';
          break;
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          } else if (error.response?.statusCode == 401) {
            message = 'Session expired. Please login again.';
            // Trigger logout logic here if possible
          } else if (error.response?.statusCode == 404) {
             message = 'Resource not found.';
          } else if (error.response?.statusCode == 500) {
            message = 'Server error. Please try again later.';
          }
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection.';
          break;
        default:
          message = 'Network error occurred.';
      }
    } else if (error is String) {
      message = error;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
