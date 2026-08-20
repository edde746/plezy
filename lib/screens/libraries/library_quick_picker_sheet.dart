import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_library.dart';
import '../../utils/content_utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import 'library_server_label.dart';

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

  List<Widget> _buildLibraryRows(BuildContext context) {
    return buildLibraryServerEntries<Widget>(
      libraries,
      groupByServer: groupByServer,
      buildHeader: (library, fallbackServerName) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: LibraryServerLabel(
          library: library,
          fallbackServerName: fallbackServerName,
          badgeSize: 12,
          style: libraryServerHeaderStyle(context),
          constrainText: true,
        ),
      ),
      buildItem: (library, {required bool showServerName}) =>
          _buildLibraryTile(context, library, showServerName: showServerName),
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
      subtitle: showServerName
          ? LibraryServerLabel(
              library: library,
              badgeSize: 10,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              constrainText: true,
            )
          : null,
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
