import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub/common/nav_center/models/compose_bar_config.dart';
import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';

/// All behavioral parameters for a compose flow.
/// [ComposeScaffold] has zero conditionals; all branching is via this config and builder slots.
@immutable
class ComposeConfig {
  const ComposeConfig({
    required this.mode,
    required this.repoRef,
    required this.onSubmit,
    this.title = '',
    this.subtitle,
    this.submitIcon = Icons.check,
    this.submitLabel = 'Submit',
    this.loadingVerb = 'Saving…',
    this.showTitle = true,
    this.titleValidator,
    this.initialTitle,
    this.initialBody,
    this.draftSubject,
    this.draftScope,
    this.getMentionCandidates,
  });

  final ComposeMode mode;
  final RepoRef repoRef;
  final Future<void> Function(String title, String body) onSubmit;
  final String title;
  final String? subtitle;
  final IconData submitIcon;
  final String submitLabel;
  final String loadingVerb;
  final bool showTitle;
  final FormFieldValidator<String>? titleValidator;
  final String? initialTitle;
  final String? initialBody;

  /// Entity this draft is for. DAO extracts apiPath/dbType/parentPath from it.
  /// When non-null with [draftScope], enables auto-save (500ms debounce) + manual save button.
  final EntityRef? draftSubject;

  /// Which composition surface (comment, review, issueBody, prBody).
  final DraftScope? draftScope;

  /// Whether draft persistence is enabled.
  bool get hasDraft => draftSubject != null && draftScope != null;

  /// When non-null, enables @-mention suggestions in the body editor.
  final Future<List<MentionCandidate>> Function()? getMentionCandidates;
}
