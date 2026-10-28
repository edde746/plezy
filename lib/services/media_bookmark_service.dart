import 'package:uuid/uuid.dart';

import '../models/media_bookmark.dart';
import 'settings_service.dart';

class MediaBookmarkLimitException implements Exception {
  const MediaBookmarkLimitException();
}

/// Persists named timeline marks locally, keyed by a server media identity or
/// a one-way digest for transient local and direct media. These marks never
/// alter server watch progress.
class MediaBookmarkService {
  static const maxBookmarksPerItem = 100;
  static final _uuid = Uuid();
  static Future<void> _writeQueue = Future<void>.value();

  static List<MediaBookmark> forMedia(String mediaKey) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return const [];
    return List.unmodifiable(settings.read(SettingsService.mediaBookmarks)[mediaKey] ?? const []);
  }

  static Future<MediaBookmark> add(String mediaKey, String label, int positionMs) async {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty || normalizedLabel.length > 80 || positionMs < 0) {
      throw ArgumentError('Invalid media bookmark');
    }
    late MediaBookmark added;
    await _serialize(() async {
      final settings = SettingsService.instanceOrNull;
      if (settings == null) throw StateError('Settings are not ready');
      final bookmarks = settings.read(SettingsService.mediaBookmarks);
      final current = bookmarks[mediaKey] ?? const <MediaBookmark>[];
      if (current.length >= maxBookmarksPerItem) throw const MediaBookmarkLimitException();
      added = MediaBookmark(
        id: _uuid.v4(),
        label: normalizedLabel,
        positionMs: positionMs,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await settings.write(SettingsService.mediaBookmarks, {
        ...bookmarks,
        mediaKey: [...current, added],
      });
    });
    return added;
  }

  static Future<void> remove(String mediaKey, String bookmarkId) => _serialize(() async {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) throw StateError('Settings are not ready');
    final bookmarks = settings.read(SettingsService.mediaBookmarks);
    final current = bookmarks[mediaKey] ?? const <MediaBookmark>[];
    final updated = current.where((bookmark) => bookmark.id != bookmarkId).toList(growable: false);
    final values = Map<String, List<MediaBookmark>>.of(bookmarks);
    if (updated.isEmpty) {
      values.remove(mediaKey);
    } else {
      values[mediaKey] = updated;
    }
    await settings.write(SettingsService.mediaBookmarks, values);
  });

  static Future<void> _serialize(Future<void> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}
