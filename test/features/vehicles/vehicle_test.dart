import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

void main() {
  group('Vehicle model - Consumo', () {
    test('Conserva el rendimiento de un vehículo de gasolina', () {
      final vehicle = Vehicle(
        id: 'vehicle-1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2022,
        vehicleType: 'car',
        fuelType: 'gasoline',
        fuelConsumptionKmPerLiter: 14.5,
        electricConsumptionKwhPer100Km: null,
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        plateEnding: '123-E',
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final restored = Vehicle.fromMap(
        vehicle.id,
        Map<Object?, Object?>.from(vehicle.toMap()),
      );

      expect(restored.fuelConsumptionKmPerLiter, 14.5);
      expect(restored.electricConsumptionKwhPer100Km, isNull);
    });

    test('Conserva ambos consumos para un híbrido enchufable', () {
      final vehicle = Vehicle(
        id: 'vehicle-2',
        brand: 'Toyota',
        model: 'Prius',
        year: 2024,
        vehicleType: 'car',
        fuelType: 'hybrid',
        fuelConsumptionKmPerLiter: 20.0,
        electricConsumptionKwhPer100Km: 15.5,
        registrationCountry: 'México',
        registrationRegion: 'Querétaro',
        plateEnding: 'ABC-8',
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final restored = Vehicle.fromMap(
        vehicle.id,
        Map<Object?, Object?>.from(vehicle.toMap()),
      );

      expect(restored.isHybrid, isTrue);
      expect(restored.fuelConsumptionKmPerLiter, 20.0);
      expect(restored.electricConsumptionKwhPer100Km, 15.5);
    });

    test('Conserva el consumo de un vehículo eléctrico', () {
      final vehicle = Vehicle(
        id: 'vehicle-3',
        brand: 'Tesla',
        model: 'Model 3',
        year: 2024,
        vehicleType: 'car',
        fuelType: 'electric',
        fuelConsumptionKmPerLiter: null,
        electricConsumptionKwhPer100Km: 16.8,
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        plateEnding: null,
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final restored = Vehicle.fromMap(
        vehicle.id,
        Map<Object?, Object?>.from(vehicle.toMap()),
      );

      expect(restored.isElectric, isTrue);
      expect(restored.electricConsumptionKwhPer100Km, 16.8);
      expect(restored.fuelConsumptionKmPerLiter, isNull);
    });

    test('Mantiene los datos antiguos de consumo km/L', () {
      final oldData = <Object?, Object?>{
        'brand': 'Honda',
        'model': 'Civic',
        'year': 2021,
        'vehicleType': 'car',
        'fuelType': 'gasoline',
        'averageConsumption': 13.5,
        'consumptionUnit': 'km/L',
        'registrationCountry': 'México',
        'registrationRegion': 'Guanajuato',
        'plateLastDigit': 5,
        'createdAt': 1770000000000,
        'updatedAt': 1770000000000,
      };

      final restored = Vehicle.fromMap('old-vehicle', oldData);

      expect(restored.fuelConsumptionKmPerLiter, 13.5);
      expect(restored.plateEnding, '5');
      expect(restored.plateLastNumericDigit, 5);
    });

    test('Mantiene los datos antiguos de consumo eléctrico', () {
      final oldData = <Object?, Object?>{
        'brand': 'Tesla',
        'model': 'Model 3',
        'year': 2023,
        'vehicleType': 'car',
        'fuelType': 'electric',
        'averageConsumption': 17.2,
        'consumptionUnit': 'kWh/100 km',
        'registrationCountry': 'México',
        'registrationRegion': 'Querétaro',
        'createdAt': 1770000000000,
        'updatedAt': 1770000000000,
      };

      final restored = Vehicle.fromMap('old-electric', oldData);

      expect(restored.electricConsumptionKwhPer100Km, 17.2);
      expect(restored.fuelConsumptionKmPerLiter, isNull);
    });

    test(
      'No escribe los campos antiguos al guardar un vehículo actualizado',
      () {
        final vehicle = Vehicle(
          id: 'vehicle-4',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2022,
          vehicleType: 'car',
          fuelType: 'gasoline',
          fuelConsumptionKmPerLiter: 14.5,
          electricConsumptionKwhPer100Km: null,
          registrationCountry: 'México',
          registrationRegion: 'Guanajuato',
          plateEnding: '123-E',
          insuranceCompany: null,
          insuranceValidUntil: null,
          verificationHologram: null,
          verificationValidUntil: null,
          createdAt: 1770000000000,
          updatedAt: 1770000000000,
        );

        final data = vehicle.toMap();

        expect(data['schemaVersion'], 3);
        expect(data.containsKey('averageConsumption'), isFalse);
        expect(data.containsKey('consumptionUnit'), isFalse);
        expect(data.containsKey('plateLastDigit'), isFalse);
      },
    );
  });

  group('Vehicle model - Catálogos', () {
    test('Guarda y recupera los identificadores de catálogo', () {
      final vehicle = Vehicle(
        id: 'vehicle-catalog-1',
        brand: 'Toyota',
        model: 'Corolla',
        year: 2022,
        brandId: 'toyota',
        modelId: 'toyota-corolla',
        vehicleType: 'car',
        fuelType: 'gasoline',
        fuelConsumptionKmPerLiter: 14.5,
        electricConsumptionKwhPer100Km: null,
        registrationCountry: 'México',
        registrationRegion: 'Guanajuato',
        registrationCountryCode: 'MX',
        registrationRegionCode: 'MX-GUA',
        plateEnding: null,
        insuranceCompany: null,
        insuranceValidUntil: null,
        verificationHologram: null,
        verificationValidUntil: null,
        createdAt: 1770000000000,
        updatedAt: 1770000000000,
      );

      final data = vehicle.toMap();
      final restored = Vehicle.fromMap(
        vehicle.id,
        Map<Object?, Object?>.from(data),
      );

      expect(data['schemaVersion'], 3);
      expect(restored.brandId, 'toyota');
      expect(restored.modelId, 'toyota-corolla');
      expect(restored.registrationCountryCode, 'MX');
      expect(restored.registrationRegionCode, 'MX-GUA');
    });

    test(
      'Los registros anteriores no requieren identificadores de catálogo',
      () {
        final oldData = <Object?, Object?>{
          'brand': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'vehicleType': 'car',
          'fuelType': 'gasoline',
          'registrationCountry': 'México',
          'registrationRegion': 'Guanajuato',
          'createdAt': 1770000000000,
          'updatedAt': 1770000000000,
        };

        final restored = Vehicle.fromMap('legacy-vehicle', oldData);

        expect(restored.brand, 'Toyota');
        expect(restored.model, 'Corolla');
        expect(restored.registrationCountry, 'México');
        expect(restored.registrationRegion, 'Guanajuato');
        expect(restored.brandId, isNull);
        expect(restored.modelId, isNull);
        expect(restored.registrationCountryCode, isNull);
        expect(restored.registrationRegionCode, isNull);
      },
    );
  });

  group('Vehicle model - Placas', () {
    test('Obtiene el último dígito de una terminación alfanumérica', () {
      final vehicle = _vehicleWithPlate('123-E');

      expect(vehicle.plateEnding, '123-E');
      expect(vehicle.plateLastNumericDigit, 3);
    });

    test('Identifica el último número aunque existan varios dígitos', () {
      final vehicle = _vehicleWithPlate('ABC-45');

      expect(vehicle.plateLastNumericDigit, 5);
    });

    test('Regresa null cuando la terminación no tiene números', () {
      final vehicle = _vehicleWithPlate('ABC-E');

      expect(vehicle.plateLastNumericDigit, isNull);
    });

    test('Guarda la terminación en mayúsculas', () {
      final vehicle = _vehicleWithPlate('abc-5');

      final data = vehicle.toMap();

      expect(data['plateEnding'], 'ABC-5');
    });
  });
}

Vehicle _vehicleWithPlate(String ending) {
  return Vehicle(
    id: 'plate-test',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2022,
    vehicleType: 'car',
    fuelType: 'gasoline',
    fuelConsumptionKmPerLiter: null,
    electricConsumptionKwhPer100Km: null,
    registrationCountry: 'México',
    registrationRegion: 'Guanajuato',
    plateEnding: ending,
    insuranceCompany: null,
    insuranceValidUntil: null,
    verificationHologram: null,
    verificationValidUntil: null,
    createdAt: 1770000000000,
    updatedAt: 1770000000000,
  );
}
