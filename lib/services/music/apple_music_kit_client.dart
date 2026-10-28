import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppleMusicSong {
  const AppleMusicSong({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;

  factory AppleMusicSong.fromMap(Map<String, Object?> value) {
    final id = value['id'];
    final title = value['title'];
    final artist = value['artist'];
    final album = value['album'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 128 ||
        title is! String ||
        title.trim().isEmpty ||
        artist is! String ||
        artist.trim().isEmpty) {
      throw const FormatException('Invalid Apple Music result');
    }
    return AppleMusicSong(
      id: id,
      title: title.trim(),
      artist: artist.trim(),
      album: album is String && album.trim().isNotEmpty ? album.trim() : null,
    );
  }
}

/// iOS-only MusicKit pilot. Catalog search is explicit and playback is handed
/// to Apple's native ApplicationMusicPlayer; this never downloads Apple files.
class AppleMusicKitClient {
  AppleMusicKitClient({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('com.plezy/apple_music_kit');

  static const enabled = bool.fromEnvironment('ENABLE_APPLE_MUSICKIT', defaultValue: false);

  final MethodChannel _channel;

  bool get isAvailable => enabled && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> requestAuthorization() async {
    _requireAvailable();
    final status = await _call<String>('requestAuthorization');
    return status == 'authorized';
  }

  Future<List<AppleMusicSong>> search(String query) async {
    _requireAvailable();
    final term = query.trim();
    if (term.isEmpty || term.length > 160) return const [];
    final rows = await _channel.invokeListMethod<Object?>('search', {'query': term});
    return List.unmodifiable([
      for (final raw in rows ?? const [])
        if (raw is Map) AppleMusicSong.fromMap(Map<String, Object?>.from(raw)),
    ]);
  }

  Future<bool> canPlayCatalogContent() async {
    _requireAvailable();
    return await _call<bool>('canPlayCatalogContent') ?? false;
  }

  Future<void> play(AppleMusicSong song) async {
    _requireAvailable();
    await _channel.invokeMethod<void>('play', {'id': song.id});
  }

  Future<void> stop() async {
    _requireAvailable();
    await _channel.invokeMethod<void>('stop');
  }

  void _requireAvailable() {
    if (!isAvailable) throw const AppleMusicKitException('UNAVAILABLE');
  }

  Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException catch (error) {
      throw AppleMusicKitException(error.code);
    }
  }
}

class AppleMusicKitException implements Exception {
  const AppleMusicKitException(this.code);
  final String code;
}
