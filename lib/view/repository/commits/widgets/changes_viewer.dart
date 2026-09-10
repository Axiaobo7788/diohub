import 'package:auto_route/annotations.dart';
import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/code/diff_file_view.dart';
import 'package:diohub/common/diff/diff_config.dart';
import 'package:diohub/common/diff/diff_view.dart' show WrapIconButton;
import 'package:diohub/common/diff/parser.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class ChangesViewer extends ConsumerStatefulWidget {
  const ChangesViewer(this.patch, this.contentURL, this.fileType, {super.key});
  final String? patch;
  final String? contentURL;
  final String? fileType;

  @override
  ConsumerState<ChangesViewer> createState() => _ChangesViewerState();
}

class _ChangesViewerState extends ConsumerState<ChangesViewer> {
  /// Null = use settings; non-null = user override for this screen.
  bool? wrapOverride;
  late ParsedDiff _parsedDiff;

  @override
  void initState() {
    super.initState();
    _parsedDiff = parseUnifiedDiffCached(widget.patch);
  }

  @override
  void didUpdateWidget(covariant final ChangesViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patch != widget.patch) {
      _parsedDiff = parseUnifiedDiffCached(widget.patch);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final DiffSettings diffSettings = ref.watch(diffSettingsProvider);
    final bool effectiveWrap = wrapOverride ?? diffSettings.wrapLines;
    final DiffViewConfig config = DiffViewConfig.fromSettings(
      diffSettings,
    ).copyWith(wrap: effectiveWrap);
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          WrapIconButton(
            wrap: effectiveWrap,
            onWrap: (final bool value) {
              setState(() {
                wrapOverride = value;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: widget.patch != null && widget.patch!.isNotEmpty
                ? () async {
                    await ref
                        .read(clipboardServiceProvider)
                        .copy(widget.patch!);
                  }
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: context.spacing.pagePadding,
          child: DiffFileView(
            parsedDiff: _parsedDiff,
            config: config,
            fileType: widget.fileType,
            mode: diffSettings.defaultDiffDisplayMode,
          ),
        ),
      ),
    );
  }
}
