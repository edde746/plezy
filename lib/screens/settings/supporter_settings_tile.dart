import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../services/supporter/supporter_service.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/supporter_sheet.dart';

/// The top Settings tile in store builds: opens lifetime access and restore.
class SupporterSettingsTile extends StatelessWidget {
  const SupporterSettingsTile({super.key, this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupporterService>();
    final unlocked = service.hasLifetimeUnlock;
    return SettingNavigationTile(
      focusNode: focusNode,
      icon: unlocked ? Symbols.favorite_rounded : Symbols.volunteer_activism_rounded,
      title: unlocked ? t.appAccess.lifetimeTitle : t.settings.lifetimeAccess,
      subtitle: unlocked
          ? t.appAccess.lifetimeBody
          : service.isTrialActive
          ? t.appAccess.trialActive
          : t.appAccess.manageDescription,
      onTap: () => showSupporterSheet(context),
    );
  }
}
