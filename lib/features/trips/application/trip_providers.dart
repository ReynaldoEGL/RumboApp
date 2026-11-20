import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/core/providers/firebase_database_provider.dart';
import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/trips/data/trip_repository.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(firebaseDatabaseProvider));
});

final tripsProvider = StreamProvider.family<List<Trip>, String>((ref, uid) {
  return ref.watch(tripRepositoryProvider).watchTrips(uid);
});

final tripControllerProvider = AsyncNotifierProvider<TripController, void>(
  TripController.new,
);

class TripController extends AsyncNotifier<void> {
  TripRepository get _repository {
    return ref.read(tripRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  String _getAuthenticatedUid() {
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (user == null) {
      throw StateError('Debes iniciar sesión para administrar tus viajes.');
    }

    final usesPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (usesPasswordProvider && !user.emailVerified) {
      throw StateError('Debes verificar tu correo antes de continuar.');
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

  Future<String> addTrip(Trip trip) {
    return _execute((uid) => _repository.addTrip(uid, trip));
  }

  Future<void> updateTrip(Trip trip) {
    return _execute((uid) => _repository.updateTrip(uid, trip));
  }

  Future<void> deleteTrip(String tripId) {
    return _execute((uid) => _repository.deleteTrip(uid, tripId));
  }
}
