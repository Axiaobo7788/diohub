import 'package:diohub/common/nav_center/models/entity_capability_renderers.dart';
import 'package:diohub/view/issues_pulls/widgets/config/pull_capabilities.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Widget> pullSettingsSections(
  BuildContext context,
  WidgetRef ref,
  PullRequestRef pullRef,
  PullInfo data,
) {
  final caps = pullCapabilities(
    context: context,
    ref: ref,
    pullRef: pullRef,
    data: data,
  );
  return buildSettingsFromCapabilities(caps, context);
}
