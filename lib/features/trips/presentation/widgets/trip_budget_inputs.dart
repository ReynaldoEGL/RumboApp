import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/trips/application/trip_form_provider.dart';

class TripBudgetInputs extends ConsumerWidget {
  const TripBudgetInputs({super.key, required this.formArgs});

  final TripFormArgs formArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(tripFormProvider(formArgs));
    final controller = ref.read(tripFormProvider(formArgs).notifier);
    final theme = Theme.of(context);
    final currency = selections.currencyCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hospedaje y regreso', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Indica 0 noches si no necesitas hotel. Si aún no lo sabes, '
          'deja el campo vacío y el presupuesto quedará pendiente.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('trip-budget-nights'),
          initialValue: selections.lodgingNights?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Noches de hospedaje',
            hintText: 'Ej. 2, o 0 si no necesitas hotel',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (text) {
            controller.setLodgingNights(int.tryParse(text.trim()));
          },
          validator: (value) {
            final normalized = value?.trim() ?? '';
            if (normalized.isEmpty) return null;
            final nights = int.tryParse(normalized);
            if (nights == null || nights < 0) {
              return 'Ingresa un número entero no negativo.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('trip-budget-nightly-rate'),
          initialValue: selections.lodgingNightlyRate?.toString() ?? '',
          decoration: InputDecoration(
            labelText: 'Precio por noche ($currency)',
            hintText: 'Ej. 1200',
            helperText: selections.lodgingNights == 0
                ? 'No se cobrará hospedaje con 0 noches.'
                : 'Tarifa manual; no es una cotización de hotel.',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          onChanged: (text) {
            controller.setLodgingNightlyRate(_readDecimal(text));
          },
          validator: (value) => _validateDecimal(value, allowZero: false),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Incluir viaje de regreso'),
          subtitle: const Text(
            'No duplicaremos la distancia ni los peajes de ida.',
          ),
          value: selections.includeReturn,
          onChanged: controller.setIncludeReturn,
        ),
        if (selections.includeReturn) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('trip-budget-return-distance'),
            initialValue: selections.returnDistanceKm?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Distancia del regreso (km)',
              hintText: 'Ej. 280',
              helperText:
                  'Introduce la distancia estimada del trayecto de regreso.',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            onChanged: (text) {
              controller.setReturnDistanceKm(_readDecimal(text));
            },
            validator: (value) => _validateDecimal(value, allowZero: false),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('trip-budget-return-tolls'),
            initialValue: selections.returnTollsAmount?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'Peajes del regreso ($currency)',
              hintText: 'Ej. 350',
              helperText:
                  'Introduce 0 si confirmaste que no habrá peajes; '
                  'déjalo vacío si aún no conoces el costo.',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            onChanged: (text) {
              controller.setReturnTollsAmount(_readDecimal(text));
            },
            validator: (value) => _validateDecimal(value, allowZero: true),
          ),
        ],
      ],
    );
  }

  static double? _readDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String? _validateDecimal(String? value, {required bool allowZero}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    final amount = _readDecimal(normalized);
    if (amount == null ||
        !amount.isFinite ||
        (allowZero ? amount < 0 : amount <= 0)) {
      return allowZero
          ? 'Ingresa un valor mayor o igual que cero.'
          : 'Ingresa un valor mayor que cero.';
    }
    return null;
  }
}
