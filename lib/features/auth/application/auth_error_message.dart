import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMessage {
  static String from(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo electrónico no tiene un formato válido.';

        case 'email-already-in-use':
          return 'Este correo ya está registrado. Intenta iniciar sesión.';

        case 'weak-password':
          return 'La contraseña es demasiado débil.';

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'El correo o la contraseña son incorrectos.';

        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';

        case 'too-many-requests':
          return 'Se realizaron demasiados intentos. Intenta más tarde.';

        case 'network-request-failed':
          return 'No hay conexión. Comprueba tu conexión a Internet.';

        case 'operation-not-allowed':
          return 'Este método de acceso todavía no está habilitado.';

        case 'account-exists-with-different-credential':
          return 'Este correo ya utiliza otro método de acceso.';

        case 'credential-already-in-use':
          return 'Esta cuenta externa ya está vinculada a otro usuario.';

        case 'popup-closed-by-user':
          return 'Se canceló la ventana de autenticación.';

        case 'requires-recent-login':
          return 'Vuelve a iniciar sesión para realizar esta operación.';

        default:
          return 'No fue posible completar la autenticación. Intenta nuevamente.';
      }
    }

    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}
