part of 'bottom_sheets.dart';

// ─── Sealed config ─────────────────────────────────────────────────────────

sealed class _SheetConfig<T> {
  const _SheetConfig({this.enableDrag = true, this.constraints});
  final bool enableDrag;
  final BoxConstraints? constraints;
}

class _ActionsConfig<T> extends _SheetConfig<T> {
  const _ActionsConfig({required this.actionsBuilder, this.header});
  final Widget? header;
  final List<SheetAction> Function(BuildContext) actionsBuilder;
}

class _ScrollableConfig<T> extends _SheetConfig<T> {
  const _ScrollableConfig({
    required this.scrollableBodyBuilder,
    this.header,
    this.headerBuilder,
    super.enableDrag,
    this.initialChildSize = 0.7,
    this.maxChildSize = 0.95,
    this.minChildSize = 0.5,
  });
  final Widget? header;
  final StatefulWidgetBuilder? headerBuilder;
  final ScrollBuilder scrollableBodyBuilder;
  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;
}

class _FormConfig<T> extends _SheetConfig<T> {
  const _FormConfig({
    required this.bodyBuilder,
    this.header,
    this.headerBuilder,
    super.enableDrag,
  });
  final Widget? header;
  final StatefulWidgetBuilder? headerBuilder;
  final StatefulWidgetBuilder bodyBuilder;
}

class _SimpleConfig<T> extends _SheetConfig<T> {
  const _SimpleConfig({
    required this.bodyBuilder,
    this.header,
    this.headerBuilder,
    super.enableDrag,
  });
  final Widget? header;
  final StatefulWidgetBuilder? headerBuilder;
  final StatefulWidgetBuilder bodyBuilder;
}

// ─── AppSheetHeader ───────────────────────────────────────────────────────

/// Structured header for AppSheet.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.titleStyle,
    super.key,
  });

  /// Convenience: string title rendered as left-aligned titleLarge bold.
  factory AppSheetHeader.text(
    String titleText, {
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    Widget? bottom,
    Key? key,
  }) =>
      AppSheetHeader(
        title: Text(titleText),
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        bottom: bottom,
        key: key,
      );

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final titleWidget = DefaultTextStyle.merge(
      style: titleStyle ??
          context.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
      child: title,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, context.spacing.itemGap],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (subtitle != null) ...[
                    context.spacing.tightGap,
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[context.spacing.itemGap, trailing!],
          ],
        ),
        if (bottom != null) ...[
          context.spacing.itemGap,
          bottom!,
        ],
      ],
    );
  }
}

// ─── _SheetChrome ──────────────────────────────────────────────────────────

