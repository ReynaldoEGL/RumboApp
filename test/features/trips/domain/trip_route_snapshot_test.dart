import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';

void main() {
  group('Trip route snapshot', () {
    const origin = RouteLocation(
      hereId: 'here-origin',
      title: 'Celaya',
      addressLabel: 'Celaya, Guanajuato, México',
      coordinate: RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
    );

    const destination = RouteLocation(
      hereId: 'here-destination',
      title: 'Querétaro',
      addressLabel: 'Santiago de Querétaro, Querétaro, México',
      coordinate: RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
    );

    RoadRoute createRoute() {
      return RoadRoute(
        id: 'here-route-1',
        origin: origin,
        destination: destination,
        tollDataIncluded: true,
        sections: [
          RouteSection(
            id: 'section-1',
            type: 'vehicle',
            transportMode: 'car',
            distanceMeters: 80000,
            durationSeconds: 4200,
            geometry: const [
              RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
              RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
            ],
            tolls: const [
              RouteToll(
                countryCode: 'MEX',
                tollSystem: 'Autopista de prueba',
                fares: [
                  RouteTollFare(
                    id: 'fare-1',
                    name: 'Tarifa general',
                    priceType: 'value',
                    amount: 100,
                    currencyCode: 'MXN',
                    convertedAmount: null,
                    convertedCurrencyCode: null,
                    reason: 'toll',
                    paymentMethods: ['cash'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    Trip createTrip({RoadRoute? routeSnapshot}) {
      return Trip(
        id: 'trip-1',
        title: 'Viaje a Querétaro',
        origin: routeSnapshot?.origin.addressLabel ?? origin.addressLabel,
        destination:
            routeSnapshot?.destination.addressLabel ?? destination.addressLabel,
        departureDate: DateTime(2026, 12, 10),
        status: TripStatus.planned,
        currencyCode: 'MXN',
        distanceKm: routeSnapshot?.distanceKilometers,
        routeSnapshot: routeSnapshot,
        createdAt: 1000,
        updatedAt: 1000,
      );
    }

    test('guarda el recorrido completo dentro del viaje', () {
      final route = createRoute();
      final trip = createTrip(routeSnapshot: route);

      final data = trip.toMap();

      expect(data['schemaVersion'], 1);
      expect(data['distanceKm'], 80);
      expect(data['routeSnapshot'], isA<Map>());
    });

    test('restaura geometría, tramos y peajes', () {
      final route = createRoute();
      final trip = createTrip(routeSnapshot: route);

      final restored = Trip.fromMap(
        trip.id,
        Map<Object?, Object?>.from(trip.toMap()),
      );

      expect(restored.routeSnapshot, isNotNull);
      expect(restored.routeSnapshot!.id, 'here-route-1');
      expect(restored.routeSnapshot!.distanceKilometers, 80);
      expect(restored.routeSnapshot!.durationSeconds, 4200);
      expect(restored.routeSnapshot!.geometry, hasLength(2));
      expect(restored.routeSnapshot!.tolls, hasLength(1));
      expect(restored.routeSnapshot!.tolls.first.fares.first.amount, 100);
      expect(restored.distanceKm, 80);
    });

    test('permite leer un viaje anterior sin ruta asociada', () {
      final data = createTrip().toMap()..remove('routeSnapshot');

      final restored = Trip.fromMap(
        'trip-legacy',
        Map<Object?, Object?>.from(data),
      );

      expect(restored.routeSnapshot, isNull);
      expect(restored.title, 'Viaje a Querétaro');
      expect(restored.origin, origin.addressLabel);
      expect(restored.destination, destination.addressLabel);
    });

    test('rechaza una distancia diferente a la ruta conservada', () {
      final route = createRoute();

      final trip = Trip(
        id: 'trip-1',
        title: 'Viaje a Querétaro',
        origin: route.origin.addressLabel,
        destination: route.destination.addressLabel,
        departureDate: DateTime(2026, 12, 10),
        status: TripStatus.planned,
        currencyCode: 'MXN',
        distanceKm: 95,
        routeSnapshot: route,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });

    test('rechaza un origen distinto al recorrido conservado', () {
      final route = createRoute();

      final trip = Trip(
        id: 'trip-1',
        title: 'Viaje a Querétaro',
        origin: 'León, Guanajuato, México',
        destination: route.destination.addressLabel,
        departureDate: DateTime(2026, 12, 10),
        status: TripStatus.planned,
        currencyCode: 'MXN',
        distanceKm: route.distanceKilometers,
        routeSnapshot: route,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(() => trip.toMap(), throwsA(isA<FormatException>()));
    });
  });
}
