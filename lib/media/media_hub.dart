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

  MediaHub copyWith({
    String? id,
    String? identifier,
    String? title,
    String? type,
    List<MediaItem>? items,
    int? size,
    bool? more,
    String? libraryId,
    String? serverId,
    String? serverName,
  }) {
    return MediaHub(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      type: type ?? this.type,
      items: items ?? this.items,
      size: size ?? this.size,
      more: more ?? this.more,
      libraryId: libraryId ?? this.libraryId,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }
}

bool _isContinueWatchingKey(String rawKey) {
  final compactKey = _compactHubKey(rawKey);
  if (compactKey == 'continuewatching') return true;

  final tokens = _hubKeyTokens(rawKey);
  return tokens.contains('inprogress') || _hasTailToken(tokens, 'continue');
}

bool _usesContinueWatchingActionKey(String rawKey) {
  final tokens = _hubKeyTokens(rawKey);
  return _hasTailToken(tokens, 'nextup') || tokens.contains('ondeck');
}

List<String> _hubKeyTokens(String rawKey) {
  return rawKey.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((part) => part.isNotEmpty).toList(growable: false);
}

String _compactHubKey(String rawKey) => rawKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

bool _hasTailToken(List<String> tokens, String token) => tokens.isNotEmpty && tokens.last == token;
