import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/plex_media_version.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../../../widgets/overlay_sheet.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for selecting video version
class VersionSheet extends StatefulWidget {
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final Function(int) onVersionSelected;

  const VersionSheet({
    super.key,
    required this.availableVersions,
    required this.selectedMediaIndex,
    required this.onVersionSelected,
  });

  @override
  State<VersionSheet> createState() => _VersionSheetState();
}

class _VersionSheetState extends State<VersionSheet> {
  @override
  Widget build(BuildContext context) {
    return BaseVideoControlSheet(
      title: 'Video Version',
      icon: Symbols.video_file_rounded,
      child: ListView.builder(
        itemCount: widget.availableVersions.length,
        itemBuilder: (context, index) {
          final version = widget.availableVersions[index];
          final isSelected = index == widget.selectedMediaIndex;

          return FocusableListTile(
            title: Text(version.displayLabel, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
            trailing: isSelected ? const AppIcon(Symbols.check_rounded, fill: 1, color: Colors.blue) : null,
            onTap: () {
              OverlaySheetController.of(context).close();
              widget.onVersionSelected(index);
            },
          );
        },
      ),
    );
  }
}
