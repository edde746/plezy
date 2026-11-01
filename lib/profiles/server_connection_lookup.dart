import '../connection/connection.dart';
import 'profile_connection.dart';

/// Resolve the Jellyfin connection that hosts a Bonfire virtual profile.
///
/// Bonfire household entries — and therefore virtual profile ids and join
/// rows — are keyed by the server's *machine* id so they stay
/// caller-independent (switching A -> B -> C must not mint new profile ids).
/// But the connection row that actually hosts them is usually the compound
/// `machineId/userId` row created at sign-in (upstream keys Jellyfin
/// connections that way), so a direct map lookup on the machine id can miss.
/// Try the direct id first (covers raw-id rows and legacy compound ids
/// stored before machine-keying), then fall back to the shortest connection
/// id serving that machine — the raw-most login row.
JellyfinConnection? jellyfinConnectionForServerId(Map<String, Connection> connectionsById, String parentId) {
  if (connectionsById[parentId] case final JellyfinConnection direct) return direct;
  JellyfinConnection? best;
  for (final c in connectionsById.values) {
    if (c is! JellyfinConnection) continue;
    if (c.serverMachineId != parentId) continue;
    if (best == null || c.id.length < best.id.length) best = c;
  }
  return best;
}

/// Whether a `profile_connections` row belongs to a virtual profile's parent
/// connection rather than being a borrowed row on another server.
///
/// Bonfire rows are written with the parent connection's persisted row id
/// (the FK target), while the profile's `parentConnectionId` carries the
/// canonical machine id — and rows written before that split may carry the
/// machine id or a compound host id directly. Accept any shape that resolves
/// to the same host connection; everything else is a borrow.
bool joinRowBelongsToParent(
  ProfileConnection row, {
  required String parentConnectionId,
  Connection? parentConnection,
  required Map<String, Connection> connectionsById,
}) {
  if (parentConnection != null && row.connectionId == parentConnection.id) return true;
  if (row.connectionId == parentConnectionId) return true;
  if (jellyfinConnectionForServerId(connectionsById, row.connectionId)
          case final JellyfinConnection resolved) {
    return resolved.serverMachineId == parentConnectionId || resolved.id == parentConnection?.id;
  }
  return false;
}
