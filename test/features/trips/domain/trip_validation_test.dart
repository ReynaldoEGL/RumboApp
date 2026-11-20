import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';

void main() {
  group('Trip validation', () {
    Trip createTrip({
      String title = 'Viaje de prueba',
      String origin = 'Celaya, Guanajuato',
      String destination = 'Querétaro, Querétaro',
      String currencyCode = 'MXN',
      DateTime? returnDate,
      double? distanceKm,
      double? energyUnitPrice,
    }) {
      return Trip(
        id: 'trip-test',
        title: title,
        origin: origin,
        destination: destination,
        departureDate: DateTime(2026, 12, 10),
        returnDate: returnDate,
        distanceKm: distanceKm,
        energyUnitPrice: energyUnitPrice,
        currencyCode: currencyCode,
        status: TripStatus.planned,
        createdAt: 1000,
        updatedAt: 1000,
      );
    }

    test('rechaza un nombre vacío', () {
      final trip = createTrip(title: '   ');

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza un origen vacío', () {
      final trip = createTrip(origin: '');

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza un destino vacío', () {
      final trip = createTrip(destination: '  ');

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza un código de moneda inválido', () {
      final trip = createTrip(currencyCode: 'US');

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza una fecha de regreso anterior a la salida', () {
      final trip = createTrip(returnDate: DateTime(2026, 12, 9));

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza una distancia inválida', () {
      final trip = createTrip(distanceKm: double.nan);

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza un precio energético igual a cero', () {
      final trip = createTrip(energyUnitPrice: 0);

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('permite omitir los datos que son opcionales', () {
      final trip = createTrip();

      final data = trip.toMap();

      expect(data['title'], 'Viaje de prueba');
      expect(data['origin'], 'Celaya, Guanajuato');
      expect(data['destination'], 'Querétaro, Querétaro');
      expect(data.containsKey('vehicleId'), isFalse);
      expect(data.containsKey('vehicleSnapshot'), isFalse);
      expect(data.containsKey('distanceKm'), isFalse);
      expect(data.containsKey('energyUnitPrice'), isFalse);
      expect(data.containsKey('returnDate'), isFalse);
      expect(data.containsKey('notes'), isFalse);
    });
  });
}
