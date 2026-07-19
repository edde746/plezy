import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/providers/trakt_account_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetSharedPreferencesForTest);

  test('Jellyfin Favorites disappears offline and restores the persisted source preference', () async {
    final client = testJellyfinClient();
    final manager = MultiServerManager()..debugRegisterJellyfinClientForTesting(client);
    final multiServer = MultiServerProvider(manager, DataAggregationService(manager));
    final trakt = TraktAccountProvider();
    final trackers = TrackersProvider();
    final seerr = SeerrAccountProvider();
    final hiddenLibraries = HiddenLibrariesProvider();
    final sources = CatalogSourcesProvider();
    addTearDown(sources.dispose);
    addTearDown(seerr.dispose);
    addTearDown(trackers.dispose);
    addTearDown(trakt.dispose);
    addTearDown(hiddenLibraries.dispose);
    addTearDown(multiServer.dispose);
    addTearDown(manager.dispose);

    await sources.onActiveProfileChanged('profile-1');
    await hiddenLibraries.ensureInitialized();
    sources.update(trakt, trackers, seerr, multiServer, hiddenLibraries);
    expect(sources.connectedSources.map((source) => source.id), [CatalogSourceId.jellyfin]);

    await sources.setActiveSource(CatalogSourceId.jellyfin);
    expect(sources.activeSource?.id, CatalogSourceId.jellyfin);

    manager.debugMarkAuthErrorForTesting(client.serverId);
    await pumpEventQueue();
    sources.update(trakt, trackers, seerr, multiServer, hiddenLibraries);
    expect(sources.hasAnySource, isFalse);
    expect(sources.activeSource, isNull);

    manager.debugRegisterJellyfinClientForTesting(client);
    sources.update(trakt, trackers, seerr, multiServer, hiddenLibraries);
    expect(sources.activeSource?.id, CatalogSourceId.jellyfin);
  });
}
