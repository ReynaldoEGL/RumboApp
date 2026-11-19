import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/vehicles/data/vehicle_catalog_repository.dart';
import 'package:rumboapp/features/vehicles/data/sources/local_vehicle_catalog_source.dart';

import 'package:rumboapp/features/vehicles/domain/catalogs/vehicle_brand.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/vehicle_model.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/country.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/region.dart';

typedef VehicleCatalogModelQuery = ({
  String brandId,
  String? vehicleType,
  int? year,
});

final vehicleCatalogSourceProvider = Provider<VehicleCatalogSource>((ref) {
  return AssetVehicleCatalogSource();
});

/// Repositorio central de catálogos.
final vehicleCatalogRepositoryProvider = Provider<VehicleCatalogRepository>((
  ref,
) {
  return VehicleCatalogRepository(ref.watch(vehicleCatalogSourceProvider));
});

/// Obtiene las marcas disponibles.
///
/// El argumento puede ser null para obtener todas las marcas,
/// o un tipo de vehículo para filtrar los resultados.
final vehicleCatalogBrandsProvider =
    FutureProvider.family<List<VehicleBrand>, String?>((ref, vehicleType) {
      return ref
          .watch(vehicleCatalogRepositoryProvider)
          .getBrands(vehicleType: vehicleType);
    });

/// Obtiene los modelos de una marca.
///
/// También permite filtrar por tipo de vehículo y año.
final vehicleCatalogModelsProvider =
    FutureProvider.family<List<VehicleModel>, VehicleCatalogModelQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(vehicleCatalogRepositoryProvider)
          .getModelsForBrand(
            brandId: query.brandId,
            vehicleType: query.vehicleType,
            year: query.year,
          );
    });

/// Obtiene los países disponibles.
final vehicleCatalogCountriesProvider = FutureProvider<List<Country>>((ref) {
  return ref.watch(vehicleCatalogRepositoryProvider).getCountries();
});

/// Obtiene las regiones de un país.
///
/// El argumento debe ser el código ISO alpha-2.
/// Ejemplo: 'MX'.
final vehicleCatalogRegionsProvider =
    FutureProvider.family<List<Region>, String>((ref, countryCode) {
      return ref
          .watch(vehicleCatalogRepositoryProvider)
          .getRegionsForCountry(countryCode);
    });
