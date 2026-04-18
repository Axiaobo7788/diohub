import 'package:diohub/common/charts/language_distribution_chart.dart';
import 'package:diohub/common/widgets/section_header.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/utils/diff_analysis.dart';
import 'package:diohub/utils/diff_analysis_mappers.dart';
import 'package:flutter/material.dart';

/// Reusable widget that takes a [DiffAnalysisResult] and renders complexity badge,
/// directory breakdown, and language breakdown.
class DiffInsightsSection extends StatelessWidget {
  const DiffInsightsSection({
    required this.analysis,
    this.onDirectoryTap,
    this.onLanguageTap,
    this.showComplexity = true,
    super.key,
  });

  final DiffAnalysisResult analysis;
  final void Function(DirectoryImpact)? onDirectoryTap;
  final void Function(LanguageImpact)? onLanguageTap;
  final bool showComplexity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showComplexity) _ComplexityBadge(complexity: analysis.complexity),
        if (analysis.directoryBreakdown.isNotEmpty) ...[
          SectionHeader(
            title: 'Directories',
            style: SectionHeaderStyle.small,
            child: LanguageDistributionChart(
              languages: toDirectoryChartData(analysis.directoryBreakdown),
              showSize: true,
              showPercentage: true,
              onLanguageTap: onDirectoryTap != null
                  ? (data) {
                      final dir = analysis.directoryBreakdown.firstWhere(
                        (d) => d.directory == data.name,
                      );
                      onDirectoryTap!(dir);
                    }
                  : null,
            ),
          ),
        ],
        if (analysis.languageBreakdown.isNotEmpty) ...[
          SectionHeader(
            title: 'Languages',
            style: SectionHeaderStyle.small,
            child: LanguageDistributionChart(
              languages: toLanguageChartData(analysis.languageBreakdown),
              showPercentage: true,
              onLanguageTap: onLanguageTap != null
                  ? (data) {
                      final lang = analysis.languageBreakdown.firstWhere(
                        (l) => l.language == data.name,
                      );
                      onLanguageTap!(lang);
                    }
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _ComplexityBadge extends StatelessWidget {
  const _ComplexityBadge({required this.complexity});
  final ChangeComplexity complexity;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (complexity.size) {
      ChangeSize.xs => Colors.green.shade700,
      ChangeSize.small => Colors.teal.shade700,
      ChangeSize.medium => Colors.orange.shade700,
      ChangeSize.large => Colors.deepOrange.shade700,
      ChangeSize.xl => Colors.red.shade700,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TintedChip(
        color: color,
        label: complexity.label,
      ),
    );
  }
}
