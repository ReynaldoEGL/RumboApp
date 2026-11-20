import 'route_coordinate.dart';

class RouteLocation {
  const RouteLocation({
    required this.hereId,
    required this.title,
    required this.addressLabel,
    required this.coordinate,
    this.resultType,
  });

  final String hereId;
  final String title;
  final String addressLabel;
  final RouteCoordinate coordinate;
  final String? resultType;

  factory RouteLocation.fromHereMap(Map<Object?, Object?> data) {
    final hereId = _requiredString(data['id']);
    final title = _requiredString(data['title']);

    final position = _readMap(data['position']);
    final address = _optionalMap(data['address']);

    final label = _optionalString(address?['label']) ?? title;

    return RouteLocation(
      hereId: hereId,
      title: title,
      addressLabel: label,
      coordinate: RouteCoordinate.fromHereMap(position),
      resultType: _optionalString(data['resultType']),
    );
  }

  factory RouteLocation.fromMap(Map<Object?, Object?> data) {
    return RouteLocation(
      hereId: _requiredString(data['hereId']),
      title: _requiredString(data['title']),
      addressLabel: _requiredString(data['addressLabel']),
      coordinate: RouteCoordinate.fromMap(_readMap(data['coordinate'])),
      resultType: _optionalString(data['resultType']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hereId': hereId,
      'title': title,
      'addressLabel': addressLabel,
      'coordinate': coordinate.toMap(),
      if (resultType != null) 'resultType': resultType,
    };
  }
}

Map<Object?, Object?> _readMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('La ubicación recibida no es válida.');
  }

  return Map<Object?, Object?>.from(value);
}

Map<Object?, Object?>? _optionalMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return Map<Object?, Object?>.from(value);
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('La ubicación contiene un campo vacío.');
  }

  return value.trim();
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return value.trim();
}
