import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_item.freezed.dart';
part 'email_item.g.dart';

/// Single email address from GET /user/emails.
@freezed
abstract class EmailItem with _$EmailItem {
  const factory EmailItem({
    required String email,
    @Default(false) bool primary,
    @Default(false) bool verified,
    String? visibility,
  }) = _EmailItem;

  factory EmailItem.fromJson(Map<String, dynamic> json) =>
      _$EmailItemFromJson(json);
}
