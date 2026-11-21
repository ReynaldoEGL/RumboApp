import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_section.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_estimate.dart';
import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';

void main() {
  group('TripBudgetEstimate', () {
    test('suma combustible y tarifa de peaje', () {
      final route = _route([
        [
          _toll([_fare(id: 't1', amount: 150, currency: 'MXN')]),
        ],
      ]);
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: route,
        currencyCode: 'MXN',
        lodgingNights: 0,
      );
      expect(budget.tolls?.knownAmount, 150);
      expect(budget.knownSubtotal, 630);
      expect(budget.isPartial, isFalse);
    });

    test('no suma dos tarifas diferentes del mismo peaje', () {
      final route = _route([
        [
          _toll([
            _fare(id: 'cash', amount: 150, currency: 'MXN'),
            _fare(id: 'tag', amount: 120, currency: 'MXN'),
          ]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'MXN',
      );
      expect(tolls?.knownAmount, 0);
      expect(tolls?.unpricedTolls, 1);
      expect(tolls?.isComplete, isFalse);
    });

    test('acepta tarifas alternativas iguales', () {
      final route = _route([
        [
          _toll([
            _fare(id: 'cash', amount: 100, currency: 'MXN'),
            _fare(id: 'tag', amount: 100, currency: 'MXN'),
          ]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'MXN',
      );
      expect(tolls?.knownAmount, 100);
      expect(tolls?.isComplete, isTrue);
    });

    test('usa precio convertido en la moneda seleccionada', () {
      final route = _route([
        [
          _toll([
            _fare(
              id: 't1',
              amount: 200,
              currency: 'MXN',
              convertedAmount: 10,
              convertedCurrency: 'USD',
            ),
          ]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'USD',
      );
      expect(tolls?.knownAmount, 10);
      expect(tolls?.isComplete, isTrue);
    });

    test('no mezcla monedas distintas', () {
      final route = _route([
        [
          _toll([_fare(id: 't1', amount: 200, currency: 'MXN')]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'USD',
      );
      expect(tolls?.knownAmount, 0);
      expect(tolls?.unpricedTolls, 1);
    });

    test('no duplica la misma tarifa entre tramos', () {
      final route = _route([
        [
          _toll([_fare(id: 'shared', amount: 85, currency: 'MXN')]),
        ],
        [
          _toll([_fare(id: 'shared', amount: 85, currency: 'MXN')]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'MXN',
      );
      expect(tolls?.knownAmount, 85);
      expect(tolls?.reportedTolls, 1);
    });

    test('costos de peaje incompletos permanecen pendientes', () {
      final route = _route([
        [
          _toll([_fare(id: 't1', amount: 50, currency: 'MXN')]),
          _toll([]),
        ],
      ]);
      final tolls = calculateTripTollEstimate(
        route: route,
        currencyCode: 'MXN',
      );
      expect(tolls?.knownAmount, 50);
      expect(tolls?.unpricedTolls, 1);
      expect(tolls?.isComplete, isFalse);
    });

    test('ruta sin peajes reportados no añade importe', () {
      final tolls = calculateTripTollEstimate(
        route: _route([[]]),
        currencyCode: 'MXN',
      );
      expect(tolls?.reportedTolls, 0);
      expect(tolls?.knownAmount, 0);
      expect(tolls?.isComplete, isTrue);
    });

    test('sin ruta ni datos no inventa costos', () {
      final budget = calculateTripBudgetEstimate(
        energy: null,
        route: null,
        currencyCode: 'MXN',
      );
      expect(budget.tolls, isNull);
      expect(budget.hasKnownCosts, isFalse);
      expect(budget.isPartial, isTrue);
    });

    test('rechaza códigos de moneda inválidos', () {
      expect(
        () => calculateTripBudgetEstimate(
          energy: null,
          route: null,
          currencyCode: 'M',
        ),
        throwsFormatException,
      );
    });

    test('multiplica noches por tarifa sin mezclar otros gastos', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 2,
        lodgingNightlyRate: 900,
      );
      expect(budget.lodging.cost, 1800);
      expect(budget.knownSubtotal, 2280);
      expect(budget.isPartial, isFalse);
    });

    test('cero noches expresa que no se necesita hospedaje', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(500),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 0,
      );
      expect(budget.lodging.cost, 0);
      expect(budget.lodging.isComplete, isTrue);
      expect(budget.isPartial, isFalse);
    });

    test('noches sin tarifa no se cobran como si fueran gratis', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(500),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 2,
      );
      expect(budget.lodging.cost, isNull);
      expect(budget.knownSubtotal, 500);
      expect(budget.isPartial, isTrue);
    });

    test('el regreso usa otro consumo y casetas manuales', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 1,
        lodgingNightlyRate: 850,
        includeReturn: true,
        returnEnergy: _energy(390),
        returnTollsAmount: 120,
      );
      expect(budget.knownSubtotal, 1840);
      expect(budget.isPartial, isFalse);
    });

    test('regreso sin casetas definidas permanece parcial', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 0,
        includeReturn: true,
        returnEnergy: _energy(390),
      );
      expect(budget.knownSubtotal, 870);
      expect(budget.isPartial, isTrue);
    });

    test('cero peajes manuales de regreso es explícitamente válido', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 0,
        includeReturn: true,
        returnEnergy: _energy(390),
        returnTollsAmount: 0,
      );
      expect(budget.returnTollsAmount, 0);
      expect(budget.isPartial, isFalse);
    });

    test('desactivar regreso excluye los importes anteriores', () {
      final budget = calculateTripBudgetEstimate(
        energy: _energy(480),
        route: _route([[]]),
        currencyCode: 'MXN',
        lodgingNights: 0,
        includeReturn: false,
        returnEnergy: _energy(390),
        returnTollsAmount: 120,
      );
      expect(budget.returnEnergy, isNull);
      expect(budget.returnTollsAmount, isNull);
      expect(budget.knownSubtotal, 480);
    });

    test('rechaza precios negativos y noches negativas', () {
      expect(
        () => calculateTripBudgetEstimate(
          energy: null,
          route: null,
          currencyCode: 'MXN',
          lodgingNights: -1,
        ),
        throwsFormatException,
      );
      expect(
        () => calculateTripBudgetEstimate(
          energy: null,
          route: null,
          currencyCode: 'MXN',
          includeReturn: true,
          returnTollsAmount: -5,
        ),
        throwsFormatException,
      );
    });
  });
}

TripEnergyEstimate _energy(double cost) {
  return TripEnergyEstimate(
    quantity: cost / 24,
    unit: 'L',
    cost: cost,
    description: 'Consumo de prueba',
  );
}

RouteLocation _location(String id) {
  return RouteLocation(
    hereId: id,
    title: id,
    addressLabel: id,
    coordinate: const RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
  );
}

RoadRoute _route(List<List<RouteToll>> tollGroups) {
  final sections = <RouteSection>[];
  for (var index = 0; index < tollGroups.length; index++) {
    sections.add(
      RouteSection(
        id: 'section-$index',
        type: 'vehicle',
        transportMode: 'car',
        distanceMeters: 10000,
        durationSeconds: 600,
        geometry: const [
          RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
          RouteCoordinate(latitude: 20.5888, longitude: -100.3899),
        ],
        tolls: tollGroups[index],
      ),
    );
  }
  return RoadRoute(
    id: 'test-route',
    origin: _location('origin'),
    destination: _location('destination'),
    sections: sections,
    tollDataIncluded: true,
  );
}

RouteToll _toll(List<RouteTollFare> fares) {
  return RouteToll(
    countryCode: 'MX',
    tollSystem: 'Autopista de prueba',
    fares: fares,
  );
}

RouteTollFare _fare({
  required String id,
  required double amount,
  required String currency,
  double? convertedAmount,
  String? convertedCurrency,
}) {
  return RouteTollFare(
    id: id,
    name: 'Tarifa de prueba',
    priceType: 'value',
    amount: amount,
    currencyCode: currency,
    convertedAmount: convertedAmount,
    convertedCurrencyCode: convertedCurrency,
    reason: null,
    paymentMethods: const [],
  );
}
