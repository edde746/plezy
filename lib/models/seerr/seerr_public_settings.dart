import 'package:json_annotation/json_annotation.dart';

part 'seerr_public_settings.g.dart';

/// `GET /settings/public` — unauthenticated instance metadata. The connect
/// flow keys the offered sign-in methods off it; the request sheet keys the
/// 4K toggle and per-season selection off it.
@JsonSerializable(createToJson: false)
class SeerrPublicSettings {
  final bool initialized;
  final String? applicationTitle;

  /// Whether `/auth/local` is enabled.
  final bool localLogin;

  /// Whether signing in through the linked media server is enabled.
  final bool mediaServerLogin;

  /// `SeerrMediaServerType` of the linked media server.
  final int? mediaServerType;

  final bool movie4kEnabled;
  final bool series4kEnabled;

  /// Whether users may request individual seasons rather than whole shows.
  final bool partialRequestsEnabled;

  const SeerrPublicSettings({
    this.initialized = false,
    this.applicationTitle,
    this.localLogin = true,
    this.mediaServerLogin = true,
    this.mediaServerType,
    this.movie4kEnabled = false,
    this.series4kEnabled = false,
    this.partialRequestsEnabled = true,
  });

  String get instanceLabel => (applicationTitle?.isNotEmpty ?? false) ? applicationTitle! : 'Seerr';

  factory SeerrPublicSettings.fromJson(Map<String, dynamic> json) => _$SeerrPublicSettingsFromJson(json);
}
