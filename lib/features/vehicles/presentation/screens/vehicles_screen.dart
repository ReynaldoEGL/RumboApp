import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import '../../application/vehicle_providers.dart';
import '../../domain/vehicle.dart';
import 'vehicle_form_screen.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  Future<void> _openVehicleForm(
    BuildContext context, {
    Vehicle? vehicle,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleFormScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis vehículos')),

      floatingActionButton: authState.asData?.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                _openVehicleForm(context);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar vehículo'),
            ),

      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => const _VehicleMessage(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos comprobar tu sesión',
          description: 'Comprueba tu conexión e intenta nuevamente.',
        ),

        data: (user) {
          if (user == null) {
            return const _VehicleMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sesión no disponible',
              description:
                  'Inicia sesión nuevamente para consultar tus vehículos.',
            );
          }

          final vehiclesState = ref.watch(vehiclesProvider(user.uid));

          return vehiclesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),

            error: (error, stackTrace) => const _VehicleMessage(
              icon: Icons.error_outline_rounded,
              title: 'No pudimos cargar tus vehículos',
              description: 'Comprueba tu conexión y los permisos de Firebase.',
            ),

            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const _EmptyVehicles();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Text(
                    'Tus vehículos',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Administra la información de los vehículos '
                    'que utilizas para viajar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 22),

                  ...vehicles.map(
                    (vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _VehicleCard(
                        vehicle: vehicle,
                        onEdit: () {
                          _openVehicleForm(context, vehicle: vehicle);
                        },
                        onDelete: () {
                          _confirmDelete(context, ref, vehicle);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar vehículo'),
          content: Text('¿Deseas eliminar ${vehicle.displayName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(vehicleControllerProvider.notifier)
          .deleteVehicle(vehicle.id);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible eliminar el vehículo.')),
      );
    }
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  String _vehicleTypeLabel(String value) {
    return switch (value) {
      'car' => 'Automóvil',
      'motorcycle' => 'Motocicleta',
      'pickup' => 'Pickup',
      'van' => 'Van',
      'truck' => 'Camión',
      _ => 'Otro',
    };
  }

  String _fuelTypeLabel(String value) {
    return switch (value) {
      'gasoline' => 'Gasolina',
      'diesel' => 'Diésel',
      'hybrid' => 'Híbrido',
      'electric' => 'Eléctrico',
      _ => 'Otro',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _expirationLabel(String name, DateTime? date) {
    if (date == null) {
      return '$name: sin fecha registrada';
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final expiration = DateUtils.dateOnly(date);

    if (expiration.isBefore(today)) {
      return '$name: fecha registrada vencida '
          '(${_formatDate(date)})';
    }

    if (expiration.isAtSameMomentAs(today)) {
      return '$name: fecha de vencimiento hoy';
    }

    return '$name: fecha registrada '
        '${_formatDate(date)}';
  }

  List<Widget> _buildConsumptionInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget line({required String label, required String value}) {
      return Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.speed_rounded, size: 18, color: colorScheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text('$label: $value', style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    final fuel = vehicle.fuelConsumptionKmPerLiter;
    final electric = vehicle.electricConsumptionKwhPer100Km;

    switch (vehicle.fuelType) {
      case 'gasoline':
      case 'diesel':
        return [
          line(
            label: 'Rendimiento promedio',
            value: fuel == null
                ? 'No registrado'
                : '${fuel.toStringAsFixed(2)} km/L',
          ),
        ];

      case 'electric':
        return [
          line(
            label: 'Consumo eléctrico',
            value: electric == null
                ? 'No registrado'
                : '${electric.toStringAsFixed(2)} kWh/100 km',
          ),
        ];

      case 'hybrid':
        return [
          line(
            label: 'Rendimiento de combustible',
            value: fuel == null
                ? 'No registrado'
                : '${fuel.toStringAsFixed(2)} km/L',
          ),
          line(
            label: 'Consumo eléctrico',
            value: electric == null
                ? 'No registrado'
                : '${electric.toStringAsFixed(2)} kWh/100 km',
          ),
        ];

      default:
        return [line(label: 'Consumo', value: 'Sin estimación disponible')];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final icon = vehicle.isElectric
        ? Icons.electric_car_outlined
        : Icons.directions_car_outlined;

    final plateEnding = vehicle.plateEnding;

    final lastNumericDigit = vehicle.plateLastNumericDigit;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onSecondaryContainer,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${vehicle.registrationRegion}, '
                        '${vehicle.registrationCountry}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VehicleTag(label: _vehicleTypeLabel(vehicle.vehicleType)),
                _VehicleTag(label: _fuelTypeLabel(vehicle.fuelType)),
              ],
            ),

            const SizedBox(height: 12),

            ..._buildConsumptionInfo(context),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 19,
                  color: colorScheme.secondary,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plateEnding == null
                            ? 'Terminación de placa: no registrada'
                            : 'Terminación registrada: $plateEnding',
                        style: theme.textTheme.bodyMedium,
                      ),

                      if (plateEnding != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          lastNumericDigit == null
                              ? 'No se detectó un dígito numérico.'
                              : 'Último dígito numérico: $lastNumericDigit',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 8),

            Text(
              _expirationLabel('Seguro', vehicle.insuranceValidUntil),
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 6),

            if (vehicle.insuranceCompany != null) ...[
              Text(
                'Aseguradora declarada: ${vehicle.insuranceCompany}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
            ],

            Text(
              _expirationLabel('Verificación', vehicle.verificationValidUntil),
              style: theme.textTheme.bodySmall,
            ),

            if (vehicle.verificationHologram != null) ...[
              const SizedBox(height: 6),
              Text(
                'Holograma declarado: ${vehicle.verificationHologram}',
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 8),

            Text(
              'Las vigencias son datos registrados por el usuario.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTag extends StatelessWidget {
  final String label;

  const _VehicleTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _EmptyVehicles extends StatelessWidget {
  const _EmptyVehicles();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 76,
                color: colorScheme.primary,
              ),

              const SizedBox(height: 22),

              Text(
                'Todavía no tienes vehículos',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Registra tu automóvil o cualquier otro vehículo '
                'que utilices para viajar. Después podrás utilizar '
                'sus datos para calcular combustible y revisar '
                'requisitos de circulación.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _VehicleMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.primary),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
