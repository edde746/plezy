import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/services/settings_mutation_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  testWidgets('shared settings writes, resets, and bulk replay reconcile Plex download quality', (tester) async {
    final settings = await SettingsService.getInstance();
    final downloads = _RecordingDownloads();
    addTearDown(downloads.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      ChangeNotifierProvider<DownloadProvider>.value(
        value: downloads,
        child: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const mutations = SettingsMutationService();
    const pref = SettingsService.defaultDownloadQualityPreset;
    await mutations.write(context, pref, TranscodeQualityPreset.p240_320);
    expect(settings.read(pref), TranscodeQualityPreset.p240_320);
    expect(downloads.reconciledPresets, [TranscodeQualityPreset.p240_320]);

    await mutations.write(context, pref, TranscodeQualityPreset.original, reset: true);
    expect(settings.prefs.containsKey(pref.key), isFalse);
    expect(downloads.reconciledPresets, [TranscodeQualityPreset.p240_320, TranscodeQualityPreset.original]);

    await settings.write(pref, TranscodeQualityPreset.p720_3mbps);
    await mutations.applyStoredEffects(
      context,
      previousRootConfiguration: SettingsMutationService.captureRootConfiguration(),
    );
    expect(downloads.reconciledPresets, [
      TranscodeQualityPreset.p240_320,
      TranscodeQualityPreset.original,
      TranscodeQualityPreset.p720_3mbps,
    ]);
  });
}

class _RecordingDownloads extends Fake with ChangeNotifier implements DownloadProvider {
  final reconciledPresets = <TranscodeQualityPreset>[];

  @override
  Future<void> reconcileAllDownloadQualities() async {
    reconciledPresets.add(SettingsService.instance.read(SettingsService.defaultDownloadQualityPreset));
  }
}
