import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoDebugPrint extends DartLintRule {
  NoDebugPrint()
      : super(
          code: const LintCode(
            name: 'no_debug_print',
            problemMessage:
                'Do not use debugPrint. Use a logger (e.g. logger.debug) instead.',
            correctionMessage: 'Replace with logger.debug(msg).',
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
      if (node.methodName.name == 'debugPrint') {
        reporter.atNode(node, code);
      }
    });
  }
}
