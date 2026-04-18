import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';

/// Unified content for repository creation events in timeline
class TimelineRepositoryContent extends StatelessWidget {
  const TimelineRepositoryContent({
    required this.repoCardFields,
    super.key,
  });

  final RepoCardData repoCardFields;

  @override
  Widget build(final BuildContext context) {
    final RepoRef repoRef = RepoRef.fromRepoCardFields(repoCardFields);
    return BorderedContainer(
      ref: repoRef,
      child: RepositoryCard(repoCardFields),
    );
  }
}
