import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rumboapp/features/road_routes/data/here_routing_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

void main() {
  const origin = RouteLocation(
    hereId: 'here-origin',
    title: 'Celaya',
    addressLabel: 'Celaya, Guanajuato, México',
    coordinate: RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
    resultType: 'locality',
  );

  const destination = RouteLocation(
    hereId: 'here-destination',
    title: 'Querétaro',
    addressLabel: 'Santiago de Querétaro, Querétaro, México',
    coordinate: RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
    resultType: 'locality',
  );

  const encodedPolyline =
      'BlD05xgKuy2xCCx9B7vUCl0OhnRC54EqSCzpEl-HCxjD3pBCiGnyGCi2CvwFCsgD3nDC4vB6eC';

  group('HereRoutingService', () {
    test('busca ubicaciones mediante Autosuggest', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'autosuggest.search.hereapi.com');

        expect(request.url.path, '/v1/autosuggest');

        expect(request.url.queryParameters['q'], 'Querétaro');
        expect(request.url.queryParameters['at'], '20.5235000,-100.8157000');
        expect(request.url.queryParameters['limit'], '8');
        expect(request.url.queryParameters['lang'], 'es-MX');
        expect(request.url.queryParameters['mobilityMode'], 'car');
        expect(request.url.queryParameters['apiKey'], 'test-key');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'here-location-1',
                'title': 'Santiago de Querétaro',
                'resultType': 'locality',
                'position': {'lat': 20.5888, 'lng': -100.3899},
                'address': {'label': 'Querétaro, México'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      final locations = await service.searchLocations(
        query: 'Querétaro',
        at: origin.coordinate,
      );

      expect(locations, hasLength(1));
      expect(locations.first.hereId, 'here-location-1');
      expect(locations.first.title, 'Santiago de Querétaro');
      expect(locations.first.addressLabel, 'Querétaro, México');
      expect(locations.first.coordinate.latitude, 20.5888);
    });

    test('no realiza solicitudes para consultas demasiado cortas', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        return http.Response(jsonEncode({'items': []}), 200);
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      final results = await service.searchLocations(
        query: 'Q',
        at: origin.coordinate,
      );

      expect(results, isEmpty);
      expect(requestCount, 0);
    });

    test('calcula una ruta y procesa los peajes', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'router.hereapi.com');

        expect(request.url.path, '/v8/routes');

        expect(request.url.queryParameters['transportMode'], 'car');
        expect(
          request.url.queryParameters['origin'],
          '20.5235000,-100.8157000',
        );
        expect(
          request.url.queryParameters['destination'],
          '20.5888000,-100.3899000',
        );
        expect(request.url.queryParameters['routingMode'], 'fast');
        expect(request.url.queryParameters['alternatives'], '2');
        expect(request.url.queryParameters['return'], 'polyline,summary,tolls');
        expect(request.url.queryParameters['units'], 'metric');
        expect(request.url.queryParameters['currency'], 'MXN');
        expect(request.url.queryParameters['lang'], 'es-MX');
        expect(request.url.queryParameters['apiKey'], 'test-key');

        return http.Response(
          jsonEncode({
            'routes': [
              {
                'id': 'here-route-1',
                'sections': [
                  {
                    'id': 'section-1',
                    'type': 'vehicle',
                    'transport': {'mode': 'car'},
                    'summary': {'length': 1000, 'duration': 300},
                    'polyline': encodedPolyline,
                    'tolls': [
                      {
                        'countryCode': 'MEX',
                        'tollSystem': 'Autopista de prueba',
                        'fares': [
                          {
                            'id': 'fare-1',
                            'name': 'Tarifa general',
                            'price': {
                              'type': 'value',
                              'currency': 'MXN',
                              'value': 100,
                            },
                            'paymentMethods': ['cash'],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      final routes = await service.calculateRoutes(
        origin: origin,
        destination: destination,
      );

      expect(routes, hasLength(1));

      final route = routes.first;

      expect(route.id, 'here-route-1');
      expect(route.origin.title, 'Celaya');
      expect(route.destination.title, 'Querétaro');
      expect(route.distanceMeters, 1000);
      expect(route.durationSeconds, 300);
      expect(route.tollDataIncluded, isTrue);
      expect(route.geometry, hasLength(10));

      expect(route.tolls, hasLength(1));
      expect(route.tolls.first.countryCode, 'MEX');
      expect(route.tolls.first.tollSystem, 'Autopista de prueba');

      expect(route.tolls.first.fares, hasLength(1));
      expect(route.tolls.first.fares.first.amount, 100);
      expect(route.tolls.first.fares.first.paymentMethods, ['cash']);
    });

    test('omite los peajes cuando no se solicitan', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['return'], 'polyline,summary');

        return http.Response(jsonEncode({'routes': []}), 200);
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      final routes = await service.calculateRoutes(
        origin: origin,
        destination: destination,
        includeTolls: false,
      );

      expect(routes, isEmpty);
    });

    test('devuelve lista vacía cuando HERE no encuentra rutas', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'routes': []}), 200);
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      final routes = await service.calculateRoutes(
        origin: origin,
        destination: destination,
      );

      expect(routes, isEmpty);
    });

    test('convierte el código HTTP 429 en una excepción controlada', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'title': 'Too Many Requests'}), 429);
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      await expectLater(
        service.searchLocations(query: 'Celaya', at: origin.coordinate),
        throwsA(
          isA<HereApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
    });

    test('rechaza una solicitud sin clave API configurada', () async {
      final service = HereRoutingService(apiKey: '');

      addTearDown(service.close);

      await expectLater(
        service.searchLocations(query: 'Celaya', at: origin.coordinate),
        throwsA(isA<HereApiException>()),
      );
    });
    test(
      'rechaza un número de alternativas fuera del rango permitido',
      () async {
        final service = HereRoutingService(apiKey: 'test-key');

        addTearDown(service.close);

        await expectLater(
          service.calculateRoutes(
            origin: origin,
            destination: destination,
            alternatives: 7,
          ),
          throwsA(isA<RangeError>()),
        );
      },
    );

    test('rechaza un código de moneda inválido', () async {
      final service = HereRoutingService(apiKey: 'test-key');

      addTearDown(service.close);

      await expectLater(
        service.calculateRoutes(
          origin: origin,
          destination: destination,
          currencyCode: 'US',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
