import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music_assistant/music_assistant_players.dart';

MaPlayer _player({
  String id = 'RINCON_1',
  String name = '➡️ 🥙 Dining Room',
  bool available = true,
  String? activeSource = 'RINCON_1',
  List<String> childs = const [],
  int volume = 2,
  Set<String> features = const {'volume_set', 'seek', 'next_previous'},
}) => MaPlayer(
  playerId: id,
  name: name,
  provider: 'sonos',
  available: available,
  powered: true,
  state: MaPlayerState.idle,
  volumeLevel: volume,
  activeSource: activeSource,
  groupChilds: childs,
  supportedFeatures: features,
);

void main() {
  group('MusicOutput', () {
    test('ids are scoped by server, because a player id is only unique inside one', () {
      final a = MusicOutput.fromPlayer(_player(), serverId: 'server-a');
      final b = MusicOutput.fromPlayer(_player(), serverId: 'server-b');
      expect(a.id, 'server-a|RINCON_1');
      expect(a, isNot(b));
    });

    test('carries the speaker name through, emoji and all', () {
      expect(MusicOutput.fromPlayer(_player(), serverId: 's').name, '➡️ 🥙 Dining Room');
    });

    test('an unavailable room says why instead of disappearing', () {
      final output = MusicOutput.fromPlayer(_player(available: false, activeSource: 'airplay'), serverId: 's');
      expect(output.available, isFalse);
      expect(output.unavailableReason, 'In use by airplay');
    });

    test('an available room with a foreign source is still offered, with a note', () {
      // Measured: a Sonos playing Spotify reports available: true on 2.6.3.
      // Taking it over is legitimate; doing it without saying so is not.
      final output = MusicOutput.fromPlayer(_player(activeSource: 'Spotify'), serverId: 's');
      expect(output.available, isTrue);
      expect(output.unavailableReason, 'Playing Spotify');
    });

    test('a room Music Assistant is driving itself carries no note', () {
      expect(MusicOutput.fromPlayer(_player(), serverId: 's').unavailableReason, isNull);
    });

    test('capabilities come from the player rather than being assumed', () {
      final output = MusicOutput.fromPlayer(_player(features: const {}), serverId: 's');
      expect(output.supportsVolume, isFalse);
      expect(output.supportsSeek, isFalse);
    });

    test('a group is marked as one', () {
      expect(MusicOutput.fromPlayer(_player(childs: ['a']), serverId: 's').isGroup, isTrue);
    });

    test('thisDevice is local and always available', () {
      expect(MusicOutput.thisDevice.isThisDevice, isTrue);
      expect(MusicOutput.thisDevice.isRemote, isFalse);
      expect(MusicOutput.thisDevice.available, isTrue);
      expect(MusicOutput.thisDevice.serverId, isNull);
      expect(MusicOutput.thisDevice.playerId, isNull);
    });

    test('a remote output knows its queue id', () {
      final output = MusicOutput.fromPlayer(_player(), serverId: 's');
      expect(output.isRemote, isTrue);
      expect(output.playerId, 'RINCON_1');
      expect(output.serverId, 's');
    });

    test('copyWith keeps identity while refreshing the snapshot', () {
      final output = MusicOutput.fromPlayer(_player(volume: 2), serverId: 's');
      final refreshed = output.copyWith(volume: 40, available: false);
      expect(refreshed, output);
      expect(refreshed.volume, 40);
      expect(refreshed.available, isFalse);
    });
  });
}
