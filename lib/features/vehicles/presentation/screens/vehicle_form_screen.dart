import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/vehicles/application/vehicle_form_selection_provider.dart';
import 'package:rumboapp/features/vehicles/application/vehicle_providers.dart';
import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  /// Si es null, se registra un vehículo nuevo.
  /// Si contiene un vehículo, se abre el formulario en modo edición.
  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Identifica esta instancia del formulario.
  ///
  /// Se conserva durante toda la vida de la pantalla para que Riverpod
  /// no confunda las selecciones de formularios diferentes.
  final Object _formSessionKey = Object();

  // ---------------------------------------------------------------------------
  // CONTROLADORES DE TEXTO
  // ---------------------------------------------------------------------------

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;

  late final TextEditingController _fuelConsumptionController;
  late final TextEditingController _electricConsumptionController;

  late final TextEditingController _registrationCountryController;
  late final TextEditingController _registrationRegionController;
  late final TextEditingController _plateEndingController;

  late final TextEditingController _insuranceCompanyController;
  late final TextEditingController _insuranceDateController;

  late final TextEditingController _verificationHologramController;
  late final TextEditingController _verificationDateController;

  DateTime? _insuranceValidUntil;
  DateTime? _verificationValidUntil;
  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  /// Argumentos utilizados por la familia del provider.
  ///
  /// Los valores iniciales provienen del vehículo cuando se está editando.
  VehicleFormSelectionArgs get _selectionArgs {
    return (
      vehicleType: widget.vehicle?.vehicleType,
      fuelType: widget.vehicle?.fuelType,
      sessionKey: _formSessionKey,
    );
  }

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    // Los controladores de texto se inicializan aquí.
    // No modificamos ningún provider durante initState.

    _brandController = TextEditingController(text: vehicle?.brand ?? '');

    _modelController = TextEditingController(text: vehicle?.model ?? '');

    _yearController = TextEditingController(
      text: vehicle?.year.toString() ?? '',
    );

    _fuelConsumptionController = TextEditingController(
      text: vehicle?.fuelConsumptionKmPerLiter?.toString() ?? '',
    );

    _electricConsumptionController = TextEditingController(
      text: vehicle?.electricConsumptionKwhPer100Km?.toString() ?? '',
    );

    _registrationCountryController = TextEditingController(
      text: vehicle?.registrationCountry ?? '',
    );

    _registrationRegionController = TextEditingController(
      text: vehicle?.registrationRegion ?? '',
    );

    _plateEndingController = TextEditingController(
      text: vehicle?.plateEnding ?? '',
    );

    _insuranceCompanyController = TextEditingController(
      text: vehicle?.insuranceCompany ?? '',
    );

    _insuranceValidUntil = vehicle?.insuranceValidUntil;

    _insuranceDateController = TextEditingController(
      text: _formatDate(_insuranceValidUntil),
    );

    _verificationHologramController = TextEditingController(
      text: vehicle?.verificationHologram ?? '',
    );

    _verificationValidUntil = vehicle?.verificationValidUntil;

    _verificationDateController = TextEditingController(
      text: _formatDate(_verificationValidUntil),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();

    _fuelConsumptionController.dispose();
    _electricConsumptionController.dispose();

    _registrationCountryController.dispose();
    _registrationRegionController.dispose();
    _plateEndingController.dispose();

    _insuranceCompanyController.dispose();
    _insuranceDateController.dispose();

    _verificationHologramController.dispose();
    _verificationDateController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FORMATO DE DATOS
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String? _readOptionalText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  double? _readPositiveNumber(TextEditingController controller) {
    final value = controller.text.trim().replaceAll(',', '.');

    if (value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value);

    if (number == null || !number.isFinite || number <= 0) {
      return null;
    }

    return number;
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES
  // ---------------------------------------------------------------------------

  String? _validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $fieldName.';
    }

    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el año del vehículo.';
    }

    final year = int.tryParse(value.trim());

    if (year == null) {
      return 'Ingresa un año válido.';
    }

    if (year < 1886 || year > DateTime.now().year + 1) {
      return 'El año está fuera del rango permitido.';
    }

    return null;
  }

  String? _validatePlateEnding(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final plate = value.trim();

    if (plate.length > 12) {
      return 'La terminación no puede superar 12 caracteres.';
    }

    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(plate)) {
      return 'Utiliza únicamente letras, números y guiones.';
    }

    return null;
  }

  String? _validatePositiveNumber(
    String? value, {
    required bool requiredValue,
  }) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';

    if (normalized.isEmpty) {
      return requiredValue ? 'Este consumo es obligatorio.' : null;
    }

    final number = double.tryParse(normalized);

    if (number == null || !number.isFinite || number <= 0) {
      return 'Ingresa un número mayor que cero.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // CLASIFICACIÓN DEL COMBUSTIBLE
  // ---------------------------------------------------------------------------

  String _normalizeFuelType(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  bool _isGasoline(String? value) {
    return _normalizeFuelType(value) == 'gasoline';
  }

  bool _isDiesel(String? value) {
    return _normalizeFuelType(value) == 'diesel';
  }

  bool _isElectric(String? value) {
    return _normalizeFuelType(value) == 'electric';
  }

  bool _isHybrid(String? value) {
    return _normalizeFuelType(value) == 'hybrid';
  }

  bool _requiresFuelConsumption(String? value) {
    return _isGasoline(value) || _isDiesel(value) || _isHybrid(value);
  }

  bool _requiresElectricConsumption(String? value) {
    return _isElectric(value) || _isHybrid(value);
  }

  bool _isFuelConsumptionRequired(String? value) {
    return _isGasoline(value) || _isDiesel(value) || _isHybrid(value);
  }

  bool _isElectricConsumptionRequired(String? value) {
    return _isElectric(value);
  }

  // ---------------------------------------------------------------------------
  // OPCIONES DE LOS DESPLEGABLES
  // ---------------------------------------------------------------------------

  List<DropdownMenuItem<String>> _buildDropdownItems({
    required List<String> values,
    required Map<String, String> labels,
    required String? currentValue,
  }) {
    final items = <DropdownMenuItem<String>>[];

    // Si un registro anterior contiene un valor que ya no está en el
    // catálogo actual, se conserva como opción para no perderlo al editar.
    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !values.contains(currentValue)) {
      items.add(
        DropdownMenuItem<String>(
          value: currentValue,
          child: Text('Valor existente: $currentValue'),
        ),
      );
    }

    for (final value in values) {
      items.add(
        DropdownMenuItem<String>(
          value: value,
          child: Text(labels[value] ?? value),
        ),
      );
    }

    return items;
  }

  List<DropdownMenuItem<String>> _vehicleTypeItems(String? currentValue) {
    const values = ['car', 'motorcycle', 'pickup', 'van', 'truck', 'other'];

    const labels = {
      'car': 'Automóvil',
      'motorcycle': 'Motocicleta',
      'pickup': 'Camioneta pickup',
      'van': 'Van',
      'truck': 'Camión',
      'other': 'Otro',
    };

    return _buildDropdownItems(
      values: values,
      labels: labels,
      currentValue: currentValue,
    );
  }

  List<DropdownMenuItem<String>> _fuelTypeItems(String? currentValue) {
    const values = ['gasoline', 'diesel', 'electric', 'hybrid', 'other'];

    const labels = {
      'gasoline': 'Gasolina',
      'diesel': 'Diésel',
      'electric': 'Eléctrico',
      'hybrid': 'Híbrido',
      'other': 'Otro',
    };

    return _buildDropdownItems(
      values: values,
      labels: labels,
      currentValue: currentValue,
    );
  }

  // ---------------------------------------------------------------------------
  // DECORACIÓN Y CAMPOS REUTILIZABLES
  // ---------------------------------------------------------------------------

  InputDecoration _decoration(
    String label, {
    String? hint,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(),
      alignLabelWithHint: true,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _decoration(label, hint: hint, suffixText: suffixText),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  // ---------------------------------------------------------------------------
  // DESPLEGABLE DE TIPO DE VEHÍCULO
  // ---------------------------------------------------------------------------

  Widget _vehicleTypeDropdown(
    VehicleFormSelections selections,
    VehicleFormSelectionsController controller,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: selections.vehicleType,
      isExpanded: true,
      decoration: _decoration('Tipo de vehículo'),
      items: _vehicleTypeItems(selections.vehicleType),
      onChanged: controller.setVehicleType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona el tipo de vehículo.';
        }

        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DESPLEGABLE DE COMBUSTIBLE
  // ---------------------------------------------------------------------------

  Widget _fuelTypeDropdown(
    VehicleFormSelections selections,
    VehicleFormSelectionsController controller,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: selections.fuelType,
      isExpanded: true,
      decoration: _decoration('Tipo de energía o combustible'),
      items: _fuelTypeItems(selections.fuelType),
      onChanged: controller.setFuelType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona el tipo de energía.';
        }

        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CAMPOS DE CONSUMO
  // ---------------------------------------------------------------------------

  Widget _fuelConsumptionField({required bool requiredValue}) {
    return _textField(
      controller: _fuelConsumptionController,
      label: 'Consumo de combustible',
      hint: 'Ej. 14.5',
      suffixText: 'km/L',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      validator: (value) {
        return _validatePositiveNumber(value, requiredValue: requiredValue);
      },
    );
  }

  Widget _electricConsumptionField({required bool requiredValue}) {
    return _textField(
      controller: _electricConsumptionController,
      label: 'Consumo eléctrico',
      hint: 'Ej. 16.8',
      suffixText: 'kWh/100 km',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      validator: (value) {
        return _validatePositiveNumber(value, requiredValue: requiredValue);
      },
    );
  }

  Widget _consumptionFields(String? fuelType) {
    final showFuel = _requiresFuelConsumption(fuelType);
    final showElectric = _requiresElectricConsumption(fuelType);

    if (!showFuel && !showElectric) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Para este tipo de energía no se registrará un '
                  'consumo automático. Puedes continuar con los '
                  'demás datos del vehículo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFuel) ...[
          _fuelConsumptionField(
            requiredValue: _isFuelConsumptionRequired(fuelType),
          ),
          const SizedBox(height: 16),
        ],
        if (showElectric) ...[
          _electricConsumptionField(
            requiredValue: _isElectricConsumptionRequired(fuelType),
          ),
          if (_isHybrid(fuelType))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'En vehículos híbridos, el consumo eléctrico es opcional. '
                'Se recomienda registrarlo cuando el vehículo permita '
                'recarga externa. Los cálculos posteriores deberán '
                'distinguir los kilómetros recorridos en cada modo '
                'de energía.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FECHAS DE VIGENCIA
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({required bool isInsuranceDate}) async {
    final currentDate = isInsuranceDate
        ? _insuranceValidUntil
        : _verificationValidUntil;

    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 30, 12, 31),
      helpText: isInsuranceDate
          ? 'Vigencia del seguro'
          : 'Vigencia de la verificación',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    if (isInsuranceDate) {
      _insuranceValidUntil = pickedDate;
      _insuranceDateController.text = _formatDate(pickedDate);
    } else {
      _verificationValidUntil = pickedDate;
      _verificationDateController.text = _formatDate(pickedDate);
    }
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _decoration(
        label,
        hint: 'Selecciona una fecha',
        suffixIcon: IconButton(
          tooltip: 'Seleccionar fecha',
          onPressed: onTap,
          icon: const Icon(Icons.calendar_month),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GUARDAR VEHÍCULO
  // ---------------------------------------------------------------------------

  Future<void> _saveVehicle() async {
    FocusScope.of(context).unfocus();

    // Evita envíos duplicados.
    final selectionProvider = vehicleFormSelectionsProvider(_selectionArgs);

    final currentSelections = ref.read(selectionProvider);

    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vehicleType = currentSelections.vehicleType;
    final fuelType = currentSelections.fuelType;

    if (vehicleType == null || fuelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el tipo de vehículo y su energía.'),
        ),
      );
      return;
    }

    final year = int.tryParse(_yearController.text.trim());

    if (year == null) {
      return;
    }

    // Solo se guardan los consumos correspondientes al combustible
    // seleccionado. Los campos ocultos no conservan valores anteriores
    // que ya no correspondan a la nueva selección.
    final fuelConsumption = _requiresFuelConsumption(fuelType)
        ? _readPositiveNumber(_fuelConsumptionController)
        : null;

    final electricConsumption = _requiresElectricConsumption(fuelType)
        ? _readPositiveNumber(_electricConsumptionController)
        : null;

    if (_isFuelConsumptionRequired(fuelType) && fuelConsumption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un consumo de combustible válido en km/L.'),
        ),
      );
      return;
    }

    if (_isElectricConsumptionRequired(fuelType) &&
        electricConsumption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un consumo eléctrico válido en kWh/100 km.'),
        ),
      );
      return;
    }

    final existingVehicle = widget.vehicle;
    final now = DateTime.now().millisecondsSinceEpoch;

    final vehicle = Vehicle(
      id: existingVehicle?.id ?? '',
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: year,
      vehicleType: vehicleType,
      fuelType: fuelType,
      fuelConsumptionKmPerLiter: fuelConsumption,
      electricConsumptionKwhPer100Km: electricConsumption,
      registrationCountry: _registrationCountryController.text.trim(),
      registrationRegion: _registrationRegionController.text.trim(),
      plateEnding: _readOptionalText(_plateEndingController)?.toUpperCase(),
      insuranceCompany: _readOptionalText(_insuranceCompanyController),
      verificationHologram: _readOptionalText(_verificationHologramController),
      insuranceValidUntil: _insuranceValidUntil,
      verificationValidUntil: _verificationValidUntil,
      createdAt: existingVehicle?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(vehicleControllerProvider.notifier);
      if (_isEditing) {
        await controller.updateVehicle(vehicle);
      } else {
        await controller.addVehicle(vehicle);
      }

      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Vehículo actualizado correctamente.'
                : 'Vehículo registrado correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar el vehículo: $error')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // INTERFAZ PRINCIPAL
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selectionProvider = vehicleFormSelectionsProvider(_selectionArgs);

    final selections = ref.watch(selectionProvider);

    final selectionController = ref.read(selectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar vehículo' : 'Registrar vehículo'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------------------------------------------------------------
              // INFORMACIÓN GENERAL
              // ---------------------------------------------------------------

              _sectionTitle('Información general'),

              _textField(
                controller: _brandController,
                label: 'Marca',
                hint: 'Ej. Toyota',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  return _validateRequired(value, fieldName: 'la marca');
                },
              ),
              const SizedBox(height: 16),

              _textField(
                controller: _modelController,
                label: 'Modelo',
                hint: 'Ej. Corolla',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  return _validateRequired(value, fieldName: 'el modelo');
                },
              ),
              const SizedBox(height: 16),

              _textField(
                controller: _yearController,
                label: 'Año',
                hint: 'Ej. 2022',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: _validateYear,
              ),
              const SizedBox(height: 16),

              _vehicleTypeDropdown(selections, selectionController),
              const SizedBox(height: 16),

              _fuelTypeDropdown(selections, selectionController),

              // ---------------------------------------------------------------
              // CONSUMO ENERGÉTICO
              // ---------------------------------------------------------------
              const SizedBox(height: 28),

              _sectionTitle('Consumo energético'),

              Text(
                'Registra el consumo aproximado del vehículo. '
                'Estos valores servirán como referencia para los cálculos '
                'de combustible y energía durante la planeación de viajes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              _consumptionFields(selections.fuelType),

              // ---------------------------------------------------------------
              // REGISTRO Y PLACAS
              // ---------------------------------------------------------------
              const SizedBox(height: 28),

              _sectionTitle('Registro y placas'),

              _textField(
                controller: _registrationCountryController,
                label: 'País de registro',
                hint: 'Ej. México',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  return _validateRequired(
                    value,
                    fieldName: 'el país de registro',
                  );
                },
              ),
              const SizedBox(height: 16),

              _textField(
                controller: _registrationRegionController,
                label: 'Estado o región de registro',
                hint: 'Ej. Guanajuato',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  return _validateRequired(
                    value,
                    fieldName: 'el estado o región',
                  );
                },
              ),
              const SizedBox(height: 16),

              _textField(
                controller: _plateEndingController,
                label: 'Terminación de placa',
                hint: 'Ej. 123-E',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: _validatePlateEnding,
              ),
              const SizedBox(height: 8),

              Text(
                'Puedes registrar letras, números y guiones. Rumbo '
                'obtendrá el último dígito numérico cuando exista. '
                'Este dato no sustituye la identificación completa '
                'de la placa.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              // ---------------------------------------------------------------
              // SEGURO
              // ---------------------------------------------------------------
              const SizedBox(height: 28),

              _sectionTitle('Seguro'),

              _textField(
                controller: _insuranceCompanyController,
                label: 'Aseguradora',
                hint: 'Ej. Nombre de la aseguradora',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              _dateField(
                controller: _insuranceDateController,
                label: 'Vigencia del seguro',
                onTap: () {
                  _pickDate(isInsuranceDate: true);
                },
              ),

              // ---------------------------------------------------------------
              // VERIFICACIÓN
              // ---------------------------------------------------------------
              const SizedBox(height: 28),

              _sectionTitle('Verificación y holograma'),

              _textField(
                controller: _verificationHologramController,
                label: 'Holograma o distintivo',
                hint: 'Ej. 00, 0, 1, 2 o descripción',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              _dateField(
                controller: _verificationDateController,
                label: 'Vigencia de la verificación',
                onTap: () {
                  _pickDate(isInsuranceDate: false);
                },
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los datos del seguro, la verificación y el '
                          'holograma son declarados por el usuario. '
                          'Su registro en Rumbo no constituye una '
                          'validación oficial de vigencia ni determina '
                          'por sí mismo las restricciones para circular.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // GUARDAR
              // ---------------------------------------------------------------
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isSaving ? null : _saveVehicle,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : _isEditing
                      ? 'Actualizar vehículo'
                      : 'Guardar vehículo',
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
