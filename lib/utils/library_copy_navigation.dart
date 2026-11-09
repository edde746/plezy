import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../providers/discover_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/continue_watching_copy_dialog.dart';
import 'dialogs.dart';
import 'video_player_navigation.dart';

/// Explicit catalogue lookup for copies missing from the Continue Watching hub.
/// No lookup runs on normal activation or while merely opening the context menu.
/// Returns false when dismissed; otherwise completes after playback returns.
Future<bool> promptAndPlayLibraryCopy(BuildContext context, MediaItem item) async {
  if ((!item.isMovie && !item.isEpisode) || context.read<OfflineModeProvider?>()?.isOffline == true) return false;
  final discover = context.read<DiscoverProvider?>();
  if (discover == null) return false;
  final picked = await showScopedDialog<MediaItem>(
    context: context,
    builder: (_) =>
        ContinueWatchingCopyDialog(resolve: (abort) => discover.resolveContinueWatchingCopies(item, abort: abort)),
  );
  if (picked == null || !context.mounted) return false;
  await navigateToVideoPlayer(context, metadata: picked);
  return true;
}
