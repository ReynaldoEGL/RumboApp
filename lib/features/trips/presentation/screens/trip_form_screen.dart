import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';
import 'package:rumboapp/features/trips/application/trip_providers.dart';

import 'package:rumboapp/features/trips/domain/trip.dart';
import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';

import 'package:rumboapp/features/vehicles/application/vehicle_providers.dart';
import 'package:rumboapp/features/vehicles/domain/vehicle.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.trip, this.route})
    : assert(trip == null || route == null);

  final Trip? trip;
  final RoadRoute? route;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final Object _sessionKey = Object();

  late final TextEditingController _titleController;
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late final TextEditingController _departureDateController;
  late final TextEditingController _returnDateController;
  late final TextEditingController _distanceController;
  late final TextEditingController _energyPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _notesController;

  DateTime _departureDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _returnDate;

  bool get _isEditing => widget.trip != null;

  RoadRoute? get _routeSnapshot {
    return widget.route ?? widget.trip?.routeSnapshot;
  }

  bool get _hasRouteSnapshot {
    return _routeSnapshot != null;
  }

  TripFormArgs get _formArgs {
    final trip = widget.trip;
    final route = widget.route;

    return (
      sessionKey: _sessionKey,
      vehicleId: trip?.vehicleId,
      status: trip?.status ?? TripStatus.planned,
      distanceKm: trip?.distanceKm ?? route?.distanceKilometers,
      energyUnitPrice: trip?.energyUnitPrice,
      currencyCode: trip?.currencyCode ?? 'MXN',
    );
  }

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;
    final route = _routeSnapshot;

    if (trip != null) {
      _departureDate = DateUtils.dateOnly(trip.departureDate);

      _returnDate = trip.returnDate == null
          ? null
          : DateUtils.dateOnly(trip.returnDate!);
    }

    _titleController = TextEditingController(
      text:
          trip?.title ??
          (route == null ? '' : 'Viaje a ${route.destination.title}'),
    );

    _originController = TextEditingController(
      text: trip?.origin ?? route?.origin.addressLabel ?? '',
    );

    _destinationController = TextEditingController(
      text: trip?.destination ?? route?.destination.addressLabel ?? '',
    );

    _departureDateController = TextEditingController(
      text: _formatDate(_departureDate),
    );

    _returnDateController = TextEditingController(
      text: _formatDate(_returnDate),
    );

    _distanceController = TextEditingController(
      text:
          trip?.distanceKm?.toString() ??
          route?.distanceKilometers.toStringAsFixed(3) ??
          '',
    );

    _energyPriceController = TextEditingController(
      text: trip?.energyUnitPrice?.toString() ?? '',
    );

    _currencyController = TextEditingController(
      text: trip?.currencyCode ?? 'MXN',
    );

    _notesController = TextEditingController(text: trip?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _departureDateController.dispose();
    _returnDateController.dispose();
    _distanceController.dispose();
    _energyPriceController.dispose();
    _currencyController.dispose();
    _notesController.dispose();

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

  String? _validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $fieldName.';
    }

    return null;
  }

  String? _validateReturnDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (_returnDate == null) {
      return 'Selecciona una fecha válida.';
    }

    if (_returnDate!.isBefore(_departureDate)) {
      return 'El regreso no puede ser anterior a la salida.';
    }

    return null;
  }

  String? _validatePositiveNumber(
    String? value, {
    required String fieldName,
    required bool requiredValue,
  }) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';

    if (normalized.isEmpty) {
      return requiredValue ? 'Ingresa $fieldName.' : null;
    }

    final number = double.tryParse(normalized);

    if (number == null || !number.isFinite || number <= 0) {
      return 'Ingresa un valor mayor que cero.';
    }

    return null;
  }

  String? _validateCurrencyCode(String? value) {
    if (value == null || !RegExp(r'^[A-Za-z]{3}$').hasMatch(value.trim())) {
      return 'Ingresa un código de moneda de tres letras, por ejemplo MXN.';
    }

    return null;
  }

  double? _readOptionalPositiveNumber(TextEditingController controller) {
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

  String? _readOptionalText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  Future<void> _selectDate({required bool isDepartureDate}) async {
    final now = DateUtils.dateOnly(DateTime.now());

    final currentDate = isDepartureDate
        ? _departureDate
        : _returnDate ?? _departureDate;

    final firstDate = isDepartureDate ? DateTime(1900) : _departureDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate.isBefore(firstDate) ? firstDate : currentDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 30, 12, 31),
      helpText: isDepartureDate ? 'Fecha de salida' : 'Fecha de regreso',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final selected = DateUtils.dateOnly(pickedDate);

    setState(() {
      if (isDepartureDate) {
        _departureDate = selected;
        _departureDateController.text = _formatDate(selected);
      } else {
        _returnDate = selected;
        _returnDateController.text = _formatDate(selected);
      }
    });
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: optional ? 'Opcional' : 'Selecciona una fecha',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: 'Seleccionar fecha',
          onPressed: onTap,
          icon: const Icon(Icons.calendar_month),
        ),
      ),
    );
  }

  Vehicle? _findVehicle(List<Vehicle> vehicles, String? vehicleId) {
    if (vehicleId == null) {
      return null;
    }

    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  TripVehicleSnapshot? _resolveSnapshot({
    required List<Vehicle> vehicles,
    required TripFormSelections selections,
  }) {
    if (selections.vehicleId == null) {
      return null;
    }

    final vehicle = _findVehicle(vehicles, selections.vehicleId);

    if (vehicle != null) {
      return TripVehicleSnapshot.fromVehicle(vehicle);
    }

    final previousSnapshot = widget.trip?.vehicleSnapshot;

    if (previousSnapshot?.id == selections.vehicleId) {
      return previousSnapshot;
    }

    return null;
  }

  void _updateDistance(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final distance = double.tryParse(normalized);

    ref.read(tripFormProvider(_formArgs).notifier).setDistanceKm(distance);
  }

  void _updateEnergyPrice(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final price = double.tryParse(normalized);

    ref.read(tripFormProvider(_formArgs).notifier).setEnergyUnitPrice(price);
  }

  void _updateCurrencyCode(String value) {
    ref.read(tripFormProvider(_formArgs).notifier).setCurrencyCode(value);
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      readOnly: readOnly,
    );
  }

  Widget _statusDropdown(TripFormSelections selections) {
    return DropdownButtonFormField<TripStatus>(
      key: ValueKey(selections.status),
      initialValue: selections.status,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Estado del viaje',
        border: OutlineInputBorder(),
      ),
      items: TripStatus.values.map((status) {
        return DropdownMenuItem<TripStatus>(
          value: status,
          child: Text(status.label),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(tripFormProvider(_formArgs).notifier).setStatus(value);
        }
      },
    );
  }

  Widget _vehicleDropdown({
    required TripFormSelections selections,
    required List<Vehicle> vehicles,
    required bool loading,
  }) {
    final selectedId = selections.vehicleId;

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Sin vehículo asignado'),
      ),
    ];

    final selectedExists = vehicles.any((vehicle) => vehicle.id == selectedId);

    if (selectedId != null && !selectedExists) {
      final previousSnapshot = widget.trip?.vehicleSnapshot;

      items.add(
        DropdownMenuItem<String>(
          value: selectedId,
          child: Text(
            previousSnapshot?.displayName ?? 'Vehículo no disponible',
          ),
        ),
      );
    }

    for (final vehicle in vehicles) {
      items.add(
        DropdownMenuItem<String>(
          value: vehicle.id,
          child: Text(vehicle.displayName),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey(selectedId ?? 'no-vehicle'),
      initialValue: selectedId ?? '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Vehículo',
        helperText: loading
            ? 'Cargando vehículos...'
            : 'Selecciona un vehículo para utilizar sus datos de consumo.',
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: (value) {
        ref.read(tripFormProvider(_formArgs).notifier).selectVehicle(value);
      },
    );
  }

  Widget _energyEstimateCard({
    required TripEnergyEstimate? estimate,
    required TripFormSelections selections,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (estimate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'La estimación estará disponible cuando se haya '
                  'seleccionado un vehículo con consumo registrado, '
                  'una distancia y un precio energético válido.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimación energética',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${estimate.quantity.toStringAsFixed(2)} ${estimate.unit}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${estimate.cost.toStringAsFixed(2)} '
              '${selections.currencyCode}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              estimate.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (estimate.isPartial) ...[
              const SizedBox(height: 8),
              Text(
                'Estimación parcial',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeSnapshotCard(RoadRoute route) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final distance = route.distanceKilometers.toStringAsFixed(1);
    final duration = Duration(seconds: route.durationSeconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final durationLabel = hours == 0
        ? '$minutes min'
        : minutes == 0
        ? '$hours h'
        : '$hours h $minutes min';

    final tollCount = route.tolls.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, color: colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Ruta seleccionada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.verified_rounded, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              '$distance km · $durationLabel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              tollCount == 0
                  ? 'No se reportaron registros de peaje en esta alternativa.'
                  : '$tollCount registros de peaje disponibles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'El trazado y los datos disponibles de los peajes '
              'se conservarán junto con este viaje.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrip({required List<Vehicle> vehicles}) async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();

    if (title.isEmpty || origin.isEmpty || destination.isEmpty) {
      return;
    }

    final selections = ref.read(tripFormProvider(_formArgs));

    final routeSnapshot = _routeSnapshot;

    final distanceKm =
        routeSnapshot?.distanceKilometers ??
        _readOptionalPositiveNumber(_distanceController);

    final energyPrice = _readOptionalPositiveNumber(_energyPriceController);

    final currencyCode = _currencyController.text.trim().toUpperCase();

    if (_returnDate != null && _returnDate!.isBefore(_departureDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de regreso no puede ser anterior a la salida.',
          ),
        ),
      );
      return;
    }

    final vehicleSnapshot = _resolveSnapshot(
      vehicles: vehicles,
      selections: selections,
    );

    if (selections.vehicleId != null && vehicleSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El vehículo seleccionado ya no está disponible. '
            'Selecciona otro o continúa sin vehículo.',
          ),
        ),
      );
      return;
    }

    final existingTrip = widget.trip;
    final now = DateTime.now().millisecondsSinceEpoch;

    final trip = Trip(
      id: existingTrip?.id ?? '',
      title: title,
      origin: origin,
      destination: destination,
      departureDate: _departureDate,
      returnDate: _returnDate,
      vehicleId: selections.vehicleId,
      vehicleSnapshot: vehicleSnapshot,
      distanceKm: distanceKm,
      energyUnitPrice: energyPrice,
      routeSnapshot: routeSnapshot,
      currencyCode: currencyCode,
      status: selections.status,
      notes: _readOptionalText(_notesController),
      createdAt: existingTrip?.createdAt ?? now,
      updatedAt: now,
    );

    final operation = ref.read(tripControllerProvider.notifier);

    try {
      trip.validate();

      if (_isEditing) {
        await operation.updateTrip(trip);
      } else {
        await operation.addTrip(trip);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Viaje actualizado correctamente.'
                : 'Viaje registrado correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible guardar el viaje. Inténtalo nuevamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUserProvider);

    return authState.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        return const Scaffold(
          body: Center(child: Text('No fue posible comprobar la sesión.')),
        );
      },
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Inicia sesión para administrar tus viajes.'),
            ),
          );
        }

        return _buildForm(user.uid);
      },
    );
  }

  Widget _buildForm(String uid) {
    final selections = ref.watch(tripFormProvider(_formArgs));

    final vehiclesAsync = ref.watch(vehiclesProvider(uid));

    final operationState = ref.watch(tripControllerProvider);

    final vehicles = vehiclesAsync.asData?.value ?? <Vehicle>[];

    final vehicleSnapshot = _resolveSnapshot(
      vehicles: vehicles,
      selections: selections,
    );

    final estimate = calculateTripEnergyEstimate(
      fuelType: vehicleSnapshot?.fuelType,
      distanceKm: selections.distanceKm,
      energyUnitPrice: selections.energyUnitPrice,
      fuelConsumptionKmPerLiter: vehicleSnapshot?.fuelConsumptionKmPerLiter,
      electricConsumptionKwhPer100Km:
          vehicleSnapshot?.electricConsumptionKwhPer100Km,
    );

    final priceLabel = vehicleSnapshot?.fuelType == 'electric'
        ? 'Precio por kWh'
        : 'Precio por litro';

    final routeSnapshot = _routeSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar viaje' : 'Planear viaje'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Información general',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _titleController,
                label: 'Nombre del viaje',
                hint: 'Ej. Fin de semana en Querétaro',
                validator: (value) {
                  return _validateRequired(
                    value,
                    fieldName: 'el nombre del viaje',
                  );
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _originController,
                label: 'Origen',
                hint: 'Ej. Celaya, Guanajuato',
                readOnly: _hasRouteSnapshot,
                validator: (value) {
                  return _validateRequired(value, fieldName: 'el origen');
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _destinationController,
                label: 'Destino',
                hint: 'Ej. Querétaro, Querétaro',
                readOnly: _hasRouteSnapshot,
                validator: (value) {
                  return _validateRequired(value, fieldName: 'el destino');
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 28),
              Text(
                'Fechas del viaje',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _dateField(
                controller: _departureDateController,
                label: 'Fecha de salida',
                onTap: () {
                  _selectDate(isDepartureDate: true);
                },
              ),
              const SizedBox(height: 16),
              _dateField(
                controller: _returnDateController,
                label: 'Fecha de regreso',
                optional: true,
                validator: _validateReturnDate,
                onTap: () {
                  _selectDate(isDepartureDate: false);
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Vehículo y recorrido',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _vehicleDropdown(
                selections: selections,
                vehicles: vehicles,
                loading: vehiclesAsync.isLoading,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _distanceController,
                label: 'Distancia del recorrido',
                hint: 'Ej. 250',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                onChanged: _hasRouteSnapshot ? null : _updateDistance,
                readOnly: _hasRouteSnapshot,
                validator: (value) {
                  return _validatePositiveNumber(
                    value,
                    fieldName: 'una distancia válida',
                    requiredValue: false,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                _hasRouteSnapshot
                    ? 'Distancia obtenida del recorrido seleccionado.'
                    : 'Indica la distancia total aproximada del recorrido en kilómetros.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (routeSnapshot != null) ...[
                const SizedBox(height: 12),
                _routeSnapshotCard(routeSnapshot),
              ],
              const SizedBox(height: 28),
              Text(
                'Estimación de energía',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _energyPriceController,
                label: priceLabel,
                hint: 'Ej. 24.50',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                onChanged: _updateEnergyPrice,
                validator: (value) {
                  return _validatePositiveNumber(
                    value,
                    fieldName: 'un precio energético válido',
                    requiredValue: false,
                  );
                },
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _currencyController,
                label: 'Código de moneda',
                hint: 'MXN',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: _updateCurrencyCode,
                validator: _validateCurrencyCode,
              ),
              const SizedBox(height: 16),
              _energyEstimateCard(estimate: estimate, selections: selections),
              const SizedBox(height: 28),
              Text(
                'Organización',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _statusDropdown(selections),
              const SizedBox(height: 16),
              _textField(
                controller: _notesController,
                label: 'Notas',
                hint: 'Pendientes, recordatorios o información adicional',
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: operationState.isLoading
                    ? null
                    : () {
                        _saveTrip(vehicles: vehicles);
                      },
                icon: operationState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  operationState.isLoading
                      ? 'Guardando...'
                      : _isEditing
                      ? 'Actualizar viaje'
                      : 'Guardar viaje',
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
