import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';

void main() {
  group('RoadRoute', () {
    final origin = RouteLocation(
      hereId: 'here-origin',
      title: 'Celaya',
      addressLabel: 'Celaya, Guanajuato, México',
      coordinate: const RouteCoordinate(
        latitude: 20.5235,
        longitude: -100.8157,
      ),
      resultType: 'locality',
    );

    final destination = RouteLocation(
      hereId: 'here-destination',
      title: 'Querétaro',
      addressLabel: 'Santiago de Querétaro, Querétaro, México',
      coordinate: const RouteCoordinate(
        latitude: 20.5888,
        longitude: -100.3899,
      ),
      resultType: 'locality',
    );

    RouteToll createToll() {
      return const RouteToll(
        countryCode: 'MEX',
        tollSystem: 'Autopista de prueba',
        fares: [
          RouteTollFare(
            id: 'fare-cash',
            name: 'Tarifa general',
            priceType: 'value',
            amount: 100,
            currencyCode: 'MXN',
            convertedAmount: null,
            convertedCurrencyCode: null,
            reason: 'toll',
            paymentMethods: ['cash'],
          ),
          RouteTollFare(
            id: 'fare-card',
            name: 'Tarifa con tarjeta',
            priceType: 'value',
            amount: 95,
            currencyCode: 'MXN',
            convertedAmount: null,
            convertedCurrencyCode: null,
            reason: 'toll',
            paymentMethods: ['bankCard'],
          ),
        ],
      );
    }

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
            distanceMeters: 50000,
            durationSeconds: 2400,
            geometry: const [
              RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
              RouteCoordinate(latitude: 20.55, longitude: -100.7),
            ],
            tolls: [createToll()],
          ),
          RouteSection(
            id: 'section-2',
            type: 'vehicle',
            transportMode: 'car',
            distanceMeters: 30000,
            durationSeconds: 1800,
            geometry: const [
              RouteCoordinate(latitude: 20.55, longitude: -100.7),
              RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
            ],
            tolls: const [],
          ),
        ],
      );
    }

    test('calcula distancia y duración de todos los tramos', () {
      final route = createRoute();

      expect(route.distanceMeters, 80000);
      expect(route.distanceKilometers, 80);
      expect(route.durationSeconds, 4200);
    });

    test('combina la geometría sin duplicar los puntos de unión', () {
      final route = createRoute();

      expect(route.geometry, hasLength(3));
      expect(route.geometry.first.latitude, 20.5235);
      expect(route.geometry.last.longitude, -100.3899);
    });

    test('conserva los peajes de los diferentes tramos', () {
      final route = createRoute();

      expect(route.tolls, hasLength(1));
      expect(route.tolls.first.countryCode, 'MEX');
      expect(route.tolls.first.fares, hasLength(2));
      expect(route.tolls.first.fares.first.amount, 100);
      expect(route.tolls.first.fares.last.paymentMethods, ['bankCard']);
    });

    test('serializa y recupera una ruta completa', () {
      final route = createRoute();

      final restored = RoadRoute.fromMap(
        Map<Object?, Object?>.from(route.toMap()),
      );

      expect(restored.id, route.id);
      expect(restored.origin.title, 'Celaya');
      expect(restored.destination.title, 'Querétaro');
      expect(restored.sections, hasLength(2));
      expect(restored.distanceKilometers, 80);
      expect(restored.durationSeconds, 4200);
      expect(restored.tollDataIncluded, isTrue);
      expect(restored.tolls.first.fares, hasLength(2));
    });

    test('rechaza una ruta sin secciones', () {
      expect(
        () => RoadRoute(
          id: 'route-invalid',
          origin: origin,
          destination: destination,
          sections: const [],
          tollDataIncluded: false,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
