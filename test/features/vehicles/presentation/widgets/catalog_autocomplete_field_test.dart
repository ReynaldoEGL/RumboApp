import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/domain/catalogs/vehicle_brand.dart';

import 'package:rumboapp/features/vehicles/presentation/widgets/catalog_autocomplete_field.dart';

void main() {
  group('CatalogAutocompleteField', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('encuentra opciones mediante alias', (
      WidgetTester tester,
    ) async {
      final brands = [
        const VehicleBrand(
          id: 'volkswagen',
          name: 'Volkswagen',
          vehicleTypes: ['car'],
          aliases: ['VW'],
        ),
        const VehicleBrand(
          id: 'toyota',
          name: 'Toyota',
          vehicleTypes: ['car'],
          aliases: [],
        ),
      ];

      VehicleBrand? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CatalogAutocompleteField<VehicleBrand>(
                controller: controller,
                focusNode: focusNode,
                label: 'Marca',
                options: brands,
                displayStringForOption: (brand) => brand.name,
                aliasesForOption: (brand) => [brand.id, ...brand.aliases],
                onSelected: (brand) {
                  selected = brand;
                },
                onChanged: (_) {},
                validator: (_) => null,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'VW');

      await tester.pumpAndSettle();

      expect(find.text('Volkswagen'), findsOneWidget);

      await tester.tap(find.text('Volkswagen'));

      await tester.pumpAndSettle();

      expect(selected?.id, 'volkswagen');
      expect(controller.text, 'Volkswagen');
    });

    testWidgets('permite capturar un valor que no está en el catálogo', (
      WidgetTester tester,
    ) async {
      final brands = [
        const VehicleBrand(id: 'toyota', name: 'Toyota', vehicleTypes: ['car']),
      ];

      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CatalogAutocompleteField<VehicleBrand>(
                controller: controller,
                focusNode: focusNode,
                label: 'Marca',
                options: brands,
                displayStringForOption: (brand) => brand.name,
                aliasesForOption: (brand) => brand.aliases,
                onSelected: (_) {},
                onChanged: (value) {
                  changedValue = value;
                },
                validator: (_) => null,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Marca Personalizada');

      await tester.pumpAndSettle();

      expect(controller.text, 'Marca Personalizada');
      expect(changedValue, 'Marca Personalizada');
    });

    testWidgets('busca ignorando acentos y mayúsculas', (
      WidgetTester tester,
    ) async {
      final brands = [
        const VehicleBrand(
          id: 'citroen',
          name: 'Citroën',
          vehicleTypes: ['car'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CatalogAutocompleteField<VehicleBrand>(
                controller: controller,
                focusNode: focusNode,
                label: 'Marca',
                options: brands,
                displayStringForOption: (brand) => brand.name,
                aliasesForOption: (brand) => brand.aliases,
                onSelected: (_) {},
                onChanged: (_) {},
                validator: (_) => null,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'citroen');

      await tester.pumpAndSettle();

      expect(find.text('Citroën'), findsOneWidget);
    });
  });
}
