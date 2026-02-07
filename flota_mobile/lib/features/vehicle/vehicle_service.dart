import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/vehicle/vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VehicleService {
  final ApiClient _apiClient;

  VehicleService(this._apiClient);

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.dio.get('vehicles');
      final data = response.data['data'] as List;
      return data.map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<Vehicle> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _apiClient.dio.post('vehicles', data: vehicleData);
      return Vehicle.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to add vehicle: $e');
    }
  }

  Future<void> activateVehicle(int vehicleId) async {
    try {
      await _apiClient.dio.post('vehicles/$vehicleId/activate');
    } catch (e) {
      throw Exception('Failed to activate vehicle: $e');
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      await _apiClient.dio.delete('vehicles/$vehicleId');
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }
}

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return VehicleService(apiClient);
});

final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getVehicles();
});
