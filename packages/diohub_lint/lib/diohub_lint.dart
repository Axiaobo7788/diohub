library diohub_lint;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/no_dart_io_in_view.dart';
import 'src/rules/no_database_import_in_view.dart';
import 'src/rules/no_debug_print.dart';
import 'src/rules/no_empty_catch_body.dart';
import 'src/rules/no_service_import_in_common.dart';
import 'src/rules/no_service_import_in_view.dart';
import 'src/rules/no_upward_import_in_models.dart';
import 'src/rules/no_view_import_in_common.dart';
import 'src/rules/no_view_import_in_providers.dart';
import 'src/rules/no_view_import_in_services.dart';
import 'src/rules/prefer_async_await.dart';
import 'src/rules/require_tool_serialization.dart';
import 'src/rules/use_app_spacing.dart';
import 'src/rules/use_theme_colors.dart';

PluginBase createPlugin() => _DioHubLintPlugin();

class _DioHubLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        NoServiceImportInView(),
        NoServiceImportInCommon(),
        NoDatabaseImportInView(),
        NoViewImportInCommon(),
        NoViewImportInProviders(),
        NoViewImportInServices(),
        NoUpwardImportInModels(),
        NoEmptyCatchBody(),
        NoDebugPrint(),
        PreferAsyncAwait(),
        NoDartIoInView(),
        UseAppSpacing(),
        UseThemeColors(),
        RequireToolSerialization(),
      ];
}
