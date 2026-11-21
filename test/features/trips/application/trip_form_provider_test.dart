import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';

void main() {
  group('TripFormController', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness();
    });

    tearDown(() {
      harness.dispose();
    });

    test('inicializa los datos del formulario', () {
      final state = harness.container.read(harness.provider);

      expect(state.vehicleId, 'vehicle-1');
      expect(state.status, TripStatus.planned);
      expect(state.distanceKm, 250);
      expect(state.energyUnitPrice, 25);
      expect(state.currencyCode, 'MXN');
    });

    test('permite seleccionar un vehículo diferente', () {
      harness.container
          .read(harness.provider.notifier)
          .selectVehicle('vehicle-2');

      expect(harness.container.read(harness.provider).vehicleId, 'vehicle-2');
    });

    test('permite quitar el vehículo asignado', () {
      harness.container.read(harness.provider.notifier).clearVehicle();

      expect(harness.container.read(harness.provider).vehicleId, isNull);
    });

    test('permite actualizar el estado', () {
      harness.container
          .read(harness.provider.notifier)
          .setStatus(TripStatus.inProgress);

      expect(
        harness.container.read(harness.provider).status,
        TripStatus.inProgress,
      );
    });

    test('actualiza la distancia', () {
      harness.container.read(harness.provider.notifier).setDistanceKm(400);

      expect(harness.container.read(harness.provider).distanceKm, 400);
    });

    test('limpia la distancia si no es válida', () {
      harness.container.read(harness.provider.notifier).setDistanceKm(0);

      expect(harness.container.read(harness.provider).distanceKm, isNull);
    });

    test('actualiza el precio energético', () {
      harness.container
          .read(harness.provider.notifier)
          .setEnergyUnitPrice(28.5);

      expect(harness.container.read(harness.provider).energyUnitPrice, 28.5);
    });

    test('actualiza el código de moneda válido', () {
      harness.container.read(harness.provider.notifier).setCurrencyCode('usd');

      expect(harness.container.read(harness.provider).currencyCode, 'USD');
    });

    test('ignora los códigos de moneda inválidos', () {
      harness.container.read(harness.provider.notifier).setCurrencyCode('US');

      expect(harness.container.read(harness.provider).currencyCode, 'MXN');
    });

    test('mantiene separados dos formularios', () {
      final secondArgs = (
        sessionKey: Object(),
        vehicleId: null,
        status: TripStatus.completed,
        distanceKm: null,
        energyUnitPrice: null,
        currencyCode: 'USD',
        budgetPlan: null,
      );

      final secondProvider = tripFormProvider(secondArgs);

      harness.container.listen(secondProvider, (previous, next) {});

      harness.container.read(harness.provider.notifier).setDistanceKm(500);

      expect(harness.container.read(harness.provider).distanceKm, 500);

      expect(harness.container.read(secondProvider).distanceKm, isNull);

      expect(harness.container.read(secondProvider).currencyCode, 'USD');

      expect(
        harness.container.read(secondProvider).status,
        TripStatus.completed,
      );
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
    vehicleId: 'vehicle-1',
    status: TripStatus.planned,
    distanceKm: 250.0,
    energyUnitPrice: 25.0,
    currencyCode: 'MXN',
    budgetPlan: null,
  );

  late final provider = tripFormProvider(args);

  void dispose() {
    container.dispose();
  }
}
