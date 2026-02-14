/// Native player factory implementation.
library;

import 'dart:io' show Platform;

import 'player.dart';
import 'player_android.dart';
import 'player_native.dart';
import 'platform/player_linux.dart';
import 'platform/player_windows.dart';

/// Creates a platform-specific player instance for native platforms.
Player createPlatformPlayer({bool? useExoPlayer}) {
  if (Platform.isAndroid) {
    final useExo = useExoPlayer ?? true;
    if (useExo) {
      return PlayerAndroid();
    }
    return PlayerNative();
  }
  if (Platform.isMacOS || Platform.isIOS) {
    return PlayerNative();
  }
  if (Platform.isWindows) {
    return PlayerWindows();
  }
  if (Platform.isLinux) {
    return PlayerLinux();
  }
  throw UnsupportedError('Player is not supported on this platform');
}
