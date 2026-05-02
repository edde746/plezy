import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

mixin TrackerSettingsLoadMixin<T extends StatefulWidget> on State<T> {
  SettingsService? trackerSettings;
  bool trackerSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadTrackerSettings();
  }

  Future<void> loadTrackerSettings() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      trackerSettings = settings;
      readTrackerSettings(settings);
      trackerSettingsLoaded = true;
    });
  }

  void readTrackerSettings(SettingsService settings);
}
