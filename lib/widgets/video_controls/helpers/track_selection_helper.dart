import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../mpv/mpv.dart';
import '../../../widgets/focusable_list_tile.dart';

/// Helper class for shared track selection logic
///
/// Provides common utilities for empty states, "Off" handling, and selection logic
class TrackSelectionHelper {
  /// Get the appropriate empty message based on track type
  static String getEmptyMessage<T>() {
    if (T == SubtitleTrack) {
      return 'No subtitles available';
    } else if (T == AudioTrack) {
      return 'No audio tracks available';
    }
    return 'No tracks available';
  }

  /// Build a centered empty state widget
  static Widget buildEmptyState<T>() {
    return Center(child: Text(getEmptyMessage<T>()));
  }

  /// Check if "Off" is selected for a track
  static bool isOffSelected<T>(T? selectedTrack, bool Function(T track)? isOffTrack) {
    return selectedTrack == null || (isOffTrack?.call(selectedTrack) ?? false);
  }

  /// Get the track ID from a track object
  static String getTrackId<T>(T track) {
    if (track is AudioTrack) {
      return track.id;
    } else if (track is SubtitleTrack) {
      return track.id;
    }
    return '';
  }

  /// Build the "Off" list tile for track selection
  static Widget buildOffTile<T>({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
    VoidCallback? onLongPress,
    VoidCallback? onSecondaryTap,
    Widget? badge,
  }) {
    return _buildSelectableTile(
      context: context,
      label: 'Off',
      isSelected: isSelected,
      onTap: onTap,
      focusNode: focusNode,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      badge: badge,
    );
  }

  /// Build a track selection list tile
  static Widget buildTrackTile<T>({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
    VoidCallback? onLongPress,
    VoidCallback? onSecondaryTap,
    Widget? badge,
  }) {
    return _buildSelectableTile(
      context: context,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      focusNode: focusNode,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      badge: badge,
    );
  }

  /// Build a numbered badge for primary/secondary subtitle indicators.
  static Widget buildTrackBadge(BuildContext context, int number) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(color: colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget _buildSelectableTile({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
    VoidCallback? onLongPress,
    VoidCallback? onSecondaryTap,
    Widget? badge,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    Widget? trailing;
    if (badge != null) {
      trailing = badge;
    } else if (isSelected) {
      trailing = AppIcon(Symbols.check_rounded, fill: 1, color: primaryColor);
    }

    Widget tile = FocusableListTile(
      focusNode: focusNode,
      title: Text(label, style: TextStyle(color: isSelected ? primaryColor : null)),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (onSecondaryTap != null) {
      tile = GestureDetector(onSecondaryTap: onSecondaryTap, child: tile);
    }

    return tile;
  }
}
