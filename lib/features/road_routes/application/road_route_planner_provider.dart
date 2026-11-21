import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/application/here_routing_service_provider.dart';
import 'package:rumboapp/features/road_routes/data/here_routing_service.dart';
import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

final roadRoutePlannerProvider =
    NotifierProvider<RoadRoutePlannerController, RoadRoutePlannerState>(
      RoadRoutePlannerController.new,
    );

class RoadRoutePlannerState {
  const RoadRoutePlannerState({
    this.originQuery = '',
    this.destinationQuery = '',
    this.origin,
    this.destination,
    this.originSuggestions = const [],
    this.destinationSuggestions = const [],
    this.routes = const [],
    this.selectedRouteId,
    this.currencyCode = 'MXN',
    this.isSearchingOrigin = false,
    this.isSearchingDestination = false,
    this.isCalculatingRoutes = false,
    this.originSearchMessage,
    this.destinationSearchMessage,
    this.routeCalculationMessage,
  });

  final String originQuery;
  final String destinationQuery;

  final RouteLocation? origin;
  final RouteLocation? destination;

  final List<RouteLocation> originSuggestions;
  final List<RouteLocation> destinationSuggestions;

  final List<RoadRoute> routes;
  final String? selectedRouteId;

  final String currencyCode;

  final bool isSearchingOrigin;
  final bool isSearchingDestination;
  final bool isCalculatingRoutes;

  final String? originSearchMessage;
  final String? destinationSearchMessage;
  final String? routeCalculationMessage;

  bool get canCalculate {
    return origin != null && destination != null && !isCalculatingRoutes;
  }

  RoadRoute? get selectedRoute {
    for (final route in routes) {
      if (route.id == selectedRouteId) {
        return route;
      }
    }

    return null;
  }

  RoadRoutePlannerState copyWith({
    String? originQuery,
    String? destinationQuery,
    RouteLocation? origin,
    RouteLocation? destination,
    bool clearOrigin = false,
    bool clearDestination = false,
    List<RouteLocation>? originSuggestions,
    List<RouteLocation>? destinationSuggestions,
    List<RoadRoute>? routes,
    String? selectedRouteId,
    bool clearSelectedRouteId = false,
    String? currencyCode,
    bool? isSearchingOrigin,
    bool? isSearchingDestination,
    bool? isCalculatingRoutes,
    String? originSearchMessage,
    bool clearOriginSearchMessage = false,
    String? destinationSearchMessage,
    bool clearDestinationSearchMessage = false,
    String? routeCalculationMessage,
    bool clearRouteCalculationMessage = false,
  }) {
    return RoadRoutePlannerState(
      originQuery: originQuery ?? this.originQuery,
      destinationQuery: destinationQuery ?? this.destinationQuery,
      origin: clearOrigin ? null : origin ?? this.origin,
      destination: clearDestination ? null : destination ?? this.destination,
      originSuggestions: originSuggestions ?? this.originSuggestions,
      destinationSuggestions:
          destinationSuggestions ?? this.destinationSuggestions,
      routes: routes ?? this.routes,
      selectedRouteId: clearSelectedRouteId
          ? null
          : selectedRouteId ?? this.selectedRouteId,
      currencyCode: currencyCode ?? this.currencyCode,
      isSearchingOrigin: isSearchingOrigin ?? this.isSearchingOrigin,
      isSearchingDestination:
          isSearchingDestination ?? this.isSearchingDestination,
      isCalculatingRoutes: isCalculatingRoutes ?? this.isCalculatingRoutes,
      originSearchMessage: clearOriginSearchMessage
          ? null
          : originSearchMessage ?? this.originSearchMessage,
      destinationSearchMessage: clearDestinationSearchMessage
          ? null
          : destinationSearchMessage ?? this.destinationSearchMessage,
      routeCalculationMessage: clearRouteCalculationMessage
          ? null
          : routeCalculationMessage ?? this.routeCalculationMessage,
    );
  }
}

class RoadRoutePlannerController extends Notifier<RoadRoutePlannerState> {
  Timer? _originSearchTimer;
  Timer? _destinationSearchTimer;

  int _originSearchVersion = 0;
  int _destinationSearchVersion = 0;
  int _routeRequestVersion = 0;

  bool _disposed = false;

