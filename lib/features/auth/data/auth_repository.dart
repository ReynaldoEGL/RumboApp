import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _googleSignInInitialization;

  User? get currentUser => _auth.currentUser;

  Stream<User?> userChanges() {
    return _auth.userChanges();
  }

  Future<UserCredential> createEmailAccount({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'No existe una sesión activa para enviar la verificación.',
      );
    }

    await _auth.setLanguageCode('es');

    await user.sendEmailVerification();
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    await user.reload();

    return _auth.currentUser;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.setLanguageCode('es');

    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      return _auth.signInWithPopup(provider);
    }

    await _ensureGoogleSignInInitialized();

    // authenticate() devuelve una cuenta no nullable.
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // El ID token sí puede ser nulo.
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError('Google no proporcionó un token de autenticación.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _auth.signInWithCredential(credential);
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialization != null) {
      await _googleSignInInitialization;
      return;
    }

    final initialization = _googleSignIn.initialize();

    _googleSignInInitialization = initialization;

    try {
      await initialization;
    } catch (_) {
      _googleSignInInitialization = null;
      rethrow;
    }
  }

  Future<UserCredential> signInWithGitHub() async {
    final provider = GithubAuthProvider();

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    return _auth.signInWithProvider(provider);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
