import 'package:diohub/common/nav_center/models/entity_capability_renderers.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Widget> issueSettingsSections(
  BuildContext context,
  WidgetRef ref,
  IssueRef issueRef,
  IssueInfo data,
) {
  final caps = issueCapabilities(
    context: context,
    ref: ref,
    issueRef: issueRef,
    data: data,
  );
  return buildSettingsFromCapabilities(caps, context);
}
