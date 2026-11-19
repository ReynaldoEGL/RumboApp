import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/vehicles/application/vehicle_catalog_form_selection_provider.dart';
import 'package:rumboapp/features/vehicles/application/vehicle_catalog_providers.dart';
import 'package:rumboapp/features/vehicles/application/vehicle_form_selection_provider.dart';
import 'package:rumboapp/features/vehicles/application/vehicle_providers.dart';

import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

import 'package:rumboapp/features/vehicles/domain/catalogs/country.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/region.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/vehicle_brand.dart';
import 'package:rumboapp/features/vehicles/domain/catalogs/vehicle_model.dart';

import 'package:rumboapp/features/vehicles/presentation/widgets/catalog_autocomplete_field.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final Object _formSessionKey = Object();

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

  late final FocusNode _brandFocusNode;
  late final FocusNode _modelFocusNode;
  late final FocusNode _countryFocusNode;
  late final FocusNode _regionFocusNode;

  DateTime? _insuranceValidUntil;
  DateTime? _verificationValidUntil;

  bool get _isEditing => widget.vehicle != null;

  VehicleFormSelectionArgs get _selectionArgs {
    return (
      vehicleType: widget.vehicle?.vehicleType,
      fuelType: widget.vehicle?.fuelType,
      sessionKey: _formSessionKey,
    );
  }

  int? get _initialYear {
    final year = widget.vehicle?.year;

    if (year == null || year <= 0) {
      return null;
    }

    return year;
  }

  VehicleCatalogFormSelectionArgs get _catalogSelectionArgs {
    return (
      sessionKey: _formSessionKey,
      brandId: widget.vehicle?.brandId,
      modelId: widget.vehicle?.modelId,
      countryCode: widget.vehicle?.registrationCountryCode,
      regionCode: widget.vehicle?.registrationRegionCode,
      year: _initialYear,
    );
  }

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _brandController = TextEditingController(text: vehicle?.brand ?? '');

    _modelController = TextEditingController(text: vehicle?.model ?? '');

    _yearController = TextEditingController(
      text: vehicle != null && vehicle.year > 0 ? vehicle.year.toString() : '',
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

    _brandFocusNode = FocusNode();
    _modelFocusNode = FocusNode();
    _countryFocusNode = FocusNode();
    _regionFocusNode = FocusNode();
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

    _brandFocusNode.dispose();
    _modelFocusNode.dispose();
    _countryFocusNode.dispose();
    _regionFocusNode.dispose();

    super.dispose();
  }

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

  bool _matchesCatalogText(String value, Iterable<String> candidates) {
    final normalized = normalizeCatalogSearchText(value);

    if (normalized.isEmpty) {
      return false;
    }

    return candidates.any(
      (candidate) => normalizeCatalogSearchText(candidate) == normalized,
    );
  }

  VehicleCatalogFormSelections get _currentCatalogSelections {
    return ref.read(
      vehicleCatalogFormSelectionsProvider(_catalogSelectionArgs),
    );
  }

  VehicleCatalogFormSelectionController get _catalogSelectionController {
    return ref.read(
      vehicleCatalogFormSelectionsProvider(_catalogSelectionArgs).notifier,
    );
  }

  void _handleBrandTextChanged(String value, List<VehicleBrand> options) {
    final current = _currentCatalogSelections;

    if (current.brandId == null) {
      return;
    }

    VehicleBrand? selectedBrand;

    for (final brand in options) {
      if (brand.id == current.brandId) {
        selectedBrand = brand;
        break;
      }
    }

    if (selectedBrand == null ||
        !_matchesCatalogText(value, [
          selectedBrand.name,
          selectedBrand.id,
          ...selectedBrand.aliases,
        ])) {
      _catalogSelectionController.clearBrand();
      _modelController.clear();
    }
  }

  void _handleModelTextChanged(String value, List<VehicleModel> options) {
    final current = _currentCatalogSelections;

    if (current.modelId == null) {
      return;
    }

    VehicleModel? selectedModel;

    for (final model in options) {
      if (model.id == current.modelId) {
        selectedModel = model;
        break;
      }
    }

    if (selectedModel == null ||
        !_matchesCatalogText(value, [
          selectedModel.name,
          selectedModel.id,
          ...selectedModel.aliases,
        ])) {
      _catalogSelectionController.clearModel();
    }
  }

  void _handleCountryTextChanged(String value, List<Country> options) {
    final current = _currentCatalogSelections;

    if (current.countryCode == null) {
      return;
    }

    Country? selectedCountry;

    for (final country in options) {
      if (country.code == current.countryCode) {
        selectedCountry = country;
        break;
      }
    }

    final matches =
        selectedCountry != null &&
        _matchesCatalogText(value, [
          selectedCountry.name,
          selectedCountry.code,
          if (selectedCountry.alpha3 != null) selectedCountry.alpha3!,
          ...selectedCountry.aliases,
        ]);

    if (!matches) {
      _catalogSelectionController.clearCountry();
      _registrationRegionController.clear();
    }
  }

  void _handleRegionTextChanged(String value, List<Region> options) {
    final current = _currentCatalogSelections;

    if (current.regionCode == null) {
      return;
    }

    Region? selectedRegion;

    for (final region in options) {
      if (region.code == current.regionCode) {
        selectedRegion = region;
        break;
      }
    }

    if (selectedRegion == null ||
        !_matchesCatalogText(value, [
          selectedRegion.name,
          selectedRegion.code,
          ...selectedRegion.aliases,
        ])) {
      _catalogSelectionController.clearRegion();
    }
  }

  void _handleYearChanged(String value) {
    final current = _currentCatalogSelections;
    final year = int.tryParse(value.trim());

    if (year == current.year) {
      return;
    }

    if (current.modelId != null) {
      _modelController.clear();
    }

    _catalogSelectionController.setYear(year);
  }

  void _handleVehicleTypeChanged(String? value) {
    final provider = vehicleFormSelectionsProvider(_selectionArgs);
    final previousType = ref.read(provider).vehicleType;

    if (previousType == value) {
      return;
    }

    ref.read(provider.notifier).setVehicleType(value);

    final catalogSelections = _currentCatalogSelections;

    if (catalogSelections.brandId != null ||
        catalogSelections.modelId != null) {
      _catalogSelectionController.clearBrand();
      _brandController.clear();
      _modelController.clear();
    }
  }

  String _catalogHelperText({
    required bool loading,
    required bool hasError,
    required bool hasOptions,
    required String available,
    required String empty,
  }) {
    if (loading) {
      return 'Cargando opciones del catálogo...';
    }

    if (hasError) {
      return 'No se pudo cargar el catálogo. Puedes escribir el valor manualmente.';
    }

    return hasOptions ? available : empty;
  }

  Widget _brandField({
    required List<VehicleBrand> options,
    required bool loading,
    required bool hasError,
  }) {
    return CatalogAutocompleteField<VehicleBrand>(
      controller: _brandController,
      focusNode: _brandFocusNode,
      label: 'Marca',
      hint: 'Ej. Toyota',
      options: options,
      loading: loading,
      displayStringForOption: (brand) => brand.name,
      aliasesForOption: (brand) => [brand.id, ...brand.aliases],
      onChanged: (value) {
        _handleBrandTextChanged(value, options);
      },
      onSelected: (brand) {
        final current = _currentCatalogSelections;

        if (current.brandId != brand.id) {
          _modelController.clear();
        }

        _catalogSelectionController.selectBrand(brand.id);
      },
      validator: (value) {
        return _validateRequired(value, fieldName: 'la marca');
      },
      helperText: _catalogHelperText(
        loading: loading,
        hasError: hasError,
        hasOptions: options.isNotEmpty,
        available: 'Selecciona una marca o escribe su nombre manualmente.',
        empty: 'No hay marcas disponibles para este tipo. Puedes escribirla manualmente.',
      ),
    );
  }

  Widget _modelField({
    required List<VehicleModel> options,
    required bool loading,
    required bool hasError,
    required bool hasBrand,
  }) {
    return CatalogAutocompleteField<VehicleModel>(
      controller: _modelController,
      focusNode: _modelFocusNode,
      label: 'Modelo',
      hint: 'Ej. Corolla',
      options: options,
      loading: loading,
      displayStringForOption: (model) => model.name,
      aliasesForOption: (model) => [model.id, ...model.aliases],
      onChanged: (value) {
        _handleModelTextChanged(value, options);
      },
      onSelected: (model) {
        _catalogSelectionController.selectModel(model.id);
      },
      validator: (value) {
        return _validateRequired(value, fieldName: 'el modelo');
      },
      helperText: _catalogHelperText(
        loading: loading,
        hasError: hasError,
        hasOptions: options.isNotEmpty,
        available: 'Los modelos se filtran por marca, tipo y año. También puedes escribirlo manualmente.',
        empty: hasBrand
            ? 'No hay modelos disponibles para estos filtros. Puedes escribirlo manualmente.'
            : 'Selecciona una marca del catálogo para recibir sugerencias o escribe el modelo manualmente.',
      ),
    );
  }

  Widget _countryField({
    required List<Country> options,
    required bool loading,
    required bool hasError,
  }) {
    return CatalogAutocompleteField<Country>(
      controller: _registrationCountryController,
      focusNode: _countryFocusNode,
      label: 'País de registro',
      hint: 'Ej. México',
      options: options,
      loading: loading,
      displayStringForOption: (country) => country.name,
      aliasesForOption: (country) => [
        country.code,
        if (country.alpha3 != null) country.alpha3!,
        ...country.aliases,
      ],
      onChanged: (value) {
        _handleCountryTextChanged(value, options);
      },
      onSelected: (country) {
        final current = _currentCatalogSelections;

        if (current.countryCode != country.code) {
          _registrationRegionController.clear();
        }

        _catalogSelectionController.selectCountry(country.code);
      },
      validator: (value) {
        return _validateRequired(value, fieldName: 'el país de registro');
      },
      helperText: _catalogHelperText(
        loading: loading,
        hasError: hasError,
        hasOptions: options.isNotEmpty,
        available: 'Selecciona un país o escribe su nombre manualmente.',
        empty: 'No hay países disponibles. Puedes escribirlo manualmente.',
      ),
    );
  }

  Widget _regionField({
    required List<Region> options,
    required bool loading,
    required bool hasError,
    required bool hasCountry,
  }) {
    return CatalogAutocompleteField<Region>(
      controller: _registrationRegionController,
      focusNode: _regionFocusNode,
      label: 'Estado o región de registro',
      hint: 'Ej. Guanajuato',
      options: options,
      loading: loading,
      displayStringForOption: (region) => region.name,
      aliasesForOption: (region) => [region.code, ...region.aliases],
      onChanged: (value) {
        _handleRegionTextChanged(value, options);
      },
      onSelected: (region) {
        _catalogSelectionController.selectRegion(region.code);
      },
      validator: (value) {
        return _validateRequired(value, fieldName: 'el estado o región');
      },
      helperText: _catalogHelperText(
        loading: loading,
        hasError: hasError,
        hasOptions: options.isNotEmpty,
        available: 'Las regiones dependen del país seleccionado. También puedes escribir manualmente.',
        empty: hasCountry
            ? 'No hay regiones cargadas para este país. Puedes escribir la región manualmente.'
            : 'Selecciona un país del catálogo o escribe la región manualmente.',
      ),
    );
  }

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
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _decoration(label, hint: hint, suffixText: suffixText),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
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

  List<DropdownMenuItem<String>> _buildDropdownItems({
    required List<String> values,
    required Map<String, String> labels,
    required String? currentValue,
  }) {
    final items = <DropdownMenuItem<String>>[];

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

  Widget _vehicleTypeDropdown(VehicleFormSelections selections) {
    return DropdownButtonFormField<String>(
      initialValue: selections.vehicleType,
      isExpanded: true,
      decoration: _decoration('Tipo de vehículo'),
      items: _vehicleTypeItems(selections.vehicleType),
      onChanged: _handleVehicleTypeChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona el tipo de vehículo.';
        }

        return null;
      },
    );
  }

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
                  'Para este tipo de energía no se registrará un consumo '
                  'automático. Puedes continuar con los demás datos.',
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

  Future<void> _saveVehicle() async {
    FocusScope.of(context).unfocus();

    final selectionProvider = vehicleFormSelectionsProvider(_selectionArgs);

    final catalogProvider = vehicleCatalogFormSelectionsProvider(
      _catalogSelectionArgs,
    );

    final selectionController = ref.read(selectionProvider.notifier);

    final currentSelections = ref.read(selectionProvider);

    final catalogSelections = ref.read(catalogProvider);

    if (currentSelections.isSaving) {
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
      brandId: catalogSelections.brandId,
      modelId: catalogSelections.modelId,
      vehicleType: vehicleType,
      fuelType: fuelType,
      fuelConsumptionKmPerLiter: fuelConsumption,
      electricConsumptionKwhPer100Km: electricConsumption,
      registrationCountry: _registrationCountryController.text.trim(),
      registrationRegion: _registrationRegionController.text.trim(),
      registrationCountryCode: catalogSelections.countryCode,
      registrationRegionCode: catalogSelections.regionCode,
      plateEnding: _readOptionalText(_plateEndingController)?.toUpperCase(),
      insuranceCompany: _readOptionalText(_insuranceCompanyController),
      insuranceValidUntil: _insuranceValidUntil,
      verificationHologram: _readOptionalText(_verificationHologramController),
      verificationValidUntil: _verificationValidUntil,
      createdAt: existingVehicle?.createdAt ?? now,
      updatedAt: now,
    );

    selectionController.setSaving(true);

    try {
      final vehicleController = ref.read(vehicleControllerProvider.notifier);

      if (_isEditing) {
        await vehicleController.updateVehicle(vehicle);
      } else {
        await vehicleController.addVehicle(vehicle);
      }

      if (!mounted) {
        return;
      }

      selectionController.setSaving(false);

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

      selectionController.setSaving(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar el vehículo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionProvider = vehicleFormSelectionsProvider(_selectionArgs);

    final catalogProvider = vehicleCatalogFormSelectionsProvider(
      _catalogSelectionArgs,
    );

    final selections = ref.watch(selectionProvider);

    final selectionController = ref.read(selectionProvider.notifier);

    final catalogSelections = ref.watch(catalogProvider);

    final brandsAsync = ref.watch(
      vehicleCatalogBrandsProvider(selections.vehicleType),
    );

    final modelsAsync = catalogSelections.brandId == null
        ? const AsyncData<List<VehicleModel>>(<VehicleModel>[])
        : ref.watch(
            vehicleCatalogModelsProvider((
              brandId: catalogSelections.brandId!,
              vehicleType: selections.vehicleType,
              year: catalogSelections.year,
            )),
          );

    final countriesAsync = ref.watch(vehicleCatalogCountriesProvider);

    final regionsAsync = catalogSelections.countryCode == null
        ? const AsyncData<List<Region>>(<Region>[])
        : ref.watch(
            vehicleCatalogRegionsProvider(catalogSelections.countryCode!),
          );

    final brands = brandsAsync.when(
      data: (value) => value,
      error: (error, stackTrace) => const <VehicleBrand>[],
      loading: () => const <VehicleBrand>[],
    );

    final models = modelsAsync.when(
      data: (value) => value,
      error: (error, stackTrace) => const <VehicleModel>[],
      loading: () => const <VehicleModel>[],
    );

    final countries = countriesAsync.when(
      data: (value) => value,
      error: (error, stackTrace) => const <Country>[],
      loading: () => const <Country>[],
    );

    final regions = regionsAsync.when(
      data: (value) => value,
      error: (error, stackTrace) => const <Region>[],
      loading: () => const <Region>[],
    );

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
              _sectionTitle('Información general'),

              _brandField(
                options: brands,
                loading: brandsAsync.isLoading,
                hasError: brandsAsync.hasError,
              ),

              const SizedBox(height: 16),

              _modelField(
                options: models,
                loading: modelsAsync.isLoading,
                hasError: modelsAsync.hasError,
                hasBrand: catalogSelections.brandId != null,
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
                onChanged: _handleYearChanged,
              ),

              const SizedBox(height: 16),

              _vehicleTypeDropdown(selections),

              const SizedBox(height: 16),

              _fuelTypeDropdown(selections, selectionController),

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

              const SizedBox(height: 28),

              _sectionTitle('Registro y placas'),

              _countryField(
                options: countries,
                loading: countriesAsync.isLoading,
                hasError: countriesAsync.hasError,
              ),

              const SizedBox(height: 16),

              _regionField(
                options: regions,
                loading: regionsAsync.isLoading,
                hasError: regionsAsync.hasError,
                hasCountry: catalogSelections.countryCode != null,
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

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: selections.isSaving ? null : _saveVehicle,
                icon: selections.isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  selections.isSaving
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