  @override
  RoadRoutePlannerState build() {
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;

      _originSearchTimer?.cancel();
      _destinationSearchTimer?.cancel();

      _originSearchVersion++;
      _destinationSearchVersion++;
      _routeRequestVersion++;
    });

    return const RoadRoutePlannerState();
  }

  void setOriginQuery(String value) {
    final normalized = value;
    final requestVersion = ++_originSearchVersion;

    _originSearchTimer?.cancel();

    _invalidateRouteResults();

    state = state.copyWith(
      originQuery: normalized,
      clearOrigin: true,
      originSuggestions: const [],
      isSearchingOrigin: false,
      clearOriginSearchMessage: true,
    );

    if (normalized.trim().length < 2) {
      return;
    }

    _originSearchTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_performOriginSearch(normalized.trim(), requestVersion));
    });
  }

  void setDestinationQuery(String value) {
    final normalized = value;
    final requestVersion = ++_destinationSearchVersion;

    _destinationSearchTimer?.cancel();

    _invalidateRouteResults();

    state = state.copyWith(
      destinationQuery: normalized,
      clearDestination: true,
      destinationSuggestions: const [],
      isSearchingDestination: false,
      clearDestinationSearchMessage: true,
    );

    if (normalized.trim().length < 2) {
      return;
    }

    _destinationSearchTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_performDestinationSearch(normalized.trim(), requestVersion));
    });
  }

  Future<void> searchOriginNow() async {
    _originSearchTimer?.cancel();

    final requestVersion = ++_originSearchVersion;
    final query = state.originQuery.trim();

    if (query.length < 2) {
      state = state.copyWith(
        originSuggestions: const [],
        isSearchingOrigin: false,
        clearOriginSearchMessage: true,
      );

      return;
    }

    await _performOriginSearch(query, requestVersion);
  }

  Future<void> searchDestinationNow() async {
    _destinationSearchTimer?.cancel();

    final requestVersion = ++_destinationSearchVersion;
    final query = state.destinationQuery.trim();

    if (query.length < 2) {
      state = state.copyWith(
        destinationSuggestions: const [],
        isSearchingDestination: false,
        clearDestinationSearchMessage: true,
      );

      return;
    }

    await _performDestinationSearch(query, requestVersion);
  }

  Future<void> _performOriginSearch(String query, int requestVersion) async {
    if (_disposed || requestVersion != _originSearchVersion) {
      return;
    }

    state = state.copyWith(
      isSearchingOrigin: true,
      clearOriginSearchMessage: true,
    );

    try {
      final searchCenter =
          state.destination?.coordinate ??
          HereRoutingService.defaultSearchCenter;

      final locations = await ref
          .read(hereRoutingServiceProvider)
          .searchLocations(query: query, at: searchCenter);

      if (_disposed || requestVersion != _originSearchVersion) {
        return;
      }

      state = state.copyWith(
        originSuggestions: locations,
        isSearchingOrigin: false,
        originSearchMessage: locations.isEmpty
            ? 'No encontramos coincidencias. Prueba con otra forma de escribir la ubicación.'
            : null,
        clearOriginSearchMessage: locations.isNotEmpty,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Falló la búsqueda del punto de partida.',
        name: 'rumbo.road_routes',
        error: error,
        stackTrace: stackTrace,
      );

      if (_disposed || requestVersion != _originSearchVersion) {
        return;
      }

      state = state.copyWith(
        originSuggestions: const [],
        isSearchingOrigin: false,
        originSearchMessage: 'No fue posible buscar ubicaciones. Comprueba tu conexión e inténtalo nuevamente.',
      );
    }
  }

  Future<void> _performDestinationSearch(
    String query,
    int requestVersion,
  ) async {
    if (_disposed || requestVersion != _destinationSearchVersion) {
      return;
    }

    state = state.copyWith(
      isSearchingDestination: true,
      clearDestinationSearchMessage: true,
    );

    try {
      final searchCenter =
          state.origin?.coordinate ?? HereRoutingService.defaultSearchCenter;

      final locations = await ref
          .read(hereRoutingServiceProvider)
          .searchLocations(query: query, at: searchCenter);

      if (_disposed || requestVersion != _destinationSearchVersion) {
        return;
      }

      state = state.copyWith(
        destinationSuggestions: locations,
        isSearchingDestination: false,
        destinationSearchMessage: locations.isEmpty
            ? 'No encontramos coincidencias. Prueba con otra forma de escribir la ubicación.'
            : null,
        clearDestinationSearchMessage: locations.isNotEmpty,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Falló la búsqueda del destino.',
        name: 'rumbo.road_routes',
        error: error,
        stackTrace: stackTrace,
      );

      if (_disposed || requestVersion != _destinationSearchVersion) {
        return;
      }

      state = state.copyWith(
        destinationSuggestions: const [],
        isSearchingDestination: false,
        destinationSearchMessage: 'No fue posible buscar ubicaciones. Comprueba tu conexión e inténtalo nuevamente.',
      );
    }
  }

  void selectOrigin(RouteLocation location) {
    _originSearchTimer?.cancel();
    _originSearchVersion++;

    _invalidateRouteResults();

    state = state.copyWith(
      originQuery: location.title,
      origin: location,
      originSuggestions: const [],
      isSearchingOrigin: false,
      clearOriginSearchMessage: true,
    );
  }

  void selectDestination(RouteLocation location) {
    _destinationSearchTimer?.cancel();
    _destinationSearchVersion++;

    _invalidateRouteResults();

    state = state.copyWith(
      destinationQuery: location.title,
      destination: location,
      destinationSuggestions: const [],
      isSearchingDestination: false,
      clearDestinationSearchMessage: true,
    );
  }

  void clearOrigin() {
    setOriginQuery('');
  }

  void clearDestination() {
    setDestinationQuery('');
  }

  void setCurrencyCode(String value) {
    final normalized = value.trim().toUpperCase();

    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
      return;
    }

    if (normalized == state.currencyCode) {
      return;
    }

    _invalidateRouteResults();

    state = state.copyWith(currencyCode: normalized);
  }

  Future<void> calculateRoutes({
    int alternatives = 2,
    DateTime? departureTime,
  }) async {
    final origin = state.origin;
    final destination = state.destination;

    if (origin == null || destination == null) {
      state = state.copyWith(
        routeCalculationMessage:
            'Selecciona un origen y un destino para continuar.',
        isCalculatingRoutes: false,
      );

      return;
    }

    if (origin.hereId == destination.hereId) {
      state = state.copyWith(
        routeCalculationMessage: 'El origen y el destino deben ser diferentes.',
        isCalculatingRoutes: false,
      );

      return;
    }

    final requestVersion = ++_routeRequestVersion;

    state = state.copyWith(
      isCalculatingRoutes: true,
      routes: const [],
      clearSelectedRouteId: true,
      clearRouteCalculationMessage: true,
    );

    try {
      final routes = await ref
          .read(hereRoutingServiceProvider)
          .calculateRoutes(
            origin: origin,
            destination: destination,
            alternatives: alternatives,
            currencyCode: state.currencyCode,
            departureTime: departureTime,
            includeTolls: true,
          );

      if (_disposed || requestVersion != _routeRequestVersion) {
        return;
      }

      state = state.copyWith(
        routes: routes,
        isCalculatingRoutes: false,
        selectedRouteId: routes.isEmpty ? null : routes.first.id,
        clearSelectedRouteId: routes.isEmpty,
        routeCalculationMessage: routes.isEmpty
            ? 'No se encontró una ruta entre esos puntos. Prueba seleccionando ubicaciones cercanas a una carretera.'
            : null,
        clearRouteCalculationMessage: routes.isNotEmpty,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Falló el cálculo de un recorrido.',
        name: 'rumbo.road_routes',
        error: error,
        stackTrace: stackTrace,
      );

      if (_disposed || requestVersion != _routeRequestVersion) {
        return;
      }

      final message = error is HereApiException
          ? error.message
          : 'No fue posible calcular la ruta. Inténtalo nuevamente.';

      state = state.copyWith(
        routes: const [],
        isCalculatingRoutes: false,
        clearSelectedRouteId: true,
        routeCalculationMessage: message,
      );
    }
  }

  void selectRoute(String routeId) {
    final exists = state.routes.any((route) => route.id == routeId);

    if (!exists) {
      return;
    }

    state = state.copyWith(
      selectedRouteId: routeId,
      clearRouteCalculationMessage: true,
    );
  }

  void reset() {
    _originSearchTimer?.cancel();
    _destinationSearchTimer?.cancel();

    _originSearchVersion++;
    _destinationSearchVersion++;
    _routeRequestVersion++;

    state = const RoadRoutePlannerState();
  }

  void _invalidateRouteResults() {
    _routeRequestVersion++;

    state = state.copyWith(
      routes: const [],
      clearSelectedRouteId: true,
      isCalculatingRoutes: false,
      clearRouteCalculationMessage: true,
    );
  }
}
