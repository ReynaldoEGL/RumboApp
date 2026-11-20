import 'dart:developer' as developer;

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
        throw const FormatException('La estructura almacenada no es válida.');
      }

      final trips = <Trip>[];

      for (final entry in rawData.entries) {
        final id = entry.key.toString();
        final record = entry.value;

        if (record is! Map) {
          continue;
        }

        try {
          final trip = Trip.fromMap(id, Map<Object?, Object?>.from(record));

          trips.add(trip);
        } catch (error, stackTrace) {
          developer.log(
            'Se omitió un registro de viaje con datos no válidos.',
            name: 'rumbo.trips',
            error: error,
            stackTrace: stackTrace,
          );
        }
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
    final data = trip.toMap();

    final reference = _tripsReference(uid).push();
    final id = reference.key;

    if (id == null) {
      throw StateError(
        'No fue posible generar un identificador para el viaje.',
      );
    }

    await reference.set(data);

    return id;
  }

  Future<void> updateTrip(String uid, Trip trip) async {
    final id = trip.id.trim();

    if (id.isEmpty) {
      throw ArgumentError('No se puede actualizar un viaje sin identificador.');
    }

    final data = trip.toMap();

    await _tripsReference(uid).child(id).set(data);
  }

  Future<void> deleteTrip(String uid, String tripId) async {
    final id = tripId.trim();

    if (id.isEmpty) {
      throw ArgumentError('El identificador del viaje no puede estar vacío.');
    }

    await _tripsReference(uid).child(id).remove();
  }
}
