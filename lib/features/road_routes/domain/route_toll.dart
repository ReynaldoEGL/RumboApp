class RouteTollFare {
  const RouteTollFare({
    required this.id,
    required this.name,
    required this.priceType,
    required this.amount,
    required this.currencyCode,
    required this.convertedAmount,
    required this.convertedCurrencyCode,
    required this.reason,
    required this.paymentMethods,
  });

  final String? id;
  final String name;
  final String? priceType;
  final double? amount;
  final String? currencyCode;
  final double? convertedAmount;
  final String? convertedCurrencyCode;
  final String? reason;
  final List<String> paymentMethods;

  factory RouteTollFare.fromHereMap(Map<Object?, Object?> data) {
    final price = _optionalMap(data['price']);
    final convertedPrice = _optionalMap(data['convertedPrice']);

    return RouteTollFare(
      id: _optionalString(data['id']),
      name: _optionalString(data['name']) ?? 'Tarifa de peaje',
      priceType: _optionalString(price?['type']),
      amount: _optionalNonNegativeNumber(price?['value']),
      currencyCode: _optionalString(price?['currency']),
      convertedAmount: _optionalNonNegativeNumber(convertedPrice?['value']),
      convertedCurrencyCode: _optionalString(convertedPrice?['currency']),
      reason: _optionalString(data['reason']),
      paymentMethods: _readStringList(data['paymentMethods']),
    );
  }

  factory RouteTollFare.fromMap(Map<Object?, Object?> data) {
    return RouteTollFare(
      id: _optionalString(data['id']),
      name: _optionalString(data['name']) ?? 'Tarifa de peaje',
      priceType: _optionalString(data['priceType']),
      amount: _optionalNonNegativeNumber(data['amount']),
      currencyCode: _optionalString(data['currencyCode']),
      convertedAmount: _optionalNonNegativeNumber(data['convertedAmount']),
      convertedCurrencyCode: _optionalString(data['convertedCurrencyCode']),
      reason: _optionalString(data['reason']),
      paymentMethods: _readStringList(data['paymentMethods']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (priceType != null) 'priceType': priceType,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currencyCode': currencyCode,
      if (convertedAmount != null) 'convertedAmount': convertedAmount,
      if (convertedCurrencyCode != null)
        'convertedCurrencyCode': convertedCurrencyCode,
      if (reason != null) 'reason': reason,
      'paymentMethods': paymentMethods,
    };
  }
}

class RouteToll {
  const RouteToll({
    required this.countryCode,
    required this.tollSystem,
    required this.fares,
  });

  final String? countryCode;
  final String? tollSystem;
  final List<RouteTollFare> fares;

  factory RouteToll.fromHereMap(Map<Object?, Object?> data) {
    final rawFares = data['fares'];

    final fares = rawFares is List
        ? rawFares
              .whereType<Map>()
              .map(
                (fare) =>
                    RouteTollFare.fromHereMap(Map<Object?, Object?>.from(fare)),
              )
              .toList()
        : <RouteTollFare>[];

    return RouteToll(
      countryCode: _optionalString(data['countryCode']),
      tollSystem: _optionalString(data['tollSystem']),
      fares: List.unmodifiable(fares),
    );
  }

  factory RouteToll.fromMap(Map<Object?, Object?> data) {
    final rawFares = data['fares'];

    final fares = rawFares is List
        ? rawFares
              .whereType<Map>()
              .map(
                (fare) =>
                    RouteTollFare.fromMap(Map<Object?, Object?>.from(fare)),
              )
              .toList()
        : <RouteTollFare>[];

    return RouteToll(
      countryCode: _optionalString(data['countryCode']),
      tollSystem: _optionalString(data['tollSystem']),
      fares: List.unmodifiable(fares),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (countryCode != null) 'countryCode': countryCode,
      if (tollSystem != null) 'tollSystem': tollSystem,
      'fares': fares.map((fare) => fare.toMap()).toList(),
    };
  }
}

Map<Object?, Object?>? _optionalMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return Map<Object?, Object?>.from(value);
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value.trim();
}

double? _optionalNonNegativeNumber(Object? value) {
  if (value is! num) {
    return null;
  }

  final result = value.toDouble();

  if (!result.isFinite || result < 0) {
    return null;
  }

  return result;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  final values = value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  return List.unmodifiable(values);
}
