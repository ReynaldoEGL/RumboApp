import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rumboapp/features/road_routes/data/here_reverse_geocoding_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

void main() {
  const coordinate = RouteCoordinate(latitude: 20.5235, longitude: -100.8157);

  group('HereReverseGeocodingService', () {
    test('consulta el endpoint correcto y recupera la dirección', () async {
      final client = MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'revgeocode.search.hereapi.com');
        expect(request.url.path, '/v1/revgeocode');
        expect(request.url.queryParameters['at'], '20.5235000,-100.8157000');
        expect(request.url.queryParameters['lang'], 'es-MX');
        expect(request.url.queryParameters['limit'], '1');
        expect(request.url.queryParameters['apiKey'], 'test-key');

        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'items': [
                {
                  'id': 'here:example',
                  'title': 'Calle de prueba',
                  'address': {
                    'label': 'Calle de prueba, Celaya, Guanajuato, México',
                  },
                },
              ],
            }),
          ),
          200,
        );
      });
      addTearDown(client.close);

      final service = HereReverseGeocodingService(
        apiKey: 'test-key',
        client: client,
      );
      final address = await service.reverseGeocode(coordinate);

      expect(address, 'Calle de prueba, Celaya, Guanajuato, México');
    });

    test('devuelve null cuando no hay resultados', () async {
      final client = MockClient((_) async {
        return http.Response('{"items":[]}', 200);
      });
      addTearDown(client.close);

      final service = HereReverseGeocodingService(
        apiKey: 'test-key',
        client: client,
      );

      expect(await service.reverseGeocode(coordinate), isNull);
    });

    test('devuelve null ante un error HTTP sin perder el GPS', () async {
      final client = MockClient((_) async {
        return http.Response('{"title":"Forbidden"}', 403);
      });
      addTearDown(client.close);

      final service = HereReverseGeocodingService(
        apiKey: 'test-key',
        client: client,
      );

      expect(await service.reverseGeocode(coordinate), isNull);
    });

    test('no realiza una solicitud cuando falta la clave', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);

      final service = HereReverseGeocodingService(apiKey: '', client: client);

      expect(await service.reverseGeocode(coordinate), isNull);
      expect(requestCount, 0);
    });

    test('rechaza coordenadas inválidas', () async {
      final service = HereReverseGeocodingService(apiKey: 'test-key');
      addTearDown(service.close);

      await expectLater(
        service.reverseGeocode(
          const RouteCoordinate(latitude: 92, longitude: -100),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
