///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
	@override late final _Translations$auth$hu auth = _Translations$auth$hu._(_root);
	@override late final _Translations$common$hu common = _Translations$common$hu._(_root);
	@override late final _Translations$screens$hu screens = _Translations$screens$hu._(_root);
	@override late final _Translations$update$hu update = _Translations$update$hu._(_root);
	@override late final _Translations$settings$hu settings = _Translations$settings$hu._(_root);
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
	@override late final _Translations$discover$hu discover = _Translations$discover$hu._(_root);
	@override late final _Translations$errors$hu errors = _Translations$errors$hu._(_root);
	@override late final _Translations$libraries$hu libraries = _Translations$libraries$hu._(_root);
	@override late final _Translations$about$hu about = _Translations$about$hu._(_root);
	@override late final _Translations$serverSelection$hu serverSelection = _Translations$serverSelection$hu._(_root);
	@override late final _Translations$hubDetail$hu hubDetail = _Translations$hubDetail$hu._(_root);
	@override late final _Translations$logs$hu logs = _Translations$logs$hu._(_root);
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
}

// Path: app
class _Translations$app$hu extends Translations$app$en {
	_Translations$app$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get useQuickConnect => 'Quick Connect használata';
	@override String get quickConnectInstructions => 'Nyisd meg a Quick Connect-et a Jellyfinben, és add meg ezt a kódot.';
	@override String get quickConnectWaiting => 'Várakozás a jóváhagyásra…';
	@override String get quickConnectCancel => 'Mégse';
	@override String get quickConnectExpired => 'A Quick Connect kód lejárt. Próbáld újra.';
	@override String get localDataRecoveryRequired => 'A Plezy nem tudta biztonságosan helyreállítani a helyi bejelentkezés és a függőben lévő lejátszás adatait. Jelentkezz be újra.';
}

