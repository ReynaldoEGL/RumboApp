import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifica los valores iniciales de cada formulario.
typedef VehicleFormSelectionArgs = ({
  String? vehicleType,
  String? fuelType,
  Object sessionKey,
});

/// Estado de las selecciones y del envío del formulario.
class VehicleFormSelections {
  const VehicleFormSelections({
    this.vehicleType,
    this.fuelType,
    this.isSaving = false,
  });

  final String? vehicleType;
  final String? fuelType;
  final bool isSaving;

  VehicleFormSelections copyWith({
    String? vehicleType,
    String? fuelType,
    bool? isSaving,
  }) {
    return VehicleFormSelections(
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Provider autoDispose independiente por formulario.
final vehicleFormSelectionsProvider = NotifierProvider.autoDispose
    .family<
      VehicleFormSelectionsController,
      VehicleFormSelections,
      VehicleFormSelectionArgs
    >(VehicleFormSelectionsController.new);

class VehicleFormSelectionsController extends Notifier<VehicleFormSelections> {
  VehicleFormSelectionsController(this.initialSelections);

  final VehicleFormSelectionArgs initialSelections;

  @override
  VehicleFormSelections build() {
    return VehicleFormSelections(
      vehicleType: initialSelections.vehicleType,
      fuelType: initialSelections.fuelType,
    );
  }

  void setVehicleType(String? value) {
    if (value == null || value == state.vehicleType) {
      return;
    }

    state = state.copyWith(vehicleType: value);
  }

  void setFuelType(String? value) {
    if (value == null || value == state.fuelType) {
      return;
    }

    state = state.copyWith(fuelType: value);
  }

  /// Controla el estado de guardado del formulario.
  void setSaving(bool value) {
    if (value == state.isSaving) {
      return;
    }

    state = state.copyWith(isSaving: value);
  }
}
