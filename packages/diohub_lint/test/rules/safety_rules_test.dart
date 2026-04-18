import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:diohub_lint/diohub_lint.dart';
import 'package:test/test.dart';

void main() {
  group('P1 safety rules', () {
    test('plugin registers no_empty_catch_body', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('no_empty_catch_body'));
    });

    test('plugin registers no_debug_print', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('no_debug_print'));
    });

    test('plugin registers prefer_async_await', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('prefer_async_await'));
    });

    test('plugin registers no_dart_io_in_view', () {
      final plugin = createPlugin();
      final rules = plugin.getLintRules(CustomLintConfigs.empty);
      final names = rules.map((r) => r.code.name).toList();
      expect(names, contains('no_dart_io_in_view'));
    });
  });
}