// Path: common
class _Translations$common$hu extends Translations$common$en {
	_Translations$common$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Mégse';
	@override String get save => 'Mentés';
	@override String get close => 'Bezárás';
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
	@override String get supportDeveloper => 'Plezy támogatása';
	@override String get supportDeveloperDescription => 'A fejlesztés támogatása Liberapay-en keresztül';
	@override String get language => 'Nyelv';
	@override String get theme => 'Téma';
	@override String get appearance => 'Megjelenés';
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
	@override String get libraryDensity => 'Könyvtársűrűség';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Kényelmes';
	@override String get tvCornerSpotlightBackdrop => 'Sarokban megjelenő kiemelt háttérkép';
	@override String get tvCornerSpotlightBackdropDescription => 'A kiemelt háttérkép megjelenítése a jobb felső sarokban a teljes képernyő helyett';
	@override String get viewMode => 'Nézetmód';
	@override String get gridView => 'Rács';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Kiemelt sáv megjelenítése';
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
	@override String get bufferSize => 'Puffer mérete';
	@override String bufferSizeMB({required Object size}) => '${size} MB';
	@override String get bufferSizeAuto => 'Automatikus (ajánlott)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap} MB memória érhető el. A(z) ${size} MB méretű puffer befolyásolhatja a lejátszást.';
	@override String get defaultQualityTitle => 'Alapértelmezett minőség';
	@override String get musicQualityTitle => 'Zene minősége';
	@override String get subtitleStyling => 'Feliratok stílusa';
	@override String get subtitleStylingDescription => 'Feliratok megjelenésének testreszabása';
	@override String get smallSkipDuration => 'Kis ugrás időtartama';
	@override String get largeSkipDuration => 'Nagy ugrás időtartama';
	@override String get rewindOnResume => 'Visszatekerés folytatáskor';
	@override String secondsUnit({required Object seconds}) => '${seconds} másodperc';
	@override String get defaultSleepTimer => 'Alapértelmezett elalvási időzítő';
	@override String minutesUnit({required Object minutes}) => '${minutes} perc';
	@override String get rememberTrackSelections => 'Sávválasztások megjegyzése sorozatonként/filmenként';
	@override String get rememberTrackSelectionsDescription => 'Hang- és feliratválasztások megjegyzése címenként';
	@override String get followServerTrackSelections => 'A szerver epizódonkénti sávválasztásának használata';
	@override String get followServerTrackSelectionsDescription => 'Epizódváltáskor a szerveren kiválasztott hang és felirat lép életbe az aktuális választás átvitele helyett';
	@override String get showChapterMarkersOnTimeline => 'Fejezetjelölők megjelenítése az idősávon';
	@override String get showChapterMarkersOnTimelineDescription => 'Az idősáv felosztása a fejezetek határainál';
	@override String get clickVideoTogglesPlayback => 'Kattintás a videóra a lejátszás/szünet váltásához';
	@override String get clickVideoTogglesPlaybackDescription => 'A videóra kattintva vált a lejátszás/szünet, a vezérlők megjelenítése helyett.';
	@override String get videoPlayerControls => 'Videólejátszó vezérlői';
	@override String get keyboardShortcuts => 'Billentyűparancsok';
	@override String get keyboardShortcutsDescription => 'Billentyűparancsok testreszabása';
	@override String get videoPlayerNavigation => 'Videólejátszó-navigáció';
	@override String get videoPlayerNavigationDescription => 'A nyílbillentyűk használata a videólejátszó vezérlői közötti navigáláshoz';
	@override String get watchTogetherRelay => 'Watch Together-relé';
	@override String get watchTogetherRelayDescription => 'Egyéni relé beállítása. Mindenkinek ugyanazt a szervert kell használnia.';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Adj meg egy érvényes HTTP- vagy HTTPS-alapú relészerver-URL-t.';
	@override String get crashReporting => 'Összeomlási jelentések';
	@override String get crashReportingDescription => 'Összeomlási jelentések küldése az alkalmazás fejlesztésének elősegítéséhez';
	@override String get debugLogging => 'Hibakeresési naplózás';
	@override String get debugLoggingDescription => 'Részletes naplózás engedélyezése a hibaelhárításhoz';
	@override String get viewLogs => 'Naplók megtekintése';
	@override String get viewLogsDescription => 'Alkalmazásnaplók megtekintése';
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
	@override String get importSettingsInvalidFile => 'Ez a fájl nem érvényes Plezy-beállításexport';
	@override String get importSettingsNoUser => 'Jelentkezz be a beállítások importálása előtt';
	@override String get shortcutsReset => 'A billentyűparancsok visszaálltak az alapértelmezettekre';
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
	@override String get autoSkip => 'Automatikus átugrás';
	@override String get autoSkipIntro => 'Intró automatikus átugrása';
	@override String get autoSkipIntroDescription => 'Az intrójelölők automatikus átugrása néhány másodperc után';
	@override String get autoSkipCredits => 'Stáblista automatikus átugrása';
	@override String get autoSkipCreditsDescription => 'A stáblista automatikus átugrása és a következő epizód lejátszása';
	@override String get forceSkipMarkerFallback => 'Tartalék jelölők kényszerítése';
	@override String get forceSkipMarkerFallbackDescription => 'Fejezetcím-minták használata akkor is, ha a Plex rendelkezik jelölőkkel';
	@override String get autoSkipDelay => 'Automatikus átugrás késleltetése';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Várakozás ${seconds} másodpercig az automatikus átugrás előtt';
	@override String get introPattern => 'Intrójelölő mintája';
	@override String get introPatternDescription => 'Reguláris kifejezés az intrójelölők illesztéséhez a fejezetcímekben';
	@override String get creditsPattern => 'Stáblistajelölő mintája';
	@override String get creditsPatternDescription => 'Reguláris kifejezés a stáblistajelölők illesztéséhez a fejezetcímekben';
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
	@override String get autoPip => 'Automatikus kép a képben (PiP)';
	@override String get autoPipDescription => 'Lejátszás közben az alkalmazás elhagyásakor automatikusan kép a képben módra vált';
	@override String get matchContentFrameRate => 'Képkockasebesség illesztése a tartalomhoz';
	@override String get matchContentFrameRateDescription => 'A kijelző frissítési frekvenciájának igazítása a videóhoz';
	@override String get matchRefreshRate => 'Frissítési frekvencia illesztése';
	@override String get matchRefreshRateDescription => 'A kijelző frissítési frekvenciájának igazítása teljes képernyőn';
	@override String get matchDynamicRange => 'Dinamikatartomány illesztése';
	@override String get matchDynamicRangeDescription => 'HDR bekapcsolása HDR-tartalmak esetén, majd visszaváltás SDR-re';
	@override String get displaySwitchDelay => 'Kijelzőváltási késleltetés';
	@override String get tunneledPlayback => 'Alagutas lejátszás';
	@override String get tunneledPlaybackDescription => 'Videóalagút használata. Tiltsd le, ha HDR-lejátszáskor fekete a kép.';
	@override String get audioPassthrough => 'Hangtovábbítás (passthrough)';
	@override String get audioPassthroughDescription => 'Dolby/DTS-hang továbbítása az erősítőre vagy a TV-re újrakódolás nélkül, a térhangzás megőrzésével. Kapcsold ki, ha nincs hang.';
	@override String get audioPassthroughDescriptionAppleTv => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. A DTS és a TrueHD továbbra is többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.';
	@override String get audioDownmix => 'Lekeverés sztereóra';
	@override String get audioDownmixDescription => 'A térhangzás lekeverése két csatornára sztereó hangszórókhoz vagy fejhallgatókhoz';
	@override String get downmixCenterBoost => 'Középső csatorna kiemelése';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Kiemelés (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Hangerő normalizálása lekeveréskor';
	@override String get audioDownmixNormalizeDescription => 'A keverés szintjének csökkentése a torzítás elkerülésére. Kapcsold ki az eredeti hangerő megőrzéséhez (a hangos jelenetek torzíthatnak).';
	@override String get atmosDiagnostics => 'Atmos kimeneti teszt';
	@override String get atmosDiagnosticsDescription => 'Dolby Atmos kimenet diagnosztizálása tesztjelek lejátszásával a rendszerlejátszón keresztül';
	@override String get atmosTestHlsAtmos => 'Apple Atmos folyam';
	@override String get atmosTestHlsAtmosDescription => 'Igazoltan működő Dolby Atmos-adatfolyam. Az erősítő kijelzőjén a Dolby Atmos formátumnak kell megjelennie.';
	@override String get atmosTestHlsControl => 'Apple térhangzású folyam';
	@override String get atmosTestHlsControlDescription => 'Atmos nélküli ellenőrző adatfolyam. Az erősítő kijelzőjén térhangzásnak kell megjelennie, Atmos nélkül.';
	@override String get atmosTestRawStream => 'Nyers EAC3 folyam';
	@override String get atmosTestRawStreamDescription => 'A tesztfájlt pontosan úgy közvetíti, mint a lejátszón belüli Atmos lejátszás. Szükséges a tesztfájl URL-je.';
	@override String get atmosTestRawFile => 'Nyers EAC3 fájl';
	@override String get atmosTestRawFileDescription => 'Ismert hosszúságú tesztfájlt játszik le. Szükséges a tesztfájl URL-je.';
	@override String get atmosTestAsbarNative => 'Mintapuffer-megjelenítő (natív)';
	@override String get atmosTestAsbarNativeDescription => 'A fájl érintetlen tömörített hangját közvetlenül a rendszer megjelenítőjének adja. Szükséges a tesztfájl URL-je.';
	@override String get atmosTestAsbarGenerated => 'Mintapuffer-megjelenítő (újraépített)';
	@override String get atmosTestAsbarGeneratedDescription => 'Ugyanaz, de a lejátszás módján felépített hangleírással. Szükséges a tesztfájl URL-je.';
	@override String get atmosTestSessionMode => 'Filmlejátszási mód használata';
	@override String get atmosTestSessionModeDescription => 'Kikapcsolva a Dolby által dokumentált módot használja. Bekapcsolva a korábbi módot.';
	@override String get atmosTestShowRoutePicker => 'AirPlay kimenet választása';
	@override String get atmosTestHideRoutePicker => 'AirPlay kimenetválasztó elrejtése';
	@override String get atmosTestRoutePickerDescription => 'Elküldi a tesztet egy AirPlay vevőnek. Csak az AirPlay jelzi a feloldott hangmódot.';
	@override String get atmosTestStop => 'Teszt leállítása';
	@override String get atmosTestUrl => 'Tesztfájl URL-je';
	@override String get atmosTestUrlDescription => 'Nyers .ec3 Dolby Atmos fájl HTTP URL-je (pl. ffmpeg-gel kinyerve)';
	@override String get atmosTestUrlMissing => 'Először állítsd be a tesztfájl URL-jét';
	@override String get atmosTestStatus => 'Állapot';
	@override String get dvConversionMode => 'Dolby Vision-átalakítás';
	@override String get dvConversionModeDescription => 'Válaszd ki, hogyan kezelje az ExoPlayer a Dolby Vision Profile 7 fájlokat.';
	@override String get dvConversionAuto => 'Automatikus';
	@override String get dvConversionNative => 'Natív / letiltva';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Az eszköz képességeinek felismerése és szükség esetén a szokásos tartalék megoldás használata';
	@override String get dvConversionNativeDescription => 'A natív DV7 kényszerítése és a DV-átalakítási újrapróbálkozás letiltása';
	@override String get dvConversionDv81Description => 'A közvetlen RPU-átalakítás kényszerítése Dolby Vision Profile 8.1-re';
	@override String get dvConversionHevcStripDescription => 'A Dolby Vision RPU/EL-rétegek eltávolítása és egyszerű HEVC-ként való megjelenítés';
	@override String get requireProfileSelectionOnOpen => 'Profil kérése az alkalmazás megnyitásakor';
	@override String get requireProfileSelectionOnOpenDescription => 'Profilválasztó megjelenítése minden alkalommal, amikor az alkalmazást megnyitod';
	@override String get forceTvMode => 'TV-mód kényszerítése';
	@override String get forceTvModeDescription => 'TV-elrendezés kényszerítése az automatikus felismeréssel nem rendelkező eszközökön. Újraindítást igényel.';
	@override String get startInFullscreen => 'Indítás teljes képernyőn';
	@override String get startInFullscreenDescription => 'A Plezy megnyitása teljes képernyős módban indításkor';
	@override String get exitFullscreenOnPlayerClose => 'Kilépés a teljes képernyőből a lejátszó bezárásakor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Automatikus kilépés a teljes képernyőből a videólejátszó bezárásakor';
	@override String get autoHidePerformanceOverlay => 'Teljesítményadatok automatikus elrejtése';
	@override String get autoHidePerformanceOverlayDescription => 'A teljesítményadatok elhalványítása a lejátszásvezérlőkkel együtt';
	@override String get showNavBarLabels => 'Navigációs sáv címkéinek megjelenítése';
	@override String get showNavBarLabelsDescription => 'Szöveges címkék megjelenítése a navigációs sáv ikonjai alatt';
	@override String get startupSection => 'Indítási oldal';
	@override String get liveTvDefaultFavorites => 'Kedvenc csatornák alapértelmezés szerint';
	@override String get liveTvDefaultFavoritesDescription => 'Csak a kedvenc csatornák megjelenítése az Élő TV megnyitásakor';
	@override String get display => 'Kijelző';
	@override String get homeScreen => 'Kezdőképernyő';
	@override String get navigation => 'Navigáció';
	@override String get window => 'Ablak';
	@override String get content => 'Tartalom';
	@override String get player => 'Lejátszó';
	@override String get subtitlesAndConfig => 'Feliratok és konfiguráció';
	@override String get seekAndTiming => 'Tekerés és időzítés';
	@override String get behavior => 'Viselkedés';
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
	@override String get video => 'Videó';
	@override String get audio => 'Hang';
	@override String get subtitles => 'Feliratok';
	@override String get file => 'Fájl';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Felbontás';
	@override String get bitrate => 'Bitráta';
	@override String get frameRate => 'Képkockasebesség';
	@override String get aspectRatio => 'Méretarány';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bitmélység';
	@override String get colorSpace => 'Színtér';
	@override String get colorRange => 'Színtartomány';
	@override String get colorPrimaries => 'Elsődleges színek';
	@override String get chromaSubsampling => 'Krominancia-alulmintavételezés';
	@override String get channels => 'Csatornák';
	@override String get overallBitrate => 'Összesített bitráta';
	@override String get path => 'Elérési út';
	@override String get size => 'Méret';
	@override String get container => 'Konténer';
	@override String get duration => 'Időtartam';
	@override String get optimizedForStreaming => 'Adatfolyam-továbbításra optimalizálva';
	@override String get has64bitOffsets => '64 bites eltolások';
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
	@override String get deleteMultipleWarning => 'Ez magában foglalja az összes epizódot és azok fájljait.';
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
	@override String get resetToZero => 'Visszaállítás 0 ms-ra';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label}: későbbre állítva';
	@override String playsEarlier({required Object label}) => '${label}: korábbra állítva';
	@override String get noOffset => 'Nincs eltolás';
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
	@override String get longPressToUnlock => 'Nyomd hosszan a feloldáshoz';
	@override String get timelineSlider => 'Videó idősáv';
	@override String get volumeSlider => 'Hangerő';
	@override String endsAt({required Object time}) => 'Vége: ${time}';
	@override String get pipActive => 'Lejátszás kép a képben módban';
	@override String get pipFailed => 'Nem sikerült elindítani a kép a képben módot';
	@override String get screenshotSaved => 'Képernyőkép elmentve';
	@override String zoomPercent({required Object percent}) => 'Nagyítás ${percent}%';
	@override late final _Translations$videoControls$pipErrors$hu pipErrors = _Translations$videoControls$pipErrors$hu._(_root);
	@override String get chapters => 'Fejezetek';
	@override String get noChaptersAvailable => 'Nincsenek elérhető fejezetek';
	@override String get queue => 'Lejátszási sor';
	@override String get noQueueItems => 'Nincsenek elemek a sorban';
	@override String get searchSubtitles => 'Feliratok keresése';
	@override String get language => 'Nyelv';
	@override String get noSubtitlesFound => 'Nem találhatók feliratok';
	@override String get subtitleDownloaded => 'Felirat letöltve';
	@override String get subtitleDownloadedNotApplied => 'Felirat letöltve, de nem sikerült kiválasztani';
	@override String get subtitleDownloadFailed => 'Nem sikerült a felirat letöltése';
	@override String get searchLanguages => 'Nyelvek keresése...';
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
		one: '${n} megtekintett letöltés automatikusan eltávolítva',
		other: '${n} megtekintett letöltés automatikusan eltávolítva',
	);
	@override String get removedFromContinueWatching => 'Eltávolítva a folytatásból';
	@override String errorLoading({required Object error}) => 'Hiba: ${error}';
	@override String get streamInterrupted => 'Az adatfolyam megszakadt. Az újrapróbálkozáshoz indítsd el a lejátszást, vagy tekerj másik pozícióra.';
	@override String get liveStreamInterrupted => 'Az élő adás megszakadt. Nyomd meg a lejátszást az újrapróbálkozáshoz.';
	@override String get fileInfoNotAvailable => 'A fájlinformáció nem érhető el';
	@override String get playbackAuthenticationRequired => 'Az elem lejátszásához jelentkezz be újra a médiaszerverre.';
	@override String get playbackServerUnavailable => 'A médiaszerver nem érhető el. Próbáld újra később.';
	@override String get playbackDataInvalid => 'A szerver érvénytelen lejátszási adatokat küldött.';
	@override String get playbackCancelled => 'A lejátszás megszakítva.';
	@override String get playbackFailed => 'Nem sikerült elindítani a lejátszást.';
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
	@override String get logsUploaded => 'Naplók feltöltve';
	@override String get logsUploadFailed => 'Nem sikerült a naplók feltöltése';
	@override String get logId => 'Naplóazonosító';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$hu extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
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
	@override String get bold => 'Félkövér';
	@override String get italic => 'Dőlt';
	@override String get renderResolution => 'Renderelési felbontás';
	@override String get renderResolutionScreen => 'Képernyőfelbontás';
	@override String get renderResolutionVideo => 'Videófelbontás';
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
	@override String get addPlezyProfile => 'Plezy profil hozzáadása';
	@override String get switchingProfile => 'Profilváltás…';
	@override String get deleteThisProfileTitle => 'Törlöd ezt a profilt?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} eltávolítása. A kapcsolatokat nem érinti.';
	@override String get active => 'Aktív';
	@override String get manage => 'Kezelés';
	@override String get delete => 'Törlés';
	@override String get signOut => 'Kijelentkezés';
	@override String get signOutPlexTitle => 'Kijelentkezel a Plexből?';
	@override String signOutPlexMessage({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és az összes Plex Home-felhasználót? Bármikor visszajelentkezhetsz.';
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
	@override String get borrowEmptySubtitle => 'Először csatlakoztasd a Plexet vagy a Jellyfint egy másik profilhoz.';
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
}

// Path: connections
class _Translations$connections$hu extends Translations$connections$en {
	_Translations$connections$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Kapcsolatok';
	@override String get addConnection => 'Kapcsolat hozzáadása';
	@override String get addConnectionSubtitleNoProfile => 'Jelentkezz be Plexszel, vagy csatlakoztass egy Jellyfin-szervert';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Hozzáadás a következőhöz (${displayName}): Plex, Jellyfin vagy más profilkapcsolat';
	@override String sessionExpiredOne({required Object name}) => 'A(z) ${name} munkamenete lejárt';
	@override String sessionExpiredMany({required Object count}) => '${count} szerver munkamenete lejárt';
	@override String get signInAgain => 'Bejelentkezés újra';
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
	@override String get extras => 'Előzetesek és extrák';
	@override String get studio => 'Stúdió';
	@override String get rating => 'Értékelés';
	@override String get director => 'Rendező';
	@override String get directors => 'Rendezők';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-sorozat';
	@override String minutesLeft({required Object minutes}) => '${minutes} perc van hátra';
	@override String get moreLikeThis => 'Hasonló tartalmak';
}

// Path: errors
class _Translations$errors$hu extends Translations$errors$en {
	_Translations$errors$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Keresés sikertelen: ${error}';
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
}

// Path: libraries
class _Translations$libraries$hu extends Translations$libraries$en {
	_Translations$libraries$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$hu extends Translations$about$en {
	_Translations$about$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Névjegy';
	@override String get openSourceLicenses => 'Nyílt forráskódú licencek';
	@override String versionLabel({required Object version}) => 'Verzió: ${version}';
	@override String get appDescription => 'Gyönyörű Flutter-kliens a Plexhez és a Jellyfinhez';
	@override String get viewLicensesDescription => 'Külső fejlesztésű programkönyvtárak licenceinek megtekintése';
}

// Path: serverSelection
class _Translations$serverSelection$hu extends Translations$serverSelection$en {
	_Translations$serverSelection$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nem találhatók szerverek ehhez a fiókhoz: ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Nem sikerült a szerverek betöltése: ${error}';
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
	@override String get title => 'Böngészés';
	@override String get selectSource => 'Forrás kiválasztása';
	@override late final _Translations$explore$rows$hu rows = _Translations$explore$rows$hu._(_root);
	@override late final _Translations$explore$status$hu status = _Translations$explore$status$hu._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n,
		one: '${n} epizód',
		other: '${n} epizód',
	);
	@override String get cast => 'Szereplők';
	@override String get characters => 'Karakterek';
	@override String get addToWatchlist => 'Hozzáadás a Néznivalókhoz';
	@override String get removeFromWatchlist => 'Eltávolítás a Néznivalókból';
	@override String get watchlistUpdateFailed => 'Nem sikerült a Néznivalók frissítése';
	@override String get notInLibrary => 'Nincs a könyvtáradban';
	@override String get inTheseLibraries => 'Ezekben a könyvtárakban';
	@override String get checkingLibrary => 'Könyvtár ellenőrzése...';
	@override String get emptyTitle => 'Még nincs itt semmi';
	@override String emptyMessage({required Object source}) => 'A(z) ${source} forrásból származó sorok itt fognak megjelenni, amint van tartalmuk.';
	@override String searchHint({required Object source}) => 'Keresés itt: ${source}';
	@override String searchEmpty({required Object query}) => 'Nincs találat a következőre: "${query}"';
	@override String searchPrompt({required Object source}) => 'Filmek és sorozatok keresése a következőn: ${source}.';
	@override String get searchFailed => 'A keresés nem sikerült. Ellenőrizd a kapcsolatot és próbáld újra.';
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
	@override String get unknownHub => 'Ismeretlen';
	@override String get unknownError => 'Ismeretlen hiba';
	@override String channelNumber({required Object number}) => '${number}. csatorna';
	@override String get unknownChannel => 'Ismeretlen csatorna';
	@override String get live => 'ÉLŐ';
	@override String get reloadGuide => 'Műsorújság újratöltése';
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
	@override String get rulesProcessRequested => 'Szabályok újraértékelése kérve';
	@override String get recordShow => 'Műsor rögzítése';
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
	@override String itemCount({required Object count}) => '${count} elem';
	@override String get oneItem => '1 elem';
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
		one: '${n} zeneszám',
		other: '${n} zeneszám',
	);
	@override String get nowPlaying => 'Most szól';
	@override String playingFrom({required Object title}) => 'Lejátszás innen: ${title}';
	@override String get queue => 'Lejátszási sor';
	@override String get clearQueue => 'Sor törlése';
	@override String get lyrics => 'Dalszöveg';
	@override String get noLyrics => 'Nincs elérhető dalszöveg';
	@override String get sleepTimer => 'Elalvási időzítő';
	@override String get sleepTimerEndOfTrack => 'Zeneszám vége';
	@override String sleepTimerMinutes({required Object n}) => '${n} perc';
	@override String get stopPlayback => 'Lejátszás leállítása';
	@override String get previousTrack => 'Előző szám';
	@override String get nextTrack => 'Következő szám';
	@override String get repeat => 'Ismétlés';
	@override String get repeatAll => 'Összes ismétlése';
	@override String get repeatOne => 'Egy szám ismétlése';
}

