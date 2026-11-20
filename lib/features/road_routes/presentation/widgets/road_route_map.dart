import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:rumboapp/features/road_routes/domain/road_route.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

class RoadRouteMap extends StatefulWidget {
  const RoadRouteMap({
    super.key,
    required this.origin,
    required this.destination,
    required this.routes,
    required this.selectedRoute,
  });

  final RouteLocation? origin;
  final RouteLocation? destination;
  final List<RoadRoute> routes;
  final RoadRoute? selectedRoute;

  @override
  State<RoadRouteMap> createState() => _RoadRouteMapState();
}

class _RoadRouteMapState extends State<RoadRouteMap> {
  static const String _applicationId = 'com.example.rumboapp';

  final MapController _mapController = MapController();

  bool _mapReady = false;

  @override
  void didUpdateWidget(covariant RoadRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSignature = _cameraSignature(
      oldWidget.origin,
      oldWidget.destination,
      oldWidget.routes,
      oldWidget.selectedRoute,
    );

    final newSignature = _cameraSignature(
      widget.origin,
      widget.destination,
      widget.routes,
      widget.selectedRoute,
    );

    if (oldSignature != newSignature) {
      _scheduleCameraFit();
    }
  }

  String _cameraSignature(
    RouteLocation? origin,
    RouteLocation? destination,
    List<RoadRoute> routes,
    RoadRoute? selectedRoute,
  ) {
    return [
      origin?.hereId ?? '',
      destination?.hereId ?? '',
      selectedRoute?.id ?? '',
      routes.map((route) => route.id).join('|'),
    ].join('::');
  }

  LatLng _toLatLng(RouteCoordinate coordinate) {
    return LatLng(coordinate.latitude, coordinate.longitude);
  }

  void _onMapReady() {
    _mapReady = true;
    _fitCamera();
  }

  void _scheduleCameraFit() {
    if (!_mapReady) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapReady) {
        _fitCamera();
      }
    });
  }

  List<LatLng> _visibleCoordinates() {
    final points = <LatLng>[];

    for (final route in widget.routes) {
      points.addAll(route.geometry.map(_toLatLng));
    }

    if (widget.origin != null) {
      points.add(_toLatLng(widget.origin!.coordinate));
    }

    if (widget.destination != null) {
      points.add(_toLatLng(widget.destination!.coordinate));
    }

    return points;
  }

  void _fitCamera() {
    final points = _visibleCoordinates();

    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
        maxZoom: 15,
      ),
    );
  }

  List<Polyline> _buildPolylines(ColorScheme colorScheme) {
    final polylines = <Polyline>[];

    for (final route in widget.routes) {
      final points = route.geometry.map(_toLatLng).toList();

      if (points.length < 2) {
        continue;
      }

      final selected = route.id == widget.selectedRoute?.id;

      polylines.add(
        Polyline(
          points: points,
          strokeWidth: selected ? 6 : 3,
          color: selected
              ? colorScheme.primary
              : colorScheme.tertiary.withValues(alpha: 0.72),
          borderStrokeWidth: selected ? 2 : 1,
          borderColor: colorScheme.surface,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  List<Marker> _buildMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];

    final origin = widget.origin;

    if (origin != null) {
      markers.add(
        Marker(
          point: _toLatLng(origin.coordinate),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: _MapMarker(
            color: colorScheme.primary,
            icon: Icons.trip_origin_rounded,
          ),
        ),
      );
    }

    final destination = widget.destination;

    if (destination != null) {
      markers.add(
        Marker(
          point: _toLatLng(destination.coordinate),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: _MapMarker(
            color: colorScheme.tertiary,
            icon: Icons.location_on_rounded,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final centerCoordinate =
        widget.origin?.coordinate ??
        widget.destination?.coordinate ??
        const RouteCoordinate(latitude: 23.6345, longitude: -102.5528);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 370,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _toLatLng(centerCoordinate),
                initialZoom: 5.5,
                minZoom: 2,
                maxZoom: 19,
                backgroundColor: colorScheme.surfaceContainerHighest,
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: _applicationId,
                  maxZoom: 19,
                ),
                if (widget.routes.isNotEmpty)
                  PolylineLayer(polylines: _buildPolylines(colorScheme)),
                if (widget.origin != null || widget.destination != null)
                  MarkerLayer(markers: _buildMarkers(colorScheme)),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
