import 'package:flutter/material.dart';

import '../../media/media_library.dart';
import '../../utils/library_grouping.dart';
import '../../widgets/backend_badge.dart';

/// Whether the visible [libraries] span more than one server.
bool librariesSpanMultipleServers(List<MediaLibrary> libraries) {
  final serverIds = libraries.where((library) => library.serverId != null).map((library) => library.serverId).toSet();
  return serverIds.length > 1;
}

/// Shared typography for per-server group headers on library surfaces.
TextStyle? libraryServerHeaderStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.labelSmall?.copyWith(
    fontWeight: .w600,
    letterSpacing: 0.4,
    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
  );
}

/// Builds the library entry list shared by the libraries dropdown and the quick
/// picker, applying one server-label policy: when [groupByServer] is on and the
/// list spans more than one server, entries are grouped under per-server headers
/// and rows carry no server name (the header does); otherwise rows stay flat and
/// each shows its server name whenever multiple servers are visible.
List<T> buildLibraryServerEntries<T>(
  List<MediaLibrary> libraries, {
  required bool groupByServer,
  required T Function(MediaLibrary library, String fallbackServerName) buildHeader,
  required T Function(MediaLibrary library, {required bool showServerName}) buildItem,
}) {
  final multipleServers = librariesSpanMultipleServers(libraries);
  if (!groupByServer || !multipleServers) {
    return libraries
        .map((library) => buildItem(library, showServerName: multipleServers && library.serverName != null))
        .toList();
  }

  final grouped = groupLibrariesByFirstAppearance(libraries);
  final entries = <T>[];
  for (final serverKey in grouped.serverOrder) {
    final bucket = grouped.byServer[serverKey]!;
    if (serverKey.isNotEmpty) {
      entries.add(buildHeader(bucket.first, serverKey));
    }
    for (final library in bucket) {
      entries.add(buildItem(library, showServerName: false));
    }
  }
  return entries;
}

/// [BackendBadge] plus server-name text, used for group headers and row
/// subtitles on library surfaces. Typography comes from [style] and [badgeSize].
class LibraryServerLabel extends StatelessWidget {
  final MediaLibrary library;
  final String? fallbackServerName;
  final double badgeSize;
  final TextStyle? style;
  final bool constrainText;

  const LibraryServerLabel({
    super.key,
    required this.library,
    this.fallbackServerName,
    this.badgeSize = 11,
    this.style,
    this.constrainText = false,
  });

  @override
  Widget build(BuildContext context) {
    final serverName = library.serverName ?? fallbackServerName;
    if (serverName == null || serverName.isEmpty) return const SizedBox.shrink();

    final text = Text(serverName, style: style, maxLines: 1, overflow: .ellipsis);
    return Row(
      mainAxisSize: .min,
      children: [
        BackendBadge(backend: library.backend, size: badgeSize, color: style?.color),
        const SizedBox(width: 4),
        if (constrainText) Flexible(child: text) else text,
      ],
    );
  }
}
