import 'package:firebase_database/firebase_database.dart';

import '../domain/vehicle.dart';

class VehicleRepository {
  final FirebaseDatabase _database;

  VehicleRepository(this._database);

  DatabaseReference _vehiclesReference(String uid) {
    return _database.ref('users/$uid/vehicles');
  }

  Stream<List<Vehicle>> watchVehicles(String uid) {
    return _vehiclesReference(uid).onValue.map((event) {
      final rawData = event.snapshot.value;

      if (rawData == null) {
        return <Vehicle>[];
      }

      if (rawData is! Map) {
        throw const FormatException(
          'La estructura de vehículos almacenada no es válida.',
        );
      }

      final vehicles = <Vehicle>[];

      for (final entry in rawData.entries) {
        final String id = entry.key.toString();
        final record = entry.value;

        if (record is Map) {
          final normalizedRecord = Map<Object?, Object?>.from(record);

          vehicles.add(Vehicle.fromMap(id, normalizedRecord));
        }
      }

      vehicles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return vehicles;
    });
  }

  Future<String> addVehicle(String uid, Vehicle vehicle) async {
    final reference = _vehiclesReference(uid).push();

    final String? vehicleId = reference.key;

    if (vehicleId == null) {
      throw StateError(
        'No fue posible generar un identificador para el vehículo.',
      );
    }

    await reference.set(vehicle.toMap());

    return vehicleId;
  }

  Future<void> updateVehicle(String uid, Vehicle vehicle) async {
    if (vehicle.id.isEmpty) {
      throw ArgumentError(
        'No se puede actualizar un vehículo sin identificador.',
      );
    }

    await _vehiclesReference(uid).child(vehicle.id).set(vehicle.toMap());
  }

  Future<void> deleteVehicle(String uid, String vehicleId) async {
    if (vehicleId.isEmpty) {
      throw ArgumentError(
        'El identificador del vehículo no puede estar vacío.',
      );
    }

    await _vehiclesReference(uid).child(vehicleId).remove();
  }
}
