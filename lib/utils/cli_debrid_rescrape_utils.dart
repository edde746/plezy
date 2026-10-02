import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import '../providers/cli_debrid_account_provider.dart';
import '../services/cli_debrid/cli_debrid_client.dart';
import 'dialogs.dart';
import 'media_version_resolver.dart';

/// Whether a "Re-request" action should be offered for [item] at all —
/// cli_debrid connected, and the item is a kind cli_debrid tracks (movie or
/// episode; shows/seasons re-request per-episode via their children, which
/// this action doesn't attempt to enumerate).
bool cliDebridReRequestSupported(CliDebridAccountProvider account, MediaItem item) {
  return account.isConnected && (item.kind == MediaKind.movie || item.kind == MediaKind.episode);
}

/// Move [item] back to cli_debrid's Wanted queue for re-request.
///
/// Resolves the item's versions (using [client] to fetch them if not already
/// inline on [item]) and, when there's more than one, prompts the user via
/// [showOptionPickerDialog] to choose which file/version to re-request —
/// mirroring [resolveDownloadVersion]'s "only prompt when ambiguous" shape.
///
/// The chosen version's file path (if the backend reports one) is sent as
/// `filename` so cli_debrid can disambiguate server-side too, in case its own
/// idea of "how many versions exist" differs from what the media server
/// reports (e.g. a duplicate the user already deleted from Plex/Jellyfin but
/// that's still separately tracked in cli_debrid).
///
/// Returns true on success, false if the user cancelled a picker, and throws
/// on failure (caller shows the error).
Future<bool> reRequestMediaItem(
  BuildContext context, {
  required MediaItem item,
  required CliDebridClient client,
  required MediaServerClient serverClient,
}) async {
  final versions = await resolveMediaVersions(item, serverClient);
  if (!context.mounted) return false;

  String? filename;
  if (versions.length > 1) {
    final picked = await showOptionPickerDialog<int>(
      context,
      title: t.cliDebrid.chooseVersion,
      options: List.generate(
        versions.length,
        (index) => (icon: Symbols.video_file_rounded, label: versions[index].displayLabel, value: index),
      ),
    );
    if (picked == null) return false;
    filename = _fileNameOf(versions[picked]);
  } else if (versions.length == 1) {
    filename = _fileNameOf(versions.single);
  }

  final isEpisode = item.kind == MediaKind.episode;
  final seasonNumber = isEpisode ? item.parentIndex : null;
  final episodeNumber = isEpisode ? item.index : null;
  // cli_debrid stores the *show's* media-server id on every episode row
  // (ms_item_id is not unique per-episode), so an episode lookup must send
  // the show's id (grandparentId), not the episode's own id.
  final msItemId = isEpisode ? item.grandparentId : item.id;

  try {
    if (isEpisode && msItemId == null) {
      throw StateError('Episode ${item.id} is missing grandparentId (show id) — cannot resolve for re-request');
    }
    await client.rescrapeItem(
      msItemId: msItemId,
      type: isEpisode ? 'episode' : 'movie',
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      filename: filename,
    );
    return true;
  } on CliDebridAmbiguousRescrapeException catch (e) {
    if (!context.mounted) return false;
    final picked = await showOptionPickerDialog<int>(
      context,
      title: t.cliDebrid.chooseVersion,
      options: List.generate(
        e.candidates.length,
        (index) => (
          icon: Symbols.video_file_rounded,
          label: e.candidates[index].displayFilename.isNotEmpty
              ? e.candidates[index].displayFilename
              : (e.candidates[index].version ?? e.candidates[index].title),
          value: index,
        ),
      ),
    );
    if (picked == null) return false;
    await client.rescrapeItem(itemId: e.candidates[picked].id);
    return true;
  }
}

String? _fileNameOf(MediaVersion version) {
  for (final part in version.parts) {
    if (part.file != null && part.file!.isNotEmpty) return part.file;
  }
  return null;
}

/// Outcome of a season-wide bulk re-request, for a single summary message
/// rather than one snackbar per episode.
class CliDebridBulkReRequestResult {
  final int succeeded;
  final int skippedAmbiguous;
  final int failed;

  const CliDebridBulkReRequestResult({required this.succeeded, required this.skippedAmbiguous, required this.failed});

  bool get isEmpty => succeeded == 0 && skippedAmbiguous == 0 && failed == 0;
}

/// Re-request every episode of a season in one pass, without interactive
/// version pickers: an episode with exactly one version (or the picker's
/// single-candidate path) is re-requested; an episode with more than one
/// version, or one that comes back ambiguous from cli_debrid, is skipped and
/// counted rather than blocking the whole season on a prompt (per-episode
/// version choices belong to the single-item action in [reRequestMediaItem]).
///
/// [episodes] should be the season's full episode list (see
/// [MediaServerClient.fetchChildren] — not a paginated subset), since a
/// season action that silently only covers the loaded page would look like
/// it worked while quietly skipping most of the season.
Future<CliDebridBulkReRequestResult> reRequestSeasonEpisodes(
  List<MediaItem> episodes, {
  required CliDebridClient client,
  required MediaServerClient serverClient,
}) async {
  var succeeded = 0;
  var skippedAmbiguous = 0;
  var failed = 0;

  for (final episode in episodes) {
    if (episode.kind != MediaKind.episode) continue;
    try {
      // cli_debrid stores the show's media-server id on every episode row,
      // not the episode's own id — see reRequestMediaItem's comment.
      final msItemId = episode.grandparentId;
      if (msItemId == null) {
        failed++;
        continue;
      }
      final versions = await resolveMediaVersions(episode, serverClient);
      if (versions.length > 1) {
        skippedAmbiguous++;
        continue;
      }
      final filename = versions.length == 1 ? _fileNameOf(versions.single) : null;
      await client.rescrapeItem(
        msItemId: msItemId,
        type: 'episode',
        seasonNumber: episode.parentIndex,
        episodeNumber: episode.index,
        filename: filename,
      );
      succeeded++;
    } on CliDebridAmbiguousRescrapeException {
      skippedAmbiguous++;
    } catch (_) {
      failed++;
    }
  }

  return CliDebridBulkReRequestResult(succeeded: succeeded, skippedAmbiguous: skippedAmbiguous, failed: failed);
}
