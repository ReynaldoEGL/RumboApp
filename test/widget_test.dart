import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/app/app.dart';
import 'package:rumboapp/core/providers/app_settings_provider.dart';

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
      ],
    );

    // Esperar a que Riverpod termine de recuperar las preferencias.
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
    testWidgets('Muestra el onboarding al iniciar por primera vez', (
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

    testWidgets('Permite omitir el onboarding y entrar al inicio', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer();

      addTearDown(container.dispose);

      await launchApp(tester, container);

      await tester.tap(find.text('Omitir'));

      await tester.pumpAndSettle();

      expect(find.text('Hola, viajero'), findsOneWidget);

      expect(find.text('Tu próximo viaje, mejor organizado.'), findsOneWidget);

      expect(find.text('Tus documentos, siempre en orden.'), findsNothing);
    });

    testWidgets('Permite completar las tres páginas del onboarding', (
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

      expect(find.text('Hola, viajero'), findsOneWidget);
    });

    testWidgets('No muestra onboarding si ya fue completado', (
      WidgetTester tester,
    ) async {
      final container = await createTestContainer(onboardingCompleted: true);

      addTearDown(container.dispose);

      await launchApp(tester, container);

      expect(find.text('Hola, viajero'), findsOneWidget);

      expect(find.text('Tus documentos, siempre en orden.'), findsNothing);
    });
  });

  group('Rumbo - Preferencias', () {
    testWidgets('Permite cambiar el tema desde la pantalla principal', (
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
