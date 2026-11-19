import 'catalog_parsing.dart';

class VehicleBrand {
  const VehicleBrand({
    required this.id,
    required this.name,
    required this.vehicleTypes,
    this.aliases = const [],
  });

  final String id;
  final String name;

  /// Tipos de vehículo compatibles con la marca.
  ///
  /// Valores alineados con el modelo Vehicle:
  /// car, motorcycle, pickup, van, truck y otros.
  final List<String> vehicleTypes;

  /// Nombres alternativos para futuras búsquedas.
  final List<String> aliases;

  /// Indica si la marca admite el tipo de vehículo indicado.
  bool supportsVehicleType(String? vehicleType) {
    if (vehicleType == null || vehicleType.trim().isEmpty) {
      return true;
    }

    return vehicleTypes.contains(vehicleType.trim().toLowerCase());
  }

  factory VehicleBrand.fromMap(Map<String, Object?> data) {
    final id = readRequiredString(data, 'id');
    validateCatalogSlug(id, fieldName: 'id');

    final name = readRequiredString(data, 'name');

    final vehicleTypes = readStringList(data, 'vehicleTypes', required: true);

    final aliases = readStringList(data, 'aliases');

    return VehicleBrand(
      id: id,
      name: name,
      vehicleTypes: vehicleTypes,
      aliases: aliases,
    );
  }
}
