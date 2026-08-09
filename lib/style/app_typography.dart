import 'package:flutter/material.dart';

/// Semantic typography for the GitHub-dense Material 3 surfaces.
///
/// Every role is derived from the active [TextTheme] so theme colors and the
/// user-selected proportional font remain intact. The [mono] role retains the
/// inherited text attributes but intentionally selects the platform monospace
/// family. Only DioHub-owned semantic metrics are overridden here.
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.pageTitle,
    required this.repositoryTitle,
    required this.sectionTitle,
    required this.primaryInformation,
    required this.body,
    required this.metadata,
    required this.label,
    required this.mono,
  });

  factory AppTypography.fromTextTheme(final TextTheme textTheme) {
    final TextStyle fallback = textTheme.bodyMedium ?? const TextStyle();
    return AppTypography(
      pageTitle: (textTheme.headlineSmall ?? fallback).copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
      ),
      repositoryTitle: (textTheme.titleLarge ?? fallback).copyWith(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
      ),
      sectionTitle: (textTheme.titleMedium ?? fallback).copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
      ),
      primaryInformation: (textTheme.titleSmall ?? fallback).copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      body: fallback.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      metadata: (textTheme.bodySmall ?? fallback).copyWith(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
      ),
      label: (textTheme.labelLarge ?? fallback).copyWith(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
      ),
      mono: fallback.copyWith(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 20 / 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  final TextStyle pageTitle;
  final TextStyle repositoryTitle;
  final TextStyle sectionTitle;
  final TextStyle primaryInformation;
  final TextStyle body;
  final TextStyle metadata;
  final TextStyle label;
  final TextStyle mono;

  @override
  AppTypography copyWith({
    final TextStyle? pageTitle,
    final TextStyle? repositoryTitle,
    final TextStyle? sectionTitle,
    final TextStyle? primaryInformation,
    final TextStyle? body,
    final TextStyle? metadata,
    final TextStyle? label,
    final TextStyle? mono,
  }) => AppTypography(
    pageTitle: pageTitle ?? this.pageTitle,
    repositoryTitle: repositoryTitle ?? this.repositoryTitle,
    sectionTitle: sectionTitle ?? this.sectionTitle,
    primaryInformation: primaryInformation ?? this.primaryInformation,
    body: body ?? this.body,
    metadata: metadata ?? this.metadata,
    label: label ?? this.label,
    mono: mono ?? this.mono,
  );

  @override
  AppTypography lerp(
    covariant final ThemeExtension<AppTypography>? other,
    final double t,
  ) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t)!,
      repositoryTitle: TextStyle.lerp(
        repositoryTitle,
        other.repositoryTitle,
        t,
      )!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      primaryInformation: TextStyle.lerp(
        primaryInformation,
        other.primaryInformation,
        t,
      )!,
      body: TextStyle.lerp(body, other.body, t)!,
      metadata: TextStyle.lerp(metadata, other.metadata, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}

extension AppTypographyThemeEx on ThemeData {
  AppTypography get appTypography =>
      extension<AppTypography>() ?? AppTypography.fromTextTheme(textTheme);
}

extension AppTypographyContextEx on BuildContext {
  AppTypography get appTypography => Theme.of(this).appTypography;
}
