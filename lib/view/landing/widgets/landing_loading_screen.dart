import 'package:auto_route/auto_route.dart';
import 'package:auto_route/annotations.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/view/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Show loading indicator on app startup until authentication status is determined.
@RoutePage()
class LandingLoadingScreen extends StatelessWidget {
  const LandingLoadingScreen({super.key, this.initLink});

  final Uri? initLink;

  @override
  Widget build(final BuildContext context) =>
      BlocListener<AccountBloc, AccountState>(
        listener: (final BuildContext context, final AccountState state) {},
        child: Scaffold(
          body: BlocBuilder<AccountBloc, AccountState>(
            builder:
                (final BuildContext context, final AccountState accountState) {
              // Show loading while loading/adding/switching accounts
              if (accountState is AccountLoading ||
                  accountState is AccountAdding ||
                  accountState is AccountSwitching) {
                return SafeArea(
                  child: Scaffold(
                    body: Column(
                      children: <Widget>[
                        Expanded(child: Container()),
                        const Expanded(child: LoadingIndicator()),
                        const Expanded(
                          child: AppNameWithVersion(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // If account ready with active account, show provider loading flow
              if (accountState is AccountReady &&
                  accountState.activeAccount != null) {
                return ProviderLoadingProgressWrapper<CurrentUserProvider>(
                  listener: (final Status value) async {
                    if (value == Status.loaded && initLink != null) {
                      await deepLinkNavigate(initLink!);
                    }
                  },
                  loadingBuilder: (final BuildContext context) => SafeArea(
                    child: Scaffold(
                      body: Column(
                        children: <Widget>[
                          Expanded(child: Container()),
                          const Expanded(child: LoadingIndicator()),
                          const Expanded(
                            child: AppNameWithVersion(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childBuilder: (final BuildContext context,
                          final CurrentUserProvider value) =>
                      const HomeScreen(),
                );
              }

              // Fallback (shouldn't reach here, but just in case)
              return const SizedBox.shrink();
            },
          ),
        ),
      );
}
