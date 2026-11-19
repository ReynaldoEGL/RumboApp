String readRequiredString(Map<String, Object?> data, String key) {
  final value = data[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'El campo "$key" es obligatorio y debe contener texto.',
    );
  }

  return value.trim();
}

/// Lee una cadena opcional.
///
/// Si no existe o está vacía, devuelve null.
String? readOptionalString(Map<String, Object?> data, String key) {
  final value = data[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('El campo opcional "$key" debe contener texto.');
  }

  final normalized = value.trim();

  return normalized.isEmpty ? null : normalized;
}

/// Lee una lista de cadenas.
///
/// Si el campo no existe y no es obligatorio, devuelve una lista vacía.
/// No permite elementos vacíos ni valores repetidos.
List<String> readStringList(
  Map<String, Object?> data,
  String key, {
  bool required = false,
}) {
  final value = data[key];

  if (value == null && !required) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('El campo "$key" debe ser una lista.');
  }

  final result = <String>[];
  final seen = <String>{};

  for (final item in value) {
    if (item is! String || item.trim().isEmpty) {
      throw FormatException('La lista "$key" contiene un elemento inválido.');
    }

    final normalized = item.trim();

    if (!seen.add(normalized)) {
      throw FormatException(
        'La lista "$key" contiene el valor duplicado "$normalized".',
      );
    }

    result.add(normalized);
  }

  if (required && result.isEmpty) {
    throw FormatException('La lista "$key" no puede estar vacía.');
  }

  return List.unmodifiable(result);
}

/// Lee un entero opcional.
int? readOptionalInt(Map<String, Object?> data, String key) {
  final value = data[key];

  if (value == null) {
    return null;
  }

  if (value is! int) {
    throw FormatException('El campo "$key" debe ser un número entero.');
  }

  return value;
}

/// Comprueba que un identificador de catálogo tenga formato slug.
///
/// Ejemplos válidos:
///   toyota
///   mercedes-benz
///   toyota-corolla
///
/// Ejemplos inválidos:
///   Toyota
///   Toyota Corolla
///   toyota_corolla
void validateCatalogSlug(String value, {required String fieldName}) {
  final valid = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value);

  if (!valid) {
    throw FormatException(
      'El identificador "$fieldName" tiene un formato inválido: $value',
    );
  }
}
