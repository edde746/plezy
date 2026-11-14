import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_backend.dart';
import '../../services/music/audio_route_service.dart';
import '../../services/music/music_output.dart';
import '../../services/music/music_output_controller.dart';
import '../../services/music/music_playback_service.dart';
import '../../services/music_assistant/music_assistant_api.dart';
import '../../services/music_assistant/music_assistant_players.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../app_icon.dart';
import '../bottom_sheet_header.dart';
import '../loading_indicator_box.dart';
import '../overlay_sheet.dart';
import 'airplay_route_button.dart';

/// Open the output picker.
///
/// [OverlaySheetController.showAdaptive], not `of(context).show`, because this
/// is reached from the album and artist action bars as well as from the
/// now-playing screen. Those bars are built from their screen's `State`
/// context, which sits *above* the [OverlaySheetHost] the detail-screen mixin
/// installs in `build` — the same trap the now-playing screen documents and
/// works around with a keyed child. `of` asserts there, so the button threw
/// instead of opening. The adaptive form uses the host when the calling
/// context can see one and a modal sheet when it cannot.
Future<void> showOutputPickerSheet(BuildContext context) {
  // Captured here and re-provided below, because the modal fallback builds
  // against the navigator rather than inside the profile session's provider
  // scope. Without this the sheet could not see the controller and, worse,
  // read that as "the phone is selected" — so choosing a speaker and
  // reopening the picker showed the tick back on This device.
  //
  // The calling context always has them: every entry point is inside the
  // session. `.value` keeps the same instances, so `watch` inside the sheet
  // still rebuilds when the selection or the route changes.
  final controller = OutputPickerSheet._maybe<MusicOutputController>(context, listen: false);
  final routes = OutputPickerSheet._maybe<AudioRouteService>(context, listen: false);
  return OverlaySheetController.showAdaptive<void>(
    context,
    showDragHandle: true,
    builder: (_) {
      Widget sheet = const OutputPickerSheet();
      if (routes != null) {
        sheet = ChangeNotifierProvider<AudioRouteService>.value(value: routes, child: sheet);
      }
      if (controller != null) {
        sheet = ChangeNotifierProvider<MusicOutputController>.value(value: controller, child: sheet);
      }
      return sheet;
    },
  );
}

/// "Where does this come out?" — the control the whole Sonos feature exists
/// for.
///
/// One tap from the mini player and from the now-playing screen, because the
/// thing it answers ("play this in the kitchen") is a decision people make
/// *while* choosing music, not something to go hunting for in settings.
///
/// ### Three paths, and why they are drawn as three
///
/// There are exactly three ways audio can leave this app, and two of them can
/// end at the same physical speaker:
///
///  1. **This phone.** The local engine decodes and plays. Closing the app
///     stops it.
///  2. **AirPlay.** Still the local engine — same decoding, same battery, same
///     queue — with iOS carrying the result onward. The phone is the source,
///     so walking out of the house takes the music with it.
///  3. **Music Assistant.** The server fetches and plays. The phone is a
///     remote control, and playback survives it locking, backgrounding or
///     leaving.
///
/// Naming them is not enough, because "Dining Room" appears under both (2) and
/// (3) and they behave completely differently. So every option carries one
/// line, directly beneath it, saying what happens to the music when the phone
/// goes away — the only difference that actually matters at the moment of
/// choosing. The captions sit under their own row rather than at the foot of a
/// group because a sentence placed after two rows explains neither.
///
/// The phone and AirPlay share a header, which is the other half of the
/// lesson: they are the same engine. What the header groups is "this phone is
/// playing", and Music Assistant's group is "it is not".
///
/// Unavailable rooms are listed and greyed with the reason attached rather
/// than hidden. A speaker that has silently vanished from the list reads as a
/// bug in the app; "In use by Spotify" reads as an answer.
class OutputPickerSheet extends StatefulWidget {
  const OutputPickerSheet({super.key});

