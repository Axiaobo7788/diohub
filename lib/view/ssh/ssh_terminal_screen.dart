import 'dart:async';
import 'dart:typed_data';

import 'package:auto_route/annotations.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_models/models/ssh/ssh_connection.dart';
import 'package:diohub/providers/settings/terminal_settings_provider.dart';
import 'package:diohub/providers/ssh/ssh_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';

@RoutePage()
class SSHTerminalScreen extends ConsumerStatefulWidget {
  const SSHTerminalScreen({
    super.key,
    required this.connectionId,
  });

  final String connectionId;

  @override
  ConsumerState<SSHTerminalScreen> createState() => _SSHTerminalScreenState();
}

class _SSHTerminalScreenState extends ConsumerState<SSHTerminalScreen> {
  String _status = 'Connecting...';
  Widget? _body;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  Future<void> _connect() async {
    final connections =
        ref.read(sshConnectionsProvider).value ?? <SSHConnection>[];
    final connection = connections.cast<SSHConnection?>().firstWhere(
          (c) => c?.id == widget.connectionId,
          orElse: () => null,
        );
    if (connection == null) {
      setState(() {
        _error = 'Connection not found';
        _status = 'Error';
      });
      return;
    }

    SSHConnectionCredentials? credentials;
    try {
      credentials = await ref
          .read(sshConnectionCredentialsProvider(widget.connectionId).future);
    } on Exception catch (e) {
      AppLogger.error('Failed to load SSH credentials', error: e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load credentials';
          _status = 'Error';
        });
      }
      return;
    }
    if (credentials == null) {
      if (mounted) {
        setState(() {
          _error = 'No private key found for this connection';
          _status = 'Error';
        });
      }
      return;
    }

    String? password = credentials.password;
    if (connection.authMethod == SSHAuthMethod.password &&
        (password == null || password.isEmpty)) {
      if (mounted) {
        password = await _promptPassword(context, connection.label);
        if (password != null && password.isNotEmpty) {
          await ref
              .read(sshConnectionsProvider.notifier)
              .saveConnectionPassword(widget.connectionId, password);
        }
      }
    }

    final identities = credentials.identities;

    try {
      if (!mounted) return;
      setState(() =>
          _status = 'Connecting to ${connection.host}:${connection.port}...');

      final socket = await SSHSocket.connect(connection.host, connection.port);
      final client = SSHClient(
        socket,
        username: connection.username,
        onPasswordRequest:
            connection.authMethod == SSHAuthMethod.password && password != null
                ? () => password!
                : null,
        identities: identities,
      );

      await client.authenticated;
      if (!mounted) return;
      setState(() => _status = 'Connected');

      final session = await client.shell();
      if (!mounted) return;
      final terminalSettings = ref.read(terminalSettingsProvider);
      setState(() {
        _body = _SSHTerminalBody(
          client: client,
          session: session,
          connection: connection,
          fontSizeDelta: terminalSettings.terminalFontSizeDelta.toDouble(),
          maxLines: terminalSettings.terminalMaxScrollback,
          onDisconnected: () {
            if (mounted) {
              setState(() {
                _status = 'Disconnected';
                _body = _buildDisconnectedBody(context, connection);
              });
            }
          },
        );
        // ignore: prefer_async_await
      });
      // ignore: prefer_async_await

      // ignore: prefer_async_await
      client.done.then((_) {
        if (mounted) {
          setState(() {
            _status = 'Disconnected';
            _body = _buildDisconnectedBody(context, connection);
          });
        }
      });
    } catch (e, st) {
      AppLogger.warning(
        'SSH connect/session failed',
        error: e,
        stackTrace: st,
        tag: 'SSHTerminalScreen',
      );
      if (mounted) {
        setState(() {
          _error = e.toString();
          _status = 'Error';
        });
      }
    }
  }

  Future<String?> _promptPassword(BuildContext context, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Password for $label'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter SSH password',
          ),
          obscureText: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedBody(
      BuildContext context, SSHConnection connection) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disconnected')),
      body: Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 48,
                color: context.colorScheme.onSurfaceVariant,
              ),
              context.spacing.sectionGap,
              Text(
                'Disconnected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              context.spacing.spaciousGap,
              FilledButton.icon(
                onPressed: () => _connect(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_status)),
        body: Center(
          child: Padding(
            padding: context.spacing.spaciousPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.colorScheme.error,
                ),
                context.spacing.sectionGap,
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_body != null) return _body!;

    return Scaffold(
      appBar: AppBar(title: Text(_status)),
      body: const CenteredSpinner(),
    );
  }
}

/// Wires an SSH session to an xterm Terminal and builds TerminalView.
class _SSHTerminalBody extends StatefulWidget {
  const _SSHTerminalBody({
    required this.client,
    required this.session,
    required this.connection,
    required this.fontSizeDelta,
    required this.maxLines,
    required this.onDisconnected,
  });

  final SSHClient client;
  final SSHSession session;
  final SSHConnection connection;
  final double fontSizeDelta;
  final int maxLines;
  final VoidCallback onDisconnected;

  @override
  State<_SSHTerminalBody> createState() => _SSHTerminalBodyState();
}

class _SSHTerminalBodyState extends State<_SSHTerminalBody> {
  late final Terminal terminal;
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: widget.maxLines);
    terminal.onOutput = (data) {
      widget.session.write(Uint8List.fromList(data.codeUnits));
    };
    _stdoutSub = widget.session.stdout.listen((data) {
      if (mounted) terminal.write(String.fromCharCodes(data));
    });
    _stderrSub = widget.session.stderr.listen((data) {
      if (mounted) terminal.write(String.fromCharCodes(data));
    });
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    widget.client.close();
    super.dispose();
  }

  TerminalTheme _theme(BuildContext context) {
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
        title: Text(widget.connection.label),
        actions: [
          Consumer(
            builder: (context, ref, child) => IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy all',
              onPressed: () {
                final text = terminal.buffer.getText();
                if (text.isNotEmpty) {
                  ref.read(clipboardServiceProvider).copy(text);
                }
              },
            ),
          ),
        ],
      ),
      body: TerminalView(
        terminal,
        theme: _theme(context),
        textStyle: TerminalStyle(
          fontFamily: 'monospace',
          fontSize: 13.0 + widget.fontSizeDelta,
        ),
        readOnly: false,
        autofocus: true,
      ),
    );
  }
}
