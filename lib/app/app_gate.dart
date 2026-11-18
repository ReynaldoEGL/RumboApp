import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/core/providers/app_settings_provider.dart';
import 'package:rumboapp/core/widgets/rumbo_brand.dart';

import 'package:rumboapp/features/auth/presentation/auth_gate.dart';

import 'package:rumboapp/features/onboarding/presentation/screens/onboarding_screen.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return settings.when(
      loading: () => const _StartupScreen(),

      error: (error, stackTrace) => _StartupErrorScreen(
        onRetry: () {
          ref.invalidate(appSettingsProvider);
        },
      ),

      data: (appSettings) {
        if (!appSettings.onboardingCompleted) {
          return const OnboardingScreen();
        }

        return const AuthGate();
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RumboBrand(iconSize: 64, textSize: 30),

            const SizedBox(height: 28),

            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RumboBrand(),

                const SizedBox(height: 28),

                Icon(
                  Icons.settings_outlined,
                  color: colorScheme.error,
                  size: 46,
                ),

                const SizedBox(height: 18),

                Text(
                  'No pudimos iniciar Rumbo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Ocurrió un problema al recuperar las '
                  'preferencias locales de la aplicación.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 22),

                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Intentar nuevamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
