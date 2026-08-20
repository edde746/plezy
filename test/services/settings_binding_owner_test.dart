import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_binding_owner.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('refreshes when a bound preference changes', () async {
    final settings = await SettingsService.getInstance();
    final values = <int>[];
    final binding = SettingsBindingOwner(
      prefs: [SettingsService.maxVolume],
      onRefresh: (service) => values.add(service.read(SettingsService.maxVolume)),
    );
    addTearDown(binding.dispose);

    await binding.bind();
    await settings.write(SettingsService.maxVolume, 175);

    expect(values, [100, 175]);
  });

  test('disposal before initialization ignores the stale completion', () async {
    final settings = await SettingsService.getInstance();
    final acquired = Completer<SettingsService>();
    var refreshes = 0;
    final binding = SettingsBindingOwner(
      prefs: [SettingsService.maxVolume],
      onRefresh: (_) => refreshes++,
      acquireSettings: () => acquired.future,
    );

    final initialized = binding.bind();
    binding.dispose();
    acquired.complete(settings);
    await initialized;
    await settings.write(SettingsService.maxVolume, 150);

    expect(refreshes, 0);
    expect(binding.isBound, isFalse);
  });

  test('duplicate binding shares initialization and registers one listener', () async {
    final settings = await SettingsService.getInstance();
    final acquired = Completer<SettingsService>();
    var acquisitions = 0;
    var refreshes = 0;
    final binding = SettingsBindingOwner(
      prefs: [SettingsService.maxVolume],
      onRefresh: (_) => refreshes++,
      acquireSettings: () {
        acquisitions++;
        return acquired.future;
      },
    );
    addTearDown(binding.dispose);

    final first = binding.bind();
    final second = binding.bind();
    acquired.complete(settings);
    await Future.wait([first, second]);
    await binding.bind();
    await settings.write(SettingsService.maxVolume, 125);

    expect(acquisitions, 2);
    expect(refreshes, 3);
  });

  test('does not refresh after disposal', () async {
    final settings = await SettingsService.getInstance();
    var refreshes = 0;
    final binding = SettingsBindingOwner(prefs: [SettingsService.maxVolume], onRefresh: (_) => refreshes++);

    await binding.bind();
    binding.dispose();
    await settings.write(SettingsService.maxVolume, 200);
    binding.refresh();

    expect(refreshes, 1);
  });
}
