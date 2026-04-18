import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/wrappers/loading_wrapper.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/common/compose/toolbar/compose_toolbar_overlay.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared scaffold for all compose flows. Zero conditionals — behavior from [config] and builder slots.
class ComposeScaffold extends ConsumerStatefulWidget {
  const ComposeScaffold({
    required this.config,
    required this.bodyBuilder,
    this.metadataBuilder,
    this.headerBuilder,
    super.key,
  });

  final ComposeConfig config;
  final Widget Function(
    BuildContext context,
    TextEditingController titleController,
    TextEditingController bodyController,
    FocusNode bodyFocusNode,
  ) bodyBuilder;
  final Widget Function(BuildContext context)? metadataBuilder;
  final Widget Function(BuildContext context)? headerBuilder;

  @override
  ConsumerState<ComposeScaffold> createState() => _ComposeScaffoldState();
}

class _ComposeScaffoldState extends ConsumerState<ComposeScaffold> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final FocusNode _bodyFocusNode;
  bool _draftApplied = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.config.initialTitle ?? '');
    _bodyController =
        TextEditingController(text: widget.config.initialBody ?? '');
    _bodyFocusNode = FocusNode();
    _bodyController.addListener(_onBodyChanged);
  }

  void _onBodyChanged() {
    final config = widget.config;
    if (!config.hasDraft) return;
    final key = DraftKey.fromConfig(config);
    if (key == null) return;
    ref
        .read(composeDraftProvider(key).notifier)
        .updateBody(_bodyController.text);
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final draftKey = DraftKey.fromConfig(config);
    if (draftKey != null) {
      ref.watch(composeDraftProvider(draftKey)); // keep provider alive
      ref.listen(composeDraftProvider(draftKey), (prev, next) {
        next.whenData((body) {
          if (!_draftApplied &&
              body.isNotEmpty &&
              _bodyController.text.isEmpty &&
              mounted) {
            _draftApplied = true;
            _bodyController.text = body;
          }
        });
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(config.title),
            if (config.subtitle != null)
              Text(
                config.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        actions: <Widget>[
          Tooltip(
            message: config.submitLabel,
            child: SubmitButton(
              variant: SubmitButtonVariant.text,
              icon: Icon(config.submitIcon),
              onSubmit: () async {
              await ref.read(hapticServiceProvider).mediumImpact();
              final title = _titleController.text;
              final body = _bodyController.text;
              if (config.titleValidator != null) {
                final error = config.titleValidator!(title);
                if (error != null) {
                  ref.read(notificationServiceProvider).error(error);
                  return;
                }
              }
              await config.onSubmit(title, body);
              final key = DraftKey.fromConfig(config);
              if (key != null) {
                await ref.read(composeDraftProvider(key).notifier).clear();
              }
              if (mounted) Navigator.maybeOf(context)?.pop();
            },
            label: (_) => const SizedBox.shrink(),
            onError: (e) {
              AppLogger.warning(
                'Compose scaffold submit failed',
                error: e,
                tag: 'ComposeScaffold',
              );
              ref.read(notificationServiceProvider).error('Something went wrong');
            },
          ),
          ),
        ],
      ),
      body: LoadingWrapper(
        status: PageStatus.loaded,
        loadingBuilder: (BuildContext context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const LoadingIndicator(),
              context.spacing.sectionGap,
              Text(config.loadingVerb),
            ],
          ),
        ),
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.metadataBuilder != null)
                widget.metadataBuilder!(context),
              if (widget.headerBuilder != null) widget.headerBuilder!(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: context.spacing.screenPadding,
                  child: widget.bodyBuilder(
                    context,
                    _titleController,
                    _bodyController,
                    _bodyFocusNode,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: ComposeToolbarOverlay(
        controller: _bodyController,
        focusNode: _bodyFocusNode,
        config: config,
        titleController: _titleController,
      ),
    );
  }
}
