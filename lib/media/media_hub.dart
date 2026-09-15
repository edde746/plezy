import 'media_item.dart';

/// A named, ordered list of items grouped on the home screen (Plex `Hub`,
/// or a synthesized Jellyfin "Latest"/"Resume"/"NextUp" row).
class MediaHub {
  /// Backend-opaque hub identifier (Plex `key`, synthesized for Jellyfin).
  final String id;

  /// Human-readable hub identifier for analytics and routing — e.g.
  /// `home.continue`, `tv.recentlyadded`. Synthesized for Jellyfin.
  final String? identifier;

  final String title;

  /// Hub kind: `movie`, `show`, `mixed`, `clip`, etc. — drives UI rendering.
  final String type;

  final List<MediaItem> items;

  /// Total number of items the server reports (may exceed [items.length] when
  /// a "see more" affordance is available).
  final int size;

  /// Whether more items are available beyond what's loaded.
  final bool more;

  /// When set, this hub was split from a multi-library hub and should only
  /// show items belonging to this library.
  final String? libraryId;

  final String? serverId;
  final String? serverName;

  const MediaHub({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    this.identifier,
    this.size = 0,
    this.more = false,
    this.libraryId,
    this.serverId,
    this.serverName,
  });

  /// True for hubs that represent the user's resumable Continue Watching row.
  bool get isContinueWatchingHub => _anySemanticKey(_isContinueWatchingKey);

  /// True when selecting an item should honor the Continue Watching action
  /// preference. This is intentionally broader than [isContinueWatchingHub]:
  /// backend "Next Up" rows should use the same activation preference without
  /// inheriting remove-from-Continue-Watching menu semantics.
  bool get usesContinueWatchingAction => isContinueWatchingHub || _anySemanticKey(_usesContinueWatchingActionKey);

  bool _anySemanticKey(bool Function(String key) matches) {
    if (matches(id)) return true;
    final hubIdentifier = identifier;
    return hubIdentifier != null && matches(hubIdentifier);
  }

  MediaHub copyWith({List<MediaItem>? items, int? size}) {
    return MediaHub(
      id: id,
      identifier: identifier,
      title: title,
      type: type,
      items: items ?? this.items,
      size: size ?? this.size,
      more: more,
      libraryId: libraryId,
      serverId: serverId,
      serverName: serverName,
    );
  }
}

// Per-key memo: every card build and D-pad step re-asks these, and the
// answer needs two regex passes over a key. The set of distinct hub keys a
// session sees is small, so the maps stay small too.
final Map<String, bool> _continueWatchingKeys = <String, bool>{};
final Map<String, bool> _continueWatchingActionKeys = <String, bool>{};
final RegExp _hubKeySeparators = RegExp(r'[^a-z0-9]+');

bool _isContinueWatchingKey(String rawKey) => _continueWatchingKeys.putIfAbsent(rawKey, () {
  final compactKey = _compactHubKey(rawKey);
  if (compactKey == 'continuewatching') return true;

  final tokens = _hubKeyTokens(rawKey);
  return tokens.contains('inprogress') || _hasTailToken(tokens, 'continue');
});

bool _usesContinueWatchingActionKey(String rawKey) => _continueWatchingActionKeys.putIfAbsent(rawKey, () {
  final tokens = _hubKeyTokens(rawKey);
  return _hasTailToken(tokens, 'nextup') || tokens.contains('ondeck');
});

List<String> _hubKeyTokens(String rawKey) {
  return rawKey.toLowerCase().split(_hubKeySeparators).where((part) => part.isNotEmpty).toList(growable: false);
}

String _compactHubKey(String rawKey) => rawKey.toLowerCase().replaceAll(_hubKeySeparators, '');

bool _hasTailToken(List<String> tokens, String token) => tokens.isNotEmpty && tokens.last == token;

/// Index of [previous] within [items] after a content refresh, so visual
/// focus can follow the item it was on instead of staying at a stale
/// position (a Continue Watching refresh moves the just-played entry to the
/// front). The exact item wins; an episode that left the list falls back to
/// its series' replacement entry (a finished episode becomes the next
/// episode). Returns -1 when neither is present.
int followItemIndex(List<MediaItem> items, MediaItem previous) {
  final exactIndex = items.indexWhere((item) => item.globalKey == previous.globalKey);
  if (exactIndex != -1) return exactIndex;
  final seriesKey = previous.seriesGlobalKey;
  if (seriesKey == null) return -1;
  return items.indexWhere((item) => item.seriesGlobalKey == seriesKey);
}
