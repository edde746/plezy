import 'dart:async';
import 'dart:convert';

import 'package:plezy/connection/connection.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant_client.dart';

/// An error reply (`error_code` / `details`) instead of a result.
class MaErrorReply {
  final int code;
  final String details;

  const MaErrorReply(this.code, [this.details = 'error']);
}

/// In-memory Music Assistant, standing in for the WebSocket.
///
/// Auto-answers every command through [responder] so tests read as
/// "given these server answers, assert on the requests and the mapped result"
/// rather than as frame choreography.
class FakeMaServer implements MaChannel {
  final _incoming = StreamController<dynamic>.broadcast();

  /// Every request frame the client sent, in order.
  final List<Map<String, dynamic>> requests = [];

  Object? Function(String command, Map<String, dynamic> args) responder;

  FakeMaServer({Object? Function(String command, Map<String, dynamic> args)? responder})
    : responder = responder ?? ((_, _) => const <dynamic>[]) {
    // The greeting is unsolicited and arrives before any command.
    _incoming.onListen = () => scheduleMicrotask(
      () => _incoming.add(
        jsonEncode({
          'server_id': 'fe2f5b6fd78e4608bb8b075a6c269fbf',
          'server_version': '2.6.3',
          'schema_version': 26,
          'min_supported_schema_version': 24,
          'base_url': 'http://10.0.2.107:8095',
        }),
      ),
    );
  }

  Future<MaChannel> open(Uri url) async => this;

  /// Commands sent so far, in order.
  List<String> get commands => [for (final request in requests) request['command'] as String];

  /// Arguments of the last request for [command].
  Map<String, dynamic> argsFor(String command) {
    final match = requests.lastWhere((request) => request['command'] == command);
    return (match['args'] as Map<String, dynamic>?) ?? const {};
  }

  int countOf(String command) => commands.where((sent) => sent == command).length;

  /// Push an unsolicited event frame, as the server does for `builtin_player`,
  /// `queue_updated` and friends. Events carry no `message_id`, which is the
  /// only thing that distinguishes them from a reply.
  void pushEvent(Map<String, dynamic> frame) {
    if (_incoming.isClosed) return;
    _incoming.add(jsonEncode(frame));
  }

  /// When set, the queue commands echo the `builtin_player` events a live
  /// server sends for this player id.
  ///
  /// Measured against 2.6.3 with a flow stream genuinely open and being
  /// consumed, which is the only state in which there is anything to tear down:
  ///
  /// - `player_queues/play_media` with `option: replace` → `stop`, `play_media`
  /// - `player_queues/play_index`                        → `play_media`
  ///
  /// The asymmetry is the whole reason `expectQueueReplacement()` guards one
  /// branch and not the other, so a fake that stays silent lets a test "prove"
  /// either arrangement. An earlier version of this file did exactly that.
  String? echoQueueEventsForPlayerId;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  /// Accept commands and answer none of them, which is what a wedged 2.6.3
  /// looks like from here: the socket stays open and the greeting already
  /// happened, so nothing about the connection says anything is wrong.
  bool wedged = false;

  @override
  void send(String message) {
    final frame = jsonDecode(message) as Map<String, dynamic>;
    requests.add(frame);
    if (wedged) return;
    scheduleMicrotask(() {
      if (_incoming.isClosed) return;
      final command = frame['command'] as String;
      final reply = responder(command, (frame['args'] as Map<String, dynamic>?) ?? const {});
      _incoming.add(
        jsonEncode(
          reply is MaErrorReply
              ? {'message_id': frame['message_id'], 'error_code': reply.code, 'details': reply.details}
              : {'message_id': frame['message_id'], 'result': reply, 'partial': false},
        ),
      );
      _echoQueueEvents(command);
    });
  }

