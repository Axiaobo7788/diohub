part of 'bottom_sheets.dart';

/// A reusable filter/search field for bottom sheets: leading search icon,
/// optional trailing clear, [InputBorder.none], with optional debounce.
class SheetFilterField extends StatefulWidget {
  const SheetFilterField({
    required this.queryNotifier,
    super.key,
    this.hintText = 'Search...',
    this.debounce = const Duration(milliseconds: 150),
  });

  final ValueNotifier<String> queryNotifier;
  final String hintText;
  final Duration debounce;

  @override
  State<SheetFilterField> createState() => _SheetFilterFieldState();
}

class _SheetFilterFieldState extends State<SheetFilterField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final String initial = widget.queryNotifier.value;
    if (initial.isNotEmpty) _controller.text = initial;
    widget.queryNotifier.addListener(_onNotifierChanged);
  }

  void _onNotifierChanged() {
    final String value = widget.queryNotifier.value;
    if (_controller.text != value) _controller.text = value;
  }

  @override
  void dispose() {
    widget.queryNotifier.removeListener(_onNotifierChanged);
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(final String value) {
    _debounceTimer?.cancel();
    if (widget.debounce == Duration.zero) {
      widget.queryNotifier.value = value;
      return;
    }
    _debounceTimer = Timer(widget.debounce, () {
      widget.queryNotifier.value = value;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return ListenableBuilder(
      listenable: widget.queryNotifier,
      builder: (final BuildContext context, final _) {
        final String query = widget.queryNotifier.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: context.radius(RadiusSize.medium),
            border: Border.all(
              color: context.colorScheme.outline.tint,
            ),
          ),
          child: TextField(
            controller: _controller,
            style: context.textTheme.bodyMedium?.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant.muted,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: context.colorScheme.onSurfaceVariant.secondary,
                      ),
                      onPressed: () {
                        _controller.clear();
                        widget.queryNotifier.value = '';
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            onChanged: _onChanged,
          ),
        );
      },
    );
  }
}
