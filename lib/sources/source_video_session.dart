import 'dart:convert';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../services/playback_context.dart';
import 'content_access.dart';
import 'external_video_progress.dart';
import 'source_controller.dart';
import 'source_models.dart';

/// A file-video queue in the existing shared player. Stable metadata and lazy
/// resolvers belong to the queue; each selected file owns its progress/lease.
class SourceVideoSession {
  SourceVideoSession._(this.sources, this.entry, this.files, this.profile, this.generation) {
    items = List.unmodifiable(
      files.map(
        (file) => MediaItem.plex(
          id: 'remote-source:${sourceDigest(jsonEncode([profile, entry.key, file.fingerprint]))}',
          kind: MediaKind.movie,
          title: files.length == 1 ? entry.displayTitle : file.name,
          summary: entry.description,
          year: entry.releaseYear,
          durationMs: file.durationMs,
          thumbPath: entry.onlinePosterUrl,
        ),
      ),
    );
  }

  final SourceController sources;
  final SourceEntry entry;
  final List<PublicationFile> files;
  final String profile;
  final int generation;
  late final List<MediaItem> items;
  final Set<ExternalPlaybackSource> _leases = {};
  bool _closed = false;
  String get contextKey =>
      'source-video:${sourceDigest(jsonEncode([profile, entry.key, files.map((f) => f.fingerprint).toList()]))}';
  bool get valid => !_closed && !sources.blocked && sources.profileId == profile && sources.current(generation);

  static Future<SourceVideoSession> open(
    SourceController sources,
    SourceEntry entry,
    List<PublicationFile> files,
  ) async {
    final profile = sources.profileId, generation = sources.generation;
    await sources.ready;
    sources.requireSession(generation);
    if (profile == null ||
        sources.profileId != profile ||
        files.isEmpty ||
        files.any(
          (file) =>
              file.kind != SourceItemKind.video || !entry.files.any((owned) => owned.fingerprint == file.fingerprint),
        )) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return SourceVideoSession._(sources, entry, List.unmodifiable(files), profile, generation);
  }

  Future<ExternalPlaybackSource> resolve(MediaItem metadata) {
    final index = items.indexWhere((item) => item.globalKey == metadata.globalKey);
    if (index < 0) throw const SourceException(SourceFailure.invalidData);
    return resolveFile(files[index], metadata: metadata);
  }

  Future<ExternalPlaybackSource> resolveFile(
    PublicationFile file, {
    required MediaItem metadata,
    bool trackProgress = true,
  }) async {
    void requireCurrent() {
      if (!valid) throw const SourceException(SourceFailure.cancelled);
    }

    requireCurrent();
    if (!files.any((owned) => owned.fingerprint == file.fingerprint)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    SourceStreamGateway? gateway;
    ExternalVideoProgressSession? progress;
    try {
      // Offline copies must work without hydrating or contacting an account.
      final cached = await sources.downloads.local(profile, entry.sourceId, file);
      requireCurrent();
      late final Uri uri;
      if (cached != null) {
        uri = cached.uri;
      } else {
        final adapter = sources.adapter(entry.sourceId);
        if (adapter.source.kind == FileSourceKind.local) {
          uri = (await adapter.resolve(file)).uri;
        } else if (adapter.source.kind == FileSourceKind.remoteCloud) {
          final lease = await sources.resolveRemoteCloudFile(entry, file);
          requireCurrent();
          gateway = SourceStreamGateway(valid: () => valid);
          uri = await gateway.registerUri(
            lease.uri,
            headers: lease.headers,
            renew: () async {
              requireCurrent();
              final refreshed = await sources.resolveRemoteCloudFile(entry, file);
              requireCurrent();
              return (uri: refreshed.uri, headers: refreshed.headers);
            },
          );
        } else {
          gateway = SourceStreamGateway(valid: () => valid);
          uri = await gateway.register(adapter, file);
        }
      }
      requireCurrent();
      if (trackProgress) progress = await ExternalVideoProgressSession.open(sources, entry, file);
      requireCurrent();
      late final ExternalPlaybackSource result;
      result = ExternalPlaybackSource(
        mediaGlobalKey: metadata.globalKey,
        profileId: profile,
        uri: uri,
        onProgress: progress?.record,
        initialPosition: Duration(milliseconds: progress?.resumePositionMs ?? 0),
        onRelease: () async {
          try {
            await progress?.close();
          } finally {
            await gateway?.close();
            _leases.remove(result);
          }
        },
      );
      _leases.add(result);
      return result;
    } catch (_) {
      try {
        await progress?.close();
      } finally {
        await gateway?.close();
      }
      rethrow;
    }
  }

  Future<void> close() async {
    _closed = true;
    await Future.wait(_leases.toList().map((lease) => lease.release()));
  }
}
