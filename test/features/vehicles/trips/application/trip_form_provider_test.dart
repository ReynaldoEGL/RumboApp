import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';

void main() {
  group('TripFormController', () {
    late ProviderContainer container;

    final args = (
      sessionKey: Object(),
      vehicleId: 'vehicle-1',
      status: TripStatus.planned,
      distanceKm: 250.0,
      energyUnitPrice: 25.0,
      currencyCode: 'MXN',
    );

    late NotifierProvider<TripFormController, TripFormSelections> provider;

    setUp(() {
      container = ProviderContainer();
      provider = tripFormProvider(args);
      container.listen(provider, (previous, next) {});
    });

    tearDown(() {
      container.dispose();
    });

    test('inicializa los datos del formulario', () {
      final state = container.read(provider);

      expect(state.vehicleId, 'vehicle-1');
      expect(state.status, TripStatus.planned);
      expect(state.distanceKm, 250);
      expect(state.energyUnitPrice, 25);
      expect(state.currencyCode, 'MXN');
    });

    test('permite seleccionar un vehículo diferente', () {
      container.read(provider.notifier).selectVehicle('vehicle-2');

      expect(container.read(provider).vehicleId, 'vehicle-2');
    });

    test('permite quitar el vehículo asignado', () {
      container.read(provider.notifier).clearVehicle();

      expect(container.read(provider).vehicleId, isNull);
    });

    test('permite actualizar el estado', () {
      container.read(provider.notifier).setStatus(TripStatus.inProgress);

      expect(container.read(provider).status, TripStatus.inProgress);
    });

    test('actualiza la distancia', () {
      container.read(provider.notifier).setDistanceKm(400);

      expect(container.read(provider).distanceKm, 400);
    });

    test('limpia la distancia si no es válida', () {
      container.read(provider.notifier).setDistanceKm(0);

      expect(container.read(provider).distanceKm, isNull);
    });

    test('actualiza el precio energético', () {
      container.read(provider.notifier).setEnergyUnitPrice(28.5);

      expect(container.read(provider).energyUnitPrice, 28.5);
    });

    test('actualiza el código de moneda válido', () {
      container.read(provider.notifier).setCurrencyCode('usd');

      expect(container.read(provider).currencyCode, 'USD');
    });

    test('ignora los códigos de moneda inválidos', () {
      container.read(provider.notifier).setCurrencyCode('US');

      expect(container.read(provider).currencyCode, 'MXN');
    });

    test('mantiene separados dos formularios', () {
      final secondArgs = (
        sessionKey: Object(),
        vehicleId: null,
        status: TripStatus.completed,
        distanceKm: null,
        energyUnitPrice: null,
        currencyCode: 'USD',
      );

      final secondProvider = tripFormProvider(secondArgs);

      container.listen(secondProvider, (previous, next) {});

      container.read(provider.notifier).setDistanceKm(500);

      expect(container.read(provider).distanceKm, 500);
      expect(container.read(secondProvider).distanceKm, isNull);
      expect(container.read(secondProvider).currencyCode, 'USD');
      expect(container.read(secondProvider).status, TripStatus.completed);
    });
  });
}
