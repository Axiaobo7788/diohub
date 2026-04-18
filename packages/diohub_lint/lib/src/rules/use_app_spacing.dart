import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/path_utils.dart';

class UseAppSpacing extends DartLintRule {
  UseAppSpacing()
      : super(
          code: const LintCode(
            name: 'use_app_spacing',
            problemMessage:
                'Use app spacing constants (e.g. from theme or style) instead of raw numeric literals.',
            correctionMessage:
                'Replace with a constant from AppSpacing or theme.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  static bool _isZeroLiteral(Expression expr) {
    if (expr is IntegerLiteral) return expr.value == 0;
    if (expr is DoubleLiteral) return expr.value == 0.0;
    return false;
  }

  static bool _isRawNumericLiteral(Expression expr) {
    if (expr is IntegerLiteral) return true;
    if (expr is DoubleLiteral) return true;
    return false;
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (resolveLayer(resolver.path) == AppLayer.style) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;

      if (typeName == 'EdgeInsets' || typeName == 'EdgeInsetsDirectional') {
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression) {
            final expr = arg.expression;
            if (_isZeroLiteral(expr)) continue;
            if (_isRawNumericLiteral(expr)) {
              reporter.atNode(node, code);
              return;
            }
          }
        }
      }

      if (typeName == 'SizedBox') {
        for (final arg in node.argumentList.arguments) {
          if (arg is NamedExpression &&
              (arg.name.label.name == 'width' ||
                  arg.name.label.name == 'height')) {
            final expr = arg.expression;
            if (_isZeroLiteral(expr)) continue;
            if (_isRawNumericLiteral(expr)) {
              reporter.atNode(node, code);
              return;
            }
          }
        }
      }
    });
  }
}
