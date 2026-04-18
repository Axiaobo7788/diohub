import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/logo_asset.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/providers/shorebird/shorebird_update_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/app/startup_flows/widgets/shorebird_update_screen.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/widgets/rate_limit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Optional URLs for About section links. Set to non-empty to show the tile.
const String kAboutSourceCodeUrl = 'https://github.com/NamanShergill/diohub';
const String kAboutPrivacyPolicyUrl = '';

/// About section: app version, Flutter/Dart version, tier, licenses, optional links.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<int?> patchNumber = ref.watch(currentPatchProvider);

    return Padding(
      padding: spacing.sectionTitlePaddingLarge,
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder:
            (
              final BuildContext context,
              final AsyncSnapshot<PackageInfo> snapshot,
            ) {
              final PackageInfo? info = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Brand shrine header
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.itemSpacing,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const LogoAsset(size: 80),
                          SizedBox(height: spacing.itemSpacing),
                          const AppNameWidget(size: 32),
                          if (info != null) ...[
                            SizedBox(height: spacing.tightSpacing),
                            Text(
                              patchNumber.when(
                                data: (int? patch) =>
                                    _buildVersionString(info, patch),
                                loading: () =>
                                    '${info.version}+${info.buildNumber}',
                                error: (Object _, StackTrace __) =>
                                    '${info.version}+${info.buildNumber}',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.itemSpacing),
                  // Version details in a card
                  if (info != null)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(spacing.itemSpacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _VersionRow(
                              label: 'Flutter',
                              value: FlutterVersion.version ?? '—',
                              theme: theme,
                            ),
                            _VersionRow(
                              label: 'Dart',
                              value: FlutterVersion.dartVersion ?? '—',
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LoadingIndicator(size: 20),
                    ),
                  SizedBox(height: spacing.itemSpacing),
                  ListTile(
                    leading: const Icon(Icons.system_update),
                    title: const Text('Check for updates'),
                    subtitle: patchNumber.when(
                      data: (int? patch) => patch != null
                          ? Text('Patch $patch installed')
                          : const Text('OTA updates'),
                      loading: () => const Text('Loading...'),
                      error: (Object _, StackTrace __) =>
                          const Text('OTA updates'),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShorebirdUpdateScreen(),
                      ),
                    ),
                  ),
                  if (info != null)
                    ListTile(
                      leading: const Icon(Icons.new_releases_outlined),
                      title: const Text("What's new"),
                      subtitle: const Text('Changelog and release history'),
                      onTap: () => context.router.push(const ChangelogRoute()),
                    ),
                  ListTile(
                    leading: const Icon(Icons.speed_outlined),
                    title: const Text('View GraphQL quota'),
                    subtitle: const Text('API rate limit'),
                    onTap: () => RateLimitSheet.show(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Open source licenses'),
                    onTap: () => showLicensePage(context: context),
                  ),
                  if (kAboutPrivacyPolicyUrl.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy policy'),
                      onTap: () => launchUrl(
                        Uri.parse(kAboutPrivacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  if (kAboutSourceCodeUrl.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Source code'),
                      subtitle: const Text('GitHub repository'),
                      onTap: () => launchUrl(
                        Uri.parse(kAboutSourceCodeUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }

  String _buildVersionString(PackageInfo info, int? patchNumber) {
    final String base = '${info.version}+${info.buildNumber}';
    if (patchNumber != null) {
      return '$base (patch $patchNumber)';
    }
    return base;
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
