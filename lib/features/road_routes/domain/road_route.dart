import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';

class RoadRoute {
  RoadRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required List<RouteSection> sections,
    required this.tollDataIncluded,
  }) : sections = List.unmodifiable(sections) {
    if (id.trim().isEmpty) {
      throw const FormatException('La ruta no tiene identificador.');
    }

    if (sections.isEmpty) {
      throw const FormatException('La ruta no contiene tramos.');
    }
  }

  final String id;
  final RouteLocation origin;
  final RouteLocation destination;
  final List<RouteSection> sections;
  final bool tollDataIncluded;

  double get distanceMeters {
    return sections.fold(0, (total, section) => total + section.distanceMeters);
  }

  double get distanceKilometers => distanceMeters / 1000;

  int get durationSeconds {
    return sections.fold(
      0,
      (total, section) => total + section.durationSeconds,
    );
  }

  List<RouteCoordinate> get geometry {
    final result = <RouteCoordinate>[];

    for (final section in sections) {
      for (final coordinate in section.geometry) {
        if (result.isNotEmpty && _sameCoordinate(result.last, coordinate)) {
          continue;
        }

        result.add(coordinate);
      }
    }

    return List.unmodifiable(result);
  }

  List<RouteToll> get tolls {
    return List.unmodifiable(sections.expand((section) => section.tolls));
  }

  factory RoadRoute.fromHereMap(
    Map<Object?, Object?> data, {
    required RouteLocation origin,
    required RouteLocation destination,
    required bool tollDataIncluded,
  }) {
    final rawSections = data['sections'];

    if (rawSections is! List) {
      throw const FormatException('La respuesta no contiene tramos.');
    }

    final sections = <RouteSection>[];

    for (var index = 0; index < rawSections.length; index++) {
      final rawSection = rawSections[index];

      if (rawSection is! Map) {
        continue;
      }

      sections.add(
        RouteSection.fromHereMap(
          Map<Object?, Object?>.from(rawSection),
          index: index,
        ),
      );
    }

    return RoadRoute(
      id: _requiredString(data['id']),
      origin: origin,
      destination: destination,
      sections: sections,
      tollDataIncluded: tollDataIncluded,
    );
  }

  factory RoadRoute.fromMap(Map<Object?, Object?> data) {
    final rawSections = data['sections'];

    if (rawSections is! List) {
      throw const FormatException('La ruta almacenada no contiene tramos.');
    }

    final sections = rawSections
        .whereType<Map>()
        .map(
          (section) =>
              RouteSection.fromMap(Map<Object?, Object?>.from(section)),
        )
        .toList();

    return RoadRoute(
      id: _requiredString(data['id']),
      origin: RouteLocation.fromMap(_readMap(data['origin'])),
      destination: RouteLocation.fromMap(_readMap(data['destination'])),
      sections: sections,
      tollDataIncluded: data['tollDataIncluded'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'sections': sections.map((section) => section.toMap()).toList(),
      'tollDataIncluded': tollDataIncluded,
    };
  }
}

bool _sameCoordinate(RouteCoordinate first, RouteCoordinate second) {
  return (first.latitude - second.latitude).abs() < 0.000001 &&
      (first.longitude - second.longitude).abs() < 0.000001;
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('La ruta contiene un identificador inválido.');
  }

  return value.trim();
}

Map<Object?, Object?> _readMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('La ubicación de la ruta no es válida.');
  }

  return Map<Object?, Object?>.from(value);
}
