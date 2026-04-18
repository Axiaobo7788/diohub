import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory settings for terminal and workflow log viewer.
class TerminalSettings {
  const TerminalSettings({
    this.logPollingIntervalSeconds = 5,
    this.logAutoScroll = true,
    this.terminalFontSizeDelta = 0,
    this.terminalMaxScrollback = 10000,
  });

  final int logPollingIntervalSeconds;
  final bool logAutoScroll;
  final int terminalFontSizeDelta;
  final int terminalMaxScrollback;

  TerminalSettings copyWith({
    int? logPollingIntervalSeconds,
    bool? logAutoScroll,
    int? terminalFontSizeDelta,
    int? terminalMaxScrollback,
  }) =>
      TerminalSettings(
        logPollingIntervalSeconds:
            logPollingIntervalSeconds ?? this.logPollingIntervalSeconds,
        logAutoScroll: logAutoScroll ?? this.logAutoScroll,
        terminalFontSizeDelta:
            terminalFontSizeDelta ?? this.terminalFontSizeDelta,
        terminalMaxScrollback:
            terminalMaxScrollback ?? this.terminalMaxScrollback,
      );
}

final terminalSettingsProvider =
    NotifierProvider<TerminalSettingsNotifier, TerminalSettings>(
  TerminalSettingsNotifier.new,
);

class TerminalSettingsNotifier extends Notifier<TerminalSettings> {
  @override
  TerminalSettings build() => const TerminalSettings();

  void setLogPollingIntervalSeconds(final int value) {
    state = state.copyWith(
      logPollingIntervalSeconds: value.clamp(2, 30),
    );
  }

  void setLogAutoScroll(final bool value) {
    state = state.copyWith(logAutoScroll: value);
  }

  void setTerminalFontSizeDelta(final int value) {
    state = state.copyWith(terminalFontSizeDelta: value);
  }

  void setTerminalMaxScrollback(final int value) {
    state = state.copyWith(
      terminalMaxScrollback: value.clamp(1000, 100000),
    );
  }
}
