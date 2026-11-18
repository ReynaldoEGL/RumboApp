import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).userChanges();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _repository {
    return ref.read(authRepositoryProvider);
  }

  @override
  Future<void> build() async {}

  Future<T> _execute<T>(Future<T> Function() operation) async {
    state = const AsyncLoading<void>();

    try {
      final result = await operation();

      state = const AsyncData<void>(null);

      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);

      rethrow;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _execute(() async {
      await _repository.createEmailAccount(email: email, password: password);

      await _repository.sendVerificationEmail();
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _execute(() async {
      await _repository.signInWithEmail(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() {
    return _execute(() async {
      await _repository.signInWithGoogle();
    });
  }

  Future<void> signInWithGitHub() {
    return _execute(() async {
      await _repository.signInWithGitHub();
    });
  }

  Future<void> resendVerificationEmail() {
    return _execute(() async {
      await _repository.sendVerificationEmail();
    });
  }

  Future<bool> refreshVerificationStatus() {
    return _execute(() async {
      final user = await _repository.reloadCurrentUser();

      return user?.emailVerified ?? false;
    });
  }

  Future<void> requestPasswordReset(String email) {
    return _execute(() async {
      try {
        await _repository.sendPasswordResetEmail(email);
      } on FirebaseAuthException catch (error) {
        // Evita revelar si una dirección tiene una cuenta registrada.
        if (error.code != 'user-not-found') {
          rethrow;
        }
      }
    });
  }

  Future<void> signOut() {
    return _execute(() async {
      await _repository.signOut();
    });
  }
}
