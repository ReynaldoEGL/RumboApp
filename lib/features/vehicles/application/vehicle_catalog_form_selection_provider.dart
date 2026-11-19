import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef VehicleCatalogFormSelectionArgs = ({
  Object sessionKey,
  String? brandId,
  String? modelId,
  String? countryCode,
  String? regionCode,
  int? year,
});

class VehicleCatalogFormSelections {
  const VehicleCatalogFormSelections({
    this.brandId,
    this.modelId,
    this.countryCode,
    this.regionCode,
    this.year,
  });

  final String? brandId;
  final String? modelId;
  final String? countryCode;
  final String? regionCode;
  final int? year;

  VehicleCatalogFormSelections copyWith({
    String? brandId,
    bool clearBrandId = false,
    String? modelId,
    bool clearModelId = false,
    String? countryCode,
    bool clearCountryCode = false,
    String? regionCode,
    bool clearRegionCode = false,
    int? year,
    bool clearYear = false,
  }) {
    return VehicleCatalogFormSelections(
      brandId: clearBrandId ? null : brandId ?? this.brandId,
      modelId: clearModelId ? null : modelId ?? this.modelId,
      countryCode: clearCountryCode ? null : countryCode ?? this.countryCode,
      regionCode: clearRegionCode ? null : regionCode ?? this.regionCode,
      year: clearYear ? null : year ?? this.year,
    );
  }
}

final vehicleCatalogFormSelectionsProvider = NotifierProvider.autoDispose
    .family<
      VehicleCatalogFormSelectionController,
      VehicleCatalogFormSelections,
      VehicleCatalogFormSelectionArgs
    >(VehicleCatalogFormSelectionController.new);

class VehicleCatalogFormSelectionController
    extends Notifier<VehicleCatalogFormSelections> {
  VehicleCatalogFormSelectionController(this.initialSelections);

  final VehicleCatalogFormSelectionArgs initialSelections;

  @override
  VehicleCatalogFormSelections build() {
    return VehicleCatalogFormSelections(
      brandId: initialSelections.brandId,
      modelId: initialSelections.modelId,
      countryCode: initialSelections.countryCode,
      regionCode: initialSelections.regionCode,
      year: initialSelections.year,
    );
  }

  void selectBrand(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized == state.brandId) {
      return;
    }

    state = state.copyWith(brandId: normalized, clearModelId: true);
  }

  void clearBrand() {
    if (state.brandId == null && state.modelId == null) {
      return;
    }

    state = state.copyWith(clearBrandId: true, clearModelId: true);
  }

  void selectModel(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized == state.modelId) {
      return;
    }

    state = state.copyWith(modelId: normalized);
  }

  void clearModel() {
    if (state.modelId == null) {
      return;
    }

    state = state.copyWith(clearModelId: true);
  }

  void selectCountry(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.isEmpty || normalized == state.countryCode) {
      return;
    }

    state = state.copyWith(countryCode: normalized, clearRegionCode: true);
  }

  void clearCountry() {
    if (state.countryCode == null && state.regionCode == null) {
      return;
    }

    state = state.copyWith(clearCountryCode: true, clearRegionCode: true);
  }

  void selectRegion(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.isEmpty || normalized == state.regionCode) {
      return;
    }

    state = state.copyWith(regionCode: normalized);
  }

  void clearRegion() {
    if (state.regionCode == null) {
      return;
    }

    state = state.copyWith(clearRegionCode: true);
  }

  void setYear(int? value) {
    if (value == state.year) {
      return;
    }

    state = state.copyWith(
      year: value,
      clearYear: value == null,
      clearModelId: true,
    );
  }
}
