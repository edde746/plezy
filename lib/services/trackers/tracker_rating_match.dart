import '../../utils/json_utils.dart';

/// Shared id-matching helpers for the Trakt/Simkl rating sources, which both
/// scan a list of remote rating entries and match them against local ids.

/// Extract the nested `ids` map from a rating entry's media object (e.g. the
/// `movie`/`show` node), normalized to `Map<String, dynamic>`.
Map<String, dynamic>? trackerNestedIds(Object? value) {
  if (value is! Map) return null;
  final ids = value['ids'];
  return ids is Map ? ids.cast<String, dynamic>() : null;
}

/// True when any local id matches a remote id by string or integer value.
bool trackerIdsMatch(Map<String, dynamic>? remoteIds, Map<String, Object?> localIds) {
  if (remoteIds == null) return false;
  for (final entry in localIds.entries) {
    final local = entry.value;
    if (local == null) continue;
    final remote = remoteIds[entry.key];
    if (remote == null) continue;
    if (local is String && remote.toString() == local) return true;
    final remoteInt = flexibleInt(remote);
    final localInt = flexibleInt(local);
    if (remoteInt != null && localInt != null && remoteInt == localInt) return true;
  }
  return false;
}
