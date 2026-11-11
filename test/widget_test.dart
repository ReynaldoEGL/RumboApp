import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/app/app.dart';
import 'package:rumboapp/core/providers/theme_mode_provider.dart';

void main() {
  group('Rumbo', () {
    testWidgets('Muestra correctamente la pantalla de inicio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RumboApp()));

      await tester.pumpAndSettle();

      expect(find.text('Rumbo'), findsOneWidget);
      expect(find.text('Hola, viajero'), findsOneWidget);

      expect(find.text('Tu próximo viaje, mejor organizado.'), findsOneWidget);

      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Rutas y casetas'), findsOneWidget);
      expect(find.text('Mis viajes'), findsOneWidget);
    });

    testWidgets('Permite navegar a la sección de documentos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RumboApp()));

      await tester.pumpAndSettle();

      final documentsTitle = find.text('Documentos').last;

      await tester.ensureVisible(documentsTitle);
      await tester.pumpAndSettle();

      await tester.tap(documentsTitle);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Este módulo forma parte del alcance de '
          'Rumbo y se desarrollará en una siguiente etapa.',
        ),
        findsOneWidget,
      );
    });

    test('Permite cambiar el tema mediante Riverpod', () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).toggle();

      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggle();

      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
