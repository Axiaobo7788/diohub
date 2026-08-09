import 'package:diohub/app/settings/glass_pill.dart';
import 'package:diohub/app/settings/spacing.dart';
import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/main.dart' show getTheme;
import 'package:diohub/style/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives semantic roles without dropping base colors or user font', () {
    const Color inheritedColor = Color(0xff123456);
    const TextStyle inheritedStyle = TextStyle(
      color: inheritedColor,
      fontFamily: 'UserFont',
      letterSpacing: 0.25,
    );
    const TextTheme textTheme = TextTheme(
      headlineSmall: inheritedStyle,
      titleLarge: inheritedStyle,
      titleMedium: inheritedStyle,
      titleSmall: inheritedStyle,
      bodyMedium: inheritedStyle,
      bodySmall: inheritedStyle,
      labelLarge: inheritedStyle,
    );

    final AppTypography typography = AppTypography.fromTextTheme(textTheme);

    expect(typography.pageTitle.fontSize, 24);
    expect(typography.pageTitle.height, closeTo(32 / 24, 0.0001));
    expect(typography.pageTitle.fontWeight, FontWeight.w700);
    expect(typography.repositoryTitle.fontSize, 20);
    expect(typography.repositoryTitle.height, closeTo(28 / 20, 0.0001));
    expect(typography.sectionTitle.fontSize, 16);
    expect(typography.sectionTitle.height, closeTo(24 / 16, 0.0001));
    expect(typography.sectionTitle.fontWeight, FontWeight.w600);
    expect(typography.primaryInformation.fontSize, 14);
    expect(typography.primaryInformation.height, closeTo(20 / 14, 0.0001));
    expect(typography.primaryInformation.fontWeight, FontWeight.w600);
    expect(typography.body.fontSize, 14);
    expect(typography.body.height, closeTo(20 / 14, 0.0001));
    expect(typography.body.fontWeight, FontWeight.w400);
    expect(typography.metadata.fontSize, 12);
    expect(typography.metadata.height, closeTo(18 / 12, 0.0001));
    expect(typography.metadata.fontWeight, FontWeight.w400);
    expect(typography.label.fontSize, 13);
    expect(typography.label.height, closeTo(18 / 13, 0.0001));
    expect(typography.label.fontWeight, FontWeight.w600);
    expect(typography.mono.fontSize, 13);
    expect(typography.mono.height, closeTo(20 / 13, 0.0001));
    expect(typography.mono.fontWeight, FontWeight.w400);
    expect(typography.mono.fontFamily, 'monospace');

    for (final TextStyle style in <TextStyle>[
      typography.pageTitle,
      typography.repositoryTitle,
      typography.sectionTitle,
      typography.primaryInformation,
      typography.body,
      typography.metadata,
      typography.label,
      typography.mono,
    ]) {
      expect(style.color, inheritedColor);
      expect(style.letterSpacing, 0.25);
    }
    expect(typography.pageTitle.fontFamily, 'UserFont');
    expect(typography.body.fontFamily, 'UserFont');
  });

  testWidgets('installs semantic typography in light and dark app themes', (
    final WidgetTester tester,
  ) async {
    late ThemeData lightTheme;
    late ThemeData darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (final BuildContext context) {
            lightTheme = getTheme(
              context,
              brightness: Brightness.light,
              colorScheme: null,
              materialYouEnabled: false,
              flexSettings: FlexThemeSettingsModel(),
              fontFamily: 'UserFont',
              spacingSettings: const SpacingSettings(),
              glassPillSettings: const GlassPillSettings(),
            );
            darkTheme = getTheme(
              context,
              brightness: Brightness.dark,
              colorScheme: null,
              materialYouEnabled: false,
              flexSettings: FlexThemeSettingsModel(),
              fontFamily: 'UserFont',
              spacingSettings: const SpacingSettings(),
              glassPillSettings: const GlassPillSettings(),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    for (final ThemeData theme in <ThemeData>[lightTheme, darkTheme]) {
      final AppTypography? typography = theme.extension<AppTypography>();
      expect(typography, isNotNull);
      expect(typography!.pageTitle.color, theme.textTheme.headlineSmall?.color);
      expect(
        typography.pageTitle.fontFamily,
        theme.textTheme.headlineSmall?.fontFamily,
      );
      expect(
        typography.primaryInformation.color,
        theme.textTheme.titleSmall?.color,
      );
      expect(typography.body.color, theme.textTheme.bodyMedium?.color);
      expect(typography.metadata.color, theme.textTheme.bodySmall?.color);
    }
  });
}
