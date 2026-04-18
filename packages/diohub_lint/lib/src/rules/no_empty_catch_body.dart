import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoEmptyCatchBody extends DartLintRule {
  NoEmptyCatchBody()
      : super(
          code: const LintCode(
            name: 'no_empty_catch_body',
            problemMessage:
                'Empty catch block. Add a comment or handle the error.',
            correctionMessage: 'Add a TODO comment or proper error handling.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCatchClause((node) {
      final body = node.body;
      if (body.statements.isEmpty) {
        reporter.atNode(node, code);
      }
    });
  }
}