// Path: watchTogether
class _Translations$watchTogether$hu extends Translations$watchTogether$en {
	_Translations$watchTogether$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Watch Together (Közös nézés)';
	@override String get description => 'Nézz tartalmat szinkronban barátaiddal és családoddal';
	@override String get createSession => 'Munkamenet létrehozása';
	@override String get creating => 'Létrehozás...';
	@override String get joinSession => 'Csatlakozás munkamenethez';
	@override String get joining => 'Csatlakozás...';
	@override String get controlMode => 'Vezérlési mód';
	@override String get controlModeQuestion => 'Ki vezérelheti a lejátszást?';
	@override String get hostOnly => 'Csak a házigazda';
	@override String get anyone => 'Bárki';
	@override String get hostingSession => 'Munkamenet indítása';
	@override String get inSession => 'Munkamenetben';
	@override String get sessionCode => 'Munkamenet kódja';
	@override String get openSessionControls => 'Watch Together munkamenet-vezérlők megnyitása';
	@override String get copySessionCode => 'Munkamenet-kód másolása';
	@override String get hostControlsPlayback => 'A házigazda vezérli a lejátszást';
	@override String get anyoneCanControl => 'Bárki vezérelheti a lejátszást';
	@override String get hostControls => 'A házigazda vezérel';
	@override String get anyoneControls => 'Bárki vezérelheti';
	@override String get participants => 'Résztvevők';
	@override String get host => 'Házigazda';
	@override String get hostBadge => 'HÁZIGAZDA';
	@override String get youAreHost => 'Te vagy a házigazda';
	@override String get watchingWithOthers => 'Nézés másokkal';
	@override String get endSession => 'Munkamenet befejezése';
	@override String get leaveSession => 'Munkamenet elhagyása';
	@override String get endSessionQuestion => 'Befejezed a munkamenetet?';
	@override String get leaveSessionQuestion => 'Elhagyod a munkamenetet?';
	@override String get endSessionConfirm => 'Ezzel minden résztvevő számára véget ér a munkamenet.';
	@override String get leaveSessionConfirm => 'Eltávolításra kerülsz a munkamenetből.';
	@override String get endSessionConfirmOverlay => 'Ezzel minden résztvevő számára véget ér a közös nézés.';
	@override String get leaveSessionConfirmOverlay => 'Kilépsz a közös nézésből.';
	@override String get end => 'Befejezés';
	@override String get leave => 'Kilépés';
	@override String get syncing => 'Szinkronizálás...';
	@override String get joinWatchSession => 'Csatlakozás közös nézéshez';
	@override String get enterCodeHint => 'Add meg az 5 karakteres kódot';
	@override String get pasteFromClipboard => 'Beillesztés a vágólapról';
	@override String get pleaseEnterCode => 'Adj meg egy munkamenetkódot';
	@override String get codeMustBe5Chars => 'A munkamenetkódnak 5 karakterből kell állnia';
	@override String get joinInstructions => 'Add meg a házigazda kódját a csatlakozáshoz.';
	@override String get failedToCreate => 'Nem sikerült a munkamenet létrehozása';
	@override String get failedToJoin => 'Nem sikerült csatlakozni a munkamenethez';
	@override String get sessionCodeCopied => 'A munkamenetkód a vágólapra másolva';
	@override String get relayUnreachable => 'A relészerver nem érhető el. Az internetszolgáltató blokkolása megakadályozhatja a közös nézést.';
	@override String get reconnectingToHost => 'Újracsatlakozás a házigazdához...';
	@override String get currentPlayback => 'Jelenlegi lejátszás';
	@override String get joinCurrentPlayback => 'Csatlakozás a jelenlegi lejátszáshoz';
	@override String get joinCurrentPlaybackDescription => 'Visszatérés ahhoz, amit a házigazda éppen néz';
	@override String get failedToOpenCurrentPlayback => 'Nem sikerült megnyitni a jelenlegi lejátszást';
	@override String participantJoined({required Object name}) => '${name} csatlakozott';
	@override String participantLeft({required Object name}) => '${name} kilépett';
	@override String participantPaused({required Object name}) => '${name} szüneteltette a lejátszást';
	@override String participantResumed({required Object name}) => '${name} folytatta a lejátszást';
	@override String participantSeeked({required Object name}) => '${name} módosította a lejátszási pozíciót';
	@override String participantBuffering({required Object name}) => '${name} pufferel';
	@override String participantNeedsUpdate({required Object name}) => '${name} régebbi alkalmazásverziót használ — a szinkronizálás nem érhető el';
	@override String resumingWithout({required Object name}) => 'Folytatás a következő nélkül: ${name}';
	@override String get waitingForParticipants => 'Várakozás, amíg a többieknél betöltődik a tartalom...';
	@override String waitingForName({required Object name}) => 'Várakozás: ${name}...';
	@override String get recentRooms => 'Legutóbbi szobák';
	@override String get renameRoom => 'Szoba átnevezése';
	@override String get removeRoom => 'Eltávolítás';
	@override String get guestSwitchUnavailable => 'Nem sikerült a váltás — a szerver nem érhető el szinkronizáláshoz';
	@override String get guestSwitchFailed => 'Nem sikerült a váltás — a tartalom nem található ezen a szerveren';
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
	@override String get storageFull => 'A letöltések leálltak, mert az eszköz tárhelye megtelt. Szabadíts fel helyet, majd próbáld újra.';
	@override String episodesQueued({required Object count}) => '${count} epizód letöltésre sorba állítva';
	@override String get downloadDeleted => 'Letöltés törölve';
	@override String deleteConfirm({required Object title}) => 'Törlöd a következőt: "${title}" erről az eszközről?';
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
	@override String get deleteAll => 'Összes törlése';
	@override String get selectVersion => 'Verzió kiválasztása';
	@override String get allEpisodes => 'Minden epizód';
	@override String get unwatchedOnly => 'Csak a nem látottak';
	@override String nextNUnwatched({required Object count}) => 'A következő ${count} nem látott epizód';
	@override String get customAmount => 'Egyéni mennyiség...';
	@override String get includeSpecials => 'Különkiadások is';
	@override String get howManyEpisodes => 'Hány epizód?';
	@override String get invalidEpisodeCount => 'Adj meg egy érvényes epizódszámot.';
	@override String get keepSynced => 'Szinkronban tartás';
	@override String get downloadOnce => 'Egyszeri letöltés';
	@override String keepNUnwatched({required Object count}) => '${count} nem látott epizód megtartása';
	@override String get editSyncRule => 'Szinkronizálási szabály szerkesztése';
	@override String get removeSyncRule => 'Szinkronizálási szabály eltávolítása';
	@override String removeSyncRuleConfirm({required Object title}) => 'Leállítod a(z) "${title}" szinkronizálását? A letöltött epizódok megmaradnak.';
	@override String syncRuleCreated({required Object count}) => 'Szinkronizálási szabály létrehozva — ${count} nem látott epizód megtartása';
	@override String get syncRuleUpdated => 'Szinkronizálási szabály frissítve';
	@override String get syncRuleRemoved => 'Szinkronizálási szabály eltávolítva';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} új epizód szinkronizálva a következőhöz: ${title}';
	@override String get activeSyncRules => 'Szinkronizálási szabályok';
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
	@override String get syncRuleNotAvailableForProfile => 'Nem érhető el a jelenlegi profilhoz';
	@override String get syncRuleUnknownServer => 'Ismeretlen szerver';
	@override String get syncRuleListCreated => 'Szinkronizálási szabály létrehozva';
	@override late final _Translations$downloads$backgroundWarning$hu backgroundWarning = _Translations$downloads$backgroundWarning$hu._(_root);
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
	@override String get audioOutput => 'Hangkimenet';
	@override String get performanceOverlay => 'Teljesítményadatok';
	@override String get audioPassthrough => 'Hangtovábbítás (passthrough)';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Térhatású';
	@override String get audioOutputSpatial => 'Térbeli hang';
	@override String get audioOutputStereo => 'Sztereó';
	@override String get audioNormalization => 'Hangerő normalizálása';
	@override String get audioDownmix => 'Lekeverés sztereóra';
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
	@override String get aspect => 'Méretarány';
	@override String get rotation => 'Forgatás';
	@override String get dvSource => 'DV-forrás';
	@override String get dvPath => 'DV-útvonal';
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
	@override String get memory => 'Memória';
	@override String get uiFps => 'Felület-FPS';
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
	@override String get style => 'Stílus';
	@override String get mood => 'Hangulat';
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
	@override String get disconnectConfirmBody => 'A Plezy nem küld több eseményt a Traktnak. Bármikor újracsatlakozhatsz.';
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
	@override String get noSignInMethods => 'Ez a Seerr példány nem kínál olyan bejelentkezési módot, amit a Plezy támogat.';
	@override String get instance => 'Példány';
	@override String get disconnectConfirm => 'Leválasztod a Seerr-kapcsolatot?';
	@override String get disconnectConfirmBody => 'A Plezy elfelejti ezt a Seerr példányt. Bármikor újracsatlakozhatsz.';
	@override String get request => 'Igénylés';
	@override String get request4k => 'Igénylés 4K-ban';
	@override String get seasons => 'Évadok';
	@override String get allSeasons => 'Minden évad';
	@override String get advancedOptions => 'Haladó';
	@override String get destinationServer => 'Célszerver';
	@override String get qualityProfile => 'Minőségi profil';
	@override String get rootFolder => 'Gyökérmappa';
	@override String get languageProfile => 'Nyelvi profil';
	@override String get requestSubmitted => 'Igénylés elküldve';
	@override String requestFailed({required Object error}) => 'Az igénylés nem sikerült: ${error}';
	@override String get requestsLoadFailed => 'Nem sikerült betölteni az igénylési opciókat';
	@override String get nothingToRequest => 'Minden elem már elérhető vagy igényelve van.';
	@override String get statusAvailable => 'Elérhető';
	@override String get statusPartiallyAvailable => 'Részben elérhető';
	@override String get statusRequested => 'Igényelve';
	@override String get statusProcessing => 'Feldolgozás alatt';
}

