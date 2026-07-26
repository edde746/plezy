import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

/// #1300 diagnostics: plays known test signals through a bare AVPlayer (via
/// the native AtmosProbe plugin) so a tester can read the receiver's format
/// display per test and isolate where Atmos output breaks.
class AtmosDiagnosticsScreen extends StatefulWidget {
  const AtmosDiagnosticsScreen({super.key});

  @override
  State<AtmosDiagnosticsScreen> createState() => _AtmosDiagnosticsScreenState();
}

class _AtmosDiagnosticsScreenState extends State<AtmosDiagnosticsScreen> {
  static const _channel = MethodChannel('plezy/atmos_probe');

  Timer? _poll;
  Map<Object?, Object?> _status = const {};
  String? _activeMode;
  bool _stopping = false;
  bool _routePickerVisible = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refreshStatus());
    _refreshStatus();
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (!_stopping) _channel.invokeMethod('stop').ignore();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _channel.invokeMethod<Map<Object?, Object?>>('getStatus');
      if (mounted && status != null) setState(() => _status = status);
    } on PlatformException {
      // native side unavailable (non-Apple build); leave the status empty
    }
  }

  /// AirPlay is the only route where the system resolves `renderingMode` and
  /// `supportedOutputChannelLayouts`, so the picker is what makes those arms of
  /// the matrix testable.
  Future<void> _toggleRoutePicker() async {
    final next = !_routePickerVisible;
    try {
      await _channel.invokeMethod(next ? 'showRoutePicker' : 'hideRoutePicker');
      if (!mounted) return;
      setState(() => _routePickerVisible = next);
    } on PlatformException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message ?? e.code);
    }
  }

  Future<void> _start(String mode) async {
    const urlModes = {'rawEc3', 'rawEc3Finite', 'asbarNative', 'asbarGenerated'};
    final needsUrl = urlModes.contains(mode);
    final url = SettingsService.instance.read(SettingsService.atmosProbeUrl);
    if (needsUrl && url.isEmpty) {
      showAppSnackBar(context, t.settings.atmosTestUrlMissing);
      return;
    }
    try {
      await _channel.invokeMethod('start', {
        'mode': mode,
        if (needsUrl) 'url': url,
        'sessionMode': SettingsService.instance.read(SettingsService.atmosProbeMoviePlaybackMode)
            ? 'moviePlayback'
            : 'default',
      });
      if (!mounted) return;
      setState(() => _activeMode = mode);
    } on PlatformException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message ?? e.code);
    }
    await _refreshStatus();
  }

  Future<void> _stop() async {
    if (_stopping) return;
    _stopping = true;
    try {
      await _channel.invokeMethod('stop');
      if (!mounted) return;
      setState(() => _activeMode = null);
      await _refreshStatus();
    } on PlatformException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message ?? e.code);
    } finally {
      _stopping = false;
    }
  }

  Widget _testTile({required String mode, required IconData icon, required String title, required String subtitle}) {
    final active = _activeMode == mode;
    return SettingNavigationTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailingIcon: active ? Symbols.graphic_eq_rounded : Symbols.play_arrow_rounded,
      onTap: () => _start(mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _status.entries.map((e) => '${e.key}: ${e.value}').join('\n');

    return SettingsPage(
      title: Text(t.settings.atmosDiagnostics),
      children: [
        SettingsGroup(
          children: [
            _testTile(
              mode: 'hlsAtmos',
              icon: Symbols.spatial_audio_rounded,
              title: t.settings.atmosTestHlsAtmos,
              subtitle: t.settings.atmosTestHlsAtmosDescription,
            ),
            _testTile(
              mode: 'hlsControl',
              icon: Symbols.surround_sound_rounded,
              title: t.settings.atmosTestHlsControl,
              subtitle: t.settings.atmosTestHlsControlDescription,
            ),
            _testTile(
              mode: 'rawEc3',
              icon: Symbols.stream_rounded,
              title: t.settings.atmosTestRawStream,
              subtitle: t.settings.atmosTestRawStreamDescription,
            ),
            _testTile(
              mode: 'rawEc3Finite',
              icon: Symbols.audio_file_rounded,
              title: t.settings.atmosTestRawFile,
              subtitle: t.settings.atmosTestRawFileDescription,
            ),
            _testTile(
              mode: 'asbarNative',
              icon: Symbols.graphic_eq_rounded,
              title: t.settings.atmosTestAsbarNative,
              subtitle: t.settings.atmosTestAsbarNativeDescription,
            ),
            _testTile(
              mode: 'asbarGenerated',
              icon: Symbols.tune_rounded,
              title: t.settings.atmosTestAsbarGenerated,
              subtitle: t.settings.atmosTestAsbarGeneratedDescription,
            ),
            SettingNavigationTile(
              icon: Symbols.airplay_rounded,
              title: _routePickerVisible ? t.settings.atmosTestHideRoutePicker : t.settings.atmosTestShowRoutePicker,
              subtitle: t.settings.atmosTestRoutePickerDescription,
              onTap: _toggleRoutePicker,
            ),
            SettingSwitchTile(
              pref: SettingsService.atmosProbeMoviePlaybackMode,
              icon: Symbols.tv_options_input_settings_rounded,
              title: t.settings.atmosTestSessionMode,
              subtitle: t.settings.atmosTestSessionModeDescription,
            ),
            SettingNavigationTile(
              icon: Symbols.stop_circle_rounded,
              title: t.settings.atmosTestStop,
              trailingIcon: Symbols.stop_rounded,
              onTap: _stop,
            ),
          ],
        ),
        SettingsGroup(
          children: [
            SettingValueBuilder<String>(
              pref: SettingsService.atmosProbeUrl,
              builder: (context, value, _) => SettingNavigationTile(
                icon: Symbols.link_rounded,
                title: t.settings.atmosTestUrl,
                subtitle: value.isEmpty ? t.settings.atmosTestUrlDescription : value,
                onTap: () async {
                  final result = await showTextInputDialog(
                    context,
                    title: t.settings.atmosTestUrl,
                    labelText: 'URL',
                    initialValue: value,
                    allowEmpty: true,
                  );
                  if (result != null) {
                    await SettingsService.instance.write(SettingsService.atmosProbeUrl, result.trim());
                  }
                },
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: t.settings.atmosTestStatus,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  statusText.isEmpty ? '—' : statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
