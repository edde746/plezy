import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_backend.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import '../models/transcode_quality_preset.dart';
import '../media/episode_collection.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/media_version_resolver.dart';
import '../utils/quality_preset_labels.dart';
import '../i18n/strings.g.dart';

/// Configuration for download version selection, threaded through the queue pipeline.
class DownloadVersionConfig {
  final int mediaIndex;
  final TranscodeQualityPreset quality;
  final Set<String> acceptedSignatures;
  final Future<int?> Function(MediaItem episode, List<MediaVersion> versions)? onVersionMismatch;

  DownloadVersionConfig({
    this.mediaIndex = 0,
    this.quality = TranscodeQualityPreset.original,
    Set<String>? acceptedSignatures,
    this.onVersionMismatch,
  }) : acceptedSignatures = acceptedSignatures ?? {};

  /// Create from a selected version's signature.
  factory DownloadVersionConfig.fromSignature(
    String signature, {
    int mediaIndex = 0,
    TranscodeQualityPreset quality = TranscodeQualityPreset.original,
    Future<int?> Function(MediaItem, List<MediaVersion>)? onVersionMismatch,
  }) {
    return DownloadVersionConfig(
      mediaIndex: mediaIndex,
      quality: quality,
      acceptedSignatures: {signature},
      onVersionMismatch: onVersionMismatch,
    );
  }
}

/// Resolve source version and download quality. Only Plex video downloads
/// support server-prepared copies; other backends and music keep the original.
/// Pass [quality] to preserve an existing download's choice when retrying.
/// Returns null if the user cancels, or a config with the selection.
Future<DownloadVersionConfig?> resolveDownloadVersion(
  BuildContext context,
  MediaItem metadata,
  MediaServerClient client, {
  List<MediaVersion>? fallbackVersions,
  TranscodeQualityPreset? quality,
}) async {
  final config = await _resolveSourceVersion(context, metadata, client, fallbackVersions: fallbackVersions);
  if (config == null || !context.mounted) return null;
  if (client.backend != MediaBackend.plex ||
      !const {MediaKind.movie, MediaKind.episode, MediaKind.show, MediaKind.season}.contains(metadata.kind)) {
    return config;
  }

  final selectedQuality =
      quality ??
      await showQualityPickerDialog(
        context,
        title: t.downloads.selectQuality,
        description: t.downloads.preparationBackgroundHint,
      );
  if (selectedQuality == null || !context.mounted) return null;
  return DownloadVersionConfig(
    mediaIndex: config.mediaIndex,
    quality: selectedQuality,
    acceptedSignatures: config.acceptedSignatures,
    onVersionMismatch: config.onVersionMismatch,
  );
}

Future<DownloadVersionConfig?> _resolveSourceVersion(
  BuildContext context,
  MediaItem metadata,
  MediaServerClient client, {
  List<MediaVersion>? fallbackVersions,
}) async {
  final kind = metadata.kind;

  if (kind == MediaKind.movie || kind == MediaKind.episode) {
    final versions = await resolveMediaVersions(metadata, client, fallbackVersions: fallbackVersions);
    if (!context.mounted) return null;
    if (versions.length > 1) {
      final selectedIndex = await showVersionPickerDialog(context, versions, t.downloads.selectVersion);
      if (selectedIndex == null || !context.mounted) return null;
      return DownloadVersionConfig(mediaIndex: selectedIndex);
    }
    return DownloadVersionConfig();
  }

  if (kind == MediaKind.show || kind == MediaKind.season) {
    final versions = await fetchRepresentativeVersions(client, metadata);
    if (versions != null && versions.length > 1) {
      if (!context.mounted) return null;
      final selectedIndex = await showVersionPickerDialog(context, versions, t.downloads.selectVersion);
      if (selectedIndex == null || !context.mounted) return null;
      return DownloadVersionConfig.fromSignature(
        versions[selectedIndex].signature,
        mediaIndex: selectedIndex,
        onVersionMismatch: (episode, episodeVersions) async {
          if (!context.mounted) return null;
          return showVersionPickerDialog(
            context,
            episodeVersions,
            '${episode.displayTitle} - ${t.downloads.selectVersion}',
          );
        },
      );
    }
    return DownloadVersionConfig();
  }

  return DownloadVersionConfig();
}

/// Show a dialog for selecting a media version.
/// Returns the selected index, or null if cancelled.
Future<int?> showVersionPickerDialog(BuildContext context, List<MediaVersion> versions, String title) {
  return showOptionPickerDialog<int>(
    context,
    title: title,
    options: List.generate(
      versions.length,
      (index) => (icon: Symbols.video_file_rounded, label: versions[index].displayLabel, value: index),
    ),
  );
}

/// Fetch media versions from a representative episode (first episode of first season).
Future<List<MediaVersion>?> fetchRepresentativeVersions(MediaServerClient client, MediaItem metadata) async {
  try {
    String? episodeRatingKey;

    if (metadata.kind == MediaKind.season) {
      final firstEpisode = await fetchFirstEpisodeForSeason(
        client,
        metadata.id,
        seriesId: metadata.grandparentId ?? metadata.parentId,
      );
      episodeRatingKey = firstEpisode?.id;
    } else if (metadata.kind == MediaKind.show) {
      final seasons = await client.fetchChildren(metadata.id);
      final firstSeason = defaultPlaybackSeason(seasons);
      if (firstSeason != null) {
        final firstEpisode = await fetchFirstEpisodeForSeason(client, firstSeason.id, seriesId: metadata.id);
        episodeRatingKey = firstEpisode?.id;
      }
    }

    if (episodeRatingKey == null) return null;

    final fullMetadata = await client.fetchItem(episodeRatingKey);
    return fullMetadata?.mediaVersions;
  } catch (e) {
    appLogger.w('Failed to fetch representative versions', error: e);
    return null;
  }
}
