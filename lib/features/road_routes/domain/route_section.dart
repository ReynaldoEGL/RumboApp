import 'package:rumboapp/features/road_routes/domain/here_flexible_polyline.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';

class RouteSection {
  RouteSection({
    required this.id,
    required this.type,
    required this.transportMode,
    required this.distanceMeters,
    required this.durationSeconds,
    required List<RouteCoordinate> geometry,
    required List<RouteToll> tolls,
  }) : geometry = List.unmodifiable(geometry),
       tolls = List.unmodifiable(tolls);

  final String id;
  final String type;
  final String? transportMode;
  final double distanceMeters;
  final int durationSeconds;
  final List<RouteCoordinate> geometry;
  final List<RouteToll> tolls;

  double get distanceKilometers => distanceMeters / 1000;

  factory RouteSection.fromHereMap(
    Map<Object?, Object?> data, {
    required int index,
  }) {
    final summary = _readMap(data['summary']);

    final distance = _readNumber(summary['length']);
    final duration = _readNumber(summary['duration']);

    if (distance < 0 || duration < 0) {
      throw const FormatException('Los datos del tramo no son válidos.');
    }

    final encodedPolyline = _optionalString(data['polyline']);

    final geometry = encodedPolyline == null
        ? <RouteCoordinate>[]
        : HereFlexiblePolyline.decode(encodedPolyline);

    final rawTolls = data['tolls'];

    final tolls = rawTolls is List
        ? rawTolls
              .whereType<Map>()
              .map(
                (toll) =>
                    RouteToll.fromHereMap(Map<Object?, Object?>.from(toll)),
              )
              .toList()
        : <RouteToll>[];

    return RouteSection(
      id: _optionalString(data['id']) ?? 'section-$index',
      type: _optionalString(data['type']) ?? 'vehicle',
      transportMode: _optionalString(_optionalMap(data['transport'])?['mode']),
      distanceMeters: distance,
      durationSeconds: duration.round(),
      geometry: geometry,
      tolls: tolls,
    );
  }

  factory RouteSection.fromMap(Map<Object?, Object?> data) {
    final rawGeometry = data['geometry'];
    final rawTolls = data['tolls'];

    final geometry = rawGeometry is List
        ? rawGeometry
              .whereType<Map>()
              .map(
                (coordinate) => RouteCoordinate.fromMap(
                  Map<Object?, Object?>.from(coordinate),
                ),
              )
              .toList()
        : <RouteCoordinate>[];

    final tolls = rawTolls is List
        ? rawTolls
              .whereType<Map>()
              .map(
                (toll) => RouteToll.fromMap(Map<Object?, Object?>.from(toll)),
              )
              .toList()
        : <RouteToll>[];

    final distance = _readNumber(data['distanceMeters']);
    final duration = _readNumber(data['durationSeconds']);

    if (distance < 0 || duration < 0) {
      throw const FormatException(
        'Los datos del tramo almacenado no son válidos.',
      );
    }

    return RouteSection(
      id: _requiredString(data['id']),
      type: _requiredString(data['type']),
      transportMode: _optionalString(data['transportMode']),
      distanceMeters: distance,
      durationSeconds: duration.round(),
      geometry: geometry,
      tolls: tolls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      if (transportMode != null) 'transportMode': transportMode,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'geometry': geometry.map((coordinate) => coordinate.toMap()).toList(),
      'tolls': tolls.map((toll) => toll.toMap()).toList(),
    };
  }
}

Map<Object?, Object?> _readMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('El resumen del tramo no es válido.');
  }

  return Map<Object?, Object?>.from(value);
}

Map<Object?, Object?>? _optionalMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return Map<Object?, Object?>.from(value);
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('El tramo contiene un campo vacío.');
  }

  return value.trim();
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value.trim();
}

double _readNumber(Object? value) {
  if (value is! num) {
    throw const FormatException('El resumen contiene un valor no numérico.');
  }

  final result = value.toDouble();

  if (!result.isFinite) {
    throw const FormatException('El resumen contiene un valor inválido.');
  }

  return result;
}
