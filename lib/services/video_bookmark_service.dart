import 'package:uuid/uuid.dart';

import '../models/video_bookmark.dart';
import 'settings_service.dart';

class VideoBookmarkLimitException implements Exception {
  const VideoBookmarkLimitException();
}

/// Persists named timeline marks locally, keyed by the media server's stable
/// cross-server item identity. These marks never alter server watch progress.
class VideoBookmarkService {
  static const maxBookmarksPerItem = 100;
  static final _uuid = Uuid();
  static Future<void> _writeQueue = Future<void>.value();

  static List<VideoBookmark> forMedia(String mediaKey) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return const [];
    return List.unmodifiable(settings.read(SettingsService.videoBookmarks)[mediaKey] ?? const []);
  }

  static Future<VideoBookmark> add(String mediaKey, String label, int positionMs) async {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty || normalizedLabel.length > 80 || positionMs < 0) {
      throw ArgumentError('Invalid video bookmark');
    }
    late VideoBookmark added;
    await _serialize(() async {
      final settings = SettingsService.instanceOrNull;
      if (settings == null) throw StateError('Settings are not ready');
      final bookmarks = settings.read(SettingsService.videoBookmarks);
      final current = bookmarks[mediaKey] ?? const <VideoBookmark>[];
      if (current.length >= maxBookmarksPerItem) throw const VideoBookmarkLimitException();
      added = VideoBookmark(
        id: _uuid.v4(),
        label: normalizedLabel,
        positionMs: positionMs,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await settings.write(SettingsService.videoBookmarks, {
        ...bookmarks,
        mediaKey: [...current, added],
      });
    });
    return added;
  }

  static Future<void> remove(String mediaKey, String bookmarkId) => _serialize(() async {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) throw StateError('Settings are not ready');
    final bookmarks = settings.read(SettingsService.videoBookmarks);
    final current = bookmarks[mediaKey] ?? const <VideoBookmark>[];
    final updated = current.where((bookmark) => bookmark.id != bookmarkId).toList(growable: false);
    final values = Map<String, List<VideoBookmark>>.of(bookmarks);
    if (updated.isEmpty) {
      values.remove(mediaKey);
    } else {
      values[mediaKey] = updated;
    }
    await settings.write(SettingsService.videoBookmarks, values);
  });

  static Future<void> _serialize(Future<void> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}
