import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/services/settings_mutation_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

class _CountingDiscoverProvider extends DiscoverProvider {
  _CountingDiscoverProvider(super.multiServer, super.hiddenLibraries, super.libraries)
    : super(profileId: 'profile', isProfileBinding: () => false, syncSystemShelf: (_, _) async {});

  int loads = 0;

  @override
  Future<void> load() async => loads++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('switching Use Home Layout reloads the home hubs', (tester) async {
    final libraries = LibrariesProvider();
    addTearDown(libraries.dispose);
    final hiddenLibraries = HiddenLibrariesProvider();
    addTearDown(hiddenLibraries.dispose);
    final discover = _CountingDiscoverProvider(testMultiServer().provider, hiddenLibraries, libraries);
    addTearDown(discover.dispose);

    late BuildContext context;
    await tester.pumpWidget(
      ChangeNotifierProvider<DiscoverProvider>.value(
        value: discover,
        child: MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() => const SettingsMutationService().write(context, SettingsService.useGlobalHubs, false));

    expect(SettingsService.instance.read(SettingsService.useGlobalHubs), isFalse);
    expect(discover.loads, 1);
  });
}
