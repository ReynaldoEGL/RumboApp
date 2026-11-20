import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/application/here_routing_service_provider.dart';
import 'package:rumboapp/features/road_routes/application/road_route_planner_provider.dart';
import 'package:rumboapp/features/road_routes/data/here_routing_service.dart';
import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';

void main() {
  group('RoadRoutePlannerController', () {
    late _FakeHereRoutingService service;
    late ProviderContainer container;
    late RoadRoutePlannerController controller;

    setUp(() {
      service = _FakeHereRoutingService();

      container = ProviderContainer(
        overrides: [hereRoutingServiceProvider.overrideWithValue(service)],
      );

      container.listen(roadRoutePlannerProvider, (previous, next) {});

      controller = container.read(roadRoutePlannerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
      service.close();
    });

    test('inicializa el planificador correctamente', () {
      final state = container.read(roadRoutePlannerProvider);

      expect(state.origin, isNull);
      expect(state.destination, isNull);
      expect(state.originQuery, isEmpty);
      expect(state.destinationQuery, isEmpty);
      expect(state.routes, isEmpty);
      expect(state.currencyCode, 'MXN');
      expect(state.canCalculate, isFalse);
    });

    test('busca ubicaciones para el origen', () async {
      controller.setOriginQuery('Celaya');

      await controller.searchOriginNow();

      final state = container.read(roadRoutePlannerProvider);

      expect(state.originSuggestions, hasLength(1));
      expect(state.originSuggestions.first.title, 'Celaya');
      expect(state.isSearchingOrigin, isFalse);
      expect(state.originSearchMessage, isNull);
    });

    test('busca el destino tomando el origen como referencia', () async {
      controller.selectOrigin(service.origin);
      controller.setDestinationQuery('Querétaro');

      await controller.searchDestinationNow();

      final state = container.read(roadRoutePlannerProvider);

      expect(state.destinationSuggestions, hasLength(1));
      expect(state.destinationSuggestions.first.title, 'Querétaro');
      expect(
        service.lastSearchCenter?.latitude,
        service.origin.coordinate.latitude,
      );
      expect(
        service.lastSearchCenter?.longitude,
        service.origin.coordinate.longitude,
      );
    });

    test('calcula las alternativas y selecciona la primera', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      expect(container.read(roadRoutePlannerProvider).canCalculate, isTrue);

      await controller.calculateRoutes();

      final state = container.read(roadRoutePlannerProvider);

      expect(state.routes, hasLength(2));
      expect(state.selectedRouteId, 'here-route-1');
      expect(state.selectedRoute, isNotNull);
      expect(state.selectedRoute!.distanceKilometers, 80);
      expect(state.isCalculatingRoutes, isFalse);
      expect(state.routeCalculationMessage, isNull);
    });

    test('permite seleccionar otra alternativa disponible', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      await controller.calculateRoutes();

      controller.selectRoute('here-route-2');

      final state = container.read(roadRoutePlannerProvider);

      expect(state.selectedRouteId, 'here-route-2');
      expect(state.selectedRoute!.distanceKilometers, 90);
    });

    test('ignora la selección de una ruta inexistente', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      await controller.calculateRoutes();

      controller.selectRoute('route-does-not-exist');

      expect(
        container.read(roadRoutePlannerProvider).selectedRouteId,
        'here-route-1',
      );
    });

    test('no calcula rutas si faltan ubicaciones', () async {
      await controller.calculateRoutes();

      final state = container.read(roadRoutePlannerProvider);

      expect(state.routes, isEmpty);
      expect(state.isCalculatingRoutes, isFalse);
      expect(state.routeCalculationMessage, isNotNull);
      expect(service.routeRequestCount, 0);
    });

    test('limpia las alternativas al modificar el origen', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      await controller.calculateRoutes();

      expect(container.read(roadRoutePlannerProvider).routes, isNotEmpty);

      controller.setOriginQuery('León');

      final state = container.read(roadRoutePlannerProvider);

      expect(state.origin, isNull);
      expect(state.routes, isEmpty);
      expect(state.selectedRouteId, isNull);
    });

    test('limpia las alternativas al cambiar la moneda', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      await controller.calculateRoutes();

      controller.setCurrencyCode('USD');

      final state = container.read(roadRoutePlannerProvider);

      expect(state.currencyCode, 'USD');
      expect(state.routes, isEmpty);
      expect(state.selectedRouteId, isNull);
    });

    test('ignora un código de moneda inválido', () {
      controller.setCurrencyCode('US');

      expect(container.read(roadRoutePlannerProvider).currencyCode, 'MXN');
    });

    test('restablece el planificador', () async {
      controller.selectOrigin(service.origin);
      controller.selectDestination(service.destination);

      await controller.calculateRoutes();

      controller.reset();

      final state = container.read(roadRoutePlannerProvider);

      expect(state.origin, isNull);
      expect(state.destination, isNull);
      expect(state.routes, isEmpty);
      expect(state.selectedRouteId, isNull);
      expect(state.currencyCode, 'MXN');
    });
  });
}

class _FakeHereRoutingService extends HereRoutingService {
  _FakeHereRoutingService() : super(apiKey: 'test-key');

  final RouteLocation origin = const RouteLocation(
    hereId: 'here-origin',
    title: 'Celaya',
    addressLabel: 'Celaya, Guanajuato, México',
    coordinate: RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
    resultType: 'locality',
  );

  final RouteLocation destination = const RouteLocation(
    hereId: 'here-destination',
    title: 'Querétaro',
    addressLabel: 'Santiago de Querétaro, Querétaro, México',
    coordinate: RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
    resultType: 'locality',
  );

  int routeRequestCount = 0;

  RouteCoordinate? lastSearchCenter;

  RoadRoute get route {
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
          tolls: const [],
        ),
      ],
    );
  }

  RoadRoute get alternativeRoute {
    return RoadRoute(
      id: 'here-route-2',
      origin: origin,
      destination: destination,
      tollDataIncluded: true,
      sections: [
        RouteSection(
          id: 'section-2',
          type: 'vehicle',
          transportMode: 'car',
          distanceMeters: 90000,
          durationSeconds: 4500,
          geometry: const [
            RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
            RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
          ],
          tolls: const [],
        ),
      ],
    );
  }

  @override
  Future<List<RouteLocation>> searchLocations({
    required String query,
    RouteCoordinate? at,
    int limit = 8,
    String language = 'es-MX',
  }) async {
    lastSearchCenter = at;

    final normalizedQuery = query.toLowerCase();

    return [origin, destination]
        .where(
          (location) =>
              location.title.toLowerCase().contains(normalizedQuery) ||
              location.addressLabel.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  Future<List<RoadRoute>> calculateRoutes({
    required RouteLocation origin,
    required RouteLocation destination,
    int alternatives = 2,
    String currencyCode = 'MXN',
    String language = 'es-MX',
    DateTime? departureTime,
    bool includeTolls = true,
  }) async {
    routeRequestCount++;

    return [route, alternativeRoute];
  }
}
