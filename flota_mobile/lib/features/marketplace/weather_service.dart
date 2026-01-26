import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class WeatherService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.open-meteo.com/v1/';

  // London coordinates
  static const double lat = 51.5074;
  static const double lng = -0.1278;

  static Future<Map<String, dynamic>> getCurrentWeather({double? latitude, double? longitude}) async {
    final useLat = latitude ?? lat;
    final useLng = longitude ?? lng;
    
    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': useLat,
          'longitude': useLng,
          'current_weather': true,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['current_weather'];
        final temp = data['temperature'];
        final conditionCode = data['weathercode']; // WMO code

        return {
          'temp': '${temp.round()}°C',
          'condition': _getConditionString(conditionCode),
          'icon': _getIcon(conditionCode),
          'location': (latitude != null) ? 'Your Area' : 'London',
        };
      }
      throw 'Failed to fetch weather';
    } catch (e) {
      // Fallback
      return {
        'temp': '--°C',
        'condition': 'Unavailable',
        'icon': Icons.cloud_off,
        'location': 'Unknown',
      };
    }
  }

  static String _getConditionString(int code) {
    if (code == 0) return 'Clear Sky';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  static IconData _getIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_queue_rounded;
    if (code >= 61 && code <= 65) return Icons.grain_rounded;
    if (code >= 95) return Icons.flash_on_rounded;
    return Icons.cloud_rounded;
  }
}
