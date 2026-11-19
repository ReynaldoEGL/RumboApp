import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';

final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(firebaseDatabaseProvider));
});

final vehiclesProvider = StreamProvider.family<List<Vehicle>, String>((
  ref,
  uid,
) {
  return ref.watch(vehicleRepositoryProvider).watchVehicles(uid);
});

final vehicleControllerProvider =
    AsyncNotifierProvider<VehicleController, void>(VehicleController.new);

class VehicleController extends AsyncNotifier<void> {
  VehicleRepository get _repository {
    return ref.read(vehicleRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  String _getAuthenticatedUid() {
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (user == null) {
      throw StateError('Debes iniciar sesión para administrar tus vehículos.');
    }

    final bool usesPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (usesPasswordProvider && !user.emailVerified) {
      throw StateError('Debes verificar tu correo antes de continuar.');
    }

    return user.uid;
  }

  Future<T> _execute<T>(Future<T> Function(String uid) operation) async {
    state = const AsyncLoading<void>();

    try {
      final uid = _getAuthenticatedUid();

      final result = await operation(uid);

      state = const AsyncData<void>(null);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);

      rethrow;
    }
  }

  Future<String> addVehicle(Vehicle vehicle) {
    return _execute((uid) => _repository.addVehicle(uid, vehicle));
  }

  Future<void> updateVehicle(Vehicle vehicle) {
    return _execute((uid) => _repository.updateVehicle(uid, vehicle));
  }

  Future<void> deleteVehicle(String vehicleId) {
    return _execute((uid) => _repository.deleteVehicle(uid, vehicleId));
  }
}
