import 'catalog_parsing.dart';

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.vehicleTypes,
    this.aliases = const [],
    this.firstYear,
    this.lastYear,
  });

  /// Identificador estable del modelo.
  ///
  /// Ejemplo: toyota-corolla.
  final String id;

  /// ID de la marca a la que pertenece.
  final String brandId;

  final String name;

  /// Tipos de vehículo asociados al modelo.
  final List<String> vehicleTypes;

  final List<String> aliases;

  /// Año inicial, cuando se dispone de ese dato.
  final int? firstYear;

  /// Año final, cuando se dispone de ese dato.
  ///
  /// Si es null, no significa que el modelo siga fabricándose:
  /// significa que el catálogo no dispone de una fecha final.
  final int? lastYear;

  bool supportsVehicleType(String? vehicleType) {
    if (vehicleType == null || vehicleType.trim().isEmpty) {
      return true;
    }

    return vehicleTypes.contains(vehicleType.trim().toLowerCase());
  }

  /// Comprueba si el año proporcionado está dentro del intervalo conocido.
  ///
  /// Si no se conocen los años de producción, no se excluye el modelo.
  bool supportsYear(int? year) {
    if (year == null) {
      return true;
    }

    if (firstYear != null && year < firstYear!) {
      return false;
    }

    if (lastYear != null && year > lastYear!) {
      return false;
    }

    return true;
  }

  factory VehicleModel.fromMap(Map<String, Object?> data) {
    final id = readRequiredString(data, 'id');
    final brandId = readRequiredString(data, 'brandId');

    validateCatalogSlug(id, fieldName: 'id');
    validateCatalogSlug(brandId, fieldName: 'brandId');

    final firstYear = readOptionalInt(data, 'firstYear');
    final lastYear = readOptionalInt(data, 'lastYear');

    if (firstYear != null && firstYear < 1886) {
      throw FormatException('El año inicial de "$id" no es válido.');
    }

    if (lastYear != null && lastYear < 1886) {
      throw FormatException('El año final de "$id" no es válido.');
    }

    if (firstYear != null && lastYear != null && lastYear < firstYear) {
      throw FormatException(
        'El intervalo de años del modelo "$id" es inválido.',
      );
    }

    return VehicleModel(
      id: id,
      brandId: brandId,
      name: readRequiredString(data, 'name'),
      vehicleTypes: readStringList(data, 'vehicleTypes', required: true),
      aliases: readStringList(data, 'aliases'),
      firstYear: firstYear,
      lastYear: lastYear,
    );
  }
}
