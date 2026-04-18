import 'dart:io';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform-aware setup sheet for GitHub link handling.
/// Android: Guides to "Open by default" system settings.
/// iOS: Explains Share Extension, Opener app, and Shortcuts.
class LinkHandlingSetupSheet {
  LinkHandlingSetupSheet._();

  static Future<void> show(final BuildContext context) async {
    await AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Set up link handling'),
      bodyBuilder: (final BuildContext context, final _) {
        return Platform.isAndroid
            ? const _AndroidContent()
            : const _IOSContent();
      },
    );
  }
}

// ─── Android Content ────────────────────────────────────────────────────────

class _AndroidContent extends StatelessWidget {
  const _AndroidContent();

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'To open GitHub links directly in DioHub:',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: spacing.itemSpacing),
          _StepCard(
            number: 1,
            title: 'Open Android Settings',
            description: 'Tap the button below to open system settings',
            scheme: scheme,
            spacing: spacing,
          ),
          SizedBox(height: spacing.compactSpacing),
          _StepCard(
            number: 2,
            title: 'Enable link handling',
            description:
                'Go to "Open by default" and enable github.com and www.github.com',
            scheme: scheme,
            spacing: spacing,
          ),
          SizedBox(height: spacing.sectionSpacing),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── iOS Content ────────────────────────────────────────────────────────────

class _IOSContent extends StatefulWidget {
  const _IOSContent();

  @override
  State<_IOSContent> createState() => _IOSContentState();
}

class _IOSContentState extends State<_IOSContent> {
  bool? _openerInstalled;

  @override
  void initState() {
    super.initState();
    _checkOpener();
  }

  Future<void> _checkOpener() async {
    final bool canLaunch =
        await canLaunchUrl(Uri.parse('opener://'));
    if (mounted) {
      setState(() {
        _openerInstalled = canLaunch;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IOSSection(
            icon: Icons.ios_share,
            title: 'Share Extension',
            description:
                'When viewing a GitHub page in Safari, tap the Share button and select DioHub to open the page in-app.',
            scheme: scheme,
            spacing: spacing,
          ),
          SizedBox(height: spacing.sectionSpacing),
          _IOSSection(
            icon: Icons.open_in_new,
            title: 'Opener App (Recommended)',
            description: _openerInstalled == true
                ? 'Opener is installed. Open it and add DioHub as the handler for github.com links.'
                : 'Install Opener from the App Store to automatically route GitHub links to DioHub.',
            scheme: scheme,
            spacing: spacing,
            action: _openerInstalled == false
                ? _OpenerButton(spacing: spacing)
                : null,
          ),
          SizedBox(height: spacing.sectionSpacing),
          _IOSSection(
            icon: Icons.shortcut,
            title: 'Shortcuts',
            description:
                'You can also create a Shortcut to open any URL in DioHub using the diohub:// URL scheme.',
            scheme: scheme,
            spacing: spacing,
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.scheme,
    required this.spacing,
  });

  final int number;
  final String title;
  final String description;
  final ColorScheme scheme;
  final AppSpacing spacing;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: spacing.cardContentPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.compactSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.tightSpacing),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IOSSection extends StatelessWidget {
  const _IOSSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.scheme,
    required this.spacing,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final ColorScheme scheme;
  final AppSpacing spacing;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: scheme.primary,
            ),
            SizedBox(width: spacing.tightSpacing),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.compactSpacing),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
        if (action != null) ...<Widget>[
          SizedBox(height: spacing.itemSpacing),
          action!,
        ],
      ],
    );
  }
}

class _OpenerButton extends StatelessWidget {
  const _OpenerButton({required this.spacing});

  final AppSpacing spacing;

  Future<void> _openOpenerAppStore() async {
    final Uri url = Uri.parse('https://apps.apple.com/app/opener/id989565871');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openOpenerAppStore,
        icon: const Icon(Icons.download),
        label: const Text('Get Opener'),
      ),
    );
  }
}
