import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/road_routes/domain/here_flexible_polyline.dart';

void main() {
  group('HereFlexiblePolyline', () {
    const mexicoRoute = 'BF8io9DpnqnTk0DqoWylK-r7B';

    const hereTwoDimensionalRoute =
        'BGwynmkDu39wZvBtF3InfvHrdvHvboGzF0FnGoGvHsOvR8L3NkSvWoGvHsEzFgFvHkD3IwHrJwHrJgKjN4D_E0ezoBjInV3N_iBzJ_Z';

    const hereThreeDimensionalRoute =
        'BlD05xgKuy2xCCx9B7vUCl0OhnRC54EqSCzpEl-HCxjD3pBCiGnyGCi2CvwFCsgD3nDC4vB6eC';

    test('decodifica coordenadas de una ruta en México', () {
      final coordinates = HereFlexiblePolyline.decode(mexicoRoute);

      expect(coordinates, hasLength(3));

      expect(coordinates.first.latitude, closeTo(20.52142, 0.000001));
      expect(coordinates.first.longitude, closeTo(-100.81397, 0.000001));

      expect(coordinates.last.latitude, closeTo(20.59209, 0.000001));
      expect(coordinates.last.longitude, closeTo(-100.39601, 0.000001));
    });

    test('decodifica una geometría 2D de HERE', () {
      final coordinates = HereFlexiblePolyline.decode(hereTwoDimensionalRoute);

      expect(coordinates, hasLength(23));

      expect(coordinates.first.latitude, closeTo(52.530984, 0.000001));
      expect(coordinates.first.longitude, closeTo(13.384567, 0.000001));

      expect(coordinates.last.latitude, closeTo(52.532326, 0.000001));
      expect(coordinates.last.longitude, closeTo(13.378874, 0.000001));
    });

    test('decodifica una geometría 3D de HERE', () {
      final coordinates = HereFlexiblePolyline.decode(
        hereThreeDimensionalRoute,
      );

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

    test('identifica las coordenadas que están fuera de rango', () {
      const invalidRoute = 'BFgutrR_nriT';

      expect(
        () => HereFlexiblePolyline.decode(invalidRoute),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Latitud: 91.0000000'),
          ),
        ),
      );
    });
  });
}
