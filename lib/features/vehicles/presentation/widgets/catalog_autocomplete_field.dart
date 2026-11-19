import 'package:flutter/material.dart';

String normalizeCatalogSearchText(String value) {
  var result = value.trim().toLowerCase();

  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }

  return result;
}

class CatalogAutocompleteField<T extends Object> extends StatelessWidget {
  const CatalogAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.options,
    required this.displayStringForOption,
    required this.aliasesForOption,
    required this.onSelected,
    required this.onChanged,
    required this.validator,
    this.hint,
    this.helperText,
    this.loading = false,
    this.maxOptions = 10,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final String label;
  final String? hint;
  final String? helperText;

  final List<T> options;

  final String Function(T option) displayStringForOption;
  final Iterable<String> Function(T option) aliasesForOption;

  final ValueChanged<T> onSelected;
  final ValueChanged<String> onChanged;

  final String? Function(String?) validator;

  final bool loading;
  final int maxOptions;

  final TextCapitalization textCapitalization;

  Iterable<T> _filterOptions(TextEditingValue value) {
    final query = normalizeCatalogSearchText(value.text);

    if (query.isEmpty) {
      return options.take(maxOptions);
    }

    return options
        .where((option) {
          final searchValues = <String>[
            displayStringForOption(option),
            ...aliasesForOption(option),
          ];

          return searchValues.any(
            (value) => normalizeCatalogSearchText(value).contains(query),
          );
        })
        .take(maxOptions);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: displayStringForOption,
      optionsBuilder: _filterOptions,
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textController, fieldFocusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textController,
              focusNode: fieldFocusNode,
              validator: validator,
              onChanged: onChanged,
              textCapitalization: textCapitalization,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                onFieldSubmitted();
              },
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                helperText: helperText,
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                suffixIcon: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            );
          },
      optionsViewBuilder: (context, selectOption, availableOptions) {
        final items = availableOptions.toList(growable: false);

        final screenWidth = MediaQuery.sizeOf(context).width;
        final popupWidth = screenWidth < 600 ? screenWidth - 32 : 520.0;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: popupWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      color: colorScheme.outlineVariant,
                    );
                  },
                  itemBuilder: (context, index) {
                    final option = items[index];

                    return ListTile(
                      dense: true,
                      title: Text(displayStringForOption(option)),
                      onTap: () {
                        selectOption(option);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
