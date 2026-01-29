import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class Locker {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final int totalCompartments;
  final int availableCompartments;

  Locker({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.totalCompartments,
    required this.availableCompartments,
  });

  factory Locker.fromJson(Map<String, dynamic> json) {
    return Locker(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      status: json['status'],
      totalCompartments: json['total_compartments'],
      availableCompartments: json['available_compartments'],
    );
  }
}

class LockerRepository {
  final ApiClient _api;
  LockerRepository(this._api);

  Future<List<Locker>> getLockers({String country = 'GB'}) async {
    final response = await _api.dio.get('/lockers', queryParameters: {'country': country});
    final List<dynamic> data = response.data;
    return data.map((json) => Locker.fromJson(json)).toList();
  }
}

final lockerRepositoryProvider = Provider((ref) => LockerRepository(ref.read(apiClientProvider)));

final lockersProvider = FutureProvider<List<Locker>>((ref) async {
  final country = ref.watch(authProvider).countryCode ?? 'GB'; // 'GB', 'NG', etc.
  return ref.read(lockerRepositoryProvider).getLockers(country: country);
});
