import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

class HereApiException implements Exception {
  const HereApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HereRoutingService {
  HereRoutingService({
    required String apiKey,
    http.Client? client,
    this._timeout = const Duration(seconds: 25),
  }) : _apiKey = apiKey.trim(),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const String _searchHost = 'autosuggest.search.hereapi.com';
  static const String _routingHost = 'router.hereapi.com';

  static const String _searchPath = '/v1/autosuggest';
  static const String _routingPath = '/v8/routes';

  final String _apiKey;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  Future<List<RouteLocation>> searchLocations({
    required String query,
    RouteCoordinate? at,
    int limit = 8,
    String language = 'es-MX',
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < 2) {
      return const [];
    }

    if (at != null && !at.isValid) {
      throw const FormatException(
        'El centro de búsqueda no contiene coordenadas válidas.',
      );
    }

    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    if (language.trim().isEmpty) {
      throw ArgumentError.value(language, 'language');
    }

    final apiKey = _validatedApiKey();

    final queryParameters = <String, String>{
      'q': normalizedQuery,
      'limit': '$limit',
      'lang': language.trim(),
      'mobilityMode': 'car',
      'apiKey': apiKey,
    };

    if (at != null) {
      queryParameters['at'] = _formatCoordinate(at);
    }

    final uri = Uri.https(_searchHost, _searchPath, queryParameters);

    final payload = await _requestJson(uri);
    final rawItems = payload['items'];

    if (rawItems == null) {
      return const [];
    }

    if (rawItems is! List) {
      throw const HereApiException(
        message: 'El servicio de búsqueda devolvió una respuesta no válida.',
      );
    }

    final locations = <RouteLocation>[];
    final existingIds = <String>{};

    for (final item in rawItems) {
      if (item is! Map) {
        continue;
      }

      try {
        final location = RouteLocation.fromHereMap(
          Map<Object?, Object?>.from(item),
        );

        if (existingIds.add(location.hereId)) {
          locations.add(location);
        }
      } catch (error, stackTrace) {
        developer.log(
          'Se omitió una sugerencia geográfica no válida.',
          name: 'rumbo.road_routes',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return List.unmodifiable(locations);
  }

  Future<List<RoadRoute>> calculateRoutes({
    required RouteLocation origin,
    required RouteLocation destination,
    int alternatives = 2,
    String currencyCode = 'MXN',
    String language = 'es-MX',
    DateTime? departureTime,
    bool includeTolls = true,
  }) async {
    if (!origin.coordinate.isValid || !destination.coordinate.isValid) {
      throw const FormatException(
        'El origen y el destino deben tener coordenadas válidas.',
      );
    }

    if (origin.hereId == destination.hereId) {
      throw const FormatException(
        'El origen y el destino deben ser diferentes.',
      );
    }

    if (alternatives < 0 || alternatives > 6) {
      throw RangeError.range(alternatives, 0, 6, 'alternatives');
    }

    final normalizedCurrency = currencyCode.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
      throw const FormatException(
        'El código de moneda debe contener tres letras.',
      );
    }

    if (language.trim().isEmpty) {
      throw ArgumentError.value(language, 'language');
    }

    final apiKey = _validatedApiKey();

    final returnFields = <String>[
      'polyline',
      'summary',
      if (includeTolls) 'tolls',
    ];

    final queryParameters = <String, String>{
      'transportMode': 'car',
      'origin': _formatCoordinate(origin.coordinate),
      'destination': _formatCoordinate(destination.coordinate),
      'routingMode': 'fast',
      'alternatives': '$alternatives',
      'return': returnFields.join(','),
      'units': 'metric',
      'currency': normalizedCurrency,
      'lang': language.trim(),
      'apiKey': apiKey,
    };

    if (departureTime != null) {
      queryParameters['departureTime'] = departureTime.toIso8601String();
    }

    final uri = Uri.https(_routingHost, _routingPath, queryParameters);

    final payload = await _requestJson(uri);
    final rawRoutes = payload['routes'];

    if (rawRoutes == null) {
      return const [];
    }

    if (rawRoutes is! List) {
      throw const HereApiException(
        message: 'El servicio de rutas devolvió una respuesta no válida.',
      );
    }

    final routes = <RoadRoute>[];

    for (final item in rawRoutes) {
      if (item is! Map) {
        continue;
      }

      try {
        final route = RoadRoute.fromHereMap(
          Map<Object?, Object?>.from(item),
          origin: origin,
          destination: destination,
          tollDataIncluded: includeTolls,
        );

        routes.add(route);
      } catch (error, stackTrace) {
        developer.log(
          'Se omitió una alternativa de ruta no válida.',
          name: 'rumbo.road_routes',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return List.unmodifiable(routes);
  }

  Future<Map<String, Object?>> _requestJson(Uri uri) async {
    late final http.Response response;

    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const HereApiException(
        message: 'El servicio de mapas tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw const HereApiException(
        message: 'No fue posible establecer conexión con el servicio de mapas.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HereApiException(
        statusCode: response.statusCode,
        message: _messageForStatusCode(response.statusCode),
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const HereApiException(
        message: 'El servicio de mapas devolvió una respuesta no válida.',
      );
    }

    if (decoded is! Map) {
      throw const HereApiException(
        message: 'El servicio de mapas devolvió una respuesta no válida.',
      );
    }

    return Map<String, Object?>.from(decoded);
  }

  String _validatedApiKey() {
    if (_apiKey.isEmpty) {
      throw const HereApiException(
        message: 'El servicio de mapas no está configurado.',
      );
    }

    return _apiKey;
  }

  String _formatCoordinate(RouteCoordinate coordinate) {
    return '${coordinate.latitude.toStringAsFixed(7)},'
        '${coordinate.longitude.toStringAsFixed(7)}';
  }

  String _messageForStatusCode(int statusCode) {
    if (statusCode == 400) {
      return 'No fue posible interpretar la solicitud de búsqueda o ruta.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'El servicio de mapas no autorizó la solicitud.';
    }

    if (statusCode == 429) {
      return 'El servicio de mapas recibió demasiadas solicitudes.';
    }

    if (statusCode >= 500) {
      return 'El servicio de mapas no está disponible temporalmente.';
    }

    return 'No fue posible completar la solicitud de mapas.';
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
