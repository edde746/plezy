import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_browser_dialect.dart';

/// Contract tests for the Jellyfin/Emby dialect discriminator.
///
/// The detection fixtures are verbatim `/System/Info/Public` bodies captured
/// from Jellyfin 10.10.7 and Emby 4.9.5, so a shape change on either server
/// surfaces here rather than as a mis-labelled connection.
void main() {
  group('MediaBrowserDialect ids', () {
    test('id round-trips through fromId', () {
      for (final dialect in MediaBrowserDialect.values) {
        expect(MediaBrowserDialect.fromId(dialect.id), dialect);
      }
    });

    test('fromId throws on an unknown id', () {
      expect(() => MediaBrowserDialect.fromId('plex'), throwsA(isA<ArgumentError>()));
    });

    test('ids match the MediaBackend ids they map to', () {
      for (final dialect in MediaBrowserDialect.values) {
        expect(dialect.backend.id, dialect.id);
        expect(dialect.backend.dialect, dialect);
      }
    });

    test('fromIdOrJellyfin tolerates legacy rows that carry no dialect', () {
      expect(MediaBrowserDialect.fromIdOrJellyfin(null), MediaBrowserDialect.jellyfin);
      expect(MediaBrowserDialect.fromIdOrJellyfin(''), MediaBrowserDialect.jellyfin);
      expect(MediaBrowserDialect.fromIdOrJellyfin('nonsense'), MediaBrowserDialect.jellyfin);
      expect(MediaBrowserDialect.fromIdOrJellyfin('emby'), MediaBrowserDialect.emby);
    });
  });

  group('MediaBrowserDialect capabilities', () {
    test('Jellyfin-only features are off for Emby', () {
      expect(MediaBrowserDialect.jellyfin.supportsQuickConnect, isTrue);
      expect(MediaBrowserDialect.emby.supportsQuickConnect, isFalse);

      expect(MediaBrowserDialect.jellyfin.supportsTrickplay, isTrue);
      expect(MediaBrowserDialect.emby.supportsTrickplay, isFalse);

      expect(MediaBrowserDialect.jellyfin.supportsMediaSegments, isTrue);
      expect(MediaBrowserDialect.emby.supportsMediaSegments, isFalse);

      // Emby resolves /Audio/{id}/Lyrics to audio streaming with `Lyrics` as
      // the container and starts a failing ffmpeg process, so this gate is
      // load-bearing rather than cosmetic.
      expect(MediaBrowserDialect.jellyfin.supportsLyrics, isTrue);
      expect(MediaBrowserDialect.emby.supportsLyrics, isFalse);

      expect(MediaBrowserDialect.jellyfin.supportsAggregateItemFilters, isTrue);
      expect(MediaBrowserDialect.emby.supportsAggregateItemFilters, isFalse);
    });

    test('only Emby needs the pre-10.9 user-scoped item routes', () {
      expect(MediaBrowserDialect.emby.requiresUserScopedItemRoutes, isTrue);
      expect(MediaBrowserDialect.jellyfin.requiresUserScopedItemRoutes, isFalse);
    });

    test('LAN discovery payloads are distinct so the datagram identifies the dialect', () {
      expect(MediaBrowserDialect.jellyfin.lanDiscoveryMessage, 'who is JellyfinServer?');
      expect(MediaBrowserDialect.emby.lanDiscoveryMessage, 'who is EmbyServer?');
    });

    test('Emby adds its 8920 HTTPS default to the port guesses', () {
      expect(MediaBrowserDialect.jellyfin.httpsPortGuesses, [8096]);
      expect(MediaBrowserDialect.emby.httpsPortGuesses, contains(8920));
      expect(MediaBrowserDialect.emby.httpsPortGuesses, contains(8096));
    });

    test('product names are the untranslated brand names', () {
      expect(MediaBrowserDialect.jellyfin.productName, 'Jellyfin');
      expect(MediaBrowserDialect.emby.productName, 'Emby');
    });
  });

  group('MediaBrowserDialect.detectFromPublicSystemInfo', () {
    test('identifies a real Jellyfin 10.10.7 body by ProductName', () {
      expect(
        MediaBrowserDialect.detectFromPublicSystemInfo(const {
          'LocalAddress': 'http://172.17.0.3:8096',
          'ServerName': '0c1d332b2f44',
          'Version': '10.10.7',
          'ProductName': 'Jellyfin Server',
          'OperatingSystem': '',
          'Id': 'c88f271ded7e42cf87e6b12c287906ac',
          'StartupWizardCompleted': true,
        }),
        MediaBrowserDialect.jellyfin,
      );
    });

    test('identifies a real Emby 4.9.5 body by its RemoteAddresses array', () {
      expect(
        MediaBrowserDialect.detectFromPublicSystemInfo(const {
          'LocalAddresses': <String>[],
          'RemoteAddresses': <String>[],
          'ServerName': '7befeeb2e8c9',
          'Version': '4.9.5.0',
          'Id': '9b6b1ea5ad4c4409a89f0f5e40607022',
        }),
        MediaBrowserDialect.emby,
      );
    });

    test('an explicit Emby ProductName wins over shape sniffing', () {
      expect(
        MediaBrowserDialect.detectFromPublicSystemInfo(const {'ProductName': 'Emby Server', 'Id': 'x'}),
        MediaBrowserDialect.emby,
      );
    });

    test('returns null when neither signal is present so the caller keeps the user choice', () {
      expect(MediaBrowserDialect.detectFromPublicSystemInfo(const {'ServerName': 'x', 'Id': 'y'}), isNull);
      expect(MediaBrowserDialect.detectFromPublicSystemInfo(const {'ProductName': ''}), isNull);
    });
  });

  group('MediaBackend MediaBrowser predicate', () {
    test('usesMediaBrowserApi covers Jellyfin and Emby but not Plex', () {
      expect(MediaBackend.plex.usesMediaBrowserApi, isFalse);
      expect(MediaBackend.jellyfin.usesMediaBrowserApi, isTrue);
      expect(MediaBackend.emby.usesMediaBrowserApi, isTrue);
      expect(MediaBackend.plex.dialect, isNull);
    });

    test('emby round-trips through the persisted id helpers', () {
      expect(MediaBackend.emby.id, 'emby');
      expect(MediaBackend.fromId('emby'), MediaBackend.emby);
      expect(MediaBackend.fromString('emby'), MediaBackend.emby);
    });

    test('a missing backend id still falls back to Plex for pre-Jellyfin cache rows', () {
      expect(MediaBackend.fromString(null), MediaBackend.plex);
    });
  });
}
