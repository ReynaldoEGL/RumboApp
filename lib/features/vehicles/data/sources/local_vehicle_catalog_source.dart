import 'dart:convert';

import 'package:flutter/services.dart';

abstract interface class VehicleCatalogSource {
  Future<List<Map<String, Object?>>> loadItems(String assetPath);
}

class AssetVehicleCatalogSource implements VehicleCatalogSource {
  AssetVehicleCatalogSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const int supportedSchemaVersion = 1;

  @override
  Future<List<Map<String, Object?>>> loadItems(String assetPath) async {
    late final String content;

    try {
      content = await _bundle.loadString(assetPath);
    } catch (error) {
      throw FormatException(
        'No fue posible leer el catálogo local "$assetPath": $error',
      );
    }

    late final Object? decoded;

    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      throw FormatException(
        'El archivo "$assetPath" contiene JSON inválido: '
        '${error.message}',
      );
    }

    if (decoded is! Map) {
      throw FormatException('La raíz de "$assetPath" debe ser un objeto JSON.');
    }

    final schemaVersion = decoded['schemaVersion'];

    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'El catálogo "$assetPath" utiliza la versión '
        '"$schemaVersion", pero esta aplicación admite '
        'la versión $supportedSchemaVersion.',
      );
    }

    final catalogId = decoded['catalogId'];

    if (catalogId is! String || catalogId.trim().isEmpty) {
      throw FormatException(
        'El catálogo "$assetPath" no tiene un catalogId válido.',
      );
    }

    final rawItems = decoded['items'];

    if (rawItems is! List) {
      throw FormatException(
        'El campo "items" de "$assetPath" debe ser una lista.',
      );
    }

    final result = <Map<String, Object?>>[];

    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = rawItems[index];

      if (rawItem is! Map) {
        throw FormatException(
          'El elemento $index de "$assetPath" no es un objeto JSON.',
        );
      }

      final normalizedItem = <String, Object?>{};

      for (final entry in rawItem.entries) {
        if (entry.key is! String) {
          throw FormatException(
            'El elemento $index de "$assetPath" '
            'contiene una clave que no es texto.',
          );
        }

        normalizedItem[entry.key as String] = entry.value;
      }

      result.add(Map.unmodifiable(normalizedItem));
    }

    return List.unmodifiable(result);
  }
}
