import 'package:diohub/common/widgets/section_toc_button.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/settings_section_config.dart';
import 'package:diohub/view/settings/sections/diff_code_section.dart';
import 'package:diohub/view/settings/widgets/code_browser_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const Set<CodeSectionId> _navigableSectionIds = {
  CodeSectionId.diffCode,
  CodeSectionId.codeBrowser,
};

/// Code & Diffs tab: Diff & Code, Code Browser, Downloads.
class CodeSettingsTabSlivers extends ConsumerStatefulWidget {
  const CodeSettingsTabSlivers({super.key});

  @override
  ConsumerState<CodeSettingsTabSlivers> createState() =>
      _CodeSettingsTabSliversState();
}

class _CodeSettingsTabSliversState
    extends ConsumerState<CodeSettingsTabSlivers> {
  late final Map<CodeSectionId, GlobalKey<State<StatefulWidget>>> _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = {
      for (final CodeSectionId id in _navigableSectionIds) id: GlobalKey(),
    };
  }

  void _scrollToSection(CodeSectionId id) {
    final BuildContext? ctx = _sectionKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  static Widget _sectionContent(CodeSectionId id) {
    return switch (id) {
      CodeSectionId.diffCode => const DiffCodeSection(),
      CodeSectionId.codeBrowser => const CodeBrowserSettingsSection(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = [];

    final List<SectionTocEntry> tocEntries = codeSectionToc
        .where((e) => _navigableSectionIds.contains(e.id))
        .map(
          (e) => SectionTocEntry(id: e.id.name, title: e.title, icon: e.icon),
        )
        .toList();

    final SectionTocButton? tocButton = tocEntries.isNotEmpty
        ? SectionTocButton(
            entries: tocEntries,
            onSelect: (String sectionId) {
              final CodeSectionId sid = CodeSectionId.values.byName(sectionId);
              _scrollToSection(sid);
            },
          )
        : null;

    for (final SettingsSectionEntry<CodeSectionId> entry in codeSectionToc) {
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
      if (entry.id == CodeSectionId.diffCode) {
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
