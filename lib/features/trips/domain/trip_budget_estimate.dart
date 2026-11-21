import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';
import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';

class TripTollEstimate {
  const TripTollEstimate({
    required this.currencyCode,
    required this.knownAmount,
    required this.reportedTolls,
    required this.pricedTolls,
    required this.unpricedTolls,
  });

  final String currencyCode;
  final double knownAmount;
  final int reportedTolls;
  final int pricedTolls;
  final int unpricedTolls;

  bool get isComplete => unpricedTolls == 0;
  bool get hasKnownPrices => pricedTolls > 0;
}

class TripLodgingEstimate {
  const TripLodgingEstimate({required this.nights, required this.nightlyRate});

  final int? nights;
  final double? nightlyRate;

  double? get cost {
    if (nights == null) {
      return null;
    }

    if (nights == 0) {
      return 0;
    }

    final rate = nightlyRate;

    if (rate == null || !rate.isFinite || rate <= 0) {
      return null;
    }

    final result = nights!.toDouble() * rate;
    return result.isFinite ? result : null;
  }

  bool get isComplete => cost != null;
}

class TripBudgetEstimate {
  const TripBudgetEstimate({
    required this.currencyCode,
    required this.energy,
    required this.tolls,
    required this.lodging,
    required this.includesReturn,
    required this.returnEnergy,
    required this.returnTollsAmount,
  });

  final String currencyCode;
  final TripEnergyEstimate? energy;
  final TripTollEstimate? tolls;
  final TripLodgingEstimate lodging;
  final bool includesReturn;
  final TripEnergyEstimate? returnEnergy;
  final double? returnTollsAmount;

  double get knownSubtotal {
    return (energy?.cost ?? 0) +
        (tolls?.knownAmount ?? 0) +
        (lodging.cost ?? 0) +
        (includesReturn ? (returnEnergy?.cost ?? 0) : 0) +
        (includesReturn ? (returnTollsAmount ?? 0) : 0);
  }

  bool get hasKnownCosts {
    return energy != null ||
        (tolls?.hasKnownPrices ?? false) ||
        lodging.isComplete ||
        (includesReturn && (returnEnergy != null || returnTollsAmount != null));
  }

  bool get isPartial {
    final outboundIncomplete =
        energy == null ||
        energy!.isPartial ||
        tolls == null ||
        !tolls!.isComplete;

    final returnIncomplete =
        includesReturn &&
        (returnEnergy == null ||
            returnEnergy!.isPartial ||
            returnTollsAmount == null);

    return outboundIncomplete || !lodging.isComplete || returnIncomplete;
  }
}

TripBudgetEstimate calculateTripBudgetEstimate({
  required TripEnergyEstimate? energy,
  required RoadRoute? route,
  required String currencyCode,
  int? lodgingNights,
  double? lodgingNightlyRate,
  bool includeReturn = false,
  TripEnergyEstimate? returnEnergy,
  double? returnTollsAmount,
}) {
  final normalizedCurrency = currencyCode.trim().toUpperCase();

  if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
    throw const FormatException(
      'El código de moneda del presupuesto no es válido.',
    );
  }

  if (lodgingNights != null && lodgingNights < 0) {
    throw const FormatException(
      'Las noches de hospedaje no pueden ser negativas.',
    );
  }

  if (lodgingNightlyRate != null &&
      (!lodgingNightlyRate.isFinite || lodgingNightlyRate <= 0)) {
    throw const FormatException('El precio por noche debe ser mayor que cero.');
  }

  if (includeReturn &&
      returnTollsAmount != null &&
      (!returnTollsAmount.isFinite || returnTollsAmount < 0)) {
    throw const FormatException(
      'Los peajes de regreso no pueden tener un importe negativo.',
    );
  }

  return TripBudgetEstimate(
    currencyCode: normalizedCurrency,
    energy: energy,
    tolls: calculateTripTollEstimate(
      route: route,
      currencyCode: normalizedCurrency,
    ),
    lodging: TripLodgingEstimate(
      nights: lodgingNights,
      nightlyRate: lodgingNightlyRate,
    ),
    includesReturn: includeReturn,
    returnEnergy: includeReturn ? returnEnergy : null,
    returnTollsAmount: includeReturn ? returnTollsAmount : null,
  );
}

TripTollEstimate? calculateTripTollEstimate({
  required RoadRoute? route,
  required String currencyCode,
}) {
  if (route == null || !route.tollDataIncluded) {
    return null;
  }

  final normalizedCurrency = currencyCode.trim().toUpperCase();

  if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
    throw const FormatException(
      'El código de moneda de los peajes no es válido.',
    );
  }

  var total = 0.0;
  var reportedTolls = 0;
  var pricedTolls = 0;
  var unpricedTolls = 0;

  final processedFareIds = <String>{};

  for (final toll in route.tolls) {
    final tollFareId = _sharedFareId(toll);

    if (tollFareId != null && processedFareIds.contains(tollFareId)) {
      continue;
    }

    if (tollFareId != null) {
      processedFareIds.add(tollFareId);
    }

    reportedTolls++;

    final amount = _singleTollAmount(toll, normalizedCurrency);

    if (amount == null) {
      unpricedTolls++;
      continue;
    }

    pricedTolls++;
    total += amount;
  }

  return TripTollEstimate(
    currencyCode: normalizedCurrency,
    knownAmount: total,
    reportedTolls: reportedTolls,
    pricedTolls: pricedTolls,
    unpricedTolls: unpricedTolls,
  );
}

String? _sharedFareId(RouteToll toll) {
  if (toll.fares.isEmpty) {
    return null;
  }

  final ids = toll.fares
      .map((fare) => fare.id?.trim())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();

  if (ids.length != 1 ||
      toll.fares.any((fare) => fare.id == null || fare.id!.trim().isEmpty)) {
    return null;
  }

  return ids.single;
}

double? _singleTollAmount(RouteToll toll, String currencyCode) {
  if (toll.fares.isEmpty) {
    return null;
  }

  final amounts = <double>[];

  for (final fare in toll.fares) {
    final amount = _fareAmountInCurrency(fare, currencyCode);

    if (amount == null) {
      return null;
    }

    amounts.add(amount);
  }

  final firstAmount = amounts.first;

  for (final amount in amounts.skip(1)) {
    if ((amount - firstAmount).abs() > 0.000001) {
      return null;
    }
  }

  return firstAmount;
}

double? _fareAmountInCurrency(RouteTollFare fare, String currencyCode) {
  final originalCurrency = fare.currencyCode?.trim().toUpperCase();
  final convertedCurrency = fare.convertedCurrencyCode?.trim().toUpperCase();

  if (originalCurrency == currencyCode && _validAmount(fare.amount)) {
    return fare.amount;
  }

  if (convertedCurrency == currencyCode && _validAmount(fare.convertedAmount)) {
    return fare.convertedAmount;
  }

  return null;
}

bool _validAmount(double? amount) {
  return amount != null && amount.isFinite && amount >= 0;
}
