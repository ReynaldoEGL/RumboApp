import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rumboapp/features/vehicles/data/sources/local_vehicle_catalog_source.dart';

void main() {
  group('AssetVehicleCatalogSource', () {
    test('lee correctamente un catálogo válido', () async {
      final bundle = _MemoryAssetBundle({
        'catalog.json': jsonEncode({
          'schemaVersion': 1,
          'catalogId': 'test_catalog',
          'items': [
            {'id': 'toyota', 'name': 'Toyota'},
          ],
        }),
      });

      final source = AssetVehicleCatalogSource(bundle: bundle);

      final items = await source.loadItems('catalog.json');

      expect(items, hasLength(1));
      expect(items.single['id'], 'toyota');
      expect(items.single['name'], 'Toyota');
    });

    test('rechaza una versión de esquema incompatible', () async {
      final bundle = _MemoryAssetBundle({
        'catalog.json': jsonEncode({
          'schemaVersion': 99,
          'catalogId': 'test_catalog',
          'items': [],
        }),
      });

      final source = AssetVehicleCatalogSource(bundle: bundle);

      await expectLater(
        source.loadItems('catalog.json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza un catálogo sin la colección items', () async {
      final bundle = _MemoryAssetBundle({
        'catalog.json': jsonEncode({
          'schemaVersion': 1,
          'catalogId': 'test_catalog',
        }),
      });

      final source = AssetVehicleCatalogSource(bundle: bundle);

      await expectLater(
        source.loadItems('catalog.json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza elementos que no son objetos JSON', () async {
      final bundle = _MemoryAssetBundle({
        'catalog.json': jsonEncode({
          'schemaVersion': 1,
          'catalogId': 'test_catalog',
          'items': ['Toyota', 123],
        }),
      });

      final source = AssetVehicleCatalogSource(bundle: bundle);

      await expectLater(
        source.loadItems('catalog.json'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

/// AssetBundle de prueba que entrega texto desde memoria.
///
/// Así probamos el lector JSON sin crear archivos temporales ni depender
/// de recursos incluidos en el bundle real de Flutter.
class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.contents);

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final content = contents[key];

    if (content == null) {
      throw FlutterError('No existe el asset simulado "$key".');
    }

    final bytes = Uint8List.fromList(utf8.encode(content));

    return ByteData.sublistView(bytes);
  }
}
