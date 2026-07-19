import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_version.dart';
import '../media/media_version_preference.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialog_action_button.dart';
import 'dialogs.dart';
import 'download_version_utils.dart';
import 'media_server_http_client.dart';

typedef PlaybackVersionLoader = Future<List<MediaVersion>> Function(AbortController abort);

/// The exact ordered source selected for a playback launch.
class PlaybackVersionSelection {
  final List<MediaVersion> versions;
  final int index;

  const PlaybackVersionSelection({required this.versions, required this.index});

  MediaVersion get version => versions[index];
}

/// Discovers the current server-side playback sources, then asks the user to
/// choose when more than one is available. A single source proceeds without
/// an extra tap. Discovery errors remain retryable in the dialog, so callers
/// never accidentally continue with a guessed source.
Future<PlaybackVersionSelection?> showPlaybackVersionSelector(
  BuildContext context, {
  required String title,
  required PlaybackVersionLoader loadVersions,
  MediaVersionPreference? preferredVersion,
}) async {
  final versions = await showScopedDialog<List<MediaVersion>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PlaybackVersionDiscoveryDialog(title: title, loadVersions: loadVersions),
  );
  if (versions == null || versions.isEmpty || !context.mounted) return null;

  final initialIndex = preferredVersion?.resolveIndex(versions) ?? 0;
  if (versions.length == 1) {
    return PlaybackVersionSelection(versions: versions, index: 0);
  }

  final selectedIndex = await showVersionPickerDialog(context, versions, title, initialIndex: initialIndex);
  if (selectedIndex == null || !context.mounted) return null;
  return PlaybackVersionSelection(versions: versions, index: selectedIndex);
}

class _NoPlaybackVersionsException implements Exception {
  const _NoPlaybackVersionsException();
}

class _PlaybackVersionDiscoveryDialog extends StatefulWidget {
  final String title;
  final PlaybackVersionLoader loadVersions;

  const _PlaybackVersionDiscoveryDialog({required this.title, required this.loadVersions});

  @override
  State<_PlaybackVersionDiscoveryDialog> createState() => _PlaybackVersionDiscoveryDialogState();
}

class _PlaybackVersionDiscoveryDialogState extends State<_PlaybackVersionDiscoveryDialog> {
  AbortController? _abort;
  Object? _error;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _abort?.abort();
    super.dispose();
  }

  Future<void> _load() async {
    _abort?.abort();
    final abort = AbortController();
    _abort = abort;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final versions = await widget.loadVersions(abort);
      if (!mounted || !identical(_abort, abort) || abort.isAborted) return;
      if (versions.isEmpty) throw const _NoPlaybackVersionsException();
      Navigator.pop(context, List<MediaVersion>.unmodifiable(versions));
    } catch (error) {
      if (!mounted || !identical(_abort, abort) || abort.isAborted) return;
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  void _cancel() {
    _abort?.abort();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final errorMessage = error is _NoPlaybackVersionsException
        ? t.common.error
        : t.messages.errorLoading(error: error.toString());

    return AlertDialog(
      key: const ValueKey('playback-version-discovery'),
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: _isLoading
            ? Row(
                key: const ValueKey('playback-version-loading'),
                children: [
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                  const SizedBox(width: 18),
                  Expanded(child: Text(t.common.loading)),
                ],
              )
            : Row(
                key: const ValueKey('playback-version-error'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(Symbols.error_rounded, color: Theme.of(context).colorScheme.error, fill: 1),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage, maxLines: 5, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
      actions: [
        DialogActionButton(onPressed: _cancel, label: t.common.cancel, autofocus: _isLoading),
        if (!_isLoading)
          DialogActionButton(
            key: const ValueKey('playback-version-retry'),
            onPressed: _load,
            label: t.common.retry,
            autofocus: true,
            isPrimary: true,
          ),
      ],
    );
  }
}
