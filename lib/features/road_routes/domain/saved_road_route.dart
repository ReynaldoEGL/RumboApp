import 'package:rumboapp/features/road_routes/domain/road_route.dart';

class SavedRoadRoute {
  const SavedRoadRoute({
    required this.id,
    required this.route,
    required this.savedAt,
  });

  final String id;
  final RoadRoute route;
  final int savedAt;

  String get displayName {
    return '${route.origin.title} → ${route.destination.title}';
  }

  factory SavedRoadRoute.fromMap(String id, Map<Object?, Object?> rawData) {
    final data = Map<String, Object?>.from(rawData);

    if (id.trim().isEmpty) {
      throw const FormatException('La ruta guardada no tiene identificador.');
    }

    final schemaVersion = data['schemaVersion'];
    final savedAt = data['savedAt'];
    final rawRoute = data['route'];

    if (schemaVersion is! num || schemaVersion.toInt() != 1) {
      throw const FormatException(
        'La versión de la ruta guardada no es compatible.',
      );
    }

    if (savedAt is! num || !savedAt.isFinite || savedAt < 0) {
      throw const FormatException(
        'La fecha de guardado de la ruta no es válida.',
      );
    }

    if (rawRoute is! Map) {
      throw const FormatException(
        'Los datos de la ruta guardada no son válidos.',
      );
    }

    return SavedRoadRoute(
      id: id,
      route: RoadRoute.fromMap(Map<Object?, Object?>.from(rawRoute)),
      savedAt: savedAt.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'No se puede guardar una ruta sin identificador.',
      );
    }

    if (savedAt < 0) {
      throw const FormatException('La fecha de guardado no es válida.');
    }

    return {'schemaVersion': 1, 'savedAt': savedAt, 'route': route.toMap()};
  }
}
