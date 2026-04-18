/// Sealed class representing all notification types in the app.
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

@freezed
sealed class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification.success({
    required String message,
    @Default(Icons.check_circle_outline_rounded) IconData? icon,
    @Default(Duration(seconds: 2)) Duration duration,
    VoidCallback? onTap,
  }) = SuccessNotification;

  const factory AppNotification.error({
    required String message,
    @Default(Icons.error_outline_rounded) IconData? icon,
    @Default(Duration(seconds: 4)) Duration duration,
    VoidCallback? retryAction,
  }) = ErrorNotification;

  const factory AppNotification.undo({
    required String message,
    required VoidCallback onUndo,
    @Default(Icons.undo_rounded) IconData? icon,
    @Default(Duration(seconds: 5)) Duration duration,
  }) = UndoNotification;

  const factory AppNotification.progress({
    required String message,
    @Default(Icons.sync_rounded) IconData? icon,
    @Default(Duration(seconds: 30)) Duration duration,
    double? progress,
  }) = ProgressNotification;
}
