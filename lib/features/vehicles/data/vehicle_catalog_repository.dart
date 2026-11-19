import '../domain/catalogs/vehicle_brand.dart';
import '../domain/catalogs/vehicle_model.dart';
import '../domain/catalogs/country.dart';
import '../domain/catalogs/region.dart';

import 'sources/local_vehicle_catalog_source.dart';

class VehicleCatalogRepository {
  VehicleCatalogRepository(this._source);

  final VehicleCatalogSource _source;

  // ---------------------------------------------------------------------------
  // RUTAS DE LOS CATÁLOGOS
  // ---------------------------------------------------------------------------

  static const String brandsAssetPath = 'assets/catalogs/vehicles/brands.json';

  static const String modelsAssetPath = 'assets/catalogs/vehicles/models.json';

  static const String countriesAssetPath =
      'assets/catalogs/geography/countries.json';

  static const String regionsAssetPath =
      'assets/catalogs/geography/regions.json';

  // ---------------------------------------------------------------------------
  // MARCAS
  // ---------------------------------------------------------------------------

  /// Obtiene todas las marcas, o solo las compatibles con un tipo de vehículo.
  ///
  /// Ejemplos:
  /// getBrands()                    -> todas las marcas.
  /// getBrands(vehicleType: 'car')  -> marcas compatibles con automóvil.
  /// getBrands(vehicleType: 'motorcycle') -> marcas de motocicletas.
  Future<List<VehicleBrand>> getBrands({String? vehicleType}) async {
    final rows = await _source.loadItems(brandsAssetPath);

    final brands = rows.map(VehicleBrand.fromMap).toList(growable: false);

    _ensureUniqueIds<VehicleBrand>(
      brands,
      idOf: (brand) => brand.id,
      catalogName: 'marcas',
    );

    final normalizedType = _normalizeOptionalCode(vehicleType);

    final filtered = normalizedType == null
        ? brands
        : brands
              .where((brand) => brand.supportsVehicleType(normalizedType))
              .toList(growable: false);

    return _sortByName<VehicleBrand>(filtered, nameOf: (brand) => brand.name);
  }

  // ---------------------------------------------------------------------------
  // MODELOS
  // ---------------------------------------------------------------------------

  /// Devuelve modelos asociados a una marca.
  ///
  /// El tipo de vehículo y el año son filtros opcionales.
  ///
  /// Si un modelo no tiene años de producción conocidos, no se elimina
  /// por el filtro de año.
  Future<List<VehicleModel>> getModelsForBrand({
    required String brandId,
    String? vehicleType,
    int? year,
  }) async {
    final normalizedBrandId = brandId.trim().toLowerCase();

    if (normalizedBrandId.isEmpty) {
      return const [];
    }

    // Primero verificamos que la marca exista.
    // No se deben mostrar modelos que apunten a una marca desconocida.
    final brands = await getBrands();

    final knownBrandIds = brands.map((brand) => brand.id).toSet();

    if (!knownBrandIds.contains(normalizedBrandId)) {
      return const [];
    }

    final rows = await _source.loadItems(modelsAssetPath);

    final models = rows.map(VehicleModel.fromMap).toList(growable: false);

    _ensureUniqueIds<VehicleModel>(
      models,
      idOf: (model) => model.id,
      catalogName: 'modelos',
    );

    // Comprobamos las relaciones de todos los modelos.
    // Así un error en el JSON no queda oculto porque el usuario
    // haya seleccionado otra marca.
    for (final model in models) {
      if (!knownBrandIds.contains(model.brandId)) {
        throw FormatException(
          'El modelo "${model.id}" hace referencia a la marca '
          '"${model.brandId}", que no existe en el catálogo.',
        );
      }
    }

    final normalizedType = _normalizeOptionalCode(vehicleType);

    final filtered = models
        .where((model) {
          if (model.brandId != normalizedBrandId) {
            return false;
          }

          if (normalizedType != null &&
              !model.supportsVehicleType(normalizedType)) {
            return false;
          }

          if (!model.supportsYear(year)) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    return _sortByName<VehicleModel>(filtered, nameOf: (model) => model.name);
  }

  // ---------------------------------------------------------------------------
  // PAÍSES
  // ---------------------------------------------------------------------------

  Future<List<Country>> getCountries() async {
    final rows = await _source.loadItems(countriesAssetPath);

    final countries = rows.map(Country.fromMap).toList(growable: false);

    _ensureUniqueIds<Country>(
      countries,
      idOf: (country) => country.code,
      catalogName: 'países',
    );

    return _sortByName<Country>(countries, nameOf: (country) => country.name);
  }

  // ---------------------------------------------------------------------------
  // REGIONES
  // ---------------------------------------------------------------------------

  /// Devuelve las regiones de un país.
  ///
  /// Ejemplo:
  /// getRegionsForCountry('MX')
  /// devuelve las entidades federativas de México.
  ///
  /// Si todavía no existe un catálogo regional para un país,
  /// devuelve una lista vacía. La futura interfaz permitirá
  /// introducir manualmente el nombre de la región.
  Future<List<Region>> getRegionsForCountry(String countryCode) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCountryCode)) {
      return const [];
    }

    // No permitimos regiones cuyo país no exista en el catálogo.
    final countries = await getCountries();

    final countryExists = countries.any(
      (country) => country.code == normalizedCountryCode,
    );

    if (!countryExists) {
      return const [];
    }

    final rows = await _source.loadItems(regionsAssetPath);

    final regions = rows.map(Region.fromMap).toList(growable: false);

    _ensureUniqueIds<Region>(
      regions,
      idOf: (region) => region.code,
      catalogName: 'regiones',
    );

    // Verificamos que todas las regiones pertenezcan a un país válido.
    final knownCountryCodes = countries.map((country) => country.code).toSet();

    for (final region in regions) {
      if (!knownCountryCodes.contains(region.countryCode)) {
        throw FormatException(
          'La región "${region.code}" hace referencia '
          'al país "${region.countryCode}", que no existe.',
        );
      }
    }

    final filtered = regions
        .where((region) => region.countryCode == normalizedCountryCode)
        .toList(growable: false);

    return _sortByName<Region>(filtered, nameOf: (region) => region.name);
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES INTERNAS
  // ---------------------------------------------------------------------------

  String? _normalizeOptionalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim().toLowerCase();
  }

  void _ensureUniqueIds<T>(
    List<T> items, {
    required String Function(T) idOf,
    required String catalogName,
  }) {
    final seen = <String>{};

    for (final item in items) {
      final id = idOf(item);

      if (!seen.add(id)) {
        throw FormatException(
          'El catálogo de $catalogName contiene '
          'el identificador duplicado "$id".',
        );
      }
    }
  }

  List<T> _sortByName<T>(List<T> items, {required String Function(T) nameOf}) {
    final sorted = List<T>.of(items);

    sorted.sort(
      (a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
    );

    return List.unmodifiable(sorted);
  }
}
