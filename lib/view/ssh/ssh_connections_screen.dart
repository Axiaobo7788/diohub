import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_models/models/ssh/ssh_connection.dart';
import 'package:diohub/providers/ssh/ssh_providers.dart';
import 'package:diohub/services/ssh/ssh_secure_storage.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:uuid/uuid.dart';

import 'package:diohub/routes/router.gr.dart';

@RoutePage()
class SSHConnectionsScreen extends ConsumerWidget {
  const SSHConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConnections = ref.watch(sshConnectionsProvider);
    final notifier = ref.read(sshConnectionsProvider.notifier);
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add connection',
            onPressed: () => _showAddConnectionSheet(context, ref),
          ),
        ],
      ),
      body: asyncConnections.when(
        loading: () => const CenteredSpinner(),
        error: (e, _) => Center(
          child: Padding(
            padding: spacing.pagePadding,
            child: Text('Failed to load connections: $e'),
          ),
        ),
        data: (connections) => connections.isEmpty
            ? Center(
                child: Padding(
                  padding: spacing.pagePadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      SizedBox(height: spacing.itemSpacing),
                      Text(
                        'No SSH connections',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: spacing.tightSpacing),
                      Text(
                        'Add a connection to connect to servers via SSH.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      SizedBox(height: spacing.sectionSpacing),
                      FilledButton.icon(
                        onPressed: () => _showAddConnectionSheet(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add connection'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: spacing.pagePadding,
                itemExtent: 80,
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  final c = connections[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                    child: BorderedContainer(
                      padding: spacing.contentPadding,
                      child: Row(
                        children: [
                          Icon(
                            Octicons.device_desktop,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: spacing.itemSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  c.label,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SizedBox(height: spacing.tightSpacing / 2),
                                Text(
                                  '${c.username}@${c.host}:${c.port} · ${c.authMethod == SSHAuthMethod.password ? "Password" : "Key"} auth',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.router
                                  .push(SSHTerminalRoute(connectionId: c.id));
                            },
                            icon:
                                const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Connect'),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditConnectionSheet(context, ref, c);
                              } else if (value == 'delete') {
                                notifier.remove(c.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_rounded, size: 20),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline_rounded,
                                      size: 20),
                                  title: Text('Delete'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddConnectionSheet(BuildContext context, WidgetRef ref) {
    _showConnectionSheet(context, ref, connection: null);
  }

  void _showEditConnectionSheet(
      BuildContext context, WidgetRef ref, SSHConnection c) {
    _showConnectionSheet(context, ref, connection: c);
  }

  void _showConnectionSheet(BuildContext context, WidgetRef ref,
      {SSHConnection? connection}) {
    AppSheet.form<void>(
      context,
      header: AppSheetHeader.text(
        connection != null ? 'Edit connection' : 'Add connection',
      ),
      bodyBuilder: (BuildContext sheetContext, StateSetter setState) {
        return _ConnectionSheetForm(
          connection: connection,
          ref: ref,
          sheetContext: sheetContext,
        );
      },
    );
  }
}

class _ConnectionSheetForm extends StatefulWidget {
  const _ConnectionSheetForm({
    required this.connection,
    required this.ref,
    required this.sheetContext,
  });

  final SSHConnection? connection;
  final WidgetRef ref;
  final BuildContext sheetContext;

  @override
  State<_ConnectionSheetForm> createState() => _ConnectionSheetFormState();
}

class _ConnectionSheetFormState extends State<_ConnectionSheetForm> {
  late final TextEditingController labelController;
  late final TextEditingController hostController;
  late final TextEditingController portController;
  late final TextEditingController usernameController;
  late final TextEditingController privateKeyController;
  late SSHAuthMethod authMethod;

  @override
  void initState() {
    super.initState();
    final connection = widget.connection;
    labelController = TextEditingController(text: connection?.label ?? '');
    hostController = TextEditingController(text: connection?.host ?? '');
    portController = TextEditingController(text: connection?.port.toString() ?? '22');
    usernameController = TextEditingController(text: connection?.username ?? '');
    privateKeyController = TextEditingController();
    authMethod = connection?.authMethod ?? SSHAuthMethod.password;
  }

  @override
  void dispose() {
    labelController.dispose();
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    privateKeyController.dispose();
    super.dispose();
  }

  bool get isEdit => widget.connection != null;

  @override
  Widget build(BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. My Server',
              ),
            ),
            context.spacing.contentGap,
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'hostname or IP',
              ),
              keyboardType: TextInputType.url,
            ),
            context.spacing.contentGap,
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Port',
              ),
              keyboardType: TextInputType.number,
            ),
            context.spacing.contentGap,
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            context.spacing.sectionGap,
            DropdownButtonFormField<SSHAuthMethod>(
              value: authMethod,
              decoration: const InputDecoration(labelText: 'Auth method'),
              items: const [
                DropdownMenuItem(
                    value: SSHAuthMethod.password, child: Text('Password')),
                DropdownMenuItem(
                    value: SSHAuthMethod.key, child: Text('SSH Key')),
              ],
              onChanged: (v) =>
                  setState(() => authMethod = v ?? SSHAuthMethod.password),
            ),
            if (authMethod == SSHAuthMethod.key) ...[
              context.spacing.contentGap,
              TextField(
                controller: privateKeyController,
                decoration: const InputDecoration(
                  labelText: 'Private key (PEM)',
                  hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
            context.spacing.spaciousGap,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(widget.sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
                context.spacing.itemGap,
                FilledButton(
                  onPressed: () async {
                    final host = hostController.text.trim();
                    final username = usernameController.text.trim();
                    final port = int.tryParse(portController.text.trim()) ?? 22;
                    if (host.isEmpty || username.isEmpty) return;
                    final notifier = widget.ref.read(sshConnectionsProvider.notifier);
                    late final String connectionId;
                    if (isEdit) {
                      connectionId = widget.connection!.id;
                      notifier.updateConnection(widget.connection!.copyWith(
                        label: labelController.text.trim().isEmpty
                            ? widget.connection!.label
                            : labelController.text.trim(),
                        host: host,
                        port: port,
                        username: username,
                        authMethod: authMethod,
                      ));
                    } else {
                      connectionId = const Uuid().v4();
                      notifier.add(SSHConnection(
                        id: connectionId,
                        label: labelController.text.trim().isEmpty
                            ? host
                            : labelController.text.trim(),
                        host: host,
                        port: port,
                        username: username,
                        authMethod: authMethod,
                      ));
                    }
                    if (authMethod == SSHAuthMethod.key &&
                        privateKeyController.text.trim().isNotEmpty) {
                      final SSHSecureStorage storage =
                          widget.ref.read(sshSecureStorageProvider);
                      await storage.setPrivateKey(
                        connectionId,
                        privateKeyController.text.trim(),
                      );
                    }
                    if (widget.sheetContext.mounted) {
                      Navigator.of(widget.sheetContext).pop();
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        );
  }
}
