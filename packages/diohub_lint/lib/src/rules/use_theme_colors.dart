import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/path_utils.dart';

class UseThemeColors extends DartLintRule {
  UseThemeColors()
      : super(
          code: const LintCode(
            name: 'use_theme_colors',
            problemMessage:
                'Use theme colors instead of direct Colors.xxx or Color() outside lib/style/.',
            correctionMessage:
                'Use Theme.of(context).colorScheme or style constants.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (resolveLayer(resolver.path) == AppLayer.style) return;

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors') {
        if (node.identifier.name == 'transparent') return;
        reporter.atNode(node, code);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'Color') {
        reporter.atNode(node, code);
      }
    });
  }
}
