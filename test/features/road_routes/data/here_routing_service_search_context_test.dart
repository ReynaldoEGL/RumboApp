import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rumboapp/features/road_routes/data/here_routing_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

void main() {
  group('HereRoutingService search context', () {
    test(
      'utiliza el centro de referencia cuando no se proporciona at',
      () async {
        final client = MockClient((request) async {
          expect(request.url.queryParameters['at'], '23.6345000,-102.5528000');

          expect(request.url.queryParameters['q'], 'Paris');

          return http.Response(
            jsonEncode({'items': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        addTearDown(client.close);

        final service = HereRoutingService(apiKey: 'test-key', client: client);

        await service.searchLocations(query: 'Paris');
      },
    );

    test(
      'conserva las coordenadas cuando se proporciona una referencia',
      () async {
        final client = MockClient((request) async {
          expect(request.url.queryParameters['at'], '48.8566000,2.3522000');

          return http.Response(
            jsonEncode({'items': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        addTearDown(client.close);

        final service = HereRoutingService(apiKey: 'test-key', client: client);

        await service.searchLocations(
          query: 'Torre Eiffel',
          at: const RouteCoordinate(latitude: 48.8566, longitude: 2.3522),
        );
      },
    );
  });
}