  void _echoQueueEvents(String command) {
    final playerId = echoQueueEventsForPlayerId;
    if (playerId == null) return;
    final types = switch (command) {
      'player_queues/play_media' => const ['stop', 'play_media'],
      'player_queues/play_index' => const ['play_media'],
      _ => const <String>[],
    };
    for (final type in types) {
      pushEvent({
        'event': 'builtin_player',
        'object_id': playerId,
        'data': {'type': type, 'media_url': 'builtin_player/flow/$playerId.mp3'},
      });
    }
  }

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

/// A server-side player queue, modelled closely enough to lie the way 2.6.3
/// lies.
///
/// The point of this is what it lets a test *express*. A fake that only records
/// the commands it was sent can never disagree with the client, so every
/// assertion about "the server holds the queue we pushed" holds by construction
/// — which is how a client that jumped into somebody else's queue passed its
/// tests. These behaviours are all verified against 2.6.3 and are all silent:
///
/// * `replace_next` keeps every item **before** the current one, so the queue
///   grows a prefix the client never sent.
/// * `play_media` skips uris it cannot resolve and still answers `result:
///   null` — a three-uri push becoming a one-item queue.
/// * `play_index` past the end is accepted, sets `current_index` out of range
///   and goes idle.
/// * `player_queues/items` for a queue that does not exist answers `[]` rather
///   than an error.
class FakeMaQueue {
  FakeMaQueue({this.unresolvableUris = const {}});

  /// Uris this server cannot resolve, dropped from any push in silence.
  final Set<String> unresolvableUris;

  final List<String> items = [];
  int currentIndex = 0;

  /// Whatever another controller did to this queue — the Music Assistant web
  /// UI, a second phone — with no involvement from the client under test.
  void replacedByAnotherController(List<String> uris) {
    items
      ..clear()
      ..addAll(uris);
    currentIndex = 0;
  }

  String? get currentUri => currentIndex >= 0 && currentIndex < items.length ? items[currentIndex] : null;
}

/// Answers the `player_queues/*` commands out of real [FakeMaQueue] state.
///
/// Install with `server.responder = FakeMaQueues(...).respond;`. Commands it
/// does not know fall through to [fallback].
class FakeMaQueues {
  FakeMaQueues({Map<String, FakeMaQueue>? queues, this.fallback}) : queues = queues ?? {};

  final Map<String, FakeMaQueue> queues;
  final Object? Function(String command, Map<String, dynamic> args)? fallback;

  /// `queue_id` is the builtin player id, and a queue springs into existence
  /// the first time something is pushed to it.
  FakeMaQueue of(String queueId) => queues.putIfAbsent(queueId, FakeMaQueue.new);

