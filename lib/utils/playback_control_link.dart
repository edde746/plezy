import '../services/playback_coordinator.dart';

/// A small Android intent surface for Home Assistant and other automation
/// tools. Control links address the already-active player only and never
/// start content from an untrusted URL.
class PlaybackControlLink {
  const PlaybackControlLink._(this.command);

  static const scheme = 'plezy';
  static const host = 'control';

  final String command;

  static PlaybackControlLink? tryParse(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    final command = uri.queryParameters['command']?.trim().toLowerCase();
    if (command == null || !const {'play', 'pause', 'toggle', 'stop'}.contains(command)) return null;
    return PlaybackControlLink._(command);
  }

  Future<bool> launch() => switch (command) {
    'stop' => PlaybackCoordinator.instance.stopVideoAndExit(),
    'play' => PlaybackCoordinator.instance.controlVideo(VideoAutomationCommand.play),
    'pause' => PlaybackCoordinator.instance.controlVideo(VideoAutomationCommand.pause),
    'toggle' => PlaybackCoordinator.instance.controlVideo(VideoAutomationCommand.toggle),
    _ => Future.value(false),
  };
}
