import 'package:rumboapp/features/road_routes/domain/route_coordinate.dart';

class HereFlexiblePolyline {
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static List<RouteCoordinate> decode(String encoded) {
    if (encoded.isEmpty) {
      throw const FormatException('La geometría de la ruta está vacía.');
    }

    var index = 0;

    final versionResult = _decodeUnsigned(encoded, index);
    final version = versionResult.value;
    index = versionResult.nextIndex;

    if (version != 1) {
      throw FormatException(
        'La versión de Flexible Polyline no está soportada: $version.',
      );
    }

    final headerResult = _decodeUnsigned(encoded, index);
    final header = headerResult.value;
    index = headerResult.nextIndex;

    final precision = header & 0x0F;
    final thirdDimension = (header >> 4) & 0x07;

    final coordinateFactor = _powerOfTen(precision);

    final coordinates = <RouteCoordinate>[];

    var accumulatedLatitude = 0;
    var accumulatedLongitude = 0;

    while (index < encoded.length) {
      final latitudeResult = _decodeUnsigned(encoded, index);
      index = latitudeResult.nextIndex;

      final longitudeResult = _decodeUnsigned(encoded, index);
      index = longitudeResult.nextIndex;

      accumulatedLatitude += _decodeSigned(latitudeResult.value);
      accumulatedLongitude += _decodeSigned(longitudeResult.value);

      if (thirdDimension != 0) {
        final thirdDimensionResult = _decodeUnsigned(encoded, index);
        index = thirdDimensionResult.nextIndex;

        _decodeSigned(thirdDimensionResult.value);
      }

      final coordinate = RouteCoordinate(
        latitude: accumulatedLatitude / coordinateFactor,
        longitude: accumulatedLongitude / coordinateFactor,
      );

      if (!coordinate.isValid) {
        throw const FormatException(
          'La geometría contiene coordenadas fuera de rango.',
        );
      }

      coordinates.add(coordinate);
    }

    if (coordinates.isEmpty) {
      throw const FormatException('La geometría no contiene coordenadas.');
    }

    return List.unmodifiable(coordinates);
  }

  static _DecodedValue _decodeUnsigned(String encoded, int startIndex) {
    var index = startIndex;
    var shift = 0;
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

      value |= (chunk & 0x1F) << shift;

      index++;

      if ((chunk & 0x20) == 0) {
        break;
      }

      shift += 5;

      if (shift > 60) {
        throw const FormatException(
          'La geometría contiene un valor demasiado grande.',
        );
      }
    }

    return _DecodedValue(value, index);
  }

  static int _decodeSigned(int value) {
    if ((value & 1) == 1) {
      return ~(value >> 1);
    }

    return value >> 1;
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
