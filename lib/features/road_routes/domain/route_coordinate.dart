class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  factory RouteCoordinate.fromHereMap(Map<Object?, Object?> data) {
    final latitude = _readNumber(data['lat']);
    final longitude = _readNumber(data['lng']);

    final coordinate = RouteCoordinate(
      latitude: latitude,
      longitude: longitude,
    );

    if (!coordinate.isValid) {
      throw const FormatException('La coordenada no es válida.');
    }

    return coordinate;
  }

  factory RouteCoordinate.fromMap(Map<Object?, Object?> data) {
    final coordinate = RouteCoordinate(
      latitude: _readNumber(data['latitude']),
      longitude: _readNumber(data['longitude']),
    );

    if (!coordinate.isValid) {
      throw const FormatException('La coordenada almacenada no es válida.');
    }

    return coordinate;
  }

  Map<String, dynamic> toMap() {
    if (!isValid) {
      throw const FormatException(
        'No se puede guardar una coordenada inválida.',
      );
    }

    return {'latitude': latitude, 'longitude': longitude};
  }

  static double _readNumber(Object? value) {
    if (value is! num) {
      throw const FormatException('El valor de la coordenada no es numérico.');
    }

    final result = value.toDouble();

    if (!result.isFinite) {
      throw const FormatException('El valor de la coordenada no es válido.');
    }

    return result;
  }
}
