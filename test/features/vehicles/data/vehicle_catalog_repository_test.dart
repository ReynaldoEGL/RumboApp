import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/data/vehicle_catalog_repository.dart';
import 'package:rumboapp/features/vehicles/data/sources/local_vehicle_catalog_source.dart';

void main() {
  group('VehicleCatalogRepository', () {
    late _MemoryCatalogSource source;
    late VehicleCatalogRepository repository;

    setUp(() {
      source = _createSource();
      repository = VehicleCatalogRepository(source);
    });

    test('obtiene todas las marcas ordenadas alfabéticamente', () async {
      final brands = await repository.getBrands();

      expect(brands, hasLength(2));

      expect(brands.map((brand) => brand.name).toList(), ['Toyota', 'Yamaha']);
    });

    test('filtra marcas por tipo de vehículo', () async {
      final carBrands = await repository.getBrands(vehicleType: 'car');

      expect(carBrands, hasLength(1));
      expect(carBrands.single.id, 'toyota');

      final motorcycleBrands = await repository.getBrands(
        vehicleType: 'motorcycle',
      );

      expect(motorcycleBrands, hasLength(1));
      expect(motorcycleBrands.single.id, 'yamaha');
    });

    test('filtra modelos por marca y tipo de vehículo', () async {
      final carModels = await repository.getModelsForBrand(
        brandId: 'toyota',
        vehicleType: 'car',
      );

      expect(carModels, hasLength(1));
      expect(carModels.single.id, 'toyota-corolla');

      final pickupModels = await repository.getModelsForBrand(
        brandId: 'toyota',
        vehicleType: 'pickup',
      );

      expect(pickupModels, hasLength(1));
      expect(pickupModels.single.id, 'toyota-hilux');
    });

    test('aplica el filtro de año cuando existen límites conocidos', () async {
      final models = await repository.getModelsForBrand(
        brandId: 'toyota',
        vehicleType: 'car',
        year: 2024,
      );

      expect(models, hasLength(1));
      expect(models.single.id, 'toyota-corolla');

      final modelsOutsideRange = await repository.getModelsForBrand(
        brandId: 'toyota',
        vehicleType: 'car',
        year: 2010,
      );

      expect(modelsOutsideRange, isEmpty);
    });

    test('devuelve una lista vacía si la marca no existe', () async {
      final models = await repository.getModelsForBrand(
        brandId: 'marca-inexistente',
      );

      expect(models, isEmpty);
    });

    test('obtiene los países ordenados por nombre', () async {
      final countries = await repository.getCountries();

      expect(countries, hasLength(2));

      // El repositorio ordena por nombre visible:
      // Estados Unidos aparece antes que México.
      expect(countries.map((country) => country.name).toList(), [
        'Estados Unidos',
        'México',
      ]);

      expect(countries.map((country) => country.code).toList(), ['US', 'MX']);
    });

    test('filtra las regiones por código de país', () async {
      final mexicoRegions = await repository.getRegionsForCountry('MX');

      expect(mexicoRegions, hasLength(2));

      expect(mexicoRegions.map((region) => region.code).toSet(), {
        'MX-GUA',
        'MX-QUE',
      });

      final usRegions = await repository.getRegionsForCountry('US');

      expect(usRegions, hasLength(1));
      expect(usRegions.single.code, 'US-CA');
    });

    test('devuelve lista vacía para un código de país inválido', () async {
      final regions = await repository.getRegionsForCountry('ABC');

      expect(regions, isEmpty);
    });

    test('detecta marcas con identificadores duplicados', () async {
      source.catalogs[VehicleCatalogRepository.brandsAssetPath] = [
        {
          'id': 'toyota',
          'name': 'Toyota',
          'vehicleTypes': ['car'],
        },
        {
          'id': 'toyota',
          'name': 'Toyota duplicada',
          'vehicleTypes': ['car'],
        },
      ];

      await expectLater(
        repository.getBrands(),
        throwsA(isA<FormatException>()),
      );
    });

    test('detecta modelos que apuntan a marcas inexistentes', () async {
      source.catalogs[VehicleCatalogRepository.modelsAssetPath] = [
        {
          'id': 'modelo-sin-marca',
          'brandId': 'marca-inexistente',
          'name': 'Modelo inválido',
          'vehicleTypes': ['car'],
        },
      ];

      await expectLater(
        repository.getModelsForBrand(brandId: 'toyota'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

/// Fuente simulada que permite probar el repositorio sin Firebase
/// y sin depender de archivos externos.
class _MemoryCatalogSource implements VehicleCatalogSource {
  _MemoryCatalogSource(this.catalogs);

  final Map<String, List<Map<String, Object?>>> catalogs;

  @override
  Future<List<Map<String, Object?>>> loadItems(String assetPath) async {
    final items = catalogs[assetPath];

    if (items == null) {
      throw StateError('No existe un catálogo simulado para "$assetPath".');
    }

    return List.unmodifiable(items);
  }
}

/// Datos controlados para las pruebas del repositorio.
_MemoryCatalogSource _createSource() {
  return _MemoryCatalogSource({
    VehicleCatalogRepository.brandsAssetPath: [
      {
        'id': 'toyota',
        'name': 'Toyota',
        'vehicleTypes': ['car', 'pickup'],
      },
      {
        'id': 'yamaha',
        'name': 'Yamaha',
        'vehicleTypes': ['motorcycle'],
      },
    ],
    VehicleCatalogRepository.modelsAssetPath: [
      {
        'id': 'toyota-corolla',
        'brandId': 'toyota',
        'name': 'Corolla',
        'vehicleTypes': ['car'],
        'firstYear': 2020,
        'lastYear': 2025,
      },
      {
        'id': 'toyota-hilux',
        'brandId': 'toyota',
        'name': 'Hilux',
        'vehicleTypes': ['pickup'],
      },
      {
        'id': 'yamaha-mt-03',
        'brandId': 'yamaha',
        'name': 'MT-03',
        'vehicleTypes': ['motorcycle'],
      },
    ],
    VehicleCatalogRepository.countriesAssetPath: [
      {'code': 'MX', 'alpha3': 'MEX', 'name': 'México'},
      {'code': 'US', 'alpha3': 'USA', 'name': 'Estados Unidos'},
    ],
    VehicleCatalogRepository.regionsAssetPath: [
      {'code': 'MX-GUA', 'countryCode': 'MX', 'name': 'Guanajuato'},
      {'code': 'MX-QUE', 'countryCode': 'MX', 'name': 'Querétaro'},
      {'code': 'US-CA', 'countryCode': 'US', 'name': 'California'},
    ],
  });
}
