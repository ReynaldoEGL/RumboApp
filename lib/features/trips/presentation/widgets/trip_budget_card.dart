import 'package:flutter/material.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/trips/domain/trip_budget_estimate.dart';
import 'package:rumboapp/features/trips/domain/trip_energy_estimate.dart';

class TripBudgetCard extends StatelessWidget {
  const TripBudgetCard({
    super.key,
    required this.energy,
    required this.route,
    required this.currencyCode,
    this.lodgingNights,
    this.lodgingNightlyRate,
    this.includeReturn = false,
    this.returnEnergy,
    this.returnTollsAmount,
  });

  final TripEnergyEstimate? energy;
  final RoadRoute? route;
  final String currencyCode;
  final int? lodgingNights;
  final double? lodgingNightlyRate;
  final bool includeReturn;
  final TripEnergyEstimate? returnEnergy;
  final double? returnTollsAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final budget = calculateTripBudgetEstimate(
      energy: energy,
      route: route,
      currencyCode: currencyCode,
      lodgingNights: lodgingNights,
      lodgingNightlyRate: lodgingNightlyRate,
      includeReturn: includeReturn,
      returnEnergy: returnEnergy,
      returnTollsAmount: returnTollsAmount,
    );

    final tolls = budget.tolls;

    final energyLabel = energy == null
        ? 'Pendiente'
        : _money(energy!.cost, budget.currencyCode);

    final tollLabel = tolls == null
        ? 'Sin información de peajes'
        : tolls.reportedTolls == 0
        ? 'Sin peajes reportados'
        : tolls.isComplete
        ? _money(tolls.knownAmount, budget.currencyCode)
        : tolls.hasKnownPrices
        ? '${_money(tolls.knownAmount, budget.currencyCode)} conocidos'
        : 'Tarifa pendiente';

    final lodging = budget.lodging;
    final lodgingLabel = lodging.nights == null
        ? 'No especificado'
        : lodging.nights == 0
        ? 'Sin hospedaje (0 noches)'
        : lodging.cost == null
        ? '${lodging.nights} noche(s) · falta tarifa'
        : '${lodging.nights} noche(s) · ${_money(lodging.cost!, budget.currencyCode)}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Presupuesto del viaje',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Importes estimados con los datos que has proporcionado.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _BudgetLine(
              icon: Icons.local_gas_station_outlined,
              label: 'Energía de ida',
              value: energyLabel,
            ),
            if (energy?.isPartial == true) ...[
              const SizedBox(height: 6),
              Text(
                'Estimación parcial para vehículo híbrido: no incluye consumo eléctrico.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            _BudgetLine(
              icon: Icons.toll_outlined,
              label: 'Peajes de ida',
              value: tollLabel,
            ),
            if (tolls != null && tolls.unpricedTolls > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${tolls.unpricedTolls} peaje(s) sin una tarifa única en ${budget.currencyCode}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (tolls != null && tolls.reportedTolls == 0) ...[
              const SizedBox(height: 6),
              Text(
                'No se encontraron peajes; esto no garantiza que el recorrido sea gratuito.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            _BudgetLine(
              icon: Icons.hotel_outlined,
              label: 'Hospedaje',
              value: lodgingLabel,
            ),
            if (includeReturn) ...[
              const SizedBox(height: 16),
              _BudgetLine(
                icon: Icons.route_outlined,
                label: 'Energía de regreso',
                value: returnEnergy == null
                    ? 'Pendiente de distancia, vehículo o precio'
                    : _money(returnEnergy!.cost, budget.currencyCode),
              ),
              if (returnEnergy?.isPartial == true) ...[
                const SizedBox(height: 6),
                Text(
                  'Estimación parcial de regreso para vehículo híbrido.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              _BudgetLine(
                icon: Icons.toll_outlined,
                label: 'Peajes de regreso',
                value: returnTollsAmount == null
                    ? 'Pendiente de especificar'
                    : _money(returnTollsAmount!, budget.currencyCode),
              ),
            ],
            const SizedBox(height: 18),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 10),
            Text(
              'Subtotal conocido',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              budget.hasKnownCosts
                  ? _money(budget.knownSubtotal, budget.currencyCode)
                  : 'Pendiente de calcular',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (budget.isPartial)
              Text(
                'Presupuesto parcial: falta completar algún costo o dato del recorrido.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                'Todos los conceptos configurados tienen un importe. No son precios garantizados.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'El regreso no se duplica automáticamente: utiliza su distancia y peajes ingresados. '
              'El consumo utiliza el mismo vehículo y precio energético de ida. '
              'No se incluyen alimentación, estacionamientos ni otros gastos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los precios que ingreses se expresan en ${budget.currencyCode}. ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _money(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
