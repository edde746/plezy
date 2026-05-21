import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/models/livetv_channel.dart';
import 'package:vibe_stream/models/livetv_program.dart';
import 'package:vibe_stream/utils/live_tv_matching.dart';

void main() {
  test('matches channel by id and server', () {
    final program = LiveTvProgram(title: 'News', channelIdentifier: '101', serverId: 'server-a');

    expect(liveTvProgramMatchesChannel(program, LiveTvChannel(key: '101', serverId: 'server-a')), isTrue);
    expect(liveTvProgramMatchesChannel(program, LiveTvChannel(key: '101', serverId: 'server-b')), isFalse);
  });

  test('matches channel identifier fallback', () {
    final program = LiveTvProgram(title: 'News', channelIdentifier: 'station-101', serverId: 'server-a');
    final channel = LiveTvChannel(key: '101', identifier: 'station-101', serverId: 'server-a');

    expect(liveTvProgramMatchesChannel(program, channel), isTrue);
  });

  test('uses provider identifier when duplicate channels exist on one server', () {
    final program = LiveTvProgram(
      title: 'News',
      channelIdentifier: '101',
      serverId: 'server-a',
      providerIdentifier: 'provider-a',
    );

    final matching = LiveTvChannel(key: '101', serverId: 'server-a', favoriteSource: 'server://machine/provider-a');
    final otherProvider = LiveTvChannel(
      key: '101',
      serverId: 'server-a',
      favoriteSource: 'server://machine/provider-b',
    );

    expect(liveTvProgramMatchesChannel(program, matching), isTrue);
    expect(liveTvProgramMatchesChannel(program, otherProvider), isFalse);
  });
}