class _SheetChrome<T> extends StatelessWidget {
  const _SheetChrome({required this.config, super.key});
  final _SheetConfig<T> config;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SafeArea(
      child: StatefulBuilder(
        builder: (context, setState) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.subtle,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                context.spacing.contentGap,
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurfaceVariant.borderO,
                      borderRadius: context.radius(RadiusSize.soft),
                    ),
                  ),
                ),
                context.spacing.itemGap,
                ..._buildHeader(context, setState, spacing),
                Flexible(child: _buildBody(context, setState, spacing)),
                if (config is _FormConfig<T>)
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ),
                context.spacing.itemGap,
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildHeader(
    BuildContext context,
    StateSetter setState,
    AppSpacing spacing,
  ) {
    final Widget? header = switch (config) {
      _ActionsConfig<T>(header: final h) => h,
      _ScrollableConfig<T>(header: final h, headerBuilder: final hb) =>
        h ?? hb?.call(context, setState),
      _FormConfig<T>(header: final h, headerBuilder: final hb) =>
        h ?? hb?.call(context, setState),
      _SimpleConfig<T>(header: final h, headerBuilder: final hb) =>
        h ?? hb?.call(context, setState),
    };
    if (header == null) return [];
    return [
      Padding(
        padding: spacing.sheetPadding,
        child: header,
      ),
      Divider(
        height: 1,
        thickness: 1,
        color: context.colorScheme.outline.subtle,
      ),
    ];
  }

  Widget _buildBody(
    BuildContext context,
    StateSetter setState,
    AppSpacing spacing,
  ) {
    return switch (config) {
      _ActionsConfig<T>(actionsBuilder: final ab) => SheetBodyList(
          children: ab(context).map((a) => _actionTile(context, a)).toList(),
        ),
      _ScrollableConfig<T>(
        scrollableBodyBuilder: final sbb,
        initialChildSize: final init,
        maxChildSize: final max,
        minChildSize: final min,
      ) =>
        DraggableScrollableSheet(
          initialChildSize: init,
          maxChildSize: max,
          minChildSize: min,
          expand: false,
          builder: (context, scrollController) =>
              sbb(context, setState, scrollController),
        ),
      _FormConfig<T>(bodyBuilder: final bb) => SingleChildScrollView(
          padding: spacing.sheetPadding,
          child: bb(context, setState),
        ),
      _SimpleConfig<T>(bodyBuilder: final bb) => Padding(
          padding: spacing.sheetPadding,
          child: bb(context, setState),
        ),
    };
  }

  static Widget _actionTile(BuildContext context, SheetAction action) {
    return ListTile(
      contentPadding: context.spacing.screenPadding,
      title: DefaultTextStyle(
        style: context.textTheme.bodyLarge?.copyWith(
              color: action.isDestructiveAction
                  ? context.colorScheme.error
                  : context.colorScheme.onSurface,
              fontWeight:
                  action.isDefaultAction ? FontWeight.w600 : FontWeight.normal,
            ) ??
            const TextStyle(),
        child: action.title,
      ),
      leading: action.leading != null
          ? DefaultTextStyle(
              style: TextStyle(
                color: action.isDestructiveAction
                    ? context.colorScheme.error
                    : context.colorScheme.onSurfaceVariant,
              ),
              child: action.leading!,
            )
          : null,
      trailing: action.trailing != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: action.trailing!,
            )
          : null,
      onTap: () {
        action.onPressed();
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}

// ─── AppSheet ──────────────────────────────────────────────────────────────

/// Unified bottom sheet launcher.
class AppSheet {
  AppSheet._();

  static Future<T?> _show<T>(
    BuildContext context, {
    required _SheetConfig<T> config,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: config.enableDrag,
      useSafeArea: true,
      constraints: config.constraints,
      builder: (_) => _SheetChrome<T>(config: config),
    );
  }

  /// Action list — DH-themed list of tappable options.
  static Future<T?> actions<T>(
    BuildContext context, {
    required List<SheetAction> Function(BuildContext) actions,
    Widget? header,
  }) {
    return _show<T>(
      context,
      config: _ActionsConfig<T>(
        header: header,
        actionsBuilder: actions,
      ),
    );
  }

  /// Scrollable sheet — header + DraggableScrollableSheet body.
  static Future<T?> scrollable<T>(
    BuildContext context, {
    Widget? header,
    StatefulWidgetBuilder? headerBuilder,
    required Widget Function(
      BuildContext context,
      StateSetter setState,
      ScrollController scrollController,
    ) bodyBuilder,
    bool enableDrag = true,
    double initialChildSize = 0.7,
    double maxChildSize = 0.95,
    double minChildSize = 0.5,
  }) {
    assert(
      header == null || headerBuilder == null,
      'Provide header OR headerBuilder, not both.',
    );
    return _show<T>(
      context,
      config: _ScrollableConfig<T>(
        header: header,
        headerBuilder: headerBuilder,
        scrollableBodyBuilder: bodyBuilder,
        enableDrag: enableDrag,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        minChildSize: minChildSize,
      ),
    );
  }

  /// Form / confirmation — keyboard-aware, auto-scrollable body.
  static Future<T?> form<T>(
    BuildContext context, {
    Widget? header,
    StatefulWidgetBuilder? headerBuilder,
    required Widget Function(BuildContext context, StateSetter setState)
        bodyBuilder,
    bool enableDrag = true,
  }) {
    assert(
      header == null || headerBuilder == null,
      'Provide header OR headerBuilder, not both.',
    );
    return _show<T>(
      context,
      config: _FormConfig<T>(
        header: header,
        headerBuilder: headerBuilder,
        bodyBuilder: bodyBuilder,
        enableDrag: enableDrag,
      ),
    );
  }

  /// Simple non-scrollable body.
  static Future<T?> simple<T>(
    BuildContext context, {
    Widget? header,
    StatefulWidgetBuilder? headerBuilder,
    required Widget Function(BuildContext context, StateSetter setState)
        bodyBuilder,
    bool enableDrag = true,
  }) {
    assert(
      header == null || headerBuilder == null,
      'Provide header OR headerBuilder, not both.',
    );
    return _show<T>(
      context,
      config: _SimpleConfig<T>(
        header: header,
        headerBuilder: headerBuilder,
        bodyBuilder: bodyBuilder,
        enableDrag: enableDrag,
      ),
    );
  }
}
