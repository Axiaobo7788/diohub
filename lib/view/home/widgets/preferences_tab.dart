import 'package:diohub/common/widgets/section_toc_button.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/onboarding/onboarding_overlay.dart';
import 'package:diohub/view/settings/settings_section_config.dart';
import 'package:diohub/view/settings/sections/card_display_section.dart';
import 'package:diohub/view/settings/sections/defaults_section.dart';
import 'package:diohub/view/settings/sections/layout_density_section.dart';
import 'package:diohub/view/settings/sections/reset_preferences_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const Set<PreferencesSectionId> _navigableSectionIds = {
  PreferencesSectionId.layoutDensity,
  PreferencesSectionId.cardDisplay,
  PreferencesSectionId.defaults,
  PreferencesSectionId.resetPreferences,
};

/// Preferences tab: Layout & Density, Card Display, Defaults, Reset Preferences.
class PreferencesTabSlivers extends ConsumerStatefulWidget {
  const PreferencesTabSlivers({super.key});

  @override
  ConsumerState<PreferencesTabSlivers> createState() =>
      _PreferencesTabSliversState();
}

class _PreferencesTabSliversState extends ConsumerState<PreferencesTabSlivers> {
  late final Map<PreferencesSectionId, GlobalKey<State<StatefulWidget>>>
      _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = {
      for (final PreferencesSectionId id in _navigableSectionIds) id: GlobalKey(),
    };
  }

  void _scrollToSection(PreferencesSectionId id) {
    final BuildContext? ctx = _sectionKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  static Widget _sectionContent(PreferencesSectionId id) {
    return switch (id) {
      PreferencesSectionId.layoutDensity => const LayoutDensitySection(),
      PreferencesSectionId.cardDisplay => const CardDisplaySection(),
      PreferencesSectionId.defaults => const DefaultsSection(),
      PreferencesSectionId.resetPreferences => const ResetPreferencesSection(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> leading = [
      ListTile(
        leading: const Icon(Icons.replay),
        title: const Text('Show onboarding again'),
        subtitle: const Text('Reset and see the customisation flow again'),
        onTap: () => showOnboardingOverlay(context),
      ),
      const Divider(),
    ];

    final List<Widget> slivers = [
      if (kDebugMode || kProfileMode)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.screenPadding.left,
              context.spacing.itemSpacing,
              context.spacing.screenPadding.right,
              0,
            ),
            child: OutlinedButton.icon(
              onPressed: () => showOnboardingOverlay(context),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Run onboarding again'),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: leading,
        ),
      ),
    ];

    final List<SectionTocEntry> tocEntries = preferencesSectionToc
        .where((e) => _navigableSectionIds.contains(e.id))
        .map((e) => SectionTocEntry(
              id: e.id.name,
              title: e.title,
              icon: e.icon,
            ))
        .toList();

    final SectionTocButton? tocButton = tocEntries.isNotEmpty
        ? SectionTocButton(
            entries: tocEntries,
            onSelect: (String sectionId) {
              final PreferencesSectionId sid =
                  PreferencesSectionId.values.byName(sectionId);
              _scrollToSection(sid);
            },
          )
        : null;

    for (final SettingsSectionEntry<PreferencesSectionId> entry
        in preferencesSectionToc) {
      if (!_navigableSectionIds.contains(entry.id)) continue;

      final GlobalKey<State<StatefulWidget>>? key = _sectionKeys[entry.id];
      final Widget sectionContent = KeyedSubtree(
        key: key,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.screenPadding.left,
            0,
            context.spacing.screenPadding.right,
            context.spacing.sectionSpacing,
          ),
          child: _sectionContent(entry.id),
        ),
      );

      Widget? trailing;
      if (entry.id == PreferencesSectionId.layoutDensity) {
        trailing = tocButton;
      }

      slivers.add(
        StickyGlassSection.withTitle(
          title: entry.title,
          icon: entry.icon,
          trailing: trailing,
          sliver: SliverToBoxAdapter(child: sectionContent),
        ),
      );
    }

    return SliverPadding(
      padding: context.spacing.listInset,
      sliver: MultiSliver(children: slivers),
    );
  }
}
