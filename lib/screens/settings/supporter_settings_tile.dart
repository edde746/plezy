import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../services/supporter/supporter_service.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/supporter_sheet.dart';

/// The top Settings tile in purchasable builds: names the Theme & Icon Pack,
/// opens its sheet while locked, and thanks the user once it is unlocked.
class SupporterSettingsTile extends StatelessWidget {
  const SupporterSettingsTile({super.key, this.focusNode});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final unlocked = context.select<SupporterService, bool>((s) => s.isUnlocked);
    return SettingNavigationTile(
      focusNode: focusNode,
      icon: Symbols.palette_rounded,
      title: t.supporter.title,
      subtitle: unlocked
          ? t.supporter.tileUnlocked
          : supporterOffersAppIcons()
          ? t.supporter.tileSubtitle
          : t.supporter.tileSubtitleThemesOnly,
      onTap: () => showSupporterSheet(context),
    );
  }
}
