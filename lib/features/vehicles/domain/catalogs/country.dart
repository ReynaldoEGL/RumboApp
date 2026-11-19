import 'catalog_parsing.dart';

class Country {
  const Country({
    required this.code,
    required this.name,
    this.alpha3,
    this.aliases = const [],
  });

  final String code;
  final String name;
  final String? alpha3;
  final List<String> aliases;

  factory Country.fromMap(Map<String, Object?> data) {
    final code = readRequiredString(data, 'code').toUpperCase();

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
      throw FormatException(
        'El código ISO alpha-2 del país "$code" no es válido.',
      );
    }

    final alpha3 = readOptionalString(data, 'alpha3')?.toUpperCase();

    if (alpha3 != null && !RegExp(r'^[A-Z]{3}$').hasMatch(alpha3)) {
      throw FormatException(
        'El código ISO alpha-3 del país "$code" no es válido.',
      );
    }

    return Country(
      code: code,
      name: readRequiredString(data, 'name'),
      alpha3: alpha3,
      aliases: readStringList(data, 'aliases'),
    );
  }
}
