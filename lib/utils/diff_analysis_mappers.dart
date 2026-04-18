import 'package:diohub/common/charts/language_distribution_chart.dart';
import 'package:diohub/utils/diff_analysis.dart';
import 'package:flutter/material.dart' show Color;

/// Convenience mappers from [DiffAnalysisResult] to chart widget data types.
/// Keeps diff_analysis.dart free of Flutter imports.

List<LanguageData> toLanguageChartData(List<LanguageImpact> impacts) {
  return impacts
      .map((i) => LanguageData(
            name: i.language,
            percentage: i.percentage,
            color: i.color != null ? Color(i.color!.value) : null,
            size: i.totalChanges,
          ))
      .toList();
}

List<LanguageData> toDirectoryChartData(List<DirectoryImpact> impacts) {
  return impacts
      .map((d) => LanguageData(
            name: d.directory,
            percentage: d.percentage,
            size: d.totalChanges,
          ))
      .toList();
}
