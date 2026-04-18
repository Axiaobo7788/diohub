import 'dart:async';

import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

/// Reusable terminal screen with app bar, copy action, and optional auto-scroll.
/// When [liveStream] is set, each emitted chunk is appended to the terminal (for live log tailing).
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({
    super.key,
    required this.title,
    this.initialContent,
    this.readOnly = true,
    this.autoScroll = false,
    this.onOutput,
    this.liveStream,
    this.actions,
    this.maxLines = 10000,
    this.fontSizeDelta = 0,
  });

  final String title;
  final String? initialContent;
  final bool readOnly;
  final bool autoScroll;
  final void Function(String)? onOutput;

  /// When non-null, each emitted string is appended to the terminal (e.g. live log tailing).
  final Stream<String>? liveStream;
  final List<Widget>? actions;
  final int maxLines;
  final int fontSizeDelta;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal terminal;
  StreamSubscription<String>? _liveSubscription;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: widget.maxLines);
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      terminal.write(widget.initialContent!);
    }
    if (widget.onOutput != null) {
      terminal.onOutput = widget.onOutput;
    }
    if (widget.liveStream != null) {
      _liveSubscription = widget.liveStream!.listen((String chunk) {
        if (mounted) terminal.write(chunk);
      });
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }

  TerminalTheme _themeFromContext(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return TerminalTheme(
      cursor: scheme.primary.withValues(alpha: 0.7),
      selection: scheme.primary.withValues(alpha: 0.4),
      foreground: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
      background: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      black: isDark ? const Color(0xFF000000) : const Color(0xFF000000),
      red: scheme.error,
      green: const Color(0xFF0DBC79),
      yellow: const Color(0xFFE5E510),
      blue: scheme.primary,
      magenta: const Color(0xFFBC3FBC),
      cyan: const Color(0xFF11A8CD),
      white: isDark ? const Color(0xFFE5E5E5) : const Color(0xFFE5E5E5),
      brightBlack: const Color(0xFF666666),
      brightRed: scheme.error,
      brightGreen: const Color(0xFF23D18B),
      brightYellow: const Color(0xFFF5F543),
      brightBlue: scheme.primary,
      brightMagenta: const Color(0xFFD670D6),
      brightCyan: const Color(0xFF29B8DB),
      brightWhite: const Color(0xFFFFFFFF),
      searchHitBackground: const Color(0xFFFFFF2B),
      searchHitBackgroundCurrent: const Color(0xFF31FF26),
      searchHitForeground: const Color(0xFF000000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy all',
            onPressed: () {
              final text = terminal.buffer.getText();
              if (text.isNotEmpty && mounted) {
                ProviderScope.containerOf(context)
                    .read(clipboardServiceProvider)
                    .copy(text);
              }
            },
          ),
          ...?widget.actions,
        ],
      ),
      body: TerminalView(
        terminal,
        theme: _themeFromContext(context),
        textStyle: TerminalStyle(
          fontFamily: 'monospace',
          fontSize: 13.0 + widget.fontSizeDelta,
        ),
        readOnly: widget.readOnly,
        autofocus: !widget.readOnly,
      ),
    );
  }
}
