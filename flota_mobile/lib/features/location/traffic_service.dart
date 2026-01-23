import 'package:flutter/material.dart';

enum TrafficStatus {
  clear,
  moderate,
  heavy,
  severe
}

class TrafficService {
  static Future<Map<String, dynamic>> getTFLStatus() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock Data
    return {
      'status': TrafficStatus.moderate,
      'description': 'Moderate congestion on A40 Westway due to roadworks.',
      'tube_status': 'Circle Line: Minor Delays',
      'color': Colors.orange,
    };
  }
}
