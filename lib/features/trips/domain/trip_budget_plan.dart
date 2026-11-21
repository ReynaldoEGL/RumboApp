class TripBudgetPlan {
  const TripBudgetPlan({
    this.lodgingNights,
    this.lodgingNightlyRate,
    this.includeReturn = false,
    this.returnDistanceKm,
    this.returnTollsAmount,
  });

  final int? lodgingNights;
  final double? lodgingNightlyRate;
  final bool includeReturn;
  final double? returnDistanceKm;
  final double? returnTollsAmount;

  void validate() {
    if (lodgingNights != null && lodgingNights! < 0) {
      throw const FormatException(
        'Las noches de hospedaje no pueden ser negativas.',
      );
    }

    if (lodgingNightlyRate != null &&
        (!lodgingNightlyRate!.isFinite || lodgingNightlyRate! <= 0)) {
      throw const FormatException(
        'El precio por noche debe ser mayor que cero.',
      );
    }

    if (returnDistanceKm != null &&
        (!returnDistanceKm!.isFinite || returnDistanceKm! <= 0)) {
      throw const FormatException(
        'La distancia del regreso debe ser mayor que cero.',
      );
    }

    if (returnTollsAmount != null &&
        (!returnTollsAmount!.isFinite || returnTollsAmount! < 0)) {
      throw const FormatException(
        'Los peajes de regreso no pueden tener un importe negativo.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'includeReturn': includeReturn,
      if (lodgingNights != null) 'lodgingNights': lodgingNights,
      if (lodgingNightlyRate != null) 'lodgingNightlyRate': lodgingNightlyRate,
      if (returnDistanceKm != null) 'returnDistanceKm': returnDistanceKm,
      if (returnTollsAmount != null) 'returnTollsAmount': returnTollsAmount,
    };
  }

  factory TripBudgetPlan.fromMap(Map<Object?, Object?> rawData) {
    final plan = TripBudgetPlan(
      lodgingNights: _readNonNegativeInteger(rawData['lodgingNights']),
      lodgingNightlyRate: _readPositiveNumber(rawData['lodgingNightlyRate']),
      includeReturn: rawData['includeReturn'] == true,
      returnDistanceKm: _readPositiveNumber(rawData['returnDistanceKm']),
      returnTollsAmount: _readNonNegativeNumber(rawData['returnTollsAmount']),
    );

    plan.validate();
    return plan;
  }

  static int? _readNonNegativeInteger(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      return null;
    }

    if (value != value.truncateToDouble()) {
      return null;
    }

    return value.toInt();
  }

  static double? _readPositiveNumber(Object? value) {
    if (value is! num || !value.isFinite || value <= 0) {
      return null;
    }

    return value.toDouble();
  }

  static double? _readNonNegativeNumber(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      return null;
    }

    return value.toDouble();
  }
}
