import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return GeolocatorDeviceLocationService();
});

final deviceLocationControllerProvider =
    AsyncNotifierProvider<DeviceLocationController, void>(
      DeviceLocationController.new,
    );

class DeviceLocationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<RouteLocation> getCurrentLocation() async {
    state = const AsyncLoading<void>();

    try {
      final coordinate = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentCoordinate();

      final location = RouteLocation(
        hereId:
            'device:${coordinate.latitude.toStringAsFixed(7)}:'
            '${coordinate.longitude.toStringAsFixed(7)}',
        title: 'Mi ubicación actual',
        addressLabel: 'Coordenadas del dispositivo',
        coordinate: coordinate,
        resultType: 'deviceLocation',
      );

      state = const AsyncData<void>(null);

      return location;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);

      rethrow;
    }
  }
}
