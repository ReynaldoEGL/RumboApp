import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';

void main() {
  group('Trip energy estimation', () {
    test('calcula combustible para gasolina', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'gasoline',
        distanceKm: 300,
        energyUnitPrice: 25,
        fuelConsumptionKmPerLiter: 15,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNotNull);
      expect(estimate!.quantity, 20);
      expect(estimate.cost, 500);
      expect(estimate.unit, 'L');
      expect(estimate.isPartial, isFalse);
    });

    test('calcula combustible para diésel', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'diesel',
        distanceKm: 450,
        energyUnitPrice: 26,
        fuelConsumptionKmPerLiter: 18,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNotNull);
      expect(estimate!.quantity, 25);
      expect(estimate.cost, 650);
    });

    test('calcula energía para vehículo eléctrico', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'electric',
        distanceKm: 200,
        energyUnitPrice: 3,
        fuelConsumptionKmPerLiter: null,
        electricConsumptionKwhPer100Km: 16,
      );

      expect(estimate, isNotNull);
      expect(estimate!.quantity, 32);
      expect(estimate.cost, 96);
      expect(estimate.unit, 'kWh');
    });

    test('marca la estimación híbrida como parcial', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'hybrid',
        distanceKm: 100,
        energyUnitPrice: 25,
        fuelConsumptionKmPerLiter: 20,
        electricConsumptionKwhPer100Km: 14,
      );

      expect(estimate, isNotNull);
      expect(estimate!.quantity, 5);
      expect(estimate.cost, 125);
      expect(estimate.isPartial, isTrue);
    });

    test('no calcula cuando el combustible es otro', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'other',
        distanceKm: 100,
        energyUnitPrice: 25,
        fuelConsumptionKmPerLiter: 15,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNull);
    });

    test('no calcula con distancia inválida', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'gasoline',
        distanceKm: 0,
        energyUnitPrice: 25,
        fuelConsumptionKmPerLiter: 15,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNull);
    });

    test('no calcula sin precio energético', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'gasoline',
        distanceKm: 300,
        energyUnitPrice: null,
        fuelConsumptionKmPerLiter: 15,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNull);
    });

    test('no calcula sin consumo registrado', () {
      final estimate = calculateTripEnergyEstimate(
        fuelType: 'electric',
        distanceKm: 300,
        energyUnitPrice: 3,
        fuelConsumptionKmPerLiter: null,
        electricConsumptionKwhPer100Km: null,
      );

      expect(estimate, isNull);
    });
  });
}
