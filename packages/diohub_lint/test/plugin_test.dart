import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:diohub_lint/diohub_lint.dart';
import 'package:test/test.dart';

void main() {
  test('createPlugin returns a plugin with 14 lint rules', () {
    final plugin = createPlugin();
    expect(plugin, isNotNull);
    final rules = plugin.getLintRules(CustomLintConfigs.empty);
    expect(rules.length, 14);
  });
}
