import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_plan.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_estimate.dart';
import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

enum TripStatus { planned, inProgress, completed, cancelled }

extension TripStatusPresentation on TripStatus {
  String get label {
    return switch (this) {
      TripStatus.planned => 'Planeado',
      TripStatus.inProgress => 'En curso',
      TripStatus.completed => 'Completado',
      TripStatus.cancelled => 'Cancelado',
    };
  }

  static TripStatus fromValue(Object? value) {
    return switch (value) {
      'inProgress' => TripStatus.inProgress,
      'completed' => TripStatus.completed,
      'cancelled' => TripStatus.cancelled,
      _ => TripStatus.planned,
    };
  }
}

class TripVehicleSnapshot {
  const TripVehicleSnapshot({
    required this.id,
    required this.displayName,
    required this.fuelType,
    this.fuelConsumptionKmPerLiter,
    this.electricConsumptionKwhPer100Km,
  });

  final String id;
  final String displayName;
  final String fuelType;
  final double? fuelConsumptionKmPerLiter;
  final double? electricConsumptionKwhPer100Km;

  factory TripVehicleSnapshot.fromVehicle(Vehicle vehicle) {
    return TripVehicleSnapshot(
      id: vehicle.id,
      displayName: vehicle.displayName,
      fuelType: vehicle.fuelType,
      fuelConsumptionKmPerLiter: vehicle.fuelConsumptionKmPerLiter,
      electricConsumptionKwhPer100Km: vehicle.electricConsumptionKwhPer100Km,
    );
  }

  factory TripVehicleSnapshot.fromMap(Map<Object?, Object?> rawData) {
    final data = Map<String, Object?>.from(rawData);

    return TripVehicleSnapshot(
      id: _requiredString(data, 'id'),
      displayName: _requiredString(data, 'displayName'),
      fuelType: _requiredString(data, 'fuelType'),
      fuelConsumptionKmPerLiter: _positiveDouble(
        data['fuelConsumptionKmPerLiter'],
      ),
      electricConsumptionKwhPer100Km: _positiveDouble(
        data['electricConsumptionKwhPer100Km'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'fuelType': fuelType,
      if (fuelConsumptionKmPerLiter != null)
        'fuelConsumptionKmPerLiter': fuelConsumptionKmPerLiter,
      if (electricConsumptionKwhPer100Km != null)
        'electricConsumptionKwhPer100Km': electricConsumptionKwhPer100Km,
    };
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.status,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.returnDate,
    this.vehicleId,
    this.vehicleSnapshot,
    this.distanceKm,
    this.energyUnitPrice,
    this.routeSnapshot,
    this.budgetPlan,
    this.notes,
  });

  final String id;
  final String title;
  final String origin;
  final String destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final String? vehicleId;
  final TripVehicleSnapshot? vehicleSnapshot;
  final double? distanceKm;
  final double? energyUnitPrice;
  final RoadRoute? routeSnapshot;
  final TripBudgetPlan? budgetPlan;
  final String currencyCode;
  final TripStatus status;
  final String? notes;
  final int createdAt;
  final int updatedAt;

  String get routeLabel => '$origin → $destination';

  TripEnergyEstimate? get energyEstimate {
    final snapshot = vehicleSnapshot;

    if (snapshot == null) {
      return null;
    }

    return calculateTripEnergyEstimate(
      fuelType: snapshot.fuelType,
      distanceKm: distanceKm,
      energyUnitPrice: energyUnitPrice,
      fuelConsumptionKmPerLiter: snapshot.fuelConsumptionKmPerLiter,
      electricConsumptionKwhPer100Km: snapshot.electricConsumptionKwhPer100Km,
    );
  }

  TripBudgetEstimate get budgetEstimate {
    final plan = budgetPlan;
    final vehicle = vehicleSnapshot;

    final returnEnergy = plan?.includeReturn == true && vehicle != null
        ? calculateTripEnergyEstimate(
            fuelType: vehicle.fuelType,
            distanceKm: plan?.returnDistanceKm,
            energyUnitPrice: energyUnitPrice,
            fuelConsumptionKmPerLiter: vehicle.fuelConsumptionKmPerLiter,
            electricConsumptionKwhPer100Km:
                vehicle.electricConsumptionKwhPer100Km,
          )
        : null;

    return calculateTripBudgetEstimate(
      energy: energyEstimate,
      route: routeSnapshot,
      currencyCode: currencyCode,
      lodgingNights: plan?.lodgingNights,
      lodgingNightlyRate: plan?.lodgingNightlyRate,
      includeReturn: plan?.includeReturn ?? false,
      returnEnergy: returnEnergy,
      returnTollsAmount: plan?.returnTollsAmount,
    );
  }

  void validate() {
    _validateRequiredText(title, 'El nombre del viaje');
    _validateRequiredText(origin, 'El origen');
    _validateRequiredText(destination, 'El destino');

    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currencyCode.trim())) {
      throw const FormatException(
        'El código de moneda debe contener tres letras.',
      );
    }

