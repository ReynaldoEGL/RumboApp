import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/application/vehicle_catalog_form_selection_provider.dart';

void main() {
  group('VehicleCatalogFormSelectionController', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness();
    });

    tearDown(() {
      harness.dispose();
    });

    test('inicializa las selecciones existentes', () {
      final selections = harness.container.read(harness.provider);

      expect(selections.brandId, 'toyota');
      expect(selections.modelId, 'toyota-corolla');
      expect(selections.countryCode, 'MX');
      expect(selections.regionCode, 'MX-GUA');
    });

    test('cambiar la marca limpia el modelo anterior', () {
      harness.container.read(harness.provider.notifier).selectBrand('honda');

      final selections = harness.container.read(harness.provider);

      expect(selections.brandId, 'honda');
      expect(selections.modelId, isNull);
      expect(selections.countryCode, 'MX');
      expect(selections.regionCode, 'MX-GUA');
    });

    test('limpiar la marca también limpia el modelo', () {
      harness.container.read(harness.provider.notifier).clearBrand();

      final selections = harness.container.read(harness.provider);

      expect(selections.brandId, isNull);
      expect(selections.modelId, isNull);
    });

    test('seleccionar un modelo conserva la marca', () {
      harness.container
          .read(harness.provider.notifier)
          .selectModel('toyota-rav4');

      final selections = harness.container.read(harness.provider);

      expect(selections.brandId, 'toyota');
      expect(selections.modelId, 'toyota-rav4');
    });

    test('limpiar el modelo conserva la marca', () {
      harness.container.read(harness.provider.notifier).clearModel();

      final selections = harness.container.read(harness.provider);

      expect(selections.brandId, 'toyota');
      expect(selections.modelId, isNull);
    });

    test('cambiar el país limpia la región anterior', () {
      harness.container.read(harness.provider.notifier).selectCountry('US');

      final selections = harness.container.read(harness.provider);

      expect(selections.countryCode, 'US');
      expect(selections.regionCode, isNull);
    });

    test('seleccionar el mismo país conserva la región', () {
      harness.container.read(harness.provider.notifier).selectCountry('MX');

      final selections = harness.container.read(harness.provider);

      expect(selections.countryCode, 'MX');
      expect(selections.regionCode, 'MX-GUA');
    });

    test('limpiar el país también limpia la región', () {
      harness.container.read(harness.provider.notifier).clearCountry();

      final selections = harness.container.read(harness.provider);

      expect(selections.countryCode, isNull);
      expect(selections.regionCode, isNull);
    });

    test('seleccionar una región conserva el país', () {
      harness.container.read(harness.provider.notifier).selectRegion('MX-QUE');

      final selections = harness.container.read(harness.provider);

      expect(selections.countryCode, 'MX');
      expect(selections.regionCode, 'MX-QUE');
    });

    test('los formularios mantienen selecciones independientes', () {
      final secondArgs = (
        sessionKey: Object(),
        brandId: 'honda',
        modelId: 'honda-civic',
        countryCode: 'US',
        regionCode: null,
      );

      final secondProvider = vehicleCatalogFormSelectionsProvider(secondArgs);

      harness.container.listen(secondProvider, (previous, next) {});

      harness.container.read(harness.provider.notifier).selectBrand('mazda');

      final firstSelections = harness.container.read(harness.provider);
      final secondSelections = harness.container.read(secondProvider);

      expect(firstSelections.brandId, 'mazda');
      expect(firstSelections.modelId, isNull);

      expect(secondSelections.brandId, 'honda');
      expect(secondSelections.modelId, 'honda-civic');
      expect(secondSelections.countryCode, 'US');
    });
  });
}

class _Harness {
  _Harness() {
    container.listen(provider, (previous, next) {});
  }

  final container = ProviderContainer();

  final args = (
    sessionKey: Object(),
    brandId: 'toyota',
    modelId: 'toyota-corolla',
    countryCode: 'MX',
    regionCode: 'MX-GUA',
  );

  late final provider = vehicleCatalogFormSelectionsProvider(args);

  void dispose() {
    container.dispose();
  }
}
