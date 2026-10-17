import '../../i18n/strings.g.dart';

/// One home-screen icon the user can pick: the default or a Supporter alternate.
class AppIconOption {
  const AppIconOption._(this.id, this._label);

  /// Permanent platform id: the Android launcher alias `.appicon.<id>` and the
  /// Apple alternate icon `AppIcon-<id>`. Devices keep the chosen icon by this
  /// id across updates, so an id is never renamed or removed.
  final String id;

  final String Function(Translations t) _label;

  bool get isDefault => id == defaultAppIconId;

  String label(Translations t) => _label(t);

  /// The bundled picker thumbnail; null for the default, which the picker draws
  /// as this device's launcher shows it (see [defaultAppIconTvosPreview]).
  String? get previewAsset => isDefault ? null : 'assets/app_icons/previews/$id.webp';
}

/// The default icon as the TV launchers draw it, rendered from the shipping
/// tvOS image stack and Android TV banner by
/// scripts/codegen/generate_app_icons.py: both are dark plates, unlike the
/// phone icons. Phone launchers draw the shipping logo on a flat plate, which
/// the picker paints itself.
const defaultAppIconTvosPreview = 'assets/app_icons/previews/default-tvos.webp';
const defaultAppIconAndroidTvPreview = 'assets/app_icons/previews/default-androidtv.webp';

/// What the platforms call the icon the app ships with.
const defaultAppIconId = 'default';

/// The picker's order, default first. The alternates match ICONS in
/// scripts/codegen/generate_app_icons.py, which renders their platform assets.
final List<AppIconOption> appIconCatalog = List.unmodifiable([
  AppIconOption._(defaultAppIconId, (t) => t.appIcon.defaultIcon),
  AppIconOption._('midnight', (t) => t.appIcon.names.midnight),
  AppIconOption._('ember', (t) => t.appIcon.names.ember),
  AppIconOption._('paper', (t) => t.appIcon.names.paper),
  AppIconOption._('oled', (t) => t.appIcon.names.oled),
  AppIconOption._('line', (t) => t.appIcon.names.line),
  AppIconOption._('ocean', (t) => t.appIcon.names.ocean),
  AppIconOption._('ultraviolet', (t) => t.appIcon.names.ultraviolet),
  AppIconOption._('matcha', (t) => t.appIcon.names.matcha),
  AppIconOption._('sunset', (t) => t.appIcon.names.sunset),
  AppIconOption._('gold', (t) => t.appIcon.names.gold),
  AppIconOption._('titanium', (t) => t.appIcon.names.titanium),
  AppIconOption._('glass', (t) => t.appIcon.names.glass),
  AppIconOption._('crt', (t) => t.appIcon.names.crt),
  AppIconOption._('vhs', (t) => t.appIcon.names.vhs),
  AppIconOption._('synthwave', (t) => t.appIcon.names.synthwave),
  AppIconOption._('pixel', (t) => t.appIcon.names.pixel),
  AppIconOption._('neon', (t) => t.appIcon.names.neon),
  AppIconOption._('sticker', (t) => t.appIcon.names.sticker),
  AppIconOption._('ticket', (t) => t.appIcon.names.ticket),
  AppIconOption._('pop', (t) => t.appIcon.names.pop),
  AppIconOption._('strata', (t) => t.appIcon.names.strata),
  AppIconOption._('facet', (t) => t.appIcon.names.facet),
  AppIconOption._('tilde', (t) => t.appIcon.names.tilde),
]);

/// The catalog entry for a platform id; null for an id this build does not know.
AppIconOption? appIconById(String id) {
  for (final option in appIconCatalog) {
    if (option.id == id) return option;
  }
  return null;
}
