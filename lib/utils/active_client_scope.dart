import '../media/ids.dart';

/// Returns the user-specific active client scope, or `null` when the client is
/// absent or only exposes the public server namespace.
String? resolveActiveClientScopeId({required ServerId serverId, required String? cacheServerId}) {
  if (cacheServerId == null) return null;
  final userPrefix = '$serverId/';
  if (!cacheServerId.startsWith(userPrefix) || cacheServerId.length == userPrefix.length) return null;
  return cacheServerId;
}
