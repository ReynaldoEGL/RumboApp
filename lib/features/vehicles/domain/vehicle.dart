class Vehicle {
  final String id;

  final String brand;
  final String model;
  final int year;

  final String vehicleType;
  final String fuelType;

  final double? averageConsumption;
  final String consumptionUnit;

  final String registrationCountry;
  final String registrationRegion;

  // Solamente guardamos el último dígito de la placa.
  final int? plateLastDigit;

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
    required this.averageConsumption,
    required this.consumptionUnit,
    required this.registrationCountry,
    required this.registrationRegion,
    required this.plateLastDigit,
    required this.insuranceCompany,
    required this.insuranceValidUntil,
    required this.verificationHologram,
    required this.verificationValidUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand.trim(),
      'model': model.trim(),
      'year': year,
      'vehicleType': vehicleType,
      'fuelType': fuelType,
      'consumptionUnit': consumptionUnit,
      'registrationCountry': registrationCountry.trim(),
      'registrationRegion': registrationRegion.trim(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,

      if (averageConsumption != null) 'averageConsumption': averageConsumption,

      if (plateLastDigit != null) 'plateLastDigit': plateLastDigit,

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

    return Vehicle(
      id: id,
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      vehicleType: data['vehicleType'] as String? ?? 'other',
      fuelType: data['fuelType'] as String? ?? 'other',

      averageConsumption: (data['averageConsumption'] as num?)?.toDouble(),

      consumptionUnit: data['consumptionUnit'] as String? ?? 'km/L',

      registrationCountry: data['registrationCountry'] as String? ?? '',

      registrationRegion: data['registrationRegion'] as String? ?? '',

      plateLastDigit: (data['plateLastDigit'] as num?)?.toInt(),

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

  static DateTime? _dateFromMilliseconds(Object? value) {
    if (value is! num) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  String get displayName {
    return '$brand $model ($year)';
  }

  bool get isElectric {
    return fuelType == 'electric';
  }
}
