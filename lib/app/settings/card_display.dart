import 'package:diohub/app/settings/settings_descriptor.dart';

/// Card density presets for controlling information display.
enum CardDensity {
  /// Minimal: max 3 chips, body/reactions/projects/branchRefs/topics/activityPulse/timeToResolution/authorAssoc OFF
  compact,
  
  /// Balanced (default): max 5 chips, body OFF, reactions/branchRefs ON
  comfortable,
  
  /// Full: unlimited chips, everything ON
  detailed,
}

/// Card display preferences: which optional sections to show on cards.
class CardDisplaySettings {
  const CardDisplaySettings({
    this.density = CardDensity.comfortable,
    this.maxVisibleChips,
    this.showBodyPreview = true,
    this.showReactions = true,
    this.showProjectChips = true,
    this.showBranchRefs = true,
    this.showDiffDistribution = true,
    this.showReviewerChip = true,
    this.showTopics = true,
    this.showRepoLanguage = true,
    this.showRepoStats = true,
    this.showDefaultBranch = true,
    this.showChecksStatus = true,
    this.showLabels = true,
    this.showCommentCount = true,
    this.showTimestamps = true,
    this.showTimeToResolution = true,
    this.showAuthorAssociation = true,
    this.showNotificationPriority = true,
    this.showActivityPulse = true,
    this.showReleaseScope = false,
    this.showUserActivity = false,
  });

  factory CardDisplaySettings.fromJson(final Map<String, dynamic> json) =>
      CardDisplaySettings(
        density: CardDensity.values.firstWhere(
          (final CardDensity d) => d.name == json['density'],
          orElse: () => CardDensity.comfortable,
        ),
        maxVisibleChips: json['maxVisibleChips'] as int?,
        showBodyPreview: json['showBodyPreview'] as bool? ?? true,
        showReactions: json['showReactions'] as bool? ?? true,
        showProjectChips: json['showProjectChips'] as bool? ?? true,
        showBranchRefs: json['showBranchRefs'] as bool? ?? true,
        showDiffDistribution: json['showDiffDistribution'] as bool? ?? true,
        showReviewerChip: json['showReviewerChip'] as bool? ?? true,
        showTopics: json['showTopics'] as bool? ?? true,
        showRepoLanguage: json['showRepoLanguage'] as bool? ?? true,
        showRepoStats: json['showRepoStats'] as bool? ?? true,
        showDefaultBranch: json['showDefaultBranch'] as bool? ?? true,
        showChecksStatus: json['showChecksStatus'] as bool? ?? true,
        showLabels: json['showLabels'] as bool? ?? true,
        showCommentCount: json['showCommentCount'] as bool? ?? true,
        showTimestamps: json['showTimestamps'] as bool? ?? true,
        showTimeToResolution: json['showTimeToResolution'] as bool? ?? true,
        showAuthorAssociation: json['showAuthorAssociation'] as bool? ?? true,
        showNotificationPriority:
            json['showNotificationPriority'] as bool? ?? true,
        showActivityPulse: json['showActivityPulse'] as bool? ?? true,
        showReleaseScope: json['showReleaseScope'] as bool? ?? false,
        showUserActivity: json['showUserActivity'] as bool? ?? false,
      );

  /// Card density preset (compact/comfortable/detailed).
  final CardDensity density;
  
  /// Maximum visible chips (null = use density default).
  /// When non-null, overrides density preset → shows "Custom" in UI.
  final int? maxVisibleChips;
  
  /// Effective max chips: returns [maxVisibleChips] if set, otherwise density default.
  int get effectiveMaxChips {
    if (maxVisibleChips != null) return maxVisibleChips!;
    return switch (density) {
      CardDensity.compact => 3,
      CardDensity.comfortable => 5,
      CardDensity.detailed => 999,
    };
  }
  
