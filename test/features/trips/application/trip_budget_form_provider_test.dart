import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';

void main() {
  test('guarda hospedaje y regreso en el estado temporal de Riverpod', () {
    final args = (
      sessionKey: Object(),
      vehicleId: null as String?,
      status: TripStatus.planned,
      distanceKm: 200.0 as double?,
      energyUnitPrice: 24.0 as double?,
      currencyCode: 'MXN',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final provider = tripFormProvider(args);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    final controller = container.read(provider.notifier);
    controller.setLodgingNights(2);
    controller.setLodgingNightlyRate(800);
    controller.setIncludeReturn(true);
    controller.setReturnDistanceKm(230);
    controller.setReturnTollsAmount(0);

    final state = container.read(provider);
    expect(state.lodgingNights, 2);
    expect(state.lodgingNightlyRate, 800);
    expect(state.includeReturn, isTrue);
    expect(state.returnDistanceKm, 230);
    expect(state.returnTollsAmount, 0);
    expect(state.energyUnitPrice, 24);

    controller.setIncludeReturn(false);
    expect(container.read(provider).includeReturn, isFalse);
    expect(container.read(provider).returnDistanceKm, 230);
  });
}
