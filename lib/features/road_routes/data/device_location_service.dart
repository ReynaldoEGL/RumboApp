import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class DeviceLocationService {
  Future<RouteCoordinate> getCurrentCoordinate();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  static const Duration _locationTimeout = Duration(seconds: 25);

  @override
  Future<RouteCoordinate> getCurrentCoordinate() async {
    try {
      if (kIsWeb) {
        _validateBrowserContext();
      } else {
        await _checkNativePermissions();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(_locationTimeout);

      final coordinate = RouteCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!coordinate.isValid) {
        throw const DeviceLocationException(
          'El dispositivo devolvió una ubicación que no es válida.',
        );
      }

      return coordinate;
    } on DeviceLocationException {
      rethrow;
    } on TimeoutException {
      throw const DeviceLocationException(
        'No pudimos obtener tu ubicación a tiempo. Comprueba la señal GPS e inténtalo nuevamente.',
      );
    } on LocationServiceDisabledException {
      throw const DeviceLocationException(
        'Los servicios de ubicación están desactivados. Actívalos e inténtalo nuevamente.',
      );
    } on PermissionDeniedException {
      throw const DeviceLocationException(
        'No se concedió permiso para acceder a tu ubicación.',
      );
    } catch (error, stackTrace) {
      developer.log(
        'No fue posible obtener la ubicación actual del dispositivo.',
        name: 'rumbo.device_location',
        error: error,
        stackTrace: stackTrace,
      );

      throw const DeviceLocationException(
        'No fue posible obtener tu ubicación actual. Comprueba los permisos e inténtalo nuevamente.',
      );
    }
  }

  Future<void> _checkNativePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const DeviceLocationException(
        'Los servicios de ubicación están desactivados. Actívalos e inténtalo nuevamente.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'El permiso de ubicación está desactivado para Rumbo. Habilítalo desde la configuración del dispositivo.',
      );
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const DeviceLocationException(
        'Necesitamos permiso para acceder a tu ubicación. Puedes concederlo desde los ajustes del dispositivo.',
      );
    }
  }

  void _validateBrowserContext() {
    final uri = Uri.base;

    final isLocalhost =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';

    if (uri.scheme != 'https' && !isLocalhost) {
      throw const DeviceLocationException(
        'Para obtener la ubicación en el navegador, Rumbo necesita ejecutarse mediante HTTPS o desde localhost.',
      );
    }
  }
}
