import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';
import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

void main() {
  group('Trip model', () {
    final departure = DateTime(2026, 12, 10);
    final returnDate = DateTime(2026, 12, 13);

    Trip createTrip() {
      final vehicle = Vehicle(
        id: 'vehicle-1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2022,
        vehicleType: 'car',
        fuelType: 'gasoline',
        fuelConsumptionKmPerLiter: 15,
        electricConsumptionKwhPer100Km: null,
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        plateEnding: '123-E',
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      return Trip(
        id: 'trip-1',
        title: 'Viaje a Querétaro',
        origin: 'Celaya',
        destination: 'Querétaro',
        departureDate: departure,
        returnDate: returnDate,
        vehicleId: vehicle.id,
        vehicleSnapshot: TripVehicleSnapshot.fromVehicle(vehicle),
        distanceKm: 150,
        energyUnitPrice: 25,
        currencyCode: 'MXN',
        status: TripStatus.planned,
        notes: 'Salida temprano',
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );
    }

    test('serializa y recupera un viaje completo', () {
      final trip = createTrip();

      final restored = Trip.fromMap(
        trip.id,
        Map<Object?, Object?>.from(trip.toMap()),
      );

      expect(restored.id, trip.id);
      expect(restored.title, trip.title);
      expect(restored.origin, trip.origin);
      expect(restored.destination, trip.destination);
      expect(restored.departureDate, departure);
      expect(restored.returnDate, returnDate);
      expect(restored.vehicleId, 'vehicle-1');
      expect(restored.vehicleSnapshot?.displayName, 'Toyota Corolla (2022)');
      expect(restored.distanceKm, 150);
      expect(restored.energyUnitPrice, 25);
      expect(restored.currencyCode, 'MXN');
      expect(restored.status, TripStatus.planned);
      expect(restored.notes, 'Salida temprano');
    });

    test('conserva el cálculo energético del vehículo asociado', () {
      final trip = createTrip();

      final estimate = trip.energyEstimate;

      expect(estimate, isNotNull);
      expect(estimate!.quantity, 10);
      expect(estimate.cost, 250);
    });

    test('permite un viaje sin vehículo', () {
      final trip = Trip(
        id: 'trip-2',
        title: 'Viaje sin vehículo',
        origin: 'Celaya',
        destination: 'León',
        departureDate: departure,
        status: TripStatus.planned,
        currencyCode: 'MXN',
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final restored = Trip.fromMap(
        trip.id,
        Map<Object?, Object?>.from(trip.toMap()),
      );

      expect(restored.vehicleId, isNull);
      expect(restored.vehicleSnapshot, isNull);
      expect(restored.energyEstimate, isNull);
      expect(restored.returnDate, isNull);
    });

    test('no guarda notas vacías', () {
      final trip = Trip(
        id: 'trip-3',
        title: 'Viaje',
        origin: 'Celaya',
        destination: 'Querétaro',
        departureDate: departure,
        status: TripStatus.planned,
        currencyCode: 'MXN',
        notes: '   ',
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      expect(trip.toMap().containsKey('notes'), isFalse);
    });

    test('conserva el estado del viaje', () {
      final trip = createTrip();

      final map = trip.toMap();
      map['status'] = 'completed';

      final restored = Trip.fromMap(trip.id, Map<Object?, Object?>.from(map));

      expect(restored.status, TripStatus.completed);
      expect(restored.status.label, 'Completado');
    });

    test('usa MXN cuando el código de moneda almacenado no es válido', () {
      final trip = createTrip();

      final map = trip.toMap();
      map['currencyCode'] = 'INVALID';

      final restored = Trip.fromMap(trip.id, Map<Object?, Object?>.from(map));

      expect(restored.currencyCode, 'MXN');
    });

    test('detecta un estado desconocido como planeado', () {
      final trip = createTrip();

      final map = trip.toMap();
      map['status'] = 'unknown';

      final restored = Trip.fromMap(trip.id, Map<Object?, Object?>.from(map));

      expect(restored.status, TripStatus.planned);
    });

    test('rechaza un nombre de viaje vacío en los datos almacenados', () {
      expect(
        () => Trip.fromMap('trip-invalid', {
          'title': '',
          'origin': 'Celaya',
          'destination': 'Querétaro',
          'departureDate': departure.millisecondsSinceEpoch,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
