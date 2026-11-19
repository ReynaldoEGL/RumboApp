import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/application/vehicle_form_selection_provider.dart';

void main() {
  group('VehicleFormSelectionsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('inicializa las selecciones recibidas', () {
      final args = (
        vehicleType: 'car',
        fuelType: 'gasoline',
        sessionKey: Object(),
      );

      final provider = vehicleFormSelectionsProvider(args);

      final subscription = container.listen(provider, (_, _) {});

      addTearDown(subscription.close);

      final selections = container.read(provider);

      expect(selections.vehicleType, 'car');
      expect(selections.fuelType, 'gasoline');
      expect(selections.isSaving, false);
    });

    test('permite iniciar un formulario sin selecciones', () {
      final args = (vehicleType: null, fuelType: null, sessionKey: Object());

      final provider = vehicleFormSelectionsProvider(args);

      final subscription = container.listen(provider, (_, _) {});

      addTearDown(subscription.close);

      final selections = container.read(provider);

      expect(selections.vehicleType, isNull);
      expect(selections.fuelType, isNull);
      expect(selections.isSaving, false);
    });

    test('actualiza el tipo de vehículo', () {
      final args = (
        vehicleType: 'car',
        fuelType: 'gasoline',
        sessionKey: Object(),
      );

      final provider = vehicleFormSelectionsProvider(args);

      final subscription = container.listen(provider, (_, _) {});

      addTearDown(subscription.close);

      container.read(provider.notifier).setVehicleType('motorcycle');

      expect(container.read(provider).vehicleType, 'motorcycle');

      // El combustible no debe cambiar al modificar el vehículo.
      expect(container.read(provider).fuelType, 'gasoline');
    });

    test('actualiza el tipo de combustible', () {
      final args = (
        vehicleType: 'car',
        fuelType: 'gasoline',
        sessionKey: Object(),
      );

      final provider = vehicleFormSelectionsProvider(args);

      final subscription = container.listen(provider, (_, _) {});

      addTearDown(subscription.close);

      container.read(provider.notifier).setFuelType('electric');

      expect(container.read(provider).fuelType, 'electric');

      // El tipo de vehículo debe mantenerse.
      expect(container.read(provider).vehicleType, 'car');
    });

    test('actualiza el indicador de guardado', () {
      final args = (
        vehicleType: 'car',
        fuelType: 'gasoline',
        sessionKey: Object(),
      );

      final provider = vehicleFormSelectionsProvider(args);

      final subscription = container.listen(provider, (_, _) {});

      addTearDown(subscription.close);

      final controller = container.read(provider.notifier);

      controller.setSaving(true);

      expect(container.read(provider).isSaving, true);

      controller.setSaving(false);

      expect(container.read(provider).isSaving, false);
    });

    test('mantiene independientes dos formularios', () {
      final firstArgs = (
        vehicleType: 'car',
        fuelType: 'gasoline',
        sessionKey: Object(),
      );

      final secondArgs = (
        vehicleType: 'motorcycle',
        fuelType: 'electric',
        sessionKey: Object(),
      );

      final firstProvider = vehicleFormSelectionsProvider(firstArgs);

      final secondProvider = vehicleFormSelectionsProvider(secondArgs);

      final firstSubscription = container.listen(firstProvider, (_, _) {});

      final secondSubscription = container.listen(secondProvider, (_, _) {});

      addTearDown(firstSubscription.close);
      addTearDown(secondSubscription.close);

      expect(container.read(firstProvider).vehicleType, 'car');

      expect(container.read(firstProvider).fuelType, 'gasoline');

      expect(container.read(secondProvider).vehicleType, 'motorcycle');

      expect(container.read(secondProvider).fuelType, 'electric');

      // Modificar el primer formulario no debe alterar el segundo.
      container.read(firstProvider.notifier).setFuelType('diesel');

      expect(container.read(firstProvider).fuelType, 'diesel');

      expect(container.read(secondProvider).fuelType, 'electric');

      // El estado de guardado también es independiente.
      container.read(firstProvider.notifier).setSaving(true);

      expect(container.read(firstProvider).isSaving, true);

      expect(container.read(secondProvider).isSaving, false);
    });
  });
}
