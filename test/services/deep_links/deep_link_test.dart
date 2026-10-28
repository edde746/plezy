import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/screens/video_player/live_tv_session_args.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/utils/external_ids.dart';

LiveTvChannel _channel(String key, {String? identifier, String? number, String? callSign}) =>
    LiveTvChannel(key: key, identifier: identifier, number: number, callSign: callSign, hd: false);

Profile _local(String id, String name) => Profile.local(id: id, displayName: name, createdAt: DateTime(2026));

Profile _home(String id, String name, String uuid) =>
    Profile.plexHome(id: id, displayName: name, plexHomeUserUuid: uuid, createdAt: DateTime(2026));

void main() {
  group('DeepLink.tryParse', () {
    test('reads an item on a server, of any backend', () {
      final link = DeepLink.tryParse('plezy://play?server=abc123&id=42&mode=shuffle&profile=Kids') as PlayLink;
      expect(link.target, ItemPlayTarget(serverId: ServerId('abc123'), itemId: '42'));
      expect(link.mode, PlayMode.shuffle);
      expect(link.profile, 'Kids');
    });

    test('reads the launcher shelf content id', () {
      final link = DeepLink.tryParse('plezy://play?content_id=plezy_abc123_42') as PlayLink;
      expect(link.target, ItemPlayTarget(serverId: ServerId('abc123'), itemId: '42'));
      expect(link.mode, PlayMode.next);
    });

    test('reads a catalogue title and normalizes its ids', () {
      final link = DeepLink.tryParse('plezy://play?type=Show&tvdb=81189&imdb=TT0903747&plex=5d9c086c46115600200aa2fe');
      expect(
        (link! as PlayLink).target,
        const CatalogPlayTarget(
          kind: MediaKind.show,
          ids: ExternalIds(tvdb: 81189, imdb: 'tt0903747'),
          plexHash: '5d9c086c46115600200aa2fe',
        ),
      );
      expect(((link as PlayLink).target as CatalogPlayTarget).plexGuid, 'plex://show/5d9c086c46115600200aa2fe');
    });

    test('reads a live channel', () {
      final link = DeepLink.tryParse('plezy://live?channel=4.1&server=abc123&start=beginning') as LiveLink;
      expect(link.channel, '4.1');
      expect(link.serverId, 'abc123');
      expect(link.startPosition, LiveTvStartPosition.beginning);
      expect((DeepLink.tryParse('plezy://live?channel=KNTV')! as LiveLink).startPosition, LiveTvStartPosition.ask);
      expect(
        (DeepLink.tryParse('plezy://live?channel=4&start=live')! as LiveLink).startPosition,
        LiveTvStartPosition.live,
      );
    });

    test('reads open with and without a profile', () {
      expect((DeepLink.tryParse('plezy://open')! as OpenLink).profile, isNull);
      expect((DeepLink.tryParse('plezy://open?profile=%20Kids%20')! as OpenLink).profile, 'Kids');
      expect(DeepLink.tryParse('PLEZY://OPEN'), isA<OpenLink>());
    });

    test('keeps an external player return link whole', () {
      const url = 'plezy://external-player/success/s1?position=12.5&duration=1420.016';
      final link = DeepLink.tryParse(url) as ExternalPlayerReturnLink;
      expect(link.uri.toString(), url);
    });

    test('rejects links that do not say what to play', () {
      for (final url in [
        'https://example.com/play?server=a&id=1',
        'plezy://unknown',
        'plezy://play',
        'plezy://play?id=42',
        'plezy://play?server=abc123',
        'plezy://play?server=abc123&id=42&mode=random',
        'plezy://play?content_id=garbage',
        'plezy://play?type=movie',
        'plezy://play?type=episode&tmdb=1',
        'plezy://play?type=movie&tmdb=12a',
        'plezy://play?type=movie&tmdb=99999999999999999999999',
        'plezy://play?type=movie&imdb=0903747',
        'plezy://play?type=movie&plex=not-a-hash',
        'plezy://live',
        'plezy://live?channel=',
        'plezy://live?channel=4&start=sideways',
        'plezy://play?server=a&id=%E0%A4%A',
      ]) {
        expect(DeepLink.tryParse(url), isNull, reason: url);
      }
    });

    test('a link written out parses back to the same link', () {
      final links = <DeepLink>[
        const OpenLink(),
        const OpenLink(profile: 'Kids'),
        PlayLink(
          target: ItemPlayTarget(serverId: ServerId('srv 1'), itemId: 'a/b&c'),
        ),
        const PlayLink(
          target: CatalogPlayTarget(
            kind: MediaKind.movie,
            ids: ExternalIds(tmdb: 603, imdb: 'tt0133093'),
          ),
          profile: 'plex-home-1',
        ),
        const PlayLink(
          target: CatalogPlayTarget(kind: MediaKind.show, plexHash: '5d9c086c46115600200aa2fe'),
          mode: PlayMode.shuffle,
        ),
        LiveLink(channel: 'KNTV & co', serverId: ServerId('abc'), startPosition: LiveTvStartPosition.live),
      ];
      for (final link in links) {
        final reparsed = DeepLink.tryParse(link.toUri().toString());
        expect(reparsed?.toUri(), link.toUri(), reason: link.toUri().toString());
        expect(reparsed?.profile, link.profile);
        if (link is PlayLink) {
          final play = reparsed! as PlayLink;
          expect(play.target, link.target);
          expect(play.mode, link.mode);
        }
      }
    });
  });

  group('LiveLink.selectChannel', () {
    final channels = [
      _channel('k1', identifier: '004.1', number: '4.1', callSign: 'KNTVDT'),
      _channel('k2', identifier: '011.1', number: '11.1', callSign: 'KNTVDT2'),
      _channel('k3', identifier: '036.1', number: '4.1', callSign: 'KICU'),
    ];

    LiveTvChannel? select(String channel) => LiveLink(channel: channel).selectChannel(channels);

    test('matches key, identifier, unique number and case-insensitive call sign', () {
      expect(select('k2')?.key, 'k2');
      expect(select('036.1')?.key, 'k3');
      expect(select('11.1')?.key, 'k2');
      expect(select('kntvdt')?.key, 'k1');
    });

    test('returns null for ambiguous or unknown channels', () {
      expect(select('4.1'), isNull);
      expect(select('999'), isNull);
    });
  });

  group('resolveLinkProfile', () {
    final max = _home('plex-home-a-max', 'Max', 'AAAA1111');
    final kids = _local('local-1', 'Kids');
    final leo = _home('plex-home-a-leo', 'Leo', 'BBBB2222');

    test('matches the profile id, then the Plex Home UUID, then the name', () {
      final profiles = [max, kids, leo];
      expect(resolveLinkProfile(profiles, 'local-1'), kids);
      expect(resolveLinkProfile(profiles, 'bbbb2222'), leo);
      expect(resolveLinkProfile(profiles, ' kids '), kids);
    });

    test('an id beats a display name that happens to equal it', () {
      final named = _local('local-2', 'local-1');
      expect(resolveLinkProfile([named, kids], 'local-1'), kids);
    });

    test('returns null for an unknown or ambiguous reference', () {
      expect(resolveLinkProfile([max, kids], 'Nobody'), isNull);
      expect(resolveLinkProfile([kids, _local('local-3', 'KIDS')], 'kids'), isNull);
    });

    test('generated references resolve to the same profile', () {
      final profiles = [max, kids, leo];
      for (final profile in profiles) {
        expect(resolveLinkProfile(profiles, linkProfileRef(profile)), profile);
      }
    });
  });
}
