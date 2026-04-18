import 'package:diohub_lint/src/helpers/path_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:diohub_lint/diohub_lint.dart';
import 'package:test/test.dart';

void main() {
  group('P2 consistency rules', () {
    test('plugin registers use_app_spacing', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('use_app_spacing'));
    });

    test('plugin registers use_theme_colors', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('use_theme_colors'));
    });

    test('use_app_spacing skips lib/style/ layer', () {
      expect(resolveLayer('lib/style/spacing.dart'), AppLayer.style);
    });

    test('use_theme_colors skips lib/style/ layer', () {
      expect(resolveLayer('lib/style/colors.dart'), AppLayer.style);
    });
  });
}
