import 'package:diohub/common/charts/language_distribution_chart.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:flutter/material.dart';

/// Top languages aggregated from commit contributions by repository.
class TopLanguagesSection extends StatelessWidget {
  const TopLanguagesSection({
    required this.repositories,
    super.key,
  });

  final List<ContributedRepository> repositories;

  @override
  Widget build(BuildContext context) {
    final languages = _aggregateLanguages(repositories);
    if (languages.isEmpty) return const SizedBox.shrink();

    return SectionHeader(
      title: 'Top Languages',
      showDivider: true,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.itemSpacing),
        child: LanguageDistributionChart(
          languages: languages,
          maxLanguages: 5,
          showPercentage: true,
        ),
      ),
    );
  }
}

List<LanguageData> _aggregateLanguages(List<ContributedRepository> repos) {
  final Map<String, ({int commits, Color? color})> languageCommits =
      <String, ({int commits, Color? color})>{};
  int totalCommits = 0;
  for (final repo in repos) {
    final lang = repo.graphQLRepository.primaryLanguage;
    if (lang == null) continue;
    final name = lang.name;
    final commitCount = repo.contributionCount;
    totalCommits += commitCount;
    final existing = languageCommits[name];
    final color = lang.color != null ? _parseHexColor(lang.color!) : null;
    languageCommits[name] = (
      commits: (existing?.commits ?? 0) + commitCount,
      color: existing?.color ?? color,
    );
  }
  if (totalCommits == 0) return <LanguageData>[];
  return languageCommits.entries
      .map((e) => LanguageData(
            name: e.key,
            percentage: (e.value.commits / totalCommits) * 100,
            color: e.value.color,
          ))
      .toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));
}

Color _parseHexColor(String hex) {
  return tryParseHexColor(hex, fallback: Colors.grey) ?? Colors.grey;
}