// Path: services
class _Translations$services$hu extends Translations$services$en {
	_Translations$services$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Szolgáltatások';
	@override String get hubSubtitle => 'Megtekintési haladás szinkronizálása és új tartalmak igénylése.';
	@override String get notConnected => 'Nincs csatlakoztatva';
	@override String connectedAs({required Object username}) => '@${username} néven csatlakoztatva';
	@override String get scrobble => 'Haladás automatikus követése';
	@override String get scrobbleDescription => 'Lista frissítése, amikor befejezel egy epizódot vagy filmet.';
	@override String disconnectConfirm({required Object service}) => 'Leválasztod a(z) ${service} szolgáltatást?';
	@override String disconnectConfirmBody({required Object service}) => 'A Plezy nem frissíti többé a(z) ${service} adatait. Bármikor újracsatlakozhatsz.';
	@override String connectFailed({required Object service}) => 'Nem sikerült csatlakozni a következőhöz: ${service}. Próbáld újra.';
	@override late final _Translations$services$names$hu names = _Translations$services$names$hu._(_root);
	@override late final _Translations$services$deviceCode$hu deviceCode = _Translations$services$deviceCode$hu._(_root);
	@override late final _Translations$services$oauthProxy$hu oauthProxy = _Translations$services$oauthProxy$hu._(_root);
	@override late final _Translations$services$libraryFilter$hu libraryFilter = _Translations$services$libraryFilter$hu._(_root);
}

// Path: addServer
class _Translations$addServer$hu extends Translations$addServer$en {
	_Translations$addServer$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get serverUrls => 'Szerver URL-címei';
	@override String get serverUrlsHelper => 'Több URL is megadható, vesszővel elválasztva.';
	@override String get findServer => 'Szerver keresése';
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
	@override String get addConnectionTitle => 'Kapcsolat hozzáadása';
	@override String addConnectionTitleScoped({required Object name}) => 'Hozzáadás a következőhöz: ${name}';
	@override String get signInWithPlexCard => 'Bejelentkezés Plexszel';
	@override String get signInWithPlexCardSubtitle => 'Eszköz engedélyezése. A megosztott szerverek hozzáadásra kerülnek.';
	@override String get signInWithPlexCardSubtitleScoped => 'Plex-fiók engedélyezése. A Plex Home-felhasználókból profilok lesznek.';
	@override String get borrowFromAnotherProfile => 'Kapcsolat használata másik profilból';
	@override String get borrowFromAnotherProfileSubtitle => 'Egy másik profil kapcsolatának használata. A PIN-kóddal védett profilokhoz PIN-kód szükséges.';
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
	@override String get shaderToggle => 'Shaderek be- és kikapcsolása';
	@override String get skipMarker => 'Intró/stáblista átugrása';
	@override String get screenshot => 'Képernyőkép készítése';
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
	@override String unknown({required Object error}) => 'Hiba történt: ${error}';
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
	@override String get sheetIntro => 'Az Android megakadályozza, hogy a Plezy megbízhatóan töltsön le a háttérben.';
	@override String get sheetIntroDegraded => 'Az eszközöd korlátozza, hogy a Plezy mikor tölthet le a háttérben.';
	@override String get reasonBackgroundRestricted => 'A Plezy háttérbeli használata korlátozva van. Állítsd az akkumulátor- vagy háttérhasználatát „Korlátlan” értékre.';
	@override String get reasonStandbyRestricted => 'Az Android korlátozott készenléti állapotba helyezte a Plezyt. Állítsd az akkumulátorhasználatát „Korlátlan” értékre.';
	@override String get reasonDownloadChannelBlocked => 'A letöltési értesítések ki vannak kapcsolva, ezért előfordulhat, hogy a folyamatjelzés és a vezérlők nem érhetők el.';
	@override String get reasonNotificationsDisabled => 'Az értesítések ki vannak kapcsolva. Android 13 vagy újabb rendszeren szükségesek a hosszú háttérbeli letöltésekhez.';
	@override String get reasonDataSaver => 'Az Adatforgalom-csökkentő be van kapcsolva, ezért mobiladat-kapcsolaton nem működnek a háttérbeli letöltések. Wi-Fi-n továbbra is működniük kell.';
	@override String get reasonOemUnknown => 'A letöltések többször leálltak, miközben a Plezy a háttérben futott. Ellenőrizd a Plezy akkumulátor- vagy háttérhasználati beállításait.';
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
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$hu extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Az azonos Plex-fiókot használó Plezy-eszközök itt jelennek meg';
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
	@override String get sessionNotFound => 'Az eszköz nem található. Győződj meg arról, hogy a Plezy fut a gazdagépen.';
	@override String get authFailed => 'A hitelesítés nem sikerült. Mindkét eszközön ugyanazt a Plex-fiókot kell használni.';
	@override String failedToConnect({required Object error}) => 'Nem sikerült a csatlakozás: ${error}';
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
}

// Path: services.deviceCode
class _Translations$services$deviceCode$hu extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$hu._(TranslationsHu root) : this._root = root, super.internal(root);

	final TranslationsHu _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy aktiválása a következőn: ${service}';
	@override String body({required Object url}) => 'Nyisd meg a(z) ${url} oldalt és add meg ezt a kódot:';
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
}

