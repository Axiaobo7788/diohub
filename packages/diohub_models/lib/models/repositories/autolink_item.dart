import 'package:freezed_annotation/freezed_annotation.dart';

part 'autolink_item.freezed.dart';
part 'autolink_item.g.dart';

/// One autolink from REST GET /repos/{owner}/{repo}/autolinks.
@freezed
abstract class AutolinkItem with _$AutolinkItem {
  const factory AutolinkItem({
    required int id,
    @JsonKey(name: 'key_prefix') required String keyPrefix,
    @JsonKey(name: 'url_template') required String urlTemplate,
    @JsonKey(name: 'is_alphanumeric') @Default(true) bool isAlphanumeric,
  }) = _AutolinkItem;

  factory AutolinkItem.fromJson(Map<String, dynamic> json) =>
      _$AutolinkItemFromJson(json);
}
