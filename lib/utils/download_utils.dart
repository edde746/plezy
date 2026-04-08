import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focusable_button.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../models/plex_metadata.dart';
import '../providers/download_provider.dart';
import '../services/plex_client.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';

/// Dialog option for the download picker. Typed to avoid stringly-typed values.
enum _DownloadChoice { all, unwatched, next5, next10, custom }

/// Shows download options dialog for shows/seasons, then queues the download.
/// For movies/episodes, queues directly without a dialog.
/// Returns the number of items queued, or null if cancelled.
Future<int?> showDownloadOptionsAndQueue(
  BuildContext context, {
  required PlexMetadata metadata,
  required PlexClient client,
  required DownloadProvider downloadProvider,
}) async {
  final mt = metadata.mediaType;

  var filter = DownloadFilter.all;
  int? maxCount;

  if (mt == PlexMediaType.show || mt == PlexMediaType.season) {
    final selected = await showOptionPickerDialog<_DownloadChoice>(
      context,
      title: t.downloads.downloadNow,
      options: [
        (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: _DownloadChoice.all),
        (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: _DownloadChoice.unwatched),
        (icon: Symbols.filter_5_rounded, label: t.downloads.nextNUnwatched(count: 5), value: _DownloadChoice.next5),
        (icon: Symbols.filter_9_plus_rounded, label: t.downloads.nextNUnwatched(count: 10), value: _DownloadChoice.next10),
        (icon: Symbols.tune_rounded, label: t.downloads.customAmount, value: _DownloadChoice.custom),
      ],
    );

    if (selected == null || !context.mounted) return null;

    switch (selected) {
      case _DownloadChoice.all:
        break;
      case _DownloadChoice.unwatched:
        filter = DownloadFilter.unwatched;
      case _DownloadChoice.next5:
        filter = DownloadFilter.unwatched;
        maxCount = 5;
      case _DownloadChoice.next10:
        filter = DownloadFilter.unwatched;
        maxCount = 10;
      case _DownloadChoice.custom:
        final count = await _showEpisodeCountDialog(context);
        if (count == null || !context.mounted) return null;
        filter = DownloadFilter.unwatched;
        maxCount = count;
    }
  }

  if (!context.mounted) return null;

  final versionConfig = await resolveDownloadVersion(context, metadata, client);
  if (versionConfig == null || !context.mounted) return null;

  return await downloadProvider.queueDownload(
    metadata,
    client,
    versionConfig: versionConfig,
    filter: filter,
    maxCount: maxCount,
  );
}

/// Shows download options dialog for playlists, then queues the download.
/// Returns the number of items queued, or null if cancelled.
Future<int?> showPlaylistDownloadOptionsAndQueue(
  BuildContext context, {
  required List<PlexMetadata> items,
  required PlexClient client,
  required DownloadProvider downloadProvider,
}) async {
  final selected = await showOptionPickerDialog<DownloadFilter>(
    context,
    title: t.downloads.downloadNow,
    options: [
      (icon: Symbols.download_rounded, label: t.downloads.allEpisodes, value: DownloadFilter.all),
      (icon: Symbols.visibility_off_rounded, label: t.downloads.unwatchedOnly, value: DownloadFilter.unwatched),
    ],
  );

  if (selected == null || !context.mounted) return null;

  return await downloadProvider.queuePlaylistDownload(
    items,
    client,
    filter: selected,
  );
}

Future<int?> _showEpisodeCountDialog(BuildContext context) {
  final autoFocus = InputModeTracker.isKeyboardMode(context);
  return showDialog<int>(
    context: context,
    builder: (context) => _EpisodeCountDialog(autoFocus: autoFocus),
  );
}

class _EpisodeCountDialog extends StatefulWidget {
  final bool autoFocus;
  const _EpisodeCountDialog({this.autoFocus = false});

  @override
  State<_EpisodeCountDialog> createState() => _EpisodeCountDialogState();
}

class _EpisodeCountDialogState extends State<_EpisodeCountDialog> {
  late final TextEditingController _controller;
  final _submitFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final count = int.tryParse(_controller.text);
    if (count != null && count > 0) {
      Navigator.pop(context, count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.downloads.howManyEpisodes),
      content: TextField(
        controller: _controller,
        autofocus: widget.autoFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submitFocusNode.requestFocus(),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
        FocusableButton(
          focusNode: _submitFocusNode,
          onPressed: _submit,
          child: TextButton(onPressed: _submit, child: Text(t.common.ok)),
        ),
      ],
    );
  }
}
