import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/application/device_location_provider.dart';
import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

void main() {
  group('DeviceLocationController', () {
    late _FakeDeviceLocationService service;
    late ProviderContainer container;

    setUp(() async {
      service = _FakeDeviceLocationService(
        const RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
      );

      container = ProviderContainer(
        overrides: [deviceLocationServiceProvider.overrideWithValue(service)],
      );

      container.listen(deviceLocationControllerProvider, (previous, next) {});

      await container.read(deviceLocationControllerProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('convierte las coordenadas en una ubicación de Rumbo', () async {
      final location = await container
          .read(deviceLocationControllerProvider.notifier)
          .getCurrentLocation();

      expect(location.title, 'Mi ubicación actual');
      expect(location.resultType, 'deviceLocation');
      expect(location.coordinate.latitude, 20.5235);
      expect(location.coordinate.longitude, -100.8157);
      expect(location.hereId, contains('device:'));

      expect(container.read(deviceLocationControllerProvider).hasValue, isTrue);
    });

    test('propaga el error del servicio sin ocultarlo', () async {
      service.error = const DeviceLocationException(
        'No se concedió permiso de ubicación.',
      );

      final controller = container.read(
        deviceLocationControllerProvider.notifier,
      );

      await expectLater(
        controller.getCurrentLocation(),
        throwsA(isA<DeviceLocationException>()),
      );

      expect(container.read(deviceLocationControllerProvider).hasError, isTrue);
    });
  });
}

class _FakeDeviceLocationService implements DeviceLocationService {
  _FakeDeviceLocationService(this.coordinate);

  final RouteCoordinate coordinate;

  Object? error;

  @override
  Future<RouteCoordinate> getCurrentCoordinate() async {
    if (error != null) {
      throw error!;
    }

    return coordinate;
  }
}
