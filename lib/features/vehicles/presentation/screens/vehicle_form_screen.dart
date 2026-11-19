import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/vehicle_providers.dart';
import '../../domain/vehicle.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;

  late final TextEditingController _consumptionController;

  late final TextEditingController _countryController;
  late final TextEditingController _regionController;
  late final TextEditingController _plateLastDigitController;

  late final TextEditingController _insuranceCompanyController;
  late final TextEditingController _insuranceDateController;

  late final TextEditingController _verificationDateController;
  late final TextEditingController _verificationHologramController;

  String _vehicleType = 'car';
  String _fuelType = 'gasoline';

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _brandController = TextEditingController(text: vehicle?.brand ?? '');

    _modelController = TextEditingController(text: vehicle?.model ?? '');

    _yearController = TextEditingController(
      text: vehicle?.year.toString() ?? '',
    );

    _consumptionController = TextEditingController(
      text: vehicle?.averageConsumption?.toString() ?? '',
    );

    _countryController = TextEditingController(
      text: vehicle?.registrationCountry ?? 'México',
    );

    _regionController = TextEditingController(
      text: vehicle?.registrationRegion ?? '',
    );

    _plateLastDigitController = TextEditingController(
      text: vehicle?.plateLastDigit?.toString() ?? '',
    );

    _insuranceCompanyController = TextEditingController(
      text: vehicle?.insuranceCompany ?? '',
    );

    _insuranceDateController = TextEditingController(
      text: _formatDate(vehicle?.insuranceValidUntil),
    );

    _verificationDateController = TextEditingController(
      text: _formatDate(vehicle?.verificationValidUntil),
    );

    _verificationHologramController = TextEditingController(
      text: vehicle?.verificationHologram ?? '',
    );

    if (vehicle != null) {
      const vehicleTypes = [
        'car',
        'motorcycle',
        'pickup',
        'van',
        'truck',
        'other',
      ];

      const fuelTypes = ['gasoline', 'diesel', 'hybrid', 'electric', 'other'];

      _vehicleType = vehicleTypes.contains(vehicle.vehicleType)
          ? vehicle.vehicleType
          : 'other';

      _fuelType = fuelTypes.contains(vehicle.fuelType)
          ? vehicle.fuelType
          : 'other';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();

    _consumptionController.dispose();

    _countryController.dispose();
    _regionController.dispose();
    _plateLastDigitController.dispose();

    _insuranceCompanyController.dispose();
    _insuranceDateController.dispose();

    _verificationDateController.dispose();
    _verificationHologramController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final firstDate = DateTime(1950);
    final lastDate = DateTime(2100);

    final existingDate = DateTime.tryParse(controller.text);

    DateTime initialDate = existingDate ?? now;

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecciona la fecha de vencimiento',
    );

    if (selectedDate == null) {
      return;
    }

    controller.text = _formatDate(selectedDate);
  }

  String? _validateRequiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $label.';
    }

    if (value.trim().length > 60) {
      return 'El texto no puede superar los 60 caracteres.';
    }

    return null;
  }

  Future<void> _saveVehicle() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int year = int.parse(_yearController.text.trim());

    final String consumptionText = _consumptionController.text
        .trim()
        .replaceAll(',', '.');

    final double? consumption = consumptionText.isEmpty
        ? null
        : double.tryParse(consumptionText);

    final String plateText = _plateLastDigitController.text.trim();

    final int? plateLastDigit = plateText.isEmpty
        ? null
        : int.tryParse(plateText);

    final DateTime? insuranceDate = _insuranceDateController.text.isEmpty
        ? null
        : DateTime.tryParse(_insuranceDateController.text);

    final DateTime? verificationDate = _verificationDateController.text.isEmpty
        ? null
        : DateTime.tryParse(_verificationDateController.text);

    final now = DateTime.now().millisecondsSinceEpoch;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? '',

      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: year,

      vehicleType: _vehicleType,
      fuelType: _fuelType,

      averageConsumption: consumption,

      consumptionUnit: _fuelType == 'electric' ? 'kWh/100 km' : 'km/L',

      registrationCountry: _countryController.text.trim(),
      registrationRegion: _regionController.text.trim(),

      plateLastDigit: plateLastDigit,

      insuranceCompany: _insuranceCompanyController.text.trim().isEmpty
          ? null
          : _insuranceCompanyController.text.trim(),

      insuranceValidUntil: insuranceDate,

      verificationHologram: _verificationHologramController.text.trim().isEmpty
          ? null
          : _verificationHologramController.text.trim(),

      verificationValidUntil: verificationDate,

      createdAt: widget.vehicle?.createdAt ?? now,
      updatedAt: now,
    );

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Vehículo actualizado.' : 'Vehículo registrado.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase no permitió guardar el vehículo. '
            'Comprueba las reglas y tu conexión.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible guardar el vehículo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isLoading = ref.watch(vehicleControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar vehículo' : 'Agregar vehículo'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Información general',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Registra las características de tu vehículo. '
                      'Estos datos servirán para preparar tus próximos viajes.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _brandController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      validator: (value) =>
                          _validateRequiredText(value, 'la marca'),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _modelController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        prefixIcon: Icon(Icons.car_repair_outlined),
                      ),
                      validator: (value) =>
                          _validateRequiredText(value, 'el modelo'),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (value) {
                        final year = int.tryParse(value?.trim() ?? '');

                        final currentYear = DateTime.now().year + 1;

                        if (year == null || year < 1950 || year > currentYear) {
                          return 'Ingresa un año válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: _vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vehículo',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'car',
                          child: Text('Automóvil'),
                        ),
                        DropdownMenuItem(
                          value: 'motorcycle',
                          child: Text('Motocicleta'),
                        ),
                        DropdownMenuItem(
                          value: 'pickup',
                          child: Text('Pickup'),
                        ),
                        DropdownMenuItem(value: 'van', child: Text('Van')),
                        DropdownMenuItem(value: 'truck', child: Text('Camión')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _vehicleType = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona un tipo de vehículo.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: _fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de combustible',
                        prefixIcon: Icon(Icons.local_gas_station_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'gasoline',
                          child: Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'diesel',
                          child: Text('Diésel'),
                        ),
                        DropdownMenuItem(
                          value: 'hybrid',
                          child: Text('Híbrido'),
                        ),
                        DropdownMenuItem(
                          value: 'electric',
                          child: Text('Eléctrico'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _fuelType = value;
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _consumptionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Consumo promedio (opcional)',
                        prefixIcon: Icon(Icons.speed_outlined),
                        helperText:
                            'km/L para combustibles líquidos; '
                            'kWh/100 km para vehículos eléctricos.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        final consumption = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );

                        if (consumption == null ||
                            !consumption.isFinite ||
                            consumption <= 0 ||
                            consumption > 1000) {
                          return 'Ingresa un consumo válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Registro del vehículo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _countryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'País de registro',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                      validator: (value) =>
                          _validateRequiredText(value, 'el país'),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _regionController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Estado, provincia o región',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (value) =>
                          _validateRequiredText(value, 'la región'),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _plateLastDigitController,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        labelText: 'Último dígito de la placa',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        helperText:
                            'Opcional. No se guardará la matrícula completa.',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }

                        if (!RegExp(r'^[0-9]$').hasMatch(value)) {
                          return 'Ingresa un solo dígito del 0 al 9.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Seguro vehicular',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Estos datos ayudarán a organizar la documentación. '
                      'No sustituyen la comprobación de la cobertura.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _insuranceCompanyController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Aseguradora (opcional)',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _insuranceDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Vigencia del seguro',
                        prefixIcon: Icon(Icons.event_outlined),
                        hintText: 'Seleccionar fecha',
                      ),
                      onTap: () {
                        _selectDate(_insuranceDateController);
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Verificación vehicular',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _verificationHologramController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Holograma (opcional)',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _verificationDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Vigencia registrada',
                        prefixIcon: Icon(Icons.event_outlined),
                        hintText: 'Seleccionar fecha',
                      ),
                      onTap: () {
                        _selectDate(_verificationDateController);
                      },
                    ),

                    const SizedBox(height: 32),

                    FilledButton.icon(
                      onPressed: isLoading ? null : _saveVehicle,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isLoading
                            ? 'Guardando...'
                            : _isEditing
                            ? 'Guardar cambios'
                            : 'Registrar vehículo',
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
