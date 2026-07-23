import 'package:diohub/app/settings/locale_settings.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

String appLanguageLabel(
  final BuildContext context,
  final AppLanguage language,
) => switch (language) {
  AppLanguage.system => context.l10n.languageSystem,
  AppLanguage.english => context.l10n.languageEnglish,
  AppLanguage.simplifiedChinese => context.l10n.languageSimplifiedChinese,
};

Future<AppLanguage?> showAppLanguageDialog(
  final BuildContext context,
  final AppLanguage current,
) => showDialog<AppLanguage>(
  context: context,
  builder: (final BuildContext dialogContext) => SimpleDialog(
    key: const ValueKey<String>('home-language-dialog'),
    title: Text(dialogContext.l10n.languageAndRegion),
    children: <Widget>[
      for (final AppLanguage option in AppLanguage.values)
        SimpleDialogOption(
          key: ValueKey<String>('home-language-option-${option.storageValue}'),
          onPressed: () => Navigator.of(dialogContext).pop(option),
          child: Row(
            children: <Widget>[
              Icon(
                option == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(appLanguageLabel(dialogContext, option))),
            ],
          ),
        ),
    ],
  ),
);
