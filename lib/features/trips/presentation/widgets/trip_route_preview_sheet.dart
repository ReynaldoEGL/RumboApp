import 'package:flutter/material.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';
import 'package:rumboapp/features/road_routes/presentation/widgets/road_route_map.dart';

class TripRoutePreviewSheet extends StatelessWidget {
  const TripRoutePreviewSheet({super.key, required this.route});

  final RoadRoute route;

  static Future<void> show(BuildContext context, RoadRoute route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return TripRoutePreviewSheet(route: route);
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours h';
    }

    return '$hours h $minutes min';
  }

  String _formatDistance(double kilometers) {
    return '${kilometers.toStringAsFixed(1)} km';
  }

  String _paymentMethodLabel(String method) {
    return switch (method) {
      'cash' => 'Efectivo',
      'cashExact' => 'Efectivo exacto',
      'cashTollCollector' => 'Cobro en caseta',
      'bankCard' => 'Tarjeta bancaria',
      'tollTag' => 'Tag de peaje',
      'transponder' => 'Transpondedor',
      _ => method,
    };
  }

  Widget _buildTollDetails(BuildContext context) {
    final theme = Theme.of(context);
    final tolls = route.tolls;

    if (!route.tollDataIncluded) {
      return const _TollMessage(
        message: 'No se obtuvo información de peajes para este recorrido.',
      );
    }

    if (tolls.isEmpty) {
      return const _TollMessage(
        message: 'No se reportaron peajes en esta alternativa.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < tolls.length; index++)
          _TollCard(
            index: index + 1,
            toll: tolls[index],
            paymentMethodLabel: _paymentMethodLabel,
          ),
        const SizedBox(height: 6),
        Text(
          'Las tarifas son estimaciones proporcionadas por el servicio '
          'de rutas y pueden variar según las condiciones del recorrido.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorrido del viaje',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${route.origin.addressLabel} → '
              '${route.destination.addressLabel}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _RouteSummaryChip(
                  icon: Icons.straighten_rounded,
                  label: _formatDistance(route.distanceKilometers),
                ),
                _RouteSummaryChip(
                  icon: Icons.schedule_rounded,
                  label: _formatDuration(route.durationSeconds),
                ),
                _RouteSummaryChip(
                  icon: Icons.toll_rounded,
                  label: '${route.tolls.length} registros de peaje',
                ),
              ],
            ),
            const SizedBox(height: 18),
            RoadRouteMap(
              origin: route.origin,
              destination: route.destination,
              routes: [route],
              selectedRoute: route,
            ),
            const SizedBox(height: 24),
            Text(
              'Información de peajes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _buildTollDetails(context),
          ],
        ),
      ),
    );
  }
}

class _TollCard extends StatelessWidget {
  const _TollCard({
    required this.index,
    required this.toll,
    required this.paymentMethodLabel,
  });

  final int index;
  final RouteToll toll;
  final String Function(String) paymentMethodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              toll.tollSystem ?? 'Sistema de peaje $index',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (toll.countryCode != null) ...[
              const SizedBox(height: 3),
              Text(toll.countryCode!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            if (toll.fares.isEmpty) const Text('No hay tarifas disponibles.'),
            for (final fare in toll.fares)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TollFareDetails(
                  fare: fare,
                  paymentMethodLabel: paymentMethodLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TollFareDetails extends StatelessWidget {
  const _TollFareDetails({
    required this.fare,
    required this.paymentMethodLabel,
  });

  final RouteTollFare fare;
  final String Function(String) paymentMethodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final amount = fare.amount;
    final currency = fare.currencyCode;

    final priceLabel = amount == null || currency == null
        ? 'Tarifa no disponible'
        : '$currency ${amount.toStringAsFixed(2)}';

    final convertedLabel =
        fare.convertedAmount != null && fare.convertedCurrencyCode != null
        ? '${fare.convertedCurrencyCode} '
              '${fare.convertedAmount!.toStringAsFixed(2)}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                fare.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (convertedLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            'Importe convertido: $convertedLabel',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (fare.paymentMethods.isNotEmpty) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: fare.paymentMethods.map((method) {
              return Chip(
                visualDensity: VisualDensity.compact,
                label: Text(paymentMethodLabel(method)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _RouteSummaryChip extends StatelessWidget {
  const _RouteSummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(icon, size: 17, color: theme.colorScheme.primary),
      label: Text(label),
    );
  }
}

class _TollMessage extends StatelessWidget {
  const _TollMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}
