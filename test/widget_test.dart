import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/app/app.dart';

import 'package:rumboapp/core/providers/app_settings_provider.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

class _MemoryAppSettingsController extends AppSettingsController {
  final AppSettings initialSettings;

  _MemoryAppSettingsController(this.initialSettings);

  @override
  Future<AppSettings> build() async {
    return initialSettings;
  }

  @override
  Future<void> completeOnboarding() async {
    final currentSettings = state.requireValue;

    state = AsyncData(currentSettings.copyWith(onboardingCompleted: true));
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final currentSettings = state.requireValue;

    state = AsyncData(currentSettings.copyWith(themeMode: themeMode));
  }
}

class _MemoryAuthController extends AuthController {
  @override
  Future<void> build() async {
    // No inicializa Firebase durante las pruebas de interfaz.
  }
}

void main() {
  Future<ProviderContainer> createTestContainer({
    bool onboardingCompleted = false,
    ThemeMode themeMode = ThemeMode.system,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          () => _MemoryAppSettingsController(
            AppSettings(
              onboardingCompleted: onboardingCompleted,
              themeMode: themeMode,
            ),
          ),
        ),

        authUserProvider.overrideWith((ref) => Stream<User?>.value(null)),

        authControllerProvider.overrideWith(_MemoryAuthController.new),
      ],
    );

    await container.read(appSettingsProvider.future);

    return container;
  }

  Future<void> launchApp(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RumboApp()),
    );

    await tester.pumpAndSettle();
  }

  group('Rumbo - Onboarding', () {
    testWidgets('Muestra onboarding al iniciar por primera vez', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer();

      addTearDown(container.dispose);

      await launchApp(tester, container);

      expect(find.text('Tus documentos, siempre en orden.'), findsOneWidget);

      expect(find.text('Omitir'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('Permite avanzar a la segunda página', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer();

      addTearDown(container.dispose);

      await launchApp(tester, container);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Planea mejor tus recorridos.'), findsOneWidget);
    });

    testWidgets('Permite omitir onboarding y mostrar login', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer();

      addTearDown(container.dispose);

      await launchApp(tester, container);

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión'), findsOneWidget);

      expect(find.text('Tus documentos, siempre en orden.'), findsNothing);
    });

    testWidgets('Permite completar las tres páginas', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer();

      addTearDown(container.dispose);

      await launchApp(tester, container);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Planea mejor tus recorridos.'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Calcula cuánto puede costar tu viaje.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión'), findsOneWidget);
    });

    testWidgets('No muestra onboarding si ya fue completado', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      expect(find.text('Inicia sesión'), findsOneWidget);

      expect(find.text('Tus documentos, siempre en orden.'), findsNothing);
    });
  });

  group('Rumbo - Autenticación', () {
    testWidgets('Muestra login cuando no existe una sesión', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      expect(find.text('Inicia sesión'), findsOneWidget);

      expect(find.text('Correo electrónico'), findsOneWidget);

      expect(find.text('Contraseña'), findsOneWidget);

      expect(find.text('Continuar con Google'), findsOneWidget);

      expect(find.text('Continuar con GitHub'), findsOneWidget);
    });

    testWidgets('Permite abrir el registro', (WidgetTester tester) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      final registerButton = find.text('Regístrate');

      // Desplazar el formulario hasta que el botón sea visible.
      await tester.ensureVisible(registerButton);

      await tester.pumpAndSettle();

      // Comprobar que realmente se encuentra dentro de la pantalla.
      expect(registerButton, findsOneWidget);

      // Ejecutar la interacción.
      await tester.tap(registerButton);

      await tester.pumpAndSettle();

      expect(find.text('Crea tu cuenta'), findsOneWidget);

      expect(find.text('Confirmar contraseña'), findsOneWidget);
    });

    testWidgets('Permite abrir la recuperación de contraseña', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      await tester.tap(find.text('¿Olvidaste tu contraseña?'));

      await tester.pumpAndSettle();

      expect(find.text('Recupera tu contraseña'), findsOneWidget);
    });
  });

  group('Rumbo - Preferencias', () {
    testWidgets('Permite cambiar el tema desde login', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      expect(find.byTooltip('Cambiar a tema oscuro'), findsOneWidget);

      await tester.tap(find.byTooltip('Cambiar a tema oscuro'));

      await tester.pumpAndSettle();

      expect(find.byTooltip('Cambiar a tema claro'), findsOneWidget);
    });
  });
}
