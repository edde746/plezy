import 'package:flutter/widgets.dart';

/// Opens the Supporter purchase sheet: perks, price, Buy and Restore Purchases.
///
/// Callers use this from every locked perk (a preset or custom theme, an app
/// icon) and from the Settings "Support Plezy" tile in purchasable builds.
/// Completes when the sheet closes; read `SupporterService.isUnlocked` after
/// it to see whether the user unlocked.
Future<void> showSupporterSheet(BuildContext context) async {}
