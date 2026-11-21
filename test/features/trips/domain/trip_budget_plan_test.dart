import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_plan.dart';

void main() {
  group('TripBudgetPlan', () {
    test('conserva cero noches y cero peajes de regreso', () {
      const plan = TripBudgetPlan(
        lodgingNights: 0,
        includeReturn: true,
        returnDistanceKm: 220,
        returnTollsAmount: 0,
      );

      final restored = TripBudgetPlan.fromMap(plan.toMap());

      expect(restored.lodgingNights, 0);
      expect(restored.includeReturn, isTrue);
      expect(restored.returnDistanceKm, 220);
      expect(restored.returnTollsAmount, 0);
    });

    test('conserva el precio y la cantidad de noches', () {
      const plan = TripBudgetPlan(lodgingNights: 2, lodgingNightlyRate: 950);

      final data = plan.toMap();
      final restored = TripBudgetPlan.fromMap(data);

      expect(restored.lodgingNights, 2);
      expect(restored.lodgingNightlyRate, 950);
      expect(restored.includeReturn, isFalse);
    });

    test('conserva valores del regreso aunque esté desactivado', () {
      const plan = TripBudgetPlan(
        includeReturn: false,
        returnDistanceKm: 150,
        returnTollsAmount: 60,
      );

      final restored = TripBudgetPlan.fromMap(plan.toMap());

      expect(restored.includeReturn, isFalse);
      expect(restored.returnDistanceKm, 150);
      expect(restored.returnTollsAmount, 60);
    });

    test('rechaza importes negativos y valores infinitos', () {
      expect(
        () => const TripBudgetPlan(lodgingNights: -1).toMap(),
        throwsFormatException,
      );
      expect(
        () => const TripBudgetPlan(lodgingNightlyRate: 0).toMap(),
        throwsFormatException,
      );
      expect(
        () => const TripBudgetPlan(returnDistanceKm: -5).toMap(),
        throwsFormatException,
      );
      expect(
        () => const TripBudgetPlan(returnTollsAmount: -1).toMap(),
        throwsFormatException,
      );
      expect(
        () => TripBudgetPlan(lodgingNightlyRate: double.infinity).toMap(),
        throwsFormatException,
      );
    });

    test('ignora campos opcionales inválidos al leer un registro', () {
      final plan = TripBudgetPlan.fromMap(<Object?, Object?>{
        'lodgingNights': 'desconocido',
        'lodgingNightlyRate': -8,
        'includeReturn': true,
        'returnDistanceKm': 0,
        'returnTollsAmount': 'sin dato',
      });

      expect(plan.lodgingNights, isNull);
      expect(plan.lodgingNightlyRate, isNull);
      expect(plan.includeReturn, isTrue);
      expect(plan.returnDistanceKm, isNull);
      expect(plan.returnTollsAmount, isNull);
    });
  });

  group('Trip: persistencia del presupuesto', () {
    Trip makeTrip({TripBudgetPlan? plan}) {
      return Trip(
        id: 'trip-test',
        title: 'Vacaciones',
        origin: 'Celaya',
        destination: 'Querétaro',
        departureDate: DateTime(2026, 12, 12),
        status: TripStatus.planned,
        currencyCode: 'MXN',
        createdAt: 100,
        updatedAt: 200,
        budgetPlan: plan,
      );
    }

    test('guarda y recupera presupuesto, incluso ceros', () {
      final trip = makeTrip(
        plan: const TripBudgetPlan(
          lodgingNights: 2,
          lodgingNightlyRate: 900,
          includeReturn: true,
          returnDistanceKm: 200,
          returnTollsAmount: 0,
        ),
      );

      final map = trip.toMap();
      expect(map['schemaVersion'], 2);

      final restored = Trip.fromMap(
        'trip-test',
        Map<Object?, Object?>.from(map),
      );

      final plan = restored.budgetPlan;
      expect(plan, isNotNull);
      expect(plan!.lodgingNights, 2);
      expect(plan.lodgingNightlyRate, 900);
      expect(plan.includeReturn, isTrue);
      expect(plan.returnDistanceKm, 200);
      expect(plan.returnTollsAmount, 0);
      expect(restored.budgetEstimate.lodging.cost, 1800);
      expect(restored.budgetEstimate.isPartial, isTrue);
    });

    test('los viajes antiguos siguen abriendo sin presupuesto', () {
      final data = makeTrip().toMap();
      expect(data['schemaVersion'], 1);
      expect(data.containsKey('budgetPlan'), isFalse);

      final restored = Trip.fromMap(
        'trip-antiguo',
        Map<Object?, Object?>.from(data),
      );

      expect(restored.budgetPlan, isNull);
    });

    test('no desaparece un viaje por presupuesto mal formado', () {
      final data = makeTrip().toMap();
      data['budgetPlan'] = 'valor inesperado';

      final restored = Trip.fromMap(
        'trip-antiguo',
        Map<Object?, Object?>.from(data),
      );

      expect(restored.budgetPlan, isNull);
      expect(restored.title, 'Vacaciones');
    });
  });
}
