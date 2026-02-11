import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.open-meteo.com/v1/';

  /// Get the user's current position, falling back to a default if unavailable.
  static Future<Position?> _getUserPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Low accuracy is fine for weather
      );
    } catch (e) {
      return null;
    }
  }

  /// Resolve a city/locality name from coordinates.
  static Future<String> _getCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? 
               placemarks.first.administrativeArea ?? 
               'Your Area';
      }
    } catch (_) {}
    return 'Your Area';
  }

  static Future<Map<String, dynamic>> getCurrentWeather() async {
    double lat = 6.5244; // Default: Lagos
    double lng = 3.3792;
    String locationName = 'Lagos';

    try {
      // 1. Try to get user's actual location
      final position = await _getUserPosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
        locationName = await _getCityName(lat, lng);
      }

      // 2. Fetch weather for the resolved coordinates
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current_weather': true,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['current_weather'];
        final temp = data['temperature'];
        final conditionCode = data['weathercode'];

        return {
          'temp': '${temp.round()}°C',
          'condition': _getConditionString(conditionCode),
          'icon': _getIcon(conditionCode),
          'location': locationName,
        };
      }
      throw 'Failed to fetch weather';
    } catch (e) {
      return {
        'temp': '--°C',
        'condition': 'Unavailable',
        'icon': Icons.cloud_off,
        'location': locationName,
      };
    }
  }

  static String _getConditionString(int code) {
    if (code == 0) return 'Clear Sky';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 56 && code <= 57) return 'Freezing Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 66 && code <= 67) return 'Freezing Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  static IconData _getIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_queue_rounded;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 55) return Icons.water_drop_outlined;
    if (code >= 61 && code <= 65) return Icons.grain_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.shower;
    if (code >= 95) return Icons.flash_on_rounded;
    return Icons.cloud_rounded;
  }
}
