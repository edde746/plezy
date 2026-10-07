import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../providers/download_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../services/watch_actions.dart';
import 'app_logger.dart';
import 'dialogs.dart';
import 'error_message_utils.dart';
import 'snackbar_helper.dart';

// Actions on a downloads folder: a collection shown on the downloads screen,
// standing for the downloaded titles inside it. Shared by the folder card's
// context menu and the offline collection screen.

/// Mark every downloaded title in [folder] watched or unwatched. Offline, the
/// marks queue for the next sync. Reports the result in one snackbar.
Future<void> setDownloadsFolderWatched(BuildContext context, MediaItem folder, {required bool watched}) async {
  final titles = context.read<DownloadProvider>().downloadedCollectionItems(folder.globalKey).where((title) {
    final hasWatchState = title.isWatched || title.isPartiallyWatched || title.hasActiveProgress;
    return watched ? !title.isWatched : hasWatchState;
  });
  final offline = context.read<OfflineModeProvider>().isOffline;
  try {
    var reachedServer = true;
    for (final title in titles) {
      if (!context.mounted) return;
      final outcome = await WatchActions.setWatched(context, title, watched: watched, offline: offline);
      if (outcome == WatchMarkOutcome.skipped) reachedServer = false;
    }
    if (!context.mounted) return;
    if (!reachedServer) {
      showErrorSnackBar(context, t.messages.errorLoading(error: t.errors.reasonUnreachable));
    } else if (offline) {
      showAppSnackBar(context, watched ? t.messages.markedAsWatchedOffline : t.messages.markedAsUnwatchedOffline);
    } else {
      showSuccessSnackBar(context, watched ? t.messages.markedAsWatched : t.messages.markedAsUnwatched);
    }
  } catch (e, st) {
    appLogger.e('Failed to mark downloads folder ${folder.globalKey}', error: e, stackTrace: st);
    if (context.mounted) showErrorSnackBar(context, t.messages.errorLoading(error: localizedErrorReason(e)));
  }
}

/// Ask, then delete every downloaded title in [folder]. Returns whether the
/// downloads were deleted.
Future<bool> deleteDownloadsFolder(BuildContext context, MediaItem folder) async {
  final confirmed = await showDeleteConfirmation(
    context,
    title: t.downloads.deleteCollectionDownloads,
    message: t.downloads.deleteCollectionDownloadsConfirm(title: folder.displayTitle),
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await context.read<DownloadProvider>().deleteCollectionDownloads(folder.globalKey);
    if (context.mounted) showSuccessSnackBar(context, t.downloads.collectionDownloadsDeleted);
    return true;
  } catch (e, st) {
    appLogger.e('Failed to delete downloads folder ${folder.globalKey}', error: e, stackTrace: st);
    if (context.mounted) showErrorSnackBar(context, t.messages.errorLoading(error: localizedErrorReason(e)));
    return false;
  }
}