  Object? respond(String command, Map<String, dynamic> args) {
    final queueId = args['queue_id']?.toString();
    switch (command) {
      case 'player_queues/play_media':
        final queue = of(queueId!);
        final media = [for (final uri in (args['media'] as List? ?? const [])) uri.toString()];
        final playable = [
          for (final uri in media)
            if (!queue.unresolvableUris.contains(uri)) uri,
        ];
        if (playable.isEmpty) return const MaErrorReply(2, 'No playable items found');
        if (args['option'] == 'replace_next') {
          // The prefix survives — the whole of Finding A.
          final keep = queue.items.take(queue.currentIndex + 1).toList();
          queue.items
            ..clear()
            ..addAll([...keep, ...playable]);
        } else {
          queue.items
            ..clear()
            ..addAll(playable);
          queue.currentIndex = 0;
        }
        return null;
      case 'player_queues/play_index':
        // No bounds check, exactly like the server: an out-of-range jump is
        // accepted and simply plays nothing.
        of(queueId!).currentIndex = (args['index'] as num).toInt();
        return null;
      case 'player_queues/items':
        final queue = queues[queueId];
        if (queue == null) return const <dynamic>[];
        final offset = (args['offset'] as num?)?.toInt() ?? 0;
        final limit = (args['limit'] as num?)?.toInt() ?? queue.items.length;
        return [
          for (final uri in queue.items.skip(offset).take(limit))
            {
              'queue_id': queueId,
              'queue_item_id': 'qi-$uri',
              'name': uri,
              'media_item': {'uri': uri, 'media_type': 'track'},
            },
        ];
      case 'player_queues/get':
        final queue = queues[queueId];
        if (queue == null) return null;
        return {
          'queue_id': queueId,
          'items': queue.items.length,
          'current_index': queue.currentIndex,
          'current_item': queue.currentUri == null
              ? <String, dynamic>{}
              : {
                  'name': queue.currentUri,
                  'media_item': {'uri': queue.currentUri, 'media_type': 'track'},
                },
        };
    }
    return fallback?.call(command, args) ?? const <dynamic>[];
  }
}

/// A connected [MusicAssistantClient] backed by [server].
Future<MusicAssistantClient> connectedClient(
  FakeMaServer server, {
  String displayName = 'Basement NAS',

  /// Defaults short so ordinary tests fail fast. Pass the production value
  /// when the point of the test is a budget *shorter* than this one — with
  /// both at five seconds, a missing timeout is indistinguishable from a
  /// working one.
  Duration requestTimeout = const Duration(seconds: 5),
}) async {
  final connection = MusicAssistantConnection(
    id: 'ma-1',
    displayName: displayName,
    baseUrl: 'http://10.0.2.107:8095',
    createdAt: DateTime.utc(2026),
  );
  return MusicAssistantClient.create(
    connection,
    api: MusicAssistantApi(
      channelFactory: server.open,
      requestTimeout: requestTimeout,
      handshakeTimeout: const Duration(seconds: 2),
      autoReconnect: false,
    ),
  );
}

/// A `library_items` row, close enough to the live shape to exercise mapping.
Map<String, dynamic> maAlbum(String itemId, {String? name, bool favorite = false, int? year = 2011}) => {
  'item_id': itemId,
  'provider': 'library',
  'name': name ?? 'Album $itemId',
  'sort_name': (name ?? 'Album $itemId').toLowerCase(),
  'uri': 'library://album/$itemId',
  'media_type': 'album',
  'favorite': favorite,
  'year': year,
  'artists': [
    {
      'item_id': '46',
      'provider': 'library',
      'name': 'Ed Sheeran',
      'uri': 'library://artist/46',
      'media_type': 'artist',
      'image': null,
    },
  ],
  'metadata': {
    'images': [
      {'type': 'thumb', 'path': 'al-$itemId', 'provider': 'opensubsonic--pu5hhsYV', 'remotely_accessible': false},
    ],
  },
};

Map<String, dynamic> maArtist(String itemId, {String? name}) => {
  'item_id': itemId,
  'provider': 'library',
  'name': name ?? 'Artist $itemId',
  'sort_name': (name ?? 'Artist $itemId').toLowerCase(),
  'uri': 'library://artist/$itemId',
  'media_type': 'artist',
};

Map<String, dynamic> maTrack(String itemId, {String? name, int? trackNumber = 9, int? discNumber = 1}) => {
  'item_id': itemId,
  'provider': 'library',
  'name': name ?? 'Track $itemId',
  'sort_name': (name ?? 'Track $itemId').toLowerCase(),
  'uri': 'library://track/$itemId',
  'media_type': 'track',
  'duration': 21,
  'track_number': trackNumber,
  'disc_number': discNumber,
  'artists': [
    {
      'item_id': '36',
      'provider': 'library',
      'name': 'Coldplay',
      'uri': 'library://artist/36',
      'media_type': 'artist',
      'image': null,
    },
  ],
  'album': {
    'item_id': '7058',
    'provider': 'library',
    'name': 'Music of the Spheres',
    'uri': 'library://album/7058',
    'media_type': 'album',
    'image': {'path': 'al-7058', 'provider': 'opensubsonic--pu5hhsYV'},
  },
};
