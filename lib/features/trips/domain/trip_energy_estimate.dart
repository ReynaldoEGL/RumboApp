class TripEnergyEstimate {
  const TripEnergyEstimate({
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.description,
    this.isPartial = false,
  });

  final double quantity;
  final String unit;
  final double cost;
  final String description;
  final bool isPartial;
}

TripEnergyEstimate? calculateTripEnergyEstimate({
  required String? fuelType,
  required double? distanceKm,
  required double? energyUnitPrice,
  required double? fuelConsumptionKmPerLiter,
  required double? electricConsumptionKwhPer100Km,
}) {
  if (distanceKm == null ||
      energyUnitPrice == null ||
      !distanceKm.isFinite ||
      !energyUnitPrice.isFinite ||
      distanceKm <= 0 ||
      energyUnitPrice <= 0) {
    return null;
  }

  final normalizedFuelType = fuelType?.trim().toLowerCase();

  if (normalizedFuelType == 'gasoline' ||
      normalizedFuelType == 'diesel' ||
      normalizedFuelType == 'hybrid') {
    final consumption = fuelConsumptionKmPerLiter;

    if (consumption == null || !consumption.isFinite || consumption <= 0) {
      return null;
    }

    final liters = distanceKm / consumption;
    final cost = liters * energyUnitPrice;

    if (!liters.isFinite || !cost.isFinite) {
      return null;
    }

    return TripEnergyEstimate(
      quantity: liters,
      unit: 'L',
      cost: cost,
      description: normalizedFuelType == 'hybrid'
          ? 'Estimación de combustible; no incluye el consumo eléctrico.'
          : 'Combustible estimado para la distancia registrada.',
      isPartial: normalizedFuelType == 'hybrid',
    );
  }

  if (normalizedFuelType == 'electric') {
    final consumption = electricConsumptionKwhPer100Km;

    if (consumption == null || !consumption.isFinite || consumption <= 0) {
      return null;
    }

    final energy = (distanceKm * consumption) / 100;
    final cost = energy * energyUnitPrice;

    if (!energy.isFinite || !cost.isFinite) {
      return null;
    }

    return TripEnergyEstimate(
      quantity: energy,
      unit: 'kWh',
      cost: cost,
      description: 'Energía eléctrica estimada para la distancia registrada.',
    );
  }

  return null;
}
