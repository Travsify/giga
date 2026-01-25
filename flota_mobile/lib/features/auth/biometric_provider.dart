import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isBiometricAvailable();
});
