import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/app_dialog.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Known GitHub token prefixes for clipboard auto-detection.
const List<String> _tokenPrefixes = <String>[
  'ghp_',
  'github_pat_',
  'gho_',
  'ghu_',
];

/// Which server the user is signing into (ServerConfig selection).
enum _TokenLoginServer { githubDotCom, enterprise }

/// Dialog for signing in with a Personal Access Token.
///
/// Supports both GitHub.com and GitHub Enterprise Server via a toggle.
class EnterpriseLoginDialog extends ConsumerStatefulWidget {
  const EnterpriseLoginDialog({super.key});

  @override
  ConsumerState<EnterpriseLoginDialog> createState() =>
      _EnterpriseLoginDialogState();
}

class _EnterpriseLoginDialogState extends ConsumerState<EnterpriseLoginDialog> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorMessage;

  /// Selected server: GitHub.com or Enterprise (shows host field when enterprise).
  _TokenLoginServer _serverChoice = _TokenLoginServer.githubDotCom;

  /// Token detected on clipboard (set during initState).
  String? _clipboardToken;

  @override
  void initState() {
    super.initState();
    // Defer clipboard access to a post-frame callback so the dialog is
    // fully laid out first. On iOS 16+, programmatic clipboard reads
    // outside a user gesture context may be silently denied; deferring
    // gives the system the best chance of succeeding.
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _detectClipboardToken();
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _detectClipboardToken() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      final String? text = data?.text?.trim();
      if (text != null && _tokenPrefixes.any(text.startsWith)) {
        if (mounted) {
          setState(() => _clipboardToken = text);
        }
      }
    } catch (e) {
      AppLogger.info('Clipboard access denied or unavailable', tag: 'Auth');
    }
  }

  void _pasteToken(final String token) {
    _tokenController.text = token;
    setState(() => _clipboardToken = null);
  }

  String? _validateHost(final String? value) {
    if (_serverChoice != _TokenLoginServer.enterprise) return null;
    if (value == null || value.isEmpty) {
      return 'Host URL is required';
    }
    try {
      final Uri uri = Uri.parse(value);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Host must start with http:// or https://';
      }
      if (!uri.hasAuthority) {
        return 'Invalid host URL';
      }
    } catch (e, st) {
      AppLogger.warning(
        'Invalid host URL format',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
      return 'Invalid URL format';
    }
    return null;
  }

  String? _validateToken(final String? value) {
    if (value == null || value.isEmpty) {
      return 'Personal Access Token is required';
    }
    if (value.length < 20) {
      return 'Token appears to be too short';
    }
    return null;
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Raw host URL for enterprise (no /api/v3 suffix — ServerConfig derives it).
      final String? hostUrl = _serverChoice == _TokenLoginServer.enterprise
          ? _hostController.text.trim()
          : null;
      final String token = _tokenController.text.trim();

      if (!mounted) {
        setState(() {
          _loading = false;
        });
        return;
      }

      if (mounted) {
        final AccessTokenModel tokenModel = AccessTokenModel(
          accessToken: token,
          // Scope will be read from X-OAuth-Scopes header in fetchViewerInfoWithToken
          scope: null,
        );
        await ref
            .read(accountProvider.notifier)
            .addAccount(
              tokenModel,
              hostUrl: hostUrl,
              authMethod: AuthMethod.pat,
            );
        ref.read(authProvider.notifier).reset();
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e, st) {
      AppLogger.warning(
        'Enterprise token authentication failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppDialog(
      title: 'Sign in with Token',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Explanation text
            Text(
              'A Personal Access Token gives full access to '
              'organizations that may restrict third-party apps.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.muted,
                height: 1.4,
              ),
            ),
            context.spacing.sectionGap,

            // GitHub.com / Enterprise toggle (ServerConfig selection)
            SegmentedButton<_TokenLoginServer>(
              segments: const <ButtonSegment<_TokenLoginServer>>[
                ButtonSegment<_TokenLoginServer>(
                  value: _TokenLoginServer.githubDotCom,
                  label: Text('GitHub.com'),
                ),
                ButtonSegment<_TokenLoginServer>(
                  value: _TokenLoginServer.enterprise,
                  label: Text('Enterprise'),
                ),
              ],
              selected: <_TokenLoginServer>{_serverChoice},
              onSelectionChanged: (final Set<_TokenLoginServer> selection) {
                setState(() => _serverChoice = selection.first);
              },
              showSelectedIcon: false,
            ),
            context.spacing.sectionGap,

            // Host URL field (Enterprise only)
            if (_serverChoice == _TokenLoginServer.enterprise) ...<Widget>[
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host URL',
                  hintText: 'https://github.company.com',
                  helperText: 'Your enterprise server URL',
                ),
                validator: _validateHost,
                enabled: !_loading,
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              context.spacing.sectionGap,
            ],

            // Clipboard auto-detect chip
            if (_clipboardToken != null) ...<Widget>[
              ActionChip(
                avatar: const Icon(Icons.content_paste, size: 16),
                label: const Text('Token detected on clipboard'),
                onPressed: () => _pasteToken(_clipboardToken!),
              ),
              context.spacing.contentGap,
            ],

            // Token field
            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_...',
                helperText:
                    'Generate from Settings > Developer settings > Tokens',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste, size: 20),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    try {
                      final ClipboardData? data = await Clipboard.getData(
                        'text/plain',
                      );
                      if (data?.text != null && data!.text!.trim().isNotEmpty) {
                        _tokenController.text = data.text!.trim();
                      } else if (mounted) {
                        ref
                            .read(notificationServiceProvider)
                            .error('Clipboard is empty');
                      }
                    } catch (e) {
                      AppLogger.info('Clipboard paste failed: $e', tag: 'Auth');
                      if (mounted) {
                        ref
                            .read(notificationServiceProvider)
                            .error(
                              'Could not access clipboard. '
                              'Please paste the token manually.',
                            );
                      }
                    }
                  },
                ),
              ),
              validator: _validateToken,
              enabled: !_loading,
              obscureText: true,
              autocorrect: false,
            ),

            // Create Token link (GitHub.com only; Enterprise uses host field)
            if (_serverChoice == _TokenLoginServer.githubDotCom) ...<Widget>[
              context.spacing.itemGap,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    openInAppBrowser(ServerConfig.gitHubDotCom.createTokenUrl);
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Create Token on GitHub'),
                ),
              ),
            ],

            if (_errorMessage != null) ...<Widget>[
              context.spacing.sectionGap,
              Container(
                padding: context.spacing.contentPadding,
                decoration: BoxDecoration(
                  color: Colors.red.subtle,
                  borderRadius: context.radius(RadiusSize.small),
                  border: Border.all(color: Colors.red.borderO),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
            context.spacing.spaciousGap,
            StringButton(
              title: _loading ? 'Authenticating...' : 'Sign in',
              loading: _loading,
              onTap: _loading ? null : _authenticate,
            ),
            context.spacing.itemGap,
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
