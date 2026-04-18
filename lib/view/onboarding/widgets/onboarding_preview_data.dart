import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Placeholder repo card for onboarding and theme preview (octocat/Hello-World).
/// Matches [RepositoryCard] layout without requiring [RepoCardData].
class OnboardingPlaceholderRepoCard extends StatelessWidget {
  const OnboardingPlaceholderRepoCard({super.key});

  static const String _ownerLogin = 'octocat';
  static const String _name = 'Hello-World';
  static const String _description =
      'A simple repository for demos and previews.';
  static const String _language = 'Dart';
  static const int _stargazerCount = 42;
  static const String _avatarUrl = 'https://github.com/octocat.png';

  @override
  Widget build(final BuildContext context) {
    final Color languageColor = Color(getLangColor(_language));
    return BorderedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: EntityHeader(
                  avatarUrl: _avatarUrl,
                  title: _name,
                  subtitle: _ownerLogin,
                  showAvatar: true,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MetadataChip(
                    leading: Icon(
                      Octicons.star,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    label: '$_stargazerCount',
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.9),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                MetadataChip(
                  leading: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: languageColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: _language,
                  accentColor: languageColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
