import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

void main() {
  group('Vehicle model', () {
    test('Convierte un vehículo a mapa y permite reconstruirlo', () {
      final insuranceDate = DateTime(2027, 6, 30);
      final verificationDate = DateTime(2027, 12, 31);

      final vehicle = Vehicle(
        id: 'vehicle-123',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2022,
        vehicleType: 'car',
        fuelType: 'gasoline',
        averageConsumption: 14.5,
        consumptionUnit: 'km/L',
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        plateLastDigit: 5,
        insuranceCompany: 'Aseguradora de prueba',
        insuranceValidUntil: insuranceDate,
        verificationHologram: '0',
        verificationValidUntil: verificationDate,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final Map<Object?, Object?> serialized = Map<Object?, Object?>.from(
        vehicle.toMap(),
      );

      final restoredVehicle = Vehicle.fromMap('vehicle-123', serialized);

      expect(restoredVehicle.id, 'vehicle-123');
      expect(restoredVehicle.brand, 'Toyota');
      expect(restoredVehicle.model, 'Corolla');
      expect(restoredVehicle.year, 2022);

      expect(restoredVehicle.fuelType, 'gasoline');
      expect(restoredVehicle.averageConsumption, 14.5);
      expect(restoredVehicle.consumptionUnit, 'km/L');

      expect(restoredVehicle.registrationCountry, 'México');
      expect(restoredVehicle.registrationRegion, 'Guanajuato');

      expect(restoredVehicle.plateLastDigit, 5);

      expect(restoredVehicle.insuranceValidUntil, insuranceDate);

      expect(restoredVehicle.verificationValidUntil, verificationDate);
    });

    test('No almacena campos opcionales vacíos', () {
      final vehicle = Vehicle(
        id: '',
        brand: 'Honda',
        model: 'Civic',
        year: 2021,
        vehicleType: 'car',
        fuelType: 'gasoline',
        averageConsumption: null,
        consumptionUnit: 'km/L',
        registrationCountry: 'México',
        registrationRegion: 'Querétaro',
        plateLastDigit: null,
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final data = vehicle.toMap();

      expect(data.containsKey('averageConsumption'), false);
      expect(data.containsKey('plateLastDigit'), false);
      expect(data.containsKey('insuranceCompany'), false);
      expect(data.containsKey('insuranceValidUntil'), false);
      expect(data.containsKey('verificationHologram'), false);
    });

    test('Conserva la unidad de consumo de un vehículo eléctrico', () {
      final vehicle = Vehicle(
        id: '',
        brand: 'Tesla',
        model: 'Model 3',
        year: 2024,
        vehicleType: 'car',
        fuelType: 'electric',
        averageConsumption: 15.2,
        consumptionUnit: 'kWh/100 km',
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        plateLastDigit: null,
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final restored = Vehicle.fromMap(
        'vehicle-electric',
        Map<Object?, Object?>.from(vehicle.toMap()),
      );

      expect(restored.fuelType, 'electric');
      expect(restored.consumptionUnit, 'kWh/100 km');
      expect(restored.averageConsumption, 15.2);
    });
  });
}