  /// Look up a provider without making its absence fatal.
  ///
  /// This sheet is opened from the mini player, which is mounted *above* the
  /// navigator, and `showAdaptive` falls back to a modal route when the
  /// calling context cannot see a sheet host. A modal route builds against the
  /// navigator rather than inside the profile session's provider scope, so a
  /// plain `watch` can throw — and a throw during build replaces the whole
  /// sheet with an error widget, which is how this rendered as a drag handle
  /// with nothing under it while audio was playing.
  ///
  /// Degrading is the right answer rather than asserting: every part of this
  /// sheet that needs a provider has a truthful thing to show without one.
  /// Pass `listen: false` from callbacks — `watch` outside a build is a
  /// framework assertion, not a lookup failure, so the `try` below cannot
  /// catch it.
  static T? _maybe<T extends Object>(BuildContext context, {bool listen = true}) {
    try {
      return listen ? context.watch<T>() : context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  State<OutputPickerSheet> createState() => _OutputPickerSheetState();

  static Future<void> _selectThisDevice(BuildContext context) async =>
      _maybe<MusicOutputController>(context, listen: false)?.select(MusicOutput.thisDevice);

  /// What to call the phone's own output.
  ///
  /// Blank for the built-in speaker — "This device" already says it — and the
  /// system's name for anything else, so headphones and a car stereo are named
  /// rather than hidden behind a label that claims the phone is playing out
  /// loud.
  static String? _phoneSubtitle(AudioRouteService? routes) {
    if (routes == null || !routes.supported || routes.isAirPlay) return null;
    final route = routes.route;
    if (route.name.isEmpty || route.kind == AudioRouteKind.speaker) return null;
    return route.name;
  }

  static IconData _phoneIcon(AudioRouteService? routes) => switch (routes?.route.kind) {
    AudioRouteKind.headphones => Symbols.headphones_rounded,
    AudioRouteKind.bluetooth => Symbols.bluetooth_rounded,
    AudioRouteKind.car => Symbols.directions_car_rounded,
    AudioRouteKind.wired => Symbols.cable_rounded,
    _ => Symbols.smartphone_rounded,
  };
}

class _OutputPickerSheetState extends State<OutputPickerSheet> {
  /// Swapped in place rather than opened as a second sheet: this one may be a
  /// modal or an overlay depending on where it was opened from, and a sheet on
  /// a sheet has to get that right twice.
  bool _choosingRooms = false;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final controller = OutputPickerSheet._maybe<MusicOutputController>(context);
    if (_choosingRooms && controller != null) {
      return _RoomGroupPicker(controller: controller, onBack: () => setState(() => _choosingRooms = false));
    }
    // Watched, not read: picking a destination in the system picker changes
    // the route while this sheet is still on screen, and the row has to move
    // its tick without the user doing anything else.
    final routes = OutputPickerSheet._maybe<AudioRouteService>(context);
    // "This device" is not sourced from the controller. It is the output that
    // is playing right now, so it has to be on screen even when the list it
    // would come from is unreachable — a picker that cannot show what is
    // currently making sound is broken in the most basic way it can be.
    final outputs = controller?.outputs ?? const <MusicOutput>[MusicOutput.thisDevice];
    final remote = outputs.where((output) => output.isRemote).toList(growable: false);

    // No controller means the selection is *unknown*, not the phone. Ticking a
    // row on a guess is worse than ticking none: it tells the user their
    // speaker choice was discarded when it was not.
    final onPhone = controller?.selected.isThisDevice ?? false;
    final airPlayEngaged = routes?.isAirPlay ?? false;
    // The two local rows split one selection between them. `thisDevice` is a
    // single output in the controller — as it should be, since it is one
    // engine — and which of the two rows is ticked is decided by the route,
    // not by a second entry in the output list.
    final phoneSelected = onPhone && !airPlayEngaged;
    final airPlaySelected = onPhone && airPlayEngaged;
    // A Music Assistant track plays only on that server's speakers. Moving it
    // to the phone stops the speaker and leaves nothing that can play, so the
    // row says why instead of offering it.
    final loaded = OutputPickerSheet._maybe<MusicPlaybackService>(context)?.currentTrack;
    final phoneCannotPlay = !onPhone && loaded?.backend == MediaBackend.musicAssistant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(
          title: t.music.playOn,
          action: IconButton(
            icon: AppIcon(Symbols.refresh_rounded, color: tk.textMuted),
            tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            onPressed: () {
              unawaited(controller?.refresh() ?? Future<void>.value());
              unawaited(routes?.refresh() ?? Future<void>.value());
            },
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              _OutputTile(
                title: t.music.outputThisDevice,
                // The route's own name when it is something other than the
                // built-in speaker: with AirPods connected, "This device" is
                // true about the engine and misleading about where the sound
                // is, and the system already has the better word for it.
                subtitle: phoneCannotPlay
                    ? t.music.outputThisDeviceMusicAssistant
                    : OutputPickerSheet._phoneSubtitle(routes),
                selected: phoneSelected,
                icon: OutputPickerSheet._phoneIcon(routes),
                enabled: !phoneCannotPlay,
                onTap: () {
                  unawaited(OutputPickerSheet._selectThisDevice(context));
                  Navigator.of(context).maybePop();
                },
              ),
              // AirPlay is the phone's engine too, so it fails the same way.
              if (routes != null && routes.supported && !phoneCannotPlay) ...[
                _AirPlayTile(
                  selected: airPlaySelected,
                  route: routes.route,
                  onSelectPhoneEngine: () => unawaited(OutputPickerSheet._selectThisDevice(context)),
                ),
              ],
              if (remote.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.music.outputNoneFound,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tk.text),
                      ),
                      const SizedBox(height: 4),
                      Text(t.music.outputNoneFoundDetail, style: TextStyle(fontSize: 13, color: tk.textMuted)),
                    ],
                  ),
                )
              else ...[
                _SectionLabel(t.music.outputSectionServer),
                for (final output in remote)
                  _OutputTile(
                    title: output.name,
                    subtitle: output.unavailableReason,
                    selected: controller?.selected.id == output.id,
                    icon: output.isGroup ? Symbols.speaker_group_rounded : Symbols.speaker_rounded,
                    enabled: output.available,
                    onTap: () {
                      unawaited(controller?.select(output) ?? Future<void>.value());
                      Navigator.of(context).maybePop();
                    },
                  ),
                if ((controller?.groupableRooms.length ?? 0) >= 2)
                  _OutputTile(
                    title: t.music.outputGroupAction,
                    subtitle: null,
                    selected: false,
                    icon: Symbols.add_rounded,
                    enabled: true,
                    onTap: () => setState(() => _choosingRooms = true),
                  ),
                // Only worth saying once there is something to confuse it
                // with: with no AirPlay on the platform, or no server players,
                // there is no double-listed speaker to explain.
                if (routes != null && routes.supported) _Caption(t.music.outputAirPlaySameSpeakerNote),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tick rooms, then play to them together.
///
/// A sync group belongs to one server, so the first room ticked rules out any
/// room on another. The sheet stays up until the group exists: the failures
/// here are ones the user can act on, by unticking a room or signing in as an
/// admin, and that needs the ticks still on screen.
class _RoomGroupPicker extends StatefulWidget {
  const _RoomGroupPicker({required this.controller, required this.onBack});

  final MusicOutputController controller;
  final VoidCallback onBack;

  @override
  State<_RoomGroupPicker> createState() => _RoomGroupPickerState();
}

class _RoomGroupPickerState extends State<_RoomGroupPicker> {
  late final Set<String> _ticked = {
    if (widget.controller.groupableRooms.contains(widget.controller.selected)) widget.controller.selected.id,
  };
  bool _busy = false;
  String? _error;

  List<MusicOutput> get _tickedRooms =>
      widget.controller.groupableRooms.where((room) => _ticked.contains(room.id)).toList(growable: false);

  Future<void> _play() async {
    final rooms = _tickedRooms;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.selectGroup(rooms);
      if (mounted) await Navigator.of(context).maybePop();
    } catch (e, st) {
      appLogger.w('Could not group ${rooms.length} speakers', error: e, stackTrace: st);
      if (mounted) setState(() => _error = _describe(e, rooms));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _describe(Object error, List<MusicOutput> rooms) => switch (error) {
    MaGroupRefusedException(:final refused) => t.music.outputGroupRefused(
      names: rooms.where((room) => refused.contains(room.playerId)).map((room) => room.name).join(', '),
    ),
    MaRequestException(isPermissionDenied: true) => t.music.outputGroupNeedsAdmin,
    MaException(:final message) => t.music.outputGroupFailed(error: message),
    _ => t.music.outputGroupFailed(error: error.toString()),
  };

  @override
  Widget build(BuildContext context) {
    final rooms = widget.controller.groupableRooms;
    final ticked = _tickedRooms;
    final server = ticked.isEmpty ? null : ticked.first.serverId;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(title: t.music.outputGroupAction, onBack: _busy ? null : widget.onBack),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final room in rooms)
                CheckboxListTile(
                  title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  value: _ticked.contains(room.id),
                  onChanged: _busy || (server != null && room.serverId != server)
                      ? null
                      : (on) => setState(() => on == true ? _ticked.add(room.id) : _ticked.remove(room.id)),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(error, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy || ticked.length < 2 ? null : () => unawaited(_play()),
              child: _busy
                  ? const LoadingIndicatorBox()
                  : Text(ticked.length < 2 ? t.music.outputGroupPickTwo : t.music.outputGroupPlay(n: ticked.length)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The AirPlay row.
///
/// Two affordances on purpose, because the row answers two different
/// questions. Tapping the body says "the phone is the source" and hands the
/// engine back to the local player — which is what a user coming from a Sonos
/// selection needs, and what makes the tick meaningful. The trailing control
/// is Apple's own route button and answers "which destination", because that
/// is a question only the system can be asked.
///
/// The sheet is deliberately *not* dismissed by either. The system picker
/// slides up over this sheet, and popping it first would take the route button
/// down with the thing that presented it.
class _AirPlayTile extends StatelessWidget {
  const _AirPlayTile({required this.selected, required this.route, required this.onSelectPhoneEngine});

  final bool selected;
  final AudioRoute route;
  final VoidCallback onSelectPhoneEngine;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : tk.text;
    final subtitle = selected && route.name.isNotEmpty
        ? t.music.outputAirPlayActive(name: route.name)
        : t.music.outputAirPlayChoose;

    return ListTile(
      leading: AppIcon(Symbols.airplay_rounded, color: foreground, fill: selected ? 1 : 0),
      title: Text(
        t.music.outputAirPlay,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: foreground),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: tk.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) AppIcon(Symbols.check_rounded, color: colorScheme.primary),
          AirPlayRouteButton(tint: tk.text, activeTint: colorScheme.primary),
        ],
      ),
      onTap: onSelectPhoneEngine,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tk.textMuted),
      ),
    );
  }
}

/// The one line that tells a group apart from the other groups.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Text(text, style: TextStyle(fontSize: 12, height: 1.35, color: tk.textMuted)),
    );
  }
}

class _OutputTile extends StatelessWidget {
  const _OutputTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = !enabled
        ? tk.textMuted
        : selected
        ? colorScheme.primary
        : tk.text;
    final subtitleText = subtitle;

    return ListTile(
      enabled: enabled,
      leading: AppIcon(icon, color: foreground, fill: selected ? 1 : 0),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: foreground),
      ),
      subtitle: subtitleText == null
          ? null
          : Text(
              subtitleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tk.textMuted),
            ),
      trailing: selected ? AppIcon(Symbols.check_rounded, color: colorScheme.primary) : null,
      onTap: enabled ? onTap : null,
    );
  }
}
