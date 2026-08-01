import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/services/plex_discover_client.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetSharedPreferencesForTest);

  test('profile hydration exposes Plex when Discover credentials are available', () async {
    var calls = 0;
    final provider = CatalogSourcesProvider(
      plexSessionSupplier: () async {
        calls++;
        return const PlexDiscoverSession(accessToken: 'profile-token', clientIdentifier: 'client-id');
      },
    );
    addTearDown(provider.dispose);

    await provider.onActiveProfileChanged('profile-1');

    expect(calls, 1);
    expect(provider.connectedSources.map((source) => source.id), [CatalogSourceId.plex]);
    expect(provider.activeSource?.displayName, 'Plex');
    expect(provider.watchlistCapableSource?.id, CatalogSourceId.plex);
  });

  test('profile hydration omits Plex when the active profile has no Plex identity', () async {
    final provider = CatalogSourcesProvider(plexSessionSupplier: () async => null);
    addTearDown(provider.dispose);

    await provider.onActiveProfileChanged('profile-1');

    expect(provider.connectedSources, isEmpty);
    expect(provider.hasAnySource, isFalse);
  });

  test('Plex session lookup failure does not abort profile hydration', () async {
    final provider = CatalogSourcesProvider(plexSessionSupplier: () async => throw StateError('vault unavailable'));
    addTearDown(provider.dispose);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.onActiveProfileChanged('profile-1');

    expect(provider.connectedSources, isEmpty);
    expect(notifications, 1);
  });

  test('same-profile binding completion refreshes Plex connection state', () async {
    PlexDiscoverSession? session;
    var calls = 0;
    final provider = CatalogSourcesProvider(
      plexSessionSupplier: () async {
        calls++;
        return session;
      },
    );
    addTearDown(provider.dispose);

    await provider.onActiveProfileChanged('profile-1');
    await provider.onProfileBindingStateChanged(false);
    expect(calls, 1);
    expect(provider.connectedSources, isEmpty);

    await provider.onProfileBindingStateChanged(true);
    session = const PlexDiscoverSession(accessToken: 'connected', clientIdentifier: 'client-id');
    await provider.onProfileBindingStateChanged(false);
    expect(calls, 2);
    expect(provider.connectedSources.map((source) => source.id), [CatalogSourceId.plex]);

    await provider.onProfileBindingStateChanged(true);
    session = null;
    await provider.onProfileBindingStateChanged(false);
    expect(calls, 3);
    expect(provider.connectedSources, isEmpty);
  });
}
