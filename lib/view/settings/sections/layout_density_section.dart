import 'package:diohub/app/settings/layout.dart';
import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/layout_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/widgets/previews/mock_list_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layout & Density section: density dropdown, sticky headers.
class LayoutDensitySection extends ConsumerWidget {
  const LayoutDensitySection({super.key});

  static List<SettingsDropdownOption<LayoutDensity>> get _densityOptions =>
      <SettingsDropdownOption<LayoutDensity>>[
        const SettingsDropdownOption<LayoutDensity>(
          value: LayoutDensity.compact,
          label: 'Compact',
        ),
        const SettingsDropdownOption<LayoutDensity>(
          value: LayoutDensity.default_,
          label: 'Default',
        ),
        const SettingsDropdownOption<LayoutDensity>(
          value: LayoutDensity.spacious,
          label: 'Spacious',
        ),
      ];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final LayoutSettings layout = ref.watch(layoutProvider);
    final LayoutNotifier notifier = ref.read(layoutProvider.notifier);
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ContextualPreview(
          child: _LayoutDensityPreview(density: layout.density),
        ),
        SizedBox(height: spacing.itemSpacing),
        SettingsGroup(
          children: <Widget>[
            SettingsDropdown<LayoutDensity>(
              title: 'List density',
              value: layout.density,
              options: _densityOptions,
              onChanged: notifier.updateDensity,
            ),
            SettingsToggle(
              title: 'Sticky section headers',
              value: layout.stickyHeaders,
              onChanged: notifier.updateStickyHeaders,
            ),
          ],
        ),
      ],
    );
  }
}

class _LayoutDensityPreview extends StatelessWidget {
  const _LayoutDensityPreview({required this.density});

  final LayoutDensity density;

  @override
  Widget build(final BuildContext context) {
    final double paddingValue = switch (density) {
      LayoutDensity.compact => 6,
      LayoutDensity.default_ => 10,
      LayoutDensity.spacious => 14,
    };
    final EdgeInsets padding = EdgeInsets.all(paddingValue);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiniIssueCard(
            title: 'Add dark mode support',
            number: '128',
            stateColor: Colors.green,
            repoName: 'octocat/Hello-World',
            padding: padding,
          ),
          context.spacing.compactGap,
          MiniIssueCard(
            title: 'Fix notification badge count',
            number: '127',
            stateColor: Colors.red,
            repoName: 'octocat/Hello-World',
            padding: padding,
          ),
        ],
      ),
    );
  }
}
