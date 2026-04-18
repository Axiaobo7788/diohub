import 'package:drift/drift.dart';

/// Miscellaneous app-level metadata (key-value).
/// Replaces: OnboardingSettings, StartupFlowsSettings, SharedPrefs for IAP/account.
/// Keys: iap_max_tier, active_account, theme_mode.
class AppMetaEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