    if (returnDate != null) {
      final departure = _dateOnly(departureDate);
      final returnValue = _dateOnly(returnDate!);

      if (returnValue.isBefore(departure)) {
        throw const FormatException(
          'La fecha de regreso no puede ser anterior a la salida.',
        );
      }
    }

    _validateOptionalPositiveNumber(distanceKm, 'La distancia');
    _validateOptionalPositiveNumber(energyUnitPrice, 'El precio energético');
    budgetPlan?.validate();

    if (vehicleId != null && vehicleId!.trim().isEmpty) {
      throw const FormatException(
        'El identificador del vehículo no es válido.',
      );
    }

    final vehicle = vehicleSnapshot;

    if (vehicle != null) {
      _validateRequiredText(vehicle.id, 'El identificador del vehículo');
      _validateRequiredText(vehicle.displayName, 'El nombre del vehículo');
      _validateRequiredText(vehicle.fuelType, 'El tipo de combustible');

      if (vehicleId != null && vehicleId!.trim() != vehicle.id.trim()) {
        throw const FormatException(
          'Los datos del vehículo asociado no coinciden.',
        );
      }

      _validateOptionalPositiveNumber(
        vehicle.fuelConsumptionKmPerLiter,
        'El consumo de combustible',
      );

      _validateOptionalPositiveNumber(
        vehicle.electricConsumptionKwhPer100Km,
        'El consumo eléctrico',
      );
    }

    final route = routeSnapshot;

