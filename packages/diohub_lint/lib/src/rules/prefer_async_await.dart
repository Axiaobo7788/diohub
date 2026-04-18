import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferAsyncAwait extends DartLintRule {
  static final _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  PreferAsyncAwait()
      : super(
          code: const LintCode(
            name: 'prefer_async_await',
            problemMessage: 'Prefer async/await over .then() for readability.',
            correctionMessage: 'Convert to async function and use await.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'then') {
        final targetType = node.realTarget?.staticType;
        if (targetType != null &&
            _futureChecker.isAssignableFromType(targetType)) {
          reporter.atNode(node.methodName, code);
        }
      }
    });
  }
}
