import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/view/authentication/widgets/code_info_box.dart';
import 'package:diohub/view/authentication/widgets/error_popup.dart';
import 'package:diohub/view/authentication/widgets/login_popup.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared authentication content used by startup and explicit account routes.
class AuthFlowContent extends ConsumerWidget {
  const AuthFlowContent({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AuthenticationState state = ref.watch(authProvider);
    return switch (state) {
      AuthenticationUnauthenticated() => const LoginPopup(),
      AuthenticationChecking() ||
      AuthenticationAccountLinking() => const LoadingIndicator(),
      AuthenticationInitialized(:final DeviceCodeResponse deviceCodeResponse) =>
        CodeInfoBox(deviceCodeResponse),
      AuthenticationError(:final String error) => ErrorPopup(error),
    };
  }
}
