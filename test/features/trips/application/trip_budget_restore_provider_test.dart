import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_plan.dart';

void main() {
  test('restaura los datos de hospedaje y regreso al editar un viaje', () {
    final args = (
      sessionKey: Object(),
      vehicleId: null as String?,
      status: TripStatus.planned,
      distanceKm: 180.0 as double?,
      energyUnitPrice: 24.0 as double?,
      currencyCode: 'MXN',
      budgetPlan: const TripBudgetPlan(
        lodgingNights: 3,
        lodgingNightlyRate: 700,
        includeReturn: true,
        returnDistanceKm: 185,
        returnTollsAmount: 0,
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = tripFormProvider(args);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    final initial = container.read(provider);
    expect(initial.lodgingNights, 3);
    expect(initial.lodgingNightlyRate, 700);
    expect(initial.includeReturn, isTrue);
    expect(initial.returnDistanceKm, 185);
    expect(initial.returnTollsAmount, 0);

    container.read(provider.notifier).setLodgingNightlyRate(850);
    expect(container.read(provider).lodgingNightlyRate, 850);
  });
}
