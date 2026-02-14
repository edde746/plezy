/// Web player factory implementation.
library;

import 'player.dart';
import 'player_web.dart';

/// Creates a web-based player instance using HTML5 <video>.
Player createPlatformPlayer({bool? useExoPlayer}) {
  return PlayerWeb();
}
