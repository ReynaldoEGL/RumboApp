import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';

typedef TripFormArgs = ({
  Object sessionKey,
  String? vehicleId,
  TripStatus status,
  double? distanceKm,
  double? energyUnitPrice,
  String currencyCode,
});

class TripFormSelections {
  const TripFormSelections({
    this.vehicleId,
    this.status = TripStatus.planned,
    this.distanceKm,
    this.energyUnitPrice,
    this.currencyCode = 'MXN',
  });

  final String? vehicleId;
  final TripStatus status;
  final double? distanceKm;
  final double? energyUnitPrice;
  final String currencyCode;

  TripFormSelections copyWith({
    String? vehicleId,
    bool clearVehicleId = false,
    TripStatus? status,
    double? distanceKm,
    bool clearDistanceKm = false,
    double? energyUnitPrice,
    bool clearEnergyUnitPrice = false,
    String? currencyCode,
  }) {
    return TripFormSelections(
      vehicleId: clearVehicleId ? null : vehicleId ?? this.vehicleId,
      status: status ?? this.status,
      distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      energyUnitPrice: clearEnergyUnitPrice
          ? null
          : energyUnitPrice ?? this.energyUnitPrice,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}

final tripFormProvider = NotifierProvider.autoDispose
    .family<TripFormController, TripFormSelections, TripFormArgs>(
      TripFormController.new,
    );

class TripFormController extends Notifier<TripFormSelections> {
  TripFormController(this.initialValues);

  final TripFormArgs initialValues;

  @override
  TripFormSelections build() {
    return TripFormSelections(
      vehicleId: initialValues.vehicleId,
      status: initialValues.status,
      distanceKm: initialValues.distanceKm,
      energyUnitPrice: initialValues.energyUnitPrice,
      currencyCode: initialValues.currencyCode,
    );
  }

  void selectVehicle(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      clearVehicle();
      return;
    }

    if (normalized == state.vehicleId) {
      return;
    }

    state = state.copyWith(vehicleId: normalized);
  }

  void clearVehicle() {
    if (state.vehicleId == null) {
      return;
    }

    state = state.copyWith(clearVehicleId: true);
  }

  void setStatus(TripStatus value) {
    if (value == state.status) {
      return;
    }

    state = state.copyWith(status: value);
  }

  void setDistanceKm(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearDistanceKm: true);
      return;
    }

    if (value == state.distanceKm) {
      return;
    }

    state = state.copyWith(distanceKm: value);
  }

  void setEnergyUnitPrice(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearEnergyUnitPrice: true);
      return;
    }

    if (value == state.energyUnitPrice) {
      return;
    }

    state = state.copyWith(energyUnitPrice: value);
  }

  void setCurrencyCode(String value) {
    final normalized = value.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized) ||
        normalized == state.currencyCode) {
      return;
    }

    state = state.copyWith(currencyCode: normalized);
  }
}
