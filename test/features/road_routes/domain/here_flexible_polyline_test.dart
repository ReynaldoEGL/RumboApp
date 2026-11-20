import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/here_flexible_polyline.dart';

void main() {
  group('HereFlexiblePolyline', () {
    const encoded =
        'BlD05xgKuy2xCCx9B7vUCl0OhnRC54EqSCzpEl-HCxjD3pBCiGnyGCi2CvwFCsgD3nDC4vB6eC';

    test('decodifica la geometría de HERE', () {
      final coordinates = HereFlexiblePolyline.decode(encoded);

      expect(coordinates, hasLength(10));

      expect(coordinates.first.latitude, closeTo(52.51994, 0.00001));
      expect(coordinates.first.longitude, closeTo(13.38663, 0.00001));

      expect(coordinates.last.latitude, closeTo(52.41058, 0.00001));
      expect(coordinates.last.longitude, closeTo(13.07555, 0.00001));
    });

    test('rechaza una geometría vacía', () {
      expect(
        () => HereFlexiblePolyline.decode(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza una cabecera inválida', () {
      expect(
        () => HereFlexiblePolyline.decode('invalid'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
