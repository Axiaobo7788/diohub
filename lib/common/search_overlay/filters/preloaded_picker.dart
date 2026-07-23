import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filters/dynamic_chip_row.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class PreloadedPicker extends StatefulWidget {
  const PreloadedPicker({
    required this.section,
    required this.scope,
    required this.state,
    required this.notifier,
    super.key,
  });

  final PreloadedFilterSection section;
  final SearchScope scope;
  final SearchState state;
  final SearchStateNotifier notifier;

  @override
  State<PreloadedPicker> createState() => _PreloadedPickerState();
}

class _PreloadedPickerState extends State<PreloadedPicker> {
  List<FilterOption>? _options;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.section.load == null) return;
    setState(() {
      _options = null;
      _error = null;
    });
    try {
      final options = await widget.section.load!();
      if (mounted) setState(() => _options = options);
    } catch (e, st) {
      AppLogger.warning(
        'Filter options load failed',
        error: e,
        stackTrace: st,
        tag: 'Search',
      );
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        context.l10n.filterOptionsLoadError,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.error,
        ),
      );
    }
    if (_options == null) {
      return SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colorScheme.primary,
            ),
          ),
        ),
      );
    }
    if (_options!.isEmpty) {
      return Text(
        context.l10n.filterNoOptions,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return DynamicChipRow(
      scope: widget.scope,
      section: widget.section,
      state: widget.state,
      notifier: widget.notifier,
      options: _options!,
    );
  }
}
