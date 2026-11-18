import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/auth/presentation/screens/login_screen.dart';
import 'package:rumboapp/features/auth/presentation/screens/email_verification_screen.dart';

import 'package:rumboapp/features/home/presentation/screens/home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  bool _requiresEmailVerification(User user) {
    final usesPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return usesPasswordProvider && !user.emailVerified;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserProvider);

    return authState.when(
      loading: () => const _AuthLoadingScreen(),

      error: (error, stackTrace) => _AuthErrorScreen(
        onRetry: () {
          ref.invalidate(authUserProvider);
        },
      ),

      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        if (_requiresEmailVerification(user)) {
          return EmailVerificationScreen(user: user);
        }

        return const HomeScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: colorScheme.primary,
              size: 42,
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(),

            const SizedBox(height: 16),

            const Text('Comprobando tu sesión...'),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _AuthErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: theme.colorScheme.error,
                  size: 48,
                ),

                const SizedBox(height: 18),

                Text(
                  'No pudimos comprobar tu sesión',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Comprueba tu conexión e intenta nuevamente.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 22),

                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
