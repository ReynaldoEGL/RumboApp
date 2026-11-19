import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Argumentos iniciales de cada formulario.
///
/// sessionKey identifica una instancia específica del formulario.
/// Esto permite mantener independientes las selecciones de diferentes
/// vehículos y formularios.
typedef VehicleFormSelectionArgs = ({
  String? vehicleType,
  String? fuelType,
  Object sessionKey,
});

/// Estado de las selecciones del formulario.
class VehicleFormSelections {
  const VehicleFormSelections({
    this.vehicleType,
    this.fuelType,
    this.isSaving = false,
  });

  final String? vehicleType;
  final String? fuelType;
  final bool isSaving;

  /// Crea una nueva instancia conservando los valores no modificados.
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

/// Provider independiente para cada instancia del formulario.
///
/// Configuración para Riverpod 3:
/// - Notifier unificado.
/// - autoDispose para liberar el estado al abandonar el formulario.
/// - family para recibir las selecciones iniciales.
/// - El argumento se recibe en el constructor del Notifier.
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
    // El estado inicial se construye directamente.
    //
    // No utilizar initialize() desde initState ni modificar
    // el provider durante la construcción de los widgets.
    return VehicleFormSelections(
      vehicleType: initialSelections.vehicleType,
      fuelType: initialSelections.fuelType,
      isSaving: false,
    );
  }

  /// Actualiza el tipo de vehículo.
  void setVehicleType(String? value) {
    if (value == null || value == state.vehicleType) {
      return;
    }

    state = state.copyWith(vehicleType: value);
  }

  /// Actualiza el tipo de combustible o energía.
  void setFuelType(String? value) {
    if (value == null || value == state.fuelType) {
      return;
    }

    state = state.copyWith(fuelType: value);
  }

  /// Actualiza el indicador de guardado.
  void setSaving(bool value) {
    if (value == state.isSaving) {
      return;
    }

    state = state.copyWith(isSaving: value);
  }
}
