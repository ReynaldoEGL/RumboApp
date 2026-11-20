import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/core/providers/firebase_database_provider.dart';
import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/road_routes/data/road_route_repository.dart';
import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/saved_road_route.dart';

final roadRouteRepositoryProvider = Provider<RoadRouteRepository>((ref) {
  return RoadRouteRepository(ref.watch(firebaseDatabaseProvider));
});

final savedRoadRoutesProvider =
    StreamProvider.family<List<SavedRoadRoute>, String>((ref, uid) {
      return ref.watch(roadRouteRepositoryProvider).watchSavedRoutes(uid);
    });

final savedRoadRouteControllerProvider =
    AsyncNotifierProvider<SavedRoadRouteController, void>(
      SavedRoadRouteController.new,
    );

class SavedRoadRouteController extends AsyncNotifier<void> {
  RoadRouteRepository get _repository {
    return ref.read(roadRouteRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  String _getAuthenticatedUid() {
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (user == null) {
      throw StateError('Es necesario iniciar sesión para administrar rutas.');
    }

    final usesPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (usesPasswordProvider && !user.emailVerified) {
      throw StateError('Es necesario verificar el correo electrónico.');
    }

    return user.uid;
  }

  Future<T> _execute<T>(Future<T> Function(String uid) operation) async {
    state = const AsyncLoading<void>();

    try {
      final uid = _getAuthenticatedUid();
      final result = await operation(uid);

      state = const AsyncData<void>(null);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);

      rethrow;
    }
  }

  Future<String> saveRoute(RoadRoute route) {
    return _execute((uid) => _repository.saveRoute(uid, route));
  }

  Future<void> deleteSavedRoute(String routeId) {
    return _execute((uid) => _repository.deleteSavedRoute(uid, routeId));
  }
}
