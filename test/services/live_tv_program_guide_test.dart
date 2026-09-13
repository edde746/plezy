import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/services/live_tv_program_guide.dart';

void main() {
  final channel = LiveTvChannel(key: 'A');
  final a = LiveTvProgram(title: 'History', channelIdentifier: 'A', beginsAt: 1000, endsAt: 2000);
  final b = LiveTvProgram(title: 'Current', channelIdentifier: 'A', beginsAt: 2000, endsAt: 3000);

  test('history is queried in epoch milliseconds and retained across partial refresh', () async {
    final guide = LiveTvProgramGuide();
    final owner = Object();
    await guide.refresh(
      owner: owner,
      channel: channel,
      fromEpoch: 1500,
      toEpoch: 3500,
      fetch: (from, to) async {
        expect(from.isUtc, isTrue);
        expect(from.millisecondsSinceEpoch, 1500000);
        expect(to.millisecondsSinceEpoch, 3500000);
        return [a, b];
      },
    );
    await guide.refresh(owner: owner, channel: channel, fromEpoch: 1600, toEpoch: 3500, fetch: (_, _) async => [b]);
    expect(guide.programs, [a, b]);
    await guide.refresh(owner: owner, channel: channel, fromEpoch: 2100, toEpoch: 3500, fetch: (_, _) async => [b]);
    expect(guide.programs, [b]);
  });

  test('empty Plex-style response marks retained history stale and corrected end replaces airing', () async {
    final guide = LiveTvProgramGuide();
    final owner = Object();
    final original = LiveTvProgram(
      title: 'Game',
      ratingKey: 'game',
      channelIdentifier: 'A',
      beginsAt: 1000,
      endsAt: 2000,
    );
    final corrected = LiveTvProgram(
      title: 'Game',
      ratingKey: 'game',
      channelIdentifier: 'A',
      beginsAt: 1000,
      endsAt: 2500,
    );
    await guide.refresh(
      owner: owner,
      channel: channel,
      fromEpoch: 1000,
      toEpoch: 3500,
      fetch: (_, _) async => [original],
    );
    await guide.refresh(owner: owner, channel: channel, fromEpoch: 1000, toEpoch: 3500, fetch: (_, _) async => []);
    expect(guide.programs, [original]);
    expect(guide.stale, isTrue);
    await guide.refresh(
      owner: owner,
      channel: channel,
      fromEpoch: 1000,
      toEpoch: 3500,
      fetch: (_, _) async => [corrected],
    );
    expect(guide.programs, [corrected]);
    expect(guide.stale, isFalse);
  });

  test('A to B to A rejects first A result and failure retains marked-stale history', () async {
    final guide = LiveTvProgramGuide();
    final first = Object();
    final second = Object();
    final delayed = Completer<List<LiveTvProgram>>();
    final old = guide.refresh(
      owner: first,
      channel: channel,
      fromEpoch: 1000,
      toEpoch: 3500,
      fetch: (_, _) => delayed.future,
    );
    guide.reset(Object());
    await guide.refresh(owner: second, channel: channel, fromEpoch: 1000, toEpoch: 3500, fetch: (_, _) async => [b]);
    delayed.complete([a]);
    expect(await old, isFalse);
    expect(guide.programs, [b]);
    await guide.refresh(
      owner: second,
      channel: channel,
      fromEpoch: 1000,
      toEpoch: 3500,
      fetch: (_, _) async => throw StateError('unavailable'),
    );
    expect(guide.programs, [b]);
    expect(guide.stale, isTrue);
  });
}
