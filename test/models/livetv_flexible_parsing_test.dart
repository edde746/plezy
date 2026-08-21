import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_dvr.dart';
import 'package:plezy/models/media_subscription.dart';

void main() {
  test('Live TV collection models skip malformed entries and keep valid siblings', () {
    final dvr = LiveTvDvr.fromJson({
      'key': 'dvr-1',
      'ChannelMapping': [
        {'channelKey': 7},
        {'channelKey': 'channel-1'},
      ],
      'Setting': [
        {'id': 7},
        {'id': 'setting-1'},
      ],
      'Device': [
        'invalid',
        {'uuid': 'device-1'},
      ],
    });
    expect(dvr.channelMappings.map((entry) => entry.channelKey), ['channel-1']);
    expect(dvr.settings.map((entry) => entry.id), ['setting-1']);
    expect(dvr.devices, [
      {'uuid': 'device-1'},
    ]);

    final template = SubscriptionTemplate.fromJson({
      'MediaSubscription': [
        {'title': 7},
        {'key': 'subscription-1', 'title': 'Recordings'},
      ],
    });
    expect(template.subscriptions.map((entry) => entry.key), ['subscription-1']);
  });
}
