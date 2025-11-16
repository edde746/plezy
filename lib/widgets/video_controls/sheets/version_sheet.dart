import 'package:flutter/material.dart';
import '../../../models/plex_media_version.dart';
import 'base_video_control_sheet.dart';

/// Bottom sheet for selecting video version
class VersionSheet extends StatelessWidget {
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
    Function(int) onVersionSelected,
  ) {
    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) => VersionSheet(
        availableVersions: availableVersions,
        selectedMediaIndex: selectedMediaIndex,
        onVersionSelected: onVersionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseVideoControlSheet(
      title: 'Video Version',
      icon: Icons.video_file,
      child: ListView.builder(
        itemCount: availableVersions.length,
        itemBuilder: (context, index) {
          final version = availableVersions[index];
          final isSelected = index == selectedMediaIndex;

          return ListTile(
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
              onVersionSelected(index);
            },
          );
        },
      ),
    );
  }
}
