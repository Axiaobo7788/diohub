import 'package:diohub/providers/startup_flows/startup_flow.dart';
// ignore: no_view_import_in_providers
import 'package:diohub/view/app/startup_flows/flows/link_handling_setup_flow.dart';
// ignore: no_view_import_in_providers
import 'package:diohub/view/app/startup_flows/flows/onboarding_flow.dart';
// ignore: no_view_import_in_providers
import 'package:diohub/view/app/startup_flows/flows/scope_reauth_flow.dart';
// ignore: no_view_import_in_providers
import 'package:diohub/view/app/startup_flows/flows/shorebird_patch_flow.dart';
// ignore: no_view_import_in_providers
import 'package:diohub/view/app/startup_flows/flows/whats_new_flow.dart';

/// All known startup flows, in priority order.
///
/// Register new flows by adding them to this list.
List<StartupFlow> get startupFlowRegistry => <StartupFlow>[
      ScopeReauthFlow(),
      ShorebirdPatchFlow(),
      OnboardingFlow(),
      WhatsNewFlow(),
      LinkHandlingSetupFlow(),
    ];
