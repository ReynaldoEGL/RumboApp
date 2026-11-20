import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';
import 'package:rumboapp/features/road_routes/domain/saved_road_route.dart';

void main() {
  group('SavedRoadRoute', () {
    final origin = RouteLocation(
      hereId: 'here-origin',
      title: 'Celaya',
      addressLabel: 'Celaya, Guanajuato, México',
      coordinate: const RouteCoordinate(
        latitude: 20.5235,
        longitude: -100.8157,
      ),
    );

    final destination = RouteLocation(
      hereId: 'here-destination',
      title: 'Querétaro',
      addressLabel: 'Santiago de Querétaro, Querétaro, México',
      coordinate: const RouteCoordinate(
        latitude: 20.5888,
        longitude: -100.3899,
      ),
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

    test('genera el nombre de la ruta guardada', () {
      final savedRoute = SavedRoadRoute(
        id: 'firebase-route-1',
        route: createRoute(),
        savedAt: 1795000000000,
      );

      expect(savedRoute.displayName, 'Celaya → Querétaro');
    });

    test('serializa y restaura todos los datos', () {
      final savedRoute = SavedRoadRoute(
        id: 'firebase-route-1',
        route: createRoute(),
        savedAt: 1795000000000,
      );

      final restored = SavedRoadRoute.fromMap(
        savedRoute.id,
        Map<Object?, Object?>.from(savedRoute.toMap()),
      );

      expect(restored.id, 'firebase-route-1');
      expect(restored.savedAt, 1795000000000);
      expect(restored.route.id, 'here-route-1');
      expect(restored.route.origin.title, 'Celaya');
      expect(restored.route.destination.title, 'Querétaro');
      expect(restored.route.distanceKilometers, 80);
      expect(restored.route.durationSeconds, 4200);
      expect(restored.route.geometry, hasLength(2));
      expect(restored.route.tolls, hasLength(1));
      expect(restored.route.tolls.first.fares.first.amount, 100);
    });

    test('rechaza un identificador vacío', () {
      expect(
        () => SavedRoadRoute(
          id: '',
          route: createRoute(),
          savedAt: 1795000000000,
        ).toMap(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza una versión de esquema desconocida', () {
      expect(
        () => SavedRoadRoute.fromMap('firebase-route-1', {
          'schemaVersion': 2,
          'savedAt': 1795000000000,
          'route': createRoute().toMap(),
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza una fecha de guardado inválida', () {
      expect(
        () => SavedRoadRoute.fromMap('firebase-route-1', {
          'schemaVersion': 1,
          'savedAt': -1,
          'route': createRoute().toMap(),
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
