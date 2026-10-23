import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../services/supporter/supporter_service.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/supporter_sheet.dart';

/// The top Settings tile in purchasable builds: opens the Supporter sheet
/// while locked, and thanks the user once the perks are unlocked.
class SupporterSettingsTile extends StatelessWidget {
  const SupporterSettingsTile({super.key, this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final unlocked = context.select<SupporterService, bool>((s) => s.isUnlocked);
    return SettingNavigationTile(
      focusNode: focusNode,
      icon: unlocked ? Symbols.favorite_rounded : Symbols.volunteer_activism_rounded,
      title: unlocked ? t.supporter.title : t.settings.supportDeveloper,
      subtitle: unlocked
          ? t.supporter.tileUnlocked
          : supporterOffersAppIcons()
          ? t.supporter.tileSubtitle
          : t.supporter.tileSubtitleThemesOnly,
      onTap: () => showSupporterSheet(context),
    );
  }
}
