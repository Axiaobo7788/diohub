import 'package:diohub/common/widgets/section_toc_button.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/settings_section_config.dart';
import 'package:diohub/view/settings/sections/about_section.dart';
import 'package:diohub/view/settings/sections/events_section.dart';
import 'package:diohub/view/settings/sections/integrations_section.dart';
import 'package:diohub/view/settings/sections/navigation_links_section.dart';
import 'package:diohub/view/settings/sections/notifications_section.dart';
import 'package:diohub/view/settings/sections/privacy_diagnostics_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const Set<BehaviorSectionId> _navigableSectionIds = {
  BehaviorSectionId.notifications,
  BehaviorSectionId.navigationLinks,
  BehaviorSectionId.events,
  BehaviorSectionId.integrations,
  BehaviorSectionId.privacyDiagnostics,
  BehaviorSectionId.about,
};

/// Behavior tab: Notifications, Navigation & Links, Events, Integrations, About.
class BehaviorTabSlivers extends ConsumerStatefulWidget {
  const BehaviorTabSlivers({super.key});

  @override
  ConsumerState<BehaviorTabSlivers> createState() =>
      _BehaviorTabSliversState();
}

class _BehaviorTabSliversState extends ConsumerState<BehaviorTabSlivers> {
  late final Map<BehaviorSectionId, GlobalKey<State<StatefulWidget>>>
      _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = {
      for (final BehaviorSectionId id in _navigableSectionIds) id: GlobalKey(),
    };
  }

  void _scrollToSection(BehaviorSectionId id) {
    final BuildContext? ctx = _sectionKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  static Widget _sectionContent(BehaviorSectionId id) {
    return switch (id) {
      BehaviorSectionId.notifications => const NotificationsSection(),
      BehaviorSectionId.navigationLinks => const NavigationLinksSection(),
      BehaviorSectionId.events => const EventsSection(),
      BehaviorSectionId.integrations => const IntegrationsSection(),
      BehaviorSectionId.privacyDiagnostics => const PrivacyDiagnosticsSection(),
      BehaviorSectionId.about => const AboutSection(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = [];

    final List<SectionTocEntry> tocEntries = behaviorSectionToc
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
              final BehaviorSectionId sid =
                  BehaviorSectionId.values.byName(sectionId);
              _scrollToSection(sid);
            },
          )
        : null;

    for (final SettingsSectionEntry<BehaviorSectionId> entry
        in behaviorSectionToc) {
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
      if (entry.id == BehaviorSectionId.notifications) {
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
