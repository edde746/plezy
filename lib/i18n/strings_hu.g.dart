///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:plezy/i18n/locale_preferences.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsHu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsHu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.hu,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <hu>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsHu _root = this; // ignore: unused_field

	@override 
	TranslationsHu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsHu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$hu app = _Translations$app$hu._(_root);
	@override late final _Translations$appIcon$hu appIcon = _Translations$appIcon$hu._(_root);
	@override late final _Translations$auth$hu auth = _Translations$auth$hu._(_root);
	@override late final _Translations$common$hu common = _Translations$common$hu._(_root);
	@override late final _Translations$screens$hu screens = _Translations$screens$hu._(_root);
	@override late final _Translations$update$hu update = _Translations$update$hu._(_root);
	@override late final _Translations$settings$hu settings = _Translations$settings$hu._(_root);
	@override late final _Translations$themeEditor$hu themeEditor = _Translations$themeEditor$hu._(_root);
	@override late final _Translations$search$hu search = _Translations$search$hu._(_root);
	@override late final _Translations$hotkeys$hu hotkeys = _Translations$hotkeys$hu._(_root);
	@override late final _Translations$fileInfo$hu fileInfo = _Translations$fileInfo$hu._(_root);
	@override late final _Translations$mediaMenu$hu mediaMenu = _Translations$mediaMenu$hu._(_root);
	@override late final _Translations$rateSheet$hu rateSheet = _Translations$rateSheet$hu._(_root);
	@override late final _Translations$accessibility$hu accessibility = _Translations$accessibility$hu._(_root);
	@override late final _Translations$tooltips$hu tooltips = _Translations$tooltips$hu._(_root);
	@override late final _Translations$audioTracks$hu audioTracks = _Translations$audioTracks$hu._(_root);
	@override late final _Translations$videoControls$hu videoControls = _Translations$videoControls$hu._(_root);
	@override late final _Translations$messages$hu messages = _Translations$messages$hu._(_root);
	@override late final _Translations$subtitlingStyling$hu subtitlingStyling = _Translations$subtitlingStyling$hu._(_root);
	@override late final _Translations$mpvConfig$hu mpvConfig = _Translations$mpvConfig$hu._(_root);
	@override late final _Translations$dialog$hu dialog = _Translations$dialog$hu._(_root);
	@override late final _Translations$profiles$hu profiles = _Translations$profiles$hu._(_root);
	@override late final _Translations$connections$hu connections = _Translations$connections$hu._(_root);
	@override late final _Translations$accountPreferences$hu accountPreferences = _Translations$accountPreferences$hu._(_root);
	@override late final _Translations$discover$hu discover = _Translations$discover$hu._(_root);
	@override late final _Translations$errors$hu errors = _Translations$errors$hu._(_root);
	@override late final _Translations$libraries$hu libraries = _Translations$libraries$hu._(_root);
	@override late final _Translations$about$hu about = _Translations$about$hu._(_root);
	@override late final _Translations$serverSelection$hu serverSelection = _Translations$serverSelection$hu._(_root);
	@override late final _Translations$hubDetail$hu hubDetail = _Translations$hubDetail$hu._(_root);
	@override late final _Translations$logs$hu logs = _Translations$logs$hu._(_root);
	@override late final _Translations$startup$hu startup = _Translations$startup$hu._(_root);
	@override late final _Translations$licenses$hu licenses = _Translations$licenses$hu._(_root);
	@override late final _Translations$navigation$hu navigation = _Translations$navigation$hu._(_root);
	@override late final _Translations$explore$hu explore = _Translations$explore$hu._(_root);
	@override late final _Translations$liveTv$hu liveTv = _Translations$liveTv$hu._(_root);
	@override late final _Translations$collections$hu collections = _Translations$collections$hu._(_root);
	@override late final _Translations$playlists$hu playlists = _Translations$playlists$hu._(_root);
	@override late final _Translations$music$hu music = _Translations$music$hu._(_root);
	@override late final _Translations$watchTogether$hu watchTogether = _Translations$watchTogether$hu._(_root);
	@override late final _Translations$downloads$hu downloads = _Translations$downloads$hu._(_root);
	@override late final _Translations$shaders$hu shaders = _Translations$shaders$hu._(_root);
	@override late final _Translations$companionRemote$hu companionRemote = _Translations$companionRemote$hu._(_root);
	@override late final _Translations$videoSettings$hu videoSettings = _Translations$videoSettings$hu._(_root);
	@override late final _Translations$performanceOverlay$hu performanceOverlay = _Translations$performanceOverlay$hu._(_root);
	@override late final _Translations$externalPlayer$hu externalPlayer = _Translations$externalPlayer$hu._(_root);
	@override late final _Translations$metadataEdit$hu metadataEdit = _Translations$metadataEdit$hu._(_root);
	@override late final _Translations$matchScreen$hu matchScreen = _Translations$matchScreen$hu._(_root);
	@override late final _Translations$serverTasks$hu serverTasks = _Translations$serverTasks$hu._(_root);
	@override late final _Translations$trakt$hu trakt = _Translations$trakt$hu._(_root);
	@override late final _Translations$seerr$hu seerr = _Translations$seerr$hu._(_root);
	@override late final _Translations$services$hu services = _Translations$services$hu._(_root);
	@override late final _Translations$addServer$hu addServer = _Translations$addServer$hu._(_root);
	@override late final _Translations$cast$hu cast = _Translations$cast$hu._(_root);
	@override late final _Translations$automation$hu automation = _Translations$automation$hu._(_root);
	@override late final _Translations$notifications$hu notifications = _Translations$notifications$hu._(_root);
	@override late final _Translations$appAccess$hu appAccess = _Translations$appAccess$hu._(_root);
	@override late final _Translations$detail$hu detail = _Translations$detail$hu._(_root);
	@override late final _Translations$watchLink$hu watchLink = _Translations$watchLink$hu._(_root);
	@override late final _Translations$homeLayout$hu homeLayout = _Translations$homeLayout$hu._(_root);
	@override late final _Translations$platform$hu platform = _Translations$platform$hu._(_root);
	@override late final _Translations$universalMedia$hu universalMedia = _Translations$universalMedia$hu._(_root);
	@override late final _Translations$fileSources$hu fileSources = _Translations$fileSources$hu._(_root);
	@override late final _Translations$lending$hu lending = _Translations$lending$hu._(_root);
	@override late final _Translations$audiobook$hu audiobook = _Translations$audiobook$hu._(_root);
	@override late final _Translations$sourceSetup$hu sourceSetup = _Translations$sourceSetup$hu._(_root);
	@override late final _Translations$comics$hu comics = _Translations$comics$hu._(_root);
	@override late final _Translations$games$hu games = _Translations$games$hu._(_root);
	@override late final _Translations$deepLinks$hu deepLinks = _Translations$deepLinks$hu._(_root);
	@override late final _Translations$householdSetup$hu householdSetup = _Translations$householdSetup$hu._(_root);
	@override late final _Translations$issueReport$hu issueReport = _Translations$issueReport$hu._(_root);
}

// Path: app
class _Translations$app$hu extends Translations$app$en {
	_Translations$app$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$hu extends Translations$appIcon$en {
	_Translations$appIcon$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alkalmazásikon';
	@override String get defaultIcon => 'Alapértelmezett';
	@override String get current => 'Jelenlegi ikon';
	@override String get locked => 'Élethosszú hozzáférés szükséges';
	@override String get lockedHint => 'Kezdje a 7 napos próbát vagy letiltja a PlezyNG élethosszig, hogy alternatív ikonokat használjon.';
	@override String get changeFailed => 'Nem sikerült módosítani az alkalmazásikont';
	@override String get launcherHint => 'Az új ikon azután jelenik meg a kezdőképernyőn, hogy kiléptél a Plezyből.';
	@override String get tvLauncherHint => 'Az új banner azután jelenik meg, hogy kiléptél a Plezyből. Az Android TV a TV újraindításáig még a régit is mutathatja.';
	@override late final _Translations$appIcon$names$hu names = _Translations$appIcon$names$hu._(_root);
	@override String get description => 'Válassza ki az ikonot, amelyet a készülék indítója mutat. Az előrejelzések megmutatják, hogy hogyan néz ki minden lehetőség.';
}

// Path: auth
class _Translations$auth$hu extends Translations$auth$en {
	_Translations$auth$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Bejelentkezés Plexszel';
	@override String get showQRCode => 'QR-kód megjelenítése';
	@override String get authenticate => 'Hitelesítés';
	@override String get authenticationTimeout => 'A hitelesítés időtúllépés miatt megszakadt. Próbáld újra.';
	@override String get scanQRToSignIn => 'Olvasd be ezt a QR-kódot a bejelentkezéshez';
	@override String get waitingForAuth => 'Várakozás a hitelesítésre...\nJelentkezz be a böngésződben.';
	@override String get useBrowser => 'Böngésző használata';
	@override String get or => 'vagy';
	@override String connectToMediaBrowser({required Object product}) => 'Csatlakozás a(z) ${product} szolgáltatáshoz';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Quick Connect használata';
	@override String get quickConnectInstructions => 'Nyisd meg a Quick Connect-et a Jellyfinben, és add meg ezt a kódot.';
	@override String get quickConnectWaiting => 'Várakozás a jóváhagyásra…';
	@override String get quickConnectCancel => 'Mégse';
	@override String get quickConnectExpired => 'A Quick Connect kód lejárt. Próbáld újra.';
	@override String get localDataRecoveryRequired => 'A PlezyNG nem tudta biztonságosan helyreállítani a helyi bejelentkezés és a függőben lévő lejátszás adatait. Jelentkezz be újra.';
	@override String get pinCheckRejected => 'A Plex PIN ellenőrzését elutasították';
	@override String get connectToDirectPlex => 'Kapcsolat a helyi Plex szerverhez';
}

// Path: common
class _Translations$common$hu extends Translations$common$en {
	_Translations$common$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Mégse';
	@override String get save => 'Mentés';
	@override String get close => 'Bezárás';
	@override String get closeMiniPlayer => 'Mini játékosok';
	@override String get closeWorkspaceWindow => 'Közel ablak';
	@override String get returnToFullView => 'Vissza a teljes nézőpontba';
	@override String get manageMediaSessions => 'Média ülések kezelése';
	@override String get hideMediaSessions => 'A médiaközlemények elrejtése';
	@override String get mediaSessions => 'Média ülések';
	@override String get mediaSessionsHint => 'Válassza ki, hogy egy ülést előre hozzon.A park elrejti ablakát, de nyitva tartja.A visszatérés teljes nézetben nyílik meg; a közel véget ér.';
	@override String get sessionInWorkspace => 'A munkaterületben';
	@override String get sessionParked => 'Parkolás';
	@override String get sessionFullscreen => 'Teljes képernyő';
	@override String get switchToNextWindow => 'Változás a következő ablakkal';
	@override String get moveWindow => 'Mozgás ablak';
	@override String get finishMovingWindow => 'Véget ér a mozgó ablak';
	@override String get moveWindowHint => 'Hosszú nyomás és húzza az ablakot, hogy mozogjon. Ez a vezérlés lehetővé teszi a lövedék-kulcs mozgását is.';
	@override String get movingWindowHelp => 'Kattintson a mozgáshoz · Nyomja meg a kulcsokat · Enter Saves · Escape cancels';
	@override String get resizeWindow => 'Az ablak felújítása';
	@override String get resizeWindowHint => 'Vágja ki ezt a kézikönyvt, vagy használja a lövedék kulcsát az ablak átalakításához.';
	@override String get workspaceWindowHint => 'Használja a mozgásszabályozást vagy a hosszú nyomást és húzza, hogy mozogjon.';
	@override String get workspacePaneHint => 'Válassza ki ezt a panelt, hogy összpontosítson rá. Használja a teljes képernyő vezérlőjét bővíteni.';
	@override String workspaceWindowLabel({required Object title}) => 'Az ülés ablakai: ${title}';
	@override String get workspaceTitleHint => 'Kattintson a címsorra, hogy mozogjon; használja a teljes képernyő gombot kiterjeszteni.';
	@override String get moveToSessionTray => 'Helyezze be a Session Tray-t';
	@override String get moveToSessionTrayHint => 'Ez az ülést jeleníti meg, anélkül, hogy ablakát mutatnánk.';
	@override String get closeSessionHint => 'Zárja be az ablakot, és befejezi az ülését.';
	@override String get sideBySideLayout => 'Töltse át a side-by-side layout';
	@override String get floatingWindows => 'Switch az ablakok áramlásához';
	@override String get clear => 'Törlés';
	@override String get reset => 'Visszaállítás';
	@override String get later => 'Később';
	@override String get submit => 'Beküldés';
	@override String get confirm => 'Megerősítés';
	@override String get retry => 'Újra';
	@override String get logout => 'Kijelentkezés';
	@override String get unknown => 'Ismeretlen';
	@override String get refresh => 'Frissítés';
	@override String get yes => 'Igen';
	@override String get no => 'Nem';
	@override String get delete => 'Törlés';
	@override String get edit => 'Szerkesztés';
	@override String get shuffle => 'Véletlenszerű lejátszás';
	@override String get addTo => 'Hozzáadás...';
	@override String get createNew => 'Új létrehozása';
	@override String get connect => 'Csatlakozás';
	@override String get disconnect => 'Kapcsolat bontása';
	@override String get play => 'Lejátszás';
	@override String get pause => 'Szünet';
	@override String get resume => 'Folytatás';
	@override String get error => 'Hiba';
	@override String get search => 'Keresés';
	@override String get home => 'Kezdőlap';
	@override String get back => 'Vissza';
	@override String get settings => 'Beállítások';
	@override String get mute => 'Némítás';
	@override String get ok => 'OK';
	@override String get off => 'Ki';
	@override String get options => 'Lehetőségek';
	@override String seasonNumber({required Object number}) => '${number}. évad';
	@override String episodeNumberTitle({required Object number, required Object title}) => '${number}. epizód - ${title}';
	@override String chapterNumber({required Object number}) => '${number}. fejezet';
	@override String get reconnect => 'Újracsatlakozás';
	@override String get viewAll => 'Összes megtekintése';
	@override String get checkingNetwork => 'Hálózat ellenőrzése...';
	@override String get loadingServers => 'Szerverek betöltése...';
	@override String get connectingToServers => 'Csatlakozás a szerverekhez...';
	@override String get startingOfflineMode => 'Kapcsolat nélküli mód indítása...';
	@override String get loading => 'Betöltés...';
	@override String get fullscreen => 'Teljes képernyő';
	@override String get exitFullscreen => 'Kilépés a teljes képernyőből';
	@override String get pressBackAgainToExit => 'A kilépéshez nyomd meg újra a Vissza gombot';
	@override late final _Translations$common$ratingSource$hu ratingSource = _Translations$common$ratingSource$hu._(_root);
	@override String get notAvailable => 'N/A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$hu mediaKind = _Translations$common$mediaKind$hu._(_root);
}

// Path: screens
class _Translations$screens$hu extends Translations$screens$en {
	_Translations$screens$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencek';
	@override String get switchProfile => 'Profilváltás';
	@override String get subtitleStyling => 'Feliratok stílusa';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Naplók';
}

// Path: update
class _Translations$update$hu extends Translations$update$en {
	_Translations$update$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get available => 'Frissítés érhető el';
	@override String versionAvailable({required Object version}) => 'A(z) ${version} verzió elérhető';
	@override String currentVersion({required Object version}) => 'Jelenlegi: ${version}';
	@override String get skipVersion => 'Verzió kihagyása';
	@override String get viewRelease => 'Kiadási megjegyzések';
	@override String get latestVersion => 'A legújabb verziót használod';
	@override String get checkFailed => 'Nem sikerült az újabb frissítések ellenőrzése';
}

// Path: settings
class _Translations$settings$hu extends Translations$settings$en {
	_Translations$settings$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Beállítások';
	@override String get supportDeveloper => 'PlezyNG támogatása';
	@override String get supportDeveloperDescription => 'Adománnyal támogassa a fejlesztést';
	@override String get lifetimeAccess => 'PlezyNG Élethosszú hozzáférés';
	@override String get language => 'Nyelv';
	@override String get theme => 'Téma';
	@override String get appearance => 'Megjelenés';
	@override String get detailPage => 'Részletes oldal';
	@override String get themeSongsEnabled => 'Téma dalok';
	@override String get themeSongsEnabledDescription => 'Játsszon elérhető tematikus dalokat, miközben nézi a média részleteit.';
	@override String get themeSongVolume => 'Téma: Volume ének';
	@override String get videoPlayback => 'Videólejátszás';
	@override String get videoPlaybackDescription => 'Lejátszási viselkedés beállítása';
	@override String get advanced => 'Haladó';
	@override String get episodePosterMode => 'Epizódborító stílusa';
	@override String get seriesPoster => 'Sorozatborító';
	@override String get seasonPoster => 'Évadborító';
	@override String get episodeThumbnail => 'Bélyegkép';
	@override String get showHeroSectionDescription => 'Kiemelt tartalmak sávjának megjelenítése a kezdőlapon';
	@override String get secondsLabel => 'Másodperc';
	@override String get minutesLabel => 'Perc';
	@override String get secondsShort => 'mp';
	@override String get minutesShort => 'p';
	@override String durationHint({required Object min, required Object max}) => 'Add meg az időtartamot (${min}-${max})';
	@override String get systemTheme => 'Rendszer';
	@override String get lightTheme => 'Világos';
	@override String get darkTheme => 'Sötét';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Parázs';
	@override String get glacierTheme => 'Gleccser';
	@override String get forestTheme => 'Erdő';
	@override String get plumTheme => 'Szilva';
	@override String get paperTheme => 'Papír';
	@override String get libraryDensity => 'Könyvtársűrűség';
	@override String get displayScale => 'Kijelző méretezése';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Kényelmes';
	@override String get gridSpacing => 'Rácstávolság';
	@override String get gridSpacingTight => 'Sűrű';
	@override String get gridSpacingNormal => 'Normál';
	@override String get gridSpacingSpacious => 'Tágas';
	@override String get tvCornerSpotlightBackdrop => 'Sarokban megjelenő kiemelt háttérkép';
	@override String get tvCornerSpotlightBackdropDescription => 'A kiemelt háttérkép megjelenítése a jobb felső sarokban a teljes képernyő helyett';
	@override String get viewMode => 'Nézetmód';
	@override String get gridView => 'Rács';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Kiemelt sáv megjelenítése';
	@override String get showHomeBackdrop => 'Home Backdrop Művészeti műsor';
	@override String get showHomeBackdropDescription => 'Nagy műalkotás megjelenítése hátsó bemutatott házi sorok mögött';
	@override String get contentScreensaverEnabled => 'tartalom képernyő';
	@override String get contentScreensaverEnabledDescription => 'A teljes képernyőn megjelenő műalkotás, miután az alkalmazás idle lett';
	@override String get contentScreensaverDelay => 'Kezdje a screensaver után';
	@override String get contentScreensaverLibraries => 'Screensaver könyvtárak';
	@override String get contentScreensaverLibrariesDescription => 'Válassza ki, mely könyvtárak biztosítsák a képernyővédő képeit. Ha egyet sem választ ki, az összes könyvtár képeit használjuk.';
	@override String get contentScreensaverAllLibraries => 'Minden könyvtár';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} kiválasztott könyvtárak';
	@override String get contentScreensaverNoLibraries => 'Nem állnak rendelkezésre kapcsolódó médiakönyvtárak.';
	@override String get contentScreensaverDismissHint => 'Nyomja meg a gombot vagy nyomja meg a lemondáshoz';
	@override String get newEpisodeNotifications => 'Új epizód értesítések';
	@override String get newEpisodeNotificationsDescription => 'Figyelmeztetés, amikor egy új epizód hozzáadódik egy show, akkor fogadják fel. Ellenőrizze, míg Plezy nyitva van.';
	@override String get continueWatchingRowSize => 'Folytatjuk a sorméret figyelését';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} kártyák';
	@override String get rowSizeCompact => 'Kompakt';
	@override String get rowSizeStandard => 'Standard';
	@override String get rowSizeLarge => 'Nagy';
	@override String get continueWatchingAction => 'A „Folytatás” művelete';
	@override String get continueWatchingPlay => 'Lejátszás';
	@override String get continueWatchingDetails => 'Részletek megnyitása';
	@override String get episodeAction => 'Az epizódkártya művelete';
	@override String get episodePlay => 'Lejátszás';
	@override String get episodeDetails => 'Részletek megnyitása';
	@override String get useGlobalHubs => 'Kezdőlap elrendezés használata';
	@override String get useGlobalHubsDescription => 'Egyesített kezdőlapi blokkok megjelenítése. Egyébként a könyvtári ajánlások jelennek meg.';
	@override String get showServerNameOnHubs => 'Szervernév megjelenítése a blokkoknál';
	@override String get showServerNameOnHubsDescription => 'Mindig jelenjen meg a szerver neve a blokkok címében.';
	@override String get groupLibrariesByServer => 'Könyvtárak csoportosítása szerver szerint';
	@override String get groupLibrariesByServerDescription => 'Az oldalsáv könyvtárainak csoportosítása a médiaszerverek alatt.';
	@override String get alwaysKeepSidebarOpen => 'Oldalsáv mindig nyitva';
	@override String get alwaysKeepSidebarOpenDescription => 'Az oldalsáv kibontva marad, a tartalom területe igazodik hozzá';
	@override String get showUnwatchedCount => 'Nem látott elemek számának megjelenítése';
	@override String get showUnwatchedCountDescription => 'Megjeleníti a még nem látott epizódok számát a sorozatoknál és évadoknál';
	@override String get showWatchedIndicators => 'Megtekintésjelölők megjelenítése';
	@override String get showWatchedIndicatorsDescription => 'Pipa megjelenítése a megtekintett filmeken, sorozatokon és epizódokon';
	@override String get showEpisodeNumberOnCards => 'Epizódszám megjelenítése a kártyákon';
	@override String get showEpisodeNumberOnCardsDescription => 'Megjeleníti az évad- és epizódszámot az epizódkártyákon';
	@override String get showSeasonPostersOnTabs => 'Évadborítók megjelenítése a füleken';
	@override String get showSeasonPostersOnTabsDescription => 'Megjeleníti az egyes évadok borítóját a fülük felett';
	@override String get tvFullCardLayout => 'Teljes TV-kártyák';
	@override String get tvFullCardLayoutDescription => 'Csak képet tartalmazó TV-kártyák használata, rájuk helyezett színésznevekkel';
	@override String get focusGlow => 'Kijelölési ragyogás';
	@override String get focusGlowDescription => 'Finom ragyogás rajzolása a kijelölt kártya köré';
	@override String get visualEffects => 'Vizuális effektek';
	@override String get visualEffectsAuto => 'Automatikus';
	@override String get visualEffectsAutoDescription => 'Effektek automatikus csökkentése alacsony teljesítményű eszközökön';
	@override String get visualEffectsFull => 'Teljes';
	@override String get visualEffectsReduced => 'Csökkentett';
	@override String get visualEffectsReducedDescription => 'Kevesebb animáció és alacsonyabb felbontású képek';
	@override String get hideSpoilers => 'Spoilerek elrejtése a nem látott epizódoknál';
	@override String get hideSpoilersDescription => 'Bélyegképek és leírások elhomályosítása a még meg nem nézett epizódoknál';
	@override String get playerBackend => 'Lejátszómotor';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardveres dekódolás';
	@override String get hardwareDecodingDescription => 'Hardveres gyorsítás használata, ha elérhető';
	@override String get playbackBuffer => 'Lejátszási puffer';
	@override String get playbackBufferAuto => 'Automatikus (ajánlott)';
	@override String get playbackBufferLarge => 'Nagy';
	@override String get playbackBufferExtraLarge => 'Extra nagy';
	@override String get playbackBufferDescription => 'Több puffert használ instabil kapcsolatok ellen. A pufferméret is korlátozza.';
	@override String get streamBufferSize => 'Buffer méret';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Mennyit kell tölteni a videót, amikor közvetlenül játszani. transzkódok megállnak a szerver saját transzkód buffer. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'A Playback Buffer helyettesítése a beállított, az alkalmazás memóriameghatározásának felére elkapott';
	@override String get streamBufferMegabytes => 'Megabajták';
	@override String get defaultQualityTitle => 'Alapértelmezett minőség';
	@override String get cellularQualityTitle => 'Alapértelmezett minőség mobilhálózaton';
	@override String get remoteQualityTitle => 'Remote Streaming minőség';
	@override String get remoteQualitySameAsDefault => 'A szabványos minőség';
	@override String get cellularQualitySameAsDefault => 'Ugyanaz, mint az alapértelmezett minőség';
	@override String get directPlayCoveredQuality => 'Kisebb videók lejátszása eredeti minőségben';
	@override String get directPlayCoveredQualityDescription => 'A minőségi korláton belüli videók közvetlen lejátszása átkódolás helyett';
	@override String get videoCodecs => 'Videokodekek';
	@override String get videoCodecsDescription => 'A nem bejelölt kodekeket a szerver átkódolja';
	@override String get videoCodecsAlwaysAccepted => 'Mindig elfogadva';
	@override String get musicQualityTitle => 'Zene minősége';
	@override String get subtitleStyling => 'Feliratok stílusa';
	@override String get subtitleStylingDescription => 'Feliratok megjelenésének testreszabása';
	@override String get smallSkipDuration => 'Kis ugrás időtartama';
	@override String get largeSkipDuration => 'Nagy ugrás időtartama';
	@override String get rewindOnResume => 'Visszatekerés folytatáskor';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} másodperc',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} másodperc',
	);
	@override String get defaultSleepTimer => 'Alapértelmezett elalvási időzítő';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} perc',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} perc',
	);
	@override String get rememberTrackSelections => 'Sávválasztások megjegyzése sorozatonként/filmenként';
	@override String get chooseTracksBeforePlayback => 'Válassza ki a hangokat és altitkolatokat a playback előtt';
	@override String get chooseTracksBeforePlaybackDescription => 'Válassza ki a forrás hang és altitkos nyomokat, mielőtt minden videó elindul.';
	@override String get alwaysShowSubtitlesOnDevice => 'Mindig mutatnak altitkok ezen a készüléken';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Ha a szerver nem rendelkezik kiválasztott alszámmal, válasszon egy pályát helyi helyen. Ez soha nem változtatja meg a szerver preferenciáit.';
	@override String get autoDownloadPreferredSubtitle => 'A FETCH hiányzik a preferált nyelv altitkok';
	@override String get autoDownloadPreferredSubtitleDescription => 'Válasszon egy elérhető alszámot a kedvenc nyelven helyi. ha nincs, kérje a szervert, hogy a támogatott. A kiválasztás ezen a készüléken marad.';
	@override String get rememberTrackSelectionsDescription => 'Hang- és feliratválasztások megjegyzése címenként';
	@override String get rememberTrackSelectionsBackendRule => 'A Plex minden választást fájlonként a szerveren ment; a Jellyfin a fiók „Választások megjegyzése” funkcióját is bekapcsolja; az Emby nem támogatott';
	@override String get followServerTrackSelections => 'A szerver epizódonkénti sávválasztásának használata';
	@override String get followServerTrackSelectionsDescription => 'Epizódváltáskor a szerveren kiválasztott hang és felirat lép életbe az aktuális választás átvitele helyett';
	@override String get resumeMusicOnLaunch => 'Zenei munkamenet megjegyzése';
	@override String get resumeMusicOnLaunchDescription => 'Az alkalmazás indításakor az utolsó szám szüneteltetve nyílik meg ott, ahol abbamaradt';
	@override String get showChapterMarkersOnTimeline => 'Fejezetjelölők megjelenítése az idősávon';
	@override String get showChapterMarkersOnTimelineDescription => 'Az idősáv felosztása a fejezetek határainál';
	@override String get specialsOrdering => 'Különkiadások epizódsorrendben';
	@override String get specialsOrderingDescription => 'A különkiadások helye a sorozat lejátszási sorrendjében';
	@override String get specialsOrderingServer => 'Szerver szerinti sorrend';
	@override String get specialsOrderingAirDate => 'Adás dátuma szerint közbeszúrva';
	@override String get specialsOrderingLast => 'A normál évadok után';
	@override String get clickVideoTogglesPlayback => 'Kattintás a videóra a lejátszás/szünet váltásához';
	@override String get clickVideoTogglesPlaybackDescription => 'A videóra kattintva vált a lejátszás/szünet, a vezérlők megjelenítése helyett.';
	@override String get videoPlayerControls => 'Videólejátszó vezérlői';
	@override String get keyboardShortcuts => 'Billentyűparancsok';
	@override String get keyboardShortcutsDescription => 'Billentyűparancsok testreszabása';
	@override String get videoPlayerNavigation => 'Videólejátszó-navigáció';
	@override String get videoPlayerNavigationDescription => 'A nyílbillentyűk használata a videólejátszó vezérlői közötti navigáláshoz';
	@override String get watchTogetherRelay => 'Watch Together-relé';
	@override String get watchTogetherRelayDescription => 'Nyilvános Open Watch Party-relék, hacsak nem adsz meg sajátot';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Adj meg egy érvényes HTTP- vagy HTTPS-alapú relészerver-URL-t.';
	@override String get crashReporting => 'Összeomlási jelentések';
	@override String get crashReportingDescription => 'Összeomlási jelentések küldése az alkalmazás fejlesztésének elősegítéséhez';
	@override String get debugLogging => 'Hibakeresési naplózás';
	@override String get debugLoggingDescription => 'Részletes naplózás engedélyezése a hibaelhárításhoz';
	@override String get viewLogs => 'Naplók megtekintése';
	@override String get viewLogsDescription => 'Alkalmazásnaplók megtekintése';
	@override String get clearImageCache => 'Képgyorsítótár törlése';
	@override String get clearImageCacheDescription => 'Törli a gyorsítótárazott borítókat és miniatűröket. A képek lassabban tölthetők be, amíg újra le nem töltődnek.';
	@override String get clearImageCacheSuccess => 'A képgyorsítótár sikeresen törölve';
	@override String get resetSettings => 'Beállítások visszaállítása';
	@override String get resetSettingsDescription => 'Az alapértelmezett beállítások visszaállítása. Ez a művelet nem vonható vissza.';
	@override String get resetSettingsSuccess => 'A beállítások sikeresen visszaállítva';
	@override String get backup => 'Biztonsági mentés';
	@override String get exportSettings => 'Beállítások exportálása';
	@override String get exportSettingsDescription => 'Beállítások mentése fájlba';
	@override String get exportSettingsSuccess => 'Beállítások exportálva';
	@override String get importSettings => 'Beállítások importálása';
	@override String get importSettingsDescription => 'Beállítások visszaállítása fájlból';
	@override String get importSettingsConfirm => 'Ez felülírja a jelenlegi beállításaidat. Folytatod?';
	@override String get importSettingsSuccess => 'Beállítások importálva';
	@override String get importSettingsInvalidFile => 'Ez a fájl nem érvényes PlezyNG-beállításexport';
	@override String get importSettingsNoUser => 'Jelentkezz be a beállítások importálása előtt';
	@override String get cloudBackup => 'Felhőalapú biztonsági mentés';
	@override String get cloudBackupDescription => 'Készíts biztonsági másolatot az átvihető beállításokról egy WebDAV-címre HTTPS-en keresztül. A szerverkapcsolatok és a bejelentkezési adatok ezen az eszközön maradnak.';
	@override String get cloudBackupUrl => 'WebDAV JSON fájl URL';
	@override String get cloudBackupUsername => 'Felhasználónév';
	@override String get cloudBackupPassword => 'Jelszó';
	@override String get cloudBackupSaved => 'Cloud Backup cél mentett';
	@override String get cloudBackupNow => 'Vissza most';
	@override String get cloudBackupComplete => 'Backup beállítások feltöltve';
	@override String get cloudBackupRestore => 'Backup visszaállítása';
	@override String get cloudBackupRestoreConfirm => 'Ez helyettesíti a hordozható beállítások megfelelését ezen a készüléken.';
	@override String get cloudBackupRestored => 'A felhő biztonsági mentéséből helyreállított beállítások';
	@override String get shortcutsReset => 'A billentyűparancsok visszaálltak az alapértelmezettekre';
	@override String get resetShortcutsConfirm => 'Ezzel az egyéni billentyűparancsaid helyére az alapértelmezettek kerülnek. Folytatod?';
	@override String get about => 'Névjegy';
	@override String get aboutDescription => 'Alkalmazásadatok és licencek';
	@override String get updates => 'Frissítések';
	@override String get updateAvailable => 'Frissítés érhető el';
	@override String get checkForUpdates => 'Frissítések keresése';
	@override String get autoCheckUpdatesOnStartup => 'Frissítések automatikus keresése indításkor';
	@override String get autoCheckUpdatesOnStartupDescription => 'Értesítés küldése indításkor, ha új frissítés érhető el';
	@override String get validationErrorEnterNumber => 'Adj meg egy érvényes számot';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Az időtartamnak ${min} és ${max} ${unit} között kell lennie';
	@override String shortcutAlreadyAssigned({required Object action}) => 'A billentyűparancs már hozzá van rendelve a következőhöz: ${action}';
	@override String shortcutUpdated({required Object action}) => 'Billentyűparancs frissítve a következőhöz: ${action}';
	@override String get saveFailed => 'Nem sikerült menteni a módosításokat. Próbáld újra.';
	@override String get autoPlayAndSkip => 'Automatikus lejátszás és átugrás';
	@override String get autoPlayNextEpisode => 'Következő epizód automatikus lejátszása';
	@override String get autoPlayNextEpisodeDescription => 'A következő epizód automatikus elindítása, amikor az aktuális véget ér';
	@override String get shuffleStartsFromBeginning => 'Véletlenszerű lejátszás az elejétől';
	@override String get shuffleStartsFromBeginningDescription => 'Minden epizód az elejétől indul véletlenszerű lejátszáskor a folytatás helyett';
	@override String get plexCinemaPreRoll => 'A szerverek filmbevételét';
	@override String get plexCinemaPreRollDescription => 'Játssz konfigurált Plex előzetes vagy Jellyfin és Emby bejegyzést, mielőtt egy film elindul.';
	@override String get playNextCountdown => 'Visszaszámlálás a következő epizódig';
	@override String get playNextCountdownImmediate => 'Azonnali lejátszás';
	@override String get skipIntroMode => 'Intró átugrása';
	@override String get skipIntroModeOffDescription => 'Az intrók normálisan lejátszódnak, átugró gomb nélkül';
	@override String get skipIntroModeButtonDescription => 'Átugró gomb megjelenítése az intró kezdetekor';
	@override String get skipIntroModeAutoDescription => 'Az intrók automatikus átugrása az alábbi késleltetés után';
	@override String get skipCreditsMode => 'Stáblista átugrása';
	@override String get skipCreditsModeOffDescription => 'A stáblista normálisan lejátszódik, átugró gomb nélkül';
	@override String get skipCreditsModeButtonDescription => 'Átugró gomb megjelenítése a stáblista kezdetekor';
	@override String get skipCreditsModeAutoDescription => 'A stáblista automatikus átugrása és a következő epizód lejátszása';
	@override String get skipAdsMode => 'Skip hirdetések';
	@override String get skipAdsModeOffDescription => 'Játsszon észlelt hirdetéseket normálisan, a skip gomb nélkül';
	@override String get skipAdsModeButtonDescription => 'A skip gomb megjelenítése, amikor a Plex egy hirdetést észlel';
	@override String get skipAdsModeAutoDescription => 'A felderített hirdetések automatikusan eltávolítása az alábbi késések után';
	@override String get musicPlayback => 'Zene Playback';
	@override String get musicSweetFades => 'édes fát';
	@override String get musicSweetFadesDescription => 'A zene a track edgein, amikor a Plex hangadatokkal rendelkezik. az album lejátszását változatlanul tartják.';
	@override String get skipMarkerModeOff => 'Ki';
	@override String get skipMarkerModeButton => 'Gomb megjelenítése';
	@override String get skipMarkerModeAuto => 'Automatikus';
	@override String get forceSkipMarkerFallback => 'Tartalék jelölők kényszerítése';
	@override String get forceSkipMarkerFallbackDescription => 'Fejezetcím-minták használata akkor is, ha a Plex rendelkezik jelölőkkel';
	@override String get theIntroDbFallback => 'A TheIntroDB-t intro fallbackként használja';
	@override String get theIntroDbFallbackDescription => 'A közösségi időzítéseket csak akkor használja, ha a szerver nem rendelkezik intro markerrel.';
	@override String get autoSkipDelay => 'Automatikus átugrás késleltetése';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Várakozás ${seconds} másodpercig az automatikus átugrás előtt';
	@override String get introPattern => 'Intrójelölő mintája';
	@override String get introPatternDescription => 'Reguláris kifejezés az intrójelölők illesztéséhez a fejezetcímekben';
	@override String get creditsPattern => 'Stáblistajelölő mintája';
	@override String get creditsPatternDescription => 'Reguláris kifejezés a stáblistajelölők illesztéséhez a fejezetcímekben';
	@override String get prerolls => 'Prerollok';
	@override String get playPrerollsBeforeMovies => 'Prorollok játszani a filmek előtt';
	@override String get playPrerollsBeforeMoviesDescription => 'Játssz egy véletlenszerű klip a kiválasztás alább, mielőtt minden film. nyomja meg vissza, hogy ugráljon.';
	@override String get prerollLibrary => 'Preroll könyvtár';
	@override String get prerollLibraryNotSet => 'Nincs beállítva';
	@override String get prerollLibraryNoneFound => 'Nincs könyvtár a szervereken.';
	@override String get prerollSelection => 'Kiválasztott előadások';
	@override String get prerollSelectionPickLibraryFirst => 'Először egy könyvtárat választunk';
	@override String get prerollSelectionNoneSelected => 'Nem kiválasztott előadások';
	@override String prerollSelectionCount({required Object count}) => '${count} kiválasztva';
	@override String get prerollItemPicker => 'Proroll kiválasztása';
	@override String get prerollItemPickerLoadFailed => 'Nem tudtam elhelyezni a könyvtárból származó elemeket.';
	@override String get invalidRegex => 'Érvénytelen reguláris kifejezés';
	@override String get regex => 'Reguláris kifejezés';
	@override String get downloads => 'Letöltések';
	@override String get downloadLocationDescription => 'Válaszd ki a letöltött tartalom tárolási helyét';
	@override String get downloadLocationDefault => 'Alapértelmezett (alkalmazástárhely)';
	@override String get downloadLocationCustom => 'Egyéni hely';
	@override String get selectFolder => 'Mappa kiválasztása';
	@override String get resetToDefault => 'Visszaállítás alapértelmezettre';
	@override String currentPath({required Object path}) => 'Jelenlegi: ${path}';
	@override String get downloadLocationChanged => 'A letöltési hely megváltozott';
	@override String get downloadLocationReset => 'A letöltési hely visszaállt az alapértelmezettre';
	@override String get downloadLocationInvalid => 'A kiválasztott mappa nem írható';
	@override String get downloadLocationPickerUnavailable => 'A mappaválasztás ezen az eszközön nem érhető el';
	@override String get downloadOnWifiOnly => 'Letöltés csak Wi-Fi-n';
	@override String get downloadOnWifiOnlyDescription => 'Letöltések megakadályozása mobiladat-használat esetén';
	@override String get autoRemoveWatchedDownloads => 'Megnézett letöltések automatikus eltávolítása';
	@override String get autoRemoveWatchedDownloadsDescription => 'A megnézett letöltések automatikus törlése';
	@override String get autoDownloadContinueWatching => 'Autó-töltés Folytatás nézőpont';
	@override String get autoDownloadContinueWatchingDescription => 'Tartsa az elemeket a Fenntartható Figyelem rakodó letöltve, és távolítsa el őket, miután elhagyja a rakodót';
	@override String get downloadQuality => 'Download minőség';
	@override String get downloadQualityDescription => 'A Plex készíti a letöltésbe fordított másolatot. Jellyfin és Emby transzkód, míg a fájl letölthető; megszakított átvitelek újraindításra lehet szükség.';
	@override String get askDownloadQualityEachTime => 'Válassza ki a minőséget minden letöltéshez';
	@override String get askDownloadQualityEachTimeDescription => 'Megjelenítse a minőségi pickeret, mielőtt minden videót letölt';
	@override String get cellularDownloadBlocked => 'A letöltések mobilhálózaton le vannak tiltva. Használj Wi-Fi-t, vagy módosítsd a beállítást.';
	@override String get maxVolume => 'Maximális hangerő';
	@override String get maxVolumeDescription => 'A hangerő 100% fölé emelésének engedélyezése halk tartalmak esetén';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Megjeleníti a Discordon, hogy éppen mit nézel';
	@override String get services => 'Szolgáltatások';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr és egyéb szolgáltatások csatlakoztatása';
	@override String get manageLibrariesDescription => 'Könyvtárak sorrendjének módosítása és elrejtése';
	@override String get companionRemoteServer => 'Kísérőtávirányító szervere';
	@override String get companionRemoteServerDescription => 'Lehetővé teszi, hogy a hálózaton lévő mobileszközökről vezéreld az alkalmazást';
	@override String get companionRemoteServerStartFailed => 'Nem sikerült elindítani a kísérőtávirányító szerverét';
	@override String get companionRemoteServerStopFailed => 'Nem sikerült leállítani a kísérőtávirányító szerverét';
	@override String get autoPip => 'Automatikus kép a képben (PiP)';
	@override String get autoPipDescription => 'Lejátszás közben az alkalmazás elhagyásakor automatikusan kép a képben módra vált';
	@override String get matchContentFrameRate => 'Képkockasebesség illesztése a tartalomhoz';
	@override String get matchContentFrameRateDescription => 'A kijelző frissítési frekvenciájának igazítása a videóhoz';
	@override String get matchContentResolution => 'Igazítás a tartalom felbontásához';
	@override String get matchContentResolutionDescription => 'A kijelzőt a videó natív felbontására váltja, hogy a felskálázást a tévé végezze. Lejátszás közben a menük és a feliratok is felskálázódnak';
	@override String get matchRefreshRate => 'Frissítési frekvencia illesztése';
	@override String get matchRefreshRateDescription => 'A kijelző frissítési frekvenciájának igazítása teljes képernyőn';
	@override String get matchDynamicRange => 'Dinamikatartomány illesztése';
	@override String get matchDynamicRangeDescription => 'HDR bekapcsolása HDR-tartalmak esetén, majd visszaváltás SDR-re';
	@override String get displaySwitchDelay => 'Kijelzőváltási késleltetés';
	@override String get tunneledPlayback => 'Alagutas lejátszás';
	@override String get tunneledPlaybackDescription => 'Videóalagút használata. Tiltsd le, ha HDR-lejátszáskor fekete a kép vagy akadozik a mozgás.';
	@override String get audioPassthrough => 'Hangtovábbítás (passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS-hang továbbítása az erősítőre vagy a TV-re újrakódolás nélkül, a térhangzás megőrzésével. Kapcsold ki, ha nincs hang.';
	@override String get audioPassthroughDescriptionApple => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. A DTS és a TrueHD továbbra is többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. iOS, iPadOS és tvOS 26 vagy újabb rendszeren a TrueHD Atmos és a DTS:X térbeli hangzásként szól. A többi DTS- és TrueHD-sáv többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.';
	@override String get audioPassthroughOverriddenByNormalization => 'Ki, amíg a hangerőnormalizálás be van kapcsolva';
	@override String get audioChannelLimit => 'Hangcsatornák';
	@override String get audioChannelLimitDescription => 'A dekódolt hang lekeverése olyan hangszórókhoz, fejhallgatókhoz vagy HDMI-rendszerekhez, amelyek nem tudják lejátszani az összes csatornát';
	@override String get audioChannelLimitOriginal => 'Eredeti';
	@override String get audioChannelLimitOriginalDescription => 'A sáv összes csatornájának lejátszása';
	@override String get audioChannelLimitSurround51 => 'Legfeljebb 5.1';
	@override String get audioChannelLimitSurround51Description => '7.1 lekeverése 5.1-re olyan TV-khez és erősítőkhöz, amelyek csak 5.1-es PCM-et fogadnak. A hangtovábbítást nem érinti.';
	@override String get audioChannelLimitStereo => 'Sztereó';
	@override String get audioChannelLimitStereoDescription => 'Lekeverés két csatornára sztereó hangszórókhoz vagy fejhallgatóhoz. Kikapcsolja a hangtovábbítást.';
	@override String get downmixCenterBoost => 'Középső csatorna kiemelése';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Kiemelés (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Hangerő normalizálása lekeveréskor';
	@override String get audioDownmixNormalizeDescription => 'A keverés szintjének csökkentése a torzítás elkerülésére. Kapcsold ki az eredeti hangerő megőrzéséhez (a hangos jelenetek torzíthatnak).';
	@override String get dvConversionMode => 'Dolby Vision-átalakítás';
	@override String get dvConversionModeDescription => 'Válaszd ki, hogyan legyenek kezelve a Dolby Vision Profile 7 fájlok.';
	@override String get dvConversionAuto => 'Automatikus';
	@override String get dvConversionNative => 'Natív / letiltva';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Az eszköz képességeinek felismerése és szükség esetén a szokásos tartalék megoldás használata';
	@override String get dvConversionNativeDescription => 'A natív DV7 kényszerítése és a DV-átalakítási újrapróbálkozás letiltása';
	@override String get dvConversionDv81Description => 'A közvetlen RPU-átalakítás kényszerítése Dolby Vision Profile 8.1-re';
	@override String get dvConversionHevcStripDescription => 'A Dolby Vision RPU/EL-rétegek eltávolítása és egyszerű HEVC-ként való megjelenítés';
	@override String get experimentalDolbyVision => 'Kísérleti Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'A következő lejátszáskor a kísérleti FEL-megjelenítő használata. Külön motorbuild szükséges.';
	@override String get dvExperimentUnavailableDescription => 'Ez a kísérlet jelenleg csak Linuxon érhető el.';
	@override String get dvCompatibilityFallback => 'Kompatibilitási tartalék mód';
	@override String get dvCompatibilityFallbackDescription => 'Ha a kísérlet nem indul, a normál megjelenítő használata. A FEL-adatok elveszhetnek.';
	@override String get dvExperimentDiagnostics => 'Videókísérlet naplózása';
	@override String get dvExperimentDiagnosticsDescription => 'Részletes lejátszónaplók engedélyezése a következő lejátszáskor.';
	@override String get disableDolbyVision => 'Dolby Vision letiltása';
	@override String get disableDolbyVisionDescription => 'A Dolby Vision helyett a fájl HDR10 vagy HLG rétegének lejátszása, ha van ilyen';
	@override String get hdrSdrConversion => 'HDR–SDR átalakítás';
	@override String get hdrSdrConversionDescription => 'Válaszd ki, mi alakítsa át a HDR-videót, ha a kijelző nem tud HDR-t megjeleníteni.';
	@override String get hdrSdrConversionAuto => 'Automatikus';
	@override String get hdrSdrConversionAutoDescription => 'Eszköz Android 9-től, lejátszó a régebbi verziókon';
	@override String get hdrSdrConversionDevice => 'Eszköz';
	@override String get hdrSdrConversionDeviceDescription => 'Az eszköz videohardvere alakítja át. A leggyorsabb, de a színek az eszköztől függnek';
	@override String get hdrSdrConversionPlayer => 'Lejátszó';
	@override String get hdrSdrConversionPlayerDescription => 'A lejátszó alakítja át. Egységes színek, de a 4K akadozhat a gyengébb TV-boxokon';
	@override String get deinterlace => 'Deinterlacing';
	@override String get deinterlaceDescription => 'Fésűfog-műtermékek eltávolítása a váltott soros videóból (csak mpv lejátszóval)';
	@override String get deinterlaceOff => 'Ki';
	@override String get deinterlaceOffDescription => 'A váltott soros videó megjelenítése úgy, ahogy dekódolva lett';
	@override String get deinterlaceVideo => 'Videó';
	@override String get deinterlaceVideoDescription => 'Minden félképből teljes képkocka lesz. TV-re rögzített felvételekhez, például sporthoz, hírekhez és koncertekhez';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'A 29,97 fps-re telecine-eljárással átalakított filmek és animációk eredeti képkockáinak helyreállítása, ami gyakori az NTSC DVD-ken. A TV-re rögzített felvételek akadoznak. Az Élő TV a Videó módot használja';
	@override String get requireProfileSelectionOnOpen => 'Profil kérése az alkalmazás megnyitásakor';
	@override String get requireProfileSelectionOnOpenDescription => 'Profilválasztó megjelenítése minden alkalommal, amikor az alkalmazást megnyitod';
	@override String get forceTvMode => 'TV-mód kényszerítése';
	@override String get forceTvModeDescription => 'TV-elrendezés kényszerítése az automatikus felismeréssel nem rendelkező eszközökön. Újraindítást igényel.';
	@override String get startInFullscreen => 'Indítás teljes képernyőn';
	@override String get startInFullscreenDescription => 'A PlezyNG megnyitása teljes képernyős módban indításkor';
	@override String get exitFullscreenOnPlayerClose => 'Kilépés a teljes képernyőből a lejátszó bezárásakor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Automatikus kilépés a teljes képernyőből a videólejátszó bezárásakor';
	@override String get autoHidePerformanceOverlay => 'Teljesítményadatok automatikus elrejtése';
	@override String get autoHidePerformanceOverlayDescription => 'A teljesítményadatok elhalványítása a lejátszásvezérlőkkel együtt';
	@override String get showNavBarLabels => 'Navigációs sáv címkéinek megjelenítése';
	@override String get showNavBarLabelsDescription => 'Szöveges címkék megjelenítése a navigációs sáv ikonjai alatt';
	@override String get startupSection => 'Indítási oldal';
	@override String get preferredServer => 'Kedvenc szerverek';
	@override String get preferredServerDescription => 'A szerver eredményeinek prioritása, miközben minden csatlakoztatott szervert elérhetővé teszi.';
	@override String get preferredServerAutomatic => 'Automatikus';
	@override String get showExploreTab => 'Felfedezés lap megjelenítése';
	@override String get showExploreTabDescription => 'A Plex Discover és a csatlakoztatott követők tartalmait megjelenítő Felfedezés lap megjelenítése';
	@override String get hideEmptyLibraries => 'Tisztítsa el az üres könyvtárakat';
	@override String get hideEmptyLibrariesDescription => 'Távolítsa el a könyvtárakat, amelyek a kiszolgáló által jelentett objektumok számát nulláról a navigációból.';
	@override String get liveTvDefaultFavorites => 'Kedvenc csatornák alapértelmezés szerint';
	@override String get liveTvDefaultFavoritesDescription => 'Csak a kedvenc csatornák megjelenítése az Élő TV megnyitásakor';
	@override String get general => 'Általános';
	@override String get generalDescription => 'Nyelv, indítás és ablakviselkedés';
	@override String get languageAndRegion => 'Nyelv és régió';
	@override String get startup => 'Indítás';
	@override String get display => 'Kijelző';
	@override String get libraryAndCards => 'Könyvtár és kártyák';
	@override String get homeScreen => 'Kezdőképernyő';
	@override String get navigation => 'Navigáció';
	@override String get window => 'Ablak';
	@override String get liveTv => 'Élő TV';
	@override String get player => 'Lejátszó';
	@override String get videoAndDisplay => 'Videó és kijelző';
	@override String get audio => 'Hang';
	@override String get quality => 'Minőség';
	@override String get subtitles => 'Feliratok';
	@override String get seekAndTiming => 'Tekerés és időzítés';
	@override String get behavior => 'Viselkedés';
	@override String get gestures => 'Mozdulatok';
	@override String get gestureBrightnessSwipe => 'Fényerő-húzás';
	@override String get gestureBrightnessSwipeDescription => 'Húzd felfelé vagy lefelé a bal szélén a fényerő beállításához';
	@override String get gestureVolumeSwipe => 'Hangerő-húzás';
	@override String get gestureVolumeSwipeDescription => 'Húzd felfelé vagy lefelé a jobb szélén a hangerő beállításához';
	@override String get gesturePinchToZoom => 'Csípés a nagyításhoz';
	@override String get gesturePinchToZoomDescription => 'Csípj a videóra a nagyításhoz vagy kicsinyítéshez';
	@override String get gestureSeekSwipe => 'Keresés Swipe';
	@override String get gestureSeekSwipeDescription => 'A videó kereséséhez balra vagy jobbra váltja; szabadon engedje a ugrást';
	@override String get rememberBrightnessLevel => 'Fényerőszint megjegyzése';
	@override String get rememberBrightnessLevelDescription => 'A lejátszás az utolsó húzással beállított fényerővel indul';
	@override String get controls => 'Vezérlők';
	@override String get rememberPlayerChanges => 'Lejátszó módosításainak megjegyzése';
	@override String get rememberPlayerChangesDescription => 'A lejátszás közben végzett módosítások mentési és újbóli alkalmazási helye';
	@override String get scopePlaybackSpeed => 'Lejátszási sebesség';
	@override String get scopeShaderPreset => 'Shader-előbeállítás';
	@override String get scopeAspectRatio => 'Képarány';
	@override String get scopeSyncOffsets => 'Hang- és feliratszinkronizálás';
	@override String get playerScopeOff => 'Ne mentse';
	@override String get playerScopeGlobal => 'Mindenhol';
	@override String get playerScopeLibrary => 'Könyvtáronként';
	@override String get playerScopeTitle => 'Sorozatonként vagy filmenként';
	@override String get exportDialogTitle => 'PlezyNG-beállítások exportálása';
	@override String get followSystem => 'Rendszernyelv követése';
	@override String get followAppLanguage => 'A felület nyelvével megegyező';
	@override String get regionFormat => 'Területi formátumok';
	@override String get regionFormatDescription => 'Válassza ki a dátumok, számok és mértékegységek megjelenítési módját.';
	@override String get metadataLanguage => 'Metaadatok nyelve';
	@override String get metadataLanguageDescription => 'A címek és leírások előnyben részesített nyelve, ha a kiszolgáló támogatja. A hang és a felirat nyelve külön állítható be.';
	@override String get enterFullscreenOnPlaybackStart => 'Helyezze be a teljes képernyőt, amikor megkezdődik a playback';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Nyissa meg az asztali videót a teljes képernyőn, amikor elkezdődik a playback';
	@override String get extendVideoIntoDisplayCutout => 'Videó bővítése a Display Cutout-ba';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Hagyja, hogy a teljes képernyős videó használja a fényképezőgép cutout az Android telefonok';
	@override String get languageDescription => 'Válassza ki a használt nyelvet PlezyNG vezérlők és üzenetek. kövesse a rendszer nyomon követése a készülék nyelvét.';
	@override String get themeDescription => 'Válassza ki az alkalmazás során használt színeket és kontrasztokat.';
	@override String get libraryDensityDescription => 'Változtassa meg, hogy hány könyvtári kártyát alkalmaznak minden sorban.';
	@override String get displayScaleDescription => 'Visszaállítsa a felületet ebben az autó képernyőjén anélkül, hogy megváltoztatná a készülék szerinti szöveges méretét.';
	@override String get themeSongVolumeDescription => 'Állítsa be a tematikus dalok mennyiségét más audio-hoz képest.';
	@override String get viewModeDescription => 'Válassza ki, hogy a könyvtár elemei plakátként jelennek meg egy hálózatban vagy kompakt listaként.';
	@override String get gridViewDescription => 'Szervezze a könyvtári elemeket poszterek soraiban és oszlopaiban.';
	@override String get listViewDescription => 'A könyvtár elemeinek megjelenítése egy függőleges listában, több szöveggel elemenként.';
	@override String get gridSpacingDescription => 'Állítsa be a plakátok közötti távolságot a könyvtári hálózatokban.';
	@override String get gridSpacingTightDescription => 'A képernyőn több plakátot illeszkedik kisebb távolságokkal.';
	@override String get gridSpacingNormalDescription => 'Használja a plakátok közötti szabványos távolságot.';
	@override String get gridSpacingSpaciousDescription => 'Hozzon nagyobb távolságokat a plakátok között, hogy több szétválasztást kapjon.';
	@override String get episodePosterModeDescription => 'Válassza ki, melyik műalkotás jelenik meg az epizódkártyákon.';
	@override String get seriesPosterDescription => 'Használja a show-sorozat plakátját minden epizódhoz.';
	@override String get seasonPosterDescription => 'Használja a szezon plakátot minden epizódra, amikor elérhető.';
	@override String get episodeThumbnailDescription => 'Használjon egy keretet az epizódból, amikor elérhető.';
	@override String get continueWatchingActionDescription => 'Válassza ki, hogy mi történik, amikor aktiválja a Folyamatos megfigyelési kártyát.';
	@override String get continueWatchingPlayDescription => 'Azonnal indítsa el a filmet vagy az epizódot.';
	@override String get continueWatchingDetailsDescription => 'Nyissa meg először a címlapot, hogy áttekinthesse az adatokat és válasszon egy lépést.';
	@override String get episodeActionDescription => 'Válassza ki, mi történik, amikor egy epizódkártya aktiválódik.';
	@override String get episodePlayDescription => 'Az epizód azonnal megkezdődik.';
	@override String get episodeDetailsDescription => 'Nyissa meg az epizód oldalt a playback előtt.';
	@override String get contentScreensaverDelayDescription => 'Válassza ki, hogy mennyi időt vár a PlezyNG bevitele nélkül, mielőtt műalkotást mutatna.';
	@override String get continueWatchingRowSizeDescription => 'Válassza ki, hogy a kártyák hány méretűek a Folyamatos megfigyelési sorban.';
	@override String get rowSizeCompactDescription => 'Nézze meg a kisebb kártyákat, hogy több elem megfeleljen a soron.';
	@override String get rowSizeStandardDescription => 'Használja a kártya méretét.';
	@override String get rowSizeLargeDescription => 'Nézze meg a nagyobb kártyákat több műalkotási részletekkel.';
	@override String get visualEffectsDescription => 'Válassza ki az animációs és művészeti hatások költségvetését erre a készülékre.';
	@override String get visualEffectsFullDescription => 'Használja a teljes animációs és műalkotási hatásokat minden eszközön.';
	@override String get startupSectionDescription => 'Válassza ki, melyik szakasz megnyílik, amikor a PlezyNG elindul.';
	@override late final _Translations$settings$startupSectionOptions$hu startupSectionOptions = _Translations$settings$startupSectionOptions$hu._(_root);
	@override String get smallSkipDurationDescription => 'Állítsa be a távolságot, amelyet a rövid hátsó és előre irányításokat keres.';
	@override String get largeSkipDurationDescription => 'Állítsa be a távolságot, amelyet a hosszú hátsó és előre irányításokat keres.';
	@override String get rewindOnResumeDescription => 'Ezzel az összeggel mozgatja a lejátszást, amikor egy videót újra készítenek.';
	@override String get defaultSleepTimerDescription => 'Állítsa be a használt kezdeti időtartamot, amikor elkezdi az alvási időszámítást.';
	@override String get playNextCountdownDescription => 'Várjon sokáig, mielőtt elkezdené a következő epizódot. 0-ra állítsa be, hogy azonnal kezdődjön.';
	@override String get autoSkipDelaySettingDescription => 'Alkalmazható, amikor egy intro, kredit vagy hirdetés beállítva automatikusan elhagyja.';
	@override String get downmixCenterBoostDescription => 'Emelje fel a párbeszédet a központi csatornában, amikor a környező hangot sztereóba keverjük össze.';
	@override String get displaySwitchDelayDescription => 'Várjon, mielőtt megváltoztatná a kijelző üzemmódját, hogy a TV vagy a fogadó befejezheti az előző váltót.';
	@override String get playerBackendDescription => 'Válassza ki, melyik lejátszó motor dekódolja és visszahívja a videót ezen az eszközön.';
	@override String get exoPlayerDescription => 'Használja az Android indiai Media3 alapú lejátszóját és a támogatott hardverpályait.';
	@override String get mpvDescription => 'Használja az MPV-t, amely további lejátszásokat, alfejezeteket és videó feldolgozási ellenőrzéseket mutat be.';
	@override String get scopeOffDescription => 'Csak a jelenlegi lejátszásra vonatkozó módosításokat tartsa fenn.';
	@override String get scopeGlobalDescription => 'Ismét használja ugyanazt az értéket minden könyvtár és cím.';
	@override String get scopeLibraryDescription => 'Emlékezzünk egy külön értékre minden könyvtár számára.';
	@override String get scopeTitleDescription => 'Emlékezzünk egy külön értékre minden előadásra vagy filmre.';
	@override String get specialsOrderingServerDescription => 'Tartsa meg a média szerver által biztosított epizódrendet.';
	@override String get specialsOrderingAirDateDescription => 'Helyezze a különlegeseket a rendszeres epizódok között a levegő dátumánál.';
	@override String get specialsOrderingLastDescription => 'Minden különleges helyet a rendszeres szezonok után.';
	@override String get skipIntroModeDescription => 'Válassza ki, hogy az intro markerek normálisan játszanak-e, mutatnak egy ugrás gombot vagy automatikusan ugrálnak.';
	@override String get skipCreditsModeDescription => 'Válassza ki, hogy a hitelek normálisan játszanak-e, jelezzen egy ugrás gombot, vagy automatikusan ugrik.';
	@override String get skipAdsModeDescription => 'Válassza ki, hogy a kimutatott hirdetések normálisan játszanak-e, mutatnak egy ugrás gombot, vagy automatikusan ugrálnak.';
	@override String get playbackBufferAutoDescription => 'Hagyja, hogy az aktív játékos kiválassza a normális buffer méretét.';
	@override String get playbackBufferLargeDescription => 'Tartsa több médiát készen a lejátszást megelőzően; ez több memóriát használ.';
	@override String get playbackBufferExtraLargeDescription => 'Tartsa a legnagyobb olvasási-felület buffer; ez használja a legtöbb memóriát.';
	@override String get defaultQualityDescription => 'Állítsa be az alapértelmezett videó felbontást és bitrat tetőt a szerver által transzkódolt áramlásokhoz.';
	@override String get cellularQualityDescription => 'Az alapértelmezett minőség felülvizsgálata, amikor a készülék csak celluláris kapcsolatot használ.';
	@override String get remoteQualityDescription => 'Az alapértelmezett minőség felülvizsgálata a szerverhez való csatlakozás során egy távoli kapcsolaton keresztül.';
	@override String get qualityPresetOriginalDescription => 'Játssz a forrást a rendelkezésre álló minőségben anélkül, hogy kérné a kiszolgálót, hogy transzkódolja azt.';
	@override String get qualityPresetTranscodeOptionDescription => 'Kérje meg a szervert egy átalakított áram használatával a felbontás és bitrate látható fent.';
	@override String get qualityPresetSameAsDefaultDescription => 'Használja a kiválasztott minőséget az alapértelmezett minőségben.';
	@override String get musicQualityDescription => 'Állítsa be a szervertől megkövetelt maximális hangbiterességet; Az eredeti tartja a forrásáramlást.';
	@override String get musicQualityOriginalDescription => 'Játssz a forráskódot bitrate-capped transcode nélkül.';
	@override String get musicQualityTranscodeOptionDescription => 'Kérjen egy szerver transzkódot, amely a fenti bitrate közelében van rögzítve; a tényleges kimenetel változhat.';
	@override String get maxVolumeInputLabel => 'Maximális térfogat (%)';
	@override String get checkForUpdatesDescription => 'Most ellenőrizze, hogy a PlezyNG újabb verziója elérhető-e.';
	@override String get appearanceDescription => 'Válassza ki az alkalmazás témáját, és módosítsa a könyvtári kártyákat, az otthoni sorokat és a navigációt.';
	@override String get prerollLibraryDescription => 'Válassza ki a könyvtárat, amely tartalmazza a klipek elérhető film pre-rolls.';
	@override String get prerollSelectionDescription => 'Válassza ki, hogy mely klipek a kiválasztott könyvtár játszhat előtt filmek.';
	@override String get contentScreensaverDelayOptionDescription => 'Várjon sok percet bejutás nélkül, mielőtt a screensaver műalkotást mutatja.';
	@override String get videoCodecOptionDescription => 'Engedje meg a közvetlen lejátszást erre a kódolóra, amikor támogatásra kerül. A nem ellenőrzött kódokat a média szerver átruházza.';
}

// Path: themeEditor
class _Translations$themeEditor$hu extends Translations$themeEditor$en {
	_Translations$themeEditor$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Beépített';
	@override String get presets => 'Előre beállított';
	@override String get custom => 'Egyéni';
	@override String get customEmpty => 'Még nincs létrehozva';
	@override String get editCustom => 'Egyéni téma szerkesztése';
	@override String get editCustomDescription => 'Válaszd ki magad az összes színt';
	@override String get locked => 'Élethosszú hozzáférés szükséges';
	@override String get savedLocked => 'Megtakarítás – élethosszig tartó hozzáféréssel rendelkezésre áll';
	@override String get title => 'Egyéni téma';
	@override String get startFrom => 'Kiindulási téma';
	@override String get startFromDescription => 'Az összes szín átmásolása egy másik témából';
	@override String get colors => 'Színek';
	@override String get preview => 'Előnézet';
	@override late final _Translations$themeEditor$slots$hu slots = _Translations$themeEditor$slots$hu._(_root);
	@override String get opacity => 'Átlátszatlanság';
	@override String get hexHint => '#RRGGBB vagy #AARRGGBB';
	@override String get fromOtherThemes => 'Más témákból';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} – ${color}';
	@override late final _Translations$themeEditor$contrast$hu contrast = _Translations$themeEditor$contrast$hu._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, az ajánlott ${minimum}:1 alatt';
	@override String get discardTitle => 'Elveted a módosításokat?';
	@override String get discardMessage => 'A nem mentett színmódosítások elvesznek.';
	@override String get discard => 'Elvetés';
	@override String previewCardTitle({required Object number}) => '${number}. epizód';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} perc van hátra';
	@override String get previewSwitch => 'Automatikus lejátszás';
	@override String get previewMutedText => 'Így néz ki a másodlagos szöveg';
	@override String get themeSystemDescription => 'Kövesse a készülék megjelenését, és automatikusan váltja át a fényt és a sötétet.';
	@override String get themeLightDescription => 'Használjon fényes háttérrel sötét szöveggel.';
	@override String get themeDarkDescription => 'Használjon sötét háttérrel fényes szöveggel.';
	@override String get themeOledDescription => 'Használjon közel fekete felületeket, amelyek csökkentik a fényt az OLED képernyőn.';
	@override String get themeEmberDescription => 'Használjon meleg vörös és amber hangsúlyos színeket.';
	@override String get themeGlacierDescription => 'Használja a hideg kék színt.';
	@override String get themeForestDescription => 'Használjon zöld és természetes hangsúlyos színeket.';
	@override String get themePlumDescription => 'Használjon lila és plum hangsúlyos színeket.';
	@override String get themePaperDescription => 'Használjon meleg papírszerű felületeket és tinta inspirált színeket.';
	@override String get themeCustomDescription => 'Használja az általad létrehozott színpalettát a személyre szabott tematikus szerkesztőben.';
	@override String get editorDescription => 'Válasszon egy palettás színt, módosítsa a hangját, telítettségét, fényességét vagy láthatatlanságát, és nézze meg az előzetes frissítést, mielőtt mentse.';
}

// Path: search
class _Translations$search$hu extends Translations$search$en {
	_Translations$search$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Keresés filmek, sorozatok és zenék között...';
	@override String get tryDifferentTerm => 'Próbálj másik keresési kifejezést';
	@override String get searchYourMedia => 'Keresés a saját médiatartalmak között';
	@override String get enterTitleActorOrKeyword => 'Adj meg egy címet, színészt vagy kulcsszót';
	@override String get people => 'Személyek';
}

// Path: hotkeys
class _Translations$hotkeys$hu extends Translations$hotkeys$en {
	_Translations$hotkeys$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Billentyűparancs beállítása ehhez: ${actionName}';
	@override String get clearShortcut => 'Billentyűparancs törlése';
	@override String get noShortcutSet => 'Nincs billentyűparancs beállítva';
	@override String get currentShortcut => 'Jelenlegi billentyűparancs:';
	@override String get pressToRecord => 'Válaszd ki a billentyűparancs rögzítéséhez';
	@override String get recordingShortcut => 'Nyomd meg most a billentyűparancsot';
	@override late final _Translations$hotkeys$actions$hu actions = _Translations$hotkeys$actions$hu._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$hu extends Translations$fileInfo$en {
	_Translations$fileInfo$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fájlinformáció';
	@override String get overview => 'Áttekintés';
	@override String get video => 'Videó';
	@override String get audio => 'Hang';
	@override String get subtitles => 'Feliratok';
	@override String get images => 'Beágyazott képek';
	@override String get dataStreams => 'Adatfolyamok';
	@override String get lyrics => 'Dalszövegek';
	@override String get file => 'Fájl';
	@override String get attachments => 'Mellékletek';
	@override String get delivery => 'Kézbesítés';
	@override String versionCounter({required Object index, required Object count}) => '${index}. verzió a(z) ${count} közül';
	@override String fileCounter({required Object index, required Object count}) => '${index}. fájl a(z) ${count} közül';
	@override String get noStreams => 'A szerver nem jelentett adatfolyamot ehhez a fájlhoz.';
	@override String get copyPath => 'Útvonal másolása';
	@override String get pathCopied => 'Fájlútvonal kimásolva';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Kodekcímke';
	@override String get resolution => 'Felbontás';
	@override String get codedResolution => 'Kódolt felbontás';
	@override String get bitrate => 'Bitráta';
	@override String get frameRate => 'Képkockasebesség';
	@override String get rotation => 'Forgatás';
	@override String get comment => 'Megjegyzés';
	@override String get audioDescription => 'Hangleírás';
	@override String get headerCompression => 'Fejléc-tömörítés';
	@override String get sidecarFile => 'Kísérő fájl';
	@override String get transportTimestamp => 'Szállítási időbélyeg';
	@override String get displayOffset => 'Megjelenítési eltolás';
	@override String get previewFailureCode => 'Előnézeti hibakód';
	@override String get previewRetries => 'Előnézeti újrapróbálkozások';
	@override String get aspectRatio => 'Méretarány';
	@override String get pixelAspectRatio => 'Pixel képarány';
	@override String get profile => 'Profil';
	@override String get level => 'Szint';
	@override String get bitDepth => 'Bitmélység';
	@override String get pixelFormat => 'Pixelformátum';
	@override String get colorSpace => 'Színtér';
	@override String get colorRange => 'Színtartomány';
	@override String get colorPrimaries => 'Elsődleges színek';
	@override String get colorTransfer => 'Színátvitel';
	@override String get chromaSubsampling => 'Krominancia-alulmintavételezés';
	@override String get chromaLocation => 'Kroma elhelyezkedés';
	@override String get scanType => 'Pásztázási típus';
	@override String get interlaced => 'Váltott soros';
	@override String get anamorphic => 'Anamorf';
	@override String get referenceFrames => 'Referencia képkockák';
	@override String get dynamicRange => 'Dinamikatartomány';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision szint';
	@override String get dolbyVisionVersion => 'Dolby Vision verzió';
	@override String get dolbyVisionLayers => 'Dolby Vision rétegek';
	@override String get baseLayerCompatibility => 'Alapréteg-kompatibilitás';
	@override String get avcBitstream => 'AVC bitfolyam';
	@override String get nalLengthSize => 'NAL hosszméret';
	@override String get scalingMatrix => 'Egyéni méretezési mátrix';
	@override String get streamIdentifier => 'Adatfolyam-azonosító';
	@override String get streamIndex => 'Adatfolyam-index';
	@override String get streamId => 'Adatfolyam azonosítója';
	@override String get language => 'Nyelv';
	@override String get languageCode => 'Nyelvkód';
	@override String get streamTitle => 'Sáv címe';
	@override String get channels => 'Csatornák';
	@override String get sampleRate => 'Mintavételi frekvencia';
	@override String get spatialAudio => 'Térbeli hang';
	@override String get textBased => 'Szövegalapú';
	@override String get subtitleFormat => 'Kísérő formátum';
	@override String get provider => 'Szolgáltató';
	@override String get matchScore => 'Egyezési pontszám';
	@override String get externalDelivery => 'Külön is kiszolgálható';
	@override String get sidecarPath => 'Kísérő fájl útvonala';
	@override String get sourceStream => 'Másolva innen';
	@override String get temporary => 'Ideiglenes';
	@override String get timeBase => 'Időalap';
	@override String get overallBitrate => 'Összesített bitráta';
	@override String get path => 'Elérési út';
	@override String get fileName => 'Fájlnév';
	@override String get size => 'Méret';
	@override String get totalSize => 'Teljes méret';
	@override String get container => 'Konténer';
	@override String get duration => 'Időtartam';
	@override String get previewThumbnails => 'Előnézeti miniatűrök';
	@override String get previewIndex => 'Előnézeti index';
	@override String get packetLength => 'Csomaghossz';
	@override String get filePresent => 'Fájl jelen van';
	@override String get fileReadable => 'A szerver számára olvasható';
	@override String get streamPath => 'Adatfolyam útvonala';
	@override String get optimizedForStreaming => 'Adatfolyam-továbbításra optimalizálva';
	@override String get has64bitOffsets => '64 bites eltolások';
	@override String get protocol => 'Protokoll';
	@override String get mediaType => 'Médiatípus';
	@override String get sourceKind => 'Forrás típusa';
	@override String get optimizedVersion => 'Optimalizált verzió';
	@override String get optimizationTarget => 'Optimalizálási cél';
	@override String get deletedAt => 'Törölve';
	@override String get remoteSource => 'Távoli forrás';
	@override String get infiniteStream => 'Végtelen adatfolyam';
	@override String get directPlay => 'Közvetlen lejátszás';
	@override String get directStream => 'Közvetlen adatfolyam';
	@override String get transcoding => 'Átkódolás';
	@override String get etag => 'ETag';
	@override String get versionId => 'Verzióazonosító';
	@override String get fileId => 'Fájlazonosító';
	@override String get defaultAudioTrack => 'Alapértelmezett hangsáv';
	@override String get defaultSubtitleTrack => 'Alapértelmezett feliratsáv';
	@override String get subtitlesOff => 'Ki';
	@override String get flagDefault => 'Alapértelmezett';
	@override String get flagForced => 'Kényszerített';
	@override String get flagSelected => 'Kiválasztva';
	@override String get flagExternal => 'Külső';
	@override String get flagHearingImpaired => 'Nagyothallóknak';
	@override String get flagDub => 'Szinkron';
	@override String get flagOriginal => 'Eredeti';
	@override String get channelsMono => 'Monó';
	@override String dolbyVisionProfile({required Object profile}) => '${profile} profil';
}

// Path: mediaMenu
class _Translations$mediaMenu$hu extends Translations$mediaMenu$en {
	_Translations$mediaMenu$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Megjelölés megtekintettként';
	@override String get markAsUnwatched => 'Megjelölés nem megtekintettként';
	@override String get removeFromContinueWatching => 'Eltávolítás a folytatásból';
	@override String get viewDetails => 'Részletek megtekintése';
	@override String get goToSeries => 'Ugrás a sorozathoz';
	@override String get shufflePlay => 'Véletlenszerű lejátszás';
	@override String get shuffleNotAvailableOffline => 'A véletlenszerű lejátszás nem érhető el offline';
	@override String get fileInfo => 'Fájlinformáció';
	@override String get deleteEpisodeFromServer => 'Epizód törlése a szerverről';
	@override String get deleteSeasonFromServer => 'Évad törlése a szerverről';
	@override String get deleteShowFromServer => 'Sorozat törlése a szerverről';
	@override String get deleteMovieFromServer => 'Film törlése a szerverről';
	@override String get deleteEpisodeTitle => 'Töröljük ezt az epizódot?';
	@override String get deleteSeasonTitle => 'Töröljük ezt az évadot?';
	@override String get deleteShowTitle => 'Töröljük ezt a sorozatot?';
	@override String get deleteMovieTitle => 'Töröljük ezt a filmet?';
	@override String get deleteEpisodeConfirm => 'Epizód törlése';
	@override String get deleteSeasonConfirm => 'Évad törlése';
	@override String get deleteShowConfirm => 'Sorozat törlése';
	@override String get deleteMovieConfirm => 'Film törlése';
	@override String get deleteAnyway => 'Törlés mindenképp';
	@override String confirmDeleteTarget({required Object title}) => 'Véglegesen töröljük a(z) ${title} elemet a szerverről?';
	@override String get deleteMultipleWarning => 'Ez magában foglalja az összes epizódot és azok fájljait.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: 'Ez törli az összes (${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) epizódot benne és a hozzá tartozó fájlt.',
		other: 'Ez törli az összes (${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) epizódot benne és a fájljaikat.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: 'Ez az elem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fájlban van tárolva, amely törlésre kerül.',
		other: 'Ez az elem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fájlban van tárolva, és mindegyik törlésre kerül.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: 'További ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód is ugyanabban a fájlban van, és szintén törlésre kerül:',
		other: 'További ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód is ugyanabban a fájlban van, és szintén törlésre kerül:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'A PlezyNG nem tudta ellenőrizni, mely fájlokat távolítja el ez, ezért a fent nevezett elemnél többet is törölhet. Szakítsa meg és próbálja újra, vagy töröljön mindenképp.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'A szerver nem szolgáltatott fájladatokat ehhez az elemhez, ezért a PlezyNG nem tudja ellenőrizni, mely fájlokat távolít el. A fent nevezett elemnél többet is törölhet.';
	@override String get mediaDeletedSuccessfully => 'Médiaelem sikeresen törölve';
	@override String get mediaFailedToDelete => 'Nem sikerült a médiaelem törlése';
	@override String get rate => 'Értékelés';
	@override String get playFromBeginning => 'Lejátszás az elejétől';
	@override String get playVersion => 'Verzió lejátszása...';
}

// Path: rateSheet
class _Translations$rateSheet$hu extends Translations$rateSheet$en {
	_Translations$rateSheet$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Értékelés';
	@override String get server => 'Szerver';
	@override String get favorite => 'Kedvenc';
	@override String get favorited => 'Kedvencekhez hozzáadva';
	@override String get saved => 'Mentve';
	@override String get notAvailable => 'Nincs találat';
	@override String get noConnectedServices => 'Az értékeléshez csatlakoztass egy szolgáltatást a Beállításokban.';
}

// Path: accessibility
class _Translations$accessibility$hu extends Translations$accessibility$en {
	_Translations$accessibility$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-sorozat';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'megtekintve';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} százalék megtekintve';
	@override String get mediaCardUnwatched => 'még nem láttad';
	@override String get tapToPlay => 'Koppints a lejátszáshoz';
	@override String get decrease => 'Csökkentés';
	@override String get increase => 'Növelés';
	@override String decreaseValue({required Object label}) => '${label} csökkentése';
	@override String increaseValue({required Object label}) => '${label} növelése';
	@override String get hue => 'Árnyalat';
	@override String get saturation => 'Telítettség';
	@override String get brightness => 'Fényerő';
	@override String get hexColor => 'Hex színkód';
	@override String get expandText => 'Szöveg kibontása';
	@override String get collapseText => 'Szöveg összecsukása';
	@override String get alphabetNavigation => 'Ábécé szerinti navigáció';
	@override String get alphabetScrollHint => 'A betűnkénti léptetéshez pöccints felfelé vagy lefelé';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '${row}. sor a(z) ${rowCount} sorból, ${column}. oszlop a(z) ${columnCount} oszlopból';
	@override String rowPosition({required Object row, required Object rowCount}) => '${row}. sor a(z) ${rowCount} sorból';
	@override String get autoScrollPlay => 'Automatikus görgetés indítása';
	@override String get autoScrollPause => 'Automatikus görgetés szüneteltetése';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Vörös';
	@override String get green => 'Zöld';
	@override String get blue => 'kék';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'hozzáférhetőség';
	@override String get summary => 'szöveg, kontraszt, mozgás és ellenőrzés';
	@override String get systemHint => 'A készülék hozzáférhetőségének beállításait mindig alkalmazzák.Ezek a lehetőségek a PlezyNG egészében módosításokat adnak hozzá.';
	@override String get readability => 'Olvasás és láthatóság';
	@override String get textSize => 'További szövegméret';
	@override String get preview => 'Olvasson, hallgasson és nézd meg a saját sebességedben.';
	@override String get boldText => 'Bold Interface szöveg';
	@override String get highContrast => 'Nagy kontraszt';
	@override String get highContrastHint => 'Erősebb szöveg, kiemelkedések és a fényes vagy sötét felületeken lévő figyelemfelkeltő mutatók.';
	@override String get interaction => 'Mozgás és interakció';
	@override String get reduceMotion => 'Mozgás csökkentése';
	@override String get reduceMotionHint => 'Állítsd le a fókuszjelző mozgását, az oldalátmeneteket és a díszítő animációkat.';
	@override String get largeTargets => 'Nagyabb érintkezési célok';
	@override String get largeTargetsHint => 'A megosztott vezérlők több helyet biztosítanak a hozzáféréshez és a segéd navigációhoz.';
	@override String get navigationHint => 'A Tab és a Shift+Tab billentyűkkel léphetsz a vezérlők között, az Enter vagy a szóköz aktiválja őket, az Escape vagy a Vissza pedig bezár. Megnyitott könyvnél a nagyítás és az olvasási beállítások is elérhetők.';
	@override String get textSizeDescription => 'Skála felület szöveg PlezyNG-ben a készülék rendszer szöveges méretének beállítása mellett.';
	@override String get boldTextHint => 'Használjon súlyosabb felület címkéket és üzeneteket, hogy könnyebben megkülönböztessék őket.';
}

// Path: tooltips
class _Translations$tooltips$hu extends Translations$tooltips$en {
	_Translations$tooltips$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Véletlenszerű lejátszás';
	@override String get playTrailer => 'Előzetes lejátszása';
	@override String get markAsWatched => 'Megjelölés megtekintettként';
	@override String get markAsUnwatched => 'Megjelölés nem megtekintettként';
}

// Path: audioTracks
class _Translations$audioTracks$hu extends Translations$audioTracks$en {
	_Translations$audioTracks$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => '${n}. hangsáv';
}

// Path: videoControls
class _Translations$videoControls$hu extends Translations$videoControls$en {
	_Translations$videoControls$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Hang';
	@override String get subtitlesLabel => 'Feliratok';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Fekete sávok';
	@override String get fillScreen => 'Képernyő kitöltése';
	@override String get stretch => 'Nyújtás';
	@override String get lockRotation => 'Forgatás zárolása';
	@override String get unlockRotation => 'Forgatás feloldása';
	@override String get timerActive => 'Időzítő aktív';
	@override String playbackWillPauseIn({required Object duration}) => 'A lejátszás ${duration} múlva szünetel';
	@override String get sleepTimerEndOfVideo => 'Jelenlegi videó vége';
	@override String get sleepTimerStopAtHeader => 'Leállítás ekkor';
	@override String get sleepTimerDurationHeader => 'Időzítő';
	@override String get playbackWillPauseAtEnd => 'A lejátszás szünetel a videó végén';
	@override String get stillWatching => 'Még nézed?';
	@override String pausingIn({required Object seconds}) => 'Szüneteltetés ${seconds} mp múlva';
	@override String get continueWatching => 'Folytatás';
	@override String get autoPlayNext => 'Következő automatikus lejátszása';
	@override String get playNext => 'Következő lejátszása';
	@override String get playButton => 'Lejátszás';
	@override String get pauseButton => 'Szünet';
	@override String get playbackPaused => 'Szüneteltetve';
	@override String get playbackResumed => 'Lejátszás';
	@override String get loadingVideo => 'Videó betöltése';
	@override String get showPlaybackControls => 'Lejátszásvezérlők megjelenítése';
	@override String get hidePlaybackControls => 'Lejátszásvezérlők elrejtése';
	@override String seekBackwardButton({required Object seconds}) => 'Tekerés hátra ${seconds} másodperccel';
	@override String seekForwardButton({required Object seconds}) => 'Tekerés előre ${seconds} másodperccel';
	@override String get previousButton => 'Előző epizód';
	@override String get nextButton => 'Következő epizód';
	@override String get previousChapterButton => 'Előző fejezet';
	@override String get nextChapterButton => 'Következő fejezet';
	@override String get muteButton => 'Némítás';
	@override String get unmuteButton => 'Hang visszakapcsolása';
	@override String get settingsButton => 'Lejátszási beállítások';
	@override String get tracksButton => 'Hang és feliratok';
	@override String get chaptersButton => 'Fejezetek';
	@override String get segmentLoopHelp => 'Az A beállítása, majd a B későbbi beállítás az idővonalon.';
	@override String get setLoopStart => 'Kezdőlap Hírek A (A)';
	@override String get setLoopEnd => 'A csúszás vége (B)';
	@override String get clearSegmentLoop => 'Tiszta szegmens';
	@override String get setLoopStartFirst => 'Állítsa be a pályát kezdődik (A) előtt a véget (B).';
	@override String get loopEndAfterStart => 'A befejezésnek későn kell lennie, mint a kezdet.';
	@override String get segmentLoopUnavailable => 'A Segment Looping nem érhető el ebben a playbackben.';
	@override String get loopPointNotSet => 'Nem állít';
	@override String get bookmarksHelp => 'A könyvjelzők ebben a készülékben kerülnek mentésre. Válassza ki az egyiket, hogy menjen erre az időre.';
	@override String get bookmarksButton => 'könyvjelzők';
	@override String get chaptersAndBookmarks => 'fejezetek és könyvjelzők';
	@override String get segmentLoop => 'Segmentális lejátszás';
	@override String get addBookmark => 'Hozzáadása Bookmark';
	@override String get bookmarkName => 'Bookmark név';
	@override String get bookmarkNameHint => 'Például a színpad megnyitása';
	@override String bookmarkDefaultName({required Object n}) => 'könyvjelző ${n}';
	@override String get bookmarkNameRequired => 'Írjon be egy nevet erre a könyvjelzőre.';
	@override String get deleteBookmark => 'Távolítsa el a Bookmark';
	@override String get bookmarkLimitReached => 'Ez a cikk már 100 könyvjelzővel rendelkezik.';
	@override String get bookmarkUnavailable => 'Nem tudtam menteni vagy eltávolítani ezt a könyvjelzőt.';
	@override String get bookmarkSaved => 'A könyv megmentett.';
	@override String get bookmarkDeleted => 'Bookmark törlésre került.';
	@override String loopPointSet({required Object point, required Object time}) => 'Loop pont ${point} beállítása a ${time}A';
	@override String get noChaptersOrBookmarks => 'Nincs rendelkezésre álló fejezetek vagy könyvjelzők.';
	@override String get versionQualityButton => 'Verzió és minőség';
	@override String get versionColumnHeader => 'Verzió';
	@override String get qualityColumnHeader => 'Minőség';
	@override String get qualityOriginal => 'Eredeti';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'A transzkódolás nem érhető el — eredeti minőség lejátszása';
	@override String get subtitleUnavailableFallback => 'A kiválasztott feliratot nem sikerült betölteni — folytatás felirat nélkül';
	@override String get pipButton => 'Kép a képben mód';
	@override String get aspectRatioButton => 'Méretarány';
	@override String get ambientLighting => 'Környezeti megvilágítás';
	@override String get fullscreenButton => 'Teljes képernyős mód bekapcsolása';
	@override String get exitFullscreenButton => 'Teljes képernyős mód kikapcsolása';
	@override String get alwaysOnTopButton => 'Mindig legfelül';
	@override String get rotationLockButton => 'Elforgatás zárolása';
	@override String get lockScreen => 'Képernyő zárolása';
	@override String get screenLockButton => 'Képernyőzár';
	@override String get timelineSlider => 'Videó idősáv';
	@override String get volumeSlider => 'Hangerő';
	@override String endsAt({required Object time}) => 'Vége: ${time}';
	@override String get pipActive => 'Lejátszás kép a képben módban';
	@override String get pipFailed => 'Nem sikerült elindítani a kép a képben módot';
	@override String get screenshotSaved => 'Képernyőkép elmentve';
	@override String get screenshotFailed => 'Nem sikerült képernyőképet készíteni';
	@override String zoomPercent({required Object percent}) => 'Nagyítás ${percent}%';
	@override String volumePercent({required Object percent}) => 'Hangerő ${percent}%';
	@override late final _Translations$videoControls$pipErrors$hu pipErrors = _Translations$videoControls$pipErrors$hu._(_root);
	@override String get chapters => 'Fejezetek';
	@override String get noChaptersAvailable => 'Nincsenek elérhető fejezetek';
	@override String get queue => 'Lejátszási sor';
	@override String get noQueueItems => 'Nincsenek elemek a sorban';
	@override String get noAudioDevicesAvailable => 'Nincsenek elérhető audioeszközök';
	@override String get searchSubtitles => 'Feliratok keresése';
	@override String get language => 'Nyelv';
	@override String get noSubtitlesFound => 'Nem találhatók feliratok';
	@override String get subtitleDownloaded => 'Felirat letöltve';
	@override String get subtitleDownloadedNotApplied => 'Felirat letöltve, de nem sikerült kiválasztani';
	@override String get subtitleDownloadFailed => 'Nem sikerült a felirat letöltése';
	@override String get searchLanguages => 'Nyelvek keresése...';
	@override String get skipIntro => 'Főcím átugrása';
	@override String get skipCredits => 'Stáblista átugrása';
	@override String get nextEpisode => 'Következő epizód';
	@override String subtitleTrack({required Object n}) => '${n}. sáv';
	@override String subtitleFile({required Object name}) => '${name} felirat';
	@override String forcedTrack({required Object label}) => '${label} (kényszerített)';
	@override String get osdSubtitlesOff => 'Feliratok: ki';
	@override String osdSubtitles({required Object track}) => 'Feliratok: ${track}';
	@override String osdAudio({required Object track}) => 'Hang: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} keretrendszer',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} keretek',
	);
	@override String get trackSelectionTitle => 'Válassza ki a játékot a playback előtt';
	@override String get trackSelectionAuto => 'Automatikus kiválasztás';
	@override String get openMiniPlayer => 'Nyitott mini játékos';
	@override String get returnToFullPlayer => 'Visszatérés a teljes játékoshoz';
	@override String get loadSubtitleFile => 'A subtitle fájl felvétele...';
	@override String get subtitleLoadFailed => 'Nem töltöttem fel a subtitle fájlt';
	@override String get skipAds => 'Skip hirdetések';
	@override String get tapToUnlock => 'Koppintson a feloldáshoz';
	@override String get tapAgainToUnlock => 'Koppintson ismét a feloldáshoz';
}

// Path: messages
class _Translations$messages$hu extends Translations$messages$en {
	_Translations$messages$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Megjelölve megtekintettként';
	@override String get markedAsUnwatched => 'Megjelölve nem megtekintettként';
	@override String get markedAsWatchedOffline => 'Megjelölve megtekintettként (szinkronizálás online állapotban)';
	@override String get markedAsUnwatchedOffline => 'Megjelölve nem megtekintettként (szinkronizálás online állapotban)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatikusan eltávolítva: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintett letöltés automatikusan eltávolítva',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintett letöltés automatikusan eltávolítva',
	);
	@override String get removedFromContinueWatching => 'Eltávolítva a folytatásból';
	@override String errorLoading({required Object error}) => 'Hiba: ${error}';
	@override String get searchPartialResults => 'Néhány médiaszervert nem sikerült keresni. Az elérhető találatok megjelenítése.';
	@override String get streamInterrupted => 'Az adatfolyam megszakadt. Az újrapróbálkozáshoz indítsd el a lejátszást, vagy tekerj másik pozícióra.';
	@override String get liveStreamInterrupted => 'Az élő adás megszakadt. Nyomd meg a lejátszást az újrapróbálkozáshoz.';
	@override String get fileInfoNotAvailable => 'A fájlinformáció nem érhető el';
	@override String get playbackAuthenticationRequired => 'Az elem lejátszásához jelentkezz be újra a médiaszerverre.';
	@override String get playbackServerUnavailable => 'A médiaszerver nem érhető el. Próbáld újra később.';
	@override String get playbackDataInvalid => 'A szerver érvénytelen lejátszási adatokat küldött.';
	@override String get playbackCancelled => 'A lejátszás megszakítva.';
	@override String get playbackFailed => 'Nem sikerült elindítani a lejátszást.';
	@override String playbackFailedDetail({required Object error}) => 'Nem sikerült elindítani a lejátszást: ${error}';
	@override String get audioOutputFailed => 'A hangkimenet nem válaszol. Ellenőrizd a TV vagy az erősítő hangcsatlakozását; ha más alkalmazásokban sincs hang, indítsd újra az eszközt.';
	@override String get mediaUnavailable => 'Ez a tartalom már nem érhető el.';
	@override String errorLoadingFileInfo({required Object error}) => 'Hiba a fájlinformációk betöltésekor: ${error}';
	@override String get errorLoadingSeries => 'Hiba a sorozat betöltésekor';
	@override String get musicNotSupported => 'A zenelejátszás még nem támogatott';
	@override String get noDescriptionAvailable => 'Nincs elérhető leírás';
	@override String get noProfilesAvailable => 'Nincsenek elérhető profilok';
	@override String get contactAdminForProfiles => 'Lépj kapcsolatba a szerver adminisztrátorával profilok hozzáadásához';
	@override String get unableToDetermineLibrarySection => 'Nem sikerült meghatározni az elem könyvtári részlegét';
	@override String get logsCleared => 'Naplók törölve';
	@override String get logsCopied => 'Naplók a vágólapra másolva';
	@override String get noLogsAvailable => 'Nincsenek elérhető naplók';
	@override String libraryScanning({required Object title}) => '"${title}" beolvasása...';
	@override String libraryScanStarted({required Object title}) => 'Könyvtár beolvasása elindítva a következőhöz: "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Nem sikerült a könyvtár beolvasása: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metaadatok frissítése a következőhöz: "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metaadatok frissítése elindítva a következőhöz: "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Nem sikerült a metaadatok frissítése: ${error}';
	@override String get logoutConfirm => 'Biztosan ki szeretnél jelentkezni?';
	@override String get noSeasonsFound => 'Nem találhatók évadok';
	@override String get seasonsLoadFailed => 'Nem sikerült az évadok betöltése';
	@override String get noEpisodesFound => 'Nem találhatók epizódok az első évadban';
	@override String get noEpisodesFoundGeneral => 'Nem találhatók epizódok';
	@override String get episodesLoadFailed => 'Nem sikerült az epizódok betöltése';
	@override String get noResultsFound => 'Nincs találat';
	@override String sleepTimerSet({required Object label}) => 'Elalvási időzítő beállítva: ${label}';
	@override String get noItemsAvailable => 'Nincsenek elérhető elemek';
	@override String get failedToCreatePlayQueueNoItems => 'Nem sikerült létrehozni a lejátszási sort — nincsenek elemek';
	@override String failedPlayback({required Object action, required Object error}) => 'Nem sikerült a művelet (${action}): ${error}';
	@override String get switchingToCompatiblePlayer => 'Váltás kompatibilis lejátszóra...';
	@override String get serverLimitTitle => 'A lejátszás nem sikerült';
	@override String get serverLimitBody => 'Szerverhiba (HTTP 500). A munkamenetet valószínűleg egy sávszélességi vagy átkódolási korlát utasította el. Kérd meg a tulajdonost a korlát módosítására.';
	@override String get mediaUnreadableTitle => 'A fájl nem érhető el';
	@override String get mediaUnreadableBody => 'A szerver megtalálta ezt az elemet, de nem tudta beolvasni a fájlját (HTTP 404). A fájl valószínűleg áthelyezésre vagy törlésre került, vagy a tárhelye offline. Kérje meg a szerver tulajdonosát, hogy ellenőrizze a fájlt, és vizsgálja újra a könyvtárat.';
	@override String get serverBusyTitle => 'A stream nem érhető el';
	@override String get serverBusyBody => 'A szerver ismételten megtagadta ennek a fájlnak a streamelését (HTTP 503). Lehet, hogy újraindul, túlterhelt, vagy a fájl tárhelye nem érhető el. Próbáld újra egy kis idő múlva – ha a probléma továbbra is fennáll, kérd meg a szerver tulajdonosát, hogy ellenőrizze a szervert és a fájl tárhelyét.';
	@override String get playbackNotAllowedTitle => 'A lejátszás nem engedélyezett';
	@override String get playbackNotAllowedBody => 'A szerver megtagadta ennek az elemnek a streamelését (HTTP 403). Lehet, hogy a fiókodnak nincs engedélye a lejátszására, vagy a szerver csak a helyi hálózatán engedélyezi a lejátszást.';
	@override String get logsUploaded => 'Naplók feltöltve';
	@override String get logsUploadFailed => 'Nem sikerült a naplók feltöltése';
	@override String get logId => 'Naplóazonosító';
	@override String get burnedSubtitlesUseMenu => 'A feliratok bele vannak égetve ebbe a streambe. A feliratmenüben módosíthatod őket.';
	@override String get noVideoUrl => 'Nem érhető el videó-URL';
	@override String get playbackNoMediaSources => 'A szerver nem adott vissza lejátszható médiaforrást';
	@override String get playbackDataNotPrepared => 'A lejátszás az adatok elkészülte előtt indult el';
	@override String get streamSelectionUnavailable => 'Ehhez a forráshoz nem érhető el a streamek kiválasztása';
	@override String get streamSelectionFailed => 'Nem sikerült alkalmazni a kiválasztott streameket';
	@override String get trackSelectionNotRemembered => 'Ez a sávválasztás csak az aktuális lejátszásra érvényes.';
	@override String get serverUnavailableForProfile => 'Az aktív profilhoz nem érhető el szerver';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$hu extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'A gyors barna fox a szégyenletes kutya fölé ugrik';
	@override String get text => 'Szöveg';
	@override String get border => 'Keret';
	@override String get background => 'Háttér';
	@override String get fontSize => 'Betűméret';
	@override String get textColor => 'Szövegszín';
	@override String get borderSize => 'Keretméret';
	@override String get borderColor => 'Keretszín';
	@override String get backgroundOpacity => 'Háttér átlátszatlansága';
	@override String get backgroundColor => 'Háttérszín';
	@override String get position => 'Pozíció';
	@override String get assOverride => 'ASS felülbírálása';
	@override String get overrideScale => 'Skálázás';
	@override String get overrideForce => 'Kényszerítés';
	@override String get overrideStrip => 'Stílus eltávolítása';
	@override String get positionTop => 'Fent';
	@override String get positionBottom => 'Lent';
	@override String get useMargins => 'Margók használata';
	@override String get useMarginsDescription => 'A szöveges feliratok a videón kívüli területen is megjelenhetnek. A stilizált feliratok megtarthatják eredeti pozíciójukat.';
	@override String get anchorToScreen => 'Képernyőhöz rögzítés';
	@override String get anchorToScreenDescription => 'A szöveges feliratok megjelenítése a szélesvásznú videó alatti fekete sávban';
	@override String get bold => 'Félkövér';
	@override String get italic => 'Dőlt';
	@override String get renderResolution => 'Renderelési felbontás';
	@override String get renderResolutionScreen => 'Képernyőfelbontás';
	@override String get renderResolutionVideo => 'Videófelbontás';
	@override String get fontSizeDescription => 'Állítsa be a szöveg méretét ezen az eszközön.';
	@override String get textColorDescription => 'Válassza ki a szöveg színét.';
	@override String get borderSizeDescription => 'Állítsa be a nyomtatvány vastagságát az alszöveg szövegének körül.';
	@override String get borderColorDescription => 'Válassza ki a színét, amelyet az alfejezéshez használnak.';
	@override String get backgroundColorDescription => 'Válassza ki a színét az alszöveg szövegének hátterében.';
	@override String get backgroundOpacityDescription => 'Állítsa be, hogy a háttér mennyire átlátszó: 0% világos és 100% szilárd.';
	@override String get positionDescription => '0 % a videó tetején, és 100% az alsó.';
	@override String get assOverrideDescription => 'Válassza ki, hogy a játékos követi-e, módosítja, helyettesíti vagy eltávolítja az ASS altitkokba beépített stílust.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$hu assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$hu._(_root);
	@override String get renderResolutionDescription => 'Válassza ki a felbontást, amelyet a kép és az ASS altitkok rasterizálására használnak. Alacsonyabb Android skálák csökkenthetik a rendering munkát, de látszólag vékonyabbak.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$hu renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$hu._(_root);
	@override String get boldDescription => 'Írja le a szubtitkár szövegét súlyosabb súlyban.';
	@override String get italicDescription => 'Írja le az olasz nyelvű szöveget.';
}

// Path: mpvConfig
class _Translations$mpvConfig$hu extends Translations$mpvConfig$en {
	_Translations$mpvConfig$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Haladó videólejátszó beállítások';
	@override String get presets => 'Előbeállítások';
	@override String get noPresets => 'Nincsenek mentett előbeállítások';
	@override String get saveAsPreset => 'Mentés előbeállításként...';
	@override String get presetName => 'Előbeállítás neve';
	@override String get presetNameHint => 'Add meg az előbeállítás nevét';
	@override String get loadPreset => 'Betöltés';
	@override String get deletePreset => 'Törlés';
	@override String get presetSaved => 'Előbeállítás mentve';
	@override String get presetLoaded => 'Előbeállítás betöltve';
	@override String get presetDeleted => 'Előbeállítás törölve';
	@override String get confirmDeletePreset => 'Biztosan törölni szeretnéd ezt az előbeállítást?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# megjegyzés';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Sor hozzáadása';
	@override String get removeLine => 'Sor eltávolítása';
	@override String get embeddedVoHint => 'A vo, gpu-context és gpu-api beállítások Linuxon figyelmen kívül maradnak: a beágyazott videó mindig a vo=libmpv-n keresztül jelenik meg a videósíkon, a gpu-next (amelyre az ArtCNN-hez hasonló compute shadereknek szükségük van) pedig nem futhat beágyazva.';
}

// Path: dialog
class _Translations$dialog$hu extends Translations$dialog$en {
	_Translations$dialog$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Művelet megerősítése';
}

// Path: profiles
class _Translations$profiles$hu extends Translations$profiles$en {
	_Translations$profiles$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG profil hozzáadása';
	@override String get switchingProfile => 'Profilváltás…';
	@override String get deleteThisProfileTitle => 'Törlöd ezt a profilt?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} eltávolítása. A kapcsolatokat nem érinti.';
	@override String get active => 'Aktív';
	@override String get manage => 'Kezelés';
	@override String get delete => 'Törlés';
	@override String get signOut => 'Kijelentkezés';
	@override String get signOutPlexTitle => 'Kijelentkezel a Plexből?';
	@override String signOutPlexMessage({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és az összes Plex Home-felhasználót? Bármikor visszajelentkezhetsz.';
	@override String get signOutPlexDeleteDownloads => 'A letöltések törlése is';
	@override String get signOutPlexDeleteDownloadsDescription => 'Ellenkező esetben az eszközön maradnak, és újra megjelennek, amikor visszajelentkezel ebbe a fiókba.';
	@override String get signedOutPlex => 'Kijelentkezve a Plexből.';
	@override String get signOutFailed => 'A kijelentkezés nem sikerült.';
	@override String get sectionTitle => 'Profilok';
	@override String get summarySingle => 'Adj hozzá profilokat a kezelt felhasználók és a helyi profilok együttes használatához';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profil · aktív: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profil';
	@override String get removeConnectionTitle => 'Eltávolítod a kapcsolatot?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Eltávolítod ${displayName} hozzáférését a(z) ${connectionLabel} kapcsolathoz. Más profilok megtartják.';
	@override String get deleteProfileTitle => 'Törlöd a profilt?';
	@override String deleteProfileMessage({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és annak kapcsolatait. A szerverek elérhetőek maradnak.';
	@override String get profileNameLabel => 'Profil neve';
	@override String get pinProtectionLabel => 'PIN-kódos védelem';
	@override String get copyAutomationLink => 'Android automatizálási link';
	@override String get copyAutomationLinkDescription => 'Válassza ki ezt a profilot a Android szándékból vagy automatizálásból.';
	@override String get automationLinkCopied => 'Profil automatizálása link másolt.';
	@override String get pinManagedByPlex => 'A PIN-kódot a Plex kezeli. Szerkesztés a plex.tv oldalon.';
	@override String get noPinSetEditOnPlex => 'Nincs PIN beállítva. PIN kéréséhez szerkeszd az otthoni felhasználót a plex.tv-n.';
	@override String get setPin => 'PIN beállítása';
	@override String get setPinTitle => 'PIN beállítása';
	@override String get confirmPinTitle => 'PIN megerősítése';
	@override String get pinSet => 'PIN beállítva';
	@override String get changePin => 'Módosítás';
	@override String get removePin => 'Eltávolítás';
	@override String get connectionsLabel => 'Kapcsolatok';
	@override String get add => 'Hozzáadás';
	@override String get deleteProfileButton => 'Profil törlése';
	@override String get noConnectionsHint => 'Nincsenek kapcsolatok — adj hozzá egyet a profil használatához.';
	@override String get noConnections => 'Nincsenek kapcsolatok';
	@override String get plexHomeAccount => 'Plex Home-fiók';
	@override String plexAccountChip({required Object account}) => 'Plex-fiók: ${account}';
	@override String plexAccountUserChip({required Object account, required Object user}) => '${account} fiókján keresztül: ${user}';
	@override String get connectionDefault => 'Alapértelmezett';
	@override String connectionAs({required Object displayName}) => 'mint ${displayName}';
	@override String get makeDefault => 'Beállítás alapértelmezettként';
	@override String get removeConnection => 'Eltávolítás';
	@override String get profileRenamed => 'Profil átnevezve.';
	@override String borrowAddTo({required Object displayName}) => 'Hozzáadás a következőhöz: ${displayName}';
	@override String get borrowExplain => 'Használd egy másik profil kapcsolatát. A PIN-kóddal védett profilokhoz PIN-kód szükséges.';
	@override String get borrowEmpty => 'Még nincs használható kapcsolat.';
	@override String get borrowEmptySubtitle => 'Először csatlakoztasd a Plexet, a Jellyfint vagy az Embyt egy másik profilhoz.';
	@override String get borrowLoadFailed => 'Nem sikerült betölteni az elérhető kapcsolatokat. Próbáld újra.';
	@override String borrowFromProfile({required Object displayName}) => 'Innen: ${displayName}';
	@override String get borrowConnectionBorrowed => 'Kapcsolat átvéve.';
	@override String get borrowFailed => 'Nem sikerült átvenni a kapcsolatot.';
	@override String get incorrectPin => 'Helytelen PIN-kód.';
	@override String get incorrectPinTryAgain => 'Helytelen PIN-kód. Próbáld újra.';
	@override String get sourceProfileMissingParentAccount => 'A forrásprofilból hiányzik a szülőfiók.';
	@override String get failedToLoadHomeUsers => 'Nem sikerült betölteni a Plex Home-felhasználókat. Ellenőrizd a kapcsolatot, majd próbáld újra.';
	@override String get failedToVerifyPin => 'Nem sikerült a PIN-kód ellenőrzése.';
	@override String get newProfile => 'Új profil';
	@override String get profileNameHint => 'pl. Vendégek, Gyerekek, Nappali';
	@override String get pinProtectionOptional => 'PIN-védelem (opcionális)';
	@override String get pinExplain => '4 jegyű PIN-kód szükséges a profilváltáshoz.';
	@override String get continueButton => 'Folytatás';
	@override String get pinsDontMatch => 'A PIN-kódok nem egyeznek';
	@override String get tokenIdentityMismatch => 'A Plex-profil tokenje nem a várt szerverhez tartozik';
	@override String get settingsLocked => 'A beállítások zárva vannak a profilhoz.';
	@override String get unlockSettings => 'A beállítások feloldása';
	@override String get showExploreForProfile => 'Show Explore for this profil - A profil megtekintése';
	@override String get showExploreForProfileDescription => 'Távolítsa el a Explore eltávolítását a profil navigációjából.';
}

// Path: connections
class _Translations$connections$hu extends Translations$connections$en {
	_Translations$connections$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Kapcsolatok';
	@override String get addConnection => 'Kapcsolat hozzáadása';
	@override String get addConnectionSubtitleNoProfile => 'Jelentkezz be Plexszel, vagy csatlakoztass egy Jellyfin- vagy Emby-szervert';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Hozzáadás a következőhöz (${displayName}): Plex, Jellyfin, Emby vagy más profilkapcsolat';
	@override String sessionExpiredOne({required Object name}) => 'A(z) ${name} munkamenete lejárt';
	@override String sessionExpiredMany({required Object count}) => '${count} szerver munkamenete lejárt';
	@override String accessDeniedOne({required Object name}) => 'A(z) ${name} megtagadta a hozzáférést ettől a fióktól';
	@override String accessDeniedMany({required Object count}) => '${count} szerver megtagadta a hozzáférést ettől a fióktól';
	@override String get signInAgain => 'Bejelentkezés újra';
	@override String editMediaBrowserTitle({required Object product}) => 'A(z) ${product} kapcsolat szerkesztése';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Adjon hozzá vagy távolítson el URL-eket a(z) ${serverName} esetén. A PlezyNG a legkisebb késleltetésű, elérhető URL-t fogja használni.';
}

// Path: accountPreferences
class _Translations$accountPreferences$hu extends Translations$accountPreferences$en {
	_Translations$accountPreferences$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Fiókbeállítások';
	@override String hubSubtitleSingle({required Object account}) => 'Hang-, felirat- és könyvtárbeállítások mentve a(z) ${account} fiókra';
	@override String hubSubtitleMultiple({required Object count}) => 'Hang-, felirat- és könyvtárbeállítások mentve ${count} fiókra';
	@override String get pickAccount => 'Minden fiók a saját beállításait tárolja. Válaszd ki a szerkesztendőt.';
	@override String get storedOnAccount => 'Ezek a beállítások magán a fiókon tárolódnak, így minden bejelentkezett alkalmazás használja őket — beleértve a Plezyt a többi eszközödön.';
	@override String get noAccounts => 'Nincs beállítható fiók';
	@override String get noAccountsHint => 'Jelentkezz be a Plexbe, vagy csatlakoztass egy Jellyfin- vagy Emby-szervert, és az azon a fiókon tárolt beállítások itt jelennek meg.';
	@override String get unavailable => 'Ez a fiók nem érhető el';
	@override String get loadFailed => 'Nem sikerült betölteni ezeket a beállításokat';
	@override String get noPreference => 'Nincs preferencia';
	@override String get notSet => 'Nincs beállítva';
	@override late final _Translations$accountPreferences$groups$hu groups = _Translations$accountPreferences$groups$hu._(_root);
	@override String get preferredAudioLanguage => 'Elsődleges hangnyelv';
	@override String get autoSelectAudio => 'Hangsáv kiválasztása nyelv alapján';
	@override String get autoSelectAudioDescription => 'Ki kapcsolásnál a fájl által alapértelmezettként megjelölt hangsáv marad.';
	@override String get preferredSubtitleLanguage => 'Elsődleges feliratnyelv';
	@override String get subtitleMode => 'Feliratok bekapcsolása';
	@override late final _Translations$accountPreferences$subtitleModes$hu subtitleModes = _Translations$accountPreferences$subtitleModes$hu._(_root);
	@override String get subtitleAccessibility => 'SDH-feliratok';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$hu subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$hu._(_root);
	@override String get forcedSubtitles => 'Kényszerített feliratok';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$hu forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$hu._(_root);
	@override String get displayMissingEpisodes => 'Hiányzó epizódok megjelenítése';
	@override String get displayMissingEpisodesDescription => 'Azoknak az epizódoknak a listázása, amelyeket a szerver ismer, de nincs hozzájuk fájl.';
	@override String get hidePlayedInLatest => 'Megnézett elemek elrejtése a Legújabbak között';
	@override String get hidePlayedInLatestDescription => 'A már megnézett elemek kimaradnak a szerver Legújabbak soraiból.';
	@override String get displayCollectionsView => 'Gyűjtemények nézet megjelenítése';
	@override String get displayCollectionsViewDescription => 'A szerver Gyűjtemények nézetének megjelenítése a könyvtárak mellett.';
	@override String get rewatchingInNextUp => 'Újranézett sorozatok megtartása a Következikben';
	@override String get rewatchingInNextUpDescription => 'Ha befejezel egy sorozatot, és újra elkezded, a Következik az újranézést követi, ahelyett hogy eldobná a sorozatot.';
	@override String get watchedIndicator => 'Megtekintett jelzések';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$hu watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$hu._(_root);
	@override String get mediaReviewsVisibility => 'Értékelések és kritikák';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$hu mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$hu._(_root);
	@override String get preferredAudioLanguageDescription => 'Előnyben részesíti az audio nyomtatásokat ebben a nyelven, amikor a szerver vagy a lejátszó automatikusan kiválasztja a nyomtatást.';
	@override String get preferredSubtitleLanguageDescription => 'Előnyben részesíti a szubtitkák nyomon követését ebben a nyelven, amikor az altitkok automatikusan kiválasztódnak.';
	@override String get subtitleAccessibilityDescription => 'Válassza ki, hogy az SDH kapciók előnyben részesülnek-e vagy szükségesek-e az automatikus alszámválasztás során.';
	@override String get forcedSubtitleDescription => 'Válassza ki, hogy az automatikus kiválasztás során előnyben részesülnek-e vagy megkövetelik-e a kényszerítő alkategóriák.';
	@override String get watchedIndicatorDescription => 'Válassza ki, hogy mely médiatípusok kapnak megfigyelhető ellenőrző jelet a szerver interfészben.';
	@override String get mediaReviewsVisibilityDescription => 'Válassza ki, hogy mely közönség és kritikus értékelések a szerver megjeleníti a média oldalak.';
	@override String get subtitleModeDescription => 'Válassza ki, amikor az altitkok automatikusan aktiválódnak ebben a szerverfiókban.';
	@override String get hubDescription => 'Ezek a preferenciák tárolódnak a médiaszolgáltató fiókjában, és más ügyfelekre is alkalmazhatók.';
}

// Path: discover
class _Translations$discover$hu extends Translations$discover$en {
	_Translations$discover$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Felfedezés';
	@override String get noContentAvailable => 'Nincs elérhető tartalom';
	@override String get addMediaToLibraries => 'Adj hozzá médiát a könyvtáraidhoz';
	@override String get continueWatching => 'Folytatás';
	@override String continueWatchingIn({required Object library}) => 'Folytatás itt: ${library}';
	@override String get nextUp => 'Következik';
	@override String nextUpIn({required Object library}) => 'Következik itt: ${library}';
	@override String get recentlyAdded => 'Legutóbb hozzáadva';
	@override String recentlyAddedIn({required Object library}) => 'Legutóbb hozzáadva itt: ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Legújabb albumok itt: ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Legutóbb lejátszva itt: ${library}';
	@override String mostPlayedIn({required Object library}) => 'Legtöbbször lejátszva itt: ${library}';
	@override String playEpisode({required Object season, required Object episode}) => '${season}. évad, ${episode}. epizód';
	@override String get overview => 'Áttekintés';
	@override String get cast => 'Szereplők';
	@override late final _Translations$discover$findNext$hu findNext = _Translations$discover$findNext$hu._(_root);
	@override String get extras => 'Előzetesek és extrák';
	@override String get studio => 'Stúdió';
	@override String get rating => 'Értékelés';
	@override String get director => 'Rendező';
	@override String get directors => 'Rendezők';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-sorozat';
	@override String minutesLeft({required Object minutes}) => '${minutes} perc van hátra';
	@override String get moreLikeThis => 'Hasonló tartalmak';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cím',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cím',
	);
	@override late final _Translations$discover$person$hu person = _Translations$discover$person$hu._(_root);
}

// Path: errors
class _Translations$errors$hu extends Translations$errors$en {
	_Translations$errors$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Keresés sikertelen: ${error}';
	@override String get searchUnavailable => 'A keresés egyetlen médiaszervert sem tudott elérni.';
	@override String connectionTimeout({required Object context}) => 'Hálózati időtúllépés a következő betöltésekor: ${context}';
	@override String get connectionFailed => 'Nem sikerült csatlakozni a médiaszerverhez';
	@override String unableToLoad({required Object context}) => 'Nem sikerült betölteni a következőt: ${context}. Próbáld újra.';
	@override String get noClientAvailable => 'Nincs elérhető kliens';
	@override String get pleaseEnterToken => 'Adj meg egy tokent';
	@override String get invalidToken => 'Érvénytelen token';
	@override String failedToVerifyToken({required Object error}) => 'Nem sikerült a token ellenőrzése: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Nem sikerült átváltani a következő profilra: ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Nem sikerült törölni a következőt: ${displayName}';
	@override String get failedToRate => 'Nem sikerült frissíteni az értékelést';
	@override String get reasonTimedOut => 'időtúllépés történt a kapcsolatban';
	@override String get reasonUnreachable => 'a médiaszerver nem érhető el';
	@override String get reasonRefused => 'a médiaszerver elutasította a kérést';
	@override String get reasonNotFound => 'az elem már nem található a médiaszerveren';
	@override String get reasonServerError => 'a médiaszerver hibát jelzett';
	@override String get reasonCancelled => 'a kérés meg lett szakítva';
	@override String get reasonUnexpected => 'váratlan hiba történt';
}

// Path: libraries
class _Translations$libraries$hu extends Translations$libraries$en {
	_Translations$libraries$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Játssz egy véletlenszerű filmet';
	@override String get randomPickFailed => 'Nem tudtam kiválasztani egy véletlenszerű filmet ebből a könyvtárból.';
	@override String get title => 'Könyvtárak';
	@override String get fallbackTitle => 'Könyvtár';
	@override String get scanLibraryFiles => 'Könyvtárfájlok beolvasása';
	@override String get scanLibrary => 'Könyvtár beolvasása';
	@override String get analyze => 'Elemzés';
	@override String get analyzeLibrary => 'Könyvtár elemzése';
	@override String get refreshMetadata => 'Metaadatok frissítése';
	@override String get emptyTrash => 'Lomtár ürítése';
	@override String emptyingTrash({required Object title}) => 'Lomtár ürítése a következőhöz: "${title}"...';
	@override String trashEmptied({required Object title}) => 'Lomtár kiürítve a következőhöz: "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Nem sikerült a lomtár ürítése: ${error}';
	@override String analyzing({required Object title}) => '"${title}" elemzése...';
	@override String analysisStarted({required Object title}) => 'Elemzés elindítva a következőhöz: "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Nem sikerült a könyvtár elemzése: ${error}';
	@override String get noLibrariesFound => 'Nem találhatók könyvtárak';
	@override String get allLibrariesHidden => 'Minden könyvtár el van rejtve';
	@override String hiddenLibrariesCount({required Object count}) => 'Rejtett könyvtárak (${count})';
	@override String get thisLibraryIsEmpty => 'Ez a könyvtár üres';
	@override String get noItemsMatchFilters => 'Nincs az aktív szűrőknek megfelelő elem';
	@override String get resetFilters => 'Szűrők visszaállítása';
	@override String get all => 'Összes';
	@override String get clearAll => 'Összes törlése';
	@override String scanLibraryConfirm({required Object title}) => 'Biztosan be szeretnéd olvasni a következőt: "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Biztosan elemezni szeretnéd a következőt: "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Biztosan frissíteni szeretnéd a metaadatokat a következőhöz: "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Biztosan ki szeretnéd üríteni a lomtárat a következőnél: "${title}"?';
	@override String get manageLibraries => 'Könyvtárak kezelése';
	@override String get sort => 'Rendezés';
	@override String get sortBy => 'Rendezés ez alapján';
	@override String get filters => 'Szűrők';
	@override String get confirmActionMessage => 'Biztosan végre szeretnéd hajtani ezt a műveletet?';
	@override String get showLibrary => 'Könyvtár megjelenítése';
	@override String get hideLibrary => 'Könyvtár elrejtése';
	@override String get libraryOptions => 'Könyvtár beállításai';
	@override String get content => 'könyvtár tartalma';
	@override String get selectLibrary => 'Könyvtár kiválasztása';
	@override String filtersWithCount({required Object count}) => 'Szűrők (${count})';
	@override String get noRecommendations => 'Nincsenek elérhető ajánlások';
	@override String get noCollections => 'Nincsenek gyűjtemények ebben a könyvtárban';
	@override String get noFoldersFound => 'Nem találhatók mappák';
	@override String get folders => 'mappák';
	@override late final _Translations$libraries$tabs$hu tabs = _Translations$libraries$tabs$hu._(_root);
	@override late final _Translations$libraries$groupings$hu groupings = _Translations$libraries$groupings$hu._(_root);
	@override late final _Translations$libraries$filterCategories$hu filterCategories = _Translations$libraries$filterCategories$hu._(_root);
	@override late final _Translations$libraries$sortLabels$hu sortLabels = _Translations$libraries$sortLabels$hu._(_root);
	@override late final _Translations$libraries$advancedFilters$hu advancedFilters = _Translations$libraries$advancedFilters$hu._(_root);
	@override late final _Translations$libraries$selection$hu selection = _Translations$libraries$selection$hu._(_root);
}

// Path: about
class _Translations$about$hu extends Translations$about$en {
	_Translations$about$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Névjegy';
	@override String get openSourceLicenses => 'Nyílt forráskódú licencek';
	@override String versionLabel({required Object version}) => 'Verzió: ${version}';
	@override String get appDescription => 'Gyönyörű Flutter-kliens a Plexhez, a Jellyfinhez és az Embyhez';
	@override String get viewLicensesDescription => 'Külső fejlesztésű programkönyvtárak licenceinek megtekintése';
	@override String get privacyPolicy => 'Adatvédelmi tájékoztató';
}

// Path: serverSelection
class _Translations$serverSelection$hu extends Translations$serverSelection$en {
	_Translations$serverSelection$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nem találhatók szerverek ehhez a fiókhoz: ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Nem sikerült a szerverek betöltése: ${error}';
	@override String get noValidServers => 'Nem található használható szerver ehhez a fiókhoz';
}

// Path: hubDetail
class _Translations$hubDetail$hu extends Translations$hubDetail$en {
	_Translations$hubDetail$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cím';
	@override String get releaseYear => 'Kiadási év';
	@override String get dateAdded => 'Hozzáadás dátuma';
	@override String get rating => 'Értékelés';
	@override String get noItemsFound => 'Nem találhatók elemek';
}

// Path: logs
class _Translations$logs$hu extends Translations$logs$en {
	_Translations$logs$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Naplók törlése';
	@override String get copyLogs => 'Naplók másolása';
	@override String get uploadLogs => 'Naplók feltöltése';
	@override String get saveLogs => 'Logs to File tárolás';
	@override String logsSaved({required Object path}) => 'A regisztrációt a ${path}';
	@override String get saveLogsFailed => 'Nem tudta megmenteni a log fájlt.';
}

// Path: startup
class _Translations$startup$hu extends Translations$startup$en {
	_Translations$startup$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'A PlezyNG nem tudott elindulni';
	@override String get failedBody => 'Valami hiba történt az indítás során. Az alábbi részletek mutatják, mi hibázott.';
	@override String get failedBodyRepairable => 'A PlezyNG mentett beállításfájlja sérült, és újra kell építeni, mielőtt a PlezyNG elindulhatna. Az újrapróbálkozás nem segít – válassza a Tárhely javítása lehetőséget.';
	@override String get phaseLabel => 'Lépés';
	@override String get showDetails => 'Részletek megjelenítése';
	@override String get hideDetails => 'Részletek elrejtése';
	@override String get copyDetails => 'Részletek másolása';
	@override String get detailsCopied => 'A részletek a vágólapra kerültek';
	@override String get uploadDetails => 'Részletek feltöltése';
	@override String get repairStorage => 'Tárhely javítása';
	@override String get repairTitle => 'Javítsuk a tárolt adatokat?';
	@override String get repairBodyCommon => 'A PlezyNG beállításfájlja sérült, és nem olvasható. A javítás minden beállítást visszaállít az alapértelmezettre.';
	@override String get repairBodyOneCredential => 'Egy mentett bejelentkezés sérült, és nem olvasható. A javítás csak azt távolítja el; a többi beállítása érintetlen marad.';
	@override String get repairBodySignInsKept => 'A szervereinek és profiljainak bejelentkezve kell maradniuk.';
	@override String get repairBodySignInsLost => 'A mentett bejelentkezéseket védő kulcs nem nyerhető vissza ebből a fájlból, ezért minden szerverre és profilba újra be kell jelentkeznie. A médiaszerveren semmi nem érintett.';
	@override String get repairBodySessionsUncertain => 'A nyomkövetők (MAL, AniList, Simkl, Trakt) és a Seerr külön vannak tárolva, és megmaradhatnak vagy nem. A PlezyNG pontosan megmondja, mit őrzött meg.';
	@override String get repairConfirm => 'Javítás';
	@override String get repairSucceeded => 'A tárhely javítva';
	@override String get repairNeedsRestart => 'A tárhely javítva – újraindítás szükséges';
	@override String get restartRequiredBody => 'Az adatait kijavítottuk, de a PlezyNG-nek frissen kell elindulnia, mielőtt használhatná. Zárja be a PlezyNG-t, és nyissa meg újra.';
	@override String get quitPlezy => 'Kilépés a PlezyNG-ből';
	@override String get repairFailed => 'A javítás nem sikerült';
	@override String get repairKeptSignIns => 'A szerverei és profiljai továbbra is be vannak jelentkezve.';
	@override String get repairLostSignIns => 'A mentett bejelentkezéseket védő kulcs nem volt visszanyerhető. Minden szerverre és profilba újra be kell jelentkeznie.';
	@override String get repairLostSessions => 'Legalább egy nyomkövető- vagy Seerr-kapcsolat elveszett, és újra kell csatlakoztatni.';
	@override String get backupTitle => 'A sérült fájlról másolat készült';
	@override String get backupWarning => 'Bejelentkezési adatait tartalmazza. Ne töltse fel és ne ossza meg.';
	@override String get deleteBackup => 'Másolat törlése';
	@override String get backupDeleted => 'A másolat törölve.';
	@override String get previousFailureTitle => 'A PlezyNG legutóbb nem tudott elindulni';
}

// Path: licenses
class _Translations$licenses$hu extends Translations$licenses$en {
	_Translations$licenses$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Kapcsolódó csomagok';
	@override String get license => 'Licenc';
	@override String licenseNumber({required Object number}) => '${number}. licenc';
	@override String licensesCount({required Object count}) => '${count} licenc';
}

// Path: navigation
class _Translations$navigation$hu extends Translations$navigation$en {
	_Translations$navigation$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Könyvtárak';
	@override String get downloads => 'Letöltések';
	@override String get liveTv => 'Élő TV';
	@override String get explore => 'Böngészés';
}

// Path: explore
class _Translations$explore$hu extends Translations$explore$en {
	_Translations$explore$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$hu mdblistShelves = _Translations$explore$mdblistShelves$hu._(_root);
	@override String get title => 'Böngészés';
	@override String get selectSource => 'Forrás kiválasztása';
	@override late final _Translations$explore$rows$hu rows = _Translations$explore$rows$hu._(_root);
	@override late final _Translations$explore$status$hu status = _Translations$explore$status$hu._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód',
	);
	@override String get cast => 'Szereplők';
	@override String get characters => 'Karakterek';
	@override String get addToWatchlist => 'Hozzáadás a Néznivalókhoz';
	@override String get removeFromWatchlist => 'Eltávolítás a Néznivalókból';
	@override String get addedToWatchlist => 'Hozzáadva a figyelőlistához';
	@override String get removedFromWatchlist => 'Eltávolítva a figyelőlistáról';
	@override String get watchlistUpdateFailed => 'Nem sikerült a Néznivalók frissítése';
	@override String get watchlistNoMatch => 'Nem sikerült ezt az elemet figyelőlistához társítani';
	@override String get notInLibrary => 'Nincs a könyvtáradban';
	@override String get inTheseLibraries => 'Ezekben a könyvtárakban';
	@override String get checkingLibrary => 'Könyvtár ellenőrzése...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: 'Nem sikerült ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} szervert ellenőrizni',
		other: 'Nem sikerült ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} szervert ellenőrizni',
	);
	@override String get emptyTitle => 'Még nincs itt semmi';
	@override String emptyMessage({required Object source}) => 'A(z) ${source} forrásból származó sorok itt fognak megjelenni, amint van tartalmuk.';
	@override String searchHint({required Object source}) => 'Keresés itt: ${source}';
	@override String searchEmpty({required Object query}) => 'Nincs találat a következőre: "${query}"';
	@override String searchPrompt({required Object source}) => 'Filmek és sorozatok keresése a következőn: ${source}.';
	@override String get searchFailed => 'A keresés nem sikerült. Ellenőrizd a kapcsolatot és próbáld újra.';
	@override late final _Translations$explore$badge$hu badge = _Translations$explore$badge$hu._(_root);
	@override late final _Translations$explore$stats$hu stats = _Translations$explore$stats$hu._(_root);
	@override late final _Translations$explore$season$hu season = _Translations$explore$season$hu._(_root);
	@override late final _Translations$explore$format$hu format = _Translations$explore$format$hu._(_root);
	@override late final _Translations$explore$sourceMaterial$hu sourceMaterial = _Translations$explore$sourceMaterial$hu._(_root);
	@override late final _Translations$explore$creditRole$hu creditRole = _Translations$explore$creditRole$hu._(_root);
	@override late final _Translations$explore$relation$hu relation = _Translations$explore$relation$hu._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Adásban: ${day}, ${time} órakor';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Adásban: ${day}, ${time} ${timezone}';
	@override late final _Translations$explore$detail$hu detail = _Translations$explore$detail$hu._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} találat',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} találat',
	);
}

// Path: liveTv
class _Translations$liveTv$hu extends Translations$liveTv$en {
	_Translations$liveTv$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Élő TV';
	@override String get guide => 'Műsorújság';
	@override String get noChannels => 'Nincsenek elérhető csatornák';
	@override String get noDvr => 'Egyik szerveren sincs beállítva DVR';
	@override String get serverUnavailable => 'Az Élő TV szerver nem érhető el.';
	@override String get serverNotConnected => 'Az Élő TV szerver nincs csatlakoztatva.';
	@override String get noPrograms => 'Nincsenek elérhető műsoradatok';
	@override String get liveStreamFailed => 'Nem sikerült elindítani az élő adást';
	@override String get unknownProgram => 'Ismeretlen műsor';
	@override String get timelineLiveProgram => 'Live program (a játék visszafordítása lehet ezen a programon kívül)';
	@override String get timelineBuffer => 'Buffer időzítés';
	@override String get timelineUnavailable => 'Időjárás nem elérhető';
	@override String get timelineEstimated => 'Értékelhető playback';
	@override String get timelinePending => 'Keresés közben';
	@override String get timelineStale => 'A határidő elavult lehet';
	@override String get unknownHub => 'Ismeretlen';
	@override String get unknownError => 'Ismeretlen hiba';
	@override String channelNumber({required Object number}) => '${number}. csatorna';
	@override String get unknownChannel => 'Ismeretlen csatorna';
	@override String get live => 'ÉLŐ';
	@override String get premiereBadge => 'Új';
	@override String get reloadGuide => 'Műsorújság újratöltése';
	@override String get searchGuide => 'Keresés a műsorújságban';
	@override String get searchHint => 'Csatornák és műsorok keresése';
	@override String searchNoResults({required Object query}) => 'Nincs találat a következőre: "${query}"';
	@override String get channelsSection => 'Csatornák';
	@override String get programsSection => 'Műsorok';
	@override String get now => 'Most';
	@override String get today => 'Ma';
	@override String get tomorrow => 'Holnap';
	@override String get midnight => 'Éjfél';
	@override String get overnight => 'Késő éjszaka';
	@override String get morning => 'Reggel';
	@override String get daytime => 'Napközben';
	@override String get evening => 'Este';
	@override String get lateNight => 'Éjszaka';
	@override String get whatsOn => 'Mi megy most?';
	@override String get watchChannel => 'Csatorna nézése';
	@override String get favorites => 'Kedvencek';
	@override String get reorderFavorites => 'Kedvencek rendezése';
	@override String get noFavoriteChannels => 'Nincsenek kedvenc csatornák';
	@override String get noFavoriteChannelsHint => 'Jelenítsd meg az összes csatornát, majd hosszan nyomj meg egy csatornát, hogy hozzáadd a kedvenceidhez.';
	@override String get showAllChannels => 'Összes csatorna megjelenítése';
	@override String get favoritesLoadFailed => 'Nem sikerült a kedvencek betöltése. Ellenőrizd a kapcsolatot és próbáld újra.';
	@override String get favoritesUpdateFailed => 'Nem sikerült frissíteni a kedvenceket. Ellenőrizd a kapcsolatot, majd próbáld újra.';
	@override String get joinSession => 'Csatlakozás a folyamatban lévő adáshoz';
	@override String watchFromStart({required Object minutes}) => 'Nézés az elejétől (${minutes} perce megy)';
	@override String get watchLive => 'Élő adás nézése';
	@override String get goToLive => 'Ugrás az élő adásra';
	@override String get record => 'Felvétel';
	@override String get recordEpisode => 'Epizód rögzítése';
	@override String get recordSeries => 'Sorozat rögzítése';
	@override String get recordOptions => 'Felvételi beállítások';
	@override String get saveTo => 'Mentés ide';
	@override String get recordings => 'Felvételek';
	@override String get scheduledRecordings => 'Ütemezve';
	@override String get recordingRules => 'Felvételi szabályok';
	@override String get noScheduledRecordings => 'Nincs semmi felvételre ütemezve';
	@override String get manageRecording => 'Felvétel kezelése';
	@override String get cancelRecording => 'Felvétel megszakítása';
	@override String get cancelRecordingTitle => 'Megszakítod ezt a felvételt?';
	@override String cancelRecordingMessage({required Object title}) => 'A(z) ${title} nem kerül rögzítésre.';
	@override String get deleteRule => 'Szabály törlése';
	@override String get deleteRuleTitle => 'Törlöd a felvételi szabályt?';
	@override String deleteRuleMessage({required Object title}) => 'A(z) ${title} jövőbeli epizódjai nem kerülnek rögzítésre.';
	@override String get recordingScheduled => 'Felvétel ütemezve';
	@override String get alreadyScheduled => 'Ez a műsor már ütemezve van';
	@override String get dvrAdminRequired => 'A DVR beállításokhoz adminisztrátori fiók szükséges';
	@override String get recordingFailed => 'Nem sikerült a felvétel ütemezése';
	@override String get recordingTargetMissing => 'Nem sikerült meghatározni a felvételi könyvtárat';
	@override String get recordNotAvailable => 'A felvétel nem érhető el ehhez a műsorhoz';
	@override String get recordingCancelled => 'Felvétel megszakítva';
	@override String get recordingRuleDeleted => 'Felvételi szabály törölve';
	@override String get processRecordingRules => 'Szabályok újraértékelése';
	@override String get recordingInProgress => 'Rögzítés folyamatban';
	@override String recordingsCount({required Object count}) => '${count} ütemezve';
	@override String get editRule => 'Szabály szerkesztése';
	@override String get editRuleAction => 'Szerkesztés';
	@override String get recordingRuleUpdated => 'Felvételi szabály frissítve';
	@override String get guideReloadRequested => 'Műsorújság frissítése kérve';
	@override String get guideReloadFailed => 'Nem sikerült frissíteni a műsorújságot';
	@override String get rulesProcessRequested => 'Szabályok újraértékelése kérve';
	@override String get rulesProcessFailed => 'Nem sikerült újra kiértékelni a felvételi szabályokat';
	@override String get recordShow => 'Műsor rögzítése';
	@override late final _Translations$liveTv$recordSettings$hu recordSettings = _Translations$liveTv$recordSettings$hu._(_root);
	@override String startingInMinutes({required Object minutes}) => '${minutes} perc múlva kezdődik';
	@override String dayAtTime({required Object day, required Object time}) => '${day}, ${time}';
	@override String invalidPlaybackData({required Object product}) => 'A(z) ${product} érvénytelen Élő TV-lejátszási adatokat adott vissza';
	@override String get failedToStartChannel => 'Nem sikerült elindítani az élő csatornát';
	@override String get failedToBuildStreamUrl => 'Nem sikerült összeállítani a stream URL-címét';
	@override String playbackStartFailed({required Object reason}) => 'Nem sikerült elindítani a csatornát: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Nem sikerült csatornát váltani: ${reason}';
}

// Path: collections
class _Translations$collections$hu extends Translations$collections$en {
	_Translations$collections$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gyűjtemények';
	@override String get collection => 'Gyűjtemény';
	@override String get empty => 'A gyűjtemény üres';
	@override String get deleteCollection => 'Gyűjtemény törlése';
	@override String deleteConfirm({required Object title}) => 'Törlöd a következőt: "${title}"? Ez nem vonható vissza.';
	@override String get deleted => 'Gyűjtemény törölve';
	@override String get deleteFailed => 'Nem sikerült a gyűjtemény törlése';
	@override String deleteFailedWithError({required Object error}) => 'Nem sikerült a gyűjtemény törlése: ${error}';
	@override String get selectCollection => 'Gyűjtemény kiválasztása';
	@override String get collectionName => 'Gyűjtemény neve';
	@override String get enterCollectionName => 'Add meg a gyűjtemény nevét';
	@override String get addedToCollection => 'Hozzáadva a gyűjteményhez';
	@override String get errorAddingToCollection => 'Nem sikerült a gyűjteményhez adni';
	@override String get created => 'Gyűjtemény létrehozva';
	@override String get removeFromCollection => 'Eltávolítás a gyűjteményből';
	@override String removeFromCollectionConfirm({required Object title}) => 'Eltávolítod a következőt: "${title}" ebből a gyűjteményből?';
	@override String get removedFromCollection => 'Eltávolítva a gyűjteményből';
	@override String get removeFromCollectionFailed => 'Nem sikerült az eltávolítás a gyűjteményből';
	@override String removeFromCollectionError({required Object error}) => 'Hiba a gyűjteményből való eltávolításkor: ${error}';
	@override String get searchCollections => 'Gyűjtemények keresése...';
}

// Path: playlists
class _Translations$playlists$hu extends Translations$playlists$en {
	_Translations$playlists$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lejátszási listák';
	@override String get playlist => 'Lejátszási lista';
	@override String get noPlaylists => 'Nem találhatók lejátszási listák';
	@override String get create => 'Lejátszási lista létrehozása';
	@override String get playlistName => 'Lejátszási lista neve';
	@override String get enterPlaylistName => 'Add meg a lejátszási lista nevét';
	@override String get delete => 'Lejátszási lista törlése';
	@override String get removeItem => 'Eltávolítás a lejátszási listáról';
	@override String get smartPlaylist => 'Okos lejátszási lista';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elem',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elem',
	);
	@override String get emptyPlaylist => 'Ez a lejátszási lista üres';
	@override String get deleteConfirm => 'Törlöd a lejátszási listát?';
	@override String deleteMessage({required Object name}) => 'Biztosan törölni szeretnéd a következőt: "${name}"?';
	@override String get created => 'Lejátszási lista létrehozva';
	@override String get deleted => 'Lejátszási lista törölve';
	@override String get itemAdded => 'Hozzáadva a lejátszási listához';
	@override String get itemRemoved => 'Eltávolítva a lejátszási listáról';
	@override String get selectPlaylist => 'Lejátszási lista kiválasztása';
	@override String get searchPlaylists => 'Lejátszási listák keresése...';
	@override String get errorCreating => 'Nem sikerült a lejátszási lista létrehozása';
	@override String get errorDeleting => 'Nem sikerült a lejátszási lista törlése';
	@override String get errorLoading => 'Nem sikerült a lejátszási listák betöltése';
	@override String get errorAdding => 'Nem sikerült a lejátszási listához adni';
	@override String get errorReordering => 'Nem sikerült átrendezni a lejátszási lista elemét';
	@override String get errorRemoving => 'Nem sikerült az eltávolítás a lejátszási listáról';
}

// Path: music
class _Translations$music$hu extends Translations$music$en {
	_Translations$music$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ugrás az albumhoz';
	@override String get goToArtist => 'Ugrás az előadóhoz';
	@override String get instantMix => 'Azonnali keverés';
	@override String get playNext => 'Következő lejátszása';
	@override String get addToQueue => 'Hozzáadás a lejátszási sorhoz';
	@override String discNumber({required Object n}) => '${n}. lemez';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} zeneszám',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} zeneszám',
	);
	@override String get nowPlaying => 'Most szól';
	@override String playingFrom({required Object title}) => 'Lejátszás innen: ${title}';
	@override String get queue => 'Lejátszási sor';
	@override String get clearQueue => 'Sor törlése';
	@override String get lyrics => 'Dalszöveg';
	@override String get visualizer => 'vizualizálása';
	@override String get visualizerProfileLoading => 'A track analízis...';
	@override String get visualizerAmbientMotion => 'Környezetmoció';
	@override String get visualizerPlexLoudness => 'Plex hangzás';
	@override String get visualizerLiveAudio => 'Élő hangelemzés';
	@override String get visualizerPreviousPreset => 'Előző vizuális stílus';
	@override String get visualizerNextPreset => 'Következő vizuális stílus';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Bloom';
	@override String get visualizerPresetOrbitals => 'Orbitalok';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Tunnel';
	@override String get visualizerPresetTrackMap => 'Térkép';
	@override String get noLyrics => 'Nincs elérhető dalszöveg';
	@override String get sleepTimer => 'Elalvási időzítő';
	@override String get sleepTimerEndOfTrack => 'Zeneszám vége';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} perc',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} perc',
	);
	@override String get stopPlayback => 'Lejátszás leállítása';
	@override String get previousTrack => 'Előző szám';
	@override String get nextTrack => 'Következő szám';
	@override String get repeat => 'Ismétlés';
	@override String get repeatAll => 'Összes ismétlése';
	@override String get repeatOne => 'Egy szám ismétlése';
	@override String get instantMixNoServer => 'Nem érhető el szerver az azonnali mixhez';
	@override String get instantMixFailed => 'Nem sikerült betölteni az azonnali mixet';
	@override String get instantMixEmpty => 'Az azonnali mix nem adott vissza zeneszámokat';
	@override String noAudioUrl({required Object track}) => 'Nem érhető el hang-URL ehhez: ${track}';
	@override late final _Translations$music$discography$hu discography = _Translations$music$discography$hu._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$hu extends Translations$watchTogether$en {
	_Translations$watchTogether$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Together (Közös nézés)';
	@override String get description => 'Nézz tartalmat szinkronban barátaiddal és családoddal';
	@override String get createRoom => 'Szoba létrehozása';
	@override String get creatingRoom => 'Szoba létrehozása...';
	@override String get joinRoom => 'Csatlakozás szobához';
	@override String get joiningRoom => 'Csatlakozás a szobához...';
	@override String get connecting => 'Csatlakozás...';
	@override String get relayPublic => 'A szobák a nyilvános Open Watch Party-reléket használják.';
	@override String relayCustom({required Object url}) => 'A szobák a saját relédet használják: ${url}.';
	@override String get recentRooms => 'Legutóbbi szobák';
	@override String get roomActions => 'Szobaműveletek';
	@override String get renameRoom => 'Szoba átnevezése';
	@override String get removeRoom => 'Eltávolítás';
	@override String get enterRoomCode => 'Add meg a házigazdától kapott 6 karakteres kódot.';
	@override String get roomCode => 'Szobakód';
	@override String get paste => 'Beillesztés';
	@override String get noCodeInClipboard => 'A vágólapon nincs szobakód';
	@override String get copyCode => 'Kód másolása';
	@override String get codeCopied => 'Szobakód másolva';
	@override String get shareInvite => 'Meghívó megosztása';
	@override String get inviteCopied => 'Meghívó másolva. Illeszd be egy üzenetbe.';
	@override String inviteMessage({required Object code}) => 'Csatlakozz a Watch Together-szobámhoz a Plezyben: nyisd meg a Watch Together (Közös nézés) menüt, válaszd a Csatlakozás szobához lehetőséget, és írd be ezt a kódot: ${code}.';
	@override String get openSessionControls => 'Watch Together munkamenet-vezérlők megnyitása';
	@override String get reconnecting => 'Újracsatlakozás...';
	@override String get reconnectingDescription => 'Megszakadt a kapcsolat. Automatikusan visszacsatlakozol a szobához.';
	@override String get connected => 'Csatlakozva';
	@override String get disconnected => 'Kapcsolat bontva';
	@override String get youAreHost => 'Te vagy a házigazda';
	@override String hostedBy({required Object name}) => 'Házigazda: ${name}';
	@override String get hostControlsPlayback => 'A házigazda vezérli a lejátszást';
	@override String get anyoneCanControl => 'Bárki vezérelheti a lejátszást';
	@override String get roomLocked => 'Szoba zárolva';
	@override String get nowPlaying => 'Most megy';
	@override String get nothingPlaying => 'Nincs lejátszás';
	@override String get nothingPlayingHost => 'Játssz le valamit bármelyik könyvtárból, hogy megoszd a szobával.';
	@override String get nothingPlayingGuest => 'Amikor a házigazda lejátszik valamit, itt fog megnyílni.';
	@override String get notShareable => 'Ehhez a videóhoz nincs katalógusbeli egyezés, ezért csak azok tudják lejátszani, akik hozzáférnek ugyanahhoz a szerverhez.';
	@override String get searching => 'A videó keresése a könyvtáraidban...';
	@override String get yourCopy => 'A saját példányod';
	@override String get sharingYourCopy => 'A saját példányodat osztod meg';
	@override String playingOtherLength({required Object difference}) => 'Saját példányod lejátszása (${difference})';
	@override String get mismatchTitle => 'A példányod hossza eltér';
	@override String mismatchDescription({required Object difference}) => 'A legközelebbi példányod ${difference}, mint a szoba videója. Lehet, hogy más vágás vagy változat.';
	@override String get playAnyway => 'Lejátszás mégis';
	@override String get chooseAnotherCopy => 'Másik példány választása';
	@override String get dontPlay => 'Ne játszd le';
	@override String get unavailableTitle => 'Ez a videó nincs meg neked';
	@override String get unavailableDescription => 'A PlezyNG nem találta meg a könyvtáraidban. Válassz ki magad egy példányt, vagy keress újra.';
	@override String get chooseCopy => 'Példány választása';
	@override String get searchAgain => 'Keresés újra';
	@override String get noCandidates => 'Nem található példány a könyvtáraidban.';
	@override String get choiceFailed => 'Nem sikerült lejátszani ezt a példányt a szobának';
	@override String lengthLonger({required Object duration}) => '${duration} különbséggel hosszabb';
	@override String lengthShorter({required Object duration}) => '${duration} különbséggel rövidebb';
	@override String get lengthSame => 'Azonos hosszúságú';
	@override String get lengthUnknown => 'Ismeretlen hosszúságú';
	@override String get joinCurrentPlayback => 'Csatlakozás a jelenlegi lejátszáshoz';
	@override String get joinCurrentPlaybackDescription => 'Visszatérés ahhoz, amit a házigazda éppen néz';
	@override String get stopMedia => 'Videó leállítása mindenkinél';
	@override String get syncOffset => 'Szinkroneltolás';
	@override String get syncOffsetDescription => 'Told el a videódat, ha a szobához képest előrébb jár vagy lemarad.';
	@override String offsetHint({required Object difference}) => 'A példányod ${difference}, mint a szoba videója.';
	@override String applyDifference({required Object offset}) => '${offset} alkalmazása';
	@override String get offsetMinusSecond => '-1 mp';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 mp';
	@override String get participants => 'Résztvevők';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résztvevő',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résztvevő',
	);
	@override String get hostBadge => 'HÁZIGAZDA';
	@override String nameYou({required Object name}) => '${name} (te)';
	@override String get playerIdle => 'Tétlen';
	@override String get playerLoading => 'Betöltés';
	@override String get playerReady => 'Kész';
	@override String get playerBuffering => 'Pufferelés';
	@override String get matchSearching => 'Keresés';
	@override String get matchMatched => 'Megvan a videó';
	@override String get matchMismatched => 'Eltérő hosszúságú';
	@override String get matchUnavailable => 'Nincs meg a videó';
	@override String participantOffset({required Object offset}) => 'Eltolás: ${offset}';
	@override String get makeHost => 'Házigazdává tétel';
	@override String get makeHostQuestion => 'Átadod a házigazdaságot?';
	@override String makeHostConfirm({required Object name}) => '${name} vezérli majd a lejátszást és a munkamenetet mindenki számára.';
	@override String get transfer => 'Átadás';
	@override String get removeParticipant => 'Eltávolítás a szobából';
	@override String removeParticipantQuestion({required Object name}) => '${name} eltávolítása?';
	@override String removeParticipantConfirm({required Object name}) => '${name} kikerül a szobából. A kóddal újra csatlakozhat, hacsak nem zárolod a szobát.';
	@override String get remove => 'Eltávolítás';
	@override String get roomSettings => 'Szobabeállítások';
	@override String get letEveryoneControl => 'Mindenki vezérelheti a lejátszást';
	@override String get lockRoom => 'Szoba zárolása';
	@override String get lockRoomDescription => 'Új résztvevők nem csatlakozhatnak';
	@override String get leaveRoom => 'Kilépés a szobából';
	@override String get leaveRoomQuestion => 'Kilépsz a szobából?';
	@override String get leaveRoomConfirm => 'A szobakóddal újra csatlakozhatsz.';
	@override String get leave => 'Kilépés';
	@override String get endRoom => 'Szoba bezárása';
	@override String get endRoomQuestion => 'Bezárod a szobát?';
	@override String get endRoomConfirm => 'Ezzel mindenki számára bezárod a szobát.';
	@override String get end => 'Befejezés';
	@override String get playBlockedTitle => 'A lejátszás nem indult el';
	@override String get playBlockedDescription => 'Nyomd meg a lejátszás gombot, hogy együtt nézhesd a szobával.';
	@override late final _Translations$watchTogether$notices$hu notices = _Translations$watchTogether$notices$hu._(_root);
	@override late final _Translations$watchTogether$ended$hu ended = _Translations$watchTogether$ended$hu._(_root);
	@override late final _Translations$watchTogether$errors$hu errors = _Translations$watchTogether$errors$hu._(_root);
	@override String untitledEpisode({required Object number}) => '${number}. epizód';
}

// Path: downloads
class _Translations$downloads$hu extends Translations$downloads$en {
	_Translations$downloads$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Letöltések';
	@override String get manage => 'Kezelés';
	@override String get tvShows => 'TV-sorozatok';
	@override String get movies => 'Filmek';
	@override String get music => 'Zene';
	@override String tracksQueued({required Object count}) => '${count} zeneszám letöltésre sorba állítva';
	@override String get noDownloads => 'Még nincsenek letöltések';
	@override String get noDownloadsDescription => 'A letöltött tartalmak itt jelennek meg az offline megtekintéshez';
	@override String get downloadNow => 'Letöltés';
	@override String get deleteDownload => 'Letöltés törlése';
	@override String get retryDownload => 'Letöltés újrapróbálása';
	@override String get downloadQueued => 'Letöltés sorba állítva';
	@override String get downloadResumed => 'Letöltés folytatva';
	@override String get serverErrorBitrate => 'Szerverhiba: a fájl meghaladhatja a távoli bitrátakorlátot';
	@override String get storageFull => 'A letöltések leálltak a szabad tárhely védelme érdekében. Szabadíts fel helyet, vagy válassz másik letöltési helyet, majd próbáld újra.';
	@override String get storageUnavailable => 'A letöltések leálltak, mert a rendelkezésre álló tárhely nem ellenőrizhető. Ellenőrizd a letöltési helyet, majd próbáld újra.';
	@override String episodesQueued({required Object count}) => '${count} epizód letöltésre sorba állítva';
	@override String get downloadDeleted => 'Letöltés törölve';
	@override String deleteConfirm({required Object title}) => 'Törlöd a következőt: "${title}" erről az eszközről?';
	@override String get deleteCollectionDownloads => 'Letöltések törlése';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Törlöd a(z) "${title}" összes letöltését erről az eszközről?';
	@override String get collectionDownloadsDeleted => 'Letöltések törölve';
	@override String get cancelledDownloadTitle => 'Megszakított letöltés';
	@override String get cancelledDownloadMessage => 'Ez a letöltés meg lett szakítva. Mit szeretnél tenni?';
	@override String get allEpisodesAlreadyDownloaded => 'Minden epizód le van töltve';
	@override String get resumeDownload => 'Letöltés folytatása';
	@override String get cancelledDownload => 'Megszakított letöltés';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} szinkronizálása)';
	@override String downloadedFileClickToComplete({required Object file}) => 'Letöltve: ${file} - Kattints a befejezéshez';
	@override String get partialDownloadClickToComplete => 'Részben letöltve - Kattints a befejezéshez';
	@override String get deleting => 'Törlés...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} törlése... (${current}/${total})';
	@override String get queuedTooltip => 'Sorban áll';
	@override String queuedFilesTooltip({required Object files}) => 'Sorba állítva: ${files}';
	@override String get downloadingTooltip => 'Letöltés...';
	@override String downloadingFilesTooltip({required Object files}) => 'Letöltés alatt: ${files}';
	@override String get noDownloadsTree => 'Nincsenek letöltések';
	@override String get pauseAll => 'Összes szüneteltetése';
	@override String get resumeAll => 'Összes folytatása';
	@override String get retryAll => 'Összes újrapróbálása';
	@override String get retryFailed => 'Sikertelen letöltések újrapróbálása';
	@override String get deleteAll => 'Összes törlése';
	@override String get selectVersion => 'Verzió kiválasztása';
	@override String get allEpisodes => 'Minden epizód';
	@override String get unwatchedOnly => 'Csak a nem látottak';
	@override String nextNUnwatched({required Object count}) => 'A következő ${count} nem látott epizód';
	@override String get customAmount => 'Egyéni mennyiség...';
	@override String get customAmountAny => 'A megadott összeg (minden)';
	@override String get randomEpisodes => 'Rádió epizódok';
	@override String get includeSpecials => 'Különkiadások is';
	@override String get howManyEpisodes => 'Hány epizód?';
	@override String get invalidEpisodeCount => 'Adj meg egy érvényes epizódszámot.';
	@override String get keepSynced => 'Szinkronban tartás';
	@override String get downloadOnce => 'Egyszeri letöltés';
	@override String keepNUnwatched({required Object count}) => '${count} nem látott epizód megtartása';
	@override String get editSyncRule => 'Szinkronizálási szabály szerkesztése';
	@override String get removeSyncRule => 'Szinkronizálási szabály eltávolítása';
	@override String removeSyncRuleConfirm({required Object title}) => 'Leállítod a(z) "${title}" szinkronizálását? A letöltött epizódok megmaradnak.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Leállítjuk a(z) "${title}" szinkronizálását?';
	@override String get deleteSyncRuleDownloads => 'A kapcsolódó letöltések törlése is';
	@override String get deleteSyncRuleDownloadsDescription => 'A másik szinkronszabály vagy profil által használt letöltések megmaradnak.';
	@override String syncRuleCreated({required Object count}) => 'Szinkronizálási szabály létrehozva — ${count} nem látott epizód megtartása';
	@override String get syncRuleUpdated => 'Szinkronizálási szabály frissítve';
	@override String get syncRuleRemoved => 'Szinkronizálási szabály eltávolítva';
	@override String get syncRuleAndDownloadsRemoved => 'A szinkronszabály és a kapcsolódó letöltések eltávolítva';
	@override String get syncRuleCleanupBusy => 'A szinkronszabályok éppen frissülnek. Próbálja újra egy pillanat múlva.';
	@override String get syncRuleCleanupUnavailable => 'A kapcsolódó letöltések nem azonosíthatók biztonságosan. Csatlakoztassa újra a szervert, és próbálja újra, vagy távolítsa el a szabályt a letöltések törlése nélkül.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} új epizód szinkronizálva a következőhöz: ${title}';
	@override String get syncNow => 'Szinkronizálás most';
	@override String get downloadsUpToDate => 'A letöltések naprakészek';
	@override String syncComplete({required Object queued, required Object removed}) => 'Szinkronizálás teljes · ${queued} queued, ${removed} eltávolított';
	@override String get activeSyncRules => 'Szinkronizálási szabályok';
	@override String get reviewOrphanFiles => 'Árva letöltések áttekintése';
	@override String get orphanReviewTitle => 'Árva letöltések áttekintése';
	@override String get orphanReviewDescription => 'Ezek a címkézett fájlok a PlezyNG által kezelt alapértelmezett letöltési mappákban találhatók, és nincs hozzájuk tartozó letöltési rekord vagy aktív feladat. Törlés előtt ellenőrizze a listát.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} fájl · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} fájl törlése';
	@override String get orphanCleanupNone => 'Nem található árva letöltési fájl';
	@override String get orphanCleanupFailed => 'A PlezyNG nem tudta biztonságosan átvizsgálni a kezelt letöltési mappát. Nem töröltünk fájlokat.';
	@override String get orphanCleanupChanged => 'A letöltési lista az áttekintés közben megváltozott. Tisztítás előtt tekintse át újra a fájlokat.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} árva letöltési fájl törölve · ${size} tárhely felszabadítva';
	@override String get noSyncRules => 'Nincsenek szinkronizálási szabályok';
	@override String get manageSyncRule => 'Szinkronizálás kezelése';
	@override String get editEpisodeCount => 'Epizódszám';
	@override String get editSyncFilter => 'Szinkronizálási szűrő';
	@override String get syncAllItems => 'Minden elem szinkronizálása';
	@override String get syncUnwatchedItems => 'Nem látott elemek szinkronizálása';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Szerver: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Elérhető';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Bejelentkezés szükséges';
	@override String get syncRuleAccessDenied => 'Hozzáférés megtagadva';
	@override String get syncRuleNotAvailableForProfile => 'Nem érhető el a jelenlegi profilhoz';
	@override String get syncRuleUnknownServer => 'Ismeretlen szerver';
	@override String get syncRuleListCreated => 'Szinkronizálási szabály létrehozva';
	@override late final _Translations$downloads$backgroundWarning$hu backgroundWarning = _Translations$downloads$backgroundWarning$hu._(_root);
	@override String get options => 'Letöltések lehetőségei';
	@override late final _Translations$downloads$groupings$hu groupings = _Translations$downloads$groupings$hu._(_root);
	@override String get unknownLibrary => 'Ismeretlen könyvtár';
	@override String get unknownShow => 'Ismeretlen sorozat';
	@override String get unknownSeason => 'Ismeretlen évad';
	@override String get unknownAlbum => 'Ismeretlen album';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} kész';
	@override String storageUsed({required Object size}) => 'Használt tároló: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} letöltés',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} letöltés',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bemutató',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintés',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmek',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmek',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
	);
	@override String get errorFileNotFound => 'A fájl nem található (404)';
	@override String get errorDownloadNotAllowed => 'A szerver nem engedélyezi a letöltést (403)';
	@override String get errorDownloadFailed => 'A letöltés nem sikerült';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'A letöltés nem sikerült: ${reason}';
	@override String get convertingOnServer => 'A szerverre való átalakítás...';
	@override String convertingOnServerPercent({required Object percent}) => 'Szerverre való átalakítás · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'A letöltés nem sikerült (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Az utófeldolgozás nem sikerült: ${reason}';
	@override String get reasonFileNotSaved => 'a fájlt nem sikerült menteni erre az eszközre';
	@override String get reasonCannotResume => 'a részleges letöltést nem sikerült folytatni';
	@override String get reasonDeviceStorageFull => 'az eszközön elfogyott a tárhely';
	@override String get notificationDownloading => 'Letöltés...';
	@override String get notificationComplete => 'Letöltés kész';
	@override String get notificationPaused => 'Letöltés szüneteltetve';
}

// Path: shaders
class _Translations$shaders$hu extends Translations$shaders$en {
	_Translations$shaders$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaderek';
	@override String get noShaderDescription => 'Nincs videójavítás';
	@override String get nvscalerDescription => 'NVIDIA képskálázás az élesebb videóért';
	@override String get artcnnVariantNeutral => 'Semleges';
	@override String get artcnnVariantDenoise => 'Zajcsökkentés';
	@override String get artcnnVariantDenoiseSharpen => 'Zajcsökkentés + Élesítés';
	@override String get qualityFast => 'Gyors';
	@override String get qualityHQ => 'Kiváló minőség';
	@override String get mode => 'Mód';
	@override String get importShader => 'Shader importálása';
	@override String get customShaderDescription => 'Egyéni GLSL shader';
	@override String get shaderImported => 'Shader importálva';
	@override String get shaderImportFailed => 'Nem sikerült a shader importálása';
	@override String get deleteShader => 'Shader törlése';
	@override String deleteShaderConfirm({required Object name}) => 'Törlöd a következőt: "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$hu extends Translations$companionRemote$en {
	_Translations$companionRemote$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kísérőtávirányító';
	@override String connectedTo({required Object name}) => 'Csatlakoztatva a következőhöz: ${name}';
	@override String get unknownDevice => 'Ismeretlen eszköz';
	@override late final _Translations$companionRemote$session$hu session = _Translations$companionRemote$session$hu._(_root);
	@override late final _Translations$companionRemote$pairing$hu pairing = _Translations$companionRemote$pairing$hu._(_root);
	@override late final _Translations$companionRemote$remote$hu remote = _Translations$companionRemote$remote$hu._(_root);
	@override late final _Translations$companionRemote$errors$hu errors = _Translations$companionRemote$errors$hu._(_root);
	@override String get closedBeforeAuth => 'A kapcsolat a hitelesítés előtt megszakadt';
}

// Path: videoSettings
class _Translations$videoSettings$hu extends Translations$videoSettings$en {
	_Translations$videoSettings$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Lejátszási sebesség';
	@override String get normalSpeed => 'Normál';
	@override String sleepTimerActive({required Object duration}) => 'Aktív (${duration})';
	@override String get zoom => 'Nagyítás';
	@override String get sleepTimer => 'Elalvási időzítő';
	@override String get audioSync => 'Hang szinkronizálása';
	@override String get subtitleSync => 'Felirat szinkronizálása';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'A HDR itt nem érhető el – ez az asztali kompozitor vagy videókimenet nem képes továbbítani.';
	@override String get hdrToneMapping => 'HDR-tónusleképezés';
	@override String get hdrToneMappingCompositor => 'Kompozitor';
	@override String get hdrToneMappingCompositorDescription => 'Továbbítja a forrás HDR-metaadatait, és az asztali kompozitorra bízza a tónusleképezést.';
	@override String get hdrToneMappingPlayer => 'Lejátszó';
	@override String get hdrToneMappingPlayerDescription => 'A lejátszóban a kijelző maximális fényerejéhez igazítja a képet, majd közli az eredményt a kompozitorral.';
	@override String get hdrToneMappingFailed => 'Nem sikerült módosítani a HDR-tónusleképezést – továbbra is az előző mód aktív.';
	@override String get audioOutput => 'Hangkimenet';
	@override String get videoTrack => 'Videósáv';
	@override String get videoTrackDescription => 'Válaszd ki a megjelenítendő videofolyamot. MPV-lejátszáskor érhető el, ha a fájl több videósávot tartalmaz.';
	@override String get videoTrackDefault => 'Alapértelmezett';
	@override String get videoTrackUnavailable => 'Nincsenek elérhető alternatív videósávok.';
	@override String get videoTrackFailed => 'Nem sikerült megváltoztatni a videósávot.';
	@override String videoTrackNumber({required Object id}) => '${id}. sáv';
	@override String get performanceOverlay => 'Teljesítményadatok';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Térhatású';
	@override String get audioOutputSpatial => 'Térbeli hang';
	@override String get audioOutputStereo => 'Sztereó';
	@override String get audioEqualizer => 'Audio egyenlet';
	@override String get audioEqualizerDescription => '10 Band Equalizer MPV. A hangszűrők dekódolt audio használatát használják, és kapcsolja ki a passthrough-t.';
	@override String get audioEqualizerFlat => 'Sík';
	@override String get audioEqualizerActive => 'Egyéni';
	@override String get audioEqualizerSaveFailed => 'Nem menthetek meg a hang egyenletítő beállításokat.';
	@override String get audioEffectsDescription => 'A hatások dekódolt hangot használnak, így a passthrough elfordul. szoba környezete és sztereó kiterjesztése függ a MPV Építsen és nyomon kövesse.';
	@override String get audioStereoWidth => 'Stereó bővítés';
	@override String get audioSpatializer => 'Szoba környezete';
	@override String get audioSpatializerDescription => 'Adjunk nyugodt helyiség reflexiókat.';
	@override String get audioPitch => 'Pécsi változás';
	@override String get audioPitchDescription => 'Változtassa meg a pályát, nem változtatja meg a sebességet MPV Az építkezésnek tartalmaznia kell Rubber BandA';
	@override String get audioEffectUnavailable => 'Ez a hatás nem áll rendelkezésre ezen a pályán, vagy MPV Az építkezés.';
	@override String get backgroundVideoAudio => 'Videó audio háttér';
	@override String get backgroundVideoAudioDescription => 'A videó hangjátékot a lejátszó elhagyása után tartsa; a kép elrejtve van, amíg visszatér. Android médiaszámlálási értesítést használ.';
	@override String get audioNormalization => 'Hangerő normalizálása';
	@override String get audioNormalizationDisablesPassthrough => 'PCM-mé dekódolja a hangot; a passthrough ki van kapcsolva, amíg ez be van kapcsolva';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$hu extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get color => 'Szín';
	@override String get performance => 'Teljesítmény';
	@override String get buffer => 'Puffer';
	@override String get app => 'Alkalmazás';
	@override String get decoder => 'Dekóder';
	@override String get rawDecoder => 'Nyers dekóder';
	@override String get tunneling => 'Alagutazás';
	@override String get passthrough => 'Passthrough';
	@override String get aspect => 'Méretarány';
	@override String get rotation => 'Forgatás';
	@override String get dvSource => 'DV-forrás';
	@override String get dvPath => 'DV-útvonal';
	@override String get dvRouteDecoder => 'Dolby Vision-dekóder';
	@override String get dvRouteDecoderP81 => 'Dolby Vision-dekóder (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Alapréteg';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10-alapréteg';
	@override String get dvRouteBaseLayerHlg => 'HLG-alapréteg';
	@override String get dvRouteBaseLayerSdr => 'SDR-alapréteg';
	@override String get dvRouteReshaped => 'RPU-átformálás (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Kísérleti P7 FEL grafika (nem minősített)';
	@override String get p7Conversion => 'P7-átalakítás';
	@override String get sampleRate => 'Mintavételezési frekvencia';
	@override String get pixelFormat => 'Képpontformátum';
	@override String get hwFormat => 'Hardverformátum';
	@override String get matrix => 'Mátrix';
	@override String get primaries => 'Elsődleges színek';
	@override String get transfer => 'Átvitel';
	@override String get renderFps => 'Renderelési FPS';
	@override String get displayFps => 'Kijelző-FPS';
	@override String get avSync => 'A/V-szinkron';
	@override String get dropped => 'Eldobva';
	@override String get dvRpus => 'DV RPU-k';
	@override String get dvRpuAverage => 'DV RPU-átlag';
	@override String get dvSampleAverage => 'DV-mintaátlag';
	@override String get maxLuma => 'Maximális luma';
	@override String get minLuma => 'Minimális luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Használt gyorsítótár';
	@override String get cacheLimit => 'Gyorsítótár korlátja';
	@override String get speed => 'Sebesség';
	@override String get player => 'Lejátszó';
	@override String get playMethod => 'Játék módszer';
	@override String get memory => 'Memória';
	@override String get uiFps => 'Felület-FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Szoftveres';
	@override String get decoderHardware => 'Hardveres';
	@override String get tunnelingActive => 'Aktív';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} sikertelen)';
}

// Path: externalPlayer
class _Translations$externalPlayer$hu extends Translations$externalPlayer$en {
	_Translations$externalPlayer$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Külső lejátszó';
	@override String get useExternalPlayer => 'Külső lejátszó használata';
	@override String get useExternalPlayerDescription => 'Videók megnyitása egy másik alkalmazásban';
	@override String get selectPlayer => 'Lejátszó kiválasztása';
	@override String get customPlayers => 'Egyéni lejátszók';
	@override String get systemDefault => 'Rendszer alapértelmezése';
	@override String get addCustomPlayer => 'Egyéni lejátszó hozzáadása';
	@override String get playerName => 'Lejátszó neve';
	@override String get playerNameHint => 'Saját lejátszó';
	@override String get playerCommand => 'Parancs';
	@override String get playerPackage => 'Csomagnév';
	@override String get playerUrlScheme => 'URL-séma';
	@override String get off => 'Ki';
	@override String get launchFailed => 'Nem sikerült megnyitni a külső lejátszót';
	@override String appNotInstalled({required Object name}) => 'A(z) ${name} nincs telepítve';
	@override String get playInExternalPlayer => 'Lejátszás külső lejátszóban';
	@override String get description => 'Válasszon egy másik alkalmazást, hogy nyissa meg a videókat. A rendelkezésre álló játékosok attól függnek, hogy a készülék és telepített alkalmazások.';
	@override String get systemDefaultDescription => 'Hagyja, hogy az operációs rendszer nyissa meg a videót az alapértelmezett alkalmazással.';
	@override String playerOptionDescription({required Object player}) => 'Nyissa meg a videókat a ${player} használatával.';
	@override String get playerNameDescription => 'A címke a játékosok listáján látható.';
	@override String get playerPackageDescription => 'Adja meg az Android csomag nevét a játékos alkalmazás, mint például com.example.player.';
	@override String get playerCommandDescription => 'Írja be a telepített játékos parancsot vagy végrehajtható utat erre a készülékre.';
	@override String get playerUrlSchemeDescription => 'Írja be az URL-t és az opcionális URL-típusot, amelyet a játékos indításához használnak.';
}

// Path: metadataEdit
class _Translations$metadataEdit$hu extends Translations$metadataEdit$en {
	_Translations$metadataEdit$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Szerkesztés...';
	@override String get screenTitle => 'Metaadatok szerkesztése';
	@override String get basicInfo => 'Alapinformációk';
	@override String get artwork => 'Borítók és képek';
	@override String get advancedSettings => 'Haladó beállítások';
	@override String get title => 'Cím';
	@override String get sortTitle => 'Rendezési cím';
	@override String get originalTitle => 'Eredeti cím';
	@override String get releaseDate => 'Bemutató dátuma';
	@override String get contentRating => 'Korhatár-besorolás';
	@override String get studio => 'Stúdió';
	@override String get tagline => 'Jelmondat';
	@override String get summary => 'Összefoglaló';
	@override String get poster => 'Poszter';
	@override String get background => 'Háttér';
	@override String get logo => 'Logó';
	@override String get squareArt => 'Négyzetes kép';
	@override String get selectPoster => 'Poszter kiválasztása';
	@override String get selectBackground => 'Háttér kiválasztása';
	@override String get selectLogo => 'Logó kiválasztása';
	@override String get selectSquareArt => 'Négyzetes kép kiválasztása';
	@override String get fromUrl => 'URL-ről';
	@override String get uploadFile => 'Fájl feltöltése';
	@override String get enterImageUrl => 'Add meg a kép URL-címét';
	@override String get imageUrl => 'Kép URL-címe';
	@override String get metadataUpdated => 'Metaadatok frissítve';
	@override String get metadataUpdateFailed => 'Nem sikerült a metaadatok frissítése';
	@override String get artworkUpdated => 'Képek frissítve';
	@override String get artworkUpdateFailed => 'Nem sikerült a képek frissítése';
	@override String get noArtworkAvailable => 'Nincsenek elérhető képek';
	@override String artworkOption({required Object index}) => '${index}. képváltozat';
	@override String selectedArtworkOption({required Object index}) => '${index}. képváltozat, kiválasztva';
	@override String get notSet => 'Nincs beállítva';
	@override String get libraryDefault => 'Könyvtári alapértelmezés';
	@override String get accountDefault => 'Fiók alapértelmezése';
	@override String get seriesDefault => 'Sorozat alapértelmezése';
	@override String get episodeSorting => 'Epizódok rendezése';
	@override String get oldestFirst => 'Legrégebbi elöl';
	@override String get newestFirst => 'Legújabb elöl';
	@override String get keep => 'Megtartás';
	@override String get allEpisodes => 'Minden epizód';
	@override String latestEpisodes({required Object count}) => 'Legutóbbi ${count} epizód';
	@override String get latestEpisode => 'Legutóbbi epizód';
	@override String episodesAddedPastDays({required Object count}) => 'Az elmúlt ${count} napban hozzáadott epizódok';
	@override String get deleteAfterPlaying => 'Epizódok törlése lejátszás után';
	@override String get never => 'Soha';
	@override String get afterADay => 'Egy nap után';
	@override String get afterAWeek => 'Egy hét után';
	@override String get afterAMonth => 'Egy hónap után';
	@override String get onNextRefresh => 'A következő frissítéskor';
	@override String get seasons => 'Évadok';
	@override String get show => 'Megjelenítés';
	@override String get hide => 'Elrejtés';
	@override String get episodeOrdering => 'Epizódok sorrendje';
	@override String get tmdbAiring => 'The Movie Database (sugárzási sorrend)';
	@override String get tvdbAiring => 'TheTVDB (sugárzási sorrend)';
	@override String get tvdbAbsolute => 'TheTVDB (abszolút sorrend)';
	@override String get metadataLanguage => 'Metaadatok nyelve';
	@override String get useOriginalTitle => 'Eredeti cím használata';
	@override String get preferredAudioLanguage => 'Elsődleges hangnyelv';
	@override String get preferredSubtitleLanguage => 'Elsődleges feliratnyelv';
	@override String get subtitleMode => 'Automatikus feliratválasztási mód';
	@override String get manuallySelected => 'Kézzel kiválasztva';
	@override String get shownWithForeignAudio => 'Idegen nyelvű hang esetén megjelenítve';
	@override String get alwaysEnabled => 'Mindig engedélyezve';
	@override String get tags => 'Címkék';
	@override String get addTag => 'Címke hozzáadása';
	@override String get genre => 'Műfaj';
	@override String get director => 'Rendező';
	@override String get writer => 'Író';
	@override String get producer => 'Producer';
	@override String get country => 'Ország';
	@override String get collection => 'Gyűjtemény';
	@override String get label => 'Kiadó';
	@override String get quickTag => 'Gyors címke...';
}

// Path: matchScreen
class _Translations$matchScreen$hu extends Translations$matchScreen$en {
	_Translations$matchScreen$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get match => 'Párosítás...';
	@override String get fixMatch => 'Párosítás javítása...';
	@override String get unmatch => 'Párosítás megszüntetése';
	@override String get unmatchConfirm => 'Törlöd ezt a párosítást? A Plex párosítatlanként kezeli az újrapárosításig.';
	@override String get unmatchSuccess => 'Párosítás megszüntetve';
	@override String get unmatchFailed => 'Nem sikerült a párosítás megszüntetése';
	@override String get matchApplied => 'Párosítás alkalmazva';
	@override String get matchFailed => 'Nem sikerült a párosítás alkalmazása';
	@override String get titleHint => 'Cím';
	@override String get yearHint => 'Év';
	@override String get search => 'Keresés';
	@override String get noMatchesFound => 'Nincsenek egyezések';
}

// Path: serverTasks
class _Translations$serverTasks$hu extends Translations$serverTasks$en {
	_Translations$serverTasks$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Szerverfeladatok';
	@override String get failedToLoad => 'Nem sikerült a feladatok betöltése';
	@override String get noTasks => 'Nincsenek futó feladatok';
}

// Path: trakt
class _Translations$trakt$hu extends Translations$trakt$en {
	_Translations$trakt$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Csatlakoztatva';
	@override String connectedAs({required Object username}) => '@${username} néven csatlakoztatva';
	@override String get disconnectConfirm => 'Leválasztod a Trakt-fiókot?';
	@override String get disconnectConfirmBody => 'A PlezyNG nem küld több eseményt a Traktnak. Bármikor újracsatlakozhatsz.';
	@override String get scrobble => 'Valós idejű scrobbling';
	@override String get scrobbleDescription => 'Lejátszási, szüneteltetési és leállítási események küldése a Traktnak lejátszás közben.';
	@override String get watchedSync => 'Megtekintési állapot szinkronizálása';
	@override String get watchedSyncDescription => 'Ha egy elemet megtekintettként jelölsz meg a Plezyben, a Trakt is megtekintettként jelöli.';
}

// Path: seerr
class _Translations$seerr$hu extends Translations$seerr$en {
	_Translations$seerr$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr csatlakoztatása';
	@override String get serverUrl => 'Szerver URL-címe';
	@override String get serverUrlHelper => 'A Seerr példányod címe';
	@override String get checkServer => 'Folytatás';
	@override String get signInWithJellyfin => 'Bejelentkezés Jellyfinnel';
	@override String get signInWithEmby => 'Bejelentkezés Emby-vel';
	@override String get signInWithLocal => 'Helyi fiók használata';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Ez a Seerr példány nem kínál olyan bejelentkezési módot, amit a PlezyNG támogat.';
	@override String get instance => 'Példány';
	@override String get disconnectConfirm => 'Leválasztod a Seerr-kapcsolatot?';
	@override String get disconnectConfirmBody => 'A PlezyNG elfelejti ezt a Seerr példányt. Bármikor újracsatlakozhatsz.';
	@override String get request => 'Igénylés';
	@override String get request4k => 'Igénylés 4K-ban';
	@override String get seasons => 'Évadok';
	@override String get allSeasons => 'Minden évad';
	@override String get advancedOptions => 'Haladó';
	@override String get destinationServer => 'Célszerver';
	@override String get qualityProfile => 'Minőségi profil';
	@override String get rootFolder => 'Gyökérmappa';
	@override String get languageProfile => 'Nyelvi profil';
	@override String get tags => 'Címkék';
	@override String get noTags => 'Nincsenek címkék';
	@override String defaultOption({required Object name}) => '${name} (alapértelmezett)';
	@override String get animeNote => 'Ez a sorozat anime.';
	@override String get requestSubmitted => 'Igénylés elküldve';
	@override String requestFailed({required Object error}) => 'Az igénylés nem sikerült: ${error}';
	@override String get requestsLoadFailed => 'Nem sikerült betölteni az igénylési opciókat';
	@override String get nothingToRequest => 'Minden elem már elérhető vagy igényelve van.';
	@override String get statusAvailable => 'Elérhető';
	@override String get statusPartiallyAvailable => 'Részben elérhető';
	@override String get statusRequested => 'Igényelve';
	@override String get statusProcessing => 'Feldolgozás alatt';
	@override String get statusBlocklisted => 'Tiltólistán';
	@override String couldNotReach({required Object url, required Object error}) => 'Nem sikerült elérni ezt: ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Nem található Seerr-példány ezen a címen: ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'A Seerr helyett egy hitelesítő fordított proxy (SSO vagy HTTP-hitelesítés) válaszolt. A PlezyNG nem tud rajta bejelentkezni: engedd, hogy a Seerr /api/v1 útvonala megkerülje a proxyt ennél az alkalmazásnál, vagy használj olyan címet, amely közvetlenül eléri a Seerr-t.';
	@override String get invalidUrl => 'Adj meg egy szervercímet, például: https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Ez a Seerr-példány nem támogatja a Quick Connectet. Seerr 3.4 vagy újabb verzió szükséges.';
	@override String get notInitialized => 'Ennek a Seerr-példánynak a kezdeti beállítása még nem fejeződött be';
	@override String get noPlexTokenForReauth => 'Nem áll rendelkezésre Plex-token az újbóli bejelentkezéshez';
	@override String get noStoredCredentials => 'Nem állnak rendelkezésre mentett hitelesítő adatok az újbóli bejelentkezéshez';
	@override String get signInRejected => 'A bejelentkezést elutasították';
	@override String get noSessionCookie => 'A Seerr nem adott ki munkamenet-sütit';
	@override String get freshCookieRejected => 'A Seerr elutasította az új munkamenet-sütit';
	@override String get noUserInformation => 'A Seerr nem adott vissza felhasználói adatokat';
	@override String get sessionRejectedAfterReauth => 'A munkamenetet az újbóli bejelentkezés után elutasították';
	@override String get permissionDenied => 'A Seerr elutasította ezt a műveletet: a fiókod már nem rendelkezik a szükséges jogosultsággal';
	@override String get permissionRevoked => 'Már nincs jogosultságod ennek az igényléséhez';
}

// Path: services
class _Translations$services$hu extends Translations$services$en {
	_Translations$services$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Szolgáltatások';
	@override String get hubSubtitle => 'Megtekintési haladás szinkronizálása és új tartalmak igénylése.';
	@override String get integrations => 'Integrációk';
	@override String get notConnected => 'Nincs csatlakoztatva';
	@override String connectedAs({required Object username}) => '@${username} néven csatlakoztatva';
	@override String get scrobble => 'Haladás automatikus követése';
	@override String get scrobbleDescription => 'Lista frissítése, amikor befejezel egy epizódot vagy filmet.';
	@override String disconnectConfirm({required Object service}) => 'Leválasztod a(z) ${service} szolgáltatást?';
	@override String disconnectConfirmBody({required Object service}) => 'A PlezyNG nem frissíti többé a(z) ${service} adatait. Bármikor újracsatlakozhatsz.';
	@override String connectFailed({required Object service}) => 'Nem sikerült csatlakozni a következőhöz: ${service}. Próbáld újra.';
	@override late final _Translations$services$names$hu names = _Translations$services$names$hu._(_root);
	@override late final _Translations$services$simklReconnect$hu simklReconnect = _Translations$services$simklReconnect$hu._(_root);
	@override late final _Translations$services$deviceCode$hu deviceCode = _Translations$services$deviceCode$hu._(_root);
	@override late final _Translations$services$oauthProxy$hu oauthProxy = _Translations$services$oauthProxy$hu._(_root);
	@override late final _Translations$services$pendingAuth$hu pendingAuth = _Translations$services$pendingAuth$hu._(_root);
	@override late final _Translations$services$libraryFilter$hu libraryFilter = _Translations$services$libraryFilter$hu._(_root);
	@override String get seerrDescription => 'Csatlakozzon a Seerr-hez vagy az Overseerr-hoz, hogy címeket keressen és médiakérdéseket küldjön.';
	@override late final _Translations$services$trackerDescriptions$hu trackerDescriptions = _Translations$services$trackerDescriptions$hu._(_root);
}

// Path: addServer
class _Translations$addServer$hu extends Translations$addServer$en {
	_Translations$addServer$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product} szerver hozzáadása';
	@override String get serverUrls => 'Szerver URL-címei';
	@override String get serverUrlsHelper => 'Több URL is megadható, vesszővel elválasztva.';
	@override String get findServer => 'Szerver keresése';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Helyi ${product} szerverek keresése...';
	@override String localMediaBrowserServers({required Object product}) => 'Helyi ${product} szerverek';
	@override String get username => 'Felhasználónév';
	@override String get password => 'Jelszó';
	@override String get signIn => 'Bejelentkezés';
	@override String get change => 'Módosítás';
	@override String get required => 'Kötelező';
	@override String couldNotReachServer({required Object error}) => 'Nem sikerült elérni a szervert: ${error}';
	@override String signInFailed({required Object error}) => 'A bejelentkezés nem sikerült: ${error}';
	@override String quickConnectFailed({required Object error}) => 'A Quick Connect használata nem sikerült: ${error}';
	@override String get addPlexTitle => 'Bejelentkezés Plexszel';
	@override String get pinExpired => 'A PIN-kód a bejelentkezés előtt lejárt. Próbáld újra.';
	@override String failedToRegisterAccount({required Object error}) => 'Nem sikerült a fiók regisztrálása: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Adja meg a(z) ${product} szerver URL-jét';
	@override String get addConnectionTitle => 'Kapcsolat hozzáadása';
	@override String addConnectionTitleScoped({required Object name}) => 'Hozzáadás a következőhöz: ${name}';
	@override String get signInWithPlexCard => 'Bejelentkezés Plexszel';
	@override String get signInWithPlexCardSubtitle => 'Eszköz engedélyezése. A megosztott szerverek hozzáadásra kerülnek.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex-fiók engedélyezése. A Plex Home-felhasználókból profilok lesznek.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Csatlakozás a(z) ${product} szolgáltatáshoz';
	@override String get connectToMediaBrowserCardSubtitle => 'Adja meg a szerver URL-jét, felhasználónevét és jelszavát.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Jelentkezzen be a(z) ${product} szerverére. A(z) ${name} szolgáltatáshoz kötődik.';
	@override String get borrowFromAnotherProfile => 'Kapcsolat használata másik profilból';
	@override String get borrowFromAnotherProfileSubtitle => 'Egy másik profil kapcsolatának használata. A PIN-kóddal védett profilokhoz PIN-kód szükséges.';
	@override String get invalidCredentials => 'Érvénytelen felhasználónév vagy jelszó';
	@override String get authResponseNotJson => 'A hitelesítési válasz nem érvényes JSON';
	@override String get authResponseIncomplete => 'A szerver bejelentkezési válasza hiányos volt';
	@override String get quickConnectRejected => 'A szerver elutasította a Quick Connect-kérést';
	@override String get quickConnectNotJson => 'A Quick Connect válasza nem érvényes JSON';
	@override String get quickConnectMissingFields => 'A Quick Connect válaszából hiányzik a kód vagy a titkos kulcs';
	@override String get quickConnectPollRejected => 'A szerver elutasította a Quick Connect lekérdezését';
	@override String get serverTimedOut => 'A szerver nem válaszolt időben';
	@override String get responseNotJson => 'A szerver válasza nem érvényes JSON';
	@override String responseMissingIdentity({required Object product}) => 'A válaszból hiányzik az azonosító vagy a szerver neve – ez valóban ${product}-szerver?';
	@override String probeFailed({required Object error}) => 'Nem sikerült elérni a szervert: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Adj meg legalább egy ${product}-szerverhez tartozó URL-t';
	@override String noReachableServer({required Object product}) => 'Nem található elérhető ${product}-szerver';
	@override String urlsPointToDifferentServers({required Object product}) => 'Ezek az URL-ek különböző ${product}-szerverekre mutatnak';
	@override String urlDoesNotMatchServer({required Object product}) => 'Ez az URL nem egyezik a(z) ${product}-szerverrel';
	@override String get redirectUnsupported => 'A szerver nem támogatott URL-re irányított át';
	@override String redirectDifferentHost({required Object product}) => 'A szerver egy másik gazdagépre irányított át. Add meg közvetlenül a végleges ${product} URL-t.';
	@override String get redirectInsecure => 'A szerver HTTPS-ről nem biztonságos URL-re irányított át';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'A szerver nem támogatott URL-re irányított át. Add meg közvetlenül a végleges ${product} URL-t.';
	@override String get directPlexServerUrl => 'Plex-kiszolgáló URL-címe';
	@override String get directPlexServerUrlHelper => 'Írja be a helyi IP-t és portot a Plex Media Server-ról.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (választható)';
	@override String get plexTokenHelper => 'Hagyja szabadon, ha az auth nélküli hozzáférés engedélyezett ezen a szerveren.';
	@override String get plexTokenRequired => 'Kérjük, adja meg a Plex token (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (közvetlen / helyi)';
	@override String get connectDirectPlexCardSubtitle => 'Csatlakozzon közvetlenül a helyi IP vagy URL segítségével plex.tv fiók nélkül.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Kapcsolat közvetlenül a helyi IP vagy URL használatával. Kapcsolatok a ${name}.';
	@override String get insecureTitle => 'titkosítatlan kapcsolat';
	@override String insecureDescription({required Object url}) => 'A(z) ${url} HTTP-t használ. A hálózaton mások elolvashatják vagy módosíthatják a jelszavát, a tokenjeit és a médiatartalmait. Ha elérhető, használjon HTTPS-t. Csak akkor folytassa, ha megbízik ebben a hálózatban és elfogadja a kockázatot.';
	@override String get allowHttp => 'HTTP engedélyezése';
	@override String get httpsRequired => 'Használja a HTTPS vagy kifejezetten engedélyezi a titkosított kapcsolatot.';
}

// Path: cast
class _Translations$cast$hu extends Translations$cast$en {
	_Translations$cast$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'A készülékre kattintva';
	@override String get searching => 'A Cast eszközök keresése...';
	@override String connectedTo({required Object device}) => 'Kapcsolódó oldalak ${device}';
	@override String get device => 'Cast eszköz';
	@override String get readyToCast => 'Kész a kiadásra';
	@override String get subtitle => 'Feliratok';
	@override String get serverNotAvailable => 'A média szerver nem elérhető.';
	@override String get stopCasting => 'Csatlakozás megáll';
	@override String get castToDevice => 'A készülékre vágás';
	@override String get noEpisodeAvailable => 'Nincs epizód, amit el lehet dobni.';
	@override String get startFailed => 'Nem tudok elkezdeni a szétválasztást. ellenőrizze a szervert, és próbáljon újra.';
}

// Path: automation
class _Translations$automation$hu extends Translations$automation$en {
	_Translations$automation$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Nincs aktív videó ülés ellenőrzésére.';
}

// Path: notifications
class _Translations$notifications$hu extends Translations$notifications$en {
	_Translations$notifications$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Új epizód';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$hu extends Translations$appAccess$en {
	_Translations$appAccess$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Próbáld ki minden funkciót ingyen 7 napig';
	@override String get description => 'Kezdje a hét napos próbát minden PlezyNG funkcióhoz való teljes hozzáféréssel. A próbában nincs díj és nincs előfizetés. A próbát követően egy élethosszig tartó vásárlás az üzlet árán PlezyNG az élethosszú zárat nyit.';
	@override String get trialEndedDescription => 'A PlezyNG minden funkciót letiltja az életre egy vásárlással az üzlet árán.';
	@override String get startTrial => 'Kezdje a 7 napos ingyenes próbát';
	@override String get trialActive => 'A 7 napos teljes funkciót tesztelője aktív.';
	@override String get trialEnded => 'A 7 napos bírósági eljárás befejeződött';
	@override String get trialStartFailed => 'Nem tudtam menteni a tesztet a készülékre. kérjük, próbáljon újra.';
	@override String get lifetimeTitle => 'PlezyNG életre szóló zárolás';
	@override String get lifetimeBody => 'Köszönöm! az egész életen át tartó hozzáférést kap minden PlezyNG funkcióhoz.';
	@override String get manageTitle => 'PlezyNG Élethosszú hozzáférés';
	@override String get manageDescription => 'Próbáld ki minden funkciót ingyen 7 napig, majd letölti az egész életet egy fizetéssel az áruház ára.';
	@override String buy({required Object price}) => 'Minden funkció letiltása a ${price}';
	@override String get loadingPrice => 'A szállítási árak...';
	@override String get retryPrice => 'Visszaállítási ár keresés';
	@override String get restore => 'Életmód vásárlás';
	@override String get pending => 'A vásárlás fizetést vagy jóváhagyást vár. Az élethosszig tartó hozzáférés a bolt befejezését követően zárul.';
	@override String get storeUnavailable => 'A vásárlás nem elérhető. Ellenőrizze, hogy Ön regisztrált a boltban, és a vásárlás engedélyezett ezen a készüléken.';
	@override String get productNotFound => 'A PlezyNG élethosszig tartó zárolás még nem elérhető ebben a boltban.';
	@override String get productQueryFailed => 'Nem tudtam feltölteni a bolt árat. Ellenőrizze a kapcsolatot, és próbáljon meg újra.';
	@override String get purchaseFailed => 'A vásárlás nem ment át. próbáljon újra.';
	@override String get restoreFailed => 'Nem tudtam eljutni a boltba, hogy visszaállítsam a vásárlást. próbáljon újra.';
	@override String get nothingToRestore => 'A PlezyNG életévét megvásárlás találta ebben a boltban.';
}

// Path: detail
class _Translations$detail$hu extends Translations$detail$en {
	_Translations$detail$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Vége: ${time}';
}

// Path: watchLink
class _Translations$watchLink$hu extends Translations$watchLink$en {
	_Translations$watchLink$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Nem tudtam elérni a Plex szervert erre a linkre.';
	@override String get notFound => 'Nem találtam ezt a show-t vagy filmet a Plex szervereken.';
	@override String get ambiguous => 'Ez a link megfelel az elemeknek több szerveren.A linkhez adjon hozzá egy szervert.';
	@override String get plexOnly => 'A jelenleg csak Plex szervereket támogat.';
	@override String get unsupportedItem => 'A néző linkek csak egy show-t vagy filmet nyithatnak meg.';
	@override String get menuItem => 'Lásd a linket';
	@override String get dialogTitle => 'Lásd linket';
	@override String get dialogShowHint => 'A link megnyitása a következő epizódot játssza. Add &mode=shuffle a végén, hogy játsszon a show on shuffle.';
	@override String get dialogMovieHint => 'A link megnyitása a filmet játssza.';
	@override String get copy => 'másolás';
	@override String get copied => 'Link másolat';
}

// Path: homeLayout
class _Translations$homeLayout$hu extends Translations$homeLayout$en {
	_Translations$homeLayout$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home újra az eredeti Plezy hős elrendezésre';
	@override String get resetHeroTitle => 'A hős elrendezésének helyreállítása a Plezy raktárba?';
	@override String get resetHeroBody => 'A hős állítása minden sorban törli, és visszahozza az egyetlen forgó banneret a ház tetején, mint az előző sorokban.';
	@override String get removeRowTitle => 'Helyreállítsa a homlokzatot?';
	@override String removeRowBody({required Object title}) => '${title} törlésre kerül. ez nem lehet megszüntetni.';
	@override String get sync => 'Szinkronizálás';
	@override String get syncAccountTitle => 'Szinkronizálja a Plex fiókkal való elrendezést';
	@override String get syncAccountOn => 'A: Ez a készülék megosztja a sorrendet, sorokat, Hero és Auto-slide a többi készülékkel.';
	@override String get syncAccountOff => 'Kattintson: Ez a készülék saját elrendezését tartja.';
	@override String get syncNow => 'Szinkronizálás most';
	@override String get plexHomeManager => 'Plex Házigazgató';
	@override String get managePlexRows => 'Plex sorok kezelése Plezy sorban';
	@override String get managePlexRowsDescription => 'Nyitva a házilag kiválasztott sorok megszervezéséhez';
	@override String get organizeHomeRows => 'Szervezze a házirendeket';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} sorok: mozog, Hős, Auto-slide, eltávolítása';
	@override String organizeLibraryRows({required Object library}) => 'Szervezés ${library} sorok';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Folytatás Nézd + ${n} sorok: mozog, Könyvtár, Ház, Hős, Autó-szalag';
	@override String get renderAsHero => 'Hősként válogatott kártyát';
	@override String get heroOnlySingleCollection => 'Csak akkor érhető el, ha ez a sor egy gyűjtemény valós címére oldódik meg';
	@override String get hero => 'Hősök';
	@override String get autoSlide => 'Autó Slide';
	@override String get autoSlideDescription => 'A bejutások (PC) és a d-pad (TV) mindig működnek és újraindítják a időzítőt.';
	@override String get autoSlideEditDescription => 'A csúszás is önmagában néhány másodpercenként. kikapcsolva: csak akkor mozog, ha egy lövedéket (PC) kattintson vagy balra/jobbra nyomja a távoli (TV) oldalon.';
	@override String get enableHeroFirst => 'Először a hős';
	@override String get showOnHome => 'Show on Home képernyőn';
	@override String get home => 'Kezdőlap';
	@override String get removeFromHome => 'eltávolítása otthonról';
	@override String get selectRowsFirst => 'Válassza ki az első helyen található házsorozatokat.';
	@override String plexManagedRows({required Object n}) => '${n} Plex irányított sorok';
	@override String get continueWatching => 'Folytatás';
	@override String get continueWatchingLibraryDescription => 'A könyvtár saját újjáépítésének sorrendje';
	@override String get continueWatchingHomeDescription => 'A folyamatos folyamatok újbóli sorát mutatják be otthon';
	@override String get nextUpHomeDescription => 'A következő nem figyelt epizód sorozatot külön-külön mutatott a Home';
	@override String get library => 'Könyvtár';
	@override String get showInRecommended => 'A könyvtárban ajánlott';
	@override String get customPlexRow => 'Személyes Plex sor';
	@override String get heroNeedsLibrary => 'Kövesse a könyvtárat először – Hero kell valahol megmutatni';
	@override String get heroNeedsSurface => 'Kezdőlap / Könyvtár / Kezdőlapi könyvtár / A hősnek valahol kell megmutatnia';
	@override String get removeHub => 'Hulladék Hub';
	@override String get noPlexRows => 'A Plex-es irányított sorok visszatértek erre a könyvtárra.';
	@override String get openDetails => 'Nyitott részletek';
	@override String get heroCards => 'Hős kártyák';
	@override String get tapHeroCard => 'Hős kártyát kap';
	@override String get tvPlayFocus => 'Televízió távoli: hangsúlyt a Play gomb';
	@override String get tvPlayFocusDescription => 'A D-pad leáll a Play gombra, mielőtt a következő sorba halad.';
	@override String get tvWrap => 'Televízió távoli: loop hős kártyák';
	@override String get tvWrapDescription => 'Az utolsó kártyán az első kártyára megy vissza. az utolsó kártyára megáll. az első kártán a bal mindig az oldalbarra megy.';
	@override String get castOnHero => 'Banner a hősökkel';
	@override String get castOnHeroDescription => 'A címet a hős banner alján mutatja be, és csak a címet és a összefoglalót tartja.';
	@override String get customRows => 'Custom sorok';
	@override String get loading => 'Home Layout Házas felbontás...';
	@override String get noCustomRows => 'Még nincs szokásos sor';
	@override String get addRowHint => 'Használja a Hozzáadása Home sor, hogy hozzon létre egy.';
	@override String get addHomeRow => 'Hozzáadása Home Rue';
	@override String get addHomeRowDescription => 'Válasszon egy kategóriát; az új sor automatikusan hozzáadódik a Szervezőhez';
	@override String get removeRow => 'eltávolítása sor';
	@override String get recentlyAdded => 'Legutóbb hozzáadva';
	@override String get recentlyReleased => 'Nemrégiben kiadott';
	@override String get movieCollections => 'Filmgyűjtemények';
	@override String get showCollections => 'Kollekciók bemutatása';
	@override String get rowTitle => 'Row cím';
	@override String get content => 'Tartalom';
	@override String get showThisRowIn => 'Ez a sor a következőben jelenik meg:';
	@override String get libraryRecommended => 'Könyvtár ajánlott';
	@override String get heroCard => 'Hős kártyák';
	@override String get heroCardDescription => 'A teljes körű forgatási kártyát mutatja be a poszter-szekrény helyett.';
	@override String get heroUnavailableDescription => 'Csak akkor áll rendelkezésre, ha ez a sor egy gyűjtemény tényleges címére oldódik meg - több mint egy gyűjtés kiválasztásával egyetlen cím sem fordulhat át.';
	@override String get librariesSelection => 'Könyvtárak (az összes ellenőrzés nélküli könyvtárat minden könyvtárhoz bele kell foglalni)';
	@override String get librariesMergedDescription => 'Minden könyvtár itt ellenőrzött össze van keverve ebben az egyik sorban.';
	@override String get movieCollectionsSelection => 'Filmgyűjtemények (minden ellenőrzés nélküli lemez minden kiválasztott könyvtárban)';
	@override String get showCollectionsSelection => 'Megjelenítés gyűjtemények (töltsön ki minden nem ellenőrzött minden kiválasztott könyvtár)';
	@override String get collectionRowsDescription => 'Ha pontosan egy gyűjtemény mérkőzik, a címek közvetlenül a sorban jelennek meg. Ha több mint egy mérkőzik az egyes gyűjtemények egy plakátként jelennek meg - kattintson rá, hogy megnyissa azt a gyűjteményt.';
	@override String get allCollections => 'Összes gyűjtemény';
	@override String get noRowsHere => 'Még nincs sor itt.';
	@override String get hideWatchedRows => 'Elrejtett tárgyak sorban';
	@override String get hideWatchedRowsDescription => 'Teljesen megtekintett címek elhagyják a Ház és a könyvtár Ajánlott sorok.';
	@override String get untitledCollection => 'címtelen gyűjtemény';
	@override String get moveRowHint => 'Felszállás: lépés sorban · Válassza ki: dobja le itt · Vissza: törli';
	@override String get organizeRowsHint => 'Válasszon egy sorban (vagy tartsa Válassza ki): mozogjon · Balra/jobbra: sorban lehetőségek · Vissza: véget ért';
	@override String get layoutNavDescription => 'Válasszon sorokat, könyvtárakat és gyűjteménykategóriákat';
	@override String get editHomeRow => 'Edit Home Rózsaszín';
	@override String get resetHeroButton => 'A Hero layout visszaállítása a stockhoz Plezy';
	@override String get reorderingUnlocked => 'Újra elzárva';
	@override String get reorderingLocked => 'Újra zárva';
	@override String get rowsCanBeDragged => 'A szálak húzhatók - nyomja meg a zárat, hogy megakadályozzák ezt';
	@override String get tapLockToDrag => 'Nyomja meg a zárat a sorok húzásához';
	@override String customRowLabel({required Object title}) => 'Személyes adatok: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Elrejtés';
	@override String get remove => 'Eltávolítás';
	@override String get libraryResumeRow => 'A könyvtár újbóli sorrendje';
	@override String get pressAgainToDelete => 'Nyomja meg újra a törléshez';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'A';
	@override String get resetHeroButtonDescription => 'A hős állításait minden sorban törli le, és visszahozza az egyetlen forgó banneret a tetején, mint az előző sorban.';
	@override String get tapHeroCardDescription => 'Válassza ki, hogy egy Hero kártyát nyomtatva vagy kiválasztva megkezdődik a lejátszás, vagy megnyitja annak részleteit.';
	@override String get heroTapPlayDescription => 'Indítsa el a kiválasztott elemet azonnal.';
	@override String get heroTapDetailsDescription => 'Nyissa meg a kiválasztott elem részleteit, mielőtt egy akciót választ.';
}

// Path: platform
class _Translations$platform$hu extends Translations$platform$en {
	_Translations$platform$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'A PlezyNG a helyi hálózaton keresztül csatlakozik a média szerverekhez és a lejátszó eszközökhöz.';
	@override String get locationPermission => 'A PlezyNG akkor használja a helyadatokhoz való hozzáférést, ha az iOS ezt megköveteli a helyi hálózat felismeréséhez és a médiaszerverekhez való csatlakozáshoz.';
	@override String get photoLibraryPermission => 'Válassz képeket a fotókönyvtáradból a médiatartalmak borítóképeihez és illusztrációihoz.';
	@override String get cameraPermission => 'QR kódok szkennelése a Companion Remote párosításához.';
}

// Path: universalMedia
class _Translations$universalMedia$hu extends Translations$universalMedia$en {
	_Translations$universalMedia$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nyílt média';
	@override String get shortcutHelp => 'Játssz egy linket, lejátszási listát vagy fájlt erre az ülésre.';
	@override String get intro => 'Nyissa meg a linket, a lejátszási listát vagy a fájlt.A Playback használja a PlezyNG szabványos lejátszóját és nem ad hozzá történetet a könyvtárához.';
	@override String get openWhat => 'Mit szeretne megnyitni?';
	@override String get stream => 'Stream cím';
	@override String get playlist => 'játéklisták';
	@override String get files => 'készülék fájl';
	@override String get favorites => 'Megtakarított stream kedvencek';
	@override String get address => 'média cím';
	@override String get addressHelp => 'Az elismert hitelesítési vagy aláírási paraméterekkel rendelkező URL-k csak ebben az ülésen használhatók, és nem menthetők kedvencként.';
	@override String get displayName => 'A kijelző neve (opcionális)';
	@override String get displayNameHelp => 'Válasszon egy rövid nevét a játékos és a rendszer média vezérlők.';
	@override String get allowHttp => 'A titkosítás nélküli HTTP-kapcsolat engedélyezése';
	@override String get allowHttpHelp => 'A HTTP nem titkosítja a kapcsolatot. csak megbízható hálózaton engedélyezheti. ha lehetséges, használja a HTTPS-t.';
	@override String get advancedProtocols => 'Csak MPV: adjon meg egy RTSP, RTMP/RTMPS, UDP vagy RTP címet.';
	@override String get liveStream => 'Élőként kezeljük';
	@override String get liveStreamHelp => 'Használja ezt az élő videó vagy rádió. Az alkalmazás elrejti az időzónát, a skip gombokat és a go-to-time opciót.';
	@override String get privateSession => 'Csak ez a lejátszás használja az címet. mentse meg a jogosult stream kedvenc, hogy ezt tartsa ebben a profilban.';
	@override String get saveFavorite => 'Megmentse kedvencét';
	@override String get playNow => 'Játssz most';
	@override String get favoriteSaved => 'Stream kedvenc mentett erre a profilra';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: 'A ${count} nem támogatott vagy biztonságos lejátszási lista bejárata.',
		other: 'A ${count} nem támogatott vagy biztonságos lejátszási listájának bejegyzései.',
	);
	@override String get playlistAddress => 'Playlist címek';
	@override String get playlistAddressHelp => 'Nyissa meg a M3U, M3u8 vagy PLS lejátszási listát egy webcímről. közvetlen áramlás linkek nem menthetik meg a lejátszó listát.';
	@override String get choosePlaylist => 'Válassza ki a Playlist fájlt';
	@override String get openPlaylist => 'Nyílt Playlist';
	@override String get playlistFormatsHelp => 'A lejátszó listája legfeljebb 1000 elemet és 2 MB-ot tartalmazhat. a HLS nyílt áramlatként jelenik meg, így a játékos kiválaszthatja a minőséget.';
	@override String get saveQueuePlaylist => 'Sor mentése lejátszási listaként';
	@override String get queuePlaylistSaved => 'A lejátszási lista a médiafájlok mellé lett mentve.';
	@override String get queuePlaylistUnavailable => 'Ez a sor nem menthető újra felhasználható helyi lejátszási listaként.';
	@override String get queuePlaylistFolderRequired => 'A sor fájljaival azonos mappát válassz mentési helyként.';
	@override String get noFavorites => 'Nincs mentett stream kedvencek még. Favoritek maradnak ebben a profilban.';
	@override String get removeFavorite => 'Távolítsa el a kedvenc stream';
	@override String get filesHelp => 'Válassza ki az audio, a videó vagy az ISO fájlokat egy ideiglenes tartományhoz. A fájlok és URL-ek nem kerülnek hozzáadásra a könyvtár történetéhez.';
	@override String get chooseFiles => 'Válasszon fájlokat';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '1 kiválasztott fájl',
		other: '${count} kiválasztott fájlok',
	);
	@override String get wifiTransfer => 'Fájlok küldése Wi-Fi';
	@override String get wifiTransferHelp => 'Támogatott fájlok átadása egy böngészőről ugyanazon megbízható hálózaton.';
	@override String get wifiTransferIntro => 'Nyissa meg ezt a címet egy böngészőben egy másik eszközön. Válassza ki a fájlokat, hogy hozzáadják őket a készülék Fájlok és könyvek könyvtárába.';
	@override String get wifiTransferPrivacy => 'Ez a készülék fogadja a fájlokat a helyi hálózaton keresztül. Bárki, aki ismeri ezt az címet, elküldheti azokat addig, amíg nem hagyja abba az átutalást vagy a cím 15 perc elteltével megszűnik. Maximum: 100 fájlt, 4 GiB fájlokonként, 10 GiB összesen.';
	@override String get wifiTransferStarting => 'Személyre szabott, korlátozott átutalás...';
	@override String get wifiTransferUnavailable => 'Nem tudja elkezdeni az átutalást. ellenőrizze a helyi hálózati hozzáférést, és próbálja meg újra.';
	@override String get openThisAddress => 'Nyissa meg az egyik címet a küldő eszközön';
	@override String get copyAddress => 'átviteli cím másolása';
	@override String get addressCopied => 'átutalási cím másolva';
	@override String transferExpires({required Object time}) => 'Ez a cím az ${time}-ben lejár.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${count} fájl kapott',
		other: '${count} fájlok kaptak',
	);
	@override String uploadedData({required Object size}) => 'Megérkezett ${size}';
	@override String get stopTransfer => 'Megállapodás átadásáról és cím megsemmisítéséről';
	@override String get startTransfer => 'Kezdődik a transzfer';
	@override String get wifiImportedFiles => 'Wi-Fi átutalás';
	@override String get wifiBrowserTitle => 'Fájlok küldése PlezyNG';
	@override String get wifiBrowserIntro => 'Válassza ki az audio, videó, ebook vagy képregény fájlokat küldeni. A fájlok tárolódnak a készülék Fájlok és könyvek könyvtárában. Maximum: 100 fájlt, 4 GiB fájlonként, 10 GiB összesen.';
	@override String get uploadFilesLabel => 'Fájlok küldeni';
	@override String get uploadSelected => 'A kiválasztott fájlok feltöltése';
	@override String get uploadSelectFirst => 'Válasszon egy vagy több fájlt először.';
	@override String get uploading => 'küldés';
	@override String get uploadComplete => 'Fájl hozzáadva PlezyNG.';
	@override String get uploadFailed => 'A fájl nem lehet hozzáadni. tartsa nyitva ezt az oldalt, és próbálja meg újra.';
	@override String get liveCue => 'Élő';
	@override String get liveSession => 'Élő Stream';
	@override String get liveCueHelp => 'Az élő videó vagy rádió esetében az alkalmazás elrejti az időzónát és a gombokat. nem mentheti meg a címet vagy a történetet.';
	@override String get sessionOnly => 'Ez a playback csak szezonális';
	@override String get sessionOnlyHelp => 'A Playback soha nem mentse meg a haladást vagy a történelmet. mentse az áramlat kedvencnek, hogy ebben a profilban maradjon, ha jogosult.';
	@override String get pictureAdjustments => 'Kép módosítása';
	@override String get pictureHelp => 'Ezek a képváltozások csak ezt a lejátszást érintik. újra beállítják, amikor a playback véget ér.';
	@override String get resetPicture => 'Visszaállítási kép';
	@override String get brightness => 'fényesség';
	@override String get contrast => 'kontraszt';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'szaturáció';
	@override String get view360 => 'A 360 fokos videó megjelenítése';
	@override String get view360Help => 'Használja ezt az egyenes 360°-os videóhoz. MPV-nek szüksége van a FFmpeg v360 szűrőjére erre a nézőpontra.';
	@override String get view360Unavailable => 'Ez az MPV szerkezet nem alkalmazhatja a 360 fokos szűrőt.';
	@override String get view360Yaw => 'Horizontális kilátás';
	@override String get view360Pitch => 'Vertikális kilátás';
	@override String get view360FieldOfView => 'A látványterület';
	@override String get recordStream => 'Live stream rekordok';
	@override String get stopRecording => 'Állítsa meg és mentse a felvételt';
	@override String get recordingStarted => 'A lejátszás megszűnik, és megmenti a felvételt.';
	@override String get recordingSaved => 'A felvétel befejeződött és mentett.';
	@override String get recordingActive => 'Ez a készülék.Leaving playback megáll és mentse meg.';
	@override String get recordingFormatHelp => 'Videó esetén válassza ki a MKV vagy MPEG-TS. A hang esetében válasszon MKA vagy MKV.';
	@override String get replaceRecordingTitle => 'Ezt a felvételt helyettesítjük?';
	@override String get replaceRecordingHelp => 'A PlezyNG visszaállítja a meglévő fájlt a rögzítés során. ha nem tudja menteni az új rögzítést, a Plezy NG visszaállíthatja a biztonsági mentést.';
	@override String get replaceRecording => 'Fájl cseréje';
	@override String get discHelp => 'Nyissa meg a lemezt ebben a számítógép optikai lemezében.Az ISO-képet is megnyithatja a Device fájlokból.';
	@override String get discs => 'Optikai lemez';
	@override String get editionOrTitle => 'Kiadás vagy lemezcím';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray';
	@override String get audioCd => 'Audió CD';
	@override String get discAvailability => 'A lemezlejátszásnak kompatibilis MPV szerkezetre, támogatott lemezre és operációs rendszer engedélyére van szüksége.';
	@override String get converterTitle => 'A helyi média fájl átalakítása';
	@override String get converterHelp => 'Konvertáljon egy helyi fájlt, vagy helyreállítsa a FFmpegA';
	@override String get converterIntro => 'Konvertáljon egy helyi audio vagy videó fájlt olyan formátumra, amely több eszközön működik.';
	@override String get converterPrivacy => 'FFmpeg kell telepíteni ezen a számítógépen. konverzió csak helyi fájlokat olvasható. nem tölt le áramlatok vagy eltávolítja DRM-t.';
	@override String get converterChooseInput => 'Válasszon egy helyi média fájlt';
	@override String get converterFormat => 'kimeneti formátum';
	@override String get converterMp4 => 'MP4 · H.264 és AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 hangszóró';
	@override String get allowFtp => 'FTP engedélyezése';
	@override String get allowFtpHelp => 'Az FTP titkosítás nélküli médiát küld, csak megbízható hálózatokon használja.';
	@override String get converterSaveAs => 'Az átalakított média mentése';
	@override String get converterExtensionMismatch => 'Válasszon egy fájlnevet a kiválasztott kimeneti kiterjesztéssel.';
	@override String get converterUnsupportedInput => 'Válasszon egy audio vagy videó fájlt.';
	@override String get converterLocalOnly => 'A kiválasztott fájl nem áll rendelkezésre helyi eszközútként.';
	@override String get converterReplaceTitle => 'A fájl helyettesítése?';
	@override String get converterReplaceHelp => 'A PlezyNG visszaállítja a meglévő fájlt, amíg az átalakított másolat menthető.';
	@override String get converterStarting => 'Megkezdődött az FFmpeg...';
	@override String get converterProgress => 'Ezzel a számítógéppel átalakítva...';
	@override String get converterComplete => 'Az új fájl készen áll.';
	@override String get converterFfmpegMissing => 'FFmpeg hiányzik, vagy nem támogatja ezt a formátumot.';
	@override String get converterFailed => 'Ellenőrizze, hogy a forráskód fájl olvasható és a rendeltetési hely elegendő szabad hely.';
	@override String get converterCancelled => 'Az átalakítás törlésre került, a hiányos eredményt eltávolították.';
	@override String get converterDesktopOnly => 'Helyi átalakítás elérhető asztali számítógépeken FFmpeg telepítve.';
	@override String get converterStart => 'fájl átalakítása';
	@override String get mediaToolsTitle => 'Média eszközök';
	@override String get mediaToolsShortcut => 'Foglaljon vagy ossza meg a média, adjon hozzá keresési kiterjesztéseket, vagy használja a parancsvonalat.';
	@override String get mediaToolsIntro => 'Válasszon egy fókuszált eszközt. Foglaljon és áramlást használjon FFmpeg telepítve ezen a asztalon. kiterjesztések és CLI parancsok használja a korlátozott HTTPS kérések és a meglévő Open media áramlást.';
	@override String get mediaToolsAccessibility => 'Az eszközválasztás és a vezérlések a touch, a mutató, a billentyűzet és a D-pad fókuszával működnek. A felvételi, megosztási és keresési állapot változásait hirdetik.';
	@override String get mediaTool => 'média eszközök';
	@override String get captureIntro => 'A képernyőt vagy a fényképezőgépet a MP4 fájlra rögzíti ezen a számítógépen. a FFmpeg telepítve kell lennie, és a H.264 kódot kell tartalmazni.';
	@override String get captureNoDevices => 'Nem találták meg a képernyőt vagy a fényképezőgépet. ellenőrizze a FFmpeg felvételi támogatást és az operációs rendszer adatvédelmi engedélyeket.';
	@override String get captureSource => 'képernyő vagy kamera';
	@override String get captureScreen => 'képernyő';
	@override String get captureAudioSource => 'Audio beviteli lehetőség (opcionális)';
	@override String get captureAudioHelp => 'Hozzon hozzá hangot egy mikrofonból vagy a rendelkezésre álló bevitelt. A készülék kiválasztása a FFmpeg és a rendszer engedélyezéseitől függ.';
	@override String get captureAudioNone => 'Nincs audio';
	@override String get captureDefaultAudio => 'Audio beviteli előzetes';
	@override String get captureWaylandHelp => 'Wayland korlátozza ezt a XWayland fogást a X display-re. A XWayland-en kívüli Windows nem jelenik meg.';
	@override String get captureFrameRate => 'Részletesebben Regisztrációs ráta';
	@override String get capturePrivacy => 'A rögzítés csak az Ön által kiválasztott fájlra menthető. a mikrofon rögzítése opcionális. a PlezyNG nem tölti fel a rögzítést.';
	@override String get captureSaveAs => 'A képernyő felvétele, mint';
	@override String get captureExtensionMismatch => 'Válassza ki a .mp4-ben végződő filenámot.';
	@override String get captureFfmpegMissing => 'FFmpeg vagy a H.264 videó kódoló nem érhető el. Telepítse a támogatott FFmpeg építkezést, majd próbáljon újra.';
	@override String get captureFailed => 'A felvétel nem menthető meg. Ellenőrizze a készülék engedélyét, a rendelkezésre álló tárolást és a FFmpeg támogatást.';
	@override String get captureSaved => 'A képernyő felvétele mentett.';
	@override String get captureElapsedLabel => 'Rekordidő';
	@override String get captureStart => 'Kezdődik a felvétel';
	@override String get capturePreview => 'Előnézet a lejátszóban';
	@override String get capturePreviewHelp => 'A kiválasztott forrás előnézete a szokásos lejátszóban. Csak erre a munkamenetre szól, és nem ment felvételt. Az eszköztámogatás és az engedélyek az MPV-től és az operációs rendszertől függenek. Az előnézet csak videót használ; a mentett felvételekhez opcionális hang is tartozhat.';
	@override String get capturePreviewActive => 'Élő előnézet · nincs felvétel';
	@override String get captureStop => 'Állj meg és mentse meg';
	@override String get captureMode => 'fogság';
	@override String get shareMode => 'megosztás';
	@override String get shareIntro => 'Küldje el a helyi médiafájlt egy másik eszközre a magánhálózaton. PlezyNG létrehoz egy ideiglenes HLS áramlást.';
	@override String get sharePrivacy => 'Bárki a helyi hálózaton, aki a privát linket kapja meg, megtekintheti, miközben aktív. A link 60 perc után megszűnik.';
	@override String get shareChooseFile => 'Válassza ki a média fájlt';
	@override String get shareChooseHelp => 'Válasszon egy helyi audio vagy videó fájlt. A fájl ezen a számítógépen marad.';
	@override String get shareFfmpegMissing => 'A FFmpeg vagy a H.264/AAC kódolók nem érhetők el. A FFmpeg telepítése a H.264 és a AAC kódolási támogatással.';
	@override String get shareFailed => 'Az áramlat nem indult vagy váratlanul megállt. ellenőrizze a FFmpeg és a hálózati hozzáférést.';
	@override String get shareActive => 'Az áramlat készen áll a magánhálózaton.';
	@override String get shareEnded => 'A média elérte a véget, és már nem oszlik meg.';
	@override String get shareStopped => 'A megosztás megszűnt. az ideiglenes link már nem érvényes.';
	@override String get shareUrlCopied => 'Az áramszolgáltatás címét másolták.';
	@override String get shareOpenUrl => 'Nyissa meg ezt a címet egy játékosban a másik eszközön';
	@override String get shareQrLabel => 'QR kód az ideiglenes áramlat címéhez';
	@override String get shareQrHelp => 'Scan egy kompatibilis lejátszóval, amely ugyanazon magánhálózathoz van csatlakoztatva.';
	@override String get shareHttpHint => 'Ez az áramlás titkosított HTTP. A PlezyNG, engedélyezze HTTP, mielőtt megnyitja.';
	@override String get shareCopyUrl => 'Stream cím másolása';
	@override String get shareExpiresLabel => 'A link lejár';
	@override String get shareStarting => 'Az áramlás előkészítése...';
	@override String get shareStart => 'Kezdődik a megosztás';
	@override String get shareStop => 'Megáll a megosztás';
	@override String get extensionsMode => 'Kiterjesztések és CLI';
	@override String get extensionsIntro => 'Hozzon hozzá egy adat-csak keresési kiterjesztést, hogy megtalálja a média. Válasszon egy eredményt, hogy töltse le a jól ismert Open media űrlap.';
	@override String get extensionsPrivacy => 'Egy manifeszt meghatározhatja a HTTPS keresési végpontot és a térkép válasz mezőit. Nem fut kódot, kérési címeket adhat hozzá, olvassa el a fájlokat, vagy indítsa el a shell parancsokat.';
	@override String get extensionImport => 'Meghosszabbítás manifeszt';
	@override String get extensionEmpty => 'Nincs keresési szolgáltatás még. Válasszon egy megbízható manifeszt JSON fájlt, hogy hozzáadja az egyiket.';
	@override String get extensionChoose => 'Keresési szolgáltatás';
	@override String get extensionSearchConsent => 'Minden keresés elküldi a szavakat erre a HTTPS szolgáltatásra.Az eredmények csak az egyik kiválasztása után nyílik meg.';
	@override String get extensionSearchLabel => 'Keresési média';
	@override String get extensionSearch => 'Keresés';
	@override String get extensionSearching => 'Keresés...';
	@override String get extensionNoResults => 'Nincs biztonságos média eredmények visszatértek. próbáljon meg egy újabb keresést.';
	@override String get extensionInstallTitle => 'Adja meg ezt a keresési szolgáltatást?';
	@override String get extensionReplaceTitle => 'Aktualizálja ezt a keresési szolgáltatást?';
	@override String get extensionService => 'Szolgáltatás';
	@override String get extensionEndpoint => 'HTTPS végpont';
	@override String get extensionConsent => 'A keresési szöveget küldik erre a szolgáltatásra. a manifeszt nem tartalmaz végrehajtható kódot. Csak akkor folytatja, ha ezt a végpontot bízik.';
	@override String get extensionInstall => 'Add szolgáltatás';
	@override String get extensionReplace => 'frissítés szolgáltatás';
	@override String get extensionRemoveTitle => 'Távolítsa el ezt a keresési szolgáltatást?';
	@override String get extensionRemoveHelp => 'Ez eltávolítja a szolgáltatást ebből a profilból. a PlezyNG nem lép kapcsolatba a végpontjával.';
	@override String get extensionRemove => 'eltávolítása szolgáltatás';
	@override String get extensionInvalidManifest => 'Ez a fájl nem támogatott kiterjesztés manifesztus. lásd a Open media útmutatót a formátumra.';
	@override String get extensionSaveFailed => 'A kiterjesztés nem menthető meg az aktív profilra.';
	@override String get extensionSearchFailed => 'A keresési szolgáltatás nem ad vissza érvényes választ. Ellenőrizze a végpontot, és próbálja meg újra.';
	@override String get cliTitle => 'parancsvonal';
	@override String get cliHelp => 'Használja a plezyctl útmutatót egy manifeszt validálására vagy ugyanazon kiterjesztés keresésére. Minden keresés előtt felülvizsgálja a HTTPS szolgáltatást. Az eredmények a meglévő médiaformátumban nyílik meg; válassza ki a lejátszási gombot.';
	@override String get cliCopyExample => 'A parancs példája';
	@override String get cliCopied => 'A parancs példája másolt.';
}

// Path: fileSources
class _Translations$fileSources$hu extends Translations$fileSources$en {
	_Translations$fileSources$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fájlok és könyvek';
	@override String get subtitle => 'Olvasson, hallgasson és figyelj a saját fájlokat.';
	@override String get add => 'Hozzáadása forrás';
	@override String get importFiles => 'Import fájl';
	@override String get localFiles => 'Ebben a készülékben';
	@override String get source => 'forrás';
	@override String get name => 'nevét';
	@override String get endpoint => 'Szerver URL-címe';
	@override String get smbEndpointHint => 'Példa: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Adjon meg egy SMB-kiszolgálót és egy megosztást.';
	@override String get root => 'Folder vagy prefix';
	@override String get smbFolderHelp => 'Hagyja üresen a teljes megosztás használatához, vagy adjon meg egy azon belüli mappát.';
	@override String get username => 'Felhasználónév';
	@override String get smbDomain => 'Tartomány (nem kötelező)';
	@override String get password => 'Jelszó';
	@override String get token => 'API token';
	@override String get accessKey => 'Access kulcs ID';
	@override String get secretKey => 'titkos hozzáférési kulcs';
	@override String get sessionToken => 'Session token (szükséges)';
	@override String get region => 'régió';
	@override String get clientId => 'OAuth ügyfél ID';
	@override String get clientSecret => 'OAuth ügyfél titka (csak a Google asztali)';
	@override String get allowHttp => 'Titkosítatlan HTTP engedélyezése megbízható hálózaton';
	@override String get smbEncryption => 'SMB3-kapcsolat titkosítása';
	@override String get smbEncryptionHint => 'SMB3-titkosítás használata, ha a NAS támogatja.';
	@override String get connect => 'Csatlakozás';
	@override String get cancel => 'Mégse';
	@override String get save => 'Mentés';
	@override String get close => 'Bezárás';
	@override String get removeSource => 'Kapcsolatfelvétel forrás';
	@override String get disconnectMessage => 'Leválasztod ezt a forrást? A letöltött fájlok, valamint az olvasási és hallgatási előzmények ezen az eszközön maradnak.';
	@override String get localFolder => 'Válassza ki a mappa';
	@override String get empty => 'Még nincs itt semmi';
	@override String get emptyHint => 'Hozzon hozzá forrást vagy importáljon egy könyvet, audiókönyvet, zenét vagy videót.';
	@override String get search => 'Keresés a fájlban';
	@override String get searchCached => 'Keresés mentett könyvtár';
	@override String get refresh => 'Frissítés';
	@override String get loadMore => 'Töltse tovább';
	@override String get offline => 'Offline elérhető';
	@override String get download => 'offline maradjon';
	@override String get removeDownload => 'offline másolatok eltávolítása';
	@override String get continueReading => 'Folytatás olvasás';
	@override String get continueListening => 'Folytatjuk a hallgatást';
	@override String get continueWatching => 'Folytatjuk a figyelmét';
	@override String get read => 'Olvasson';
	@override String get listen => 'Hallgasson';
	@override String get play => 'Lejátszás';
	@override String get pause => 'Szünet';
	@override String get stop => 'Leállítás';
	@override String get startOver => 'Kezdődjön a';
	@override String get finished => 'Befejeződött';
	@override String get markFinished => 'Márk befejeződött';
	@override String get markUnfinished => 'Márk végtelen';
	@override String get editions => 'Kiadványok és fájlok';
	@override String get chapters => 'Fejezetek';
	@override String get bookmarks => 'Könyvek és jegyzetek';
	@override String get bookmark => 'Add a bookmark';
	@override String get highlight => 'Fokozás';
	@override String get note => 'jegyzetek';
	@override String get delete => 'Törlés';
	@override String get export => 'exportjegyzékek';
	@override String get exported => 'Kiadó jegyzetek';
	@override String get sync => 'Sinkronizálódás';
	@override String get synced => 'Progressz szinkronizálódott';
	@override String get conflict => 'Egy másik eszköz más helyzetben van. Válassza ki, hol kell folytatni.';
	@override String get useLocal => 'Használja ezt a készüléket';
	@override String get useRemote => 'Egy másik eszköz használata';
	@override String get history => 'pozíció története';
	@override String get groupAudio => 'Hallgassunk egy audiókönyvében';
	@override String get groupHint => 'Összefügg a jelenleg ezen a mappában feltöltött audiofájlokkal. Minden oldal feltöltése először.';
	@override String get order => 'File rend';
	@override String get moveUp => 'mozgatni fel';
	@override String get moveDown => 'Mozgás le';
	@override String get speed => 'Playback sebesség';
	@override String get sleep => 'Elalvási időzítő';
	@override String get sleepOff => 'Ki';
	@override String get endChapter => 'fejezet vége';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} perc',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} perc',
	);
	@override String get skipBack => 'Vissza a Skip';
	@override String get skipForward => 'Skip előre';
	@override String get smartRewind => 'Intelligens visszacsatolás a szünet után';
	@override String get playbackOptions => 'Hallgatási lehetőségek';
	@override String remaining({required Object time}) => '${time} megmaradt';
	@override String get contents => 'Tartalom';
	@override String get readerSettings => 'Olvasási beállítások';
	@override String get fontSize => 'szöveg méret';
	@override String get lineHeight => 'Line tér';
	@override String get margin => 'Margók';
	@override String get font => 'Tippfelület';
	@override String get serif => 'Talpas';
	@override String get sans => 'Szerif nélkül';
	@override String get mono => 'Monopar';
	@override String get columns => 'oszlopok';
	@override String get scroll => 'Vertikálisan Scroll';
	@override String get justify => 'A szöveg igazolása';
	@override String get readerTheme => 'oldal megjelenése';
	@override String get appTheme => 'Következő app témák';
	@override String get paper => 'Papír';
	@override String get sepia => 'Sepia';
	@override String get night => 'éjszaka';
	@override String get readAloud => 'Az oldal felolvasása';
	@override String get readAlong => 'Olvass tovább';
	@override String get stopReading => 'A narráció megállítása';
	@override String get searchBook => 'Keresés a könyvben';
	@override String get noMatches => 'Nincs mérkőzés';
	@override String get previousPage => 'Előző oldal';
	@override String get nextPage => 'Következő oldal';
	@override String page({required Object number}) => 'oldal ${number}';
	@override String get externalBlocked => 'A külső könyv linkek a olvasóban kikapcsolódnak.';
	@override String get loading => 'Nyitó...';
	@override String get narrator => 'Történész';
	@override String get audio => 'Hang';
	@override String get video => 'Videó';
	@override String get ebooks => 'Ebook';
	@override String get all => 'Összes';
	@override String get downloads => 'Offline fájlok';
	@override String get confirmDelete => 'Távolítsa el a kiválasztott offline másolatot? a pozíció és a jegyzetek maradnak.';
	@override String get errorAuthentication => 'Jelentkezzen be újra, hogy újra csatlakozzon erre a forrásra.';
	@override String get errorPermission => 'Ez a forrás nem adta hozzáférést a kért fájlhoz.';
	@override String get errorUnavailable => 'A forrás nem elérhető. Próbáljon újra, vagy nyissa meg az offline másolatot.';
	@override String get errorUnsupported => 'Ez a formátum vagy a kapcsolat nem támogatott ebben a készülékben. ellenőrizze a forrás beállítási útmutatót.';
	@override String get errorInvalidData => 'Ez a fájl vagy a szerver válasz nem lehetett biztonságosan olvasni.';
	@override String get errorCancelled => 'A műveletet törölték.';
	@override String get errorConflict => 'A pozíció egy másik ülésen megváltozott. Újra nyissa meg az elemet, hogy válasszon egy pozíciót.';
	@override String get signIn => 'Bejelentkezés';
	@override String get reconnect => 'Újracsatlakozás';
	@override String get folderHelp => 'Hagyja a nyílt, hogy elkezdődjön a forrás gyökér. S3 URL-k tartalmazza a csomagtartót.';
	@override String get preferences => 'preferenciák';
	@override String get timePosition => 'Pozíció';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtitle útvonal';
	@override String get none => 'Nincs';
	@override String get fullscreen => 'Teljes képernyő';
	@override String get syncLocation => 'Progress szinkronizálás (opcionális)';
	@override String get syncLocationHint => 'A WebDAV fájl a PlezyNG állapothoz. feltételezett írásokat használ; a média változatlan marad.';
	@override String get audiobooks => 'Audiókönyvek';
	@override String get comics => 'Képregények';
	@override String get scan => 'A könyv és a média szkennelése';
	@override String get browserReader => 'Nyílt olvasó';
	@override String get browserReaderHelp => 'A böngészőben a olvasó nyitva van. A PlezyNG nyitva tartása a hely és a jegyzetek mentéséhez.';
	@override String get on => 'A';
	@override String get advancedSetup => 'App regisztráció';
	@override String get microsoftSignIn => 'Jelentkezzen be a Microsoft-hoz';
	@override String get zoomIn => 'Zoom a';
	@override String get zoomOut => 'Zoom ki';
	@override String get fitPage => 'Fit oldal';
	@override String get fitWidth => 'széles széles';
	@override String get actualSize => 'Aktuális méret';
	@override String get goToPage => 'Menj a lapra';
	@override String get goToSection => 'Menj a fejezetbe';
	@override String pageRange({required Object count}) => 'Írja be az 1 számot a ${count}';
	@override String get pageLayout => 'Page layout oldal';
	@override String get automatic => 'Automatikus';
	@override String get singlePage => 'Egyoldalú oldal';
	@override String get twoPages => 'Két oldal';
	@override String get readingDirection => 'Olvasási irány';
	@override String get leftToRight => 'Balra a jobbra';
	@override String get rightToLeft => 'Jobbról balra';
	@override String get letterSpacing => 'levél spacing';
	@override String get wordSpacing => 'Szavak spacing';
	@override String get readerControlsHelp => 'Két ujj széthúzásával vagy a nagyítási vezérlőkkel nagyíthatod az oldalakat. Húzással mozgathatod az oldalt. A Ctrl/⌘ és + vagy − módosítja a nagyítást; a Ctrl/⌘ és 0 visszaállítja azt. A Page Up és Page Down lapoz.';
	@override String get imagePage => 'Képregényoldal';
	@override String get resetReader => 'Újraindítás olvasási preferenciák';
	@override String get zoom => 'Nagyítás';
	@override String get useFiles => 'Fájlok és könyvek használata';
	@override String get cancelScan => '- törlés scan';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Offline letöltés limit';
	@override String get offlineQuotaHelp => 'Állítsa be a maximális helyet használt offline másolatok, importált fájlok, és lejátszott letöltések. A határ csökkentése nem távolítja el a meglévő másolatokat.';
	@override String get offlineStorageUsage => 'Offline tárolás';
	@override String get reservedStorage => 'fenntartás';
	@override String get downloadQueue => 'Letöltés Queue';
	@override String get downloadRunning => 'Letöltés';
	@override String get downloadQueued => 'Várakozás';
	@override String get downloadPaused => 'pihenés';
	@override String get downloadFailed => 'Visszavonulás szükséges';
	@override String get importing => 'behozatal';
	@override String get importInterrupted => 'Import megszakadt · eltávolítása tisztázni';
	@override String get errorQuotaExceeded => 'Az offline tárolási korlátozás elérte. emelje fel a korlátot vagy távolítsa el a letöltött másolatot.';
	@override String get errorStorageLow => 'Nincs elég ingyenes tárolási eszköz a védett tartalék fenntartásához.';
	@override String get errorStorageUnavailable => 'A PlezyNG nem tudta ellenőrizni a szabad készülék tárolását, így az írás megszűnt.';
	@override String get removeDownloadJob => 'Letöltés eltávolítása';
	@override String get downloadAlreadyComplete => 'Ez a letöltés befejeződött, mielőtt eltávolítható. az elem most elérhető offline.';
	@override String get confirmRemoveDownloadJob => 'Távolítsa el ezt a letöltést, és törölje a részben letöltött adatokat?';
}

// Path: lending
class _Translations$lending$hu extends Translations$lending$en {
	_Translations$lending$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Közös könyvtárak';
	@override String get add => 'Hozzáadjuk a könyvtárat';
	@override String get other => 'Egy másik könyvtár';
	@override String get libraryName => 'Könyvtár neve';
	@override String get libraryUrl => 'Könyvtár honlapja';
	@override String get libraryUrlHint => 'Használja a könyvtár katalógusát vagy a bejelentkezési oldalt.';
	@override String get intro => 'Hitelezzen a könyvtárból, tartsa a könyveit.';
	@override String get handoff => 'Jelentkezzen be, kölcsönözze és olvassa biztonságosan a könyvtár saját szolgáltatásaival.';
	@override String get openService => 'Nyílt könyvtár';
	@override String get findLibrary => 'Keresse meg a könyvtárat';
	@override String get search => 'Könyvek és szerzők keresése';
	@override String get catalogue => 'Katalógus';
	@override String get loans => 'kölcsönök';
	@override String get holds => 'Előjegyzések';
	@override String get signIn => 'Jelentkezzen be a könyvtárával';
	@override String get waiting => 'Véget ért a regisztráció a böngészőben, majd térj vissza ide.';
	@override String get cancel => 'Mégse';
	@override String get disconnect => 'Könyvtár eltávolítása';
	@override String get disconnectMessage => 'Eltávolítod ezt a könyvtárat ebből a profilból? A kölcsönzéseid és előjegyzéseid megmaradnak a könyvtárnál.';
	@override String get getBook => 'Könyvet kap';
	@override String get checkAvailability => 'Ellenőrizze a rendelkezésre állást';
	@override String get available => 'Elérhető kölcsönzéshez';
	@override String get unavailable => 'Jelenleg nem elérhető';
	@override String get borrow => 'Kölcsönzés';
	@override String get placeHold => 'Előjegyzés';
	@override String get returnBook => 'Korai visszatérés';
	@override String get cancelHold => 'Előjegyzés törlése';
	@override String get confirmBorrow => 'Ezt a címet kölcsönözzétek a könyvtárból?';
	@override String get confirmReturn => 'Vissza kell adnia ezt a címet most? lehet, hogy újra kölcsönözni, hogy folytassa.';
	@override String get confirmCancelHold => 'Törlöd a címre vonatkozó előjegyzésedet?';
	@override String get email => 'Hajtsa az értesítést e-mail';
	@override String due({required Object date}) => 'Személyi ${date}';
	@override String queue({required Object position}) => '${position} pozíció a sorban';
	@override String get empty => 'Még nincs címünk itt.';
	@override String get openLibraryNote => 'Fedezze fel a nyílt könyvtár katalógusát.Az olvasási és hitelezési lehetőségek az egyes címek oldalán jelennek meg.';
	@override String get more => 'Töltse tovább';
	@override String get gateway => 'Könyvtár beiratkozás szolgáltatás';
	@override String get gatewayHint => 'A könyvtár vagy a PlezyNG adminisztrátor által biztosított.';
	@override String get advanced => 'Könyvtár integráció';
	@override String get loadLibraries => 'Válassza ki a könyvtárát';
	@override String get expired => 'Ez a hitel lejár.';
	@override String get updated => 'Könyvtár frissítés';
	@override String get continueService => 'Folytatjuk a szolgálatot';
	@override String get comingSoon => 'In-app kölcsönzés · Jön hamarosan';
	@override String get comingSoonDescription => 'A Libby integráció a maga módján van.A Libby könyvtárát használhatja, miközben befejezzük a kapcsolatot.';
	@override String get suspendHold => 'Megszakított tartás';
	@override String get resumeHold => 'Összefoglaló tartsa';
	@override String get suspendMessage => 'Megtartod a helyedet a sorban, és átengeded ezt a példányt a következő olvasónak? Az előjegyzést később folytathatod.';
	@override String get resumeMessage => 'Folytatod ezt az előjegyzést, hogy a könyvtár felajánlhassa a következő elérhető példányt?';
	@override String get editEmail => 'Változtassuk meg az értesítés e-mail';
}

// Path: audiobook
class _Translations$audiobook$hu extends Translations$audiobook$en {
	_Translations$audiobook$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'olvasás és hallgatás szinkronizálás';
	@override String get syncHelp => 'Tartsa az olvasási pozíciókat, a hallgatási pozíciókat, a befejezési állapotot, a könyvjelzőket és a jegyzeteket az eszközökön keresztül. Válasszon egy hozzáadott tárolási fiókot, és használja ugyanazt a szinkron kódot minden eszközön. Az olvasás és a hallgatás külön marad.';
	@override String get addSyncSource => 'Add hozzá a Google Drive, OneDrive, Dropbox, WebDAV vagy S3 a Fájlok és könyvek először.';
	@override String get syncDestination => 'Sync tárolási számla';
	@override String get syncFolder => 'Szinkronizálódás vagy prefix';
	@override String get syncFolderHelp => 'Használjon egy külön meglévő mappát a WebDAV forráson belül, vagy egy dedikált S3 előfizetést.';
	@override String get syncCode => 'Magánszinkron kód';
	@override String get syncCodeHelp => 'Hozzon létre egy kódot az első eszközön, majd adja meg azt a kódot a többi eszközön. tartsa magán másolatot: ez a kulcs a titkosított állapot. Használjon egy másik kódot minden egyes személy számára.';
	@override String get showCode => 'Megmutatja vagy elrejti a szinkron kódot';
	@override String get newSyncCode => 'Hozzon létre egy új szinkron kódot';
	@override String get saveSync => 'Megtakarítás és szinkronizálás';
	@override String get disableSync => 'Távolítsa el a szinkronizálást ezen a készüléken';
	@override String get syncSourceDisconnect => 'Ez a forrás eltávolítása kikapcsolja az olvasást és a hallgatást a szinkronizálás itt. titkosított szinkronizált fájlok maradnak a szolgáltató.';
	@override String get syncReconnect => 'Újra összekapcsolja a tárolási fiókot';
	@override String lastSynced({required Object time}) => 'Legutóbb szinkronizált a ${time}';
	@override String get syncPrivacy => 'Csak titkosított előrehaladást és jegyzeteket tárolnak. Audio és ebook fájlokat, fiók tokeneket és jelszavakat nem töltik fel. A Google Drive és a OneDrive alkalmazás tárolását használja; a Dropbox PlezyNG Szinkronizálást használ. A szinkronizálás lehetővé tétele további írásos hozzáférést igényelhet. Amíg aktiválódik, ez a cél a progress szinkronizálást birtokolja; a szerver előrehaladása elválasztva marad. A szinkronizálást törölve tartja a helyi történetet és a távoli állapotot.';
	@override String get syncConflicts => 'Válassza ki, hol kell újra';
	@override String get conflictHelp => 'Ezek a változások önállóan történtek. Válassza ki a pozíciót vagy a betűtípus verzióját, hogy tartsa. A későbbi időzítés vagy a magasabb arány automatikusan nem nyer.';
	@override String syncDevice({required Object device}) => 'készülék ${device}';
	@override String get syncUnknownDevice => 'Ismeretlen eszközök';
	@override String get deletedBookmark => 'Eltávolított könyvjelző';
	@override String get finished => 'befejezett';
	@override String readingPosition({required Object percent}) => 'Olvasás · ${percent}%';
	@override String get chapterTimeline => 'fejezet előrehaladás';
	@override String get bookTimeline => 'Az egész könyv előrehaladása';
	@override String bookRemaining({required Object time}) => 'Idő marad ebben a könyvben: ${time}';
	@override String chapterRemaining({required Object time}) => 'Idő marad ebben a fejezetben: ${time}';
	@override String get unknownRemaining => 'Teljes rendelkezésre álló idő, mivel a részeket játszanak';
	@override String get undoSeek => 'Utolsó keresés';
	@override String get customSpeed => 'Custom playback sebesség';
	@override String get speedHelp => 'Válasszon egy sebességet 0,25× és 4× között.';
	@override String get apply => 'alkalmazás';
	@override String get customSleep => 'Alvási időszámítás';
	@override String get sleepMinutes => 'percek (1–1440)';
	@override String sleepChapters({required Object count}) => '${count} fejezetek után';
	@override String get extendSleep => 'Add hozzá 5 percet';
	@override String sleepRemaining({required Object time}) => 'Alvás időzítő: ${time}';
	@override String get useDefaults => 'Használja ezeket a hallgatási vezérlőket az új könyvekhez';
	@override String get librarySort => 'Színes könyvek';
	@override String get sortTitle => 'címek';
	@override String get sortAuthor => 'Szerző';
	@override String get sortNarrator => 'Történész';
	@override String get sortSeries => 'sorozatrendelés';
	@override String get sortRecent => 'Nemrégiben megnyitott';
	@override String get statusFilter => 'Olvasási állapot';
	@override String get statusAll => 'Minden könyv';
	@override String get statusNew => 'Nem kezdődött';
	@override String get statusProgress => 'előrehaladás';
	@override String get statusFinished => 'befejezett';
	@override String get goToTime => 'Menj az időbe';
	@override String get timeHelp => 'Idők: percek: másodpercek, vagy percek: másodpercek';
	@override String get recoveryHelp => 'A szinkronizációs adatok áthelyezése vagy javítása előtt exportáljon egy nemrégiben titkosított másolatot. Az importok összeolvadnak a jelenlegi állapotgal; soha nem helyettesítik a helyi szinkrálás történetét.';
	@override String get recoveryExport => 'Export titkosított helyreállítási fájl';
	@override String get recoveryImport => 'Import titkosított helyreállítási fájl';
	@override String get recoveryImportConfirm => 'Ez a titkosított helyreállítási fájl összekapcsolja az aktuális olvasási pozíciókkal és jegyzetekkel? A meglévő történelem megmarad. Megosztott könyvtár és elem azonosítók nem szerepelnek; beállítja az egyes eszközök megfelelő azonosítóját az import előtt.';
	@override String get recoveryExported => 'A titkosított helyreállítási fájl mentett.';
	@override String get recoveryImported => 'A helyreállítási adatok összegyűltek.';
}

// Path: sourceSetup
class _Translations$sourceSetup$hu extends Translations$sourceSetup$en {
	_Translations$sourceSetup$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Mentett szervertanúsítvány';
	@override String get nfsEndpointInvalid => 'Adj meg egy NFS URL-t, például: nfs://nas:2049/export.';
	@override String get dlnaNone => 'Nem található DLNA-kiszolgáló. Add meg kézzel az eszközleírás URL-jét.';
	@override String get dlnaServers => 'DLNA-médiakiszolgálók';
	@override String get dlnaUnavailable => 'A DLNA-felderítés ezen a hálózaton nem érhető el. Add meg kézzel az eszközleírás URL-jét.';
	@override String get dlnaSearching => 'DLNA-kiszolgálók keresése a helyi hálózaton';
	@override String get networkSearching => 'Keresés a helyi hálózaton…';
	@override String get dlnaDiscover => 'DLNA-kiszolgálók felderítése';
	@override String get dlnaHelp => 'A felderítés a helyi hálózat multicast-forgalmától függ. Ha nem jelenik meg kiszolgáló, add meg fent az eszközleírásának URL-jét.';
	@override String get dlnaRoot => 'DLNA-objektumazonosító; üresen hagyva az eszköz gyökerét használja.';
	@override String get passwordOrKey => 'Adj meg egy jelszót, vagy adj hozzá lent egy privát kulcsot.';
	@override String get sshFingerprint => 'Az SSH-gépkulcs SHA256-ujjlenyomata';
	@override String get sshFingerprintHelp => 'Ellenőrizd a szerver rendszergazdájával. A szerveren futtasd az ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub parancsot, és használd az SHA256-értékét.';
	@override String get sshFingerprintKeep => 'Hagyd üresen a jelenleg rögzített ujjlenyomat megőrzéséhez, vagy adj meg új szerverujjlenyomatot.';
	@override String get sshAuthentication => 'SSH-hitelesítés nyilvános kulccsal';
	@override String get sshAuthenticationHelp => 'Nem kötelező; a jelszavas hitelesítés is támogatott.';
	@override String get privateKey => 'Privát kulcs (PEM- vagy OpenSSH-formátum)';
	@override String get privateKeyPassphrase => 'A privát kulcs jelmondata';
	@override String get nfsMountPort => 'Az NFS-csatolási szolgáltatás TCP-portja';
	@override String get nfsMountPortHelp => 'Alapértelmezett: 20048';
	@override String get nfsUserId => 'NFS-felhasználóazonosító (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Alapértelmezett: 1000. A NAS NFS-megosztása által engedélyezett azonosítót használd.';
	@override String get nfsGroupId => 'NFS-csoportazonosító (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Alapértelmezett: 1000. A NAS NFS-megosztása által engedélyezett csoportazonosítót használd.';
	@override String get nfsEncryption => 'Titkosított NFS megkövetelése (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'TLS 1.3 megkövetelése az NFS-hez és a csatolási szolgáltatáshoz. Ha a NAS ezt nem támogatja, a kapcsolat nem jön létre.';
	@override String get nfsTrustCertificate => 'Egyéni NFS CA vagy szervertanúsítvány (PEM, nem kötelező)';
	@override String get nfsTrustHelp => 'Hagyd üresen az eszköz által megbízhatónak tartott tanúsítványokhoz. Szükség esetén adj hozzá privát CA-tanúsítványt vagy önaláírt szervertanúsítványt; a benne szereplő neveknek egyezniük kell az NFS URL gépnevével.';
	@override String get nfsTrustInvalid => 'PEM-formátumú CA- vagy szervertanúsítványt használj. Ne adj meg privát kulcsot.';
	@override String get addTrustCertificate => 'Egyéni megbízható tanúsítvány hozzáadása';
	@override String get replaceTrustCertificate => 'Mentett egyéni tanúsítvány cseréje';
	@override String get nfsTlsHelp => 'Az RPC-with-TLS a szokásos NFS- és csatolásiszolgáltatás-portokat használja, és RFC 9289-támogatást igényel a NAS-on. TLS 1.3 szükséges. A gépnévnek vagy IP-címnek egyeznie kell a tanúsítvánnyal. Az AUTH_SYS UID/GID a titkosított csatornán belül is érvényes.';
	@override String get clientCertificate => 'Kliens tanúsítványa (nem kötelező)';
	@override String get clientCertificateHelp => 'Lehetővé teszi, hogy a NAS hitelesítse ezt a klienst; az AUTH_SYS-azonosítók továbbra is a NAS NFS-megosztásának szabályaitól függenek.';
	@override String get savedIdentity => 'A mentett kliensazonosság lesz használva.';
	@override String get replaceIdentity => 'Mentett kliensazonosság cseréje';
	@override String get chooseIdentity => 'PKCS#12-kliensazonosság kiválasztása';
	@override String get identityPassphrase => 'A kliensazonosság jelmondata';
	@override String get identityPassphraseHelp => 'Hagyd üresen, ha a fájlnak nincs jelmondata.';
	@override String get removeIdentity => 'Mentett kliensazonosság eltávolítása';
	@override String get identityStorageHelp => 'A kliensazonosságok a forrás titkosított hitelesítőadat-tárába kerülnek. A mentett azonosság megőrzéséhez hagyd változatlanul ezt a részt.';
	@override String get nfsLimitations => 'Csak olvasható NFSv3 TCP felett. RPC-with-TLS nélkül az NFS-forgalom titkosítatlan. A NAS-nak engedélyeznie kell a választott AUTH_SYS-azonosítókat és a nem privilegizált kliensportokat (ez gyakran az „insecure” exportbeállítás). Az NFSv4 és az UDP nem támogatott.';
	@override String get nfsSetupHelp => 'NFS-beállítási súgó';
	@override String get nfsSetupHint => 'Ellenőrizd ezeket a beállításokat, ha nem jön létre a kapcsolat.';
	@override String get nfsSetupDetails => 'NFSv3-megosztást használj TCP felett. Ha titkosítás szükséges, az NFS- és a csatolási szolgáltatásnak is támogatnia kell az RPC-with-TLS-t. Hagyd üresen az egyéni tanúsítványt az eszköz által megbízhatónak tartott szervertanúsítványhoz, vagy add hozzá a NAS CA-tanúsítványát vagy önaláírt tanúsítványát. A tanúsítványban lévő névnek egyeznie kell a végpont gépnevével. Ha a NAS kölcsönös TLS-hitelesítést kér, add hozzá a PKCS#12-kliensazonosságát. Végül ellenőrizd, hogy a megosztás engedélyezi-e a beállított AUTH_SYS UID/GID értékeket és a kliensportokra vonatkozó szabályokat.';
	@override String get ftpHelp => 'Az FTP passzív módot használ. Titkosítatlan FTP-hez ftp://, explicit TLS-hez ftpes://, TLS-hez pedig ftps:// használható (a 990-es porton implicit, más portokon explicit).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Opcionális feliratkeresés önálló videókhoz.';
	@override String get apiKey => 'API-kulcs';
	@override String get optionalUsername => 'A fiók felhasználóneve (nem kötelező)';
	@override String get optionalPassword => 'A fiók jelszava (nem kötelező)';
	@override String get subtitlePrivacy => 'Szerezz API-kulcsot az opensubtitles.com oldalon. A keresés a videó címét és az elérhető IMDb/TMDB-azonosítókat küldi el, a videófájlt soha. A kulcs és az opcionális fiókhitelesítő adatok ezzel a forrással együtt titkosítva tárolódnak.';
	@override String get automaticMetadata => 'Automatikus online videómetaadatok';
	@override String get metadataPrivacy => 'Csak a fájlnévből származó címet/évet és epizódszámokat vagy egy NFO-azonosítót küld el, médiát vagy hitelesítő adatokat soha. Az NFO-mezők elsőbbsége megmarad.';
	@override String get nfsEncryptionFailure => 'Titkosított NFS esetén ellenőrizd az RFC 9289 és a TLS 1.3 támogatását mindkét NAS-szolgáltatásnál, a tanúsítvány nevét és a megosztás UID/GID értékeit. A PlezyNG nem próbálja újra ezt a kapcsolatot titkosítás nélkül.';
	@override String get sourceConnecting => 'Kapcsolódás a forráshoz';
	@override String get metadataSearchPrivacy => 'Ez a címkeresés a Trakthoz kerül. A megadott címet küldi el, nem a videót vagy a forrás hitelesítő adatait.';
	@override String get chooseMatch => 'Találat kiválasztása';
	@override String get metadataMatchHelp => 'Választás előtt ellenőrizd a címet és az évet. A Trakt a keresett címet kapja meg; a videó a forrásán marad.';
	@override String get metadataNoMatches => 'Nem található egyező cím online. Próbálj másik címet.';
	@override String get metadataSearch => 'Online metaadatok keresése';
	@override String get metadataLoading => 'Filmek és sorozatok adatainak keresése online…';
	@override String get metadataFromTrakt => 'Online metaadatok a Trakttól';
	@override String get metadataNoAutomaticMatch => 'Nem található automatikus címegyezés. Keress rá a címre a találat kiválasztásához.';
	@override String get metadataFailed => 'Az online metaadatok nem tölthetők be. A lejátszás és a helyi adatok továbbra is elérhetők.';
	@override String get videoDetailsLoading => 'Videóadatok betöltése';
	@override String get subtitleKeyRequired => 'OpenSubtitles-API-kulcs szükséges';
	@override String get subtitleKeyHelp => 'Szerkeszd ezt a fájlforrást, és adj hozzá OpenSubtitles-API-kulcsot az opcionális feliratbeállításoknál.';
	@override String get subtitleSearchFailed => 'A feliratkeresés sikertelen. Ellenőrizd az API-kulcsot, a kapcsolatot és a szolgáltatás elérhetőségét.';
	@override String get subtitleApplyFailed => 'A felirat nem tölthető le vagy nem alkalmazható. Ellenőrizd a kapcsolatot, és próbálj másik találatot.';
	@override String get subtitleSearch => 'Keresés az OpenSubtitles oldalán';
	@override String get subtitleSearchPrivacy => 'A keresés a címet és az elérhető IMDb/TMDB-azonosítókat használja. A videófájl a forrásán marad. Választás előtt ellenőrizd a nyelvet, a kényszerített vagy hallássérülteknek készült felirat jelölését és az értékelést.';
	@override String get movieOrShow => 'Film vagy sorozat';
	@override String get subtitleTitleHint => 'Adj meg címet a találatok pontosításához';
	@override String get subtitleLanguage => 'Felirat nyelve';
	@override String get subtitleSearching => 'Keresés az OpenSubtitles oldalán';
	@override String get subtitleNoMatches => 'Nem található megfelelő felirat. Próbálj másik címet vagy nyelvet.';
	@override String get downloadSubtitle => 'Felirat letöltése';
	@override String get subtitle => 'Felirat';
	@override String get nfsTlsRequired => 'RPC-with-TLS szükséges';
	@override String get nfsUnencrypted => 'Titkosítatlan NFS';
	@override String get tlsEncrypted => 'TLS-titkosítás';
	@override String get ftpPlain => 'Titkosítatlan FTP';
	@override String get sshPinned => 'Titkosított SSH · rögzített gépkulcs';
	@override String get smbEncrypted => 'SMB3-titkosítás bekapcsolva';
	@override String get smbUnencrypted => 'SMB3-titkosítás kikapcsolva';
	@override String get httpUnencrypted => 'HTTP átviteli titkosítás nélkül';
	@override String get checkEndpointSecurity => 'Végpont biztonságának ellenőrzése';
	@override String fieldRequired({required Object label}) => 'Kötelező mező: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'A(z) ${label} értéke ${min} és ${max} között legyen.';
	@override String replaceFile({required Object name}) => '${name} cseréje';
	@override String selectedIdentity({required Object name}) => 'Kiválasztott kliensazonosság: ${name}';
	@override String subtitleRating({required Object rating}) => 'Értékelés: ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Felirat letöltése: ${title}';
	@override String get sharedEntryPair => 'Csatlakozzon ehhez az elemhez';
	@override String get sharedEntryPairHelp => 'Írja be ugyanazt az azonosítót erre az elemre minden eszközön. Használjon stabil megosztott azonosítóját vagy hozzon létre egyet, és másolja azt a megfelelõ elemre. A progress párosul csak akkor, ha a kiadvány fájl típusa, mérete és rendje megfelel. Blank eltávolítja ezt a mappázást.';
	@override String get sharedEntryId => 'Megosztott elem ID';
	@override String get generateSharedEntryId => 'Megosztott elem ID generálása';
	@override String get sharedLibraryId => 'Megosztott könyvtár azonosító (opcionális)';
	@override String get sharedLibraryHelp => 'Használja ugyanazt az ID-t olyan eszközökön, amelyek ugyanezt a könyvtárat nyitják meg. Ez a nyilvános ID segít olvasási előrehaladást és jegyzeteket tartani különböző forráskódú kapcsolatokon keresztül; ez nem jelszó. Amikor a szolgáltatók különböző elemek azonosítóját használják, azokat a részletes képernyőktől párolják.';
	@override String get sharedLibraryInvalid => 'Használjon 8–100 betűt, számot, pontokat, alszámokat vagy hyphenseket.';
	@override String get generateSharedLibraryId => 'Egy megosztott könyvtár azonosító létrehozása';
	@override String get nfsReadAhead => 'NFS olvasási kérelmek';
	@override String get nfsReadAheadHelp => 'Több párhuzamos olvasás javíthatja a gyors NAS vagy hálózati átjárót. Használjon 1 ha a szerver korlátozza az egymást követő kéréseket.';
	@override String get nfsReadTest => 'NFS olvasási teljesítmény mérése';
	@override String get nfsReadTestHelp => 'A legnagyobb fájltól 64 MiB-ig olvasható, hogy mérje ezt a NAS kapcsolatot.';
	@override String get nfsQualificationResult => 'NFS olvasás mérés';
	@override String get nfsReadBytes => 'Az adatok olvasása';
	@override String get nfsReadSpeed => 'Mérhető sebesség';
	@override String get nfsReadRequests => 'Olvassa el a kéréseket';
	@override String get sharedEntryConflict => 'Ez a megosztott elem azonosító már párosított egy másik elem ebben a könyvtárban.';
}

// Path: comics
class _Translations$comics$hu extends Translations$comics$en {
	_Translations$comics$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Magassághoz igazítás';
	@override String get readingMode => 'Olvasási mód';
	@override String get paged => 'Oldalak';
	@override String get webtoon => 'Folyamatos görgetés';
	@override String get coverAlone => 'Borító külön megjelenítése';
	@override String get splitWide => 'Széles oldalak felosztása';
	@override String get splitWideHelp => 'A két felet külön, olvasási sorrendben jeleníti meg. Bekapcsolva az oldalpárok megjelenítése szünetel.';
	@override String get thumbnails => 'Oldalak bélyegképei';
	@override String get controlsHelp => 'Lapozáshoz húzza el az ujját. Az igazítás módosításához koppintson duplán. Folyamatos görgetésnél húzza függőlegesen, vagy használja a Page Up és Page Down billentyűket.';
	@override String get savedForComic => 'A megjelenítési beállításokat ez a profil megjegyzi ehhez a képregényhez.';
	@override String get readLists => 'Olvasási listák';
	@override String get collections => 'Gyűjtemények';
}

// Path: games
class _Translations$games$hu extends Translations$games$en {
	_Translations$games$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get subtitle => 'Your games, from your computers.';
	@override String get computers => 'Your computers';
	@override String get nearby => 'Nearby computers';
	@override String get findComputers => 'Find computers';
	@override String get addComputer => 'Add computer';
	@override String get scanHint => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.';
	@override String get empty => 'Add your gaming computer to get started.';
	@override String get noNearby => 'No computers found on this network. You can enter an address manually.';
	@override String get name => 'Computer name';
	@override String get address => 'IP address or hostname';
	@override String get port => 'Service port';
	@override String get protocol => 'Streaming service';
	@override String get moonlight => 'Sunshine / Moonlight';
	@override String get steam => 'Steam Remote Play';
	@override String get save => 'Save computer';
	@override String get invalidAddress => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.';
	@override String get pair => 'Connect computer';
	@override String get pairTitle => 'Approve this device';
	@override String get pairInstructions => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.';
	@override String get pairHelp => 'Connect this computer again to approve or renew pairing.';
	@override String get openPairingPage => 'Open Sunshine PIN page';
	@override String get qrHelp => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.';
	@override String get refreshGames => 'Refresh games';
	@override String get play => 'Play';
	@override String get favorites => 'Favorites';
	@override String get allGames => 'All games';
	@override String get search => 'Find a game';
	@override String get noMatches => 'No games match this search.';
	@override String get favorite => 'Save favorite';
	@override String get unfavorite => 'Remove favorite';
	@override String get forget => 'Forget computer';
	@override String get forgetDescription => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.';
	@override String get unavailable => 'The connection could not complete. Check that the computer is awake and paired, then try again.';
	@override String get timeout => 'Connection timed out. Check the computer, pairing code and network before trying again.';
	@override String get libraryHint => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.';
	@override String get touchControls => 'On-screen controller';
	@override String get touchDescription => 'Show the on-screen controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
	@override String get touchSetup => 'On-screen controls';
	@override String get touchSetupHint => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.';
	@override String get addGame => 'Add game shortcut';
	@override String get gameName => 'Game name';
	@override String get gameId => 'Host application ID';
	@override String get invalidGame => 'Enter a game name and a positive numeric host application ID.';
	@override String get wake => 'Wake computer';
	@override String get wakeSent => 'Wake request sent. The computer must support Wake-on-LAN on this network.';
	@override String get mac => 'MAC address (optional)';
	@override String get help => 'Games help';
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Steam can open Big Picture or launch a saved game shortcut inside PlezyNG on receivers that support it. Connect Companion Remote to combine installed games from your computers in one library. Steam pairing does not grant access to a private account library.\n\nSteam receivers are experimental on Android, Linux and Apple. The stream menu provides controller, audio and connection controls. Pyrowave is an optional codec on compatible Android and Apple receivers and needs a fast network.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include an embedded Steam receiver for this device. You can browse your library and manage computers. Playing here requires a build with a compatible receiver.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
}

// Path: deepLinks
class _Translations$deepLinks$hu extends Translations$deepLinks$en {
	_Translations$deepLinks$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Ez a Plezy link nem érvényes.';
	@override String profileNotFound({required Object profile}) => 'Nincs profil a "${profile}" címmel.';
	@override String get serverUnavailable => 'Nem tudtam elérni a szervert erre a linkre.';
	@override String get notFound => 'Nem találtam ezt a címet a könyvtárakban.';
	@override String get unsupportedItem => 'Ezt a linket nem lehet játszani.';
	@override String get noLiveTv => 'Nincs Live TV szerver elérhető ezen a linken.';
	@override String channelNotFound({required Object channel}) => 'Nem találták meg a "${channel}" csatornát.';
	@override String get showLink => 'Show linkek';
	@override String get showProfileLink => 'Profil link megjelenítése';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'A link megnyitása a következő epizódot játssza. Add &mode=shuffle to play the show on shuffle.';
	@override String get movieHint => 'A link megnyitása a filmet játssza.';
	@override String get episodeHint => 'A link megnyitása ezt az epizódot játssza.';
	@override String get profileHint => 'A link megnyitása váltja át ezt a profilot.';
	@override String openAsProfile({required Object name}) => 'Nyissa meg, mint ${name}';
	@override String get copy => 'másolás';
	@override String get copied => 'Link másolat';
}

// Path: householdSetup
class _Translations$householdSetup$hu extends Translations$householdSetup$en {
	_Translations$householdSetup$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Háztartás beállítása';
}

// Path: issueReport
class _Translations$issueReport$hu extends Translations$issueReport$en {
	_Translations$issueReport$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hiba jelentése';
	@override String get instructions => 'Olvasd be a QR-kódot az előre kitöltött GitHub-vázlat megnyitásához. Ellenőrizd, és csak akkor küldd el, ha készen állsz.';
	@override String get privacy => 'A vázlat az alkalmazás verzióját, a platformot és a kapcsolatok számát tartalmazza. Nem tartalmaz szervercímeket, fiók- vagy profilneveket, médiacímeket és fájlútvonalakat.';
	@override String get logPrivacy => 'A naplók megadása nem kötelező. Feltöltés előtt nézd át őket. Az azonosítójuk bekerülhet a nyilvános vázlatba.';
	@override String get openDraft => 'GitHub-vázlat megnyitása';
}

// Path: appIcon.names
class _Translations$appIcon$names$hu extends Translations$appIcon$names$en {
	_Translations$appIcon$names$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Éjfél';
	@override String get ember => 'Parázs';
	@override String get paper => 'Papír';
	@override String get oled => 'OLED';
	@override String get line => 'Vonal';
	@override String get ocean => 'Óceán';
	@override String get ultraviolet => 'Ultraibolya';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Naplemente';
	@override String get gold => 'Arany';
	@override String get titanium => 'Titán';
	@override String get glass => 'Üveg';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Matrica';
	@override String get ticket => 'Jegy';
	@override String get pop => 'Pop';
	@override String get strata => 'Rétegek';
	@override String get facet => 'Fazetta';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$hu extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Critics';
	@override String get audience => 'Audience';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes critics';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes audience';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$hu extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Sorozat';
	@override String get season => 'Évad';
	@override String get episode => 'Epizód';
	@override String get artist => 'Előadó';
	@override String get album => 'Album';
	@override String get track => 'Szám';
	@override String get collection => 'Gyűjtemény';
	@override String get playlist => 'Lejátszási lista';
	@override String get clip => 'Klip';
	@override String get photo => 'Fénykép';
	@override String get folder => 'Mappa';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$hu extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Nyissa meg az ajánlásokat és a kapcsolódó felfedezési forrásokból származó elemeket.';
	@override String get libraries => 'Nyissa meg a kapcsolódó média könyvtárakat.';
	@override String get liveTv => 'Nyissa meg a Live TV-t, amikor egy szerver biztosítja azt; különben a startup visszatér a Házba.';
	@override String get search => 'Nyílt média keresés.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$hu extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Háttér';
	@override String get surface => 'Felület';
	@override String get outline => 'Körvonal';
	@override String get text => 'Szöveg';
	@override String get textMuted => 'Másodlagos szöveg';
	@override String get accent => 'Kiemelőszín';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$hu extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Szöveg a háttéren';
	@override String get textOnSurface => 'Szöveg a felületen';
	@override String get textMutedOnBg => 'Másodlagos szöveg a háttéren';
	@override String get textMutedOnSurface => 'Másodlagos szöveg a felületen';
	@override String get accentOnBg => 'Kiemelőszín a háttéren';
	@override String get accentOnSurface => 'Kiemelőszín a felületen';
	@override String get labelOnAccent => 'Gombfelirat a kiemelőszínen';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$hu extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Lejátszás/Szünet';
	@override String get volumeUp => 'Hangerő fel';
	@override String get volumeDown => 'Hangerő le';
	@override String seekForward({required Object seconds}) => 'Tekerés előre (${seconds} mp)';
	@override String seekBackward({required Object seconds}) => 'Tekerés hátra (${seconds} mp)';
	@override String get fullscreenToggle => 'Teljes képernyős mód váltása';
	@override String get muteToggle => 'Némítás be- és kikapcsolása';
	@override String get subtitleToggle => 'Feliratok be- és kikapcsolása';
	@override String get audioTrackNext => 'Következő hangsáv';
	@override String get subtitleTrackNext => 'Következő feliratsáv';
	@override String get chapterNext => 'Következő fejezet';
	@override String get chapterPrevious => 'Előző fejezet';
	@override String get episodeNext => 'Következő epizód';
	@override String get episodePrevious => 'Előző epizód';
	@override String get speedIncrease => 'Sebesség növelése';
	@override String get speedDecrease => 'Sebesség csökkentése';
	@override String get speedReset => 'Sebesség alaphelyzetbe állítása';
	@override String get zoomIn => 'Nagyítás';
	@override String get zoomOut => 'Kicsinyítés';
	@override String get zoomReset => 'Nagyítás alaphelyzetbe állítása';
	@override String get subSeekNext => 'Ugrás a következő feliratra';
	@override String get subSeekPrev => 'Ugrás az előző feliratra';
	@override String get subtitleDelayIncrease => 'Feliratok késleltetése';
	@override String get subtitleDelayDecrease => 'Feliratok előrehozása';
	@override String get shaderToggle => 'Shaderek be- és kikapcsolása';
	@override String get skipMarker => 'Intró/stáblista átugrása';
	@override String get screenshot => 'Képernyőkép készítése';
	@override String get framePrevious => 'Előző Frame';
	@override String get frameNext => 'Következő Frame';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$hu extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Android 8.0 vagy újabb szükséges';
	@override String get iosVersion => 'iOS 15.0 vagy újabb szükséges';
	@override String get permissionDisabled => 'A kép a képben mód le van tiltva. Engedélyezd a rendszerbeállításokban.';
	@override String get notSupported => 'Az eszköz nem támogatja a kép a képben módot';
	@override String get voSwitchFailed => 'Nem sikerült átváltani a videókimenetet a kép a képben módhoz';
	@override String get failed => 'Nem sikerült elindítani a kép a képben módot';
	@override String get prepareFailed => 'Nem sikerült előkészíteni a kép a képben módot';
	@override String unknown({required Object error}) => 'Hiba történt: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$hu extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get no => 'Tartsa a betűtípusokat, színeket, méreteket és elhelyezkedést az alszámfájlban.';
	@override String get yes => 'Engedje meg a játékos szubtitkár stílusának beállításait, hogy igazítsa az ASS szubtiteleket.';
	@override String get scale => 'Alkalmazza a játékos stílusát és a beágyazott méreteket, hogy megfeleljen a videó dimenzióknak.';
	@override String get force => 'A beágyazott ASS stílusok helyettesítése a játékos szubtitlap stílusával.';
	@override String get strip => 'Távolítsa el a beágyazott ASS formázást, és egyértelművé tegye az alszöveg szöveget.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$hu extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render a teljes kijelző felületfelbontáson a legsűrűbb eredmény érdekében.';
	@override String get video => 'A videó felbontását a referenciaként használja, ami csökkenti a nagy hatékonyságú kijelzők munkáját.';
	@override String get threeQuarter => 'A képernyőfelület felbontásának 75% -a a mérsékelt teljesítménymegtakarítás érdekében.';
	@override String get half => 'A képernyő felületfelbontásának 50% -ára csökkenti a munkát, vékonyabb szélességekkel.';
	@override String get third => 'A kijelző felszíni felbontásának egyharmada a munka csökkentése érdekében, vékonyabb szélességekkel.';
	@override String get quarter => 'A képernyő felszíni felbontásának egyharmada a munka csökkentése érdekében, a legszélesebb eredményt.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$hu extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Hang és feliratok';
	@override String get libraryDisplay => 'Könyvtár';
	@override String get personalMedia => 'Személyes média';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$hu extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get none => 'Kézzel kiválasztva';
	@override String get noneDescription => 'Soha ne kapcsolja be magától a feliratokat.';
	@override String get defaultMode => 'A sáv jelzőinek követése';
	@override String get defaultModeDescription => 'Az egyes feliratsávokon tárolt alapértelmezett és kényszerített jelzők használata.';
	@override String get always => 'Mindig engedélyezve';
	@override String get alwaysDescription => 'Feliratsáv bekapcsolása az elsődleges nyelven, ha van ilyen.';
	@override String get onlyForced => 'Csak kényszerített feliratok';
	@override String get onlyForcedDescription => 'Csak a kényszerítettként megjelölt sávok betöltése.';
	@override String get smart => 'Idegen nyelvű hang esetén megjelenítve';
	@override String get smartDescription => 'Feliratok bekapcsolása csak akkor, ha a hang más nyelven szól.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$hu extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Nem SDH-feliratok előnyben részesítése';
	@override String get preferSdh => 'SDH-feliratok előnyben részesítése';
	@override String get onlySdh => 'Csak SDH-feliratok';
	@override String get onlyNonSdh => 'Csak nem SDH-feliratok';
	@override String get preferNonSdhDescription => 'Előnyben részesíti a szabványos alfejezeteket, amikor mind a standard, mind az SDH verziók állnak rendelkezésre.';
	@override String get preferSdhDescription => 'Előnyben részesíti az SDH altitkákat, amikor rendelkezésre állnak, de lehetővé teszi a szabványos altitkok visszavonulását.';
	@override String get onlySdhDescription => 'Csak SDH altitkok használata; ne térjen vissza a szabványos altitkákhoz.';
	@override String get onlyNonSdhDescription => 'Csak szabványos altitkok használata; kizárja az SDH altitkokat.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$hu extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Nem kényszerített feliratok előnyben részesítése';
	@override String get preferForced => 'Kényszerített feliratok előnyben részesítése';
	@override String get onlyForced => 'Csak kényszerített feliratok';
	@override String get onlyNonForced => 'Csak nem kényszerített feliratok';
	@override String get preferNonForcedDescription => 'Előnyben részesíti a rendszeres altitkok, de lehetővé teszi a kényszerített nyomokat, mint egy visszafelé.';
	@override String get preferForcedDescription => 'Előnyben részesítik a kényszerített pályákat, amikor rendelkezésre állnak, de lehetővé teszik a rendszeres altitkok visszavonulását.';
	@override String get onlyForcedDescription => 'Használjon csak nyomokat, amelyeket kényszerként jelöltek ki.';
	@override String get onlyNonForcedDescription => 'Kizárják a nyomokat, amelyeket kényszerítőként jelölnek ki.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$hu extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get none => 'Soha';
	@override String get moviesAndShows => 'Filmek és TV-sorozatok';
	@override String get movies => 'Csak filmek';
	@override String get shows => 'Csak TV-sorozatok';
	@override String get noneDescription => 'Ne mutassa meg a megfigyelt ellenőrző jeleket.';
	@override String get moviesAndShowsDescription => 'Megjeleníti a filmek és a televíziós műsorok ellenőrzési pontjait.';
	@override String get moviesDescription => 'Csak a filmek tekintetében mutatja meg az ellenőrző jeleket.';
	@override String get showsDescription => 'Show watched checkmarks for TV shows only. - Csak a tévéműsorok ellenőrizése.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$hu extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Felhasználók és kritikusok';
	@override String get usersOnly => 'Csak felhasználók';
	@override String get criticsOnly => 'Csak kritikusok';
	@override String get nobody => 'Rejtett';
	@override String get usersAndCriticsDescription => 'Megmutatja mind a felhasználói minősítéseket, mind a kritikus értékeléseket.';
	@override String get usersOnlyDescription => 'Tekintse meg a felhasználók által benyújtott értékeléseket és véleményeket.';
	@override String get criticsOnlyDescription => 'Kritikus értékelések és vélemények megjelenítése.';
	@override String get nobodyDescription => 'Elrejti a minősítéseket és az értékeléseket.';
}

// Path: discover.findNext
class _Translations$discover$findNext$hu extends Translations$discover$findNext$en {
	_Translations$discover$findNext$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Találd meg a következő kedvenced';
	@override String get open => 'Találd meg a következő kedvenced';
	@override String get anyTime => 'Bármennyi idő';
	@override String get timeAvailable => 'Mennyi időd van?';
	@override String get filters => 'Válassz a pillanathoz illőt';
	@override String get watch => 'Nézés';
	@override String get listen => 'Hallgatás';
	@override String get read => 'Olvasás';
	@override String finishable({required Object duration}) => '${duration} alatt befejezhető';
	@override String aboutDuration({required Object duration}) => 'Körülbelül ${duration}';
	@override String nextUnit({required Object duration}) => 'Következő fejezet · ${duration}';
	@override String totalDuration({required Object duration}) => 'Összesen ${duration}';
	@override String get timingVaries => 'Az időtartam változó';
	@override String get notNow => 'Most nem';
	@override String get swipeHint => 'Húzd a borítót valamelyik nyíl felé, vagy használd az alábbi gombokat.';
	@override String get saved => 'Mentett ajánlások';
	@override String savedCount({required Object count}) => 'Mentett ajánlások · ${count}';
	@override String get undo => 'Visszavonás';
	@override String get details => 'Részletek';
	@override String get noPicks => 'Még nincs miből választani';
	@override String get noPicksHint => 'A kezdéshez csatlakoztass egy könyvtárat, vagy adj hozzá egy médiaforrást.';
	@override String get noMatches => 'Most nincs megfelelő ajánlás';
	@override String get noMatchesHint => 'Próbálj más médiatípust, vagy szánj rá több időt.';
	@override String get allDone => 'Minden ajánlást megnéztél';
	@override String get allDoneHint => 'Indíts új válogatást, hogy újra lásd ezeket a lehetőségeket.';
	@override String get refresh => 'Másik válogatás keresése';
	@override String sourceReason({required Object source}) => 'Forrás: ${source}';
	@override String libraryReason({required Object library}) => 'Könyvtár: ${library}';
	@override String get ownedReason => 'A könyvtáradból';
	@override String get liveNow => 'Most műsoron';
	@override String get watchLive => 'Élő adás megtekintése';
	@override String get filterAnything => 'Bármi';
	@override String get filterWatch => 'Nézés';
	@override String get filterListen => 'Hallgatás';
	@override String get filterRead => 'Olvasás';
	@override String get twentyMinutes => '20 perc';
	@override String get fortyFiveMinutes => '45 perc';
	@override String get ninetyMinutes => '90 perc';
	@override String get apply => 'Alkalmaz';
	@override String get openFailed => 'Ez a lehetőség már nem érhető el. Frissíts az újbóli ellenőrzéshez.';
	@override String get changeFailed => 'A módosítást nem sikerült menteni. Próbáld újra.';
	@override String get savedLimit => 'A mentett ajánlások listája megtelt. Távolíts el egyet, hogy másikat menthess.';
	@override String get chooseHint => 'Nyiss meg egy címet, mentsd el későbbre, vagy hagyd ki.';
	@override String get howItWorks => 'Így működik';
	@override String get notNowHelp => 'Ezt a címet most kihagyod. A könyvtáradban megmarad.';
	@override String get saveHelp => 'Mentsd a profil mentett ajánlatai közé ezen az eszközön. A mentés nem tölti le a címet.';
	@override String get openHelp => 'A részletekhez válaszd ki a borítót. A fő művelettel lejátszhatod, olvashatod vagy megnyithatod a címet.';
	@override String get controlsHelp => 'Billentyűzet vagy távirányító: válassz egy gombot, majd nyomd meg az Enter vagy a Kiválasztás gombot. A Visszavonás visszaállítja az utolsó választásodat.';
	@override String get artworkLoading => 'Kép betöltése…';
	@override String get artworkUnavailable => 'A kép nem érhető el';
	@override String get savedFeedback => 'Hozzáadva a mentett ajánlatokhoz';
	@override String get skippedFeedback => 'Most kihagyva';
	@override String get releaseToConfirm => 'Engedd el a megerősítéshez';
	@override String get remoteHint => 'Borító kijelölve: ← / → választás · Kiválasztás: részletek · ↑ / ↓ fókusz mozgatása';
}

// Path: discover.person
class _Translations$discover$person$hu extends Translations$discover$person$en {
	_Translations$discover$person$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get born => 'Született';
	@override String get died => 'Elhunyt';
	@override String get birthplace => 'Születési hely';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} éves)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (${age} évesen)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$hu extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Ajánlott';
	@override String get browse => 'Böngészés';
	@override String get collections => 'Gyűjtemények';
	@override String get playlists => 'Lejátszási listák';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$hu extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Csoportosítás';
	@override String get all => 'Összes';
	@override String get movies => 'Filmek';
	@override String get shows => 'TV-sorozatok';
	@override String get seasons => 'Évadok';
	@override String get episodes => 'Epizódok';
	@override String get artists => 'Előadók';
	@override String get albums => 'Albumok';
	@override String get tracks => 'Zeneszámok';
	@override String get folders => 'Mappák';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$hu extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Műfaj';
	@override String get year => 'Év';
	@override String get contentRating => 'Korhatár-besorolás';
	@override String get tag => 'Címke';
	@override String get unwatched => 'Nem látott';
	@override String get unplayed => 'Nem lejátszott';
	@override String get favorites => 'Kedvencek';
	@override String get filePath => 'Fájl elérési útja';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$hu extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cím';
	@override String get dateAdded => 'Hozzáadás dátuma';
	@override String get releaseDate => 'Bemutató dátuma';
	@override String get rating => 'Értékelés';
	@override String get communityRating => 'Közösségi értékelés';
	@override String get criticRating => 'Kritikusi értékelés';
	@override String get userRating => 'Saját értékelés';
	@override String get datePlayed => 'Lejátszás dátuma';
	@override String get playCount => 'Lejátszások száma';
	@override String get productionYear => 'Gyártási év';
	@override String get runtime => 'Játékidő';
	@override String get officialRating => 'Hivatalos besorolás';
	@override String get premiereDate => 'Premier dátuma';
	@override String get startDate => 'Kezdés dátuma';
	@override String get airTime => 'Adásidő';
	@override String get studio => 'Stúdió';
	@override String get random => 'Véletlenszerű';
	@override String get dateShared => 'Megosztás dátuma';
	@override String get latestEpisodeAirDate => 'A legutóbbi epizód sugárzási dátuma';
	@override String get lastEpisodeDateAdded => 'Utolsó epizód hozzáadásának dátuma';
	@override String get dateDownloaded => 'Letöltés dátuma';
	@override String get size => 'Méret';
	@override String get library => 'Könyvtár';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$hu extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get include => 'Belefoglalás';
	@override String get exclude => 'Kizárás';
	@override String get any => 'Mindegy';
	@override String get yes => 'Igen';
	@override String get no => 'Nem';
	@override String not({required Object value}) => 'Kivéve: ${value}';
	@override String valueCount({required Object count}) => '${count} kiválasztva';
	@override String valueCountExcluded({required Object count}) => '${count} kizárva';
	@override String get searchValues => 'Értékek keresése';
	@override String get noValues => 'Nincsenek értékek';
	@override String get matchContains => 'Tartalmazza';
	@override String get matchNotContains => 'Nem tartalmazza';
	@override String get matchIs => 'Egyezik';
	@override String get matchIsNot => 'Nem egyezik';
	@override String get matchBeginsWith => 'Ezzel kezdődik';
	@override String get matchEndsWith => 'Erre végződik';
	@override String get textHint => 'Írd be a keresett szöveget';
	@override String get from => 'Ettől';
	@override String get to => 'Eddig';
	@override String range({required Object from, required Object to}) => '${from} – ${to}';
	@override String atLeast({required Object value}) => 'Legalább ${value}';
	@override String atMost({required Object value}) => 'Legfeljebb ${value}';
	@override String dateLastDays({required Object count}) => 'Az elmúlt ${count} nap';
	@override String get dateLastYear => 'Az elmúlt év';
	@override String dateOlderThanDays({required Object count}) => '${count} napnál régebbi';
	@override String get dateOlderThanYear => 'Egy évnél régebbi';
}

// Path: libraries.selection
class _Translations$libraries$selection$hu extends Translations$libraries$selection$en {
	_Translations$libraries$selection$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Válassza ki az elemeket';
	@override String selectedCount({required Object count}) => '${count} kiválasztva';
	@override String get actions => 'Választási akciók';
	@override String get confirmDescendants => 'Ez megváltoztatja az összes epizódot a kiválasztott előadásokban és szezonokban.';
	@override String get confirmUnwatched => 'Ez a kiválasztott elemek lejátszási előrehaladását is törli.';
	@override String confirmCount({required Object count}) => 'Válogatott elemek: ${count}.';
	@override String completed({required Object count}) => 'Aktualizált elemek: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Aktualizált ${succeeded}; nem sikerült ${failed}. A nem sikerült elemeket továbbra is kiválasztották.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$hu extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Kutatás a padlók';
	@override String get manageDescription => 'Válassza ki és rendezi a listákat a MDBList fiókjától';
	@override String get description => 'Válasszon nyilvános film- és sorozatlistákat az MDBList-fiókjából. Hozzon létre vagy másoljon listákat az MDBListen, majd frissítsen.';
	@override String get selected => 'Válogatott tálcák';
	@override String get available => 'Elérhető számlák listája';
	@override String get noLists => 'Nincs nyilvános film vagy TV listák visszatértek. Hozzon létre vagy másolja a listát a MDBList-re, majd frissítse.';
	@override String get displayName => 'Shelf kijelző neve';
	@override String get nameHint => 'Hagyja a nyílt, hogy használja a forráslistát.';
	@override String get add => 'Add Shelf';
	@override String get save => 'mentse a tálcákat';
	@override String moveUp({required Object title}) => '${title} felfelé';
	@override String moveDown({required Object title}) => '${title} lefelé';
	@override String get unavailable => 'Ez a lista nem elérhető. visszavonja vagy távolítsa el a szekrényt a beállításokban.';
	@override String get rateLimited => 'MDBList kérelem határérték elérte. kérjük, visszavonja később.';
	@override String get loadFailed => 'Nem lehet feltölteni a tálcákat. ellenőrizze a kapcsolatot és visszavonul.';
	@override String get saveFailed => 'Nem tudok megmenteni a szeleteket. kérjük, visszavonulj.';
	@override String get accountChanged => 'A fiók vagy a profil megváltozott. Újra megnyitja ezeket a beállításokat.';
	@override String get settingsUnreadable => 'A mentett lapok nem olvashatók. Válassza ki a listákat újra, hogy helyettesítse ezeket a beállításokat.';
}

// Path: explore.rows
class _Translations$explore$rows$hu extends Translations$explore$rows$en {
	_Translations$explore$rows$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Néznivalók listája';
	@override String get recommendedMovies => 'Ajánlott filmek';
	@override String get recommendedShows => 'Ajánlott sorozatok';
	@override String get trendingMovies => 'Felkapott filmek';
	@override String get trendingShows => 'Felkapott sorozatok';
	@override String get popularMovies => 'Népszerű filmek';
	@override String get popularShows => 'Népszerű sorozatok';
	@override String get trendingAnime => 'Felkapott animék';
	@override String get suggestedAnime => 'Ajánlott animék';
	@override String get airingAnime => 'Jelenleg futó top animék';
	@override String get popularAnime => 'Legnépszerűbb animék';
	@override String get trending => 'Felkapott';
	@override String get upcomingMovies => 'Közelgő filmek';
	@override String get upcomingShows => 'Közelgő sorozatok';
}

// Path: explore.status
class _Translations$explore$status$hu extends Translations$explore$status$en {
	_Translations$explore$status$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Adásban';
	@override String get ended => 'Befejeződött';
	@override String get canceled => 'Törölve';
	@override String get upcoming => 'Közelgő';
}

// Path: explore.badge
class _Translations$explore$badge$hu extends Translations$explore$badge$en {
	_Translations$explore$badge$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} népszerű';
	@override String rankAiring({required Object n}) => '#${n} adásban';
	@override String rankRated({required Object n}) => '#${n} értékelt';
	@override String rankTrending({required Object n}) => '#${n} felkapott';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} a(z) ${season} évadban';
	@override String watchingNow({required Object n}) => '${n} nézi';
	@override String get available => 'Elérhető';
	@override String get partiallyAvailable => 'Részben elérhető';
	@override String get availableIn4k => '4K elérhető';
	@override String get requested => 'Kérve';
	@override String get pendingApproval => 'Jóváhagyásra vár';
	@override String get processing => 'Feldolgozás alatt';
	@override String get declined => 'Elutasítva';
	@override String get requestFailed => 'A kérés nem sikerült';
	@override String get requested4k => '4K kérve';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} évad';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => '${episode}. ep. ${duration} múlva';
	@override String nextAiringIn({required Object duration}) => 'Következő ${duration} múlva';
	@override String episodesShort({required Object n}) => '${n} ep.';
	@override String minutesPerEpisode({required Object n}) => '${n} perc/ep.';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$hu extends Translations$explore$stats$en {
	_Translations$explore$stats$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} listázva';
	@override String viewersDay({required Object n}) => '${n} nézte ma';
	@override String viewersWeek({required Object n}) => '${n} nézte ezen a héten';
	@override String viewersMonth({required Object n}) => '${n} nézte ebben a hónapban';
	@override String viewersYear({required Object n}) => '${n} nézte ebben az évben';
	@override String viewersAllTime({required Object n}) => '${n} néző';
	@override String planning({required Object n}) => '${n} tervezi megnézni';
	@override String favorited({required Object n}) => '${n} kedvenc';
	@override String dropRate({required Object percent}) => '${percent} felhagyott vele';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hozzászólás',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hozzászólás',
	);
	@override String votes({required Object n}) => '${n} szavazat';
	@override String watching({required Object n}) => '${n} nézi';
	@override String completed({required Object n}) => '${n} befejezte';
	@override String onHold({required Object n}) => '${n} szünetelteti';
	@override String dropped({required Object n}) => '${n} felhagyott vele';
}

// Path: explore.season
class _Translations$explore$season$hu extends Translations$explore$season$en {
	_Translations$explore$season$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Tél';
	@override String get spring => 'Tavasz';
	@override String get summer => 'Nyár';
	@override String get fall => 'Ősz';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$hu extends Translations$explore$format$en {
	_Translations$explore$format$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV rövid';
	@override String get movie => 'Film';
	@override String get special => 'Különkiadás';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Zene';
	@override String get other => 'Egyéb';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$hu extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get original => 'Eredeti';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Regény';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Játék';
	@override String get webComic => 'Webképregény';
	@override String get musicRelease => 'Zene';
	@override String get otherMedia => 'Egyéb';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$hu extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Színész';
	@override String get director => 'Rendező';
	@override String get writer => 'Író';
	@override String get producer => 'Producer';
	@override String get creator => 'Alkotó';
	@override String get composer => 'Zeneszerző';
}

// Path: explore.relation
class _Translations$explore$relation$hu extends Translations$explore$relation$en {
	_Translations$explore$relation$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Előzmény';
	@override String get sequel => 'Folytatás';
	@override String get sideStory => 'Melléktörténet';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Alternatív verzió';
	@override String get summary => 'Összefoglaló';
	@override String get parentStory => 'Fő történet';
	@override String get adaptation => 'Adaptáció';
	@override String get other => 'Kapcsolódó';
}

// Path: explore.detail
class _Translations$explore$detail$hu extends Translations$explore$detail$en {
	_Translations$explore$detail$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Eredeti cím';
	@override String get alsoKnownAs => 'Más néven';
	@override String get studios => 'Stúdiók';
	@override String get country => 'Ország';
	@override String get language => 'Nyelv';
	@override String get released => 'Megjelent';
	@override String get physicalRelease => 'Lemezes';
	@override String get ended => 'Befejeződött';
	@override String addedOn({required Object date}) => 'Hozzáadva: ${date}';
	@override String get yourRating => 'Az Ön értékelése';
	@override String get budget => 'Költségvetés';
	@override String get revenue => 'Bevétel';
	@override String get contentAdvisory => 'Korhatár';
	@override String get tags => 'Címkék';
	@override String get revealSpoilerTags => 'Spoiler címkék megjelenítése';
	@override String get links => 'Hivatkozások';
	@override String get watchOn => 'Megnézhető itt';
	@override String get watchTrailer => 'Előzetes megtekintése';
	@override String openOn({required Object site}) => 'Megnyitás itt: ${site}';
	@override String get crew => 'Stáb';
	@override String get ratings => 'Értékelések';
	@override String get schedule => 'Műsorrend';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} felhasználó ajánlja',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} felhasználó ajánlja',
	);
	@override String recommendedBy({required Object who}) => 'Ajánlotta: ${who}';
	@override String favoritedBy({required Object who}) => 'Kedvencek közt: ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} még nem került adásba';
	@override String recommendedByPercent({required Object percent}) => 'A nézők ${percent}-a ajánlja';
	@override String get relatedTitles => 'Kapcsolódó címek';
	@override String get background => 'Háttér';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$hu extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Korábbi kezdés (másodperc)';
	@override String get endLate => 'Későbbi befejezés (másodperc)';
	@override String get newOnly => 'Csak új epizódok';
	@override String get anyChannel => 'Felvétel bármelyik csatornáról';
	@override String get anyTime => 'Felvétel bármikor';
	@override String get skipInLibrary => 'A könyvtárban már meglévő epizódok kihagyása';
	@override String get keepUpTo => 'Megtartandó epizódok';
	@override String get keepUpToHint => 'A 0 minden epizódot megtart';
}

// Path: music.discography
class _Translations$music$discography$hu extends Translations$music$discography$en {
	_Translations$music$discography$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Kislemezek és EP-k';
	@override String get live => 'Élő';
	@override String get compilations => 'Válogatások';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$hu extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} elindította a lejátszást';
	@override String get playbackStarted => 'A lejátszás elindult';
	@override String paused({required Object name}) => '${name} szüneteltette a lejátszást';
	@override String get playbackPaused => 'A lejátszás szünetel';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ide ugrott: ${position}';
	@override String roomJumpedTo({required Object position}) => 'Ugrás ide: ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} a sebességet ${speed} értékre állította';
	@override String speedChanged({required Object speed}) => 'Sebesség beállítva: ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} elindította: ${title}';
	@override String mediaStarted({required Object title}) => 'Most megy: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} leállította a videót';
	@override String get mediaStopped => 'A videó leállt';
	@override String waitingFor({required Object name}) => 'Várakozás: ${name}...';
	@override String get waitingForSomeone => 'Várakozás a lemaradókra...';
	@override String get finished => 'Befejeződött';
	@override String hostChangedTo({required Object name}) => '${name} lett a házigazda';
	@override String get youAreNowHost => 'Mostantól te vagy a házigazda';
	@override String joined({required Object name}) => '${name} csatlakozott';
	@override String left({required Object name}) => '${name} kilépett';
	@override String get controlRefused => 'Csak a házigazda vezérelheti a lejátszást';
	@override String get searchFailed => 'Néhány szerveren nem sikerült megkeresni a szoba videóját';
	@override String get playBlocked => 'Az indításhoz nyomd meg a lejátszás gombot';
	@override String get shareFailed => 'Nem sikerült megosztani ezt a videót a szobával';
	@override String get downloadNotShared => 'A letöltések nem oszthatók meg a szobával, amíg a szerverük nem érhető el';
	@override String get openFailed => 'Nem sikerült megnyitni a szoba videóját';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$hu extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get ended => 'A házigazda bezárta a szobát';
	@override String get kicked => 'Eltávolítottak a szobából';
	@override String get expired => 'A szoba lejárt';
	@override String get replaced => 'Egy másik eszközön csatlakoztál ehhez a szobához';
	@override String get lost => 'Megszakadt a kapcsolat a szobával';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$hu extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Ez nem szobakód. A kód 6 betűből és számjegyből áll, 0, 1, I, L és O nélkül.';
	@override String get roomNotFound => 'Nincs ilyen kódú szoba. Lehet, hogy már bezárták.';
	@override String get roomFull => 'Ez a szoba megtelt.';
	@override String get roomLocked => 'A házigazda zárolta ezt a szobát.';
	@override String get relayFull => 'A Watch Together jelenleg túlterhelt. Próbáld újra később.';
	@override String get unreachable => 'Nem sikerült elérni a Watch Together-relét. Ellenőrizd a kapcsolatot.';
	@override String get rateLimited => 'Túl sok próbálkozás. Várj egy kicsit, majd próbáld újra.';
	@override String get clientBlocked => 'A PlezyNG ezen verziója nem tudja használni a relét. Frissítsd az alkalmazást.';
	@override String get forbidden => 'Ezt csak a házigazda teheti meg.';
	@override String get notInRoom => 'Nem vagy szobában.';
	@override String get alreadyInRoom => 'Már egy szobában vagy.';
	@override String get resumeFailed => 'Nem sikerült visszacsatlakozni a szobához.';
	@override String get unsupported => 'A relé ezt nem támogatja.';
	@override String get generic => 'Hiba történt. Próbáld újra.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$hu extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'A letöltések leállnak, ha kilépsz az alkalmazásból';
	@override String get bannerDegraded => 'A háttérbeli letöltések korlátozottak lehetnek';
	@override String get bannerAction => 'Részletek';
	@override String get sheetTitle => 'A háttérbeli letöltések le vannak tiltva';
	@override String get sheetTitleDegraded => 'A háttérbeli letöltések korlátozottak lehetnek';
	@override String get sheetIntro => 'Az Android megakadályozza, hogy a PlezyNG megbízhatóan töltsön le a háttérben.';
	@override String get sheetIntroDegraded => 'Az eszközöd korlátozza, hogy a PlezyNG mikor tölthet le a háttérben.';
	@override String get reasonBackgroundRestricted => 'A PlezyNG háttérbeli használata korlátozva van. Állítsd az akkumulátor- vagy háttérhasználatát „Korlátlan” értékre.';
	@override String get reasonStandbyRestricted => 'Az Android korlátozott készenléti állapotba helyezte a Plezyt. Állítsd az akkumulátorhasználatát „Korlátlan” értékre.';
	@override String get reasonDownloadChannelBlocked => 'A letöltési értesítések ki vannak kapcsolva, ezért előfordulhat, hogy a folyamatjelzés és a vezérlők nem érhetők el.';
	@override String get reasonNotificationsDisabled => 'Az értesítések ki vannak kapcsolva. Android 13 vagy újabb rendszeren szükségesek a hosszú háttérbeli letöltésekhez.';
	@override String get reasonDataSaver => 'Az Adatforgalom-csökkentő be van kapcsolva, ezért mobiladat-kapcsolaton nem működnek a háttérbeli letöltések. Wi-Fi-n továbbra is működniük kell.';
	@override String get reasonOemUnknown => 'A letöltések többször leálltak, miközben a PlezyNG a háttérben futott. Ellenőrizd a PlezyNG akkumulátor- vagy háttérhasználati beállításait.';
	@override String get openSettings => 'Beállítások megnyitása';
	@override String get stillNotWorking => 'Eszközspecifikus segítség';
	@override String get stillNotWorkingDescription => 'Nézd meg az eszközödhöz tartozó lépéseket, vagy ha a probléma továbbra is fennáll, küldj naplót a Beállítások › Naplók megtekintése menüből.';
	@override String get dialogTitle => 'A letöltések nem biztos, hogy befejeződnek';
	@override String get dialogDownloadAnyway => 'Letöltés mégis';
	@override String get dialogFixFirst => 'Előbb javítom';
	@override String get statusTile => 'Háttérbeli letöltések';
	@override String get statusOk => 'Futhat a háttérben';
	@override String get statusBlocked => 'A rendszerbeállítások blokkolják';
	@override String get statusDegraded => 'A rendszerbeállítások korlátozzák';
	@override String get statusUnknown => 'Még nincs ellenőrizve';
	@override String get settingsUnavailable => 'Ezen az eszközön nem sikerült megnyitni a rendszerbeállításokat';
	@override String get linkUnavailable => 'Ezen az eszközön nem sikerült megnyitni a dontkillmyapp.com webhelyet';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$hu extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get library => 'Könyvtár';
	@override String get collections => 'Gyűjtemények';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$hu extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Távirányító-szerver indítása...';
	@override String get hostAddress => 'Gazdagép címe';
	@override String get connected => 'Csatlakoztatva';
	@override String get serverRunning => 'A távirányító-szerver aktív';
	@override String get serverStopped => 'A távirányító-szerver leállítva';
	@override String get serverRunningDescription => 'A hálózaton lévő mobileszközök csatlakozhatnak ehhez az alkalmazáshoz';
	@override String get serverStoppedDescription => 'Indítsd el a szervert, hogy a mobileszközök csatlakozhassanak';
	@override String get usePhoneToControl => 'Használd a mobileszközödet az alkalmazás vezérléséhez';
	@override String get startServer => 'Szerver indítása';
	@override String get stopServer => 'Szerver leállítása';
	@override String get minimize => 'Kis méret';
	@override String get manualAddressHint => 'Kézi kapcsolódási cím:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$hu extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Az azonos Plex-fiókot használó PlezyNG-eszközök itt jelennek meg';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Csatlakozás...';
	@override String get searchingForDevices => 'Eszközök keresése...';
	@override String get noDevicesFound => 'Nem találhatók eszközök a hálózaton';
	@override String get noDevicesHint => 'Nyisd meg a Plezyt asztali gépen, és használd ugyanazt a Wi-Fi-hálózatot';
	@override String get availableDevices => 'Elérhető eszközök';
	@override String get manualConnection => 'Kézi csatlakozás';
	@override String get cryptoInitFailed => 'Nem sikerült elindítani a biztonságos kapcsolatot. Először jelentkezz be a Plexbe.';
	@override String get validationHostRequired => 'Add meg a gazdagép címét';
	@override String get validationHostFormat => 'A formátumnak IP:port kell lennie (pl. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'A csatlakozás túllépte az időkorlátot. Használd ugyanazt a hálózatot mindkét eszközön.';
	@override String get sessionNotFound => 'Az eszköz nem található. Győződj meg arról, hogy a PlezyNG fut a gazdagépen.';
	@override String get authFailed => 'A hitelesítés nem sikerült. Mindkét eszközön ugyanazt a Plex-fiókot kell használni.';
	@override String failedToConnect({required Object error}) => 'Nem sikerült a csatlakozás: ${error}';
	@override String get codeTitle => 'páros kód';
	@override String get codeDescription => 'A Companion Remote-ban megjelenített kódot a tárolóeszközön adja meg. Mindkét eszköznek olyan verziót kell használnia, amely támogatja a biztonságos párosítást.';
	@override String get codeInvalid => 'Írja be a házigazda kódjából származó 32 betűt és számot.';
	@override String get updateRequired => 'Mindkét készülék frissítése olyan verzióra, amely támogatja a biztonságos párosítást.';
	@override String get hostDescription => 'Adja meg ezt a kódot egyszer minden távoli. tartsa magán: ez adja meg a profil ellenőrzését.';
	@override String get resetCode => 'Újraállítása páros kód';
	@override String get resetDescription => 'Kapcsolja ki az összes távoli és hozzon létre egy új kódot. Minden távoli kell párosítani újra.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$hu extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Bontod a kapcsolatot a távoli munkamenettel?';
	@override String get reconnecting => 'Újracsatlakozás...';
	@override String attemptOf({required Object current}) => '${current} / 5 próbálkozás';
	@override String get retryNow => 'Újrapróbálkozás most';
	@override String get tabRemote => 'Távirányító';
	@override String get tabPlay => 'Lejátszás';
	@override String get tabMore => 'Egyebek';
	@override String get menu => 'Menü';
	@override String get tabNavigation => 'Navigációs lap';
	@override String get tabDiscover => 'Felfedezés';
	@override String get tabLibraries => 'Könyvtárak';
	@override String get tabSearch => 'Keresés';
	@override String get tabDownloads => 'Letöltések';
	@override String get tabSettings => 'Beállítások';
	@override String get previous => 'Előző';
	@override String get playPause => 'Lejátszás/Szünet';
	@override String get next => 'Következő';
	@override String get seekBack => 'Visszatekerés';
	@override String get stop => 'Leállítás';
	@override String get seekForward => 'Előretekerés';
	@override String get volume => 'Hangerő';
	@override String get volumeDown => 'Hangerő le';
	@override String get volumeUp => 'Hangerő fel';
	@override String get fullscreen => 'Teljes képernyő';
	@override String get subtitles => 'Feliratok';
	@override String get audio => 'Hang';
	@override String get searchHint => 'Keresés az asztali gépen...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$hu extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nem található hálózati csatoló';
	@override String get authenticationFailed => 'A hitelesítés nem sikerült';
	@override String serverStartFailed({required Object error}) => 'Nem sikerült elindítani a távirányító-szervert: ${error}';
	@override String commandFailed({required Object error}) => 'Nem sikerült elküldeni a távoli parancsot: ${error}';
	@override String get joinTimedOut => 'Időtúllépés a munkamenethez való csatlakozáskor';
	@override String get failedToConnectAnyAddress => 'Egyetlen címhez sem sikerült csatlakozni';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'A kapcsolat megszakadt ${attempts} próbálkozás után';
	@override String get connectionLost => 'A kapcsolat megszakadt';
}

// Path: services.names
class _Translations$services$names$hu extends Translations$services$names$en {
	_Translations$services$names$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$hu extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simkl újracsatlakoztatása';
	@override String get subtitle => 'A Simkl kivezeti a kapcsolat által használt bejelentkezési módot. Az újracsatlakozás megnyitja a simkl.com oldalt, ahol jóváhagyhatod a Plezyt — a PlezyNG sosem látja a jelszavadat. A megtekintési előzményeid a Simklen maradnak.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$hu extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'PlezyNG aktiválása a következőn: ${service}';
	@override String get instructions => 'Olvasd be a QR-kódot, vagy nyisd meg az alábbi címet, és írd be ezt a kódot:';
	@override String openToActivate({required Object service}) => 'Nyisd meg a(z) ${service} oldalt az aktiváláshoz';
	@override String get copyCode => 'Aktiválási kód másolása';
	@override String get waitingForAuthorization => 'Várakozás az engedélyezésre…';
	@override String get codeCopied => 'Kód másolva';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$hu extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Bejelentkezés ide: ${service}';
	@override String get body => 'Olvasd be ezt a QR-kódot vagy nyisd meg az URL-t bármelyik eszközön.';
	@override String openToSignIn({required Object service}) => 'Nyisd meg a(z) ${service} oldalt a bejelentkezéshez';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$hu extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Bejelentkezési URL másolása';
	@override String get urlCopied => 'URL másolva';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$hu extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Könyvtárszűrő';
	@override String get subtitleAllSyncing => 'Minden könyvtár szinkronizálása';
	@override String get subtitleNoneSyncing => 'Nincs szinkronizálás';
	@override String subtitleBlocked({required Object count}) => '${count} kizárva';
	@override String subtitleAllowed({required Object count}) => '${count} engedélyezve';
	@override String get mode => 'Szűrési mód';
	@override String get modeBlacklist => 'Tiltólista';
	@override String get modeWhitelist => 'Engedélyezőlista';
	@override String get modeHintBlacklist => 'Minden könyvtár szinkronizálása az alább bejelöltek kivételével.';
	@override String get modeHintWhitelist => 'Csak az alább bejelölt könyvtárak szinkronizálása.';
	@override String get libraries => 'Könyvtárak';
	@override String get noLibraries => 'Nincsenek elérhető könyvtárak';
	@override String get modeDescription => 'Válassza ki, hogy a ellenőrzött könyvtárak nem szinkronizálódnak-e, vagy az egyetlen könyvtár, amely szinkráló.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$hu extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Szinkronizálja a megtekintett epizódokat és filmeket a Trakt fiókjával.';
	@override String get mal => 'Szinkronizálja az anime listákat és nézze meg a fejlődést MyAnimeList segítségével.';
	@override String get anilist => 'Szinkronizálja az anime listákat, és nézd meg a haladást az AniList segítségével.';
	@override String get simkl => 'Sync filmeket, televíziós műsorokat és anime-t nézett a Simklrel.';
	@override String get mdblist => 'MDBList minősítések és listák megjelenítése az ajánlásokban és a felfedezésben.';
}

/// The flat map containing all translations for locale <hu>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Alkalmazásikon',
			'appIcon.defaultIcon' => 'Alapértelmezett',
			'appIcon.current' => 'Jelenlegi ikon',
			'appIcon.locked' => 'Élethosszú hozzáférés szükséges',
			'appIcon.lockedHint' => 'Kezdje a 7 napos próbát vagy letiltja a PlezyNG élethosszig, hogy alternatív ikonokat használjon.',
			'appIcon.changeFailed' => 'Nem sikerült módosítani az alkalmazásikont',
			'appIcon.launcherHint' => 'Az új ikon azután jelenik meg a kezdőképernyőn, hogy kiléptél a Plezyből.',
			'appIcon.tvLauncherHint' => 'Az új banner azután jelenik meg, hogy kiléptél a Plezyből. Az Android TV a TV újraindításáig még a régit is mutathatja.',
			'appIcon.names.midnight' => 'Éjfél',
			'appIcon.names.ember' => 'Parázs',
			'appIcon.names.paper' => 'Papír',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Vonal',
			'appIcon.names.ocean' => 'Óceán',
			'appIcon.names.ultraviolet' => 'Ultraibolya',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Naplemente',
			'appIcon.names.gold' => 'Arany',
			'appIcon.names.titanium' => 'Titán',
			'appIcon.names.glass' => 'Üveg',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Matrica',
			'appIcon.names.ticket' => 'Jegy',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Rétegek',
			'appIcon.names.facet' => 'Fazetta',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Válassza ki az ikonot, amelyet a készülék indítója mutat. Az előrejelzések megmutatják, hogy hogyan néz ki minden lehetőség.',
			'auth.signInWithPlex' => 'Bejelentkezés Plexszel',
			'auth.showQRCode' => 'QR-kód megjelenítése',
			'auth.authenticate' => 'Hitelesítés',
			'auth.authenticationTimeout' => 'A hitelesítés időtúllépés miatt megszakadt. Próbáld újra.',
			'auth.scanQRToSignIn' => 'Olvasd be ezt a QR-kódot a bejelentkezéshez',
			'auth.waitingForAuth' => 'Várakozás a hitelesítésre...\nJelentkezz be a böngésződben.',
			'auth.useBrowser' => 'Böngésző használata',
			'auth.or' => 'vagy',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Csatlakozás a(z) ${product} szolgáltatáshoz',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Quick Connect használata',
			'auth.quickConnectInstructions' => 'Nyisd meg a Quick Connect-et a Jellyfinben, és add meg ezt a kódot.',
			'auth.quickConnectWaiting' => 'Várakozás a jóváhagyásra…',
			'auth.quickConnectCancel' => 'Mégse',
			'auth.quickConnectExpired' => 'A Quick Connect kód lejárt. Próbáld újra.',
			'auth.localDataRecoveryRequired' => 'A PlezyNG nem tudta biztonságosan helyreállítani a helyi bejelentkezés és a függőben lévő lejátszás adatait. Jelentkezz be újra.',
			'auth.pinCheckRejected' => 'A Plex PIN ellenőrzését elutasították',
			'auth.connectToDirectPlex' => 'Kapcsolat a helyi Plex szerverhez',
			'common.cancel' => 'Mégse',
			'common.save' => 'Mentés',
			'common.close' => 'Bezárás',
			'common.closeMiniPlayer' => 'Mini játékosok',
			'common.closeWorkspaceWindow' => 'Közel ablak',
			'common.returnToFullView' => 'Vissza a teljes nézőpontba',
			'common.manageMediaSessions' => 'Média ülések kezelése',
			'common.hideMediaSessions' => 'A médiaközlemények elrejtése',
			'common.mediaSessions' => 'Média ülések',
			'common.mediaSessionsHint' => 'Válassza ki, hogy egy ülést előre hozzon.A park elrejti ablakát, de nyitva tartja.A visszatérés teljes nézetben nyílik meg; a közel véget ér.',
			'common.sessionInWorkspace' => 'A munkaterületben',
			'common.sessionParked' => 'Parkolás',
			'common.sessionFullscreen' => 'Teljes képernyő',
			'common.switchToNextWindow' => 'Változás a következő ablakkal',
			'common.moveWindow' => 'Mozgás ablak',
			'common.finishMovingWindow' => 'Véget ér a mozgó ablak',
			'common.moveWindowHint' => 'Hosszú nyomás és húzza az ablakot, hogy mozogjon. Ez a vezérlés lehetővé teszi a lövedék-kulcs mozgását is.',
			'common.movingWindowHelp' => 'Kattintson a mozgáshoz · Nyomja meg a kulcsokat · Enter Saves · Escape cancels',
			'common.resizeWindow' => 'Az ablak felújítása',
			'common.resizeWindowHint' => 'Vágja ki ezt a kézikönyvt, vagy használja a lövedék kulcsát az ablak átalakításához.',
			'common.workspaceWindowHint' => 'Használja a mozgásszabályozást vagy a hosszú nyomást és húzza, hogy mozogjon.',
			'common.workspacePaneHint' => 'Válassza ki ezt a panelt, hogy összpontosítson rá. Használja a teljes képernyő vezérlőjét bővíteni.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Az ülés ablakai: ${title}',
			'common.workspaceTitleHint' => 'Kattintson a címsorra, hogy mozogjon; használja a teljes képernyő gombot kiterjeszteni.',
			'common.moveToSessionTray' => 'Helyezze be a Session Tray-t',
			'common.moveToSessionTrayHint' => 'Ez az ülést jeleníti meg, anélkül, hogy ablakát mutatnánk.',
			'common.closeSessionHint' => 'Zárja be az ablakot, és befejezi az ülését.',
			'common.sideBySideLayout' => 'Töltse át a side-by-side layout',
			'common.floatingWindows' => 'Switch az ablakok áramlásához',
			'common.clear' => 'Törlés',
			'common.reset' => 'Visszaállítás',
			'common.later' => 'Később',
			'common.submit' => 'Beküldés',
			'common.confirm' => 'Megerősítés',
			'common.retry' => 'Újra',
			'common.logout' => 'Kijelentkezés',
			'common.unknown' => 'Ismeretlen',
			'common.refresh' => 'Frissítés',
			'common.yes' => 'Igen',
			'common.no' => 'Nem',
			'common.delete' => 'Törlés',
			'common.edit' => 'Szerkesztés',
			'common.shuffle' => 'Véletlenszerű lejátszás',
			'common.addTo' => 'Hozzáadás...',
			'common.createNew' => 'Új létrehozása',
			'common.connect' => 'Csatlakozás',
			'common.disconnect' => 'Kapcsolat bontása',
			'common.play' => 'Lejátszás',
			'common.pause' => 'Szünet',
			'common.resume' => 'Folytatás',
			'common.error' => 'Hiba',
			'common.search' => 'Keresés',
			'common.home' => 'Kezdőlap',
			'common.back' => 'Vissza',
			'common.settings' => 'Beállítások',
			'common.mute' => 'Némítás',
			'common.ok' => 'OK',
			'common.off' => 'Ki',
			'common.options' => 'Lehetőségek',
			'common.seasonNumber' => ({required Object number}) => '${number}. évad',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => '${number}. epizód - ${title}',
			'common.chapterNumber' => ({required Object number}) => '${number}. fejezet',
			'common.reconnect' => 'Újracsatlakozás',
			'common.viewAll' => 'Összes megtekintése',
			'common.checkingNetwork' => 'Hálózat ellenőrzése...',
			'common.loadingServers' => 'Szerverek betöltése...',
			'common.connectingToServers' => 'Csatlakozás a szerverekhez...',
			'common.startingOfflineMode' => 'Kapcsolat nélküli mód indítása...',
			'common.loading' => 'Betöltés...',
			'common.fullscreen' => 'Teljes képernyő',
			'common.exitFullscreen' => 'Kilépés a teljes képernyőből',
			'common.pressBackAgainToExit' => 'A kilépéshez nyomd meg újra a Vissza gombot',
			'common.ratingSource.critic' => 'Critics',
			'common.ratingSource.audience' => 'Audience',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes critics',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes audience',
			'common.ratingSource.metacritic' => 'Metacritic',
			'common.ratingSource.letterboxd' => 'Letterboxd',
			'common.notAvailable' => 'N/A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Sorozat',
			'common.mediaKind.season' => 'Évad',
			'common.mediaKind.episode' => 'Epizód',
			'common.mediaKind.artist' => 'Előadó',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Szám',
			'common.mediaKind.collection' => 'Gyűjtemény',
			'common.mediaKind.playlist' => 'Lejátszási lista',
			'common.mediaKind.clip' => 'Klip',
			'common.mediaKind.photo' => 'Fénykép',
			'common.mediaKind.folder' => 'Mappa',
			'screens.licenses' => 'Licencek',
			'screens.switchProfile' => 'Profilváltás',
			'screens.subtitleStyling' => 'Feliratok stílusa',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Naplók',
			'update.available' => 'Frissítés érhető el',
			'update.versionAvailable' => ({required Object version}) => 'A(z) ${version} verzió elérhető',
			'update.currentVersion' => ({required Object version}) => 'Jelenlegi: ${version}',
			'update.skipVersion' => 'Verzió kihagyása',
			'update.viewRelease' => 'Kiadási megjegyzések',
			'update.latestVersion' => 'A legújabb verziót használod',
			'update.checkFailed' => 'Nem sikerült az újabb frissítések ellenőrzése',
			'settings.title' => 'Beállítások',
			'settings.supportDeveloper' => 'PlezyNG támogatása',
			'settings.supportDeveloperDescription' => 'Adománnyal támogassa a fejlesztést',
			'settings.lifetimeAccess' => 'PlezyNG Élethosszú hozzáférés',
			'settings.language' => 'Nyelv',
			'settings.theme' => 'Téma',
			'settings.appearance' => 'Megjelenés',
			'settings.detailPage' => 'Részletes oldal',
			'settings.themeSongsEnabled' => 'Téma dalok',
			'settings.themeSongsEnabledDescription' => 'Játsszon elérhető tematikus dalokat, miközben nézi a média részleteit.',
			'settings.themeSongVolume' => 'Téma: Volume ének',
			'settings.videoPlayback' => 'Videólejátszás',
			'settings.videoPlaybackDescription' => 'Lejátszási viselkedés beállítása',
			'settings.advanced' => 'Haladó',
			'settings.episodePosterMode' => 'Epizódborító stílusa',
			'settings.seriesPoster' => 'Sorozatborító',
			'settings.seasonPoster' => 'Évadborító',
			'settings.episodeThumbnail' => 'Bélyegkép',
			'settings.showHeroSectionDescription' => 'Kiemelt tartalmak sávjának megjelenítése a kezdőlapon',
			'settings.secondsLabel' => 'Másodperc',
			'settings.minutesLabel' => 'Perc',
			'settings.secondsShort' => 'mp',
			'settings.minutesShort' => 'p',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Add meg az időtartamot (${min}-${max})',
			'settings.systemTheme' => 'Rendszer',
			'settings.lightTheme' => 'Világos',
			'settings.darkTheme' => 'Sötét',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Parázs',
			'settings.glacierTheme' => 'Gleccser',
			'settings.forestTheme' => 'Erdő',
			'settings.plumTheme' => 'Szilva',
			'settings.paperTheme' => 'Papír',
			'settings.libraryDensity' => 'Könyvtársűrűség',
			'settings.displayScale' => 'Kijelző méretezése',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Kényelmes',
			'settings.gridSpacing' => 'Rácstávolság',
			'settings.gridSpacingTight' => 'Sűrű',
			'settings.gridSpacingNormal' => 'Normál',
			'settings.gridSpacingSpacious' => 'Tágas',
			'settings.tvCornerSpotlightBackdrop' => 'Sarokban megjelenő kiemelt háttérkép',
			'settings.tvCornerSpotlightBackdropDescription' => 'A kiemelt háttérkép megjelenítése a jobb felső sarokban a teljes képernyő helyett',
			'settings.viewMode' => 'Nézetmód',
			'settings.gridView' => 'Rács',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Kiemelt sáv megjelenítése',
			'settings.showHomeBackdrop' => 'Home Backdrop Művészeti műsor',
			'settings.showHomeBackdropDescription' => 'Nagy műalkotás megjelenítése hátsó bemutatott házi sorok mögött',
			'settings.contentScreensaverEnabled' => 'tartalom képernyő',
			'settings.contentScreensaverEnabledDescription' => 'A teljes képernyőn megjelenő műalkotás, miután az alkalmazás idle lett',
			'settings.contentScreensaverDelay' => 'Kezdje a screensaver után',
			'settings.contentScreensaverLibraries' => 'Screensaver könyvtárak',
			'settings.contentScreensaverLibrariesDescription' => 'Válassza ki, mely könyvtárak biztosítsák a képernyővédő képeit. Ha egyet sem választ ki, az összes könyvtár képeit használjuk.',
			'settings.contentScreensaverAllLibraries' => 'Minden könyvtár',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} kiválasztott könyvtárak',
			'settings.contentScreensaverNoLibraries' => 'Nem állnak rendelkezésre kapcsolódó médiakönyvtárak.',
			'settings.contentScreensaverDismissHint' => 'Nyomja meg a gombot vagy nyomja meg a lemondáshoz',
			'settings.newEpisodeNotifications' => 'Új epizód értesítések',
			'settings.newEpisodeNotificationsDescription' => 'Figyelmeztetés, amikor egy új epizód hozzáadódik egy show, akkor fogadják fel. Ellenőrizze, míg Plezy nyitva van.',
			'settings.continueWatchingRowSize' => 'Folytatjuk a sorméret figyelését',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} kártyák',
			'settings.rowSizeCompact' => 'Kompakt',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Nagy',
			'settings.continueWatchingAction' => 'A „Folytatás” művelete',
			'settings.continueWatchingPlay' => 'Lejátszás',
			'settings.continueWatchingDetails' => 'Részletek megnyitása',
			'settings.episodeAction' => 'Az epizódkártya művelete',
			'settings.episodePlay' => 'Lejátszás',
			'settings.episodeDetails' => 'Részletek megnyitása',
			'settings.useGlobalHubs' => 'Kezdőlap elrendezés használata',
			'settings.useGlobalHubsDescription' => 'Egyesített kezdőlapi blokkok megjelenítése. Egyébként a könyvtári ajánlások jelennek meg.',
			'settings.showServerNameOnHubs' => 'Szervernév megjelenítése a blokkoknál',
			'settings.showServerNameOnHubsDescription' => 'Mindig jelenjen meg a szerver neve a blokkok címében.',
			'settings.groupLibrariesByServer' => 'Könyvtárak csoportosítása szerver szerint',
			'settings.groupLibrariesByServerDescription' => 'Az oldalsáv könyvtárainak csoportosítása a médiaszerverek alatt.',
			'settings.alwaysKeepSidebarOpen' => 'Oldalsáv mindig nyitva',
			'settings.alwaysKeepSidebarOpenDescription' => 'Az oldalsáv kibontva marad, a tartalom területe igazodik hozzá',
			'settings.showUnwatchedCount' => 'Nem látott elemek számának megjelenítése',
			'settings.showUnwatchedCountDescription' => 'Megjeleníti a még nem látott epizódok számát a sorozatoknál és évadoknál',
			'settings.showWatchedIndicators' => 'Megtekintésjelölők megjelenítése',
			'settings.showWatchedIndicatorsDescription' => 'Pipa megjelenítése a megtekintett filmeken, sorozatokon és epizódokon',
			'settings.showEpisodeNumberOnCards' => 'Epizódszám megjelenítése a kártyákon',
			'settings.showEpisodeNumberOnCardsDescription' => 'Megjeleníti az évad- és epizódszámot az epizódkártyákon',
			'settings.showSeasonPostersOnTabs' => 'Évadborítók megjelenítése a füleken',
			'settings.showSeasonPostersOnTabsDescription' => 'Megjeleníti az egyes évadok borítóját a fülük felett',
			'settings.tvFullCardLayout' => 'Teljes TV-kártyák',
			'settings.tvFullCardLayoutDescription' => 'Csak képet tartalmazó TV-kártyák használata, rájuk helyezett színésznevekkel',
			'settings.focusGlow' => 'Kijelölési ragyogás',
			'settings.focusGlowDescription' => 'Finom ragyogás rajzolása a kijelölt kártya köré',
			'settings.visualEffects' => 'Vizuális effektek',
			'settings.visualEffectsAuto' => 'Automatikus',
			'settings.visualEffectsAutoDescription' => 'Effektek automatikus csökkentése alacsony teljesítményű eszközökön',
			'settings.visualEffectsFull' => 'Teljes',
			'settings.visualEffectsReduced' => 'Csökkentett',
			'settings.visualEffectsReducedDescription' => 'Kevesebb animáció és alacsonyabb felbontású képek',
			'settings.hideSpoilers' => 'Spoilerek elrejtése a nem látott epizódoknál',
			'settings.hideSpoilersDescription' => 'Bélyegképek és leírások elhomályosítása a még meg nem nézett epizódoknál',
			'settings.playerBackend' => 'Lejátszómotor',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardveres dekódolás',
			'settings.hardwareDecodingDescription' => 'Hardveres gyorsítás használata, ha elérhető',
			'settings.playbackBuffer' => 'Lejátszási puffer',
			'settings.playbackBufferAuto' => 'Automatikus (ajánlott)',
			'settings.playbackBufferLarge' => 'Nagy',
			'settings.playbackBufferExtraLarge' => 'Extra nagy',
			'settings.playbackBufferDescription' => 'Több puffert használ instabil kapcsolatok ellen. A pufferméret is korlátozza.',
			'settings.streamBufferSize' => 'Buffer méret',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Mennyit kell tölteni a videót, amikor közvetlenül játszani. transzkódok megállnak a szerver saját transzkód buffer. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'A Playback Buffer helyettesítése a beállított, az alkalmazás memóriameghatározásának felére elkapott',
			'settings.streamBufferMegabytes' => 'Megabajták',
			'settings.defaultQualityTitle' => 'Alapértelmezett minőség',
			'settings.cellularQualityTitle' => 'Alapértelmezett minőség mobilhálózaton',
			'settings.remoteQualityTitle' => 'Remote Streaming minőség',
			'settings.remoteQualitySameAsDefault' => 'A szabványos minőség',
			'settings.cellularQualitySameAsDefault' => 'Ugyanaz, mint az alapértelmezett minőség',
			'settings.directPlayCoveredQuality' => 'Kisebb videók lejátszása eredeti minőségben',
			'settings.directPlayCoveredQualityDescription' => 'A minőségi korláton belüli videók közvetlen lejátszása átkódolás helyett',
			'settings.videoCodecs' => 'Videokodekek',
			'settings.videoCodecsDescription' => 'A nem bejelölt kodekeket a szerver átkódolja',
			'settings.videoCodecsAlwaysAccepted' => 'Mindig elfogadva',
			'settings.musicQualityTitle' => 'Zene minősége',
			'settings.subtitleStyling' => 'Feliratok stílusa',
			'settings.subtitleStylingDescription' => 'Feliratok megjelenésének testreszabása',
			'settings.smallSkipDuration' => 'Kis ugrás időtartama',
			'settings.largeSkipDuration' => 'Nagy ugrás időtartama',
			'settings.rewindOnResume' => 'Visszatekerés folytatáskor',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} másodperc', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} másodperc', ), 
			'settings.defaultSleepTimer' => 'Alapértelmezett elalvási időzítő',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} perc', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} perc', ), 
			'settings.rememberTrackSelections' => 'Sávválasztások megjegyzése sorozatonként/filmenként',
			'settings.chooseTracksBeforePlayback' => 'Válassza ki a hangokat és altitkolatokat a playback előtt',
			'settings.chooseTracksBeforePlaybackDescription' => 'Válassza ki a forrás hang és altitkos nyomokat, mielőtt minden videó elindul.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Mindig mutatnak altitkok ezen a készüléken',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Ha a szerver nem rendelkezik kiválasztott alszámmal, válasszon egy pályát helyi helyen. Ez soha nem változtatja meg a szerver preferenciáit.',
			'settings.autoDownloadPreferredSubtitle' => 'A FETCH hiányzik a preferált nyelv altitkok',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Válasszon egy elérhető alszámot a kedvenc nyelven helyi. ha nincs, kérje a szervert, hogy a támogatott. A kiválasztás ezen a készüléken marad.',
			'settings.rememberTrackSelectionsDescription' => 'Hang- és feliratválasztások megjegyzése címenként',
			'settings.rememberTrackSelectionsBackendRule' => 'A Plex minden választást fájlonként a szerveren ment; a Jellyfin a fiók „Választások megjegyzése” funkcióját is bekapcsolja; az Emby nem támogatott',
			'settings.followServerTrackSelections' => 'A szerver epizódonkénti sávválasztásának használata',
			'settings.followServerTrackSelectionsDescription' => 'Epizódváltáskor a szerveren kiválasztott hang és felirat lép életbe az aktuális választás átvitele helyett',
			'settings.resumeMusicOnLaunch' => 'Zenei munkamenet megjegyzése',
			'settings.resumeMusicOnLaunchDescription' => 'Az alkalmazás indításakor az utolsó szám szüneteltetve nyílik meg ott, ahol abbamaradt',
			'settings.showChapterMarkersOnTimeline' => 'Fejezetjelölők megjelenítése az idősávon',
			'settings.showChapterMarkersOnTimelineDescription' => 'Az idősáv felosztása a fejezetek határainál',
			'settings.specialsOrdering' => 'Különkiadások epizódsorrendben',
			'settings.specialsOrderingDescription' => 'A különkiadások helye a sorozat lejátszási sorrendjében',
			'settings.specialsOrderingServer' => 'Szerver szerinti sorrend',
			'settings.specialsOrderingAirDate' => 'Adás dátuma szerint közbeszúrva',
			'settings.specialsOrderingLast' => 'A normál évadok után',
			'settings.clickVideoTogglesPlayback' => 'Kattintás a videóra a lejátszás/szünet váltásához',
			'settings.clickVideoTogglesPlaybackDescription' => 'A videóra kattintva vált a lejátszás/szünet, a vezérlők megjelenítése helyett.',
			'settings.videoPlayerControls' => 'Videólejátszó vezérlői',
			'settings.keyboardShortcuts' => 'Billentyűparancsok',
			'settings.keyboardShortcutsDescription' => 'Billentyűparancsok testreszabása',
			'settings.videoPlayerNavigation' => 'Videólejátszó-navigáció',
			'settings.videoPlayerNavigationDescription' => 'A nyílbillentyűk használata a videólejátszó vezérlői közötti navigáláshoz',
			'settings.watchTogetherRelay' => 'Watch Together-relé',
			'settings.watchTogetherRelayDescription' => 'Nyilvános Open Watch Party-relék, hacsak nem adsz meg sajátot',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Adj meg egy érvényes HTTP- vagy HTTPS-alapú relészerver-URL-t.',
			'settings.crashReporting' => 'Összeomlási jelentések',
			'settings.crashReportingDescription' => 'Összeomlási jelentések küldése az alkalmazás fejlesztésének elősegítéséhez',
			'settings.debugLogging' => 'Hibakeresési naplózás',
			'settings.debugLoggingDescription' => 'Részletes naplózás engedélyezése a hibaelhárításhoz',
			'settings.viewLogs' => 'Naplók megtekintése',
			'settings.viewLogsDescription' => 'Alkalmazásnaplók megtekintése',
			'settings.clearImageCache' => 'Képgyorsítótár törlése',
			'settings.clearImageCacheDescription' => 'Törli a gyorsítótárazott borítókat és miniatűröket. A képek lassabban tölthetők be, amíg újra le nem töltődnek.',
			'settings.clearImageCacheSuccess' => 'A képgyorsítótár sikeresen törölve',
			'settings.resetSettings' => 'Beállítások visszaállítása',
			'settings.resetSettingsDescription' => 'Az alapértelmezett beállítások visszaállítása. Ez a művelet nem vonható vissza.',
			'settings.resetSettingsSuccess' => 'A beállítások sikeresen visszaállítva',
			'settings.backup' => 'Biztonsági mentés',
			'settings.exportSettings' => 'Beállítások exportálása',
			'settings.exportSettingsDescription' => 'Beállítások mentése fájlba',
			'settings.exportSettingsSuccess' => 'Beállítások exportálva',
			'settings.importSettings' => 'Beállítások importálása',
			'settings.importSettingsDescription' => 'Beállítások visszaállítása fájlból',
			'settings.importSettingsConfirm' => 'Ez felülírja a jelenlegi beállításaidat. Folytatod?',
			'settings.importSettingsSuccess' => 'Beállítások importálva',
			'settings.importSettingsInvalidFile' => 'Ez a fájl nem érvényes PlezyNG-beállításexport',
			'settings.importSettingsNoUser' => 'Jelentkezz be a beállítások importálása előtt',
			'settings.cloudBackup' => 'Felhőalapú biztonsági mentés',
			'settings.cloudBackupDescription' => 'Készíts biztonsági másolatot az átvihető beállításokról egy WebDAV-címre HTTPS-en keresztül. A szerverkapcsolatok és a bejelentkezési adatok ezen az eszközön maradnak.',
			'settings.cloudBackupUrl' => 'WebDAV JSON fájl URL',
			'settings.cloudBackupUsername' => 'Felhasználónév',
			'settings.cloudBackupPassword' => 'Jelszó',
			'settings.cloudBackupSaved' => 'Cloud Backup cél mentett',
			'settings.cloudBackupNow' => 'Vissza most',
			'settings.cloudBackupComplete' => 'Backup beállítások feltöltve',
			'settings.cloudBackupRestore' => 'Backup visszaállítása',
			'settings.cloudBackupRestoreConfirm' => 'Ez helyettesíti a hordozható beállítások megfelelését ezen a készüléken.',
			'settings.cloudBackupRestored' => 'A felhő biztonsági mentéséből helyreállított beállítások',
			'settings.shortcutsReset' => 'A billentyűparancsok visszaálltak az alapértelmezettekre',
			'settings.resetShortcutsConfirm' => 'Ezzel az egyéni billentyűparancsaid helyére az alapértelmezettek kerülnek. Folytatod?',
			'settings.about' => 'Névjegy',
			'settings.aboutDescription' => 'Alkalmazásadatok és licencek',
			'settings.updates' => 'Frissítések',
			'settings.updateAvailable' => 'Frissítés érhető el',
			'settings.checkForUpdates' => 'Frissítések keresése',
			'settings.autoCheckUpdatesOnStartup' => 'Frissítések automatikus keresése indításkor',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Értesítés küldése indításkor, ha új frissítés érhető el',
			'settings.validationErrorEnterNumber' => 'Adj meg egy érvényes számot',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Az időtartamnak ${min} és ${max} ${unit} között kell lennie',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'A billentyűparancs már hozzá van rendelve a következőhöz: ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Billentyűparancs frissítve a következőhöz: ${action}',
			'settings.saveFailed' => 'Nem sikerült menteni a módosításokat. Próbáld újra.',
			'settings.autoPlayAndSkip' => 'Automatikus lejátszás és átugrás',
			'settings.autoPlayNextEpisode' => 'Következő epizód automatikus lejátszása',
			'settings.autoPlayNextEpisodeDescription' => 'A következő epizód automatikus elindítása, amikor az aktuális véget ér',
			'settings.shuffleStartsFromBeginning' => 'Véletlenszerű lejátszás az elejétől',
			'settings.shuffleStartsFromBeginningDescription' => 'Minden epizód az elejétől indul véletlenszerű lejátszáskor a folytatás helyett',
			'settings.plexCinemaPreRoll' => 'A szerverek filmbevételét',
			'settings.plexCinemaPreRollDescription' => 'Játssz konfigurált Plex előzetes vagy Jellyfin és Emby bejegyzést, mielőtt egy film elindul.',
			'settings.playNextCountdown' => 'Visszaszámlálás a következő epizódig',
			'settings.playNextCountdownImmediate' => 'Azonnali lejátszás',
			'settings.skipIntroMode' => 'Intró átugrása',
			'settings.skipIntroModeOffDescription' => 'Az intrók normálisan lejátszódnak, átugró gomb nélkül',
			'settings.skipIntroModeButtonDescription' => 'Átugró gomb megjelenítése az intró kezdetekor',
			'settings.skipIntroModeAutoDescription' => 'Az intrók automatikus átugrása az alábbi késleltetés után',
			'settings.skipCreditsMode' => 'Stáblista átugrása',
			'settings.skipCreditsModeOffDescription' => 'A stáblista normálisan lejátszódik, átugró gomb nélkül',
			'settings.skipCreditsModeButtonDescription' => 'Átugró gomb megjelenítése a stáblista kezdetekor',
			'settings.skipCreditsModeAutoDescription' => 'A stáblista automatikus átugrása és a következő epizód lejátszása',
			'settings.skipAdsMode' => 'Skip hirdetések',
			'settings.skipAdsModeOffDescription' => 'Játsszon észlelt hirdetéseket normálisan, a skip gomb nélkül',
			'settings.skipAdsModeButtonDescription' => 'A skip gomb megjelenítése, amikor a Plex egy hirdetést észlel',
			'settings.skipAdsModeAutoDescription' => 'A felderített hirdetések automatikusan eltávolítása az alábbi késések után',
			'settings.musicPlayback' => 'Zene Playback',
			'settings.musicSweetFades' => 'édes fát',
			'settings.musicSweetFadesDescription' => 'A zene a track edgein, amikor a Plex hangadatokkal rendelkezik. az album lejátszását változatlanul tartják.',
			'settings.skipMarkerModeOff' => 'Ki',
			'settings.skipMarkerModeButton' => 'Gomb megjelenítése',
			'settings.skipMarkerModeAuto' => 'Automatikus',
			'settings.forceSkipMarkerFallback' => 'Tartalék jelölők kényszerítése',
			'settings.forceSkipMarkerFallbackDescription' => 'Fejezetcím-minták használata akkor is, ha a Plex rendelkezik jelölőkkel',
			'settings.theIntroDbFallback' => 'A TheIntroDB-t intro fallbackként használja',
			'settings.theIntroDbFallbackDescription' => 'A közösségi időzítéseket csak akkor használja, ha a szerver nem rendelkezik intro markerrel.',
			'settings.autoSkipDelay' => 'Automatikus átugrás késleltetése',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Várakozás ${seconds} másodpercig az automatikus átugrás előtt',
			'settings.introPattern' => 'Intrójelölő mintája',
			'settings.introPatternDescription' => 'Reguláris kifejezés az intrójelölők illesztéséhez a fejezetcímekben',
			'settings.creditsPattern' => 'Stáblistajelölő mintája',
			'settings.creditsPatternDescription' => 'Reguláris kifejezés a stáblistajelölők illesztéséhez a fejezetcímekben',
			'settings.prerolls' => 'Prerollok',
			'settings.playPrerollsBeforeMovies' => 'Prorollok játszani a filmek előtt',
			'settings.playPrerollsBeforeMoviesDescription' => 'Játssz egy véletlenszerű klip a kiválasztás alább, mielőtt minden film. nyomja meg vissza, hogy ugráljon.',
			'settings.prerollLibrary' => 'Preroll könyvtár',
			'settings.prerollLibraryNotSet' => 'Nincs beállítva',
			'settings.prerollLibraryNoneFound' => 'Nincs könyvtár a szervereken.',
			'settings.prerollSelection' => 'Kiválasztott előadások',
			'settings.prerollSelectionPickLibraryFirst' => 'Először egy könyvtárat választunk',
			'settings.prerollSelectionNoneSelected' => 'Nem kiválasztott előadások',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} kiválasztva',
			'settings.prerollItemPicker' => 'Proroll kiválasztása',
			'settings.prerollItemPickerLoadFailed' => 'Nem tudtam elhelyezni a könyvtárból származó elemeket.',
			'settings.invalidRegex' => 'Érvénytelen reguláris kifejezés',
			'settings.regex' => 'Reguláris kifejezés',
			'settings.downloads' => 'Letöltések',
			'settings.downloadLocationDescription' => 'Válaszd ki a letöltött tartalom tárolási helyét',
			'settings.downloadLocationDefault' => 'Alapértelmezett (alkalmazástárhely)',
			'settings.downloadLocationCustom' => 'Egyéni hely',
			'settings.selectFolder' => 'Mappa kiválasztása',
			'settings.resetToDefault' => 'Visszaállítás alapértelmezettre',
			'settings.currentPath' => ({required Object path}) => 'Jelenlegi: ${path}',
			'settings.downloadLocationChanged' => 'A letöltési hely megváltozott',
			'settings.downloadLocationReset' => 'A letöltési hely visszaállt az alapértelmezettre',
			'settings.downloadLocationInvalid' => 'A kiválasztott mappa nem írható',
			'settings.downloadLocationPickerUnavailable' => 'A mappaválasztás ezen az eszközön nem érhető el',
			'settings.downloadOnWifiOnly' => 'Letöltés csak Wi-Fi-n',
			'settings.downloadOnWifiOnlyDescription' => 'Letöltések megakadályozása mobiladat-használat esetén',
			'settings.autoRemoveWatchedDownloads' => 'Megnézett letöltések automatikus eltávolítása',
			'settings.autoRemoveWatchedDownloadsDescription' => 'A megnézett letöltések automatikus törlése',
			'settings.autoDownloadContinueWatching' => 'Autó-töltés Folytatás nézőpont',
			'settings.autoDownloadContinueWatchingDescription' => 'Tartsa az elemeket a Fenntartható Figyelem rakodó letöltve, és távolítsa el őket, miután elhagyja a rakodót',
			'settings.downloadQuality' => 'Download minőség',
			'settings.downloadQualityDescription' => 'A Plex készíti a letöltésbe fordított másolatot. Jellyfin és Emby transzkód, míg a fájl letölthető; megszakított átvitelek újraindításra lehet szükség.',
			'settings.askDownloadQualityEachTime' => 'Válassza ki a minőséget minden letöltéshez',
			'settings.askDownloadQualityEachTimeDescription' => 'Megjelenítse a minőségi pickeret, mielőtt minden videót letölt',
			'settings.cellularDownloadBlocked' => 'A letöltések mobilhálózaton le vannak tiltva. Használj Wi-Fi-t, vagy módosítsd a beállítást.',
			'settings.maxVolume' => 'Maximális hangerő',
			'settings.maxVolumeDescription' => 'A hangerő 100% fölé emelésének engedélyezése halk tartalmak esetén',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Megjeleníti a Discordon, hogy éppen mit nézel',
			'settings.services' => 'Szolgáltatások',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr és egyéb szolgáltatások csatlakoztatása',
			'settings.manageLibrariesDescription' => 'Könyvtárak sorrendjének módosítása és elrejtése',
			'settings.companionRemoteServer' => 'Kísérőtávirányító szervere',
			'settings.companionRemoteServerDescription' => 'Lehetővé teszi, hogy a hálózaton lévő mobileszközökről vezéreld az alkalmazást',
			'settings.companionRemoteServerStartFailed' => 'Nem sikerült elindítani a kísérőtávirányító szerverét',
			'settings.companionRemoteServerStopFailed' => 'Nem sikerült leállítani a kísérőtávirányító szerverét',
			'settings.autoPip' => 'Automatikus kép a képben (PiP)',
			'settings.autoPipDescription' => 'Lejátszás közben az alkalmazás elhagyásakor automatikusan kép a képben módra vált',
			'settings.matchContentFrameRate' => 'Képkockasebesség illesztése a tartalomhoz',
			'settings.matchContentFrameRateDescription' => 'A kijelző frissítési frekvenciájának igazítása a videóhoz',
			'settings.matchContentResolution' => 'Igazítás a tartalom felbontásához',
			'settings.matchContentResolutionDescription' => 'A kijelzőt a videó natív felbontására váltja, hogy a felskálázást a tévé végezze. Lejátszás közben a menük és a feliratok is felskálázódnak',
			'settings.matchRefreshRate' => 'Frissítési frekvencia illesztése',
			'settings.matchRefreshRateDescription' => 'A kijelző frissítési frekvenciájának igazítása teljes képernyőn',
			'settings.matchDynamicRange' => 'Dinamikatartomány illesztése',
			'settings.matchDynamicRangeDescription' => 'HDR bekapcsolása HDR-tartalmak esetén, majd visszaváltás SDR-re',
			'settings.displaySwitchDelay' => 'Kijelzőváltási késleltetés',
			'settings.tunneledPlayback' => 'Alagutas lejátszás',
			'settings.tunneledPlaybackDescription' => 'Videóalagút használata. Tiltsd le, ha HDR-lejátszáskor fekete a kép vagy akadozik a mozgás.',
			'settings.audioPassthrough' => 'Hangtovábbítás (passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS-hang továbbítása az erősítőre vagy a TV-re újrakódolás nélkül, a térhangzás megőrzésével. Kapcsold ki, ha nincs hang.',
			'settings.audioPassthroughDescriptionApple' => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. A DTS és a TrueHD továbbra is többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. iOS, iPadOS és tvOS 26 vagy újabb rendszeren a TrueHD Atmos és a DTS:X térbeli hangzásként szól. A többi DTS- és TrueHD-sáv többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Ki, amíg a hangerőnormalizálás be van kapcsolva',
			'settings.audioChannelLimit' => 'Hangcsatornák',
			'settings.audioChannelLimitDescription' => 'A dekódolt hang lekeverése olyan hangszórókhoz, fejhallgatókhoz vagy HDMI-rendszerekhez, amelyek nem tudják lejátszani az összes csatornát',
			'settings.audioChannelLimitOriginal' => 'Eredeti',
			'settings.audioChannelLimitOriginalDescription' => 'A sáv összes csatornájának lejátszása',
			'settings.audioChannelLimitSurround51' => 'Legfeljebb 5.1',
			'settings.audioChannelLimitSurround51Description' => '7.1 lekeverése 5.1-re olyan TV-khez és erősítőkhöz, amelyek csak 5.1-es PCM-et fogadnak. A hangtovábbítást nem érinti.',
			'settings.audioChannelLimitStereo' => 'Sztereó',
			'settings.audioChannelLimitStereoDescription' => 'Lekeverés két csatornára sztereó hangszórókhoz vagy fejhallgatóhoz. Kikapcsolja a hangtovábbítást.',
			'settings.downmixCenterBoost' => 'Középső csatorna kiemelése',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Kiemelés (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Hangerő normalizálása lekeveréskor',
			'settings.audioDownmixNormalizeDescription' => 'A keverés szintjének csökkentése a torzítás elkerülésére. Kapcsold ki az eredeti hangerő megőrzéséhez (a hangos jelenetek torzíthatnak).',
			'settings.dvConversionMode' => 'Dolby Vision-átalakítás',
			'settings.dvConversionModeDescription' => 'Válaszd ki, hogyan legyenek kezelve a Dolby Vision Profile 7 fájlok.',
			'settings.dvConversionAuto' => 'Automatikus',
			'settings.dvConversionNative' => 'Natív / letiltva',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Az eszköz képességeinek felismerése és szükség esetén a szokásos tartalék megoldás használata',
			'settings.dvConversionNativeDescription' => 'A natív DV7 kényszerítése és a DV-átalakítási újrapróbálkozás letiltása',
			'settings.dvConversionDv81Description' => 'A közvetlen RPU-átalakítás kényszerítése Dolby Vision Profile 8.1-re',
			'settings.dvConversionHevcStripDescription' => 'A Dolby Vision RPU/EL-rétegek eltávolítása és egyszerű HEVC-ként való megjelenítés',
			'settings.experimentalDolbyVision' => 'Kísérleti Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'A következő lejátszáskor a kísérleti FEL-megjelenítő használata. Külön motorbuild szükséges.',
			'settings.dvExperimentUnavailableDescription' => 'Ez a kísérlet jelenleg csak Linuxon érhető el.',
			'settings.dvCompatibilityFallback' => 'Kompatibilitási tartalék mód',
			'settings.dvCompatibilityFallbackDescription' => 'Ha a kísérlet nem indul, a normál megjelenítő használata. A FEL-adatok elveszhetnek.',
			'settings.dvExperimentDiagnostics' => 'Videókísérlet naplózása',
			'settings.dvExperimentDiagnosticsDescription' => 'Részletes lejátszónaplók engedélyezése a következő lejátszáskor.',
			'settings.disableDolbyVision' => 'Dolby Vision letiltása',
			'settings.disableDolbyVisionDescription' => 'A Dolby Vision helyett a fájl HDR10 vagy HLG rétegének lejátszása, ha van ilyen',
			'settings.hdrSdrConversion' => 'HDR–SDR átalakítás',
			'settings.hdrSdrConversionDescription' => 'Válaszd ki, mi alakítsa át a HDR-videót, ha a kijelző nem tud HDR-t megjeleníteni.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automatikus',
			'settings.hdrSdrConversionAutoDescription' => 'Eszköz Android 9-től, lejátszó a régebbi verziókon',
			'settings.hdrSdrConversionDevice' => 'Eszköz',
			'settings.hdrSdrConversionDeviceDescription' => 'Az eszköz videohardvere alakítja át. A leggyorsabb, de a színek az eszköztől függnek',
			'settings.hdrSdrConversionPlayer' => 'Lejátszó',
			'settings.hdrSdrConversionPlayerDescription' => 'A lejátszó alakítja át. Egységes színek, de a 4K akadozhat a gyengébb TV-boxokon',
			'settings.deinterlace' => 'Deinterlacing',
			'settings.deinterlaceDescription' => 'Fésűfog-műtermékek eltávolítása a váltott soros videóból (csak mpv lejátszóval)',
			'settings.deinterlaceOff' => 'Ki',
			'settings.deinterlaceOffDescription' => 'A váltott soros videó megjelenítése úgy, ahogy dekódolva lett',
			'settings.deinterlaceVideo' => 'Videó',
			'settings.deinterlaceVideoDescription' => 'Minden félképből teljes képkocka lesz. TV-re rögzített felvételekhez, például sporthoz, hírekhez és koncertekhez',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'A 29,97 fps-re telecine-eljárással átalakított filmek és animációk eredeti képkockáinak helyreállítása, ami gyakori az NTSC DVD-ken. A TV-re rögzített felvételek akadoznak. Az Élő TV a Videó módot használja',
			'settings.requireProfileSelectionOnOpen' => 'Profil kérése az alkalmazás megnyitásakor',
			'settings.requireProfileSelectionOnOpenDescription' => 'Profilválasztó megjelenítése minden alkalommal, amikor az alkalmazást megnyitod',
			'settings.forceTvMode' => 'TV-mód kényszerítése',
			'settings.forceTvModeDescription' => 'TV-elrendezés kényszerítése az automatikus felismeréssel nem rendelkező eszközökön. Újraindítást igényel.',
			'settings.startInFullscreen' => 'Indítás teljes képernyőn',
			'settings.startInFullscreenDescription' => 'A PlezyNG megnyitása teljes képernyős módban indításkor',
			'settings.exitFullscreenOnPlayerClose' => 'Kilépés a teljes képernyőből a lejátszó bezárásakor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatikus kilépés a teljes képernyőből a videólejátszó bezárásakor',
			'settings.autoHidePerformanceOverlay' => 'Teljesítményadatok automatikus elrejtése',
			'settings.autoHidePerformanceOverlayDescription' => 'A teljesítményadatok elhalványítása a lejátszásvezérlőkkel együtt',
			'settings.showNavBarLabels' => 'Navigációs sáv címkéinek megjelenítése',
			'settings.showNavBarLabelsDescription' => 'Szöveges címkék megjelenítése a navigációs sáv ikonjai alatt',
			'settings.startupSection' => 'Indítási oldal',
			'settings.preferredServer' => 'Kedvenc szerverek',
			'settings.preferredServerDescription' => 'A szerver eredményeinek prioritása, miközben minden csatlakoztatott szervert elérhetővé teszi.',
			'settings.preferredServerAutomatic' => 'Automatikus',
			'settings.showExploreTab' => 'Felfedezés lap megjelenítése',
			'settings.showExploreTabDescription' => 'A Plex Discover és a csatlakoztatott követők tartalmait megjelenítő Felfedezés lap megjelenítése',
			'settings.hideEmptyLibraries' => 'Tisztítsa el az üres könyvtárakat',
			'settings.hideEmptyLibrariesDescription' => 'Távolítsa el a könyvtárakat, amelyek a kiszolgáló által jelentett objektumok számát nulláról a navigációból.',
			'settings.liveTvDefaultFavorites' => 'Kedvenc csatornák alapértelmezés szerint',
			'settings.liveTvDefaultFavoritesDescription' => 'Csak a kedvenc csatornák megjelenítése az Élő TV megnyitásakor',
			'settings.general' => 'Általános',
			'settings.generalDescription' => 'Nyelv, indítás és ablakviselkedés',
			'settings.languageAndRegion' => 'Nyelv és régió',
			'settings.startup' => 'Indítás',
			'settings.display' => 'Kijelző',
			'settings.libraryAndCards' => 'Könyvtár és kártyák',
			'settings.homeScreen' => 'Kezdőképernyő',
			'settings.navigation' => 'Navigáció',
			'settings.window' => 'Ablak',
			'settings.liveTv' => 'Élő TV',
			'settings.player' => 'Lejátszó',
			'settings.videoAndDisplay' => 'Videó és kijelző',
			'settings.audio' => 'Hang',
			'settings.quality' => 'Minőség',
			'settings.subtitles' => 'Feliratok',
			'settings.seekAndTiming' => 'Tekerés és időzítés',
			'settings.behavior' => 'Viselkedés',
			'settings.gestures' => 'Mozdulatok',
			'settings.gestureBrightnessSwipe' => 'Fényerő-húzás',
			'settings.gestureBrightnessSwipeDescription' => 'Húzd felfelé vagy lefelé a bal szélén a fényerő beállításához',
			'settings.gestureVolumeSwipe' => 'Hangerő-húzás',
			'settings.gestureVolumeSwipeDescription' => 'Húzd felfelé vagy lefelé a jobb szélén a hangerő beállításához',
			'settings.gesturePinchToZoom' => 'Csípés a nagyításhoz',
			'settings.gesturePinchToZoomDescription' => 'Csípj a videóra a nagyításhoz vagy kicsinyítéshez',
			'settings.gestureSeekSwipe' => 'Keresés Swipe',
			'settings.gestureSeekSwipeDescription' => 'A videó kereséséhez balra vagy jobbra váltja; szabadon engedje a ugrást',
			'settings.rememberBrightnessLevel' => 'Fényerőszint megjegyzése',
			'settings.rememberBrightnessLevelDescription' => 'A lejátszás az utolsó húzással beállított fényerővel indul',
			'settings.controls' => 'Vezérlők',
			'settings.rememberPlayerChanges' => 'Lejátszó módosításainak megjegyzése',
			'settings.rememberPlayerChangesDescription' => 'A lejátszás közben végzett módosítások mentési és újbóli alkalmazási helye',
			'settings.scopePlaybackSpeed' => 'Lejátszási sebesség',
			'settings.scopeShaderPreset' => 'Shader-előbeállítás',
			'settings.scopeAspectRatio' => 'Képarány',
			'settings.scopeSyncOffsets' => 'Hang- és feliratszinkronizálás',
			'settings.playerScopeOff' => 'Ne mentse',
			'settings.playerScopeGlobal' => 'Mindenhol',
			'settings.playerScopeLibrary' => 'Könyvtáronként',
			'settings.playerScopeTitle' => 'Sorozatonként vagy filmenként',
			'settings.exportDialogTitle' => 'PlezyNG-beállítások exportálása',
			'settings.followSystem' => 'Rendszernyelv követése',
			'settings.followAppLanguage' => 'A felület nyelvével megegyező',
			'settings.regionFormat' => 'Területi formátumok',
			'settings.regionFormatDescription' => 'Válassza ki a dátumok, számok és mértékegységek megjelenítési módját.',
			'settings.metadataLanguage' => 'Metaadatok nyelve',
			'settings.metadataLanguageDescription' => 'A címek és leírások előnyben részesített nyelve, ha a kiszolgáló támogatja. A hang és a felirat nyelve külön állítható be.',
			'settings.enterFullscreenOnPlaybackStart' => 'Helyezze be a teljes képernyőt, amikor megkezdődik a playback',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Nyissa meg az asztali videót a teljes képernyőn, amikor elkezdődik a playback',
			'settings.extendVideoIntoDisplayCutout' => 'Videó bővítése a Display Cutout-ba',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Hagyja, hogy a teljes képernyős videó használja a fényképezőgép cutout az Android telefonok',
			'settings.languageDescription' => 'Válassza ki a használt nyelvet PlezyNG vezérlők és üzenetek. kövesse a rendszer nyomon követése a készülék nyelvét.',
			'settings.themeDescription' => 'Válassza ki az alkalmazás során használt színeket és kontrasztokat.',
			'settings.libraryDensityDescription' => 'Változtassa meg, hogy hány könyvtári kártyát alkalmaznak minden sorban.',
			'settings.displayScaleDescription' => 'Visszaállítsa a felületet ebben az autó képernyőjén anélkül, hogy megváltoztatná a készülék szerinti szöveges méretét.',
			'settings.themeSongVolumeDescription' => 'Állítsa be a tematikus dalok mennyiségét más audio-hoz képest.',
			'settings.viewModeDescription' => 'Válassza ki, hogy a könyvtár elemei plakátként jelennek meg egy hálózatban vagy kompakt listaként.',
			'settings.gridViewDescription' => 'Szervezze a könyvtári elemeket poszterek soraiban és oszlopaiban.',
			'settings.listViewDescription' => 'A könyvtár elemeinek megjelenítése egy függőleges listában, több szöveggel elemenként.',
			'settings.gridSpacingDescription' => 'Állítsa be a plakátok közötti távolságot a könyvtári hálózatokban.',
			'settings.gridSpacingTightDescription' => 'A képernyőn több plakátot illeszkedik kisebb távolságokkal.',
			'settings.gridSpacingNormalDescription' => 'Használja a plakátok közötti szabványos távolságot.',
			'settings.gridSpacingSpaciousDescription' => 'Hozzon nagyobb távolságokat a plakátok között, hogy több szétválasztást kapjon.',
			'settings.episodePosterModeDescription' => 'Válassza ki, melyik műalkotás jelenik meg az epizódkártyákon.',
			'settings.seriesPosterDescription' => 'Használja a show-sorozat plakátját minden epizódhoz.',
			'settings.seasonPosterDescription' => 'Használja a szezon plakátot minden epizódra, amikor elérhető.',
			'settings.episodeThumbnailDescription' => 'Használjon egy keretet az epizódból, amikor elérhető.',
			'settings.continueWatchingActionDescription' => 'Válassza ki, hogy mi történik, amikor aktiválja a Folyamatos megfigyelési kártyát.',
			'settings.continueWatchingPlayDescription' => 'Azonnal indítsa el a filmet vagy az epizódot.',
			'settings.continueWatchingDetailsDescription' => 'Nyissa meg először a címlapot, hogy áttekinthesse az adatokat és válasszon egy lépést.',
			'settings.episodeActionDescription' => 'Válassza ki, mi történik, amikor egy epizódkártya aktiválódik.',
			'settings.episodePlayDescription' => 'Az epizód azonnal megkezdődik.',
			'settings.episodeDetailsDescription' => 'Nyissa meg az epizód oldalt a playback előtt.',
			'settings.contentScreensaverDelayDescription' => 'Válassza ki, hogy mennyi időt vár a PlezyNG bevitele nélkül, mielőtt műalkotást mutatna.',
			'settings.continueWatchingRowSizeDescription' => 'Válassza ki, hogy a kártyák hány méretűek a Folyamatos megfigyelési sorban.',
			'settings.rowSizeCompactDescription' => 'Nézze meg a kisebb kártyákat, hogy több elem megfeleljen a soron.',
			'settings.rowSizeStandardDescription' => 'Használja a kártya méretét.',
			'settings.rowSizeLargeDescription' => 'Nézze meg a nagyobb kártyákat több műalkotási részletekkel.',
			'settings.visualEffectsDescription' => 'Válassza ki az animációs és művészeti hatások költségvetését erre a készülékre.',
			'settings.visualEffectsFullDescription' => 'Használja a teljes animációs és műalkotási hatásokat minden eszközön.',
			'settings.startupSectionDescription' => 'Válassza ki, melyik szakasz megnyílik, amikor a PlezyNG elindul.',
			'settings.startupSectionOptions.discover' => 'Nyissa meg az ajánlásokat és a kapcsolódó felfedezési forrásokból származó elemeket.',
			'settings.startupSectionOptions.libraries' => 'Nyissa meg a kapcsolódó média könyvtárakat.',
			'settings.startupSectionOptions.liveTv' => 'Nyissa meg a Live TV-t, amikor egy szerver biztosítja azt; különben a startup visszatér a Házba.',
			'settings.startupSectionOptions.search' => 'Nyílt média keresés.',
			'settings.smallSkipDurationDescription' => 'Állítsa be a távolságot, amelyet a rövid hátsó és előre irányításokat keres.',
			'settings.largeSkipDurationDescription' => 'Állítsa be a távolságot, amelyet a hosszú hátsó és előre irányításokat keres.',
			'settings.rewindOnResumeDescription' => 'Ezzel az összeggel mozgatja a lejátszást, amikor egy videót újra készítenek.',
			'settings.defaultSleepTimerDescription' => 'Állítsa be a használt kezdeti időtartamot, amikor elkezdi az alvási időszámítást.',
			'settings.playNextCountdownDescription' => 'Várjon sokáig, mielőtt elkezdené a következő epizódot. 0-ra állítsa be, hogy azonnal kezdődjön.',
			'settings.autoSkipDelaySettingDescription' => 'Alkalmazható, amikor egy intro, kredit vagy hirdetés beállítva automatikusan elhagyja.',
			'settings.downmixCenterBoostDescription' => 'Emelje fel a párbeszédet a központi csatornában, amikor a környező hangot sztereóba keverjük össze.',
			'settings.displaySwitchDelayDescription' => 'Várjon, mielőtt megváltoztatná a kijelző üzemmódját, hogy a TV vagy a fogadó befejezheti az előző váltót.',
			'settings.playerBackendDescription' => 'Válassza ki, melyik lejátszó motor dekódolja és visszahívja a videót ezen az eszközön.',
			'settings.exoPlayerDescription' => 'Használja az Android indiai Media3 alapú lejátszóját és a támogatott hardverpályait.',
			'settings.mpvDescription' => 'Használja az MPV-t, amely további lejátszásokat, alfejezeteket és videó feldolgozási ellenőrzéseket mutat be.',
			'settings.scopeOffDescription' => 'Csak a jelenlegi lejátszásra vonatkozó módosításokat tartsa fenn.',
			'settings.scopeGlobalDescription' => 'Ismét használja ugyanazt az értéket minden könyvtár és cím.',
			'settings.scopeLibraryDescription' => 'Emlékezzünk egy külön értékre minden könyvtár számára.',
			'settings.scopeTitleDescription' => 'Emlékezzünk egy külön értékre minden előadásra vagy filmre.',
			'settings.specialsOrderingServerDescription' => 'Tartsa meg a média szerver által biztosított epizódrendet.',
			'settings.specialsOrderingAirDateDescription' => 'Helyezze a különlegeseket a rendszeres epizódok között a levegő dátumánál.',
			'settings.specialsOrderingLastDescription' => 'Minden különleges helyet a rendszeres szezonok után.',
			'settings.skipIntroModeDescription' => 'Válassza ki, hogy az intro markerek normálisan játszanak-e, mutatnak egy ugrás gombot vagy automatikusan ugrálnak.',
			'settings.skipCreditsModeDescription' => 'Válassza ki, hogy a hitelek normálisan játszanak-e, jelezzen egy ugrás gombot, vagy automatikusan ugrik.',
			'settings.skipAdsModeDescription' => 'Válassza ki, hogy a kimutatott hirdetések normálisan játszanak-e, mutatnak egy ugrás gombot, vagy automatikusan ugrálnak.',
			'settings.playbackBufferAutoDescription' => 'Hagyja, hogy az aktív játékos kiválassza a normális buffer méretét.',
			'settings.playbackBufferLargeDescription' => 'Tartsa több médiát készen a lejátszást megelőzően; ez több memóriát használ.',
			'settings.playbackBufferExtraLargeDescription' => 'Tartsa a legnagyobb olvasási-felület buffer; ez használja a legtöbb memóriát.',
			'settings.defaultQualityDescription' => 'Állítsa be az alapértelmezett videó felbontást és bitrat tetőt a szerver által transzkódolt áramlásokhoz.',
			'settings.cellularQualityDescription' => 'Az alapértelmezett minőség felülvizsgálata, amikor a készülék csak celluláris kapcsolatot használ.',
			'settings.remoteQualityDescription' => 'Az alapértelmezett minőség felülvizsgálata a szerverhez való csatlakozás során egy távoli kapcsolaton keresztül.',
			'settings.qualityPresetOriginalDescription' => 'Játssz a forrást a rendelkezésre álló minőségben anélkül, hogy kérné a kiszolgálót, hogy transzkódolja azt.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Kérje meg a szervert egy átalakított áram használatával a felbontás és bitrate látható fent.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Használja a kiválasztott minőséget az alapértelmezett minőségben.',
			'settings.musicQualityDescription' => 'Állítsa be a szervertől megkövetelt maximális hangbiterességet; Az eredeti tartja a forrásáramlást.',
			'settings.musicQualityOriginalDescription' => 'Játssz a forráskódot bitrate-capped transcode nélkül.',
			'settings.musicQualityTranscodeOptionDescription' => 'Kérjen egy szerver transzkódot, amely a fenti bitrate közelében van rögzítve; a tényleges kimenetel változhat.',
			'settings.maxVolumeInputLabel' => 'Maximális térfogat (%)',
			'settings.checkForUpdatesDescription' => 'Most ellenőrizze, hogy a PlezyNG újabb verziója elérhető-e.',
			'settings.appearanceDescription' => 'Válassza ki az alkalmazás témáját, és módosítsa a könyvtári kártyákat, az otthoni sorokat és a navigációt.',
			'settings.prerollLibraryDescription' => 'Válassza ki a könyvtárat, amely tartalmazza a klipek elérhető film pre-rolls.',
			'settings.prerollSelectionDescription' => 'Válassza ki, hogy mely klipek a kiválasztott könyvtár játszhat előtt filmek.',
			'settings.contentScreensaverDelayOptionDescription' => 'Várjon sok percet bejutás nélkül, mielőtt a screensaver műalkotást mutatja.',
			'settings.videoCodecOptionDescription' => 'Engedje meg a közvetlen lejátszást erre a kódolóra, amikor támogatásra kerül. A nem ellenőrzött kódokat a média szerver átruházza.',
			'themeEditor.builtIn' => 'Beépített',
			'themeEditor.presets' => 'Előre beállított',
			'themeEditor.custom' => 'Egyéni',
			'themeEditor.customEmpty' => 'Még nincs létrehozva',
			'themeEditor.editCustom' => 'Egyéni téma szerkesztése',
			'themeEditor.editCustomDescription' => 'Válaszd ki magad az összes színt',
			'themeEditor.locked' => 'Élethosszú hozzáférés szükséges',
			'themeEditor.savedLocked' => 'Megtakarítás – élethosszig tartó hozzáféréssel rendelkezésre áll',
			'themeEditor.title' => 'Egyéni téma',
			'themeEditor.startFrom' => 'Kiindulási téma',
			'themeEditor.startFromDescription' => 'Az összes szín átmásolása egy másik témából',
			'themeEditor.colors' => 'Színek',
			'themeEditor.preview' => 'Előnézet',
			'themeEditor.slots.bg' => 'Háttér',
			'themeEditor.slots.surface' => 'Felület',
			'themeEditor.slots.outline' => 'Körvonal',
			'themeEditor.slots.text' => 'Szöveg',
			'themeEditor.slots.textMuted' => 'Másodlagos szöveg',
			'themeEditor.slots.accent' => 'Kiemelőszín',
			'themeEditor.opacity' => 'Átlátszatlanság',
			'themeEditor.hexHint' => '#RRGGBB vagy #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Más témákból',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} – ${color}',
			'themeEditor.contrast.textOnBg' => 'Szöveg a háttéren',
			'themeEditor.contrast.textOnSurface' => 'Szöveg a felületen',
			'themeEditor.contrast.textMutedOnBg' => 'Másodlagos szöveg a háttéren',
			'themeEditor.contrast.textMutedOnSurface' => 'Másodlagos szöveg a felületen',
			'themeEditor.contrast.accentOnBg' => 'Kiemelőszín a háttéren',
			'themeEditor.contrast.accentOnSurface' => 'Kiemelőszín a felületen',
			'themeEditor.contrast.labelOnAccent' => 'Gombfelirat a kiemelőszínen',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, az ajánlott ${minimum}:1 alatt',
			'themeEditor.discardTitle' => 'Elveted a módosításokat?',
			'themeEditor.discardMessage' => 'A nem mentett színmódosítások elvesznek.',
			'themeEditor.discard' => 'Elvetés',
			'themeEditor.previewCardTitle' => ({required Object number}) => '${number}. epizód',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} perc van hátra',
			'themeEditor.previewSwitch' => 'Automatikus lejátszás',
			'themeEditor.previewMutedText' => 'Így néz ki a másodlagos szöveg',
			'themeEditor.themeSystemDescription' => 'Kövesse a készülék megjelenését, és automatikusan váltja át a fényt és a sötétet.',
			'themeEditor.themeLightDescription' => 'Használjon fényes háttérrel sötét szöveggel.',
			'themeEditor.themeDarkDescription' => 'Használjon sötét háttérrel fényes szöveggel.',
			'themeEditor.themeOledDescription' => 'Használjon közel fekete felületeket, amelyek csökkentik a fényt az OLED képernyőn.',
			'themeEditor.themeEmberDescription' => 'Használjon meleg vörös és amber hangsúlyos színeket.',
			'themeEditor.themeGlacierDescription' => 'Használja a hideg kék színt.',
			'themeEditor.themeForestDescription' => 'Használjon zöld és természetes hangsúlyos színeket.',
			'themeEditor.themePlumDescription' => 'Használjon lila és plum hangsúlyos színeket.',
			'themeEditor.themePaperDescription' => 'Használjon meleg papírszerű felületeket és tinta inspirált színeket.',
			'themeEditor.themeCustomDescription' => 'Használja az általad létrehozott színpalettát a személyre szabott tematikus szerkesztőben.',
			'themeEditor.editorDescription' => 'Válasszon egy palettás színt, módosítsa a hangját, telítettségét, fényességét vagy láthatatlanságát, és nézze meg az előzetes frissítést, mielőtt mentse.',
			'search.hint' => 'Keresés filmek, sorozatok és zenék között...',
			'search.tryDifferentTerm' => 'Próbálj másik keresési kifejezést',
			'search.searchYourMedia' => 'Keresés a saját médiatartalmak között',
			'search.enterTitleActorOrKeyword' => 'Adj meg egy címet, színészt vagy kulcsszót',
			'search.people' => 'Személyek',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Billentyűparancs beállítása ehhez: ${actionName}',
			'hotkeys.clearShortcut' => 'Billentyűparancs törlése',
			'hotkeys.noShortcutSet' => 'Nincs billentyűparancs beállítva',
			'hotkeys.currentShortcut' => 'Jelenlegi billentyűparancs:',
			'hotkeys.pressToRecord' => 'Válaszd ki a billentyűparancs rögzítéséhez',
			'hotkeys.recordingShortcut' => 'Nyomd meg most a billentyűparancsot',
			'hotkeys.actions.playPause' => 'Lejátszás/Szünet',
			'hotkeys.actions.volumeUp' => 'Hangerő fel',
			'hotkeys.actions.volumeDown' => 'Hangerő le',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Tekerés előre (${seconds} mp)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Tekerés hátra (${seconds} mp)',
			'hotkeys.actions.fullscreenToggle' => 'Teljes képernyős mód váltása',
			'hotkeys.actions.muteToggle' => 'Némítás be- és kikapcsolása',
			'hotkeys.actions.subtitleToggle' => 'Feliratok be- és kikapcsolása',
			'hotkeys.actions.audioTrackNext' => 'Következő hangsáv',
			'hotkeys.actions.subtitleTrackNext' => 'Következő feliratsáv',
			'hotkeys.actions.chapterNext' => 'Következő fejezet',
			'hotkeys.actions.chapterPrevious' => 'Előző fejezet',
			'hotkeys.actions.episodeNext' => 'Következő epizód',
			'hotkeys.actions.episodePrevious' => 'Előző epizód',
			'hotkeys.actions.speedIncrease' => 'Sebesség növelése',
			'hotkeys.actions.speedDecrease' => 'Sebesség csökkentése',
			'hotkeys.actions.speedReset' => 'Sebesség alaphelyzetbe állítása',
			'hotkeys.actions.zoomIn' => 'Nagyítás',
			'hotkeys.actions.zoomOut' => 'Kicsinyítés',
			'hotkeys.actions.zoomReset' => 'Nagyítás alaphelyzetbe állítása',
			'hotkeys.actions.subSeekNext' => 'Ugrás a következő feliratra',
			'hotkeys.actions.subSeekPrev' => 'Ugrás az előző feliratra',
			'hotkeys.actions.subtitleDelayIncrease' => 'Feliratok késleltetése',
			'hotkeys.actions.subtitleDelayDecrease' => 'Feliratok előrehozása',
			'hotkeys.actions.shaderToggle' => 'Shaderek be- és kikapcsolása',
			'hotkeys.actions.skipMarker' => 'Intró/stáblista átugrása',
			'hotkeys.actions.screenshot' => 'Képernyőkép készítése',
			'hotkeys.actions.framePrevious' => 'Előző Frame',
			'hotkeys.actions.frameNext' => 'Következő Frame',
			'fileInfo.title' => 'Fájlinformáció',
			'fileInfo.overview' => 'Áttekintés',
			'fileInfo.video' => 'Videó',
			'fileInfo.audio' => 'Hang',
			'fileInfo.subtitles' => 'Feliratok',
			'fileInfo.images' => 'Beágyazott képek',
			'fileInfo.dataStreams' => 'Adatfolyamok',
			'fileInfo.lyrics' => 'Dalszövegek',
			'fileInfo.file' => 'Fájl',
			'fileInfo.attachments' => 'Mellékletek',
			'fileInfo.delivery' => 'Kézbesítés',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => '${index}. verzió a(z) ${count} közül',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => '${index}. fájl a(z) ${count} közül',
			'fileInfo.noStreams' => 'A szerver nem jelentett adatfolyamot ehhez a fájlhoz.',
			'fileInfo.copyPath' => 'Útvonal másolása',
			'fileInfo.pathCopied' => 'Fájlútvonal kimásolva',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Kodekcímke',
			'fileInfo.resolution' => 'Felbontás',
			'fileInfo.codedResolution' => 'Kódolt felbontás',
			'fileInfo.bitrate' => 'Bitráta',
			'fileInfo.frameRate' => 'Képkockasebesség',
			'fileInfo.rotation' => 'Forgatás',
			'fileInfo.comment' => 'Megjegyzés',
			'fileInfo.audioDescription' => 'Hangleírás',
			'fileInfo.headerCompression' => 'Fejléc-tömörítés',
			'fileInfo.sidecarFile' => 'Kísérő fájl',
			'fileInfo.transportTimestamp' => 'Szállítási időbélyeg',
			'fileInfo.displayOffset' => 'Megjelenítési eltolás',
			'fileInfo.previewFailureCode' => 'Előnézeti hibakód',
			'fileInfo.previewRetries' => 'Előnézeti újrapróbálkozások',
			'fileInfo.aspectRatio' => 'Méretarány',
			'fileInfo.pixelAspectRatio' => 'Pixel képarány',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Szint',
			'fileInfo.bitDepth' => 'Bitmélység',
			'fileInfo.pixelFormat' => 'Pixelformátum',
			'fileInfo.colorSpace' => 'Színtér',
			'fileInfo.colorRange' => 'Színtartomány',
			'fileInfo.colorPrimaries' => 'Elsődleges színek',
			'fileInfo.colorTransfer' => 'Színátvitel',
			'fileInfo.chromaSubsampling' => 'Krominancia-alulmintavételezés',
			'fileInfo.chromaLocation' => 'Kroma elhelyezkedés',
			'fileInfo.scanType' => 'Pásztázási típus',
			'fileInfo.interlaced' => 'Váltott soros',
			'fileInfo.anamorphic' => 'Anamorf',
			'fileInfo.referenceFrames' => 'Referencia képkockák',
			'fileInfo.dynamicRange' => 'Dinamikatartomány',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision szint',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision verzió',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision rétegek',
			'fileInfo.baseLayerCompatibility' => 'Alapréteg-kompatibilitás',
			'fileInfo.avcBitstream' => 'AVC bitfolyam',
			'fileInfo.nalLengthSize' => 'NAL hosszméret',
			'fileInfo.scalingMatrix' => 'Egyéni méretezési mátrix',
			'fileInfo.streamIdentifier' => 'Adatfolyam-azonosító',
			'fileInfo.streamIndex' => 'Adatfolyam-index',
			'fileInfo.streamId' => 'Adatfolyam azonosítója',
			'fileInfo.language' => 'Nyelv',
			'fileInfo.languageCode' => 'Nyelvkód',
			'fileInfo.streamTitle' => 'Sáv címe',
			'fileInfo.channels' => 'Csatornák',
			'fileInfo.sampleRate' => 'Mintavételi frekvencia',
			'fileInfo.spatialAudio' => 'Térbeli hang',
			'fileInfo.textBased' => 'Szövegalapú',
			'fileInfo.subtitleFormat' => 'Kísérő formátum',
			'fileInfo.provider' => 'Szolgáltató',
			'fileInfo.matchScore' => 'Egyezési pontszám',
			'fileInfo.externalDelivery' => 'Külön is kiszolgálható',
			'fileInfo.sidecarPath' => 'Kísérő fájl útvonala',
			'fileInfo.sourceStream' => 'Másolva innen',
			'fileInfo.temporary' => 'Ideiglenes',
			'fileInfo.timeBase' => 'Időalap',
			'fileInfo.overallBitrate' => 'Összesített bitráta',
			'fileInfo.path' => 'Elérési út',
			'fileInfo.fileName' => 'Fájlnév',
			'fileInfo.size' => 'Méret',
			'fileInfo.totalSize' => 'Teljes méret',
			'fileInfo.container' => 'Konténer',
			'fileInfo.duration' => 'Időtartam',
			'fileInfo.previewThumbnails' => 'Előnézeti miniatűrök',
			'fileInfo.previewIndex' => 'Előnézeti index',
			'fileInfo.packetLength' => 'Csomaghossz',
			'fileInfo.filePresent' => 'Fájl jelen van',
			'fileInfo.fileReadable' => 'A szerver számára olvasható',
			'fileInfo.streamPath' => 'Adatfolyam útvonala',
			'fileInfo.optimizedForStreaming' => 'Adatfolyam-továbbításra optimalizálva',
			'fileInfo.has64bitOffsets' => '64 bites eltolások',
			'fileInfo.protocol' => 'Protokoll',
			'fileInfo.mediaType' => 'Médiatípus',
			'fileInfo.sourceKind' => 'Forrás típusa',
			'fileInfo.optimizedVersion' => 'Optimalizált verzió',
			'fileInfo.optimizationTarget' => 'Optimalizálási cél',
			'fileInfo.deletedAt' => 'Törölve',
			'fileInfo.remoteSource' => 'Távoli forrás',
			'fileInfo.infiniteStream' => 'Végtelen adatfolyam',
			'fileInfo.directPlay' => 'Közvetlen lejátszás',
			'fileInfo.directStream' => 'Közvetlen adatfolyam',
			'fileInfo.transcoding' => 'Átkódolás',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Verzióazonosító',
			'fileInfo.fileId' => 'Fájlazonosító',
			'fileInfo.defaultAudioTrack' => 'Alapértelmezett hangsáv',
			'fileInfo.defaultSubtitleTrack' => 'Alapértelmezett feliratsáv',
			'fileInfo.subtitlesOff' => 'Ki',
			'fileInfo.flagDefault' => 'Alapértelmezett',
			'fileInfo.flagForced' => 'Kényszerített',
			'fileInfo.flagSelected' => 'Kiválasztva',
			'fileInfo.flagExternal' => 'Külső',
			'fileInfo.flagHearingImpaired' => 'Nagyothallóknak',
			'fileInfo.flagDub' => 'Szinkron',
			'fileInfo.flagOriginal' => 'Eredeti',
			'fileInfo.channelsMono' => 'Monó',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => '${profile} profil',
			'mediaMenu.markAsWatched' => 'Megjelölés megtekintettként',
			'mediaMenu.markAsUnwatched' => 'Megjelölés nem megtekintettként',
			'mediaMenu.removeFromContinueWatching' => 'Eltávolítás a folytatásból',
			'mediaMenu.viewDetails' => 'Részletek megtekintése',
			'mediaMenu.goToSeries' => 'Ugrás a sorozathoz',
			'mediaMenu.shufflePlay' => 'Véletlenszerű lejátszás',
			'mediaMenu.shuffleNotAvailableOffline' => 'A véletlenszerű lejátszás nem érhető el offline',
			'mediaMenu.fileInfo' => 'Fájlinformáció',
			'mediaMenu.deleteEpisodeFromServer' => 'Epizód törlése a szerverről',
			'mediaMenu.deleteSeasonFromServer' => 'Évad törlése a szerverről',
			'mediaMenu.deleteShowFromServer' => 'Sorozat törlése a szerverről',
			'mediaMenu.deleteMovieFromServer' => 'Film törlése a szerverről',
			'mediaMenu.deleteEpisodeTitle' => 'Töröljük ezt az epizódot?',
			'mediaMenu.deleteSeasonTitle' => 'Töröljük ezt az évadot?',
			'mediaMenu.deleteShowTitle' => 'Töröljük ezt a sorozatot?',
			'mediaMenu.deleteMovieTitle' => 'Töröljük ezt a filmet?',
			'mediaMenu.deleteEpisodeConfirm' => 'Epizód törlése',
			'mediaMenu.deleteSeasonConfirm' => 'Évad törlése',
			'mediaMenu.deleteShowConfirm' => 'Sorozat törlése',
			'mediaMenu.deleteMovieConfirm' => 'Film törlése',
			'mediaMenu.deleteAnyway' => 'Törlés mindenképp',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Véglegesen töröljük a(z) ${title} elemet a szerverről?',
			'mediaMenu.deleteMultipleWarning' => 'Ez magában foglalja az összes epizódot és azok fájljait.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: 'Ez törli az összes (${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) epizódot benne és a hozzá tartozó fájlt.', other: 'Ez törli az összes (${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) epizódot benne és a fájljaikat.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: 'Ez az elem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fájlban van tárolva, amely törlésre kerül.', other: 'Ez az elem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} fájlban van tárolva, és mindegyik törlésre kerül.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: 'További ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód is ugyanabban a fájlban van, és szintén törlésre kerül:', other: 'További ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód is ugyanabban a fájlban van, és szintén törlésre kerül:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'A PlezyNG nem tudta ellenőrizni, mely fájlokat távolítja el ez, ezért a fent nevezett elemnél többet is törölhet. Szakítsa meg és próbálja újra, vagy töröljön mindenképp.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'A szerver nem szolgáltatott fájladatokat ehhez az elemhez, ezért a PlezyNG nem tudja ellenőrizni, mely fájlokat távolít el. A fent nevezett elemnél többet is törölhet.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Médiaelem sikeresen törölve',
			'mediaMenu.mediaFailedToDelete' => 'Nem sikerült a médiaelem törlése',
			'mediaMenu.rate' => 'Értékelés',
			'mediaMenu.playFromBeginning' => 'Lejátszás az elejétől',
			'mediaMenu.playVersion' => 'Verzió lejátszása...',
			'rateSheet.title' => 'Értékelés',
			'rateSheet.server' => 'Szerver',
			'rateSheet.favorite' => 'Kedvenc',
			'rateSheet.favorited' => 'Kedvencekhez hozzáadva',
			'rateSheet.saved' => 'Mentve',
			'rateSheet.notAvailable' => 'Nincs találat',
			'rateSheet.noConnectedServices' => 'Az értékeléshez csatlakoztass egy szolgáltatást a Beállításokban.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-sorozat',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'megtekintve',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} százalék megtekintve',
			'accessibility.mediaCardUnwatched' => 'még nem láttad',
			'accessibility.tapToPlay' => 'Koppints a lejátszáshoz',
			'accessibility.decrease' => 'Csökkentés',
			'accessibility.increase' => 'Növelés',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} csökkentése',
			'accessibility.increaseValue' => ({required Object label}) => '${label} növelése',
			'accessibility.hue' => 'Árnyalat',
			'accessibility.saturation' => 'Telítettség',
			'accessibility.brightness' => 'Fényerő',
			'accessibility.hexColor' => 'Hex színkód',
			'accessibility.expandText' => 'Szöveg kibontása',
			'accessibility.collapseText' => 'Szöveg összecsukása',
			'accessibility.alphabetNavigation' => 'Ábécé szerinti navigáció',
			'accessibility.alphabetScrollHint' => 'A betűnkénti léptetéshez pöccints felfelé vagy lefelé',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => '${row}. sor a(z) ${rowCount} sorból, ${column}. oszlop a(z) ${columnCount} oszlopból',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => '${row}. sor a(z) ${rowCount} sorból',
			'accessibility.autoScrollPlay' => 'Automatikus görgetés indítása',
			'accessibility.autoScrollPause' => 'Automatikus görgetés szüneteltetése',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Vörös',
			'accessibility.green' => 'Zöld',
			'accessibility.blue' => 'kék',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'hozzáférhetőség',
			'accessibility.summary' => 'szöveg, kontraszt, mozgás és ellenőrzés',
			'accessibility.systemHint' => 'A készülék hozzáférhetőségének beállításait mindig alkalmazzák.Ezek a lehetőségek a PlezyNG egészében módosításokat adnak hozzá.',
			'accessibility.readability' => 'Olvasás és láthatóság',
			'accessibility.textSize' => 'További szövegméret',
			'accessibility.preview' => 'Olvasson, hallgasson és nézd meg a saját sebességedben.',
			'accessibility.boldText' => 'Bold Interface szöveg',
			'accessibility.highContrast' => 'Nagy kontraszt',
			'accessibility.highContrastHint' => 'Erősebb szöveg, kiemelkedések és a fényes vagy sötét felületeken lévő figyelemfelkeltő mutatók.',
			'accessibility.interaction' => 'Mozgás és interakció',
			'accessibility.reduceMotion' => 'Mozgás csökkentése',
			'accessibility.reduceMotionHint' => 'Állítsd le a fókuszjelző mozgását, az oldalátmeneteket és a díszítő animációkat.',
			'accessibility.largeTargets' => 'Nagyabb érintkezési célok',
			'accessibility.largeTargetsHint' => 'A megosztott vezérlők több helyet biztosítanak a hozzáféréshez és a segéd navigációhoz.',
			'accessibility.navigationHint' => 'A Tab és a Shift+Tab billentyűkkel léphetsz a vezérlők között, az Enter vagy a szóköz aktiválja őket, az Escape vagy a Vissza pedig bezár. Megnyitott könyvnél a nagyítás és az olvasási beállítások is elérhetők.',
			'accessibility.textSizeDescription' => 'Skála felület szöveg PlezyNG-ben a készülék rendszer szöveges méretének beállítása mellett.',
			'accessibility.boldTextHint' => 'Használjon súlyosabb felület címkéket és üzeneteket, hogy könnyebben megkülönböztessék őket.',
			'tooltips.shufflePlay' => 'Véletlenszerű lejátszás',
			'tooltips.playTrailer' => 'Előzetes lejátszása',
			'tooltips.markAsWatched' => 'Megjelölés megtekintettként',
			'tooltips.markAsUnwatched' => 'Megjelölés nem megtekintettként',
			'audioTracks.track' => ({required Object n}) => '${n}. hangsáv',
			'videoControls.audioLabel' => 'Hang',
			'videoControls.subtitlesLabel' => 'Feliratok',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Fekete sávok',
			'videoControls.fillScreen' => 'Képernyő kitöltése',
			'videoControls.stretch' => 'Nyújtás',
			'videoControls.lockRotation' => 'Forgatás zárolása',
			'videoControls.unlockRotation' => 'Forgatás feloldása',
			'videoControls.timerActive' => 'Időzítő aktív',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'A lejátszás ${duration} múlva szünetel',
			'videoControls.sleepTimerEndOfVideo' => 'Jelenlegi videó vége',
			'videoControls.sleepTimerStopAtHeader' => 'Leállítás ekkor',
			'videoControls.sleepTimerDurationHeader' => 'Időzítő',
			'videoControls.playbackWillPauseAtEnd' => 'A lejátszás szünetel a videó végén',
			'videoControls.stillWatching' => 'Még nézed?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Szüneteltetés ${seconds} mp múlva',
			'videoControls.continueWatching' => 'Folytatás',
			'videoControls.autoPlayNext' => 'Következő automatikus lejátszása',
			'videoControls.playNext' => 'Következő lejátszása',
			'videoControls.playButton' => 'Lejátszás',
			'videoControls.pauseButton' => 'Szünet',
			'videoControls.playbackPaused' => 'Szüneteltetve',
			'videoControls.playbackResumed' => 'Lejátszás',
			'videoControls.loadingVideo' => 'Videó betöltése',
			'videoControls.showPlaybackControls' => 'Lejátszásvezérlők megjelenítése',
			'videoControls.hidePlaybackControls' => 'Lejátszásvezérlők elrejtése',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Tekerés hátra ${seconds} másodperccel',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Tekerés előre ${seconds} másodperccel',
			'videoControls.previousButton' => 'Előző epizód',
			'videoControls.nextButton' => 'Következő epizód',
			'videoControls.previousChapterButton' => 'Előző fejezet',
			'videoControls.nextChapterButton' => 'Következő fejezet',
			'videoControls.muteButton' => 'Némítás',
			'videoControls.unmuteButton' => 'Hang visszakapcsolása',
			'videoControls.settingsButton' => 'Lejátszási beállítások',
			'videoControls.tracksButton' => 'Hang és feliratok',
			'videoControls.chaptersButton' => 'Fejezetek',
			'videoControls.segmentLoopHelp' => 'Az A beállítása, majd a B későbbi beállítás az idővonalon.',
			'videoControls.setLoopStart' => 'Kezdőlap Hírek A (A)',
			'videoControls.setLoopEnd' => 'A csúszás vége (B)',
			'videoControls.clearSegmentLoop' => 'Tiszta szegmens',
			'videoControls.setLoopStartFirst' => 'Állítsa be a pályát kezdődik (A) előtt a véget (B).',
			'videoControls.loopEndAfterStart' => 'A befejezésnek későn kell lennie, mint a kezdet.',
			'videoControls.segmentLoopUnavailable' => 'A Segment Looping nem érhető el ebben a playbackben.',
			'videoControls.loopPointNotSet' => 'Nem állít',
			'videoControls.bookmarksHelp' => 'A könyvjelzők ebben a készülékben kerülnek mentésre. Válassza ki az egyiket, hogy menjen erre az időre.',
			'videoControls.bookmarksButton' => 'könyvjelzők',
			'videoControls.chaptersAndBookmarks' => 'fejezetek és könyvjelzők',
			'videoControls.segmentLoop' => 'Segmentális lejátszás',
			'videoControls.addBookmark' => 'Hozzáadása Bookmark',
			'videoControls.bookmarkName' => 'Bookmark név',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Például a színpad megnyitása',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'könyvjelző ${n}',
			'videoControls.bookmarkNameRequired' => 'Írjon be egy nevet erre a könyvjelzőre.',
			'videoControls.deleteBookmark' => 'Távolítsa el a Bookmark',
			'videoControls.bookmarkLimitReached' => 'Ez a cikk már 100 könyvjelzővel rendelkezik.',
			'videoControls.bookmarkUnavailable' => 'Nem tudtam menteni vagy eltávolítani ezt a könyvjelzőt.',
			'videoControls.bookmarkSaved' => 'A könyv megmentett.',
			'videoControls.bookmarkDeleted' => 'Bookmark törlésre került.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Loop pont ${point} beállítása a ${time}A',
			'videoControls.noChaptersOrBookmarks' => 'Nincs rendelkezésre álló fejezetek vagy könyvjelzők.',
			'videoControls.versionQualityButton' => 'Verzió és minőség',
			'videoControls.versionColumnHeader' => 'Verzió',
			'videoControls.qualityColumnHeader' => 'Minőség',
			'videoControls.qualityOriginal' => 'Eredeti',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'A transzkódolás nem érhető el — eredeti minőség lejátszása',
			'videoControls.subtitleUnavailableFallback' => 'A kiválasztott feliratot nem sikerült betölteni — folytatás felirat nélkül',
			'videoControls.pipButton' => 'Kép a képben mód',
			'videoControls.aspectRatioButton' => 'Méretarány',
			'videoControls.ambientLighting' => 'Környezeti megvilágítás',
			'videoControls.fullscreenButton' => 'Teljes képernyős mód bekapcsolása',
			'videoControls.exitFullscreenButton' => 'Teljes képernyős mód kikapcsolása',
			'videoControls.alwaysOnTopButton' => 'Mindig legfelül',
			'videoControls.rotationLockButton' => 'Elforgatás zárolása',
			'videoControls.lockScreen' => 'Képernyő zárolása',
			'videoControls.screenLockButton' => 'Képernyőzár',
			'videoControls.timelineSlider' => 'Videó idősáv',
			'videoControls.volumeSlider' => 'Hangerő',
			'videoControls.endsAt' => ({required Object time}) => 'Vége: ${time}',
			'videoControls.pipActive' => 'Lejátszás kép a képben módban',
			'videoControls.pipFailed' => 'Nem sikerült elindítani a kép a képben módot',
			'videoControls.screenshotSaved' => 'Képernyőkép elmentve',
			'videoControls.screenshotFailed' => 'Nem sikerült képernyőképet készíteni',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Nagyítás ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Hangerő ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 vagy újabb szükséges',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 vagy újabb szükséges',
			'videoControls.pipErrors.permissionDisabled' => 'A kép a képben mód le van tiltva. Engedélyezd a rendszerbeállításokban.',
			'videoControls.pipErrors.notSupported' => 'Az eszköz nem támogatja a kép a képben módot',
			'videoControls.pipErrors.voSwitchFailed' => 'Nem sikerült átváltani a videókimenetet a kép a képben módhoz',
			'videoControls.pipErrors.failed' => 'Nem sikerült elindítani a kép a képben módot',
			'videoControls.pipErrors.prepareFailed' => 'Nem sikerült előkészíteni a kép a képben módot',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Hiba történt: ${error}',
			'videoControls.chapters' => 'Fejezetek',
			'videoControls.noChaptersAvailable' => 'Nincsenek elérhető fejezetek',
			'videoControls.queue' => 'Lejátszási sor',
			'videoControls.noQueueItems' => 'Nincsenek elemek a sorban',
			'videoControls.noAudioDevicesAvailable' => 'Nincsenek elérhető audioeszközök',
			'videoControls.searchSubtitles' => 'Feliratok keresése',
			'videoControls.language' => 'Nyelv',
			'videoControls.noSubtitlesFound' => 'Nem találhatók feliratok',
			'videoControls.subtitleDownloaded' => 'Felirat letöltve',
			'videoControls.subtitleDownloadedNotApplied' => 'Felirat letöltve, de nem sikerült kiválasztani',
			'videoControls.subtitleDownloadFailed' => 'Nem sikerült a felirat letöltése',
			'videoControls.searchLanguages' => 'Nyelvek keresése...',
			'videoControls.skipIntro' => 'Főcím átugrása',
			'videoControls.skipCredits' => 'Stáblista átugrása',
			'videoControls.nextEpisode' => 'Következő epizód',
			'videoControls.subtitleTrack' => ({required Object n}) => '${n}. sáv',
			'videoControls.subtitleFile' => ({required Object name}) => '${name} felirat',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (kényszerített)',
			'videoControls.osdSubtitlesOff' => 'Feliratok: ki',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Feliratok: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Hang: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} keretrendszer', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} keretek', ), 
			'videoControls.trackSelectionTitle' => 'Válassza ki a játékot a playback előtt',
			'videoControls.trackSelectionAuto' => 'Automatikus kiválasztás',
			'videoControls.openMiniPlayer' => 'Nyitott mini játékos',
			'videoControls.returnToFullPlayer' => 'Visszatérés a teljes játékoshoz',
			'videoControls.loadSubtitleFile' => 'A subtitle fájl felvétele...',
			'videoControls.subtitleLoadFailed' => 'Nem töltöttem fel a subtitle fájlt',
			'videoControls.skipAds' => 'Skip hirdetések',
			'videoControls.tapToUnlock' => 'Koppintson a feloldáshoz',
			'videoControls.tapAgainToUnlock' => 'Koppintson ismét a feloldáshoz',
			'messages.markedAsWatched' => 'Megjelölve megtekintettként',
			'messages.markedAsUnwatched' => 'Megjelölve nem megtekintettként',
			'messages.markedAsWatchedOffline' => 'Megjelölve megtekintettként (szinkronizálás online állapotban)',
			'messages.markedAsUnwatchedOffline' => 'Megjelölve nem megtekintettként (szinkronizálás online állapotban)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatikusan eltávolítva: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintett letöltés automatikusan eltávolítva', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintett letöltés automatikusan eltávolítva', ), 
			'messages.removedFromContinueWatching' => 'Eltávolítva a folytatásból',
			'messages.errorLoading' => ({required Object error}) => 'Hiba: ${error}',
			'messages.searchPartialResults' => 'Néhány médiaszervert nem sikerült keresni. Az elérhető találatok megjelenítése.',
			'messages.streamInterrupted' => 'Az adatfolyam megszakadt. Az újrapróbálkozáshoz indítsd el a lejátszást, vagy tekerj másik pozícióra.',
			'messages.liveStreamInterrupted' => 'Az élő adás megszakadt. Nyomd meg a lejátszást az újrapróbálkozáshoz.',
			'messages.fileInfoNotAvailable' => 'A fájlinformáció nem érhető el',
			'messages.playbackAuthenticationRequired' => 'Az elem lejátszásához jelentkezz be újra a médiaszerverre.',
			'messages.playbackServerUnavailable' => 'A médiaszerver nem érhető el. Próbáld újra később.',
			'messages.playbackDataInvalid' => 'A szerver érvénytelen lejátszási adatokat küldött.',
			'messages.playbackCancelled' => 'A lejátszás megszakítva.',
			'messages.playbackFailed' => 'Nem sikerült elindítani a lejátszást.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Nem sikerült elindítani a lejátszást: ${error}',
			'messages.audioOutputFailed' => 'A hangkimenet nem válaszol. Ellenőrizd a TV vagy az erősítő hangcsatlakozását; ha más alkalmazásokban sincs hang, indítsd újra az eszközt.',
			'messages.mediaUnavailable' => 'Ez a tartalom már nem érhető el.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Hiba a fájlinformációk betöltésekor: ${error}',
			'messages.errorLoadingSeries' => 'Hiba a sorozat betöltésekor',
			'messages.musicNotSupported' => 'A zenelejátszás még nem támogatott',
			'messages.noDescriptionAvailable' => 'Nincs elérhető leírás',
			'messages.noProfilesAvailable' => 'Nincsenek elérhető profilok',
			'messages.contactAdminForProfiles' => 'Lépj kapcsolatba a szerver adminisztrátorával profilok hozzáadásához',
			'messages.unableToDetermineLibrarySection' => 'Nem sikerült meghatározni az elem könyvtári részlegét',
			'messages.logsCleared' => 'Naplók törölve',
			'messages.logsCopied' => 'Naplók a vágólapra másolva',
			'messages.noLogsAvailable' => 'Nincsenek elérhető naplók',
			'messages.libraryScanning' => ({required Object title}) => '"${title}" beolvasása...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Könyvtár beolvasása elindítva a következőhöz: "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Nem sikerült a könyvtár beolvasása: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metaadatok frissítése a következőhöz: "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metaadatok frissítése elindítva a következőhöz: "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Nem sikerült a metaadatok frissítése: ${error}',
			'messages.logoutConfirm' => 'Biztosan ki szeretnél jelentkezni?',
			'messages.noSeasonsFound' => 'Nem találhatók évadok',
			'messages.seasonsLoadFailed' => 'Nem sikerült az évadok betöltése',
			'messages.noEpisodesFound' => 'Nem találhatók epizódok az első évadban',
			'messages.noEpisodesFoundGeneral' => 'Nem találhatók epizódok',
			'messages.episodesLoadFailed' => 'Nem sikerült az epizódok betöltése',
			'messages.noResultsFound' => 'Nincs találat',
			'messages.sleepTimerSet' => ({required Object label}) => 'Elalvási időzítő beállítva: ${label}',
			'messages.noItemsAvailable' => 'Nincsenek elérhető elemek',
			'messages.failedToCreatePlayQueueNoItems' => 'Nem sikerült létrehozni a lejátszási sort — nincsenek elemek',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Nem sikerült a művelet (${action}): ${error}',
			'messages.switchingToCompatiblePlayer' => 'Váltás kompatibilis lejátszóra...',
			'messages.serverLimitTitle' => 'A lejátszás nem sikerült',
			'messages.serverLimitBody' => 'Szerverhiba (HTTP 500). A munkamenetet valószínűleg egy sávszélességi vagy átkódolási korlát utasította el. Kérd meg a tulajdonost a korlát módosítására.',
			'messages.mediaUnreadableTitle' => 'A fájl nem érhető el',
			'messages.mediaUnreadableBody' => 'A szerver megtalálta ezt az elemet, de nem tudta beolvasni a fájlját (HTTP 404). A fájl valószínűleg áthelyezésre vagy törlésre került, vagy a tárhelye offline. Kérje meg a szerver tulajdonosát, hogy ellenőrizze a fájlt, és vizsgálja újra a könyvtárat.',
			'messages.serverBusyTitle' => 'A stream nem érhető el',
			'messages.serverBusyBody' => 'A szerver ismételten megtagadta ennek a fájlnak a streamelését (HTTP 503). Lehet, hogy újraindul, túlterhelt, vagy a fájl tárhelye nem érhető el. Próbáld újra egy kis idő múlva – ha a probléma továbbra is fennáll, kérd meg a szerver tulajdonosát, hogy ellenőrizze a szervert és a fájl tárhelyét.',
			'messages.playbackNotAllowedTitle' => 'A lejátszás nem engedélyezett',
			'messages.playbackNotAllowedBody' => 'A szerver megtagadta ennek az elemnek a streamelését (HTTP 403). Lehet, hogy a fiókodnak nincs engedélye a lejátszására, vagy a szerver csak a helyi hálózatán engedélyezi a lejátszást.',
			'messages.logsUploaded' => 'Naplók feltöltve',
			'messages.logsUploadFailed' => 'Nem sikerült a naplók feltöltése',
			'messages.logId' => 'Naplóazonosító',
			'messages.burnedSubtitlesUseMenu' => 'A feliratok bele vannak égetve ebbe a streambe. A feliratmenüben módosíthatod őket.',
			'messages.noVideoUrl' => 'Nem érhető el videó-URL',
			'messages.playbackNoMediaSources' => 'A szerver nem adott vissza lejátszható médiaforrást',
			'messages.playbackDataNotPrepared' => 'A lejátszás az adatok elkészülte előtt indult el',
			'messages.streamSelectionUnavailable' => 'Ehhez a forráshoz nem érhető el a streamek kiválasztása',
			'messages.streamSelectionFailed' => 'Nem sikerült alkalmazni a kiválasztott streameket',
			'messages.trackSelectionNotRemembered' => 'Ez a sávválasztás csak az aktuális lejátszásra érvényes.',
			'messages.serverUnavailableForProfile' => 'Az aktív profilhoz nem érhető el szerver',
			'subtitlingStyling.previewSample' => 'A gyors barna fox a szégyenletes kutya fölé ugrik',
			'subtitlingStyling.text' => 'Szöveg',
			'subtitlingStyling.border' => 'Keret',
			'subtitlingStyling.background' => 'Háttér',
			'subtitlingStyling.fontSize' => 'Betűméret',
			'subtitlingStyling.textColor' => 'Szövegszín',
			'subtitlingStyling.borderSize' => 'Keretméret',
			'subtitlingStyling.borderColor' => 'Keretszín',
			'subtitlingStyling.backgroundOpacity' => 'Háttér átlátszatlansága',
			'subtitlingStyling.backgroundColor' => 'Háttérszín',
			'subtitlingStyling.position' => 'Pozíció',
			'subtitlingStyling.assOverride' => 'ASS felülbírálása',
			'subtitlingStyling.overrideScale' => 'Skálázás',
			'subtitlingStyling.overrideForce' => 'Kényszerítés',
			'subtitlingStyling.overrideStrip' => 'Stílus eltávolítása',
			'subtitlingStyling.positionTop' => 'Fent',
			'subtitlingStyling.positionBottom' => 'Lent',
			'subtitlingStyling.useMargins' => 'Margók használata',
			'subtitlingStyling.useMarginsDescription' => 'A szöveges feliratok a videón kívüli területen is megjelenhetnek. A stilizált feliratok megtarthatják eredeti pozíciójukat.',
			'subtitlingStyling.anchorToScreen' => 'Képernyőhöz rögzítés',
			'subtitlingStyling.anchorToScreenDescription' => 'A szöveges feliratok megjelenítése a szélesvásznú videó alatti fekete sávban',
			'subtitlingStyling.bold' => 'Félkövér',
			'subtitlingStyling.italic' => 'Dőlt',
			'subtitlingStyling.renderResolution' => 'Renderelési felbontás',
			'subtitlingStyling.renderResolutionScreen' => 'Képernyőfelbontás',
			'subtitlingStyling.renderResolutionVideo' => 'Videófelbontás',
			'subtitlingStyling.fontSizeDescription' => 'Állítsa be a szöveg méretét ezen az eszközön.',
			'subtitlingStyling.textColorDescription' => 'Válassza ki a szöveg színét.',
			'subtitlingStyling.borderSizeDescription' => 'Állítsa be a nyomtatvány vastagságát az alszöveg szövegének körül.',
			'subtitlingStyling.borderColorDescription' => 'Válassza ki a színét, amelyet az alfejezéshez használnak.',
			'subtitlingStyling.backgroundColorDescription' => 'Válassza ki a színét az alszöveg szövegének hátterében.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Állítsa be, hogy a háttér mennyire átlátszó: 0% világos és 100% szilárd.',
			'subtitlingStyling.positionDescription' => '0 % a videó tetején, és 100% az alsó.',
			'subtitlingStyling.assOverrideDescription' => 'Válassza ki, hogy a játékos követi-e, módosítja, helyettesíti vagy eltávolítja az ASS altitkokba beépített stílust.',
			'subtitlingStyling.assOverrideOptions.no' => 'Tartsa a betűtípusokat, színeket, méreteket és elhelyezkedést az alszámfájlban.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Engedje meg a játékos szubtitkár stílusának beállításait, hogy igazítsa az ASS szubtiteleket.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Alkalmazza a játékos stílusát és a beágyazott méreteket, hogy megfeleljen a videó dimenzióknak.',
			'subtitlingStyling.assOverrideOptions.force' => 'A beágyazott ASS stílusok helyettesítése a játékos szubtitlap stílusával.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Távolítsa el a beágyazott ASS formázást, és egyértelművé tegye az alszöveg szöveget.',
			'subtitlingStyling.renderResolutionDescription' => 'Válassza ki a felbontást, amelyet a kép és az ASS altitkok rasterizálására használnak. Alacsonyabb Android skálák csökkenthetik a rendering munkát, de látszólag vékonyabbak.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render a teljes kijelző felületfelbontáson a legsűrűbb eredmény érdekében.',
			'subtitlingStyling.renderResolutionOptions.video' => 'A videó felbontását a referenciaként használja, ami csökkenti a nagy hatékonyságú kijelzők munkáját.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'A képernyőfelület felbontásának 75% -a a mérsékelt teljesítménymegtakarítás érdekében.',
			'subtitlingStyling.renderResolutionOptions.half' => 'A képernyő felületfelbontásának 50% -ára csökkenti a munkát, vékonyabb szélességekkel.',
			'subtitlingStyling.renderResolutionOptions.third' => 'A kijelző felszíni felbontásának egyharmada a munka csökkentése érdekében, vékonyabb szélességekkel.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'A képernyő felszíni felbontásának egyharmada a munka csökkentése érdekében, a legszélesebb eredményt.',
			'subtitlingStyling.boldDescription' => 'Írja le a szubtitkár szövegét súlyosabb súlyban.',
			'subtitlingStyling.italicDescription' => 'Írja le az olasz nyelvű szöveget.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Haladó videólejátszó beállítások',
			'mpvConfig.presets' => 'Előbeállítások',
			'mpvConfig.noPresets' => 'Nincsenek mentett előbeállítások',
			'mpvConfig.saveAsPreset' => 'Mentés előbeállításként...',
			'mpvConfig.presetName' => 'Előbeállítás neve',
			'mpvConfig.presetNameHint' => 'Add meg az előbeállítás nevét',
			'mpvConfig.loadPreset' => 'Betöltés',
			'mpvConfig.deletePreset' => 'Törlés',
			'mpvConfig.presetSaved' => 'Előbeállítás mentve',
			'mpvConfig.presetLoaded' => 'Előbeállítás betöltve',
			'mpvConfig.presetDeleted' => 'Előbeállítás törölve',
			'mpvConfig.confirmDeletePreset' => 'Biztosan törölni szeretnéd ezt az előbeállítást?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# megjegyzés',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Sor hozzáadása',
			'mpvConfig.removeLine' => 'Sor eltávolítása',
			'mpvConfig.embeddedVoHint' => 'A vo, gpu-context és gpu-api beállítások Linuxon figyelmen kívül maradnak: a beágyazott videó mindig a vo=libmpv-n keresztül jelenik meg a videósíkon, a gpu-next (amelyre az ArtCNN-hez hasonló compute shadereknek szükségük van) pedig nem futhat beágyazva.',
			'dialog.confirmAction' => 'Művelet megerősítése',
			'profiles.addPlezyProfile' => 'PlezyNG profil hozzáadása',
			'profiles.switchingProfile' => 'Profilváltás…',
			'profiles.deleteThisProfileTitle' => 'Törlöd ezt a profilt?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} eltávolítása. A kapcsolatokat nem érinti.',
			'profiles.active' => 'Aktív',
			'profiles.manage' => 'Kezelés',
			'profiles.delete' => 'Törlés',
			'profiles.signOut' => 'Kijelentkezés',
			'profiles.signOutPlexTitle' => 'Kijelentkezel a Plexből?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és az összes Plex Home-felhasználót? Bármikor visszajelentkezhetsz.',
			'profiles.signOutPlexDeleteDownloads' => 'A letöltések törlése is',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Ellenkező esetben az eszközön maradnak, és újra megjelennek, amikor visszajelentkezel ebbe a fiókba.',
			'profiles.signedOutPlex' => 'Kijelentkezve a Plexből.',
			'profiles.signOutFailed' => 'A kijelentkezés nem sikerült.',
			'profiles.sectionTitle' => 'Profilok',
			'profiles.summarySingle' => 'Adj hozzá profilokat a kezelt felhasználók és a helyi profilok együttes használatához',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profil · aktív: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profil',
			'profiles.removeConnectionTitle' => 'Eltávolítod a kapcsolatot?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Eltávolítod ${displayName} hozzáférését a(z) ${connectionLabel} kapcsolathoz. Más profilok megtartják.',
			'profiles.deleteProfileTitle' => 'Törlöd a profilt?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és annak kapcsolatait. A szerverek elérhetőek maradnak.',
			'profiles.profileNameLabel' => 'Profil neve',
			'profiles.pinProtectionLabel' => 'PIN-kódos védelem',
			'profiles.copyAutomationLink' => 'Android automatizálási link',
			'profiles.copyAutomationLinkDescription' => 'Válassza ki ezt a profilot a Android szándékból vagy automatizálásból.',
			'profiles.automationLinkCopied' => 'Profil automatizálása link másolt.',
			'profiles.pinManagedByPlex' => 'A PIN-kódot a Plex kezeli. Szerkesztés a plex.tv oldalon.',
			'profiles.noPinSetEditOnPlex' => 'Nincs PIN beállítva. PIN kéréséhez szerkeszd az otthoni felhasználót a plex.tv-n.',
			'profiles.setPin' => 'PIN beállítása',
			'profiles.setPinTitle' => 'PIN beállítása',
			'profiles.confirmPinTitle' => 'PIN megerősítése',
			'profiles.pinSet' => 'PIN beállítva',
			'profiles.changePin' => 'Módosítás',
			'profiles.removePin' => 'Eltávolítás',
			'profiles.connectionsLabel' => 'Kapcsolatok',
			'profiles.add' => 'Hozzáadás',
			'profiles.deleteProfileButton' => 'Profil törlése',
			'profiles.noConnectionsHint' => 'Nincsenek kapcsolatok — adj hozzá egyet a profil használatához.',
			'profiles.noConnections' => 'Nincsenek kapcsolatok',
			'profiles.plexHomeAccount' => 'Plex Home-fiók',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex-fiók: ${account}',
			'profiles.plexAccountUserChip' => ({required Object account, required Object user}) => '${account} fiókján keresztül: ${user}',
			'profiles.connectionDefault' => 'Alapértelmezett',
			'profiles.connectionAs' => ({required Object displayName}) => 'mint ${displayName}',
			'profiles.makeDefault' => 'Beállítás alapértelmezettként',
			'profiles.removeConnection' => 'Eltávolítás',
			'profiles.profileRenamed' => 'Profil átnevezve.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Hozzáadás a következőhöz: ${displayName}',
			'profiles.borrowExplain' => 'Használd egy másik profil kapcsolatát. A PIN-kóddal védett profilokhoz PIN-kód szükséges.',
			'profiles.borrowEmpty' => 'Még nincs használható kapcsolat.',
			'profiles.borrowEmptySubtitle' => 'Először csatlakoztasd a Plexet, a Jellyfint vagy az Embyt egy másik profilhoz.',
			'profiles.borrowLoadFailed' => 'Nem sikerült betölteni az elérhető kapcsolatokat. Próbáld újra.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Innen: ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Kapcsolat átvéve.',
			'profiles.borrowFailed' => 'Nem sikerült átvenni a kapcsolatot.',
			'profiles.incorrectPin' => 'Helytelen PIN-kód.',
			'profiles.incorrectPinTryAgain' => 'Helytelen PIN-kód. Próbáld újra.',
			'profiles.sourceProfileMissingParentAccount' => 'A forrásprofilból hiányzik a szülőfiók.',
			'profiles.failedToLoadHomeUsers' => 'Nem sikerült betölteni a Plex Home-felhasználókat. Ellenőrizd a kapcsolatot, majd próbáld újra.',
			'profiles.failedToVerifyPin' => 'Nem sikerült a PIN-kód ellenőrzése.',
			'profiles.newProfile' => 'Új profil',
			'profiles.profileNameHint' => 'pl. Vendégek, Gyerekek, Nappali',
			'profiles.pinProtectionOptional' => 'PIN-védelem (opcionális)',
			'profiles.pinExplain' => '4 jegyű PIN-kód szükséges a profilváltáshoz.',
			'profiles.continueButton' => 'Folytatás',
			'profiles.pinsDontMatch' => 'A PIN-kódok nem egyeznek',
			'profiles.tokenIdentityMismatch' => 'A Plex-profil tokenje nem a várt szerverhez tartozik',
			'profiles.settingsLocked' => 'A beállítások zárva vannak a profilhoz.',
			'profiles.unlockSettings' => 'A beállítások feloldása',
			'profiles.showExploreForProfile' => 'Show Explore for this profil - A profil megtekintése',
			'profiles.showExploreForProfileDescription' => 'Távolítsa el a Explore eltávolítását a profil navigációjából.',
			'connections.sectionTitle' => 'Kapcsolatok',
			'connections.addConnection' => 'Kapcsolat hozzáadása',
			'connections.addConnectionSubtitleNoProfile' => 'Jelentkezz be Plexszel, vagy csatlakoztass egy Jellyfin- vagy Emby-szervert',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Hozzáadás a következőhöz (${displayName}): Plex, Jellyfin, Emby vagy más profilkapcsolat',
			'connections.sessionExpiredOne' => ({required Object name}) => 'A(z) ${name} munkamenete lejárt',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} szerver munkamenete lejárt',
			'connections.accessDeniedOne' => ({required Object name}) => 'A(z) ${name} megtagadta a hozzáférést ettől a fióktól',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} szerver megtagadta a hozzáférést ettől a fióktól',
			'connections.signInAgain' => 'Bejelentkezés újra',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'A(z) ${product} kapcsolat szerkesztése',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Adjon hozzá vagy távolítson el URL-eket a(z) ${serverName} esetén. A PlezyNG a legkisebb késleltetésű, elérhető URL-t fogja használni.',
			'accountPreferences.sectionTitle' => 'Fiókbeállítások',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Hang-, felirat- és könyvtárbeállítások mentve a(z) ${account} fiókra',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Hang-, felirat- és könyvtárbeállítások mentve ${count} fiókra',
			'accountPreferences.pickAccount' => 'Minden fiók a saját beállításait tárolja. Válaszd ki a szerkesztendőt.',
			'accountPreferences.storedOnAccount' => 'Ezek a beállítások magán a fiókon tárolódnak, így minden bejelentkezett alkalmazás használja őket — beleértve a Plezyt a többi eszközödön.',
			'accountPreferences.noAccounts' => 'Nincs beállítható fiók',
			'accountPreferences.noAccountsHint' => 'Jelentkezz be a Plexbe, vagy csatlakoztass egy Jellyfin- vagy Emby-szervert, és az azon a fiókon tárolt beállítások itt jelennek meg.',
			'accountPreferences.unavailable' => 'Ez a fiók nem érhető el',
			'accountPreferences.loadFailed' => 'Nem sikerült betölteni ezeket a beállításokat',
			'accountPreferences.noPreference' => 'Nincs preferencia',
			'accountPreferences.notSet' => 'Nincs beállítva',
			'accountPreferences.groups.audioAndSubtitles' => 'Hang és feliratok',
			'accountPreferences.groups.libraryDisplay' => 'Könyvtár',
			'accountPreferences.groups.personalMedia' => 'Személyes média',
			'accountPreferences.preferredAudioLanguage' => 'Elsődleges hangnyelv',
			'accountPreferences.autoSelectAudio' => 'Hangsáv kiválasztása nyelv alapján',
			'accountPreferences.autoSelectAudioDescription' => 'Ki kapcsolásnál a fájl által alapértelmezettként megjelölt hangsáv marad.',
			'accountPreferences.preferredSubtitleLanguage' => 'Elsődleges feliratnyelv',
			'accountPreferences.subtitleMode' => 'Feliratok bekapcsolása',
			'accountPreferences.subtitleModes.none' => 'Kézzel kiválasztva',
			'accountPreferences.subtitleModes.noneDescription' => 'Soha ne kapcsolja be magától a feliratokat.',
			'accountPreferences.subtitleModes.defaultMode' => 'A sáv jelzőinek követése',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Az egyes feliratsávokon tárolt alapértelmezett és kényszerített jelzők használata.',
			'accountPreferences.subtitleModes.always' => 'Mindig engedélyezve',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Feliratsáv bekapcsolása az elsődleges nyelven, ha van ilyen.',
			'accountPreferences.subtitleModes.onlyForced' => 'Csak kényszerített feliratok',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Csak a kényszerítettként megjelölt sávok betöltése.',
			'accountPreferences.subtitleModes.smart' => 'Idegen nyelvű hang esetén megjelenítve',
			'accountPreferences.subtitleModes.smartDescription' => 'Feliratok bekapcsolása csak akkor, ha a hang más nyelven szól.',
			'accountPreferences.subtitleAccessibility' => 'SDH-feliratok',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Nem SDH-feliratok előnyben részesítése',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH-feliratok előnyben részesítése',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Csak SDH-feliratok',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Csak nem SDH-feliratok',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Előnyben részesíti a szabványos alfejezeteket, amikor mind a standard, mind az SDH verziók állnak rendelkezésre.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Előnyben részesíti az SDH altitkákat, amikor rendelkezésre állnak, de lehetővé teszi a szabványos altitkok visszavonulását.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Csak SDH altitkok használata; ne térjen vissza a szabványos altitkákhoz.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Csak szabványos altitkok használata; kizárja az SDH altitkokat.',
			'accountPreferences.forcedSubtitles' => 'Kényszerített feliratok',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Nem kényszerített feliratok előnyben részesítése',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Kényszerített feliratok előnyben részesítése',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Csak kényszerített feliratok',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Csak nem kényszerített feliratok',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Előnyben részesíti a rendszeres altitkok, de lehetővé teszi a kényszerített nyomokat, mint egy visszafelé.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Előnyben részesítik a kényszerített pályákat, amikor rendelkezésre állnak, de lehetővé teszik a rendszeres altitkok visszavonulását.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Használjon csak nyomokat, amelyeket kényszerként jelöltek ki.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Kizárják a nyomokat, amelyeket kényszerítőként jelölnek ki.',
			'accountPreferences.displayMissingEpisodes' => 'Hiányzó epizódok megjelenítése',
			'accountPreferences.displayMissingEpisodesDescription' => 'Azoknak az epizódoknak a listázása, amelyeket a szerver ismer, de nincs hozzájuk fájl.',
			'accountPreferences.hidePlayedInLatest' => 'Megnézett elemek elrejtése a Legújabbak között',
			'accountPreferences.hidePlayedInLatestDescription' => 'A már megnézett elemek kimaradnak a szerver Legújabbak soraiból.',
			'accountPreferences.displayCollectionsView' => 'Gyűjtemények nézet megjelenítése',
			'accountPreferences.displayCollectionsViewDescription' => 'A szerver Gyűjtemények nézetének megjelenítése a könyvtárak mellett.',
			'accountPreferences.rewatchingInNextUp' => 'Újranézett sorozatok megtartása a Következikben',
			'accountPreferences.rewatchingInNextUpDescription' => 'Ha befejezel egy sorozatot, és újra elkezded, a Következik az újranézést követi, ahelyett hogy eldobná a sorozatot.',
			'accountPreferences.watchedIndicator' => 'Megtekintett jelzések',
			'accountPreferences.watchedIndicatorOptions.none' => 'Soha',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmek és TV-sorozatok',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Csak filmek',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Csak TV-sorozatok',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Ne mutassa meg a megfigyelt ellenőrző jeleket.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Megjeleníti a filmek és a televíziós műsorok ellenőrzési pontjait.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Csak a filmek tekintetében mutatja meg az ellenőrző jeleket.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Show watched checkmarks for TV shows only. - Csak a tévéműsorok ellenőrizése.',
			'accountPreferences.mediaReviewsVisibility' => 'Értékelések és kritikák',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Felhasználók és kritikusok',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Csak felhasználók',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Csak kritikusok',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Rejtett',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Megmutatja mind a felhasználói minősítéseket, mind a kritikus értékeléseket.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Tekintse meg a felhasználók által benyújtott értékeléseket és véleményeket.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Kritikus értékelések és vélemények megjelenítése.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Elrejti a minősítéseket és az értékeléseket.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Előnyben részesíti az audio nyomtatásokat ebben a nyelven, amikor a szerver vagy a lejátszó automatikusan kiválasztja a nyomtatást.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Előnyben részesíti a szubtitkák nyomon követését ebben a nyelven, amikor az altitkok automatikusan kiválasztódnak.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Válassza ki, hogy az SDH kapciók előnyben részesülnek-e vagy szükségesek-e az automatikus alszámválasztás során.',
			'accountPreferences.forcedSubtitleDescription' => 'Válassza ki, hogy az automatikus kiválasztás során előnyben részesülnek-e vagy megkövetelik-e a kényszerítő alkategóriák.',
			'accountPreferences.watchedIndicatorDescription' => 'Válassza ki, hogy mely médiatípusok kapnak megfigyelhető ellenőrző jelet a szerver interfészben.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Válassza ki, hogy mely közönség és kritikus értékelések a szerver megjeleníti a média oldalak.',
			'accountPreferences.subtitleModeDescription' => 'Válassza ki, amikor az altitkok automatikusan aktiválódnak ebben a szerverfiókban.',
			'accountPreferences.hubDescription' => 'Ezek a preferenciák tárolódnak a médiaszolgáltató fiókjában, és más ügyfelekre is alkalmazhatók.',
			'discover.title' => 'Felfedezés',
			'discover.noContentAvailable' => 'Nincs elérhető tartalom',
			'discover.addMediaToLibraries' => 'Adj hozzá médiát a könyvtáraidhoz',
			'discover.continueWatching' => 'Folytatás',
			'discover.continueWatchingIn' => ({required Object library}) => 'Folytatás itt: ${library}',
			'discover.nextUp' => 'Következik',
			'discover.nextUpIn' => ({required Object library}) => 'Következik itt: ${library}',
			'discover.recentlyAdded' => 'Legutóbb hozzáadva',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Legutóbb hozzáadva itt: ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Legújabb albumok itt: ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Legutóbb lejátszva itt: ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Legtöbbször lejátszva itt: ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => '${season}. évad, ${episode}. epizód',
			'discover.overview' => 'Áttekintés',
			'discover.cast' => 'Szereplők',
			'discover.findNext.title' => 'Találd meg a következő kedvenced',
			'discover.findNext.open' => 'Találd meg a következő kedvenced',
			'discover.findNext.anyTime' => 'Bármennyi idő',
			'discover.findNext.timeAvailable' => 'Mennyi időd van?',
			'discover.findNext.filters' => 'Válassz a pillanathoz illőt',
			'discover.findNext.watch' => 'Nézés',
			'discover.findNext.listen' => 'Hallgatás',
			'discover.findNext.read' => 'Olvasás',
			'discover.findNext.finishable' => ({required Object duration}) => '${duration} alatt befejezhető',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Körülbelül ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Következő fejezet · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Összesen ${duration}',
			'discover.findNext.timingVaries' => 'Az időtartam változó',
			'discover.findNext.notNow' => 'Most nem',
			'discover.findNext.swipeHint' => 'Húzd a borítót valamelyik nyíl felé, vagy használd az alábbi gombokat.',
			'discover.findNext.saved' => 'Mentett ajánlások',
			'discover.findNext.savedCount' => ({required Object count}) => 'Mentett ajánlások · ${count}',
			'discover.findNext.undo' => 'Visszavonás',
			'discover.findNext.details' => 'Részletek',
			'discover.findNext.noPicks' => 'Még nincs miből választani',
			'discover.findNext.noPicksHint' => 'A kezdéshez csatlakoztass egy könyvtárat, vagy adj hozzá egy médiaforrást.',
			'discover.findNext.noMatches' => 'Most nincs megfelelő ajánlás',
			'discover.findNext.noMatchesHint' => 'Próbálj más médiatípust, vagy szánj rá több időt.',
			'discover.findNext.allDone' => 'Minden ajánlást megnéztél',
			'discover.findNext.allDoneHint' => 'Indíts új válogatást, hogy újra lásd ezeket a lehetőségeket.',
			'discover.findNext.refresh' => 'Másik válogatás keresése',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Forrás: ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Könyvtár: ${library}',
			'discover.findNext.ownedReason' => 'A könyvtáradból',
			'discover.findNext.liveNow' => 'Most műsoron',
			'discover.findNext.watchLive' => 'Élő adás megtekintése',
			'discover.findNext.filterAnything' => 'Bármi',
			'discover.findNext.filterWatch' => 'Nézés',
			'discover.findNext.filterListen' => 'Hallgatás',
			'discover.findNext.filterRead' => 'Olvasás',
			'discover.findNext.twentyMinutes' => '20 perc',
			'discover.findNext.fortyFiveMinutes' => '45 perc',
			'discover.findNext.ninetyMinutes' => '90 perc',
			'discover.findNext.apply' => 'Alkalmaz',
			'discover.findNext.openFailed' => 'Ez a lehetőség már nem érhető el. Frissíts az újbóli ellenőrzéshez.',
			'discover.findNext.changeFailed' => 'A módosítást nem sikerült menteni. Próbáld újra.',
			'discover.findNext.savedLimit' => 'A mentett ajánlások listája megtelt. Távolíts el egyet, hogy másikat menthess.',
			'discover.findNext.chooseHint' => 'Nyiss meg egy címet, mentsd el későbbre, vagy hagyd ki.',
			'discover.findNext.howItWorks' => 'Így működik',
			'discover.findNext.notNowHelp' => 'Ezt a címet most kihagyod. A könyvtáradban megmarad.',
			'discover.findNext.saveHelp' => 'Mentsd a profil mentett ajánlatai közé ezen az eszközön. A mentés nem tölti le a címet.',
			'discover.findNext.openHelp' => 'A részletekhez válaszd ki a borítót. A fő művelettel lejátszhatod, olvashatod vagy megnyithatod a címet.',
			'discover.findNext.controlsHelp' => 'Billentyűzet vagy távirányító: válassz egy gombot, majd nyomd meg az Enter vagy a Kiválasztás gombot. A Visszavonás visszaállítja az utolsó választásodat.',
			'discover.findNext.artworkLoading' => 'Kép betöltése…',
			'discover.findNext.artworkUnavailable' => 'A kép nem érhető el',
			'discover.findNext.savedFeedback' => 'Hozzáadva a mentett ajánlatokhoz',
			'discover.findNext.skippedFeedback' => 'Most kihagyva',
			'discover.findNext.releaseToConfirm' => 'Engedd el a megerősítéshez',
			'discover.findNext.remoteHint' => 'Borító kijelölve: ← / → választás · Kiválasztás: részletek · ↑ / ↓ fókusz mozgatása',
			'discover.extras' => 'Előzetesek és extrák',
			'discover.studio' => 'Stúdió',
			'discover.rating' => 'Értékelés',
			'discover.director' => 'Rendező',
			'discover.directors' => 'Rendezők',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-sorozat',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} perc van hátra',
			'discover.moreLikeThis' => 'Hasonló tartalmak',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cím', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cím', ), 
			'discover.person.born' => 'Született',
			'discover.person.died' => 'Elhunyt',
			'discover.person.birthplace' => 'Születési hely',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} éves)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (${age} évesen)',
			'errors.searchFailed' => ({required Object error}) => 'Keresés sikertelen: ${error}',
			'errors.searchUnavailable' => 'A keresés egyetlen médiaszervert sem tudott elérni.',
			'errors.connectionTimeout' => ({required Object context}) => 'Hálózati időtúllépés a következő betöltésekor: ${context}',
			'errors.connectionFailed' => 'Nem sikerült csatlakozni a médiaszerverhez',
			'errors.unableToLoad' => ({required Object context}) => 'Nem sikerült betölteni a következőt: ${context}. Próbáld újra.',
			'errors.noClientAvailable' => 'Nincs elérhető kliens',
			'errors.pleaseEnterToken' => 'Adj meg egy tokent',
			'errors.invalidToken' => 'Érvénytelen token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Nem sikerült a token ellenőrzése: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Nem sikerült átváltani a következő profilra: ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Nem sikerült törölni a következőt: ${displayName}',
			'errors.failedToRate' => 'Nem sikerült frissíteni az értékelést',
			'errors.reasonTimedOut' => 'időtúllépés történt a kapcsolatban',
			'errors.reasonUnreachable' => 'a médiaszerver nem érhető el',
			'errors.reasonRefused' => 'a médiaszerver elutasította a kérést',
			'errors.reasonNotFound' => 'az elem már nem található a médiaszerveren',
			'errors.reasonServerError' => 'a médiaszerver hibát jelzett',
			'errors.reasonCancelled' => 'a kérés meg lett szakítva',
			'errors.reasonUnexpected' => 'váratlan hiba történt',
			'libraries.playRandomMovie' => 'Játssz egy véletlenszerű filmet',
			'libraries.randomPickFailed' => 'Nem tudtam kiválasztani egy véletlenszerű filmet ebből a könyvtárból.',
			'libraries.title' => 'Könyvtárak',
			'libraries.fallbackTitle' => 'Könyvtár',
			'libraries.scanLibraryFiles' => 'Könyvtárfájlok beolvasása',
			'libraries.scanLibrary' => 'Könyvtár beolvasása',
			'libraries.analyze' => 'Elemzés',
			'libraries.analyzeLibrary' => 'Könyvtár elemzése',
			'libraries.refreshMetadata' => 'Metaadatok frissítése',
			'libraries.emptyTrash' => 'Lomtár ürítése',
			'libraries.emptyingTrash' => ({required Object title}) => 'Lomtár ürítése a következőhöz: "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Lomtár kiürítve a következőhöz: "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Nem sikerült a lomtár ürítése: ${error}',
			'libraries.analyzing' => ({required Object title}) => '"${title}" elemzése...',
			'libraries.analysisStarted' => ({required Object title}) => 'Elemzés elindítva a következőhöz: "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Nem sikerült a könyvtár elemzése: ${error}',
			'libraries.noLibrariesFound' => 'Nem találhatók könyvtárak',
			'libraries.allLibrariesHidden' => 'Minden könyvtár el van rejtve',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Rejtett könyvtárak (${count})',
			'libraries.thisLibraryIsEmpty' => 'Ez a könyvtár üres',
			'libraries.noItemsMatchFilters' => 'Nincs az aktív szűrőknek megfelelő elem',
			'libraries.resetFilters' => 'Szűrők visszaállítása',
			'libraries.all' => 'Összes',
			'libraries.clearAll' => 'Összes törlése',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Biztosan be szeretnéd olvasni a következőt: "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Biztosan elemezni szeretnéd a következőt: "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Biztosan frissíteni szeretnéd a metaadatokat a következőhöz: "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Biztosan ki szeretnéd üríteni a lomtárat a következőnél: "${title}"?',
			'libraries.manageLibraries' => 'Könyvtárak kezelése',
			'libraries.sort' => 'Rendezés',
			'libraries.sortBy' => 'Rendezés ez alapján',
			'libraries.filters' => 'Szűrők',
			'libraries.confirmActionMessage' => 'Biztosan végre szeretnéd hajtani ezt a műveletet?',
			'libraries.showLibrary' => 'Könyvtár megjelenítése',
			'libraries.hideLibrary' => 'Könyvtár elrejtése',
			'libraries.libraryOptions' => 'Könyvtár beállításai',
			'libraries.content' => 'könyvtár tartalma',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Könyvtár kiválasztása',
			'libraries.filtersWithCount' => ({required Object count}) => 'Szűrők (${count})',
			'libraries.noRecommendations' => 'Nincsenek elérhető ajánlások',
			'libraries.noCollections' => 'Nincsenek gyűjtemények ebben a könyvtárban',
			'libraries.noFoldersFound' => 'Nem találhatók mappák',
			'libraries.folders' => 'mappák',
			'libraries.tabs.recommended' => 'Ajánlott',
			'libraries.tabs.browse' => 'Böngészés',
			'libraries.tabs.collections' => 'Gyűjtemények',
			'libraries.tabs.playlists' => 'Lejátszási listák',
			'libraries.groupings.title' => 'Csoportosítás',
			'libraries.groupings.all' => 'Összes',
			'libraries.groupings.movies' => 'Filmek',
			'libraries.groupings.shows' => 'TV-sorozatok',
			'libraries.groupings.seasons' => 'Évadok',
			'libraries.groupings.episodes' => 'Epizódok',
			'libraries.groupings.artists' => 'Előadók',
			'libraries.groupings.albums' => 'Albumok',
			'libraries.groupings.tracks' => 'Zeneszámok',
			'libraries.groupings.folders' => 'Mappák',
			'libraries.filterCategories.genre' => 'Műfaj',
			'libraries.filterCategories.year' => 'Év',
			'libraries.filterCategories.contentRating' => 'Korhatár-besorolás',
			'libraries.filterCategories.tag' => 'Címke',
			'libraries.filterCategories.unwatched' => 'Nem látott',
			'libraries.filterCategories.unplayed' => 'Nem lejátszott',
			'libraries.filterCategories.favorites' => 'Kedvencek',
			'libraries.filterCategories.filePath' => 'Fájl elérési útja',
			'libraries.sortLabels.title' => 'Cím',
			'libraries.sortLabels.dateAdded' => 'Hozzáadás dátuma',
			'libraries.sortLabels.releaseDate' => 'Bemutató dátuma',
			'libraries.sortLabels.rating' => 'Értékelés',
			'libraries.sortLabels.communityRating' => 'Közösségi értékelés',
			'libraries.sortLabels.criticRating' => 'Kritikusi értékelés',
			'libraries.sortLabels.userRating' => 'Saját értékelés',
			'libraries.sortLabels.datePlayed' => 'Lejátszás dátuma',
			'libraries.sortLabels.playCount' => 'Lejátszások száma',
			'libraries.sortLabels.productionYear' => 'Gyártási év',
			'libraries.sortLabels.runtime' => 'Játékidő',
			'libraries.sortLabels.officialRating' => 'Hivatalos besorolás',
			'libraries.sortLabels.premiereDate' => 'Premier dátuma',
			'libraries.sortLabels.startDate' => 'Kezdés dátuma',
			'libraries.sortLabels.airTime' => 'Adásidő',
			'libraries.sortLabels.studio' => 'Stúdió',
			'libraries.sortLabels.random' => 'Véletlenszerű',
			'libraries.sortLabels.dateShared' => 'Megosztás dátuma',
			'libraries.sortLabels.latestEpisodeAirDate' => 'A legutóbbi epizód sugárzási dátuma',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Utolsó epizód hozzáadásának dátuma',
			'libraries.sortLabels.dateDownloaded' => 'Letöltés dátuma',
			'libraries.sortLabels.size' => 'Méret',
			'libraries.sortLabels.library' => 'Könyvtár',
			'libraries.advancedFilters.include' => 'Belefoglalás',
			'libraries.advancedFilters.exclude' => 'Kizárás',
			'libraries.advancedFilters.any' => 'Mindegy',
			'libraries.advancedFilters.yes' => 'Igen',
			'libraries.advancedFilters.no' => 'Nem',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Kivéve: ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} kiválasztva',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} kizárva',
			'libraries.advancedFilters.searchValues' => 'Értékek keresése',
			'libraries.advancedFilters.noValues' => 'Nincsenek értékek',
			'libraries.advancedFilters.matchContains' => 'Tartalmazza',
			'libraries.advancedFilters.matchNotContains' => 'Nem tartalmazza',
			'libraries.advancedFilters.matchIs' => 'Egyezik',
			'libraries.advancedFilters.matchIsNot' => 'Nem egyezik',
			'libraries.advancedFilters.matchBeginsWith' => 'Ezzel kezdődik',
			'libraries.advancedFilters.matchEndsWith' => 'Erre végződik',
			'libraries.advancedFilters.textHint' => 'Írd be a keresett szöveget',
			'libraries.advancedFilters.from' => 'Ettől',
			'libraries.advancedFilters.to' => 'Eddig',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} – ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => 'Legalább ${value}',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Legfeljebb ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Az elmúlt ${count} nap',
			'libraries.advancedFilters.dateLastYear' => 'Az elmúlt év',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => '${count} napnál régebbi',
			'libraries.advancedFilters.dateOlderThanYear' => 'Egy évnél régebbi',
			'libraries.selection.selectItems' => 'Válassza ki az elemeket',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} kiválasztva',
			'libraries.selection.actions' => 'Választási akciók',
			'libraries.selection.confirmDescendants' => 'Ez megváltoztatja az összes epizódot a kiválasztott előadásokban és szezonokban.',
			'libraries.selection.confirmUnwatched' => 'Ez a kiválasztott elemek lejátszási előrehaladását is törli.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Válogatott elemek: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Aktualizált elemek: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Aktualizált ${succeeded}; nem sikerült ${failed}. A nem sikerült elemeket továbbra is kiválasztották.',
			'about.title' => 'Névjegy',
			'about.openSourceLicenses' => 'Nyílt forráskódú licencek',
			'about.versionLabel' => ({required Object version}) => 'Verzió: ${version}',
			'about.appDescription' => 'Gyönyörű Flutter-kliens a Plexhez, a Jellyfinhez és az Embyhez',
			'about.viewLicensesDescription' => 'Külső fejlesztésű programkönyvtárak licenceinek megtekintése',
			'about.privacyPolicy' => 'Adatvédelmi tájékoztató',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nem találhatók szerverek ehhez a fiókhoz: ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Nem sikerült a szerverek betöltése: ${error}',
			'serverSelection.noValidServers' => 'Nem található használható szerver ehhez a fiókhoz',
			'hubDetail.title' => 'Cím',
			'hubDetail.releaseYear' => 'Kiadási év',
			'hubDetail.dateAdded' => 'Hozzáadás dátuma',
			'hubDetail.rating' => 'Értékelés',
			'hubDetail.noItemsFound' => 'Nem találhatók elemek',
			'logs.clearLogs' => 'Naplók törlése',
			'logs.copyLogs' => 'Naplók másolása',
			'logs.uploadLogs' => 'Naplók feltöltése',
			'logs.saveLogs' => 'Logs to File tárolás',
			'logs.logsSaved' => ({required Object path}) => 'A regisztrációt a ${path}',
			'logs.saveLogsFailed' => 'Nem tudta megmenteni a log fájlt.',
			'startup.failedTitle' => 'A PlezyNG nem tudott elindulni',
			'startup.failedBody' => 'Valami hiba történt az indítás során. Az alábbi részletek mutatják, mi hibázott.',
			'startup.failedBodyRepairable' => 'A PlezyNG mentett beállításfájlja sérült, és újra kell építeni, mielőtt a PlezyNG elindulhatna. Az újrapróbálkozás nem segít – válassza a Tárhely javítása lehetőséget.',
			'startup.phaseLabel' => 'Lépés',
			'startup.showDetails' => 'Részletek megjelenítése',
			'startup.hideDetails' => 'Részletek elrejtése',
			'startup.copyDetails' => 'Részletek másolása',
			'startup.detailsCopied' => 'A részletek a vágólapra kerültek',
			'startup.uploadDetails' => 'Részletek feltöltése',
			'startup.repairStorage' => 'Tárhely javítása',
			'startup.repairTitle' => 'Javítsuk a tárolt adatokat?',
			'startup.repairBodyCommon' => 'A PlezyNG beállításfájlja sérült, és nem olvasható. A javítás minden beállítást visszaállít az alapértelmezettre.',
			'startup.repairBodyOneCredential' => 'Egy mentett bejelentkezés sérült, és nem olvasható. A javítás csak azt távolítja el; a többi beállítása érintetlen marad.',
			'startup.repairBodySignInsKept' => 'A szervereinek és profiljainak bejelentkezve kell maradniuk.',
			'startup.repairBodySignInsLost' => 'A mentett bejelentkezéseket védő kulcs nem nyerhető vissza ebből a fájlból, ezért minden szerverre és profilba újra be kell jelentkeznie. A médiaszerveren semmi nem érintett.',
			'startup.repairBodySessionsUncertain' => 'A nyomkövetők (MAL, AniList, Simkl, Trakt) és a Seerr külön vannak tárolva, és megmaradhatnak vagy nem. A PlezyNG pontosan megmondja, mit őrzött meg.',
			'startup.repairConfirm' => 'Javítás',
			'startup.repairSucceeded' => 'A tárhely javítva',
			'startup.repairNeedsRestart' => 'A tárhely javítva – újraindítás szükséges',
			'startup.restartRequiredBody' => 'Az adatait kijavítottuk, de a PlezyNG-nek frissen kell elindulnia, mielőtt használhatná. Zárja be a PlezyNG-t, és nyissa meg újra.',
			'startup.quitPlezy' => 'Kilépés a PlezyNG-ből',
			'startup.repairFailed' => 'A javítás nem sikerült',
			'startup.repairKeptSignIns' => 'A szerverei és profiljai továbbra is be vannak jelentkezve.',
			'startup.repairLostSignIns' => 'A mentett bejelentkezéseket védő kulcs nem volt visszanyerhető. Minden szerverre és profilba újra be kell jelentkeznie.',
			'startup.repairLostSessions' => 'Legalább egy nyomkövető- vagy Seerr-kapcsolat elveszett, és újra kell csatlakoztatni.',
			'startup.backupTitle' => 'A sérült fájlról másolat készült',
			'startup.backupWarning' => 'Bejelentkezési adatait tartalmazza. Ne töltse fel és ne ossza meg.',
			'startup.deleteBackup' => 'Másolat törlése',
			'startup.backupDeleted' => 'A másolat törölve.',
			'startup.previousFailureTitle' => 'A PlezyNG legutóbb nem tudott elindulni',
			'licenses.relatedPackages' => 'Kapcsolódó csomagok',
			'licenses.license' => 'Licenc',
			'licenses.licenseNumber' => ({required Object number}) => '${number}. licenc',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenc',
			'navigation.libraries' => 'Könyvtárak',
			'navigation.downloads' => 'Letöltések',
			'navigation.liveTv' => 'Élő TV',
			'navigation.explore' => 'Böngészés',
			'explore.mdblistShelves.manage' => 'Kutatás a padlók',
			'explore.mdblistShelves.manageDescription' => 'Válassza ki és rendezi a listákat a MDBList fiókjától',
			'explore.mdblistShelves.description' => 'Válasszon nyilvános film- és sorozatlistákat az MDBList-fiókjából. Hozzon létre vagy másoljon listákat az MDBListen, majd frissítsen.',
			'explore.mdblistShelves.selected' => 'Válogatott tálcák',
			'explore.mdblistShelves.available' => 'Elérhető számlák listája',
			'explore.mdblistShelves.noLists' => 'Nincs nyilvános film vagy TV listák visszatértek. Hozzon létre vagy másolja a listát a MDBList-re, majd frissítse.',
			'explore.mdblistShelves.displayName' => 'Shelf kijelző neve',
			'explore.mdblistShelves.nameHint' => 'Hagyja a nyílt, hogy használja a forráslistát.',
			'explore.mdblistShelves.add' => 'Add Shelf',
			'explore.mdblistShelves.save' => 'mentse a tálcákat',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '${title} felfelé',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '${title} lefelé',
			'explore.mdblistShelves.unavailable' => 'Ez a lista nem elérhető. visszavonja vagy távolítsa el a szekrényt a beállításokban.',
			'explore.mdblistShelves.rateLimited' => 'MDBList kérelem határérték elérte. kérjük, visszavonja később.',
			'explore.mdblistShelves.loadFailed' => 'Nem lehet feltölteni a tálcákat. ellenőrizze a kapcsolatot és visszavonul.',
			'explore.mdblistShelves.saveFailed' => 'Nem tudok megmenteni a szeleteket. kérjük, visszavonulj.',
			'explore.mdblistShelves.accountChanged' => 'A fiók vagy a profil megváltozott. Újra megnyitja ezeket a beállításokat.',
			'explore.mdblistShelves.settingsUnreadable' => 'A mentett lapok nem olvashatók. Válassza ki a listákat újra, hogy helyettesítse ezeket a beállításokat.',
			'explore.title' => 'Böngészés',
			'explore.selectSource' => 'Forrás kiválasztása',
			'explore.rows.watchlist' => 'Néznivalók listája',
			'explore.rows.recommendedMovies' => 'Ajánlott filmek',
			'explore.rows.recommendedShows' => 'Ajánlott sorozatok',
			'explore.rows.trendingMovies' => 'Felkapott filmek',
			'explore.rows.trendingShows' => 'Felkapott sorozatok',
			'explore.rows.popularMovies' => 'Népszerű filmek',
			'explore.rows.popularShows' => 'Népszerű sorozatok',
			'explore.rows.trendingAnime' => 'Felkapott animék',
			'explore.rows.suggestedAnime' => 'Ajánlott animék',
			'explore.rows.airingAnime' => 'Jelenleg futó top animék',
			'explore.rows.popularAnime' => 'Legnépszerűbb animék',
			'explore.rows.trending' => 'Felkapott',
			'explore.rows.upcomingMovies' => 'Közelgő filmek',
			'explore.rows.upcomingShows' => 'Közelgő sorozatok',
			'explore.status.airing' => 'Adásban',
			'explore.status.ended' => 'Befejeződött',
			'explore.status.canceled' => 'Törölve',
			'explore.status.upcoming' => 'Közelgő',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizód', ), 
			'explore.cast' => 'Szereplők',
			'explore.characters' => 'Karakterek',
			'explore.addToWatchlist' => 'Hozzáadás a Néznivalókhoz',
			'explore.removeFromWatchlist' => 'Eltávolítás a Néznivalókból',
			'explore.addedToWatchlist' => 'Hozzáadva a figyelőlistához',
			'explore.removedFromWatchlist' => 'Eltávolítva a figyelőlistáról',
			'explore.watchlistUpdateFailed' => 'Nem sikerült a Néznivalók frissítése',
			'explore.watchlistNoMatch' => 'Nem sikerült ezt az elemet figyelőlistához társítani',
			'explore.notInLibrary' => 'Nincs a könyvtáradban',
			'explore.inTheseLibraries' => 'Ezekben a könyvtárakban',
			'explore.checkingLibrary' => 'Könyvtár ellenőrzése...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: 'Nem sikerült ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} szervert ellenőrizni', other: 'Nem sikerült ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} szervert ellenőrizni', ), 
			'explore.emptyTitle' => 'Még nincs itt semmi',
			'explore.emptyMessage' => ({required Object source}) => 'A(z) ${source} forrásból származó sorok itt fognak megjelenni, amint van tartalmuk.',
			'explore.searchHint' => ({required Object source}) => 'Keresés itt: ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nincs találat a következőre: "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Filmek és sorozatok keresése a következőn: ${source}.',
			'explore.searchFailed' => 'A keresés nem sikerült. Ellenőrizd a kapcsolatot és próbáld újra.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} népszerű',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} adásban',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} értékelt',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} felkapott',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} a(z) ${season} évadban',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} nézi',
			'explore.badge.available' => 'Elérhető',
			'explore.badge.partiallyAvailable' => 'Részben elérhető',
			'explore.badge.availableIn4k' => '4K elérhető',
			'explore.badge.requested' => 'Kérve',
			'explore.badge.pendingApproval' => 'Jóváhagyásra vár',
			'explore.badge.processing' => 'Feldolgozás alatt',
			'explore.badge.declined' => 'Elutasítva',
			'explore.badge.requestFailed' => 'A kérés nem sikerült',
			'explore.badge.requested4k' => '4K kérve',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} évad',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => '${episode}. ep. ${duration} múlva',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Következő ${duration} múlva',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} perc/ep.',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} listázva',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} nézte ma',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} nézte ezen a héten',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} nézte ebben a hónapban',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} nézte ebben az évben',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} néző',
			'explore.stats.planning' => ({required Object n}) => '${n} tervezi megnézni',
			'explore.stats.favorited' => ({required Object n}) => '${n} kedvenc',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} felhagyott vele',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hozzászólás', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} hozzászólás', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} szavazat',
			'explore.stats.watching' => ({required Object n}) => '${n} nézi',
			'explore.stats.completed' => ({required Object n}) => '${n} befejezte',
			'explore.stats.onHold' => ({required Object n}) => '${n} szünetelteti',
			'explore.stats.dropped' => ({required Object n}) => '${n} felhagyott vele',
			'explore.season.winter' => 'Tél',
			'explore.season.spring' => 'Tavasz',
			'explore.season.summer' => 'Nyár',
			'explore.season.fall' => 'Ősz',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV rövid',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Különkiadás',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Zene',
			'explore.format.other' => 'Egyéb',
			'explore.sourceMaterial.original' => 'Eredeti',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Regény',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Játék',
			'explore.sourceMaterial.webComic' => 'Webképregény',
			'explore.sourceMaterial.musicRelease' => 'Zene',
			'explore.sourceMaterial.otherMedia' => 'Egyéb',
			'explore.creditRole.actor' => 'Színész',
			'explore.creditRole.director' => 'Rendező',
			'explore.creditRole.writer' => 'Író',
			'explore.creditRole.producer' => 'Producer',
			'explore.creditRole.creator' => 'Alkotó',
			'explore.creditRole.composer' => 'Zeneszerző',
			'explore.relation.prequel' => 'Előzmény',
			'explore.relation.sequel' => 'Folytatás',
			'explore.relation.sideStory' => 'Melléktörténet',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternatív verzió',
			'explore.relation.summary' => 'Összefoglaló',
			'explore.relation.parentStory' => 'Fő történet',
			'explore.relation.adaptation' => 'Adaptáció',
			'explore.relation.other' => 'Kapcsolódó',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Adásban: ${day}, ${time} órakor',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Adásban: ${day}, ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Eredeti cím',
			'explore.detail.alsoKnownAs' => 'Más néven',
			'explore.detail.studios' => 'Stúdiók',
			'explore.detail.country' => 'Ország',
			'explore.detail.language' => 'Nyelv',
			'explore.detail.released' => 'Megjelent',
			'explore.detail.physicalRelease' => 'Lemezes',
			'explore.detail.ended' => 'Befejeződött',
			'explore.detail.addedOn' => ({required Object date}) => 'Hozzáadva: ${date}',
			'explore.detail.yourRating' => 'Az Ön értékelése',
			'explore.detail.budget' => 'Költségvetés',
			'explore.detail.revenue' => 'Bevétel',
			'explore.detail.contentAdvisory' => 'Korhatár',
			'explore.detail.tags' => 'Címkék',
			'explore.detail.revealSpoilerTags' => 'Spoiler címkék megjelenítése',
			'explore.detail.links' => 'Hivatkozások',
			'explore.detail.watchOn' => 'Megnézhető itt',
			'explore.detail.watchTrailer' => 'Előzetes megtekintése',
			'explore.detail.openOn' => ({required Object site}) => 'Megnyitás itt: ${site}',
			'explore.detail.crew' => 'Stáb',
			'explore.detail.ratings' => 'Értékelések',
			'explore.detail.schedule' => 'Műsorrend',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} felhasználó ajánlja', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} felhasználó ajánlja', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Ajánlotta: ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Kedvencek közt: ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} még nem került adásba',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'A nézők ${percent}-a ajánlja',
			'explore.detail.relatedTitles' => 'Kapcsolódó címek',
			'explore.detail.background' => 'Háttér',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} találat', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} találat', ), 
			'liveTv.title' => 'Élő TV',
			'liveTv.guide' => 'Műsorújság',
			'liveTv.noChannels' => 'Nincsenek elérhető csatornák',
			'liveTv.noDvr' => 'Egyik szerveren sincs beállítva DVR',
			'liveTv.serverUnavailable' => 'Az Élő TV szerver nem érhető el.',
			'liveTv.serverNotConnected' => 'Az Élő TV szerver nincs csatlakoztatva.',
			'liveTv.noPrograms' => 'Nincsenek elérhető műsoradatok',
			'liveTv.liveStreamFailed' => 'Nem sikerült elindítani az élő adást',
			'liveTv.unknownProgram' => 'Ismeretlen műsor',
			'liveTv.timelineLiveProgram' => 'Live program (a játék visszafordítása lehet ezen a programon kívül)',
			'liveTv.timelineBuffer' => 'Buffer időzítés',
			'liveTv.timelineUnavailable' => 'Időjárás nem elérhető',
			'liveTv.timelineEstimated' => 'Értékelhető playback',
			'liveTv.timelinePending' => 'Keresés közben',
			'liveTv.timelineStale' => 'A határidő elavult lehet',
			'liveTv.unknownHub' => 'Ismeretlen',
			'liveTv.unknownError' => 'Ismeretlen hiba',
			'liveTv.channelNumber' => ({required Object number}) => '${number}. csatorna',
			'liveTv.unknownChannel' => 'Ismeretlen csatorna',
			'liveTv.live' => 'ÉLŐ',
			'liveTv.premiereBadge' => 'Új',
			'liveTv.reloadGuide' => 'Műsorújság újratöltése',
			'liveTv.searchGuide' => 'Keresés a műsorújságban',
			'liveTv.searchHint' => 'Csatornák és műsorok keresése',
			'liveTv.searchNoResults' => ({required Object query}) => 'Nincs találat a következőre: "${query}"',
			'liveTv.channelsSection' => 'Csatornák',
			'liveTv.programsSection' => 'Műsorok',
			'liveTv.now' => 'Most',
			'liveTv.today' => 'Ma',
			'liveTv.tomorrow' => 'Holnap',
			'liveTv.midnight' => 'Éjfél',
			'liveTv.overnight' => 'Késő éjszaka',
			'liveTv.morning' => 'Reggel',
			'liveTv.daytime' => 'Napközben',
			'liveTv.evening' => 'Este',
			'liveTv.lateNight' => 'Éjszaka',
			'liveTv.whatsOn' => 'Mi megy most?',
			'liveTv.watchChannel' => 'Csatorna nézése',
			'liveTv.favorites' => 'Kedvencek',
			'liveTv.reorderFavorites' => 'Kedvencek rendezése',
			'liveTv.noFavoriteChannels' => 'Nincsenek kedvenc csatornák',
			'liveTv.noFavoriteChannelsHint' => 'Jelenítsd meg az összes csatornát, majd hosszan nyomj meg egy csatornát, hogy hozzáadd a kedvenceidhez.',
			'liveTv.showAllChannels' => 'Összes csatorna megjelenítése',
			'liveTv.favoritesLoadFailed' => 'Nem sikerült a kedvencek betöltése. Ellenőrizd a kapcsolatot és próbáld újra.',
			'liveTv.favoritesUpdateFailed' => 'Nem sikerült frissíteni a kedvenceket. Ellenőrizd a kapcsolatot, majd próbáld újra.',
			'liveTv.joinSession' => 'Csatlakozás a folyamatban lévő adáshoz',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Nézés az elejétől (${minutes} perce megy)',
			'liveTv.watchLive' => 'Élő adás nézése',
			'liveTv.goToLive' => 'Ugrás az élő adásra',
			'liveTv.record' => 'Felvétel',
			'liveTv.recordEpisode' => 'Epizód rögzítése',
			'liveTv.recordSeries' => 'Sorozat rögzítése',
			'liveTv.recordOptions' => 'Felvételi beállítások',
			'liveTv.saveTo' => 'Mentés ide',
			'liveTv.recordings' => 'Felvételek',
			'liveTv.scheduledRecordings' => 'Ütemezve',
			'liveTv.recordingRules' => 'Felvételi szabályok',
			'liveTv.noScheduledRecordings' => 'Nincs semmi felvételre ütemezve',
			'liveTv.manageRecording' => 'Felvétel kezelése',
			'liveTv.cancelRecording' => 'Felvétel megszakítása',
			'liveTv.cancelRecordingTitle' => 'Megszakítod ezt a felvételt?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => 'A(z) ${title} nem kerül rögzítésre.',
			'liveTv.deleteRule' => 'Szabály törlése',
			'liveTv.deleteRuleTitle' => 'Törlöd a felvételi szabályt?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'A(z) ${title} jövőbeli epizódjai nem kerülnek rögzítésre.',
			'liveTv.recordingScheduled' => 'Felvétel ütemezve',
			'liveTv.alreadyScheduled' => 'Ez a műsor már ütemezve van',
			'liveTv.dvrAdminRequired' => 'A DVR beállításokhoz adminisztrátori fiók szükséges',
			'liveTv.recordingFailed' => 'Nem sikerült a felvétel ütemezése',
			'liveTv.recordingTargetMissing' => 'Nem sikerült meghatározni a felvételi könyvtárat',
			'liveTv.recordNotAvailable' => 'A felvétel nem érhető el ehhez a műsorhoz',
			'liveTv.recordingCancelled' => 'Felvétel megszakítva',
			'liveTv.recordingRuleDeleted' => 'Felvételi szabály törölve',
			'liveTv.processRecordingRules' => 'Szabályok újraértékelése',
			'liveTv.recordingInProgress' => 'Rögzítés folyamatban',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} ütemezve',
			'liveTv.editRule' => 'Szabály szerkesztése',
			'liveTv.editRuleAction' => 'Szerkesztés',
			'liveTv.recordingRuleUpdated' => 'Felvételi szabály frissítve',
			'liveTv.guideReloadRequested' => 'Műsorújság frissítése kérve',
			'liveTv.guideReloadFailed' => 'Nem sikerült frissíteni a műsorújságot',
			'liveTv.rulesProcessRequested' => 'Szabályok újraértékelése kérve',
			'liveTv.rulesProcessFailed' => 'Nem sikerült újra kiértékelni a felvételi szabályokat',
			'liveTv.recordShow' => 'Műsor rögzítése',
			'liveTv.recordSettings.startEarly' => 'Korábbi kezdés (másodperc)',
			'liveTv.recordSettings.endLate' => 'Későbbi befejezés (másodperc)',
			'liveTv.recordSettings.newOnly' => 'Csak új epizódok',
			'liveTv.recordSettings.anyChannel' => 'Felvétel bármelyik csatornáról',
			'liveTv.recordSettings.anyTime' => 'Felvétel bármikor',
			'liveTv.recordSettings.skipInLibrary' => 'A könyvtárban már meglévő epizódok kihagyása',
			'liveTv.recordSettings.keepUpTo' => 'Megtartandó epizódok',
			'liveTv.recordSettings.keepUpToHint' => 'A 0 minden epizódot megtart',
			'liveTv.startingInMinutes' => ({required Object minutes}) => '${minutes} perc múlva kezdődik',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day}, ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => 'A(z) ${product} érvénytelen Élő TV-lejátszási adatokat adott vissza',
			'liveTv.failedToStartChannel' => 'Nem sikerült elindítani az élő csatornát',
			'liveTv.failedToBuildStreamUrl' => 'Nem sikerült összeállítani a stream URL-címét',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Nem sikerült elindítani a csatornát: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Nem sikerült csatornát váltani: ${reason}',
			'collections.title' => 'Gyűjtemények',
			'collections.collection' => 'Gyűjtemény',
			'collections.empty' => 'A gyűjtemény üres',
			'collections.deleteCollection' => 'Gyűjtemény törlése',
			'collections.deleteConfirm' => ({required Object title}) => 'Törlöd a következőt: "${title}"? Ez nem vonható vissza.',
			'collections.deleted' => 'Gyűjtemény törölve',
			'collections.deleteFailed' => 'Nem sikerült a gyűjtemény törlése',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Nem sikerült a gyűjtemény törlése: ${error}',
			'collections.selectCollection' => 'Gyűjtemény kiválasztása',
			'collections.collectionName' => 'Gyűjtemény neve',
			'collections.enterCollectionName' => 'Add meg a gyűjtemény nevét',
			'collections.addedToCollection' => 'Hozzáadva a gyűjteményhez',
			'collections.errorAddingToCollection' => 'Nem sikerült a gyűjteményhez adni',
			'collections.created' => 'Gyűjtemény létrehozva',
			'collections.removeFromCollection' => 'Eltávolítás a gyűjteményből',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Eltávolítod a következőt: "${title}" ebből a gyűjteményből?',
			'collections.removedFromCollection' => 'Eltávolítva a gyűjteményből',
			'collections.removeFromCollectionFailed' => 'Nem sikerült az eltávolítás a gyűjteményből',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Hiba a gyűjteményből való eltávolításkor: ${error}',
			'collections.searchCollections' => 'Gyűjtemények keresése...',
			'playlists.title' => 'Lejátszási listák',
			'playlists.playlist' => 'Lejátszási lista',
			'playlists.noPlaylists' => 'Nem találhatók lejátszási listák',
			'playlists.create' => 'Lejátszási lista létrehozása',
			'playlists.playlistName' => 'Lejátszási lista neve',
			'playlists.enterPlaylistName' => 'Add meg a lejátszási lista nevét',
			'playlists.delete' => 'Lejátszási lista törlése',
			'playlists.removeItem' => 'Eltávolítás a lejátszási listáról',
			'playlists.smartPlaylist' => 'Okos lejátszási lista',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elem', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elem', ), 
			'playlists.emptyPlaylist' => 'Ez a lejátszási lista üres',
			'playlists.deleteConfirm' => 'Törlöd a lejátszási listát?',
			'playlists.deleteMessage' => ({required Object name}) => 'Biztosan törölni szeretnéd a következőt: "${name}"?',
			'playlists.created' => 'Lejátszási lista létrehozva',
			'playlists.deleted' => 'Lejátszási lista törölve',
			'playlists.itemAdded' => 'Hozzáadva a lejátszási listához',
			'playlists.itemRemoved' => 'Eltávolítva a lejátszási listáról',
			'playlists.selectPlaylist' => 'Lejátszási lista kiválasztása',
			'playlists.searchPlaylists' => 'Lejátszási listák keresése...',
			'playlists.errorCreating' => 'Nem sikerült a lejátszási lista létrehozása',
			'playlists.errorDeleting' => 'Nem sikerült a lejátszási lista törlése',
			'playlists.errorLoading' => 'Nem sikerült a lejátszási listák betöltése',
			'playlists.errorAdding' => 'Nem sikerült a lejátszási listához adni',
			'playlists.errorReordering' => 'Nem sikerült átrendezni a lejátszási lista elemét',
			'playlists.errorRemoving' => 'Nem sikerült az eltávolítás a lejátszási listáról',
			'music.goToAlbum' => 'Ugrás az albumhoz',
			'music.goToArtist' => 'Ugrás az előadóhoz',
			'music.instantMix' => 'Azonnali keverés',
			'music.playNext' => 'Következő lejátszása',
			'music.addToQueue' => 'Hozzáadás a lejátszási sorhoz',
			'music.discNumber' => ({required Object n}) => '${n}. lemez',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} zeneszám', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} zeneszám', ), 
			'music.nowPlaying' => 'Most szól',
			'music.playingFrom' => ({required Object title}) => 'Lejátszás innen: ${title}',
			'music.queue' => 'Lejátszási sor',
			'music.clearQueue' => 'Sor törlése',
			'music.lyrics' => 'Dalszöveg',
			'music.visualizer' => 'vizualizálása',
			'music.visualizerProfileLoading' => 'A track analízis...',
			'music.visualizerAmbientMotion' => 'Környezetmoció',
			'music.visualizerPlexLoudness' => 'Plex hangzás',
			'music.visualizerLiveAudio' => 'Élő hangelemzés',
			'music.visualizerPreviousPreset' => 'Előző vizuális stílus',
			'music.visualizerNextPreset' => 'Következő vizuális stílus',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Bloom',
			'music.visualizerPresetOrbitals' => 'Orbitalok',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Tunnel',
			'music.visualizerPresetTrackMap' => 'Térkép',
			'music.noLyrics' => 'Nincs elérhető dalszöveg',
			'music.sleepTimer' => 'Elalvási időzítő',
			'music.sleepTimerEndOfTrack' => 'Zeneszám vége',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} perc', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} perc', ), 
			'music.stopPlayback' => 'Lejátszás leállítása',
			'music.previousTrack' => 'Előző szám',
			'music.nextTrack' => 'Következő szám',
			'music.repeat' => 'Ismétlés',
			'music.repeatAll' => 'Összes ismétlése',
			'music.repeatOne' => 'Egy szám ismétlése',
			'music.instantMixNoServer' => 'Nem érhető el szerver az azonnali mixhez',
			'music.instantMixFailed' => 'Nem sikerült betölteni az azonnali mixet',
			'music.instantMixEmpty' => 'Az azonnali mix nem adott vissza zeneszámokat',
			'music.noAudioUrl' => ({required Object track}) => 'Nem érhető el hang-URL ehhez: ${track}',
			'music.discography.singlesAndEps' => 'Kislemezek és EP-k',
			'music.discography.live' => 'Élő',
			'music.discography.compilations' => 'Válogatások',
			'watchTogether.title' => 'Watch Together (Közös nézés)',
			'watchTogether.description' => 'Nézz tartalmat szinkronban barátaiddal és családoddal',
			'watchTogether.createRoom' => 'Szoba létrehozása',
			'watchTogether.creatingRoom' => 'Szoba létrehozása...',
			'watchTogether.joinRoom' => 'Csatlakozás szobához',
			'watchTogether.joiningRoom' => 'Csatlakozás a szobához...',
			'watchTogether.connecting' => 'Csatlakozás...',
			'watchTogether.relayPublic' => 'A szobák a nyilvános Open Watch Party-reléket használják.',
			'watchTogether.relayCustom' => ({required Object url}) => 'A szobák a saját relédet használják: ${url}.',
			'watchTogether.recentRooms' => 'Legutóbbi szobák',
			'watchTogether.roomActions' => 'Szobaműveletek',
			'watchTogether.renameRoom' => 'Szoba átnevezése',
			'watchTogether.removeRoom' => 'Eltávolítás',
			'watchTogether.enterRoomCode' => 'Add meg a házigazdától kapott 6 karakteres kódot.',
			'watchTogether.roomCode' => 'Szobakód',
			'watchTogether.paste' => 'Beillesztés',
			'watchTogether.noCodeInClipboard' => 'A vágólapon nincs szobakód',
			'watchTogether.copyCode' => 'Kód másolása',
			'watchTogether.codeCopied' => 'Szobakód másolva',
			'watchTogether.shareInvite' => 'Meghívó megosztása',
			'watchTogether.inviteCopied' => 'Meghívó másolva. Illeszd be egy üzenetbe.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.inviteMessage' => ({required Object code}) => 'Csatlakozz a Watch Together-szobámhoz a Plezyben: nyisd meg a Watch Together (Közös nézés) menüt, válaszd a Csatlakozás szobához lehetőséget, és írd be ezt a kódot: ${code}.',
			'watchTogether.openSessionControls' => 'Watch Together munkamenet-vezérlők megnyitása',
			'watchTogether.reconnecting' => 'Újracsatlakozás...',
			'watchTogether.reconnectingDescription' => 'Megszakadt a kapcsolat. Automatikusan visszacsatlakozol a szobához.',
			'watchTogether.connected' => 'Csatlakozva',
			'watchTogether.disconnected' => 'Kapcsolat bontva',
			'watchTogether.youAreHost' => 'Te vagy a házigazda',
			'watchTogether.hostedBy' => ({required Object name}) => 'Házigazda: ${name}',
			'watchTogether.hostControlsPlayback' => 'A házigazda vezérli a lejátszást',
			'watchTogether.anyoneCanControl' => 'Bárki vezérelheti a lejátszást',
			'watchTogether.roomLocked' => 'Szoba zárolva',
			'watchTogether.nowPlaying' => 'Most megy',
			'watchTogether.nothingPlaying' => 'Nincs lejátszás',
			'watchTogether.nothingPlayingHost' => 'Játssz le valamit bármelyik könyvtárból, hogy megoszd a szobával.',
			'watchTogether.nothingPlayingGuest' => 'Amikor a házigazda lejátszik valamit, itt fog megnyílni.',
			'watchTogether.notShareable' => 'Ehhez a videóhoz nincs katalógusbeli egyezés, ezért csak azok tudják lejátszani, akik hozzáférnek ugyanahhoz a szerverhez.',
			'watchTogether.searching' => 'A videó keresése a könyvtáraidban...',
			'watchTogether.yourCopy' => 'A saját példányod',
			'watchTogether.sharingYourCopy' => 'A saját példányodat osztod meg',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Saját példányod lejátszása (${difference})',
			'watchTogether.mismatchTitle' => 'A példányod hossza eltér',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'A legközelebbi példányod ${difference}, mint a szoba videója. Lehet, hogy más vágás vagy változat.',
			'watchTogether.playAnyway' => 'Lejátszás mégis',
			'watchTogether.chooseAnotherCopy' => 'Másik példány választása',
			'watchTogether.dontPlay' => 'Ne játszd le',
			'watchTogether.unavailableTitle' => 'Ez a videó nincs meg neked',
			'watchTogether.unavailableDescription' => 'A PlezyNG nem találta meg a könyvtáraidban. Válassz ki magad egy példányt, vagy keress újra.',
			'watchTogether.chooseCopy' => 'Példány választása',
			'watchTogether.searchAgain' => 'Keresés újra',
			'watchTogether.noCandidates' => 'Nem található példány a könyvtáraidban.',
			'watchTogether.choiceFailed' => 'Nem sikerült lejátszani ezt a példányt a szobának',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} különbséggel hosszabb',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} különbséggel rövidebb',
			'watchTogether.lengthSame' => 'Azonos hosszúságú',
			'watchTogether.lengthUnknown' => 'Ismeretlen hosszúságú',
			'watchTogether.joinCurrentPlayback' => 'Csatlakozás a jelenlegi lejátszáshoz',
			'watchTogether.joinCurrentPlaybackDescription' => 'Visszatérés ahhoz, amit a házigazda éppen néz',
			'watchTogether.stopMedia' => 'Videó leállítása mindenkinél',
			'watchTogether.syncOffset' => 'Szinkroneltolás',
			'watchTogether.syncOffsetDescription' => 'Told el a videódat, ha a szobához képest előrébb jár vagy lemarad.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'A példányod ${difference}, mint a szoba videója.',
			'watchTogether.applyDifference' => ({required Object offset}) => '${offset} alkalmazása',
			'watchTogether.offsetMinusSecond' => '-1 mp',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 mp',
			'watchTogether.participants' => 'Résztvevők',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résztvevő', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} résztvevő', ), 
			'watchTogether.hostBadge' => 'HÁZIGAZDA',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (te)',
			'watchTogether.playerIdle' => 'Tétlen',
			'watchTogether.playerLoading' => 'Betöltés',
			'watchTogether.playerReady' => 'Kész',
			'watchTogether.playerBuffering' => 'Pufferelés',
			'watchTogether.matchSearching' => 'Keresés',
			'watchTogether.matchMatched' => 'Megvan a videó',
			'watchTogether.matchMismatched' => 'Eltérő hosszúságú',
			'watchTogether.matchUnavailable' => 'Nincs meg a videó',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Eltolás: ${offset}',
			'watchTogether.makeHost' => 'Házigazdává tétel',
			'watchTogether.makeHostQuestion' => 'Átadod a házigazdaságot?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} vezérli majd a lejátszást és a munkamenetet mindenki számára.',
			'watchTogether.transfer' => 'Átadás',
			'watchTogether.removeParticipant' => 'Eltávolítás a szobából',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} eltávolítása?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} kikerül a szobából. A kóddal újra csatlakozhat, hacsak nem zárolod a szobát.',
			'watchTogether.remove' => 'Eltávolítás',
			'watchTogether.roomSettings' => 'Szobabeállítások',
			'watchTogether.letEveryoneControl' => 'Mindenki vezérelheti a lejátszást',
			'watchTogether.lockRoom' => 'Szoba zárolása',
			'watchTogether.lockRoomDescription' => 'Új résztvevők nem csatlakozhatnak',
			'watchTogether.leaveRoom' => 'Kilépés a szobából',
			'watchTogether.leaveRoomQuestion' => 'Kilépsz a szobából?',
			'watchTogether.leaveRoomConfirm' => 'A szobakóddal újra csatlakozhatsz.',
			'watchTogether.leave' => 'Kilépés',
			'watchTogether.endRoom' => 'Szoba bezárása',
			'watchTogether.endRoomQuestion' => 'Bezárod a szobát?',
			'watchTogether.endRoomConfirm' => 'Ezzel mindenki számára bezárod a szobát.',
			'watchTogether.end' => 'Befejezés',
			'watchTogether.playBlockedTitle' => 'A lejátszás nem indult el',
			'watchTogether.playBlockedDescription' => 'Nyomd meg a lejátszás gombot, hogy együtt nézhesd a szobával.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} elindította a lejátszást',
			'watchTogether.notices.playbackStarted' => 'A lejátszás elindult',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} szüneteltette a lejátszást',
			'watchTogether.notices.playbackPaused' => 'A lejátszás szünetel',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ide ugrott: ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Ugrás ide: ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} a sebességet ${speed} értékre állította',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Sebesség beállítva: ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} elindította: ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Most megy: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} leállította a videót',
			'watchTogether.notices.mediaStopped' => 'A videó leállt',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Várakozás: ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Várakozás a lemaradókra...',
			'watchTogether.notices.finished' => 'Befejeződött',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} lett a házigazda',
			'watchTogether.notices.youAreNowHost' => 'Mostantól te vagy a házigazda',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} csatlakozott',
			'watchTogether.notices.left' => ({required Object name}) => '${name} kilépett',
			'watchTogether.notices.controlRefused' => 'Csak a házigazda vezérelheti a lejátszást',
			'watchTogether.notices.searchFailed' => 'Néhány szerveren nem sikerült megkeresni a szoba videóját',
			'watchTogether.notices.playBlocked' => 'Az indításhoz nyomd meg a lejátszás gombot',
			'watchTogether.notices.shareFailed' => 'Nem sikerült megosztani ezt a videót a szobával',
			'watchTogether.notices.downloadNotShared' => 'A letöltések nem oszthatók meg a szobával, amíg a szerverük nem érhető el',
			'watchTogether.notices.openFailed' => 'Nem sikerült megnyitni a szoba videóját',
			'watchTogether.ended.ended' => 'A házigazda bezárta a szobát',
			'watchTogether.ended.kicked' => 'Eltávolítottak a szobából',
			'watchTogether.ended.expired' => 'A szoba lejárt',
			'watchTogether.ended.replaced' => 'Egy másik eszközön csatlakoztál ehhez a szobához',
			'watchTogether.ended.lost' => 'Megszakadt a kapcsolat a szobával',
			'watchTogether.errors.invalidCode' => 'Ez nem szobakód. A kód 6 betűből és számjegyből áll, 0, 1, I, L és O nélkül.',
			'watchTogether.errors.roomNotFound' => 'Nincs ilyen kódú szoba. Lehet, hogy már bezárták.',
			'watchTogether.errors.roomFull' => 'Ez a szoba megtelt.',
			'watchTogether.errors.roomLocked' => 'A házigazda zárolta ezt a szobát.',
			'watchTogether.errors.relayFull' => 'A Watch Together jelenleg túlterhelt. Próbáld újra később.',
			'watchTogether.errors.unreachable' => 'Nem sikerült elérni a Watch Together-relét. Ellenőrizd a kapcsolatot.',
			'watchTogether.errors.rateLimited' => 'Túl sok próbálkozás. Várj egy kicsit, majd próbáld újra.',
			'watchTogether.errors.clientBlocked' => 'A PlezyNG ezen verziója nem tudja használni a relét. Frissítsd az alkalmazást.',
			'watchTogether.errors.forbidden' => 'Ezt csak a házigazda teheti meg.',
			'watchTogether.errors.notInRoom' => 'Nem vagy szobában.',
			'watchTogether.errors.alreadyInRoom' => 'Már egy szobában vagy.',
			'watchTogether.errors.resumeFailed' => 'Nem sikerült visszacsatlakozni a szobához.',
			'watchTogether.errors.unsupported' => 'A relé ezt nem támogatja.',
			'watchTogether.errors.generic' => 'Hiba történt. Próbáld újra.',
			'watchTogether.untitledEpisode' => ({required Object number}) => '${number}. epizód',
			'downloads.title' => 'Letöltések',
			'downloads.manage' => 'Kezelés',
			'downloads.tvShows' => 'TV-sorozatok',
			'downloads.movies' => 'Filmek',
			'downloads.music' => 'Zene',
			'downloads.tracksQueued' => ({required Object count}) => '${count} zeneszám letöltésre sorba állítva',
			'downloads.noDownloads' => 'Még nincsenek letöltések',
			'downloads.noDownloadsDescription' => 'A letöltött tartalmak itt jelennek meg az offline megtekintéshez',
			'downloads.downloadNow' => 'Letöltés',
			'downloads.deleteDownload' => 'Letöltés törlése',
			'downloads.retryDownload' => 'Letöltés újrapróbálása',
			'downloads.downloadQueued' => 'Letöltés sorba állítva',
			'downloads.downloadResumed' => 'Letöltés folytatva',
			'downloads.serverErrorBitrate' => 'Szerverhiba: a fájl meghaladhatja a távoli bitrátakorlátot',
			'downloads.storageFull' => 'A letöltések leálltak a szabad tárhely védelme érdekében. Szabadíts fel helyet, vagy válassz másik letöltési helyet, majd próbáld újra.',
			'downloads.storageUnavailable' => 'A letöltések leálltak, mert a rendelkezésre álló tárhely nem ellenőrizhető. Ellenőrizd a letöltési helyet, majd próbáld újra.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} epizód letöltésre sorba állítva',
			'downloads.downloadDeleted' => 'Letöltés törölve',
			'downloads.deleteConfirm' => ({required Object title}) => 'Törlöd a következőt: "${title}" erről az eszközről?',
			'downloads.deleteCollectionDownloads' => 'Letöltések törlése',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Törlöd a(z) "${title}" összes letöltését erről az eszközről?',
			'downloads.collectionDownloadsDeleted' => 'Letöltések törölve',
			'downloads.cancelledDownloadTitle' => 'Megszakított letöltés',
			'downloads.cancelledDownloadMessage' => 'Ez a letöltés meg lett szakítva. Mit szeretnél tenni?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Minden epizód le van töltve',
			'downloads.resumeDownload' => 'Letöltés folytatása',
			'downloads.cancelledDownload' => 'Megszakított letöltés',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} szinkronizálása)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Letöltve: ${file} - Kattints a befejezéshez',
			'downloads.partialDownloadClickToComplete' => 'Részben letöltve - Kattints a befejezéshez',
			'downloads.deleting' => 'Törlés...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} törlése... (${current}/${total})',
			'downloads.queuedTooltip' => 'Sorban áll',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Sorba állítva: ${files}',
			'downloads.downloadingTooltip' => 'Letöltés...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Letöltés alatt: ${files}',
			'downloads.noDownloadsTree' => 'Nincsenek letöltések',
			'downloads.pauseAll' => 'Összes szüneteltetése',
			'downloads.resumeAll' => 'Összes folytatása',
			'downloads.retryAll' => 'Összes újrapróbálása',
			'downloads.retryFailed' => 'Sikertelen letöltések újrapróbálása',
			'downloads.deleteAll' => 'Összes törlése',
			'downloads.selectVersion' => 'Verzió kiválasztása',
			'downloads.allEpisodes' => 'Minden epizód',
			'downloads.unwatchedOnly' => 'Csak a nem látottak',
			'downloads.nextNUnwatched' => ({required Object count}) => 'A következő ${count} nem látott epizód',
			'downloads.customAmount' => 'Egyéni mennyiség...',
			'downloads.customAmountAny' => 'A megadott összeg (minden)',
			'downloads.randomEpisodes' => 'Rádió epizódok',
			'downloads.includeSpecials' => 'Különkiadások is',
			'downloads.howManyEpisodes' => 'Hány epizód?',
			'downloads.invalidEpisodeCount' => 'Adj meg egy érvényes epizódszámot.',
			'downloads.keepSynced' => 'Szinkronban tartás',
			'downloads.downloadOnce' => 'Egyszeri letöltés',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} nem látott epizód megtartása',
			'downloads.editSyncRule' => 'Szinkronizálási szabály szerkesztése',
			'downloads.removeSyncRule' => 'Szinkronizálási szabály eltávolítása',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Leállítod a(z) "${title}" szinkronizálását? A letöltött epizódok megmaradnak.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Leállítjuk a(z) "${title}" szinkronizálását?',
			'downloads.deleteSyncRuleDownloads' => 'A kapcsolódó letöltések törlése is',
			'downloads.deleteSyncRuleDownloadsDescription' => 'A másik szinkronszabály vagy profil által használt letöltések megmaradnak.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Szinkronizálási szabály létrehozva — ${count} nem látott epizód megtartása',
			'downloads.syncRuleUpdated' => 'Szinkronizálási szabály frissítve',
			'downloads.syncRuleRemoved' => 'Szinkronizálási szabály eltávolítva',
			'downloads.syncRuleAndDownloadsRemoved' => 'A szinkronszabály és a kapcsolódó letöltések eltávolítva',
			'downloads.syncRuleCleanupBusy' => 'A szinkronszabályok éppen frissülnek. Próbálja újra egy pillanat múlva.',
			'downloads.syncRuleCleanupUnavailable' => 'A kapcsolódó letöltések nem azonosíthatók biztonságosan. Csatlakoztassa újra a szervert, és próbálja újra, vagy távolítsa el a szabályt a letöltések törlése nélkül.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} új epizód szinkronizálva a következőhöz: ${title}',
			'downloads.syncNow' => 'Szinkronizálás most',
			'downloads.downloadsUpToDate' => 'A letöltések naprakészek',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Szinkronizálás teljes · ${queued} queued, ${removed} eltávolított',
			'downloads.activeSyncRules' => 'Szinkronizálási szabályok',
			'downloads.reviewOrphanFiles' => 'Árva letöltések áttekintése',
			'downloads.orphanReviewTitle' => 'Árva letöltések áttekintése',
			'downloads.orphanReviewDescription' => 'Ezek a címkézett fájlok a PlezyNG által kezelt alapértelmezett letöltési mappákban találhatók, és nincs hozzájuk tartozó letöltési rekord vagy aktív feladat. Törlés előtt ellenőrizze a listát.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} fájl · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} fájl törlése',
			'downloads.orphanCleanupNone' => 'Nem található árva letöltési fájl',
			'downloads.orphanCleanupFailed' => 'A PlezyNG nem tudta biztonságosan átvizsgálni a kezelt letöltési mappát. Nem töröltünk fájlokat.',
			'downloads.orphanCleanupChanged' => 'A letöltési lista az áttekintés közben megváltozott. Tisztítás előtt tekintse át újra a fájlokat.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} árva letöltési fájl törölve · ${size} tárhely felszabadítva',
			'downloads.noSyncRules' => 'Nincsenek szinkronizálási szabályok',
			'downloads.manageSyncRule' => 'Szinkronizálás kezelése',
			'downloads.editEpisodeCount' => 'Epizódszám',
			'downloads.editSyncFilter' => 'Szinkronizálási szűrő',
			'downloads.syncAllItems' => 'Minden elem szinkronizálása',
			'downloads.syncUnwatchedItems' => 'Nem látott elemek szinkronizálása',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Szerver: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Elérhető',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Bejelentkezés szükséges',
			'downloads.syncRuleAccessDenied' => 'Hozzáférés megtagadva',
			'downloads.syncRuleNotAvailableForProfile' => 'Nem érhető el a jelenlegi profilhoz',
			'downloads.syncRuleUnknownServer' => 'Ismeretlen szerver',
			'downloads.syncRuleListCreated' => 'Szinkronizálási szabály létrehozva',
			'downloads.backgroundWarning.bannerBlocked' => 'A letöltések leállnak, ha kilépsz az alkalmazásból',
			'downloads.backgroundWarning.bannerDegraded' => 'A háttérbeli letöltések korlátozottak lehetnek',
			'downloads.backgroundWarning.bannerAction' => 'Részletek',
			'downloads.backgroundWarning.sheetTitle' => 'A háttérbeli letöltések le vannak tiltva',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'A háttérbeli letöltések korlátozottak lehetnek',
			'downloads.backgroundWarning.sheetIntro' => 'Az Android megakadályozza, hogy a PlezyNG megbízhatóan töltsön le a háttérben.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Az eszközöd korlátozza, hogy a PlezyNG mikor tölthet le a háttérben.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'A PlezyNG háttérbeli használata korlátozva van. Állítsd az akkumulátor- vagy háttérhasználatát „Korlátlan” értékre.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Az Android korlátozott készenléti állapotba helyezte a Plezyt. Állítsd az akkumulátorhasználatát „Korlátlan” értékre.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'A letöltési értesítések ki vannak kapcsolva, ezért előfordulhat, hogy a folyamatjelzés és a vezérlők nem érhetők el.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Az értesítések ki vannak kapcsolva. Android 13 vagy újabb rendszeren szükségesek a hosszú háttérbeli letöltésekhez.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Az Adatforgalom-csökkentő be van kapcsolva, ezért mobiladat-kapcsolaton nem működnek a háttérbeli letöltések. Wi-Fi-n továbbra is működniük kell.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'A letöltések többször leálltak, miközben a PlezyNG a háttérben futott. Ellenőrizd a PlezyNG akkumulátor- vagy háttérhasználati beállításait.',
			'downloads.backgroundWarning.openSettings' => 'Beállítások megnyitása',
			'downloads.backgroundWarning.stillNotWorking' => 'Eszközspecifikus segítség',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Nézd meg az eszközödhöz tartozó lépéseket, vagy ha a probléma továbbra is fennáll, küldj naplót a Beállítások › Naplók megtekintése menüből.',
			'downloads.backgroundWarning.dialogTitle' => 'A letöltések nem biztos, hogy befejeződnek',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Letöltés mégis',
			'downloads.backgroundWarning.dialogFixFirst' => 'Előbb javítom',
			'downloads.backgroundWarning.statusTile' => 'Háttérbeli letöltések',
			'downloads.backgroundWarning.statusOk' => 'Futhat a háttérben',
			'downloads.backgroundWarning.statusBlocked' => 'A rendszerbeállítások blokkolják',
			'downloads.backgroundWarning.statusDegraded' => 'A rendszerbeállítások korlátozzák',
			'downloads.backgroundWarning.statusUnknown' => 'Még nincs ellenőrizve',
			'downloads.backgroundWarning.settingsUnavailable' => 'Ezen az eszközön nem sikerült megnyitni a rendszerbeállításokat',
			'downloads.backgroundWarning.linkUnavailable' => 'Ezen az eszközön nem sikerült megnyitni a dontkillmyapp.com webhelyet',
			'downloads.options' => 'Letöltések lehetőségei',
			'downloads.groupings.library' => 'Könyvtár',
			'downloads.groupings.collections' => 'Gyűjtemények',
			'downloads.unknownLibrary' => 'Ismeretlen könyvtár',
			'downloads.unknownShow' => 'Ismeretlen sorozat',
			'downloads.unknownSeason' => 'Ismeretlen évad',
			'downloads.unknownAlbum' => 'Ismeretlen album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} kész',
			'downloads.storageUsed' => ({required Object size}) => 'Használt tároló: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} letöltés', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} letöltés', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} bemutató', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} megtekintés', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmek', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmek', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', ), 
			'downloads.errorFileNotFound' => 'A fájl nem található (404)',
			'downloads.errorDownloadNotAllowed' => 'A szerver nem engedélyezi a letöltést (403)',
			'downloads.errorDownloadFailed' => 'A letöltés nem sikerült',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'A letöltés nem sikerült: ${reason}',
			'downloads.convertingOnServer' => 'A szerverre való átalakítás...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Szerverre való átalakítás · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'A letöltés nem sikerült (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Az utófeldolgozás nem sikerült: ${reason}',
			'downloads.reasonFileNotSaved' => 'a fájlt nem sikerült menteni erre az eszközre',
			'downloads.reasonCannotResume' => 'a részleges letöltést nem sikerült folytatni',
			'downloads.reasonDeviceStorageFull' => 'az eszközön elfogyott a tárhely',
			'downloads.notificationDownloading' => 'Letöltés...',
			'downloads.notificationComplete' => 'Letöltés kész',
			'downloads.notificationPaused' => 'Letöltés szüneteltetve',
			'shaders.title' => 'Shaderek',
			'shaders.noShaderDescription' => 'Nincs videójavítás',
			'shaders.nvscalerDescription' => 'NVIDIA képskálázás az élesebb videóért',
			'shaders.artcnnVariantNeutral' => 'Semleges',
			'shaders.artcnnVariantDenoise' => 'Zajcsökkentés',
			'shaders.artcnnVariantDenoiseSharpen' => 'Zajcsökkentés + Élesítés',
			'shaders.qualityFast' => 'Gyors',
			'shaders.qualityHQ' => 'Kiváló minőség',
			'shaders.mode' => 'Mód',
			'shaders.importShader' => 'Shader importálása',
			'shaders.customShaderDescription' => 'Egyéni GLSL shader',
			'shaders.shaderImported' => 'Shader importálva',
			'shaders.shaderImportFailed' => 'Nem sikerült a shader importálása',
			'shaders.deleteShader' => 'Shader törlése',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Törlöd a következőt: "${name}"?',
			'companionRemote.title' => 'Kísérőtávirányító',
			'companionRemote.connectedTo' => ({required Object name}) => 'Csatlakoztatva a következőhöz: ${name}',
			'companionRemote.unknownDevice' => 'Ismeretlen eszköz',
			'companionRemote.session.startingServer' => 'Távirányító-szerver indítása...',
			'companionRemote.session.hostAddress' => 'Gazdagép címe',
			'companionRemote.session.connected' => 'Csatlakoztatva',
			'companionRemote.session.serverRunning' => 'A távirányító-szerver aktív',
			'companionRemote.session.serverStopped' => 'A távirányító-szerver leállítva',
			'companionRemote.session.serverRunningDescription' => 'A hálózaton lévő mobileszközök csatlakozhatnak ehhez az alkalmazáshoz',
			'companionRemote.session.serverStoppedDescription' => 'Indítsd el a szervert, hogy a mobileszközök csatlakozhassanak',
			'companionRemote.session.usePhoneToControl' => 'Használd a mobileszközödet az alkalmazás vezérléséhez',
			'companionRemote.session.startServer' => 'Szerver indítása',
			'companionRemote.session.stopServer' => 'Szerver leállítása',
			'companionRemote.session.minimize' => 'Kis méret',
			'companionRemote.session.manualAddressHint' => 'Kézi kapcsolódási cím:',
			'companionRemote.pairing.discoveryDescription' => 'Az azonos Plex-fiókot használó PlezyNG-eszközök itt jelennek meg',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Csatlakozás...',
			'companionRemote.pairing.searchingForDevices' => 'Eszközök keresése...',
			'companionRemote.pairing.noDevicesFound' => 'Nem találhatók eszközök a hálózaton',
			'companionRemote.pairing.noDevicesHint' => 'Nyisd meg a Plezyt asztali gépen, és használd ugyanazt a Wi-Fi-hálózatot',
			'companionRemote.pairing.availableDevices' => 'Elérhető eszközök',
			'companionRemote.pairing.manualConnection' => 'Kézi csatlakozás',
			'companionRemote.pairing.cryptoInitFailed' => 'Nem sikerült elindítani a biztonságos kapcsolatot. Először jelentkezz be a Plexbe.',
			'companionRemote.pairing.validationHostRequired' => 'Add meg a gazdagép címét',
			'companionRemote.pairing.validationHostFormat' => 'A formátumnak IP:port kell lennie (pl. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'A csatlakozás túllépte az időkorlátot. Használd ugyanazt a hálózatot mindkét eszközön.',
			'companionRemote.pairing.sessionNotFound' => 'Az eszköz nem található. Győződj meg arról, hogy a PlezyNG fut a gazdagépen.',
			'companionRemote.pairing.authFailed' => 'A hitelesítés nem sikerült. Mindkét eszközön ugyanazt a Plex-fiókot kell használni.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nem sikerült a csatlakozás: ${error}',
			'companionRemote.pairing.codeTitle' => 'páros kód',
			'companionRemote.pairing.codeDescription' => 'A Companion Remote-ban megjelenített kódot a tárolóeszközön adja meg. Mindkét eszköznek olyan verziót kell használnia, amely támogatja a biztonságos párosítást.',
			'companionRemote.pairing.codeInvalid' => 'Írja be a házigazda kódjából származó 32 betűt és számot.',
			'companionRemote.pairing.updateRequired' => 'Mindkét készülék frissítése olyan verzióra, amely támogatja a biztonságos párosítást.',
			'companionRemote.pairing.hostDescription' => 'Adja meg ezt a kódot egyszer minden távoli. tartsa magán: ez adja meg a profil ellenőrzését.',
			'companionRemote.pairing.resetCode' => 'Újraállítása páros kód',
			'companionRemote.pairing.resetDescription' => 'Kapcsolja ki az összes távoli és hozzon létre egy új kódot. Minden távoli kell párosítani újra.',
			'companionRemote.remote.disconnectConfirm' => 'Bontod a kapcsolatot a távoli munkamenettel?',
			'companionRemote.remote.reconnecting' => 'Újracsatlakozás...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => '${current} / 5 próbálkozás',
			'companionRemote.remote.retryNow' => 'Újrapróbálkozás most',
			'companionRemote.remote.tabRemote' => 'Távirányító',
			'companionRemote.remote.tabPlay' => 'Lejátszás',
			'companionRemote.remote.tabMore' => 'Egyebek',
			'companionRemote.remote.menu' => 'Menü',
			'companionRemote.remote.tabNavigation' => 'Navigációs lap',
			'companionRemote.remote.tabDiscover' => 'Felfedezés',
			'companionRemote.remote.tabLibraries' => 'Könyvtárak',
			'companionRemote.remote.tabSearch' => 'Keresés',
			'companionRemote.remote.tabDownloads' => 'Letöltések',
			'companionRemote.remote.tabSettings' => 'Beállítások',
			'companionRemote.remote.previous' => 'Előző',
			'companionRemote.remote.playPause' => 'Lejátszás/Szünet',
			'companionRemote.remote.next' => 'Következő',
			'companionRemote.remote.seekBack' => 'Visszatekerés',
			'companionRemote.remote.stop' => 'Leállítás',
			'companionRemote.remote.seekForward' => 'Előretekerés',
			'companionRemote.remote.volume' => 'Hangerő',
			'companionRemote.remote.volumeDown' => 'Hangerő le',
			'companionRemote.remote.volumeUp' => 'Hangerő fel',
			'companionRemote.remote.fullscreen' => 'Teljes képernyő',
			'companionRemote.remote.subtitles' => 'Feliratok',
			'companionRemote.remote.audio' => 'Hang',
			'companionRemote.remote.searchHint' => 'Keresés az asztali gépen...',
			'companionRemote.errors.noNetworkInterface' => 'Nem található hálózati csatoló',
			'companionRemote.errors.authenticationFailed' => 'A hitelesítés nem sikerült',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Nem sikerült elindítani a távirányító-szervert: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Nem sikerült elküldeni a távoli parancsot: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Időtúllépés a munkamenethez való csatlakozáskor',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Egyetlen címhez sem sikerült csatlakozni',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'A kapcsolat megszakadt ${attempts} próbálkozás után',
			'companionRemote.errors.connectionLost' => 'A kapcsolat megszakadt',
			'companionRemote.closedBeforeAuth' => 'A kapcsolat a hitelesítés előtt megszakadt',
			'videoSettings.playbackSpeed' => 'Lejátszási sebesség',
			'videoSettings.normalSpeed' => 'Normál',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktív (${duration})',
			'videoSettings.zoom' => 'Nagyítás',
			'videoSettings.sleepTimer' => 'Elalvási időzítő',
			'videoSettings.audioSync' => 'Hang szinkronizálása',
			'videoSettings.subtitleSync' => 'Felirat szinkronizálása',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'A HDR itt nem érhető el – ez az asztali kompozitor vagy videókimenet nem képes továbbítani.',
			'videoSettings.hdrToneMapping' => 'HDR-tónusleképezés',
			'videoSettings.hdrToneMappingCompositor' => 'Kompozitor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Továbbítja a forrás HDR-metaadatait, és az asztali kompozitorra bízza a tónusleképezést.',
			'videoSettings.hdrToneMappingPlayer' => 'Lejátszó',
			'videoSettings.hdrToneMappingPlayerDescription' => 'A lejátszóban a kijelző maximális fényerejéhez igazítja a képet, majd közli az eredményt a kompozitorral.',
			'videoSettings.hdrToneMappingFailed' => 'Nem sikerült módosítani a HDR-tónusleképezést – továbbra is az előző mód aktív.',
			'videoSettings.audioOutput' => 'Hangkimenet',
			'videoSettings.videoTrack' => 'Videósáv',
			'videoSettings.videoTrackDescription' => 'Válaszd ki a megjelenítendő videofolyamot. MPV-lejátszáskor érhető el, ha a fájl több videósávot tartalmaz.',
			'videoSettings.videoTrackDefault' => 'Alapértelmezett',
			'videoSettings.videoTrackUnavailable' => 'Nincsenek elérhető alternatív videósávok.',
			'videoSettings.videoTrackFailed' => 'Nem sikerült megváltoztatni a videósávot.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => '${id}. sáv',
			'videoSettings.performanceOverlay' => 'Teljesítményadatok',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Térhatású',
			'videoSettings.audioOutputSpatial' => 'Térbeli hang',
			'videoSettings.audioOutputStereo' => 'Sztereó',
			'videoSettings.audioEqualizer' => 'Audio egyenlet',
			'videoSettings.audioEqualizerDescription' => '10 Band Equalizer MPV. A hangszűrők dekódolt audio használatát használják, és kapcsolja ki a passthrough-t.',
			'videoSettings.audioEqualizerFlat' => 'Sík',
			'videoSettings.audioEqualizerActive' => 'Egyéni',
			'videoSettings.audioEqualizerSaveFailed' => 'Nem menthetek meg a hang egyenletítő beállításokat.',
			'videoSettings.audioEffectsDescription' => 'A hatások dekódolt hangot használnak, így a passthrough elfordul. szoba környezete és sztereó kiterjesztése függ a MPV Építsen és nyomon kövesse.',
			'videoSettings.audioStereoWidth' => 'Stereó bővítés',
			'videoSettings.audioSpatializer' => 'Szoba környezete',
			'videoSettings.audioSpatializerDescription' => 'Adjunk nyugodt helyiség reflexiókat.',
			'videoSettings.audioPitch' => 'Pécsi változás',
			'videoSettings.audioPitchDescription' => 'Változtassa meg a pályát, nem változtatja meg a sebességet MPV Az építkezésnek tartalmaznia kell Rubber BandA',
			'videoSettings.audioEffectUnavailable' => 'Ez a hatás nem áll rendelkezésre ezen a pályán, vagy MPV Az építkezés.',
			'videoSettings.backgroundVideoAudio' => 'Videó audio háttér',
			'videoSettings.backgroundVideoAudioDescription' => 'A videó hangjátékot a lejátszó elhagyása után tartsa; a kép elrejtve van, amíg visszatér. Android médiaszámlálási értesítést használ.',
			'videoSettings.audioNormalization' => 'Hangerő normalizálása',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'PCM-mé dekódolja a hangot; a passthrough ki van kapcsolva, amíg ez be van kapcsolva',
			'performanceOverlay.color' => 'Szín',
			'performanceOverlay.performance' => 'Teljesítmény',
			'performanceOverlay.buffer' => 'Puffer',
			'performanceOverlay.app' => 'Alkalmazás',
			'performanceOverlay.decoder' => 'Dekóder',
			'performanceOverlay.rawDecoder' => 'Nyers dekóder',
			'performanceOverlay.tunneling' => 'Alagutazás',
			'performanceOverlay.passthrough' => 'Passthrough',
			'performanceOverlay.aspect' => 'Méretarány',
			'performanceOverlay.rotation' => 'Forgatás',
			'performanceOverlay.dvSource' => 'DV-forrás',
			'performanceOverlay.dvPath' => 'DV-útvonal',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision-dekóder',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision-dekóder (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Alapréteg',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10-alapréteg',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG-alapréteg',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR-alapréteg',
			'performanceOverlay.dvRouteReshaped' => 'RPU-átformálás (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Kísérleti P7 FEL grafika (nem minősített)',
			'performanceOverlay.p7Conversion' => 'P7-átalakítás',
			'performanceOverlay.sampleRate' => 'Mintavételezési frekvencia',
			'performanceOverlay.pixelFormat' => 'Képpontformátum',
			'performanceOverlay.hwFormat' => 'Hardverformátum',
			'performanceOverlay.matrix' => 'Mátrix',
			'performanceOverlay.primaries' => 'Elsődleges színek',
			'performanceOverlay.transfer' => 'Átvitel',
			'performanceOverlay.renderFps' => 'Renderelési FPS',
			'performanceOverlay.displayFps' => 'Kijelző-FPS',
			'performanceOverlay.avSync' => 'A/V-szinkron',
			'performanceOverlay.dropped' => 'Eldobva',
			'performanceOverlay.dvRpus' => 'DV RPU-k',
			'performanceOverlay.dvRpuAverage' => 'DV RPU-átlag',
			'performanceOverlay.dvSampleAverage' => 'DV-mintaátlag',
			'performanceOverlay.maxLuma' => 'Maximális luma',
			'performanceOverlay.minLuma' => 'Minimális luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Használt gyorsítótár',
			'performanceOverlay.cacheLimit' => 'Gyorsítótár korlátja',
			'performanceOverlay.speed' => 'Sebesség',
			'performanceOverlay.player' => 'Lejátszó',
			'performanceOverlay.playMethod' => 'Játék módszer',
			'performanceOverlay.memory' => 'Memória',
			'performanceOverlay.uiFps' => 'Felület-FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Szoftveres',
			'performanceOverlay.decoderHardware' => 'Hardveres',
			'performanceOverlay.tunnelingActive' => 'Aktív',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} sikertelen)',
			'externalPlayer.title' => 'Külső lejátszó',
			'externalPlayer.useExternalPlayer' => 'Külső lejátszó használata',
			'externalPlayer.useExternalPlayerDescription' => 'Videók megnyitása egy másik alkalmazásban',
			'externalPlayer.selectPlayer' => 'Lejátszó kiválasztása',
			'externalPlayer.customPlayers' => 'Egyéni lejátszók',
			'externalPlayer.systemDefault' => 'Rendszer alapértelmezése',
			'externalPlayer.addCustomPlayer' => 'Egyéni lejátszó hozzáadása',
			'externalPlayer.playerName' => 'Lejátszó neve',
			'externalPlayer.playerNameHint' => 'Saját lejátszó',
			'externalPlayer.playerCommand' => 'Parancs',
			'externalPlayer.playerPackage' => 'Csomagnév',
			'externalPlayer.playerUrlScheme' => 'URL-séma',
			'externalPlayer.off' => 'Ki',
			'externalPlayer.launchFailed' => 'Nem sikerült megnyitni a külső lejátszót',
			'externalPlayer.appNotInstalled' => ({required Object name}) => 'A(z) ${name} nincs telepítve',
			'externalPlayer.playInExternalPlayer' => 'Lejátszás külső lejátszóban',
			'externalPlayer.description' => 'Válasszon egy másik alkalmazást, hogy nyissa meg a videókat. A rendelkezésre álló játékosok attól függnek, hogy a készülék és telepített alkalmazások.',
			'externalPlayer.systemDefaultDescription' => 'Hagyja, hogy az operációs rendszer nyissa meg a videót az alapértelmezett alkalmazással.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Nyissa meg a videókat a ${player} használatával.',
			'externalPlayer.playerNameDescription' => 'A címke a játékosok listáján látható.',
			'externalPlayer.playerPackageDescription' => 'Adja meg az Android csomag nevét a játékos alkalmazás, mint például com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Írja be a telepített játékos parancsot vagy végrehajtható utat erre a készülékre.',
			'externalPlayer.playerUrlSchemeDescription' => 'Írja be az URL-t és az opcionális URL-típusot, amelyet a játékos indításához használnak.',
			'metadataEdit.editMetadata' => 'Szerkesztés...',
			'metadataEdit.screenTitle' => 'Metaadatok szerkesztése',
			'metadataEdit.basicInfo' => 'Alapinformációk',
			'metadataEdit.artwork' => 'Borítók és képek',
			'metadataEdit.advancedSettings' => 'Haladó beállítások',
			'metadataEdit.title' => 'Cím',
			'metadataEdit.sortTitle' => 'Rendezési cím',
			'metadataEdit.originalTitle' => 'Eredeti cím',
			'metadataEdit.releaseDate' => 'Bemutató dátuma',
			'metadataEdit.contentRating' => 'Korhatár-besorolás',
			'metadataEdit.studio' => 'Stúdió',
			'metadataEdit.tagline' => 'Jelmondat',
			'metadataEdit.summary' => 'Összefoglaló',
			'metadataEdit.poster' => 'Poszter',
			'metadataEdit.background' => 'Háttér',
			'metadataEdit.logo' => 'Logó',
			'metadataEdit.squareArt' => 'Négyzetes kép',
			'metadataEdit.selectPoster' => 'Poszter kiválasztása',
			'metadataEdit.selectBackground' => 'Háttér kiválasztása',
			'metadataEdit.selectLogo' => 'Logó kiválasztása',
			'metadataEdit.selectSquareArt' => 'Négyzetes kép kiválasztása',
			'metadataEdit.fromUrl' => 'URL-ről',
			'metadataEdit.uploadFile' => 'Fájl feltöltése',
			'metadataEdit.enterImageUrl' => 'Add meg a kép URL-címét',
			'metadataEdit.imageUrl' => 'Kép URL-címe',
			'metadataEdit.metadataUpdated' => 'Metaadatok frissítve',
			'metadataEdit.metadataUpdateFailed' => 'Nem sikerült a metaadatok frissítése',
			'metadataEdit.artworkUpdated' => 'Képek frissítve',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.artworkUpdateFailed' => 'Nem sikerült a képek frissítése',
			'metadataEdit.noArtworkAvailable' => 'Nincsenek elérhető képek',
			'metadataEdit.artworkOption' => ({required Object index}) => '${index}. képváltozat',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => '${index}. képváltozat, kiválasztva',
			'metadataEdit.notSet' => 'Nincs beállítva',
			'metadataEdit.libraryDefault' => 'Könyvtári alapértelmezés',
			'metadataEdit.accountDefault' => 'Fiók alapértelmezése',
			'metadataEdit.seriesDefault' => 'Sorozat alapértelmezése',
			'metadataEdit.episodeSorting' => 'Epizódok rendezése',
			'metadataEdit.oldestFirst' => 'Legrégebbi elöl',
			'metadataEdit.newestFirst' => 'Legújabb elöl',
			'metadataEdit.keep' => 'Megtartás',
			'metadataEdit.allEpisodes' => 'Minden epizód',
			'metadataEdit.latestEpisodes' => ({required Object count}) => 'Legutóbbi ${count} epizód',
			'metadataEdit.latestEpisode' => 'Legutóbbi epizód',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Az elmúlt ${count} napban hozzáadott epizódok',
			'metadataEdit.deleteAfterPlaying' => 'Epizódok törlése lejátszás után',
			'metadataEdit.never' => 'Soha',
			'metadataEdit.afterADay' => 'Egy nap után',
			'metadataEdit.afterAWeek' => 'Egy hét után',
			'metadataEdit.afterAMonth' => 'Egy hónap után',
			'metadataEdit.onNextRefresh' => 'A következő frissítéskor',
			'metadataEdit.seasons' => 'Évadok',
			'metadataEdit.show' => 'Megjelenítés',
			'metadataEdit.hide' => 'Elrejtés',
			'metadataEdit.episodeOrdering' => 'Epizódok sorrendje',
			'metadataEdit.tmdbAiring' => 'The Movie Database (sugárzási sorrend)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (sugárzási sorrend)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (abszolút sorrend)',
			'metadataEdit.metadataLanguage' => 'Metaadatok nyelve',
			'metadataEdit.useOriginalTitle' => 'Eredeti cím használata',
			'metadataEdit.preferredAudioLanguage' => 'Elsődleges hangnyelv',
			'metadataEdit.preferredSubtitleLanguage' => 'Elsődleges feliratnyelv',
			'metadataEdit.subtitleMode' => 'Automatikus feliratválasztási mód',
			'metadataEdit.manuallySelected' => 'Kézzel kiválasztva',
			'metadataEdit.shownWithForeignAudio' => 'Idegen nyelvű hang esetén megjelenítve',
			'metadataEdit.alwaysEnabled' => 'Mindig engedélyezve',
			'metadataEdit.tags' => 'Címkék',
			'metadataEdit.addTag' => 'Címke hozzáadása',
			'metadataEdit.genre' => 'Műfaj',
			'metadataEdit.director' => 'Rendező',
			'metadataEdit.writer' => 'Író',
			'metadataEdit.producer' => 'Producer',
			'metadataEdit.country' => 'Ország',
			'metadataEdit.collection' => 'Gyűjtemény',
			'metadataEdit.label' => 'Kiadó',
			'metadataEdit.quickTag' => 'Gyors címke...',
			'matchScreen.match' => 'Párosítás...',
			'matchScreen.fixMatch' => 'Párosítás javítása...',
			'matchScreen.unmatch' => 'Párosítás megszüntetése',
			'matchScreen.unmatchConfirm' => 'Törlöd ezt a párosítást? A Plex párosítatlanként kezeli az újrapárosításig.',
			'matchScreen.unmatchSuccess' => 'Párosítás megszüntetve',
			'matchScreen.unmatchFailed' => 'Nem sikerült a párosítás megszüntetése',
			'matchScreen.matchApplied' => 'Párosítás alkalmazva',
			'matchScreen.matchFailed' => 'Nem sikerült a párosítás alkalmazása',
			'matchScreen.titleHint' => 'Cím',
			'matchScreen.yearHint' => 'Év',
			'matchScreen.search' => 'Keresés',
			'matchScreen.noMatchesFound' => 'Nincsenek egyezések',
			'serverTasks.title' => 'Szerverfeladatok',
			'serverTasks.failedToLoad' => 'Nem sikerült a feladatok betöltése',
			'serverTasks.noTasks' => 'Nincsenek futó feladatok',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Csatlakoztatva',
			'trakt.connectedAs' => ({required Object username}) => '@${username} néven csatlakoztatva',
			'trakt.disconnectConfirm' => 'Leválasztod a Trakt-fiókot?',
			'trakt.disconnectConfirmBody' => 'A PlezyNG nem küld több eseményt a Traktnak. Bármikor újracsatlakozhatsz.',
			'trakt.scrobble' => 'Valós idejű scrobbling',
			'trakt.scrobbleDescription' => 'Lejátszási, szüneteltetési és leállítási események küldése a Traktnak lejátszás közben.',
			'trakt.watchedSync' => 'Megtekintési állapot szinkronizálása',
			'trakt.watchedSyncDescription' => 'Ha egy elemet megtekintettként jelölsz meg a Plezyben, a Trakt is megtekintettként jelöli.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr csatlakoztatása',
			'seerr.serverUrl' => 'Szerver URL-címe',
			'seerr.serverUrlHelper' => 'A Seerr példányod címe',
			'seerr.checkServer' => 'Folytatás',
			'seerr.signInWithJellyfin' => 'Bejelentkezés Jellyfinnel',
			'seerr.signInWithEmby' => 'Bejelentkezés Emby-vel',
			'seerr.signInWithLocal' => 'Helyi fiók használata',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Ez a Seerr példány nem kínál olyan bejelentkezési módot, amit a PlezyNG támogat.',
			'seerr.instance' => 'Példány',
			'seerr.disconnectConfirm' => 'Leválasztod a Seerr-kapcsolatot?',
			'seerr.disconnectConfirmBody' => 'A PlezyNG elfelejti ezt a Seerr példányt. Bármikor újracsatlakozhatsz.',
			'seerr.request' => 'Igénylés',
			'seerr.request4k' => 'Igénylés 4K-ban',
			'seerr.seasons' => 'Évadok',
			'seerr.allSeasons' => 'Minden évad',
			'seerr.advancedOptions' => 'Haladó',
			'seerr.destinationServer' => 'Célszerver',
			'seerr.qualityProfile' => 'Minőségi profil',
			'seerr.rootFolder' => 'Gyökérmappa',
			'seerr.languageProfile' => 'Nyelvi profil',
			'seerr.tags' => 'Címkék',
			'seerr.noTags' => 'Nincsenek címkék',
			'seerr.defaultOption' => ({required Object name}) => '${name} (alapértelmezett)',
			'seerr.animeNote' => 'Ez a sorozat anime.',
			'seerr.requestSubmitted' => 'Igénylés elküldve',
			'seerr.requestFailed' => ({required Object error}) => 'Az igénylés nem sikerült: ${error}',
			'seerr.requestsLoadFailed' => 'Nem sikerült betölteni az igénylési opciókat',
			'seerr.nothingToRequest' => 'Minden elem már elérhető vagy igényelve van.',
			'seerr.statusAvailable' => 'Elérhető',
			'seerr.statusPartiallyAvailable' => 'Részben elérhető',
			'seerr.statusRequested' => 'Igényelve',
			'seerr.statusProcessing' => 'Feldolgozás alatt',
			'seerr.statusBlocklisted' => 'Tiltólistán',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Nem sikerült elérni ezt: ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Nem található Seerr-példány ezen a címen: ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'A Seerr helyett egy hitelesítő fordított proxy (SSO vagy HTTP-hitelesítés) válaszolt. A PlezyNG nem tud rajta bejelentkezni: engedd, hogy a Seerr /api/v1 útvonala megkerülje a proxyt ennél az alkalmazásnál, vagy használj olyan címet, amely közvetlenül eléri a Seerr-t.',
			'seerr.invalidUrl' => 'Adj meg egy szervercímet, például: https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Ez a Seerr-példány nem támogatja a Quick Connectet. Seerr 3.4 vagy újabb verzió szükséges.',
			'seerr.notInitialized' => 'Ennek a Seerr-példánynak a kezdeti beállítása még nem fejeződött be',
			'seerr.noPlexTokenForReauth' => 'Nem áll rendelkezésre Plex-token az újbóli bejelentkezéshez',
			'seerr.noStoredCredentials' => 'Nem állnak rendelkezésre mentett hitelesítő adatok az újbóli bejelentkezéshez',
			'seerr.signInRejected' => 'A bejelentkezést elutasították',
			'seerr.noSessionCookie' => 'A Seerr nem adott ki munkamenet-sütit',
			'seerr.freshCookieRejected' => 'A Seerr elutasította az új munkamenet-sütit',
			'seerr.noUserInformation' => 'A Seerr nem adott vissza felhasználói adatokat',
			'seerr.sessionRejectedAfterReauth' => 'A munkamenetet az újbóli bejelentkezés után elutasították',
			'seerr.permissionDenied' => 'A Seerr elutasította ezt a műveletet: a fiókod már nem rendelkezik a szükséges jogosultsággal',
			'seerr.permissionRevoked' => 'Már nincs jogosultságod ennek az igényléséhez',
			'services.title' => 'Szolgáltatások',
			'services.hubSubtitle' => 'Megtekintési haladás szinkronizálása és új tartalmak igénylése.',
			'services.integrations' => 'Integrációk',
			'services.notConnected' => 'Nincs csatlakoztatva',
			'services.connectedAs' => ({required Object username}) => '@${username} néven csatlakoztatva',
			'services.scrobble' => 'Haladás automatikus követése',
			'services.scrobbleDescription' => 'Lista frissítése, amikor befejezel egy epizódot vagy filmet.',
			'services.disconnectConfirm' => ({required Object service}) => 'Leválasztod a(z) ${service} szolgáltatást?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'A PlezyNG nem frissíti többé a(z) ${service} adatait. Bármikor újracsatlakozhatsz.',
			'services.connectFailed' => ({required Object service}) => 'Nem sikerült csatlakozni a következőhöz: ${service}. Próbáld újra.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Simkl újracsatlakoztatása',
			'services.simklReconnect.subtitle' => 'A Simkl kivezeti a kapcsolat által használt bejelentkezési módot. Az újracsatlakozás megnyitja a simkl.com oldalt, ahol jóváhagyhatod a Plezyt — a PlezyNG sosem látja a jelszavadat. A megtekintési előzményeid a Simklen maradnak.',
			'services.deviceCode.title' => ({required Object service}) => 'PlezyNG aktiválása a következőn: ${service}',
			'services.deviceCode.instructions' => 'Olvasd be a QR-kódot, vagy nyisd meg az alábbi címet, és írd be ezt a kódot:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Nyisd meg a(z) ${service} oldalt az aktiváláshoz',
			'services.deviceCode.copyCode' => 'Aktiválási kód másolása',
			'services.deviceCode.waitingForAuthorization' => 'Várakozás az engedélyezésre…',
			'services.deviceCode.codeCopied' => 'Kód másolva',
			'services.oauthProxy.title' => ({required Object service}) => 'Bejelentkezés ide: ${service}',
			'services.oauthProxy.body' => 'Olvasd be ezt a QR-kódot vagy nyisd meg az URL-t bármelyik eszközön.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Nyisd meg a(z) ${service} oldalt a bejelentkezéshez',
			'services.pendingAuth.copyUrl' => 'Bejelentkezési URL másolása',
			'services.pendingAuth.urlCopied' => 'URL másolva',
			'services.libraryFilter.title' => 'Könyvtárszűrő',
			'services.libraryFilter.subtitleAllSyncing' => 'Minden könyvtár szinkronizálása',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nincs szinkronizálás',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} kizárva',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} engedélyezve',
			'services.libraryFilter.mode' => 'Szűrési mód',
			'services.libraryFilter.modeBlacklist' => 'Tiltólista',
			'services.libraryFilter.modeWhitelist' => 'Engedélyezőlista',
			'services.libraryFilter.modeHintBlacklist' => 'Minden könyvtár szinkronizálása az alább bejelöltek kivételével.',
			'services.libraryFilter.modeHintWhitelist' => 'Csak az alább bejelölt könyvtárak szinkronizálása.',
			'services.libraryFilter.libraries' => 'Könyvtárak',
			'services.libraryFilter.noLibraries' => 'Nincsenek elérhető könyvtárak',
			'services.libraryFilter.modeDescription' => 'Válassza ki, hogy a ellenőrzött könyvtárak nem szinkronizálódnak-e, vagy az egyetlen könyvtár, amely szinkráló.',
			'services.seerrDescription' => 'Csatlakozzon a Seerr-hez vagy az Overseerr-hoz, hogy címeket keressen és médiakérdéseket küldjön.',
			'services.trackerDescriptions.trakt' => 'Szinkronizálja a megtekintett epizódokat és filmeket a Trakt fiókjával.',
			'services.trackerDescriptions.mal' => 'Szinkronizálja az anime listákat és nézze meg a fejlődést MyAnimeList segítségével.',
			'services.trackerDescriptions.anilist' => 'Szinkronizálja az anime listákat, és nézd meg a haladást az AniList segítségével.',
			'services.trackerDescriptions.simkl' => 'Sync filmeket, televíziós műsorokat és anime-t nézett a Simklrel.',
			'services.trackerDescriptions.mdblist' => 'MDBList minősítések és listák megjelenítése az ajánlásokban és a felfedezésben.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product} szerver hozzáadása',
			'addServer.serverUrls' => 'Szerver URL-címei',
			'addServer.serverUrlsHelper' => 'Több URL is megadható, vesszővel elválasztva.',
			'addServer.findServer' => 'Szerver keresése',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Helyi ${product} szerverek keresése...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Helyi ${product} szerverek',
			'addServer.username' => 'Felhasználónév',
			'addServer.password' => 'Jelszó',
			'addServer.signIn' => 'Bejelentkezés',
			'addServer.change' => 'Módosítás',
			'addServer.required' => 'Kötelező',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Nem sikerült elérni a szervert: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'A bejelentkezés nem sikerült: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'A Quick Connect használata nem sikerült: ${error}',
			'addServer.addPlexTitle' => 'Bejelentkezés Plexszel',
			'addServer.pinExpired' => 'A PIN-kód a bejelentkezés előtt lejárt. Próbáld újra.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Nem sikerült a fiók regisztrálása: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Adja meg a(z) ${product} szerver URL-jét',
			'addServer.addConnectionTitle' => 'Kapcsolat hozzáadása',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Hozzáadás a következőhöz: ${name}',
			'addServer.signInWithPlexCard' => 'Bejelentkezés Plexszel',
			'addServer.signInWithPlexCardSubtitle' => 'Eszköz engedélyezése. A megosztott szerverek hozzáadásra kerülnek.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex-fiók engedélyezése. A Plex Home-felhasználókból profilok lesznek.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Csatlakozás a(z) ${product} szolgáltatáshoz',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Adja meg a szerver URL-jét, felhasználónevét és jelszavát.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Jelentkezzen be a(z) ${product} szerverére. A(z) ${name} szolgáltatáshoz kötődik.',
			'addServer.borrowFromAnotherProfile' => 'Kapcsolat használata másik profilból',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Egy másik profil kapcsolatának használata. A PIN-kóddal védett profilokhoz PIN-kód szükséges.',
			'addServer.invalidCredentials' => 'Érvénytelen felhasználónév vagy jelszó',
			'addServer.authResponseNotJson' => 'A hitelesítési válasz nem érvényes JSON',
			'addServer.authResponseIncomplete' => 'A szerver bejelentkezési válasza hiányos volt',
			'addServer.quickConnectRejected' => 'A szerver elutasította a Quick Connect-kérést',
			'addServer.quickConnectNotJson' => 'A Quick Connect válasza nem érvényes JSON',
			'addServer.quickConnectMissingFields' => 'A Quick Connect válaszából hiányzik a kód vagy a titkos kulcs',
			'addServer.quickConnectPollRejected' => 'A szerver elutasította a Quick Connect lekérdezését',
			'addServer.serverTimedOut' => 'A szerver nem válaszolt időben',
			'addServer.responseNotJson' => 'A szerver válasza nem érvényes JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'A válaszból hiányzik az azonosító vagy a szerver neve – ez valóban ${product}-szerver?',
			'addServer.probeFailed' => ({required Object error}) => 'Nem sikerült elérni a szervert: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Adj meg legalább egy ${product}-szerverhez tartozó URL-t',
			'addServer.noReachableServer' => ({required Object product}) => 'Nem található elérhető ${product}-szerver',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Ezek az URL-ek különböző ${product}-szerverekre mutatnak',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Ez az URL nem egyezik a(z) ${product}-szerverrel',
			'addServer.redirectUnsupported' => 'A szerver nem támogatott URL-re irányított át',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'A szerver egy másik gazdagépre irányított át. Add meg közvetlenül a végleges ${product} URL-t.',
			'addServer.redirectInsecure' => 'A szerver HTTPS-ről nem biztonságos URL-re irányított át',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'A szerver nem támogatott URL-re irányított át. Add meg közvetlenül a végleges ${product} URL-t.',
			'addServer.directPlexServerUrl' => 'Plex-kiszolgáló URL-címe',
			'addServer.directPlexServerUrlHelper' => 'Írja be a helyi IP-t és portot a Plex Media Server-ról.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (választható)',
			'addServer.plexTokenHelper' => 'Hagyja szabadon, ha az auth nélküli hozzáférés engedélyezett ezen a szerveren.',
			'addServer.plexTokenRequired' => 'Kérjük, adja meg a Plex token (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (közvetlen / helyi)',
			'addServer.connectDirectPlexCardSubtitle' => 'Csatlakozzon közvetlenül a helyi IP vagy URL segítségével plex.tv fiók nélkül.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Kapcsolat közvetlenül a helyi IP vagy URL használatával. Kapcsolatok a ${name}.',
			'addServer.insecureTitle' => 'titkosítatlan kapcsolat',
			'addServer.insecureDescription' => ({required Object url}) => 'A(z) ${url} HTTP-t használ. A hálózaton mások elolvashatják vagy módosíthatják a jelszavát, a tokenjeit és a médiatartalmait. Ha elérhető, használjon HTTPS-t. Csak akkor folytassa, ha megbízik ebben a hálózatban és elfogadja a kockázatot.',
			'addServer.allowHttp' => 'HTTP engedélyezése',
			'addServer.httpsRequired' => 'Használja a HTTPS vagy kifejezetten engedélyezi a titkosított kapcsolatot.',
			'cast.chooseDevice' => 'A készülékre kattintva',
			'cast.searching' => 'A Cast eszközök keresése...',
			'cast.connectedTo' => ({required Object device}) => 'Kapcsolódó oldalak ${device}',
			'cast.device' => 'Cast eszköz',
			'cast.readyToCast' => 'Kész a kiadásra',
			'cast.subtitle' => 'Feliratok',
			'cast.serverNotAvailable' => 'A média szerver nem elérhető.',
			'cast.stopCasting' => 'Csatlakozás megáll',
			'cast.castToDevice' => 'A készülékre vágás',
			'cast.noEpisodeAvailable' => 'Nincs epizód, amit el lehet dobni.',
			'cast.startFailed' => 'Nem tudok elkezdeni a szétválasztást. ellenőrizze a szervert, és próbáljon újra.',
			'automation.noActivePlayback' => 'Nincs aktív videó ülés ellenőrzésére.',
			'notifications.newEpisodeTitle' => 'Új epizód',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Próbáld ki minden funkciót ingyen 7 napig',
			'appAccess.description' => 'Kezdje a hét napos próbát minden PlezyNG funkcióhoz való teljes hozzáféréssel. A próbában nincs díj és nincs előfizetés. A próbát követően egy élethosszig tartó vásárlás az üzlet árán PlezyNG az élethosszú zárat nyit.',
			'appAccess.trialEndedDescription' => 'A PlezyNG minden funkciót letiltja az életre egy vásárlással az üzlet árán.',
			'appAccess.startTrial' => 'Kezdje a 7 napos ingyenes próbát',
			'appAccess.trialActive' => 'A 7 napos teljes funkciót tesztelője aktív.',
			'appAccess.trialEnded' => 'A 7 napos bírósági eljárás befejeződött',
			'appAccess.trialStartFailed' => 'Nem tudtam menteni a tesztet a készülékre. kérjük, próbáljon újra.',
			'appAccess.lifetimeTitle' => 'PlezyNG életre szóló zárolás',
			'appAccess.lifetimeBody' => 'Köszönöm! az egész életen át tartó hozzáférést kap minden PlezyNG funkcióhoz.',
			'appAccess.manageTitle' => 'PlezyNG Élethosszú hozzáférés',
			'appAccess.manageDescription' => 'Próbáld ki minden funkciót ingyen 7 napig, majd letölti az egész életet egy fizetéssel az áruház ára.',
			'appAccess.buy' => ({required Object price}) => 'Minden funkció letiltása a ${price}',
			'appAccess.loadingPrice' => 'A szállítási árak...',
			'appAccess.retryPrice' => 'Visszaállítási ár keresés',
			'appAccess.restore' => 'Életmód vásárlás',
			'appAccess.pending' => 'A vásárlás fizetést vagy jóváhagyást vár. Az élethosszig tartó hozzáférés a bolt befejezését követően zárul.',
			'appAccess.storeUnavailable' => 'A vásárlás nem elérhető. Ellenőrizze, hogy Ön regisztrált a boltban, és a vásárlás engedélyezett ezen a készüléken.',
			'appAccess.productNotFound' => 'A PlezyNG élethosszig tartó zárolás még nem elérhető ebben a boltban.',
			'appAccess.productQueryFailed' => 'Nem tudtam feltölteni a bolt árat. Ellenőrizze a kapcsolatot, és próbáljon meg újra.',
			'appAccess.purchaseFailed' => 'A vásárlás nem ment át. próbáljon újra.',
			'appAccess.restoreFailed' => 'Nem tudtam eljutni a boltba, hogy visszaállítsam a vásárlást. próbáljon újra.',
			'appAccess.nothingToRestore' => 'A PlezyNG életévét megvásárlás találta ebben a boltban.',
			'detail.endsAt' => ({required Object time}) => 'Vége: ${time}',
			'watchLink.serverUnavailable' => 'Nem tudtam elérni a Plex szervert erre a linkre.',
			'watchLink.notFound' => 'Nem találtam ezt a show-t vagy filmet a Plex szervereken.',
			'watchLink.ambiguous' => 'Ez a link megfelel az elemeknek több szerveren.A linkhez adjon hozzá egy szervert.',
			'watchLink.plexOnly' => 'A jelenleg csak Plex szervereket támogat.',
			'watchLink.unsupportedItem' => 'A néző linkek csak egy show-t vagy filmet nyithatnak meg.',
			'watchLink.menuItem' => 'Lásd a linket',
			'watchLink.dialogTitle' => 'Lásd linket',
			'watchLink.dialogShowHint' => 'A link megnyitása a következő epizódot játssza. Add &mode=shuffle a végén, hogy játsszon a show on shuffle.',
			'watchLink.dialogMovieHint' => 'A link megnyitása a filmet játssza.',
			'watchLink.copy' => 'másolás',
			'watchLink.copied' => 'Link másolat',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home újra az eredeti Plezy hős elrendezésre',
			'homeLayout.resetHeroTitle' => 'A hős elrendezésének helyreállítása a Plezy raktárba?',
			'homeLayout.resetHeroBody' => 'A hős állítása minden sorban törli, és visszahozza az egyetlen forgó banneret a ház tetején, mint az előző sorokban.',
			'homeLayout.removeRowTitle' => 'Helyreállítsa a homlokzatot?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} törlésre kerül. ez nem lehet megszüntetni.',
			'homeLayout.sync' => 'Szinkronizálás',
			'homeLayout.syncAccountTitle' => 'Szinkronizálja a Plex fiókkal való elrendezést',
			'homeLayout.syncAccountOn' => 'A: Ez a készülék megosztja a sorrendet, sorokat, Hero és Auto-slide a többi készülékkel.',
			'homeLayout.syncAccountOff' => 'Kattintson: Ez a készülék saját elrendezését tartja.',
			'homeLayout.syncNow' => 'Szinkronizálás most',
			'homeLayout.plexHomeManager' => 'Plex Házigazgató',
			'homeLayout.managePlexRows' => 'Plex sorok kezelése Plezy sorban',
			'homeLayout.managePlexRowsDescription' => 'Nyitva a házilag kiválasztott sorok megszervezéséhez',
			'homeLayout.organizeHomeRows' => 'Szervezze a házirendeket',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} sorok: mozog, Hős, Auto-slide, eltávolítása',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Szervezés ${library} sorok',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Folytatás Nézd + ${n} sorok: mozog, Könyvtár, Ház, Hős, Autó-szalag',
			'homeLayout.renderAsHero' => 'Hősként válogatott kártyát',
			'homeLayout.heroOnlySingleCollection' => 'Csak akkor érhető el, ha ez a sor egy gyűjtemény valós címére oldódik meg',
			'homeLayout.hero' => 'Hősök',
			'homeLayout.autoSlide' => 'Autó Slide',
			'homeLayout.autoSlideDescription' => 'A bejutások (PC) és a d-pad (TV) mindig működnek és újraindítják a időzítőt.',
			'homeLayout.autoSlideEditDescription' => 'A csúszás is önmagában néhány másodpercenként. kikapcsolva: csak akkor mozog, ha egy lövedéket (PC) kattintson vagy balra/jobbra nyomja a távoli (TV) oldalon.',
			'homeLayout.enableHeroFirst' => 'Először a hős',
			'homeLayout.showOnHome' => 'Show on Home képernyőn',
			'homeLayout.home' => 'Kezdőlap',
			'homeLayout.removeFromHome' => 'eltávolítása otthonról',
			'homeLayout.selectRowsFirst' => 'Válassza ki az első helyen található házsorozatokat.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex irányított sorok',
			'homeLayout.continueWatching' => 'Folytatás',
			'homeLayout.continueWatchingLibraryDescription' => 'A könyvtár saját újjáépítésének sorrendje',
			'homeLayout.continueWatchingHomeDescription' => 'A folyamatos folyamatok újbóli sorát mutatják be otthon',
			'homeLayout.nextUpHomeDescription' => 'A következő nem figyelt epizód sorozatot külön-külön mutatott a Home',
			'homeLayout.library' => 'Könyvtár',
			'homeLayout.showInRecommended' => 'A könyvtárban ajánlott',
			'homeLayout.customPlexRow' => 'Személyes Plex sor',
			'homeLayout.heroNeedsLibrary' => 'Kövesse a könyvtárat először – Hero kell valahol megmutatni',
			'homeLayout.heroNeedsSurface' => 'Kezdőlap / Könyvtár / Kezdőlapi könyvtár / A hősnek valahol kell megmutatnia',
			'homeLayout.removeHub' => 'Hulladék Hub',
			'homeLayout.noPlexRows' => 'A Plex-es irányított sorok visszatértek erre a könyvtárra.',
			'homeLayout.openDetails' => 'Nyitott részletek',
			'homeLayout.heroCards' => 'Hős kártyák',
			'homeLayout.tapHeroCard' => 'Hős kártyát kap',
			'homeLayout.tvPlayFocus' => 'Televízió távoli: hangsúlyt a Play gomb',
			'homeLayout.tvPlayFocusDescription' => 'A D-pad leáll a Play gombra, mielőtt a következő sorba halad.',
			'homeLayout.tvWrap' => 'Televízió távoli: loop hős kártyák',
			'homeLayout.tvWrapDescription' => 'Az utolsó kártyán az első kártyára megy vissza. az utolsó kártyára megáll. az első kártán a bal mindig az oldalbarra megy.',
			'homeLayout.castOnHero' => 'Banner a hősökkel',
			'homeLayout.castOnHeroDescription' => 'A címet a hős banner alján mutatja be, és csak a címet és a összefoglalót tartja.',
			'homeLayout.customRows' => 'Custom sorok',
			'homeLayout.loading' => 'Home Layout Házas felbontás...',
			'homeLayout.noCustomRows' => 'Még nincs szokásos sor',
			'homeLayout.addRowHint' => 'Használja a Hozzáadása Home sor, hogy hozzon létre egy.',
			'homeLayout.addHomeRow' => 'Hozzáadása Home Rue',
			'homeLayout.addHomeRowDescription' => 'Válasszon egy kategóriát; az új sor automatikusan hozzáadódik a Szervezőhez',
			'homeLayout.removeRow' => 'eltávolítása sor',
			'homeLayout.recentlyAdded' => 'Legutóbb hozzáadva',
			'homeLayout.recentlyReleased' => 'Nemrégiben kiadott',
			'homeLayout.movieCollections' => 'Filmgyűjtemények',
			'homeLayout.showCollections' => 'Kollekciók bemutatása',
			'homeLayout.rowTitle' => 'Row cím',
			'homeLayout.content' => 'Tartalom',
			'homeLayout.showThisRowIn' => 'Ez a sor a következőben jelenik meg:',
			'homeLayout.libraryRecommended' => 'Könyvtár ajánlott',
			'homeLayout.heroCard' => 'Hős kártyák',
			'homeLayout.heroCardDescription' => 'A teljes körű forgatási kártyát mutatja be a poszter-szekrény helyett.',
			'homeLayout.heroUnavailableDescription' => 'Csak akkor áll rendelkezésre, ha ez a sor egy gyűjtemény tényleges címére oldódik meg - több mint egy gyűjtés kiválasztásával egyetlen cím sem fordulhat át.',
			'homeLayout.librariesSelection' => 'Könyvtárak (az összes ellenőrzés nélküli könyvtárat minden könyvtárhoz bele kell foglalni)',
			'homeLayout.librariesMergedDescription' => 'Minden könyvtár itt ellenőrzött össze van keverve ebben az egyik sorban.',
			'homeLayout.movieCollectionsSelection' => 'Filmgyűjtemények (minden ellenőrzés nélküli lemez minden kiválasztott könyvtárban)',
			'homeLayout.showCollectionsSelection' => 'Megjelenítés gyűjtemények (töltsön ki minden nem ellenőrzött minden kiválasztott könyvtár)',
			'homeLayout.collectionRowsDescription' => 'Ha pontosan egy gyűjtemény mérkőzik, a címek közvetlenül a sorban jelennek meg. Ha több mint egy mérkőzik az egyes gyűjtemények egy plakátként jelennek meg - kattintson rá, hogy megnyissa azt a gyűjteményt.',
			'homeLayout.allCollections' => 'Összes gyűjtemény',
			'homeLayout.noRowsHere' => 'Még nincs sor itt.',
			'homeLayout.hideWatchedRows' => 'Elrejtett tárgyak sorban',
			'homeLayout.hideWatchedRowsDescription' => 'Teljesen megtekintett címek elhagyják a Ház és a könyvtár Ajánlott sorok.',
			'homeLayout.untitledCollection' => 'címtelen gyűjtemény',
			'homeLayout.moveRowHint' => 'Felszállás: lépés sorban · Válassza ki: dobja le itt · Vissza: törli',
			'homeLayout.organizeRowsHint' => 'Válasszon egy sorban (vagy tartsa Válassza ki): mozogjon · Balra/jobbra: sorban lehetőségek · Vissza: véget ért',
			'homeLayout.layoutNavDescription' => 'Válasszon sorokat, könyvtárakat és gyűjteménykategóriákat',
			'homeLayout.editHomeRow' => 'Edit Home Rózsaszín',
			'homeLayout.resetHeroButton' => 'A Hero layout visszaállítása a stockhoz Plezy',
			'homeLayout.reorderingUnlocked' => 'Újra elzárva',
			'homeLayout.reorderingLocked' => 'Újra zárva',
			'homeLayout.rowsCanBeDragged' => 'A szálak húzhatók - nyomja meg a zárat, hogy megakadályozzák ezt',
			'homeLayout.tapLockToDrag' => 'Nyomja meg a zárat a sorok húzásához',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Személyes adatok: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Elrejtés',
			'homeLayout.remove' => 'Eltávolítás',
			'homeLayout.libraryResumeRow' => 'A könyvtár újbóli sorrendje',
			'homeLayout.pressAgainToDelete' => 'Nyomja meg újra a törléshez',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'A',
			'homeLayout.resetHeroButtonDescription' => 'A hős állításait minden sorban törli le, és visszahozza az egyetlen forgó banneret a tetején, mint az előző sorban.',
			'homeLayout.tapHeroCardDescription' => 'Válassza ki, hogy egy Hero kártyát nyomtatva vagy kiválasztva megkezdődik a lejátszás, vagy megnyitja annak részleteit.',
			'homeLayout.heroTapPlayDescription' => 'Indítsa el a kiválasztott elemet azonnal.',
			'homeLayout.heroTapDetailsDescription' => 'Nyissa meg a kiválasztott elem részleteit, mielőtt egy akciót választ.',
			'platform.localNetworkPermission' => 'A PlezyNG a helyi hálózaton keresztül csatlakozik a média szerverekhez és a lejátszó eszközökhöz.',
			'platform.locationPermission' => 'A PlezyNG akkor használja a helyadatokhoz való hozzáférést, ha az iOS ezt megköveteli a helyi hálózat felismeréséhez és a médiaszerverekhez való csatlakozáshoz.',
			'platform.photoLibraryPermission' => 'Válassz képeket a fotókönyvtáradból a médiatartalmak borítóképeihez és illusztrációihoz.',
			'platform.cameraPermission' => 'QR kódok szkennelése a Companion Remote párosításához.',
			'universalMedia.title' => 'Nyílt média',
			'universalMedia.shortcutHelp' => 'Játssz egy linket, lejátszási listát vagy fájlt erre az ülésre.',
			'universalMedia.intro' => 'Nyissa meg a linket, a lejátszási listát vagy a fájlt.A Playback használja a PlezyNG szabványos lejátszóját és nem ad hozzá történetet a könyvtárához.',
			'universalMedia.openWhat' => 'Mit szeretne megnyitni?',
			'universalMedia.stream' => 'Stream cím',
			'universalMedia.playlist' => 'játéklisták',
			'universalMedia.files' => 'készülék fájl',
			'universalMedia.favorites' => 'Megtakarított stream kedvencek',
			'universalMedia.address' => 'média cím',
			'universalMedia.addressHelp' => 'Az elismert hitelesítési vagy aláírási paraméterekkel rendelkező URL-k csak ebben az ülésen használhatók, és nem menthetők kedvencként.',
			'universalMedia.displayName' => 'A kijelző neve (opcionális)',
			'universalMedia.displayNameHelp' => 'Válasszon egy rövid nevét a játékos és a rendszer média vezérlők.',
			'universalMedia.allowHttp' => 'A titkosítás nélküli HTTP-kapcsolat engedélyezése',
			'universalMedia.allowHttpHelp' => 'A HTTP nem titkosítja a kapcsolatot. csak megbízható hálózaton engedélyezheti. ha lehetséges, használja a HTTPS-t.',
			'universalMedia.advancedProtocols' => 'Csak MPV: adjon meg egy RTSP, RTMP/RTMPS, UDP vagy RTP címet.',
			'universalMedia.liveStream' => 'Élőként kezeljük',
			'universalMedia.liveStreamHelp' => 'Használja ezt az élő videó vagy rádió. Az alkalmazás elrejti az időzónát, a skip gombokat és a go-to-time opciót.',
			'universalMedia.privateSession' => 'Csak ez a lejátszás használja az címet. mentse meg a jogosult stream kedvenc, hogy ezt tartsa ebben a profilban.',
			'universalMedia.saveFavorite' => 'Megmentse kedvencét',
			'universalMedia.playNow' => 'Játssz most',
			'universalMedia.favoriteSaved' => 'Stream kedvenc mentett erre a profilra',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: 'A ${count} nem támogatott vagy biztonságos lejátszási lista bejárata.', other: 'A ${count} nem támogatott vagy biztonságos lejátszási listájának bejegyzései.', ), 
			'universalMedia.playlistAddress' => 'Playlist címek',
			'universalMedia.playlistAddressHelp' => 'Nyissa meg a M3U, M3u8 vagy PLS lejátszási listát egy webcímről. közvetlen áramlás linkek nem menthetik meg a lejátszó listát.',
			'universalMedia.choosePlaylist' => 'Válassza ki a Playlist fájlt',
			'universalMedia.openPlaylist' => 'Nyílt Playlist',
			'universalMedia.playlistFormatsHelp' => 'A lejátszó listája legfeljebb 1000 elemet és 2 MB-ot tartalmazhat. a HLS nyílt áramlatként jelenik meg, így a játékos kiválaszthatja a minőséget.',
			'universalMedia.saveQueuePlaylist' => 'Sor mentése lejátszási listaként',
			'universalMedia.queuePlaylistSaved' => 'A lejátszási lista a médiafájlok mellé lett mentve.',
			'universalMedia.queuePlaylistUnavailable' => 'Ez a sor nem menthető újra felhasználható helyi lejátszási listaként.',
			'universalMedia.queuePlaylistFolderRequired' => 'A sor fájljaival azonos mappát válassz mentési helyként.',
			'universalMedia.noFavorites' => 'Nincs mentett stream kedvencek még. Favoritek maradnak ebben a profilban.',
			'universalMedia.removeFavorite' => 'Távolítsa el a kedvenc stream',
			'universalMedia.filesHelp' => 'Válassza ki az audio, a videó vagy az ISO fájlokat egy ideiglenes tartományhoz. A fájlok és URL-ek nem kerülnek hozzáadásra a könyvtár történetéhez.',
			'universalMedia.chooseFiles' => 'Válasszon fájlokat',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '1 kiválasztott fájl', other: '${count} kiválasztott fájlok', ), 
			'universalMedia.wifiTransfer' => 'Fájlok küldése Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Támogatott fájlok átadása egy böngészőről ugyanazon megbízható hálózaton.',
			'universalMedia.wifiTransferIntro' => 'Nyissa meg ezt a címet egy böngészőben egy másik eszközön. Válassza ki a fájlokat, hogy hozzáadják őket a készülék Fájlok és könyvek könyvtárába.',
			'universalMedia.wifiTransferPrivacy' => 'Ez a készülék fogadja a fájlokat a helyi hálózaton keresztül. Bárki, aki ismeri ezt az címet, elküldheti azokat addig, amíg nem hagyja abba az átutalást vagy a cím 15 perc elteltével megszűnik. Maximum: 100 fájlt, 4 GiB fájlokonként, 10 GiB összesen.',
			'universalMedia.wifiTransferStarting' => 'Személyre szabott, korlátozott átutalás...',
			'universalMedia.wifiTransferUnavailable' => 'Nem tudja elkezdeni az átutalást. ellenőrizze a helyi hálózati hozzáférést, és próbálja meg újra.',
			'universalMedia.openThisAddress' => 'Nyissa meg az egyik címet a küldő eszközön',
			'universalMedia.copyAddress' => 'átviteli cím másolása',
			'universalMedia.addressCopied' => 'átutalási cím másolva',
			'universalMedia.transferExpires' => ({required Object time}) => 'Ez a cím az ${time}-ben lejár.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${count} fájl kapott', other: '${count} fájlok kaptak', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Megérkezett ${size}',
			'universalMedia.stopTransfer' => 'Megállapodás átadásáról és cím megsemmisítéséről',
			'universalMedia.startTransfer' => 'Kezdődik a transzfer',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi átutalás',
			'universalMedia.wifiBrowserTitle' => 'Fájlok küldése PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Válassza ki az audio, videó, ebook vagy képregény fájlokat küldeni. A fájlok tárolódnak a készülék Fájlok és könyvek könyvtárában. Maximum: 100 fájlt, 4 GiB fájlonként, 10 GiB összesen.',
			'universalMedia.uploadFilesLabel' => 'Fájlok küldeni',
			'universalMedia.uploadSelected' => 'A kiválasztott fájlok feltöltése',
			'universalMedia.uploadSelectFirst' => 'Válasszon egy vagy több fájlt először.',
			'universalMedia.uploading' => 'küldés',
			'universalMedia.uploadComplete' => 'Fájl hozzáadva PlezyNG.',
			'universalMedia.uploadFailed' => 'A fájl nem lehet hozzáadni. tartsa nyitva ezt az oldalt, és próbálja meg újra.',
			'universalMedia.liveCue' => 'Élő',
			'universalMedia.liveSession' => 'Élő Stream',
			'universalMedia.liveCueHelp' => 'Az élő videó vagy rádió esetében az alkalmazás elrejti az időzónát és a gombokat. nem mentheti meg a címet vagy a történetet.',
			'universalMedia.sessionOnly' => 'Ez a playback csak szezonális',
			'universalMedia.sessionOnlyHelp' => 'A Playback soha nem mentse meg a haladást vagy a történelmet. mentse az áramlat kedvencnek, hogy ebben a profilban maradjon, ha jogosult.',
			'universalMedia.pictureAdjustments' => 'Kép módosítása',
			'universalMedia.pictureHelp' => 'Ezek a képváltozások csak ezt a lejátszást érintik. újra beállítják, amikor a playback véget ér.',
			'universalMedia.resetPicture' => 'Visszaállítási kép',
			'universalMedia.brightness' => 'fényesség',
			'universalMedia.contrast' => 'kontraszt',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'szaturáció',
			'universalMedia.view360' => 'A 360 fokos videó megjelenítése',
			'universalMedia.view360Help' => 'Használja ezt az egyenes 360°-os videóhoz. MPV-nek szüksége van a FFmpeg v360 szűrőjére erre a nézőpontra.',
			'universalMedia.view360Unavailable' => 'Ez az MPV szerkezet nem alkalmazhatja a 360 fokos szűrőt.',
			'universalMedia.view360Yaw' => 'Horizontális kilátás',
			'universalMedia.view360Pitch' => 'Vertikális kilátás',
			'universalMedia.view360FieldOfView' => 'A látványterület',
			'universalMedia.recordStream' => 'Live stream rekordok',
			'universalMedia.stopRecording' => 'Állítsa meg és mentse a felvételt',
			'universalMedia.recordingStarted' => 'A lejátszás megszűnik, és megmenti a felvételt.',
			'universalMedia.recordingSaved' => 'A felvétel befejeződött és mentett.',
			'universalMedia.recordingActive' => 'Ez a készülék.Leaving playback megáll és mentse meg.',
			'universalMedia.recordingFormatHelp' => 'Videó esetén válassza ki a MKV vagy MPEG-TS. A hang esetében válasszon MKA vagy MKV.',
			'universalMedia.replaceRecordingTitle' => 'Ezt a felvételt helyettesítjük?',
			'universalMedia.replaceRecordingHelp' => 'A PlezyNG visszaállítja a meglévő fájlt a rögzítés során. ha nem tudja menteni az új rögzítést, a Plezy NG visszaállíthatja a biztonsági mentést.',
			'universalMedia.replaceRecording' => 'Fájl cseréje',
			'universalMedia.discHelp' => 'Nyissa meg a lemezt ebben a számítógép optikai lemezében.Az ISO-képet is megnyithatja a Device fájlokból.',
			'universalMedia.discs' => 'Optikai lemez',
			'universalMedia.editionOrTitle' => 'Kiadás vagy lemezcím',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'Audió CD',
			'universalMedia.discAvailability' => 'A lemezlejátszásnak kompatibilis MPV szerkezetre, támogatott lemezre és operációs rendszer engedélyére van szüksége.',
			'universalMedia.converterTitle' => 'A helyi média fájl átalakítása',
			'universalMedia.converterHelp' => 'Konvertáljon egy helyi fájlt, vagy helyreállítsa a FFmpegA',
			'universalMedia.converterIntro' => 'Konvertáljon egy helyi audio vagy videó fájlt olyan formátumra, amely több eszközön működik.',
			'universalMedia.converterPrivacy' => 'FFmpeg kell telepíteni ezen a számítógépen. konverzió csak helyi fájlokat olvasható. nem tölt le áramlatok vagy eltávolítja DRM-t.',
			'universalMedia.converterChooseInput' => 'Válasszon egy helyi média fájlt',
			'universalMedia.converterFormat' => 'kimeneti formátum',
			'universalMedia.converterMp4' => 'MP4 · H.264 és AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 hangszóró',
			'universalMedia.allowFtp' => 'FTP engedélyezése',
			'universalMedia.allowFtpHelp' => 'Az FTP titkosítás nélküli médiát küld, csak megbízható hálózatokon használja.',
			'universalMedia.converterSaveAs' => 'Az átalakított média mentése',
			'universalMedia.converterExtensionMismatch' => 'Válasszon egy fájlnevet a kiválasztott kimeneti kiterjesztéssel.',
			'universalMedia.converterUnsupportedInput' => 'Válasszon egy audio vagy videó fájlt.',
			'universalMedia.converterLocalOnly' => 'A kiválasztott fájl nem áll rendelkezésre helyi eszközútként.',
			'universalMedia.converterReplaceTitle' => 'A fájl helyettesítése?',
			'universalMedia.converterReplaceHelp' => 'A PlezyNG visszaállítja a meglévő fájlt, amíg az átalakított másolat menthető.',
			'universalMedia.converterStarting' => 'Megkezdődött az FFmpeg...',
			'universalMedia.converterProgress' => 'Ezzel a számítógéppel átalakítva...',
			'universalMedia.converterComplete' => 'Az új fájl készen áll.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg hiányzik, vagy nem támogatja ezt a formátumot.',
			'universalMedia.converterFailed' => 'Ellenőrizze, hogy a forráskód fájl olvasható és a rendeltetési hely elegendő szabad hely.',
			'universalMedia.converterCancelled' => 'Az átalakítás törlésre került, a hiányos eredményt eltávolították.',
			'universalMedia.converterDesktopOnly' => 'Helyi átalakítás elérhető asztali számítógépeken FFmpeg telepítve.',
			'universalMedia.converterStart' => 'fájl átalakítása',
			'universalMedia.mediaToolsTitle' => 'Média eszközök',
			'universalMedia.mediaToolsShortcut' => 'Foglaljon vagy ossza meg a média, adjon hozzá keresési kiterjesztéseket, vagy használja a parancsvonalat.',
			'universalMedia.mediaToolsIntro' => 'Válasszon egy fókuszált eszközt. Foglaljon és áramlást használjon FFmpeg telepítve ezen a asztalon. kiterjesztések és CLI parancsok használja a korlátozott HTTPS kérések és a meglévő Open media áramlást.',
			'universalMedia.mediaToolsAccessibility' => 'Az eszközválasztás és a vezérlések a touch, a mutató, a billentyűzet és a D-pad fókuszával működnek. A felvételi, megosztási és keresési állapot változásait hirdetik.',
			'universalMedia.mediaTool' => 'média eszközök',
			'universalMedia.captureIntro' => 'A képernyőt vagy a fényképezőgépet a MP4 fájlra rögzíti ezen a számítógépen. a FFmpeg telepítve kell lennie, és a H.264 kódot kell tartalmazni.',
			'universalMedia.captureNoDevices' => 'Nem találták meg a képernyőt vagy a fényképezőgépet. ellenőrizze a FFmpeg felvételi támogatást és az operációs rendszer adatvédelmi engedélyeket.',
			'universalMedia.captureSource' => 'képernyő vagy kamera',
			'universalMedia.captureScreen' => 'képernyő',
			'universalMedia.captureAudioSource' => 'Audio beviteli lehetőség (opcionális)',
			'universalMedia.captureAudioHelp' => 'Hozzon hozzá hangot egy mikrofonból vagy a rendelkezésre álló bevitelt. A készülék kiválasztása a FFmpeg és a rendszer engedélyezéseitől függ.',
			'universalMedia.captureAudioNone' => 'Nincs audio',
			'universalMedia.captureDefaultAudio' => 'Audio beviteli előzetes',
			'universalMedia.captureWaylandHelp' => 'Wayland korlátozza ezt a XWayland fogást a X display-re. A XWayland-en kívüli Windows nem jelenik meg.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.captureFrameRate' => 'Részletesebben Regisztrációs ráta',
			'universalMedia.capturePrivacy' => 'A rögzítés csak az Ön által kiválasztott fájlra menthető. a mikrofon rögzítése opcionális. a PlezyNG nem tölti fel a rögzítést.',
			'universalMedia.captureSaveAs' => 'A képernyő felvétele, mint',
			'universalMedia.captureExtensionMismatch' => 'Válassza ki a .mp4-ben végződő filenámot.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg vagy a H.264 videó kódoló nem érhető el. Telepítse a támogatott FFmpeg építkezést, majd próbáljon újra.',
			'universalMedia.captureFailed' => 'A felvétel nem menthető meg. Ellenőrizze a készülék engedélyét, a rendelkezésre álló tárolást és a FFmpeg támogatást.',
			'universalMedia.captureSaved' => 'A képernyő felvétele mentett.',
			'universalMedia.captureElapsedLabel' => 'Rekordidő',
			'universalMedia.captureStart' => 'Kezdődik a felvétel',
			'universalMedia.capturePreview' => 'Előnézet a lejátszóban',
			'universalMedia.capturePreviewHelp' => 'A kiválasztott forrás előnézete a szokásos lejátszóban. Csak erre a munkamenetre szól, és nem ment felvételt. Az eszköztámogatás és az engedélyek az MPV-től és az operációs rendszertől függenek. Az előnézet csak videót használ; a mentett felvételekhez opcionális hang is tartozhat.',
			'universalMedia.capturePreviewActive' => 'Élő előnézet · nincs felvétel',
			'universalMedia.captureStop' => 'Állj meg és mentse meg',
			'universalMedia.captureMode' => 'fogság',
			'universalMedia.shareMode' => 'megosztás',
			'universalMedia.shareIntro' => 'Küldje el a helyi médiafájlt egy másik eszközre a magánhálózaton. PlezyNG létrehoz egy ideiglenes HLS áramlást.',
			'universalMedia.sharePrivacy' => 'Bárki a helyi hálózaton, aki a privát linket kapja meg, megtekintheti, miközben aktív. A link 60 perc után megszűnik.',
			'universalMedia.shareChooseFile' => 'Válassza ki a média fájlt',
			'universalMedia.shareChooseHelp' => 'Válasszon egy helyi audio vagy videó fájlt. A fájl ezen a számítógépen marad.',
			'universalMedia.shareFfmpegMissing' => 'A FFmpeg vagy a H.264/AAC kódolók nem érhetők el. A FFmpeg telepítése a H.264 és a AAC kódolási támogatással.',
			'universalMedia.shareFailed' => 'Az áramlat nem indult vagy váratlanul megállt. ellenőrizze a FFmpeg és a hálózati hozzáférést.',
			'universalMedia.shareActive' => 'Az áramlat készen áll a magánhálózaton.',
			'universalMedia.shareEnded' => 'A média elérte a véget, és már nem oszlik meg.',
			'universalMedia.shareStopped' => 'A megosztás megszűnt. az ideiglenes link már nem érvényes.',
			'universalMedia.shareUrlCopied' => 'Az áramszolgáltatás címét másolták.',
			'universalMedia.shareOpenUrl' => 'Nyissa meg ezt a címet egy játékosban a másik eszközön',
			'universalMedia.shareQrLabel' => 'QR kód az ideiglenes áramlat címéhez',
			'universalMedia.shareQrHelp' => 'Scan egy kompatibilis lejátszóval, amely ugyanazon magánhálózathoz van csatlakoztatva.',
			'universalMedia.shareHttpHint' => 'Ez az áramlás titkosított HTTP. A PlezyNG, engedélyezze HTTP, mielőtt megnyitja.',
			'universalMedia.shareCopyUrl' => 'Stream cím másolása',
			'universalMedia.shareExpiresLabel' => 'A link lejár',
			'universalMedia.shareStarting' => 'Az áramlás előkészítése...',
			'universalMedia.shareStart' => 'Kezdődik a megosztás',
			'universalMedia.shareStop' => 'Megáll a megosztás',
			'universalMedia.extensionsMode' => 'Kiterjesztések és CLI',
			'universalMedia.extensionsIntro' => 'Hozzon hozzá egy adat-csak keresési kiterjesztést, hogy megtalálja a média. Válasszon egy eredményt, hogy töltse le a jól ismert Open media űrlap.',
			'universalMedia.extensionsPrivacy' => 'Egy manifeszt meghatározhatja a HTTPS keresési végpontot és a térkép válasz mezőit. Nem fut kódot, kérési címeket adhat hozzá, olvassa el a fájlokat, vagy indítsa el a shell parancsokat.',
			'universalMedia.extensionImport' => 'Meghosszabbítás manifeszt',
			'universalMedia.extensionEmpty' => 'Nincs keresési szolgáltatás még. Válasszon egy megbízható manifeszt JSON fájlt, hogy hozzáadja az egyiket.',
			'universalMedia.extensionChoose' => 'Keresési szolgáltatás',
			'universalMedia.extensionSearchConsent' => 'Minden keresés elküldi a szavakat erre a HTTPS szolgáltatásra.Az eredmények csak az egyik kiválasztása után nyílik meg.',
			'universalMedia.extensionSearchLabel' => 'Keresési média',
			'universalMedia.extensionSearch' => 'Keresés',
			'universalMedia.extensionSearching' => 'Keresés...',
			'universalMedia.extensionNoResults' => 'Nincs biztonságos média eredmények visszatértek. próbáljon meg egy újabb keresést.',
			'universalMedia.extensionInstallTitle' => 'Adja meg ezt a keresési szolgáltatást?',
			'universalMedia.extensionReplaceTitle' => 'Aktualizálja ezt a keresési szolgáltatást?',
			'universalMedia.extensionService' => 'Szolgáltatás',
			'universalMedia.extensionEndpoint' => 'HTTPS végpont',
			'universalMedia.extensionConsent' => 'A keresési szöveget küldik erre a szolgáltatásra. a manifeszt nem tartalmaz végrehajtható kódot. Csak akkor folytatja, ha ezt a végpontot bízik.',
			'universalMedia.extensionInstall' => 'Add szolgáltatás',
			'universalMedia.extensionReplace' => 'frissítés szolgáltatás',
			'universalMedia.extensionRemoveTitle' => 'Távolítsa el ezt a keresési szolgáltatást?',
			'universalMedia.extensionRemoveHelp' => 'Ez eltávolítja a szolgáltatást ebből a profilból. a PlezyNG nem lép kapcsolatba a végpontjával.',
			'universalMedia.extensionRemove' => 'eltávolítása szolgáltatás',
			'universalMedia.extensionInvalidManifest' => 'Ez a fájl nem támogatott kiterjesztés manifesztus. lásd a Open media útmutatót a formátumra.',
			'universalMedia.extensionSaveFailed' => 'A kiterjesztés nem menthető meg az aktív profilra.',
			'universalMedia.extensionSearchFailed' => 'A keresési szolgáltatás nem ad vissza érvényes választ. Ellenőrizze a végpontot, és próbálja meg újra.',
			'universalMedia.cliTitle' => 'parancsvonal',
			'universalMedia.cliHelp' => 'Használja a plezyctl útmutatót egy manifeszt validálására vagy ugyanazon kiterjesztés keresésére. Minden keresés előtt felülvizsgálja a HTTPS szolgáltatást. Az eredmények a meglévő médiaformátumban nyílik meg; válassza ki a lejátszási gombot.',
			'universalMedia.cliCopyExample' => 'A parancs példája',
			'universalMedia.cliCopied' => 'A parancs példája másolt.',
			'fileSources.title' => 'Fájlok és könyvek',
			'fileSources.subtitle' => 'Olvasson, hallgasson és figyelj a saját fájlokat.',
			'fileSources.add' => 'Hozzáadása forrás',
			'fileSources.importFiles' => 'Import fájl',
			'fileSources.localFiles' => 'Ebben a készülékben',
			'fileSources.source' => 'forrás',
			'fileSources.name' => 'nevét',
			'fileSources.endpoint' => 'Szerver URL-címe',
			'fileSources.smbEndpointHint' => 'Példa: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Adjon meg egy SMB-kiszolgálót és egy megosztást.',
			'fileSources.root' => 'Folder vagy prefix',
			'fileSources.smbFolderHelp' => 'Hagyja üresen a teljes megosztás használatához, vagy adjon meg egy azon belüli mappát.',
			'fileSources.username' => 'Felhasználónév',
			'fileSources.smbDomain' => 'Tartomány (nem kötelező)',
			'fileSources.password' => 'Jelszó',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'Access kulcs ID',
			'fileSources.secretKey' => 'titkos hozzáférési kulcs',
			'fileSources.sessionToken' => 'Session token (szükséges)',
			'fileSources.region' => 'régió',
			'fileSources.clientId' => 'OAuth ügyfél ID',
			'fileSources.clientSecret' => 'OAuth ügyfél titka (csak a Google asztali)',
			'fileSources.allowHttp' => 'Titkosítatlan HTTP engedélyezése megbízható hálózaton',
			'fileSources.smbEncryption' => 'SMB3-kapcsolat titkosítása',
			'fileSources.smbEncryptionHint' => 'SMB3-titkosítás használata, ha a NAS támogatja.',
			'fileSources.connect' => 'Csatlakozás',
			'fileSources.cancel' => 'Mégse',
			'fileSources.save' => 'Mentés',
			'fileSources.close' => 'Bezárás',
			'fileSources.removeSource' => 'Kapcsolatfelvétel forrás',
			'fileSources.disconnectMessage' => 'Leválasztod ezt a forrást? A letöltött fájlok, valamint az olvasási és hallgatási előzmények ezen az eszközön maradnak.',
			'fileSources.localFolder' => 'Válassza ki a mappa',
			'fileSources.empty' => 'Még nincs itt semmi',
			'fileSources.emptyHint' => 'Hozzon hozzá forrást vagy importáljon egy könyvet, audiókönyvet, zenét vagy videót.',
			'fileSources.search' => 'Keresés a fájlban',
			'fileSources.searchCached' => 'Keresés mentett könyvtár',
			'fileSources.refresh' => 'Frissítés',
			'fileSources.loadMore' => 'Töltse tovább',
			'fileSources.offline' => 'Offline elérhető',
			'fileSources.download' => 'offline maradjon',
			'fileSources.removeDownload' => 'offline másolatok eltávolítása',
			'fileSources.continueReading' => 'Folytatás olvasás',
			'fileSources.continueListening' => 'Folytatjuk a hallgatást',
			'fileSources.continueWatching' => 'Folytatjuk a figyelmét',
			'fileSources.read' => 'Olvasson',
			'fileSources.listen' => 'Hallgasson',
			'fileSources.play' => 'Lejátszás',
			'fileSources.pause' => 'Szünet',
			'fileSources.stop' => 'Leállítás',
			'fileSources.startOver' => 'Kezdődjön a',
			'fileSources.finished' => 'Befejeződött',
			'fileSources.markFinished' => 'Márk befejeződött',
			'fileSources.markUnfinished' => 'Márk végtelen',
			'fileSources.editions' => 'Kiadványok és fájlok',
			'fileSources.chapters' => 'Fejezetek',
			'fileSources.bookmarks' => 'Könyvek és jegyzetek',
			'fileSources.bookmark' => 'Add a bookmark',
			'fileSources.highlight' => 'Fokozás',
			'fileSources.note' => 'jegyzetek',
			'fileSources.delete' => 'Törlés',
			'fileSources.export' => 'exportjegyzékek',
			'fileSources.exported' => 'Kiadó jegyzetek',
			'fileSources.sync' => 'Sinkronizálódás',
			'fileSources.synced' => 'Progressz szinkronizálódott',
			'fileSources.conflict' => 'Egy másik eszköz más helyzetben van. Válassza ki, hol kell folytatni.',
			'fileSources.useLocal' => 'Használja ezt a készüléket',
			'fileSources.useRemote' => 'Egy másik eszköz használata',
			'fileSources.history' => 'pozíció története',
			'fileSources.groupAudio' => 'Hallgassunk egy audiókönyvében',
			'fileSources.groupHint' => 'Összefügg a jelenleg ezen a mappában feltöltött audiofájlokkal. Minden oldal feltöltése először.',
			'fileSources.order' => 'File rend',
			'fileSources.moveUp' => 'mozgatni fel',
			'fileSources.moveDown' => 'Mozgás le',
			'fileSources.speed' => 'Playback sebesség',
			'fileSources.sleep' => 'Elalvási időzítő',
			'fileSources.sleepOff' => 'Ki',
			'fileSources.endChapter' => 'fejezet vége',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} perc', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} perc', ), 
			'fileSources.skipBack' => 'Vissza a Skip',
			'fileSources.skipForward' => 'Skip előre',
			'fileSources.smartRewind' => 'Intelligens visszacsatolás a szünet után',
			'fileSources.playbackOptions' => 'Hallgatási lehetőségek',
			'fileSources.remaining' => ({required Object time}) => '${time} megmaradt',
			'fileSources.contents' => 'Tartalom',
			'fileSources.readerSettings' => 'Olvasási beállítások',
			'fileSources.fontSize' => 'szöveg méret',
			'fileSources.lineHeight' => 'Line tér',
			'fileSources.margin' => 'Margók',
			'fileSources.font' => 'Tippfelület',
			'fileSources.serif' => 'Talpas',
			'fileSources.sans' => 'Szerif nélkül',
			'fileSources.mono' => 'Monopar',
			'fileSources.columns' => 'oszlopok',
			'fileSources.scroll' => 'Vertikálisan Scroll',
			'fileSources.justify' => 'A szöveg igazolása',
			'fileSources.readerTheme' => 'oldal megjelenése',
			'fileSources.appTheme' => 'Következő app témák',
			'fileSources.paper' => 'Papír',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'éjszaka',
			'fileSources.readAloud' => 'Az oldal felolvasása',
			'fileSources.readAlong' => 'Olvass tovább',
			'fileSources.stopReading' => 'A narráció megállítása',
			'fileSources.searchBook' => 'Keresés a könyvben',
			'fileSources.noMatches' => 'Nincs mérkőzés',
			'fileSources.previousPage' => 'Előző oldal',
			'fileSources.nextPage' => 'Következő oldal',
			'fileSources.page' => ({required Object number}) => 'oldal ${number}',
			'fileSources.externalBlocked' => 'A külső könyv linkek a olvasóban kikapcsolódnak.',
			'fileSources.loading' => 'Nyitó...',
			'fileSources.narrator' => 'Történész',
			'fileSources.audio' => 'Hang',
			'fileSources.video' => 'Videó',
			'fileSources.ebooks' => 'Ebook',
			'fileSources.all' => 'Összes',
			'fileSources.downloads' => 'Offline fájlok',
			'fileSources.confirmDelete' => 'Távolítsa el a kiválasztott offline másolatot? a pozíció és a jegyzetek maradnak.',
			'fileSources.errorAuthentication' => 'Jelentkezzen be újra, hogy újra csatlakozzon erre a forrásra.',
			'fileSources.errorPermission' => 'Ez a forrás nem adta hozzáférést a kért fájlhoz.',
			'fileSources.errorUnavailable' => 'A forrás nem elérhető. Próbáljon újra, vagy nyissa meg az offline másolatot.',
			'fileSources.errorUnsupported' => 'Ez a formátum vagy a kapcsolat nem támogatott ebben a készülékben. ellenőrizze a forrás beállítási útmutatót.',
			'fileSources.errorInvalidData' => 'Ez a fájl vagy a szerver válasz nem lehetett biztonságosan olvasni.',
			'fileSources.errorCancelled' => 'A műveletet törölték.',
			'fileSources.errorConflict' => 'A pozíció egy másik ülésen megváltozott. Újra nyissa meg az elemet, hogy válasszon egy pozíciót.',
			'fileSources.signIn' => 'Bejelentkezés',
			'fileSources.reconnect' => 'Újracsatlakozás',
			'fileSources.folderHelp' => 'Hagyja a nyílt, hogy elkezdődjön a forrás gyökér. S3 URL-k tartalmazza a csomagtartót.',
			'fileSources.preferences' => 'preferenciák',
			'fileSources.timePosition' => 'Pozíció',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtitle útvonal',
			'fileSources.none' => 'Nincs',
			'fileSources.fullscreen' => 'Teljes képernyő',
			'fileSources.syncLocation' => 'Progress szinkronizálás (opcionális)',
			'fileSources.syncLocationHint' => 'A WebDAV fájl a PlezyNG állapothoz. feltételezett írásokat használ; a média változatlan marad.',
			'fileSources.audiobooks' => 'Audiókönyvek',
			'fileSources.comics' => 'Képregények',
			'fileSources.scan' => 'A könyv és a média szkennelése',
			'fileSources.browserReader' => 'Nyílt olvasó',
			'fileSources.browserReaderHelp' => 'A böngészőben a olvasó nyitva van. A PlezyNG nyitva tartása a hely és a jegyzetek mentéséhez.',
			'fileSources.on' => 'A',
			'fileSources.advancedSetup' => 'App regisztráció',
			'fileSources.microsoftSignIn' => 'Jelentkezzen be a Microsoft-hoz',
			'fileSources.zoomIn' => 'Zoom a',
			'fileSources.zoomOut' => 'Zoom ki',
			'fileSources.fitPage' => 'Fit oldal',
			'fileSources.fitWidth' => 'széles széles',
			'fileSources.actualSize' => 'Aktuális méret',
			'fileSources.goToPage' => 'Menj a lapra',
			'fileSources.goToSection' => 'Menj a fejezetbe',
			'fileSources.pageRange' => ({required Object count}) => 'Írja be az 1 számot a ${count}',
			'fileSources.pageLayout' => 'Page layout oldal',
			'fileSources.automatic' => 'Automatikus',
			'fileSources.singlePage' => 'Egyoldalú oldal',
			'fileSources.twoPages' => 'Két oldal',
			'fileSources.readingDirection' => 'Olvasási irány',
			'fileSources.leftToRight' => 'Balra a jobbra',
			'fileSources.rightToLeft' => 'Jobbról balra',
			'fileSources.letterSpacing' => 'levél spacing',
			'fileSources.wordSpacing' => 'Szavak spacing',
			'fileSources.readerControlsHelp' => 'Két ujj széthúzásával vagy a nagyítási vezérlőkkel nagyíthatod az oldalakat. Húzással mozgathatod az oldalt. A Ctrl/⌘ és + vagy − módosítja a nagyítást; a Ctrl/⌘ és 0 visszaállítja azt. A Page Up és Page Down lapoz.',
			'fileSources.imagePage' => 'Képregényoldal',
			'fileSources.resetReader' => 'Újraindítás olvasási preferenciák',
			'fileSources.zoom' => 'Nagyítás',
			'fileSources.useFiles' => 'Fájlok és könyvek használata',
			'fileSources.cancelScan' => '- törlés scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Offline letöltés limit',
			'fileSources.offlineQuotaHelp' => 'Állítsa be a maximális helyet használt offline másolatok, importált fájlok, és lejátszott letöltések. A határ csökkentése nem távolítja el a meglévő másolatokat.',
			'fileSources.offlineStorageUsage' => 'Offline tárolás',
			'fileSources.reservedStorage' => 'fenntartás',
			'fileSources.downloadQueue' => 'Letöltés Queue',
			'fileSources.downloadRunning' => 'Letöltés',
			'fileSources.downloadQueued' => 'Várakozás',
			'fileSources.downloadPaused' => 'pihenés',
			'fileSources.downloadFailed' => 'Visszavonulás szükséges',
			'fileSources.importing' => 'behozatal',
			'fileSources.importInterrupted' => 'Import megszakadt · eltávolítása tisztázni',
			'fileSources.errorQuotaExceeded' => 'Az offline tárolási korlátozás elérte. emelje fel a korlátot vagy távolítsa el a letöltött másolatot.',
			'fileSources.errorStorageLow' => 'Nincs elég ingyenes tárolási eszköz a védett tartalék fenntartásához.',
			'fileSources.errorStorageUnavailable' => 'A PlezyNG nem tudta ellenőrizni a szabad készülék tárolását, így az írás megszűnt.',
			'fileSources.removeDownloadJob' => 'Letöltés eltávolítása',
			'fileSources.downloadAlreadyComplete' => 'Ez a letöltés befejeződött, mielőtt eltávolítható. az elem most elérhető offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Távolítsa el ezt a letöltést, és törölje a részben letöltött adatokat?',
			'lending.title' => 'Közös könyvtárak',
			'lending.add' => 'Hozzáadjuk a könyvtárat',
			'lending.other' => 'Egy másik könyvtár',
			'lending.libraryName' => 'Könyvtár neve',
			'lending.libraryUrl' => 'Könyvtár honlapja',
			'lending.libraryUrlHint' => 'Használja a könyvtár katalógusát vagy a bejelentkezési oldalt.',
			'lending.intro' => 'Hitelezzen a könyvtárból, tartsa a könyveit.',
			'lending.handoff' => 'Jelentkezzen be, kölcsönözze és olvassa biztonságosan a könyvtár saját szolgáltatásaival.',
			'lending.openService' => 'Nyílt könyvtár',
			'lending.findLibrary' => 'Keresse meg a könyvtárat',
			'lending.search' => 'Könyvek és szerzők keresése',
			'lending.catalogue' => 'Katalógus',
			'lending.loans' => 'kölcsönök',
			'lending.holds' => 'Előjegyzések',
			'lending.signIn' => 'Jelentkezzen be a könyvtárával',
			'lending.waiting' => 'Véget ért a regisztráció a böngészőben, majd térj vissza ide.',
			'lending.cancel' => 'Mégse',
			'lending.disconnect' => 'Könyvtár eltávolítása',
			'lending.disconnectMessage' => 'Eltávolítod ezt a könyvtárat ebből a profilból? A kölcsönzéseid és előjegyzéseid megmaradnak a könyvtárnál.',
			'lending.getBook' => 'Könyvet kap',
			'lending.checkAvailability' => 'Ellenőrizze a rendelkezésre állást',
			'lending.available' => 'Elérhető kölcsönzéshez',
			'lending.unavailable' => 'Jelenleg nem elérhető',
			'lending.borrow' => 'Kölcsönzés',
			'lending.placeHold' => 'Előjegyzés',
			'lending.returnBook' => 'Korai visszatérés',
			'lending.cancelHold' => 'Előjegyzés törlése',
			'lending.confirmBorrow' => 'Ezt a címet kölcsönözzétek a könyvtárból?',
			'lending.confirmReturn' => 'Vissza kell adnia ezt a címet most? lehet, hogy újra kölcsönözni, hogy folytassa.',
			'lending.confirmCancelHold' => 'Törlöd a címre vonatkozó előjegyzésedet?',
			'lending.email' => 'Hajtsa az értesítést e-mail',
			'lending.due' => ({required Object date}) => 'Személyi ${date}',
			'lending.queue' => ({required Object position}) => '${position} pozíció a sorban',
			'lending.empty' => 'Még nincs címünk itt.',
			'lending.openLibraryNote' => 'Fedezze fel a nyílt könyvtár katalógusát.Az olvasási és hitelezési lehetőségek az egyes címek oldalán jelennek meg.',
			'lending.more' => 'Töltse tovább',
			'lending.gateway' => 'Könyvtár beiratkozás szolgáltatás',
			'lending.gatewayHint' => 'A könyvtár vagy a PlezyNG adminisztrátor által biztosított.',
			'lending.advanced' => 'Könyvtár integráció',
			'lending.loadLibraries' => 'Válassza ki a könyvtárát',
			'lending.expired' => 'Ez a hitel lejár.',
			'lending.updated' => 'Könyvtár frissítés',
			'lending.continueService' => 'Folytatjuk a szolgálatot',
			'lending.comingSoon' => 'In-app kölcsönzés · Jön hamarosan',
			'lending.comingSoonDescription' => 'A Libby integráció a maga módján van.A Libby könyvtárát használhatja, miközben befejezzük a kapcsolatot.',
			'lending.suspendHold' => 'Megszakított tartás',
			'lending.resumeHold' => 'Összefoglaló tartsa',
			'lending.suspendMessage' => 'Megtartod a helyedet a sorban, és átengeded ezt a példányt a következő olvasónak? Az előjegyzést később folytathatod.',
			'lending.resumeMessage' => 'Folytatod ezt az előjegyzést, hogy a könyvtár felajánlhassa a következő elérhető példányt?',
			'lending.editEmail' => 'Változtassuk meg az értesítés e-mail',
			'audiobook.syncTitle' => 'olvasás és hallgatás szinkronizálás',
			'audiobook.syncHelp' => 'Tartsa az olvasási pozíciókat, a hallgatási pozíciókat, a befejezési állapotot, a könyvjelzőket és a jegyzeteket az eszközökön keresztül. Válasszon egy hozzáadott tárolási fiókot, és használja ugyanazt a szinkron kódot minden eszközön. Az olvasás és a hallgatás külön marad.',
			'audiobook.addSyncSource' => 'Add hozzá a Google Drive, OneDrive, Dropbox, WebDAV vagy S3 a Fájlok és könyvek először.',
			'audiobook.syncDestination' => 'Sync tárolási számla',
			'audiobook.syncFolder' => 'Szinkronizálódás vagy prefix',
			'audiobook.syncFolderHelp' => 'Használjon egy külön meglévő mappát a WebDAV forráson belül, vagy egy dedikált S3 előfizetést.',
			'audiobook.syncCode' => 'Magánszinkron kód',
			'audiobook.syncCodeHelp' => 'Hozzon létre egy kódot az első eszközön, majd adja meg azt a kódot a többi eszközön. tartsa magán másolatot: ez a kulcs a titkosított állapot. Használjon egy másik kódot minden egyes személy számára.',
			'audiobook.showCode' => 'Megmutatja vagy elrejti a szinkron kódot',
			'audiobook.newSyncCode' => 'Hozzon létre egy új szinkron kódot',
			'audiobook.saveSync' => 'Megtakarítás és szinkronizálás',
			'audiobook.disableSync' => 'Távolítsa el a szinkronizálást ezen a készüléken',
			'audiobook.syncSourceDisconnect' => 'Ez a forrás eltávolítása kikapcsolja az olvasást és a hallgatást a szinkronizálás itt. titkosított szinkronizált fájlok maradnak a szolgáltató.',
			'audiobook.syncReconnect' => 'Újra összekapcsolja a tárolási fiókot',
			'audiobook.lastSynced' => ({required Object time}) => 'Legutóbb szinkronizált a ${time}',
			'audiobook.syncPrivacy' => 'Csak titkosított előrehaladást és jegyzeteket tárolnak. Audio és ebook fájlokat, fiók tokeneket és jelszavakat nem töltik fel. A Google Drive és a OneDrive alkalmazás tárolását használja; a Dropbox PlezyNG Szinkronizálást használ. A szinkronizálás lehetővé tétele további írásos hozzáférést igényelhet. Amíg aktiválódik, ez a cél a progress szinkronizálást birtokolja; a szerver előrehaladása elválasztva marad. A szinkronizálást törölve tartja a helyi történetet és a távoli állapotot.',
			'audiobook.syncConflicts' => 'Válassza ki, hol kell újra',
			'audiobook.conflictHelp' => 'Ezek a változások önállóan történtek. Válassza ki a pozíciót vagy a betűtípus verzióját, hogy tartsa. A későbbi időzítés vagy a magasabb arány automatikusan nem nyer.',
			'audiobook.syncDevice' => ({required Object device}) => 'készülék ${device}',
			'audiobook.syncUnknownDevice' => 'Ismeretlen eszközök',
			'audiobook.deletedBookmark' => 'Eltávolított könyvjelző',
			'audiobook.finished' => 'befejezett',
			'audiobook.readingPosition' => ({required Object percent}) => 'Olvasás · ${percent}%',
			'audiobook.chapterTimeline' => 'fejezet előrehaladás',
			'audiobook.bookTimeline' => 'Az egész könyv előrehaladása',
			'audiobook.bookRemaining' => ({required Object time}) => 'Idő marad ebben a könyvben: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Idő marad ebben a fejezetben: ${time}',
			'audiobook.unknownRemaining' => 'Teljes rendelkezésre álló idő, mivel a részeket játszanak',
			'audiobook.undoSeek' => 'Utolsó keresés',
			'audiobook.customSpeed' => 'Custom playback sebesség',
			'audiobook.speedHelp' => 'Válasszon egy sebességet 0,25× és 4× között.',
			'audiobook.apply' => 'alkalmazás',
			'audiobook.customSleep' => 'Alvási időszámítás',
			'audiobook.sleepMinutes' => 'percek (1–1440)',
			'audiobook.sleepChapters' => ({required Object count}) => '${count} fejezetek után',
			'audiobook.extendSleep' => 'Add hozzá 5 percet',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Alvás időzítő: ${time}',
			'audiobook.useDefaults' => 'Használja ezeket a hallgatási vezérlőket az új könyvekhez',
			'audiobook.librarySort' => 'Színes könyvek',
			'audiobook.sortTitle' => 'címek',
			'audiobook.sortAuthor' => 'Szerző',
			'audiobook.sortNarrator' => 'Történész',
			'audiobook.sortSeries' => 'sorozatrendelés',
			'audiobook.sortRecent' => 'Nemrégiben megnyitott',
			'audiobook.statusFilter' => 'Olvasási állapot',
			'audiobook.statusAll' => 'Minden könyv',
			'audiobook.statusNew' => 'Nem kezdődött',
			'audiobook.statusProgress' => 'előrehaladás',
			'audiobook.statusFinished' => 'befejezett',
			'audiobook.goToTime' => 'Menj az időbe',
			'audiobook.timeHelp' => 'Idők: percek: másodpercek, vagy percek: másodpercek',
			'audiobook.recoveryHelp' => 'A szinkronizációs adatok áthelyezése vagy javítása előtt exportáljon egy nemrégiben titkosított másolatot. Az importok összeolvadnak a jelenlegi állapotgal; soha nem helyettesítik a helyi szinkrálás történetét.',
			'audiobook.recoveryExport' => 'Export titkosított helyreállítási fájl',
			'audiobook.recoveryImport' => 'Import titkosított helyreállítási fájl',
			'audiobook.recoveryImportConfirm' => 'Ez a titkosított helyreállítási fájl összekapcsolja az aktuális olvasási pozíciókkal és jegyzetekkel? A meglévő történelem megmarad. Megosztott könyvtár és elem azonosítók nem szerepelnek; beállítja az egyes eszközök megfelelő azonosítóját az import előtt.',
			'audiobook.recoveryExported' => 'A titkosított helyreállítási fájl mentett.',
			'audiobook.recoveryImported' => 'A helyreállítási adatok összegyűltek.',
			'sourceSetup.savedCertificate' => 'Mentett szervertanúsítvány',
			'sourceSetup.nfsEndpointInvalid' => 'Adj meg egy NFS URL-t, például: nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Nem található DLNA-kiszolgáló. Add meg kézzel az eszközleírás URL-jét.',
			'sourceSetup.dlnaServers' => 'DLNA-médiakiszolgálók',
			'sourceSetup.dlnaUnavailable' => 'A DLNA-felderítés ezen a hálózaton nem érhető el. Add meg kézzel az eszközleírás URL-jét.',
			'sourceSetup.dlnaSearching' => 'DLNA-kiszolgálók keresése a helyi hálózaton',
			'sourceSetup.networkSearching' => 'Keresés a helyi hálózaton…',
			'sourceSetup.dlnaDiscover' => 'DLNA-kiszolgálók felderítése',
			'sourceSetup.dlnaHelp' => 'A felderítés a helyi hálózat multicast-forgalmától függ. Ha nem jelenik meg kiszolgáló, add meg fent az eszközleírásának URL-jét.',
			'sourceSetup.dlnaRoot' => 'DLNA-objektumazonosító; üresen hagyva az eszköz gyökerét használja.',
			'sourceSetup.passwordOrKey' => 'Adj meg egy jelszót, vagy adj hozzá lent egy privát kulcsot.',
			'sourceSetup.sshFingerprint' => 'Az SSH-gépkulcs SHA256-ujjlenyomata',
			'sourceSetup.sshFingerprintHelp' => 'Ellenőrizd a szerver rendszergazdájával. A szerveren futtasd az ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub parancsot, és használd az SHA256-értékét.',
			'sourceSetup.sshFingerprintKeep' => 'Hagyd üresen a jelenleg rögzített ujjlenyomat megőrzéséhez, vagy adj meg új szerverujjlenyomatot.',
			'sourceSetup.sshAuthentication' => 'SSH-hitelesítés nyilvános kulccsal',
			'sourceSetup.sshAuthenticationHelp' => 'Nem kötelező; a jelszavas hitelesítés is támogatott.',
			'sourceSetup.privateKey' => 'Privát kulcs (PEM- vagy OpenSSH-formátum)',
			'sourceSetup.privateKeyPassphrase' => 'A privát kulcs jelmondata',
			'sourceSetup.nfsMountPort' => 'Az NFS-csatolási szolgáltatás TCP-portja',
			'sourceSetup.nfsMountPortHelp' => 'Alapértelmezett: 20048',
			'sourceSetup.nfsUserId' => 'NFS-felhasználóazonosító (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Alapértelmezett: 1000. A NAS NFS-megosztása által engedélyezett azonosítót használd.',
			'sourceSetup.nfsGroupId' => 'NFS-csoportazonosító (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Alapértelmezett: 1000. A NAS NFS-megosztása által engedélyezett csoportazonosítót használd.',
			'sourceSetup.nfsEncryption' => 'Titkosított NFS megkövetelése (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'TLS 1.3 megkövetelése az NFS-hez és a csatolási szolgáltatáshoz. Ha a NAS ezt nem támogatja, a kapcsolat nem jön létre.',
			'sourceSetup.nfsTrustCertificate' => 'Egyéni NFS CA vagy szervertanúsítvány (PEM, nem kötelező)',
			'sourceSetup.nfsTrustHelp' => 'Hagyd üresen az eszköz által megbízhatónak tartott tanúsítványokhoz. Szükség esetén adj hozzá privát CA-tanúsítványt vagy önaláírt szervertanúsítványt; a benne szereplő neveknek egyezniük kell az NFS URL gépnevével.',
			'sourceSetup.nfsTrustInvalid' => 'PEM-formátumú CA- vagy szervertanúsítványt használj. Ne adj meg privát kulcsot.',
			'sourceSetup.addTrustCertificate' => 'Egyéni megbízható tanúsítvány hozzáadása',
			'sourceSetup.replaceTrustCertificate' => 'Mentett egyéni tanúsítvány cseréje',
			'sourceSetup.nfsTlsHelp' => 'Az RPC-with-TLS a szokásos NFS- és csatolásiszolgáltatás-portokat használja, és RFC 9289-támogatást igényel a NAS-on. TLS 1.3 szükséges. A gépnévnek vagy IP-címnek egyeznie kell a tanúsítvánnyal. Az AUTH_SYS UID/GID a titkosított csatornán belül is érvényes.',
			'sourceSetup.clientCertificate' => 'Kliens tanúsítványa (nem kötelező)',
			'sourceSetup.clientCertificateHelp' => 'Lehetővé teszi, hogy a NAS hitelesítse ezt a klienst; az AUTH_SYS-azonosítók továbbra is a NAS NFS-megosztásának szabályaitól függenek.',
			'sourceSetup.savedIdentity' => 'A mentett kliensazonosság lesz használva.',
			'sourceSetup.replaceIdentity' => 'Mentett kliensazonosság cseréje',
			'sourceSetup.chooseIdentity' => 'PKCS#12-kliensazonosság kiválasztása',
			'sourceSetup.identityPassphrase' => 'A kliensazonosság jelmondata',
			'sourceSetup.identityPassphraseHelp' => 'Hagyd üresen, ha a fájlnak nincs jelmondata.',
			'sourceSetup.removeIdentity' => 'Mentett kliensazonosság eltávolítása',
			'sourceSetup.identityStorageHelp' => 'A kliensazonosságok a forrás titkosított hitelesítőadat-tárába kerülnek. A mentett azonosság megőrzéséhez hagyd változatlanul ezt a részt.',
			'sourceSetup.nfsLimitations' => 'Csak olvasható NFSv3 TCP felett. RPC-with-TLS nélkül az NFS-forgalom titkosítatlan. A NAS-nak engedélyeznie kell a választott AUTH_SYS-azonosítókat és a nem privilegizált kliensportokat (ez gyakran az „insecure” exportbeállítás). Az NFSv4 és az UDP nem támogatott.',
			'sourceSetup.nfsSetupHelp' => 'NFS-beállítási súgó',
			'sourceSetup.nfsSetupHint' => 'Ellenőrizd ezeket a beállításokat, ha nem jön létre a kapcsolat.',
			'sourceSetup.nfsSetupDetails' => 'NFSv3-megosztást használj TCP felett. Ha titkosítás szükséges, az NFS- és a csatolási szolgáltatásnak is támogatnia kell az RPC-with-TLS-t. Hagyd üresen az egyéni tanúsítványt az eszköz által megbízhatónak tartott szervertanúsítványhoz, vagy add hozzá a NAS CA-tanúsítványát vagy önaláírt tanúsítványát. A tanúsítványban lévő névnek egyeznie kell a végpont gépnevével. Ha a NAS kölcsönös TLS-hitelesítést kér, add hozzá a PKCS#12-kliensazonosságát. Végül ellenőrizd, hogy a megosztás engedélyezi-e a beállított AUTH_SYS UID/GID értékeket és a kliensportokra vonatkozó szabályokat.',
			'sourceSetup.ftpHelp' => 'Az FTP passzív módot használ. Titkosítatlan FTP-hez ftp://, explicit TLS-hez ftpes://, TLS-hez pedig ftps:// használható (a 990-es porton implicit, más portokon explicit).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Opcionális feliratkeresés önálló videókhoz.',
			'sourceSetup.apiKey' => 'API-kulcs',
			'sourceSetup.optionalUsername' => 'A fiók felhasználóneve (nem kötelező)',
			'sourceSetup.optionalPassword' => 'A fiók jelszava (nem kötelező)',
			'sourceSetup.subtitlePrivacy' => 'Szerezz API-kulcsot az opensubtitles.com oldalon. A keresés a videó címét és az elérhető IMDb/TMDB-azonosítókat küldi el, a videófájlt soha. A kulcs és az opcionális fiókhitelesítő adatok ezzel a forrással együtt titkosítva tárolódnak.',
			'sourceSetup.automaticMetadata' => 'Automatikus online videómetaadatok',
			'sourceSetup.metadataPrivacy' => 'Csak a fájlnévből származó címet/évet és epizódszámokat vagy egy NFO-azonosítót küld el, médiát vagy hitelesítő adatokat soha. Az NFO-mezők elsőbbsége megmarad.',
			'sourceSetup.nfsEncryptionFailure' => 'Titkosított NFS esetén ellenőrizd az RFC 9289 és a TLS 1.3 támogatását mindkét NAS-szolgáltatásnál, a tanúsítvány nevét és a megosztás UID/GID értékeit. A PlezyNG nem próbálja újra ezt a kapcsolatot titkosítás nélkül.',
			'sourceSetup.sourceConnecting' => 'Kapcsolódás a forráshoz',
			'sourceSetup.metadataSearchPrivacy' => 'Ez a címkeresés a Trakthoz kerül. A megadott címet küldi el, nem a videót vagy a forrás hitelesítő adatait.',
			'sourceSetup.chooseMatch' => 'Találat kiválasztása',
			'sourceSetup.metadataMatchHelp' => 'Választás előtt ellenőrizd a címet és az évet. A Trakt a keresett címet kapja meg; a videó a forrásán marad.',
			'sourceSetup.metadataNoMatches' => 'Nem található egyező cím online. Próbálj másik címet.',
			'sourceSetup.metadataSearch' => 'Online metaadatok keresése',
			'sourceSetup.metadataLoading' => 'Filmek és sorozatok adatainak keresése online…',
			'sourceSetup.metadataFromTrakt' => 'Online metaadatok a Trakttól',
			'sourceSetup.metadataNoAutomaticMatch' => 'Nem található automatikus címegyezés. Keress rá a címre a találat kiválasztásához.',
			'sourceSetup.metadataFailed' => 'Az online metaadatok nem tölthetők be. A lejátszás és a helyi adatok továbbra is elérhetők.',
			'sourceSetup.videoDetailsLoading' => 'Videóadatok betöltése',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles-API-kulcs szükséges',
			'sourceSetup.subtitleKeyHelp' => 'Szerkeszd ezt a fájlforrást, és adj hozzá OpenSubtitles-API-kulcsot az opcionális feliratbeállításoknál.',
			'sourceSetup.subtitleSearchFailed' => 'A feliratkeresés sikertelen. Ellenőrizd az API-kulcsot, a kapcsolatot és a szolgáltatás elérhetőségét.',
			'sourceSetup.subtitleApplyFailed' => 'A felirat nem tölthető le vagy nem alkalmazható. Ellenőrizd a kapcsolatot, és próbálj másik találatot.',
			'sourceSetup.subtitleSearch' => 'Keresés az OpenSubtitles oldalán',
			'sourceSetup.subtitleSearchPrivacy' => 'A keresés a címet és az elérhető IMDb/TMDB-azonosítókat használja. A videófájl a forrásán marad. Választás előtt ellenőrizd a nyelvet, a kényszerített vagy hallássérülteknek készült felirat jelölését és az értékelést.',
			'sourceSetup.movieOrShow' => 'Film vagy sorozat',
			'sourceSetup.subtitleTitleHint' => 'Adj meg címet a találatok pontosításához',
			'sourceSetup.subtitleLanguage' => 'Felirat nyelve',
			'sourceSetup.subtitleSearching' => 'Keresés az OpenSubtitles oldalán',
			'sourceSetup.subtitleNoMatches' => 'Nem található megfelelő felirat. Próbálj másik címet vagy nyelvet.',
			'sourceSetup.downloadSubtitle' => 'Felirat letöltése',
			'sourceSetup.subtitle' => 'Felirat',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS szükséges',
			'sourceSetup.nfsUnencrypted' => 'Titkosítatlan NFS',
			'sourceSetup.tlsEncrypted' => 'TLS-titkosítás',
			'sourceSetup.ftpPlain' => 'Titkosítatlan FTP',
			'sourceSetup.sshPinned' => 'Titkosított SSH · rögzített gépkulcs',
			'sourceSetup.smbEncrypted' => 'SMB3-titkosítás bekapcsolva',
			'sourceSetup.smbUnencrypted' => 'SMB3-titkosítás kikapcsolva',
			'sourceSetup.httpUnencrypted' => 'HTTP átviteli titkosítás nélkül',
			'sourceSetup.checkEndpointSecurity' => 'Végpont biztonságának ellenőrzése',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Kötelező mező: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'A(z) ${label} értéke ${min} és ${max} között legyen.',
			'sourceSetup.replaceFile' => ({required Object name}) => '${name} cseréje',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Kiválasztott kliensazonosság: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Értékelés: ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Felirat letöltése: ${title}',
			'sourceSetup.sharedEntryPair' => 'Csatlakozzon ehhez az elemhez',
			'sourceSetup.sharedEntryPairHelp' => 'Írja be ugyanazt az azonosítót erre az elemre minden eszközön. Használjon stabil megosztott azonosítóját vagy hozzon létre egyet, és másolja azt a megfelelõ elemre. A progress párosul csak akkor, ha a kiadvány fájl típusa, mérete és rendje megfelel. Blank eltávolítja ezt a mappázást.',
			'sourceSetup.sharedEntryId' => 'Megosztott elem ID',
			'sourceSetup.generateSharedEntryId' => 'Megosztott elem ID generálása',
			'sourceSetup.sharedLibraryId' => 'Megosztott könyvtár azonosító (opcionális)',
			'sourceSetup.sharedLibraryHelp' => 'Használja ugyanazt az ID-t olyan eszközökön, amelyek ugyanezt a könyvtárat nyitják meg. Ez a nyilvános ID segít olvasási előrehaladást és jegyzeteket tartani különböző forráskódú kapcsolatokon keresztül; ez nem jelszó. Amikor a szolgáltatók különböző elemek azonosítóját használják, azokat a részletes képernyőktől párolják.',
			'sourceSetup.sharedLibraryInvalid' => 'Használjon 8–100 betűt, számot, pontokat, alszámokat vagy hyphenseket.',
			'sourceSetup.generateSharedLibraryId' => 'Egy megosztott könyvtár azonosító létrehozása',
			'sourceSetup.nfsReadAhead' => 'NFS olvasási kérelmek',
			'sourceSetup.nfsReadAheadHelp' => 'Több párhuzamos olvasás javíthatja a gyors NAS vagy hálózati átjárót. Használjon 1 ha a szerver korlátozza az egymást követő kéréseket.',
			'sourceSetup.nfsReadTest' => 'NFS olvasási teljesítmény mérése',
			'sourceSetup.nfsReadTestHelp' => 'A legnagyobb fájltól 64 MiB-ig olvasható, hogy mérje ezt a NAS kapcsolatot.',
			'sourceSetup.nfsQualificationResult' => 'NFS olvasás mérés',
			'sourceSetup.nfsReadBytes' => 'Az adatok olvasása',
			'sourceSetup.nfsReadSpeed' => 'Mérhető sebesség',
			'sourceSetup.nfsReadRequests' => 'Olvassa el a kéréseket',
			'sourceSetup.sharedEntryConflict' => 'Ez a megosztott elem azonosító már párosított egy másik elem ebben a könyvtárban.',
			'comics.fitHeight' => 'Magassághoz igazítás',
			'comics.readingMode' => 'Olvasási mód',
			'comics.paged' => 'Oldalak',
			'comics.webtoon' => 'Folyamatos görgetés',
			'comics.coverAlone' => 'Borító külön megjelenítése',
			'comics.splitWide' => 'Széles oldalak felosztása',
			'comics.splitWideHelp' => 'A két felet külön, olvasási sorrendben jeleníti meg. Bekapcsolva az oldalpárok megjelenítése szünetel.',
			'comics.thumbnails' => 'Oldalak bélyegképei',
			'comics.controlsHelp' => 'Lapozáshoz húzza el az ujját. Az igazítás módosításához koppintson duplán. Folyamatos görgetésnél húzza függőlegesen, vagy használja a Page Up és Page Down billentyűket.',
			'comics.savedForComic' => 'A megjelenítési beállításokat ez a profil megjegyzi ehhez a képregényhez.',
			'comics.readLists' => 'Olvasási listák',
			'comics.collections' => 'Gyűjtemények',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.subtitle' => 'Your games, from your computers.',
			'games.computers' => 'Your computers',
			'games.nearby' => 'Nearby computers',
			'games.findComputers' => 'Find computers',
			'games.addComputer' => 'Add computer',
			'games.scanHint' => 'Keep Steam Remote Play or Sunshine running on the same network. VPNs and guest networks may need a manual address.',
			'games.empty' => 'Add your gaming computer to get started.',
			'games.noNearby' => 'No computers found on this network. You can enter an address manually.',
			'games.name' => 'Computer name',
			'games.address' => 'IP address or hostname',
			'games.port' => 'Service port',
			'games.protocol' => 'Streaming service',
			'games.moonlight' => 'Sunshine / Moonlight',
			'games.steam' => 'Steam Remote Play',
			'games.save' => 'Save computer',
			'games.invalidAddress' => 'Enter a valid hostname or IP address, without a URL, and a port from 1 to 65534.',
			'games.pair' => 'Connect computer',
			'games.pairTitle' => 'Approve this device',
			'games.pairInstructions' => 'Enter this code in the host’s pairing prompt. For Sunshine, use the PIN page below. Keep this screen open until the computer approves.',
			'games.pairHelp' => 'Connect this computer again to approve or renew pairing.',
			'games.openPairingPage' => 'Open Sunshine PIN page',
			'games.qrHelp' => 'Scan to open the PIN page. The QR code contains only the computer address, never a password or pairing credential.',
			'games.refreshGames' => 'Refresh games',
			'games.play' => 'Play',
			'games.favorites' => 'Favorites',
			'games.allGames' => 'All games',
			'games.search' => 'Find a game',
			'games.noMatches' => 'No games match this search.',
			'games.favorite' => 'Save favorite',
			'games.unfavorite' => 'Remove favorite',
			'games.forget' => 'Forget computer',
			'games.forgetDescription' => 'Remove this computer and its game shortcuts from this profile? To revoke this device’s authorization, remove it from the host’s paired devices.',
			'games.unavailable' => 'The connection could not complete. Check that the computer is awake and paired, then try again.',
			'games.timeout' => 'Connection timed out. Check the computer, pairing code and network before trying again.',
			_ => null,
		} ?? switch (path) {
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			'games.touchDescription' => 'Show the on-screen controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
			'games.touchSetup' => 'On-screen controls',
			'games.touchSetupHint' => 'Moonlight’s controller settings support position and opacity changes. During a Steam stream, open the stream menu to toggle its controller. Bluetooth or USB input is also supported.',
			'games.addGame' => 'Add game shortcut',
			'games.gameName' => 'Game name',
			'games.gameId' => 'Host application ID',
			'games.invalidGame' => 'Enter a game name and a positive numeric host application ID.',
			'games.wake' => 'Wake computer',
			'games.wakeSent' => 'Wake request sent. The computer must support Wake-on-LAN on this network.',
			'games.mac' => 'MAC address (optional)',
			'games.help' => 'Games help',
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Steam can open Big Picture or launch a saved game shortcut inside PlezyNG on receivers that support it. Connect Companion Remote to combine installed games from your computers in one library. Steam pairing does not grant access to a private account library.\n\nSteam receivers are experimental on Android, Linux and Apple. The stream menu provides controller, audio and connection controls. Pyrowave is an optional codec on compatible Android and Apple receivers and needs a fast network.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include an embedded Steam receiver for this device. You can browse your library and manage computers. Playing here requires a build with a compatible receiver.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'deepLinks.invalid' => 'Ez a Plezy link nem érvényes.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Nincs profil a "${profile}" címmel.',
			'deepLinks.serverUnavailable' => 'Nem tudtam elérni a szervert erre a linkre.',
			'deepLinks.notFound' => 'Nem találtam ezt a címet a könyvtárakban.',
			'deepLinks.unsupportedItem' => 'Ezt a linket nem lehet játszani.',
			'deepLinks.noLiveTv' => 'Nincs Live TV szerver elérhető ezen a linken.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Nem találták meg a "${channel}" csatornát.',
			'deepLinks.showLink' => 'Show linkek',
			'deepLinks.showProfileLink' => 'Profil link megjelenítése',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'A link megnyitása a következő epizódot játssza. Add &mode=shuffle to play the show on shuffle.',
			'deepLinks.movieHint' => 'A link megnyitása a filmet játssza.',
			'deepLinks.episodeHint' => 'A link megnyitása ezt az epizódot játssza.',
			'deepLinks.profileHint' => 'A link megnyitása váltja át ezt a profilot.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Nyissa meg, mint ${name}',
			'deepLinks.copy' => 'másolás',
			'deepLinks.copied' => 'Link másolat',
			'householdSetup.title' => 'Háztartás beállítása',
			'issueReport.title' => 'Hiba jelentése',
			'issueReport.instructions' => 'Olvasd be a QR-kódot az előre kitöltött GitHub-vázlat megnyitásához. Ellenőrizd, és csak akkor küldd el, ha készen állsz.',
			'issueReport.privacy' => 'A vázlat az alkalmazás verzióját, a platformot és a kapcsolatok számát tartalmazza. Nem tartalmaz szervercímeket, fiók- vagy profilneveket, médiacímeket és fájlútvonalakat.',
			'issueReport.logPrivacy' => 'A naplók megadása nem kötelező. Feltöltés előtt nézd át őket. Az azonosítójuk bekerülhet a nyilvános vázlatba.',
			'issueReport.openDraft' => 'GitHub-vázlat megnyitása',
			_ => null,
		};
	}
}
