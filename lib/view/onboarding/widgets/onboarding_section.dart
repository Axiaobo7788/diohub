import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/widgets/theme_config/section_header_widget.dart';
import 'package:flutter/material.dart';

/// Single section primitive for onboarding: header + section-scoped preview + controls.
/// [preview] is wrapped in [ContextualPreview]. [children] may be settings primitives (e.g. SettingsGroup, toggles).
class OnboardingSection extends StatelessWidget {
  const OnboardingSection({
    required this.title,
    required this.preview,
    required this.children,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget preview;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeaderWidget(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
        SizedBox(height: spacing.itemSpacing),
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.screenPadding.left,
            0,
            spacing.screenPadding.right,
            0,
          ),
          child: ContextualPreview(child: preview),
        ),
        SizedBox(height: spacing.itemSpacing),
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.screenPadding.left,
            0,
            spacing.screenPadding.right,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}
