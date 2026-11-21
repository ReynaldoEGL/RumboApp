import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/application/device_location_provider.dart';
import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/data/here_reverse_geocoding_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

void main() {
  group('DeviceLocationController', () {
    late _FakeDeviceLocationService deviceService;
    late _FakeReverseGeocodingService reverseService;
    late ProviderContainer container;

    setUp(() async {
      deviceService = _FakeDeviceLocationService(
        const RouteCoordinate(latitude: 20.5235, longitude: -100.8157),
      );
      reverseService = _FakeReverseGeocodingService(
        'Calle de prueba, Celaya, Guanajuato, México',
      );

      container = ProviderContainer(
        overrides: [
          deviceLocationServiceProvider.overrideWithValue(deviceService),
          hereReverseGeocodingServiceProvider.overrideWithValue(reverseService),
        ],
      );

      container.listen(deviceLocationControllerProvider, (previous, next) {});
      await container.read(deviceLocationControllerProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'conserva las coordenadas GPS y muestra la dirección estimada',
      () async {
        final location = await container
            .read(deviceLocationControllerProvider.notifier)
            .getCurrentLocation();

        expect(location.title, 'Mi ubicación actual');
        expect(location.resultType, 'deviceLocation');
        expect(location.coordinate.latitude, 20.5235);
        expect(location.coordinate.longitude, -100.8157);
        expect(location.hereId, contains('device:'));
        expect(
          location.addressLabel,
          'Calle de prueba, Celaya, Guanajuato, México',
        );
        expect(
          reverseService.receivedCoordinate,
          same(deviceService.coordinate),
        );
        expect(
          container.read(deviceLocationControllerProvider).asData?.value,
          same(location),
        );
      },
    );

    test(
      'usa las coordenadas cuando HERE no encuentra una dirección',
      () async {
        reverseService.label = null;

        final location = await container
            .read(deviceLocationControllerProvider.notifier)
            .getCurrentLocation();

        expect(location.addressLabel, contains('Coordenadas GPS:'));
        expect(location.coordinate.latitude, 20.5235);
        expect(
          container.read(deviceLocationControllerProvider).hasValue,
          isTrue,
        );
      },
    );

    test('mantiene el GPS cuando el servicio HERE falla', () async {
      reverseService.error = StateError('HERE no disponible');

      final location = await container
          .read(deviceLocationControllerProvider.notifier)
          .getCurrentLocation();

      expect(location.addressLabel, contains('Coordenadas GPS:'));
      expect(location.coordinate.longitude, -100.8157);
      expect(container.read(deviceLocationControllerProvider).hasValue, isTrue);
    });

    test('propaga los errores de obtención del GPS', () async {
      deviceService.error = const DeviceLocationException(
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

class _FakeReverseGeocodingService implements ReverseGeocodingService {
  _FakeReverseGeocodingService(this.label);

  String? label;
  Object? error;
  RouteCoordinate? receivedCoordinate;

  @override
  Future<String?> reverseGeocode(RouteCoordinate coordinate) async {
    receivedCoordinate = coordinate;
    if (error != null) {
      throw error!;
    }
    return label;
  }
}
