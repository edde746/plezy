import 'package:json_annotation/json_annotation.dart';

/// Mixin that provides multi-server support fields for models.
///
/// This mixin adds serverId and serverName fields that are excluded from
/// JSON serialization but can be used to track which server an item belongs to.
mixin MultiServerFields {
  /// Server machine identifier (not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get serverId;

  /// Server display name (not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get serverName;
}
