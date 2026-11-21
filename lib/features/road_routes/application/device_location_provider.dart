import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/data/here_reverse_geocoding_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return GeolocatorDeviceLocationService();
});

final hereReverseGeocodingServiceProvider = Provider<ReverseGeocodingService>((
  ref,
) {
  const apiKey = String.fromEnvironment('HERE_API_KEY');
  final service = HereReverseGeocodingService(apiKey: apiKey);
  ref.onDispose(service.close);
  return service;
});

final deviceLocationControllerProvider =
    AsyncNotifierProvider<DeviceLocationController, RouteLocation?>(
      DeviceLocationController.new,
    );

class DeviceLocationController extends AsyncNotifier<RouteLocation?> {
  Future<RouteLocation>? _activeRequest;

  @override
  RouteLocation? build() => null;

  Future<RouteLocation> getCurrentLocation() {
    final activeRequest = _activeRequest;
    if (activeRequest != null) {
      return activeRequest;
    }

    final request = _getCurrentLocation();
    _activeRequest = request;
    return request;
  }

  Future<RouteLocation> _getCurrentLocation() async {
    final deviceService = ref.read(deviceLocationServiceProvider);
    final reverseService = ref.read(hereReverseGeocodingServiceProvider);

    state = const AsyncLoading<RouteLocation?>();

    try {
      final coordinate = await deviceService.getCurrentCoordinate();

      if (!coordinate.isValid) {
        throw const DeviceLocationException(
          'El dispositivo devolvió coordenadas no válidas.',
        );
      }

      String? resolvedAddress;

      try {
        resolvedAddress = await reverseService.reverseGeocode(coordinate);
      } catch (_) {
        developer.log(
          'No se obtuvo la dirección; se conservarán las coordenadas GPS.',
          name: 'rumbo.device_location',
        );
      }

      final location = RouteLocation(
        hereId:
            'device:${coordinate.latitude.toStringAsFixed(7)}:'
            '${coordinate.longitude.toStringAsFixed(7)}',
        title: 'Mi ubicación actual',
        addressLabel: resolvedAddress ?? _fallbackAddress(coordinate),
        coordinate: coordinate,
        resultType: 'deviceLocation',
      );

      if (ref.mounted) {
        state = AsyncData<RouteLocation?>(location);
      }

      return location;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<RouteLocation?>(error, stackTrace);
      }
      rethrow;
    } finally {
      _activeRequest = null;
    }
  }

  String _fallbackAddress(RouteCoordinate coordinate) {
    return 'Coordenadas GPS: '
        '${coordinate.latitude.toStringAsFixed(6)}, '
        '${coordinate.longitude.toStringAsFixed(6)}';
  }
}
