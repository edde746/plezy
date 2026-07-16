import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_library.dart';
import '../../utils/content_utils.dart';
import '../../utils/library_grouping.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focusable_list_tile.dart';

class LibraryQuickPickerSheet extends StatelessWidget {
  final List<MediaLibrary> libraries;
  final String? selectedLibraryKey;
  final bool isLoading;
  final bool groupByServer;
  final String emptyMessage;
  final ValueChanged<String> onSelected;

  const LibraryQuickPickerSheet({
    super.key,
    required this.libraries,
    required this.selectedLibraryKey,
    required this.isLoading,
    required this.groupByServer,
    required this.emptyMessage,
    required this.onSelected,
  });

  bool get _showServerHeaders {
    final serverIds = libraries.where((library) => library.serverId != null).map((library) => library.serverId).toSet();
    return serverIds.length > 1 && groupByServer;
  }

  Set<String> _getNonUniqueLibraryNames() {
    final nameCounts = <String, int>{};
    for (final library in libraries) {
      nameCounts[library.title] = (nameCounts[library.title] ?? 0) + 1;
    }
    return nameCounts.entries.where((entry) => entry.value > 1).map((entry) => entry.key).toSet();
  }

  List<Widget> _buildLibraryRows(BuildContext context) {
    if (!_showServerHeaders) {
      final nonUniqueNames = _getNonUniqueLibraryNames();
      return libraries.map((library) {
        return _buildLibraryTile(
          context,
          library,
          showServerName: library.serverName != null && nonUniqueNames.contains(library.title),
        );
      }).toList();
    }

    final grouped = groupLibrariesByFirstAppearance(libraries);
    final rows = <Widget>[];
    for (final serverKey in grouped.serverOrder) {
      final bucket = grouped.byServer[serverKey]!;
      if (serverKey.isNotEmpty) {
        rows.add(_buildServerHeader(context, bucket.first, serverKey));
      }
      for (final library in bucket) {
        rows.add(_buildLibraryTile(context, library, showServerName: false));
      }
    }
    return rows;
  }

  Widget _buildServerHeader(BuildContext context, MediaLibrary library, String fallbackServerName) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: .w600,
      letterSpacing: 0.4,
      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          BackendBadge(backend: library.backend, size: 12, color: labelStyle?.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(library.serverName ?? fallbackServerName, style: labelStyle, maxLines: 1, overflow: .ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSubtitle(BuildContext context, MediaLibrary library) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6));
    return Row(
      mainAxisSize: .min,
      children: [
        BackendBadge(backend: library.backend, size: 10, color: style?.color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(library.serverName!, style: style, maxLines: 1, overflow: .ellipsis),
        ),
      ],
    );
  }

  Widget _buildLibraryTile(BuildContext context, MediaLibrary library, {required bool showServerName}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = library.globalKey == selectedLibraryKey;
    final foregroundColor = isSelected ? colorScheme.primary : null;

    return FocusableListTile(
      key: ValueKey('library_quick_picker_${library.globalKey}'),
      dense: false,
      visualDensity: VisualDensity.standard,
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: AppIcon(ContentTypeHelper.getLibraryIcon(library.kind.id), fill: 1, size: 22, color: foregroundColor),
      title: Text(
        library.title,
        maxLines: 1,
        overflow: .ellipsis,
        style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: foregroundColor),
      ),
      subtitle: showServerName ? _buildServerSubtitle(context, library) : null,
      trailing: isSelected ? AppIcon(Symbols.check_rounded, fill: 1, color: colorScheme.primary) : null,
      onTap: () => onSelected(library.globalKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: .min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: .centerLeft,
            child: Text(t.libraries.selectLibrary, style: theme.textTheme.titleMedium),
          ),
        ),
        if (isLoading && libraries.isEmpty)
          const Padding(padding: .symmetric(vertical: 32), child: CircularProgressIndicator())
        else if (libraries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Text(emptyMessage, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: _buildLibraryRows(context),
            ),
          ),
      ],
    );
  }
}
