import 'package:flutter/material.dart';
import '../../../models/plex_media_version.dart';

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

  static BoxConstraints getBottomSheetConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  static void show(
    BuildContext context,
    List<PlexMediaVersion> availableVersions,
    int selectedMediaIndex,
    Function(int) onVersionSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: getBottomSheetConstraints(context),
      builder: (context) => VersionSheet(
        availableVersions: availableVersions,
        selectedMediaIndex: selectedMediaIndex,
        onVersionSelected: onVersionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.video_file, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Video Version',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
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
            ),
          ],
        ),
      ),
    );
  }
}
