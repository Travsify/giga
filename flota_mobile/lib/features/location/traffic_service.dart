import 'package:flutter/material.dart';

enum TrafficStatus {
  clear,
  moderate,
  heavy,
  severe
}

class TrafficService {
  static Future<Map<String, dynamic>> getTFLStatus() async {
    // Return empty/unavailable state as we don't have a real Traffic API connected yet
    return {
      'status': TrafficStatus.clear,
      'description': 'Traffic data unavailable',
      'tube_status': 'Status unavailable',
      'color': Colors.grey,
    };
  }
}