  final bool showBodyPreview;
  final bool showReactions;
  final bool showProjectChips;
  final bool showBranchRefs;
  final bool showDiffDistribution;
  final bool showReviewerChip;
  final bool showTopics;
  final bool showRepoLanguage;
  final bool showRepoStats;
  final bool showDefaultBranch;
  final bool showChecksStatus;
  final bool showLabels;
  final bool showCommentCount;
  final bool showTimestamps;
  final bool showTimeToResolution;
  final bool showAuthorAssociation;
  final bool showNotificationPriority;
  final bool showActivityPulse;
  final bool showReleaseScope;
  final bool showUserActivity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'density': density.name,
        'maxVisibleChips': maxVisibleChips,
        'showBodyPreview': showBodyPreview,
        'showReactions': showReactions,
        'showProjectChips': showProjectChips,
        'showBranchRefs': showBranchRefs,
        'showDiffDistribution': showDiffDistribution,
        'showReviewerChip': showReviewerChip,
        'showTopics': showTopics,
        'showRepoLanguage': showRepoLanguage,
        'showRepoStats': showRepoStats,
        'showDefaultBranch': showDefaultBranch,
        'showChecksStatus': showChecksStatus,
        'showLabels': showLabels,
        'showCommentCount': showCommentCount,
        'showTimestamps': showTimestamps,
        'showTimeToResolution': showTimeToResolution,
        'showAuthorAssociation': showAuthorAssociation,
        'showNotificationPriority': showNotificationPriority,
        'showActivityPulse': showActivityPulse,
        'showReleaseScope': showReleaseScope,
        'showUserActivity': showUserActivity,
      };

  CardDisplaySettings copyWith({
    final CardDensity? density,
    final int? maxVisibleChips,
    final bool? showBodyPreview,
    final bool? showReactions,
    final bool? showProjectChips,
    final bool? showBranchRefs,
    final bool? showDiffDistribution,
    final bool? showReviewerChip,
    final bool? showTopics,
    final bool? showRepoLanguage,
    final bool? showRepoStats,
    final bool? showDefaultBranch,
    final bool? showChecksStatus,
    final bool? showLabels,
    final bool? showCommentCount,
    final bool? showTimestamps,
    final bool? showTimeToResolution,
    final bool? showAuthorAssociation,
    final bool? showNotificationPriority,
    final bool? showActivityPulse,
    final bool? showReleaseScope,
    final bool? showUserActivity,
  }) =>
      CardDisplaySettings(
        density: density ?? this.density,
        maxVisibleChips: maxVisibleChips ?? this.maxVisibleChips,
        showBodyPreview: showBodyPreview ?? this.showBodyPreview,
        showReactions: showReactions ?? this.showReactions,
        showProjectChips: showProjectChips ?? this.showProjectChips,
        showBranchRefs: showBranchRefs ?? this.showBranchRefs,
        showDiffDistribution: showDiffDistribution ?? this.showDiffDistribution,
        showReviewerChip: showReviewerChip ?? this.showReviewerChip,
        showTopics: showTopics ?? this.showTopics,
        showRepoLanguage: showRepoLanguage ?? this.showRepoLanguage,
        showRepoStats: showRepoStats ?? this.showRepoStats,
        showDefaultBranch: showDefaultBranch ?? this.showDefaultBranch,
        showChecksStatus: showChecksStatus ?? this.showChecksStatus,
        showLabels: showLabels ?? this.showLabels,
        showCommentCount: showCommentCount ?? this.showCommentCount,
        showTimestamps: showTimestamps ?? this.showTimestamps,
        showTimeToResolution: showTimeToResolution ?? this.showTimeToResolution,
        showAuthorAssociation:
            showAuthorAssociation ?? this.showAuthorAssociation,
        showNotificationPriority:
            showNotificationPriority ?? this.showNotificationPriority,
        showActivityPulse: showActivityPulse ?? this.showActivityPulse,
        showReleaseScope: showReleaseScope ?? this.showReleaseScope,
        showUserActivity: showUserActivity ?? this.showUserActivity,
      );
}

Map<String, dynamic> _cardDisplayToJson(final CardDisplaySettings v) =>
    v.toJson();

const SettingsDescriptor<CardDisplaySettings> cardDisplayDescriptor =
    SettingsDescriptor<CardDisplaySettings>(
  key: 'app_card_display',
  defaultValue: CardDisplaySettings(),
  fromJson: CardDisplaySettings.fromJson,
  toJson: _cardDisplayToJson,
);
