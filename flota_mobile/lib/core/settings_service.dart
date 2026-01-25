import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/domain/models/country_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Service to handle app-wide settings fetched from Admin Panel
class SettingsService {
  final ApiClient _apiClient;
  
  // Cache keys
  static const String _settingsKey = 'app_settings_cache';
  
  // In-memory cache
  Map<String, dynamic> _settings = {};

  SettingsService(this._apiClient);

  /// Initialize service: load cached settings then fetch fresh ones
  Future<void> init() async {
    await _loadFromCache();
    // Fetch fresh settings in background, don't await if we want faster startup
    // But for "force update" checks, we might want to await. 
    // Let's try to fetch with a short timeout.
    try {
      await fetchCountries();
      await fetchSettings();
    } catch (e) {
      print('Failed to fetch fresh settings: $e');
    }
  }

  /// Get specific setting with default value
  T get<T>(String key, T defaultValue) {
    if (!_settings.containsKey(key)) return defaultValue;
    
    final value = _settings[key];
    
    if (value is T) return value;
    
    // Handle type conversions if needed
    if (T == bool && value is int) return (value == 1) as T;
    if (T == bool && value is String) return (value == '1' || value == 'true') as T;
    if (T == int && value is String) return int.tryParse(value) as T ?? defaultValue;
    if (T == double && value is String) return double.tryParse(value) as T ?? defaultValue;
    
    return defaultValue;
  }

  /// Fetch settings from API
  Future<void> fetchSettings() async {
    try {
      final response = await _apiClient.dio.get('settings');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        _settings = data;
        await _saveToCache(data);
      }
    } catch (e) {
      print('Error fetching settings: $e');
      rethrow;
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr != null) {
      try {
        _settings = json.decode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        print('Error decoding cached settings: $e');
      }
    }
  }

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(data));
  }

  /// Check app version against min_version from settings
  Future<AppUpdateStatus> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await _apiClient.dio.get('settings/check-version/$currentVersion');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        if (data['maintenance_mode'] == true) {
          return AppUpdateStatus(
            state: UpdateState.maintenance,
            message: data['maintenance_message'],
          );
        }
        
        if (data['update_required'] == true) {
          return AppUpdateStatus(
            state: UpdateState.forceUpdate,
            message: 'A critical update is available. Please update to continue.',
          );
        }
        
        if (data['update_available'] == true) {
          return AppUpdateStatus(
            state: UpdateState.optionalUpdate,
            message: 'A new version is available.',
          );
        }
      }
    } catch (e) {
      print('Error checking version: $e');
    }
    
    return AppUpdateStatus(state: UpdateState.upToDate);
  }
  /// Get asset URL (handles relative paths from Admin Panel)
  String getAssetUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    
    // Construct full URL assuming storage path
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // Use the base URL from ApiClient but point to /storage/
    // ApiClient uses /api/, so we need to go up one level
    // Easier to just hardcode or reuse logic if we expose baseUrl in ApiClient
    const baseUrl = 'https://giga-ytn0.onrender.com';
    return '$baseUrl/storage/$cleanPath';
  }

  // Multi-Country Support
  List<Country> _supportedCountries = [];
  List<Country> get supportedCountries => _supportedCountries;
  
  Country? _currentCountry;
  Country? get currentCountry => _currentCountry;

  Future<void> fetchCountries() async {
    try {
      final response = await _apiClient.dio.get('countries');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        _supportedCountries = data.map((e) => Country.fromJson(e)).toList();
        
        // Set default if none selected
        if (_currentCountry == null && _supportedCountries.isNotEmpty) {
           _currentCountry = _supportedCountries.firstWhere(
             (c) => c.isDefault, 
             orElse: () => _supportedCountries.first
           );
        }
        
        // Try auto-detect location
        await detectConfiguredCountry();
      }
    } catch (e) {
      print('Error fetching countries: $e');
    }
  }

  /// Detect user country based on location
  Future<void> detectConfiguredCountry() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Don't request valid permission just for config if not critical, or request if appropriate
        // Here we just skip auto-detect if permission not already granted or easily grantable
        // permission = await Geolocator.requestPermission();
        return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        String? isoCode = placemarks.first.isoCountryCode;
        if (isoCode != null) {
          // Find matching supported country or fallback to Default (UK) logic
          // BUT: Req says "UK should be constant ... auto detect based on user location"
          // If user is in Nigeria, we select Nigeria.
          final detected = _supportedCountries.firstWhere(
            (c) => c.isoCode.toUpperCase() == isoCode.toUpperCase(),
            orElse: () => _supportedCountries.firstWhere(
              (c) => c.isDefault,
              orElse: () => _supportedCountries.first
            )
          );
          
          _currentCountry = detected;
        }
      }
    } catch (e) {
      print('Error auto-detecting country: $e');
    }
  }

  void setCountry(Country country) {
    _currentCountry = country;
    // Persist selection if needed
  }
}

enum UpdateState { upToDate, optionalUpdate, forceUpdate, maintenance }

class AppUpdateStatus {
  final UpdateState state;
  final String? message;

  AppUpdateStatus({this.state = UpdateState.upToDate, this.message});
}

// Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsService(apiClient);
});

// FutureProvider for initialization
final settingsInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(settingsServiceProvider);
  await service.init();
});
