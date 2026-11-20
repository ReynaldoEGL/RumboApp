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

  group('HereRoutingService diagnostics', () {
    test('identifica cuando HERE no encuentra una ruta', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'notices': [
              {
                'title': 'No route was found.',
                'code': 'noRouteFound',
                'severity': 'critical',
              },
            ],
            'routes': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      await expectLater(
        service.calculateRoutes(origin: origin, destination: destination),
        throwsA(
          isA<HereApiException>()
              .having((error) => error.code, 'code', 'noRouteFound')
              .having((error) => error.statusCode, 'statusCode', 200),
        ),
      );
    });

    test(
      'identifica cuando HERE no puede asociar el origen a una carretera',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'notices': [
                {
                  'title': 'Route calculation failed.',
                  'code': 'couldNotMatchOrigin',
                  'severity': 'critical',
                  'details': [
                    {
                      'title': 'Origin waypoint could not be matched.',
                      'cause':
                          'The selected point is not close to a routable road.',
                      'type': 'via',
                      'index': 0,
                    },
                  ],
                },
              ],
              'routes': [],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        addTearDown(client.close);

        final service = HereRoutingService(apiKey: 'test-key', client: client);

        await expectLater(
          service.calculateRoutes(origin: origin, destination: destination),
          throwsA(
            isA<HereApiException>().having(
              (error) => error.code,
              'code',
              'couldNotMatchOrigin',
            ),
          ),
        );
      },
    );

    test('conserva el código y detalle de una respuesta HTTP 403', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Forbidden',
            'error_description': 'The application has no routing permission.',
            'code': 'PERMISSION_DENIED',
          }),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      await expectLater(
        service.calculateRoutes(origin: origin, destination: destination),
        throwsA(
          isA<HereApiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.code, 'code', 'PERMISSION_DENIED'),
        ),
      );
    });

    test('identifica una respuesta que contiene rutas ilegibles', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'routes': [
              {'id': 'broken-route', 'sections': []},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      addTearDown(client.close);

      final service = HereRoutingService(apiKey: 'test-key', client: client);

      await expectLater(
        service.calculateRoutes(origin: origin, destination: destination),
        throwsA(
          isA<HereApiException>().having(
            (error) => error.code,
            'code',
            'routeResponseUnreadable',
          ),
        ),
      );
    });
  });
}
