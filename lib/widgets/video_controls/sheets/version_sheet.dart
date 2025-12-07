import 'package:flutter/material.dart';
import '../../../models/plex_media_version.dart';
import '../../../widgets/focusable_bottom_sheet.dart';
import '../../../widgets/focusable_list_tile.dart';
import 'base_video_control_sheet.dart';
import 'video_control_sheet_launcher.dart';

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

  static void show(
    BuildContext context,
    List<PlexMediaVersion> availableVersions,
    int selectedMediaIndex,
    Function(int) onVersionSelected, {
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    VideoControlSheetLauncher.show(
      context: context,
      onOpen: onOpen,
      onClose: onClose,
      builder: (context) => VersionSheet(
        availableVersions: availableVersions,
        selectedMediaIndex: selectedMediaIndex,
        onVersionSelected: onVersionSelected,
      ),
    );
  }

  @override
  State<VersionSheet> createState() => _VersionSheetState();
}

class _VersionSheetState extends State<VersionSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'VersionSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: BaseVideoControlSheet(
        title: 'Video Version',
        icon: Icons.video_file,
        child: ListView.builder(
          itemCount: widget.availableVersions.length,
          itemBuilder: (context, index) {
            final version = widget.availableVersions[index];
            final isSelected = index == widget.selectedMediaIndex;

            return FocusableListTile(
              focusNode: index == 0 ? _initialFocusNode : null,
              title: Text(
                version.displayLabel,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                widget.onVersionSelected(index);
              },
            );
          },
        ),
      ),
    );
  }
}
