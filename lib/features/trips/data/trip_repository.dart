import 'package:firebase_database/firebase_database.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';

class TripRepository {
  TripRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _tripsReference(String uid) {
    return _database.ref('users/$uid/trips');
  }

  Stream<List<Trip>> watchTrips(String uid) {
    return _tripsReference(uid).onValue.map((event) {
      final rawData = event.snapshot.value;

      if (rawData == null) {
        return <Trip>[];
      }

      if (rawData is! Map) {
        throw const FormatException(
          'La estructura de viajes almacenada no es válida.',
        );
      }

      final trips = <Trip>[];

      for (final entry in rawData.entries) {
        final id = entry.key.toString();
        final record = entry.value;

        if (record is! Map) {
          continue;
        }

        trips.add(Trip.fromMap(id, Map<Object?, Object?>.from(record)));
      }

      trips.sort((a, b) {
        final dateComparison = a.departureDate.compareTo(b.departureDate);

        if (dateComparison != 0) {
          return dateComparison;
        }

        return b.updatedAt.compareTo(a.updatedAt);
      });

      return trips;
    });
  }

  Future<String> addTrip(String uid, Trip trip) async {
    final reference = _tripsReference(uid).push();
    final id = reference.key;

    if (id == null) {
      throw StateError(
        'No fue posible generar un identificador para el viaje.',
      );
    }

    await reference.set(trip.toMap());

    return id;
  }

  Future<void> updateTrip(String uid, Trip trip) async {
    if (trip.id.trim().isEmpty) {
      throw ArgumentError('No se puede actualizar un viaje sin identificador.');
    }

    await _tripsReference(uid).child(trip.id).set(trip.toMap());
  }

  Future<void> deleteTrip(String uid, String tripId) async {
    if (tripId.trim().isEmpty) {
      throw ArgumentError('El identificador del viaje no puede estar vacío.');
    }

    await _tripsReference(uid).child(tripId).remove();
  }
}
