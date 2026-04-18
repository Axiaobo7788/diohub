import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Overlay shown when the last token contains ':' (e.g. "is:" or "assignee:").
/// Suggests completions by [PickerType]; onSelect completes the token and triggers parse.
class QualifierSuggestionOverlay extends StatelessWidget {
  const QualifierSuggestionOverlay({
    required this.partialToken,
    required this.parser,
    required this.onSelect,
    super.key,
  });

  final String partialToken;
  final QualifierValueParser? parser;
  final void Function(String completedToken) onSelect;

  @override
  Widget build(BuildContext context) {
    if (parser == null) return const SizedBox.shrink();

    switch (parser!.pickerType) {
      case PickerType.options:
        return _OptionSuggestionList(
          partialToken: partialToken,
          options: parser!.staticOptions ?? [],
          onSelect: onSelect,
        );
      case PickerType.userSearch:
      case PickerType.text:
      case PickerType.label:
      case PickerType.milestone:
      case PickerType.branch:
        return _TextSuggestion(
          partialToken: partialToken,
          hint: parser!.pickerType == PickerType.userSearch
              ? 'Type username...'
              : 'Type value...',
          onSelect: onSelect,
        );
      case PickerType.numericRange:
        return _NumericRangeHelper(
          partialToken: partialToken,
          onSelect: onSelect,
        );
      case PickerType.dateRange:
        return _DateRangeHelper(
          partialToken: partialToken,
          onSelect: onSelect,
        );
      case PickerType.bool_:
        return _OptionSuggestionList(
          partialToken: partialToken,
          options: const ['true', 'false'],
          onSelect: onSelect,
        );
    }
  }
}

class _OptionSuggestionList extends StatelessWidget {
  const _OptionSuggestionList({
    required this.partialToken,
    required this.options,
    required this.onSelect,
  });

  final String partialToken;
  final List<String> options;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final key = partialToken.contains(':')
        ? partialToken.substring(0, partialToken.indexOf(':')).toLowerCase()
        : '';
    final filtered = options
        .where((o) => o.toLowerCase().startsWith(
            partialToken.length > key.length + 1
                ? partialToken.substring(key.length + 1).toLowerCase()
                : ''))
        .toList();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemExtent: 56,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final value = filtered[index];
            final completed = '$key:$value';
            return ListTile(
              title: Text(completed),
              onTap: () => onSelect(completed),
            );
          },
        ),
      ),
    );
  }
}

class _TextSuggestion extends StatelessWidget {
  const _TextSuggestion({
    required this.partialToken,
    required this.hint,
    required this.onSelect,
  });

  final String partialToken;
  final String hint;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: Text(
        hint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _NumericRangeHelper extends StatelessWidget {
  const _NumericRangeHelper({
    required this.partialToken,
    required this.onSelect,
  });

  final String partialToken;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    const examples = ['>10', '<100', '10..50'];
    final key = partialToken.contains(':')
        ? partialToken.substring(0, partialToken.indexOf(':')).toLowerCase()
        : '';
    return Padding(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: Wrap(
        spacing: 8,
        children: examples.map((ex) {
          final completed = '$key:$ex';
          return ActionChip(
            label: Text(completed),
            onPressed: () => onSelect(completed),
          );
        }).toList(),
      ),
    );
  }
}

class _DateRangeHelper extends StatelessWidget {
  const _DateRangeHelper({
    required this.partialToken,
    required this.onSelect,
  });

  final String partialToken;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    const examples = ['>=2024-01-01', '<2024-12-31', '2024-01-01..2024-06-01'];
    final key = partialToken.contains(':')
        ? partialToken.substring(0, partialToken.indexOf(':')).toLowerCase()
        : '';
    return Padding(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: Wrap(
        spacing: 8,
        children: examples.map((ex) {
          final completed = '$key:$ex';
          return ActionChip(
            label: Text(completed),
            onPressed: () => onSelect(completed),
          );
        }).toList(),
      ),
    );
  }
}
