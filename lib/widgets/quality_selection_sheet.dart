import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/plex_media_version.dart';
import '../i18n/strings.g.dart';
import 'app_icon.dart';
import 'focusable_bottom_sheet.dart';
import 'focusable_list_tile.dart';

/// A bottom sheet that displays available video quality versions and allows
/// the user to select one before playback starts.
///
/// This sheet is shown when the user long-presses the play button on the
/// media detail screen, enabling quality selection before streaming begins.
class QualitySelectionSheet extends StatefulWidget {
  /// Available video versions to choose from
  final List<PlexMediaVersion> availableVersions;

  /// Currently selected version index (defaults to 0)
  final int selectedIndex;

  /// Callback when a version is selected
  final void Function(int index) onVersionSelected;

  const QualitySelectionSheet({
    super.key,
    required this.availableVersions,
    required this.selectedIndex,
    required this.onVersionSelected,
  });

  /// Shows the quality selection sheet as a modal bottom sheet
  ///
  /// Parameters:
  /// - [context]: The build context for showing the sheet
  /// - [availableVersions]: List of available video versions
  /// - [selectedIndex]: Currently selected version index
  /// - [onVersionSelected]: Callback when a version is selected
  static Future<void> show({
    required BuildContext context,
    required List<PlexMediaVersion> availableVersions,
    required int selectedIndex,
    required void Function(int index) onVersionSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QualitySelectionSheet(
        availableVersions: availableVersions,
        selectedIndex: selectedIndex,
        onVersionSelected: onVersionSelected,
      ),
    );
  }

  @override
  State<QualitySelectionSheet> createState() => _QualitySelectionSheetState();
}

class _QualitySelectionSheetState extends State<QualitySelectionSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'QualitySelectionInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AppIcon(
                      Symbols.high_quality_rounded,
                      fill: 1,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.video.selectQuality,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Version list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.availableVersions.length,
                  itemBuilder: (context, index) {
                    final version = widget.availableVersions[index];
                    final isSelected = index == widget.selectedIndex;

                    return FocusableListTile(
                      focusNode: index == 0 ? _initialFocusNode : null,
                      leading: _buildQualityIcon(version, colorScheme, isSelected),
                      title: Text(
                        version.displayLabel,
                        style: TextStyle(
                          color: isSelected ? colorScheme.primary : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: _buildSubtitle(version),
                      trailing: isSelected
                          ? AppIcon(
                              Symbols.check_circle_rounded,
                              fill: 1,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onVersionSelected(index);
                      },
                    );
                  },
                ),
              ),

              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.common.cancel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an icon representing the quality tier
  Widget _buildQualityIcon(
    PlexMediaVersion version,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    IconData icon;
    Color? color;

    // Determine quality tier based on resolution
    final resolution = version.videoResolution?.toLowerCase() ?? '';
    if (resolution.contains('4k') || resolution.contains('2160')) {
      icon = Symbols.four_k_rounded;
      color = Colors.amber;
    } else if (resolution.contains('1080')) {
      icon = Symbols.hd_rounded;
      color = Colors.blue;
    } else if (resolution.contains('720')) {
      icon = Symbols.hd_rounded;
      color = colorScheme.onSurface.withOpacity(0.7);
    } else {
      icon = Symbols.sd_rounded;
      color = colorScheme.onSurface.withOpacity(0.5);
    }

    return AppIcon(
      icon,
      fill: 1,
      size: 28,
      color: isSelected ? colorScheme.primary : color,
    );
  }

  /// Builds a subtitle with codec and container info
  Widget? _buildSubtitle(PlexMediaVersion version) {
    final parts = <String>[];

    if (version.width != null && version.height != null) {
      parts.add('${version.width}x${version.height}');
    }

    if (version.videoCodec != null) {
      parts.add(version.videoCodec!.toUpperCase());
    }

    if (version.container != null) {
      parts.add(version.container!.toUpperCase());
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' \u2022 '),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}
