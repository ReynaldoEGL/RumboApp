import 'catalog_parsing.dart';

class Region {
  const Region({
    required this.code,
    required this.countryCode,
    required this.name,
    this.aliases = const [],
  });

  /// Identificador ISO 3166-2 cuando se encuentra disponible.
  final String code;

  /// País al que pertenece la subdivisión, ISO alpha-2.
  final String countryCode;

  final String name;

  final List<String> aliases;

  factory Region.fromMap(Map<String, Object?> data) {
    final code = readRequiredString(data, 'code').toUpperCase();
    final countryCode = readRequiredString(data, 'countryCode').toUpperCase();

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      throw FormatException(
        'El país de la región "$code" no tiene un código válido.',
      );
    }

    if (!RegExp(r'^[A-Z]{2}-[A-Z0-9]{1,3}$').hasMatch(code)) {
      throw FormatException(
        'El código de región "$code" no tiene un formato ISO válido.',
      );
    }

    if (!code.startsWith('$countryCode-')) {
      throw FormatException(
        'El código "$code" no corresponde al país "$countryCode".',
      );
    }

    return Region(
      code: code,
      countryCode: countryCode,
      name: readRequiredString(data, 'name'),
      aliases: readStringList(data, 'aliases'),
    );
  }
}
