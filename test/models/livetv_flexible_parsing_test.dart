import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_dvr.dart';
import 'package:plezy/models/livetv_lineup.dart';
import 'package:plezy/models/media_grabber_device.dart';
import 'package:plezy/models/media_provider_info.dart';
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

    final grabber = MediaGrabberDevice.fromJson({
      'key': 'device-1',
      'uuid': 'device-1',
      'ChannelMapping': [
        {'channelKey': 7},
        {'channelKey': 'channel-1'},
      ],
      'Setting': [
        {'id': 7},
        {'id': 'setting-1'},
      ],
    });
    expect(grabber.channelMappings.map((entry) => entry.channelKey), ['channel-1']);
    expect(grabber.settings.map((entry) => entry.id), ['setting-1']);

    final lineup = LiveTvLineup.fromJson({
      'uuid': 'lineup-1',
      'Channel': [
        {'callSign': 7},
        {'key': 'channel-1', 'callSign': 'ONE'},
      ],
    });
    expect(lineup.channels.map((entry) => entry.callSign), ['ONE']);

    final provider = MediaProviderInfo.fromJson({
      'identifier': 'provider-1',
      'Feature': [
        {'type': 7},
        {
          'type': 'livetv',
          'Directory': [
            'invalid',
            {'key': 'guide'},
          ],
        },
      ],
    });
    expect(provider.features.map((entry) => entry.type), ['livetv']);
    expect(provider.features.single.directories, [
      {'key': 'guide'},
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
