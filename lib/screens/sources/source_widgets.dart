import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../sources/source_models.dart';
import '../../sources/source_controller.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';

String sourceFailureText(Object error) => switch (error is SourceException ? error.reason : SourceFailure.unavailable) {
  SourceFailure.authentication => t.fileSources.errorAuthentication,
  SourceFailure.permission => t.fileSources.errorPermission,
  SourceFailure.unavailable => t.fileSources.errorUnavailable,
  SourceFailure.unsupported => t.fileSources.errorUnsupported,
  SourceFailure.invalidData => t.fileSources.errorInvalidData,
  SourceFailure.cancelled => t.fileSources.errorCancelled,
  SourceFailure.conflict => t.fileSources.errorConflict,
};
Future<void> sourceAction(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, sourceFailureText(e));
  }
}

String sourceKindName(FileSourceKind kind) => switch (kind) {
  FileSourceKind.local => t.fileSources.localFiles,
  FileSourceKind.googleDrive => t.fileSources.googleDrive,
  FileSourceKind.oneDrive => 'OneDrive',
  FileSourceKind.dropbox => 'Dropbox',
  FileSourceKind.webdav => 'WebDAV / Nextcloud',
  FileSourceKind.smb => 'SMB / NAS',
  FileSourceKind.ftp => 'FTP / FTPES / FTPS',
  FileSourceKind.sftp => 'SFTP',
  FileSourceKind.nfs => 'NFS',
  FileSourceKind.dlna => 'DLNA / UPnP',
  FileSourceKind.s3 => 'S3',
  FileSourceKind.opds => 'OPDS',
  FileSourceKind.audiobookshelf => 'Audiobookshelf',
};
IconData sourceItemIcon(SourceItemKind kind) => switch (kind) {
  SourceItemKind.comic => Symbols.auto_stories_rounded,
  SourceItemKind.folder => Symbols.folder_rounded,
  SourceItemKind.ebook => Symbols.menu_book_rounded,
  SourceItemKind.audiobook => Symbols.headphones_rounded,
  SourceItemKind.music => Symbols.music_note_rounded,
  SourceItemKind.video => Symbols.movie_rounded,
  SourceItemKind.unknown => Symbols.insert_drive_file_rounded,
};
String sourceTime(int milliseconds) {
  final seconds = milliseconds.clamp(0, 1 << 48) ~/ 1000;
  final minutes = seconds ~/ 60;
  return minutes >= 60
      ? '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
      : '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Same quiet grouped row geometry and focus surface as connection settings.
class SourceTile extends StatelessWidget {
  const SourceTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Symbols.folder_rounded,
    this.onTap,
    this.trailing,
    this.leading,
    this.progress,
    this.index = 0,
    this.count = 1,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? leading;
  final double? progress;
  final int index, count;
  @override
  Widget build(BuildContext context) {
    final shape = groupItemRadii(context, index, count), theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens(context).groupGap),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: FocusableWrapper(
          disableScale: true,
          useBackgroundFocus: true,
          borderRadii: shape,
          onSelect: onTap,
          descendantsAreFocusable: trailing != null,
          child: InkWell(
            onTap: onTap,
            canRequestFocus: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  leading ?? AppIcon(icon, fill: 1, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (progress != null) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            label: '${(progress!.clamp(0, 1) * 100).round()}% complete',
                            child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SourceCover extends StatefulWidget {
  const SourceCover({super.key, required this.entry});
  final SourceEntry entry;
  @override
  State<SourceCover> createState() => _SourceCoverState();
}

class _SourceCoverState extends State<SourceCover> {
  Future<File?>? _cover;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cover ??= context.read<SourceController?>()?.cover(widget.entry);
  }

  @override
  void didUpdateWidget(covariant SourceCover old) {
    super.didUpdateWidget(old);
    if (old.entry.key != widget.entry.key ||
        old.entry.coverId != widget.entry.coverId ||
        old.entry.onlinePosterUrl != widget.entry.onlinePosterUrl) {
      _cover = context.read<SourceController?>()?.cover(widget.entry);
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(tokens(context).radiusMd),
    child: FutureBuilder<File?>(
      future: _cover,
      builder: (context, snapshot) {
        final fallback = DecoratedBox(
          decoration: BoxDecoration(
            color: tokens(context).surface,
            border: Border.all(color: tokens(context).outline.withValues(alpha: .25)),
            borderRadius: BorderRadius.circular(tokens(context).radiusMd),
          ),
          child: Center(
            child: AppIcon(sourceItemIcon(widget.entry.kind), size: 52, fill: 1, color: tokens(context).textMuted),
          ),
        );
        return snapshot.data == null
            ? fallback
            : Image.file(snapshot.data!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
      },
    ),
  );
}

class SourcePosterCard extends StatelessWidget {
  const SourcePosterCard({super.key, required this.entry, required this.onTap, this.progress});
  final SourceEntry entry;
  final VoidCallback onTap;
  final double? progress;
  @override
  Widget build(BuildContext context) => FocusableWrapper(
    onSelect: onTap,
    borderRadius: tokens(context).radiusMd,
    child: InkWell(
      onTap: onTap,
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SourceCover(entry: entry),
                if (progress != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Semantics(
                      label: '${(progress!.clamp(0, 1) * 100).round()}% complete',
                      child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.displayTitle,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.author.isNotEmpty)
            Text(
              entry.author,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );
}
