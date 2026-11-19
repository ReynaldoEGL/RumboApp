class Vehicle {
  final String id;

  final String brand;
  final String model;
  final int year;

  final String vehicleType;
  final String fuelType;

  // Rendimiento de combustible: kilómetros por litro.
  final double? fuelConsumptionKmPerLiter;

  // Consumo eléctrico: kilovatios-hora por cada 100 km.
  final double? electricConsumptionKwhPer100Km;

  final String registrationCountry;
  final String registrationRegion;

  // Almacenamos solamente la terminación, no la matrícula completa.
  final String? plateEnding;

  final String? insuranceCompany;
  final DateTime? insuranceValidUntil;

  final String? verificationHologram;
  final DateTime? verificationValidUntil;

  final int createdAt;
  final int updatedAt;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.vehicleType,
    required this.fuelType,
    required this.fuelConsumptionKmPerLiter,
    required this.electricConsumptionKwhPer100Km,
    required this.registrationCountry,
    required this.registrationRegion,
    required this.plateEnding,
    required this.insuranceCompany,
    required this.insuranceValidUntil,
    required this.verificationHologram,
    required this.verificationValidUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Obtiene el último dígito numérico de la terminación.
  ///
  /// Ejemplos:
  /// 123-E  -> 3
  /// ABC-45 -> 5
  /// ABC-E  -> null
  ///
  /// La interpretación normativa de este valor dependerá
  /// posteriormente de la jurisdicción y su programa.
  int? get plateLastNumericDigit {
    final ending = plateEnding;

    if (ending == null || ending.isEmpty) {
      return null;
    }

    final matches = RegExp(r'[0-9]').allMatches(ending).toList();

    if (matches.isEmpty) {
      return null;
    }

    return int.tryParse(matches.last.group(0)!);
  }

  bool get isElectric => fuelType == 'electric';

  bool get isHybrid => fuelType == 'hybrid';

  String get displayName => '$brand $model ($year)';

  /// Convierte el vehículo a una estructura compatible con
  /// Firebase Realtime Database.
  Map<String, dynamic> toMap() {
    final normalizedEnding = plateEnding?.trim().toUpperCase();

    return {
      'schemaVersion': 2,

      'brand': brand.trim(),
      'model': model.trim(),
      'year': year,

      'vehicleType': vehicleType,
      'fuelType': fuelType,

      'registrationCountry': registrationCountry.trim(),
      'registrationRegion': registrationRegion.trim(),

      'createdAt': createdAt,
      'updatedAt': updatedAt,

      if (fuelConsumptionKmPerLiter != null)
        'fuelConsumptionKmPerLiter': fuelConsumptionKmPerLiter,

      if (electricConsumptionKwhPer100Km != null)
        'electricConsumptionKwhPer100Km': electricConsumptionKwhPer100Km,

      if (normalizedEnding != null && normalizedEnding.isNotEmpty)
        'plateEnding': normalizedEnding,

      if (insuranceCompany != null && insuranceCompany!.trim().isNotEmpty)
        'insuranceCompany': insuranceCompany!.trim(),

      if (insuranceValidUntil != null)
        'insuranceValidUntil': insuranceValidUntil!.millisecondsSinceEpoch,

      if (verificationHologram != null &&
          verificationHologram!.trim().isNotEmpty)
        'verificationHologram': verificationHologram!.trim(),

      if (verificationValidUntil != null)
        'verificationValidUntil':
            verificationValidUntil!.millisecondsSinceEpoch,
    };
  }

  factory Vehicle.fromMap(String id, Map<Object?, Object?> rawData) {
    final data = Map<String, dynamic>.from(rawData);

    final fuelType = data['fuelType'] as String? ?? 'other';

    // Compatibilidad con la versión anterior del modelo.
    final legacyAverage = _asDouble(data['averageConsumption']);

    final legacyUnit = data['consumptionUnit'] as String? ?? 'km/L';

    final legacyPlateDigit = data['plateLastDigit'];

    String? legacyPlateEnding;

    if (legacyPlateDigit is num) {
      legacyPlateEnding = legacyPlateDigit.toInt().toString();
    } else if (legacyPlateDigit is String) {
      legacyPlateEnding = legacyPlateDigit;
    }

    final currentPlateEnding = data['plateEnding'] as String?;

    // Si el registro es antiguo, tratamos de conservar
    // el consumo en la unidad que tenía anteriormente.
    final fuelConsumption =
        _asDouble(data['fuelConsumptionKmPerLiter']) ??
        (legacyAverage != null && legacyUnit.toLowerCase() == 'km/l'
            ? legacyAverage
            : null);

    final electricConsumption =
        _asDouble(data['electricConsumptionKwhPer100Km']) ??
        (legacyAverage != null &&
                (legacyUnit.toLowerCase().contains('kwh') ||
                    (fuelType == 'electric' && legacyUnit == 'km/L'))
            ? legacyAverage
            : null);

    return Vehicle(
      id: id,

      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,

      vehicleType: data['vehicleType'] as String? ?? 'other',
      fuelType: fuelType,

      fuelConsumptionKmPerLiter: fuelConsumption,
      electricConsumptionKwhPer100Km: electricConsumption,

      registrationCountry: data['registrationCountry'] as String? ?? '',

      registrationRegion: data['registrationRegion'] as String? ?? '',

      plateEnding: currentPlateEnding ?? legacyPlateEnding,

      insuranceCompany: data['insuranceCompany'] as String?,

      insuranceValidUntil: _dateFromMilliseconds(data['insuranceValidUntil']),

      verificationHologram: data['verificationHologram'] as String?,

      verificationValidUntil: _dateFromMilliseconds(
        data['verificationValidUntil'],
      ),

      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,

      updatedAt: (data['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  static DateTime? _dateFromMilliseconds(Object? value) {
    if (value is! num) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}
