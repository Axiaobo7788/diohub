import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread_subscription.freezed.dart';
part 'thread_subscription.g.dart';

@freezed
abstract class ThreadSubscription with _$ThreadSubscription {
  const factory ThreadSubscription({
    @Default(false) bool subscribed,
    @Default(false) bool ignored,
    String? reason,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ThreadSubscription;

  factory ThreadSubscription.fromJson(Map<String, dynamic> json) =>
      _$ThreadSubscriptionFromJson(json);
}
