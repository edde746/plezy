import '../media/ids.dart';
import '../media/media_server_client.dart';

/// A stable reference to *whichever* client currently serves [serverId].
///
/// ### Why this exists
///
/// A client instance is a socket, and sockets get replaced: a rebind, a
/// reconnect, a changed base URL. Anything holding the instance across that
/// swap is holding a corpse — its next request fails with "Client disposed",
/// which the UI reports as being unable to reach the media server. Two rebinds
/// racing at startup produced exactly that.
///
/// The server *identity* is stable even when the socket is not, so that is what
/// callers keep. Resolution happens at the moment of use, which is the only
/// moment at which the answer is known to be current.
///
/// ### What it deliberately does not do
///
/// It does not cache, reconnect or retry. It is a lookup, and making it more
/// than that would put a second lifecycle beside the one [MediaServerRegistry]
/// already owns — which is the mistake it exists to correct.
class ServerHandle {
  /// Private-named formal: callers pass `registry:`.
  const ServerHandle({required this.serverId, required this._registry});

  final String serverId;
  final MediaServerRegistry _registry;

  /// The live client, or null when this server is not currently bound.
  ///
  /// Re-read it on each use rather than storing it. Holding the result across
  /// an `await` reintroduces precisely the bug this type prevents.
  MediaServerClient? get client => _registry.getClient(ServerId(serverId));

  @override
  String toString() => 'ServerHandle($serverId)';
}

/// The lookup a [ServerHandle] resolves through.
///
/// Narrow on purpose: handles need one method, and depending on the whole
/// server manager would make every holder of a handle un-fakeable in a test.
abstract class MediaServerRegistry {
  MediaServerClient? getClient(ServerId serverId);
}
