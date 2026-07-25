import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/external_player_models.dart';

void main() {
  test('Linux exposes only known players whose commands are available', () {
    final players = KnownPlayers.getForCurrentPlatform();

    expect(players.map((player) => player.id), [
      'system_default',
      if (_commandIsAvailable('vlc')) 'vlc',
      if (_commandIsAvailable('mpv')) 'mpv',
      if (_commandIsAvailable('celluloid')) 'celluloid',
    ]);
  }, skip: !Platform.isLinux);
}

bool _commandIsAvailable(String command) {
  final result = Process.runSync('sh', ['-c', r'command -v "$1" >/dev/null 2>&1', 'plezy-test-command-probe', command]);
  return result.exitCode == 0;
}
