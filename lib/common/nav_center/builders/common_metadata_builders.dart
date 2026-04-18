import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds a timestamps metadata group from date fields.
/// Used by repo, issue, PR, and profile configs.
Widget buildTimestampsGroup({
  required final DateTime? createdAt,
  final DateTime? updatedAt,
  final DateTime? pushedAt,
  final DateTime? closedAt,
  final DateTime? mergedAt,
  final DateTime? archivedAt,
  final String title = 'Timeline',
}) {
  final List<TimestampEntry> timestamps = <TimestampEntry>[
    if (createdAt != null) TimestampEntry(label: 'Created', date: createdAt),
    if (updatedAt != null) TimestampEntry(label: 'Updated', date: updatedAt),
    if (pushedAt != null) TimestampEntry(label: 'Pushed', date: pushedAt),
    if (closedAt != null) TimestampEntry(label: 'Closed', date: closedAt),
    if (mergedAt != null) TimestampEntry(label: 'Merged', date: mergedAt),
    if (archivedAt != null) TimestampEntry(label: 'Archived', date: archivedAt),
  ];
  if (timestamps.isEmpty) {
    return const SizedBox.shrink();
  }
  return MetadataGroupCard(
    title: title.isEmpty ? null : title,
    children: <Widget>[
      MetadataTimestampRow(timestamps: timestamps),
    ],
  );
}

/// Builds contact/link rows (email, twitter, website, homepage) as a list.
/// Used by [buildContactGroup] and by profile to combine with location/company/flags.
List<Widget> buildContactRows({
  final String? email,
  final String? websiteUrl,
  final String? twitterUsername,
  final String? homepageUrl,
}) {
  final List<Widget> rows = <Widget>[];
  if (email != null && email.isNotEmpty) {
    rows.add(
      MetadataContactRow(
        icon: Icons.email_outlined,
        value: email,
        onTap: () => launchUrl(Uri.parse('mailto:$email')),
      ),
    );
  }
  if (twitterUsername != null && twitterUsername.isNotEmpty) {
    rows.add(
      MetadataContactRow(
        icon: Icons.tag_rounded,
        value: '@$twitterUsername',
        onTap: () => launchUrl(
          Uri.parse('https://twitter.com/$twitterUsername'),
        ),
      ),
    );
  }
  if (websiteUrl != null && websiteUrl.isNotEmpty) {
    rows.add(
      MetadataContactRow(
        icon: Icons.link_rounded,
        value: websiteUrl,
        onTap: () => launchUrl(Uri.parse(websiteUrl)),
      ),
    );
  }
  if (homepageUrl != null && homepageUrl.isNotEmpty) {
    rows.add(
      MetadataContactRow(
        icon: Icons.link_rounded,
        value: homepageUrl,
        onTap: () => launchUrl(Uri.parse(homepageUrl)),
      ),
    );
  }
  return rows;
}

/// Builds a contact/links metadata group from URL-style fields.
/// Used by repo (homepage) and profile (email, twitter, website).
/// Returns [SizedBox.shrink] if no contact fields are set.
Widget buildContactGroup({
  final String? email,
  final String? websiteUrl,
  final String? twitterUsername,
  final String? homepageUrl,
  final String title = 'Contact',
}) {
  final List<Widget> rows = buildContactRows(
    email: email,
    websiteUrl: websiteUrl,
    twitterUsername: twitterUsername,
    homepageUrl: homepageUrl,
  );
  if (rows.isEmpty) {
    return const SizedBox.shrink();
  }
  return MetadataGroupCard(
    title: title.isEmpty ? null : title,
    children: <Widget>[
      Column(mainAxisSize: MainAxisSize.min, children: rows),
    ],
  );
}
