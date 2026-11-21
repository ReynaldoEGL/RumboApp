import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

abstract interface class ReverseGeocodingService {
  Future<String?> reverseGeocode(RouteCoordinate coordinate);
}

class HereReverseGeocodingService implements ReverseGeocodingService {
  HereReverseGeocodingService({
    required String apiKey,
    http.Client? client,
    this._timeout = const Duration(seconds: 12),
  }) : _apiKey = apiKey.trim(),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const String _host = 'revgeocode.search.hereapi.com';
  static const String _path = '/v1/revgeocode';

  final String _apiKey;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  @override
  Future<String?> reverseGeocode(RouteCoordinate coordinate) async {
    if (!coordinate.isValid) {
      throw const FormatException('Las coordenadas GPS no son válidas.');
    }

    if (_apiKey.isEmpty) {
      developer.log(
        'No se configuró HERE_API_KEY para la geocodificación inversa.',
        name: 'rumbo.reverse_geocoding',
      );
      return null;
    }

    final uri = Uri.https(_host, _path, {
      'at':
          '${coordinate.latitude.toStringAsFixed(7)},'
          '${coordinate.longitude.toStringAsFixed(7)}',
      'lang': 'es-MX',
      'limit': '1',
      'apiKey': _apiKey,
    });

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        developer.log(
          'HERE Reverse Geocoding respondió HTTP ${response.statusCode}.',
          name: 'rumbo.reverse_geocoding',
        );
        return null;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map) {
        return null;
      }

      final items = decoded['items'];

      if (items is! List || items.isEmpty) {
        return null;
      }

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final address = item['address'];
        final label = address is Map ? address['label'] : null;
        final title = item['title'];

        if (label is String && label.trim().isNotEmpty) {
          return label.trim();
        }

        if (title is String && title.trim().isNotEmpty) {
          return title.trim();
        }
      }

      return null;
    } catch (error) {
      final safeError = error.toString().replaceAll(_apiKey, '[CLAVE_OCULTA]');

      developer.log(
        'No se pudo resolver una dirección aproximada: $safeError',
        name: 'rumbo.reverse_geocoding',
      );
      return null;
    }
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