    if (route != null) {
      _validateRequiredText(route.id, 'El identificador del recorrido');

      if (origin.trim() != route.origin.addressLabel.trim()) {
        throw const FormatException(
          'El origen no coincide con el recorrido seleccionado.',
        );
      }

      if (destination.trim() != route.destination.addressLabel.trim()) {
        throw const FormatException(
          'El destino no coincide con el recorrido seleccionado.',
        );
      }

      final routeDistance = route.distanceKilometers;

      if (!routeDistance.isFinite || routeDistance <= 0) {
        throw const FormatException(
          'La distancia del recorrido seleccionado no es válida.',
        );
      }

      if (distanceKm == null ||
          (distanceKm! - routeDistance).abs() > 0.000001) {
        throw const FormatException(
          'La distancia no coincide con el recorrido seleccionado.',
        );
      }
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return {
      'schemaVersion': budgetPlan == null ? 1 : 2,
      'title': title.trim(),
      'origin': origin.trim(),
      'destination': destination.trim(),
      'departureDate': _dateOnlyMilliseconds(departureDate),
      'status': status.name,
      'currencyCode': currencyCode.trim().toUpperCase(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (returnDate != null) 'returnDate': _dateOnlyMilliseconds(returnDate!),
      if (vehicleId != null && vehicleId!.trim().isNotEmpty)
        'vehicleId': vehicleId!.trim(),
      if (vehicleSnapshot != null) 'vehicleSnapshot': vehicleSnapshot!.toMap(),
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (energyUnitPrice != null) 'energyUnitPrice': energyUnitPrice,
      if (routeSnapshot != null) 'routeSnapshot': routeSnapshot!.toMap(),
      if (budgetPlan != null) 'budgetPlan': budgetPlan!.toMap(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  factory Trip.fromMap(String id, Map<Object?, Object?> rawData) {
    final data = Map<String, Object?>.from(rawData);

    TripVehicleSnapshot? vehicleSnapshot;
    RoadRoute? routeSnapshot;

    final rawVehicleSnapshot = data['vehicleSnapshot'];
    final rawRouteSnapshot = data['routeSnapshot'];
    final rawBudgetPlan = data['budgetPlan'];

    if (rawVehicleSnapshot is Map) {
      vehicleSnapshot = TripVehicleSnapshot.fromMap(
        Map<Object?, Object?>.from(rawVehicleSnapshot),
      );
    }

    if (rawRouteSnapshot is Map) {
      routeSnapshot = RoadRoute.fromMap(
        Map<Object?, Object?>.from(rawRouteSnapshot),
      );
    }

    TripBudgetPlan? budgetPlan;

    if (rawBudgetPlan is Map) {
      budgetPlan = TripBudgetPlan.fromMap(
        Map<Object?, Object?>.from(rawBudgetPlan),
      );
    }

    final storedVehicleId = _optionalString(data['vehicleId']);

    return Trip(
      id: id,
      title: _requiredString(data, 'title'),
      origin: _requiredString(data, 'origin'),
      destination: _requiredString(data, 'destination'),
      departureDate: _dateFromMilliseconds(data['departureDate']),
      returnDate: _optionalDateFromMilliseconds(data['returnDate']),
      vehicleId: storedVehicleId ?? vehicleSnapshot?.id,
      vehicleSnapshot: vehicleSnapshot,
      distanceKm: _positiveDouble(data['distanceKm']),
      energyUnitPrice: _positiveDouble(data['energyUnitPrice']),
      routeSnapshot: routeSnapshot,
      budgetPlan: budgetPlan,
      currencyCode: _currencyCode(data['currencyCode']),
      status: TripStatusPresentation.fromValue(data['status']),
      notes: _optionalString(data['notes']),
      createdAt: _integer(data['createdAt']),
      updatedAt: _integer(data['updatedAt']),
    );
  }
}

void _validateRequiredText(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw FormatException('$fieldName es obligatorio.');
  }
}

void _validateOptionalPositiveNumber(double? value, String fieldName) {
  if (value == null) {
    return;
  }

  if (!value.isFinite || value <= 0) {
    throw FormatException('$fieldName debe ser mayor que cero.');
  }
}

String _requiredString(Map<String, Object?> data, String key) {
  final value = data[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('El campo "$key" del viaje no es válido.');
  }

  return value.trim();
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value.trim();
}

double? _positiveDouble(Object? value) {
  if (value is! num) {
    return null;
  }

  final result = value.toDouble();

  if (!result.isFinite || result <= 0) {
    return null;
  }

  return result;
}

int _integer(Object? value) {
  if (value is! num) {
    return 0;
  }

  return value.toInt();
}

int _dateOnlyMilliseconds(DateTime date) {
  return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _dateFromMilliseconds(Object? value) {
  if (value is! num) {
    throw const FormatException('La fecha de salida del viaje no es válida.');
  }

  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

  return _dateOnly(date);
}

DateTime? _optionalDateFromMilliseconds(Object? value) {
  if (value is! num) {
    return null;
  }

  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

  return _dateOnly(date);
}

String _currencyCode(Object? value) {
  if (value is! String || !RegExp(r'^[A-Za-z]{3}$').hasMatch(value.trim())) {
    return 'MXN';
  }

  return value.trim().toUpperCase();
}
