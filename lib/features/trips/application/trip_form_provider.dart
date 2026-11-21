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
    this.lodgingNights,
    this.lodgingNightlyRate,
    this.includeReturn = false,
    this.returnDistanceKm,
    this.returnTollsAmount,
  });

  final String? vehicleId;
  final TripStatus status;
  final double? distanceKm;
  final double? energyUnitPrice;
  final String currencyCode;
  final int? lodgingNights;
  final double? lodgingNightlyRate;
  final bool includeReturn;
  final double? returnDistanceKm;
  final double? returnTollsAmount;

  TripFormSelections copyWith({
    String? vehicleId,
    bool clearVehicleId = false,
    TripStatus? status,
    double? distanceKm,
    bool clearDistanceKm = false,
    double? energyUnitPrice,
    bool clearEnergyUnitPrice = false,
    String? currencyCode,
    int? lodgingNights,
    bool clearLodgingNights = false,
    double? lodgingNightlyRate,
    bool clearLodgingNightlyRate = false,
    bool? includeReturn,
    double? returnDistanceKm,
    bool clearReturnDistanceKm = false,
    double? returnTollsAmount,
    bool clearReturnTollsAmount = false,
  }) {
    return TripFormSelections(
      vehicleId: clearVehicleId ? null : vehicleId ?? this.vehicleId,
      status: status ?? this.status,
      distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      energyUnitPrice: clearEnergyUnitPrice
          ? null
          : energyUnitPrice ?? this.energyUnitPrice,
      currencyCode: currencyCode ?? this.currencyCode,
      lodgingNights: clearLodgingNights
          ? null
          : lodgingNights ?? this.lodgingNights,
      lodgingNightlyRate: clearLodgingNightlyRate
          ? null
          : lodgingNightlyRate ?? this.lodgingNightlyRate,
      includeReturn: includeReturn ?? this.includeReturn,
      returnDistanceKm: clearReturnDistanceKm
          ? null
          : returnDistanceKm ?? this.returnDistanceKm,
      returnTollsAmount: clearReturnTollsAmount
          ? null
          : returnTollsAmount ?? this.returnTollsAmount,
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

    if (normalized != state.vehicleId) {
      state = state.copyWith(vehicleId: normalized);
    }
  }

  void clearVehicle() {
    if (state.vehicleId != null) {
      state = state.copyWith(clearVehicleId: true);
    }
  }

  void setStatus(TripStatus value) {
    if (value != state.status) {
      state = state.copyWith(status: value);
    }
  }

  void setDistanceKm(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearDistanceKm: true);
      return;
    }

    if (value != state.distanceKm) {
      state = state.copyWith(distanceKm: value);
    }
  }

  void setEnergyUnitPrice(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearEnergyUnitPrice: true);
      return;
    }

    if (value != state.energyUnitPrice) {
      state = state.copyWith(energyUnitPrice: value);
    }
  }

  void setCurrencyCode(String value) {
    final normalized = value.trim().toUpperCase();

    if (RegExp(r'^[A-Z]{3}$').hasMatch(normalized) &&
        normalized != state.currencyCode) {
      state = state.copyWith(currencyCode: normalized);
    }
  }

  void setLodgingNights(int? value) {
    if (value == null || value < 0) {
      state = state.copyWith(clearLodgingNights: true);
      return;
    }

    if (value != state.lodgingNights) {
      state = state.copyWith(lodgingNights: value);
    }
  }

  void setLodgingNightlyRate(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearLodgingNightlyRate: true);
      return;
    }

    if (value != state.lodgingNightlyRate) {
      state = state.copyWith(lodgingNightlyRate: value);
    }
  }

  void setIncludeReturn(bool value) {
    if (value != state.includeReturn) {
      state = state.copyWith(includeReturn: value);
    }
  }

  void setReturnDistanceKm(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      state = state.copyWith(clearReturnDistanceKm: true);
      return;
    }

    if (value != state.returnDistanceKm) {
      state = state.copyWith(returnDistanceKm: value);
    }
  }

  void setReturnTollsAmount(double? value) {
    if (value == null || !value.isFinite || value < 0) {
      state = state.copyWith(clearReturnTollsAmount: true);
      return;
    }

    if (value != state.returnTollsAmount) {
      state = state.copyWith(returnTollsAmount: value);
    }
  }
}
