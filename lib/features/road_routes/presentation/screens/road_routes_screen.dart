import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/auth/application/auth_providers.dart';

import 'package:rumboapp/features/road_routes/application/road_route_planner_provider.dart';
import 'package:rumboapp/features/road_routes/application/road_routes_providers.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';
import 'package:rumboapp/features/road_routes/domain/route_toll.dart';
import 'package:rumboapp/features/road_routes/domain/saved_road_route.dart';

import 'package:rumboapp/features/road_routes/presentation/widgets/road_route_map.dart';
import 'package:rumboapp/features/road_routes/presentation/widgets/current_location_button.dart';

import 'package:rumboapp/features/trips/presentation/screens/trip_form_screen.dart';

class RoadRoutesScreen extends ConsumerStatefulWidget {
  const RoadRoutesScreen({super.key});

  @override
  ConsumerState<RoadRoutesScreen> createState() => _RoadRoutesScreenState();
}

class _RoadRoutesScreenState extends ConsumerState<RoadRoutesScreen> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();

    final planner = ref.read(roadRoutePlannerProvider);

    _originController = TextEditingController(text: planner.originQuery);

    _destinationController = TextEditingController(
      text: planner.destinationQuery,
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _setControllerText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _selectOrigin(RouteLocation location) {
    ref.read(roadRoutePlannerProvider.notifier).selectOrigin(location);

    _setControllerText(_originController, location.title);
  }

  void _selectDestination(RouteLocation location) {
    ref.read(roadRoutePlannerProvider.notifier).selectDestination(location);

    _setControllerText(_destinationController, location.title);
  }

  void _swapLocations() {
    final state = ref.read(roadRoutePlannerProvider);

    final origin = state.origin;
    final destination = state.destination;

    if (origin == null || destination == null) {
      return;
    }

    ref.read(roadRoutePlannerProvider.notifier)
      ..selectOrigin(destination)
      ..selectDestination(origin);

    _setControllerText(_originController, destination.title);
    _setControllerText(_destinationController, origin.title);
  }

  bool _isSameSavedRoute(SavedRoadRoute saved, RoadRoute route) {
    return saved.route.id == route.id &&
        saved.route.origin.hereId == route.origin.hereId &&
        saved.route.destination.hereId == route.destination.hereId;
  }

  Future<void> _createTripFromRoute(RoadRoute route) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TripFormScreen(route: route)),
    );
  }

  Future<void> _saveSelectedRoute(
    RoadRoute route,
    String? uid,
    List<SavedRoadRoute> savedRoutes,
  ) async {
    if (uid == null) {
      _showMessage('Inicia sesión para guardar tus rutas.');
      return;
    }

    if (savedRoutes.any((saved) => _isSameSavedRoute(saved, route))) {
      _showMessage('Esta ruta ya se encuentra guardada.');
      return;
    }

    try {
      await ref
          .read(savedRoadRouteControllerProvider.notifier)
          .saveRoute(route);

      if (!mounted) {
        return;
      }

      _showMessage('Ruta guardada correctamente.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('No fue posible guardar la ruta. Inténtalo nuevamente.');
    }
  }

  Future<void> _deleteSavedRoute(SavedRoadRoute savedRoute) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar ruta guardada'),
          content: Text('¿Deseas eliminar "${savedRoute.displayName}"?'),
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
          .read(savedRoadRouteControllerProvider.notifier)
          .deleteSavedRoute(savedRoute.id);

      if (!mounted) {
        return;
      }

      _showMessage('Ruta eliminada correctamente.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('No fue posible eliminar la ruta. Inténtalo nuevamente.');
    }
  }

  void _showSavedRoutePreview(SavedRoadRoute savedRoute) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SavedRoutePreview(
          savedRoute: savedRoute,
          onCreateTrip: () {
            Navigator.of(sheetContext).pop();
            _createTripFromRoute(savedRoute.route);
          },
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(roadRoutePlannerProvider);
    final authState = ref.watch(authUserProvider);
    final user = authState.asData?.value;

    final savedRoutesState = user == null
        ? null
        : ref.watch(savedRoadRoutesProvider(user.uid));

    final savedRoutes =
        savedRoutesState?.asData?.value ?? const <SavedRoadRoute>[];

    final isSaving = ref.watch(savedRoadRouteControllerProvider).isLoading;

    final selectedRoute = planner.selectedRoute;

    final selectedRouteIsSaved =
        selectedRoute != null &&
        savedRoutes.any((saved) => _isSameSavedRoute(saved, selectedRoute));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas y casetas'),
        actions: [
          IconButton(
            tooltip: 'Limpiar recorrido',
            onPressed: () {
              ref.read(roadRoutePlannerProvider.notifier).reset();

              _setControllerText(_originController, '');
              _setControllerText(_destinationController, '');
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 18.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PageHeading(
                        title: 'Planea tu recorrido',
                        description:
                            'Encuentra rutas, compara alternativas y '
                            'consulta los peajes de tu trayecto.',
                      ),
                      const SizedBox(height: 22),
                      _buildSearchSection(planner),
                      const SizedBox(height: 22),
                      const _SectionHeading(
                        title: 'Mapa del recorrido',
                        description:
                            'Consulta el trazado y la ubicación de '
                            'origen y destino.',
                      ),
                      const SizedBox(height: 12),
                      RoadRouteMap(
                        origin: planner.origin,
                        destination: planner.destination,
                        routes: planner.routes,
                        selectedRoute: selectedRoute,
                      ),
                      if (planner.routes.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        const _SectionHeading(
                          title: 'Alternativas de ruta',
                          description:
                              'Selecciona el recorrido que mejor '
                              'se adapte a tu viaje.',
                        ),
                        const SizedBox(height: 12),
                        ...planner.routes.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RouteAlternativeCard(
                              route: entry.value,
                              index: entry.key + 1,
                              selected:
                                  entry.value.id == planner.selectedRouteId,
                              onTap: () {
                                ref
                                    .read(roadRoutePlannerProvider.notifier)
                                    .selectRoute(entry.value.id);
                              },
                            ),
                          ),
                        ),
                      ],
                      if (planner.routeCalculationMessage != null) ...[
                        const SizedBox(height: 14),
                        _InlineMessage(
                          message: planner.routeCalculationMessage!,
                          isError: planner.routes.isEmpty,
                        ),
                      ],
                      if (selectedRoute != null) ...[
                        const SizedBox(height: 22),
                        _SelectedRoutePanel(
                          route: selectedRoute,
                          isSaved: selectedRouteIsSaved,
                          isSaving: isSaving,
                          onSave: () {
                            _saveSelectedRoute(
                              selectedRoute,
                              user?.uid,
                              savedRoutes,
                            );
                          },
                          onCreateTrip: () {
                            _createTripFromRoute(selectedRoute);
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      const _SectionHeading(
                        title: 'Rutas guardadas',
                        description:
                            'Consulta nuevamente los recorridos '
                            'que conservaste.',
                      ),
                      const SizedBox(height: 12),
                      _buildSavedRoutesSection(savedRoutesState),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection(RoadRoutePlannerState state) {
    final plannerController = ref.read(roadRoutePlannerProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Origen y destino',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _LocationSearchField(
              controller: _originController,
              label: 'Punto de partida',
              hint: 'Ciudad, dirección o lugar',
              icon: Icons.trip_origin_rounded,
              isSearching: state.isSearchingOrigin,
              suggestions: state.originSuggestions,
              message: state.originSearchMessage,
              onChanged: plannerController.setOriginQuery,
              onSearch: plannerController.searchOriginNow,
              onClear: () {
                _setControllerText(_originController, '');
                plannerController.clearOrigin();
              },
              onSelect: _selectOrigin,
            ),
            CurrentLocationButton(onLocationSelected: _selectOrigin),
            if (state.origin != null && state.destination != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Intercambiar origen y destino',
                  onPressed: _swapLocations,
                  icon: const Icon(Icons.swap_vert_rounded),
                ),
              )
            else
              const SizedBox(height: 14),
            _LocationSearchField(
              controller: _destinationController,
              label: 'Destino',
              hint: 'Ciudad, dirección o lugar',
              icon: Icons.location_on_outlined,
              isSearching: state.isSearchingDestination,
              suggestions: state.destinationSuggestions,
              message: state.destinationSearchMessage,
              onChanged: plannerController.setDestinationQuery,
              onSearch: plannerController.searchDestinationNow,
              onClear: () {
                _setControllerText(_destinationController, '');
                plannerController.clearDestination();
              },
              onSelect: _selectDestination,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(state.currencyCode),
                    initialValue: state.currencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Moneda de peajes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'MXN',
                        child: Text('MXN · Peso mexicano'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('USD · Dólar'),
                      ),
                      DropdownMenuItem(
                        value: 'CAD',
                        child: Text('CAD · Dólar canadiense'),
                      ),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
                      DropdownMenuItem(
                        value: 'GBP',
                        child: Text('GBP · Libra'),
                      ),
                      DropdownMenuItem(
                        value: 'BRL',
                        child: Text('BRL · Real brasileño'),
                      ),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY · Yen')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        plannerController.setCurrencyCode(value);
                      }
                    },
                  ),
                ),
                FilledButton.icon(
                  onPressed: state.canCalculate
                      ? () {
                          plannerController.calculateRoutes(alternatives: 2);
                        }
                      : null,
                  icon: state.isCalculatingRoutes
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route_rounded),
                  label: Text(
                    state.isCalculatingRoutes
                        ? 'Calculando...'
                        : 'Calcular recorrido',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'La moneda seleccionada se utiliza para mostrar las tarifas '
              'de peaje cuando están disponibles.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRoutesSection(
    AsyncValue<List<SavedRoadRoute>>? savedRoutesState,
  ) {
    if (savedRoutesState == null) {
      return const _EmptySectionMessage(
        icon: Icons.bookmark_outline_rounded,
        title: 'Guarda tus recorridos',
        description:
            'Las rutas que guardes aparecerán aquí para '
            'consultarlas nuevamente.',
      );
    }

    return savedRoutesState.when(
      loading: () {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) {
        return const _EmptySectionMessage(
          icon: Icons.route_outlined,
          title: 'Tus rutas no están disponibles',
          description:
              'No fue posible mostrar tus rutas guardadas en este momento.',
        );
      },
      data: (savedRoutes) {
        if (savedRoutes.isEmpty) {
          return const _EmptySectionMessage(
            icon: Icons.bookmark_border_rounded,
            title: 'Aún no tienes rutas guardadas',
            description:
                'Cuando guardes una alternativa, podrás '
                'consultarla desde esta sección.',
          );
        }

        return Column(
          children: [
            for (final savedRoute in savedRoutes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SavedRouteCard(
                  savedRoute: savedRoute,
                  onPreview: () {
                    _showSavedRoutePreview(savedRoute);
                  },
                  onDelete: () {
                    _deleteSavedRoute(savedRoute);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LocationSearchField extends StatelessWidget {
  const _LocationSearchField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isSearching,
    required this.suggestions,
    required this.message,
    required this.onChanged,
    required this.onSearch,
    required this.onClear,
    required this.onSelect,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isSearching;
  final List<RouteLocation> suggestions;
  final String? message;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSearch;
  final VoidCallback onClear;
  final ValueChanged<RouteLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: (_) {
            onSearch();
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpiar',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 7),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) {
                  return Divider(
                    height: 1,
                    indent: 56,
                    color: colorScheme.outlineVariant,
                  );
                },
                itemBuilder: (context, index) {
                  final location = suggestions[index];

                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      location.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      location.addressLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      onSelect(location);
                    },
                  );
                },
              ),
            ),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 7),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteAlternativeCard extends StatelessWidget {
  const _RouteAlternativeCard({
    required this.route,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final RoadRoute route;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.48)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternativa $index',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _RouteMetric(
                          icon: Icons.straighten_rounded,
                          label: _formatDistance(route.distanceKilometers),
                        ),
                        _RouteMetric(
                          icon: Icons.schedule_rounded,
                          label: _formatDuration(route.durationSeconds),
                        ),
                        _RouteMetric(
                          icon: Icons.toll_rounded,
                          label: '${route.tolls.length} registros',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SelectedRoutePanel extends StatelessWidget {
  const _SelectedRoutePanel({
    required this.route,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
    required this.onCreateTrip,
  });

  final RoadRoute route;
  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del recorrido',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.straighten_rounded,
                    label: 'Distancia',
                    value: _formatDistance(route.distanceKilometers),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.schedule_rounded,
                    label: 'Duración estimada',
                    value: _formatDuration(route.durationSeconds),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Peajes del recorrido',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _RouteTollDetails(route: route),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving || isSaved ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isSaved
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                      ),
                label: Text(
                  isSaving
                      ? 'Guardando...'
                      : isSaved
                      ? 'Ruta guardada'
                      : 'Guardar ruta',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateTrip,
                icon: const Icon(Icons.luggage_outlined),
                label: const Text('Crear viaje con esta ruta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(height: 9),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
    );
  }
}

class _RouteTollDetails extends StatelessWidget {
  const _RouteTollDetails({required this.route});

  final RoadRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tolls = route.tolls;

    if (!route.tollDataIncluded) {
      return const _InlineMessage(
        message: 'No se obtuvo información de peajes para este recorrido.',
      );
    }

    if (tolls.isEmpty) {
      return const _InlineMessage(
        message: 'No se reportaron peajes en esta alternativa.',
        isError: false,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < tolls.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TollCard(toll: tolls[index], index: index + 1),
          ),
        Text(
          'Las tarifas y los métodos de pago dependen de la información '
          'disponible para cada sistema de cobro.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TollCard extends StatelessWidget {
  const _TollCard({required this.toll, required this.index});

  final RouteToll toll;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.toll_rounded, color: colorScheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  toll.tollSystem ?? 'Sistema de peaje $index',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (toll.countryCode != null)
                Text(
                  toll.countryCode!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (toll.fares.isEmpty)
            Text(
              'No hay tarifas disponibles para este sistema.',
              style: theme.textTheme.bodyMedium,
            ),
          for (final fare in toll.fares)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TollFareDetails(fare: fare),
            ),
        ],
      ),
    );
  }
}

class _TollFareDetails extends StatelessWidget {
  const _TollFareDetails({required this.fare});

  final RouteTollFare fare;

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
            const SizedBox(width: 12),
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
                label: Text(_paymentMethodLabel(method)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({
    required this.savedRoute,
    required this.onPreview,
    required this.onDelete,
  });

  final SavedRoadRoute savedRoute;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = savedRoute.route;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.bookmark_rounded,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savedRoute.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formatDistance(route.distanceKilometers)} · '
                    '${_formatDuration(route.durationSeconds)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ver recorrido',
              onPressed: onPreview,
              icon: const Icon(Icons.map_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar ruta',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRoutePreview extends StatelessWidget {
  const _SavedRoutePreview({
    required this.savedRoute,
    required this.onCreateTrip,
  });

  final SavedRoadRoute savedRoute;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    final route = savedRoute.route;
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              savedRoute.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${_formatDistance(route.distanceKilometers)} · '
              '${_formatDuration(route.durationSeconds)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            RoadRouteMap(
              origin: route.origin,
              destination: route.destination,
              routes: [route],
              selectedRoute: route,
            ),
            const SizedBox(height: 20),
            Text(
              'Peajes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _RouteTollDetails(route: route),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateTrip,
                icon: const Icon(Icons.luggage_outlined),
                label: const Text('Crear viaje con esta ruta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final foreground = isError
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    final background = isError
        ? colorScheme.errorContainer.withValues(alpha: 0.45)
        : colorScheme.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(double distance) {
  return '${distance.toStringAsFixed(1)} km';
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
