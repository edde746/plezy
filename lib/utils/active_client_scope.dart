import '../media/ids.dart';

const _plexProfileScopeMarker = '/~plex-profile/';

const _plexTransferScopeSuffix = '/~plex-transfer';

/// Typed private cache namespace for one Plezy profile on a public Plex
/// server. The value is never a public media identity.
extension type const PlexProfileScopeId._(String value) implements String {
  factory PlexProfileScopeId({required ServerId serverId, required String profileId}) {
    if (profileId.isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'must not be empty');
    }
    return PlexProfileScopeId._('$serverId$_plexProfileScopeMarker${Uri.encodeComponent(profileId)}');
  }

  static PlexProfileScopeId? tryParse(String value) {
    final markerIndex = value.indexOf(_plexProfileScopeMarker);
    if (markerIndex <= 0) return null;
    final serverId = ServerId.tryParse(value.substring(0, markerIndex));
    if (serverId == null) return null;
    final encodedProfileId = value.substring(markerIndex + _plexProfileScopeMarker.length);
    if (encodedProfileId.isEmpty || encodedProfileId.contains('/')) return null;
    try {
      if (Uri.decodeComponent(encodedProfileId).isEmpty) return null;
    } on FormatException {
      return null;
    }
    return PlexProfileScopeId._(value);
  }

  ServerId get publicServerId => ServerId(value.substring(0, value.indexOf(_plexProfileScopeMarker)));
  String get profileId =>
      Uri.decodeComponent(value.substring(value.indexOf(_plexProfileScopeMarker) + _plexProfileScopeMarker.length));
  ServerId get cacheServerId => ServerId(value);
}

/// Device-local namespace used only while a full logout has no profile owner.
///
/// Metadata copied here is stripped of profile-private watch/rating fields.
/// The next profile that adopts the physical download moves it into its own
/// [PlexProfileScopeId] before exposing it.
extension type const PlexTransferScopeId._(String value) implements String {
  factory PlexTransferScopeId(ServerId serverId) => PlexTransferScopeId._('$serverId$_plexTransferScopeSuffix');

  static PlexTransferScopeId? tryParse(String value) {
    if (!value.endsWith(_plexTransferScopeSuffix)) return null;
    final serverId = ServerId.tryParse(value.substring(0, value.length - _plexTransferScopeSuffix.length));
    return serverId == null ? null : PlexTransferScopeId._(value);
  }

  ServerId get publicServerId => ServerId(value.substring(0, value.length - _plexTransferScopeSuffix.length));
  ServerId get cacheServerId => ServerId(value);
}

PlexTransferScopeId buildPlexTransferScopeId(ServerId serverId) => PlexTransferScopeId(serverId);

PlexProfileScopeId buildPlexProfileScopeId({required ServerId serverId, required String profileId}) =>
    PlexProfileScopeId(serverId: serverId, profileId: profileId);

ServerId? publicPlexServerIdFromScope(String cacheServerId) =>
    PlexProfileScopeId.tryParse(cacheServerId)?.publicServerId;

ServerId? publicPlexServerIdFromCacheScope(String cacheServerId) =>
    publicPlexServerIdFromScope(cacheServerId) ?? PlexTransferScopeId.tryParse(cacheServerId)?.publicServerId;

bool isPlexProfileScopeId(String cacheServerId) => PlexProfileScopeId.tryParse(cacheServerId) != null;

/// Jellyfin's established scope is `{machineId}/{userId}`. The reserved Plex
/// namespaces are deliberately excluded so the backends cannot alias.
bool isJellyfinUserScopeId({required ServerId serverId, required String cacheServerId}) {
  final userPrefix = '$serverId/';
  return cacheServerId.startsWith(userPrefix) &&
      cacheServerId.length > userPrefix.length &&
      !isPlexProfileScopeId(cacheServerId) &&
      PlexTransferScopeId.tryParse(cacheServerId) == null;
}

/// Returns the user-specific active client scope, or `null` when the client is
/// absent or only exposes the public server namespace.
String? resolveActiveClientScopeId({required ServerId serverId, required String? cacheServerId}) {
  if (cacheServerId == null) return null;
  final plexScope = PlexProfileScopeId.tryParse(cacheServerId);
  if (plexScope != null) return plexScope.publicServerId == serverId ? plexScope : null;
  if (PlexTransferScopeId.tryParse(cacheServerId) != null) return null;
  return isJellyfinUserScopeId(serverId: serverId, cacheServerId: cacheServerId) ? cacheServerId : null;
}
