import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

class HereFlexiblePolyline {
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static const int _maxSafeInteger = 9007199254740991;

  static List<RouteCoordinate> decode(String encoded) {
    final normalized = encoded.trim();

    if (normalized.isEmpty) {
      throw const FormatException('La geometría de la ruta está vacía.');
    }

    var index = 0;

    final versionResult = _decodeUnsigned(normalized, index);
    final version = versionResult.value;
    index = versionResult.nextIndex;

    if (version != 1) {
      throw FormatException(
        'La versión de Flexible Polyline no está soportada: $version.',
      );
    }

    final headerResult = _decodeUnsigned(normalized, index);
    final header = headerResult.value;
    index = headerResult.nextIndex;

    final precision = header % 16;
    final thirdDimension = (header ~/ 16) % 8;
    final thirdDimensionPrecision = (header ~/ 128) % 16;

    final coordinateFactor = _powerOfTen(precision);
    final thirdDimensionFactor = _powerOfTen(thirdDimensionPrecision);

    var accumulatedLatitude = 0;
    var accumulatedLongitude = 0;

    final coordinates = <RouteCoordinate>[];

    var pointIndex = 0;

    while (index < normalized.length) {
      final latitudeResult = _decodeUnsigned(normalized, index);
      index = latitudeResult.nextIndex;

      final longitudeResult = _decodeUnsigned(normalized, index);
      index = longitudeResult.nextIndex;

      accumulatedLatitude = _addChecked(
        accumulatedLatitude,
        _decodeSigned(latitudeResult.value),
      );

      accumulatedLongitude = _addChecked(
        accumulatedLongitude,
        _decodeSigned(longitudeResult.value),
      );

      if (thirdDimension != 0) {
        final thirdDimensionResult = _decodeUnsigned(normalized, index);
        index = thirdDimensionResult.nextIndex;

        final thirdDimensionValue = _decodeSigned(thirdDimensionResult.value);

        final decodedThirdDimension =
            thirdDimensionValue / thirdDimensionFactor;

        if (!decodedThirdDimension.isFinite) {
          throw const FormatException(
            'La tercera dimensión de la geometría no es válida.',
          );
        }
      }

      final latitude = accumulatedLatitude / coordinateFactor;
      final longitude = accumulatedLongitude / coordinateFactor;

      final coordinate = RouteCoordinate(
        latitude: latitude,
        longitude: longitude,
      );

      if (!coordinate.isValid) {
        throw FormatException(
          'La geometría contiene coordenadas fuera de rango. '
          'Punto: $pointIndex. '
          'Latitud: ${latitude.toStringAsFixed(7)}. '
          'Longitud: ${longitude.toStringAsFixed(7)}. '
          'Precisión: $precision. '
          'Tercera dimensión: $thirdDimension.',
        );
      }

      coordinates.add(coordinate);
      pointIndex++;
    }

    if (coordinates.isEmpty) {
      throw const FormatException('La geometría no contiene coordenadas.');
    }

    return List.unmodifiable(coordinates);
  }

  static _DecodedValue _decodeUnsigned(String encoded, int startIndex) {
    var index = startIndex;
    var multiplier = 1;
    var value = 0;

    while (true) {
      if (index >= encoded.length) {
        throw const FormatException('La geometría está incompleta.');
      }

      final chunk = _alphabet.indexOf(encoded[index]);

      if (chunk < 0) {
        throw const FormatException(
          'La geometría contiene caracteres inválidos.',
        );
      }

      final payload = chunk % 32;
      final maximumPayload = (_maxSafeInteger - value) ~/ multiplier;

      if (payload > maximumPayload) {
        throw const FormatException(
          'La geometría contiene un valor numérico demasiado grande.',
        );
      }

      value += payload * multiplier;
      index++;

      if (chunk < 32) {
        return _DecodedValue(value, index);
      }

      if (multiplier > _maxSafeInteger ~/ 32) {
        throw const FormatException(
          'La geometría contiene un valor numérico demasiado grande.',
        );
      }

      multiplier *= 32;
    }
  }

  static int _decodeSigned(int value) {
    if (value.isOdd) {
      return -((value + 1) ~/ 2);
    }

    return value ~/ 2;
  }

  static int _addChecked(int current, int delta) {
    final result = current + delta;

    if (result.abs() > _maxSafeInteger) {
      throw const FormatException(
        'La geometría contiene un desplazamiento numérico demasiado grande.',
      );
    }

    return result;
  }

  static double _powerOfTen(int precision) {
    var result = 1.0;

    for (var i = 0; i < precision; i++) {
      result *= 10;
    }

    return result;
  }
}

class _DecodedValue {
  const _DecodedValue(this.value, this.nextIndex);

  final int value;
  final int nextIndex;
}
