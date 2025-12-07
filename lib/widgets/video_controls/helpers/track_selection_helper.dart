import 'package:flutter/material.dart';
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
    return Center(
      child: Text(
        getEmptyMessage<T>(),
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  /// Check if "Off" is selected for a track
  static bool isOffSelected<T>(
    T? selectedTrack,
    bool Function(T track)? isOffTrack,
  ) {
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
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    return _buildSelectableTile(
      label: 'Off',
      isSelected: isSelected,
      onTap: onTap,
      focusNode: focusNode,
    );
  }

  /// Build a track selection list tile
  static Widget buildTrackTile<T>({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    return _buildSelectableTile(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      focusNode: focusNode,
    );
  }

  static Widget _buildSelectableTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    FocusNode? focusNode,
  }) {
    return FocusableListTile(
      focusNode: focusNode,
      title: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.blue : Colors.white),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }
}
