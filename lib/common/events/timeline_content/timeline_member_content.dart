import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for MemberEvent
class TimelineMemberContent extends StatelessWidget {
  const TimelineMemberContent({
    required this.member,
    required this.action,
    required this.repoName,
    required this.repoUrl,
    super.key,
  });

  final UserInfoModel member;
  final String action;
  final String repoName;
  final String repoUrl;

  @override
  Widget build(BuildContext context) {
    return TimelineContainer(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Member card
        ProfileCard(
          member,
          compact: true,
        ),
        const SizedBox(height: 8),
        // Repository card
        RepoCardLoading(
          repoUrl,
          repoName,
          refresh: false,
        ),
      ],
      ),
    );
  }
}

