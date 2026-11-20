import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/trips/application/trip_providers.dart';
import 'package:rumboapp/features/trips/domain/trip.dart';
import 'package:rumboapp/features/trips/presentation/screens/trip_form_screen.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  Future<void> _openTripForm(BuildContext context, {Trip? trip}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TripFormScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis viajes')),
      floatingActionButton: authState.asData?.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                _openTripForm(context);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Planear viaje'),
            ),
      body: authState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return const _TripMessage(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos comprobar tu sesión',
            description: 'Comprueba tu conexión e intenta nuevamente.',
          );
        },
        data: (user) {
          if (user == null) {
            return const _TripMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sesión no disponible',
              description:
                  'Inicia sesión para consultar y administrar tus viajes.',
            );
          }

          final tripsState = ref.watch(tripsProvider(user.uid));

          return tripsState.when(
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stackTrace) {
              return const _TripMessage(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar tus viajes',
                description:
                    'Comprueba tu conexión y los permisos de Firebase.',
              );
            },
            data: (trips) {
              if (trips.isEmpty) {
                return const _EmptyTrips();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Text(
                    'Tus viajes',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta y administra los recorridos que estás '
                    'planeando o que ya realizaste.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...trips.map(
                    (trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TripCard(
                        trip: trip,
                        onEdit: () {
                          _openTripForm(context, trip: trip);
                        },
                        onDelete: () {
                          _confirmDelete(context, ref, trip);
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
    Trip trip,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar viaje'),
          content: Text('¿Deseas eliminar "${trip.title}"?'),
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
      await ref.read(tripControllerProvider.notifier).deleteTrip(trip.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible eliminar el viaje: $error')),
      );
    }
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
  });

  final Trip trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _dateLabel() {
    final departure = _formatDate(trip.departureDate);
    final returnDate = trip.returnDate;

    if (returnDate == null) {
      return 'Salida: $departure';
    }

    return '$departure – ${_formatDate(returnDate)}';
  }

  Color _statusColor(ColorScheme colorScheme) {
    return switch (trip.status) {
      TripStatus.planned => colorScheme.primaryContainer,
      TripStatus.inProgress => colorScheme.tertiaryContainer,
      TripStatus.completed => colorScheme.secondaryContainer,
      TripStatus.cancelled => colorScheme.errorContainer,
    };
  }

  Color _statusTextColor(ColorScheme colorScheme) {
    return switch (trip.status) {
      TripStatus.planned => colorScheme.onPrimaryContainer,
      TripStatus.inProgress => colorScheme.onTertiaryContainer,
      TripStatus.completed => colorScheme.onSecondaryContainer,
      TripStatus.cancelled => colorScheme.onErrorContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final estimate = trip.energyEstimate;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.luggage_outlined,
                    color: colorScheme.onSecondaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _dateLabel(),
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
            Text(trip.origin, style: theme.textTheme.bodyMedium),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            Text(
              trip.destination,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(colorScheme),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trip.status.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _statusTextColor(colorScheme),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trip.distanceKm != null)
                  _TripTag(label: '${trip.distanceKm!.toStringAsFixed(1)} km'),
              ],
            ),
            if (trip.vehicleSnapshot != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 19,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      trip.vehicleSnapshot!.displayName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (estimate != null) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Estimación energética',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${estimate.quantity.toStringAsFixed(2)} '
                '${estimate.unit} · '
                '${estimate.cost.toStringAsFixed(2)} '
                '${trip.currencyCode}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (estimate.isPartial) ...[
                const SizedBox(height: 4),
                Text(
                  'Estimación parcial: no incluye consumo eléctrico.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            if (trip.notes != null) ...[
              const SizedBox(height: 14),
              Text(
                trip.notes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripTag extends StatelessWidget {
  const _TripTag({required this.label});

  final String label;

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

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.luggage_outlined,
                size: 76,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 22),
              Text(
                'Todavía no tienes viajes',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Planea tu próximo recorrido, registra sus fechas, '
                'asigna un vehículo y conserva tus datos de viaje '
                'en un solo lugar.',
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

class _TripMessage extends StatelessWidget {
  const _TripMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
