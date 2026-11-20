import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/saved_road_route.dart';

class RoadRouteRepository {
  RoadRouteRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _savedRoutesReference(String uid) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid');
    }

    return _database.ref('users/$normalizedUid/savedRoadRoutes');
  }

  Stream<List<SavedRoadRoute>> watchSavedRoutes(String uid) {
    return _savedRoutesReference(uid).onValue.map((event) {
      final rawData = event.snapshot.value;

      if (rawData == null) {
        return <SavedRoadRoute>[];
      }

      if (rawData is! Map) {
        throw const FormatException(
          'La colección de rutas guardadas no es válida.',
        );
      }

      final routes = <SavedRoadRoute>[];

      for (final entry in rawData.entries) {
        final id = entry.key.toString();
        final record = entry.value;

        if (record is! Map) {
          continue;
        }

        try {
          routes.add(
            SavedRoadRoute.fromMap(id, Map<Object?, Object?>.from(record)),
          );
        } catch (error, stackTrace) {
          developer.log(
            'Se omitió una ruta guardada con datos no válidos.',
            name: 'rumbo.road_routes',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      routes.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return List.unmodifiable(routes);
    });
  }

  Future<String> saveRoute(String uid, RoadRoute route) async {
    final reference = _savedRoutesReference(uid).push();
    final id = reference.key;

    if (id == null) {
      throw StateError('No fue posible generar un identificador para la ruta.');
    }

    final savedRoute = SavedRoadRoute(
      id: id,
      route: route,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await reference.set(savedRoute.toMap());

    return id;
  }

  Future<void> deleteSavedRoute(String uid, String routeId) async {
    final normalizedId = routeId.trim();

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(normalizedId)) {
      throw ArgumentError.value(routeId, 'routeId');
    }

    await _savedRoutesReference(uid).child(normalizedId).remove();
  }
}
