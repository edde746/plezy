import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import '../media/episode_collection.dart';
import '../focus/input_mode_tracker.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/media_version_resolver.dart';
import '../i18n/strings.g.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/focusable_list_tile.dart';

/// Configuration for download version selection, threaded through the queue pipeline.
class DownloadVersionConfig {
  final int mediaIndex;
  final Set<String> acceptedSignatures;
  final Future<int?> Function(MediaItem episode, List<MediaVersion> versions)? onVersionMismatch;

  DownloadVersionConfig({this.mediaIndex = 0, Set<String>? acceptedSignatures, this.onVersionMismatch})
    : acceptedSignatures = acceptedSignatures ?? {};

  /// Create from a selected version's signature.
  factory DownloadVersionConfig.fromSignature(
    String signature, {
    int mediaIndex = 0,
    Future<int?> Function(MediaItem, List<MediaVersion>)? onVersionMismatch,
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
Future<int?> showVersionPickerDialog(
  BuildContext context,
  List<MediaVersion> versions,
  String title, {
  int initialIndex = 0,
}) {
  final highlightedIndex = initialIndex >= 0 && initialIndex < versions.length ? initialIndex : 0;
  final autofocusSelection = InputModeTracker.isKeyboardMode(context, listen: false);
  return showScopedDialog<int>(
    context: context,
    builder: (dialogContext) {
      final viewport = MediaQuery.sizeOf(dialogContext);
      final horizontalInset = viewport.width >= 600 ? 24.0 : 12.0;
      final dialogWidth = math.max(280.0, math.min(1100.0, viewport.width - (horizontalInset * 2)));
      final maxListHeight = math.max(96.0, math.min(viewport.height * 0.72, viewport.height - 180.0));
      return AlertDialog(
        key: const ValueKey('media-version-picker'),
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
        constraints: BoxConstraints.tightFor(width: dialogWidth),
        title: Text(title),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final highlighted = index == highlightedIndex;
              return FocusableListTile(
                key: ValueKey('media-version-option-$index'),
                autofocus: autofocusSelection && highlighted,
                selected: highlighted,
                dense: false,
                visualDensity: VisualDensity.standard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: const AppIcon(Symbols.video_file_rounded, fill: 1, size: 24),
                title: Text(mediaVersionPickerLabel(versions[index]), softWrap: true),
                trailing: highlighted ? const AppIcon(Symbols.check_rounded, fill: 1, size: 22) : null,
                onTap: () => Navigator.pop(dialogContext, index),
              );
            },
          ),
        ),
        actions: [DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel)],
      );
    },
  );
}

/// Compact presentation label for server-provided version names. Remux/AIO
/// may put a source name and description on separate lines; keep all of that
/// content while preventing embedded whitespace from breaking picker rows.
String mediaVersionPickerLabel(MediaVersion version) {
  final label = version.displayLabel.replaceAll(RegExp(r'\s+'), ' ').trim();
  return label.isEmpty ? t.common.unknown : label;
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
