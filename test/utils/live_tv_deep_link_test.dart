import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/screens/video_player/live_tv_session_args.dart';
import 'package:plezy/utils/live_tv_deep_link.dart';

LiveTvChannel _channel(String key, {String? identifier, String? number, String? callSign}) =>
    LiveTvChannel(key: key, identifier: identifier, number: number, callSign: callSign, hd: false);

void main() {
  group('LiveTvDeepLink.tryParse', () {
    test('parses channel, server and start position', () {
      final link = LiveTvDeepLink.tryParse('plezy://live?channel=4.1&server=abc123&start=beginning');
      expect(link, isNotNull);
      expect(link!.channel, '4.1');
      expect(link.serverId, 'abc123');
      expect(link.startPosition, LiveTvStartPosition.beginning);
    });

    test('defaults to asking and any server', () {
      final link = LiveTvDeepLink.tryParse('plezy://live?channel=KNTV');
      expect(link!.serverId, isNull);
      expect(link.startPosition, LiveTvStartPosition.ask);
    });

    test('accepts live start', () {
      expect(LiveTvDeepLink.tryParse('plezy://live?channel=4&start=live')!.startPosition, LiveTvStartPosition.live);
    });

    test('rejects other links and malformed input', () {
      expect(LiveTvDeepLink.tryParse('plezy_server_123'), isNull);
      expect(LiveTvDeepLink.tryParse('plezy://play?content_id=plezy_a_1'), isNull);
      expect(LiveTvDeepLink.tryParse('plezy://live'), isNull);
      expect(LiveTvDeepLink.tryParse('plezy://live?channel='), isNull);
      expect(LiveTvDeepLink.tryParse('plezy://live?channel=4&start=sideways'), isNull);
    });
  });

  group('LiveTvDeepLink.selectChannel', () {
    final channels = [
      _channel('k1', identifier: '004.1', number: '4.1', callSign: 'KNTVDT'),
      _channel('k2', identifier: '011.1', number: '11.1', callSign: 'KNTVDT2'),
      _channel('k3', identifier: '036.1', number: '4.1', callSign: 'KICU'),
    ];

    LiveTvChannel? select(String channel) => LiveTvDeepLink(channel: channel).selectChannel(channels);

    test('matches key, identifier and case-insensitive call sign', () {
      expect(select('k2')?.key, 'k2');
      expect(select('036.1')?.key, 'k3');
      expect(select('kntvdt')?.key, 'k1');
    });

    test('matches a unique channel number', () {
      expect(select('11.1')?.key, 'k2');
    });

    test('returns null for ambiguous or unknown channels', () {
      expect(select('4.1'), isNull);
      expect(select('999'), isNull);
    });
  });
}
