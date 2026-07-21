import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that all PilotTool implementations properly implement toJson() and fromJson().
/// This prevents runtime serialization failures and ensures tools can be properly
/// marshalled across isolates or persisted.
class RequireToolSerialization extends DartLintRule {
  RequireToolSerialization()
    : super(
        code: const LintCode(
          name: 'require_tool_serialization',
          problemMessage:
              'PilotTool implementations must have proper toJson() and fromJson() methods for serialization.',
          correctionMessage:
              'Implement toJson() returning Map<String, dynamic> and a fromJson factory constructor.',
          errorSeverity: ErrorSeverity.WARNING,
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // Check if this class implements or extends PilotTool
      final isPilotTool = classElement.allSupertypes.any(
        (type) => type.element.name == 'PilotTool',
      );

      if (!isPilotTool) return;

      // Check if the class is abstract (abstract classes don't need serialization)
      if (classElement.isAbstract) return;

      // Check for toJson method
      final hasToJson = classElement.methods.any(
        (method) =>
            method.name == 'toJson' &&
            method.returnType.getDisplayString(withNullability: false) ==
                'Map<String, dynamic>',
      );

      // Check for fromJson factory
      final hasFromJson = classElement.constructors.any(
        (constructor) =>
            constructor.name == 'fromJson' && constructor.isFactory,
      );

      if (!hasToJson || !hasFromJson) {
        reporter.atToken(node.name, code);
      }
    });
  }
}
