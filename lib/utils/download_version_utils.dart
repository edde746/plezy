import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../i18n/strings.g.dart';

/// Configuration for download version selection, threaded through the queue pipeline.
class DownloadVersionConfig {
  final int mediaIndex;
  final Set<String> acceptedSignatures;
  final Future<int?> Function(PlexMetadata episode, List<PlexMediaVersion> versions)? onVersionMismatch;

  DownloadVersionConfig({
    this.mediaIndex = 0,
    Set<String>? acceptedSignatures,
    this.onVersionMismatch,
  }) : acceptedSignatures = acceptedSignatures ?? {};

  /// Create from a selected version's signature.
  factory DownloadVersionConfig.fromSignature(
    String signature, {
    int mediaIndex = 0,
    Future<int?> Function(PlexMetadata, List<PlexMediaVersion>)? onVersionMismatch,
  }) {
    return DownloadVersionConfig(
      mediaIndex: mediaIndex,
      acceptedSignatures: {signature},
      onVersionMismatch: onVersionMismatch,
    );
  }
}

/// Resolve version selection for a download. Shows picker if needed.
/// Returns null if the user cancels, or a config with the selection.
Future<DownloadVersionConfig?> resolveDownloadVersion(
  BuildContext context,
  PlexMetadata metadata,
  PlexClient client, {
  List<PlexMediaVersion>? fallbackVersions,
}) async {
  final mediaType = metadata.mediaType;

  if (mediaType == PlexMediaType.movie || mediaType == PlexMediaType.episode) {
    final versions = metadata.mediaVersions ?? fallbackVersions;
    if (versions != null && versions.length > 1) {
      final selectedIndex = await showVersionPickerDialog(context, versions, t.downloads.selectVersion);
      if (selectedIndex == null || !context.mounted) return null;
      return DownloadVersionConfig(mediaIndex: selectedIndex);
    }
    return DownloadVersionConfig();
  }

  if (mediaType == PlexMediaType.show || mediaType == PlexMediaType.season) {
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
Future<int?> showVersionPickerDialog(BuildContext context, List<PlexMediaVersion> versions, String title) {
  return showOptionPickerDialog<int>(
    context,
    title: title,
    options: List.generate(versions.length, (index) => (
      icon: Symbols.video_file_rounded,
      label: versions[index].displayLabel,
      value: index,
    )),
  );
}

/// Fetch media versions from a representative episode (first episode of first season).
Future<List<PlexMediaVersion>?> fetchRepresentativeVersions(PlexClient client, PlexMetadata metadata) async {
  try {
    String? episodeRatingKey;

    if (metadata.mediaType == PlexMediaType.season) {
      final episodes = await client.getChildren(metadata.ratingKey);
      final firstEpisode = episodes.cast<PlexMetadata?>().firstWhere((e) => e?.type == 'episode', orElse: () => null);
      episodeRatingKey = firstEpisode?.ratingKey;
    } else if (metadata.mediaType == PlexMediaType.show) {
      final seasons = await client.getChildren(metadata.ratingKey);
      // Skip Season 0 (Specials) as it may have different encoding
      final firstSeason = seasons.cast<PlexMetadata?>().firstWhere(
            (s) => s?.type == 'season' && (s?.index ?? 0) > 0,
            orElse: () => seasons.cast<PlexMetadata?>().firstWhere((s) => s?.type == 'season', orElse: () => null),
          );
      if (firstSeason != null) {
        final episodes = await client.getChildren(firstSeason.ratingKey);
        final firstEpisode =
            episodes.cast<PlexMetadata?>().firstWhere((e) => e?.type == 'episode', orElse: () => null);
        episodeRatingKey = firstEpisode?.ratingKey;
      }
    }

    if (episodeRatingKey == null) return null;

    final fullMetadata = await client.getMetadataWithImages(episodeRatingKey);
    return fullMetadata?.mediaVersions;
  } catch (e) {
    appLogger.w('Failed to fetch representative versions', error: e);
    return null;
  }
}
