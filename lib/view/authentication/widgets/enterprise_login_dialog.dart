import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/common/misc/app_dialog.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterpriseLoginDialog extends StatefulWidget {
  const EnterpriseLoginDialog({super.key});

  @override
  State<EnterpriseLoginDialog> createState() => _EnterpriseLoginDialogState();
}

class _EnterpriseLoginDialogState extends State<EnterpriseLoginDialog> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _hostController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  String? _validateHost(String? value) {
    if (value == null || value.isEmpty) {
      return 'Host URL is required';
    }
    
    // Basic URL validation
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Host must start with http:// or https://';
      }
      if (!uri.hasAuthority) {
        return 'Invalid host URL';
      }
    } catch (e) {
      return 'Invalid URL format';
    }
    
    return null;
  }

  String? _validateToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'Personal Access Token is required';
    }
    if (value.length < 20) {
      return 'Token appears to be too short';
    }
    return null;
  }

  String _normalizeHostUrl(String hostUrl) {
    // Remove trailing slash
    String normalized = hostUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    // For GHES, the API is typically at /api/v3
    // If they just provided the base domain, append the API path
    if (!normalized.contains('/api')) {
      normalized = '$normalized/api/v3';
    }
    
    return normalized;
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
      final String normalizedHost = _normalizeHostUrl(_hostController.text);
      final String token = _tokenController.text.trim();
      
      final AuthRepository authRepo = AuthRepository();

      if (mounted) {
        // Unified flow: AccountBloc will fetch user and persist
        context.read<AccountBloc>().add(
              AddAccount(
                AccessTokenModel(
                  accessToken: token,
                  scope: authRepo.scopeString,
                ),
                hostUrl: normalizedHost,
              ),
            );
        
        // Signal auth gate passed
        context.read<AuthenticationBloc>().add(
              AuthSuccessful(
                AccessTokenModel(
                  accessToken: token,
                  scope: authRepo.scopeString,
                ),
              ),
            );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Enterprise Login',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Enter your GitHub Enterprise Server details',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_...',
                helperText: 'Generate from Settings > Developer settings > Personal access tokens',
              ),
              validator: _validateToken,
              enabled: !_loading,
              obscureText: true,
              autocorrect: false,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            StringButton(
              title: _loading ? 'Authenticating...' : 'Login',
              loading: _loading,
              onTap: _loading ? null : _authenticate,
            ),
            const SizedBox(height: 8),
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


