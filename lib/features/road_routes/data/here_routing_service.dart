import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

class HereApiException implements Exception {
  const HereApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.providerMessage,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? providerMessage;

  @override
  String toString() {
    final details = <String>[
      if (statusCode != null) 'HTTP $statusCode',
      if (code != null) 'código: $code',
      if (providerMessage != null) 'detalle: $providerMessage',
    ];

    if (details.isEmpty) {
      return message;
    }

    return '$message (${details.join(' | ')})';
  }
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

  static const RouteCoordinate defaultSearchCenter = RouteCoordinate(
    latitude: 23.6345,
    longitude: -102.5528,
  );

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
    final searchCenter = at ?? defaultSearchCenter;

    final queryParameters = <String, String>{
      'q': normalizedQuery,
      'at': _formatCoordinate(searchCenter),
      'limit': '$limit',
      'lang': language.trim(),
      'mobilityMode': 'car',
      'apiKey': apiKey,
    };

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

    developer.log(
      'Iniciando cálculo de recorrido. '
      'Origen: ${origin.coordinate.latitude},'
      '${origin.coordinate.longitude}. '
      'Destino: ${destination.coordinate.latitude},'
      '${destination.coordinate.longitude}.',
      name: 'rumbo.road_routes',
    );

    final payload = await _requestJson(uri);
    final rawRoutes = payload['routes'];

    if (rawRoutes is! List) {
      throw const HereApiException(
        message: 'El servicio de rutas devolvió una respuesta incompleta.',
        code: 'missingRoutesField',
      );
    }

    final criticalNotice = _findCriticalNotice(payload['notices']);

    if (criticalNotice != null) {
      final exception = _exceptionFromNotice(criticalNotice);

      developer.log(
        'HERE notificó un problema durante el cálculo de rutas.',
        name: 'rumbo.road_routes',
        error: exception,
      );

      throw exception;
    }

    if (rawRoutes.isEmpty) {
      developer.log(
        'HERE respondió correctamente, pero no devolvió rutas.',
        name: 'rumbo.road_routes',
      );

      return const [];
    }

    final routes = <RoadRoute>[];
    var skippedRoutes = 0;

