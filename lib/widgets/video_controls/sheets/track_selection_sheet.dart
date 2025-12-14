import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../widgets/focusable_bottom_sheet.dart';
import 'base_video_control_sheet.dart';
import 'video_control_sheet_launcher.dart';
import '../helpers/track_filter_helper.dart';
import '../helpers/track_selection_helper.dart';

/// Generic track selection sheet for audio and subtitle tracks
///
/// Type parameter [T] should be either [AudioTrack] or [SubtitleTrack]
class TrackSelectionSheet<T> extends StatefulWidget {
  final Player player;
  final String title;
  final IconData icon;
  final List<T> Function(Tracks?) extractTracks;
  final T? Function(TrackSelection) getCurrentTrack;
  final String Function(T track, int index) buildLabel;
  final void Function(T track) setTrack;
  final Function(T)? onTrackChanged;
  final bool showOffOption;
  final T Function()? createOffTrack;
  final bool Function(T track)? isOffTrack;

  const TrackSelectionSheet({
    super.key,
    required this.player,
    required this.title,
    required this.icon,
    required this.extractTracks,
    required this.getCurrentTrack,
    required this.buildLabel,
    required this.setTrack,
    this.onTrackChanged,
    this.showOffOption = false,
    this.createOffTrack,
    this.isOffTrack,
  });

  static void show<T>({
    required BuildContext context,
    required Player player,
    required String title,
    required IconData icon,
    required List<T> Function(Tracks?) extractTracks,
    required T? Function(TrackSelection) getCurrentTrack,
    required String Function(T track, int index) buildLabel,
    required void Function(T track) setTrack,
    Function(T)? onTrackChanged,
    bool showOffOption = false,
    T Function()? createOffTrack,
    bool Function(T track)? isOffTrack,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    VideoControlSheetLauncher.show(
      context: context,
      onOpen: onOpen,
      onClose: onClose,
      builder: (context) => TrackSelectionSheet<T>(
        player: player,
        title: title,
        icon: icon,
        extractTracks: extractTracks,
        getCurrentTrack: getCurrentTrack,
        buildLabel: buildLabel,
        setTrack: setTrack,
        onTrackChanged: onTrackChanged,
        showOffOption: showOffOption,
        createOffTrack: createOffTrack,
        isOffTrack: isOffTrack,
      ),
    );
  }

  @override
  State<TrackSelectionSheet<T>> createState() => _TrackSelectionSheetState<T>();
}

class _TrackSelectionSheetState<T> extends State<TrackSelectionSheet<T>> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'TrackSelectionInitialFocus');
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
      child: StreamBuilder<Tracks>(
        stream: widget.player.streams.tracks,
        initialData: widget.player.state.tracks,
        builder: (context, snapshot) {
          final tracks = snapshot.data;
          final availableTracks = TrackFilterHelper.extractAndFilterTracks<T>(
            tracks,
            widget.extractTracks,
          );

          return BaseVideoControlSheet(
            title: widget.title,
            icon: widget.icon,
            child: availableTracks.isEmpty
                ? TrackSelectionHelper.buildEmptyState<T>()
                : StreamBuilder<TrackSelection>(
                    stream: widget.player.streams.track,
                    initialData: widget.player.state.track,
                    builder: (context, selectedSnapshot) {
                      final currentTrack =
                          selectedSnapshot.data ?? widget.player.state.track;
                      final selectedTrack = widget.getCurrentTrack(
                        currentTrack,
                      );

                      // Determine if "Off" is selected (null or explicit off)
                      final isOffSelected = TrackSelectionHelper.isOffSelected(
                        selectedTrack,
                        widget.isOffTrack,
                      );

                      final itemCount =
                          availableTracks.length +
                          (widget.showOffOption ? 1 : 0);

                      return ListView.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          // First item is "Off" if enabled
                          if (widget.showOffOption && index == 0) {
                            return TrackSelectionHelper.buildOffTile<T>(
                              isSelected: isOffSelected,
                              focusNode: _initialFocusNode,
                              onTap: () {
                                if (widget.createOffTrack != null) {
                                  final offTrack = widget.createOffTrack!();
                                  widget.setTrack(offTrack);
                                  widget.onTrackChanged?.call(offTrack);
                                }
                                Navigator.pop(context);
                              },
                            );
                          }

                          // Subsequent items are tracks
                          final trackIndex = widget.showOffOption
                              ? index - 1
                              : index;
                          final track = availableTracks[trackIndex];

                          // Check if this track is selected
                          final trackId = TrackSelectionHelper.getTrackId(
                            track,
                          );
                          final selectedId = selectedTrack == null
                              ? ''
                              : TrackSelectionHelper.getTrackId(selectedTrack);

                          final isSelected = trackId == selectedId;
                          final label = widget.buildLabel(track, trackIndex);

                          // Focus the first actual track if no "Off" option
                          final shouldFocus =
                              !widget.showOffOption && index == 0;

                          return TrackSelectionHelper.buildTrackTile<T>(
                            label: label,
                            isSelected: isSelected,
                            focusNode: shouldFocus ? _initialFocusNode : null,
                            onTap: () {
                              widget.setTrack(track);
                              widget.onTrackChanged?.call(track);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