/// The flat map containing all translations for locale <hu>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Bejelentkezés Plexszel',
			'auth.showQRCode' => 'QR-kód megjelenítése',
			'auth.authenticate' => 'Hitelesítés',
			'auth.authenticationTimeout' => 'A hitelesítés időtúllépés miatt megszakadt. Próbáld újra.',
			'auth.scanQRToSignIn' => 'Olvasd be ezt a QR-kódot a bejelentkezéshez',
			'auth.waitingForAuth' => 'Várakozás a hitelesítésre...\nJelentkezz be a böngésződben.',
			'auth.useBrowser' => 'Böngésző használata',
			'auth.or' => 'vagy',
			'auth.useQuickConnect' => 'Quick Connect használata',
			'auth.quickConnectInstructions' => 'Nyisd meg a Quick Connect-et a Jellyfinben, és add meg ezt a kódot.',
			'auth.quickConnectWaiting' => 'Várakozás a jóváhagyásra…',
			'auth.quickConnectCancel' => 'Mégse',
			'auth.quickConnectExpired' => 'A Quick Connect kód lejárt. Próbáld újra.',
			'auth.localDataRecoveryRequired' => 'A Plezy nem tudta biztonságosan helyreállítani a helyi bejelentkezés és a függőben lévő lejátszás adatait. Jelentkezz be újra.',
			'common.cancel' => 'Mégse',
			'common.save' => 'Mentés',
			'common.close' => 'Bezárás',
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
			'settings.supportDeveloper' => 'Plezy támogatása',
			'settings.supportDeveloperDescription' => 'A fejlesztés támogatása Liberapay-en keresztül',
			'settings.language' => 'Nyelv',
			'settings.theme' => 'Téma',
			'settings.appearance' => 'Megjelenés',
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
			'settings.libraryDensity' => 'Könyvtársűrűség',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Kényelmes',
			'settings.tvCornerSpotlightBackdrop' => 'Sarokban megjelenő kiemelt háttérkép',
			'settings.tvCornerSpotlightBackdropDescription' => 'A kiemelt háttérkép megjelenítése a jobb felső sarokban a teljes képernyő helyett',
			'settings.viewMode' => 'Nézetmód',
			'settings.gridView' => 'Rács',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Kiemelt sáv megjelenítése',
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
			'settings.bufferSize' => 'Puffer mérete',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} MB',
			'settings.bufferSizeAuto' => 'Automatikus (ajánlott)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap} MB memória érhető el. A(z) ${size} MB méretű puffer befolyásolhatja a lejátszást.',
			'settings.defaultQualityTitle' => 'Alapértelmezett minőség',
			'settings.musicQualityTitle' => 'Zene minősége',
			'settings.subtitleStyling' => 'Feliratok stílusa',
			'settings.subtitleStylingDescription' => 'Feliratok megjelenésének testreszabása',
			'settings.smallSkipDuration' => 'Kis ugrás időtartama',
			'settings.largeSkipDuration' => 'Nagy ugrás időtartama',
			'settings.rewindOnResume' => 'Visszatekerés folytatáskor',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} másodperc',
			'settings.defaultSleepTimer' => 'Alapértelmezett elalvási időzítő',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} perc',
			'settings.rememberTrackSelections' => 'Sávválasztások megjegyzése sorozatonként/filmenként',
			'settings.rememberTrackSelectionsDescription' => 'Hang- és feliratválasztások megjegyzése címenként',
			'settings.followServerTrackSelections' => 'A szerver epizódonkénti sávválasztásának használata',
			'settings.followServerTrackSelectionsDescription' => 'Epizódváltáskor a szerveren kiválasztott hang és felirat lép életbe az aktuális választás átvitele helyett',
			'settings.showChapterMarkersOnTimeline' => 'Fejezetjelölők megjelenítése az idősávon',
			'settings.showChapterMarkersOnTimelineDescription' => 'Az idősáv felosztása a fejezetek határainál',
			'settings.clickVideoTogglesPlayback' => 'Kattintás a videóra a lejátszás/szünet váltásához',
			'settings.clickVideoTogglesPlaybackDescription' => 'A videóra kattintva vált a lejátszás/szünet, a vezérlők megjelenítése helyett.',
			'settings.videoPlayerControls' => 'Videólejátszó vezérlői',
			'settings.keyboardShortcuts' => 'Billentyűparancsok',
			'settings.keyboardShortcutsDescription' => 'Billentyűparancsok testreszabása',
			'settings.videoPlayerNavigation' => 'Videólejátszó-navigáció',
			'settings.videoPlayerNavigationDescription' => 'A nyílbillentyűk használata a videólejátszó vezérlői közötti navigáláshoz',
			'settings.watchTogetherRelay' => 'Watch Together-relé',
			'settings.watchTogetherRelayDescription' => 'Egyéni relé beállítása. Mindenkinek ugyanazt a szervert kell használnia.',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Adj meg egy érvényes HTTP- vagy HTTPS-alapú relészerver-URL-t.',
			'settings.crashReporting' => 'Összeomlási jelentések',
			'settings.crashReportingDescription' => 'Összeomlási jelentések küldése az alkalmazás fejlesztésének elősegítéséhez',
			'settings.debugLogging' => 'Hibakeresési naplózás',
			'settings.debugLoggingDescription' => 'Részletes naplózás engedélyezése a hibaelhárításhoz',
			'settings.viewLogs' => 'Naplók megtekintése',
			'settings.viewLogsDescription' => 'Alkalmazásnaplók megtekintése',
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
			'settings.importSettingsInvalidFile' => 'Ez a fájl nem érvényes Plezy-beállításexport',
			'settings.importSettingsNoUser' => 'Jelentkezz be a beállítások importálása előtt',
			'settings.shortcutsReset' => 'A billentyűparancsok visszaálltak az alapértelmezettekre',
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
			'settings.autoSkip' => 'Automatikus átugrás',
			'settings.autoSkipIntro' => 'Intró automatikus átugrása',
			'settings.autoSkipIntroDescription' => 'Az intrójelölők automatikus átugrása néhány másodperc után',
			'settings.autoSkipCredits' => 'Stáblista automatikus átugrása',
			'settings.autoSkipCreditsDescription' => 'A stáblista automatikus átugrása és a következő epizód lejátszása',
			'settings.forceSkipMarkerFallback' => 'Tartalék jelölők kényszerítése',
			'settings.forceSkipMarkerFallbackDescription' => 'Fejezetcím-minták használata akkor is, ha a Plex rendelkezik jelölőkkel',
			'settings.autoSkipDelay' => 'Automatikus átugrás késleltetése',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Várakozás ${seconds} másodpercig az automatikus átugrás előtt',
			'settings.introPattern' => 'Intrójelölő mintája',
			'settings.introPatternDescription' => 'Reguláris kifejezés az intrójelölők illesztéséhez a fejezetcímekben',
			'settings.creditsPattern' => 'Stáblistajelölő mintája',
			'settings.creditsPatternDescription' => 'Reguláris kifejezés a stáblistajelölők illesztéséhez a fejezetcímekben',
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
			'settings.autoPip' => 'Automatikus kép a képben (PiP)',
			'settings.autoPipDescription' => 'Lejátszás közben az alkalmazás elhagyásakor automatikusan kép a képben módra vált',
			'settings.matchContentFrameRate' => 'Képkockasebesség illesztése a tartalomhoz',
			'settings.matchContentFrameRateDescription' => 'A kijelző frissítési frekvenciájának igazítása a videóhoz',
			'settings.matchRefreshRate' => 'Frissítési frekvencia illesztése',
			'settings.matchRefreshRateDescription' => 'A kijelző frissítési frekvenciájának igazítása teljes képernyőn',
			'settings.matchDynamicRange' => 'Dinamikatartomány illesztése',
			'settings.matchDynamicRangeDescription' => 'HDR bekapcsolása HDR-tartalmak esetén, majd visszaváltás SDR-re',
			'settings.displaySwitchDelay' => 'Kijelzőváltási késleltetés',
			'settings.tunneledPlayback' => 'Alagutas lejátszás',
			'settings.tunneledPlaybackDescription' => 'Videóalagút használata. Tiltsd le, ha HDR-lejátszáskor fekete a kép.',
			'settings.audioPassthrough' => 'Hangtovábbítás (passthrough)',
			'settings.audioPassthroughDescription' => 'Dolby/DTS-hang továbbítása az erősítőre vagy a TV-re újrakódolás nélkül, a térhangzás megőrzésével. Kapcsold ki, ha nincs hang.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Az Apple natív Dolby-dekóderének használata Dolby Digital Plushoz, az Atmost is beleértve. A DTS és a TrueHD továbbra is többcsatornás PCM-ként szól. Kapcsold ki, ha nincs hang.',
			'settings.audioDownmix' => 'Lekeverés sztereóra',
			'settings.audioDownmixDescription' => 'A térhangzás lekeverése két csatornára sztereó hangszórókhoz vagy fejhallgatókhoz',
			'settings.downmixCenterBoost' => 'Középső csatorna kiemelése',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Kiemelés (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Hangerő normalizálása lekeveréskor',
			'settings.audioDownmixNormalizeDescription' => 'A keverés szintjének csökkentése a torzítás elkerülésére. Kapcsold ki az eredeti hangerő megőrzéséhez (a hangos jelenetek torzíthatnak).',
			'settings.atmosDiagnostics' => 'Atmos kimeneti teszt',
			'settings.atmosDiagnosticsDescription' => 'Dolby Atmos kimenet diagnosztizálása tesztjelek lejátszásával a rendszerlejátszón keresztül',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos folyam',
			'settings.atmosTestHlsAtmosDescription' => 'Igazoltan működő Dolby Atmos-adatfolyam. Az erősítő kijelzőjén a Dolby Atmos formátumnak kell megjelennie.',
			'settings.atmosTestHlsControl' => 'Apple térhangzású folyam',
			'settings.atmosTestHlsControlDescription' => 'Atmos nélküli ellenőrző adatfolyam. Az erősítő kijelzőjén térhangzásnak kell megjelennie, Atmos nélkül.',
			'settings.atmosTestRawStream' => 'Nyers EAC3 folyam',
			'settings.atmosTestRawStreamDescription' => 'A tesztfájlt pontosan úgy közvetíti, mint a lejátszón belüli Atmos lejátszás. Szükséges a tesztfájl URL-je.',
			'settings.atmosTestRawFile' => 'Nyers EAC3 fájl',
			'settings.atmosTestRawFileDescription' => 'Ismert hosszúságú tesztfájlt játszik le. Szükséges a tesztfájl URL-je.',
			'settings.atmosTestAsbarNative' => 'Mintapuffer-megjelenítő (natív)',
			'settings.atmosTestAsbarNativeDescription' => 'A fájl érintetlen tömörített hangját közvetlenül a rendszer megjelenítőjének adja. Szükséges a tesztfájl URL-je.',
			'settings.atmosTestAsbarGenerated' => 'Mintapuffer-megjelenítő (újraépített)',
			'settings.atmosTestAsbarGeneratedDescription' => 'Ugyanaz, de a lejátszás módján felépített hangleírással. Szükséges a tesztfájl URL-je.',
			'settings.atmosTestSessionMode' => 'Filmlejátszási mód használata',
			'settings.atmosTestSessionModeDescription' => 'Kikapcsolva a Dolby által dokumentált módot használja. Bekapcsolva a korábbi módot.',
			'settings.atmosTestShowRoutePicker' => 'AirPlay kimenet választása',
			'settings.atmosTestHideRoutePicker' => 'AirPlay kimenetválasztó elrejtése',
			'settings.atmosTestRoutePickerDescription' => 'Elküldi a tesztet egy AirPlay vevőnek. Csak az AirPlay jelzi a feloldott hangmódot.',
			'settings.atmosTestStop' => 'Teszt leállítása',
			'settings.atmosTestUrl' => 'Tesztfájl URL-je',
			'settings.atmosTestUrlDescription' => 'Nyers .ec3 Dolby Atmos fájl HTTP URL-je (pl. ffmpeg-gel kinyerve)',
			'settings.atmosTestUrlMissing' => 'Először állítsd be a tesztfájl URL-jét',
			'settings.atmosTestStatus' => 'Állapot',
			'settings.dvConversionMode' => 'Dolby Vision-átalakítás',
			'settings.dvConversionModeDescription' => 'Válaszd ki, hogyan kezelje az ExoPlayer a Dolby Vision Profile 7 fájlokat.',
			'settings.dvConversionAuto' => 'Automatikus',
			'settings.dvConversionNative' => 'Natív / letiltva',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Az eszköz képességeinek felismerése és szükség esetén a szokásos tartalék megoldás használata',
			'settings.dvConversionNativeDescription' => 'A natív DV7 kényszerítése és a DV-átalakítási újrapróbálkozás letiltása',
			'settings.dvConversionDv81Description' => 'A közvetlen RPU-átalakítás kényszerítése Dolby Vision Profile 8.1-re',
			'settings.dvConversionHevcStripDescription' => 'A Dolby Vision RPU/EL-rétegek eltávolítása és egyszerű HEVC-ként való megjelenítés',
			'settings.requireProfileSelectionOnOpen' => 'Profil kérése az alkalmazás megnyitásakor',
			'settings.requireProfileSelectionOnOpenDescription' => 'Profilválasztó megjelenítése minden alkalommal, amikor az alkalmazást megnyitod',
			'settings.forceTvMode' => 'TV-mód kényszerítése',
			'settings.forceTvModeDescription' => 'TV-elrendezés kényszerítése az automatikus felismeréssel nem rendelkező eszközökön. Újraindítást igényel.',
			'settings.startInFullscreen' => 'Indítás teljes képernyőn',
			'settings.startInFullscreenDescription' => 'A Plezy megnyitása teljes képernyős módban indításkor',
			'settings.exitFullscreenOnPlayerClose' => 'Kilépés a teljes képernyőből a lejátszó bezárásakor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automatikus kilépés a teljes képernyőből a videólejátszó bezárásakor',
			'settings.autoHidePerformanceOverlay' => 'Teljesítményadatok automatikus elrejtése',
			'settings.autoHidePerformanceOverlayDescription' => 'A teljesítményadatok elhalványítása a lejátszásvezérlőkkel együtt',
			'settings.showNavBarLabels' => 'Navigációs sáv címkéinek megjelenítése',
			'settings.showNavBarLabelsDescription' => 'Szöveges címkék megjelenítése a navigációs sáv ikonjai alatt',
			'settings.startupSection' => 'Indítási oldal',
			'settings.liveTvDefaultFavorites' => 'Kedvenc csatornák alapértelmezés szerint',
			'settings.liveTvDefaultFavoritesDescription' => 'Csak a kedvenc csatornák megjelenítése az Élő TV megnyitásakor',
			'settings.display' => 'Kijelző',
			'settings.homeScreen' => 'Kezdőképernyő',
			'settings.navigation' => 'Navigáció',
			'settings.window' => 'Ablak',
			'settings.content' => 'Tartalom',
			'settings.player' => 'Lejátszó',
			'settings.subtitlesAndConfig' => 'Feliratok és konfiguráció',
			'settings.seekAndTiming' => 'Tekerés és időzítés',
			'settings.behavior' => 'Viselkedés',
			'search.hint' => 'Keresés filmek, sorozatok és zenék között...',
			'search.tryDifferentTerm' => 'Próbálj másik keresési kifejezést',
			'search.searchYourMedia' => 'Keresés a saját médiatartalmak között',
			'search.enterTitleActorOrKeyword' => 'Adj meg egy címet, színészt vagy kulcsszót',
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
			'hotkeys.actions.shaderToggle' => 'Shaderek be- és kikapcsolása',
			'hotkeys.actions.skipMarker' => 'Intró/stáblista átugrása',
			'hotkeys.actions.screenshot' => 'Képernyőkép készítése',
			'fileInfo.title' => 'Fájlinformáció',
			'fileInfo.video' => 'Videó',
			'fileInfo.audio' => 'Hang',
			'fileInfo.subtitles' => 'Feliratok',
			'fileInfo.file' => 'Fájl',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.resolution' => 'Felbontás',
			'fileInfo.bitrate' => 'Bitráta',
			'fileInfo.frameRate' => 'Képkockasebesség',
			'fileInfo.aspectRatio' => 'Méretarány',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Bitmélység',
			'fileInfo.colorSpace' => 'Színtér',
			'fileInfo.colorRange' => 'Színtartomány',
			'fileInfo.colorPrimaries' => 'Elsődleges színek',
			'fileInfo.chromaSubsampling' => 'Krominancia-alulmintavételezés',
			'fileInfo.channels' => 'Csatornák',
			'fileInfo.overallBitrate' => 'Összesített bitráta',
			'fileInfo.path' => 'Elérési út',
			'fileInfo.size' => 'Méret',
			'fileInfo.container' => 'Konténer',
			'fileInfo.duration' => 'Időtartam',
			'fileInfo.optimizedForStreaming' => 'Adatfolyam-továbbításra optimalizálva',
			'fileInfo.has64bitOffsets' => '64 bites eltolások',
			'mediaMenu.markAsWatched' => 'Megjelölés megtekintettként',
			'mediaMenu.markAsUnwatched' => 'Megjelölés nem megtekintettként',
			'mediaMenu.removeFromContinueWatching' => 'Eltávolítás a folytatásból',
			'mediaMenu.viewDetails' => 'Részletek megtekintése',
			'mediaMenu.goToSeries' => 'Ugrás a sorozathoz',
			'mediaMenu.shufflePlay' => 'Véletlenszerű lejátszás',
			'mediaMenu.shuffleNotAvailableOffline' => 'A véletlenszerű lejátszás nem érhető el offline',
			'mediaMenu.fileInfo' => 'Fájlinformáció',
			'mediaMenu.deleteMultipleWarning' => 'Ez magában foglalja az összes epizódot és azok fájljait.',
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
			'tooltips.shufflePlay' => 'Véletlenszerű lejátszás',
			'tooltips.playTrailer' => 'Előzetes lejátszása',
			'tooltips.markAsWatched' => 'Megjelölés megtekintettként',
			'tooltips.markAsUnwatched' => 'Megjelölés nem megtekintettként',
			'audioTracks.track' => ({required Object n}) => '${n}. hangsáv',
			'videoControls.audioLabel' => 'Hang',
			'videoControls.subtitlesLabel' => 'Feliratok',
			'videoControls.resetToZero' => 'Visszaállítás 0 ms-ra',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label}: későbbre állítva',
			'videoControls.playsEarlier' => ({required Object label}) => '${label}: korábbra állítva',
			'videoControls.noOffset' => 'Nincs eltolás',
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
			'videoControls.longPressToUnlock' => 'Nyomd hosszan a feloldáshoz',
			'videoControls.timelineSlider' => 'Videó idősáv',
			'videoControls.volumeSlider' => 'Hangerő',
			'videoControls.endsAt' => ({required Object time}) => 'Vége: ${time}',
			'videoControls.pipActive' => 'Lejátszás kép a képben módban',
			'videoControls.pipFailed' => 'Nem sikerült elindítani a kép a képben módot',
			'videoControls.screenshotSaved' => 'Képernyőkép elmentve',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Nagyítás ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Android 8.0 vagy újabb szükséges',
			'videoControls.pipErrors.iosVersion' => 'iOS 15.0 vagy újabb szükséges',
			'videoControls.pipErrors.permissionDisabled' => 'A kép a képben mód le van tiltva. Engedélyezd a rendszerbeállításokban.',
			'videoControls.pipErrors.notSupported' => 'Az eszköz nem támogatja a kép a képben módot',
			'videoControls.pipErrors.voSwitchFailed' => 'Nem sikerült átváltani a videókimenetet a kép a képben módhoz',
			'videoControls.pipErrors.failed' => 'Nem sikerült elindítani a kép a képben módot',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Hiba történt: ${error}',
			'videoControls.chapters' => 'Fejezetek',
			'videoControls.noChaptersAvailable' => 'Nincsenek elérhető fejezetek',
			'videoControls.queue' => 'Lejátszási sor',
			'videoControls.noQueueItems' => 'Nincsenek elemek a sorban',
			'videoControls.searchSubtitles' => 'Feliratok keresése',
			'videoControls.language' => 'Nyelv',
			'videoControls.noSubtitlesFound' => 'Nem találhatók feliratok',
			'videoControls.subtitleDownloaded' => 'Felirat letöltve',
			'videoControls.subtitleDownloadedNotApplied' => 'Felirat letöltve, de nem sikerült kiválasztani',
			'videoControls.subtitleDownloadFailed' => 'Nem sikerült a felirat letöltése',
			_ => null,
		} ?? switch (path) {
			'videoControls.searchLanguages' => 'Nyelvek keresése...',
			'messages.markedAsWatched' => 'Megjelölve megtekintettként',
			'messages.markedAsUnwatched' => 'Megjelölve nem megtekintettként',
			'messages.markedAsWatchedOffline' => 'Megjelölve megtekintettként (szinkronizálás online állapotban)',
			'messages.markedAsUnwatchedOffline' => 'Megjelölve nem megtekintettként (szinkronizálás online állapotban)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatikusan eltávolítva: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${n} megtekintett letöltés automatikusan eltávolítva', other: '${n} megtekintett letöltés automatikusan eltávolítva', ), 
			'messages.removedFromContinueWatching' => 'Eltávolítva a folytatásból',
			'messages.errorLoading' => ({required Object error}) => 'Hiba: ${error}',
			'messages.streamInterrupted' => 'Az adatfolyam megszakadt. Az újrapróbálkozáshoz indítsd el a lejátszást, vagy tekerj másik pozícióra.',
			'messages.liveStreamInterrupted' => 'Az élő adás megszakadt. Nyomd meg a lejátszást az újrapróbálkozáshoz.',
			'messages.fileInfoNotAvailable' => 'A fájlinformáció nem érhető el',
			'messages.playbackAuthenticationRequired' => 'Az elem lejátszásához jelentkezz be újra a médiaszerverre.',
			'messages.playbackServerUnavailable' => 'A médiaszerver nem érhető el. Próbáld újra később.',
			'messages.playbackDataInvalid' => 'A szerver érvénytelen lejátszási adatokat küldött.',
			'messages.playbackCancelled' => 'A lejátszás megszakítva.',
			'messages.playbackFailed' => 'Nem sikerült elindítani a lejátszást.',
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
			'messages.logsUploaded' => 'Naplók feltöltve',
			'messages.logsUploadFailed' => 'Nem sikerült a naplók feltöltése',
			'messages.logId' => 'Naplóazonosító',
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
			'subtitlingStyling.bold' => 'Félkövér',
			'subtitlingStyling.italic' => 'Dőlt',
			'subtitlingStyling.renderResolution' => 'Renderelési felbontás',
			'subtitlingStyling.renderResolutionScreen' => 'Képernyőfelbontás',
			'subtitlingStyling.renderResolutionVideo' => 'Videófelbontás',
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
			'dialog.confirmAction' => 'Művelet megerősítése',
			'profiles.addPlezyProfile' => 'Plezy profil hozzáadása',
			'profiles.switchingProfile' => 'Profilváltás…',
			'profiles.deleteThisProfileTitle' => 'Törlöd ezt a profilt?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} eltávolítása. A kapcsolatokat nem érinti.',
			'profiles.active' => 'Aktív',
			'profiles.manage' => 'Kezelés',
			'profiles.delete' => 'Törlés',
			'profiles.signOut' => 'Kijelentkezés',
			'profiles.signOutPlexTitle' => 'Kijelentkezel a Plexből?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Eltávolítod a(z) ${displayName} profilt és az összes Plex Home-felhasználót? Bármikor visszajelentkezhetsz.',
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
			'profiles.borrowEmptySubtitle' => 'Először csatlakoztasd a Plexet vagy a Jellyfint egy másik profilhoz.',
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
			'connections.sectionTitle' => 'Kapcsolatok',
			'connections.addConnection' => 'Kapcsolat hozzáadása',
			'connections.addConnectionSubtitleNoProfile' => 'Jelentkezz be Plexszel, vagy csatlakoztass egy Jellyfin-szervert',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Hozzáadás a következőhöz (${displayName}): Plex, Jellyfin vagy más profilkapcsolat',
			'connections.sessionExpiredOne' => ({required Object name}) => 'A(z) ${name} munkamenete lejárt',
			'connections.sessionExpiredMany' => ({required Object count}) => '${count} szerver munkamenete lejárt',
			'connections.signInAgain' => 'Bejelentkezés újra',
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
			'discover.extras' => 'Előzetesek és extrák',
			'discover.studio' => 'Stúdió',
			'discover.rating' => 'Értékelés',
			'discover.director' => 'Rendező',
			'discover.directors' => 'Rendezők',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-sorozat',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} perc van hátra',
			'discover.moreLikeThis' => 'Hasonló tartalmak',
			'errors.searchFailed' => ({required Object error}) => 'Keresés sikertelen: ${error}',
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
			'about.title' => 'Névjegy',
			'about.openSourceLicenses' => 'Nyílt forráskódú licencek',
			'about.versionLabel' => ({required Object version}) => 'Verzió: ${version}',
			'about.appDescription' => 'Gyönyörű Flutter-kliens a Plexhez és a Jellyfinhez',
			'about.viewLicensesDescription' => 'Külső fejlesztésű programkönyvtárak licenceinek megtekintése',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nem találhatók szerverek ehhez a fiókhoz: ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Nem sikerült a szerverek betöltése: ${error}',
			'hubDetail.title' => 'Cím',
			'hubDetail.releaseYear' => 'Kiadási év',
			'hubDetail.dateAdded' => 'Hozzáadás dátuma',
			'hubDetail.rating' => 'Értékelés',
			'hubDetail.noItemsFound' => 'Nem találhatók elemek',
			'logs.clearLogs' => 'Naplók törlése',
			'logs.copyLogs' => 'Naplók másolása',
			'logs.uploadLogs' => 'Naplók feltöltése',
			'licenses.relatedPackages' => 'Kapcsolódó csomagok',
			'licenses.license' => 'Licenc',
			'licenses.licenseNumber' => ({required Object number}) => '${number}. licenc',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenc',
			'navigation.libraries' => 'Könyvtárak',
			'navigation.downloads' => 'Letöltések',
			'navigation.liveTv' => 'Élő TV',
			'navigation.explore' => 'Böngészés',
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${n} epizód', other: '${n} epizód', ), 
			'explore.cast' => 'Szereplők',
			'explore.characters' => 'Karakterek',
			'explore.addToWatchlist' => 'Hozzáadás a Néznivalókhoz',
			'explore.removeFromWatchlist' => 'Eltávolítás a Néznivalókból',
			'explore.watchlistUpdateFailed' => 'Nem sikerült a Néznivalók frissítése',
			'explore.notInLibrary' => 'Nincs a könyvtáradban',
			'explore.inTheseLibraries' => 'Ezekben a könyvtárakban',
			'explore.checkingLibrary' => 'Könyvtár ellenőrzése...',
			'explore.emptyTitle' => 'Még nincs itt semmi',
			'explore.emptyMessage' => ({required Object source}) => 'A(z) ${source} forrásból származó sorok itt fognak megjelenni, amint van tartalmuk.',
			'explore.searchHint' => ({required Object source}) => 'Keresés itt: ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nincs találat a következőre: "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Filmek és sorozatok keresése a következőn: ${source}.',
			'explore.searchFailed' => 'A keresés nem sikerült. Ellenőrizd a kapcsolatot és próbáld újra.',
			'liveTv.title' => 'Élő TV',
			'liveTv.guide' => 'Műsorújság',
			'liveTv.noChannels' => 'Nincsenek elérhető csatornák',
			'liveTv.noDvr' => 'Egyik szerveren sincs beállítva DVR',
			'liveTv.serverUnavailable' => 'Az Élő TV szerver nem érhető el.',
			'liveTv.serverNotConnected' => 'Az Élő TV szerver nincs csatlakoztatva.',
			'liveTv.noPrograms' => 'Nincsenek elérhető műsoradatok',
			'liveTv.liveStreamFailed' => 'Nem sikerült elindítani az élő adást',
			'liveTv.unknownProgram' => 'Ismeretlen műsor',
			'liveTv.unknownHub' => 'Ismeretlen',
			'liveTv.unknownError' => 'Ismeretlen hiba',
			'liveTv.channelNumber' => ({required Object number}) => '${number}. csatorna',
			'liveTv.unknownChannel' => 'Ismeretlen csatorna',
			'liveTv.live' => 'ÉLŐ',
			'liveTv.reloadGuide' => 'Műsorújság újratöltése',
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
			'liveTv.rulesProcessRequested' => 'Szabályok újraértékelése kérve',
			'liveTv.recordShow' => 'Műsor rögzítése',
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
			'playlists.itemCount' => ({required Object count}) => '${count} elem',
			'playlists.oneItem' => '1 elem',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('hu'))(n, one: '${n} zeneszám', other: '${n} zeneszám', ), 
			'music.nowPlaying' => 'Most szól',
			'music.playingFrom' => ({required Object title}) => 'Lejátszás innen: ${title}',
			'music.queue' => 'Lejátszási sor',
			'music.clearQueue' => 'Sor törlése',
			'music.lyrics' => 'Dalszöveg',
			'music.noLyrics' => 'Nincs elérhető dalszöveg',
			'music.sleepTimer' => 'Elalvási időzítő',
			'music.sleepTimerEndOfTrack' => 'Zeneszám vége',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} perc',
			'music.stopPlayback' => 'Lejátszás leállítása',
			'music.previousTrack' => 'Előző szám',
			'music.nextTrack' => 'Következő szám',
			'music.repeat' => 'Ismétlés',
			'music.repeatAll' => 'Összes ismétlése',
			'music.repeatOne' => 'Egy szám ismétlése',
			'watchTogether.title' => 'Watch Together (Közös nézés)',
			'watchTogether.description' => 'Nézz tartalmat szinkronban barátaiddal és családoddal',
			'watchTogether.createSession' => 'Munkamenet létrehozása',
			'watchTogether.creating' => 'Létrehozás...',
			'watchTogether.joinSession' => 'Csatlakozás munkamenethez',
			'watchTogether.joining' => 'Csatlakozás...',
			'watchTogether.controlMode' => 'Vezérlési mód',
			'watchTogether.controlModeQuestion' => 'Ki vezérelheti a lejátszást?',
			'watchTogether.hostOnly' => 'Csak a házigazda',
			'watchTogether.anyone' => 'Bárki',
			'watchTogether.hostingSession' => 'Munkamenet indítása',
			'watchTogether.inSession' => 'Munkamenetben',
			'watchTogether.sessionCode' => 'Munkamenet kódja',
			'watchTogether.openSessionControls' => 'Watch Together munkamenet-vezérlők megnyitása',
			'watchTogether.copySessionCode' => 'Munkamenet-kód másolása',
			'watchTogether.hostControlsPlayback' => 'A házigazda vezérli a lejátszást',
			'watchTogether.anyoneCanControl' => 'Bárki vezérelheti a lejátszást',
			'watchTogether.hostControls' => 'A házigazda vezérel',
			'watchTogether.anyoneControls' => 'Bárki vezérelheti',
			'watchTogether.participants' => 'Résztvevők',
			'watchTogether.host' => 'Házigazda',
			'watchTogether.hostBadge' => 'HÁZIGAZDA',
			'watchTogether.youAreHost' => 'Te vagy a házigazda',
			'watchTogether.watchingWithOthers' => 'Nézés másokkal',
			'watchTogether.endSession' => 'Munkamenet befejezése',
			'watchTogether.leaveSession' => 'Munkamenet elhagyása',
			'watchTogether.endSessionQuestion' => 'Befejezed a munkamenetet?',
			'watchTogether.leaveSessionQuestion' => 'Elhagyod a munkamenetet?',
			'watchTogether.endSessionConfirm' => 'Ezzel minden résztvevő számára véget ér a munkamenet.',
			'watchTogether.leaveSessionConfirm' => 'Eltávolításra kerülsz a munkamenetből.',
			'watchTogether.endSessionConfirmOverlay' => 'Ezzel minden résztvevő számára véget ér a közös nézés.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Kilépsz a közös nézésből.',
			'watchTogether.end' => 'Befejezés',
			'watchTogether.leave' => 'Kilépés',
			'watchTogether.syncing' => 'Szinkronizálás...',
			'watchTogether.joinWatchSession' => 'Csatlakozás közös nézéshez',
			'watchTogether.enterCodeHint' => 'Add meg az 5 karakteres kódot',
			'watchTogether.pasteFromClipboard' => 'Beillesztés a vágólapról',
			'watchTogether.pleaseEnterCode' => 'Adj meg egy munkamenetkódot',
			'watchTogether.codeMustBe5Chars' => 'A munkamenetkódnak 5 karakterből kell állnia',
			'watchTogether.joinInstructions' => 'Add meg a házigazda kódját a csatlakozáshoz.',
			'watchTogether.failedToCreate' => 'Nem sikerült a munkamenet létrehozása',
			'watchTogether.failedToJoin' => 'Nem sikerült csatlakozni a munkamenethez',
			'watchTogether.sessionCodeCopied' => 'A munkamenetkód a vágólapra másolva',
			'watchTogether.relayUnreachable' => 'A relészerver nem érhető el. Az internetszolgáltató blokkolása megakadályozhatja a közös nézést.',
			'watchTogether.reconnectingToHost' => 'Újracsatlakozás a házigazdához...',
			'watchTogether.currentPlayback' => 'Jelenlegi lejátszás',
			_ => null,
		} ?? switch (path) {
			'watchTogether.joinCurrentPlayback' => 'Csatlakozás a jelenlegi lejátszáshoz',
			'watchTogether.joinCurrentPlaybackDescription' => 'Visszatérés ahhoz, amit a házigazda éppen néz',
			'watchTogether.failedToOpenCurrentPlayback' => 'Nem sikerült megnyitni a jelenlegi lejátszást',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} csatlakozott',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} kilépett',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} szüneteltette a lejátszást',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} folytatta a lejátszást',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} módosította a lejátszási pozíciót',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} pufferel',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} régebbi alkalmazásverziót használ — a szinkronizálás nem érhető el',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Folytatás a következő nélkül: ${name}',
			'watchTogether.waitingForParticipants' => 'Várakozás, amíg a többieknél betöltődik a tartalom...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Várakozás: ${name}...',
			'watchTogether.recentRooms' => 'Legutóbbi szobák',
			'watchTogether.renameRoom' => 'Szoba átnevezése',
			'watchTogether.removeRoom' => 'Eltávolítás',
			'watchTogether.guestSwitchUnavailable' => 'Nem sikerült a váltás — a szerver nem érhető el szinkronizáláshoz',
			'watchTogether.guestSwitchFailed' => 'Nem sikerült a váltás — a tartalom nem található ezen a szerveren',
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
			'downloads.storageFull' => 'A letöltések leálltak, mert az eszköz tárhelye megtelt. Szabadíts fel helyet, majd próbáld újra.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} epizód letöltésre sorba állítva',
			'downloads.downloadDeleted' => 'Letöltés törölve',
			'downloads.deleteConfirm' => ({required Object title}) => 'Törlöd a következőt: "${title}" erről az eszközről?',
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
			'downloads.deleteAll' => 'Összes törlése',
			'downloads.selectVersion' => 'Verzió kiválasztása',
			'downloads.allEpisodes' => 'Minden epizód',
			'downloads.unwatchedOnly' => 'Csak a nem látottak',
			'downloads.nextNUnwatched' => ({required Object count}) => 'A következő ${count} nem látott epizód',
			'downloads.customAmount' => 'Egyéni mennyiség...',
			'downloads.includeSpecials' => 'Különkiadások is',
			'downloads.howManyEpisodes' => 'Hány epizód?',
			'downloads.invalidEpisodeCount' => 'Adj meg egy érvényes epizódszámot.',
			'downloads.keepSynced' => 'Szinkronban tartás',
			'downloads.downloadOnce' => 'Egyszeri letöltés',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} nem látott epizód megtartása',
			'downloads.editSyncRule' => 'Szinkronizálási szabály szerkesztése',
			'downloads.removeSyncRule' => 'Szinkronizálási szabály eltávolítása',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Leállítod a(z) "${title}" szinkronizálását? A letöltött epizódok megmaradnak.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Szinkronizálási szabály létrehozva — ${count} nem látott epizód megtartása',
			'downloads.syncRuleUpdated' => 'Szinkronizálási szabály frissítve',
			'downloads.syncRuleRemoved' => 'Szinkronizálási szabály eltávolítva',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} új epizód szinkronizálva a következőhöz: ${title}',
			'downloads.activeSyncRules' => 'Szinkronizálási szabályok',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Nem érhető el a jelenlegi profilhoz',
			'downloads.syncRuleUnknownServer' => 'Ismeretlen szerver',
			'downloads.syncRuleListCreated' => 'Szinkronizálási szabály létrehozva',
			'downloads.backgroundWarning.bannerBlocked' => 'A letöltések leállnak, ha kilépsz az alkalmazásból',
			'downloads.backgroundWarning.bannerDegraded' => 'A háttérbeli letöltések korlátozottak lehetnek',
			'downloads.backgroundWarning.bannerAction' => 'Részletek',
			'downloads.backgroundWarning.sheetTitle' => 'A háttérbeli letöltések le vannak tiltva',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'A háttérbeli letöltések korlátozottak lehetnek',
			'downloads.backgroundWarning.sheetIntro' => 'Az Android megakadályozza, hogy a Plezy megbízhatóan töltsön le a háttérben.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Az eszközöd korlátozza, hogy a Plezy mikor tölthet le a háttérben.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'A Plezy háttérbeli használata korlátozva van. Állítsd az akkumulátor- vagy háttérhasználatát „Korlátlan” értékre.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Az Android korlátozott készenléti állapotba helyezte a Plezyt. Állítsd az akkumulátorhasználatát „Korlátlan” értékre.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'A letöltési értesítések ki vannak kapcsolva, ezért előfordulhat, hogy a folyamatjelzés és a vezérlők nem érhetők el.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Az értesítések ki vannak kapcsolva. Android 13 vagy újabb rendszeren szükségesek a hosszú háttérbeli letöltésekhez.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Az Adatforgalom-csökkentő be van kapcsolva, ezért mobiladat-kapcsolaton nem működnek a háttérbeli letöltések. Wi-Fi-n továbbra is működniük kell.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'A letöltések többször leálltak, miközben a Plezy a háttérben futott. Ellenőrizd a Plezy akkumulátor- vagy háttérhasználati beállításait.',
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
			'companionRemote.pairing.discoveryDescription' => 'Az azonos Plex-fiókot használó Plezy-eszközök itt jelennek meg',
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
			'companionRemote.pairing.sessionNotFound' => 'Az eszköz nem található. Győződj meg arról, hogy a Plezy fut a gazdagépen.',
			'companionRemote.pairing.authFailed' => 'A hitelesítés nem sikerült. Mindkét eszközön ugyanazt a Plex-fiókot kell használni.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nem sikerült a csatlakozás: ${error}',
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
			'videoSettings.playbackSpeed' => 'Lejátszási sebesség',
			'videoSettings.normalSpeed' => 'Normál',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktív (${duration})',
			'videoSettings.zoom' => 'Nagyítás',
			'videoSettings.sleepTimer' => 'Elalvási időzítő',
			'videoSettings.audioSync' => 'Hang szinkronizálása',
			'videoSettings.subtitleSync' => 'Felirat szinkronizálása',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Hangkimenet',
			'videoSettings.performanceOverlay' => 'Teljesítményadatok',
			'videoSettings.audioPassthrough' => 'Hangtovábbítás (passthrough)',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Térhatású',
			'videoSettings.audioOutputSpatial' => 'Térbeli hang',
			'videoSettings.audioOutputStereo' => 'Sztereó',
			'videoSettings.audioNormalization' => 'Hangerő normalizálása',
			'videoSettings.audioDownmix' => 'Lekeverés sztereóra',
			'performanceOverlay.color' => 'Szín',
			'performanceOverlay.performance' => 'Teljesítmény',
			'performanceOverlay.buffer' => 'Puffer',
			'performanceOverlay.app' => 'Alkalmazás',
			'performanceOverlay.decoder' => 'Dekóder',
			'performanceOverlay.rawDecoder' => 'Nyers dekóder',
			'performanceOverlay.tunneling' => 'Alagutazás',
			'performanceOverlay.aspect' => 'Méretarány',
			'performanceOverlay.rotation' => 'Forgatás',
			'performanceOverlay.dvSource' => 'DV-forrás',
			'performanceOverlay.dvPath' => 'DV-útvonal',
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
			'performanceOverlay.memory' => 'Memória',
			'performanceOverlay.uiFps' => 'Felület-FPS',
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
			'metadataEdit.style' => 'Stílus',
			'metadataEdit.mood' => 'Hangulat',
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
			'trakt.disconnectConfirmBody' => 'A Plezy nem küld több eseményt a Traktnak. Bármikor újracsatlakozhatsz.',
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
			'seerr.noSignInMethods' => 'Ez a Seerr példány nem kínál olyan bejelentkezési módot, amit a Plezy támogat.',
			'seerr.instance' => 'Példány',
			'seerr.disconnectConfirm' => 'Leválasztod a Seerr-kapcsolatot?',
			'seerr.disconnectConfirmBody' => 'A Plezy elfelejti ezt a Seerr példányt. Bármikor újracsatlakozhatsz.',
			'seerr.request' => 'Igénylés',
			'seerr.request4k' => 'Igénylés 4K-ban',
			'seerr.seasons' => 'Évadok',
			'seerr.allSeasons' => 'Minden évad',
			'seerr.advancedOptions' => 'Haladó',
			'seerr.destinationServer' => 'Célszerver',
			'seerr.qualityProfile' => 'Minőségi profil',
			'seerr.rootFolder' => 'Gyökérmappa',
			'seerr.languageProfile' => 'Nyelvi profil',
			'seerr.requestSubmitted' => 'Igénylés elküldve',
			'seerr.requestFailed' => ({required Object error}) => 'Az igénylés nem sikerült: ${error}',
			'seerr.requestsLoadFailed' => 'Nem sikerült betölteni az igénylési opciókat',
			'seerr.nothingToRequest' => 'Minden elem már elérhető vagy igényelve van.',
			'seerr.statusAvailable' => 'Elérhető',
			'seerr.statusPartiallyAvailable' => 'Részben elérhető',
			'seerr.statusRequested' => 'Igényelve',
			'seerr.statusProcessing' => 'Feldolgozás alatt',
			'services.title' => 'Szolgáltatások',
			'services.hubSubtitle' => 'Megtekintési haladás szinkronizálása és új tartalmak igénylése.',
			'services.notConnected' => 'Nincs csatlakoztatva',
			'services.connectedAs' => ({required Object username}) => '@${username} néven csatlakoztatva',
			'services.scrobble' => 'Haladás automatikus követése',
			'services.scrobbleDescription' => 'Lista frissítése, amikor befejezel egy epizódot vagy filmet.',
			'services.disconnectConfirm' => ({required Object service}) => 'Leválasztod a(z) ${service} szolgáltatást?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'A Plezy nem frissíti többé a(z) ${service} adatait. Bármikor újracsatlakozhatsz.',
			'services.connectFailed' => ({required Object service}) => 'Nem sikerült csatlakozni a következőhöz: ${service}. Próbáld újra.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy aktiválása a következőn: ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Nyisd meg a(z) ${url} oldalt és add meg ezt a kódot:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Nyisd meg a(z) ${service} oldalt az aktiváláshoz',
			'services.deviceCode.copyCode' => 'Aktiválási kód másolása',
			'services.deviceCode.waitingForAuthorization' => 'Várakozás az engedélyezésre…',
			'services.deviceCode.codeCopied' => 'Kód másolva',
			'services.oauthProxy.title' => ({required Object service}) => 'Bejelentkezés ide: ${service}',
			'services.oauthProxy.body' => 'Olvasd be ezt a QR-kódot vagy nyisd meg az URL-t bármelyik eszközön.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Nyisd meg a(z) ${service} oldalt a bejelentkezéshez',
			'services.oauthProxy.copyUrl' => 'Bejelentkezési URL másolása',
			'services.oauthProxy.urlCopied' => 'URL másolva',
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
			'addServer.serverUrls' => 'Szerver URL-címei',
			'addServer.serverUrlsHelper' => 'Több URL is megadható, vesszővel elválasztva.',
			'addServer.findServer' => 'Szerver keresése',
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
			'addServer.addConnectionTitle' => 'Kapcsolat hozzáadása',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Hozzáadás a következőhöz: ${name}',
			'addServer.signInWithPlexCard' => 'Bejelentkezés Plexszel',
			'addServer.signInWithPlexCardSubtitle' => 'Eszköz engedélyezése. A megosztott szerverek hozzáadásra kerülnek.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Plex-fiók engedélyezése. A Plex Home-felhasználókból profilok lesznek.',
			'addServer.borrowFromAnotherProfile' => 'Kapcsolat használata másik profilból',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Egy másik profil kapcsolatának használata. A PIN-kóddal védett profilokhoz PIN-kód szükséges.',
			_ => null,
		};
	}
}