    for (var index = 0; index < rawRoutes.length; index++) {
      final item = rawRoutes[index];

      if (item is! Map) {
        skippedRoutes++;

        developer.log(
          'Se omitió una ruta porque su estructura no es válida.',
          name: 'rumbo.road_routes',
        );

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
        skippedRoutes++;

        final routeId = _readString(item['id']) ?? 'sin identificador';

        developer.log(
          'No fue posible interpretar la ruta $routeId.',
          name: 'rumbo.road_routes',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (routes.isEmpty && skippedRoutes > 0) {
      throw HereApiException(
        message:
            'El servicio encontró información de rutas, '
            'pero no fue posible procesarla. Inténtalo nuevamente.',
        code: 'routeResponseUnreadable',
        providerMessage:
            'Se recibieron ${rawRoutes.length} rutas y todas '
            'fueron descartadas durante su interpretación.',
      );
    }

    developer.log(
      'Cálculo terminado. '
      'Rutas válidas: ${routes.length}. '
      'Rutas descartadas: $skippedRoutes.',
      name: 'rumbo.road_routes',
    );

    return List.unmodifiable(routes);
  }

  Map<Object?, Object?>? _findCriticalNotice(Object? rawNotices) {
    if (rawNotices is! List) {
      return null;
    }

    final notices = rawNotices.whereType<Map>().map(
      (notice) => Map<Object?, Object?>.from(notice),
    );

    for (final notice in notices) {
      final severity = _readString(notice['severity'])?.toLowerCase();

      if (severity == 'critical') {
        return notice;
      }
    }

    return null;
  }

  HereApiException _exceptionFromNotice(Map<Object?, Object?> notice) {
    final code = _readString(notice['code']);
    final title = _readString(notice['title']);
    final cause = _readString(notice['cause']);

    final detailParts = <String>[
      ?title,
      ?cause,
      ..._readNoticeDetails(notice['details']),
    ];

    final providerMessage = detailParts.isEmpty ? null : detailParts.join(' ');

    return HereApiException(
      message: _messageForNoticeCode(code),
      statusCode: 200,
      code: code,
      providerMessage: providerMessage,
    );
  }

  List<String> _readNoticeDetails(Object? rawDetails) {
    if (rawDetails is! List) {
      return const [];
    }

    final details = <String>[];

    for (final item in rawDetails) {
      if (item is! Map) {
        continue;
      }

      final detail = Map<Object?, Object?>.from(item);
      final title = _readString(detail['title']);
      final cause = _readString(detail['cause']);

      if (title != null) {
        details.add(title);
      }

      if (cause != null) {
        details.add(cause);
      }
    }

    return details;
  }

  String _messageForNoticeCode(String? code) {
    return switch (code) {
      'noRouteFound' =>
        'No encontramos un recorrido transitable entre los puntos '
            'seleccionados. Prueba con ubicaciones cercanas a una carretera.',
      'couldNotMatchOrigin' =>
        'No pudimos ubicar el punto de partida sobre una carretera. '
            'Selecciona una dirección o un punto cercano.',
      'couldNotMatchDestination' =>
        'No pudimos ubicar el destino sobre una carretera. '
            'Selecciona una dirección o un punto cercano.',
      'routeLengthLimitExceeded' =>
        'El recorrido supera la distancia admitida por el servicio. '
            'Intenta planearlo por etapas.',
      'cancelled' =>
        'El cálculo del recorrido tardó demasiado. Inténtalo nuevamente.',
      'routeCalculationFailed' =>
        'No fue posible calcular el recorrido con los puntos seleccionados.',
      'unknownError' =>
        'El servicio no pudo determinar cómo calcular este recorrido.',
      _ =>
        'HERE no pudo completar el cálculo del recorrido. '
            'Comprueba los puntos seleccionados e inténtalo nuevamente.',
    };
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
        code: 'requestTimeout',
      );
    } on http.ClientException {
      throw const HereApiException(
        message: 'No fue posible establecer conexión con el servicio de mapas.',
        code: 'connectionFailed',
      );
    }

    final decodedPayload = _decodeResponseBody(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final providerCode = _readString(decodedPayload?['code']);
      final providerMessage = _readProviderErrorMessage(decodedPayload);

      throw HereApiException(
        message: _messageForStatusCode(response.statusCode),
        statusCode: response.statusCode,
        code: providerCode,
        providerMessage: providerMessage,
      );
    }

    if (decodedPayload == null) {
      throw const HereApiException(
        message: 'El servicio de mapas devolvió una respuesta no válida.',
        code: 'invalidJsonResponse',
      );
    }

    return decodedPayload;
  }

  Map<String, Object?>? _decodeResponseBody(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));

      if (decoded is! Map) {
        return null;
      }

      return Map<String, Object?>.from(decoded);
    } on FormatException {
      return null;
    }
  }

  String? _readProviderErrorMessage(Map<String, Object?>? payload) {
    if (payload == null) {
      return null;
    }

    final error = payload['error'];
    final errorDescription = payload['error_description'];

    final parts = <String>[
      ?_readString(payload['title']),
      ?_readString(payload['cause']),
      ?_readString(payload['message']),
      ?_readString(errorDescription),
      ?_readString(error),
    ];

    return parts.isEmpty ? null : parts.join(' ');
  }

  String _messageForStatusCode(int statusCode) {
    return switch (statusCode) {
      400 =>
        'El servicio rechazó los datos del recorrido. '
            'Comprueba las ubicaciones seleccionadas.',
      401 => 'No fue posible autenticar la solicitud del servicio de mapas.',
      403 =>
        'El servicio de rutas no permite esta solicitud. '
            'Es necesario revisar los permisos de la cuenta.',
      429 =>
        'Se alcanzó el límite temporal de solicitudes del servicio de mapas.',
      >= 500 => 'El servicio de mapas no está disponible temporalmente.',
      _ => 'No fue posible completar la solicitud de mapas.',
    };
  }

  String _validatedApiKey() {
    if (_apiKey.isEmpty) {
      throw const HereApiException(
        message: 'El servicio de mapas no está configurado.',
        code: 'missingApiKey',
      );
    }

    return _apiKey;
  }

  String _formatCoordinate(RouteCoordinate coordinate) {
    return '${coordinate.latitude.toStringAsFixed(7)},'
        '${coordinate.longitude.toStringAsFixed(7)}';
  }

  String? _readString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
