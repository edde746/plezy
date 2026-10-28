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
class TranslationsCs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsCs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.cs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <cs>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsCs _root = this; // ignore: unused_field

	@override 
	TranslationsCs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsCs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$cs app = _Translations$app$cs._(_root);
	@override late final _Translations$appIcon$cs appIcon = _Translations$appIcon$cs._(_root);
	@override late final _Translations$auth$cs auth = _Translations$auth$cs._(_root);
	@override late final _Translations$common$cs common = _Translations$common$cs._(_root);
	@override late final _Translations$screens$cs screens = _Translations$screens$cs._(_root);
	@override late final _Translations$update$cs update = _Translations$update$cs._(_root);
	@override late final _Translations$settings$cs settings = _Translations$settings$cs._(_root);
	@override late final _Translations$themeEditor$cs themeEditor = _Translations$themeEditor$cs._(_root);
	@override late final _Translations$search$cs search = _Translations$search$cs._(_root);
	@override late final _Translations$hotkeys$cs hotkeys = _Translations$hotkeys$cs._(_root);
	@override late final _Translations$fileInfo$cs fileInfo = _Translations$fileInfo$cs._(_root);
	@override late final _Translations$mediaMenu$cs mediaMenu = _Translations$mediaMenu$cs._(_root);
	@override late final _Translations$rateSheet$cs rateSheet = _Translations$rateSheet$cs._(_root);
	@override late final _Translations$accessibility$cs accessibility = _Translations$accessibility$cs._(_root);
	@override late final _Translations$tooltips$cs tooltips = _Translations$tooltips$cs._(_root);
	@override late final _Translations$audioTracks$cs audioTracks = _Translations$audioTracks$cs._(_root);
	@override late final _Translations$videoControls$cs videoControls = _Translations$videoControls$cs._(_root);
	@override late final _Translations$messages$cs messages = _Translations$messages$cs._(_root);
	@override late final _Translations$subtitlingStyling$cs subtitlingStyling = _Translations$subtitlingStyling$cs._(_root);
	@override late final _Translations$mpvConfig$cs mpvConfig = _Translations$mpvConfig$cs._(_root);
	@override late final _Translations$dialog$cs dialog = _Translations$dialog$cs._(_root);
	@override late final _Translations$profiles$cs profiles = _Translations$profiles$cs._(_root);
	@override late final _Translations$connections$cs connections = _Translations$connections$cs._(_root);
	@override late final _Translations$accountPreferences$cs accountPreferences = _Translations$accountPreferences$cs._(_root);
	@override late final _Translations$discover$cs discover = _Translations$discover$cs._(_root);
	@override late final _Translations$errors$cs errors = _Translations$errors$cs._(_root);
	@override late final _Translations$libraries$cs libraries = _Translations$libraries$cs._(_root);
	@override late final _Translations$about$cs about = _Translations$about$cs._(_root);
	@override late final _Translations$serverSelection$cs serverSelection = _Translations$serverSelection$cs._(_root);
	@override late final _Translations$hubDetail$cs hubDetail = _Translations$hubDetail$cs._(_root);
	@override late final _Translations$logs$cs logs = _Translations$logs$cs._(_root);
	@override late final _Translations$startup$cs startup = _Translations$startup$cs._(_root);
	@override late final _Translations$licenses$cs licenses = _Translations$licenses$cs._(_root);
	@override late final _Translations$navigation$cs navigation = _Translations$navigation$cs._(_root);
	@override late final _Translations$explore$cs explore = _Translations$explore$cs._(_root);
	@override late final _Translations$liveTv$cs liveTv = _Translations$liveTv$cs._(_root);
	@override late final _Translations$collections$cs collections = _Translations$collections$cs._(_root);
	@override late final _Translations$playlists$cs playlists = _Translations$playlists$cs._(_root);
	@override late final _Translations$music$cs music = _Translations$music$cs._(_root);
	@override late final _Translations$watchTogether$cs watchTogether = _Translations$watchTogether$cs._(_root);
	@override late final _Translations$downloads$cs downloads = _Translations$downloads$cs._(_root);
	@override late final _Translations$shaders$cs shaders = _Translations$shaders$cs._(_root);
	@override late final _Translations$companionRemote$cs companionRemote = _Translations$companionRemote$cs._(_root);
	@override late final _Translations$videoSettings$cs videoSettings = _Translations$videoSettings$cs._(_root);
	@override late final _Translations$performanceOverlay$cs performanceOverlay = _Translations$performanceOverlay$cs._(_root);
	@override late final _Translations$externalPlayer$cs externalPlayer = _Translations$externalPlayer$cs._(_root);
	@override late final _Translations$metadataEdit$cs metadataEdit = _Translations$metadataEdit$cs._(_root);
	@override late final _Translations$matchScreen$cs matchScreen = _Translations$matchScreen$cs._(_root);
	@override late final _Translations$serverTasks$cs serverTasks = _Translations$serverTasks$cs._(_root);
	@override late final _Translations$trakt$cs trakt = _Translations$trakt$cs._(_root);
	@override late final _Translations$seerr$cs seerr = _Translations$seerr$cs._(_root);
	@override late final _Translations$services$cs services = _Translations$services$cs._(_root);
	@override late final _Translations$addServer$cs addServer = _Translations$addServer$cs._(_root);
	@override late final _Translations$cast$cs cast = _Translations$cast$cs._(_root);
	@override late final _Translations$automation$cs automation = _Translations$automation$cs._(_root);
	@override late final _Translations$notifications$cs notifications = _Translations$notifications$cs._(_root);
	@override late final _Translations$appAccess$cs appAccess = _Translations$appAccess$cs._(_root);
	@override late final _Translations$detail$cs detail = _Translations$detail$cs._(_root);
	@override late final _Translations$watchLink$cs watchLink = _Translations$watchLink$cs._(_root);
	@override late final _Translations$homeLayout$cs homeLayout = _Translations$homeLayout$cs._(_root);
	@override late final _Translations$platform$cs platform = _Translations$platform$cs._(_root);
	@override late final _Translations$universalMedia$cs universalMedia = _Translations$universalMedia$cs._(_root);
	@override late final _Translations$fileSources$cs fileSources = _Translations$fileSources$cs._(_root);
	@override late final _Translations$lending$cs lending = _Translations$lending$cs._(_root);
	@override late final _Translations$audiobook$cs audiobook = _Translations$audiobook$cs._(_root);
	@override late final _Translations$sourceSetup$cs sourceSetup = _Translations$sourceSetup$cs._(_root);
	@override late final _Translations$comics$cs comics = _Translations$comics$cs._(_root);
	@override late final _Translations$games$cs games = _Translations$games$cs._(_root);
	@override late final _Translations$deepLinks$cs deepLinks = _Translations$deepLinks$cs._(_root);
	@override late final _Translations$householdSetup$cs householdSetup = _Translations$householdSetup$cs._(_root);
	@override late final _Translations$issueReport$cs issueReport = _Translations$issueReport$cs._(_root);
}

// Path: app
class _Translations$app$cs extends Translations$app$en {
	_Translations$app$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$cs extends Translations$appIcon$en {
	_Translations$appIcon$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'aplikace ikona';
	@override String get defaultIcon => 'Výchozí';
	@override String get current => 'Aktuální ikona';
	@override String get locked => 'Životní přístup požadovaný';
	@override String get lockedHint => 'Začněte 7denní zkoušku nebo odemkněte PlezyNG po celý život, abyste použili alternativní ikony.';
	@override String get changeFailed => 'Nemůžu změnit ikonu aplikace';
	@override String get launcherHint => 'Nová ikona se objeví na domácím obrazovce, jakmile opustíte PlezyNG.';
	@override String get tvLauncherHint => 'Nový banner se objeví, jakmile opustíte PlezyNG. Android TV může pokračovat v zobrazování starého, dokud se televizor neotevře.';
	@override late final _Translations$appIcon$names$cs names = _Translations$appIcon$names$cs._(_root);
	@override String get description => 'Vyberte ikonu zobrazenou spuštěčem zařízení. Předpovědi ukazují, jak vypadá každá možnost.';
}

// Path: auth
class _Translations$auth$cs extends Translations$auth$en {
	_Translations$auth$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Přihlaste se na číslo Plex';
	@override String get showQRCode => 'Zobrazit QR kód';
	@override String get authenticate => 'autentické';
	@override String get authenticationTimeout => 'Přihláška je hotová, zkuste prosím znovu.';
	@override String get scanQRToSignIn => 'Skenujte tento QR kód pro přihlášení';
	@override String get waitingForAuth => 'Čekání na autentizaci... Přihlaste se z vašeho prohlížeče.';
	@override String get useBrowser => 'Použití prohlížeče';
	@override String get or => 'nebo';
	@override String connectToMediaBrowser({required Object product}) => 'Připojte se k číslu ${product}';
	@override String get quickConnect => 'Rychlé připojení';
	@override String get useQuickConnect => 'Použít rychlé připojení';
	@override String get quickConnectInstructions => 'Otevřete číslo Quick Connect v čísle Jellyfin a zadejte tento kód.';
	@override String get quickConnectWaiting => 'Čekáme na schválení...';
	@override String get quickConnectCancel => 'Zrušit';
	@override String get quickConnectExpired => 'Platnost rychlého připojení vypršela. Zkuste to znovu.';
	@override String get localDataRecoveryRequired => 'PlezyNG nedokázalo bezpečně obnovit místní přihlašovací údaje a čekající údaje o přehrávání. Přihlaste se znovu.';
	@override String get pinCheckRejected => 'Ček PIN Plex byl zamítnut';
	@override String get connectToDirectPlex => 'Připojte se k místnímu serveru Plex';
}

// Path: common
class _Translations$common$cs extends Translations$common$en {
	_Translations$common$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Zrušit';
	@override String get save => 'Uložit';
	@override String get close => 'Zavřít';
	@override String get closeMiniPlayer => 'Blízký mini hráč';
	@override String get closeWorkspaceWindow => 'blízko okna';
	@override String get returnToFullView => 'Zpět na Full View';
	@override String get manageMediaSessions => 'Řízení mediálních zasedání';
	@override String get hideMediaSessions => 'ukrytí mediálních zasedání';
	@override String get mediaSessions => 'Mediální zasedání';
	@override String get mediaSessionsHint => 'Park skrývá okno, ale udržuje otevřené. Návrat ho otevírá v plném zobrazení; blízko končí.';
	@override String get sessionInWorkspace => 'v pracovním prostoru';
	@override String get sessionParked => 'Parkování';
	@override String get sessionFullscreen => 'Plný obrazovek';
	@override String get switchToNextWindow => 'Přepínání s příštím oknem';
	@override String get moveWindow => 'Pohybujte okno';
	@override String get finishMovingWindow => 'Konec pohybující se okna';
	@override String get moveWindowHint => 'Dlouho stiskněte a vytáhněte okno, abyste ho přesunuli.Tento ovládací prvek také umožňuje pohyb klíče šípky.';
	@override String get movingWindowHelp => 'Přejít na pohyb · Přejíždět klíče přizpůsobit · Zadejte zálohy · Únik zrušit';
	@override String get resizeWindow => 'Odstranit okno';
	@override String get resizeWindowHint => 'Vyzvedněte tuto rukojeti nebo použijte klíče strelu, aby se okno znovu rozmazalo.';
	@override String get workspaceWindowHint => 'Použijte pohybový ovládací prvek nebo dlouhý tlak a přejděte se.';
	@override String get workspacePaneHint => 'Vyberte tuto panelu, abyste ji zaměřili. Použijte její kontrolu na plný obrazovek k rozšíření.';
	@override String workspaceWindowLabel({required Object title}) => 'Okno sezení: ${title}';
	@override String get workspaceTitleHint => 'Vyberte se zaměřit. Přejděte titulní řádek k pohybu; použijte tlačítko na plný obrazovku k rozšíření.';
	@override String get moveToSessionTray => 'Přejděte na Session Tray';
	@override String get moveToSessionTrayHint => 'Tato schůzka je k dispozici bez zobrazení okna.';
	@override String get closeSessionHint => 'Zavřete tento okno a ukončíte jeho zasedání.';
	@override String get sideBySideLayout => 'Přepínání na side-by-side layout';
	@override String get floatingWindows => 'Přepínání k plovoucímu oknu';
	@override String get clear => 'jasné';
	@override String get reset => 'Resetovat';
	@override String get later => 'Později';
	@override String get submit => 'Odeslat';
	@override String get confirm => 'Potvrzení';
	@override String get retry => 'Zkusit znovu';
	@override String get logout => 'Přihlaste se';
	@override String get unknown => 'Neznámý';
	@override String get refresh => 'Aktualizovat';
	@override String get yes => 'Ano';
	@override String get no => 'Ne';
	@override String get delete => 'Odstranit';
	@override String get edit => 'Upravit';
	@override String get shuffle => 'Náhodné přehrávání';
	@override String get addTo => 'Přidejte k...';
	@override String get createNew => 'Vytvořte nové';
	@override String get connect => 'Připojit';
	@override String get disconnect => 'Odpojit';
	@override String get play => 'Přehrát';
	@override String get pause => 'Pozastavit';
	@override String get resume => 'Pokračovat';
	@override String get error => 'Chyba';
	@override String get search => 'Vyhledávání';
	@override String get home => 'Domovská obrazovka';
	@override String get back => 'Zpět';
	@override String get settings => 'Nastavení';
	@override String get mute => 'Ztlumit';
	@override String get ok => 'OK';
	@override String get off => 'Vypnuto';
	@override String get options => 'Možnosti';
	@override String seasonNumber({required Object number}) => 'Sezóna ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Článek ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Článek ${number}';
	@override String get reconnect => 'Připojení';
	@override String get viewAll => 'Zobrazit všechny';
	@override String get checkingNetwork => 'Kontrolní síť...';
	@override String get loadingServers => 'Nabíjecí servery...';
	@override String get connectingToServers => 'Připojení k serverům...';
	@override String get startingOfflineMode => 'Začínáme offline...';
	@override String get loading => 'Nabíjení...';
	@override String get fullscreen => 'Celá obrazovka';
	@override String get exitFullscreen => 'Výstup na plný obrazovek';
	@override String get pressBackAgainToExit => 'Stiskněte zpět na výstup';
	@override late final _Translations$common$ratingSource$cs ratingSource = _Translations$common$ratingSource$cs._(_root);
	@override String get notAvailable => 'N / A';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$cs mediaKind = _Translations$common$mediaKind$cs._(_root);
}

// Path: screens
class _Translations$screens$cs extends Translations$screens$en {
	_Translations$screens$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licence';
	@override String get switchProfile => 'Přepínání profilu';
	@override String get subtitleStyling => 'Styl titulků';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Záznamy';
}

// Path: update
class _Translations$update$cs extends Translations$update$en {
	_Translations$update$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get available => 'Aktualizace dostupná';
	@override String versionAvailable({required Object version}) => 'K dispozici je verze ${version}';
	@override String currentVersion({required Object version}) => 'Aktuální číslo: ${version}';
	@override String get skipVersion => 'Odstranit tuto verzi';
	@override String get viewRelease => 'Zobrazit Release';
	@override String get latestVersion => 'Jste na nejnovější verzi';
	@override String get checkFailed => 'Nedokázal se dohlížet na aktualizace';
}

// Path: settings
class _Translations$settings$cs extends Translations$settings$en {
	_Translations$settings$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nastavení';
	@override String get supportDeveloper => 'Podpora PlezyNG';
	@override String get supportDeveloperDescription => 'Dotace na podporu rozvoje';
	@override String get lifetimeAccess => 'PlezyNG Životní přístup';
	@override String get language => 'Jazyk';
	@override String get theme => 'Téma';
	@override String get appearance => 'Vzhled';
	@override String get detailPage => 'Detailní stránka';
	@override String get themeSongsEnabled => 'Hrajte tématické písně';
	@override String get themeSongsEnabledDescription => 'Zahrajte si dostupné tematické písně při prohlížení mediálních detailů.';
	@override String get themeSongVolume => 'Píseň Volume';
	@override String get videoPlayback => 'Videa Playback';
	@override String get videoPlaybackDescription => 'Nastavení chování playback';
	@override String get advanced => 'Pokročilé';
	@override String get episodePosterMode => 'Styl plakátů';
	@override String get seriesPoster => 'Seriál plakátů';
	@override String get seasonPoster => 'Sezónní plakát';
	@override String get episodeThumbnail => 'Thumbnailová';
	@override String get showHeroSectionDescription => 'Zobrazit obsahový karusel na domácím obrazovce';
	@override String get secondsLabel => 'sekundy';
	@override String get minutesLabel => 'minuty';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'M';
	@override String durationHint({required Object min, required Object max}) => 'Vložte hodnotu (${min}-${max})';
	@override String get systemTheme => 'Systém';
	@override String get lightTheme => 'Světlo';
	@override String get darkTheme => 'Tmavé';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Člověk';
	@override String get glacierTheme => 'ledovce';
	@override String get forestTheme => 'lesy';
	@override String get plumTheme => 'Švestková';
	@override String get paperTheme => 'Papír';
	@override String get libraryDensity => 'Densita knihovny';
	@override String get displayScale => 'displejová skala';
	@override String get compact => 'Kompaktní';
	@override String get comfortable => 'Pohodlné';
	@override String get gridSpacing => 'Síťový prostor';
	@override String get gridSpacingTight => 'Tightová';
	@override String get gridSpacingNormal => 'Normální';
	@override String get gridSpacingSpacious => 'Vesmírné';
	@override String get tvCornerSpotlightBackdrop => 'Spotlight záda';
	@override String get tvCornerSpotlightBackdropDescription => 'Zobrazit umělecké dílo v pravém horním rohu namísto vyplnění obrazovky';
	@override String get viewMode => 'Podívejte se na mód';
	@override String get gridView => 'síť';
	@override String get listView => 'Seznam';
	@override String get showHeroSection => 'Zobrazit Hero sekce';
	@override String get showHomeBackdrop => 'Domů Zobrazit Backdrop umělecké dílo';
	@override String get showHomeBackdropDescription => 'Zobrazit velké umělecké dílo za zobrazenými domácími řádky';
	@override String get contentScreensaverEnabled => 'Obsahový screensaver';
	@override String get contentScreensaverEnabledDescription => 'Zobrazit plnohodnotné umělecké dílo poté, co aplikace byla idle';
	@override String get contentScreensaverDelay => 'Začněte screensaver po';
	@override String get contentScreensaverLibraries => 'Screensaver knihovny';
	@override String get contentScreensaverLibrariesDescription => 'Vyberte si, které knihovny poskytují obrazovku. Pokud nejsou vybrané, umělecké dílo ze všech knihoven se používá.';
	@override String get contentScreensaverAllLibraries => 'Všechny knihovny';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} knihovny vybrané';
	@override String get contentScreensaverNoLibraries => 'K dispozici nejsou žádné propojené knihovny.';
	@override String get contentScreensaverDismissHint => 'Stiskněte tlačítko nebo stiskněte tlačítko k odvolání';
	@override String get newEpisodeNotifications => 'Nová epizoda oznámení';
	@override String get newEpisodeNotificationsDescription => 'Upozornění, když je k show přidána nová epizoda, jste zachyceni. kontroly, zatímco Plezy je otevřeno.';
	@override String get continueWatchingRowSize => 'Pokračujte v sledování velikosti řádku';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} karty';
	@override String get rowSizeCompact => 'Kompaktní';
	@override String get rowSizeStandard => 'Standardní';
	@override String get rowSizeLarge => 'Velký';
	@override String get continueWatchingAction => 'Pokračovat v sledování akce';
	@override String get continueWatchingPlay => 'Přehrát';
	@override String get continueWatchingDetails => 'Otevřené detaily';
	@override String get episodeAction => 'Akce epizody';
	@override String get episodePlay => 'Přehrát';
	@override String get episodeDetails => 'Otevřené detaily';
	@override String get useGlobalHubs => 'Domácí layout';
	@override String get useGlobalHubsDescription => 'Zobrazit jednotné domovské huby. jinak použijte doporučení knihovny.';
	@override String get showServerNameOnHubs => 'Zobrazit jméno serveru na Hubs';
	@override String get showServerNameOnHubsDescription => 'Vždy zobrazte jména serverů v titulcích hub.';
	@override String get groupLibrariesByServer => 'Knihovny na serveru';
	@override String get groupLibrariesByServerDescription => 'Knihovny skupiny pod každým mediálním serverem.';
	@override String get alwaysKeepSidebarOpen => 'Udržujte vždy sidebar otevřený';
	@override String get alwaysKeepSidebarOpenDescription => 'Stránka zůstává rozšířena a obsahová oblast se přizpůsobí';
	@override String get showUnwatchedCount => 'Zobrazit nepozorované číslo';
	@override String get showUnwatchedCountDescription => 'Zobrazit nepozorované epizody počítat na show a sezony';
	@override String get showWatchedIndicators => 'Zobrazení sledovaných ukazatelů';
	@override String get showWatchedIndicatorsDescription => 'Zobrazit kontrolní značku na sledovaných filmech, show a epizodech';
	@override String get showEpisodeNumberOnCards => 'Zobrazit číslo epizody na mapách';
	@override String get showEpisodeNumberOnCardsDescription => 'Sezóna a číslo epizody na karetách epizod';
	@override String get showSeasonPostersOnTabs => 'Zobrazit sezónní plakáty na Tabs';
	@override String get showSeasonPostersOnTabsDescription => 'Zobrazit každou sezónní plakát nad její tabulkou';
	@override String get tvFullCardLayout => 'Plné televizní karty';
	@override String get tvFullCardLayoutDescription => 'Použijte obraz-pouze TV karty s názvy herců přehnané';
	@override String get focusGlow => 'Focus Světlo';
	@override String get focusGlowDescription => 'Vytvořte měkký zář kolem soustředěné karty';
	@override String get visualEffects => 'vizuální efekty';
	@override String get visualEffectsAuto => 'Automaticky';
	@override String get visualEffectsAutoDescription => 'Snižuje efekty automaticky na zařízení s nízkou výkonem';
	@override String get visualEffectsFull => 'plnohodnotné';
	@override String get visualEffectsReduced => 'Snížená';
	@override String get visualEffectsReducedDescription => 'Méně animací a umělecké díly s nižší rozlišením';
	@override String get hideSpoilers => 'Skryté spoilery pro nepozorované epizody';
	@override String get hideSpoilersDescription => 'Blur miniatury a popisy nezaznamenaných epizod';
	@override String get playerBackend => 'Hráč Backend';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardware dekódování';
	@override String get hardwareDecodingDescription => 'Použijte hardware akcelerace, když je k dispozici';
	@override String get playbackBuffer => 'Hrají buffer';
	@override String get playbackBufferAuto => 'Doporučený ( doporučený )';
	@override String get playbackBufferLarge => 'Velký';
	@override String get playbackBufferExtraLarge => 'Extra velký';
	@override String get playbackBufferDescription => 'Buffer více proti nestabilním připojením. Také omezený buffer velikostí.';
	@override String get streamBufferSize => 'Buffer velikost';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Kolik videa je třeba přenést při přímém přehrávání. Transkódy se zastaví na vlastním buferu transkódů serveru. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Nahradí Playback Buffer při nastavení, zachycen na polovinu hranice paměti aplikace';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Podmínkou kvality';
	@override String get cellularQualityTitle => 'Kvalita v celulárním systému';
	@override String get remoteQualityTitle => 'Kvalita dálkového streamování';
	@override String get remoteQualitySameAsDefault => 'Stejně jako standardní kvalita';
	@override String get cellularQualitySameAsDefault => 'Stejně jako standardní kvalita';
	@override String get directPlayCoveredQuality => 'Zahrajte si menší videa v originální kvalitě';
	@override String get directPlayCoveredQualityDescription => 'Přímé přehrávání videí již v rámci limitu kvality namísto jejich překódování';
	@override String get videoCodecs => 'Video kodeků';
	@override String get videoCodecsDescription => 'Nepřehlédnuté kodeky jsou transkódovány serverem';
	@override String get videoCodecsAlwaysAccepted => 'Vždy přijatý';
	@override String get musicQualityTitle => 'Kvalita hudby';
	@override String get subtitleStyling => 'Styl titulků';
	@override String get subtitleStylingDescription => 'Přizpůsobte podtitul vzhledu';
	@override String get smallSkipDuration => 'Malý skok trvání';
	@override String get largeSkipDuration => 'Velký skok trvání';
	@override String get rewindOnResume => 'Zpět na přehled';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunda',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund',
	);
	@override String get defaultSleepTimer => 'Default spánkový čas';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minut',
	);
	@override String get rememberTrackSelections => 'Pamatujte si výběr tracků podle show/film';
	@override String get chooseTracksBeforePlayback => 'Vyberte audio a subtituly před přehráváním';
	@override String get chooseTracksBeforePlaybackDescription => 'Vyberte zdrojový zvuk a podtitulové stopy před zahájením každého videa.';
	@override String get alwaysShowSubtitlesOnDevice => 'Vždy ukázat titulky na tomto zařízení';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Když server nemá vybraný podtitul, vyberte stopu lokálně.Toto nikdy nezmění preference serveru.';
	@override String get autoDownloadPreferredSubtitle => 'FETCH chybí preferované jazykové podtituly';
	@override String get autoDownloadPreferredSubtitleDescription => 'Vyberte dostupný podtitul ve vašem preferovaném jazyce lokálně. Pokud neexistuje, požádejte server, aby jeden získal, když je podporován.';
	@override String get rememberTrackSelectionsDescription => 'Uložte si audio a subtitle volby show nebo film na tomto zařízení';
	@override String get rememberTrackSelectionsBackendRule => 'Společně s Plex, Jellyfin a Emby; Plex a Jellyfin můžete také uložit výběry na serveru';
	@override String get followServerTrackSelections => 'Použijte sériové výběry pro epizody serveru';
	@override String get followServerTrackSelectionsDescription => 'Při změně epizody použijte audio a subtituly vybrané na serveru namísto přenosu nad aktuální volbou.';
	@override String get resumeMusicOnLaunch => 'Pamatujte si na hudební sezení';
	@override String get resumeMusicOnLaunchDescription => 'Otevřete poslední písničku, kde se zastavil, když aplikace spustí';
	@override String get showChapterMarkersOnTimeline => 'Zobrazit značky kapitoly na vyhledávání bar';
	@override String get showChapterMarkersOnTimelineDescription => 'Segment vyhledávací bar na hranicích kapitoly';
	@override String get specialsOrdering => 'Speciální v epizodním pořadí';
	@override String get specialsOrderingDescription => 'Kde se speciály hrají v pořadí show';
	@override String get specialsOrderingServer => 'Sledujte objednávku serveru';
	@override String get specialsOrderingAirDate => 'Výstupy podle dat vzduchu';
	@override String get specialsOrderingLast => 'Po pravidelných sezónách';
	@override String get clickVideoTogglesPlayback => 'Klikněte na video, abyste si zahrali / přestávali';
	@override String get clickVideoTogglesPlaybackDescription => 'Klikněte na video a přehrávejte / přestávka namísto zobrazení kontrol.';
	@override String get videoPlayerControls => 'Video Player ovládání';
	@override String get keyboardShortcuts => 'Klávesnice Shortcuts';
	@override String get keyboardShortcutsDescription => 'Přizpůsobte klávesové zkratky';
	@override String get videoPlayerNavigation => 'Navigace přehrávače videa';
	@override String get videoPlayerNavigationDescription => 'Použijte klíče pro navigaci na videohrávači';
	@override String get watchTogetherRelay => 'Podívejte se na relace';
	@override String get watchTogetherRelayDescription => 'Public Open Watch Party přenášejí, pokud si neustanovíte vlastní';
	@override String get watchTogetherRelayHint => 'https://my-relay.example.com';
	@override String get watchTogetherRelayInvalid => 'Zadejte platnou základní adresu URL přenosového serveru s HTTP nebo HTTPS.';
	@override String get crashReporting => 'Zprávy o katastrofě';
	@override String get crashReportingDescription => 'Odeslat zprávy o havárii, které pomohou zlepšit aplikaci';
	@override String get debugLogging => 'Debug Logování';
	@override String get debugLoggingDescription => 'Umožňuje detailní přihlašování pro řešení problémů';
	@override String get viewLogs => 'Zobrazit logy';
	@override String get viewLogsDescription => 'Zobrazit logy aplikace';
	@override String get clearImageCache => 'Čistý obraz Cache';
	@override String get clearImageCacheDescription => 'Čistě zakryté umělecké dílo a miniatury. snímky mohou být přenášeny pomaleji, dokud nebudou znovu staženy.';
	@override String get clearImageCacheSuccess => 'Image cache úspěšně vymazáno';
	@override String get resetSettings => 'Reset nastavení';
	@override String get resetSettingsDescription => 'Obnovte výchozí nastavení. to nemůže být bez.';
	@override String get resetSettingsSuccess => 'Nastavení se úspěšně obnoví';
	@override String get backup => 'zálohování';
	@override String get exportSettings => 'Vývozní nastavení';
	@override String get exportSettingsDescription => 'Uložte své preference do souboru';
	@override String get exportSettingsSuccess => 'Nastavení exportované';
	@override String get importSettings => 'Importujte nastavení';
	@override String get importSettingsDescription => 'Obnovte preference z souboru';
	@override String get importSettingsConfirm => 'To nahradí vaše aktuální nastavení. pokračovat?';
	@override String get importSettingsSuccess => 'Nastavení importované';
	@override String get importSettingsInvalidFile => 'Tento soubor není platný PlezyNG nastavení export';
	@override String get importSettingsNoUser => 'Přihlaste se před dovozem';
	@override String get cloudBackup => 'Cloud záloha';
	@override String get cloudBackupDescription => 'Zálohování přenosných nastavení na koncové místo WebDAV přes HTTPS.Serverové připojení a autentifikace zůstanou na tomto zařízení.';
	@override String get cloudBackupUrl => 'WebDAV JSON soubor URL';
	@override String get cloudBackupUsername => 'Uživatelské jméno';
	@override String get cloudBackupPassword => 'Heslo';
	@override String get cloudBackupSaved => 'Cloud backup destinace zachráněna';
	@override String get cloudBackupNow => 'Zpět nyní';
	@override String get cloudBackupComplete => 'Nastavení zálohování nahráno';
	@override String get cloudBackupRestore => 'Obnovit zálohu';
	@override String get cloudBackupRestoreConfirm => 'To nahradí odpovídající přenosné nastavení na tomto zařízení.';
	@override String get cloudBackupRestored => 'Nastavení obnovené z cloud backup';
	@override String get shortcutsReset => 'Zpět na defaulty';
	@override String get resetShortcutsConfirm => 'To nahradí vaše přizpůsobené zkratky s defaulty.';
	@override String get about => 'o';
	@override String get aboutDescription => 'Informace o aplikacích a licencích';
	@override String get updates => 'Aktualizace';
	@override String get updateAvailable => 'Aktualizace dostupná';
	@override String get checkForUpdates => 'Podívejte se na aktualizace';
	@override String get autoCheckUpdatesOnStartup => 'Automaticky zkontrolujte aktualizace na startupu';
	@override String get autoCheckUpdatesOnStartupDescription => 'Oznámit, kdy je aktualizace k dispozici při spuštění';
	@override String get validationErrorEnterNumber => 'Vložte prosím platné číslo';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Musí být mezi ${min} a ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Zkratka již přidělená ${action}';
	@override String shortcutUpdated({required Object action}) => 'Aktualizace krátké zkratky na ${action}';
	@override String get saveFailed => 'Změny se nedohodnou, zkuste to znovu.';
	@override String get autoPlayAndSkip => 'Auto-Play a Skip';
	@override String get autoPlayNextEpisode => 'Auto-Play Další epizoda';
	@override String get autoPlayNextEpisodeDescription => 'Následující epizoda začíná automaticky, když jeden skončí';
	@override String get shuffleStartsFromBeginning => 'Shuffle začíná na začátku';
	@override String get shuffleStartsFromBeginningDescription => 'Začněte každou epizodu na začátku, když se střídají místo opakování';
	@override String get plexCinemaPreRoll => 'Využijte server kino intros';
	@override String get plexCinemaPreRollDescription => 'Hrajte konfigurované Plex předvolby nebo Jellyfin a Emby vstupy před zahájením filmu.';
	@override String get playNextCountdown => 'Hrajte další účet';
	@override String get playNextCountdownImmediate => 'Hrajte okamžitě';
	@override String get skipIntroMode => 'Skříň vstupuje';
	@override String get skipIntroModeOffDescription => 'Hrát intros normálně bez skákacího tlačítka';
	@override String get skipIntroModeButtonDescription => 'Zobrazit tlačítko skip, když začíná intro';
	@override String get skipIntroModeAutoDescription => 'Vstupy automaticky odkládají po delší době';
	@override String get skipCreditsMode => 'Skok úvěrů';
	@override String get skipCreditsModeOffDescription => 'Hrajte kredity normálně bez tlačítka na skok';
	@override String get skipCreditsModeButtonDescription => 'Zobrazit tlačítko skip, když začnou kredity';
	@override String get skipCreditsModeAutoDescription => 'Přesun kreditů automaticky a hrát další epizodu';
	@override String get skipAdsMode => 'Skřípání Ads';
	@override String get skipAdsModeOffDescription => 'Objevte zaznamenané reklamy normálně bez tlačítka';
	@override String get skipAdsModeButtonDescription => 'Zobrazit tlačítko skip, když Plex detekuje reklamu';
	@override String get skipAdsModeAutoDescription => 'Odstranění zaznamenaných reklam automaticky po zpoždění níže';
	@override String get musicPlayback => 'Hudební playback';
	@override String get musicSweetFades => 'Sladké fáty';
	@override String get musicSweetFadesDescription => 'Hudba se rozkládá na okraji track, když má číslo Plex daty o hlasitosti.';
	@override String get skipMarkerModeOff => 'Vypnuto';
	@override String get skipMarkerModeButton => 'Ukázat tlačítko';
	@override String get skipMarkerModeAuto => 'automatické';
	@override String get forceSkipMarkerFallback => 'Výsledky Force Fallback Markers';
	@override String get forceSkipMarkerFallbackDescription => 'Použijte šablony názvu kapitoly i tehdy, když má značka Plex';
	@override String get theIntroDbFallback => 'Použijte TheIntroDB jako intro fallback';
	@override String get theIntroDbFallbackDescription => 'Použijte časování komunity pouze tehdy, když server nemá intro marker.';
	@override String get autoSkipDelay => 'Auto Skip zpoždění';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Počkejte ${seconds} sekund před automatickým skokem';
	@override String get introPattern => 'Intro značkové vzorce';
	@override String get introPatternDescription => 'Regex pattern, aby odpovídal intro markers v kapitolách';
	@override String get creditsPattern => 'Kreditní značka Pattern';
	@override String get creditsPatternDescription => 'Regex vzor se hodí k úvěrovým markerům v kapitolách';
	@override String get prerolls => 'Prerolly';
	@override String get playPrerollsBeforeMovies => 'Hrajte před filmem';
	@override String get playPrerollsBeforeMoviesDescription => 'Přehrávejte náhodný klip z vašeho výběru níže před každým filmem.';
	@override String get prerollLibrary => 'Prerollová knihovna';
	@override String get prerollLibraryNotSet => 'Není nastaven';
	@override String get prerollLibraryNoneFound => 'Žádné knihovny nejsou na vašich serverech nalezeny.';
	@override String get prerollSelection => 'vybrané předměty';
	@override String get prerollSelectionPickLibraryFirst => 'Nejprve si vybírejte knihovnu';
	@override String get prerollSelectionNoneSelected => 'Žádné předvolby vybrané';
	@override String prerollSelectionCount({required Object count}) => '${count} vybráno';
	@override String get prerollItemPicker => 'Výběr prerollů';
	@override String get prerollItemPickerLoadFailed => 'Nemohla jsem si z této knihovny přenášet žádné položky.';
	@override String get invalidRegex => 'Neplatné pravidelné vyjádření';
	@override String get regex => 'Pravidelné vyjádření';
	@override String get downloads => 'Stažené soubory';
	@override String get downloadLocationDescription => 'Vyberte si místo, kde si stáhnout obsah';
	@override String get downloadLocationDefault => 'Podmínkou (App Storage)';
	@override String get downloadLocationCustom => 'Custom umístění';
	@override String get selectFolder => 'Vyberte složku';
	@override String get resetToDefault => 'Zpět na výchozí';
	@override String currentPath({required Object path}) => 'Aktuální číslo: ${path}';
	@override String get downloadLocationChanged => 'Stáhnout změna umístění';
	@override String get downloadLocationReset => 'Stáhnout lokalitu reset na default';
	@override String get downloadLocationInvalid => 'Vybraná složka není psatelná';
	@override String get downloadLocationPickerUnavailable => 'Výběr složek není k dispozici na tomto zařízení';
	@override String get downloadOnWifiOnly => 'Stáhnout pouze na Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Vyhněte se stahování, když na mobilních údajích';
	@override String get autoRemoveWatchedDownloads => 'Auto-remove sledované stahování';
	@override String get autoRemoveWatchedDownloadsDescription => 'Vymazat sledované stahování automaticky';
	@override String get autoDownloadContinueWatching => 'Auto-Download pokračovat v sledování';
	@override String get autoDownloadContinueWatchingDescription => 'Udržujte položky na vašem Pokračovat sledování shell stáhnout, a odstranit je, jakmile opustí shell';
	@override String get downloadQuality => 'Download Kvalita';
	@override String get downloadQualityDescription => 'Plex připravuje převedenou kopii ve svém stažení. Jellyfin a Emby transkód při stažení souboru; přerušené převody mohou být nutné restartovat.';
	@override String get askDownloadQualityEachTime => 'Vybírejte kvalitu pro každý download';
	@override String get askDownloadQualityEachTimeDescription => 'Zobrazit kvalitní piker před zkoušením každého videa';
	@override String get cellularDownloadBlocked => 'Stáhnout jsou blokovány na mobilní. použijte Wi-Fi nebo změňte nastavení.';
	@override String get maxVolume => 'Maximální hlasitost';
	@override String get maxVolumeDescription => 'Povolit zesílení nad 100 % u médií s tichým zvukem';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Bohatá přítomnost';
	@override String get discordRichPresenceDescription => 'Zobrazit, co se díváte na Discord';
	@override String get services => 'Služby';
	@override String get servicesDescription => 'Připojte se Trakt, MyAnimeList, Seerr a další';
	@override String get manageLibrariesDescription => 'Přehrávat a skrývat knihovny';
	@override String get companionRemoteServer => 'Společnost Remote Server';
	@override String get companionRemoteServerDescription => 'Umožňujte mobilním zařízením v síti ovládat tuto aplikaci';
	@override String get companionRemoteServerStartFailed => 'Nemohla spustit server';
	@override String get companionRemoteServerStopFailed => 'Nemohla jsem zastavit server';
	@override String get autoPip => 'Auto Picture v obraze';
	@override String get autoPipDescription => 'Automaticky zadejte obrázek v obrazu, když opustíte aplikaci během přehrávání';
	@override String get matchContentFrameRate => 'Match Content Frame Rate - míra obsahu';
	@override String get matchContentFrameRateDescription => 'Match displej upřesňovací sazba na video obsahu';
	@override String get matchContentResolution => 'Rozhodnutí Match Content';
	@override String get matchContentResolutionDescription => 'Přepněte displej na původní rozlišení videa, aby se váš televizor vyrovnal s upscaling. Menu a subtitles jsou také upscaled během přehrávání';
	@override String get matchRefreshRate => 'Závodní úroková sazba';
	@override String get matchRefreshRateDescription => 'Match displej úroveň osvěžení v plném obrazovce';
	@override String get matchDynamicRange => 'Dynamický rozsah zápasu';
	@override String get matchDynamicRangeDescription => 'Přepněte HDR na obsah HDR a pak zpět na SDR';
	@override String get displaySwitchDelay => 'Zpoždění displeje Switch';
	@override String get tunneledPlayback => 'tunelové playback';
	@override String get tunneledPlaybackDescription => 'Použijte video tunelování. vypněte, pokud HDR playback zobrazuje černé video nebo pohyblivé stuttery.';
	@override String get audioPassthrough => 'zvuková pasáž';
	@override String get audioPassthroughDescription => 'Odeslat Dolby/DTS audio do přijímače nebo televize bez re-kódování, zachování okolního zvuku.';
	@override String get audioPassthroughDescriptionApple => 'Použijte nativní dekodér Dolby Apple pro Dolby Digital Plus, včetně Atmos. DTS a TrueHD stále hrají jako multichannel PCM.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Použijte původní dekodér Dolby Apple pro Dolby Digital Plus, včetně Atmos. Na iOS, iPadOS a tvOS 26 nebo později, TrueHD Atmos a DTS:X přehrávat jako prostorový audio. Ostatní DTS a TrueHD stopy přehrávat jako multichannel PCM.';
	@override String get audioPassthroughOverriddenByNormalization => 'Zastavte, zatímco normalizace hluku je na';
	@override String get audioChannelLimit => 'Počet kanálů zvuku';
	@override String get audioChannelLimitDescription => 'Mícháme dekódovaný zvuk pro reproduktory, sluchátka nebo nastavení HDMI, které nemohou přehrávat každý kanál.';
	@override String get audioChannelLimitOriginal => 'originál';
	@override String get audioChannelLimitOriginalDescription => 'Zahrajte si každý kanál na trati';
	@override String get audioChannelLimitSurround51 => 'až do 5.1';
	@override String get audioChannelLimitSurround51Description => 'Mícháme 7.1 dolů na 5.1 pro televizory a přijímače, které užívají pouze 5.1 PCM.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Smícháme do dvou kanálů pro stereo reproduktory nebo sluchátka.';
	@override String get downmixCenterBoost => 'Články Channel Boost';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Zvýšení (dB)';
	@override String get downmixCenterBoostShort => 'DB';
	@override String get audioDownmixNormalize => 'Normalizace objemu na Downmix';
	@override String get audioDownmixNormalizeDescription => 'Snižte směs, aby se zabránilo klíčení. vypněte, abyste zachovali původní objem (možná narušení hlasitých scén).';
	@override String get dvConversionMode => 'Dolby Vision Převod';
	@override String get dvConversionModeDescription => 'Vyberte si, jak jsou zpracovávány soubory profilu Dolby Vision.';
	@override String get dvConversionAuto => 'Automaticky';
	@override String get dvConversionNative => 'Nativní / zdravotně postižené';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Použijte detekci kapacity zařízení a normální chování zpětného pádu';
	@override String get dvConversionNativeDescription => 'Force native DV7 a potlačení DV konverze zpět';
	@override String get dvConversionDv81Description => 'Konverze RPU na profil Dolby Vision 8.1';
	@override String get dvConversionHevcStripDescription => 'Strip Dolby Vision RPU/EL vrstvy a současná rovina HEVC';
	@override String get experimentalDolbyVision => 'Experimentální Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Při příštím přehrávání použít experimentální renderer FEL. Vyžaduje samostatné sestavení enginu.';
	@override String get dvExperimentUnavailableDescription => 'Tento experiment je zatím dostupný pouze na Linuxu.';
	@override String get dvCompatibilityFallback => 'Záložní režim kompatibility';
	@override String get dvCompatibilityFallbackDescription => 'Pokud experiment nelze spustit, použít standardní renderer. Data FEL mohou být ztracena.';
	@override String get dvExperimentDiagnostics => 'Protokolování videoexperimentu';
	@override String get dvExperimentDiagnosticsDescription => 'Při příštím přehrávání zapnout podrobné protokoly přehrávače.';
	@override String get disableDolbyVision => 'Zrušení Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Přehrávejte soubor HDR10 nebo vrstvu HLG namísto Dolby Vision, když má jeden';
	@override String get hdrSdrConversion => 'HDR na SDR konverze';
	@override String get hdrSdrConversionDescription => 'Vyberte, co konvertuje HDR video, když displej nedokáže zobrazit HDR.';
	@override String get hdrSdrConversionAuto => 'Automaticky';
	@override String get hdrSdrConversionAutoDescription => 'Přístroj na Android 9 a novější, hráč na starších verzích';
	@override String get hdrSdrConversionDevice => 'Zařízení';
	@override String get hdrSdrConversionDeviceDescription => 'Video hardware vašeho zařízení to konvertuje. nejrychlejší, ale barvy závisí na zařízení';
	@override String get hdrSdrConversionPlayer => 'Přehrávač';
	@override String get hdrSdrConversionPlayerDescription => 'Konvertuje ji hráč. konzistentní barvy, ale 4K může stoupat na nízké televizní krabičky';
	@override String get deinterlace => 'Deinterlacingová';
	@override String get deinterlaceDescription => 'Odstranění smíšených artefaktů z interlaceného videa (mpv hráčů pouze)';
	@override String get deinterlaceOff => 'Vypnuto';
	@override String get deinterlaceOffDescription => 'Zobrazit interlinkované video, jak je dekódován';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Pro video snímky pro TV, jako jsou sporty, novinky a koncerty';
	@override String get deinterlaceFilm => 'Filmy';
	@override String get deinterlaceFilmDescription => 'Obnovte původní rámy filmu a animace telecined na 29.97 fps, běžné na NTSC DVD. Video shromažďování pro TV stutters.';
	@override String get requireProfileSelectionOnOpen => 'Vyžádejte si profil v aplikaci Open';
	@override String get requireProfileSelectionOnOpenDescription => 'Zobrazit výběr profilu pokaždé, když je aplikace otevřena';
	@override String get forceTvMode => 'TV režim síly';
	@override String get forceTvModeDescription => 'Pro zařízení, která neexistuje automaticky detekce, vyžaduje restart.';
	@override String get startInFullscreen => 'Začněte na plném obrazovce';
	@override String get startInFullscreenDescription => 'Otevřete PlezyNG v režimu plného obrazovky při spuštění';
	@override String get exitFullscreenOnPlayerClose => 'Výstup na plný obrazovek na hráči uzavřené';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Automaticky vyjde na plný obrazovek při zavírání videa';
	@override String get autoHidePerformanceOverlay => 'Auto-Hide Výkon Overlay';
	@override String get autoHidePerformanceOverlayDescription => 'Zkuste překonat výkon pomocí playback kontroly';
	@override String get showNavBarLabels => 'Zobrazení Navigace Bar Labels';
	@override String get showNavBarLabelsDescription => 'Zobrazit textové štítky pod ikony navigační řádky';
	@override String get startupSection => 'Startup sekce';
	@override String get preferredServer => 'Oblíbený server';
	@override String get preferredServerDescription => 'Prioritizujte výsledky tohoto serveru a zároveň udržujte všechny připojené servery k dispozici.';
	@override String get preferredServerAutomatic => 'automatické';
	@override String get showExploreTab => 'Zobrazit tabulku';
	@override String get showExploreTabDescription => 'Zobrazit kartu Explore s obsahem z Plex Objevovat a připojené sledovatele';
	@override String get hideEmptyLibraries => 'Skryjte prázdné knihovny';
	@override String get hideEmptyLibrariesDescription => 'Odstranit knihovny s počtem položek, které jsou hláseny serverem, od nuly z navigace.';
	@override String get liveTvDefaultFavorites => 'Vstup do oblíbených kanálů';
	@override String get liveTvDefaultFavoritesDescription => 'Zobrazit pouze oblíbené kanály při otevírání Live TV';
	@override String get general => 'Obecné';
	@override String get generalDescription => 'Jazyk, startup a chování okna';
	@override String get languageAndRegion => 'Jazyk a region';
	@override String get startup => 'Startupy';
	@override String get display => 'Zobrazení';
	@override String get libraryAndCards => 'Knihovna a mapy';
	@override String get homeScreen => 'Domácí obrazovka';
	@override String get navigation => 'Navigace';
	@override String get window => 'okno';
	@override String get liveTv => 'Živé vysílání';
	@override String get player => 'Přehrávač';
	@override String get videoAndDisplay => 'Video a displej';
	@override String get audio => 'Zvuk';
	@override String get quality => 'Kvalita';
	@override String get subtitles => 'Titulky';
	@override String get seekAndTiming => 'Vyhledávání a časování';
	@override String get behavior => 'chování';
	@override String get gestures => 'gesty';
	@override String get gestureBrightnessSwipe => 'Svítí světlo';
	@override String get gestureBrightnessSwipeDescription => 'Přesunout nahoru nebo dolů na levém okraji, abyste upravili jasnost';
	@override String get gestureVolumeSwipe => 'Volume přepínání';
	@override String get gestureVolumeSwipeDescription => 'Přesunout nahoru nebo dolů na pravém okraji, abyste upravili objem';
	@override String get gesturePinchToZoom => 'Zpět na Zoom';
	@override String get gesturePinchToZoomDescription => 'Připojte se k videu a zoomujte se do nebo ven';
	@override String get gestureSeekSwipe => 'Vyhledat Swipe';
	@override String get gestureSeekSwipeDescription => 'Přesun levé nebo pravé kamkoliv na videu hledat; uvolnit na skok';
	@override String get rememberBrightnessLevel => 'Pamatujte si hladinu jasnosti';
	@override String get rememberBrightnessLevelDescription => 'Zahájení playback na jasu nastaveném posledním svipem';
	@override String get controls => 'Ovládání';
	@override String get rememberPlayerChanges => 'Pamatujte si změny hráčů';
	@override String get rememberPlayerChangesDescription => 'Kde se změna provedená během přehrávání ukládá a znovu aplikuje';
	@override String get scopePlaybackSpeed => 'Rychlost přehrávání';
	@override String get scopeShaderPreset => 'Shader představení';
	@override String get scopeAspectRatio => 'Poměr stran';
	@override String get scopeSyncOffsets => 'Audio a subtitle synchronizace';
	@override String get playerScopeOff => 'Nenechte se zachránit';
	@override String get playerScopeGlobal => 'Všude všude';
	@override String get playerScopeLibrary => 'Pro knihovnu';
	@override String get playerScopeTitle => 'Pro show nebo film';
	@override String get exportDialogTitle => 'Vývoz PlezyNG nastavení';
	@override String get followSystem => 'Podle systému';
	@override String get followAppLanguage => 'Podle jazyka rozhraní';
	@override String get regionFormat => 'Místní formáty';
	@override String get regionFormatDescription => 'Zvolte způsob zobrazení dat, čísel a měrných jednotek.';
	@override String get metadataLanguage => 'Jazyk metadat';
	@override String get metadataLanguageDescription => 'Upřednostňovaný jazyk názvů a popisů, pokud jej server podporuje. Předvolby zvuku a titulků se nastavují samostatně.';
	@override String get enterFullscreenOnPlaybackStart => 'Přihlaste se k plné obrazovce, když začíná playback';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Otevřete desktopové video na plném obrazovce, když začíná playback';
	@override String get extendVideoIntoDisplayCutout => 'Rozšířte video do displeje Cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Umožňujte, aby video s plnou obrazovkou používalo fotoaparát na telefonech Android';
	@override String get languageDescription => 'Vyberte jazyk používaný pro kontroly a zprávy PlezyNG.Sledujte systém sleduje jazyk vašeho zařízení.';
	@override String get themeDescription => 'Vyberte barvy a kontrast používané v celé aplikaci.';
	@override String get libraryDensityDescription => 'Změňte, kolik knihovních karet se hodí v každém řádku.';
	@override String get displayScaleDescription => 'Přehrávejte rozhraní na tomto autovém displeji, aniž byste změnili velikost textu v celé zařízení.';
	@override String get themeSongVolumeDescription => 'Nastavení objemu tematických písní ve vztahu k jiným zvukům.';
	@override String get viewModeDescription => 'Vyberte, zda se knižní položky zobrazují jako plakáty v síti nebo jako kompaktní seznam.';
	@override String get gridViewDescription => 'Nastavení knihovních položek v řádcích a sloupcích plakátů.';
	@override String get listViewDescription => 'Zobrazit položky knihovny v vertikálním seznamu s více textem na položku.';
	@override String get gridSpacingDescription => 'Nastavte rozdíl mezi plakáty v knihovních sítích.';
	@override String get gridSpacingTightDescription => 'Připravte více plakátů přes obrazovku s menšími mezery.';
	@override String get gridSpacingNormalDescription => 'Použijte standardní mezeru mezi plakáty.';
	@override String get gridSpacingSpaciousDescription => 'Přidejte větší mezery mezi plakáty pro více oddělení.';
	@override String get episodePosterModeDescription => 'Vyberte, které umělecké dílo se objeví na karetách epizod.';
	@override String get seriesPosterDescription => 'Použijte seriálový plakát pro každou epizodu.';
	@override String get seasonPosterDescription => 'Použijte sezónní plakát pro každou epizodu, když je k dispozici.';
	@override String get episodeThumbnailDescription => 'Použijte rám z epizody, když je k dispozici.';
	@override String get continueWatchingActionDescription => 'Vyberte si, co se stane, když aktivujete kartu Pokračující sledování.';
	@override String get continueWatchingPlayDescription => 'Začněte film nebo epizodu okamžitě.';
	@override String get continueWatchingDetailsDescription => 'Nejprve otevřete titulní stránku, abyste si mohli prohlédnout detaily a vybrat akci.';
	@override String get episodeActionDescription => 'Vyberte si, co se stane, když aktivujete epizodovou kartu.';
	@override String get episodePlayDescription => 'Hra začíná okamžitě.';
	@override String get episodeDetailsDescription => 'Otevřete stránku epizody před playbackem.';
	@override String get contentScreensaverDelayDescription => 'Vyberte si, jak dlouho PlezyNG čeká bez vstupu před zobrazením uměleckého díla.';
	@override String get continueWatchingRowSizeDescription => 'Vyberte si, jak velké jsou karty v řádku Pokračující sledování.';
	@override String get rowSizeCompactDescription => 'Zobrazit menší karty, takže více položek se hodí po řádku.';
	@override String get rowSizeStandardDescription => 'Použijte standardní velikost karty.';
	@override String get rowSizeLargeDescription => 'Zobrazit větší karty s více uměleckých detailů.';
	@override String get visualEffectsDescription => 'Vyberte rozpočet animace a uměleckých efektů pro toto zařízení.';
	@override String get visualEffectsFullDescription => 'Použijte plné animace a umělecké efekty na každém zařízení.';
	@override String get startupSectionDescription => 'Vyberte, která sekce se otevře při zahájení PlezyNG.';
	@override late final _Translations$settings$startupSectionOptions$cs startupSectionOptions = _Translations$settings$startupSectionOptions$cs._(_root);
	@override String get smallSkipDurationDescription => 'Nastavte vzdálenost pohybující se krátkou zpětnou a dopředu hledat kontroly.';
	@override String get largeSkipDurationDescription => 'Nastavte vzdálenost pohybující se dlouhým zpětným a dopředu hledat kontroly.';
	@override String get rewindOnResumeDescription => 'Převod playback zpět tímto množstvím při opětovném natáčení videa.';
	@override String get defaultSleepTimerDescription => 'Nastavení počáteční doby použité při zahájení času spánku.';
	@override String get playNextCountdownDescription => 'Čekejte to dlouho, než začnete další epizodu. nastavit na 0 začít okamžitě.';
	@override String get autoSkipDelaySettingDescription => 'Použije se, když je intro, kredit nebo reklama nastaven k automatické přerušení.';
	@override String get downmixCenterBoostDescription => 'Zvýšte dialog v centrálním kanálu, když je surround audio smícháno dolů na stereo.';
	@override String get displaySwitchDelayDescription => 'Počkejte před změnou režimu zobrazení, aby televizor nebo přijímač mohl dokončit svůj předchozí přepín.';
	@override String get playerBackendDescription => 'Vyberte si, který přehrávač dekóduje a renderuje video na tomto zařízení.';
	@override String get exoPlayerDescription => 'Použijte nativní přehrávač založený na Media3 a podporované hardwarové trasy systému Android.';
	@override String get mpvDescription => 'Použijte mpv, který vystavuje další playback, subtitle a video zpracování ovládacích prvků.';
	@override String get scopeOffDescription => 'Udržujte změny pouze pro aktuální playback.';
	@override String get scopeGlobalDescription => 'Opět použijte stejnou hodnotu pro každou knihovnu a titul.';
	@override String get scopeLibraryDescription => 'Pamatujte si na samostatnou hodnotu pro každou knihovnu.';
	@override String get scopeTitleDescription => 'Pamatujte si samostatnou hodnotu pro každou představu nebo film.';
	@override String get specialsOrderingServerDescription => 'Udržujte objednávku epizody poskytovanou mediálním serverem.';
	@override String get specialsOrderingAirDateDescription => 'Vložte speciály mezi pravidelné epizody podle jejich datum vzduchu.';
	@override String get specialsOrderingLastDescription => 'Každá speciální položka po pravidelných sezónách.';
	@override String get skipIntroModeDescription => 'Vyberte, zda intro markery hrají normálně, zobrazí tlačítko skip nebo automaticky skip.';
	@override String get skipCreditsModeDescription => 'Vyberte, zda se kredity běžně hrají, zobrazí tlačítko skok nebo automaticky skok.';
	@override String get skipAdsModeDescription => 'Vyberte, zda zjištěné reklamy hrají normálně, zobrazí tlačítko skip nebo automaticky skip.';
	@override String get playbackBufferAutoDescription => 'Nechte aktivního hráče zvolit jeho normální velikost bufetu.';
	@override String get playbackBufferLargeDescription => 'Udržujte více médií připravených před přehráváním; to využívá více paměti.';
	@override String get playbackBufferExtraLargeDescription => 'Udržujte největší čtenářský buffer, který využívá nejvíce paměti.';
	@override String get defaultQualityDescription => 'Nastavení výchozí video rozlišení a bitrate strop pro toky, které server transkóduje.';
	@override String get cellularQualityDescription => 'Override Standardní kvalita, když zařízení používá pouze buněčné připojení.';
	@override String get remoteQualityDescription => 'Override Default Quality při připojení k serveru prostřednictvím vzdáleného připojenia.';
	@override String get qualityPresetOriginalDescription => 'Přehrávejte zdroj v dostupné kvalitě, aniž byste požádali server o jeho překódování.';
	@override String get qualityPresetTranscodeOptionDescription => 'Požádejte server o převedený tok pomocí výše uvedené rozlišení a bitrate.';
	@override String get qualityPresetSameAsDefaultDescription => 'Použijte kvalitu vybranou v předvolené kvalitě.';
	@override String get musicQualityDescription => 'Nastavte maximální požadovanou audio bitovou rychlost od serveru; originál zachovává zdrojový tok.';
	@override String get musicQualityOriginalDescription => 'Přehrávejte zdrojový zvuk bez bitrate-capped transcode.';
	@override String get musicQualityTranscodeOptionDescription => 'Požádejte o transkód serveru v blízkosti výše uvedené bitové rychlosti; skutečný výsledek se může lišit.';
	@override String get maxVolumeInputLabel => 'Maximální objem (%)';
	@override String get checkForUpdatesDescription => 'Zkontrolujte, zda je k dispozici novější verze PlezyNG.';
	@override String get appearanceDescription => 'Vyberte téma aplikace a přizpůsobte karty knihovny, domovské řádky a navigaci.';
	@override String get prerollLibraryDescription => 'Vyberte si knihovnu, která obsahuje klipy k dispozici jako filmové pre-rolls.';
	@override String get prerollSelectionDescription => 'Vyberte, které klipy z vybrané knihovny můžete hrát před filmy.';
	@override String get contentScreensaverDelayOptionDescription => 'Počkejte na to mnoho minut bez vstupu, než se zobrazí obrazovkový záložní umělecké dílo.';
	@override String get videoCodecOptionDescription => 'Umožňujte přímé přehrávání pro tento kodek, když je podporován. nekontrolované kodeky jsou transkódovány mediálním serverem.';
}

// Path: themeEditor
class _Translations$themeEditor$cs extends Translations$themeEditor$en {
	_Translations$themeEditor$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'stavět-in';
	@override String get presets => 'přednášky';
	@override String get custom => 'Vlastní';
	@override String get customEmpty => 'Zatím nevytvořeno';
	@override String get editCustom => 'Edit témata';
	@override String get editCustomDescription => 'Každou barvu si vyberte sami';
	@override String get locked => 'Životní přístup požadovaný';
	@override String get savedLocked => 'Ušetřeno – dostupné s doživotním přístupem';
	@override String get title => 'Custom témata';
	@override String get startFrom => 'Začněte od';
	@override String get startFromDescription => 'Kopírovat všechny barvy z jiné tématy';
	@override String get colors => 'barvy';
	@override String get preview => 'Náhled';
	@override late final _Translations$themeEditor$slots$cs slots = _Translations$themeEditor$slots$cs._(_root);
	@override String get opacity => 'Opacita';
	@override String get hexHint => '#RRGGBB nebo #AARRGGBB';
	@override String get fromOtherThemes => 'Z jiných témat';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme} ${color}';
	@override late final _Translations$themeEditor$contrast$cs contrast = _Translations$themeEditor$contrast$cs._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, pod doporučeným ${minimum}:1';
	@override String get discardTitle => 'Chybí se změny?';
	@override String get discardMessage => 'Neuložené změny barev budou ztraceny.';
	@override String get discard => 'Diskuze';
	@override String previewCardTitle({required Object number}) => 'Článek ${number}';
	@override String previewCardSubtitle({required Object minutes}) => 'Zbývá ${minutes} min';
	@override String get previewSwitch => 'Automatické přehrávání';
	@override String get previewMutedText => 'Druhý text se takhle čte';
	@override String get themeSystemDescription => 'Sledujte vzhled vašeho zařízení a automaticky přejděte mezi světlem a temnotou.';
	@override String get themeLightDescription => 'Použijte jasný pozadí s tmavým textem.';
	@override String get themeDarkDescription => 'Použijte tmavé pozadí s lehkým textem.';
	@override String get themeOledDescription => 'Používejte černé povrchy, které snižují světlo na OLED obrazovkách.';
	@override String get themeEmberDescription => 'Použijte teplé červené a amber akcentní barvy.';
	@override String get themeGlacierDescription => 'Použijte barevné modré akcenty.';
	@override String get themeForestDescription => 'Použijte zelené a přírodní barevné akcenty.';
	@override String get themePlumDescription => 'Použijte violetní a plumové akcentní barvy.';
	@override String get themePaperDescription => 'Použijte teplé papírové povrchy a barvy inspirované inkoustem.';
	@override String get themeCustomDescription => 'Použijte barevnou paletu, kterou jste vytvořili v přizpůsobeném editoru témat.';
	@override String get editorDescription => 'Vyberte si barvu palety, upravte její hustotu, nasycení, jasnost nebo opacitu a předchozí aktualizace se zobrazí.';
}

// Path: search
class _Translations$search$cs extends Translations$search$en {
	_Translations$search$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Hledat filmy, představení, hudba...';
	@override String get tryDifferentTerm => 'Vyzkoušejte jiný vyhledávací termín';
	@override String get searchYourMedia => 'Vyhledejte své média';
	@override String get enterTitleActorOrKeyword => 'Zadejte titul, herec nebo klíčové slovo';
	@override String get people => 'Lidé';
}

// Path: hotkeys
class _Translations$hotkeys$cs extends Translations$hotkeys$en {
	_Translations$hotkeys$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Set krátký pro ${actionName}';
	@override String get clearShortcut => 'Jasný krátký';
	@override String get noShortcutSet => 'Není krátký set';
	@override String get currentShortcut => 'Aktuální zkratka :';
	@override String get pressToRecord => 'Vyberte možnost nahrávání krátkého';
	@override String get recordingShortcut => 'Stiskněte krátkodobou nyní';
	@override late final _Translations$hotkeys$actions$cs actions = _Translations$hotkeys$actions$cs._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$cs extends Translations$fileInfo$en {
	_Translations$fileInfo$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info souborů';
	@override String get overview => 'Přehled';
	@override String get video => 'Video';
	@override String get audio => 'Zvuk';
	@override String get subtitles => 'Titulky';
	@override String get images => 'Vestavěné obrázky';
	@override String get dataStreams => 'Data Streamová';
	@override String get lyrics => 'Texty';
	@override String get file => 'Soubor';
	@override String get attachments => 'Příslušenství';
	@override String get delivery => 'dodání';
	@override String versionCounter({required Object index, required Object count}) => 'verze ${index} z ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Soubor ${index} z ${count}';
	@override String get noStreams => 'Server oznámil žádné streamování pro tento soubor.';
	@override String get copyPath => 'Kopírování trasy';
	@override String get pathCopied => 'Archivní cesta kopírovaná';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Značka kodeku';
	@override String get resolution => 'Rozlišení';
	@override String get codedResolution => 'Kódovaná rezoluce';
	@override String get bitrate => 'Datový tok';
	@override String get frameRate => 'Rychlost rámu';
	@override String get rotation => 'Rotace';
	@override String get comment => 'Jak';
	@override String get audioDescription => 'Audio popis';
	@override String get headerCompression => 'Header komprese';
	@override String get sidecarFile => 'Sídlo souborů';
	@override String get transportTimestamp => 'Dopravní čas';
	@override String get displayOffset => 'Zobrazení Offset';
	@override String get previewFailureCode => 'Předchozí článekKód selhání';
	@override String get previewRetries => 'Předpověď Retries';
	@override String get aspectRatio => 'Poměr stran';
	@override String get pixelAspectRatio => 'Poměr stran pixelu';
	@override String get profile => 'Profil';
	@override String get level => 'Úroveň';
	@override String get bitDepth => 'Počet bitů na pixel';
	@override String get pixelFormat => 'Formát pixelu';
	@override String get colorSpace => 'Barva prostoru';
	@override String get colorRange => 'barevný rozsah';
	@override String get colorPrimaries => 'Primární barva';
	@override String get colorTransfer => 'Barva přenosu';
	@override String get chromaSubsampling => 'Chromová podskupina';
	@override String get chromaLocation => 'Poloha Chroma';
	@override String get scanType => 'Typ skenování';
	@override String get interlaced => 'Prokládané';
	@override String get anamorphic => 'Anamorfní';
	@override String get referenceFrames => 'Referenční rámec';
	@override String get dynamicRange => 'Dynamický rozsah';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Úroveň Dolby Vision';
	@override String get dolbyVisionVersion => 'Dolby Vision verze';
	@override String get dolbyVisionLayers => 'Dolby Vision Zásuvky';
	@override String get baseLayerCompatibility => 'Základní kompatibilita';
	@override String get avcBitstream => 'Bitový tok AVC';
	@override String get nalLengthSize => 'NAL délka velikost';
	@override String get scalingMatrix => 'Vlastní matrace';
	@override String get streamIdentifier => 'Stream identifikátor';
	@override String get streamIndex => 'Streamový index';
	@override String get streamId => 'ID streamu';
	@override String get language => 'Jazyk';
	@override String get languageCode => 'Jazykový kód';
	@override String get streamTitle => 'Název Track';
	@override String get channels => 'Kanály';
	@override String get sampleRate => 'Vzorkovací frekvence';
	@override String get spatialAudio => 'Vesmírný audio';
	@override String get textBased => 'Text založený';
	@override String get subtitleFormat => 'Sídlo formátu';
	@override String get provider => 'Poskytovatel';
	@override String get matchScore => 'Zápasový skóre';
	@override String get externalDelivery => 'Může se sloužit samostatně';
	@override String get sidecarPath => 'Sídlová cesta';
	@override String get sourceStream => 'Kopírováno z';
	@override String get temporary => 'dočasné';
	@override String get timeBase => 'Časová základna';
	@override String get overallBitrate => 'Celkový bitrate';
	@override String get path => 'Cesta k souboru';
	@override String get fileName => 'Název souboru';
	@override String get size => 'Velikost';
	@override String get totalSize => 'Celková velikost';
	@override String get container => 'Kontejner';
	@override String get duration => 'Délka';
	@override String get previewThumbnails => 'Předpověď Thumbnails';
	@override String get previewIndex => 'Předpověď Index';
	@override String get packetLength => 'Délka balení';
	@override String get filePresent => 'Soubor přítomný';
	@override String get fileReadable => 'Číst na serveru';
	@override String get streamPath => 'Stream cestou';
	@override String get optimizedForStreaming => 'Optimalizace pro streamování';
	@override String get has64bitOffsets => '64bitové offsety';
	@override String get protocol => 'Protokol';
	@override String get mediaType => 'Mediální typ';
	@override String get sourceKind => 'Zdrojový typ';
	@override String get optimizedVersion => 'Optimalizovaná verze';
	@override String get optimizationTarget => 'Optimalizace cíle';
	@override String get deletedAt => 'Odstraněno';
	@override String get remoteSource => 'Vzdálený zdroj';
	@override String get infiniteStream => 'Nekonečný proud';
	@override String get directPlay => 'Přímá hra';
	@override String get directStream => 'Přímý proud';
	@override String get transcoding => 'Překódování';
	@override String get etag => 'ETag';
	@override String get versionId => 'verze ID';
	@override String get fileId => 'ID souboru';
	@override String get defaultAudioTrack => 'Standardní Audio Track';
	@override String get defaultSubtitleTrack => 'Předvolené Subtitle Track';
	@override String get subtitlesOff => 'Vypnuto';
	@override String get flagDefault => 'Výchozí';
	@override String get flagForced => 'Vynucené';
	@override String get flagSelected => 'vybrané';
	@override String get flagExternal => 'Externí';
	@override String get flagHearingImpaired => 'Slyšící se zhoršuje';
	@override String get flagDub => 'Dubová';
	@override String get flagOriginal => 'originál';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$cs extends Translations$mediaMenu$en {
	_Translations$mediaMenu$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Mark jako sledovaný';
	@override String get markAsUnwatched => 'Mark jako nepozorovaný';
	@override String get removeFromContinueWatching => 'Odstranit od Pokračovat v sledování';
	@override String get viewDetails => 'Zobrazit detaily';
	@override String get goToSeries => 'Přejděte do série';
	@override String get shufflePlay => 'Hrají Shuffle';
	@override String get shuffleNotAvailableOffline => 'SCHUFFLE není k dispozici offline';
	@override String get fileInfo => 'Info souborů';
	@override String get deleteEpisodeFromServer => 'Odstranit epizodu z serveru';
	@override String get deleteSeasonFromServer => 'Odstranit sezónu z serveru';
	@override String get deleteShowFromServer => 'Odstranit show z serveru';
	@override String get deleteMovieFromServer => 'Odstranit film z serveru';
	@override String get deleteEpisodeTitle => 'Odstranit tuto epizodu?';
	@override String get deleteSeasonTitle => 'Zrušit tuto sezónu?';
	@override String get deleteShowTitle => 'Vymazat tuto show?';
	@override String get deleteMovieTitle => 'Vymazat tento film?';
	@override String get deleteEpisodeConfirm => 'Odstranit díl';
	@override String get deleteSeasonConfirm => 'Sezóna odstranění';
	@override String get deleteShowConfirm => 'Odstranění show';
	@override String get deleteMovieConfirm => 'Odstranit film';
	@override String get deleteAnyway => 'Odstranit v každém';
	@override String confirmDeleteTarget({required Object title}) => 'Trvale smazat ${title} ze serveru?';
	@override String get deleteMultipleWarning => 'To zahrnuje všechny epizody a jejich soubory.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Tím se smaže ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda v této položce i její soubor.',
		few: 'Tím se smažou všechny ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody v této položce i jejich soubory.',
		many: 'Tím se smažou všechny epizody v této položce (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) i jejich soubory.',
		other: 'Tím se smaže všech ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod v této položce i jejich soubory.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Tato položka je uložena v ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souboru, který bude smazán.',
		few: 'Tato položka je uložena ve ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souborech a všechny budou smazány.',
		many: 'Tato položka je uložena v souborech (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}), které budou všechny smazány.',
		other: 'Tato položka je uložena v ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souborech a všechny budou smazány.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Ve stejném souboru je uložena ještě ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda, která bude také smazána:',
		few: 'Ve stejném souboru jsou uloženy ještě ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody, které budou také smazány:',
		many: 'Další epizody ve stejném souboru (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) budou také smazány:',
		other: 'Ve stejném souboru je uloženo dalších ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod, které budou také smazány:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG nedokázalo ověřit, které soubory budou odstraněny, takže může smazat více než výše uvedenou položku. Akci zrušte a zkuste to znovu, nebo pokračujte ve smazání.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Server neposkytl podrobnosti o souborech této položky, takže PlezyNG nemůže ověřit, které soubory budou odstraněny. Může být smazáno více než výše uvedená položka.';
	@override String get mediaDeletedSuccessfully => 'Media objekt byl úspěšně odstraněn';
	@override String get mediaFailedToDelete => 'Nedokázal odstranit mediální položku';
	@override String get rate => 'Hodnocení';
	@override String get playFromBeginning => 'Přehrát od začátku';
	@override String get playVersion => 'Hrajte verzi...';
}

// Path: rateSheet
class _Translations$rateSheet$cs extends Translations$rateSheet$en {
	_Translations$rateSheet$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hodnocení';
	@override String get server => 'servery';
	@override String get favorite => 'Oblíbené';
	@override String get favorited => 'Oblíbený';
	@override String get saved => 'Zachráněno';
	@override String get notAvailable => 'Není nalezen žádný zápas';
	@override String get noConnectedServices => 'Připojte službu v nastavení, abyste tam hodnotili.';
}

// Path: accessibility
class _Translations$accessibility$cs extends Translations$accessibility$en {
	_Translations$accessibility$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, televizní show';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'Zhlédnuto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} % zobrazených';
	@override String get mediaCardUnwatched => 'nezhlédnuto';
	@override String get tapToPlay => 'Klepnutím přehrajete';
	@override String get decrease => 'Snížení';
	@override String get increase => 'Zvýšení';
	@override String decreaseValue({required Object label}) => 'Ztráta ${label}';
	@override String increaseValue({required Object label}) => 'Zvýšení ${label}';
	@override String get hue => 'Odstín';
	@override String get saturation => 'Saturace';
	@override String get brightness => 'Světlo';
	@override String get hexColor => 'Hex barva';
	@override String get expandText => 'Rozšířte text';
	@override String get collapseText => 'Zkrachovaný text';
	@override String get alphabetNavigation => 'Alphabetní navigace';
	@override String get alphabetScrollHint => 'Přejetím nahoru nebo dolů se pohybujete podle písmen';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Řádek ${row} z ${rowCount}, sloupec ${column} z ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Růž ${row} z ${rowCount}';
	@override String get autoScrollPlay => 'Hrajte si Auto-Scroll';
	@override String get autoScrollPause => 'Přestávka Auto-Scroll';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Červená';
	@override String get green => 'Zelená';
	@override String get blue => 'Modrá';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'přístupnost';
	@override String get summary => 'Text, kontrast, pohyb a kontroly';
	@override String get systemHint => 'Nastavení přístupnosti vašeho zařízení se vždy vztahují.Tyto možnosti přidávají úpravy po celém PlezyNG.';
	@override String get readability => 'Čtení a viditelnost';
	@override String get textSize => 'Další textová velikost';
	@override String get preview => 'Přečtěte si, poslouchejte a sledujte ve svém vlastním tempu.';
	@override String get boldText => 'Rozhraní text';
	@override String get highContrast => 'Vysoký kontrast';
	@override String get highContrastHint => 'Výraznější text, obrysy a indikátory zaměření na světlém i tmavém pozadí.';
	@override String get interaction => 'Pohyb a interakce';
	@override String get reduceMotion => 'Snížení pohybu';
	@override String get reduceMotionHint => 'Zastaví pohyb indikátoru zaměření, přechody stránek a dekorativní efekty.';
	@override String get largeTargets => 'větší cíle dotyku';
	@override String get largeTargetsHint => 'Dáváme sdíleným ovládacím prvkům více prostoru pro dotyk a asistenční navigaci.';
	@override String get navigationHint => 'Mezi ovládacími prvky se přesouvejte klávesami Tab a Shift+Tab, aktivujte je klávesou Enter nebo mezerníkem a zavírejte klávesou Escape nebo tlačítkem Zpět. Při otevřené knize je dostupné přiblížení a nastavení čtení.';
	@override String get textSizeDescription => 'Rozsah textového rozhraní v PlezyNG kromě nastavení velikosti textu systému vašeho zařízení.';
	@override String get boldTextHint => 'Použijte těžší váhu pro rozhraní etikety a zprávy, aby je jednodušší rozlišovat.';
}

// Path: tooltips
class _Translations$tooltips$cs extends Translations$tooltips$en {
	_Translations$tooltips$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Shuffle hraje';
	@override String get playTrailer => 'Hrajte trailer';
	@override String get markAsWatched => 'Mark jako sledovaný';
	@override String get markAsUnwatched => 'Mark jako nepozorovaný';
}

// Path: audioTracks
class _Translations$audioTracks$cs extends Translations$audioTracks$en {
	_Translations$audioTracks$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Zvukový pás ${n}';
}

// Path: videoControls
class _Translations$videoControls$cs extends Translations$videoControls$en {
	_Translations$videoControls$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Zvuk';
	@override String get subtitlesLabel => 'Titulky';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Textová krabička';
	@override String get fillScreen => 'vyplňte obrazovku';
	@override String get stretch => 'Roztáhnout';
	@override String get lockRotation => 'Závěsná rotace';
	@override String get unlockRotation => 'Odemknutí rotace';
	@override String get timerActive => 'Aktivní čas';
	@override String playbackWillPauseIn({required Object duration}) => 'Playback se zastaví v ${duration}';
	@override String get sleepTimerEndOfVideo => 'Konec aktuálního videa';
	@override String get sleepTimerStopAtHeader => 'Zastavte se';
	@override String get sleepTimerDurationHeader => 'Časový';
	@override String get playbackWillPauseAtEnd => 'Playback se zastaví na konci tohoto videa';
	@override String get stillWatching => 'Stále se díváte?';
	@override String pausingIn({required Object seconds}) => 'Odpočinek v ${seconds}s';
	@override String get continueWatching => 'pokračovat';
	@override String get autoPlayNext => 'Auto-Play Další';
	@override String get playNext => 'Přehrát jako další';
	@override String get playButton => 'Přehrát';
	@override String get pauseButton => 'Pozastavit';
	@override String get playbackPaused => 'Odpočinek';
	@override String get playbackResumed => 'Hrají';
	@override String get loadingVideo => 'nahrávání videa';
	@override String get showPlaybackControls => 'Zobrazit playback kontroly';
	@override String get hidePlaybackControls => 'Stáhněte si playback kontroly';
	@override String seekBackwardButton({required Object seconds}) => 'Hledat zpět ${seconds} sekund';
	@override String seekForwardButton({required Object seconds}) => 'Hledání vpřed ${seconds} sekund';
	@override String get previousButton => 'Předchozí epizoda';
	@override String get nextButton => 'Další díl';
	@override String get previousChapterButton => 'Předchozí kapitola';
	@override String get nextChapterButton => 'Další kapitola';
	@override String get muteButton => 'Ztlumit';
	@override String get unmuteButton => 'Povolit zvuk';
	@override String get settingsButton => 'Playback nastavení';
	@override String get tracksButton => 'Audio a subtituly';
	@override String get chaptersButton => 'Kapitoly';
	@override String get versionQualityButton => 'Verze a kvalita';
	@override String get versionColumnHeader => 'Verze';
	@override String get qualityColumnHeader => 'Kvalita';
	@override String get qualityOriginal => 'originál';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Překódování není k dispozici – hraje originální kvalitu';
	@override String get subtitleUnavailableFallback => 'Výběr vybraných titulů nelze nahrát – pokračovat bez titulů';
	@override String get pipButton => 'Obrazový režim - Picture in-Picture';
	@override String get aspectRatioButton => 'Poměr stran';
	@override String get ambientLighting => 'Atmosférické osvětlení';
	@override String get fullscreenButton => 'Vstup na plný obrazovek';
	@override String get exitFullscreenButton => 'Výstup na plný obrazovek';
	@override String get alwaysOnTopButton => 'Vždy na vrcholu';
	@override String get rotationLockButton => 'rotační zámek';
	@override String get lockScreen => 'Závěsný obrazovek';
	@override String get screenLockButton => 'Zámek obrazovky';
	@override String get timelineSlider => 'Video časové linie';
	@override String get volumeSlider => 'Úroveň objemu';
	@override String endsAt({required Object time}) => 'Končí na ${time}';
	@override String get pipActive => 'Hrají v Picture-in-Picture';
	@override String get pipFailed => 'Obrázek v obraze se neuskutečnil';
	@override String get screenshotSaved => 'Screenshot zachráněný';
	@override String get screenshotFailed => 'Nemohla jsem si pořídit screenshot';
	@override String zoomPercent({required Object percent}) => 'Přiblížení ${percent}%';
	@override String volumePercent({required Object percent}) => 'Hlasitost ${percent}%';
	@override late final _Translations$videoControls$pipErrors$cs pipErrors = _Translations$videoControls$pipErrors$cs._(_root);
	@override String get chapters => 'Kapitoly';
	@override String get noChaptersAvailable => 'Žádné kapitoly k dispozici';
	@override String get queue => 'Kouč';
	@override String get noQueueItems => 'Žádné položky v kousku';
	@override String get noAudioDevicesAvailable => 'Žádné audio zařízení k dispozici';
	@override String get searchSubtitles => 'Podtitul hledání';
	@override String get language => 'Jazyk';
	@override String get noSubtitlesFound => 'Žádné podtitulky nalezeny';
	@override String get subtitleDownloaded => 'Subtítky stažené';
	@override String get subtitleDownloadedNotApplied => 'Subtitle stažen, ale nemohl být vybrán';
	@override String get subtitleDownloadFailed => 'Nedokázal si stáhnout subtitle';
	@override String get searchLanguages => 'Vyhledávací jazyky...';
	@override String get skipIntro => 'Skříň vstupuje';
	@override String get skipCredits => 'Skok úvěrů';
	@override String get nextEpisode => 'Další díl';
	@override String subtitleTrack({required Object n}) => 'Původní číslo ${n}';
	@override String subtitleFile({required Object name}) => 'Článek ${name}';
	@override String forcedTrack({required Object label}) => '${label} (příslušný)';
	@override String get osdSubtitlesOff => 'Název titulu: Off';
	@override String osdSubtitles({required Object track}) => 'Články v kategorii: ${track}';
	@override String osdAudio({required Object track}) => 'Audio číslo: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímek',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímky',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímku',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímků',
	);
	@override String get trackSelectionTitle => 'Zvolte stopy před playbackem';
	@override String get trackSelectionAuto => 'Automatické výběr';
	@override String get openMiniPlayer => 'Otevřený mini hráč';
	@override String get returnToFullPlayer => 'Zpět na plný hráč';
	@override String get loadSubtitleFile => 'Přihláška souboru Subtitle...';
	@override String get subtitleLoadFailed => 'Nedokázal přenést soubor subtitle';
	@override String get skipAds => 'Skřípání Ads';
	@override String get tapToUnlock => 'Klepnutím odemknete';
	@override String get tapAgainToUnlock => 'Opětovným klepnutím odemknete';
}

// Path: messages
class _Translations$messages$cs extends Translations$messages$en {
	_Translations$messages$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'označené jako sledované';
	@override String get markedAsUnwatched => 'označené jako nepozorované';
	@override String get markedAsWatchedOffline => 'Zaznamenáno jako sledované (synchronizuje se, když je online)';
	@override String get markedAsUnwatchedOffline => 'Označen jako nepozorovaný (synchronizuje se, když je online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatické odstranění: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} sledované ke stažení',
		other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} sledované stahování',
	);
	@override String get removedFromContinueWatching => 'Odstranění z pokračování sledování';
	@override String errorLoading({required Object error}) => 'Chyba: ${error}';
	@override String get searchPartialResults => 'Některé mediální servery nemohou být vyhledávány. zobrazování dostupných výsledků.';
	@override String get streamInterrupted => 'Přehrávač byl přerušen. tisková hra nebo se snaží odstoupit.';
	@override String get liveStreamInterrupted => 'Přímý stream byl přerušen. tisková hra se vrací.';
	@override String get fileInfoNotAvailable => 'Informace o souborech nejsou k dispozici';
	@override String get playbackAuthenticationRequired => 'Přihlaste se k serveru médií znovu, abyste tuto položku hrali.';
	@override String get playbackServerUnavailable => 'Media server není k dispozici. zkuste znovu později.';
	@override String get playbackDataInvalid => 'Server vrátil neplatné informace o přehrávání.';
	@override String get playbackCancelled => 'Playback byl zrušen.';
	@override String get playbackFailed => 'Playback se nemohl zahájit.';
	@override String playbackFailedDetail({required Object error}) => 'Playback se nemohl spustit: ${error}';
	@override String get audioOutputFailed => 'Zkontrolujte audio připojení televizoru nebo přijímače; pokud jiné aplikace nemají ani zvuk, znovu spustit zařízení.';
	@override String get mediaUnavailable => 'Tento obsah již není k dispozici.';
	@override String errorLoadingFileInfo({required Object error}) => 'Informace o souboru chyby: ${error}';
	@override String get errorLoadingSeries => 'Chyby v seriálu';
	@override String get musicNotSupported => 'Hudební playback zatím není podporován';
	@override String get noDescriptionAvailable => 'Žádný popis k dispozici';
	@override String get noProfilesAvailable => 'Žádné profily k dispozici';
	@override String get contactAdminForProfiles => 'Kontaktujte správce serveru, abyste přidali profily';
	@override String get unableToDetermineLibrarySection => 'Není možné určit část knihovny pro tento položka';
	@override String get logsCleared => 'Logy vyčistěné';
	@override String get logsCopied => 'Přihlášky kopírované na clipboard';
	@override String get noLogsAvailable => 'Žádné logy k dispozici';
	@override String libraryScanning({required Object title}) => 'Skenování „${title}“';
	@override String libraryScanStarted({required Object title}) => 'Skenování knihovny začíná pro "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Knihovna se neskončila: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Znovuzavírací metadata pro "${title}..."';
	@override String metadataRefreshStarted({required Object title}) => 'Aktualizace metadata začíná pro "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Nepodařilo se aktualizovat metadata: ${error}';
	@override String get logoutConfirm => 'Jste si jisti, že se chcete přihlásit?';
	@override String get noSeasonsFound => 'Žádné sezóny nenajdeme';
	@override String get seasonsLoadFailed => 'Nemohla by se stahovat sezóny';
	@override String get noEpisodesFound => 'V první sezoně nebyly nalezeny žádné epizody';
	@override String get noEpisodesFoundGeneral => 'Žádné epizody nenajdete';
	@override String get episodesLoadFailed => 'Nemohl by se vyskytnout epizody';
	@override String get noResultsFound => 'Žádné výsledky.';
	@override String sleepTimerSet({required Object label}) => 'Časovač spánku nastavený pro ${label}';
	@override String get noItemsAvailable => 'Žádné položky k dispozici';
	@override String get failedToCreatePlayQueueNoItems => 'Neschopné vytvořit hřiště - žádné položky';
	@override String failedPlayback({required Object action, required Object error}) => 'Neúspěšný na ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Přepínání na kompatibilní hráče.';
	@override String get serverLimitTitle => 'Playback neuspěl';
	@override String get serverLimitBody => 'Serverová chyba (HTTP 500). omezení šířky pásma/transkódování pravděpodobně odmítlo tuto sezení.';
	@override String get mediaUnreadableTitle => 'Soubory nedostupné';
	@override String get mediaUnreadableBody => 'Server našel tento položka, ale nemohl si přečíst jeho soubor (HTTP 404). soubor byl pravděpodobně přemístěn, odstraněn, nebo jeho ukládání je offline.';
	@override String get serverBusyTitle => 'Stream nedostupný';
	@override String get serverBusyBody => 'Server odmítl streamovat tento soubor (HTTP 503).Může být restartující, zaneprázdněný, nebo souborové ukládání může být offline.Zkuste znovu v okamžiku - pokud se to stále děje, požádejte majitele serveru, aby zkontroloval server a ukládání souboru.';
	@override String get playbackNotAllowedTitle => 'Playback není povoleno';
	@override String get playbackNotAllowedBody => 'Server odmítl streamovat tento položka (HTTP 403). Váš účet nemusí mít povolení k jeho hraní, nebo server může umožnit pouze přehrávání na místní síti.';
	@override String get logsUploaded => 'Logové nahrávky';
	@override String get logsUploadFailed => 'Nepodařilo se nahrávat logy';
	@override String get logId => 'ID protokolu';
	@override String get burnedSubtitlesUseMenu => 'Podtituly jsou spáleny do tohoto toku. změnit je z podtitulového menu.';
	@override String get noVideoUrl => 'Žádný video URL není k dispozici';
	@override String get playbackNoMediaSources => 'Server nevrátil žádné přehrávané zdroje médií';
	@override String get playbackDataNotPrepared => 'Playback byl spuštěn dříve, než byly data hotová';
	@override String get streamSelectionUnavailable => 'Stream selection není k dispozici pro tento zdroj';
	@override String get streamSelectionFailed => 'Nemohou použít vybrané toky';
	@override String get trackSelectionNotRemembered => 'Tato volba track se vztahuje pouze na aktuální playback.';
	@override String get serverUnavailableForProfile => 'Server není k dispozici pro aktivní profil';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$cs extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Rychlý hnědý fox skočí nad lazy pes';
	@override String get text => 'Text';
	@override String get border => 'hranice';
	@override String get background => 'pozadí';
	@override String get fontSize => 'Zkratka velikost';
	@override String get textColor => 'Barva textu';
	@override String get borderSize => 'hraniční velikost';
	@override String get borderColor => 'hraniční barva';
	@override String get backgroundOpacity => 'Pozadí Opacity';
	@override String get backgroundColor => 'Barva pozadí';
	@override String get position => 'Pozice';
	@override String get assOverride => 'ASS Překročení';
	@override String get overrideScale => 'Skala';
	@override String get overrideForce => 'Síla';
	@override String get overrideStrip => 'Odstranění stylingu';
	@override String get positionTop => 'Top';
	@override String get positionBottom => 'Důvod';
	@override String get useMargins => 'Použití marže';
	@override String get useMarginsDescription => 'Umožňujte textové podtituly v prostoru mimo video. stylové podtituly mohou zachovat jejich původní umístění.';
	@override String get anchorToScreen => 'Anchor na obrazovce';
	@override String get anchorToScreenDescription => 'Zobrazit textové podtituly v černých čárovkách pod videem širokého obrazovky';
	@override String get bold => 'Tučné';
	@override String get italic => 'Italský';
	@override String get renderResolution => 'Renderová rezoluce';
	@override String get renderResolutionScreen => 'Rozlišení obrazovky';
	@override String get renderResolutionVideo => 'Rozlišení videa';
	@override String get fontSizeDescription => 'Na tomto zařízení nastavíte velikost podtitulu textu.';
	@override String get textColorDescription => 'Vyberte barvu použité pro text podtitulů.';
	@override String get borderSizeDescription => 'Nastavení tloušťky výstupu kolem podtitulového textu.';
	@override String get borderColorDescription => 'Zvolte barvu použité pro podtitulový výstup.';
	@override String get backgroundColorDescription => 'Zvolte barvu za textem.';
	@override String get backgroundOpacityDescription => 'Nastavte, jak transparentní je podtitulový pozadí: 0% je jasný a 100% pevný.';
	@override String get positionDescription => '0 % je horní část videa a 100 % dolní část.';
	@override String get assOverrideDescription => 'Vyberte, zda hráč sleduje, upravuje, nahrazuje nebo odstraňuje styling vložený do podtitulů ASS.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$cs assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$cs._(_root);
	@override String get renderResolutionDescription => 'Vyberte rozlišení používané k rasterizování obrazu a ASS podtitulů. nižší Android stupnice mohou snížit rendering práci, ale vypadat jemněji.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$cs renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$cs._(_root);
	@override String get boldDescription => 'Vložte text podtitulu v těžší hmotnosti.';
	@override String get italicDescription => 'Podtitulový text v italštině.';
}

// Path: mpvConfig
class _Translations$mpvConfig$cs extends Translations$mpvConfig$en {
	_Translations$mpvConfig$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Pokročilé nastavení videohrávače';
	@override String get presets => 'přednášky';
	@override String get noPresets => 'Žádné zachráněné předměty';
	@override String get saveAsPreset => 'Zachraňte jako předchozí...';
	@override String get presetName => 'Příslušný název';
	@override String get presetNameHint => 'Zadejte jméno pro tento předpis';
	@override String get loadPreset => 'zatížení';
	@override String get deletePreset => 'Odstranit';
	@override String get presetSaved => 'Prorok zachránil';
	@override String get presetLoaded => 'Přepočítání nabité';
	@override String get presetDeleted => 'Předpověď odstraněna';
	@override String get confirmDeletePreset => 'Jste si jisti, že chcete tuto předvolbu odstranit?';
	@override String get configPlaceholder => 'gpu-api=vulkan hwdec=auto # komentář';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Přidat linku';
	@override String get removeLine => 'Odstranění linie';
	@override String get embeddedVoHint => 'vo, gpu-kontext a gpu-api jsou ignorovány na Linux: vestavěné video vždy přenášejí prostřednictvím vo=libmpv na videu, a gpu-next (které počítačové odstíny, jako je ArtCNN potřebuje) nemůže spustit vestavěné.';
}

// Path: dialog
class _Translations$dialog$cs extends Translations$dialog$en {
	_Translations$dialog$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Potvrzení akce';
}

// Path: profiles
class _Translations$profiles$cs extends Translations$profiles$en {
	_Translations$profiles$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Přidat profil PlezyNG';
	@override String get switchingProfile => 'Přepínání profilu...';
	@override String get deleteThisProfileTitle => 'Vymazat tento profil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Odstranit ${displayName}. připojení není ovlivněno.';
	@override String get active => 'aktivní';
	@override String get manage => 'Řízení';
	@override String get delete => 'Odstranit';
	@override String get signOut => 'Odhlásit se';
	@override String get signOutPlexTitle => 'Přihlásit se na číslo Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Odstranit ${displayName} a všechny Plex Domácí uživatelé?';
	@override String get signOutPlexDeleteDownloads => 'Také odstranit downloads';
	@override String get signOutPlexDeleteDownloadsDescription => 'Jinak zůstanou na tomto zařízení a přijdou zpět, když se přihlásíte zpět na tento účet.';
	@override String get signedOutPlex => 'Podepsané z Plex.';
	@override String get signOutFailed => 'Podepisovat se selhal.';
	@override String get sectionTitle => 'profilů';
	@override String get summarySingle => 'Přidejte profily ke smíchání spravovaných uživatelů a místních identit';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profily · aktivní: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profily';
	@override String get removeConnectionTitle => 'Odstranit spojení?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Odstranit přístup ${displayName} na ${connectionLabel}. Ostatní profily ho uchovávají.';
	@override String get deleteProfileTitle => 'Vymazat profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Odstranit ${displayName} a jeho připojení. servery zůstávají k dispozici.';
	@override String get profileNameLabel => 'Profilní název';
	@override String get pinProtectionLabel => 'PIN ochrana';
	@override String get copyAutomationLink => 'Kopírování Android automatizace odkaz';
	@override String get copyAutomationLinkDescription => 'Vyberte tento profil z účelu nebo automatizace Android.';
	@override String get automationLinkCopied => 'Profilová automatizace odkaz kopírovaný.';
	@override String get pinManagedByPlex => 'PIN je spravován Plex. Edit on plex.tv.';
	@override String get noPinSetEditOnPlex => 'Není nastavení PIN. Chcete-li požadovat jeden, upravte domácí uživatel na plex.tv.';
	@override String get setPin => 'nastavení PIN';
	@override String get setPinTitle => 'nastavení PIN';
	@override String get confirmPinTitle => 'Potvrzení PIN';
	@override String get pinSet => 'PIN nastavení';
	@override String get changePin => 'Změna';
	@override String get removePin => 'Odstranit';
	@override String get connectionsLabel => 'připojení';
	@override String get add => 'Přidat';
	@override String get deleteProfileButton => 'Vymazat profil';
	@override String get noConnectionsHint => 'Žádné připojení – přidejte jeden pro použití tohoto profilu.';
	@override String get noConnections => 'Žádné spojení';
	@override String get plexHomeAccount => 'Plex Domácí účet';
	@override String plexAccountChip({required Object account}) => 'Plex účet: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} prostřednictvím ${account}';
	@override String get connectionDefault => 'Výchozí';
	@override String connectionAs({required Object displayName}) => 'jako ${displayName}';
	@override String get makeDefault => 'Zkuste default';
	@override String get removeConnection => 'Odstranit';
	@override String get profileRenamed => 'Profil se přejmenoval.';
	@override String borrowAddTo({required Object displayName}) => 'Přidat na ${displayName}';
	@override String get borrowExplain => 'Půjčte si připojení jiného profilu. PIN-ochráněné profily vyžadují PIN.';
	@override String get borrowEmpty => 'Zatím není co půjčit.';
	@override String get borrowEmptySubtitle => 'Nejprve se připojte k jinému profilu Plex, Jellyfin, nebo Emby.';
	@override String get borrowLoadFailed => 'Dostupné připojení nelze nahrát. zkuste znovu.';
	@override String borrowFromProfile({required Object displayName}) => 'od ${displayName}';
	@override String get borrowConnectionBorrowed => 'Připojení je půjčováno.';
	@override String get borrowFailed => 'Nepodařilo se půjčit spojení.';
	@override String get incorrectPin => 'Nesprávný PIN.';
	@override String get incorrectPinTryAgain => 'Zrušte PIN, zkuste prosím znovu.';
	@override String get sourceProfileMissingParentAccount => 'Zdrojový profil chybí jeho rodičovský účet.';
	@override String get failedToLoadHomeUsers => 'Nemohla jste si stáhnout své uživatele Plex Domácí uživatelé. zkontrolujte připojení a zkuste znovu.';
	@override String get failedToVerifyPin => 'Nemohl ověřit PIN.';
	@override String get newProfile => 'Nový profil';
	@override String get profileNameHint => 'Dětské pokoje, rodinné pokoje, rodinné pokoje';
	@override String get pinProtectionOptional => 'Ochrana PIN (opční)';
	@override String get pinExplain => '4D PIN je nutný pro přepínání profilů.';
	@override String get continueButton => 'pokračovat';
	@override String get pinsDontMatch => 'PIN se neshoduje';
	@override String get tokenIdentityMismatch => 'Profilový token Plex byl vyřešen na neočekávaném serveru';
	@override String get settingsLocked => 'Nastavení jsou pro tento profil zablokovány.';
	@override String get unlockSettings => 'Odemknout nastavení';
	@override String get showExploreForProfile => 'Zobrazit prohlídku pro tento profil';
	@override String get showExploreForProfileDescription => 'Odstranit a odstranit Explore z navigace tohoto profilu.';
}

// Path: connections
class _Translations$connections$cs extends Translations$connections$en {
	_Translations$connections$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'připojení';
	@override String get addConnection => 'Přidejte připojení';
	@override String get addConnectionSubtitleNoProfile => 'Přihlaste se k serveru Plex nebo připojte se k serveru Jellyfin nebo Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Přidat na ${displayName}: Plex, Jellyfin, Emby, nebo jinou profilu připojení';
	@override String sessionExpiredOne({required Object name}) => 'Závěrečná schůze pro ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sezóna skončila pro servery ${count}';
	@override String accessDeniedOne({required Object name}) => '${name} odmítl přístup k tomuto účtu';
	@override String accessDeniedMany({required Object count}) => '${count} servery odmítly přístup k tomuto účtu';
	@override String get signInAgain => 'Podepisujte se znovu';
	@override String editMediaBrowserTitle({required Object product}) => 'Edit ${product} připojení';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Přidat nebo odstranit URL pro ${serverName}. PlezyNG bude používat přístupné URL s nejnižší latencí.';
}

// Path: accountPreferences
class _Translations$accountPreferences$cs extends Translations$accountPreferences$en {
	_Translations$accountPreferences$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'účetní preference';
	@override String hubSubtitleSingle({required Object account}) => 'Možnosti audio, podtitulů a knihovny uložené na ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Možnosti audio, podtitulů a knihovny uložené na účtech ${count}';
	@override String get pickAccount => 'Každý účet ukládá své vlastní preference. vyberte ten, který chcete upravit.';
	@override String get storedOnAccount => 'Tyto možnosti jsou uloženy na samotném účtu, takže každá aplikace, která se k němu přihlásí, je používá – včetně PlezyNG na vašich jiných zařízeních.';
	@override String get noAccounts => 'Žádné účty, které by se měly nastavit';
	@override String get noAccountsHint => 'Přihlaste se na Plex, nebo se připojte na server Jellyfin nebo Emby, a preference uložené na tomto účtu se zobrazí zde.';
	@override String get unavailable => 'Nemůžete tento účet získat';
	@override String get loadFailed => 'Tyto preference nemůžu nabít';
	@override String get noPreference => 'Žádná preference';
	@override String get notSet => 'Není nastaven';
	@override late final _Translations$accountPreferences$groups$cs groups = _Translations$accountPreferences$groups$cs._(_root);
	@override String get preferredAudioLanguage => 'Preferovaný jazyk zvuku';
	@override String get autoSelectAudio => 'Výběr audio podle jazyka';
	@override String get autoSelectAudioDescription => 'Odstraní jakýkoliv zvuk sleduje soubor označuje jako výchozí.';
	@override String get preferredSubtitleLanguage => 'Preferovaný jazyk titulků';
	@override String get subtitleMode => 'Přepínání podtitulů na';
	@override late final _Translations$accountPreferences$subtitleModes$cs subtitleModes = _Translations$accountPreferences$subtitleModes$cs._(_root);
	@override String get subtitleAccessibility => 'Podtitul SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$cs subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$cs._(_root);
	@override String get forcedSubtitles => 'Povinné podtitulky';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$cs forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$cs._(_root);
	@override String get displayMissingEpisodes => 'Zobrazit chybějící epizody';
	@override String get displayMissingEpisodesDescription => 'Seznam epizod, o kterých server ví, ale nemá žádné soubory.';
	@override String get hidePlayedInLatest => 'Ukryte sledované položky v Poslední';
	@override String get hidePlayedInLatestDescription => 'Zanechte položky, které jste již sledovali z nejnovějších řádků serveru.';
	@override String get displayCollectionsView => 'Zobrazit pohled na kolekce';
	@override String get displayCollectionsViewDescription => 'Nabídněte zobrazení kolekcí serveru vedle vašich knihoven.';
	@override String get rewatchingInNextUp => 'Zůstaňte pozorně sledováni v Next Up';
	@override String get rewatchingInNextUpDescription => 'Jakmile dokončíte show, začněte znovu a Next Up sleduje rewatch místo toho, aby show ztratil.';
	@override String get watchedIndicator => 'Pozorované ukazatele';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$cs watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$cs._(_root);
	@override String get mediaReviewsVisibility => 'Hodnocení & recenze';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$cs mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$cs._(_root);
	@override String get preferredAudioLanguageDescription => 'Upřednostňuje zvukové stopy v tomto jazyce, když server nebo přehrávač automaticky vybere stopu.';
	@override String get preferredSubtitleLanguageDescription => 'Doporučuje se sledovat podtituly v tomto jazyce, když jsou subtituly automaticky vybrány.';
	@override String get subtitleAccessibilityDescription => 'Vyberte, zda jsou SDH captions preferovány nebo požadovány během automatického výběru podtitulů.';
	@override String get forcedSubtitleDescription => 'Vyberte si, zda jsou při automatickém výběru preferovány nebo požadovány nucené podtitulové stopy.';
	@override String get watchedIndicatorDescription => 'Vyberte, které typy médií obdrží sledovanou kontrolu v rozhraní serveru.';
	@override String get mediaReviewsVisibilityDescription => 'Vyberte, které publikum a kritické hodnocení server zobrazuje na stránkách médií.';
	@override String get subtitleModeDescription => 'Vyberte, kdy se podtituly automaticky zapnou pro tento serverový účet.';
	@override String get hubDescription => 'Tyto preference jsou uloženy na vašem účtu mediálního serveru a mohou se vztahovat i na ostatní klienty.';
}

// Path: discover
class _Translations$discover$cs extends Translations$discover$en {
	_Translations$discover$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Objevovat';
	@override String get noContentAvailable => 'Žádný obsah k dispozici';
	@override String get addMediaToLibraries => 'Přidejte nějaké média do knihoven';
	@override String get continueWatching => 'Pokračovat ve sledování';
	@override String continueWatchingIn({required Object library}) => 'Podívejte se na stránku ${library}';
	@override String get nextUp => 'Další díly';
	@override String nextUpIn({required Object library}) => 'Předchozí Článek ${library}';
	@override String get recentlyAdded => 'Nedávno přidáno';
	@override String recentlyAddedIn({required Object library}) => 'Nedávno přidáno v ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Nejnovější album v ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Nedávno přehráno v knihovně ${library}';
	@override String mostPlayedIn({required Object library}) => 'Nejvíce hrají v ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Přehled';
	@override String get cast => 'Castová';
	@override late final _Translations$discover$findNext$cs findNext = _Translations$discover$findNext$cs._(_root);
	@override String get extras => 'Trailery a extras';
	@override String get studio => 'Studio';
	@override String get rating => 'Hodnocení';
	@override String get director => 'Režisér';
	@override String get directors => 'Režiséři';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV show';
	@override String minutesLeft({required Object minutes}) => 'Zbývá ${minutes} min';
	@override String get moreLikeThis => 'Podobné položky';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titul',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tituly',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titulu',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titulů',
	);
	@override late final _Translations$discover$person$cs person = _Translations$discover$person$cs._(_root);
}

// Path: errors
class _Translations$errors$cs extends Translations$errors$en {
	_Translations$errors$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Vyhledávání selhalo: ${error}';
	@override String get searchUnavailable => 'Vyhledávání se nedá dostat na žádný mediální server.';
	@override String connectionTimeout({required Object context}) => 'Připojení do času při nabíjení ${context}';
	@override String get connectionFailed => 'Neschopnost připojit se k mediálnímu serveru';
	@override String unableToLoad({required Object context}) => 'Není možné nabíjet ${context}. prosím zkuste znovu.';
	@override String get noClientAvailable => 'Žádný zákazník k dispozici';
	@override String get pleaseEnterToken => 'Vložte prosím token';
	@override String get invalidToken => 'Invalidní token';
	@override String failedToVerifyToken({required Object error}) => 'Neuvěřený token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Přepínání na ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Neuspěl odstranit ${displayName}';
	@override String get failedToRate => 'Nemůžu aktualizovat rating';
	@override String get reasonTimedOut => 'Připojení je vyprázdněno';
	@override String get reasonUnreachable => 'server nemůže být přístupný';
	@override String get reasonRefused => 'server odmítl žádost';
	@override String get reasonNotFound => 'Už není na serveru.';
	@override String get reasonServerError => 'server oznámil chybu';
	@override String get reasonCancelled => 'Žádost byla zrušena';
	@override String get reasonUnexpected => 'Nečekaná chyba se stala';
}

// Path: libraries
class _Translations$libraries$cs extends Translations$libraries$en {
	_Translations$libraries$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Zahrajte si náhodný film';
	@override String get randomPickFailed => 'Nemohla bych si vybrat náhodný film z této knihovny.';
	@override String get title => 'Knihovny';
	@override String get fallbackTitle => 'Knihovna';
	@override String get scanLibraryFiles => 'Scan knihovny souborů';
	@override String get scanLibrary => 'Skenovat knihovnu';
	@override String get analyze => 'Analýza';
	@override String get analyzeLibrary => 'Analýza knihovny';
	@override String get refreshMetadata => 'Aktualizovat metadata';
	@override String get emptyTrash => 'prázdný trash';
	@override String emptyingTrash({required Object title}) => 'Vybavení odpadků pro "${title}..."';
	@override String trashEmptied({required Object title}) => 'Zpět na téma „${title}“';
	@override String failedToEmptyTrash({required Object error}) => 'Nepodařilo se prázdné odpadky: ${error}';
	@override String analyzing({required Object title}) => 'Zpět na téma „${title}“';
	@override String analysisStarted({required Object title}) => 'Analýza začala pro "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Neuspěl analyzovat knihovnu: ${error}';
	@override String get noLibrariesFound => 'Žádné knihovny nenajdete';
	@override String get allLibrariesHidden => 'Všechny knihovny jsou skryté';
	@override String hiddenLibrariesCount({required Object count}) => 'Skryté knihovny (${count})';
	@override String get thisLibraryIsEmpty => 'Tato knihovna je prázdná';
	@override String get noItemsMatchFilters => 'Žádné položky se neshodují s aktivními filtry';
	@override String get resetFilters => 'Vymazat filtry';
	@override String get all => 'Vše';
	@override String get clearAll => 'Jasné vše';
	@override String scanLibraryConfirm({required Object title}) => 'Jste si jisti, že chcete skenovat "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Jste si jisti, že chcete analyzovat "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Jste si jisti, že chcete aktualizovat metadata pro "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Jste si jisti, že chcete prázdný odpad pro "${title}"?';
	@override String get manageLibraries => 'Řízení knihoven';
	@override String get sort => 'Třídit';
	@override String get sortBy => 'Třídit dle';
	@override String get filters => 'Filtry';
	@override String get confirmActionMessage => 'Jste si jisti, že chcete tuto akci provést?';
	@override String get showLibrary => 'Zobrazit knihovnu';
	@override String get hideLibrary => 'Skryté knihovny';
	@override String get libraryOptions => 'Možnosti knihovny';
	@override String get content => 'Obsah knihovny';
	@override String get selectLibrary => 'Vyberte knihovnu';
	@override String filtersWithCount({required Object count}) => 'Filtry (${count})';
	@override String get noRecommendations => 'Žádné doporučení k dispozici';
	@override String get noCollections => 'Žádné sbírky v této knihovně';
	@override String get noFoldersFound => 'Žádné složky nenajdete';
	@override String get folders => 'Složky';
	@override late final _Translations$libraries$tabs$cs tabs = _Translations$libraries$tabs$cs._(_root);
	@override late final _Translations$libraries$groupings$cs groupings = _Translations$libraries$groupings$cs._(_root);
	@override late final _Translations$libraries$filterCategories$cs filterCategories = _Translations$libraries$filterCategories$cs._(_root);
	@override late final _Translations$libraries$sortLabels$cs sortLabels = _Translations$libraries$sortLabels$cs._(_root);
	@override late final _Translations$libraries$advancedFilters$cs advancedFilters = _Translations$libraries$advancedFilters$cs._(_root);
	@override late final _Translations$libraries$selection$cs selection = _Translations$libraries$selection$cs._(_root);
}

// Path: about
class _Translations$about$cs extends Translations$about$en {
	_Translations$about$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'o';
	@override String get openSourceLicenses => 'Licence Open Source';
	@override String versionLabel({required Object version}) => 'Zpětná verze ${version}';
	@override String get appDescription => 'Krásný klient Plex, Jellyfin a Emby pro Flutter';
	@override String get viewLicensesDescription => 'Zobrazit licence knihoven třetích stran';
	@override String get privacyPolicy => 'Politika soukromí';
}

// Path: serverSelection
class _Translations$serverSelection$cs extends Translations$serverSelection$en {
	_Translations$serverSelection$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Žádné servery nalezeny pro ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Neschopné nabíjet servery: ${error}';
	@override String get noValidServers => 'Na tomto účtu nebyly nalezeny žádné použitelné servery';
}

// Path: hubDetail
class _Translations$hubDetail$cs extends Translations$hubDetail$en {
	_Translations$hubDetail$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Název';
	@override String get releaseYear => 'Roku uvolnění';
	@override String get dateAdded => 'Datum přidání';
	@override String get rating => 'Hodnocení';
	@override String get noItemsFound => 'Žádné položky nenajdete';
}

// Path: logs
class _Translations$logs$cs extends Translations$logs$en {
	_Translations$logs$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Čistý log';
	@override String get copyLogs => 'Kopírování logů';
	@override String get uploadLogs => 'Přihlašování logů';
	@override String get saveLogs => 'Shromažďujte záznamy do souboru';
	@override String logsSaved({required Object path}) => 'Přihlášky uložené na ${path}';
	@override String get saveLogsFailed => 'Nemohla jsem uložit soubor.';
}

// Path: startup
class _Translations$startup$cs extends Translations$startup$en {
	_Translations$startup$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG nemohl začít';
	@override String get failedBody => 'Něco se během start-upu zhroutilo. podrobnosti níže identifikují to, co selžilo.';
	@override String get failedBodyRepairable => 'Uložený soubor nastavení PlezyNG je poškozený a před spuštěním aplikace je nutné jej znovu vytvořit. Další pokus nepomůže — zvolte opravu úložiště.';
	@override String get phaseLabel => 'Krok';
	@override String get showDetails => 'Zobrazit detaily';
	@override String get hideDetails => 'skryte detaily';
	@override String get copyDetails => 'Kopírování detailů';
	@override String get detailsCopied => 'Podrobnosti kopírovány na clipboard';
	@override String get uploadDetails => 'Upload podrobnosti';
	@override String get repairStorage => 'Oprava skladování';
	@override String get repairTitle => 'Opravy uložených dat?';
	@override String get repairBodyCommon => 'Soubor nastavení PlezyNG je poškozen a nelze ho přečíst. opravy obnoví každé nastavení na své výchozí.';
	@override String get repairBodyOneCredential => 'Jeden uložený sign-in je poškozen a nemůže být přečten. opravy odstraní pouze ten jeden; vaše ostatní nastavení jsou ponechány samy.';
	@override String get repairBodySignInsKept => 'Přihlášení k vašim serverům a profilům by mělo zůstat zachováno.';
	@override String get repairBodySignInsLost => 'Klíč chránící uložené přihlašovací údaje nelze z tohoto souboru obnovit, takže se budete muset znovu přihlásit ke každému serveru a profilu. Na mediálním serveru se nic nezmění.';
	@override String get repairBodySessionsUncertain => 'Údaje služeb MAL, AniList, Simkl, Trakt a Seerr se ukládají samostatně a mohou, ale nemusí zůstat zachovány. PlezyNG vám přesně sdělí, co zachovalo.';
	@override String get repairConfirm => 'Opravy';
	@override String get repairSucceeded => 'Úložné opravy';
	@override String get repairNeedsRestart => 'Uložení opravené – nutné restartování';
	@override String get restartRequiredBody => 'Vaše data byla opravena, ale PlezyNG je může použít až po novém spuštění. Zavřete PlezyNG a znovu jej otevřete.';
	@override String get quitPlezy => 'Zpět PlezyNG';
	@override String get repairFailed => 'Oprava selhala';
	@override String get repairKeptSignIns => 'K serverům a profilům jste stále přihlášeni.';
	@override String get repairLostSignIns => 'Klíč chránící uložené přihlašovací údaje se nepodařilo obnovit. Budete se muset znovu přihlásit ke každému serveru a profilu.';
	@override String get repairLostSessions => 'Nejméně jeden tracker nebo spojení Seerr bylo ztraceno a musí být znovu připojeno.';
	@override String get backupTitle => 'Kopie poškozeného souboru byla zachována';
	@override String get backupWarning => 'Obsahuje vaše přihlašovací údaje. Nenahrávejte ji ani ji nesdílejte.';
	@override String get deleteBackup => 'Vymazat kopii';
	@override String get backupDeleted => 'Kopie je vymazána.';
	@override String get previousFailureTitle => 'PlezyNG neuspěl naposledy';
}

// Path: licenses
class _Translations$licenses$cs extends Translations$licenses$en {
	_Translations$licenses$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'související balíčky';
	@override String get license => 'Licence';
	@override String licenseNumber({required Object number}) => 'Licence ${number}';
	@override String licensesCount({required Object count}) => '${count} licencí';
}

// Path: navigation
class _Translations$navigation$cs extends Translations$navigation$en {
	_Translations$navigation$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Knihovny';
	@override String get downloads => 'Stažené soubory';
	@override String get liveTv => 'Živé vysílání';
	@override String get explore => 'Prozkoumejte';
}

// Path: explore
class _Translations$explore$cs extends Translations$explore$en {
	_Translations$explore$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$cs mdblistShelves = _Translations$explore$mdblistShelves$cs._(_root);
	@override String get title => 'Prozkoumejte';
	@override String get selectSource => 'Vyberte zdroj';
	@override late final _Translations$explore$rows$cs rows = _Translations$explore$rows$cs._(_root);
	@override late final _Translations$explore$status$cs status = _Translations$explore$status$cs._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod',
	);
	@override String get cast => 'Castová';
	@override String get characters => 'Charaktery';
	@override String get addToWatchlist => 'Přidejte na Watchlist';
	@override String get removeFromWatchlist => 'Odstranit z Watchlist';
	@override String get addedToWatchlist => 'Přidáno na watchlist';
	@override String get removedFromWatchlist => 'Odstranění z watchlist';
	@override String get watchlistUpdateFailed => 'Nemůžu aktualizovat watchlist';
	@override String get watchlistNoMatch => 'Nemohla by se tento položka shodovat s seznamem pozorovatelů';
	@override String get notInLibrary => 'Ne v knihovně';
	@override String get inTheseLibraries => 'V těchto knihovnách';
	@override String get checkingLibrary => 'Zkontrolujte svou knihovnu...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Nemůžu ověřit server ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: 'Nemohla jsem ověřit servery ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
	);
	@override String get emptyTitle => 'Nic zde zatím';
	@override String emptyMessage({required Object source}) => 'Čerpadla z ${source} se zde objeví, jakmile mají obsah.';
	@override String searchHint({required Object source}) => 'Vyhledávání ${source}';
	@override String searchEmpty({required Object query}) => 'Žádné výsledky pro "${query}"';
	@override String searchPrompt({required Object source}) => 'Hledat filmy a představení na ${source}.';
	@override String get searchFailed => 'Vyhledávání selhalo. zkontrolujte připojení a zkuste znovu.';
	@override late final _Translations$explore$badge$cs badge = _Translations$explore$badge$cs._(_root);
	@override late final _Translations$explore$stats$cs stats = _Translations$explore$stats$cs._(_root);
	@override late final _Translations$explore$season$cs season = _Translations$explore$season$cs._(_root);
	@override late final _Translations$explore$format$cs format = _Translations$explore$format$cs._(_root);
	@override late final _Translations$explore$sourceMaterial$cs sourceMaterial = _Translations$explore$sourceMaterial$cs._(_root);
	@override late final _Translations$explore$creditRole$cs creditRole = _Translations$explore$creditRole$cs._(_root);
	@override late final _Translations$explore$relation$cs relation = _Translations$explore$relation$cs._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Airs ${day} na ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Airs ${day} na ${time} ${timezone}';
	@override late final _Translations$explore$detail$cs detail = _Translations$explore$detail$cs._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledek',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledky',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledku',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledků',
	);
}

// Path: liveTv
class _Translations$liveTv$cs extends Translations$liveTv$en {
	_Translations$liveTv$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Živé vysílání';
	@override String get guide => 'Programový průvodce';
	@override String get noChannels => 'Žádné dostupné kanály';
	@override String get noDvr => 'Žádný DVR na serveru není nastaven';
	@override String get serverUnavailable => 'Live TV server není k dispozici.';
	@override String get serverNotConnected => 'Live TV server není připojen.';
	@override String get noPrograms => 'Žádné dostupné programové údaje';
	@override String get liveStreamFailed => 'Live Stream neúspěšný';
	@override String get unknownProgram => 'Neznámý program';
	@override String get timelineLiveProgram => 'Live program (playback může být mimo tento program)';
	@override String get timelineBuffer => 'Buffer časový řádek';
	@override String get timelineUnavailable => 'Časová linka nedostupná';
	@override String get timelineEstimated => 'Hodnocení playback';
	@override String get timelinePending => 'Hledání';
	@override String get timelineStale => 'Schéma může být zastaralá';
	@override String get unknownHub => 'Neznámý';
	@override String get unknownError => 'Neznámá chyba';
	@override String channelNumber({required Object number}) => 'Kanál ${number}';
	@override String get unknownChannel => 'Neznámý kanál';
	@override String get live => 'Živě';
	@override String get premiereBadge => 'Nový';
	@override String get reloadGuide => 'Reload průvodce';
	@override String get searchGuide => 'Vyhledávací průvodce';
	@override String get searchHint => 'Vyhledávací kanály a programy';
	@override String searchNoResults({required Object query}) => 'Žádné zápasy pro "${query}"';
	@override String get channelsSection => 'Kanály';
	@override String get programsSection => 'Programy';
	@override String get now => 'Nyní';
	@override String get today => 'Dneska';
	@override String get tomorrow => 'Zítra';
	@override String get midnight => 'půlnoci';
	@override String get overnight => 'Večerní';
	@override String get morning => 'Ráno';
	@override String get daytime => 'Dnešní čas';
	@override String get evening => 'Večerní';
	@override String get lateNight => 'Pozdní noc';
	@override String get whatsOn => 'Co je na';
	@override String get watchChannel => 'Podívejte se na Channel';
	@override String get favorites => 'Oblíbené';
	@override String get reorderFavorites => 'Oblíbené Reader';
	@override String get noFavoriteChannels => 'Žádné oblíbené kanály';
	@override String get noFavoriteChannelsHint => 'Zobrazit všechny kanály, pak dlouhodobě stiskněte kanál, aby ho přidali k vašim oblíbeným.';
	@override String get showAllChannels => 'Zobrazit všechny kanály';
	@override String get favoritesLoadFailed => 'Nemůžete si stáhnout oblíbené. zkontrolujte připojení a zkuste znovu.';
	@override String get favoritesUpdateFailed => 'Nemůžete aktualizovat oblíbené. zkontrolujte připojení a zkuste znovu.';
	@override String get joinSession => 'Připojte se k setkání v pokroku';
	@override String watchFromStart({required Object minutes}) => 'Sledovat od začátku (před ${minutes} min)';
	@override String get watchLive => 'Podívejte se živě';
	@override String get goToLive => 'Jděte žít';
	@override String get record => 'Záznam';
	@override String get recordEpisode => 'Rekordní epizoda';
	@override String get recordSeries => 'Nahrát série';
	@override String get recordOptions => 'Rekordní možnosti';
	@override String get saveTo => 'Zachraňte na';
	@override String get recordings => 'Nahrávky';
	@override String get scheduledRecordings => 'plánované';
	@override String get recordingRules => 'Pravidla nahrávání';
	@override String get noScheduledRecordings => 'Nic není naplánováno k nahrávání';
	@override String get manageRecording => 'Spravovat nahrávání';
	@override String get cancelRecording => 'Zrušit nahrávání';
	@override String get cancelRecordingTitle => 'Zrušit tuto nahrávku?';
	@override String cancelRecordingMessage({required Object title}) => '${title} již nebude zaznamenán.';
	@override String get deleteRule => 'Odstranit pravidlo';
	@override String get deleteRuleTitle => 'Zrušíte pravidlo nahrávání?';
	@override String deleteRuleMessage({required Object title}) => 'Budoucí epizody čísla ${title} nebudou zaznamenány.';
	@override String get recordingScheduled => 'Plán nahrávání.';
	@override String get alreadyScheduled => 'Tento program je již naplánován';
	@override String get dvrAdminRequired => 'Nastavení DVR vyžaduje účet administrátora';
	@override String get recordingFailed => 'Nemohla jsem plánovat nahrávání';
	@override String get recordingTargetMissing => 'Nemohla jsem si vybrat knihovnu';
	@override String get recordNotAvailable => 'Záznam není k dispozici pro tento program';
	@override String get recordingCancelled => 'Záznam zrušen';
	@override String get recordingRuleDeleted => 'Pravidlo nahrávání vymazáno';
	@override String get processRecordingRules => 'Znovu hodnocená pravidla';
	@override String get recordingInProgress => 'nahrávka nyní';
	@override String recordingsCount({required Object count}) => '${count} předpověď';
	@override String get editRule => 'Edit pravidla';
	@override String get editRuleAction => 'Upravit';
	@override String get recordingRuleUpdated => 'Pravidla nahrávání aktualizována';
	@override String get guideReloadRequested => 'Návod k obnovení požadovaný';
	@override String get guideReloadFailed => 'Nemohla jsem si přečíst průvodce';
	@override String get rulesProcessRequested => 'Pravidla přehodnocení požadovaná';
	@override String get rulesProcessFailed => 'Nemohla bych přehodnotit pravidla nahrávání';
	@override String get recordShow => 'Rekordní show';
	@override late final _Translations$liveTv$recordSettings$cs recordSettings = _Translations$liveTv$recordSettings$cs._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Začátek v ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} na ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} vrátil neplatné Live TV přehrávače data';
	@override String get failedToStartChannel => 'Nemohla jsem zahájit živý kanál';
	@override String get failedToBuildStreamUrl => 'Nemohl jsem vytvořit stream URL';
	@override String playbackStartFailed({required Object reason}) => 'Nemohla jsem spustit kanál: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Nemohla by se přepínat kanál: ${reason}';
}

// Path: collections
class _Translations$collections$cs extends Translations$collections$en {
	_Translations$collections$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kolekce';
	@override String get collection => 'Kolekce';
	@override String get empty => 'Kolekce je prázdná';
	@override String get deleteCollection => 'Odstranit kolekci';
	@override String deleteConfirm({required Object title}) => 'Smazat „${title}“? Tuto akci nelze vrátit zpět.';
	@override String get deleted => 'Kolekce odstraněna';
	@override String get deleteFailed => 'Neschopnost odstranit sbírku';
	@override String deleteFailedWithError({required Object error}) => 'Neschopné odstranit sbírku: ${error}';
	@override String get selectCollection => 'Vyberte kolekci';
	@override String get collectionName => 'Název kolekce';
	@override String get enterCollectionName => 'Vložte název kolekce';
	@override String get addedToCollection => 'Přidáno do sbírky';
	@override String get errorAddingToCollection => 'Nedokázal přidat do sbírky';
	@override String get created => 'Sbírka vytvořená';
	@override String get removeFromCollection => 'Odebrat z kolekce';
	@override String removeFromCollectionConfirm({required Object title}) => 'Odebrat „${title}“ z této kolekce?';
	@override String get removedFromCollection => 'Odstranění z kolekce';
	@override String get removeFromCollectionFailed => 'Neschopnost odstranit ze sbírky';
	@override String removeFromCollectionError({required Object error}) => 'Odstranění chyb z sběru: ${error}';
	@override String get searchCollections => 'Vyhledávací sbírky...';
}

// Path: playlists
class _Translations$playlists$cs extends Translations$playlists$en {
	_Translations$playlists$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seznamy skladeb';
	@override String get playlist => 'Seznam skladeb';
	@override String get noPlaylists => 'Žádné playlisty nenajdeme';
	@override String get create => 'Vytvořte playlist';
	@override String get playlistName => 'Playlist název';
	@override String get enterPlaylistName => 'Vložte název playlist';
	@override String get delete => 'Odstranit seznam skladeb';
	@override String get removeItem => 'Odebrat ze seznam skladeb';
	@override String get smartPlaylist => 'Inteligentní playlist';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položka',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položky',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položky',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položek',
	);
	@override String get emptyPlaylist => 'Tento playlist je prázdný';
	@override String get deleteConfirm => 'Vymažte si playlist?';
	@override String deleteMessage({required Object name}) => 'Jste si jisti, že chcete odstranit „${name}“?';
	@override String get created => 'Playlist vytvořený';
	@override String get deleted => 'Playlist vymazané';
	@override String get itemAdded => 'Přidáno do playlist';
	@override String get itemRemoved => 'Odstranění z playlist';
	@override String get selectPlaylist => 'Vyberte Playlist';
	@override String get searchPlaylists => 'Vyhledávání playlistů...';
	@override String get errorCreating => 'Neudělal si playlist';
	@override String get errorDeleting => 'Nepodařilo se vymazat playlist';
	@override String get errorLoading => 'Nedokázal přenášet playlisty';
	@override String get errorAdding => 'Nedokázal přidat do playlist';
	@override String get errorReordering => 'Nedokázal přepracovat položky playlist';
	@override String get errorRemoving => 'Neschopnost odstranit z playlist';
}

// Path: music
class _Translations$music$cs extends Translations$music$en {
	_Translations$music$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Přejděte na album';
	@override String get goToArtist => 'Přejděte k umělci';
	@override String get instantMix => 'Rychlý mix';
	@override String get playNext => 'Přehrát jako další';
	@override String get addToQueue => 'Přidejte na kousek';
	@override String discNumber({required Object n}) => 'Disk ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladba',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladby',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladby',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladeb',
	);
	@override String get nowPlaying => 'Nyní hrát';
	@override String playingFrom({required Object title}) => 'Hraje se z ${title}';
	@override String get queue => 'Kouč';
	@override String get clearQueue => 'Vymazat frontu';
	@override String get lyrics => 'Texty';
	@override String get visualizer => 'vizualizace';
	@override String get visualizerProfileLoading => 'Přečtěte si analýzu track...';
	@override String get visualizerAmbientMotion => 'Atmosféra pohybu';
	@override String get visualizerPlexLoudness => 'Plex hlasitost';
	@override String get visualizerPreviousPreset => 'Předchozí vizuální styl';
	@override String get visualizerNextPreset => 'Další vizuální styl';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blondýn';
	@override String get visualizerPresetOrbitals => 'Orbitální';
	@override String get visualizerPresetPrism => 'Prismová';
	@override String get visualizerPresetTunnel => 'tunel';
	@override String get visualizerPresetTrackMap => 'Track mapy';
	@override String get noLyrics => 'Žádné texty k dispozici';
	@override String get sleepTimer => 'Časový spánek';
	@override String get sleepTimerEndOfTrack => 'Konec trasy';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minut',
	);
	@override String get stopPlayback => 'Zastavit přehrávání';
	@override String get previousTrack => 'Předchozí stopa';
	@override String get nextTrack => 'Následující stopa';
	@override String get repeat => 'Opakovat';
	@override String get repeatAll => 'Opakovat vše';
	@override String get repeatOne => 'Opakovat jeden';
	@override String get instantMixNoServer => 'Není k dispozici server pro okamžitou směs';
	@override String get instantMixFailed => 'Nedokázal nahrát okamžitou směs';
	@override String get instantMixEmpty => 'Okamžitý mix se vrátil bez stopy';
	@override String noAudioUrl({required Object track}) => 'Žádný audio URL není k dispozici pro ${track}';
	@override late final _Translations$music$discography$cs discography = _Translations$music$discography$cs._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$cs extends Translations$watchTogether$en {
	_Translations$watchTogether$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Společné sledování';
	@override String get description => 'Zobrazit obsah v synchronizaci s přáteli a rodinou';
	@override String get createRoom => 'Vytvořte místnost';
	@override String get creatingRoom => 'Vytvoření místnosti...';
	@override String get joinRoom => 'Připojte se do pokoje';
	@override String get joiningRoom => 'Připojení do místnosti...';
	@override String get connecting => 'Připojení...';
	@override String get relayPublic => 'Pokoje využívají veřejné Open Watch Party relace.';
	@override String relayCustom({required Object url}) => 'Pokoje používají váš relay na ${url}.';
	@override String get recentRooms => 'Poslední pokoje';
	@override String get roomActions => 'Akce v místnosti';
	@override String get renameRoom => 'Rekonstrukce pokoje';
	@override String get removeRoom => 'Odstranit';
	@override String get enterRoomCode => 'Vložte šesti znakový kód z hostitele.';
	@override String get roomCode => 'Kód místnosti';
	@override String get paste => 'Vložit';
	@override String get noCodeInClipboard => 'Klipboard neobsahuje kód místnosti';
	@override String get copyCode => 'Kopírování kódu';
	@override String get codeCopied => 'Kód pokoje kopírovaný';
	@override String get shareInvite => 'Sdílejte pozvání';
	@override String get inviteCopied => 'Zkuste kopírovat. vložte ji do zprávy.';
	@override String inviteMessage({required Object code}) => 'Připojte se k mým hodinám společně v místnosti PlezyNG: otevřete hodinám společně, vyberte Připojte se k místnosti a zadejte ${code}.';
	@override String get openSessionControls => 'Otevřete sledování Session Controls';
	@override String get reconnecting => 'Připojení...';
	@override String get reconnectingDescription => 'Připojení je zrušené. automaticky se připojíte k místnosti.';
	@override String get connected => 'připojené';
	@override String get disconnected => 'Rozpojení';
	@override String get youAreHost => 'Jste hostitelem';
	@override String hostedBy({required Object name}) => 'Přihláška ${name}';
	@override String get hostControlsPlayback => 'Hostingové ovládací prvky Playback';
	@override String get anyoneCanControl => 'Každý může ovládat playback';
	@override String get roomLocked => 'Místnost uzavřená';
	@override String get nowPlaying => 'Nyní hrát';
	@override String get nothingPlaying => 'Není nic hrát';
	@override String get nothingPlayingHost => 'Hrajte něco z jakékoliv knihovny a sdílejte to s místností.';
	@override String get nothingPlayingGuest => 'Když host hraje něco, otevírá se zde.';
	@override String get notShareable => 'Toto video nemá žádný katalog, takže ho mohou hrát pouze lidé s přístupem na stejný server.';
	@override String get searching => 'Hledání tohoto videa ve vašich knihovnách...';
	@override String get yourCopy => 'Vaše kopie';
	@override String get sharingYourCopy => 'Sdílejte svou kopii';
	@override String playingOtherLength({required Object difference}) => 'Přehrávat svou kopii, ${difference}';
	@override String get mismatchTitle => 'Vaše kopie má jinou délku';
	@override String mismatchDescription({required Object difference}) => 'Vaše nejbližší kopie je ${difference} než video v místnosti.';
	@override String get playAnyway => 'Hrajte jakkoliv';
	@override String get chooseAnotherCopy => 'Vyberte další kopii';
	@override String get dontPlay => 'Nehrát si';
	@override String get unavailableTitle => 'Nemáte toto video';
	@override String get unavailableDescription => 'PlezyNG nemohl najít v knihovně. vyberte si kopii sami nebo vyhledejte znovu.';
	@override String get chooseCopy => 'Vyberte si kopii';
	@override String get searchAgain => 'Znovu hledat';
	@override String get noCandidates => 'V knihovně nenajdete žádné kopie.';
	@override String get choiceFailed => 'Nemohla jsem tuto kopii hrát pro místnost';
	@override String lengthLonger({required Object duration}) => '${duration} více';
	@override String lengthShorter({required Object duration}) => '${duration} kratší';
	@override String get lengthSame => 'Stejná délka';
	@override String get lengthUnknown => 'Délka neznámá';
	@override String get joinCurrentPlayback => 'Připojte se k aktuálnímu playbacku';
	@override String get joinCurrentPlaybackDescription => 'Zpět na to, co hostitel v současné době sleduje';
	@override String get stopMedia => 'Video pro každého';
	@override String get syncOffset => 'Synchronizace Offset';
	@override String get syncOffsetDescription => 'Přesměrujte video, pokud běží před nebo za místností.';
	@override String offsetHint({required Object difference}) => 'Vaše kopie je ${difference} než video v místnosti.';
	@override String applyDifference({required Object offset}) => 'Použití ${offset}';
	@override String get offsetMinusSecond => '1 s';
	@override String get offsetMinusTenth => '100 ms';
	@override String get offsetPlusTenth => '+ 100 ms';
	@override String get offsetPlusSecond => '+ 1 s';
	@override String get participants => 'Účastníci';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastník',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníci',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníka',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníků',
	);
	@override String get hostBadge => 'Host';
	@override String nameYou({required Object name}) => '${name} (vy jste)';
	@override String get playerIdle => 'Při neaktivitě';
	@override String get playerLoading => 'Nabíjení';
	@override String get playerReady => 'připravený';
	@override String get playerBuffering => 'Bufferování';
	@override String get matchSearching => 'Vyhledávání';
	@override String get matchMatched => 'Má video';
	@override String get matchMismatched => 'Různé délky';
	@override String get matchUnavailable => 'Nemáte videa';
	@override String participantOffset({required Object offset}) => 'Příslušenství ${offset}';
	@override String get makeHost => 'Udělejte host';
	@override String get makeHostQuestion => 'Převodový host?';
	@override String makeHostConfirm({required Object name}) => '${name} bude ovládat přehrávání a provozovat sezení pro všechny.';
	@override String get transfer => 'Převod';
	@override String get removeParticipant => 'Odstranit z místnosti';
	@override String removeParticipantQuestion({required Object name}) => 'Odstranit ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} opouští místnost. mohou se znovu připojit k kódu, pokud nezapnete místnost.';
	@override String get remove => 'Odstranit';
	@override String get roomSettings => 'Nastavení místnosti';
	@override String get letEveryoneControl => 'Připravte se na Playback';
	@override String get lockRoom => 'Lockova místnost';
	@override String get lockRoomDescription => 'Nikdo nový se nemůže připojit';
	@override String get leaveRoom => 'Zanechat pokoj';
	@override String get leaveRoomQuestion => 'Zanechat si pokoj?';
	@override String get leaveRoomConfirm => 'Můžete se opět připojit k kódu místnosti.';
	@override String get leave => 'Zanechat';
	@override String get endRoom => 'Konečná místnost';
	@override String get endRoomQuestion => 'Konečný pokoj ?';
	@override String get endRoomConfirm => 'To je konec místnosti pro všechny.';
	@override String get end => 'Konec';
	@override String get playBlockedTitle => 'Playback se nezačal';
	@override String get playBlockedDescription => 'Tiskové hry začít sledovat s místností.';
	@override late final _Translations$watchTogether$notices$cs notices = _Translations$watchTogether$notices$cs._(_root);
	@override late final _Translations$watchTogether$ended$cs ended = _Translations$watchTogether$ended$cs._(_root);
	@override late final _Translations$watchTogether$errors$cs errors = _Translations$watchTogether$errors$cs._(_root);
	@override String untitledEpisode({required Object number}) => 'Článek ${number}';
}

// Path: downloads
class _Translations$downloads$cs extends Translations$downloads$en {
	_Translations$downloads$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Stažené soubory';
	@override String get manage => 'Řízení';
	@override String get tvShows => 'Seriály';
	@override String get movies => 'Filmy';
	@override String get music => 'Hudba';
	@override String tracksQueued({required Object count}) => '${count} stopy ke stažení';
	@override String get noDownloads => 'Zatím žádné stahování';
	@override String get noDownloadsDescription => 'Stáhnutý obsah se zde objeví pro offline prohlížení';
	@override String get downloadNow => 'Stáhnout';
	@override String get deleteDownload => 'Odstranit download';
	@override String get retryDownload => 'Zpět ke stažení';
	@override String get downloadQueued => 'Stažení zařazeno.';
	@override String get downloadResumed => 'Stáhnout znovu';
	@override String get serverErrorBitrate => 'Serverová chyba: soubor může překročit limit vzdálené bitrate';
	@override String get storageFull => 'Stáhnout se zastavil, aby chránil dostupné skladování. Zvolit nějaký prostor nebo si vybrat další místo stahování, pak se vrátit.';
	@override String get storageUnavailable => 'Stáhnout se zastavil, protože dostupné úložiště nemohlo být kontrolováno. zkontrolovat umístění stahování, pak se vrátit.';
	@override String episodesQueued({required Object count}) => '${count} epizody ke stažení';
	@override String get downloadDeleted => 'Stáhnout odstraněno';
	@override String deleteConfirm({required Object title}) => 'Odstranit "${title}" z tohoto zařízení?';
	@override String get deleteCollectionDownloads => 'Odstranit downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Smazat všechna stažení v kolekci „${title}“ z tohoto zařízení?';
	@override String get collectionDownloadsDeleted => 'Stáhnout odstraněno';
	@override String get cancelledDownloadTitle => 'Zrušený download';
	@override String get cancelledDownloadMessage => 'Tento download byl zrušen. co byste chtěli dělat?';
	@override String get allEpisodesAlreadyDownloaded => 'Všechny epizody již stažené';
	@override String get resumeDownload => 'Recenze download';
	@override String get cancelledDownload => 'Zrušený download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (syncování ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => 'Stáhnout ${file} - Klikněte pro dokončení';
	@override String get partialDownloadClickToComplete => 'Částečně stáhnout - klikněte na dokončit';
	@override String get deleting => 'Odstranění...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Odstranění ${title}... (${current} z ${total})';
	@override String get queuedTooltip => 'Kvůli';
	@override String queuedFilesTooltip({required Object files}) => 'Štítek ${files}';
	@override String get downloadingTooltip => 'Stáhnout...';
	@override String downloadingFilesTooltip({required Object files}) => 'Stáhnout ${files}';
	@override String get noDownloadsTree => 'Žádné stahování';
	@override String get pauseAll => 'Odpočinek vše';
	@override String get resumeAll => 'Recenze vše';
	@override String get retryAll => 'Vraťte všechny';
	@override String get retryFailed => 'Neúspěšné stahování';
	@override String get deleteAll => 'Odstranit vše';
	@override String get selectVersion => 'Vyberte verzi';
	@override String get allEpisodes => 'Všechny epizody';
	@override String get unwatchedOnly => 'Pouze ignorované';
	@override String nextNUnwatched({required Object count}) => 'Další ${count} nepozorováno';
	@override String get customAmount => 'Přizpůsobené množství...';
	@override String get customAmountAny => 'Příslušná částka (v každém případě)';
	@override String get randomEpisodes => 'Náhodné epizody';
	@override String get includeSpecials => 'Zahrnuje speciály';
	@override String get howManyEpisodes => 'Kolik epizod?';
	@override String get invalidEpisodeCount => 'Zadejte platný počet epizod.';
	@override String get keepSynced => 'Zůstaňte synchronizováni';
	@override String get downloadOnce => 'Stáhnout jednou';
	@override String keepNUnwatched({required Object count}) => 'Zůstaňte ${count} nepozorován';
	@override String get editSyncRule => 'Edit pravidlo synchronizace';
	@override String get removeSyncRule => 'Odstranit pravidlo synchronizace';
	@override String removeSyncRuleConfirm({required Object title}) => 'Přestaňte synchronizovat "${title}"? stažené epizody budou zachovány.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Přestaňte synchronizovat „${title}“?';
	@override String get deleteSyncRuleDownloads => 'Také odstranit související downloads';
	@override String get deleteSyncRuleDownloadsDescription => 'Stáhnout použité jiným pravidlem synchronizace nebo profil bude zachováno.';
	@override String syncRuleCreated({required Object count}) => 'Pravidlo synchronizace vytvořeno – zachování ${count} nepozorovaných epizod';
	@override String get syncRuleUpdated => 'Pravidlo synchronizace aktualizované';
	@override String get syncRuleRemoved => 'Pravidlo synchronizace odstraněno';
	@override String get syncRuleAndDownloadsRemoved => 'Pravidlo synchronizace a související stahování odstraněno';
	@override String get syncRuleCleanupBusy => 'Pravidla synchronizace jsou v současné době aktualizovány. zkuste znovu v okamžiku.';
	@override String get syncRuleCleanupUnavailable => 'Přidružené stahování nelze bezpečně identifikovat. znovu připojit server a zkuste znovu, nebo odstranit pravidlo bez odstranění stahování.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Synchronizováno ${count} nové epizody pro ${title}';
	@override String get syncNow => 'Synchronizace nyní';
	@override String get downloadsUpToDate => 'Snížení je aktuální';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync kompletní · ${queued} queued, ${removed} odstraněno';
	@override String get activeSyncRules => 'Synchronizační pravidla';
	@override String get reviewOrphanFiles => 'Přihláška na sirotek Downloads';
	@override String get orphanReviewTitle => 'Přihláška na sirotek Downloads';
	@override String get orphanReviewDescription => 'Tyto označené soubory se nacházejí v předvolebních aplikacích spravovaných stahovacích složkách PlezyNG a nemají odpovídající stahovací záznam nebo aktivní úkol.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} soubory · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Odstranit soubory ${count}';
	@override String get orphanCleanupNone => 'Není nalezeno žádné downloadové soubory';
	@override String get orphanCleanupFailed => 'PlezyNG nemohl bezpečně skenovat složku spravovaných stahování. žádné soubory nebyly odstraněny.';
	@override String get orphanCleanupChanged => 'Seznam stahování se během přezkumu změnil. přezkoumání souborů znovu před čištěním.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Odstraněno ${count} orphaned soubory · ${size} osvobozeno';
	@override String get noSyncRules => 'Žádné pravidla synchronizace';
	@override String get manageSyncRule => 'Řízení synchronizace';
	@override String get editEpisodeCount => 'Epizoda počítá';
	@override String get editSyncFilter => 'Synchronizace filtru';
	@override String get syncAllItems => 'Synchronizace všech položek';
	@override String get syncUnwatchedItems => 'Synchronizace nepozorovaných položek';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Dostupné';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Podepisujte požadované';
	@override String get syncRuleAccessDenied => 'přístup odmítnutý';
	@override String get syncRuleNotAvailableForProfile => 'Není k dispozici pro aktuální profil';
	@override String get syncRuleUnknownServer => 'Neznámý server';
	@override String get syncRuleListCreated => 'Synchronizační pravidlo vytvořeno';
	@override late final _Translations$downloads$backgroundWarning$cs backgroundWarning = _Translations$downloads$backgroundWarning$cs._(_root);
	@override String get options => 'možnost stahování';
	@override late final _Translations$downloads$groupings$cs groupings = _Translations$downloads$groupings$cs._(_root);
	@override String get unknownLibrary => 'Neznámá knihovna';
	@override String get unknownShow => 'Neznámá show';
	@override String get unknownSeason => 'Neznámá sezóna';
	@override String get unknownAlbum => 'Neznámý album';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} dokončeno';
	@override String storageUsed({required Object size}) => 'Použité skladování: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažený soubor',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažené soubory',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} staženého souboru',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažených souborů',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriál',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriály',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriálu',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriálů',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmy',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmu',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmů',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alba',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alba',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alb',
	);
	@override String get errorFileNotFound => 'Soubor nenajdený (404)';
	@override String get errorDownloadNotAllowed => 'Stáhnout není povoleno serverem (403)';
	@override String get errorDownloadFailed => 'Download neúspěch';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Stáhnout neúspěšný: ${reason}';
	@override String get convertingOnServer => 'Převod na server...';
	@override String convertingOnServerPercent({required Object percent}) => 'Převod na server · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Stáhnout selhalo (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Post-procesování selhalo: ${reason}';
	@override String get reasonFileNotSaved => 'soubor nelze uložit na tomto zařízení';
	@override String get reasonCannotResume => 'Částečné stahování nelze obnovit';
	@override String get reasonDeviceStorageFull => 'Tento přístroj je mimo skladování';
	@override String get notificationDownloading => 'Stáhnout...';
	@override String get notificationComplete => 'Download kompletní';
	@override String get notificationPaused => 'Stáhnout Pause';
}

// Path: shaders
class _Translations$shaders$cs extends Translations$shaders$en {
	_Translations$shaders$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadersová';
	@override String get noShaderDescription => 'Žádné video vylepšení';
	@override String get nvscalerDescription => 'NVIDIA image scaling pro ostrší video';
	@override String get artcnnVariantNeutral => 'neutrální';
	@override String get artcnnVariantDenoise => 'Denoza';
	@override String get artcnnVariantDenoiseSharpen => 'Demoise + Sharpenová';
	@override String get qualityFast => 'Rychle';
	@override String get qualityHQ => 'Vysoká kvalita';
	@override String get mode => 'Módní';
	@override String get importShader => 'Importovat shader';
	@override String get customShaderDescription => 'Přizpůsobený GLSL shader';
	@override String get shaderImported => 'Shader dovážený';
	@override String get shaderImportFailed => 'Nepodařilo se dovoz shaderu';
	@override String get deleteShader => 'Odstranění Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Odstranit „${name}“?';
}

// Path: companionRemote
class _Translations$companionRemote$cs extends Translations$companionRemote$en {
	_Translations$companionRemote$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Doprovodný ovladač';
	@override String connectedTo({required Object name}) => 'Připojení k číslu ${name}';
	@override String get unknownDevice => 'Neznámé zařízení';
	@override late final _Translations$companionRemote$session$cs session = _Translations$companionRemote$session$cs._(_root);
	@override late final _Translations$companionRemote$pairing$cs pairing = _Translations$companionRemote$pairing$cs._(_root);
	@override late final _Translations$companionRemote$remote$cs remote = _Translations$companionRemote$remote$cs._(_root);
	@override late final _Translations$companionRemote$errors$cs errors = _Translations$companionRemote$errors$cs._(_root);
	@override String get closedBeforeAuth => 'Připojení uzavřeno před autentifikací';
}

// Path: videoSettings
class _Translations$videoSettings$cs extends Translations$videoSettings$en {
	_Translations$videoSettings$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Rychlost přehrávání';
	@override String get normalSpeed => 'Normální';
	@override String sleepTimerActive({required Object duration}) => 'Aktivní (${duration})';
	@override String get zoom => 'Přiblížit';
	@override String get sleepTimer => 'Čas spánku';
	@override String get audioSync => 'Audio synchronizace';
	@override String get subtitleSync => 'Synchronizace Subtitle';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR není k dispozici zde - tento desktopový skladatel nebo video výstup ho nemůže nosit.';
	@override String get hdrToneMapping => 'HDR Tone mapování';
	@override String get hdrToneMappingCompositor => 'skladatel';
	@override String get hdrToneMappingCompositorDescription => 'Přejděte přes zdroje HDR metadata a nechte desktopovou kompozitní mapu.';
	@override String get hdrToneMappingPlayer => 'Přehrávač';
	@override String get hdrToneMappingPlayerDescription => 'Mapa na špičkové jasnosti displeje v hráči, pak řekněte skladatelovi výsledek.';
	@override String get hdrToneMappingFailed => 'Nemohlo by se změnit mapování HDR tónu - předchozí režim je stále aktivní.';
	@override String get audioOutput => 'Audio výstup';
	@override String get performanceOverlay => 'Výsledky Overlay';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'okolí';
	@override String get audioOutputSpatial => 'Vesmírný audio';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio ekvalizátor';
	@override String get audioEqualizerDescription => 'Přizpůsobte pro toto zařízení pět frekvenčních pásem. k dispozici na čísle mpv; aktivní EQ dekóduje zvuk a deaktivuje přizpůsobení.';
	@override String get audioEqualizerFlat => 'ploché';
	@override String get audioEqualizerActive => 'Vlastní';
	@override String get audioEqualizerSaveFailed => 'Nemohl jsem zachránit nastavení audio ekvalizátoru.';
	@override String get backgroundVideoAudio => 'Video audio pozadí';
	@override String get backgroundVideoAudioDescription => 'Udržujte video audio přehrávač, když opustíte přehrávač; obrázek je skryt, dokud se nevrátíte. Android používá oznámení pro přehrávač médií.';
	@override String get audioNormalization => 'Normalizace hluku';
	@override String get audioNormalizationDisablesPassthrough => 'Odstraňte audio na PCM; passthrough je vypnutý, zatímco toto je na';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$cs extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get color => 'Barva';
	@override String get performance => 'Výkon';
	@override String get buffer => 'Bufferová';
	@override String get app => 'Aplikace';
	@override String get decoder => 'dekódování';
	@override String get rawDecoder => 'Růžový decoder';
	@override String get tunneling => 'tunelů';
	@override String get passthrough => 'Pastrátová';
	@override String get aspect => 'Pohled';
	@override String get rotation => 'Rotace';
	@override String get dvSource => 'Zdroj DV';
	@override String get dvPath => 'Dva cesty';
	@override String get dvRouteDecoder => 'Dolby Vision dekódování';
	@override String get dvRouteDecoderP81 => 'Dolby Vision dekodér (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Základní vrstva';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10 základní vrstva';
	@override String get dvRouteBaseLayerHlg => 'HLG základní vrstva';
	@override String get dvRouteBaseLayerSdr => 'SDR základní vrstva';
	@override String get dvRouteReshaped => 'RPU obnovené (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Experimentální graf P7 FEL (nekvalifikovaný)';
	@override String get p7Conversion => 'Převod P7';
	@override String get sampleRate => 'Vzorkovací frekvence';
	@override String get pixelFormat => 'Formát pixelu';
	@override String get hwFormat => 'HMFF';
	@override String get matrix => 'Matrixová';
	@override String get primaries => 'Primární';
	@override String get transfer => 'Převod';
	@override String get renderFps => 'FPS vykreslování';
	@override String get displayFps => 'Zobrazit FPS';
	@override String get avSync => 'A/V synchronizace';
	@override String get dropped => 'roztrhané';
	@override String get dvRpus => 'DV RPU';
	@override String get dvRpuAverage => 'Dv RPU AVG';
	@override String get dvSampleAverage => 'DV vzorec AVG';
	@override String get maxLuma => 'Max. jas';
	@override String get minLuma => 'Min. jas';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache používá';
	@override String get cacheLimit => 'Cache limity';
	@override String get speed => 'rychlost';
	@override String get player => 'Přehrávač';
	@override String get playMethod => 'Způsob přehrání';
	@override String get memory => 'Paměť';
	@override String get uiFps => 'UI FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'Nvidia HW';
	@override String get decoderQualcommHw => 'Štítek Qualcomm';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'hardwarové';
	@override String get tunnelingActive => 'aktivní';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} selhalo)';
}

// Path: externalPlayer
class _Translations$externalPlayer$cs extends Translations$externalPlayer$en {
	_Translations$externalPlayer$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vnější hráč';
	@override String get useExternalPlayer => 'Použijte externí hráče';
	@override String get useExternalPlayerDescription => 'Otevřete videa v jiné aplikaci';
	@override String get selectPlayer => 'Vyberte hráče';
	@override String get customPlayers => 'Custom hráči';
	@override String get systemDefault => 'Systém default';
	@override String get addCustomPlayer => 'Přidat přizpůsobený hráč';
	@override String get playerName => 'Název hráče';
	@override String get playerNameHint => 'Můj hráč';
	@override String get playerCommand => 'Příkaz';
	@override String get playerPackage => 'Název balení';
	@override String get playerUrlScheme => 'URL schéma';
	@override String get off => 'Vypnuto';
	@override String get launchFailed => 'Neschopnost otevřít externí hráče';
	@override String appNotInstalled({required Object name}) => '${name} není instalován';
	@override String get playInExternalPlayer => 'Hrajte v externím hráči';
	@override String get description => 'Vyberte si jinou aplikaci k otevření videa v. Dostupné hráče závisí na vašem zařízení a na instalovaných aplikacích.';
	@override String get systemDefaultDescription => 'Nechte operační systém video otevřít pomocí své výchozí aplikace.';
	@override String playerOptionDescription({required Object player}) => 'Otevřete videa pomocí ${player}.';
	@override String get playerNameDescription => 'Značka zobrazená v seznamu hráčů.';
	@override String get playerPackageDescription => 'Zadejte název balíčku Android aplikace pro hráče, jako je com.example.player.';
	@override String get playerCommandDescription => 'Vložte nainstalovaný přehrávač příkaz nebo spustitelnou dráhu pro toto zařízení.';
	@override String get playerUrlSchemeDescription => 'Zadejte schéma URL a volitelný šablona URL používaný k spuštění hráče.';
}

// Path: metadataEdit
class _Translations$metadataEdit$cs extends Translations$metadataEdit$en {
	_Translations$metadataEdit$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Upravit';
	@override String get screenTitle => 'Upravit metadata';
	@override String get basicInfo => 'Základní info';
	@override String get artwork => 'umělecká práce';
	@override String get advancedSettings => 'Pokročilé nastavení';
	@override String get title => 'Název';
	@override String get sortTitle => 'Třídit dle názvu';
	@override String get originalTitle => 'Originální název';
	@override String get releaseDate => 'Datum vydání';
	@override String get contentRating => 'Hodnocení obsahu';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Shrnutí';
	@override String get poster => 'Plakát';
	@override String get background => 'pozadí';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Square umění';
	@override String get selectPoster => 'Vyberte plakát';
	@override String get selectBackground => 'Vyberte pozadí';
	@override String get selectLogo => 'Vyberte logo';
	@override String get selectSquareArt => 'Výběr Square Art';
	@override String get fromUrl => 'Od URL';
	@override String get uploadFile => 'Upload souborů';
	@override String get enterImageUrl => 'Vložte obrázek URL';
	@override String get imageUrl => 'obrázek URL';
	@override String get metadataUpdated => 'Aktualizované metadata';
	@override String get metadataUpdateFailed => 'Nedokázal aktualizovat metadata';
	@override String get artworkUpdated => 'Umělecká aktualizace';
	@override String get artworkUpdateFailed => 'Nedokázal aktualizovat umělecké dílo';
	@override String get noArtworkAvailable => 'K dispozici žádné umělecké dílo';
	@override String artworkOption({required Object index}) => 'Umělecká volba ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Možnost umělecké práce ${index}, vybraná';
	@override String get notSet => 'Není nastaven';
	@override String get libraryDefault => 'knihovny defektní';
	@override String get accountDefault => 'Účetní default';
	@override String get seriesDefault => 'Seriál default';
	@override String get episodeSorting => 'Epizoda rozvrhována';
	@override String get oldestFirst => 'Nejstarší první';
	@override String get newestFirst => 'Nejnovější první';
	@override String get keep => 'Držte';
	@override String get allEpisodes => 'Všechny epizody';
	@override String latestEpisodes({required Object count}) => '${count} nejnovější epizody';
	@override String get latestEpisode => 'Poslední epizoda';
	@override String episodesAddedPastDays({required Object count}) => 'Přidané epizody v posledních ${count} dnech';
	@override String get deleteAfterPlaying => 'Odstranění epizod po hraní';
	@override String get never => 'Nikdy';
	@override String get afterADay => 'Po jednom dni';
	@override String get afterAWeek => 'Po týdnu';
	@override String get afterAMonth => 'Po měsíci';
	@override String get onNextRefresh => 'Na příštím refresh';
	@override String get seasons => 'Série';
	@override String get show => 'představení';
	@override String get hide => 'Skrýt';
	@override String get episodeOrdering => 'Epizoda objednávky';
	@override String get tmdbAiring => 'Databáze filmů (Aired)';
	@override String get tvdbAiring => 'TTVDB (vzdálenost)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolutní)';
	@override String get metadataLanguage => 'Metodický jazyk';
	@override String get useOriginalTitle => 'Originální název';
	@override String get preferredAudioLanguage => 'Preferovaný jazyk zvuku';
	@override String get preferredSubtitleLanguage => 'Preferovaný jazyk titulků';
	@override String get subtitleMode => 'Auto-Select Subtitle režim';
	@override String get manuallySelected => 'Manuálně vybrané';
	@override String get shownWithForeignAudio => 'Zahraniční audio';
	@override String get alwaysEnabled => 'Vždy povolená';
	@override String get tags => 'Štítky';
	@override String get addTag => 'Přidat tag';
	@override String get genre => 'Žánr';
	@override String get director => 'Režisér';
	@override String get writer => 'Scénárista';
	@override String get producer => 'Producent';
	@override String get country => 'Země';
	@override String get collection => 'Kolekce';
	@override String get label => 'Značka';
	@override String get quickTag => 'Rychlý Tag...';
}

// Path: matchScreen
class _Translations$matchScreen$cs extends Translations$matchScreen$en {
	_Translations$matchScreen$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get match => 'Zápas...';
	@override String get fixMatch => 'Fixní zápas...';
	@override String get unmatch => 'neshody';
	@override String get unmatchConfirm => 'Zjistěte tento zápas? Plex se s ním zachází jako s neúspěšným až do ukončení.';
	@override String get unmatchSuccess => 'položka neslučitelná';
	@override String get unmatchFailed => 'Neúspěšný nesouhlasný bod';
	@override String get matchApplied => 'Zápas aplikovaný';
	@override String get matchFailed => 'Nepodařilo se zahájit zápas';
	@override String get titleHint => 'Název';
	@override String get yearHint => 'Rok';
	@override String get search => 'Vyhledávání';
	@override String get noMatchesFound => 'Žádné zápasy nalezené';
}

// Path: serverTasks
class _Translations$serverTasks$cs extends Translations$serverTasks$en {
	_Translations$serverTasks$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serverové úkoly';
	@override String get failedToLoad => 'Neschopnost naplnit úkoly';
	@override String get noTasks => 'Žádné úkoly běží';
}

// Path: trakt
class _Translations$trakt$cs extends Translations$trakt$en {
	_Translations$trakt$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'připojené';
	@override String connectedAs({required Object username}) => 'Připojeno jako @${username}';
	@override String get disconnectConfirm => 'Odstranit účet Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG přestane odesílat události na adresu Trakt.Můžete se kdykoli znovu spojit.';
	@override String get scrobble => 'Reálný scrobbling';
	@override String get scrobbleDescription => 'Pošlete si hraní, přestávku a zastavení událostí na adresu Trakt během přehrávání.';
	@override String get watchedSync => 'Sync sledovaný status';
	@override String get watchedSyncDescription => 'Pokud označíte položky podle zobrazení v čísle PlezyNG, označují se také podle zobrazení v čísle Trakt.';
}

// Path: seerr
class _Translations$seerr$cs extends Translations$seerr$en {
	_Translations$seerr$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Připojte se Seerr';
	@override String get serverUrl => 'server URL';
	@override String get serverUrlHelper => 'Adresa vašeho Seerr instance';
	@override String get checkServer => 'pokračovat';
	@override String get signInWithJellyfin => 'Přihlaste se na číslo Jellyfin';
	@override String get signInWithEmby => 'Přihlaste se na číslo Emby';
	@override String get signInWithLocal => 'Použijte místní účet';
	@override String get email => 'Emailová';
	@override String get noSignInMethods => 'Tento příklad Seerr neobsahuje žádnou podpůrnou metodu PlezyNG.';
	@override String get instance => 'Instance';
	@override String get disconnectConfirm => 'Odstranit se od Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG bude zapomenout na tento příklad Seerr.';
	@override String get request => 'Žádost';
	@override String get request4k => 'Vyžádání v 4K';
	@override String get seasons => 'Série';
	@override String get allSeasons => 'Všechny sezóny';
	@override String get advancedOptions => 'Pokročilé';
	@override String get destinationServer => 'Destinace server';
	@override String get qualityProfile => 'Kvalitní profil';
	@override String get rootFolder => 'Root složky';
	@override String get languageProfile => 'Jazykový profil';
	@override String get tags => 'Štítky';
	@override String get noTags => 'Žádné tags';
	@override String defaultOption({required Object name}) => '${name} (případní předvolba)';
	@override String get animeNote => 'Tato série je anime.';
	@override String get requestSubmitted => 'Žádost podaná';
	@override String requestFailed({required Object error}) => 'Přihláška selhala: ${error}';
	@override String get requestsLoadFailed => 'Možnosti žádosti nelze nabíjet';
	@override String get nothingToRequest => 'Vše je již k dispozici nebo požadováno.';
	@override String get statusAvailable => 'Dostupné';
	@override String get statusPartiallyAvailable => 'Částečně k dispozici';
	@override String get statusRequested => 'požadované';
	@override String get statusProcessing => 'zpracování';
	@override String get statusBlocklisted => 'Blokované';
	@override String couldNotReach({required Object url, required Object error}) => 'Nemůže dosáhnout ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Žádný případ Seerr na adrese ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Autentifikující reverzní proxy (SSO nebo HTTP auth) odpověděla namísto Seerr. PlezyNG nemůže přihlásit prostřednictvím něj: nechte Seerr /api/v1 cestu přes proxy pro tuto aplikaci, nebo použijte adresu, která se přímo dostane Seerr.';
	@override String get invalidUrl => 'Zadejte serverovou adresu jako je https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Tento příklad Seerr nepodporuje Quick Connect. Potřebuje Seerr 3.4 nebo novější.';
	@override String get notInitialized => 'Tento příklad Seerr nedokončil první instalace';
	@override String get noPlexTokenForReauth => 'No Plex token je k dispozici k opětovnému přihlášení';
	@override String get noStoredCredentials => 'Žádné uložené certifikáty nejsou k dispozici k opětovnému přihlášení';
	@override String get signInRejected => 'Sign-in byl odmítnut';
	@override String get noSessionCookie => 'Společnost Seerr neposkytla soubor cookie sezení';
	@override String get freshCookieRejected => 'Seerr odmítl nový soubor cookie';
	@override String get noUserInformation => 'Seerr nevrátil uživatelské informace';
	@override String get sessionRejectedAfterReauth => 'Zasedání bylo po opětovném podepsání zamítnuto.';
	@override String get permissionDenied => 'Seerr tuto akci odmítl: Váš účet již nemá požadované povolení';
	@override String get permissionRevoked => 'Už nemáte právo na to požádat';
}

// Path: services
class _Translations$services$cs extends Translations$services$en {
	_Translations$services$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Služby';
	@override String get hubSubtitle => 'Sync sleduje pokrok a žádá o nové tituly.';
	@override String get integrations => 'integrace';
	@override String get notConnected => 'Není připojený';
	@override String connectedAs({required Object username}) => 'Připojeno jako @${username}';
	@override String get scrobble => 'Automaticky sledujte pokrok';
	@override String get scrobbleDescription => 'Aktualizujte svůj seznam, když dokončíte epizodu nebo film.';
	@override String disconnectConfirm({required Object service}) => 'Rozhraní ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG přestane aktualizovat ${service}. znovu se připojit kdykoli.';
	@override String connectFailed({required Object service}) => 'Nemohla jsem se připojit na číslo ${service}. zkuste znovu.';
	@override late final _Translations$services$names$cs names = _Translations$services$names$cs._(_root);
	@override late final _Translations$services$simklReconnect$cs simklReconnect = _Translations$services$simklReconnect$cs._(_root);
	@override late final _Translations$services$deviceCode$cs deviceCode = _Translations$services$deviceCode$cs._(_root);
	@override late final _Translations$services$oauthProxy$cs oauthProxy = _Translations$services$oauthProxy$cs._(_root);
	@override late final _Translations$services$pendingAuth$cs pendingAuth = _Translations$services$pendingAuth$cs._(_root);
	@override late final _Translations$services$libraryFilter$cs libraryFilter = _Translations$services$libraryFilter$cs._(_root);
	@override String get seerrDescription => 'Připojte se k Seerr nebo Overseerr pro vyhledávání titulů a předložte mediální požadavky.';
	@override late final _Translations$services$trackerDescriptions$cs trackerDescriptions = _Translations$services$trackerDescriptions$cs._(_root);
}

// Path: addServer
class _Translations$addServer$cs extends Translations$addServer$en {
	_Translations$addServer$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Přidat server ${product}';
	@override String get serverUrls => 'Serverové URL';
	@override String get serverUrlsHelper => 'Mnoho URL je povoleno, odděleno komami.';
	@override String get findServer => 'Najít server';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Hledáte místní servery ${product} ...';
	@override String localMediaBrowserServers({required Object product}) => 'Lokální servery ${product}';
	@override String get username => 'Uživatelské jméno';
	@override String get password => 'Heslo';
	@override String get signIn => 'Přihlásit se';
	@override String get change => 'Změna';
	@override String get required => 'požadované';
	@override String couldNotReachServer({required Object error}) => 'Nemohla se dostat na server: ${error}';
	@override String signInFailed({required Object error}) => 'Přihláška neúspěšná: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect selhalo: ${error}';
	@override String get addPlexTitle => 'Přihlaste se na číslo Plex';
	@override String get pinExpired => 'PIN skončil před přihlášením, zkuste to znovu.';
	@override String failedToRegisterAccount({required Object error}) => 'Účet se nezregistroval: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Zadejte svůj server ${product} URL';
	@override String get addConnectionTitle => 'Přidejte připojení';
	@override String addConnectionTitleScoped({required Object name}) => 'Přidat na ${name}';
	@override String get signInWithPlexCard => 'Přihlaste se na číslo Plex';
	@override String get signInWithPlexCardSubtitle => 'Přizpůsobte toto zařízení.Sdílené servery jsou přidány.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorizujte účet Plex. domácí uživatelé se stávají profily.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Připojte se k číslu ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Zadejte URL, uživatelské jméno a heslo.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Přihlaste se k serveru ${product}. připojte se k serveru ${name}.';
	@override String get borrowFromAnotherProfile => 'Půjčka z jiného profilu';
	@override String get borrowFromAnotherProfileSubtitle => 'Další připojení profilu znovu použijte. PIN-ochráněné profily vyžadují PIN.';
	@override String get invalidCredentials => 'Invalidní uživatelské jméno nebo heslo';
	@override String get authResponseNotJson => 'Odpověď na ověření nebyla platná JSON';
	@override String get authResponseIncomplete => 'Odpověď na sign-in ze serveru byla neúplná';
	@override String get quickConnectRejected => 'Quick Connect byl odvolán serverem';
	@override String get quickConnectNotJson => 'Odpověď Quick Connect nebyla platná JSON';
	@override String get quickConnectMissingFields => 'Odpověď Quick Connect chybí kód nebo tajemství';
	@override String get quickConnectPollRejected => 'Quick Connect zpráva byla odmítnuta serverem';
	@override String get serverTimedOut => 'Server neodpovídá včas';
	@override String get responseNotJson => 'Odpověď serveru nebyla platná JSON';
	@override String responseMissingIdentity({required Object product}) => 'Odpověď chybí ID nebo jméno serveru - je to server ${product}?';
	@override String probeFailed({required Object error}) => 'Nemohla se dostat na server: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Zadejte alespoň jeden serverový URL ${product}';
	@override String noReachableServer({required Object product}) => 'Nejsou nalezeny žádné dostupné servery ${product}';
	@override String urlsPointToDifferentServers({required Object product}) => 'Tyto URL odkazují na různé servery ${product}';
	@override String urlDoesNotMatchServer({required Object product}) => 'Tento URL se neshoduje s serverem ${product}';
	@override String get redirectUnsupported => 'Server přesměrován na nepodporovaný URL';
	@override String redirectDifferentHost({required Object product}) => 'Server přesměrován na jiný host. Zadejte konečnou adresu URL ${product} přímo.';
	@override String get redirectInsecure => 'Server přesměrován z HTTPS na nejistou adresu URL';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Server přesměrován na nepodporovaný URL. Zadejte konečný URL ${product} přímo.';
	@override String get directPlexServerUrl => 'Plex URL serveru';
	@override String get directPlexServerUrlHelper => 'Zadejte místní IP a port vašeho serveru Plex Media Server.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (volitelné)';
	@override String get plexTokenHelper => 'Zanechte prázdný, pokud je přístup bez auth povolen na tomto serveru.';
	@override String get plexTokenRequired => 'Vložte prosím svůj token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Media Server (přímý / místní)';
	@override String get connectDirectPlexCardSubtitle => 'Připojte se přímo pomocí místního IP nebo URL bez účtu plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Připojte se přímo pomocí místního IP nebo URL. Připojte se k ${name}.';
	@override String get insecureTitle => 'Nekryptované spojení';
	@override String insecureDescription({required Object url}) => '${url} používá HTTP. Lidé v síti mohou číst nebo měnit vaše heslo, tokeny a média. Je-li to možné, použijte HTTPS. Pokračujte pouze v případě, že této síti důvěřujete a přijímáte toto riziko.';
	@override String get allowHttp => 'Přijmout HTTP';
	@override String get httpsRequired => 'Použití HTTPS nebo výslovně umožnit nekryptované připojení.';
}

// Path: cast
class _Translations$cast$cs extends Translations$cast$en {
	_Translations$cast$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Odeslat do zařízení';
	@override String get searching => 'Hledání zařízení pro výkresy...';
	@override String connectedTo({required Object device}) => 'Připojení k číslu ${device}';
	@override String get device => 'Zařízení pro odesílání';
	@override String get readyToCast => 'Připraveno k odesílání';
	@override String get subtitle => 'Titulky';
	@override String get serverNotAvailable => 'Media server není k dispozici.';
	@override String get stopCasting => 'Ukončit odesílání';
	@override String get castToDevice => 'Odeslat do zařízení';
	@override String get noEpisodeAvailable => 'Neexistuje žádná epizoda k dispozici.';
	@override String get startFailed => 'Nemůžete začít casting. zkontrolujte server a zkuste znovu.';
}

// Path: automation
class _Translations$automation$cs extends Translations$automation$en {
	_Translations$automation$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Neexistuje žádná aktivní videozáznamy k ovládání.';
}

// Path: notifications
class _Translations$notifications$cs extends Translations$notifications$en {
	_Translations$notifications$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nová epizoda';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$cs extends Translations$appAccess$en {
	_Translations$appAccess$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zkuste každou funkci zdarma po dobu 7 dní';
	@override String get description => 'Začněte sedmdenní zkoušku s plným přístupem k každému PlezyNG funkci. v průběhu zkoušky neexistuje žádná poplatek a žádná předplatná. Po zkoušce jeden životní nákup v ceně vašeho obchodu odblokuje PlezyNG po celý život.';
	@override String get trialEndedDescription => 'Jediným nákupem za cenu uvedenou ve vašem obchodě odemknete všechny funkce PlezyNG natrvalo. Bez předplatného.';
	@override String get startTrial => 'Začínám 7denní bezplatný test';
	@override String get trialActive => 'Váš 7denní plnohodnotný test je aktivní.';
	@override String get trialEnded => 'Sedmdenní proces skončil.';
	@override String get trialStartFailed => 'Nemohla jsem na tomto zařízení ušetřit zkoušku. prosím zkuste znovu.';
	@override String get lifetimeTitle => 'PlezyNG odemknutá po celý život';
	@override String get lifetimeBody => 'Díky! máte celoživotní přístup k každému PlezyNG funkci.';
	@override String get manageTitle => 'PlezyNG Životní přístup';
	@override String get manageDescription => 'Zkuste každou funkci zdarma po dobu 7 dnů, pak odemkněte vše po celý život s jednou platbou za cenu vašeho obchodu.';
	@override String buy({required Object price}) => 'Odemknout všechny funkce pro ${price}';
	@override String get loadingPrice => 'Nákladní obchodní cena...';
	@override String get retryPrice => 'Zpět na cenu Lookup';
	@override String get restore => 'Obnovte životní nákup';
	@override String get pending => 'Váš nákup čeká na platbu nebo schválení. celoživotní přístup odemkne, jakmile ho obchod dokončí.';
	@override String get storeUnavailable => 'Nákupy nejsou k dispozici. zkontrolujte, že jste se zaregistrovali do obchodu a nákupy jsou povoleny na tomto zařízení.';
	@override String get productNotFound => 'Životní odemknutí PlezyNG není v tomto obchodě zatím k dispozici.';
	@override String get productQueryFailed => 'Nemohla jsem si stáhnout cenu obchodu. zkontrolujte připojení a zkuste znovu.';
	@override String get purchaseFailed => 'Nákup neprošel, zkuste to znovu.';
	@override String get restoreFailed => 'Nemohla jsem se dostat do obchodu, abyste obnovili nákup. zkuste znovu.';
	@override String get nothingToRestore => 'Číslo PlezyNG pro životní nákup byl nalezen pro tento obchodní účet.';
}

// Path: detail
class _Translations$detail$cs extends Translations$detail$en {
	_Translations$detail$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Končí na ${time}';
}

// Path: watchLink
class _Translations$watchLink$cs extends Translations$watchLink$en {
	_Translations$watchLink$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Nemohl jsem se dostat k serveru Plex pro tento odkaz.';
	@override String get notFound => 'Nemohl jsem najít tento show nebo film na vašich serverech Plex.';
	@override String get ambiguous => 'Tento odkaz se shoduje s položkami na více než jednom serveru. Přidejte server na odkaz.';
	@override String get plexOnly => 'Sledování odkazů v současné době podporuje pouze servery Plex.';
	@override String get unsupportedItem => 'Sledování odkazů může otevřít pouze show nebo film.';
	@override String get menuItem => 'Zobrazit link';
	@override String get dialogTitle => 'Podívejte se link';
	@override String get dialogShowHint => 'Otevření tohoto odkazu hraje další epizodu. Přidejte &mode=shuffle do konce, abyste mohli hrát show na shuffle.';
	@override String get dialogMovieHint => 'Otevření tohoto odkazu hraje film.';
	@override String get copy => 'Kopírovat';
	@override String get copied => 'Link kopírovaný';
}

// Path: homeLayout
class _Translations$homeLayout$cs extends Translations$homeLayout$en {
	_Translations$homeLayout$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Domů Layout';
	@override String get resetToast => 'Domů Reset na původní rozložení hrdiny Plezy';
	@override String get resetHeroTitle => 'Obnovte herecký layout na zásobu Plezy?';
	@override String get resetHeroBody => 'Odstraní postavy hrdiny každé řady a přináší zpět jediný otáčící banner na vrcholu Domova, stejně jako předtím, než hrdinové řádky existovaly.';
	@override String get removeRowTitle => 'Odstranit domácí řádek?';
	@override String removeRowBody({required Object title}) => '${title} bude vymazán. to nelze vymazat.';
	@override String get sync => 'Synchronizace';
	@override String get syncAccountTitle => 'Synchronizujte rozložení s vaším účtem Plex';
	@override String get syncAccountOn => 'Na: Toto zařízení sdílí řádné řádky, řádky, Hero a Auto-slide s ostatními zařízeními.';
	@override String get syncAccountOff => 'Vypnutí: Tento přístroj si udržuje svůj vlastní layout.';
	@override String get syncNow => 'Synchronizace nyní';
	@override String get plexHomeManager => 'Plex Domácí manažer';
	@override String get managePlexRows => 'Řízení Plex řádků v Plezy';
	@override String get managePlexRowsDescription => 'Otevřeno pro organizaci domácího výběru řádků';
	@override String get organizeHomeRows => 'Domácí řádky';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} řádky: pohyb, Hero, Auto-slide, odstranění';
	@override String organizeLibraryRows({required Object library}) => 'Složení ${library} řádků';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Pokračovat v sledování + ${n} řádky: pohyb, knihovna, Domů, Hero, Auto-slide';
	@override String get renderAsHero => 'Vstup jako hrdinská karta';
	@override String get heroOnlySingleCollection => 'Dostupné pouze tehdy, když se tato řada vyřeší na skutečné tituly jedné kolekce';
	@override String get hero => 'Hrdina';
	@override String get autoSlide => 'Auto slide';
	@override String get autoSlideDescription => 'Přístupy (PC) a d-pad (TV) vždy fungují a časovač znovu spouští.';
	@override String get autoSlideEditDescription => 'Odstraní: pouze se pohybuje, když kliknete na šípku (PC) nebo stisknete levou / pravou na dálku (TV).';
	@override String get enableHeroFirst => 'První hrdina';
	@override String get showOnHome => 'Zobrazit na domácím obrazovce';
	@override String get home => 'Domovská obrazovka';
	@override String get removeFromHome => 'Odstranit z domova';
	@override String get selectRowsFirst => 'Vyberte domácí řádky níže první.';
	@override String plexManagedRows({required Object n}) => '${n} Plex řízené řádky';
	@override String get continueWatching => 'Pokračovat ve sledování';
	@override String get continueWatchingLibraryDescription => 'Tato knihovna má vlastní pokračovací řadu';
	@override String get continueWatchingHomeDescription => 'Zpětná řada pokroku zobrazená na Home';
	@override String get nextUpHomeDescription => 'Následující nedohlédnutý epizodový řádek zobrazen samostatně na Domů';
	@override String get library => 'Knihovna';
	@override String get showInRecommended => 'Představení v knihovně doporučeno';
	@override String get customPlexRow => 'Přizpůsobený Plex řádek';
	@override String get heroNeedsLibrary => 'Prohlédněte si knihovnu nejprve – Hero potřebuje někde ukázat';
	@override String get heroNeedsSurface => 'Zkontrolujte knihovnu nebo domov nejprve – Hero potřebuje někde ukázat';
	@override String get removeHub => 'Odstranění Hub';
	@override String get noPlexRows => 'Číslo Plex řízené řádky se vrátily pro tuto knihovnu.';
	@override String get openDetails => 'Otevřené detaily';
	@override String get heroCards => 'Hrdinové karty';
	@override String get tapHeroCard => 'Ztráta hrdinské karty';
	@override String get tvPlayFocus => 'TV Remote: tlačítko Play';
	@override String get tvPlayFocusDescription => 'D-pad dolů se zastaví na tlačítku Play před přechodem na další řádek.';
	@override String get tvWrap => 'TV Remote: Loup Hero karty';
	@override String get tvWrapDescription => 'Práce na poslední kartu se vrací zpět na první kartu. Odstupní zastávky na poslední kartu. Levo na první kartu vždy jde na boční bar.';
	@override String get castOnHero => 'Hrajte na herecké bannery';
	@override String get castOnHeroDescription => 'Zobrazuje výkres podél dna hrdinského banneru. Off zachovává pouze titul a shrnutí.';
	@override String get customRows => 'Custom řádek';
	@override String get loading => 'Domácí rozložení...';
	@override String get noCustomRows => 'Žádné klasické řádky';
	@override String get addRowHint => 'Použijte přidání řádku Domů k vytvoření jednoho.';
	@override String get addHomeRow => 'Přidat domácí řádek';
	@override String get addHomeRowDescription => 'Výběr kategorie; nový řádek se automaticky přidává k Organizátoru';
	@override String get removeRow => 'Odstranit řádek';
	@override String get recentlyAdded => 'Nedávno přidáno';
	@override String get recentlyReleased => 'Nedávno uvolněné';
	@override String get movieCollections => 'Filmové sbírky';
	@override String get showCollections => 'Zobrazení kolekcí';
	@override String get rowTitle => 'Row titulek';
	@override String get content => 'obsah';
	@override String get showThisRowIn => 'Zobrazit tento řádek v:';
	@override String get libraryRecommended => 'Doporučená knihovna';
	@override String get heroCard => 'Hrdinská karta';
	@override String get heroCardDescription => 'Zobrazuje se jako jedna plnoširoká rotační karta namísto plakátového šelfu.';
	@override String get heroUnavailableDescription => 'Dostupné pouze tehdy, když se tento řádek vyřeší na skutečné tituly jedné kolekce - s více než jednou kolekcí vybranou neexistuje žádný jediný titul, který by se mohl otáčet.';
	@override String get librariesSelection => 'Knihovny (pustit všechny neprohlédnuté zahrnovat každou knihovnu)';
	@override String get librariesMergedDescription => 'Každá knihovna, která je zde kontrolována, je spojena do této jedné řady.';
	@override String get movieCollectionsSelection => 'Filmové sbírky (pustit všechny nezkontrolované pro každou vybranou knihovnu)';
	@override String get showCollectionsSelection => 'Zobrazit sbírky (zanechat všechny nezkontrolované pro každou vybranou knihovnu)';
	@override String get collectionRowsDescription => 'Pokud přesně jedna sbírka zápasí, jeho tituly se zobrazují přímo v řádku. Pokud více než jedna zápasí, každá sbírka se zobrazí jako jeden plakát - klepněte na něj, abyste tuto sbírku otevřeli.';
	@override String get allCollections => 'Všechny kolekce';
	@override String get noRowsHere => 'Zatím zde žádné řádky.';
	@override String get hideWatchedRows => 'Ukryte sledované položky v řádcích';
	@override String get hideWatchedRowsDescription => 'Plně sledované tituly opouštějí Domů a knihovny Doporučené řádky.';
	@override String get untitledCollection => 'Neznámá sbírka';
	@override String get moveRowHint => 'Up/Down: přejít řádek · Vyberte: přejít zde · Zpět: zrušit';
	@override String get organizeRowsHint => 'Vyberte v řádku (nebo držte Vyberte): přejděte · Levo/vpravo: možnosti řádku · Zpět: dokončeno';
	@override String get layoutNavDescription => 'Vyberte řádky, knihovny a kategorie sběru';
	@override String get editHomeRow => 'Edit Home řádek';
	@override String get resetHeroButton => 'Obnovte herecký layout na zásobu Plezy';
	@override String get reorderingUnlocked => 'Převedení odemknutého';
	@override String get reorderingLocked => 'Převod zamčené';
	@override String get rowsCanBeDragged => 'Krovy lze přetáhnout – klepněte na zámek, aby se zabránilo tomu, aby se';
	@override String get tapLockToDrag => 'Stiskněte zámek, abyste vytihli řádky';
	@override String customRowLabel({required Object title}) => 'Příslušenství: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Skrýt';
	@override String get remove => 'Odstranit';
	@override String get libraryResumeRow => 'Knižní přehled této knihovny';
	@override String get pressAgainToDelete => 'Znovu stiskněte, abyste odstranili';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'Na';
	@override String get resetHeroButtonDescription => 'Odstraní postavy hrdiny každé řady a přináší zpět jediný otáčící banner na vrcholu, stejně jako předtím, než hrdinské řady existovaly.';
	@override String get tapHeroCardDescription => 'Vyberte, zda klepnutí nebo výběr karty Hero zahájí přehrávání nebo otevírá jeho detaily.';
	@override String get heroTapPlayDescription => 'Začněte vybranou položku ihned.';
	@override String get heroTapDetailsDescription => 'Otevřete podrobnosti vybraného položky před výběrem akce.';
}

// Path: platform
class _Translations$platform$cs extends Translations$platform$en {
	_Translations$platform$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG se připojí k vašim mediálním serverům a přehrávačům na vaší místní síti.';
	@override String get locationPermission => 'PlezyNG používá přístup k místu, když iOS vyžaduje, aby detekovala vaši místní síť a připojila se k vašim mediálním serverům.';
	@override String get photoLibraryPermission => 'Vyberte si obrázky z vaší knihovny fotografií pro použití jako umělecké dílo.';
	@override String get cameraPermission => 'Skenování QR kódů pro párování s Companion Remote.';
}

// Path: universalMedia
class _Translations$universalMedia$cs extends Translations$universalMedia$en {
	_Translations$universalMedia$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Otevřené média';
	@override String get shortcutHelp => 'Zahrajte si odkaz, playlist nebo soubor pro tuto sezení.';
	@override String get intro => 'Otevřete odkaz, playlist nebo soubor. Playback používá standardní přehrávač PlezyNG a do vaší knihovny nepřidá historii.';
	@override String get openWhat => 'Co byste chtěli otevřít?';
	@override String get stream => 'Streamová adresa';
	@override String get playlist => 'Playlisty';
	@override String get files => 'Přístrojové soubory';
	@override String get favorites => 'Úsporný stream oblíbené';
	@override String get address => 'Mediální adresa';
	@override String get addressHelp => 'URL s uznanými parametry ověřování nebo podpisů se používají pouze pro tuto schůzku a nelze je uložit jako oblíbené.';
	@override String get displayName => 'Název zobrazení (volitelné)';
	@override String get displayNameHelp => 'Vyberte krátký název pro hráče a systémové médií ovládacích prvků.';
	@override String get allowHttp => 'Umožňuje nekryptované připojení HTTP';
	@override String get allowHttpHelp => 'HTTP nešifruje připojení. dovolte ho pouze na důvěryhodné síti. použijte HTTPS kdykoli je to možné.';
	@override String get advancedProtocols => 'MPV pouze: zadejte adresu RTSP, RTMP/RTMPS, UDP nebo RTP. Tyto adresy nelze uložit jako oblíbené.';
	@override String get liveStream => 'Léčba jako živá';
	@override String get liveStreamHelp => 'Použijte to pro živé video nebo rádio. aplikace skrývá časovou řádku, skok tlačítka a možnost go-to-time. vypněte ji pro záznam.';
	@override String get privateSession => 'Pouze tento přehrávač používá adresu.Save an eligible stream favorite to keep it in this profile.';
	@override String get saveFavorite => 'Zachraňte oblíbené';
	@override String get playNow => 'Hrajte nyní';
	@override String get favoriteSaved => 'Stream oblíbené uložené do tohoto profilu';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Přepadl ${count} nepodporovaný nebo nebezpečný playlist vstup.',
		few: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.',
		many: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.',
		other: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.',
	);
	@override String get playlistAddress => 'Playlistová adresa';
	@override String get playlistAddressHelp => 'Otevřete playlist M3U, M3u8 nebo PLS z webové adresy. Přímé streamovací odkazy nezachovávají playlist.';
	@override String get choosePlaylist => 'Vyberte soubor playlist';
	@override String get openPlaylist => 'Otevřená playlist';
	@override String get playlistFormatsHelp => 'Přehrávač může obsahovat až 1000 položek a 2 MB. HLS se otevírají jako toky, takže hráč si může vybrat kvalitu.';
	@override String get noFavorites => 'Není zachráněno stream oblíbené zatím. Oblíbené zůstanou v tomto profilu.';
	@override String get removeFavorite => 'Odstranit stream oblíbené';
	@override String get filesHelp => 'Vyberte si audio, video nebo ISO soubory pro dočasný průběh. Soubory a URL nejsou přidány do historie knihovny.';
	@override String get chooseFiles => 'Vyberte soubory';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '1 vybrané soubory',
		few: '${count} vybrané soubory',
		many: '${count} vybrané soubory',
		other: '${count} vybrané soubory',
	);
	@override String get wifiTransfer => 'Odesílání souborů přes Wi-Fi';
	@override String get wifiTransferHelp => 'Přenos podporovaných souborů z prohlížeče na stejnou důvěryhodnou síť.';
	@override String get wifiTransferIntro => 'Otevřete tuto adresu v prohlížeči na jiném zařízení. Vyberte soubory, abyste je přidali do knihovny souborů a knih tohoto zařízení.';
	@override String get wifiTransferPrivacy => 'Toto zařízení přijímá soubory přes vaši místní síť.Každý, kdo zná tuto adresu může poslat soubory až do zastavení přenosu nebo adresa vyprší po 15 minutách. Maximální: 100 souborů, 4 GiB na soubor, 10 GiB celkem.';
	@override String get wifiTransferStarting => 'Příprava soukromého, časově omezeného převodu...';
	@override String get wifiTransferUnavailable => 'Nemohla jsem začít přenosu. zkontrolujte přístup k místní síti a zkuste znovu.';
	@override String get openThisAddress => 'Otevřete jednu z těchto adres na odesílací zařízení';
	@override String get copyAddress => 'Kopírování transferové adresy';
	@override String get addressCopied => 'Přenosová adresa kopírovaná';
	@override String transferExpires({required Object time}) => 'Tato adresa vyprší v ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${count} soubor přijatý',
		few: '${count} soubory obdržené',
		many: '${count} soubory obdržené',
		other: '${count} soubory obdržené',
	);
	@override String uploadedData({required Object size}) => 'Obdržel ${size}';
	@override String get stopTransfer => 'Zastavení přenosu a zrušení adresy';
	@override String get startTransfer => 'Začátek transferu';
	@override String get wifiImportedFiles => 'Přenos Wi-Fi';
	@override String get wifiBrowserTitle => 'Odeslat soubory do PlezyNG';
	@override String get wifiBrowserIntro => 'Vyberte audio, video, ebook nebo komiksové soubory k odeslání. Soubory jsou uloženy v knihovně souborů a knih tohoto zařízení. Maximální: 100 souboru, 4 GiB na soubor, 10 GiB celkem.';
	@override String get uploadFilesLabel => 'Soubory k odesílání';
	@override String get uploadSelected => 'Stáhnout vybrané soubory';
	@override String get uploadSelectFirst => 'Nejprve vyberte jeden nebo více souborů.';
	@override String get uploading => 'Odesílání';
	@override String get uploadComplete => 'Soubor přidán do PlezyNG.';
	@override String get uploadFailed => 'Soubor nelze přidat. Držte tuto stránku otevřenou a zkuste znovu.';
	@override String get liveCue => 'Životní';
	@override String get liveSession => 'Živý stream';
	@override String get liveCueHelp => 'V případě živého videa nebo rozhlasu aplikace ukrývá časovou řádku a skáče tlačítka. nezachovává adresu ani sleduje historii.';
	@override String get sessionOnly => 'Tento playback je pouze session-';
	@override String get sessionOnlyHelp => 'Playback nikdy nezachrání pokrok nebo historii. Zachraňte tok jako oblíbený, abyste ho udrželi v tomto profilu, pokud je způsobilý.';
	@override String get pictureAdjustments => 'Fotografické úpravy';
	@override String get pictureHelp => 'Tyto změny obrazu ovlivňují pouze tento playback. Oni reset, když playback skončí.';
	@override String get resetPicture => 'Reset obrázek';
	@override String get brightness => 'Světlo';
	@override String get contrast => 'kontrast';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturace';
	@override String get view360 => 'Flat View pro 360° video';
	@override String get view360Help => 'Použijte toto pro rovnoměrné 360° video. MPV potřebuje filtr v360 FFmpeg pro tento pohled.';
	@override String get view360Unavailable => 'Tento mpv stav by nemohl použít 360° filtr.';
	@override String get view360Yaw => 'Horizontální pohled';
	@override String get view360Pitch => 'Vertikální pohled';
	@override String get view360FieldOfView => 'Oblast pohledu';
	@override String get recordStream => 'Rekordní živý stream';
	@override String get stopRecording => 'Zastavte a ušetřete záznam';
	@override String get recordingStarted => 'Záznam je aktivní.Leaving playback zastaví a ukládá záznam.';
	@override String get recordingSaved => 'Záznam byl dokončen a zachráněn.';
	@override String get recordingActive => 'Zanechání playback se zastaví a ukládá.';
	@override String get recordingFormatHelp => 'Pro video, vyberte MKV nebo MPEG-TS. pro audio, zvolte MKA nebo MKV.';
	@override String get replaceRecordingTitle => 'Změníte tuto nahrávku?';
	@override String get replaceRecordingHelp => 'PlezyNG obnovuje stávající soubor při zaznamenávání. Pokud nemůže uložit novou záznam, Plezy NG obnovuje zálohu.';
	@override String get replaceRecording => 'nahrazení souborů';
	@override String get discHelp => 'Otevřete disk v optickém disku tohoto počítače.Můžete také otevřít obraz ISO z souborů zařízení.';
	@override String get discs => 'Optický disk';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray';
	@override String get audioCd => 'Audio CD';
	@override String get discAvailability => 'Disk playback vyžaduje kompatibilní MPV stavbu, podporovaný disk a oprávnění operačního systému.';
	@override String get converterTitle => 'Konvertovat soubor místních médií';
	@override String get converterHelp => 'Použijte FFmpeg, abyste vytvořili MP4, M4A nebo MP3 kopii.';
	@override String get converterIntro => 'Konvertovat místní audio nebo video soubor do formátu, který funguje na více zařízeních.';
	@override String get converterPrivacy => 'FFmpeg musí být nainstalován na tomto počítači. konverze čte pouze místní soubory. nedodává toky nebo odstraňuje DRM.';
	@override String get converterChooseInput => 'Vyberte si místní mediální soubor';
	@override String get converterFormat => 'Výstupní formát';
	@override String get converterMp4 => 'MP4 · H.264 a AAC';
	@override String get converterM4a => 'M4A - AAC audio';
	@override String get converterMp3 => 'MP3 a audio';
	@override String get converterSaveAs => 'Shromažďování převedených médií jako';
	@override String get converterExtensionMismatch => 'Vyberte název s vybraným rozšířením výstupu.';
	@override String get converterUnsupportedInput => 'Vyberte si audio nebo video soubor.';
	@override String get converterLocalOnly => 'Vybraný soubor není k dispozici jako místní zařízení.';
	@override String get converterReplaceTitle => 'Změnit tento soubor?';
	@override String get converterReplaceHelp => 'PlezyNG obnovuje stávající soubor, dokud se neukládá převedená kopie.';
	@override String get converterStarting => 'Začínáme s FFmpeg...';
	@override String get converterProgress => 'Přeměna na tento počítač...';
	@override String get converterComplete => 'Konverze je hotová, nový soubor je připraven.';
	@override String get converterFfmpegMissing => 'Instalujte FFmpeg s podporou H.264, AAC a MP3, pak zkuste znovu.';
	@override String get converterFailed => 'Přesvědčte se, že zdrojový soubor lze přečíst a destinace má dostatek volného prostoru.';
	@override String get converterCancelled => 'Konverze byla zrušena. neúplný výsledek byl odstraněn.';
	@override String get converterDesktopOnly => 'Lokální konverze je k dispozici na desktopových počítačích s FFmpeg instalován.';
	@override String get converterStart => 'Převod souborů';
	@override String get mediaToolsTitle => 'Média nástroje';
	@override String get mediaToolsShortcut => 'Zachyťte nebo sdílejte média, přidejte vyhledávací rozšíření nebo použijte příkazovou řadu.';
	@override String get mediaToolsIntro => 'Vyberte si zaměřený nástroj. zachytit a stream-out používat FFmpeg nainstalované na tomto desku. rozšíření a CLI příkazy používají omezené požadavky HTTPS a stávající Open media tok.';
	@override String get mediaToolsAccessibility => 'Výběry nástrojů a kontroly pracují s dotykem, ukazatelem, klávesnicí a zaměřením D-pad. Změny v stavu nahrávání, sdílení a vyhledávání jsou oznámeny.';
	@override String get mediaTool => 'Média nástroj';
	@override String get captureIntro => 'Na tomto počítači zaznamenáváte obrazovku nebo fotoaparát do souboru MP4. FFmpeg musí být nainstalován a obsahuje kódovač H.264.';
	@override String get captureNoDevices => 'Nebyly nalezeny žádné obrazovky nebo fotoaparáty. zkontrolujte FFmpeg zachycenou podporu a oprávnění k soukromí operačního systému.';
	@override String get captureSource => 'obrazovka nebo fotoaparát';
	@override String get captureScreen => 'obrazovka';
	@override String get captureAudioSource => 'Audio vstup (volitelné)';
	@override String get captureAudioHelp => 'Přidejte zvuk z mikrofonu nebo dostupného vstupu. volby zařízení závisí na FFmpeg a systémových povoleních.';
	@override String get captureAudioNone => 'Žádný audio';
	@override String get captureDefaultAudio => 'Předvolený audio vstup';
	@override String get captureWaylandHelp => 'Wayland omezuje toto XWayland zachycení na X display. Windows mimo XWayland se nemusí zobrazit.';
	@override String get captureFrameRate => 'Rekordní rámová sazba';
	@override String get capturePrivacy => 'Záznam se ukládá pouze na vybranou souboru. mikrofonový záznam je volitelný. PlezyNG záznam nezakládá.';
	@override String get captureSaveAs => 'Shromažďujte záznam obrazovky jako';
	@override String get captureExtensionMismatch => 'Vyberte název, který končí v .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg nebo kódování videa H.264 není k dispozici. nainstalovat podporované FFmpeg stavbu, pak zkuste znovu.';
	@override String get captureFailed => 'Zkontrolujte oprávnění zařízení, dostupné ukládání a podporu FFmpeg.';
	@override String get captureSaved => 'Scénární záznam byl zachráněn.';
	@override String get captureElapsedLabel => 'Záznamový čas';
	@override String get captureStart => 'Začíná nahrávání';
	@override String get captureStop => 'Zastavte se a zachraňte';
	@override String get captureMode => 'únos';
	@override String get shareMode => 'Sdílejte';
	@override String get shareIntro => 'Odeslat soubor místních médií do jiného zařízení na vaší soukromé síti. PlezyNG vytváří dočasný tok HLS.';
	@override String get sharePrivacy => 'Kdokoliv na vaší místní síti, kdo dostává soukromý odkaz může sledovat, zatímco je aktivní. odkaz vyprší po 60 minutách. zastavit sdílení, aby se server uzavřel a zrušit odkaz.';
	@override String get shareChooseFile => 'Vyberte mediální soubor';
	@override String get shareChooseHelp => 'Vyberte místní audio nebo video soubor. soubor zůstává na tomto počítači.';
	@override String get shareFfmpegMissing => 'FFmpeg nebo kódování H.264/AAC nejsou k dispozici. Instalace FFmpeg s podporou kódování H.264 a AAC.';
	@override String get shareFailed => 'Stream se nemohl začít ani nečekaně zastavit. zkontrolujte FFmpeg a přístup k síti.';
	@override String get shareActive => 'Stream je připraven na vaší soukromé síti.';
	@override String get shareEnded => 'Média dosáhla konce a už se nedělá.';
	@override String get shareStopped => 'Sdílení přerušeno. dočasný odkaz již neplatí.';
	@override String get shareUrlCopied => 'Přenosová adresa je kopírována.';
	@override String get shareOpenUrl => 'Otevřete tuto adresu v jednom hráči na jiném zařízení';
	@override String get shareQrLabel => 'QR kód pro dočasnou adresu toku';
	@override String get shareQrHelp => 'Skenování pomocí kompatibilního přehrávače připojeného k téže soukromé síti.';
	@override String get shareHttpHint => 'Tento tok používá nekryptované HTTP. V PlezyNG, dovolte HTTP před otevřením.';
	@override String get shareCopyUrl => 'Kopírování streamové adresy';
	@override String get shareExpiresLabel => 'Link vyprší na';
	@override String get shareStarting => 'Připravování toku...';
	@override String get shareStart => 'Začněte sdílet';
	@override String get shareStop => 'Přestaňte sdílet';
	@override String get extensionsMode => 'Rozšíření a CLI';
	@override String get extensionsIntro => 'Přidejte data-pouze vyhledávací rozšíření najít média. Vyberte výsledek, aby ji přenést do známého formuláře Open media.';
	@override String get extensionsPrivacy => 'Manifest může definovat jedno HTTPS vyhledávací koncové body a mapové odpovídající pole. Nemůže spustit kód, přidat název žádosti, číst soubory, nebo spustit příkazy shell.';
	@override String get extensionImport => 'Přidat rozšíření manifest';
	@override String get extensionEmpty => 'Zvolte důvěryhodný manifest JSON soubor pro přidání.';
	@override String get extensionChoose => 'Vyhledávací služba';
	@override String get extensionSearchConsent => 'Každé vyhledávání odesílá vaše slova k této službě HTTPS. Výsledky se otevřou pouze po vybrání jednoho.';
	@override String get extensionSearchLabel => 'Vyhledávání médií';
	@override String get extensionSearch => 'Vyhledávání';
	@override String get extensionSearching => 'Hledání...';
	@override String get extensionNoResults => 'Bezpečné výsledky médií nebyly vráceny. zkuste další vyhledávání.';
	@override String get extensionInstallTitle => 'Přidejte tuto vyhledávací službu?';
	@override String get extensionReplaceTitle => 'Aktualizovat tuto službu vyhledávání?';
	@override String get extensionService => 'Služba';
	@override String get extensionEndpoint => 'HTTPS konečný bod';
	@override String get extensionConsent => 'Váš vyhledávací text je zaslán do této služby. manifest neobsahuje prováděcí kód. Pokračujte pouze v případě, že důvěřujete tomuto bodu.';
	@override String get extensionInstall => 'Přidat službu';
	@override String get extensionReplace => 'Aktualizace služby';
	@override String get extensionRemoveTitle => 'Odstranit tuto vyhledávací službu?';
	@override String get extensionRemoveHelp => 'To odstraní službu z tohoto profilu. PlezyNG se s jeho koncovým bodem nesetká.';
	@override String get extensionRemove => 'Odstranění služby';
	@override String get extensionInvalidManifest => 'Tento soubor není podporovaným rozšířením manifest. viz průvodce Open media pro formát.';
	@override String get extensionSaveFailed => 'Rozšíření nelze uložit do aktivního profilu.';
	@override String get extensionSearchFailed => 'Vyhledávací služba nevrátila platnou odpověď. zkontrolujte koncový bod a zkuste znovu.';
	@override String get cliTitle => 'Příkazová linka';
	@override String get cliHelp => 'Použijte průvodce plezyctl k ověření manifestu nebo vyhledávání stejného rozšíření. Před každým vyhledáváním zkontrolujte službu HTTPS. Výsledky se otevřou ve stávající mediální formě; vyberte tlačítko zpětné vazby.';
	@override String get cliCopyExample => 'Kopírování příkladu';
	@override String get cliCopied => 'Příklad příkazů kopírován.';
}

// Path: fileSources
class _Translations$fileSources$cs extends Translations$fileSources$en {
	_Translations$fileSources$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Soubory a knihy';
	@override String get subtitle => 'Číst, poslouchat a sledovat z vlastních souborů.';
	@override String get add => 'Přidat zdroj';
	@override String get importFiles => 'Import souborů';
	@override String get localFiles => 'Na tomto zařízení';
	@override String get source => 'Zdroj';
	@override String get name => 'Jméno';
	@override String get endpoint => 'server URL';
	@override String get smbEndpointHint => 'Příklad: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Zadejte server SMB a jednu sdílenou složku.';
	@override String get root => 'Složka nebo předpona';
	@override String get smbFolderHelp => 'Pro použití celé sdílené složky ponechte prázdné, nebo zadejte složku uvnitř ní.';
	@override String get username => 'Uživatelské jméno';
	@override String get smbDomain => 'Doména (nepovinné)';
	@override String get password => 'Heslo';
	@override String get token => 'API token';
	@override String get accessKey => 'přístupový klíč ID';
	@override String get secretKey => 'Tajný přístupový klíč';
	@override String get sessionToken => 'Session token (volitelné)';
	@override String get region => 'Region';
	@override String get clientId => 'OAuth klient ID';
	@override String get clientSecret => 'OAuth klientská tajemství (pouze desktop Google)';
	@override String get allowHttp => 'Povolit nešifrované HTTP v důvěryhodné síti';
	@override String get smbEncryption => 'Šifrovat připojení SMB3';
	@override String get smbEncryptionHint => 'Použít šifrování SMB3, pokud ho NAS podporuje.';
	@override String get connect => 'Připojit';
	@override String get cancel => 'Zrušit';
	@override String get save => 'Uložit';
	@override String get close => 'Zavřít';
	@override String get removeSource => 'Odstranění zdroje';
	@override String get disconnectMessage => 'Odpojit tento zdroj? Stažené soubory a historie čtení a poslechu zůstanou v tomto zařízení.';
	@override String get localFolder => 'Vyberte složku';
	@override String get empty => 'Nic zde zatím';
	@override String get emptyHint => 'Přidejte zdroj nebo importujte knihu, audioknihu, hudbu nebo video.';
	@override String get search => 'Vyhledejte tento složku';
	@override String get searchCached => 'Vyhledávání zachráněné knihovny';
	@override String get refresh => 'Aktualizovat';
	@override String get loadMore => 'Naložte více';
	@override String get offline => 'Dostupné offline';
	@override String get download => 'Zůstaňte offline';
	@override String get removeDownload => 'Odstranit offline kopii';
	@override String get continueReading => 'Číst dál';
	@override String get continueListening => 'Pokračovat v poslechu';
	@override String get continueWatching => 'Pokračovat ve sledování';
	@override String get read => 'Číst';
	@override String get listen => 'Poslechněte';
	@override String get play => 'Přehrát';
	@override String get pause => 'Pozastavit';
	@override String get stop => 'Zastavit';
	@override String get startOver => 'Začíná';
	@override String get finished => 'dokončená';
	@override String get markFinished => 'Mark skončil';
	@override String get markUnfinished => 'Mark nekonečný';
	@override String get editions => 'Edice a soubory';
	@override String get chapters => 'Kapitoly';
	@override String get bookmarks => 'Bookmark a poznámky';
	@override String get bookmark => 'Přidat bookmark';
	@override String get highlight => 'Vysvětlení';
	@override String get note => 'Poznámka';
	@override String get delete => 'Odstranit';
	@override String get export => 'Exportní poznámky';
	@override String get exported => 'Poznámky vyvážené';
	@override String get sync => 'Synchronizace pokroku';
	@override String get synced => 'Synchronizace pokroku';
	@override String get conflict => 'Další zařízení má jinou pozici. vyberte, kde pokračovat.';
	@override String get useLocal => 'Použijte tento přístroj';
	@override String get useRemote => 'Použijte jiné zařízení';
	@override String get history => 'Historie pozice';
	@override String get groupAudio => 'Poslech jako jedna audioknihy';
	@override String get groupHint => 'Kombinuje audio soubory v současné době nahrané v tomto složce. Nejprve nahrajte všechny stránky.';
	@override String get order => 'File objednávka';
	@override String get moveUp => 'Přemístěte se';
	@override String get moveDown => 'Přemístěte se dolů';
	@override String get speed => 'Rychlost přehrávání';
	@override String get sleep => 'Časový spánek';
	@override String get sleepOff => 'Vypnuto';
	@override String get endChapter => 'Konec kapitoly';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuta',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minut',
	);
	@override String get skipBack => 'Skok zpět';
	@override String get skipForward => 'Skok dopředu';
	@override String get smartRewind => 'Inteligentní zpět po přestávce';
	@override String get playbackOptions => 'Poslouchací možnosti';
	@override String remaining({required Object time}) => '${time} Zbývající';
	@override String get contents => 'obsah';
	@override String get readerSettings => 'Čtení nastavení';
	@override String get fontSize => 'Velikost textu';
	@override String get lineHeight => 'Řádkování';
	@override String get margin => 'Margín';
	@override String get font => 'Typové';
	@override String get serif => 'Patkové písmo';
	@override String get sans => 'Bezpatkové písmo';
	@override String get mono => 'Neproporcionální písmo';
	@override String get columns => 'Kolony';
	@override String get scroll => 'Sklíč vertikálně';
	@override String get justify => 'Zarovnat text do bloku';
	@override String get readerTheme => 'Pohled stránky';
	@override String get appTheme => 'Sledujte téma aplikace';
	@override String get paper => 'Papír';
	@override String get sepia => 'Sepi';
	@override String get night => 'Noční';
	@override String get readAloud => 'Přečíst tuto stránku nahlas';
	@override String get readAlong => 'Číst dál';
	@override String get stopReading => 'Zastavit předčítání';
	@override String get searchBook => 'Vyhledávání v knize';
	@override String get noMatches => 'Žádné zápasy';
	@override String get previousPage => 'Předchozí stránka';
	@override String get nextPage => 'Další stránka';
	@override String page({required Object number}) => 'Stránka ${number}';
	@override String get externalBlocked => 'V čtenáři jsou vnější odkazy na knihu zrušeny.';
	@override String get loading => 'Otevření...';
	@override String get narrator => 'Příběh';
	@override String get audio => 'Zvuk';
	@override String get video => 'Video';
	@override String get ebooks => 'ebooky';
	@override String get all => 'Vše';
	@override String get downloads => 'Offline soubory';
	@override String get confirmDelete => 'Odstraňte vybranou offline kopii? Vaše poloha a poznámky zůstávají.';
	@override String get errorAuthentication => 'Zadejte si znovu a znovu se připojte k tomuto zdroji.';
	@override String get errorPermission => 'Tento zdroj neposkytl přístup k požadovanému souboru.';
	@override String get errorUnavailable => 'Zdroj není k dispozici. zkuste znovu, nebo otevřete offline kopii.';
	@override String get errorUnsupported => 'Tento formát nebo připojení není na tomto zařízení podporován. zkontrolujte průvodce nastavení zdroje.';
	@override String get errorInvalidData => 'Tento soubor nebo odpověď serveru nelze bezpečně číst.';
	@override String get errorCancelled => 'Operace byla zrušena.';
	@override String get errorConflict => 'Pozice se změnila v jiné sezení. znovu otevřete položku, abyste si vybrali pozici.';
	@override String get signIn => 'Přihlásit se';
	@override String get reconnect => 'Připojení';
	@override String get folderHelp => 'Nechte bělo na začátku na zdrojovém kořene. URL S3 zahrnuje bucket.';
	@override String get preferences => 'preferencí';
	@override String get timePosition => 'Pozice';
	@override String get audioTrack => 'Zvuková stopa';
	@override String get subtitleTrack => 'Subtitle Track';
	@override String get none => 'Žádný';
	@override String get fullscreen => 'Celá obrazovka';
	@override String get syncLocation => 'Progress sync folder (volitelné)';
	@override String get syncLocationHint => 'Vyhrazená složka WebDAV pro stav aplikace PlezyNG. Zápis probíhá podmíněně; mediální soubory zůstávají beze změny.';
	@override String get audiobooks => 'Audioknihy';
	@override String get comics => 'Komiksy';
	@override String get scan => 'Skenování knih a médií';
	@override String get browserReader => 'Otevřený čtenář';
	@override String get browserReaderHelp => 'Čtečka je otevřena ve vašem prohlížeči.Zachovávejte PlezyNG otevřený, abyste ušetřili své místo a poznámky.';
	@override String get on => 'Na';
	@override String get advancedSetup => 'App registrace';
	@override String get microsoftSignIn => 'Přihlaste se k Microsoftu';
	@override String get zoomIn => 'Zoom v';
	@override String get zoomOut => 'Zoom ven';
	@override String get fitPage => 'Fit stránka';
	@override String get fitWidth => 'Vhodná šířka';
	@override String get actualSize => 'Aktuální velikost';
	@override String get goToPage => 'Přejděte na stránku';
	@override String get goToSection => 'Přejděte do kapitoly';
	@override String pageRange({required Object count}) => 'Zadejte číslo od 1 do ${count}';
	@override String get pageLayout => 'Stránka layout';
	@override String get automatic => 'automatické';
	@override String get singlePage => 'Jednotlivá stránka';
	@override String get twoPages => '2 Stránky';
	@override String get readingDirection => 'Čtení směr';
	@override String get leftToRight => 'Zleva doprava';
	@override String get rightToLeft => 'Zprava doleva';
	@override String get letterSpacing => 'Dopis k prostoru';
	@override String get wordSpacing => 'Slovo spacing';
	@override String get readerControlsHelp => 'Stránky zvětšíte roztažením dvou prstů nebo pomocí ovládání přiblížení. Tažením stránku posunete. Ctrl/⌘ s + nebo − upravuje přiblížení; Ctrl/⌘ s 0 ho obnoví. Page Up a Page Down otáčejí stránky.';
	@override String get imagePage => 'Komiksová stránka';
	@override String get resetReader => 'Obnovit výchozí nastavení čtení';
	@override String get zoom => 'Přiblížit';
	@override String get useFiles => 'Použijte soubory a knihy';
	@override String get cancelScan => 'Zrušit skenování';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Limit pro offline stahování';
	@override String get offlineQuotaHelp => 'Nastavení maximálního místa použitého offline kopie, dovezené soubory a stažené stahování. Snížení limitu neodstraňuje stávající kopie.';
	@override String get offlineStorageUsage => 'Offline skladování';
	@override String get reservedStorage => 'Rezervované';
	@override String get downloadQueue => 'Stáhnout Queue';
	@override String get downloadRunning => 'Stáhnout';
	@override String get downloadQueued => 'Čekání';
	@override String get downloadPaused => 'Odpočinek';
	@override String get downloadFailed => 'Potřebuji zpět';
	@override String get importing => 'dovoz';
	@override String get importInterrupted => 'Import přerušený · odstranit k vymazání';
	@override String get errorQuotaExceeded => 'Zvýšení limitu nebo odstranění stažené kopie.';
	@override String get errorStorageLow => 'Neexistuje dostatek bezplatného ukládání zařízení k zachování chráněné rezervy.';
	@override String get errorStorageUnavailable => 'PlezyNG nemohl kontrolovat bezplatné ukládání zařízení, takže psaní bylo zastaveno.';
	@override String get removeDownloadJob => 'Odstranit download';
	@override String get downloadAlreadyComplete => 'Toto stahování bylo dokončeno, než by mohlo být odstraněno. položka je nyní k dispozici offline.';
	@override String get confirmRemoveDownloadJob => 'Odstranit toto stahování a odstraňovat jakékoli částečně stažené údaje? Vaše poloha a poznámky zůstane.';
}

// Path: lending
class _Translations$lending$cs extends Translations$lending$en {
	_Translations$lending$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'veřejné knihovny';
	@override String get add => 'Přidejte knihovnu';
	@override String get other => 'Další knihovna';
	@override String get libraryName => 'Název knihovny';
	@override String get libraryUrl => 'knihovny WEB';
	@override String get libraryUrlHint => 'Použijte katalog své knihovny nebo její přihlašovací stránku.';
	@override String get intro => 'Půjčte si knihu z knihovny, držte si knihy v blízkosti.';
	@override String get handoff => 'Přihlaste se, vypůjčujte si knihy a bezpečně čtěte prostřednictvím služby své knihovny.';
	@override String get openService => 'otevřená knihovna';
	@override String get findLibrary => 'Najít knihovnu';
	@override String get search => 'Vyhledávání knih a autorů';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'půjčky';
	@override String get holds => 'Rezervace';
	@override String get signIn => 'Přihlaste se k vaší knihovně';
	@override String get waiting => 'Přihlaste se do svého prohlížeče a pak se vrátíte.';
	@override String get cancel => 'Zrušit';
	@override String get disconnect => 'Odstranit knihovnu';
	@override String get disconnectMessage => 'Odebrat tuto knihovnu z tohoto profilu? Vaše výpůjčky a rezervace zůstanou u knihovny.';
	@override String get getBook => 'Získejte knihu';
	@override String get checkAvailability => 'Zkontrolujte dostupnost';
	@override String get available => 'Dostupné k půjčování';
	@override String get unavailable => 'V současné době nedostupné';
	@override String get borrow => 'Vypůjčit';
	@override String get placeHold => 'Rezervovat';
	@override String get returnBook => 'Zpět brzy';
	@override String get cancelHold => 'Zrušit rezervaci';
	@override String get confirmBorrow => 'Půjčujete si tento titul z vaší knihovny?';
	@override String get confirmReturn => 'Vrátit tento titul nyní? Abyste mohli pokračovat, možná si jej budete muset znovu vypůjčit.';
	@override String get confirmCancelHold => 'Zrušit rezervaci tohoto titulu?';
	@override String get email => 'Udržujte e-mail oznámení';
	@override String due({required Object date}) => 'Vrátit do ${date}';
	@override String queue({required Object position}) => 'Pozice ${position} v čáru';
	@override String get empty => 'Zatím tu žádné tituly.';
	@override String get openLibraryNote => 'Procházejte katalog Open Library. Možnosti čtení a vypůjčení jsou uvedeny na stránce každého titulu.';
	@override String get more => 'Naložte více';
	@override String get gateway => 'knihovny sign-in';
	@override String get gatewayHint => 'Zajištěno vaší knihovnou nebo správcem PlezyNG.';
	@override String get advanced => 'knihovny integrace';
	@override String get loadLibraries => 'Vyberte si svou knihovnu';
	@override String get expired => 'Tento úvěr skončil.';
	@override String get updated => 'Aktualizovaná knihovna';
	@override String get continueService => 'Pokračovat ve službě';
	@override String get comingSoon => 'In-app půjčka · Brzy přijde';
	@override String get comingSoonDescription => 'Libby integrace je na cestě.Můžete použít vaši knihovnu v Libby, zatímco my dokončujeme připojení.';
	@override String get suspendHold => 'Pozastavit rezervaci';
	@override String get resumeHold => 'Obnovit rezervaci';
	@override String get suspendMessage => 'Ponechat si místo ve frontě a nechat dalšího čtenáře vypůjčit si tento výtisk? Rezervaci můžete později obnovit.';
	@override String get resumeMessage => 'Obnovit rezervaci, aby vám knihovna mohla nabídnout další dostupný výtisk?';
	@override String get editEmail => 'Změna e-mailu oznámení';
}

// Path: audiobook
class _Translations$audiobook$cs extends Translations$audiobook$en {
	_Translations$audiobook$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Čtení a poslouchání synchronizace';
	@override String get syncHelp => 'Udržujte pozice čtení, pozice poslouchání, stav dokončení, poznámky a poznámky na vašich zařízeních. Vyberte připojený úložiště a použijte stejný synchronizační kód na každém zařízení. Čtení a poslouchání zůstávají oddělené.';
	@override String get addSyncSource => 'Nejprve přidejte Google Drive, OneDrive, Dropbox, WebDAV nebo S3 do souborů a knih.';
	@override String get syncDestination => 'Synchronizace účtu';
	@override String get syncFolder => 'Synchronizace mapy nebo prefiksů';
	@override String get syncFolderHelp => 'Použijte samostatnou stávající složku ve vašem WebDAV zdroji nebo předpisu S3.';
	@override String get syncCode => 'Soukromý synchronizační kód';
	@override String get syncCodeHelp => 'Vytvořte kód na prvním zařízení, pak zadejte tento kód na jiných zařízeních. Udržujte soukromou kopii: je to klíč k vašemu šifrovanému stavu. Použijte pro každou osobu jiný kód.';
	@override String get showCode => 'Zobrazit nebo skrýt synchronizační kód';
	@override String get newSyncCode => 'Vytvořte nový synchronizační kód';
	@override String get saveSync => 'Shromažďovat a synchronizovat';
	@override String get disableSync => 'Vypněte synchronizaci na tomto zařízení';
	@override String get syncSourceDisconnect => 'Odstranění tohoto zdroje vypne čtení a poslouchání synchronizace zde. šifrované synchronizace soubory zůstane v poskytovateli.';
	@override String get syncReconnect => 'Připojení úložného účtu';
	@override String lastSynced({required Object time}) => 'Poslední synchronizace na ${time}';
	@override String get syncPrivacy => 'Pouze šifrovaný pokrok a poznámky jsou uloženy. Audio a ebook soubory, účet tokeny a hesla nejsou nahrány. Google Drive a OneDrive používá aplikační úložiště; Dropbox používá PlezyNG Sync. Povolit synchronizaci může požadovat další psaní přístup. Zatímco je povolen, tato destinace vlastní progres synchronizaci; serverový pokrok zůstává oddělený.';
	@override String get syncConflicts => 'Vyberte si, kde se vrátit';
	@override String get conflictHelp => 'Tyto změny byly provedeny nezávisle.Vyberte pozici nebo verzi štítku, kterou chcete udržet.Poslední časový rámec nebo vyšší procento automaticky nevyhraje.';
	@override String syncDevice({required Object device}) => 'Přístroj ${device}';
	@override String get syncUnknownDevice => 'Neznámý přístroj';
	@override String get deletedBookmark => 'Odstraněná knižnice';
	@override String get finished => 'Dokončené';
	@override String readingPosition({required Object percent}) => 'Číst · ${percent}%';
	@override String get chapterTimeline => 'Kapitola Pokrok';
	@override String get bookTimeline => 'Celá kniha Pokrok';
	@override String bookRemaining({required Object time}) => 'Čas zůstává v této knize: ${time}';
	@override String chapterRemaining({required Object time}) => 'Čas zůstává v této kapitole: ${time}';
	@override String get unknownRemaining => 'Celkový čas k dispozici, když se hrají části';
	@override String get undoSeek => 'Poslední hledání';
	@override String get customSpeed => 'Přizpůsobená hrací rychlost';
	@override String get speedHelp => 'Vybírejte rychlost od 0,25× do 4×.';
	@override String get apply => 'aplikovat';
	@override String get customSleep => 'Přizpůsobený čas spánku';
	@override String get sleepMinutes => 'minuty (1 – 1440)';
	@override String sleepChapters({required Object count}) => 'Zastavte se po ${count} kapitolách';
	@override String get extendSleep => 'Přidejte 5 minut';
	@override String sleepRemaining({required Object time}) => 'Časovač spánku: ${time}';
	@override String get useDefaults => 'Použijte tyto ovládací prvky pro nové knihy';
	@override String get librarySort => 'Černé knihy';
	@override String get sortTitle => 'Název';
	@override String get sortAuthor => 'Autorka';
	@override String get sortNarrator => 'Příběh';
	@override String get sortSeries => 'Seriálový příkaz';
	@override String get sortRecent => 'Nedávno otevřeno';
	@override String get statusFilter => 'Status čtení';
	@override String get statusAll => 'Všechny knihy';
	@override String get statusNew => 'Nezačíná';
	@override String get statusProgress => 'V pokroku';
	@override String get statusFinished => 'Dokončené';
	@override String get goToTime => 'Jděte do času';
	@override String get timeHelp => 'Hodiny: minuty: sekundy nebo minuty: sekundy';
	@override String get recoveryHelp => 'Exportujte nedávnou šifrovanou kopii před přenesením nebo opravou synchronizačních dat. Importy se spojí s aktuálním stavem; nikdy nenahrazují místní historii synchromu.';
	@override String get recoveryExport => 'Export šifrované obnovení souborů';
	@override String get recoveryImport => 'Import šifrované obnovení souborů';
	@override String get recoveryImportConfirm => 'Spojte tento šifrovaný obnovení soubor s aktuálními čtení pozic a poznámky? existující historie bude zachována. sdílená knihovna a ID položky nejsou zahrnuty; nastavit odpovídající ID na každém zařízení před dovozem.';
	@override String get recoveryExported => 'Šifrované obnovení souboru je uloženo.';
	@override String get recoveryImported => 'Údaje o obnově se smítají.';
}

// Path: sourceSetup
class _Translations$sourceSetup$cs extends Translations$sourceSetup$en {
	_Translations$sourceSetup$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Uložený certifikát serveru';
	@override String get nfsEndpointInvalid => 'Zadejte adresu NFS, například nfs://nas:2049/export.';
	@override String get dlnaNone => 'Nenalezen žádný server DLNA. Zadejte adresu popisu zařízení ručně.';
	@override String get dlnaServers => 'Mediální servery DLNA';
	@override String get dlnaUnavailable => 'Vyhledávání DLNA není v této síti dostupné. Zadejte adresu popisu zařízení ručně.';
	@override String get dlnaSearching => 'Hledání serverů DLNA v místní síti';
	@override String get networkSearching => 'Prohledávání místní sítě…';
	@override String get dlnaDiscover => 'Najít servery DLNA';
	@override String get dlnaHelp => 'Vyhledávání závisí na multicastu v místní síti. Pokud se žádný server nezobrazí, zadejte výše adresu jeho popisu zařízení.';
	@override String get dlnaRoot => 'ID objektu DLNA; ponechte prázdné pro kořen zařízení.';
	@override String get passwordOrKey => 'Zadejte heslo nebo níže přidejte soukromý klíč.';
	@override String get sshFingerprint => 'Otisk SHA256 hostitelského klíče SSH';
	@override String get sshFingerprintHelp => 'Ověřte jej u správce serveru. Na serveru spusťte ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub a použijte hodnotu SHA256.';
	@override String get sshFingerprintKeep => 'Ponechte prázdné pro zachování připnutého otisku nebo zadejte nový otisk serveru.';
	@override String get sshAuthentication => 'Ověření SSH veřejným klíčem';
	@override String get sshAuthenticationHelp => 'Nepovinné; podporováno je i ověření heslem.';
	@override String get privateKey => 'Soukromý klíč (formát PEM nebo OpenSSH)';
	@override String get privateKeyPassphrase => 'Heslová fráze soukromého klíče';
	@override String get nfsMountPort => 'Port TCP služby připojení NFS';
	@override String get nfsMountPortHelp => 'Výchozí: 20048';
	@override String get nfsUserId => 'ID uživatele NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Výchozí: 1000. Použijte ID povolené exportem NFS na NAS.';
	@override String get nfsGroupId => 'ID skupiny NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Výchozí: 1000. Použijte ID skupiny povolené exportem NFS na NAS.';
	@override String get nfsEncryption => 'Vyžadovat šifrované NFS (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Vyžadovat TLS 1.3 pro NFS i službu připojení. Pokud jej NAS nepodporuje, spojení bude odmítnuto.';
	@override String get nfsTrustCertificate => 'Vlastní CA NFS nebo certifikát serveru (PEM, nepovinné)';
	@override String get nfsTrustHelp => 'Ponechte prázdné pro certifikáty, kterým toto zařízení důvěřuje. V případě potřeby přidejte certifikát soukromé CA nebo certifikát serveru podepsaný sebou samým; jeho názvy se musí shodovat s hostitelem v adrese NFS.';
	@override String get nfsTrustInvalid => 'Použijte certifikát CA nebo serveru ve formátu PEM. Nevkládejte soukromý klíč.';
	@override String get addTrustCertificate => 'Přidat vlastní důvěryhodný certifikát';
	@override String get replaceTrustCertificate => 'Nahradit uložený vlastní certifikát';
	@override String get nfsTlsHelp => 'RPC-with-TLS používá běžné porty NFS a služby připojení a vyžaduje podporu RFC 9289 na NAS. Je nutné TLS 1.3. Název hostitele nebo IP adresa musí odpovídat certifikátu. UID/GID AUTH_SYS nadále platí i v šifrovaném kanálu.';
	@override String get clientCertificate => 'Klientský certifikát (nepovinné)';
	@override String get clientCertificateHelp => 'Umožňuje NAS ověřit tohoto klienta; ID AUTH_SYS stále podléhají pravidlům exportu NFS na NAS.';
	@override String get savedIdentity => 'Bude použita uložená identita klienta.';
	@override String get replaceIdentity => 'Nahradit uloženou identitu klienta';
	@override String get chooseIdentity => 'Vybrat identitu klienta PKCS#12';
	@override String get identityPassphrase => 'Heslová fráze identity klienta';
	@override String get identityPassphraseHelp => 'Ponechte prázdné, pokud soubor nemá heslovou frázi.';
	@override String get removeIdentity => 'Odebrat případnou uloženou identitu klienta';
	@override String get identityStorageHelp => 'Identity klienta se ukládají do šifrovaného úložiště přihlašovacích údajů zdroje. Pokud chcete uloženou identitu zachovat, tuto část neměňte.';
	@override String get nfsLimitations => 'NFSv3 přes TCP, pouze pro čtení. Bez RPC-with-TLS není provoz NFS šifrovaný. NAS musí povolit vybraná ID AUTH_SYS a neprivilegované klientské porty (často volba exportu „insecure“). NFSv4 ani UDP nejsou podporovány.';
	@override String get nfsSetupHelp => 'Nápověda k nastavení NFS';
	@override String get nfsSetupHint => 'Pokud se připojení nenaváže, zkontrolujte tato nastavení.';
	@override String get nfsSetupDetails => 'Použijte export NFSv3 přes TCP. Je-li vyžadováno šifrování, musí NFS i služba připojení podporovat RPC-with-TLS. Vlastní certifikát ponechte prázdný pro certifikát serveru, kterému toto zařízení důvěřuje, nebo přidejte certifikát CA NAS či certifikát podepsaný sebou samým. Název v certifikátu musí odpovídat hostiteli koncového bodu. Pokud NAS vyžaduje vzájemné TLS, přidejte jeho identitu klienta PKCS#12. Nakonec ověřte, že export povoluje nastavená UID/GID AUTH_SYS a pravidla klientských portů.';
	@override String get ftpHelp => 'FTP používá pasivní režim. Použijte ftp:// pro nešifrované FTP, ftpes:// pro explicitní TLS nebo ftps:// pro TLS (implicitní na portu 990; explicitní na ostatních portech).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Volitelné hledání titulků pro samostatná videa.';
	@override String get apiKey => 'Klíč API';
	@override String get optionalUsername => 'Uživatelské jméno účtu (nepovinné)';
	@override String get optionalPassword => 'Heslo účtu (nepovinné)';
	@override String get subtitlePrivacy => 'Získejte klíč API na opensubtitles.com. Hledání odesílá název videa a dostupná ID IMDb/TMDB, nikdy videosoubor. Klíč a volitelné přihlašovací údaje účtu jsou šifrovány spolu s tímto zdrojem.';
	@override String get automaticMetadata => 'Automatická online metadata videa';
	@override String get metadataPrivacy => 'Odesílá pouze název/rok z názvu souboru a čísla epizod nebo ID NFO, nikdy média ani přihlašovací údaje. Pole NFO mají nadále přednost.';
	@override String get nfsEncryptionFailure => 'U šifrovaného NFS ověřte podporu RFC 9289 a TLS 1.3 u obou služeb NAS, název v certifikátu a UID/GID exportu. PlezyNG se nepokusí toto spojení zopakovat bez šifrování.';
	@override String get sourceConnecting => 'Připojování ke zdroji';
	@override String get metadataSearchPrivacy => 'Toto hledání názvu se odesílá do Trakt. Odesílá zadaný název, nikoli video ani přihlašovací údaje zdroje.';
	@override String get chooseMatch => 'Vybrat shodu';
	@override String get metadataMatchHelp => 'Před výběrem zkontrolujte název a rok. Trakt obdrží hledaný název; video zůstává ve svém zdroji.';
	@override String get metadataNoMatches => 'Online nebyl nalezen odpovídající název. Zkuste jiný název.';
	@override String get metadataSearch => 'Hledat online metadata';
	@override String get metadataLoading => 'Vyhledávání online informací o filmech a seriálech…';
	@override String get metadataFromTrakt => 'Online metadata z Trakt';
	@override String get metadataNoAutomaticMatch => 'Nebyla nalezena automatická shoda názvu. Vyhledejte název a vyberte shodu.';
	@override String get metadataFailed => 'Online metadata se nepodařilo načíst. Přehrávání i místní informace jsou stále dostupné.';
	@override String get videoDetailsLoading => 'Načítání informací o videu';
	@override String get subtitleKeyRequired => 'Je vyžadován klíč API OpenSubtitles';
	@override String get subtitleKeyHelp => 'Upravte tento souborový zdroj a přidejte klíč API OpenSubtitles do volitelných nastavení titulků.';
	@override String get subtitleSearchFailed => 'Hledání titulků selhalo. Zkontrolujte klíč API, připojení a přístup ke službě.';
	@override String get subtitleApplyFailed => 'Titulky se nepodařilo stáhnout nebo použít. Zkontrolujte připojení a zkuste jiný výsledek.';
	@override String get subtitleSearch => 'Hledat na OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'Hledání používá název a dostupná ID IMDb/TMDB. Videosoubor zůstává ve svém zdroji. Před výběrem zkontrolujte jazyk, označení vynucených titulků či titulků pro sluchově postižené a hodnocení.';
	@override String get movieOrShow => 'Film nebo seriál';
	@override String get subtitleTitleHint => 'Zadejte název pro upřesnění výsledků';
	@override String get subtitleLanguage => 'Jazyk titulků';
	@override String get subtitleSearching => 'Hledání na OpenSubtitles';
	@override String get subtitleNoMatches => 'Odpovídající titulky nebyly nalezeny. Zkuste jiný název nebo jazyk.';
	@override String get downloadSubtitle => 'Stáhnout titulky';
	@override String get subtitle => 'Titulky';
	@override String get nfsTlsRequired => 'Vyžadováno RPC-with-TLS';
	@override String get nfsUnencrypted => 'Nešifrované NFS';
	@override String get tlsEncrypted => 'Šifrováno pomocí TLS';
	@override String get ftpPlain => 'Nešifrované FTP';
	@override String get sshPinned => 'Šifrované SSH · připnutý hostitelský klíč';
	@override String get smbEncrypted => 'Šifrování SMB3 zapnuto';
	@override String get smbUnencrypted => 'Šifrování SMB3 vypnuto';
	@override String get httpUnencrypted => 'HTTP bez šifrování přenosu';
	@override String get checkEndpointSecurity => 'Zkontrolovat zabezpečení koncového bodu';
	@override String fieldRequired({required Object label}) => 'Povinné pole: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Pro pole „${label}“ zadejte hodnotu od ${min} do ${max}.';
	@override String replaceFile({required Object name}) => 'Nahradit ${name}';
	@override String selectedIdentity({required Object name}) => 'Vybraná identita klienta: ${name}';
	@override String subtitleRating({required Object rating}) => 'Hodnocení ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Stahování titulků: ${title}';
	@override String get sharedEntryPair => 'Porovnejte tuto položku';
	@override String get sharedEntryPairHelp => 'Vložte stejný ID pro tento položka na každém zařízení. Použijte stabilní sdílený identifikátor nebo vytvořte jeden a kopírujte ho do odpovídajícího položky. Pokrok se páří pouze tehdy, když typy souboru vydání, velikosti a objednávky se shodují. Blank odstraní toto mapování.';
	@override String get sharedEntryId => 'Sdílené položky ID';
	@override String get generateSharedEntryId => 'Vytvoření sdíleného ID položky';
	@override String get sharedLibraryId => 'ID sdílené knihovny (volitelné)';
	@override String get sharedLibraryHelp => 'Použijte stejný ID na zařízeních, které otevírají stejnou knihovnu.Tento veřejný ID pomáhá přenášet postup čtení a poznámky přes různé zdrojové připojení; není to heslo.Když poskytovatelé používají různé položky ID, páry těchto položek z jejich detailních obrazovek.';
	@override String get sharedLibraryInvalid => 'Použijte 8 až 100 písmen, čísel, bodů, podkoží nebo hyfen.';
	@override String get generateSharedLibraryId => 'Vytvoření sdíleného ID knihovny';
	@override String get nfsReadAhead => 'Žádosti o čtení NFS';
	@override String get nfsReadAheadHelp => 'Více paralelních čtení může zlepšit průchod na rychlém NAS nebo síti. Použijte 1 pokud server omezuje souběžné požadavky.';
	@override String get nfsReadTest => 'Měření NFS čtení výkonu';
	@override String get nfsReadTestHelp => 'Čte až 64 MiB z největšího souboru pro měření tohoto připojení NAS. To používá síťovou šířku pásma.';
	@override String get nfsQualificationResult => 'NFS číst měření';
	@override String get nfsReadBytes => 'Data čtení';
	@override String get nfsReadSpeed => 'měřená rychlost';
	@override String get nfsReadRequests => 'Čtěte žádosti';
	@override String get sharedEntryConflict => 'Tento sdílený ID položky je již připojen k dalším položkám v této knihovně.';
}

// Path: comics
class _Translations$comics$cs extends Translations$comics$en {
	_Translations$comics$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Přizpůsobit výšce';
	@override String get readingMode => 'Režim čtení';
	@override String get paged => 'Stránky';
	@override String get webtoon => 'Plynulé posouvání';
	@override String get coverAlone => 'Zobrazit obálku samostatně';
	@override String get splitWide => 'Rozdělit široké stránky';
	@override String get splitWideHelp => 'Zobrazí každou polovinu samostatně v pořadí čtení. Při zapnutí se stránky nezobrazují ve dvojicích.';
	@override String get thumbnails => 'Náhledy stránek';
	@override String get controlsHelp => 'Přejetím otočíte stránku. Dvojitým klepnutím změníte přizpůsobení. Při plynulém posouvání přejeďte svisle nebo použijte Page Up a Page Down.';
	@override String get savedForComic => 'Nastavení zobrazení se pro tento komiks ukládá v tomto profilu.';
	@override String get readLists => 'Seznamy četby';
	@override String get collections => 'Kolekce';
}

// Path: games
class _Translations$games$cs extends Translations$games$en {
	_Translations$games$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Games';
	@override String get enable => 'Show Games for this profile';
	@override String get enableDescription => 'Discover your gaming computers and play with an embedded streaming engine.';
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
	@override String get recent => 'Recently opened';
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
	@override String get touchDescription => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.';
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
	@override String get helpBody => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.';
	@override String get cancel => 'Cancel';
	@override String get scanning => 'Looking for computers…';
	@override String get saveShortcut => 'Save shortcut';
	@override String get manualHint => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.';
	@override String get engineUnavailable => 'In-app streaming is not available here yet';
	@override String get nativeEnginePending => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.';
	@override String get steamEnginePending => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.';
	@override String get steamBetaTitle => 'Steam beta · Pyrowave';
	@override String get steamBetaDescription => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.';
	@override String get steamLibrary => 'Steam library';
	@override String get linkSteamAccount => 'Link Steam account';
	@override String get refreshSteamAccount => 'Refresh Steam account';
	@override String get unlinkSteamAccount => 'Unlink Steam account';
	@override String get unlinkSteamAccountConfirm => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.';
	@override String get steamAccountLinked => 'Steam account linked. Games imported.';
	@override String get steamLibraryPrivate => 'Steam account linked. Its library is private or unavailable, so no games were imported.';
	@override String get steamAppId => 'Steam App ID';
	@override String get steamLibraryStale => 'Steam could not refresh the library. Showing the last available catalog.';
	@override String get steamLibraryTruncated => 'Showing up to 2,000 games. The Steam catalog was truncated.';
	@override String get connecting => 'Connecting…';
	@override String get disconnect => 'Disconnect';
	@override String get streamControls => 'Stream controls';
	@override String get steamPairInstructions => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.';
	@override String get steamLibraryHint => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.';
}

// Path: deepLinks
class _Translations$deepLinks$cs extends Translations$deepLinks$en {
	_Translations$deepLinks$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Tento odkaz Plezy není platný.';
	@override String profileNotFound({required Object profile}) => 'Žádný profil se neshoduje s "${profile}".';
	@override String get serverUnavailable => 'Nemohla jsem se dostat na server pro tento odkaz.';
	@override String get notFound => 'Tento název v knihovně nenajdete.';
	@override String get unsupportedItem => 'Tento odkaz nelze hrát.';
	@override String get noLiveTv => 'Žádný Live TV server není k dispozici pro tento odkaz.';
	@override String channelNotFound({required Object channel}) => 'Nemohla jsem najít kanál "${channel}".';
	@override String get showLink => 'Zobrazit link';
	@override String get showProfileLink => 'Zobrazit profilový link';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Otevření tohoto odkazu hraje další epizodu. Přidejte &mode=shuffle k hraní show na shuffle.';
	@override String get movieHint => 'Otevření tohoto odkazu hraje film.';
	@override String get episodeHint => 'Otvírání tohoto odkazu hraje tento epizod.';
	@override String get profileHint => 'Otevření tohoto odkazu přepíná na tento profil.';
	@override String openAsProfile({required Object name}) => 'Otevřete jako ${name}';
	@override String get copy => 'Kopírování';
	@override String get copied => 'Link kopírovaný';
}

// Path: householdSetup
class _Translations$householdSetup$cs extends Translations$householdSetup$en {
	_Translations$householdSetup$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nastavení domácnosti';
}

// Path: issueReport
class _Translations$issueReport$cs extends Translations$issueReport$en {
	_Translations$issueReport$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nahlásit problém';
	@override String get instructions => 'Naskenujte QR kód a otevřete předvyplněný návrh na GitHubu. Před odesláním ho zkontrolujte.';
	@override String get privacy => 'Návrh obsahuje verzi aplikace, platformu a počty připojení. Neobsahuje adresy serverů, názvy účtů a profilů, názvy médií ani cesty k souborům.';
	@override String get logPrivacy => 'Protokoly jsou volitelné. Před nahráním je zkontrolujte. Jejich ID se přidá do návrhu, který může být veřejný.';
	@override String get openDraft => 'Otevřít návrh na GitHubu';
}

// Path: appIcon.names
class _Translations$appIcon$names$cs extends Translations$appIcon$names$en {
	_Translations$appIcon$names$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'půlnoci';
	@override String get ember => 'Člověk';
	@override String get paper => 'Papír';
	@override String get oled => 'OLED';
	@override String get line => 'Linie';
	@override String get ocean => 'Oceán';
	@override String get ultraviolet => 'ultrafialová';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Západ slunce';
	@override String get gold => 'Zlato';
	@override String get titanium => 'Titanium';
	@override String get glass => 'sklo';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Syntetické vlny';
	@override String get pixel => 'Pixelová';
	@override String get neon => 'Neon';
	@override String get sticker => 'Stickerová';
	@override String get ticket => 'Vstupenky';
	@override String get pop => 'Pop';
	@override String get strata => 'Vrstvy';
	@override String get facet => 'tvář';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$cs extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

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
class _Translations$common$mediaKind$cs extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'představení';
	@override String get season => 'Série';
	@override String get episode => 'Epizoda';
	@override String get artist => 'Interpret';
	@override String get album => 'Album';
	@override String get track => 'Stopa';
	@override String get collection => 'Kolekce';
	@override String get playlist => 'Seznam skladeb';
	@override String get clip => 'Filmový klip';
	@override String get photo => 'Fotka';
	@override String get folder => 'Složka';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$cs extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Otevřete doporučení a položky z propojených zdrojů objevování.';
	@override String get libraries => 'Otevřete své propojené mediální knihovny.';
	@override String get liveTv => 'Otevřete Live TV, když ji server poskytuje; jinak startup padne zpět na domov.';
	@override String get search => 'Vyhledávání otevřených médií.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$cs extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get bg => 'pozadí';
	@override String get surface => 'Povrch';
	@override String get outline => 'Výstupy';
	@override String get text => 'Text';
	@override String get textMuted => 'Sekundární text';
	@override String get accent => 'Zvýraznění';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$cs extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Text na pozadí';
	@override String get textOnSurface => 'Text na povrchu';
	@override String get textMutedOnBg => 'Sekundární text na pozadí';
	@override String get textMutedOnSurface => 'Sekundární text na povrchu';
	@override String get accentOnBg => 'Pozor na pozadí';
	@override String get accentOnSurface => 'Zvláštní důraz na povrch';
	@override String get labelOnAccent => 'Tisková značka na akcentě';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$cs extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Hrát / Pause';
	@override String get volumeUp => 'Zvýšit hlasitost';
	@override String get volumeDown => 'Volume dolů';
	@override String seekForward({required Object seconds}) => 'Hledat dopředu (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Hledat zpět (${seconds}s)';
	@override String get fullscreenToggle => 'Srovnání Fullscreen';
	@override String get muteToggle => 'Společně s MUT';
	@override String get subtitleToggle => 'Podtitulky společně';
	@override String get audioTrackNext => 'Další Audio Track';
	@override String get subtitleTrackNext => 'Následující příspěvek Subtitle Track';
	@override String get chapterNext => 'Další kapitola';
	@override String get chapterPrevious => 'Předchozí kapitola';
	@override String get episodeNext => 'Další díl';
	@override String get episodePrevious => 'Předchozí epizoda';
	@override String get speedIncrease => 'Zvýšení rychlosti';
	@override String get speedDecrease => 'Snížení rychlosti';
	@override String get speedReset => 'rychlost reset';
	@override String get zoomIn => 'Zoom v';
	@override String get zoomOut => 'Zoom ven';
	@override String get zoomReset => 'Zpět na Zoom';
	@override String get subSeekNext => 'Vyhledejte další subtitle';
	@override String get subSeekPrev => 'Předchozí Předchozí Subtitle';
	@override String get subtitleDelayIncrease => 'Zpoždění podtitulů';
	@override String get subtitleDelayDecrease => 'Podtitulky Advance';
	@override String get shaderToggle => 'Společně s Shaders';
	@override String get skipMarker => 'Vstupní úvěr / Credit';
	@override String get screenshot => 'Zobrazit screenshot';
	@override String get framePrevious => 'Předchozí rámec';
	@override String get frameNext => 'Další rámec';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$cs extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Vyžaduje Android 8.0 nebo novější';
	@override String get iosVersion => 'Vyžaduje iOS 15.0 nebo novější';
	@override String get permissionDisabled => 'Obraz v obrázku je vypnut. Aktivovat ho v nastavení systému.';
	@override String get notSupported => 'Přístroj nepodporuje režim obrázku v obrazu';
	@override String get voSwitchFailed => 'Nedokázal přepínat výstup videa na obrázek v obrazu';
	@override String get failed => 'Obrázek v obraze se neuskutečnil';
	@override String get prepareFailed => 'Obrázek v obraze nelze připravit';
	@override String unknown({required Object error}) => 'Chyba se vyskytla: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$cs extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get no => 'Udržujte písma, barvy, velikosti a umístění napsané v souboru podtitulů.';
	@override String get yes => 'Umožňujte nastavení podtitulového stylu hráče přizpůsobit podtituly ASS.';
	@override String get scale => 'Aplikujte stylování hráče a rozsah vestavěných velikostí, aby odpovídala video rozměrů.';
	@override String get force => 'Nahraďte vestavěné styly ASS stylem subtitu hráče.';
	@override String get strip => 'Odstranit vestavěné formátování ASS a přinést podtitul text jasně.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$cs extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render na plné rozlišení povrchu displeje pro nejjasnější výsledek.';
	@override String get video => 'Render používá video rozlišení jako odkaz, který může snížit práci na vysoce rozlišených obrazovkách.';
	@override String get threeQuarter => 'Render na 75% rozlišení povrchu displeje pro skromné úspory výkonu.';
	@override String get half => 'Odstranit na 50% rozlišení povrchu displeje, aby se snížila práce, s jemnějšími okraji.';
	@override String get third => 'Render na třetinu rozlišení povrchu displeje ke snížení práce, s jemnějšími okraji.';
	@override String get quarter => 'Render na jednu čtvrtinu rozlišení povrchu displeje ke snížení práce, s nejjemnější výsledkem.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$cs extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio a subtituly';
	@override String get libraryDisplay => 'Knihovna';
	@override String get personalMedia => 'Osobní média';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$cs extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get none => 'Manuálně vybrané';
	@override String get noneDescription => 'Nikdy nevyměňte subtituly sami.';
	@override String get defaultMode => 'Podívejte se na track flags';
	@override String get defaultModeDescription => 'Použijte výchozí a nucené vlajky uložené na každé podtitulové stopě.';
	@override String get always => 'Vždy povolená';
	@override String get alwaysDescription => 'Přejděte na podtitulovou stopu v preferovaném jazyce, kdykoli existuje.';
	@override String get onlyForced => 'Pouze podtitulky';
	@override String get onlyForcedDescription => 'Připravte pouze stopy označené jako nucené.';
	@override String get smart => 'Zahraniční audio';
	@override String get smartDescription => 'Přepínání podtitulů pouze tehdy, když je audio v jiném jazyce.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$cs extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Nejlépe ne-SDH podtituly';
	@override String get preferSdh => 'Přednost SDH podtitulů';
	@override String get onlySdh => 'Pouze subtituly SDH';
	@override String get onlyNonSdh => 'Pouze ne-SDH podtituly';
	@override String get preferNonSdhDescription => 'Přednost standardních titulů, když jsou k dispozici jak standardní, tak i verze SDH.';
	@override String get preferSdhDescription => 'Přednost SDH podtitulů, když jsou k dispozici, ale umožňují standardní podtituly jako padnutí.';
	@override String get onlySdhDescription => 'Použijte pouze podtituly SDH; nepadněte zpět do standardních podtitulů.';
	@override String get onlyNonSdhDescription => 'Používejte pouze standardní podtituly; vyloučte SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$cs extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Přednost nepovinných titulů';
	@override String get preferForced => 'Upřednostňujeme podtitulky';
	@override String get onlyForced => 'Pouze podtitulky';
	@override String get onlyNonForced => 'Pouze nepovinné podtitulky';
	@override String get preferNonForcedDescription => 'Upřednostňuje pravidelné podtituly, ale umožňuje nucené stopy jako padnutí.';
	@override String get preferForcedDescription => 'Upřednostňuje nucené stopy, když jsou k dispozici, ale umožňují pravidelné podtituly jako padnutí.';
	@override String get onlyForcedDescription => 'Použijte pouze stopy označené jako nucené.';
	@override String get onlyNonForcedDescription => 'Vylučte stopy označené jako nucené.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$cs extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nikdy';
	@override String get moviesAndShows => 'Filmy a televizní představení';
	@override String get movies => 'Filmy pouze';
	@override String get shows => 'Televizní show pouze';
	@override String get noneDescription => 'Nevykazujte sledované kontrolní značky.';
	@override String get moviesAndShowsDescription => 'Zobrazit sledované kontroly pro filmy a televizní pořady.';
	@override String get moviesDescription => 'Zobrazit sledované kontroly pouze pro filmy.';
	@override String get showsDescription => 'Zobrazit sledované kontroly pouze pro televizní pořady.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$cs extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Uživatelé a kritikové';
	@override String get usersOnly => 'Pouze uživatelé';
	@override String get criticsOnly => 'Kritika pouze';
	@override String get nobody => 'skryté';
	@override String get usersAndCriticsDescription => 'Zobrazit uživatelské hodnocení a kritické hodnotení.';
	@override String get usersOnlyDescription => 'Zobrazit hodnocení a recenze předložené uživateli.';
	@override String get criticsOnlyDescription => 'Zobrazit kritické hodnocení a recenze.';
	@override String get nobodyDescription => 'Ukrývejte hodnocení a recenze.';
}

// Path: discover.findNext
class _Translations$discover$findNext$cs extends Translations$discover$findNext$en {
	_Translations$discover$findNext$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Najděte si něco dalšího';
	@override String get open => 'Najděte si něco dalšího';
	@override String get anyTime => 'Libovolně dlouho';
	@override String get timeAvailable => 'Kolik máte času?';
	@override String get filters => 'Vyberte si pro tuto chvíli';
	@override String get watch => 'Sledovat';
	@override String get listen => 'Poslouchat';
	@override String get read => 'Číst';
	@override String finishable({required Object duration}) => 'Doba do dokončení: ${duration}';
	@override String aboutDuration({required Object duration}) => 'Přibližná délka: ${duration}';
	@override String nextUnit({required Object duration}) => 'Další kapitola · ${duration}';
	@override String totalDuration({required Object duration}) => 'Celkem ${duration}';
	@override String get timingVaries => 'Délka se může lišit';
	@override String get notNow => 'Teď ne';
	@override String get swipeHint => 'Posuňte obal směrem k šipce nebo použijte tlačítka níže.';
	@override String get saved => 'Uložené tipy';
	@override String savedCount({required Object count}) => 'Uložené tipy · ${count}';
	@override String get undo => 'Zpět';
	@override String get details => 'Podrobnosti';
	@override String get noPicks => 'Zatím není z čeho vybírat';
	@override String get noPicksHint => 'Začněte připojením knihovny nebo přidáním zdroje médií.';
	@override String get noMatches => 'Pro tuto chvíli nic nevyhovuje';
	@override String get noMatchesHint => 'Zkuste jiný druh médií nebo si vyhraďte více času.';
	@override String get allDone => 'Prošli jste všechny tipy';
	@override String get allDoneHint => 'Vytvořte nový výběr a zobrazte si tyto tipy znovu.';
	@override String get refresh => 'Najít další výběr';
	@override String sourceReason({required Object source}) => 'Ze zdroje ${source}';
	@override String libraryReason({required Object library}) => 'Z knihovny ${library}';
	@override String get ownedReason => 'Z vaší knihovny';
	@override String get liveNow => 'Právě se vysílá';
	@override String get watchLive => 'Sledovat živě';
	@override String get filterAnything => 'Cokoli';
	@override String get filterWatch => 'Sledovat';
	@override String get filterListen => 'Poslouchat';
	@override String get filterRead => 'Číst';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Použít';
	@override String get openFailed => 'Tato položka už není dostupná. Obnovte výběr a zkontrolujte to znovu.';
	@override String get changeFailed => 'Změnu se nepodařilo uložit. Zkuste to znovu.';
	@override String get savedLimit => 'Seznam uložených tipů je plný. Odeberte jeden tip, abyste mohli uložit další.';
	@override String get chooseHint => 'Otevřete titul, uložte si ho na později nebo ho přeskočte.';
	@override String get howItWorks => 'Jak to funguje';
	@override String get notNowHelp => 'Tento titul zatím přeskočíte. Zůstane ve vaší knihovně.';
	@override String get saveHelp => 'Uložte ho mezi uložené tipy tohoto profilu na tomto zařízení. Uložení titul nestáhne.';
	@override String get openHelp => 'Výběrem obalu zobrazíte podrobnosti. Hlavní akcí můžete titul přehrát, číst nebo otevřít.';
	@override String get controlsHelp => 'Klávesnice nebo ovladač: vyberte tlačítko a stiskněte Enter nebo Vybrat. Zpět obnoví poslední volbu.';
	@override String get artworkLoading => 'Načítání obrázku…';
	@override String get artworkUnavailable => 'Obrázek není k dispozici';
	@override String get savedFeedback => 'Přidáno mezi uložené tipy';
	@override String get skippedFeedback => 'Zatím přeskočeno';
	@override String get releaseToConfirm => 'Uvolněním potvrďte';
	@override String get remoteHint => 'Vybraný obal: ← / → volba · Vybrat: podrobnosti · ↑ / ↓ přesun výběru';
}

// Path: discover.person
class _Translations$discover$person$cs extends Translations$discover$person$en {
	_Translations$discover$person$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get born => 'narození';
	@override String get died => 'Zemřel';
	@override String get birthplace => 'Místo narození';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (ve věku ${age})';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (stár ${age})';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$cs extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Doporučené';
	@override String get browse => 'Procházet';
	@override String get collections => 'Kolekce';
	@override String get playlists => 'Seznamy skladeb';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$cs extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Skupinování';
	@override String get all => 'Vše';
	@override String get movies => 'Filmy';
	@override String get shows => 'Seriály';
	@override String get seasons => 'Série';
	@override String get episodes => 'Epizody';
	@override String get artists => 'Interpreti';
	@override String get albums => 'Alba';
	@override String get tracks => 'Stopy';
	@override String get folders => 'Složky';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$cs extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Žánr';
	@override String get year => 'Rok';
	@override String get contentRating => 'Hodnocení obsahu';
	@override String get tag => 'Štítek';
	@override String get unwatched => 'Nepřehlédnutí';
	@override String get unplayed => 'Nepřehrané';
	@override String get favorites => 'Oblíbené';
	@override String get filePath => 'Cesta k souboru';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$cs extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Název';
	@override String get dateAdded => 'Datum přidání';
	@override String get releaseDate => 'Datum vydání';
	@override String get rating => 'Hodnocení';
	@override String get communityRating => 'Hodnocení komunity';
	@override String get criticRating => 'Kritické hodnocení';
	@override String get userRating => 'Uživatelská hodnocení';
	@override String get datePlayed => 'Datum přehrání';
	@override String get playCount => 'Počet přehrání';
	@override String get productionYear => 'Výroční rok';
	@override String get runtime => 'Délka';
	@override String get officialRating => 'Oficiální rating';
	@override String get premiereDate => 'Datum premiéry';
	@override String get startDate => 'Start datum';
	@override String get airTime => 'Čas vysílání';
	@override String get studio => 'Studio';
	@override String get random => 'Náhodně';
	@override String get dateShared => 'Datum sdílené';
	@override String get latestEpisodeAirDate => 'Poslední epizoda Air Date';
	@override String get lastEpisodeDateAdded => 'Poslední epizoda Datum přidáno';
	@override String get dateDownloaded => 'Datum stáhnout';
	@override String get size => 'Velikost';
	@override String get library => 'Knihovna';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$cs extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get include => 'zahrnuje';
	@override String get exclude => 'vyloučení';
	@override String get any => 'jakýkoliv';
	@override String get yes => 'Ano';
	@override String get no => 'Ne';
	@override String not({required Object value}) => 'Nejen ${value}';
	@override String valueCount({required Object count}) => '${count} vybráno';
	@override String valueCountExcluded({required Object count}) => '${count} vyloučeno';
	@override String get searchValues => 'Hledací hodnoty';
	@override String get noValues => 'Žádné hodnoty';
	@override String get matchContains => 'Obsah';
	@override String get matchNotContains => 'Neobsahuje';
	@override String get matchIs => 'Je to';
	@override String get matchIsNot => 'Není';
	@override String get matchBeginsWith => 'Začíná s';
	@override String get matchEndsWith => 'Končí s';
	@override String get textHint => 'Typ do zápasu';
	@override String get from => 'od';
	@override String get to => 'na';
	@override String range({required Object from, required Object to}) => '${from} až ${to}';
	@override String atLeast({required Object value}) => '${value} a výše';
	@override String atMost({required Object value}) => 'až ${value}';
	@override String dateLastDays({required Object count}) => 'Poslední ${count} dní';
	@override String get dateLastYear => 'Minulý rok';
	@override String dateOlderThanDays({required Object count}) => 'starší než ${count} dní';
	@override String get dateOlderThanYear => 'starší než rok';
}

// Path: libraries.selection
class _Translations$libraries$selection$cs extends Translations$libraries$selection$en {
	_Translations$libraries$selection$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Vyberte položky';
	@override String selectedCount({required Object count}) => '${count} vybráno';
	@override String get actions => 'Výběr akcí';
	@override String get confirmDescendants => 'To se mění všechny epizody ve vybraných show a sezónách.';
	@override String get confirmUnwatched => 'Tím se také vymaže průběh přehrávání vybraných položek.';
	@override String confirmCount({required Object count}) => 'Vybrané položky: ${count}.';
	@override String completed({required Object count}) => 'Aktualizované položky: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Aktualizováno ${succeeded}; selhaly ${failed}. selhaly položky zůstávají vybrány.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$cs extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Řízení průzkumných schodů';
	@override String get manageDescription => 'Vyberte si a uspořádat seznamy z vašeho účtu MDBList';
	@override String get description => 'Vyberte si veřejné filmy a televizní seznamy z účtu MDBList. Vytvořte nebo kopírujte seznamy na MDBList, pak aktualizujte.';
	@override String get selected => 'vybrané podlahy';
	@override String get available => 'Dostupné účetní listy';
	@override String get noLists => 'Žádné veřejné filmy nebo televizní seznamy se nevrátily. Vytvořte nebo kopírujte seznam na MDBList, pak aktualizujte.';
	@override String get displayName => 'Shelf název';
	@override String get nameHint => 'Zanechte pryč, abyste použili název zdrojového seznamu.';
	@override String get add => 'Přidejte shelf';
	@override String get save => 'Záchranářská schůzka';
	@override String moveUp({required Object title}) => 'Přesun ${title} nahoru';
	@override String moveDown({required Object title}) => 'Stáhnout ${title} dolů';
	@override String get unavailable => 'Tento seznam není k dispozici. Odstranit nebo odstranit jeho šálek v nastavení.';
	@override String get rateLimited => 'Byl dosažen limit požadavků MDBList. Zkuste to později.';
	@override String get loadFailed => 'Nemůžete nabíjet police. zkontrolujte připojení a odpočinek.';
	@override String get saveFailed => 'Nemohla jsem se zeptat.Prosím se vzpamatovat.';
	@override String get accountChanged => 'Účet nebo profil se změnil. znovu otevřete tyto nastavení.';
	@override String get settingsUnreadable => 'Ušetřené police se nemohou přečíst. Vyberte své seznamy znovu, abyste nahradili tyto nastavení.';
}

// Path: explore.rows
class _Translations$explore$rows$cs extends Translations$explore$rows$en {
	_Translations$explore$rows$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'sledovací seznam';
	@override String get recommendedMovies => 'Doporučené filmy';
	@override String get recommendedShows => 'Doporučené show';
	@override String get trendingMovies => 'Trendy filmů';
	@override String get trendingShows => 'Trendové show';
	@override String get popularMovies => 'Populární filmy';
	@override String get popularShows => 'Populární show';
	@override String get trendingAnime => 'Trendy Anime';
	@override String get suggestedAnime => 'Doporučené anime';
	@override String get airingAnime => 'Nejlepší Airing Anime';
	@override String get popularAnime => 'Nejpopulárnější anime';
	@override String get trending => 'Trendy';
	@override String get upcomingMovies => 'Nadcházející filmy';
	@override String get upcomingShows => 'Předchozí představení';
}

// Path: explore.status
class _Translations$explore$status$cs extends Translations$explore$status$en {
	_Translations$explore$status$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get airing => 'vzduch';
	@override String get ended => 'Ukončeno';
	@override String get canceled => 'Zrušený';
	@override String get upcoming => 'Nadcházející';
}

// Path: explore.badge
class _Translations$explore$badge$cs extends Translations$explore$badge$en {
	_Translations$explore$badge$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} populární';
	@override String rankAiring({required Object n}) => '#${n} vzduch';
	@override String rankRated({required Object n}) => '#${n} hodnoceno';
	@override String rankTrending({required Object n}) => '#${n} trendování';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} v ${season}';
	@override String watchingNow({required Object n}) => '${n} sledování';
	@override String get available => 'Dostupné';
	@override String get partiallyAvailable => 'Částečně k dispozici';
	@override String get availableIn4k => '4K k dispozici';
	@override String get requested => 'požadované';
	@override String get pendingApproval => 'Čekající schválení';
	@override String get processing => 'zpracování';
	@override String get declined => 'zkreslené';
	@override String get requestFailed => 'Žádost selhala';
	@override String get requested4k => '4K požadováno';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} sezóny';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} v ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Další v ${duration}';
	@override String episodesShort({required Object n}) => '${n} ep.';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep.';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$cs extends Translations$explore$stats$en {
	_Translations$explore$stats$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} Zprávy';
	@override String viewersDay({required Object n}) => 'Dnes sledovalo: ${n}';
	@override String viewersWeek({required Object n}) => 'Tento týden sledovalo: ${n}';
	@override String viewersMonth({required Object n}) => 'Tento měsíc sledovalo: ${n}';
	@override String viewersYear({required Object n}) => 'Tento rok sledovalo: ${n}';
	@override String viewersAllTime({required Object n}) => '${n} diváků';
	@override String planning({required Object n}) => '${n} Plánování sledovat';
	@override String favorited({required Object n}) => '${n} oblíbené';
	@override String dropRate({required Object percent}) => '${percent} se to podařilo';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentář',
		few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentáře',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentáře',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentářů',
	);
	@override String votes({required Object n}) => '${n} hlasů';
	@override String watching({required Object n}) => 'Právě sleduje: ${n}';
	@override String completed({required Object n}) => '${n} dokončeno';
	@override String onHold({required Object n}) => '${n} na držení';
	@override String dropped({required Object n}) => '${n} zrušeno';
}

// Path: explore.season
class _Translations$explore$season$cs extends Translations$explore$season$en {
	_Translations$explore$season$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Zima';
	@override String get spring => 'Jarní';
	@override String get summer => 'Léto';
	@override String get fall => 'Pád';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$cs extends Translations$explore$format$en {
	_Translations$explore$format$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get tv => 'televize';
	@override String get tvShort => 'TV krátký';
	@override String get movie => 'Film';
	@override String get special => 'Speciální';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Hudba';
	@override String get other => 'Ostatní';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$cs extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get original => 'originál';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Světelný román';
	@override String get novel => 'Román';
	@override String get visualNovel => 'Vizuální román';
	@override String get game => 'Hračky';
	@override String get webComic => 'Webové komiksy';
	@override String get musicRelease => 'Hudba';
	@override String get otherMedia => 'Ostatní';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$cs extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Herec';
	@override String get director => 'Režisér';
	@override String get writer => 'Scénárista';
	@override String get producer => 'Producent';
	@override String get creator => 'Tvůrce';
	@override String get composer => 'Skladatel';
}

// Path: explore.relation
class _Translations$explore$relation$cs extends Translations$explore$relation$en {
	_Translations$explore$relation$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Předpověď';
	@override String get sequel => 'Sekundární';
	@override String get sideStory => 'Strana příběhu';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Alternativní verze';
	@override String get summary => 'Shrnutí';
	@override String get parentStory => 'Příběh rodičů';
	@override String get adaptation => 'Přizpůsobení';
	@override String get other => 'související';
}

// Path: explore.detail
class _Translations$explore$detail$cs extends Translations$explore$detail$en {
	_Translations$explore$detail$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Originální název';
	@override String get alsoKnownAs => 'Také známý jako';
	@override String get studios => 'Studia';
	@override String get country => 'Země';
	@override String get language => 'Jazyk';
	@override String get released => 'uvolněné';
	@override String get physicalRelease => 'na disku';
	@override String get ended => 'Ukončeno';
	@override String addedOn({required Object date}) => 'Přidat ${date}';
	@override String get yourRating => 'Váš rating';
	@override String get budget => 'Rozpočet';
	@override String get revenue => 'Boxovní kancelář';
	@override String get contentAdvisory => 'Věkové vedení';
	@override String get tags => 'Štítky';
	@override String get revealSpoilerTags => 'Zobrazit spoiler tags';
	@override String get links => 'Levice';
	@override String get watchOn => 'Podívejte se';
	@override String get watchTrailer => 'Podívejte se trailer';
	@override String openOn({required Object site}) => 'Otevřeno na ${site}';
	@override String get crew => 'Posádka';
	@override String get ratings => 'Hodnocení';
	@override String get schedule => 'Plánované nahrávání';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: 'Doporučeno uživatelem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}',
		other: 'Doporučená ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uživatelů',
	);
	@override String recommendedBy({required Object who}) => 'Doporučeno od ${who}';
	@override String favoritedBy({required Object who}) => 'Oblíbeno ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ještě není zobrazeno';
	@override String recommendedByPercent({required Object percent}) => 'Doporučeno ${percent} diváků';
	@override String get relatedTitles => 'Související tituly';
	@override String get background => 'pozadí';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$cs extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Začínáme brzy (sekundy)';
	@override String get endLate => 'Konec pozdě (sekundy)';
	@override String get newOnly => 'Pouze nové epizody';
	@override String get anyChannel => 'Záznam na jakémkoliv kanálu';
	@override String get anyTime => 'Záznam v každém okamžiku';
	@override String get skipInLibrary => 'Skok epizod již v knihovně';
	@override String get keepUpTo => 'epizody, které se musí udržet';
	@override String get keepUpToHint => '0 zachovává každou epizodu';
}

// Path: music.discography
class _Translations$music$discography$cs extends Translations$music$discography$en {
	_Translations$music$discography$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles a EPs';
	@override String get live => 'Živě';
	@override String get compilations => 'Kompilace';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$cs extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} stisknutá hra';
	@override String get playbackStarted => 'Playback začíná';
	@override String paused({required Object name}) => '${name} přestávka';
	@override String get playbackPaused => 'Playback přestávka';
	@override String jumpedTo({required Object name, required Object position}) => '${name} skok na ${position}';
	@override String roomJumpedTo({required Object position}) => 'Přihláška na ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} nastavte rychlost na ${speed}';
	@override String speedChanged({required Object speed}) => 'Rychlost nastavená na ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} zahájil ${title}';
	@override String mediaStarted({required Object title}) => 'Nyní hrát ${title}';
	@override String stoppedMedia({required Object name}) => '${name} zastavilo video';
	@override String get mediaStopped => 'Video se zastavil';
	@override String waitingFor({required Object name}) => 'Čekáme na ${name}...';
	@override String get waitingForSomeone => 'Čekání na někoho, kdo se chytí...';
	@override String get finished => 'dokončená';
	@override String hostChangedTo({required Object name}) => '${name} je nyní hostitelem';
	@override String get youAreNowHost => 'Nyní jste hostitelem';
	@override String joined({required Object name}) => '${name} připojeno';
	@override String left({required Object name}) => '${name} pozůstatek';
	@override String get controlRefused => 'Pouze hostitel může ovládat playback';
	@override String get searchFailed => 'Některé servery nemohly být vyhledávány pro video místnosti';
	@override String get playBlocked => 'Tisková hra začíná';
	@override String get shareFailed => 'Nemohla bych toto video sdílet s místností';
	@override String get downloadNotShared => 'Stáhnout se s místností nesdílejí, zatímco jejich server je offline';
	@override String get openFailed => 'Nemohla jsem otevřít videa místnosti';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$cs extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Hostitel končí místnost';
	@override String get kicked => 'Byli jste odstraněni z místnosti.';
	@override String get expired => 'Místnost vypršela';
	@override String get replaced => 'Připojili jste se k této místnosti na jiném zařízení';
	@override String get lost => 'Ztrácí připojení k místnosti';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$cs extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Kód má 6 písmen a čísel, bez 0, 1, I, L nebo O.';
	@override String get roomNotFound => 'Žádná místnost nemá tento kód, může to skončit.';
	@override String get roomFull => 'Tato místnost je plná.';
	@override String get roomLocked => 'Hostitel tuto místnost uzavřel.';
	@override String get relayFull => 'Zkuste to už teď, zkuste to ještě jednou.';
	@override String get unreachable => 'Nemohla jsem se dostat na hodinky Společně relay. zkontrolujte připojení.';
	@override String get rateLimited => 'Přesně mnoho pokusů. počkejte chvíli a zkuste znovu.';
	@override String get clientBlocked => 'Tato verze PlezyNG nemůže používat relay. aktualizovat aplikaci.';
	@override String get forbidden => 'To může udělat pouze hostitel.';
	@override String get notInRoom => 'Nejste v místnosti.';
	@override String get alreadyInRoom => 'Už jste v místnosti.';
	@override String get resumeFailed => 'Nemohla jsem se do místnosti dostat.';
	@override String get unsupported => 'Tohle relace nepodporuje.';
	@override String get generic => 'Něco se nehodilo, zkuste to znovu.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$cs extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Stáhnutí se zastaví, když opustíte aplikaci';
	@override String get bannerDegraded => 'Stáhnout základy může být omezené';
	@override String get bannerAction => 'detaily';
	@override String get sheetTitle => 'Základy stahování jsou blokovány';
	@override String get sheetTitleDegraded => 'Stáhnout základy může být omezené';
	@override String get sheetIntro => 'Android zabraňuje PlezyNG od stáhnout spolehlivě v pozadí.';
	@override String get sheetIntroDegraded => 'Vaše zařízení omezuje, kdy může PlezyNG stáhnout v pozadí.';
	@override String get reasonBackgroundRestricted => 'Použití pozadí PlezyNG je omezeno. nastavte jeho použití baterie nebo pozadí na "Nezákonné".';
	@override String get reasonStandbyRestricted => 'Android je umístěn PlezyNG v omezeném stavu. nastavte jeho použití baterie na "Neomezené".';
	@override String get reasonDownloadChannelBlocked => 'Oznámení o stažení jsou vypnuty, takže pokrok a kontroly nemusí být k dispozici.';
	@override String get reasonNotificationsDisabled => 'Na Android 13 nebo novější, jsou požadovány pro dlouhé pozadí stahování.';
	@override String get reasonDataSaver => 'Data Saver je na, který blokuje pozadí stahování na mobilní údaje. stahování by mělo stále probíhat na Wi-Fi.';
	@override String get reasonOemUnknown => 'Stáhnout se opakovaně zastavil, zatímco PlezyNG byl v pozadí. zkontrolujte nastavení použití baterie nebo pozadí PlezyNG.';
	@override String get openSettings => 'Otevřené nastavení';
	@override String get stillNotWorking => 'Speciální pomoc zařízení';
	@override String get stillNotWorkingDescription => 'Zobrazit kroky pro vaše zařízení, nebo odeslat záznam z Nastavení › Zobrazit záznamy, pokud problém pokračuje.';
	@override String get dialogTitle => 'Stáhnutí nemusí skončit';
	@override String get dialogDownloadAnyway => 'Stáhnout v každém případě';
	@override String get dialogFixFirst => 'Nejprve to opravte';
	@override String get statusTile => 'Zásadní downloads';
	@override String get statusOk => 'Dovoleno běhat v pozadí';
	@override String get statusBlocked => 'Blokované systémovými nastaveními';
	@override String get statusDegraded => 'Omezený systémovými nastaveními';
	@override String get statusUnknown => 'Zatím neprověřeno';
	@override String get settingsUnavailable => 'Nemohla jsem na tomto zařízení otevřít nastavení systému';
	@override String get linkUnavailable => 'Nemohla jsem otevřít dontkillmyapp.com na tomto zařízení';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$cs extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get library => 'Knihovna';
	@override String get collections => 'Kolekce';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$cs extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Začátek vzdáleného serveru.';
	@override String get hostAddress => 'Hostitelská adresa';
	@override String get connected => 'připojené';
	@override String get serverRunning => 'Remote server aktivní';
	@override String get serverStopped => 'Remote server se zastavil';
	@override String get serverRunningDescription => 'Mobilní zařízení na vaší síti se mohou připojit k této aplikaci';
	@override String get serverStoppedDescription => 'Začněte server, abyste mobilní zařízení mohli připojit';
	@override String get usePhoneToControl => 'Použijte mobilní zařízení k ovládání této aplikace';
	@override String get startServer => 'Start serveru';
	@override String get stopServer => 'Přestaňte server';
	@override String get minimize => 'Minimalizovat';
	@override String get manualAddressHint => 'Manuální kontaktní adresa:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$cs extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Přístroje PlezyNG se stejným účtem Plex se zde zobrazí';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Připojení...';
	@override String get searchingForDevices => 'Hledáme přístroje...';
	@override String get noDevicesFound => 'Na vaší síti nenajdete žádné zařízení';
	@override String get noDevicesHint => 'Otevřete PlezyNG na desktopu a použijte stejný Wi-Fi';
	@override String get availableDevices => 'Dostupné zařízení';
	@override String get manualConnection => 'Manuální připojení';
	@override String get cryptoInitFailed => 'Bezpečné připojení se nemůže začít. přihlaste se na číslo Plex nejprve.';
	@override String get validationHostRequired => 'Vložte prosím hostitelskou adresu';
	@override String get validationHostFormat => 'Formát musí být IP:port (např. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Použijte stejnou síť na obou zařízeních.';
	@override String get sessionNotFound => 'Není nalezeno zařízení. ujistěte se, že PlezyNG běží na hostiteli.';
	@override String get authFailed => 'Obě zařízení potřebují stejný účet Plex.';
	@override String failedToConnect({required Object error}) => 'Nepodařilo se připojit: ${error}';
	@override String get codeTitle => 'Pařížový kód';
	@override String get codeDescription => 'Vložte kód zobrazený v přístroji Companion Remote na hostitelském zařízení. Oba zařízení musí používat verzi, která podporuje bezpečné páření.';
	@override String get codeInvalid => 'Zadejte všechny 32 písmen a čísel z hostovacího kódu.';
	@override String get updateRequired => 'Obě zařízení aktualizujte na verzi, která podporuje bezpečné páření.';
	@override String get hostDescription => 'Zadejte tento kód jednou na každém dálkovém. Držte ho soukromým: poskytuje kontrolu nad tímto profilem.';
	@override String get resetCode => 'Zpět na Pairing Code';
	@override String get resetDescription => 'Odstranit všechny vzdialenosti a vytvořit nový kód. Každý vzdialenost bude muset znovu pářit.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$cs extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Chcete se odhlásit od vzdálené schůzky?';
	@override String get reconnecting => 'Připojení...';
	@override String attemptOf({required Object current}) => 'Zkouška ${current} z 5';
	@override String get retryNow => 'Zpět teď';
	@override String get tabRemote => 'vzdálenost';
	@override String get tabPlay => 'Přehrát';
	@override String get tabMore => 'Více';
	@override String get menu => 'Nabídka';
	@override String get tabNavigation => 'Tab Navigace';
	@override String get tabDiscover => 'Objevovat';
	@override String get tabLibraries => 'Knihovny';
	@override String get tabSearch => 'Vyhledávání';
	@override String get tabDownloads => 'Stažené soubory';
	@override String get tabSettings => 'Nastavení';
	@override String get previous => 'Předchozí';
	@override String get playPause => 'Hrát / Pause';
	@override String get next => 'Další';
	@override String get seekBack => 'Hledat zpět';
	@override String get stop => 'Zastavit';
	@override String get seekForward => 'Hledat FWD';
	@override String get volume => 'objem';
	@override String get volumeDown => 'Dolů';
	@override String get volumeUp => 'Nahoru';
	@override String get fullscreen => 'Celá obrazovka';
	@override String get subtitles => 'Titulky';
	@override String get audio => 'Zvuk';
	@override String get searchHint => 'Vyhledávání na desktopu...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$cs extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Není nalezeno rozhraní sítě';
	@override String get authenticationFailed => 'autentifikace selhala';
	@override String serverStartFailed({required Object error}) => 'Neschopnost spustit vzdálený server: ${error}';
	@override String commandFailed({required Object error}) => 'Nedokázal odeslat příkaz na dálku: ${error}';
	@override String get joinTimedOut => 'Čas na přistoupení k schůzce';
	@override String get failedToConnectAnyAddress => 'Nedokázal se připojit k jakékoli adrese';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Ztráta připojení po pokusech ${attempts}';
	@override String get connectionLost => 'Ztracené spojení';
}

// Path: services.names
class _Translations$services$names$cs extends Translations$services$names$en {
	_Translations$services$names$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$cs extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Připojení Simkl';
	@override String get subtitle => 'Simkl ukončuje podporu způsobu přihlášení, který toto připojení používá. Opětovné připojení otevře simkl.com, kde schválíte PlezyNG — PlezyNG nikdy neuvidí vaše heslo. Historie sledování zůstane na Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$cs extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktivovat PlezyNG na ${service}';
	@override String get instructions => 'Skenujte QR kód, nebo navštivte níže uvedenou adresu a zadejte tento kód:';
	@override String openToActivate({required Object service}) => 'Otevřete ${service} aktivovat';
	@override String get copyCode => 'Kopírování aktivačního kódu';
	@override String get waitingForAuthorization => 'Čekání na autorizaci...';
	@override String get codeCopied => 'Kód kopírovaný';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$cs extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Přihlaste se na číslo ${service}';
	@override String get body => 'Skenujte tento QR kód nebo otevřete URL na kterémkoli zařízení.';
	@override String openToSignIn({required Object service}) => 'Otevřete ${service} k přihlášení';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$cs extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Kopírování sign-in URL';
	@override String get urlCopied => 'URL kopírování';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$cs extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Knihovna Filter';
	@override String get subtitleAllSyncing => 'Synchronizace všech knihoven';
	@override String get subtitleNoneSyncing => 'Není synchronizace';
	@override String subtitleBlocked({required Object count}) => '${count} blokováno';
	@override String subtitleAllowed({required Object count}) => '${count} povoleno';
	@override String get mode => 'Filterový režim';
	@override String get modeBlacklist => 'Zakázat vše kromě výjimek';
	@override String get modeWhitelist => 'Povolit vše kromě výjimek';
	@override String get modeHintBlacklist => 'Synchronizujte každou knihovnu s výjimkou níže uvedených knihoven.';
	@override String get modeHintWhitelist => 'Synchronizujte pouze níže kontrolované knihovny.';
	@override String get libraries => 'Knihovny';
	@override String get noLibraries => 'Žádné knihovny k dispozici';
	@override String get modeDescription => 'Vyberte, zda jsou kontrolované knihovny zablokovány od synchronizace nebo jsou jedinými knihovnami, které synchronifikují.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$cs extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$cs._(TranslationsCs root) : this._root = root, super.internal(root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Synchronizujte sledované epizody a filmy s vaším účtem Trakt.';
	@override String get mal => 'Synchronizovat anime seznamy a sledovat pokrok s MyAnimeList.';
	@override String get anilist => 'Synchronizujte anime seznamy a sledujte pokrok s AniList.';
	@override String get simkl => 'Sync sledoval filmy, televizní pořady a anime s Simkl.';
	@override String get mdblist => 'Zobrazit hodnocení a seznamy MDBList v doporučeních a prozkoumat.';
}

/// The flat map containing all translations for locale <cs>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsCs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'aplikace ikona',
			'appIcon.defaultIcon' => 'Výchozí',
			'appIcon.current' => 'Aktuální ikona',
			'appIcon.locked' => 'Životní přístup požadovaný',
			'appIcon.lockedHint' => 'Začněte 7denní zkoušku nebo odemkněte PlezyNG po celý život, abyste použili alternativní ikony.',
			'appIcon.changeFailed' => 'Nemůžu změnit ikonu aplikace',
			'appIcon.launcherHint' => 'Nová ikona se objeví na domácím obrazovce, jakmile opustíte PlezyNG.',
			'appIcon.tvLauncherHint' => 'Nový banner se objeví, jakmile opustíte PlezyNG. Android TV může pokračovat v zobrazování starého, dokud se televizor neotevře.',
			'appIcon.names.midnight' => 'půlnoci',
			'appIcon.names.ember' => 'Člověk',
			'appIcon.names.paper' => 'Papír',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Linie',
			'appIcon.names.ocean' => 'Oceán',
			'appIcon.names.ultraviolet' => 'ultrafialová',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Západ slunce',
			'appIcon.names.gold' => 'Zlato',
			'appIcon.names.titanium' => 'Titanium',
			'appIcon.names.glass' => 'sklo',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Syntetické vlny',
			'appIcon.names.pixel' => 'Pixelová',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Stickerová',
			'appIcon.names.ticket' => 'Vstupenky',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Vrstvy',
			'appIcon.names.facet' => 'tvář',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Vyberte ikonu zobrazenou spuštěčem zařízení. Předpovědi ukazují, jak vypadá každá možnost.',
			'auth.signInWithPlex' => 'Přihlaste se na číslo Plex',
			'auth.showQRCode' => 'Zobrazit QR kód',
			'auth.authenticate' => 'autentické',
			'auth.authenticationTimeout' => 'Přihláška je hotová, zkuste prosím znovu.',
			'auth.scanQRToSignIn' => 'Skenujte tento QR kód pro přihlášení',
			'auth.waitingForAuth' => 'Čekání na autentizaci... Přihlaste se z vašeho prohlížeče.',
			'auth.useBrowser' => 'Použití prohlížeče',
			'auth.or' => 'nebo',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Připojte se k číslu ${product}',
			'auth.quickConnect' => 'Rychlé připojení',
			'auth.useQuickConnect' => 'Použít rychlé připojení',
			'auth.quickConnectInstructions' => 'Otevřete číslo Quick Connect v čísle Jellyfin a zadejte tento kód.',
			'auth.quickConnectWaiting' => 'Čekáme na schválení...',
			'auth.quickConnectCancel' => 'Zrušit',
			'auth.quickConnectExpired' => 'Platnost rychlého připojení vypršela. Zkuste to znovu.',
			'auth.localDataRecoveryRequired' => 'PlezyNG nedokázalo bezpečně obnovit místní přihlašovací údaje a čekající údaje o přehrávání. Přihlaste se znovu.',
			'auth.pinCheckRejected' => 'Ček PIN Plex byl zamítnut',
			'auth.connectToDirectPlex' => 'Připojte se k místnímu serveru Plex',
			'common.cancel' => 'Zrušit',
			'common.save' => 'Uložit',
			'common.close' => 'Zavřít',
			'common.closeMiniPlayer' => 'Blízký mini hráč',
			'common.closeWorkspaceWindow' => 'blízko okna',
			'common.returnToFullView' => 'Zpět na Full View',
			'common.manageMediaSessions' => 'Řízení mediálních zasedání',
			'common.hideMediaSessions' => 'ukrytí mediálních zasedání',
			'common.mediaSessions' => 'Mediální zasedání',
			'common.mediaSessionsHint' => 'Park skrývá okno, ale udržuje otevřené. Návrat ho otevírá v plném zobrazení; blízko končí.',
			'common.sessionInWorkspace' => 'v pracovním prostoru',
			'common.sessionParked' => 'Parkování',
			'common.sessionFullscreen' => 'Plný obrazovek',
			'common.switchToNextWindow' => 'Přepínání s příštím oknem',
			'common.moveWindow' => 'Pohybujte okno',
			'common.finishMovingWindow' => 'Konec pohybující se okna',
			'common.moveWindowHint' => 'Dlouho stiskněte a vytáhněte okno, abyste ho přesunuli.Tento ovládací prvek také umožňuje pohyb klíče šípky.',
			'common.movingWindowHelp' => 'Přejít na pohyb · Přejíždět klíče přizpůsobit · Zadejte zálohy · Únik zrušit',
			'common.resizeWindow' => 'Odstranit okno',
			'common.resizeWindowHint' => 'Vyzvedněte tuto rukojeti nebo použijte klíče strelu, aby se okno znovu rozmazalo.',
			'common.workspaceWindowHint' => 'Použijte pohybový ovládací prvek nebo dlouhý tlak a přejděte se.',
			'common.workspacePaneHint' => 'Vyberte tuto panelu, abyste ji zaměřili. Použijte její kontrolu na plný obrazovek k rozšíření.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Okno sezení: ${title}',
			'common.workspaceTitleHint' => 'Vyberte se zaměřit. Přejděte titulní řádek k pohybu; použijte tlačítko na plný obrazovku k rozšíření.',
			'common.moveToSessionTray' => 'Přejděte na Session Tray',
			'common.moveToSessionTrayHint' => 'Tato schůzka je k dispozici bez zobrazení okna.',
			'common.closeSessionHint' => 'Zavřete tento okno a ukončíte jeho zasedání.',
			'common.sideBySideLayout' => 'Přepínání na side-by-side layout',
			'common.floatingWindows' => 'Přepínání k plovoucímu oknu',
			'common.clear' => 'jasné',
			'common.reset' => 'Resetovat',
			'common.later' => 'Později',
			'common.submit' => 'Odeslat',
			'common.confirm' => 'Potvrzení',
			'common.retry' => 'Zkusit znovu',
			'common.logout' => 'Přihlaste se',
			'common.unknown' => 'Neznámý',
			'common.refresh' => 'Aktualizovat',
			'common.yes' => 'Ano',
			'common.no' => 'Ne',
			'common.delete' => 'Odstranit',
			'common.edit' => 'Upravit',
			'common.shuffle' => 'Náhodné přehrávání',
			'common.addTo' => 'Přidejte k...',
			'common.createNew' => 'Vytvořte nové',
			'common.connect' => 'Připojit',
			'common.disconnect' => 'Odpojit',
			'common.play' => 'Přehrát',
			'common.pause' => 'Pozastavit',
			'common.resume' => 'Pokračovat',
			'common.error' => 'Chyba',
			'common.search' => 'Vyhledávání',
			'common.home' => 'Domovská obrazovka',
			'common.back' => 'Zpět',
			'common.settings' => 'Nastavení',
			'common.mute' => 'Ztlumit',
			'common.ok' => 'OK',
			'common.off' => 'Vypnuto',
			'common.options' => 'Možnosti',
			'common.seasonNumber' => ({required Object number}) => 'Sezóna ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Článek ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Článek ${number}',
			'common.reconnect' => 'Připojení',
			'common.viewAll' => 'Zobrazit všechny',
			'common.checkingNetwork' => 'Kontrolní síť...',
			'common.loadingServers' => 'Nabíjecí servery...',
			'common.connectingToServers' => 'Připojení k serverům...',
			'common.startingOfflineMode' => 'Začínáme offline...',
			'common.loading' => 'Nabíjení...',
			'common.fullscreen' => 'Celá obrazovka',
			'common.exitFullscreen' => 'Výstup na plný obrazovek',
			'common.pressBackAgainToExit' => 'Stiskněte zpět na výstup',
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
			'common.notAvailable' => 'N / A',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'představení',
			'common.mediaKind.season' => 'Série',
			'common.mediaKind.episode' => 'Epizoda',
			'common.mediaKind.artist' => 'Interpret',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Stopa',
			'common.mediaKind.collection' => 'Kolekce',
			'common.mediaKind.playlist' => 'Seznam skladeb',
			'common.mediaKind.clip' => 'Filmový klip',
			'common.mediaKind.photo' => 'Fotka',
			'common.mediaKind.folder' => 'Složka',
			'screens.licenses' => 'Licence',
			'screens.switchProfile' => 'Přepínání profilu',
			'screens.subtitleStyling' => 'Styl titulků',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Záznamy',
			'update.available' => 'Aktualizace dostupná',
			'update.versionAvailable' => ({required Object version}) => 'K dispozici je verze ${version}',
			'update.currentVersion' => ({required Object version}) => 'Aktuální číslo: ${version}',
			'update.skipVersion' => 'Odstranit tuto verzi',
			'update.viewRelease' => 'Zobrazit Release',
			'update.latestVersion' => 'Jste na nejnovější verzi',
			'update.checkFailed' => 'Nedokázal se dohlížet na aktualizace',
			'settings.title' => 'Nastavení',
			'settings.supportDeveloper' => 'Podpora PlezyNG',
			'settings.supportDeveloperDescription' => 'Dotace na podporu rozvoje',
			'settings.lifetimeAccess' => 'PlezyNG Životní přístup',
			'settings.language' => 'Jazyk',
			'settings.theme' => 'Téma',
			'settings.appearance' => 'Vzhled',
			'settings.detailPage' => 'Detailní stránka',
			'settings.themeSongsEnabled' => 'Hrajte tématické písně',
			'settings.themeSongsEnabledDescription' => 'Zahrajte si dostupné tematické písně při prohlížení mediálních detailů.',
			'settings.themeSongVolume' => 'Píseň Volume',
			'settings.videoPlayback' => 'Videa Playback',
			'settings.videoPlaybackDescription' => 'Nastavení chování playback',
			'settings.advanced' => 'Pokročilé',
			'settings.episodePosterMode' => 'Styl plakátů',
			'settings.seriesPoster' => 'Seriál plakátů',
			'settings.seasonPoster' => 'Sezónní plakát',
			'settings.episodeThumbnail' => 'Thumbnailová',
			'settings.showHeroSectionDescription' => 'Zobrazit obsahový karusel na domácím obrazovce',
			'settings.secondsLabel' => 'sekundy',
			'settings.minutesLabel' => 'minuty',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'M',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Vložte hodnotu (${min}-${max})',
			'settings.systemTheme' => 'Systém',
			'settings.lightTheme' => 'Světlo',
			'settings.darkTheme' => 'Tmavé',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Člověk',
			'settings.glacierTheme' => 'ledovce',
			'settings.forestTheme' => 'lesy',
			'settings.plumTheme' => 'Švestková',
			'settings.paperTheme' => 'Papír',
			'settings.libraryDensity' => 'Densita knihovny',
			'settings.displayScale' => 'displejová skala',
			'settings.compact' => 'Kompaktní',
			'settings.comfortable' => 'Pohodlné',
			'settings.gridSpacing' => 'Síťový prostor',
			'settings.gridSpacingTight' => 'Tightová',
			'settings.gridSpacingNormal' => 'Normální',
			'settings.gridSpacingSpacious' => 'Vesmírné',
			'settings.tvCornerSpotlightBackdrop' => 'Spotlight záda',
			'settings.tvCornerSpotlightBackdropDescription' => 'Zobrazit umělecké dílo v pravém horním rohu namísto vyplnění obrazovky',
			'settings.viewMode' => 'Podívejte se na mód',
			'settings.gridView' => 'síť',
			'settings.listView' => 'Seznam',
			'settings.showHeroSection' => 'Zobrazit Hero sekce',
			'settings.showHomeBackdrop' => 'Domů Zobrazit Backdrop umělecké dílo',
			'settings.showHomeBackdropDescription' => 'Zobrazit velké umělecké dílo za zobrazenými domácími řádky',
			'settings.contentScreensaverEnabled' => 'Obsahový screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Zobrazit plnohodnotné umělecké dílo poté, co aplikace byla idle',
			'settings.contentScreensaverDelay' => 'Začněte screensaver po',
			'settings.contentScreensaverLibraries' => 'Screensaver knihovny',
			'settings.contentScreensaverLibrariesDescription' => 'Vyberte si, které knihovny poskytují obrazovku. Pokud nejsou vybrané, umělecké dílo ze všech knihoven se používá.',
			'settings.contentScreensaverAllLibraries' => 'Všechny knihovny',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} knihovny vybrané',
			'settings.contentScreensaverNoLibraries' => 'K dispozici nejsou žádné propojené knihovny.',
			'settings.contentScreensaverDismissHint' => 'Stiskněte tlačítko nebo stiskněte tlačítko k odvolání',
			'settings.newEpisodeNotifications' => 'Nová epizoda oznámení',
			'settings.newEpisodeNotificationsDescription' => 'Upozornění, když je k show přidána nová epizoda, jste zachyceni. kontroly, zatímco Plezy je otevřeno.',
			'settings.continueWatchingRowSize' => 'Pokračujte v sledování velikosti řádku',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} karty',
			'settings.rowSizeCompact' => 'Kompaktní',
			'settings.rowSizeStandard' => 'Standardní',
			'settings.rowSizeLarge' => 'Velký',
			'settings.continueWatchingAction' => 'Pokračovat v sledování akce',
			'settings.continueWatchingPlay' => 'Přehrát',
			'settings.continueWatchingDetails' => 'Otevřené detaily',
			'settings.episodeAction' => 'Akce epizody',
			'settings.episodePlay' => 'Přehrát',
			'settings.episodeDetails' => 'Otevřené detaily',
			'settings.useGlobalHubs' => 'Domácí layout',
			'settings.useGlobalHubsDescription' => 'Zobrazit jednotné domovské huby. jinak použijte doporučení knihovny.',
			'settings.showServerNameOnHubs' => 'Zobrazit jméno serveru na Hubs',
			'settings.showServerNameOnHubsDescription' => 'Vždy zobrazte jména serverů v titulcích hub.',
			'settings.groupLibrariesByServer' => 'Knihovny na serveru',
			'settings.groupLibrariesByServerDescription' => 'Knihovny skupiny pod každým mediálním serverem.',
			'settings.alwaysKeepSidebarOpen' => 'Udržujte vždy sidebar otevřený',
			'settings.alwaysKeepSidebarOpenDescription' => 'Stránka zůstává rozšířena a obsahová oblast se přizpůsobí',
			'settings.showUnwatchedCount' => 'Zobrazit nepozorované číslo',
			'settings.showUnwatchedCountDescription' => 'Zobrazit nepozorované epizody počítat na show a sezony',
			'settings.showWatchedIndicators' => 'Zobrazení sledovaných ukazatelů',
			'settings.showWatchedIndicatorsDescription' => 'Zobrazit kontrolní značku na sledovaných filmech, show a epizodech',
			'settings.showEpisodeNumberOnCards' => 'Zobrazit číslo epizody na mapách',
			'settings.showEpisodeNumberOnCardsDescription' => 'Sezóna a číslo epizody na karetách epizod',
			'settings.showSeasonPostersOnTabs' => 'Zobrazit sezónní plakáty na Tabs',
			'settings.showSeasonPostersOnTabsDescription' => 'Zobrazit každou sezónní plakát nad její tabulkou',
			'settings.tvFullCardLayout' => 'Plné televizní karty',
			'settings.tvFullCardLayoutDescription' => 'Použijte obraz-pouze TV karty s názvy herců přehnané',
			'settings.focusGlow' => 'Focus Světlo',
			'settings.focusGlowDescription' => 'Vytvořte měkký zář kolem soustředěné karty',
			'settings.visualEffects' => 'vizuální efekty',
			'settings.visualEffectsAuto' => 'Automaticky',
			'settings.visualEffectsAutoDescription' => 'Snižuje efekty automaticky na zařízení s nízkou výkonem',
			'settings.visualEffectsFull' => 'plnohodnotné',
			'settings.visualEffectsReduced' => 'Snížená',
			'settings.visualEffectsReducedDescription' => 'Méně animací a umělecké díly s nižší rozlišením',
			'settings.hideSpoilers' => 'Skryté spoilery pro nepozorované epizody',
			'settings.hideSpoilersDescription' => 'Blur miniatury a popisy nezaznamenaných epizod',
			'settings.playerBackend' => 'Hráč Backend',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardware dekódování',
			'settings.hardwareDecodingDescription' => 'Použijte hardware akcelerace, když je k dispozici',
			'settings.playbackBuffer' => 'Hrají buffer',
			'settings.playbackBufferAuto' => 'Doporučený ( doporučený )',
			'settings.playbackBufferLarge' => 'Velký',
			'settings.playbackBufferExtraLarge' => 'Extra velký',
			'settings.playbackBufferDescription' => 'Buffer více proti nestabilním připojením. Také omezený buffer velikostí.',
			'settings.streamBufferSize' => 'Buffer velikost',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Kolik videa je třeba přenést při přímém přehrávání. Transkódy se zastaví na vlastním buferu transkódů serveru. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Nahradí Playback Buffer při nastavení, zachycen na polovinu hranice paměti aplikace',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Podmínkou kvality',
			'settings.cellularQualityTitle' => 'Kvalita v celulárním systému',
			'settings.remoteQualityTitle' => 'Kvalita dálkového streamování',
			'settings.remoteQualitySameAsDefault' => 'Stejně jako standardní kvalita',
			'settings.cellularQualitySameAsDefault' => 'Stejně jako standardní kvalita',
			'settings.directPlayCoveredQuality' => 'Zahrajte si menší videa v originální kvalitě',
			'settings.directPlayCoveredQualityDescription' => 'Přímé přehrávání videí již v rámci limitu kvality namísto jejich překódování',
			'settings.videoCodecs' => 'Video kodeků',
			'settings.videoCodecsDescription' => 'Nepřehlédnuté kodeky jsou transkódovány serverem',
			'settings.videoCodecsAlwaysAccepted' => 'Vždy přijatý',
			'settings.musicQualityTitle' => 'Kvalita hudby',
			'settings.subtitleStyling' => 'Styl titulků',
			'settings.subtitleStylingDescription' => 'Přizpůsobte podtitul vzhledu',
			'settings.smallSkipDuration' => 'Malý skok trvání',
			'settings.largeSkipDuration' => 'Velký skok trvání',
			'settings.rewindOnResume' => 'Zpět na přehled',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekunda', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekundy', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} sekund', ), 
			'settings.defaultSleepTimer' => 'Default spánkový čas',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuty', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minut', ), 
			'settings.rememberTrackSelections' => 'Pamatujte si výběr tracků podle show/film',
			'settings.chooseTracksBeforePlayback' => 'Vyberte audio a subtituly před přehráváním',
			'settings.chooseTracksBeforePlaybackDescription' => 'Vyberte zdrojový zvuk a podtitulové stopy před zahájením každého videa.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Vždy ukázat titulky na tomto zařízení',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Když server nemá vybraný podtitul, vyberte stopu lokálně.Toto nikdy nezmění preference serveru.',
			'settings.autoDownloadPreferredSubtitle' => 'FETCH chybí preferované jazykové podtituly',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Vyberte dostupný podtitul ve vašem preferovaném jazyce lokálně. Pokud neexistuje, požádejte server, aby jeden získal, když je podporován.',
			'settings.rememberTrackSelectionsDescription' => 'Uložte si audio a subtitle volby show nebo film na tomto zařízení',
			'settings.rememberTrackSelectionsBackendRule' => 'Společně s Plex, Jellyfin a Emby; Plex a Jellyfin můžete také uložit výběry na serveru',
			'settings.followServerTrackSelections' => 'Použijte sériové výběry pro epizody serveru',
			'settings.followServerTrackSelectionsDescription' => 'Při změně epizody použijte audio a subtituly vybrané na serveru namísto přenosu nad aktuální volbou.',
			'settings.resumeMusicOnLaunch' => 'Pamatujte si na hudební sezení',
			'settings.resumeMusicOnLaunchDescription' => 'Otevřete poslední písničku, kde se zastavil, když aplikace spustí',
			'settings.showChapterMarkersOnTimeline' => 'Zobrazit značky kapitoly na vyhledávání bar',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segment vyhledávací bar na hranicích kapitoly',
			'settings.specialsOrdering' => 'Speciální v epizodním pořadí',
			'settings.specialsOrderingDescription' => 'Kde se speciály hrají v pořadí show',
			'settings.specialsOrderingServer' => 'Sledujte objednávku serveru',
			'settings.specialsOrderingAirDate' => 'Výstupy podle dat vzduchu',
			'settings.specialsOrderingLast' => 'Po pravidelných sezónách',
			'settings.clickVideoTogglesPlayback' => 'Klikněte na video, abyste si zahrali / přestávali',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klikněte na video a přehrávejte / přestávka namísto zobrazení kontrol.',
			'settings.videoPlayerControls' => 'Video Player ovládání',
			'settings.keyboardShortcuts' => 'Klávesnice Shortcuts',
			'settings.keyboardShortcutsDescription' => 'Přizpůsobte klávesové zkratky',
			'settings.videoPlayerNavigation' => 'Navigace přehrávače videa',
			'settings.videoPlayerNavigationDescription' => 'Použijte klíče pro navigaci na videohrávači',
			'settings.watchTogetherRelay' => 'Podívejte se na relace',
			'settings.watchTogetherRelayDescription' => 'Public Open Watch Party přenášejí, pokud si neustanovíte vlastní',
			'settings.watchTogetherRelayHint' => 'https://my-relay.example.com',
			'settings.watchTogetherRelayInvalid' => 'Zadejte platnou základní adresu URL přenosového serveru s HTTP nebo HTTPS.',
			'settings.crashReporting' => 'Zprávy o katastrofě',
			'settings.crashReportingDescription' => 'Odeslat zprávy o havárii, které pomohou zlepšit aplikaci',
			'settings.debugLogging' => 'Debug Logování',
			'settings.debugLoggingDescription' => 'Umožňuje detailní přihlašování pro řešení problémů',
			'settings.viewLogs' => 'Zobrazit logy',
			'settings.viewLogsDescription' => 'Zobrazit logy aplikace',
			'settings.clearImageCache' => 'Čistý obraz Cache',
			'settings.clearImageCacheDescription' => 'Čistě zakryté umělecké dílo a miniatury. snímky mohou být přenášeny pomaleji, dokud nebudou znovu staženy.',
			'settings.clearImageCacheSuccess' => 'Image cache úspěšně vymazáno',
			'settings.resetSettings' => 'Reset nastavení',
			'settings.resetSettingsDescription' => 'Obnovte výchozí nastavení. to nemůže být bez.',
			'settings.resetSettingsSuccess' => 'Nastavení se úspěšně obnoví',
			'settings.backup' => 'zálohování',
			'settings.exportSettings' => 'Vývozní nastavení',
			'settings.exportSettingsDescription' => 'Uložte své preference do souboru',
			'settings.exportSettingsSuccess' => 'Nastavení exportované',
			'settings.importSettings' => 'Importujte nastavení',
			'settings.importSettingsDescription' => 'Obnovte preference z souboru',
			'settings.importSettingsConfirm' => 'To nahradí vaše aktuální nastavení. pokračovat?',
			'settings.importSettingsSuccess' => 'Nastavení importované',
			'settings.importSettingsInvalidFile' => 'Tento soubor není platný PlezyNG nastavení export',
			'settings.importSettingsNoUser' => 'Přihlaste se před dovozem',
			'settings.cloudBackup' => 'Cloud záloha',
			'settings.cloudBackupDescription' => 'Zálohování přenosných nastavení na koncové místo WebDAV přes HTTPS.Serverové připojení a autentifikace zůstanou na tomto zařízení.',
			'settings.cloudBackupUrl' => 'WebDAV JSON soubor URL',
			'settings.cloudBackupUsername' => 'Uživatelské jméno',
			'settings.cloudBackupPassword' => 'Heslo',
			'settings.cloudBackupSaved' => 'Cloud backup destinace zachráněna',
			'settings.cloudBackupNow' => 'Zpět nyní',
			'settings.cloudBackupComplete' => 'Nastavení zálohování nahráno',
			'settings.cloudBackupRestore' => 'Obnovit zálohu',
			'settings.cloudBackupRestoreConfirm' => 'To nahradí odpovídající přenosné nastavení na tomto zařízení.',
			'settings.cloudBackupRestored' => 'Nastavení obnovené z cloud backup',
			'settings.shortcutsReset' => 'Zpět na defaulty',
			'settings.resetShortcutsConfirm' => 'To nahradí vaše přizpůsobené zkratky s defaulty.',
			'settings.about' => 'o',
			'settings.aboutDescription' => 'Informace o aplikacích a licencích',
			'settings.updates' => 'Aktualizace',
			'settings.updateAvailable' => 'Aktualizace dostupná',
			'settings.checkForUpdates' => 'Podívejte se na aktualizace',
			'settings.autoCheckUpdatesOnStartup' => 'Automaticky zkontrolujte aktualizace na startupu',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Oznámit, kdy je aktualizace k dispozici při spuštění',
			'settings.validationErrorEnterNumber' => 'Vložte prosím platné číslo',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Musí být mezi ${min} a ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Zkratka již přidělená ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Aktualizace krátké zkratky na ${action}',
			'settings.saveFailed' => 'Změny se nedohodnou, zkuste to znovu.',
			'settings.autoPlayAndSkip' => 'Auto-Play a Skip',
			'settings.autoPlayNextEpisode' => 'Auto-Play Další epizoda',
			'settings.autoPlayNextEpisodeDescription' => 'Následující epizoda začíná automaticky, když jeden skončí',
			'settings.shuffleStartsFromBeginning' => 'Shuffle začíná na začátku',
			'settings.shuffleStartsFromBeginningDescription' => 'Začněte každou epizodu na začátku, když se střídají místo opakování',
			'settings.plexCinemaPreRoll' => 'Využijte server kino intros',
			'settings.plexCinemaPreRollDescription' => 'Hrajte konfigurované Plex předvolby nebo Jellyfin a Emby vstupy před zahájením filmu.',
			'settings.playNextCountdown' => 'Hrajte další účet',
			'settings.playNextCountdownImmediate' => 'Hrajte okamžitě',
			'settings.skipIntroMode' => 'Skříň vstupuje',
			'settings.skipIntroModeOffDescription' => 'Hrát intros normálně bez skákacího tlačítka',
			'settings.skipIntroModeButtonDescription' => 'Zobrazit tlačítko skip, když začíná intro',
			'settings.skipIntroModeAutoDescription' => 'Vstupy automaticky odkládají po delší době',
			'settings.skipCreditsMode' => 'Skok úvěrů',
			'settings.skipCreditsModeOffDescription' => 'Hrajte kredity normálně bez tlačítka na skok',
			'settings.skipCreditsModeButtonDescription' => 'Zobrazit tlačítko skip, když začnou kredity',
			'settings.skipCreditsModeAutoDescription' => 'Přesun kreditů automaticky a hrát další epizodu',
			'settings.skipAdsMode' => 'Skřípání Ads',
			'settings.skipAdsModeOffDescription' => 'Objevte zaznamenané reklamy normálně bez tlačítka',
			'settings.skipAdsModeButtonDescription' => 'Zobrazit tlačítko skip, když Plex detekuje reklamu',
			'settings.skipAdsModeAutoDescription' => 'Odstranění zaznamenaných reklam automaticky po zpoždění níže',
			'settings.musicPlayback' => 'Hudební playback',
			'settings.musicSweetFades' => 'Sladké fáty',
			'settings.musicSweetFadesDescription' => 'Hudba se rozkládá na okraji track, když má číslo Plex daty o hlasitosti.',
			'settings.skipMarkerModeOff' => 'Vypnuto',
			'settings.skipMarkerModeButton' => 'Ukázat tlačítko',
			'settings.skipMarkerModeAuto' => 'automatické',
			'settings.forceSkipMarkerFallback' => 'Výsledky Force Fallback Markers',
			'settings.forceSkipMarkerFallbackDescription' => 'Použijte šablony názvu kapitoly i tehdy, když má značka Plex',
			'settings.theIntroDbFallback' => 'Použijte TheIntroDB jako intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Použijte časování komunity pouze tehdy, když server nemá intro marker.',
			'settings.autoSkipDelay' => 'Auto Skip zpoždění',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Počkejte ${seconds} sekund před automatickým skokem',
			'settings.introPattern' => 'Intro značkové vzorce',
			'settings.introPatternDescription' => 'Regex pattern, aby odpovídal intro markers v kapitolách',
			'settings.creditsPattern' => 'Kreditní značka Pattern',
			'settings.creditsPatternDescription' => 'Regex vzor se hodí k úvěrovým markerům v kapitolách',
			'settings.prerolls' => 'Prerolly',
			'settings.playPrerollsBeforeMovies' => 'Hrajte před filmem',
			'settings.playPrerollsBeforeMoviesDescription' => 'Přehrávejte náhodný klip z vašeho výběru níže před každým filmem.',
			'settings.prerollLibrary' => 'Prerollová knihovna',
			'settings.prerollLibraryNotSet' => 'Není nastaven',
			'settings.prerollLibraryNoneFound' => 'Žádné knihovny nejsou na vašich serverech nalezeny.',
			'settings.prerollSelection' => 'vybrané předměty',
			'settings.prerollSelectionPickLibraryFirst' => 'Nejprve si vybírejte knihovnu',
			'settings.prerollSelectionNoneSelected' => 'Žádné předvolby vybrané',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} vybráno',
			'settings.prerollItemPicker' => 'Výběr prerollů',
			'settings.prerollItemPickerLoadFailed' => 'Nemohla jsem si z této knihovny přenášet žádné položky.',
			'settings.invalidRegex' => 'Neplatné pravidelné vyjádření',
			'settings.regex' => 'Pravidelné vyjádření',
			'settings.downloads' => 'Stažené soubory',
			'settings.downloadLocationDescription' => 'Vyberte si místo, kde si stáhnout obsah',
			'settings.downloadLocationDefault' => 'Podmínkou (App Storage)',
			'settings.downloadLocationCustom' => 'Custom umístění',
			'settings.selectFolder' => 'Vyberte složku',
			'settings.resetToDefault' => 'Zpět na výchozí',
			'settings.currentPath' => ({required Object path}) => 'Aktuální číslo: ${path}',
			'settings.downloadLocationChanged' => 'Stáhnout změna umístění',
			'settings.downloadLocationReset' => 'Stáhnout lokalitu reset na default',
			'settings.downloadLocationInvalid' => 'Vybraná složka není psatelná',
			'settings.downloadLocationPickerUnavailable' => 'Výběr složek není k dispozici na tomto zařízení',
			'settings.downloadOnWifiOnly' => 'Stáhnout pouze na Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Vyhněte se stahování, když na mobilních údajích',
			'settings.autoRemoveWatchedDownloads' => 'Auto-remove sledované stahování',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Vymazat sledované stahování automaticky',
			'settings.autoDownloadContinueWatching' => 'Auto-Download pokračovat v sledování',
			'settings.autoDownloadContinueWatchingDescription' => 'Udržujte položky na vašem Pokračovat sledování shell stáhnout, a odstranit je, jakmile opustí shell',
			'settings.downloadQuality' => 'Download Kvalita',
			'settings.downloadQualityDescription' => 'Plex připravuje převedenou kopii ve svém stažení. Jellyfin a Emby transkód při stažení souboru; přerušené převody mohou být nutné restartovat.',
			'settings.askDownloadQualityEachTime' => 'Vybírejte kvalitu pro každý download',
			'settings.askDownloadQualityEachTimeDescription' => 'Zobrazit kvalitní piker před zkoušením každého videa',
			'settings.cellularDownloadBlocked' => 'Stáhnout jsou blokovány na mobilní. použijte Wi-Fi nebo změňte nastavení.',
			'settings.maxVolume' => 'Maximální hlasitost',
			'settings.maxVolumeDescription' => 'Povolit zesílení nad 100 % u médií s tichým zvukem',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Bohatá přítomnost',
			'settings.discordRichPresenceDescription' => 'Zobrazit, co se díváte na Discord',
			'settings.services' => 'Služby',
			'settings.servicesDescription' => 'Připojte se Trakt, MyAnimeList, Seerr a další',
			'settings.manageLibrariesDescription' => 'Přehrávat a skrývat knihovny',
			'settings.companionRemoteServer' => 'Společnost Remote Server',
			'settings.companionRemoteServerDescription' => 'Umožňujte mobilním zařízením v síti ovládat tuto aplikaci',
			'settings.companionRemoteServerStartFailed' => 'Nemohla spustit server',
			'settings.companionRemoteServerStopFailed' => 'Nemohla jsem zastavit server',
			'settings.autoPip' => 'Auto Picture v obraze',
			'settings.autoPipDescription' => 'Automaticky zadejte obrázek v obrazu, když opustíte aplikaci během přehrávání',
			'settings.matchContentFrameRate' => 'Match Content Frame Rate - míra obsahu',
			'settings.matchContentFrameRateDescription' => 'Match displej upřesňovací sazba na video obsahu',
			'settings.matchContentResolution' => 'Rozhodnutí Match Content',
			'settings.matchContentResolutionDescription' => 'Přepněte displej na původní rozlišení videa, aby se váš televizor vyrovnal s upscaling. Menu a subtitles jsou také upscaled během přehrávání',
			'settings.matchRefreshRate' => 'Závodní úroková sazba',
			'settings.matchRefreshRateDescription' => 'Match displej úroveň osvěžení v plném obrazovce',
			'settings.matchDynamicRange' => 'Dynamický rozsah zápasu',
			'settings.matchDynamicRangeDescription' => 'Přepněte HDR na obsah HDR a pak zpět na SDR',
			'settings.displaySwitchDelay' => 'Zpoždění displeje Switch',
			'settings.tunneledPlayback' => 'tunelové playback',
			'settings.tunneledPlaybackDescription' => 'Použijte video tunelování. vypněte, pokud HDR playback zobrazuje černé video nebo pohyblivé stuttery.',
			'settings.audioPassthrough' => 'zvuková pasáž',
			'settings.audioPassthroughDescription' => 'Odeslat Dolby/DTS audio do přijímače nebo televize bez re-kódování, zachování okolního zvuku.',
			'settings.audioPassthroughDescriptionApple' => 'Použijte nativní dekodér Dolby Apple pro Dolby Digital Plus, včetně Atmos. DTS a TrueHD stále hrají jako multichannel PCM.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Použijte původní dekodér Dolby Apple pro Dolby Digital Plus, včetně Atmos. Na iOS, iPadOS a tvOS 26 nebo později, TrueHD Atmos a DTS:X přehrávat jako prostorový audio. Ostatní DTS a TrueHD stopy přehrávat jako multichannel PCM.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Zastavte, zatímco normalizace hluku je na',
			'settings.audioChannelLimit' => 'Počet kanálů zvuku',
			'settings.audioChannelLimitDescription' => 'Mícháme dekódovaný zvuk pro reproduktory, sluchátka nebo nastavení HDMI, které nemohou přehrávat každý kanál.',
			'settings.audioChannelLimitOriginal' => 'originál',
			'settings.audioChannelLimitOriginalDescription' => 'Zahrajte si každý kanál na trati',
			'settings.audioChannelLimitSurround51' => 'až do 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Mícháme 7.1 dolů na 5.1 pro televizory a přijímače, které užívají pouze 5.1 PCM.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Smícháme do dvou kanálů pro stereo reproduktory nebo sluchátka.',
			'settings.downmixCenterBoost' => 'Články Channel Boost',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Zvýšení (dB)',
			'settings.downmixCenterBoostShort' => 'DB',
			'settings.audioDownmixNormalize' => 'Normalizace objemu na Downmix',
			'settings.audioDownmixNormalizeDescription' => 'Snižte směs, aby se zabránilo klíčení. vypněte, abyste zachovali původní objem (možná narušení hlasitých scén).',
			'settings.dvConversionMode' => 'Dolby Vision Převod',
			'settings.dvConversionModeDescription' => 'Vyberte si, jak jsou zpracovávány soubory profilu Dolby Vision.',
			'settings.dvConversionAuto' => 'Automaticky',
			'settings.dvConversionNative' => 'Nativní / zdravotně postižené',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Použijte detekci kapacity zařízení a normální chování zpětného pádu',
			'settings.dvConversionNativeDescription' => 'Force native DV7 a potlačení DV konverze zpět',
			'settings.dvConversionDv81Description' => 'Konverze RPU na profil Dolby Vision 8.1',
			'settings.dvConversionHevcStripDescription' => 'Strip Dolby Vision RPU/EL vrstvy a současná rovina HEVC',
			'settings.experimentalDolbyVision' => 'Experimentální Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Při příštím přehrávání použít experimentální renderer FEL. Vyžaduje samostatné sestavení enginu.',
			'settings.dvExperimentUnavailableDescription' => 'Tento experiment je zatím dostupný pouze na Linuxu.',
			'settings.dvCompatibilityFallback' => 'Záložní režim kompatibility',
			'settings.dvCompatibilityFallbackDescription' => 'Pokud experiment nelze spustit, použít standardní renderer. Data FEL mohou být ztracena.',
			'settings.dvExperimentDiagnostics' => 'Protokolování videoexperimentu',
			'settings.dvExperimentDiagnosticsDescription' => 'Při příštím přehrávání zapnout podrobné protokoly přehrávače.',
			'settings.disableDolbyVision' => 'Zrušení Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Přehrávejte soubor HDR10 nebo vrstvu HLG namísto Dolby Vision, když má jeden',
			'settings.hdrSdrConversion' => 'HDR na SDR konverze',
			'settings.hdrSdrConversionDescription' => 'Vyberte, co konvertuje HDR video, když displej nedokáže zobrazit HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automaticky',
			'settings.hdrSdrConversionAutoDescription' => 'Přístroj na Android 9 a novější, hráč na starších verzích',
			'settings.hdrSdrConversionDevice' => 'Zařízení',
			'settings.hdrSdrConversionDeviceDescription' => 'Video hardware vašeho zařízení to konvertuje. nejrychlejší, ale barvy závisí na zařízení',
			'settings.hdrSdrConversionPlayer' => 'Přehrávač',
			'settings.hdrSdrConversionPlayerDescription' => 'Konvertuje ji hráč. konzistentní barvy, ale 4K může stoupat na nízké televizní krabičky',
			'settings.deinterlace' => 'Deinterlacingová',
			'settings.deinterlaceDescription' => 'Odstranění smíšených artefaktů z interlaceného videa (mpv hráčů pouze)',
			'settings.deinterlaceOff' => 'Vypnuto',
			'settings.deinterlaceOffDescription' => 'Zobrazit interlinkované video, jak je dekódován',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Pro video snímky pro TV, jako jsou sporty, novinky a koncerty',
			'settings.deinterlaceFilm' => 'Filmy',
			'settings.deinterlaceFilmDescription' => 'Obnovte původní rámy filmu a animace telecined na 29.97 fps, běžné na NTSC DVD. Video shromažďování pro TV stutters.',
			'settings.requireProfileSelectionOnOpen' => 'Vyžádejte si profil v aplikaci Open',
			'settings.requireProfileSelectionOnOpenDescription' => 'Zobrazit výběr profilu pokaždé, když je aplikace otevřena',
			'settings.forceTvMode' => 'TV režim síly',
			'settings.forceTvModeDescription' => 'Pro zařízení, která neexistuje automaticky detekce, vyžaduje restart.',
			'settings.startInFullscreen' => 'Začněte na plném obrazovce',
			'settings.startInFullscreenDescription' => 'Otevřete PlezyNG v režimu plného obrazovky při spuštění',
			'settings.exitFullscreenOnPlayerClose' => 'Výstup na plný obrazovek na hráči uzavřené',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Automaticky vyjde na plný obrazovek při zavírání videa',
			'settings.autoHidePerformanceOverlay' => 'Auto-Hide Výkon Overlay',
			'settings.autoHidePerformanceOverlayDescription' => 'Zkuste překonat výkon pomocí playback kontroly',
			'settings.showNavBarLabels' => 'Zobrazení Navigace Bar Labels',
			'settings.showNavBarLabelsDescription' => 'Zobrazit textové štítky pod ikony navigační řádky',
			'settings.startupSection' => 'Startup sekce',
			'settings.preferredServer' => 'Oblíbený server',
			'settings.preferredServerDescription' => 'Prioritizujte výsledky tohoto serveru a zároveň udržujte všechny připojené servery k dispozici.',
			'settings.preferredServerAutomatic' => 'automatické',
			'settings.showExploreTab' => 'Zobrazit tabulku',
			'settings.showExploreTabDescription' => 'Zobrazit kartu Explore s obsahem z Plex Objevovat a připojené sledovatele',
			'settings.hideEmptyLibraries' => 'Skryjte prázdné knihovny',
			'settings.hideEmptyLibrariesDescription' => 'Odstranit knihovny s počtem položek, které jsou hláseny serverem, od nuly z navigace.',
			'settings.liveTvDefaultFavorites' => 'Vstup do oblíbených kanálů',
			'settings.liveTvDefaultFavoritesDescription' => 'Zobrazit pouze oblíbené kanály při otevírání Live TV',
			'settings.general' => 'Obecné',
			'settings.generalDescription' => 'Jazyk, startup a chování okna',
			'settings.languageAndRegion' => 'Jazyk a region',
			'settings.startup' => 'Startupy',
			'settings.display' => 'Zobrazení',
			'settings.libraryAndCards' => 'Knihovna a mapy',
			'settings.homeScreen' => 'Domácí obrazovka',
			'settings.navigation' => 'Navigace',
			'settings.window' => 'okno',
			'settings.liveTv' => 'Živé vysílání',
			'settings.player' => 'Přehrávač',
			'settings.videoAndDisplay' => 'Video a displej',
			'settings.audio' => 'Zvuk',
			'settings.quality' => 'Kvalita',
			'settings.subtitles' => 'Titulky',
			'settings.seekAndTiming' => 'Vyhledávání a časování',
			'settings.behavior' => 'chování',
			'settings.gestures' => 'gesty',
			'settings.gestureBrightnessSwipe' => 'Svítí světlo',
			'settings.gestureBrightnessSwipeDescription' => 'Přesunout nahoru nebo dolů na levém okraji, abyste upravili jasnost',
			'settings.gestureVolumeSwipe' => 'Volume přepínání',
			'settings.gestureVolumeSwipeDescription' => 'Přesunout nahoru nebo dolů na pravém okraji, abyste upravili objem',
			'settings.gesturePinchToZoom' => 'Zpět na Zoom',
			'settings.gesturePinchToZoomDescription' => 'Připojte se k videu a zoomujte se do nebo ven',
			'settings.gestureSeekSwipe' => 'Vyhledat Swipe',
			'settings.gestureSeekSwipeDescription' => 'Přesun levé nebo pravé kamkoliv na videu hledat; uvolnit na skok',
			'settings.rememberBrightnessLevel' => 'Pamatujte si hladinu jasnosti',
			'settings.rememberBrightnessLevelDescription' => 'Zahájení playback na jasu nastaveném posledním svipem',
			'settings.controls' => 'Ovládání',
			'settings.rememberPlayerChanges' => 'Pamatujte si změny hráčů',
			'settings.rememberPlayerChangesDescription' => 'Kde se změna provedená během přehrávání ukládá a znovu aplikuje',
			'settings.scopePlaybackSpeed' => 'Rychlost přehrávání',
			'settings.scopeShaderPreset' => 'Shader představení',
			'settings.scopeAspectRatio' => 'Poměr stran',
			'settings.scopeSyncOffsets' => 'Audio a subtitle synchronizace',
			'settings.playerScopeOff' => 'Nenechte se zachránit',
			'settings.playerScopeGlobal' => 'Všude všude',
			'settings.playerScopeLibrary' => 'Pro knihovnu',
			'settings.playerScopeTitle' => 'Pro show nebo film',
			'settings.exportDialogTitle' => 'Vývoz PlezyNG nastavení',
			'settings.followSystem' => 'Podle systému',
			'settings.followAppLanguage' => 'Podle jazyka rozhraní',
			'settings.regionFormat' => 'Místní formáty',
			'settings.regionFormatDescription' => 'Zvolte způsob zobrazení dat, čísel a měrných jednotek.',
			'settings.metadataLanguage' => 'Jazyk metadat',
			'settings.metadataLanguageDescription' => 'Upřednostňovaný jazyk názvů a popisů, pokud jej server podporuje. Předvolby zvuku a titulků se nastavují samostatně.',
			'settings.enterFullscreenOnPlaybackStart' => 'Přihlaste se k plné obrazovce, když začíná playback',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Otevřete desktopové video na plném obrazovce, když začíná playback',
			'settings.extendVideoIntoDisplayCutout' => 'Rozšířte video do displeje Cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Umožňujte, aby video s plnou obrazovkou používalo fotoaparát na telefonech Android',
			'settings.languageDescription' => 'Vyberte jazyk používaný pro kontroly a zprávy PlezyNG.Sledujte systém sleduje jazyk vašeho zařízení.',
			'settings.themeDescription' => 'Vyberte barvy a kontrast používané v celé aplikaci.',
			'settings.libraryDensityDescription' => 'Změňte, kolik knihovních karet se hodí v každém řádku.',
			'settings.displayScaleDescription' => 'Přehrávejte rozhraní na tomto autovém displeji, aniž byste změnili velikost textu v celé zařízení.',
			'settings.themeSongVolumeDescription' => 'Nastavení objemu tematických písní ve vztahu k jiným zvukům.',
			'settings.viewModeDescription' => 'Vyberte, zda se knižní položky zobrazují jako plakáty v síti nebo jako kompaktní seznam.',
			'settings.gridViewDescription' => 'Nastavení knihovních položek v řádcích a sloupcích plakátů.',
			'settings.listViewDescription' => 'Zobrazit položky knihovny v vertikálním seznamu s více textem na položku.',
			'settings.gridSpacingDescription' => 'Nastavte rozdíl mezi plakáty v knihovních sítích.',
			'settings.gridSpacingTightDescription' => 'Připravte více plakátů přes obrazovku s menšími mezery.',
			'settings.gridSpacingNormalDescription' => 'Použijte standardní mezeru mezi plakáty.',
			'settings.gridSpacingSpaciousDescription' => 'Přidejte větší mezery mezi plakáty pro více oddělení.',
			'settings.episodePosterModeDescription' => 'Vyberte, které umělecké dílo se objeví na karetách epizod.',
			'settings.seriesPosterDescription' => 'Použijte seriálový plakát pro každou epizodu.',
			'settings.seasonPosterDescription' => 'Použijte sezónní plakát pro každou epizodu, když je k dispozici.',
			'settings.episodeThumbnailDescription' => 'Použijte rám z epizody, když je k dispozici.',
			'settings.continueWatchingActionDescription' => 'Vyberte si, co se stane, když aktivujete kartu Pokračující sledování.',
			'settings.continueWatchingPlayDescription' => 'Začněte film nebo epizodu okamžitě.',
			'settings.continueWatchingDetailsDescription' => 'Nejprve otevřete titulní stránku, abyste si mohli prohlédnout detaily a vybrat akci.',
			'settings.episodeActionDescription' => 'Vyberte si, co se stane, když aktivujete epizodovou kartu.',
			'settings.episodePlayDescription' => 'Hra začíná okamžitě.',
			'settings.episodeDetailsDescription' => 'Otevřete stránku epizody před playbackem.',
			'settings.contentScreensaverDelayDescription' => 'Vyberte si, jak dlouho PlezyNG čeká bez vstupu před zobrazením uměleckého díla.',
			'settings.continueWatchingRowSizeDescription' => 'Vyberte si, jak velké jsou karty v řádku Pokračující sledování.',
			'settings.rowSizeCompactDescription' => 'Zobrazit menší karty, takže více položek se hodí po řádku.',
			'settings.rowSizeStandardDescription' => 'Použijte standardní velikost karty.',
			'settings.rowSizeLargeDescription' => 'Zobrazit větší karty s více uměleckých detailů.',
			'settings.visualEffectsDescription' => 'Vyberte rozpočet animace a uměleckých efektů pro toto zařízení.',
			'settings.visualEffectsFullDescription' => 'Použijte plné animace a umělecké efekty na každém zařízení.',
			'settings.startupSectionDescription' => 'Vyberte, která sekce se otevře při zahájení PlezyNG.',
			'settings.startupSectionOptions.discover' => 'Otevřete doporučení a položky z propojených zdrojů objevování.',
			'settings.startupSectionOptions.libraries' => 'Otevřete své propojené mediální knihovny.',
			'settings.startupSectionOptions.liveTv' => 'Otevřete Live TV, když ji server poskytuje; jinak startup padne zpět na domov.',
			'settings.startupSectionOptions.search' => 'Vyhledávání otevřených médií.',
			'settings.smallSkipDurationDescription' => 'Nastavte vzdálenost pohybující se krátkou zpětnou a dopředu hledat kontroly.',
			'settings.largeSkipDurationDescription' => 'Nastavte vzdálenost pohybující se dlouhým zpětným a dopředu hledat kontroly.',
			'settings.rewindOnResumeDescription' => 'Převod playback zpět tímto množstvím při opětovném natáčení videa.',
			'settings.defaultSleepTimerDescription' => 'Nastavení počáteční doby použité při zahájení času spánku.',
			'settings.playNextCountdownDescription' => 'Čekejte to dlouho, než začnete další epizodu. nastavit na 0 začít okamžitě.',
			'settings.autoSkipDelaySettingDescription' => 'Použije se, když je intro, kredit nebo reklama nastaven k automatické přerušení.',
			'settings.downmixCenterBoostDescription' => 'Zvýšte dialog v centrálním kanálu, když je surround audio smícháno dolů na stereo.',
			'settings.displaySwitchDelayDescription' => 'Počkejte před změnou režimu zobrazení, aby televizor nebo přijímač mohl dokončit svůj předchozí přepín.',
			'settings.playerBackendDescription' => 'Vyberte si, který přehrávač dekóduje a renderuje video na tomto zařízení.',
			'settings.exoPlayerDescription' => 'Použijte nativní přehrávač založený na Media3 a podporované hardwarové trasy systému Android.',
			'settings.mpvDescription' => 'Použijte mpv, který vystavuje další playback, subtitle a video zpracování ovládacích prvků.',
			'settings.scopeOffDescription' => 'Udržujte změny pouze pro aktuální playback.',
			'settings.scopeGlobalDescription' => 'Opět použijte stejnou hodnotu pro každou knihovnu a titul.',
			'settings.scopeLibraryDescription' => 'Pamatujte si na samostatnou hodnotu pro každou knihovnu.',
			'settings.scopeTitleDescription' => 'Pamatujte si samostatnou hodnotu pro každou představu nebo film.',
			'settings.specialsOrderingServerDescription' => 'Udržujte objednávku epizody poskytovanou mediálním serverem.',
			'settings.specialsOrderingAirDateDescription' => 'Vložte speciály mezi pravidelné epizody podle jejich datum vzduchu.',
			'settings.specialsOrderingLastDescription' => 'Každá speciální položka po pravidelných sezónách.',
			'settings.skipIntroModeDescription' => 'Vyberte, zda intro markery hrají normálně, zobrazí tlačítko skip nebo automaticky skip.',
			'settings.skipCreditsModeDescription' => 'Vyberte, zda se kredity běžně hrají, zobrazí tlačítko skok nebo automaticky skok.',
			'settings.skipAdsModeDescription' => 'Vyberte, zda zjištěné reklamy hrají normálně, zobrazí tlačítko skip nebo automaticky skip.',
			'settings.playbackBufferAutoDescription' => 'Nechte aktivního hráče zvolit jeho normální velikost bufetu.',
			'settings.playbackBufferLargeDescription' => 'Udržujte více médií připravených před přehráváním; to využívá více paměti.',
			'settings.playbackBufferExtraLargeDescription' => 'Udržujte největší čtenářský buffer, který využívá nejvíce paměti.',
			'settings.defaultQualityDescription' => 'Nastavení výchozí video rozlišení a bitrate strop pro toky, které server transkóduje.',
			'settings.cellularQualityDescription' => 'Override Standardní kvalita, když zařízení používá pouze buněčné připojení.',
			'settings.remoteQualityDescription' => 'Override Default Quality při připojení k serveru prostřednictvím vzdáleného připojenia.',
			'settings.qualityPresetOriginalDescription' => 'Přehrávejte zdroj v dostupné kvalitě, aniž byste požádali server o jeho překódování.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Požádejte server o převedený tok pomocí výše uvedené rozlišení a bitrate.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Použijte kvalitu vybranou v předvolené kvalitě.',
			'settings.musicQualityDescription' => 'Nastavte maximální požadovanou audio bitovou rychlost od serveru; originál zachovává zdrojový tok.',
			'settings.musicQualityOriginalDescription' => 'Přehrávejte zdrojový zvuk bez bitrate-capped transcode.',
			'settings.musicQualityTranscodeOptionDescription' => 'Požádejte o transkód serveru v blízkosti výše uvedené bitové rychlosti; skutečný výsledek se může lišit.',
			'settings.maxVolumeInputLabel' => 'Maximální objem (%)',
			'settings.checkForUpdatesDescription' => 'Zkontrolujte, zda je k dispozici novější verze PlezyNG.',
			'settings.appearanceDescription' => 'Vyberte téma aplikace a přizpůsobte karty knihovny, domovské řádky a navigaci.',
			'settings.prerollLibraryDescription' => 'Vyberte si knihovnu, která obsahuje klipy k dispozici jako filmové pre-rolls.',
			'settings.prerollSelectionDescription' => 'Vyberte, které klipy z vybrané knihovny můžete hrát před filmy.',
			'settings.contentScreensaverDelayOptionDescription' => 'Počkejte na to mnoho minut bez vstupu, než se zobrazí obrazovkový záložní umělecké dílo.',
			'settings.videoCodecOptionDescription' => 'Umožňujte přímé přehrávání pro tento kodek, když je podporován. nekontrolované kodeky jsou transkódovány mediálním serverem.',
			'themeEditor.builtIn' => 'stavět-in',
			'themeEditor.presets' => 'přednášky',
			'themeEditor.custom' => 'Vlastní',
			'themeEditor.customEmpty' => 'Zatím nevytvořeno',
			'themeEditor.editCustom' => 'Edit témata',
			'themeEditor.editCustomDescription' => 'Každou barvu si vyberte sami',
			'themeEditor.locked' => 'Životní přístup požadovaný',
			'themeEditor.savedLocked' => 'Ušetřeno – dostupné s doživotním přístupem',
			'themeEditor.title' => 'Custom témata',
			'themeEditor.startFrom' => 'Začněte od',
			'themeEditor.startFromDescription' => 'Kopírovat všechny barvy z jiné tématy',
			'themeEditor.colors' => 'barvy',
			'themeEditor.preview' => 'Náhled',
			'themeEditor.slots.bg' => 'pozadí',
			'themeEditor.slots.surface' => 'Povrch',
			'themeEditor.slots.outline' => 'Výstupy',
			'themeEditor.slots.text' => 'Text',
			'themeEditor.slots.textMuted' => 'Sekundární text',
			'themeEditor.slots.accent' => 'Zvýraznění',
			'themeEditor.opacity' => 'Opacita',
			'themeEditor.hexHint' => '#RRGGBB nebo #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Z jiných témat',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme} ${color}',
			'themeEditor.contrast.textOnBg' => 'Text na pozadí',
			'themeEditor.contrast.textOnSurface' => 'Text na povrchu',
			'themeEditor.contrast.textMutedOnBg' => 'Sekundární text na pozadí',
			'themeEditor.contrast.textMutedOnSurface' => 'Sekundární text na povrchu',
			'themeEditor.contrast.accentOnBg' => 'Pozor na pozadí',
			'themeEditor.contrast.accentOnSurface' => 'Zvláštní důraz na povrch',
			'themeEditor.contrast.labelOnAccent' => 'Tisková značka na akcentě',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, pod doporučeným ${minimum}:1',
			'themeEditor.discardTitle' => 'Chybí se změny?',
			'themeEditor.discardMessage' => 'Neuložené změny barev budou ztraceny.',
			'themeEditor.discard' => 'Diskuze',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Článek ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => 'Zbývá ${minutes} min',
			'themeEditor.previewSwitch' => 'Automatické přehrávání',
			'themeEditor.previewMutedText' => 'Druhý text se takhle čte',
			'themeEditor.themeSystemDescription' => 'Sledujte vzhled vašeho zařízení a automaticky přejděte mezi světlem a temnotou.',
			'themeEditor.themeLightDescription' => 'Použijte jasný pozadí s tmavým textem.',
			'themeEditor.themeDarkDescription' => 'Použijte tmavé pozadí s lehkým textem.',
			'themeEditor.themeOledDescription' => 'Používejte černé povrchy, které snižují světlo na OLED obrazovkách.',
			'themeEditor.themeEmberDescription' => 'Použijte teplé červené a amber akcentní barvy.',
			'themeEditor.themeGlacierDescription' => 'Použijte barevné modré akcenty.',
			'themeEditor.themeForestDescription' => 'Použijte zelené a přírodní barevné akcenty.',
			'themeEditor.themePlumDescription' => 'Použijte violetní a plumové akcentní barvy.',
			'themeEditor.themePaperDescription' => 'Použijte teplé papírové povrchy a barvy inspirované inkoustem.',
			'themeEditor.themeCustomDescription' => 'Použijte barevnou paletu, kterou jste vytvořili v přizpůsobeném editoru témat.',
			'themeEditor.editorDescription' => 'Vyberte si barvu palety, upravte její hustotu, nasycení, jasnost nebo opacitu a předchozí aktualizace se zobrazí.',
			'search.hint' => 'Hledat filmy, představení, hudba...',
			'search.tryDifferentTerm' => 'Vyzkoušejte jiný vyhledávací termín',
			'search.searchYourMedia' => 'Vyhledejte své média',
			'search.enterTitleActorOrKeyword' => 'Zadejte titul, herec nebo klíčové slovo',
			'search.people' => 'Lidé',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Set krátký pro ${actionName}',
			'hotkeys.clearShortcut' => 'Jasný krátký',
			'hotkeys.noShortcutSet' => 'Není krátký set',
			'hotkeys.currentShortcut' => 'Aktuální zkratka :',
			'hotkeys.pressToRecord' => 'Vyberte možnost nahrávání krátkého',
			'hotkeys.recordingShortcut' => 'Stiskněte krátkodobou nyní',
			'hotkeys.actions.playPause' => 'Hrát / Pause',
			'hotkeys.actions.volumeUp' => 'Zvýšit hlasitost',
			'hotkeys.actions.volumeDown' => 'Volume dolů',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Hledat dopředu (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Hledat zpět (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Srovnání Fullscreen',
			'hotkeys.actions.muteToggle' => 'Společně s MUT',
			'hotkeys.actions.subtitleToggle' => 'Podtitulky společně',
			'hotkeys.actions.audioTrackNext' => 'Další Audio Track',
			'hotkeys.actions.subtitleTrackNext' => 'Následující příspěvek Subtitle Track',
			'hotkeys.actions.chapterNext' => 'Další kapitola',
			'hotkeys.actions.chapterPrevious' => 'Předchozí kapitola',
			'hotkeys.actions.episodeNext' => 'Další díl',
			'hotkeys.actions.episodePrevious' => 'Předchozí epizoda',
			'hotkeys.actions.speedIncrease' => 'Zvýšení rychlosti',
			'hotkeys.actions.speedDecrease' => 'Snížení rychlosti',
			'hotkeys.actions.speedReset' => 'rychlost reset',
			'hotkeys.actions.zoomIn' => 'Zoom v',
			'hotkeys.actions.zoomOut' => 'Zoom ven',
			'hotkeys.actions.zoomReset' => 'Zpět na Zoom',
			'hotkeys.actions.subSeekNext' => 'Vyhledejte další subtitle',
			'hotkeys.actions.subSeekPrev' => 'Předchozí Předchozí Subtitle',
			'hotkeys.actions.subtitleDelayIncrease' => 'Zpoždění podtitulů',
			'hotkeys.actions.subtitleDelayDecrease' => 'Podtitulky Advance',
			'hotkeys.actions.shaderToggle' => 'Společně s Shaders',
			'hotkeys.actions.skipMarker' => 'Vstupní úvěr / Credit',
			'hotkeys.actions.screenshot' => 'Zobrazit screenshot',
			'hotkeys.actions.framePrevious' => 'Předchozí rámec',
			'hotkeys.actions.frameNext' => 'Další rámec',
			'fileInfo.title' => 'Info souborů',
			'fileInfo.overview' => 'Přehled',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Zvuk',
			'fileInfo.subtitles' => 'Titulky',
			'fileInfo.images' => 'Vestavěné obrázky',
			'fileInfo.dataStreams' => 'Data Streamová',
			'fileInfo.lyrics' => 'Texty',
			'fileInfo.file' => 'Soubor',
			'fileInfo.attachments' => 'Příslušenství',
			'fileInfo.delivery' => 'dodání',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'verze ${index} z ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Soubor ${index} z ${count}',
			'fileInfo.noStreams' => 'Server oznámil žádné streamování pro tento soubor.',
			'fileInfo.copyPath' => 'Kopírování trasy',
			'fileInfo.pathCopied' => 'Archivní cesta kopírovaná',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Značka kodeku',
			'fileInfo.resolution' => 'Rozlišení',
			'fileInfo.codedResolution' => 'Kódovaná rezoluce',
			'fileInfo.bitrate' => 'Datový tok',
			'fileInfo.frameRate' => 'Rychlost rámu',
			'fileInfo.rotation' => 'Rotace',
			'fileInfo.comment' => 'Jak',
			'fileInfo.audioDescription' => 'Audio popis',
			'fileInfo.headerCompression' => 'Header komprese',
			'fileInfo.sidecarFile' => 'Sídlo souborů',
			'fileInfo.transportTimestamp' => 'Dopravní čas',
			'fileInfo.displayOffset' => 'Zobrazení Offset',
			'fileInfo.previewFailureCode' => 'Předchozí článekKód selhání',
			'fileInfo.previewRetries' => 'Předpověď Retries',
			'fileInfo.aspectRatio' => 'Poměr stran',
			'fileInfo.pixelAspectRatio' => 'Poměr stran pixelu',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Úroveň',
			'fileInfo.bitDepth' => 'Počet bitů na pixel',
			'fileInfo.pixelFormat' => 'Formát pixelu',
			'fileInfo.colorSpace' => 'Barva prostoru',
			'fileInfo.colorRange' => 'barevný rozsah',
			'fileInfo.colorPrimaries' => 'Primární barva',
			'fileInfo.colorTransfer' => 'Barva přenosu',
			'fileInfo.chromaSubsampling' => 'Chromová podskupina',
			'fileInfo.chromaLocation' => 'Poloha Chroma',
			'fileInfo.scanType' => 'Typ skenování',
			'fileInfo.interlaced' => 'Prokládané',
			'fileInfo.anamorphic' => 'Anamorfní',
			'fileInfo.referenceFrames' => 'Referenční rámec',
			'fileInfo.dynamicRange' => 'Dynamický rozsah',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Úroveň Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision verze',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision Zásuvky',
			'fileInfo.baseLayerCompatibility' => 'Základní kompatibilita',
			'fileInfo.avcBitstream' => 'Bitový tok AVC',
			'fileInfo.nalLengthSize' => 'NAL délka velikost',
			'fileInfo.scalingMatrix' => 'Vlastní matrace',
			'fileInfo.streamIdentifier' => 'Stream identifikátor',
			'fileInfo.streamIndex' => 'Streamový index',
			'fileInfo.streamId' => 'ID streamu',
			'fileInfo.language' => 'Jazyk',
			'fileInfo.languageCode' => 'Jazykový kód',
			'fileInfo.streamTitle' => 'Název Track',
			'fileInfo.channels' => 'Kanály',
			'fileInfo.sampleRate' => 'Vzorkovací frekvence',
			'fileInfo.spatialAudio' => 'Vesmírný audio',
			'fileInfo.textBased' => 'Text založený',
			'fileInfo.subtitleFormat' => 'Sídlo formátu',
			'fileInfo.provider' => 'Poskytovatel',
			'fileInfo.matchScore' => 'Zápasový skóre',
			'fileInfo.externalDelivery' => 'Může se sloužit samostatně',
			'fileInfo.sidecarPath' => 'Sídlová cesta',
			'fileInfo.sourceStream' => 'Kopírováno z',
			'fileInfo.temporary' => 'dočasné',
			'fileInfo.timeBase' => 'Časová základna',
			'fileInfo.overallBitrate' => 'Celkový bitrate',
			'fileInfo.path' => 'Cesta k souboru',
			'fileInfo.fileName' => 'Název souboru',
			'fileInfo.size' => 'Velikost',
			'fileInfo.totalSize' => 'Celková velikost',
			'fileInfo.container' => 'Kontejner',
			'fileInfo.duration' => 'Délka',
			'fileInfo.previewThumbnails' => 'Předpověď Thumbnails',
			'fileInfo.previewIndex' => 'Předpověď Index',
			'fileInfo.packetLength' => 'Délka balení',
			'fileInfo.filePresent' => 'Soubor přítomný',
			'fileInfo.fileReadable' => 'Číst na serveru',
			'fileInfo.streamPath' => 'Stream cestou',
			'fileInfo.optimizedForStreaming' => 'Optimalizace pro streamování',
			'fileInfo.has64bitOffsets' => '64bitové offsety',
			'fileInfo.protocol' => 'Protokol',
			'fileInfo.mediaType' => 'Mediální typ',
			'fileInfo.sourceKind' => 'Zdrojový typ',
			'fileInfo.optimizedVersion' => 'Optimalizovaná verze',
			'fileInfo.optimizationTarget' => 'Optimalizace cíle',
			'fileInfo.deletedAt' => 'Odstraněno',
			'fileInfo.remoteSource' => 'Vzdálený zdroj',
			'fileInfo.infiniteStream' => 'Nekonečný proud',
			'fileInfo.directPlay' => 'Přímá hra',
			'fileInfo.directStream' => 'Přímý proud',
			'fileInfo.transcoding' => 'Překódování',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'verze ID',
			'fileInfo.fileId' => 'ID souboru',
			'fileInfo.defaultAudioTrack' => 'Standardní Audio Track',
			'fileInfo.defaultSubtitleTrack' => 'Předvolené Subtitle Track',
			'fileInfo.subtitlesOff' => 'Vypnuto',
			'fileInfo.flagDefault' => 'Výchozí',
			'fileInfo.flagForced' => 'Vynucené',
			'fileInfo.flagSelected' => 'vybrané',
			'fileInfo.flagExternal' => 'Externí',
			'fileInfo.flagHearingImpaired' => 'Slyšící se zhoršuje',
			'fileInfo.flagDub' => 'Dubová',
			'fileInfo.flagOriginal' => 'originál',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Mark jako sledovaný',
			'mediaMenu.markAsUnwatched' => 'Mark jako nepozorovaný',
			'mediaMenu.removeFromContinueWatching' => 'Odstranit od Pokračovat v sledování',
			'mediaMenu.viewDetails' => 'Zobrazit detaily',
			'mediaMenu.goToSeries' => 'Přejděte do série',
			'mediaMenu.shufflePlay' => 'Hrají Shuffle',
			'mediaMenu.shuffleNotAvailableOffline' => 'SCHUFFLE není k dispozici offline',
			'mediaMenu.fileInfo' => 'Info souborů',
			'mediaMenu.deleteEpisodeFromServer' => 'Odstranit epizodu z serveru',
			'mediaMenu.deleteSeasonFromServer' => 'Odstranit sezónu z serveru',
			'mediaMenu.deleteShowFromServer' => 'Odstranit show z serveru',
			'mediaMenu.deleteMovieFromServer' => 'Odstranit film z serveru',
			'mediaMenu.deleteEpisodeTitle' => 'Odstranit tuto epizodu?',
			'mediaMenu.deleteSeasonTitle' => 'Zrušit tuto sezónu?',
			'mediaMenu.deleteShowTitle' => 'Vymazat tuto show?',
			'mediaMenu.deleteMovieTitle' => 'Vymazat tento film?',
			'mediaMenu.deleteEpisodeConfirm' => 'Odstranit díl',
			'mediaMenu.deleteSeasonConfirm' => 'Sezóna odstranění',
			'mediaMenu.deleteShowConfirm' => 'Odstranění show',
			'mediaMenu.deleteMovieConfirm' => 'Odstranit film',
			'mediaMenu.deleteAnyway' => 'Odstranit v každém',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Trvale smazat ${title} ze serveru?',
			'mediaMenu.deleteMultipleWarning' => 'To zahrnuje všechny epizody a jejich soubory.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Tím se smaže ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda v této položce i její soubor.', few: 'Tím se smažou všechny ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody v této položce i jejich soubory.', many: 'Tím se smažou všechny epizody v této položce (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) i jejich soubory.', other: 'Tím se smaže všech ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod v této položce i jejich soubory.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Tato položka je uložena v ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souboru, který bude smazán.', few: 'Tato položka je uložena ve ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souborech a všechny budou smazány.', many: 'Tato položka je uložena v souborech (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}), které budou všechny smazány.', other: 'Tato položka je uložena v ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} souborech a všechny budou smazány.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Ve stejném souboru je uložena ještě ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda, která bude také smazána:', few: 'Ve stejném souboru jsou uloženy ještě ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody, které budou také smazány:', many: 'Další epizody ve stejném souboru (počet: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}) budou také smazány:', other: 'Ve stejném souboru je uloženo dalších ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod, které budou také smazány:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG nedokázalo ověřit, které soubory budou odstraněny, takže může smazat více než výše uvedenou položku. Akci zrušte a zkuste to znovu, nebo pokračujte ve smazání.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Server neposkytl podrobnosti o souborech této položky, takže PlezyNG nemůže ověřit, které soubory budou odstraněny. Může být smazáno více než výše uvedená položka.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Media objekt byl úspěšně odstraněn',
			'mediaMenu.mediaFailedToDelete' => 'Nedokázal odstranit mediální položku',
			'mediaMenu.rate' => 'Hodnocení',
			'mediaMenu.playFromBeginning' => 'Přehrát od začátku',
			'mediaMenu.playVersion' => 'Hrajte verzi...',
			'rateSheet.title' => 'Hodnocení',
			'rateSheet.server' => 'servery',
			'rateSheet.favorite' => 'Oblíbené',
			'rateSheet.favorited' => 'Oblíbený',
			'rateSheet.saved' => 'Zachráněno',
			'rateSheet.notAvailable' => 'Není nalezen žádný zápas',
			'rateSheet.noConnectedServices' => 'Připojte službu v nastavení, abyste tam hodnotili.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, televizní show',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'Zhlédnuto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} % zobrazených',
			'accessibility.mediaCardUnwatched' => 'nezhlédnuto',
			'accessibility.tapToPlay' => 'Klepnutím přehrajete',
			'accessibility.decrease' => 'Snížení',
			'accessibility.increase' => 'Zvýšení',
			'accessibility.decreaseValue' => ({required Object label}) => 'Ztráta ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Zvýšení ${label}',
			'accessibility.hue' => 'Odstín',
			'accessibility.saturation' => 'Saturace',
			'accessibility.brightness' => 'Světlo',
			'accessibility.hexColor' => 'Hex barva',
			'accessibility.expandText' => 'Rozšířte text',
			'accessibility.collapseText' => 'Zkrachovaný text',
			'accessibility.alphabetNavigation' => 'Alphabetní navigace',
			'accessibility.alphabetScrollHint' => 'Přejetím nahoru nebo dolů se pohybujete podle písmen',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Řádek ${row} z ${rowCount}, sloupec ${column} z ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Růž ${row} z ${rowCount}',
			'accessibility.autoScrollPlay' => 'Hrajte si Auto-Scroll',
			'accessibility.autoScrollPause' => 'Přestávka Auto-Scroll',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Červená',
			'accessibility.green' => 'Zelená',
			'accessibility.blue' => 'Modrá',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'přístupnost',
			'accessibility.summary' => 'Text, kontrast, pohyb a kontroly',
			'accessibility.systemHint' => 'Nastavení přístupnosti vašeho zařízení se vždy vztahují.Tyto možnosti přidávají úpravy po celém PlezyNG.',
			'accessibility.readability' => 'Čtení a viditelnost',
			'accessibility.textSize' => 'Další textová velikost',
			'accessibility.preview' => 'Přečtěte si, poslouchejte a sledujte ve svém vlastním tempu.',
			'accessibility.boldText' => 'Rozhraní text',
			'accessibility.highContrast' => 'Vysoký kontrast',
			'accessibility.highContrastHint' => 'Výraznější text, obrysy a indikátory zaměření na světlém i tmavém pozadí.',
			'accessibility.interaction' => 'Pohyb a interakce',
			'accessibility.reduceMotion' => 'Snížení pohybu',
			'accessibility.reduceMotionHint' => 'Zastaví pohyb indikátoru zaměření, přechody stránek a dekorativní efekty.',
			'accessibility.largeTargets' => 'větší cíle dotyku',
			'accessibility.largeTargetsHint' => 'Dáváme sdíleným ovládacím prvkům více prostoru pro dotyk a asistenční navigaci.',
			'accessibility.navigationHint' => 'Mezi ovládacími prvky se přesouvejte klávesami Tab a Shift+Tab, aktivujte je klávesou Enter nebo mezerníkem a zavírejte klávesou Escape nebo tlačítkem Zpět. Při otevřené knize je dostupné přiblížení a nastavení čtení.',
			'accessibility.textSizeDescription' => 'Rozsah textového rozhraní v PlezyNG kromě nastavení velikosti textu systému vašeho zařízení.',
			'accessibility.boldTextHint' => 'Použijte těžší váhu pro rozhraní etikety a zprávy, aby je jednodušší rozlišovat.',
			'tooltips.shufflePlay' => 'Shuffle hraje',
			'tooltips.playTrailer' => 'Hrajte trailer',
			'tooltips.markAsWatched' => 'Mark jako sledovaný',
			'tooltips.markAsUnwatched' => 'Mark jako nepozorovaný',
			'audioTracks.track' => ({required Object n}) => 'Zvukový pás ${n}',
			'videoControls.audioLabel' => 'Zvuk',
			'videoControls.subtitlesLabel' => 'Titulky',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Textová krabička',
			'videoControls.fillScreen' => 'vyplňte obrazovku',
			'videoControls.stretch' => 'Roztáhnout',
			'videoControls.lockRotation' => 'Závěsná rotace',
			'videoControls.unlockRotation' => 'Odemknutí rotace',
			'videoControls.timerActive' => 'Aktivní čas',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Playback se zastaví v ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Konec aktuálního videa',
			'videoControls.sleepTimerStopAtHeader' => 'Zastavte se',
			'videoControls.sleepTimerDurationHeader' => 'Časový',
			'videoControls.playbackWillPauseAtEnd' => 'Playback se zastaví na konci tohoto videa',
			'videoControls.stillWatching' => 'Stále se díváte?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Odpočinek v ${seconds}s',
			'videoControls.continueWatching' => 'pokračovat',
			'videoControls.autoPlayNext' => 'Auto-Play Další',
			'videoControls.playNext' => 'Přehrát jako další',
			'videoControls.playButton' => 'Přehrát',
			'videoControls.pauseButton' => 'Pozastavit',
			'videoControls.playbackPaused' => 'Odpočinek',
			'videoControls.playbackResumed' => 'Hrají',
			'videoControls.loadingVideo' => 'nahrávání videa',
			'videoControls.showPlaybackControls' => 'Zobrazit playback kontroly',
			'videoControls.hidePlaybackControls' => 'Stáhněte si playback kontroly',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Hledat zpět ${seconds} sekund',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Hledání vpřed ${seconds} sekund',
			'videoControls.previousButton' => 'Předchozí epizoda',
			'videoControls.nextButton' => 'Další díl',
			'videoControls.previousChapterButton' => 'Předchozí kapitola',
			'videoControls.nextChapterButton' => 'Další kapitola',
			'videoControls.muteButton' => 'Ztlumit',
			'videoControls.unmuteButton' => 'Povolit zvuk',
			'videoControls.settingsButton' => 'Playback nastavení',
			'videoControls.tracksButton' => 'Audio a subtituly',
			'videoControls.chaptersButton' => 'Kapitoly',
			'videoControls.versionQualityButton' => 'Verze a kvalita',
			'videoControls.versionColumnHeader' => 'Verze',
			'videoControls.qualityColumnHeader' => 'Kvalita',
			'videoControls.qualityOriginal' => 'originál',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Překódování není k dispozici – hraje originální kvalitu',
			'videoControls.subtitleUnavailableFallback' => 'Výběr vybraných titulů nelze nahrát – pokračovat bez titulů',
			'videoControls.pipButton' => 'Obrazový režim - Picture in-Picture',
			'videoControls.aspectRatioButton' => 'Poměr stran',
			'videoControls.ambientLighting' => 'Atmosférické osvětlení',
			'videoControls.fullscreenButton' => 'Vstup na plný obrazovek',
			'videoControls.exitFullscreenButton' => 'Výstup na plný obrazovek',
			'videoControls.alwaysOnTopButton' => 'Vždy na vrcholu',
			'videoControls.rotationLockButton' => 'rotační zámek',
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => 'Závěsný obrazovek',
			'videoControls.screenLockButton' => 'Zámek obrazovky',
			'videoControls.timelineSlider' => 'Video časové linie',
			'videoControls.volumeSlider' => 'Úroveň objemu',
			'videoControls.endsAt' => ({required Object time}) => 'Končí na ${time}',
			'videoControls.pipActive' => 'Hrají v Picture-in-Picture',
			'videoControls.pipFailed' => 'Obrázek v obraze se neuskutečnil',
			'videoControls.screenshotSaved' => 'Screenshot zachráněný',
			'videoControls.screenshotFailed' => 'Nemohla jsem si pořídit screenshot',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Přiblížení ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Hlasitost ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Vyžaduje Android 8.0 nebo novější',
			'videoControls.pipErrors.iosVersion' => 'Vyžaduje iOS 15.0 nebo novější',
			'videoControls.pipErrors.permissionDisabled' => 'Obraz v obrázku je vypnut. Aktivovat ho v nastavení systému.',
			'videoControls.pipErrors.notSupported' => 'Přístroj nepodporuje režim obrázku v obrazu',
			'videoControls.pipErrors.voSwitchFailed' => 'Nedokázal přepínat výstup videa na obrázek v obrazu',
			'videoControls.pipErrors.failed' => 'Obrázek v obraze se neuskutečnil',
			'videoControls.pipErrors.prepareFailed' => 'Obrázek v obraze nelze připravit',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Chyba se vyskytla: ${error}',
			'videoControls.chapters' => 'Kapitoly',
			'videoControls.noChaptersAvailable' => 'Žádné kapitoly k dispozici',
			'videoControls.queue' => 'Kouč',
			'videoControls.noQueueItems' => 'Žádné položky v kousku',
			'videoControls.noAudioDevicesAvailable' => 'Žádné audio zařízení k dispozici',
			'videoControls.searchSubtitles' => 'Podtitul hledání',
			'videoControls.language' => 'Jazyk',
			'videoControls.noSubtitlesFound' => 'Žádné podtitulky nalezeny',
			'videoControls.subtitleDownloaded' => 'Subtítky stažené',
			'videoControls.subtitleDownloadedNotApplied' => 'Subtitle stažen, ale nemohl být vybrán',
			'videoControls.subtitleDownloadFailed' => 'Nedokázal si stáhnout subtitle',
			'videoControls.searchLanguages' => 'Vyhledávací jazyky...',
			'videoControls.skipIntro' => 'Skříň vstupuje',
			'videoControls.skipCredits' => 'Skok úvěrů',
			'videoControls.nextEpisode' => 'Další díl',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Původní číslo ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Článek ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (příslušný)',
			'videoControls.osdSubtitlesOff' => 'Název titulu: Off',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Články v kategorii: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio číslo: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímek', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímky', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímku', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} snímků', ), 
			'videoControls.trackSelectionTitle' => 'Zvolte stopy před playbackem',
			'videoControls.trackSelectionAuto' => 'Automatické výběr',
			'videoControls.openMiniPlayer' => 'Otevřený mini hráč',
			'videoControls.returnToFullPlayer' => 'Zpět na plný hráč',
			'videoControls.loadSubtitleFile' => 'Přihláška souboru Subtitle...',
			'videoControls.subtitleLoadFailed' => 'Nedokázal přenést soubor subtitle',
			'videoControls.skipAds' => 'Skřípání Ads',
			'videoControls.tapToUnlock' => 'Klepnutím odemknete',
			'videoControls.tapAgainToUnlock' => 'Opětovným klepnutím odemknete',
			'messages.markedAsWatched' => 'označené jako sledované',
			'messages.markedAsUnwatched' => 'označené jako nepozorované',
			'messages.markedAsWatchedOffline' => 'Zaznamenáno jako sledované (synchronizuje se, když je online)',
			'messages.markedAsUnwatchedOffline' => 'Označen jako nepozorovaný (synchronizuje se, když je online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatické odstranění: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} sledované ke stažení', other: 'Auto-removed ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} sledované stahování', ), 
			'messages.removedFromContinueWatching' => 'Odstranění z pokračování sledování',
			'messages.errorLoading' => ({required Object error}) => 'Chyba: ${error}',
			'messages.searchPartialResults' => 'Některé mediální servery nemohou být vyhledávány. zobrazování dostupných výsledků.',
			'messages.streamInterrupted' => 'Přehrávač byl přerušen. tisková hra nebo se snaží odstoupit.',
			'messages.liveStreamInterrupted' => 'Přímý stream byl přerušen. tisková hra se vrací.',
			'messages.fileInfoNotAvailable' => 'Informace o souborech nejsou k dispozici',
			'messages.playbackAuthenticationRequired' => 'Přihlaste se k serveru médií znovu, abyste tuto položku hrali.',
			'messages.playbackServerUnavailable' => 'Media server není k dispozici. zkuste znovu později.',
			'messages.playbackDataInvalid' => 'Server vrátil neplatné informace o přehrávání.',
			'messages.playbackCancelled' => 'Playback byl zrušen.',
			'messages.playbackFailed' => 'Playback se nemohl zahájit.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Playback se nemohl spustit: ${error}',
			'messages.audioOutputFailed' => 'Zkontrolujte audio připojení televizoru nebo přijímače; pokud jiné aplikace nemají ani zvuk, znovu spustit zařízení.',
			'messages.mediaUnavailable' => 'Tento obsah již není k dispozici.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Informace o souboru chyby: ${error}',
			'messages.errorLoadingSeries' => 'Chyby v seriálu',
			'messages.musicNotSupported' => 'Hudební playback zatím není podporován',
			'messages.noDescriptionAvailable' => 'Žádný popis k dispozici',
			'messages.noProfilesAvailable' => 'Žádné profily k dispozici',
			'messages.contactAdminForProfiles' => 'Kontaktujte správce serveru, abyste přidali profily',
			'messages.unableToDetermineLibrarySection' => 'Není možné určit část knihovny pro tento položka',
			'messages.logsCleared' => 'Logy vyčistěné',
			'messages.logsCopied' => 'Přihlášky kopírované na clipboard',
			'messages.noLogsAvailable' => 'Žádné logy k dispozici',
			'messages.libraryScanning' => ({required Object title}) => 'Skenování „${title}“',
			'messages.libraryScanStarted' => ({required Object title}) => 'Skenování knihovny začíná pro "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Knihovna se neskončila: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Znovuzavírací metadata pro "${title}..."',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Aktualizace metadata začíná pro "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Nepodařilo se aktualizovat metadata: ${error}',
			'messages.logoutConfirm' => 'Jste si jisti, že se chcete přihlásit?',
			'messages.noSeasonsFound' => 'Žádné sezóny nenajdeme',
			'messages.seasonsLoadFailed' => 'Nemohla by se stahovat sezóny',
			'messages.noEpisodesFound' => 'V první sezoně nebyly nalezeny žádné epizody',
			'messages.noEpisodesFoundGeneral' => 'Žádné epizody nenajdete',
			'messages.episodesLoadFailed' => 'Nemohl by se vyskytnout epizody',
			'messages.noResultsFound' => 'Žádné výsledky.',
			'messages.sleepTimerSet' => ({required Object label}) => 'Časovač spánku nastavený pro ${label}',
			'messages.noItemsAvailable' => 'Žádné položky k dispozici',
			'messages.failedToCreatePlayQueueNoItems' => 'Neschopné vytvořit hřiště - žádné položky',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Neúspěšný na ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Přepínání na kompatibilní hráče.',
			'messages.serverLimitTitle' => 'Playback neuspěl',
			'messages.serverLimitBody' => 'Serverová chyba (HTTP 500). omezení šířky pásma/transkódování pravděpodobně odmítlo tuto sezení.',
			'messages.mediaUnreadableTitle' => 'Soubory nedostupné',
			'messages.mediaUnreadableBody' => 'Server našel tento položka, ale nemohl si přečíst jeho soubor (HTTP 404). soubor byl pravděpodobně přemístěn, odstraněn, nebo jeho ukládání je offline.',
			'messages.serverBusyTitle' => 'Stream nedostupný',
			'messages.serverBusyBody' => 'Server odmítl streamovat tento soubor (HTTP 503).Může být restartující, zaneprázdněný, nebo souborové ukládání může být offline.Zkuste znovu v okamžiku - pokud se to stále děje, požádejte majitele serveru, aby zkontroloval server a ukládání souboru.',
			'messages.playbackNotAllowedTitle' => 'Playback není povoleno',
			'messages.playbackNotAllowedBody' => 'Server odmítl streamovat tento položka (HTTP 403). Váš účet nemusí mít povolení k jeho hraní, nebo server může umožnit pouze přehrávání na místní síti.',
			'messages.logsUploaded' => 'Logové nahrávky',
			'messages.logsUploadFailed' => 'Nepodařilo se nahrávat logy',
			'messages.logId' => 'ID protokolu',
			'messages.burnedSubtitlesUseMenu' => 'Podtituly jsou spáleny do tohoto toku. změnit je z podtitulového menu.',
			'messages.noVideoUrl' => 'Žádný video URL není k dispozici',
			'messages.playbackNoMediaSources' => 'Server nevrátil žádné přehrávané zdroje médií',
			'messages.playbackDataNotPrepared' => 'Playback byl spuštěn dříve, než byly data hotová',
			'messages.streamSelectionUnavailable' => 'Stream selection není k dispozici pro tento zdroj',
			'messages.streamSelectionFailed' => 'Nemohou použít vybrané toky',
			'messages.trackSelectionNotRemembered' => 'Tato volba track se vztahuje pouze na aktuální playback.',
			'messages.serverUnavailableForProfile' => 'Server není k dispozici pro aktivní profil',
			'subtitlingStyling.previewSample' => 'Rychlý hnědý fox skočí nad lazy pes',
			'subtitlingStyling.text' => 'Text',
			'subtitlingStyling.border' => 'hranice',
			'subtitlingStyling.background' => 'pozadí',
			'subtitlingStyling.fontSize' => 'Zkratka velikost',
			'subtitlingStyling.textColor' => 'Barva textu',
			'subtitlingStyling.borderSize' => 'hraniční velikost',
			'subtitlingStyling.borderColor' => 'hraniční barva',
			'subtitlingStyling.backgroundOpacity' => 'Pozadí Opacity',
			'subtitlingStyling.backgroundColor' => 'Barva pozadí',
			'subtitlingStyling.position' => 'Pozice',
			'subtitlingStyling.assOverride' => 'ASS Překročení',
			'subtitlingStyling.overrideScale' => 'Skala',
			'subtitlingStyling.overrideForce' => 'Síla',
			'subtitlingStyling.overrideStrip' => 'Odstranění stylingu',
			'subtitlingStyling.positionTop' => 'Top',
			'subtitlingStyling.positionBottom' => 'Důvod',
			'subtitlingStyling.useMargins' => 'Použití marže',
			'subtitlingStyling.useMarginsDescription' => 'Umožňujte textové podtituly v prostoru mimo video. stylové podtituly mohou zachovat jejich původní umístění.',
			'subtitlingStyling.anchorToScreen' => 'Anchor na obrazovce',
			'subtitlingStyling.anchorToScreenDescription' => 'Zobrazit textové podtituly v černých čárovkách pod videem širokého obrazovky',
			'subtitlingStyling.bold' => 'Tučné',
			'subtitlingStyling.italic' => 'Italský',
			'subtitlingStyling.renderResolution' => 'Renderová rezoluce',
			'subtitlingStyling.renderResolutionScreen' => 'Rozlišení obrazovky',
			'subtitlingStyling.renderResolutionVideo' => 'Rozlišení videa',
			'subtitlingStyling.fontSizeDescription' => 'Na tomto zařízení nastavíte velikost podtitulu textu.',
			'subtitlingStyling.textColorDescription' => 'Vyberte barvu použité pro text podtitulů.',
			'subtitlingStyling.borderSizeDescription' => 'Nastavení tloušťky výstupu kolem podtitulového textu.',
			'subtitlingStyling.borderColorDescription' => 'Zvolte barvu použité pro podtitulový výstup.',
			'subtitlingStyling.backgroundColorDescription' => 'Zvolte barvu za textem.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Nastavte, jak transparentní je podtitulový pozadí: 0% je jasný a 100% pevný.',
			'subtitlingStyling.positionDescription' => '0 % je horní část videa a 100 % dolní část.',
			'subtitlingStyling.assOverrideDescription' => 'Vyberte, zda hráč sleduje, upravuje, nahrazuje nebo odstraňuje styling vložený do podtitulů ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Udržujte písma, barvy, velikosti a umístění napsané v souboru podtitulů.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Umožňujte nastavení podtitulového stylu hráče přizpůsobit podtituly ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Aplikujte stylování hráče a rozsah vestavěných velikostí, aby odpovídala video rozměrů.',
			'subtitlingStyling.assOverrideOptions.force' => 'Nahraďte vestavěné styly ASS stylem subtitu hráče.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Odstranit vestavěné formátování ASS a přinést podtitul text jasně.',
			'subtitlingStyling.renderResolutionDescription' => 'Vyberte rozlišení používané k rasterizování obrazu a ASS podtitulů. nižší Android stupnice mohou snížit rendering práci, ale vypadat jemněji.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render na plné rozlišení povrchu displeje pro nejjasnější výsledek.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render používá video rozlišení jako odkaz, který může snížit práci na vysoce rozlišených obrazovkách.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render na 75% rozlišení povrchu displeje pro skromné úspory výkonu.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Odstranit na 50% rozlišení povrchu displeje, aby se snížila práce, s jemnějšími okraji.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render na třetinu rozlišení povrchu displeje ke snížení práce, s jemnějšími okraji.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render na jednu čtvrtinu rozlišení povrchu displeje ke snížení práce, s nejjemnější výsledkem.',
			'subtitlingStyling.boldDescription' => 'Vložte text podtitulu v těžší hmotnosti.',
			'subtitlingStyling.italicDescription' => 'Podtitulový text v italštině.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Pokročilé nastavení videohrávače',
			'mpvConfig.presets' => 'přednášky',
			'mpvConfig.noPresets' => 'Žádné zachráněné předměty',
			'mpvConfig.saveAsPreset' => 'Zachraňte jako předchozí...',
			'mpvConfig.presetName' => 'Příslušný název',
			'mpvConfig.presetNameHint' => 'Zadejte jméno pro tento předpis',
			'mpvConfig.loadPreset' => 'zatížení',
			'mpvConfig.deletePreset' => 'Odstranit',
			'mpvConfig.presetSaved' => 'Prorok zachránil',
			'mpvConfig.presetLoaded' => 'Přepočítání nabité',
			'mpvConfig.presetDeleted' => 'Předpověď odstraněna',
			'mpvConfig.confirmDeletePreset' => 'Jste si jisti, že chcete tuto předvolbu odstranit?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan hwdec=auto # komentář',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Přidat linku',
			'mpvConfig.removeLine' => 'Odstranění linie',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-kontext a gpu-api jsou ignorovány na Linux: vestavěné video vždy přenášejí prostřednictvím vo=libmpv na videu, a gpu-next (které počítačové odstíny, jako je ArtCNN potřebuje) nemůže spustit vestavěné.',
			'dialog.confirmAction' => 'Potvrzení akce',
			'profiles.addPlezyProfile' => 'Přidat profil PlezyNG',
			'profiles.switchingProfile' => 'Přepínání profilu...',
			'profiles.deleteThisProfileTitle' => 'Vymazat tento profil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Odstranit ${displayName}. připojení není ovlivněno.',
			'profiles.active' => 'aktivní',
			'profiles.manage' => 'Řízení',
			'profiles.delete' => 'Odstranit',
			'profiles.signOut' => 'Odhlásit se',
			'profiles.signOutPlexTitle' => 'Přihlásit se na číslo Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Odstranit ${displayName} a všechny Plex Domácí uživatelé?',
			'profiles.signOutPlexDeleteDownloads' => 'Také odstranit downloads',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Jinak zůstanou na tomto zařízení a přijdou zpět, když se přihlásíte zpět na tento účet.',
			'profiles.signedOutPlex' => 'Podepsané z Plex.',
			'profiles.signOutFailed' => 'Podepisovat se selhal.',
			'profiles.sectionTitle' => 'profilů',
			'profiles.summarySingle' => 'Přidejte profily ke smíchání spravovaných uživatelů a místních identit',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profily · aktivní: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profily',
			'profiles.removeConnectionTitle' => 'Odstranit spojení?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Odstranit přístup ${displayName} na ${connectionLabel}. Ostatní profily ho uchovávají.',
			'profiles.deleteProfileTitle' => 'Vymazat profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Odstranit ${displayName} a jeho připojení. servery zůstávají k dispozici.',
			'profiles.profileNameLabel' => 'Profilní název',
			'profiles.pinProtectionLabel' => 'PIN ochrana',
			'profiles.copyAutomationLink' => 'Kopírování Android automatizace odkaz',
			'profiles.copyAutomationLinkDescription' => 'Vyberte tento profil z účelu nebo automatizace Android.',
			'profiles.automationLinkCopied' => 'Profilová automatizace odkaz kopírovaný.',
			'profiles.pinManagedByPlex' => 'PIN je spravován Plex. Edit on plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Není nastavení PIN. Chcete-li požadovat jeden, upravte domácí uživatel na plex.tv.',
			'profiles.setPin' => 'nastavení PIN',
			'profiles.setPinTitle' => 'nastavení PIN',
			'profiles.confirmPinTitle' => 'Potvrzení PIN',
			'profiles.pinSet' => 'PIN nastavení',
			'profiles.changePin' => 'Změna',
			'profiles.removePin' => 'Odstranit',
			'profiles.connectionsLabel' => 'připojení',
			'profiles.add' => 'Přidat',
			'profiles.deleteProfileButton' => 'Vymazat profil',
			'profiles.noConnectionsHint' => 'Žádné připojení – přidejte jeden pro použití tohoto profilu.',
			'profiles.noConnections' => 'Žádné spojení',
			'profiles.plexHomeAccount' => 'Plex Domácí účet',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex účet: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} prostřednictvím ${account}',
			'profiles.connectionDefault' => 'Výchozí',
			'profiles.connectionAs' => ({required Object displayName}) => 'jako ${displayName}',
			'profiles.makeDefault' => 'Zkuste default',
			'profiles.removeConnection' => 'Odstranit',
			'profiles.profileRenamed' => 'Profil se přejmenoval.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Přidat na ${displayName}',
			'profiles.borrowExplain' => 'Půjčte si připojení jiného profilu. PIN-ochráněné profily vyžadují PIN.',
			'profiles.borrowEmpty' => 'Zatím není co půjčit.',
			'profiles.borrowEmptySubtitle' => 'Nejprve se připojte k jinému profilu Plex, Jellyfin, nebo Emby.',
			'profiles.borrowLoadFailed' => 'Dostupné připojení nelze nahrát. zkuste znovu.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'od ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Připojení je půjčováno.',
			'profiles.borrowFailed' => 'Nepodařilo se půjčit spojení.',
			'profiles.incorrectPin' => 'Nesprávný PIN.',
			'profiles.incorrectPinTryAgain' => 'Zrušte PIN, zkuste prosím znovu.',
			'profiles.sourceProfileMissingParentAccount' => 'Zdrojový profil chybí jeho rodičovský účet.',
			'profiles.failedToLoadHomeUsers' => 'Nemohla jste si stáhnout své uživatele Plex Domácí uživatelé. zkontrolujte připojení a zkuste znovu.',
			'profiles.failedToVerifyPin' => 'Nemohl ověřit PIN.',
			'profiles.newProfile' => 'Nový profil',
			'profiles.profileNameHint' => 'Dětské pokoje, rodinné pokoje, rodinné pokoje',
			'profiles.pinProtectionOptional' => 'Ochrana PIN (opční)',
			'profiles.pinExplain' => '4D PIN je nutný pro přepínání profilů.',
			'profiles.continueButton' => 'pokračovat',
			'profiles.pinsDontMatch' => 'PIN se neshoduje',
			'profiles.tokenIdentityMismatch' => 'Profilový token Plex byl vyřešen na neočekávaném serveru',
			'profiles.settingsLocked' => 'Nastavení jsou pro tento profil zablokovány.',
			'profiles.unlockSettings' => 'Odemknout nastavení',
			'profiles.showExploreForProfile' => 'Zobrazit prohlídku pro tento profil',
			'profiles.showExploreForProfileDescription' => 'Odstranit a odstranit Explore z navigace tohoto profilu.',
			'connections.sectionTitle' => 'připojení',
			'connections.addConnection' => 'Přidejte připojení',
			'connections.addConnectionSubtitleNoProfile' => 'Přihlaste se k serveru Plex nebo připojte se k serveru Jellyfin nebo Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Přidat na ${displayName}: Plex, Jellyfin, Emby, nebo jinou profilu připojení',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Závěrečná schůze pro ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sezóna skončila pro servery ${count}',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} odmítl přístup k tomuto účtu',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servery odmítly přístup k tomuto účtu',
			'connections.signInAgain' => 'Podepisujte se znovu',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Edit ${product} připojení',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Přidat nebo odstranit URL pro ${serverName}. PlezyNG bude používat přístupné URL s nejnižší latencí.',
			'accountPreferences.sectionTitle' => 'účetní preference',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Možnosti audio, podtitulů a knihovny uložené na ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Možnosti audio, podtitulů a knihovny uložené na účtech ${count}',
			'accountPreferences.pickAccount' => 'Každý účet ukládá své vlastní preference. vyberte ten, který chcete upravit.',
			'accountPreferences.storedOnAccount' => 'Tyto možnosti jsou uloženy na samotném účtu, takže každá aplikace, která se k němu přihlásí, je používá – včetně PlezyNG na vašich jiných zařízeních.',
			'accountPreferences.noAccounts' => 'Žádné účty, které by se měly nastavit',
			'accountPreferences.noAccountsHint' => 'Přihlaste se na Plex, nebo se připojte na server Jellyfin nebo Emby, a preference uložené na tomto účtu se zobrazí zde.',
			'accountPreferences.unavailable' => 'Nemůžete tento účet získat',
			'accountPreferences.loadFailed' => 'Tyto preference nemůžu nabít',
			'accountPreferences.noPreference' => 'Žádná preference',
			'accountPreferences.notSet' => 'Není nastaven',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio a subtituly',
			'accountPreferences.groups.libraryDisplay' => 'Knihovna',
			'accountPreferences.groups.personalMedia' => 'Osobní média',
			'accountPreferences.preferredAudioLanguage' => 'Preferovaný jazyk zvuku',
			'accountPreferences.autoSelectAudio' => 'Výběr audio podle jazyka',
			'accountPreferences.autoSelectAudioDescription' => 'Odstraní jakýkoliv zvuk sleduje soubor označuje jako výchozí.',
			'accountPreferences.preferredSubtitleLanguage' => 'Preferovaný jazyk titulků',
			'accountPreferences.subtitleMode' => 'Přepínání podtitulů na',
			'accountPreferences.subtitleModes.none' => 'Manuálně vybrané',
			'accountPreferences.subtitleModes.noneDescription' => 'Nikdy nevyměňte subtituly sami.',
			'accountPreferences.subtitleModes.defaultMode' => 'Podívejte se na track flags',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Použijte výchozí a nucené vlajky uložené na každé podtitulové stopě.',
			'accountPreferences.subtitleModes.always' => 'Vždy povolená',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Přejděte na podtitulovou stopu v preferovaném jazyce, kdykoli existuje.',
			'accountPreferences.subtitleModes.onlyForced' => 'Pouze podtitulky',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Připravte pouze stopy označené jako nucené.',
			'accountPreferences.subtitleModes.smart' => 'Zahraniční audio',
			'accountPreferences.subtitleModes.smartDescription' => 'Přepínání podtitulů pouze tehdy, když je audio v jiném jazyce.',
			'accountPreferences.subtitleAccessibility' => 'Podtitul SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Nejlépe ne-SDH podtituly',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Přednost SDH podtitulů',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Pouze subtituly SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Pouze ne-SDH podtituly',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Přednost standardních titulů, když jsou k dispozici jak standardní, tak i verze SDH.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Přednost SDH podtitulů, když jsou k dispozici, ale umožňují standardní podtituly jako padnutí.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Použijte pouze podtituly SDH; nepadněte zpět do standardních podtitulů.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Používejte pouze standardní podtituly; vyloučte SDH.',
			'accountPreferences.forcedSubtitles' => 'Povinné podtitulky',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Přednost nepovinných titulů',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Upřednostňujeme podtitulky',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Pouze podtitulky',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Pouze nepovinné podtitulky',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Upřednostňuje pravidelné podtituly, ale umožňuje nucené stopy jako padnutí.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Upřednostňuje nucené stopy, když jsou k dispozici, ale umožňují pravidelné podtituly jako padnutí.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Použijte pouze stopy označené jako nucené.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Vylučte stopy označené jako nucené.',
			'accountPreferences.displayMissingEpisodes' => 'Zobrazit chybějící epizody',
			'accountPreferences.displayMissingEpisodesDescription' => 'Seznam epizod, o kterých server ví, ale nemá žádné soubory.',
			'accountPreferences.hidePlayedInLatest' => 'Ukryte sledované položky v Poslední',
			'accountPreferences.hidePlayedInLatestDescription' => 'Zanechte položky, které jste již sledovali z nejnovějších řádků serveru.',
			'accountPreferences.displayCollectionsView' => 'Zobrazit pohled na kolekce',
			'accountPreferences.displayCollectionsViewDescription' => 'Nabídněte zobrazení kolekcí serveru vedle vašich knihoven.',
			'accountPreferences.rewatchingInNextUp' => 'Zůstaňte pozorně sledováni v Next Up',
			'accountPreferences.rewatchingInNextUpDescription' => 'Jakmile dokončíte show, začněte znovu a Next Up sleduje rewatch místo toho, aby show ztratil.',
			'accountPreferences.watchedIndicator' => 'Pozorované ukazatele',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nikdy',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmy a televizní představení',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Filmy pouze',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Televizní show pouze',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Nevykazujte sledované kontrolní značky.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Zobrazit sledované kontroly pro filmy a televizní pořady.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Zobrazit sledované kontroly pouze pro filmy.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Zobrazit sledované kontroly pouze pro televizní pořady.',
			'accountPreferences.mediaReviewsVisibility' => 'Hodnocení & recenze',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Uživatelé a kritikové',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Pouze uživatelé',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Kritika pouze',
			'accountPreferences.mediaReviewsOptions.nobody' => 'skryté',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Zobrazit uživatelské hodnocení a kritické hodnotení.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Zobrazit hodnocení a recenze předložené uživateli.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Zobrazit kritické hodnocení a recenze.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Ukrývejte hodnocení a recenze.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Upřednostňuje zvukové stopy v tomto jazyce, když server nebo přehrávač automaticky vybere stopu.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Doporučuje se sledovat podtituly v tomto jazyce, když jsou subtituly automaticky vybrány.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Vyberte, zda jsou SDH captions preferovány nebo požadovány během automatického výběru podtitulů.',
			'accountPreferences.forcedSubtitleDescription' => 'Vyberte si, zda jsou při automatickém výběru preferovány nebo požadovány nucené podtitulové stopy.',
			'accountPreferences.watchedIndicatorDescription' => 'Vyberte, které typy médií obdrží sledovanou kontrolu v rozhraní serveru.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Vyberte, které publikum a kritické hodnocení server zobrazuje na stránkách médií.',
			'accountPreferences.subtitleModeDescription' => 'Vyberte, kdy se podtituly automaticky zapnou pro tento serverový účet.',
			'accountPreferences.hubDescription' => 'Tyto preference jsou uloženy na vašem účtu mediálního serveru a mohou se vztahovat i na ostatní klienty.',
			'discover.title' => 'Objevovat',
			'discover.noContentAvailable' => 'Žádný obsah k dispozici',
			'discover.addMediaToLibraries' => 'Přidejte nějaké média do knihoven',
			'discover.continueWatching' => 'Pokračovat ve sledování',
			'discover.continueWatchingIn' => ({required Object library}) => 'Podívejte se na stránku ${library}',
			'discover.nextUp' => 'Další díly',
			'discover.nextUpIn' => ({required Object library}) => 'Předchozí Článek ${library}',
			'discover.recentlyAdded' => 'Nedávno přidáno',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Nedávno přidáno v ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Nejnovější album v ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Nedávno přehráno v knihovně ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Nejvíce hrají v ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Přehled',
			'discover.cast' => 'Castová',
			'discover.findNext.title' => 'Najděte si něco dalšího',
			'discover.findNext.open' => 'Najděte si něco dalšího',
			'discover.findNext.anyTime' => 'Libovolně dlouho',
			'discover.findNext.timeAvailable' => 'Kolik máte času?',
			'discover.findNext.filters' => 'Vyberte si pro tuto chvíli',
			'discover.findNext.watch' => 'Sledovat',
			'discover.findNext.listen' => 'Poslouchat',
			'discover.findNext.read' => 'Číst',
			'discover.findNext.finishable' => ({required Object duration}) => 'Doba do dokončení: ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Přibližná délka: ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Další kapitola · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Celkem ${duration}',
			'discover.findNext.timingVaries' => 'Délka se může lišit',
			'discover.findNext.notNow' => 'Teď ne',
			'discover.findNext.swipeHint' => 'Posuňte obal směrem k šipce nebo použijte tlačítka níže.',
			'discover.findNext.saved' => 'Uložené tipy',
			'discover.findNext.savedCount' => ({required Object count}) => 'Uložené tipy · ${count}',
			'discover.findNext.undo' => 'Zpět',
			'discover.findNext.details' => 'Podrobnosti',
			'discover.findNext.noPicks' => 'Zatím není z čeho vybírat',
			'discover.findNext.noPicksHint' => 'Začněte připojením knihovny nebo přidáním zdroje médií.',
			'discover.findNext.noMatches' => 'Pro tuto chvíli nic nevyhovuje',
			'discover.findNext.noMatchesHint' => 'Zkuste jiný druh médií nebo si vyhraďte více času.',
			'discover.findNext.allDone' => 'Prošli jste všechny tipy',
			'discover.findNext.allDoneHint' => 'Vytvořte nový výběr a zobrazte si tyto tipy znovu.',
			'discover.findNext.refresh' => 'Najít další výběr',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Ze zdroje ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Z knihovny ${library}',
			'discover.findNext.ownedReason' => 'Z vaší knihovny',
			'discover.findNext.liveNow' => 'Právě se vysílá',
			'discover.findNext.watchLive' => 'Sledovat živě',
			'discover.findNext.filterAnything' => 'Cokoli',
			'discover.findNext.filterWatch' => 'Sledovat',
			'discover.findNext.filterListen' => 'Poslouchat',
			'discover.findNext.filterRead' => 'Číst',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Použít',
			'discover.findNext.openFailed' => 'Tato položka už není dostupná. Obnovte výběr a zkontrolujte to znovu.',
			'discover.findNext.changeFailed' => 'Změnu se nepodařilo uložit. Zkuste to znovu.',
			'discover.findNext.savedLimit' => 'Seznam uložených tipů je plný. Odeberte jeden tip, abyste mohli uložit další.',
			'discover.findNext.chooseHint' => 'Otevřete titul, uložte si ho na později nebo ho přeskočte.',
			'discover.findNext.howItWorks' => 'Jak to funguje',
			'discover.findNext.notNowHelp' => 'Tento titul zatím přeskočíte. Zůstane ve vaší knihovně.',
			'discover.findNext.saveHelp' => 'Uložte ho mezi uložené tipy tohoto profilu na tomto zařízení. Uložení titul nestáhne.',
			'discover.findNext.openHelp' => 'Výběrem obalu zobrazíte podrobnosti. Hlavní akcí můžete titul přehrát, číst nebo otevřít.',
			'discover.findNext.controlsHelp' => 'Klávesnice nebo ovladač: vyberte tlačítko a stiskněte Enter nebo Vybrat. Zpět obnoví poslední volbu.',
			'discover.findNext.artworkLoading' => 'Načítání obrázku…',
			'discover.findNext.artworkUnavailable' => 'Obrázek není k dispozici',
			'discover.findNext.savedFeedback' => 'Přidáno mezi uložené tipy',
			'discover.findNext.skippedFeedback' => 'Zatím přeskočeno',
			'discover.findNext.releaseToConfirm' => 'Uvolněním potvrďte',
			'discover.findNext.remoteHint' => 'Vybraný obal: ← / → volba · Vybrat: podrobnosti · ↑ / ↓ přesun výběru',
			'discover.extras' => 'Trailery a extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Hodnocení',
			'discover.director' => 'Režisér',
			'discover.directors' => 'Režiséři',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV show',
			'discover.minutesLeft' => ({required Object minutes}) => 'Zbývá ${minutes} min',
			'discover.moreLikeThis' => 'Podobné položky',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titul', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} tituly', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titulu', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} titulů', ), 
			'discover.person.born' => 'narození',
			'discover.person.died' => 'Zemřel',
			'discover.person.birthplace' => 'Místo narození',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (ve věku ${age})',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (stár ${age})',
			'errors.searchFailed' => ({required Object error}) => 'Vyhledávání selhalo: ${error}',
			'errors.searchUnavailable' => 'Vyhledávání se nedá dostat na žádný mediální server.',
			'errors.connectionTimeout' => ({required Object context}) => 'Připojení do času při nabíjení ${context}',
			'errors.connectionFailed' => 'Neschopnost připojit se k mediálnímu serveru',
			'errors.unableToLoad' => ({required Object context}) => 'Není možné nabíjet ${context}. prosím zkuste znovu.',
			'errors.noClientAvailable' => 'Žádný zákazník k dispozici',
			'errors.pleaseEnterToken' => 'Vložte prosím token',
			'errors.invalidToken' => 'Invalidní token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Neuvěřený token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Přepínání na ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Neuspěl odstranit ${displayName}',
			'errors.failedToRate' => 'Nemůžu aktualizovat rating',
			'errors.reasonTimedOut' => 'Připojení je vyprázdněno',
			'errors.reasonUnreachable' => 'server nemůže být přístupný',
			'errors.reasonRefused' => 'server odmítl žádost',
			'errors.reasonNotFound' => 'Už není na serveru.',
			'errors.reasonServerError' => 'server oznámil chybu',
			'errors.reasonCancelled' => 'Žádost byla zrušena',
			'errors.reasonUnexpected' => 'Nečekaná chyba se stala',
			'libraries.playRandomMovie' => 'Zahrajte si náhodný film',
			'libraries.randomPickFailed' => 'Nemohla bych si vybrat náhodný film z této knihovny.',
			'libraries.title' => 'Knihovny',
			'libraries.fallbackTitle' => 'Knihovna',
			'libraries.scanLibraryFiles' => 'Scan knihovny souborů',
			'libraries.scanLibrary' => 'Skenovat knihovnu',
			'libraries.analyze' => 'Analýza',
			'libraries.analyzeLibrary' => 'Analýza knihovny',
			'libraries.refreshMetadata' => 'Aktualizovat metadata',
			'libraries.emptyTrash' => 'prázdný trash',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vybavení odpadků pro "${title}..."',
			'libraries.trashEmptied' => ({required Object title}) => 'Zpět na téma „${title}“',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Nepodařilo se prázdné odpadky: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Zpět na téma „${title}“',
			'libraries.analysisStarted' => ({required Object title}) => 'Analýza začala pro "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Neuspěl analyzovat knihovnu: ${error}',
			'libraries.noLibrariesFound' => 'Žádné knihovny nenajdete',
			'libraries.allLibrariesHidden' => 'Všechny knihovny jsou skryté',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Skryté knihovny (${count})',
			'libraries.thisLibraryIsEmpty' => 'Tato knihovna je prázdná',
			'libraries.noItemsMatchFilters' => 'Žádné položky se neshodují s aktivními filtry',
			'libraries.resetFilters' => 'Vymazat filtry',
			'libraries.all' => 'Vše',
			'libraries.clearAll' => 'Jasné vše',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Jste si jisti, že chcete skenovat "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Jste si jisti, že chcete analyzovat "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Jste si jisti, že chcete aktualizovat metadata pro "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Jste si jisti, že chcete prázdný odpad pro "${title}"?',
			'libraries.manageLibraries' => 'Řízení knihoven',
			'libraries.sort' => 'Třídit',
			'libraries.sortBy' => 'Třídit dle',
			'libraries.filters' => 'Filtry',
			'libraries.confirmActionMessage' => 'Jste si jisti, že chcete tuto akci provést?',
			'libraries.showLibrary' => 'Zobrazit knihovnu',
			'libraries.hideLibrary' => 'Skryté knihovny',
			'libraries.libraryOptions' => 'Možnosti knihovny',
			'libraries.content' => 'Obsah knihovny',
			'libraries.selectLibrary' => 'Vyberte knihovnu',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtry (${count})',
			'libraries.noRecommendations' => 'Žádné doporučení k dispozici',
			'libraries.noCollections' => 'Žádné sbírky v této knihovně',
			'libraries.noFoldersFound' => 'Žádné složky nenajdete',
			'libraries.folders' => 'Složky',
			'libraries.tabs.recommended' => 'Doporučené',
			'libraries.tabs.browse' => 'Procházet',
			'libraries.tabs.collections' => 'Kolekce',
			'libraries.tabs.playlists' => 'Seznamy skladeb',
			'libraries.groupings.title' => 'Skupinování',
			'libraries.groupings.all' => 'Vše',
			'libraries.groupings.movies' => 'Filmy',
			'libraries.groupings.shows' => 'Seriály',
			'libraries.groupings.seasons' => 'Série',
			'libraries.groupings.episodes' => 'Epizody',
			'libraries.groupings.artists' => 'Interpreti',
			'libraries.groupings.albums' => 'Alba',
			'libraries.groupings.tracks' => 'Stopy',
			'libraries.groupings.folders' => 'Složky',
			'libraries.filterCategories.genre' => 'Žánr',
			'libraries.filterCategories.year' => 'Rok',
			'libraries.filterCategories.contentRating' => 'Hodnocení obsahu',
			'libraries.filterCategories.tag' => 'Štítek',
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.unwatched' => 'Nepřehlédnutí',
			'libraries.filterCategories.unplayed' => 'Nepřehrané',
			'libraries.filterCategories.favorites' => 'Oblíbené',
			'libraries.filterCategories.filePath' => 'Cesta k souboru',
			'libraries.sortLabels.title' => 'Název',
			'libraries.sortLabels.dateAdded' => 'Datum přidání',
			'libraries.sortLabels.releaseDate' => 'Datum vydání',
			'libraries.sortLabels.rating' => 'Hodnocení',
			'libraries.sortLabels.communityRating' => 'Hodnocení komunity',
			'libraries.sortLabels.criticRating' => 'Kritické hodnocení',
			'libraries.sortLabels.userRating' => 'Uživatelská hodnocení',
			'libraries.sortLabels.datePlayed' => 'Datum přehrání',
			'libraries.sortLabels.playCount' => 'Počet přehrání',
			'libraries.sortLabels.productionYear' => 'Výroční rok',
			'libraries.sortLabels.runtime' => 'Délka',
			'libraries.sortLabels.officialRating' => 'Oficiální rating',
			'libraries.sortLabels.premiereDate' => 'Datum premiéry',
			'libraries.sortLabels.startDate' => 'Start datum',
			'libraries.sortLabels.airTime' => 'Čas vysílání',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Náhodně',
			'libraries.sortLabels.dateShared' => 'Datum sdílené',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Poslední epizoda Air Date',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Poslední epizoda Datum přidáno',
			'libraries.sortLabels.dateDownloaded' => 'Datum stáhnout',
			'libraries.sortLabels.size' => 'Velikost',
			'libraries.sortLabels.library' => 'Knihovna',
			'libraries.advancedFilters.include' => 'zahrnuje',
			'libraries.advancedFilters.exclude' => 'vyloučení',
			'libraries.advancedFilters.any' => 'jakýkoliv',
			'libraries.advancedFilters.yes' => 'Ano',
			'libraries.advancedFilters.no' => 'Ne',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Nejen ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} vybráno',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} vyloučeno',
			'libraries.advancedFilters.searchValues' => 'Hledací hodnoty',
			'libraries.advancedFilters.noValues' => 'Žádné hodnoty',
			'libraries.advancedFilters.matchContains' => 'Obsah',
			'libraries.advancedFilters.matchNotContains' => 'Neobsahuje',
			'libraries.advancedFilters.matchIs' => 'Je to',
			'libraries.advancedFilters.matchIsNot' => 'Není',
			'libraries.advancedFilters.matchBeginsWith' => 'Začíná s',
			'libraries.advancedFilters.matchEndsWith' => 'Končí s',
			'libraries.advancedFilters.textHint' => 'Typ do zápasu',
			'libraries.advancedFilters.from' => 'od',
			'libraries.advancedFilters.to' => 'na',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} až ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} a výše',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'až ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Poslední ${count} dní',
			'libraries.advancedFilters.dateLastYear' => 'Minulý rok',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'starší než ${count} dní',
			'libraries.advancedFilters.dateOlderThanYear' => 'starší než rok',
			'libraries.selection.selectItems' => 'Vyberte položky',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} vybráno',
			'libraries.selection.actions' => 'Výběr akcí',
			'libraries.selection.confirmDescendants' => 'To se mění všechny epizody ve vybraných show a sezónách.',
			'libraries.selection.confirmUnwatched' => 'Tím se také vymaže průběh přehrávání vybraných položek.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Vybrané položky: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Aktualizované položky: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Aktualizováno ${succeeded}; selhaly ${failed}. selhaly položky zůstávají vybrány.',
			'about.title' => 'o',
			'about.openSourceLicenses' => 'Licence Open Source',
			'about.versionLabel' => ({required Object version}) => 'Zpětná verze ${version}',
			'about.appDescription' => 'Krásný klient Plex, Jellyfin a Emby pro Flutter',
			'about.viewLicensesDescription' => 'Zobrazit licence knihoven třetích stran',
			'about.privacyPolicy' => 'Politika soukromí',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Žádné servery nalezeny pro ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Neschopné nabíjet servery: ${error}',
			'serverSelection.noValidServers' => 'Na tomto účtu nebyly nalezeny žádné použitelné servery',
			'hubDetail.title' => 'Název',
			'hubDetail.releaseYear' => 'Roku uvolnění',
			'hubDetail.dateAdded' => 'Datum přidání',
			'hubDetail.rating' => 'Hodnocení',
			'hubDetail.noItemsFound' => 'Žádné položky nenajdete',
			'logs.clearLogs' => 'Čistý log',
			'logs.copyLogs' => 'Kopírování logů',
			'logs.uploadLogs' => 'Přihlašování logů',
			'logs.saveLogs' => 'Shromažďujte záznamy do souboru',
			'logs.logsSaved' => ({required Object path}) => 'Přihlášky uložené na ${path}',
			'logs.saveLogsFailed' => 'Nemohla jsem uložit soubor.',
			'startup.failedTitle' => 'PlezyNG nemohl začít',
			'startup.failedBody' => 'Něco se během start-upu zhroutilo. podrobnosti níže identifikují to, co selžilo.',
			'startup.failedBodyRepairable' => 'Uložený soubor nastavení PlezyNG je poškozený a před spuštěním aplikace je nutné jej znovu vytvořit. Další pokus nepomůže — zvolte opravu úložiště.',
			'startup.phaseLabel' => 'Krok',
			'startup.showDetails' => 'Zobrazit detaily',
			'startup.hideDetails' => 'skryte detaily',
			'startup.copyDetails' => 'Kopírování detailů',
			'startup.detailsCopied' => 'Podrobnosti kopírovány na clipboard',
			'startup.uploadDetails' => 'Upload podrobnosti',
			'startup.repairStorage' => 'Oprava skladování',
			'startup.repairTitle' => 'Opravy uložených dat?',
			'startup.repairBodyCommon' => 'Soubor nastavení PlezyNG je poškozen a nelze ho přečíst. opravy obnoví každé nastavení na své výchozí.',
			'startup.repairBodyOneCredential' => 'Jeden uložený sign-in je poškozen a nemůže být přečten. opravy odstraní pouze ten jeden; vaše ostatní nastavení jsou ponechány samy.',
			'startup.repairBodySignInsKept' => 'Přihlášení k vašim serverům a profilům by mělo zůstat zachováno.',
			'startup.repairBodySignInsLost' => 'Klíč chránící uložené přihlašovací údaje nelze z tohoto souboru obnovit, takže se budete muset znovu přihlásit ke každému serveru a profilu. Na mediálním serveru se nic nezmění.',
			'startup.repairBodySessionsUncertain' => 'Údaje služeb MAL, AniList, Simkl, Trakt a Seerr se ukládají samostatně a mohou, ale nemusí zůstat zachovány. PlezyNG vám přesně sdělí, co zachovalo.',
			'startup.repairConfirm' => 'Opravy',
			'startup.repairSucceeded' => 'Úložné opravy',
			'startup.repairNeedsRestart' => 'Uložení opravené – nutné restartování',
			'startup.restartRequiredBody' => 'Vaše data byla opravena, ale PlezyNG je může použít až po novém spuštění. Zavřete PlezyNG a znovu jej otevřete.',
			'startup.quitPlezy' => 'Zpět PlezyNG',
			'startup.repairFailed' => 'Oprava selhala',
			'startup.repairKeptSignIns' => 'K serverům a profilům jste stále přihlášeni.',
			'startup.repairLostSignIns' => 'Klíč chránící uložené přihlašovací údaje se nepodařilo obnovit. Budete se muset znovu přihlásit ke každému serveru a profilu.',
			'startup.repairLostSessions' => 'Nejméně jeden tracker nebo spojení Seerr bylo ztraceno a musí být znovu připojeno.',
			'startup.backupTitle' => 'Kopie poškozeného souboru byla zachována',
			'startup.backupWarning' => 'Obsahuje vaše přihlašovací údaje. Nenahrávejte ji ani ji nesdílejte.',
			'startup.deleteBackup' => 'Vymazat kopii',
			'startup.backupDeleted' => 'Kopie je vymazána.',
			'startup.previousFailureTitle' => 'PlezyNG neuspěl naposledy',
			'licenses.relatedPackages' => 'související balíčky',
			'licenses.license' => 'Licence',
			'licenses.licenseNumber' => ({required Object number}) => 'Licence ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencí',
			'navigation.libraries' => 'Knihovny',
			'navigation.downloads' => 'Stažené soubory',
			'navigation.liveTv' => 'Živé vysílání',
			'navigation.explore' => 'Prozkoumejte',
			'explore.mdblistShelves.manage' => 'Řízení průzkumných schodů',
			'explore.mdblistShelves.manageDescription' => 'Vyberte si a uspořádat seznamy z vašeho účtu MDBList',
			'explore.mdblistShelves.description' => 'Vyberte si veřejné filmy a televizní seznamy z účtu MDBList. Vytvořte nebo kopírujte seznamy na MDBList, pak aktualizujte.',
			'explore.mdblistShelves.selected' => 'vybrané podlahy',
			'explore.mdblistShelves.available' => 'Dostupné účetní listy',
			'explore.mdblistShelves.noLists' => 'Žádné veřejné filmy nebo televizní seznamy se nevrátily. Vytvořte nebo kopírujte seznam na MDBList, pak aktualizujte.',
			'explore.mdblistShelves.displayName' => 'Shelf název',
			'explore.mdblistShelves.nameHint' => 'Zanechte pryč, abyste použili název zdrojového seznamu.',
			'explore.mdblistShelves.add' => 'Přidejte shelf',
			'explore.mdblistShelves.save' => 'Záchranářská schůzka',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Přesun ${title} nahoru',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Stáhnout ${title} dolů',
			'explore.mdblistShelves.unavailable' => 'Tento seznam není k dispozici. Odstranit nebo odstranit jeho šálek v nastavení.',
			'explore.mdblistShelves.rateLimited' => 'Byl dosažen limit požadavků MDBList. Zkuste to později.',
			'explore.mdblistShelves.loadFailed' => 'Nemůžete nabíjet police. zkontrolujte připojení a odpočinek.',
			'explore.mdblistShelves.saveFailed' => 'Nemohla jsem se zeptat.Prosím se vzpamatovat.',
			'explore.mdblistShelves.accountChanged' => 'Účet nebo profil se změnil. znovu otevřete tyto nastavení.',
			'explore.mdblistShelves.settingsUnreadable' => 'Ušetřené police se nemohou přečíst. Vyberte své seznamy znovu, abyste nahradili tyto nastavení.',
			'explore.title' => 'Prozkoumejte',
			'explore.selectSource' => 'Vyberte zdroj',
			'explore.rows.watchlist' => 'sledovací seznam',
			'explore.rows.recommendedMovies' => 'Doporučené filmy',
			'explore.rows.recommendedShows' => 'Doporučené show',
			'explore.rows.trendingMovies' => 'Trendy filmů',
			'explore.rows.trendingShows' => 'Trendové show',
			'explore.rows.popularMovies' => 'Populární filmy',
			'explore.rows.popularShows' => 'Populární show',
			'explore.rows.trendingAnime' => 'Trendy Anime',
			'explore.rows.suggestedAnime' => 'Doporučené anime',
			'explore.rows.airingAnime' => 'Nejlepší Airing Anime',
			'explore.rows.popularAnime' => 'Nejpopulárnější anime',
			'explore.rows.trending' => 'Trendy',
			'explore.rows.upcomingMovies' => 'Nadcházející filmy',
			'explore.rows.upcomingShows' => 'Předchozí představení',
			'explore.status.airing' => 'vzduch',
			'explore.status.ended' => 'Ukončeno',
			'explore.status.canceled' => 'Zrušený',
			'explore.status.upcoming' => 'Nadcházející',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizoda', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizody', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} epizod', ), 
			'explore.cast' => 'Castová',
			'explore.characters' => 'Charaktery',
			'explore.addToWatchlist' => 'Přidejte na Watchlist',
			'explore.removeFromWatchlist' => 'Odstranit z Watchlist',
			'explore.addedToWatchlist' => 'Přidáno na watchlist',
			'explore.removedFromWatchlist' => 'Odstranění z watchlist',
			'explore.watchlistUpdateFailed' => 'Nemůžu aktualizovat watchlist',
			'explore.watchlistNoMatch' => 'Nemohla by se tento položka shodovat s seznamem pozorovatelů',
			'explore.notInLibrary' => 'Ne v knihovně',
			'explore.inTheseLibraries' => 'V těchto knihovnách',
			'explore.checkingLibrary' => 'Zkontrolujte svou knihovnu...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Nemůžu ověřit server ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: 'Nemohla jsem ověřit servery ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', ), 
			'explore.emptyTitle' => 'Nic zde zatím',
			'explore.emptyMessage' => ({required Object source}) => 'Čerpadla z ${source} se zde objeví, jakmile mají obsah.',
			'explore.searchHint' => ({required Object source}) => 'Vyhledávání ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Žádné výsledky pro "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Hledat filmy a představení na ${source}.',
			'explore.searchFailed' => 'Vyhledávání selhalo. zkontrolujte připojení a zkuste znovu.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populární',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} vzduch',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} hodnoceno',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} trendování',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} v ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} sledování',
			'explore.badge.available' => 'Dostupné',
			'explore.badge.partiallyAvailable' => 'Částečně k dispozici',
			'explore.badge.availableIn4k' => '4K k dispozici',
			'explore.badge.requested' => 'požadované',
			'explore.badge.pendingApproval' => 'Čekající schválení',
			'explore.badge.processing' => 'zpracování',
			'explore.badge.declined' => 'zkreslené',
			'explore.badge.requestFailed' => 'Žádost selhala',
			'explore.badge.requested4k' => '4K požadováno',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} sezóny',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} v ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Další v ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep.',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} Zprávy',
			'explore.stats.viewersDay' => ({required Object n}) => 'Dnes sledovalo: ${n}',
			'explore.stats.viewersWeek' => ({required Object n}) => 'Tento týden sledovalo: ${n}',
			'explore.stats.viewersMonth' => ({required Object n}) => 'Tento měsíc sledovalo: ${n}',
			'explore.stats.viewersYear' => ({required Object n}) => 'Tento rok sledovalo: ${n}',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} diváků',
			'explore.stats.planning' => ({required Object n}) => '${n} Plánování sledovat',
			'explore.stats.favorited' => ({required Object n}) => '${n} oblíbené',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} se to podařilo',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentář', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentáře', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentáře', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} komentářů', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} hlasů',
			'explore.stats.watching' => ({required Object n}) => 'Právě sleduje: ${n}',
			'explore.stats.completed' => ({required Object n}) => '${n} dokončeno',
			'explore.stats.onHold' => ({required Object n}) => '${n} na držení',
			'explore.stats.dropped' => ({required Object n}) => '${n} zrušeno',
			'explore.season.winter' => 'Zima',
			'explore.season.spring' => 'Jarní',
			'explore.season.summer' => 'Léto',
			'explore.season.fall' => 'Pád',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'televize',
			'explore.format.tvShort' => 'TV krátký',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Speciální',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Hudba',
			'explore.format.other' => 'Ostatní',
			'explore.sourceMaterial.original' => 'originál',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Světelný román',
			'explore.sourceMaterial.novel' => 'Román',
			'explore.sourceMaterial.visualNovel' => 'Vizuální román',
			'explore.sourceMaterial.game' => 'Hračky',
			'explore.sourceMaterial.webComic' => 'Webové komiksy',
			'explore.sourceMaterial.musicRelease' => 'Hudba',
			'explore.sourceMaterial.otherMedia' => 'Ostatní',
			'explore.creditRole.actor' => 'Herec',
			'explore.creditRole.director' => 'Režisér',
			'explore.creditRole.writer' => 'Scénárista',
			'explore.creditRole.producer' => 'Producent',
			'explore.creditRole.creator' => 'Tvůrce',
			'explore.creditRole.composer' => 'Skladatel',
			'explore.relation.prequel' => 'Předpověď',
			'explore.relation.sequel' => 'Sekundární',
			'explore.relation.sideStory' => 'Strana příběhu',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternativní verze',
			'explore.relation.summary' => 'Shrnutí',
			'explore.relation.parentStory' => 'Příběh rodičů',
			'explore.relation.adaptation' => 'Přizpůsobení',
			'explore.relation.other' => 'související',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Airs ${day} na ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Airs ${day} na ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Originální název',
			'explore.detail.alsoKnownAs' => 'Také známý jako',
			'explore.detail.studios' => 'Studia',
			'explore.detail.country' => 'Země',
			'explore.detail.language' => 'Jazyk',
			'explore.detail.released' => 'uvolněné',
			'explore.detail.physicalRelease' => 'na disku',
			'explore.detail.ended' => 'Ukončeno',
			'explore.detail.addedOn' => ({required Object date}) => 'Přidat ${date}',
			'explore.detail.yourRating' => 'Váš rating',
			'explore.detail.budget' => 'Rozpočet',
			'explore.detail.revenue' => 'Boxovní kancelář',
			'explore.detail.contentAdvisory' => 'Věkové vedení',
			'explore.detail.tags' => 'Štítky',
			'explore.detail.revealSpoilerTags' => 'Zobrazit spoiler tags',
			'explore.detail.links' => 'Levice',
			'explore.detail.watchOn' => 'Podívejte se',
			'explore.detail.watchTrailer' => 'Podívejte se trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Otevřeno na ${site}',
			'explore.detail.crew' => 'Posádka',
			'explore.detail.ratings' => 'Hodnocení',
			'explore.detail.schedule' => 'Plánované nahrávání',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Doporučeno uživatelem ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)}', other: 'Doporučená ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} uživatelů', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Doporučeno od ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Oblíbeno ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ještě není zobrazeno',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Doporučeno ${percent} diváků',
			'explore.detail.relatedTitles' => 'Související tituly',
			'explore.detail.background' => 'pozadí',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledek', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledky', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledku', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} výsledků', ), 
			'liveTv.title' => 'Živé vysílání',
			'liveTv.guide' => 'Programový průvodce',
			'liveTv.noChannels' => 'Žádné dostupné kanály',
			'liveTv.noDvr' => 'Žádný DVR na serveru není nastaven',
			'liveTv.serverUnavailable' => 'Live TV server není k dispozici.',
			'liveTv.serverNotConnected' => 'Live TV server není připojen.',
			'liveTv.noPrograms' => 'Žádné dostupné programové údaje',
			'liveTv.liveStreamFailed' => 'Live Stream neúspěšný',
			'liveTv.unknownProgram' => 'Neznámý program',
			'liveTv.timelineLiveProgram' => 'Live program (playback může být mimo tento program)',
			'liveTv.timelineBuffer' => 'Buffer časový řádek',
			'liveTv.timelineUnavailable' => 'Časová linka nedostupná',
			'liveTv.timelineEstimated' => 'Hodnocení playback',
			'liveTv.timelinePending' => 'Hledání',
			'liveTv.timelineStale' => 'Schéma může být zastaralá',
			'liveTv.unknownHub' => 'Neznámý',
			'liveTv.unknownError' => 'Neznámá chyba',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanál ${number}',
			'liveTv.unknownChannel' => 'Neznámý kanál',
			'liveTv.live' => 'Živě',
			'liveTv.premiereBadge' => 'Nový',
			'liveTv.reloadGuide' => 'Reload průvodce',
			'liveTv.searchGuide' => 'Vyhledávací průvodce',
			'liveTv.searchHint' => 'Vyhledávací kanály a programy',
			'liveTv.searchNoResults' => ({required Object query}) => 'Žádné zápasy pro "${query}"',
			'liveTv.channelsSection' => 'Kanály',
			'liveTv.programsSection' => 'Programy',
			'liveTv.now' => 'Nyní',
			'liveTv.today' => 'Dneska',
			'liveTv.tomorrow' => 'Zítra',
			'liveTv.midnight' => 'půlnoci',
			'liveTv.overnight' => 'Večerní',
			'liveTv.morning' => 'Ráno',
			'liveTv.daytime' => 'Dnešní čas',
			'liveTv.evening' => 'Večerní',
			'liveTv.lateNight' => 'Pozdní noc',
			'liveTv.whatsOn' => 'Co je na',
			'liveTv.watchChannel' => 'Podívejte se na Channel',
			'liveTv.favorites' => 'Oblíbené',
			'liveTv.reorderFavorites' => 'Oblíbené Reader',
			'liveTv.noFavoriteChannels' => 'Žádné oblíbené kanály',
			'liveTv.noFavoriteChannelsHint' => 'Zobrazit všechny kanály, pak dlouhodobě stiskněte kanál, aby ho přidali k vašim oblíbeným.',
			'liveTv.showAllChannels' => 'Zobrazit všechny kanály',
			'liveTv.favoritesLoadFailed' => 'Nemůžete si stáhnout oblíbené. zkontrolujte připojení a zkuste znovu.',
			'liveTv.favoritesUpdateFailed' => 'Nemůžete aktualizovat oblíbené. zkontrolujte připojení a zkuste znovu.',
			'liveTv.joinSession' => 'Připojte se k setkání v pokroku',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Sledovat od začátku (před ${minutes} min)',
			'liveTv.watchLive' => 'Podívejte se živě',
			'liveTv.goToLive' => 'Jděte žít',
			'liveTv.record' => 'Záznam',
			'liveTv.recordEpisode' => 'Rekordní epizoda',
			'liveTv.recordSeries' => 'Nahrát série',
			'liveTv.recordOptions' => 'Rekordní možnosti',
			'liveTv.saveTo' => 'Zachraňte na',
			'liveTv.recordings' => 'Nahrávky',
			'liveTv.scheduledRecordings' => 'plánované',
			'liveTv.recordingRules' => 'Pravidla nahrávání',
			'liveTv.noScheduledRecordings' => 'Nic není naplánováno k nahrávání',
			'liveTv.manageRecording' => 'Spravovat nahrávání',
			'liveTv.cancelRecording' => 'Zrušit nahrávání',
			'liveTv.cancelRecordingTitle' => 'Zrušit tuto nahrávku?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} již nebude zaznamenán.',
			'liveTv.deleteRule' => 'Odstranit pravidlo',
			'liveTv.deleteRuleTitle' => 'Zrušíte pravidlo nahrávání?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Budoucí epizody čísla ${title} nebudou zaznamenány.',
			'liveTv.recordingScheduled' => 'Plán nahrávání.',
			'liveTv.alreadyScheduled' => 'Tento program je již naplánován',
			'liveTv.dvrAdminRequired' => 'Nastavení DVR vyžaduje účet administrátora',
			'liveTv.recordingFailed' => 'Nemohla jsem plánovat nahrávání',
			'liveTv.recordingTargetMissing' => 'Nemohla jsem si vybrat knihovnu',
			'liveTv.recordNotAvailable' => 'Záznam není k dispozici pro tento program',
			'liveTv.recordingCancelled' => 'Záznam zrušen',
			'liveTv.recordingRuleDeleted' => 'Pravidlo nahrávání vymazáno',
			'liveTv.processRecordingRules' => 'Znovu hodnocená pravidla',
			'liveTv.recordingInProgress' => 'nahrávka nyní',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} předpověď',
			'liveTv.editRule' => 'Edit pravidla',
			'liveTv.editRuleAction' => 'Upravit',
			'liveTv.recordingRuleUpdated' => 'Pravidla nahrávání aktualizována',
			'liveTv.guideReloadRequested' => 'Návod k obnovení požadovaný',
			'liveTv.guideReloadFailed' => 'Nemohla jsem si přečíst průvodce',
			'liveTv.rulesProcessRequested' => 'Pravidla přehodnocení požadovaná',
			'liveTv.rulesProcessFailed' => 'Nemohla bych přehodnotit pravidla nahrávání',
			'liveTv.recordShow' => 'Rekordní show',
			'liveTv.recordSettings.startEarly' => 'Začínáme brzy (sekundy)',
			'liveTv.recordSettings.endLate' => 'Konec pozdě (sekundy)',
			'liveTv.recordSettings.newOnly' => 'Pouze nové epizody',
			'liveTv.recordSettings.anyChannel' => 'Záznam na jakémkoliv kanálu',
			'liveTv.recordSettings.anyTime' => 'Záznam v každém okamžiku',
			'liveTv.recordSettings.skipInLibrary' => 'Skok epizod již v knihovně',
			'liveTv.recordSettings.keepUpTo' => 'epizody, které se musí udržet',
			'liveTv.recordSettings.keepUpToHint' => '0 zachovává každou epizodu',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Začátek v ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} na ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} vrátil neplatné Live TV přehrávače data',
			'liveTv.failedToStartChannel' => 'Nemohla jsem zahájit živý kanál',
			'liveTv.failedToBuildStreamUrl' => 'Nemohl jsem vytvořit stream URL',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Nemohla jsem spustit kanál: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Nemohla by se přepínat kanál: ${reason}',
			'collections.title' => 'Kolekce',
			'collections.collection' => 'Kolekce',
			'collections.empty' => 'Kolekce je prázdná',
			'collections.deleteCollection' => 'Odstranit kolekci',
			'collections.deleteConfirm' => ({required Object title}) => 'Smazat „${title}“? Tuto akci nelze vrátit zpět.',
			'collections.deleted' => 'Kolekce odstraněna',
			'collections.deleteFailed' => 'Neschopnost odstranit sbírku',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Neschopné odstranit sbírku: ${error}',
			'collections.selectCollection' => 'Vyberte kolekci',
			'collections.collectionName' => 'Název kolekce',
			'collections.enterCollectionName' => 'Vložte název kolekce',
			'collections.addedToCollection' => 'Přidáno do sbírky',
			'collections.errorAddingToCollection' => 'Nedokázal přidat do sbírky',
			'collections.created' => 'Sbírka vytvořená',
			'collections.removeFromCollection' => 'Odebrat z kolekce',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Odebrat „${title}“ z této kolekce?',
			'collections.removedFromCollection' => 'Odstranění z kolekce',
			'collections.removeFromCollectionFailed' => 'Neschopnost odstranit ze sbírky',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Odstranění chyb z sběru: ${error}',
			'collections.searchCollections' => 'Vyhledávací sbírky...',
			'playlists.title' => 'Seznamy skladeb',
			'playlists.playlist' => 'Seznam skladeb',
			'playlists.noPlaylists' => 'Žádné playlisty nenajdeme',
			'playlists.create' => 'Vytvořte playlist',
			'playlists.playlistName' => 'Playlist název',
			'playlists.enterPlaylistName' => 'Vložte název playlist',
			'playlists.delete' => 'Odstranit seznam skladeb',
			'playlists.removeItem' => 'Odebrat ze seznam skladeb',
			'playlists.smartPlaylist' => 'Inteligentní playlist',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položka', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položky', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položky', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} položek', ), 
			'playlists.emptyPlaylist' => 'Tento playlist je prázdný',
			'playlists.deleteConfirm' => 'Vymažte si playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Jste si jisti, že chcete odstranit „${name}“?',
			'playlists.created' => 'Playlist vytvořený',
			'playlists.deleted' => 'Playlist vymazané',
			'playlists.itemAdded' => 'Přidáno do playlist',
			'playlists.itemRemoved' => 'Odstranění z playlist',
			'playlists.selectPlaylist' => 'Vyberte Playlist',
			'playlists.searchPlaylists' => 'Vyhledávání playlistů...',
			'playlists.errorCreating' => 'Neudělal si playlist',
			'playlists.errorDeleting' => 'Nepodařilo se vymazat playlist',
			'playlists.errorLoading' => 'Nedokázal přenášet playlisty',
			'playlists.errorAdding' => 'Nedokázal přidat do playlist',
			'playlists.errorReordering' => 'Nedokázal přepracovat položky playlist',
			'playlists.errorRemoving' => 'Neschopnost odstranit z playlist',
			'music.goToAlbum' => 'Přejděte na album',
			'music.goToArtist' => 'Přejděte k umělci',
			'music.instantMix' => 'Rychlý mix',
			'music.playNext' => 'Přehrát jako další',
			'music.addToQueue' => 'Přidejte na kousek',
			'music.discNumber' => ({required Object n}) => 'Disk ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladba', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladby', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladby', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} skladeb', ), 
			'music.nowPlaying' => 'Nyní hrát',
			'music.playingFrom' => ({required Object title}) => 'Hraje se z ${title}',
			'music.queue' => 'Kouč',
			'music.clearQueue' => 'Vymazat frontu',
			'music.lyrics' => 'Texty',
			'music.visualizer' => 'vizualizace',
			'music.visualizerProfileLoading' => 'Přečtěte si analýzu track...',
			'music.visualizerAmbientMotion' => 'Atmosféra pohybu',
			'music.visualizerPlexLoudness' => 'Plex hlasitost',
			'music.visualizerPreviousPreset' => 'Předchozí vizuální styl',
			'music.visualizerNextPreset' => 'Další vizuální styl',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blondýn',
			'music.visualizerPresetOrbitals' => 'Orbitální',
			'music.visualizerPresetPrism' => 'Prismová',
			'music.visualizerPresetTunnel' => 'tunel',
			'music.visualizerPresetTrackMap' => 'Track mapy',
			'music.noLyrics' => 'Žádné texty k dispozici',
			'music.sleepTimer' => 'Časový spánek',
			'music.sleepTimerEndOfTrack' => 'Konec trasy',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuty', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minut', ), 
			'music.stopPlayback' => 'Zastavit přehrávání',
			'music.previousTrack' => 'Předchozí stopa',
			'music.nextTrack' => 'Následující stopa',
			'music.repeat' => 'Opakovat',
			'music.repeatAll' => 'Opakovat vše',
			'music.repeatOne' => 'Opakovat jeden',
			'music.instantMixNoServer' => 'Není k dispozici server pro okamžitou směs',
			'music.instantMixFailed' => 'Nedokázal nahrát okamžitou směs',
			'music.instantMixEmpty' => 'Okamžitý mix se vrátil bez stopy',
			'music.noAudioUrl' => ({required Object track}) => 'Žádný audio URL není k dispozici pro ${track}',
			'music.discography.singlesAndEps' => 'Singles a EPs',
			'music.discography.live' => 'Živě',
			'music.discography.compilations' => 'Kompilace',
			'watchTogether.title' => 'Společné sledování',
			'watchTogether.description' => 'Zobrazit obsah v synchronizaci s přáteli a rodinou',
			'watchTogether.createRoom' => 'Vytvořte místnost',
			'watchTogether.creatingRoom' => 'Vytvoření místnosti...',
			'watchTogether.joinRoom' => 'Připojte se do pokoje',
			'watchTogether.joiningRoom' => 'Připojení do místnosti...',
			'watchTogether.connecting' => 'Připojení...',
			'watchTogether.relayPublic' => 'Pokoje využívají veřejné Open Watch Party relace.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Pokoje používají váš relay na ${url}.',
			'watchTogether.recentRooms' => 'Poslední pokoje',
			'watchTogether.roomActions' => 'Akce v místnosti',
			'watchTogether.renameRoom' => 'Rekonstrukce pokoje',
			'watchTogether.removeRoom' => 'Odstranit',
			'watchTogether.enterRoomCode' => 'Vložte šesti znakový kód z hostitele.',
			'watchTogether.roomCode' => 'Kód místnosti',
			'watchTogether.paste' => 'Vložit',
			'watchTogether.noCodeInClipboard' => 'Klipboard neobsahuje kód místnosti',
			'watchTogether.copyCode' => 'Kopírování kódu',
			'watchTogether.codeCopied' => 'Kód pokoje kopírovaný',
			'watchTogether.shareInvite' => 'Sdílejte pozvání',
			'watchTogether.inviteCopied' => 'Zkuste kopírovat. vložte ji do zprávy.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Připojte se k mým hodinám společně v místnosti PlezyNG: otevřete hodinám společně, vyberte Připojte se k místnosti a zadejte ${code}.',
			'watchTogether.openSessionControls' => 'Otevřete sledování Session Controls',
			'watchTogether.reconnecting' => 'Připojení...',
			'watchTogether.reconnectingDescription' => 'Připojení je zrušené. automaticky se připojíte k místnosti.',
			'watchTogether.connected' => 'připojené',
			'watchTogether.disconnected' => 'Rozpojení',
			'watchTogether.youAreHost' => 'Jste hostitelem',
			'watchTogether.hostedBy' => ({required Object name}) => 'Přihláška ${name}',
			'watchTogether.hostControlsPlayback' => 'Hostingové ovládací prvky Playback',
			'watchTogether.anyoneCanControl' => 'Každý může ovládat playback',
			'watchTogether.roomLocked' => 'Místnost uzavřená',
			'watchTogether.nowPlaying' => 'Nyní hrát',
			'watchTogether.nothingPlaying' => 'Není nic hrát',
			'watchTogether.nothingPlayingHost' => 'Hrajte něco z jakékoliv knihovny a sdílejte to s místností.',
			'watchTogether.nothingPlayingGuest' => 'Když host hraje něco, otevírá se zde.',
			'watchTogether.notShareable' => 'Toto video nemá žádný katalog, takže ho mohou hrát pouze lidé s přístupem na stejný server.',
			'watchTogether.searching' => 'Hledání tohoto videa ve vašich knihovnách...',
			'watchTogether.yourCopy' => 'Vaše kopie',
			'watchTogether.sharingYourCopy' => 'Sdílejte svou kopii',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Přehrávat svou kopii, ${difference}',
			'watchTogether.mismatchTitle' => 'Vaše kopie má jinou délku',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Vaše nejbližší kopie je ${difference} než video v místnosti.',
			'watchTogether.playAnyway' => 'Hrajte jakkoliv',
			'watchTogether.chooseAnotherCopy' => 'Vyberte další kopii',
			'watchTogether.dontPlay' => 'Nehrát si',
			_ => null,
		} ?? switch (path) {
			'watchTogether.unavailableTitle' => 'Nemáte toto video',
			'watchTogether.unavailableDescription' => 'PlezyNG nemohl najít v knihovně. vyberte si kopii sami nebo vyhledejte znovu.',
			'watchTogether.chooseCopy' => 'Vyberte si kopii',
			'watchTogether.searchAgain' => 'Znovu hledat',
			'watchTogether.noCandidates' => 'V knihovně nenajdete žádné kopie.',
			'watchTogether.choiceFailed' => 'Nemohla jsem tuto kopii hrát pro místnost',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} více',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} kratší',
			'watchTogether.lengthSame' => 'Stejná délka',
			'watchTogether.lengthUnknown' => 'Délka neznámá',
			'watchTogether.joinCurrentPlayback' => 'Připojte se k aktuálnímu playbacku',
			'watchTogether.joinCurrentPlaybackDescription' => 'Zpět na to, co hostitel v současné době sleduje',
			'watchTogether.stopMedia' => 'Video pro každého',
			'watchTogether.syncOffset' => 'Synchronizace Offset',
			'watchTogether.syncOffsetDescription' => 'Přesměrujte video, pokud běží před nebo za místností.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Vaše kopie je ${difference} než video v místnosti.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Použití ${offset}',
			'watchTogether.offsetMinusSecond' => '1 s',
			'watchTogether.offsetMinusTenth' => '100 ms',
			'watchTogether.offsetPlusTenth' => '+ 100 ms',
			'watchTogether.offsetPlusSecond' => '+ 1 s',
			'watchTogether.participants' => 'Účastníci',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastník', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníci', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníka', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} účastníků', ), 
			'watchTogether.hostBadge' => 'Host',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (vy jste)',
			'watchTogether.playerIdle' => 'Při neaktivitě',
			'watchTogether.playerLoading' => 'Nabíjení',
			'watchTogether.playerReady' => 'připravený',
			'watchTogether.playerBuffering' => 'Bufferování',
			'watchTogether.matchSearching' => 'Vyhledávání',
			'watchTogether.matchMatched' => 'Má video',
			'watchTogether.matchMismatched' => 'Různé délky',
			'watchTogether.matchUnavailable' => 'Nemáte videa',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Příslušenství ${offset}',
			'watchTogether.makeHost' => 'Udělejte host',
			'watchTogether.makeHostQuestion' => 'Převodový host?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} bude ovládat přehrávání a provozovat sezení pro všechny.',
			'watchTogether.transfer' => 'Převod',
			'watchTogether.removeParticipant' => 'Odstranit z místnosti',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Odstranit ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} opouští místnost. mohou se znovu připojit k kódu, pokud nezapnete místnost.',
			'watchTogether.remove' => 'Odstranit',
			'watchTogether.roomSettings' => 'Nastavení místnosti',
			'watchTogether.letEveryoneControl' => 'Připravte se na Playback',
			'watchTogether.lockRoom' => 'Lockova místnost',
			'watchTogether.lockRoomDescription' => 'Nikdo nový se nemůže připojit',
			'watchTogether.leaveRoom' => 'Zanechat pokoj',
			'watchTogether.leaveRoomQuestion' => 'Zanechat si pokoj?',
			'watchTogether.leaveRoomConfirm' => 'Můžete se opět připojit k kódu místnosti.',
			'watchTogether.leave' => 'Zanechat',
			'watchTogether.endRoom' => 'Konečná místnost',
			'watchTogether.endRoomQuestion' => 'Konečný pokoj ?',
			'watchTogether.endRoomConfirm' => 'To je konec místnosti pro všechny.',
			'watchTogether.end' => 'Konec',
			'watchTogether.playBlockedTitle' => 'Playback se nezačal',
			'watchTogether.playBlockedDescription' => 'Tiskové hry začít sledovat s místností.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} stisknutá hra',
			'watchTogether.notices.playbackStarted' => 'Playback začíná',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} přestávka',
			'watchTogether.notices.playbackPaused' => 'Playback přestávka',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} skok na ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Přihláška na ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} nastavte rychlost na ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Rychlost nastavená na ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} zahájil ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Nyní hrát ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} zastavilo video',
			'watchTogether.notices.mediaStopped' => 'Video se zastavil',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Čekáme na ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Čekání na někoho, kdo se chytí...',
			'watchTogether.notices.finished' => 'dokončená',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} je nyní hostitelem',
			'watchTogether.notices.youAreNowHost' => 'Nyní jste hostitelem',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} připojeno',
			'watchTogether.notices.left' => ({required Object name}) => '${name} pozůstatek',
			'watchTogether.notices.controlRefused' => 'Pouze hostitel může ovládat playback',
			'watchTogether.notices.searchFailed' => 'Některé servery nemohly být vyhledávány pro video místnosti',
			'watchTogether.notices.playBlocked' => 'Tisková hra začíná',
			'watchTogether.notices.shareFailed' => 'Nemohla bych toto video sdílet s místností',
			'watchTogether.notices.downloadNotShared' => 'Stáhnout se s místností nesdílejí, zatímco jejich server je offline',
			'watchTogether.notices.openFailed' => 'Nemohla jsem otevřít videa místnosti',
			'watchTogether.ended.ended' => 'Hostitel končí místnost',
			'watchTogether.ended.kicked' => 'Byli jste odstraněni z místnosti.',
			'watchTogether.ended.expired' => 'Místnost vypršela',
			'watchTogether.ended.replaced' => 'Připojili jste se k této místnosti na jiném zařízení',
			'watchTogether.ended.lost' => 'Ztrácí připojení k místnosti',
			'watchTogether.errors.invalidCode' => 'Kód má 6 písmen a čísel, bez 0, 1, I, L nebo O.',
			'watchTogether.errors.roomNotFound' => 'Žádná místnost nemá tento kód, může to skončit.',
			'watchTogether.errors.roomFull' => 'Tato místnost je plná.',
			'watchTogether.errors.roomLocked' => 'Hostitel tuto místnost uzavřel.',
			'watchTogether.errors.relayFull' => 'Zkuste to už teď, zkuste to ještě jednou.',
			'watchTogether.errors.unreachable' => 'Nemohla jsem se dostat na hodinky Společně relay. zkontrolujte připojení.',
			'watchTogether.errors.rateLimited' => 'Přesně mnoho pokusů. počkejte chvíli a zkuste znovu.',
			'watchTogether.errors.clientBlocked' => 'Tato verze PlezyNG nemůže používat relay. aktualizovat aplikaci.',
			'watchTogether.errors.forbidden' => 'To může udělat pouze hostitel.',
			'watchTogether.errors.notInRoom' => 'Nejste v místnosti.',
			'watchTogether.errors.alreadyInRoom' => 'Už jste v místnosti.',
			'watchTogether.errors.resumeFailed' => 'Nemohla jsem se do místnosti dostat.',
			'watchTogether.errors.unsupported' => 'Tohle relace nepodporuje.',
			'watchTogether.errors.generic' => 'Něco se nehodilo, zkuste to znovu.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Článek ${number}',
			'downloads.title' => 'Stažené soubory',
			'downloads.manage' => 'Řízení',
			'downloads.tvShows' => 'Seriály',
			'downloads.movies' => 'Filmy',
			'downloads.music' => 'Hudba',
			'downloads.tracksQueued' => ({required Object count}) => '${count} stopy ke stažení',
			'downloads.noDownloads' => 'Zatím žádné stahování',
			'downloads.noDownloadsDescription' => 'Stáhnutý obsah se zde objeví pro offline prohlížení',
			'downloads.downloadNow' => 'Stáhnout',
			'downloads.deleteDownload' => 'Odstranit download',
			'downloads.retryDownload' => 'Zpět ke stažení',
			'downloads.downloadQueued' => 'Stažení zařazeno.',
			'downloads.downloadResumed' => 'Stáhnout znovu',
			'downloads.serverErrorBitrate' => 'Serverová chyba: soubor může překročit limit vzdálené bitrate',
			'downloads.storageFull' => 'Stáhnout se zastavil, aby chránil dostupné skladování. Zvolit nějaký prostor nebo si vybrat další místo stahování, pak se vrátit.',
			'downloads.storageUnavailable' => 'Stáhnout se zastavil, protože dostupné úložiště nemohlo být kontrolováno. zkontrolovat umístění stahování, pak se vrátit.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} epizody ke stažení',
			'downloads.downloadDeleted' => 'Stáhnout odstraněno',
			'downloads.deleteConfirm' => ({required Object title}) => 'Odstranit "${title}" z tohoto zařízení?',
			'downloads.deleteCollectionDownloads' => 'Odstranit downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Smazat všechna stažení v kolekci „${title}“ z tohoto zařízení?',
			'downloads.collectionDownloadsDeleted' => 'Stáhnout odstraněno',
			'downloads.cancelledDownloadTitle' => 'Zrušený download',
			'downloads.cancelledDownloadMessage' => 'Tento download byl zrušen. co byste chtěli dělat?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Všechny epizody již stažené',
			'downloads.resumeDownload' => 'Recenze download',
			'downloads.cancelledDownload' => 'Zrušený download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (syncování ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => 'Stáhnout ${file} - Klikněte pro dokončení',
			'downloads.partialDownloadClickToComplete' => 'Částečně stáhnout - klikněte na dokončit',
			'downloads.deleting' => 'Odstranění...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Odstranění ${title}... (${current} z ${total})',
			'downloads.queuedTooltip' => 'Kvůli',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Štítek ${files}',
			'downloads.downloadingTooltip' => 'Stáhnout...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Stáhnout ${files}',
			'downloads.noDownloadsTree' => 'Žádné stahování',
			'downloads.pauseAll' => 'Odpočinek vše',
			'downloads.resumeAll' => 'Recenze vše',
			'downloads.retryAll' => 'Vraťte všechny',
			'downloads.retryFailed' => 'Neúspěšné stahování',
			'downloads.deleteAll' => 'Odstranit vše',
			'downloads.selectVersion' => 'Vyberte verzi',
			'downloads.allEpisodes' => 'Všechny epizody',
			'downloads.unwatchedOnly' => 'Pouze ignorované',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Další ${count} nepozorováno',
			'downloads.customAmount' => 'Přizpůsobené množství...',
			'downloads.customAmountAny' => 'Příslušná částka (v každém případě)',
			'downloads.randomEpisodes' => 'Náhodné epizody',
			'downloads.includeSpecials' => 'Zahrnuje speciály',
			'downloads.howManyEpisodes' => 'Kolik epizod?',
			'downloads.invalidEpisodeCount' => 'Zadejte platný počet epizod.',
			'downloads.keepSynced' => 'Zůstaňte synchronizováni',
			'downloads.downloadOnce' => 'Stáhnout jednou',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Zůstaňte ${count} nepozorován',
			'downloads.editSyncRule' => 'Edit pravidlo synchronizace',
			'downloads.removeSyncRule' => 'Odstranit pravidlo synchronizace',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Přestaňte synchronizovat "${title}"? stažené epizody budou zachovány.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Přestaňte synchronizovat „${title}“?',
			'downloads.deleteSyncRuleDownloads' => 'Také odstranit související downloads',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Stáhnout použité jiným pravidlem synchronizace nebo profil bude zachováno.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Pravidlo synchronizace vytvořeno – zachování ${count} nepozorovaných epizod',
			'downloads.syncRuleUpdated' => 'Pravidlo synchronizace aktualizované',
			'downloads.syncRuleRemoved' => 'Pravidlo synchronizace odstraněno',
			'downloads.syncRuleAndDownloadsRemoved' => 'Pravidlo synchronizace a související stahování odstraněno',
			'downloads.syncRuleCleanupBusy' => 'Pravidla synchronizace jsou v současné době aktualizovány. zkuste znovu v okamžiku.',
			'downloads.syncRuleCleanupUnavailable' => 'Přidružené stahování nelze bezpečně identifikovat. znovu připojit server a zkuste znovu, nebo odstranit pravidlo bez odstranění stahování.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synchronizováno ${count} nové epizody pro ${title}',
			'downloads.syncNow' => 'Synchronizace nyní',
			'downloads.downloadsUpToDate' => 'Snížení je aktuální',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync kompletní · ${queued} queued, ${removed} odstraněno',
			'downloads.activeSyncRules' => 'Synchronizační pravidla',
			'downloads.reviewOrphanFiles' => 'Přihláška na sirotek Downloads',
			'downloads.orphanReviewTitle' => 'Přihláška na sirotek Downloads',
			'downloads.orphanReviewDescription' => 'Tyto označené soubory se nacházejí v předvolebních aplikacích spravovaných stahovacích složkách PlezyNG a nemají odpovídající stahovací záznam nebo aktivní úkol.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} soubory · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Odstranit soubory ${count}',
			'downloads.orphanCleanupNone' => 'Není nalezeno žádné downloadové soubory',
			'downloads.orphanCleanupFailed' => 'PlezyNG nemohl bezpečně skenovat složku spravovaných stahování. žádné soubory nebyly odstraněny.',
			'downloads.orphanCleanupChanged' => 'Seznam stahování se během přezkumu změnil. přezkoumání souborů znovu před čištěním.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Odstraněno ${count} orphaned soubory · ${size} osvobozeno',
			'downloads.noSyncRules' => 'Žádné pravidla synchronizace',
			'downloads.manageSyncRule' => 'Řízení synchronizace',
			'downloads.editEpisodeCount' => 'Epizoda počítá',
			'downloads.editSyncFilter' => 'Synchronizace filtru',
			'downloads.syncAllItems' => 'Synchronizace všech položek',
			'downloads.syncUnwatchedItems' => 'Synchronizace nepozorovaných položek',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Dostupné',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Podepisujte požadované',
			'downloads.syncRuleAccessDenied' => 'přístup odmítnutý',
			'downloads.syncRuleNotAvailableForProfile' => 'Není k dispozici pro aktuální profil',
			'downloads.syncRuleUnknownServer' => 'Neznámý server',
			'downloads.syncRuleListCreated' => 'Synchronizační pravidlo vytvořeno',
			'downloads.backgroundWarning.bannerBlocked' => 'Stáhnutí se zastaví, když opustíte aplikaci',
			'downloads.backgroundWarning.bannerDegraded' => 'Stáhnout základy může být omezené',
			'downloads.backgroundWarning.bannerAction' => 'detaily',
			'downloads.backgroundWarning.sheetTitle' => 'Základy stahování jsou blokovány',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Stáhnout základy může být omezené',
			'downloads.backgroundWarning.sheetIntro' => 'Android zabraňuje PlezyNG od stáhnout spolehlivě v pozadí.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Vaše zařízení omezuje, kdy může PlezyNG stáhnout v pozadí.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Použití pozadí PlezyNG je omezeno. nastavte jeho použití baterie nebo pozadí na "Nezákonné".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android je umístěn PlezyNG v omezeném stavu. nastavte jeho použití baterie na "Neomezené".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Oznámení o stažení jsou vypnuty, takže pokrok a kontroly nemusí být k dispozici.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Na Android 13 nebo novější, jsou požadovány pro dlouhé pozadí stahování.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Data Saver je na, který blokuje pozadí stahování na mobilní údaje. stahování by mělo stále probíhat na Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Stáhnout se opakovaně zastavil, zatímco PlezyNG byl v pozadí. zkontrolujte nastavení použití baterie nebo pozadí PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Otevřené nastavení',
			'downloads.backgroundWarning.stillNotWorking' => 'Speciální pomoc zařízení',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Zobrazit kroky pro vaše zařízení, nebo odeslat záznam z Nastavení › Zobrazit záznamy, pokud problém pokračuje.',
			'downloads.backgroundWarning.dialogTitle' => 'Stáhnutí nemusí skončit',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Stáhnout v každém případě',
			'downloads.backgroundWarning.dialogFixFirst' => 'Nejprve to opravte',
			'downloads.backgroundWarning.statusTile' => 'Zásadní downloads',
			'downloads.backgroundWarning.statusOk' => 'Dovoleno běhat v pozadí',
			'downloads.backgroundWarning.statusBlocked' => 'Blokované systémovými nastaveními',
			'downloads.backgroundWarning.statusDegraded' => 'Omezený systémovými nastaveními',
			'downloads.backgroundWarning.statusUnknown' => 'Zatím neprověřeno',
			'downloads.backgroundWarning.settingsUnavailable' => 'Nemohla jsem na tomto zařízení otevřít nastavení systému',
			'downloads.backgroundWarning.linkUnavailable' => 'Nemohla jsem otevřít dontkillmyapp.com na tomto zařízení',
			'downloads.options' => 'možnost stahování',
			'downloads.groupings.library' => 'Knihovna',
			'downloads.groupings.collections' => 'Kolekce',
			'downloads.unknownLibrary' => 'Neznámá knihovna',
			'downloads.unknownShow' => 'Neznámá show',
			'downloads.unknownSeason' => 'Neznámá sezóna',
			'downloads.unknownAlbum' => 'Neznámý album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} dokončeno',
			'downloads.storageUsed' => ({required Object size}) => 'Použité skladování: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažený soubor', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažené soubory', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} staženého souboru', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} stažených souborů', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriál', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriály', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriálu', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} seriálů', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} film', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmy', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmu', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmů', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} album', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alba', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alba', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} alb', ), 
			'downloads.errorFileNotFound' => 'Soubor nenajdený (404)',
			'downloads.errorDownloadNotAllowed' => 'Stáhnout není povoleno serverem (403)',
			'downloads.errorDownloadFailed' => 'Download neúspěch',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Stáhnout neúspěšný: ${reason}',
			'downloads.convertingOnServer' => 'Převod na server...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Převod na server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Stáhnout selhalo (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Post-procesování selhalo: ${reason}',
			'downloads.reasonFileNotSaved' => 'soubor nelze uložit na tomto zařízení',
			'downloads.reasonCannotResume' => 'Částečné stahování nelze obnovit',
			'downloads.reasonDeviceStorageFull' => 'Tento přístroj je mimo skladování',
			'downloads.notificationDownloading' => 'Stáhnout...',
			'downloads.notificationComplete' => 'Download kompletní',
			'downloads.notificationPaused' => 'Stáhnout Pause',
			'shaders.title' => 'Shadersová',
			'shaders.noShaderDescription' => 'Žádné video vylepšení',
			'shaders.nvscalerDescription' => 'NVIDIA image scaling pro ostrší video',
			'shaders.artcnnVariantNeutral' => 'neutrální',
			'shaders.artcnnVariantDenoise' => 'Denoza',
			'shaders.artcnnVariantDenoiseSharpen' => 'Demoise + Sharpenová',
			'shaders.qualityFast' => 'Rychle',
			'shaders.qualityHQ' => 'Vysoká kvalita',
			'shaders.mode' => 'Módní',
			'shaders.importShader' => 'Importovat shader',
			'shaders.customShaderDescription' => 'Přizpůsobený GLSL shader',
			'shaders.shaderImported' => 'Shader dovážený',
			'shaders.shaderImportFailed' => 'Nepodařilo se dovoz shaderu',
			'shaders.deleteShader' => 'Odstranění Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Odstranit „${name}“?',
			'companionRemote.title' => 'Doprovodný ovladač',
			'companionRemote.connectedTo' => ({required Object name}) => 'Připojení k číslu ${name}',
			'companionRemote.unknownDevice' => 'Neznámé zařízení',
			'companionRemote.session.startingServer' => 'Začátek vzdáleného serveru.',
			'companionRemote.session.hostAddress' => 'Hostitelská adresa',
			'companionRemote.session.connected' => 'připojené',
			'companionRemote.session.serverRunning' => 'Remote server aktivní',
			'companionRemote.session.serverStopped' => 'Remote server se zastavil',
			'companionRemote.session.serverRunningDescription' => 'Mobilní zařízení na vaší síti se mohou připojit k této aplikaci',
			'companionRemote.session.serverStoppedDescription' => 'Začněte server, abyste mobilní zařízení mohli připojit',
			'companionRemote.session.usePhoneToControl' => 'Použijte mobilní zařízení k ovládání této aplikace',
			'companionRemote.session.startServer' => 'Start serveru',
			'companionRemote.session.stopServer' => 'Přestaňte server',
			'companionRemote.session.minimize' => 'Minimalizovat',
			'companionRemote.session.manualAddressHint' => 'Manuální kontaktní adresa:',
			'companionRemote.pairing.discoveryDescription' => 'Přístroje PlezyNG se stejným účtem Plex se zde zobrazí',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Připojení...',
			'companionRemote.pairing.searchingForDevices' => 'Hledáme přístroje...',
			'companionRemote.pairing.noDevicesFound' => 'Na vaší síti nenajdete žádné zařízení',
			'companionRemote.pairing.noDevicesHint' => 'Otevřete PlezyNG na desktopu a použijte stejný Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dostupné zařízení',
			'companionRemote.pairing.manualConnection' => 'Manuální připojení',
			'companionRemote.pairing.cryptoInitFailed' => 'Bezpečné připojení se nemůže začít. přihlaste se na číslo Plex nejprve.',
			'companionRemote.pairing.validationHostRequired' => 'Vložte prosím hostitelskou adresu',
			'companionRemote.pairing.validationHostFormat' => 'Formát musí být IP:port (např. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Použijte stejnou síť na obou zařízeních.',
			'companionRemote.pairing.sessionNotFound' => 'Není nalezeno zařízení. ujistěte se, že PlezyNG běží na hostiteli.',
			'companionRemote.pairing.authFailed' => 'Obě zařízení potřebují stejný účet Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Nepodařilo se připojit: ${error}',
			'companionRemote.pairing.codeTitle' => 'Pařížový kód',
			'companionRemote.pairing.codeDescription' => 'Vložte kód zobrazený v přístroji Companion Remote na hostitelském zařízení. Oba zařízení musí používat verzi, která podporuje bezpečné páření.',
			'companionRemote.pairing.codeInvalid' => 'Zadejte všechny 32 písmen a čísel z hostovacího kódu.',
			'companionRemote.pairing.updateRequired' => 'Obě zařízení aktualizujte na verzi, která podporuje bezpečné páření.',
			'companionRemote.pairing.hostDescription' => 'Zadejte tento kód jednou na každém dálkovém. Držte ho soukromým: poskytuje kontrolu nad tímto profilem.',
			'companionRemote.pairing.resetCode' => 'Zpět na Pairing Code',
			'companionRemote.pairing.resetDescription' => 'Odstranit všechny vzdialenosti a vytvořit nový kód. Každý vzdialenost bude muset znovu pářit.',
			'companionRemote.remote.disconnectConfirm' => 'Chcete se odhlásit od vzdálené schůzky?',
			'companionRemote.remote.reconnecting' => 'Připojení...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Zkouška ${current} z 5',
			'companionRemote.remote.retryNow' => 'Zpět teď',
			'companionRemote.remote.tabRemote' => 'vzdálenost',
			'companionRemote.remote.tabPlay' => 'Přehrát',
			'companionRemote.remote.tabMore' => 'Více',
			'companionRemote.remote.menu' => 'Nabídka',
			'companionRemote.remote.tabNavigation' => 'Tab Navigace',
			'companionRemote.remote.tabDiscover' => 'Objevovat',
			'companionRemote.remote.tabLibraries' => 'Knihovny',
			'companionRemote.remote.tabSearch' => 'Vyhledávání',
			'companionRemote.remote.tabDownloads' => 'Stažené soubory',
			'companionRemote.remote.tabSettings' => 'Nastavení',
			'companionRemote.remote.previous' => 'Předchozí',
			'companionRemote.remote.playPause' => 'Hrát / Pause',
			'companionRemote.remote.next' => 'Další',
			'companionRemote.remote.seekBack' => 'Hledat zpět',
			'companionRemote.remote.stop' => 'Zastavit',
			'companionRemote.remote.seekForward' => 'Hledat FWD',
			'companionRemote.remote.volume' => 'objem',
			'companionRemote.remote.volumeDown' => 'Dolů',
			'companionRemote.remote.volumeUp' => 'Nahoru',
			'companionRemote.remote.fullscreen' => 'Celá obrazovka',
			'companionRemote.remote.subtitles' => 'Titulky',
			'companionRemote.remote.audio' => 'Zvuk',
			'companionRemote.remote.searchHint' => 'Vyhledávání na desktopu...',
			'companionRemote.errors.noNetworkInterface' => 'Není nalezeno rozhraní sítě',
			'companionRemote.errors.authenticationFailed' => 'autentifikace selhala',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Neschopnost spustit vzdálený server: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Nedokázal odeslat příkaz na dálku: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Čas na přistoupení k schůzce',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Nedokázal se připojit k jakékoli adrese',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Ztráta připojení po pokusech ${attempts}',
			'companionRemote.errors.connectionLost' => 'Ztracené spojení',
			'companionRemote.closedBeforeAuth' => 'Připojení uzavřeno před autentifikací',
			'videoSettings.playbackSpeed' => 'Rychlost přehrávání',
			'videoSettings.normalSpeed' => 'Normální',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktivní (${duration})',
			'videoSettings.zoom' => 'Přiblížit',
			'videoSettings.sleepTimer' => 'Čas spánku',
			'videoSettings.audioSync' => 'Audio synchronizace',
			'videoSettings.subtitleSync' => 'Synchronizace Subtitle',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR není k dispozici zde - tento desktopový skladatel nebo video výstup ho nemůže nosit.',
			'videoSettings.hdrToneMapping' => 'HDR Tone mapování',
			'videoSettings.hdrToneMappingCompositor' => 'skladatel',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Přejděte přes zdroje HDR metadata a nechte desktopovou kompozitní mapu.',
			'videoSettings.hdrToneMappingPlayer' => 'Přehrávač',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Mapa na špičkové jasnosti displeje v hráči, pak řekněte skladatelovi výsledek.',
			'videoSettings.hdrToneMappingFailed' => 'Nemohlo by se změnit mapování HDR tónu - předchozí režim je stále aktivní.',
			'videoSettings.audioOutput' => 'Audio výstup',
			'videoSettings.performanceOverlay' => 'Výsledky Overlay',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'okolí',
			'videoSettings.audioOutputSpatial' => 'Vesmírný audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio ekvalizátor',
			'videoSettings.audioEqualizerDescription' => 'Přizpůsobte pro toto zařízení pět frekvenčních pásem. k dispozici na čísle mpv; aktivní EQ dekóduje zvuk a deaktivuje přizpůsobení.',
			'videoSettings.audioEqualizerFlat' => 'ploché',
			'videoSettings.audioEqualizerActive' => 'Vlastní',
			'videoSettings.audioEqualizerSaveFailed' => 'Nemohl jsem zachránit nastavení audio ekvalizátoru.',
			'videoSettings.backgroundVideoAudio' => 'Video audio pozadí',
			'videoSettings.backgroundVideoAudioDescription' => 'Udržujte video audio přehrávač, když opustíte přehrávač; obrázek je skryt, dokud se nevrátíte. Android používá oznámení pro přehrávač médií.',
			'videoSettings.audioNormalization' => 'Normalizace hluku',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Odstraňte audio na PCM; passthrough je vypnutý, zatímco toto je na',
			'performanceOverlay.color' => 'Barva',
			'performanceOverlay.performance' => 'Výkon',
			'performanceOverlay.buffer' => 'Bufferová',
			'performanceOverlay.app' => 'Aplikace',
			'performanceOverlay.decoder' => 'dekódování',
			'performanceOverlay.rawDecoder' => 'Růžový decoder',
			'performanceOverlay.tunneling' => 'tunelů',
			'performanceOverlay.passthrough' => 'Pastrátová',
			'performanceOverlay.aspect' => 'Pohled',
			'performanceOverlay.rotation' => 'Rotace',
			'performanceOverlay.dvSource' => 'Zdroj DV',
			'performanceOverlay.dvPath' => 'Dva cesty',
			'performanceOverlay.dvRouteDecoder' => 'Dolby Vision dekódování',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby Vision dekodér (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Základní vrstva',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10 základní vrstva',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG základní vrstva',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR základní vrstva',
			'performanceOverlay.dvRouteReshaped' => 'RPU obnovené (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Experimentální graf P7 FEL (nekvalifikovaný)',
			'performanceOverlay.p7Conversion' => 'Převod P7',
			'performanceOverlay.sampleRate' => 'Vzorkovací frekvence',
			'performanceOverlay.pixelFormat' => 'Formát pixelu',
			'performanceOverlay.hwFormat' => 'HMFF',
			'performanceOverlay.matrix' => 'Matrixová',
			'performanceOverlay.primaries' => 'Primární',
			'performanceOverlay.transfer' => 'Převod',
			'performanceOverlay.renderFps' => 'FPS vykreslování',
			'performanceOverlay.displayFps' => 'Zobrazit FPS',
			'performanceOverlay.avSync' => 'A/V synchronizace',
			'performanceOverlay.dropped' => 'roztrhané',
			'performanceOverlay.dvRpus' => 'DV RPU',
			'performanceOverlay.dvRpuAverage' => 'Dv RPU AVG',
			'performanceOverlay.dvSampleAverage' => 'DV vzorec AVG',
			'performanceOverlay.maxLuma' => 'Max. jas',
			'performanceOverlay.minLuma' => 'Min. jas',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache používá',
			'performanceOverlay.cacheLimit' => 'Cache limity',
			'performanceOverlay.speed' => 'rychlost',
			'performanceOverlay.player' => 'Přehrávač',
			'performanceOverlay.playMethod' => 'Způsob přehrání',
			'performanceOverlay.memory' => 'Paměť',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'Nvidia HW',
			'performanceOverlay.decoderQualcommHw' => 'Štítek Qualcomm',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'hardwarové',
			'performanceOverlay.tunnelingActive' => 'aktivní',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} selhalo)',
			'externalPlayer.title' => 'Vnější hráč',
			'externalPlayer.useExternalPlayer' => 'Použijte externí hráče',
			'externalPlayer.useExternalPlayerDescription' => 'Otevřete videa v jiné aplikaci',
			'externalPlayer.selectPlayer' => 'Vyberte hráče',
			'externalPlayer.customPlayers' => 'Custom hráči',
			'externalPlayer.systemDefault' => 'Systém default',
			'externalPlayer.addCustomPlayer' => 'Přidat přizpůsobený hráč',
			'externalPlayer.playerName' => 'Název hráče',
			'externalPlayer.playerNameHint' => 'Můj hráč',
			'externalPlayer.playerCommand' => 'Příkaz',
			'externalPlayer.playerPackage' => 'Název balení',
			'externalPlayer.playerUrlScheme' => 'URL schéma',
			'externalPlayer.off' => 'Vypnuto',
			'externalPlayer.launchFailed' => 'Neschopnost otevřít externí hráče',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} není instalován',
			'externalPlayer.playInExternalPlayer' => 'Hrajte v externím hráči',
			'externalPlayer.description' => 'Vyberte si jinou aplikaci k otevření videa v. Dostupné hráče závisí na vašem zařízení a na instalovaných aplikacích.',
			'externalPlayer.systemDefaultDescription' => 'Nechte operační systém video otevřít pomocí své výchozí aplikace.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Otevřete videa pomocí ${player}.',
			'externalPlayer.playerNameDescription' => 'Značka zobrazená v seznamu hráčů.',
			'externalPlayer.playerPackageDescription' => 'Zadejte název balíčku Android aplikace pro hráče, jako je com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Vložte nainstalovaný přehrávač příkaz nebo spustitelnou dráhu pro toto zařízení.',
			'externalPlayer.playerUrlSchemeDescription' => 'Zadejte schéma URL a volitelný šablona URL používaný k spuštění hráče.',
			'metadataEdit.editMetadata' => 'Upravit',
			'metadataEdit.screenTitle' => 'Upravit metadata',
			'metadataEdit.basicInfo' => 'Základní info',
			'metadataEdit.artwork' => 'umělecká práce',
			'metadataEdit.advancedSettings' => 'Pokročilé nastavení',
			'metadataEdit.title' => 'Název',
			'metadataEdit.sortTitle' => 'Třídit dle názvu',
			'metadataEdit.originalTitle' => 'Originální název',
			'metadataEdit.releaseDate' => 'Datum vydání',
			'metadataEdit.contentRating' => 'Hodnocení obsahu',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Shrnutí',
			'metadataEdit.poster' => 'Plakát',
			'metadataEdit.background' => 'pozadí',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Square umění',
			'metadataEdit.selectPoster' => 'Vyberte plakát',
			'metadataEdit.selectBackground' => 'Vyberte pozadí',
			'metadataEdit.selectLogo' => 'Vyberte logo',
			'metadataEdit.selectSquareArt' => 'Výběr Square Art',
			'metadataEdit.fromUrl' => 'Od URL',
			'metadataEdit.uploadFile' => 'Upload souborů',
			'metadataEdit.enterImageUrl' => 'Vložte obrázek URL',
			'metadataEdit.imageUrl' => 'obrázek URL',
			'metadataEdit.metadataUpdated' => 'Aktualizované metadata',
			'metadataEdit.metadataUpdateFailed' => 'Nedokázal aktualizovat metadata',
			'metadataEdit.artworkUpdated' => 'Umělecká aktualizace',
			'metadataEdit.artworkUpdateFailed' => 'Nedokázal aktualizovat umělecké dílo',
			'metadataEdit.noArtworkAvailable' => 'K dispozici žádné umělecké dílo',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Umělecká volba ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Možnost umělecké práce ${index}, vybraná',
			'metadataEdit.notSet' => 'Není nastaven',
			'metadataEdit.libraryDefault' => 'knihovny defektní',
			'metadataEdit.accountDefault' => 'Účetní default',
			'metadataEdit.seriesDefault' => 'Seriál default',
			'metadataEdit.episodeSorting' => 'Epizoda rozvrhována',
			'metadataEdit.oldestFirst' => 'Nejstarší první',
			'metadataEdit.newestFirst' => 'Nejnovější první',
			'metadataEdit.keep' => 'Držte',
			'metadataEdit.allEpisodes' => 'Všechny epizody',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} nejnovější epizody',
			'metadataEdit.latestEpisode' => 'Poslední epizoda',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Přidané epizody v posledních ${count} dnech',
			'metadataEdit.deleteAfterPlaying' => 'Odstranění epizod po hraní',
			'metadataEdit.never' => 'Nikdy',
			'metadataEdit.afterADay' => 'Po jednom dni',
			'metadataEdit.afterAWeek' => 'Po týdnu',
			'metadataEdit.afterAMonth' => 'Po měsíci',
			'metadataEdit.onNextRefresh' => 'Na příštím refresh',
			'metadataEdit.seasons' => 'Série',
			'metadataEdit.show' => 'představení',
			'metadataEdit.hide' => 'Skrýt',
			'metadataEdit.episodeOrdering' => 'Epizoda objednávky',
			'metadataEdit.tmdbAiring' => 'Databáze filmů (Aired)',
			'metadataEdit.tvdbAiring' => 'TTVDB (vzdálenost)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolutní)',
			'metadataEdit.metadataLanguage' => 'Metodický jazyk',
			'metadataEdit.useOriginalTitle' => 'Originální název',
			'metadataEdit.preferredAudioLanguage' => 'Preferovaný jazyk zvuku',
			'metadataEdit.preferredSubtitleLanguage' => 'Preferovaný jazyk titulků',
			'metadataEdit.subtitleMode' => 'Auto-Select Subtitle režim',
			'metadataEdit.manuallySelected' => 'Manuálně vybrané',
			'metadataEdit.shownWithForeignAudio' => 'Zahraniční audio',
			'metadataEdit.alwaysEnabled' => 'Vždy povolená',
			'metadataEdit.tags' => 'Štítky',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.addTag' => 'Přidat tag',
			'metadataEdit.genre' => 'Žánr',
			'metadataEdit.director' => 'Režisér',
			'metadataEdit.writer' => 'Scénárista',
			'metadataEdit.producer' => 'Producent',
			'metadataEdit.country' => 'Země',
			'metadataEdit.collection' => 'Kolekce',
			'metadataEdit.label' => 'Značka',
			'metadataEdit.quickTag' => 'Rychlý Tag...',
			'matchScreen.match' => 'Zápas...',
			'matchScreen.fixMatch' => 'Fixní zápas...',
			'matchScreen.unmatch' => 'neshody',
			'matchScreen.unmatchConfirm' => 'Zjistěte tento zápas? Plex se s ním zachází jako s neúspěšným až do ukončení.',
			'matchScreen.unmatchSuccess' => 'položka neslučitelná',
			'matchScreen.unmatchFailed' => 'Neúspěšný nesouhlasný bod',
			'matchScreen.matchApplied' => 'Zápas aplikovaný',
			'matchScreen.matchFailed' => 'Nepodařilo se zahájit zápas',
			'matchScreen.titleHint' => 'Název',
			'matchScreen.yearHint' => 'Rok',
			'matchScreen.search' => 'Vyhledávání',
			'matchScreen.noMatchesFound' => 'Žádné zápasy nalezené',
			'serverTasks.title' => 'Serverové úkoly',
			'serverTasks.failedToLoad' => 'Neschopnost naplnit úkoly',
			'serverTasks.noTasks' => 'Žádné úkoly běží',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'připojené',
			'trakt.connectedAs' => ({required Object username}) => 'Připojeno jako @${username}',
			'trakt.disconnectConfirm' => 'Odstranit účet Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG přestane odesílat události na adresu Trakt.Můžete se kdykoli znovu spojit.',
			'trakt.scrobble' => 'Reálný scrobbling',
			'trakt.scrobbleDescription' => 'Pošlete si hraní, přestávku a zastavení událostí na adresu Trakt během přehrávání.',
			'trakt.watchedSync' => 'Sync sledovaný status',
			'trakt.watchedSyncDescription' => 'Pokud označíte položky podle zobrazení v čísle PlezyNG, označují se také podle zobrazení v čísle Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Připojte se Seerr',
			'seerr.serverUrl' => 'server URL',
			'seerr.serverUrlHelper' => 'Adresa vašeho Seerr instance',
			'seerr.checkServer' => 'pokračovat',
			'seerr.signInWithJellyfin' => 'Přihlaste se na číslo Jellyfin',
			'seerr.signInWithEmby' => 'Přihlaste se na číslo Emby',
			'seerr.signInWithLocal' => 'Použijte místní účet',
			'seerr.email' => 'Emailová',
			'seerr.noSignInMethods' => 'Tento příklad Seerr neobsahuje žádnou podpůrnou metodu PlezyNG.',
			'seerr.instance' => 'Instance',
			'seerr.disconnectConfirm' => 'Odstranit se od Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG bude zapomenout na tento příklad Seerr.',
			'seerr.request' => 'Žádost',
			'seerr.request4k' => 'Vyžádání v 4K',
			'seerr.seasons' => 'Série',
			'seerr.allSeasons' => 'Všechny sezóny',
			'seerr.advancedOptions' => 'Pokročilé',
			'seerr.destinationServer' => 'Destinace server',
			'seerr.qualityProfile' => 'Kvalitní profil',
			'seerr.rootFolder' => 'Root složky',
			'seerr.languageProfile' => 'Jazykový profil',
			'seerr.tags' => 'Štítky',
			'seerr.noTags' => 'Žádné tags',
			'seerr.defaultOption' => ({required Object name}) => '${name} (případní předvolba)',
			'seerr.animeNote' => 'Tato série je anime.',
			'seerr.requestSubmitted' => 'Žádost podaná',
			'seerr.requestFailed' => ({required Object error}) => 'Přihláška selhala: ${error}',
			'seerr.requestsLoadFailed' => 'Možnosti žádosti nelze nabíjet',
			'seerr.nothingToRequest' => 'Vše je již k dispozici nebo požadováno.',
			'seerr.statusAvailable' => 'Dostupné',
			'seerr.statusPartiallyAvailable' => 'Částečně k dispozici',
			'seerr.statusRequested' => 'požadované',
			'seerr.statusProcessing' => 'zpracování',
			'seerr.statusBlocklisted' => 'Blokované',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Nemůže dosáhnout ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Žádný případ Seerr na adrese ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Autentifikující reverzní proxy (SSO nebo HTTP auth) odpověděla namísto Seerr. PlezyNG nemůže přihlásit prostřednictvím něj: nechte Seerr /api/v1 cestu přes proxy pro tuto aplikaci, nebo použijte adresu, která se přímo dostane Seerr.',
			'seerr.invalidUrl' => 'Zadejte serverovou adresu jako je https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Tento příklad Seerr nepodporuje Quick Connect. Potřebuje Seerr 3.4 nebo novější.',
			'seerr.notInitialized' => 'Tento příklad Seerr nedokončil první instalace',
			'seerr.noPlexTokenForReauth' => 'No Plex token je k dispozici k opětovnému přihlášení',
			'seerr.noStoredCredentials' => 'Žádné uložené certifikáty nejsou k dispozici k opětovnému přihlášení',
			'seerr.signInRejected' => 'Sign-in byl odmítnut',
			'seerr.noSessionCookie' => 'Společnost Seerr neposkytla soubor cookie sezení',
			'seerr.freshCookieRejected' => 'Seerr odmítl nový soubor cookie',
			'seerr.noUserInformation' => 'Seerr nevrátil uživatelské informace',
			'seerr.sessionRejectedAfterReauth' => 'Zasedání bylo po opětovném podepsání zamítnuto.',
			'seerr.permissionDenied' => 'Seerr tuto akci odmítl: Váš účet již nemá požadované povolení',
			'seerr.permissionRevoked' => 'Už nemáte právo na to požádat',
			'services.title' => 'Služby',
			'services.hubSubtitle' => 'Sync sleduje pokrok a žádá o nové tituly.',
			'services.integrations' => 'integrace',
			'services.notConnected' => 'Není připojený',
			'services.connectedAs' => ({required Object username}) => 'Připojeno jako @${username}',
			'services.scrobble' => 'Automaticky sledujte pokrok',
			'services.scrobbleDescription' => 'Aktualizujte svůj seznam, když dokončíte epizodu nebo film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Rozhraní ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG přestane aktualizovat ${service}. znovu se připojit kdykoli.',
			'services.connectFailed' => ({required Object service}) => 'Nemohla jsem se připojit na číslo ${service}. zkuste znovu.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Připojení Simkl',
			'services.simklReconnect.subtitle' => 'Simkl ukončuje podporu způsobu přihlášení, který toto připojení používá. Opětovné připojení otevře simkl.com, kde schválíte PlezyNG — PlezyNG nikdy neuvidí vaše heslo. Historie sledování zůstane na Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Aktivovat PlezyNG na ${service}',
			'services.deviceCode.instructions' => 'Skenujte QR kód, nebo navštivte níže uvedenou adresu a zadejte tento kód:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Otevřete ${service} aktivovat',
			'services.deviceCode.copyCode' => 'Kopírování aktivačního kódu',
			'services.deviceCode.waitingForAuthorization' => 'Čekání na autorizaci...',
			'services.deviceCode.codeCopied' => 'Kód kopírovaný',
			'services.oauthProxy.title' => ({required Object service}) => 'Přihlaste se na číslo ${service}',
			'services.oauthProxy.body' => 'Skenujte tento QR kód nebo otevřete URL na kterémkoli zařízení.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Otevřete ${service} k přihlášení',
			'services.pendingAuth.copyUrl' => 'Kopírování sign-in URL',
			'services.pendingAuth.urlCopied' => 'URL kopírování',
			'services.libraryFilter.title' => 'Knihovna Filter',
			'services.libraryFilter.subtitleAllSyncing' => 'Synchronizace všech knihoven',
			'services.libraryFilter.subtitleNoneSyncing' => 'Není synchronizace',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blokováno',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} povoleno',
			'services.libraryFilter.mode' => 'Filterový režim',
			'services.libraryFilter.modeBlacklist' => 'Zakázat vše kromě výjimek',
			'services.libraryFilter.modeWhitelist' => 'Povolit vše kromě výjimek',
			'services.libraryFilter.modeHintBlacklist' => 'Synchronizujte každou knihovnu s výjimkou níže uvedených knihoven.',
			'services.libraryFilter.modeHintWhitelist' => 'Synchronizujte pouze níže kontrolované knihovny.',
			'services.libraryFilter.libraries' => 'Knihovny',
			'services.libraryFilter.noLibraries' => 'Žádné knihovny k dispozici',
			'services.libraryFilter.modeDescription' => 'Vyberte, zda jsou kontrolované knihovny zablokovány od synchronizace nebo jsou jedinými knihovnami, které synchronifikují.',
			'services.seerrDescription' => 'Připojte se k Seerr nebo Overseerr pro vyhledávání titulů a předložte mediální požadavky.',
			'services.trackerDescriptions.trakt' => 'Synchronizujte sledované epizody a filmy s vaším účtem Trakt.',
			'services.trackerDescriptions.mal' => 'Synchronizovat anime seznamy a sledovat pokrok s MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Synchronizujte anime seznamy a sledujte pokrok s AniList.',
			'services.trackerDescriptions.simkl' => 'Sync sledoval filmy, televizní pořady a anime s Simkl.',
			'services.trackerDescriptions.mdblist' => 'Zobrazit hodnocení a seznamy MDBList v doporučeních a prozkoumat.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Přidat server ${product}',
			'addServer.serverUrls' => 'Serverové URL',
			'addServer.serverUrlsHelper' => 'Mnoho URL je povoleno, odděleno komami.',
			'addServer.findServer' => 'Najít server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Hledáte místní servery ${product} ...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Lokální servery ${product}',
			'addServer.username' => 'Uživatelské jméno',
			'addServer.password' => 'Heslo',
			'addServer.signIn' => 'Přihlásit se',
			'addServer.change' => 'Změna',
			'addServer.required' => 'požadované',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Nemohla se dostat na server: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Přihláška neúspěšná: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect selhalo: ${error}',
			'addServer.addPlexTitle' => 'Přihlaste se na číslo Plex',
			'addServer.pinExpired' => 'PIN skončil před přihlášením, zkuste to znovu.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Účet se nezregistroval: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Zadejte svůj server ${product} URL',
			'addServer.addConnectionTitle' => 'Přidejte připojení',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Přidat na ${name}',
			'addServer.signInWithPlexCard' => 'Přihlaste se na číslo Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Přizpůsobte toto zařízení.Sdílené servery jsou přidány.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorizujte účet Plex. domácí uživatelé se stávají profily.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Připojte se k číslu ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Zadejte URL, uživatelské jméno a heslo.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Přihlaste se k serveru ${product}. připojte se k serveru ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Půjčka z jiného profilu',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Další připojení profilu znovu použijte. PIN-ochráněné profily vyžadují PIN.',
			'addServer.invalidCredentials' => 'Invalidní uživatelské jméno nebo heslo',
			'addServer.authResponseNotJson' => 'Odpověď na ověření nebyla platná JSON',
			'addServer.authResponseIncomplete' => 'Odpověď na sign-in ze serveru byla neúplná',
			'addServer.quickConnectRejected' => 'Quick Connect byl odvolán serverem',
			'addServer.quickConnectNotJson' => 'Odpověď Quick Connect nebyla platná JSON',
			'addServer.quickConnectMissingFields' => 'Odpověď Quick Connect chybí kód nebo tajemství',
			'addServer.quickConnectPollRejected' => 'Quick Connect zpráva byla odmítnuta serverem',
			'addServer.serverTimedOut' => 'Server neodpovídá včas',
			'addServer.responseNotJson' => 'Odpověď serveru nebyla platná JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'Odpověď chybí ID nebo jméno serveru - je to server ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Nemohla se dostat na server: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Zadejte alespoň jeden serverový URL ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Nejsou nalezeny žádné dostupné servery ${product}',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Tyto URL odkazují na různé servery ${product}',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Tento URL se neshoduje s serverem ${product}',
			'addServer.redirectUnsupported' => 'Server přesměrován na nepodporovaný URL',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Server přesměrován na jiný host. Zadejte konečnou adresu URL ${product} přímo.',
			'addServer.redirectInsecure' => 'Server přesměrován z HTTPS na nejistou adresu URL',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Server přesměrován na nepodporovaný URL. Zadejte konečný URL ${product} přímo.',
			'addServer.directPlexServerUrl' => 'Plex URL serveru',
			'addServer.directPlexServerUrlHelper' => 'Zadejte místní IP a port vašeho serveru Plex Media Server.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (volitelné)',
			'addServer.plexTokenHelper' => 'Zanechte prázdný, pokud je přístup bez auth povolen na tomto serveru.',
			'addServer.plexTokenRequired' => 'Vložte prosím svůj token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (přímý / místní)',
			'addServer.connectDirectPlexCardSubtitle' => 'Připojte se přímo pomocí místního IP nebo URL bez účtu plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Připojte se přímo pomocí místního IP nebo URL. Připojte se k ${name}.',
			'addServer.insecureTitle' => 'Nekryptované spojení',
			'addServer.insecureDescription' => ({required Object url}) => '${url} používá HTTP. Lidé v síti mohou číst nebo měnit vaše heslo, tokeny a média. Je-li to možné, použijte HTTPS. Pokračujte pouze v případě, že této síti důvěřujete a přijímáte toto riziko.',
			'addServer.allowHttp' => 'Přijmout HTTP',
			'addServer.httpsRequired' => 'Použití HTTPS nebo výslovně umožnit nekryptované připojení.',
			'cast.chooseDevice' => 'Odeslat do zařízení',
			'cast.searching' => 'Hledání zařízení pro výkresy...',
			'cast.connectedTo' => ({required Object device}) => 'Připojení k číslu ${device}',
			'cast.device' => 'Zařízení pro odesílání',
			'cast.readyToCast' => 'Připraveno k odesílání',
			'cast.subtitle' => 'Titulky',
			'cast.serverNotAvailable' => 'Media server není k dispozici.',
			'cast.stopCasting' => 'Ukončit odesílání',
			'cast.castToDevice' => 'Odeslat do zařízení',
			'cast.noEpisodeAvailable' => 'Neexistuje žádná epizoda k dispozici.',
			'cast.startFailed' => 'Nemůžete začít casting. zkontrolujte server a zkuste znovu.',
			'automation.noActivePlayback' => 'Neexistuje žádná aktivní videozáznamy k ovládání.',
			'notifications.newEpisodeTitle' => 'Nová epizoda',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Zkuste každou funkci zdarma po dobu 7 dní',
			'appAccess.description' => 'Začněte sedmdenní zkoušku s plným přístupem k každému PlezyNG funkci. v průběhu zkoušky neexistuje žádná poplatek a žádná předplatná. Po zkoušce jeden životní nákup v ceně vašeho obchodu odblokuje PlezyNG po celý život.',
			'appAccess.trialEndedDescription' => 'Jediným nákupem za cenu uvedenou ve vašem obchodě odemknete všechny funkce PlezyNG natrvalo. Bez předplatného.',
			'appAccess.startTrial' => 'Začínám 7denní bezplatný test',
			'appAccess.trialActive' => 'Váš 7denní plnohodnotný test je aktivní.',
			'appAccess.trialEnded' => 'Sedmdenní proces skončil.',
			'appAccess.trialStartFailed' => 'Nemohla jsem na tomto zařízení ušetřit zkoušku. prosím zkuste znovu.',
			'appAccess.lifetimeTitle' => 'PlezyNG odemknutá po celý život',
			'appAccess.lifetimeBody' => 'Díky! máte celoživotní přístup k každému PlezyNG funkci.',
			'appAccess.manageTitle' => 'PlezyNG Životní přístup',
			'appAccess.manageDescription' => 'Zkuste každou funkci zdarma po dobu 7 dnů, pak odemkněte vše po celý život s jednou platbou za cenu vašeho obchodu.',
			'appAccess.buy' => ({required Object price}) => 'Odemknout všechny funkce pro ${price}',
			'appAccess.loadingPrice' => 'Nákladní obchodní cena...',
			'appAccess.retryPrice' => 'Zpět na cenu Lookup',
			'appAccess.restore' => 'Obnovte životní nákup',
			'appAccess.pending' => 'Váš nákup čeká na platbu nebo schválení. celoživotní přístup odemkne, jakmile ho obchod dokončí.',
			'appAccess.storeUnavailable' => 'Nákupy nejsou k dispozici. zkontrolujte, že jste se zaregistrovali do obchodu a nákupy jsou povoleny na tomto zařízení.',
			'appAccess.productNotFound' => 'Životní odemknutí PlezyNG není v tomto obchodě zatím k dispozici.',
			'appAccess.productQueryFailed' => 'Nemohla jsem si stáhnout cenu obchodu. zkontrolujte připojení a zkuste znovu.',
			'appAccess.purchaseFailed' => 'Nákup neprošel, zkuste to znovu.',
			'appAccess.restoreFailed' => 'Nemohla jsem se dostat do obchodu, abyste obnovili nákup. zkuste znovu.',
			'appAccess.nothingToRestore' => 'Číslo PlezyNG pro životní nákup byl nalezen pro tento obchodní účet.',
			'detail.endsAt' => ({required Object time}) => 'Končí na ${time}',
			'watchLink.serverUnavailable' => 'Nemohl jsem se dostat k serveru Plex pro tento odkaz.',
			'watchLink.notFound' => 'Nemohl jsem najít tento show nebo film na vašich serverech Plex.',
			'watchLink.ambiguous' => 'Tento odkaz se shoduje s položkami na více než jednom serveru. Přidejte server na odkaz.',
			'watchLink.plexOnly' => 'Sledování odkazů v současné době podporuje pouze servery Plex.',
			'watchLink.unsupportedItem' => 'Sledování odkazů může otevřít pouze show nebo film.',
			'watchLink.menuItem' => 'Zobrazit link',
			'watchLink.dialogTitle' => 'Podívejte se link',
			'watchLink.dialogShowHint' => 'Otevření tohoto odkazu hraje další epizodu. Přidejte &mode=shuffle do konce, abyste mohli hrát show na shuffle.',
			'watchLink.dialogMovieHint' => 'Otevření tohoto odkazu hraje film.',
			'watchLink.copy' => 'Kopírovat',
			'watchLink.copied' => 'Link kopírovaný',
			'homeLayout.title' => 'Domů Layout',
			'homeLayout.resetToast' => 'Domů Reset na původní rozložení hrdiny Plezy',
			'homeLayout.resetHeroTitle' => 'Obnovte herecký layout na zásobu Plezy?',
			'homeLayout.resetHeroBody' => 'Odstraní postavy hrdiny každé řady a přináší zpět jediný otáčící banner na vrcholu Domova, stejně jako předtím, než hrdinové řádky existovaly.',
			'homeLayout.removeRowTitle' => 'Odstranit domácí řádek?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} bude vymazán. to nelze vymazat.',
			'homeLayout.sync' => 'Synchronizace',
			'homeLayout.syncAccountTitle' => 'Synchronizujte rozložení s vaším účtem Plex',
			'homeLayout.syncAccountOn' => 'Na: Toto zařízení sdílí řádné řádky, řádky, Hero a Auto-slide s ostatními zařízeními.',
			'homeLayout.syncAccountOff' => 'Vypnutí: Tento přístroj si udržuje svůj vlastní layout.',
			'homeLayout.syncNow' => 'Synchronizace nyní',
			'homeLayout.plexHomeManager' => 'Plex Domácí manažer',
			'homeLayout.managePlexRows' => 'Řízení Plex řádků v Plezy',
			'homeLayout.managePlexRowsDescription' => 'Otevřeno pro organizaci domácího výběru řádků',
			'homeLayout.organizeHomeRows' => 'Domácí řádky',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} řádky: pohyb, Hero, Auto-slide, odstranění',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Složení ${library} řádků',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Pokračovat v sledování + ${n} řádky: pohyb, knihovna, Domů, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Vstup jako hrdinská karta',
			'homeLayout.heroOnlySingleCollection' => 'Dostupné pouze tehdy, když se tato řada vyřeší na skutečné tituly jedné kolekce',
			'homeLayout.hero' => 'Hrdina',
			'homeLayout.autoSlide' => 'Auto slide',
			'homeLayout.autoSlideDescription' => 'Přístupy (PC) a d-pad (TV) vždy fungují a časovač znovu spouští.',
			'homeLayout.autoSlideEditDescription' => 'Odstraní: pouze se pohybuje, když kliknete na šípku (PC) nebo stisknete levou / pravou na dálku (TV).',
			'homeLayout.enableHeroFirst' => 'První hrdina',
			'homeLayout.showOnHome' => 'Zobrazit na domácím obrazovce',
			'homeLayout.home' => 'Domovská obrazovka',
			'homeLayout.removeFromHome' => 'Odstranit z domova',
			'homeLayout.selectRowsFirst' => 'Vyberte domácí řádky níže první.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex řízené řádky',
			'homeLayout.continueWatching' => 'Pokračovat ve sledování',
			'homeLayout.continueWatchingLibraryDescription' => 'Tato knihovna má vlastní pokračovací řadu',
			'homeLayout.continueWatchingHomeDescription' => 'Zpětná řada pokroku zobrazená na Home',
			'homeLayout.nextUpHomeDescription' => 'Následující nedohlédnutý epizodový řádek zobrazen samostatně na Domů',
			'homeLayout.library' => 'Knihovna',
			'homeLayout.showInRecommended' => 'Představení v knihovně doporučeno',
			'homeLayout.customPlexRow' => 'Přizpůsobený Plex řádek',
			'homeLayout.heroNeedsLibrary' => 'Prohlédněte si knihovnu nejprve – Hero potřebuje někde ukázat',
			'homeLayout.heroNeedsSurface' => 'Zkontrolujte knihovnu nebo domov nejprve – Hero potřebuje někde ukázat',
			'homeLayout.removeHub' => 'Odstranění Hub',
			'homeLayout.noPlexRows' => 'Číslo Plex řízené řádky se vrátily pro tuto knihovnu.',
			'homeLayout.openDetails' => 'Otevřené detaily',
			'homeLayout.heroCards' => 'Hrdinové karty',
			'homeLayout.tapHeroCard' => 'Ztráta hrdinské karty',
			'homeLayout.tvPlayFocus' => 'TV Remote: tlačítko Play',
			'homeLayout.tvPlayFocusDescription' => 'D-pad dolů se zastaví na tlačítku Play před přechodem na další řádek.',
			'homeLayout.tvWrap' => 'TV Remote: Loup Hero karty',
			'homeLayout.tvWrapDescription' => 'Práce na poslední kartu se vrací zpět na první kartu. Odstupní zastávky na poslední kartu. Levo na první kartu vždy jde na boční bar.',
			'homeLayout.castOnHero' => 'Hrajte na herecké bannery',
			'homeLayout.castOnHeroDescription' => 'Zobrazuje výkres podél dna hrdinského banneru. Off zachovává pouze titul a shrnutí.',
			'homeLayout.customRows' => 'Custom řádek',
			'homeLayout.loading' => 'Domácí rozložení...',
			'homeLayout.noCustomRows' => 'Žádné klasické řádky',
			'homeLayout.addRowHint' => 'Použijte přidání řádku Domů k vytvoření jednoho.',
			'homeLayout.addHomeRow' => 'Přidat domácí řádek',
			'homeLayout.addHomeRowDescription' => 'Výběr kategorie; nový řádek se automaticky přidává k Organizátoru',
			'homeLayout.removeRow' => 'Odstranit řádek',
			'homeLayout.recentlyAdded' => 'Nedávno přidáno',
			'homeLayout.recentlyReleased' => 'Nedávno uvolněné',
			'homeLayout.movieCollections' => 'Filmové sbírky',
			'homeLayout.showCollections' => 'Zobrazení kolekcí',
			'homeLayout.rowTitle' => 'Row titulek',
			'homeLayout.content' => 'obsah',
			'homeLayout.showThisRowIn' => 'Zobrazit tento řádek v:',
			'homeLayout.libraryRecommended' => 'Doporučená knihovna',
			'homeLayout.heroCard' => 'Hrdinská karta',
			'homeLayout.heroCardDescription' => 'Zobrazuje se jako jedna plnoširoká rotační karta namísto plakátového šelfu.',
			'homeLayout.heroUnavailableDescription' => 'Dostupné pouze tehdy, když se tento řádek vyřeší na skutečné tituly jedné kolekce - s více než jednou kolekcí vybranou neexistuje žádný jediný titul, který by se mohl otáčet.',
			'homeLayout.librariesSelection' => 'Knihovny (pustit všechny neprohlédnuté zahrnovat každou knihovnu)',
			'homeLayout.librariesMergedDescription' => 'Každá knihovna, která je zde kontrolována, je spojena do této jedné řady.',
			'homeLayout.movieCollectionsSelection' => 'Filmové sbírky (pustit všechny nezkontrolované pro každou vybranou knihovnu)',
			'homeLayout.showCollectionsSelection' => 'Zobrazit sbírky (zanechat všechny nezkontrolované pro každou vybranou knihovnu)',
			'homeLayout.collectionRowsDescription' => 'Pokud přesně jedna sbírka zápasí, jeho tituly se zobrazují přímo v řádku. Pokud více než jedna zápasí, každá sbírka se zobrazí jako jeden plakát - klepněte na něj, abyste tuto sbírku otevřeli.',
			'homeLayout.allCollections' => 'Všechny kolekce',
			'homeLayout.noRowsHere' => 'Zatím zde žádné řádky.',
			'homeLayout.hideWatchedRows' => 'Ukryte sledované položky v řádcích',
			'homeLayout.hideWatchedRowsDescription' => 'Plně sledované tituly opouštějí Domů a knihovny Doporučené řádky.',
			'homeLayout.untitledCollection' => 'Neznámá sbírka',
			'homeLayout.moveRowHint' => 'Up/Down: přejít řádek · Vyberte: přejít zde · Zpět: zrušit',
			'homeLayout.organizeRowsHint' => 'Vyberte v řádku (nebo držte Vyberte): přejděte · Levo/vpravo: možnosti řádku · Zpět: dokončeno',
			'homeLayout.layoutNavDescription' => 'Vyberte řádky, knihovny a kategorie sběru',
			'homeLayout.editHomeRow' => 'Edit Home řádek',
			'homeLayout.resetHeroButton' => 'Obnovte herecký layout na zásobu Plezy',
			'homeLayout.reorderingUnlocked' => 'Převedení odemknutého',
			'homeLayout.reorderingLocked' => 'Převod zamčené',
			'homeLayout.rowsCanBeDragged' => 'Krovy lze přetáhnout – klepněte na zámek, aby se zabránilo tomu, aby se',
			'homeLayout.tapLockToDrag' => 'Stiskněte zámek, abyste vytihli řádky',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Příslušenství: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Skrýt',
			'homeLayout.remove' => 'Odstranit',
			'homeLayout.libraryResumeRow' => 'Knižní přehled této knihovny',
			'homeLayout.pressAgainToDelete' => 'Znovu stiskněte, abyste odstranili',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'Na',
			'homeLayout.resetHeroButtonDescription' => 'Odstraní postavy hrdiny každé řady a přináší zpět jediný otáčící banner na vrcholu, stejně jako předtím, než hrdinské řady existovaly.',
			'homeLayout.tapHeroCardDescription' => 'Vyberte, zda klepnutí nebo výběr karty Hero zahájí přehrávání nebo otevírá jeho detaily.',
			'homeLayout.heroTapPlayDescription' => 'Začněte vybranou položku ihned.',
			'homeLayout.heroTapDetailsDescription' => 'Otevřete podrobnosti vybraného položky před výběrem akce.',
			'platform.localNetworkPermission' => 'PlezyNG se připojí k vašim mediálním serverům a přehrávačům na vaší místní síti.',
			'platform.locationPermission' => 'PlezyNG používá přístup k místu, když iOS vyžaduje, aby detekovala vaši místní síť a připojila se k vašim mediálním serverům.',
			'platform.photoLibraryPermission' => 'Vyberte si obrázky z vaší knihovny fotografií pro použití jako umělecké dílo.',
			'platform.cameraPermission' => 'Skenování QR kódů pro párování s Companion Remote.',
			'universalMedia.title' => 'Otevřené média',
			'universalMedia.shortcutHelp' => 'Zahrajte si odkaz, playlist nebo soubor pro tuto sezení.',
			'universalMedia.intro' => 'Otevřete odkaz, playlist nebo soubor. Playback používá standardní přehrávač PlezyNG a do vaší knihovny nepřidá historii.',
			'universalMedia.openWhat' => 'Co byste chtěli otevřít?',
			'universalMedia.stream' => 'Streamová adresa',
			'universalMedia.playlist' => 'Playlisty',
			'universalMedia.files' => 'Přístrojové soubory',
			'universalMedia.favorites' => 'Úsporný stream oblíbené',
			'universalMedia.address' => 'Mediální adresa',
			'universalMedia.addressHelp' => 'URL s uznanými parametry ověřování nebo podpisů se používají pouze pro tuto schůzku a nelze je uložit jako oblíbené.',
			'universalMedia.displayName' => 'Název zobrazení (volitelné)',
			'universalMedia.displayNameHelp' => 'Vyberte krátký název pro hráče a systémové médií ovládacích prvků.',
			'universalMedia.allowHttp' => 'Umožňuje nekryptované připojení HTTP',
			'universalMedia.allowHttpHelp' => 'HTTP nešifruje připojení. dovolte ho pouze na důvěryhodné síti. použijte HTTPS kdykoli je to možné.',
			'universalMedia.advancedProtocols' => 'MPV pouze: zadejte adresu RTSP, RTMP/RTMPS, UDP nebo RTP. Tyto adresy nelze uložit jako oblíbené.',
			'universalMedia.liveStream' => 'Léčba jako živá',
			'universalMedia.liveStreamHelp' => 'Použijte to pro živé video nebo rádio. aplikace skrývá časovou řádku, skok tlačítka a možnost go-to-time. vypněte ji pro záznam.',
			'universalMedia.privateSession' => 'Pouze tento přehrávač používá adresu.Save an eligible stream favorite to keep it in this profile.',
			'universalMedia.saveFavorite' => 'Zachraňte oblíbené',
			'universalMedia.playNow' => 'Hrajte nyní',
			'universalMedia.favoriteSaved' => 'Stream oblíbené uložené do tohoto profilu',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: 'Přepadl ${count} nepodporovaný nebo nebezpečný playlist vstup.', few: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.', many: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.', other: 'Zkracené ${count} nepodporované nebo nebezpečné playlist vstupy.', ), 
			'universalMedia.playlistAddress' => 'Playlistová adresa',
			'universalMedia.playlistAddressHelp' => 'Otevřete playlist M3U, M3u8 nebo PLS z webové adresy. Přímé streamovací odkazy nezachovávají playlist.',
			'universalMedia.choosePlaylist' => 'Vyberte soubor playlist',
			'universalMedia.openPlaylist' => 'Otevřená playlist',
			'universalMedia.playlistFormatsHelp' => 'Přehrávač může obsahovat až 1000 položek a 2 MB. HLS se otevírají jako toky, takže hráč si může vybrat kvalitu.',
			'universalMedia.noFavorites' => 'Není zachráněno stream oblíbené zatím. Oblíbené zůstanou v tomto profilu.',
			'universalMedia.removeFavorite' => 'Odstranit stream oblíbené',
			'universalMedia.filesHelp' => 'Vyberte si audio, video nebo ISO soubory pro dočasný průběh. Soubory a URL nejsou přidány do historie knihovny.',
			'universalMedia.chooseFiles' => 'Vyberte soubory',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '1 vybrané soubory', few: '${count} vybrané soubory', many: '${count} vybrané soubory', other: '${count} vybrané soubory', ), 
			'universalMedia.wifiTransfer' => 'Odesílání souborů přes Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Přenos podporovaných souborů z prohlížeče na stejnou důvěryhodnou síť.',
			'universalMedia.wifiTransferIntro' => 'Otevřete tuto adresu v prohlížeči na jiném zařízení. Vyberte soubory, abyste je přidali do knihovny souborů a knih tohoto zařízení.',
			'universalMedia.wifiTransferPrivacy' => 'Toto zařízení přijímá soubory přes vaši místní síť.Každý, kdo zná tuto adresu může poslat soubory až do zastavení přenosu nebo adresa vyprší po 15 minutách. Maximální: 100 souborů, 4 GiB na soubor, 10 GiB celkem.',
			'universalMedia.wifiTransferStarting' => 'Příprava soukromého, časově omezeného převodu...',
			'universalMedia.wifiTransferUnavailable' => 'Nemohla jsem začít přenosu. zkontrolujte přístup k místní síti a zkuste znovu.',
			'universalMedia.openThisAddress' => 'Otevřete jednu z těchto adres na odesílací zařízení',
			'universalMedia.copyAddress' => 'Kopírování transferové adresy',
			'universalMedia.addressCopied' => 'Přenosová adresa kopírovaná',
			'universalMedia.transferExpires' => ({required Object time}) => 'Tato adresa vyprší v ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${count} soubor přijatý', few: '${count} soubory obdržené', many: '${count} soubory obdržené', other: '${count} soubory obdržené', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Obdržel ${size}',
			'universalMedia.stopTransfer' => 'Zastavení přenosu a zrušení adresy',
			'universalMedia.startTransfer' => 'Začátek transferu',
			'universalMedia.wifiImportedFiles' => 'Přenos Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Odeslat soubory do PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Vyberte audio, video, ebook nebo komiksové soubory k odeslání. Soubory jsou uloženy v knihovně souborů a knih tohoto zařízení. Maximální: 100 souboru, 4 GiB na soubor, 10 GiB celkem.',
			'universalMedia.uploadFilesLabel' => 'Soubory k odesílání',
			'universalMedia.uploadSelected' => 'Stáhnout vybrané soubory',
			'universalMedia.uploadSelectFirst' => 'Nejprve vyberte jeden nebo více souborů.',
			'universalMedia.uploading' => 'Odesílání',
			'universalMedia.uploadComplete' => 'Soubor přidán do PlezyNG.',
			'universalMedia.uploadFailed' => 'Soubor nelze přidat. Držte tuto stránku otevřenou a zkuste znovu.',
			'universalMedia.liveCue' => 'Životní',
			'universalMedia.liveSession' => 'Živý stream',
			'universalMedia.liveCueHelp' => 'V případě živého videa nebo rozhlasu aplikace ukrývá časovou řádku a skáče tlačítka. nezachovává adresu ani sleduje historii.',
			'universalMedia.sessionOnly' => 'Tento playback je pouze session-',
			'universalMedia.sessionOnlyHelp' => 'Playback nikdy nezachrání pokrok nebo historii. Zachraňte tok jako oblíbený, abyste ho udrželi v tomto profilu, pokud je způsobilý.',
			'universalMedia.pictureAdjustments' => 'Fotografické úpravy',
			'universalMedia.pictureHelp' => 'Tyto změny obrazu ovlivňují pouze tento playback. Oni reset, když playback skončí.',
			'universalMedia.resetPicture' => 'Reset obrázek',
			'universalMedia.brightness' => 'Světlo',
			'universalMedia.contrast' => 'kontrast',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturace',
			'universalMedia.view360' => 'Flat View pro 360° video',
			'universalMedia.view360Help' => 'Použijte toto pro rovnoměrné 360° video. MPV potřebuje filtr v360 FFmpeg pro tento pohled.',
			'universalMedia.view360Unavailable' => 'Tento mpv stav by nemohl použít 360° filtr.',
			'universalMedia.view360Yaw' => 'Horizontální pohled',
			'universalMedia.view360Pitch' => 'Vertikální pohled',
			'universalMedia.view360FieldOfView' => 'Oblast pohledu',
			'universalMedia.recordStream' => 'Rekordní živý stream',
			'universalMedia.stopRecording' => 'Zastavte a ušetřete záznam',
			'universalMedia.recordingStarted' => 'Záznam je aktivní.Leaving playback zastaví a ukládá záznam.',
			'universalMedia.recordingSaved' => 'Záznam byl dokončen a zachráněn.',
			'universalMedia.recordingActive' => 'Zanechání playback se zastaví a ukládá.',
			'universalMedia.recordingFormatHelp' => 'Pro video, vyberte MKV nebo MPEG-TS. pro audio, zvolte MKA nebo MKV.',
			'universalMedia.replaceRecordingTitle' => 'Změníte tuto nahrávku?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG obnovuje stávající soubor při zaznamenávání. Pokud nemůže uložit novou záznam, Plezy NG obnovuje zálohu.',
			'universalMedia.replaceRecording' => 'nahrazení souborů',
			'universalMedia.discHelp' => 'Otevřete disk v optickém disku tohoto počítače.Můžete také otevřít obraz ISO z souborů zařízení.',
			'universalMedia.discs' => 'Optický disk',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disk playback vyžaduje kompatibilní MPV stavbu, podporovaný disk a oprávnění operačního systému.',
			'universalMedia.converterTitle' => 'Konvertovat soubor místních médií',
			'universalMedia.converterHelp' => 'Použijte FFmpeg, abyste vytvořili MP4, M4A nebo MP3 kopii.',
			'universalMedia.converterIntro' => 'Konvertovat místní audio nebo video soubor do formátu, který funguje na více zařízeních.',
			'universalMedia.converterPrivacy' => 'FFmpeg musí být nainstalován na tomto počítači. konverze čte pouze místní soubory. nedodává toky nebo odstraňuje DRM.',
			'universalMedia.converterChooseInput' => 'Vyberte si místní mediální soubor',
			'universalMedia.converterFormat' => 'Výstupní formát',
			'universalMedia.converterMp4' => 'MP4 · H.264 a AAC',
			'universalMedia.converterM4a' => 'M4A - AAC audio',
			'universalMedia.converterMp3' => 'MP3 a audio',
			'universalMedia.converterSaveAs' => 'Shromažďování převedených médií jako',
			'universalMedia.converterExtensionMismatch' => 'Vyberte název s vybraným rozšířením výstupu.',
			'universalMedia.converterUnsupportedInput' => 'Vyberte si audio nebo video soubor.',
			'universalMedia.converterLocalOnly' => 'Vybraný soubor není k dispozici jako místní zařízení.',
			'universalMedia.converterReplaceTitle' => 'Změnit tento soubor?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG obnovuje stávající soubor, dokud se neukládá převedená kopie.',
			'universalMedia.converterStarting' => 'Začínáme s FFmpeg...',
			'universalMedia.converterProgress' => 'Přeměna na tento počítač...',
			'universalMedia.converterComplete' => 'Konverze je hotová, nový soubor je připraven.',
			'universalMedia.converterFfmpegMissing' => 'Instalujte FFmpeg s podporou H.264, AAC a MP3, pak zkuste znovu.',
			'universalMedia.converterFailed' => 'Přesvědčte se, že zdrojový soubor lze přečíst a destinace má dostatek volného prostoru.',
			'universalMedia.converterCancelled' => 'Konverze byla zrušena. neúplný výsledek byl odstraněn.',
			'universalMedia.converterDesktopOnly' => 'Lokální konverze je k dispozici na desktopových počítačích s FFmpeg instalován.',
			'universalMedia.converterStart' => 'Převod souborů',
			'universalMedia.mediaToolsTitle' => 'Média nástroje',
			'universalMedia.mediaToolsShortcut' => 'Zachyťte nebo sdílejte média, přidejte vyhledávací rozšíření nebo použijte příkazovou řadu.',
			'universalMedia.mediaToolsIntro' => 'Vyberte si zaměřený nástroj. zachytit a stream-out používat FFmpeg nainstalované na tomto desku. rozšíření a CLI příkazy používají omezené požadavky HTTPS a stávající Open media tok.',
			'universalMedia.mediaToolsAccessibility' => 'Výběry nástrojů a kontroly pracují s dotykem, ukazatelem, klávesnicí a zaměřením D-pad. Změny v stavu nahrávání, sdílení a vyhledávání jsou oznámeny.',
			'universalMedia.mediaTool' => 'Média nástroj',
			'universalMedia.captureIntro' => 'Na tomto počítači zaznamenáváte obrazovku nebo fotoaparát do souboru MP4. FFmpeg musí být nainstalován a obsahuje kódovač H.264.',
			'universalMedia.captureNoDevices' => 'Nebyly nalezeny žádné obrazovky nebo fotoaparáty. zkontrolujte FFmpeg zachycenou podporu a oprávnění k soukromí operačního systému.',
			'universalMedia.captureSource' => 'obrazovka nebo fotoaparát',
			'universalMedia.captureScreen' => 'obrazovka',
			'universalMedia.captureAudioSource' => 'Audio vstup (volitelné)',
			'universalMedia.captureAudioHelp' => 'Přidejte zvuk z mikrofonu nebo dostupného vstupu. volby zařízení závisí na FFmpeg a systémových povoleních.',
			'universalMedia.captureAudioNone' => 'Žádný audio',
			'universalMedia.captureDefaultAudio' => 'Předvolený audio vstup',
			'universalMedia.captureWaylandHelp' => 'Wayland omezuje toto XWayland zachycení na X display. Windows mimo XWayland se nemusí zobrazit.',
			'universalMedia.captureFrameRate' => 'Rekordní rámová sazba',
			'universalMedia.capturePrivacy' => 'Záznam se ukládá pouze na vybranou souboru. mikrofonový záznam je volitelný. PlezyNG záznam nezakládá.',
			'universalMedia.captureSaveAs' => 'Shromažďujte záznam obrazovky jako',
			'universalMedia.captureExtensionMismatch' => 'Vyberte název, který končí v .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg nebo kódování videa H.264 není k dispozici. nainstalovat podporované FFmpeg stavbu, pak zkuste znovu.',
			'universalMedia.captureFailed' => 'Zkontrolujte oprávnění zařízení, dostupné ukládání a podporu FFmpeg.',
			'universalMedia.captureSaved' => 'Scénární záznam byl zachráněn.',
			'universalMedia.captureElapsedLabel' => 'Záznamový čas',
			'universalMedia.captureStart' => 'Začíná nahrávání',
			'universalMedia.captureStop' => 'Zastavte se a zachraňte',
			'universalMedia.captureMode' => 'únos',
			'universalMedia.shareMode' => 'Sdílejte',
			'universalMedia.shareIntro' => 'Odeslat soubor místních médií do jiného zařízení na vaší soukromé síti. PlezyNG vytváří dočasný tok HLS.',
			'universalMedia.sharePrivacy' => 'Kdokoliv na vaší místní síti, kdo dostává soukromý odkaz může sledovat, zatímco je aktivní. odkaz vyprší po 60 minutách. zastavit sdílení, aby se server uzavřel a zrušit odkaz.',
			'universalMedia.shareChooseFile' => 'Vyberte mediální soubor',
			'universalMedia.shareChooseHelp' => 'Vyberte místní audio nebo video soubor. soubor zůstává na tomto počítači.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg nebo kódování H.264/AAC nejsou k dispozici. Instalace FFmpeg s podporou kódování H.264 a AAC.',
			'universalMedia.shareFailed' => 'Stream se nemohl začít ani nečekaně zastavit. zkontrolujte FFmpeg a přístup k síti.',
			'universalMedia.shareActive' => 'Stream je připraven na vaší soukromé síti.',
			'universalMedia.shareEnded' => 'Média dosáhla konce a už se nedělá.',
			'universalMedia.shareStopped' => 'Sdílení přerušeno. dočasný odkaz již neplatí.',
			'universalMedia.shareUrlCopied' => 'Přenosová adresa je kopírována.',
			'universalMedia.shareOpenUrl' => 'Otevřete tuto adresu v jednom hráči na jiném zařízení',
			'universalMedia.shareQrLabel' => 'QR kód pro dočasnou adresu toku',
			'universalMedia.shareQrHelp' => 'Skenování pomocí kompatibilního přehrávače připojeného k téže soukromé síti.',
			'universalMedia.shareHttpHint' => 'Tento tok používá nekryptované HTTP. V PlezyNG, dovolte HTTP před otevřením.',
			'universalMedia.shareCopyUrl' => 'Kopírování streamové adresy',
			'universalMedia.shareExpiresLabel' => 'Link vyprší na',
			'universalMedia.shareStarting' => 'Připravování toku...',
			'universalMedia.shareStart' => 'Začněte sdílet',
			'universalMedia.shareStop' => 'Přestaňte sdílet',
			'universalMedia.extensionsMode' => 'Rozšíření a CLI',
			'universalMedia.extensionsIntro' => 'Přidejte data-pouze vyhledávací rozšíření najít média. Vyberte výsledek, aby ji přenést do známého formuláře Open media.',
			'universalMedia.extensionsPrivacy' => 'Manifest může definovat jedno HTTPS vyhledávací koncové body a mapové odpovídající pole. Nemůže spustit kód, přidat název žádosti, číst soubory, nebo spustit příkazy shell.',
			'universalMedia.extensionImport' => 'Přidat rozšíření manifest',
			'universalMedia.extensionEmpty' => 'Zvolte důvěryhodný manifest JSON soubor pro přidání.',
			'universalMedia.extensionChoose' => 'Vyhledávací služba',
			'universalMedia.extensionSearchConsent' => 'Každé vyhledávání odesílá vaše slova k této službě HTTPS. Výsledky se otevřou pouze po vybrání jednoho.',
			'universalMedia.extensionSearchLabel' => 'Vyhledávání médií',
			'universalMedia.extensionSearch' => 'Vyhledávání',
			'universalMedia.extensionSearching' => 'Hledání...',
			'universalMedia.extensionNoResults' => 'Bezpečné výsledky médií nebyly vráceny. zkuste další vyhledávání.',
			'universalMedia.extensionInstallTitle' => 'Přidejte tuto vyhledávací službu?',
			'universalMedia.extensionReplaceTitle' => 'Aktualizovat tuto službu vyhledávání?',
			'universalMedia.extensionService' => 'Služba',
			_ => null,
		} ?? switch (path) {
			'universalMedia.extensionEndpoint' => 'HTTPS konečný bod',
			'universalMedia.extensionConsent' => 'Váš vyhledávací text je zaslán do této služby. manifest neobsahuje prováděcí kód. Pokračujte pouze v případě, že důvěřujete tomuto bodu.',
			'universalMedia.extensionInstall' => 'Přidat službu',
			'universalMedia.extensionReplace' => 'Aktualizace služby',
			'universalMedia.extensionRemoveTitle' => 'Odstranit tuto vyhledávací službu?',
			'universalMedia.extensionRemoveHelp' => 'To odstraní službu z tohoto profilu. PlezyNG se s jeho koncovým bodem nesetká.',
			'universalMedia.extensionRemove' => 'Odstranění služby',
			'universalMedia.extensionInvalidManifest' => 'Tento soubor není podporovaným rozšířením manifest. viz průvodce Open media pro formát.',
			'universalMedia.extensionSaveFailed' => 'Rozšíření nelze uložit do aktivního profilu.',
			'universalMedia.extensionSearchFailed' => 'Vyhledávací služba nevrátila platnou odpověď. zkontrolujte koncový bod a zkuste znovu.',
			'universalMedia.cliTitle' => 'Příkazová linka',
			'universalMedia.cliHelp' => 'Použijte průvodce plezyctl k ověření manifestu nebo vyhledávání stejného rozšíření. Před každým vyhledáváním zkontrolujte službu HTTPS. Výsledky se otevřou ve stávající mediální formě; vyberte tlačítko zpětné vazby.',
			'universalMedia.cliCopyExample' => 'Kopírování příkladu',
			'universalMedia.cliCopied' => 'Příklad příkazů kopírován.',
			'fileSources.title' => 'Soubory a knihy',
			'fileSources.subtitle' => 'Číst, poslouchat a sledovat z vlastních souborů.',
			'fileSources.add' => 'Přidat zdroj',
			'fileSources.importFiles' => 'Import souborů',
			'fileSources.localFiles' => 'Na tomto zařízení',
			'fileSources.source' => 'Zdroj',
			'fileSources.name' => 'Jméno',
			'fileSources.endpoint' => 'server URL',
			'fileSources.smbEndpointHint' => 'Příklad: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Zadejte server SMB a jednu sdílenou složku.',
			'fileSources.root' => 'Složka nebo předpona',
			'fileSources.smbFolderHelp' => 'Pro použití celé sdílené složky ponechte prázdné, nebo zadejte složku uvnitř ní.',
			'fileSources.username' => 'Uživatelské jméno',
			'fileSources.smbDomain' => 'Doména (nepovinné)',
			'fileSources.password' => 'Heslo',
			'fileSources.token' => 'API token',
			'fileSources.accessKey' => 'přístupový klíč ID',
			'fileSources.secretKey' => 'Tajný přístupový klíč',
			'fileSources.sessionToken' => 'Session token (volitelné)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth klient ID',
			'fileSources.clientSecret' => 'OAuth klientská tajemství (pouze desktop Google)',
			'fileSources.allowHttp' => 'Povolit nešifrované HTTP v důvěryhodné síti',
			'fileSources.smbEncryption' => 'Šifrovat připojení SMB3',
			'fileSources.smbEncryptionHint' => 'Použít šifrování SMB3, pokud ho NAS podporuje.',
			'fileSources.connect' => 'Připojit',
			'fileSources.cancel' => 'Zrušit',
			'fileSources.save' => 'Uložit',
			'fileSources.close' => 'Zavřít',
			'fileSources.removeSource' => 'Odstranění zdroje',
			'fileSources.disconnectMessage' => 'Odpojit tento zdroj? Stažené soubory a historie čtení a poslechu zůstanou v tomto zařízení.',
			'fileSources.localFolder' => 'Vyberte složku',
			'fileSources.empty' => 'Nic zde zatím',
			'fileSources.emptyHint' => 'Přidejte zdroj nebo importujte knihu, audioknihu, hudbu nebo video.',
			'fileSources.search' => 'Vyhledejte tento složku',
			'fileSources.searchCached' => 'Vyhledávání zachráněné knihovny',
			'fileSources.refresh' => 'Aktualizovat',
			'fileSources.loadMore' => 'Naložte více',
			'fileSources.offline' => 'Dostupné offline',
			'fileSources.download' => 'Zůstaňte offline',
			'fileSources.removeDownload' => 'Odstranit offline kopii',
			'fileSources.continueReading' => 'Číst dál',
			'fileSources.continueListening' => 'Pokračovat v poslechu',
			'fileSources.continueWatching' => 'Pokračovat ve sledování',
			'fileSources.read' => 'Číst',
			'fileSources.listen' => 'Poslechněte',
			'fileSources.play' => 'Přehrát',
			'fileSources.pause' => 'Pozastavit',
			'fileSources.stop' => 'Zastavit',
			'fileSources.startOver' => 'Začíná',
			'fileSources.finished' => 'dokončená',
			'fileSources.markFinished' => 'Mark skončil',
			'fileSources.markUnfinished' => 'Mark nekonečný',
			'fileSources.editions' => 'Edice a soubory',
			'fileSources.chapters' => 'Kapitoly',
			'fileSources.bookmarks' => 'Bookmark a poznámky',
			'fileSources.bookmark' => 'Přidat bookmark',
			'fileSources.highlight' => 'Vysvětlení',
			'fileSources.note' => 'Poznámka',
			'fileSources.delete' => 'Odstranit',
			'fileSources.export' => 'Exportní poznámky',
			'fileSources.exported' => 'Poznámky vyvážené',
			'fileSources.sync' => 'Synchronizace pokroku',
			'fileSources.synced' => 'Synchronizace pokroku',
			'fileSources.conflict' => 'Další zařízení má jinou pozici. vyberte, kde pokračovat.',
			'fileSources.useLocal' => 'Použijte tento přístroj',
			'fileSources.useRemote' => 'Použijte jiné zařízení',
			'fileSources.history' => 'Historie pozice',
			'fileSources.groupAudio' => 'Poslech jako jedna audioknihy',
			'fileSources.groupHint' => 'Kombinuje audio soubory v současné době nahrané v tomto složce. Nejprve nahrajte všechny stránky.',
			'fileSources.order' => 'File objednávka',
			'fileSources.moveUp' => 'Přemístěte se',
			'fileSources.moveDown' => 'Přemístěte se dolů',
			'fileSources.speed' => 'Rychlost přehrávání',
			'fileSources.sleep' => 'Časový spánek',
			'fileSources.sleepOff' => 'Vypnuto',
			'fileSources.endChapter' => 'Konec kapitoly',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuta', few: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuty', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minut', ), 
			'fileSources.skipBack' => 'Skok zpět',
			'fileSources.skipForward' => 'Skok dopředu',
			'fileSources.smartRewind' => 'Inteligentní zpět po přestávce',
			'fileSources.playbackOptions' => 'Poslouchací možnosti',
			'fileSources.remaining' => ({required Object time}) => '${time} Zbývající',
			'fileSources.contents' => 'obsah',
			'fileSources.readerSettings' => 'Čtení nastavení',
			'fileSources.fontSize' => 'Velikost textu',
			'fileSources.lineHeight' => 'Řádkování',
			'fileSources.margin' => 'Margín',
			'fileSources.font' => 'Typové',
			'fileSources.serif' => 'Patkové písmo',
			'fileSources.sans' => 'Bezpatkové písmo',
			'fileSources.mono' => 'Neproporcionální písmo',
			'fileSources.columns' => 'Kolony',
			'fileSources.scroll' => 'Sklíč vertikálně',
			'fileSources.justify' => 'Zarovnat text do bloku',
			'fileSources.readerTheme' => 'Pohled stránky',
			'fileSources.appTheme' => 'Sledujte téma aplikace',
			'fileSources.paper' => 'Papír',
			'fileSources.sepia' => 'Sepi',
			'fileSources.night' => 'Noční',
			'fileSources.readAloud' => 'Přečíst tuto stránku nahlas',
			'fileSources.readAlong' => 'Číst dál',
			'fileSources.stopReading' => 'Zastavit předčítání',
			'fileSources.searchBook' => 'Vyhledávání v knize',
			'fileSources.noMatches' => 'Žádné zápasy',
			'fileSources.previousPage' => 'Předchozí stránka',
			'fileSources.nextPage' => 'Další stránka',
			'fileSources.page' => ({required Object number}) => 'Stránka ${number}',
			'fileSources.externalBlocked' => 'V čtenáři jsou vnější odkazy na knihu zrušeny.',
			'fileSources.loading' => 'Otevření...',
			'fileSources.narrator' => 'Příběh',
			'fileSources.audio' => 'Zvuk',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'ebooky',
			'fileSources.all' => 'Vše',
			'fileSources.downloads' => 'Offline soubory',
			'fileSources.confirmDelete' => 'Odstraňte vybranou offline kopii? Vaše poloha a poznámky zůstávají.',
			'fileSources.errorAuthentication' => 'Zadejte si znovu a znovu se připojte k tomuto zdroji.',
			'fileSources.errorPermission' => 'Tento zdroj neposkytl přístup k požadovanému souboru.',
			'fileSources.errorUnavailable' => 'Zdroj není k dispozici. zkuste znovu, nebo otevřete offline kopii.',
			'fileSources.errorUnsupported' => 'Tento formát nebo připojení není na tomto zařízení podporován. zkontrolujte průvodce nastavení zdroje.',
			'fileSources.errorInvalidData' => 'Tento soubor nebo odpověď serveru nelze bezpečně číst.',
			'fileSources.errorCancelled' => 'Operace byla zrušena.',
			'fileSources.errorConflict' => 'Pozice se změnila v jiné sezení. znovu otevřete položku, abyste si vybrali pozici.',
			'fileSources.signIn' => 'Přihlásit se',
			'fileSources.reconnect' => 'Připojení',
			'fileSources.folderHelp' => 'Nechte bělo na začátku na zdrojovém kořene. URL S3 zahrnuje bucket.',
			'fileSources.preferences' => 'preferencí',
			'fileSources.timePosition' => 'Pozice',
			'fileSources.audioTrack' => 'Zvuková stopa',
			'fileSources.subtitleTrack' => 'Subtitle Track',
			'fileSources.none' => 'Žádný',
			'fileSources.fullscreen' => 'Celá obrazovka',
			'fileSources.syncLocation' => 'Progress sync folder (volitelné)',
			'fileSources.syncLocationHint' => 'Vyhrazená složka WebDAV pro stav aplikace PlezyNG. Zápis probíhá podmíněně; mediální soubory zůstávají beze změny.',
			'fileSources.audiobooks' => 'Audioknihy',
			'fileSources.comics' => 'Komiksy',
			'fileSources.scan' => 'Skenování knih a médií',
			'fileSources.browserReader' => 'Otevřený čtenář',
			'fileSources.browserReaderHelp' => 'Čtečka je otevřena ve vašem prohlížeči.Zachovávejte PlezyNG otevřený, abyste ušetřili své místo a poznámky.',
			'fileSources.on' => 'Na',
			'fileSources.advancedSetup' => 'App registrace',
			'fileSources.microsoftSignIn' => 'Přihlaste se k Microsoftu',
			'fileSources.zoomIn' => 'Zoom v',
			'fileSources.zoomOut' => 'Zoom ven',
			'fileSources.fitPage' => 'Fit stránka',
			'fileSources.fitWidth' => 'Vhodná šířka',
			'fileSources.actualSize' => 'Aktuální velikost',
			'fileSources.goToPage' => 'Přejděte na stránku',
			'fileSources.goToSection' => 'Přejděte do kapitoly',
			'fileSources.pageRange' => ({required Object count}) => 'Zadejte číslo od 1 do ${count}',
			'fileSources.pageLayout' => 'Stránka layout',
			'fileSources.automatic' => 'automatické',
			'fileSources.singlePage' => 'Jednotlivá stránka',
			'fileSources.twoPages' => '2 Stránky',
			'fileSources.readingDirection' => 'Čtení směr',
			'fileSources.leftToRight' => 'Zleva doprava',
			'fileSources.rightToLeft' => 'Zprava doleva',
			'fileSources.letterSpacing' => 'Dopis k prostoru',
			'fileSources.wordSpacing' => 'Slovo spacing',
			'fileSources.readerControlsHelp' => 'Stránky zvětšíte roztažením dvou prstů nebo pomocí ovládání přiblížení. Tažením stránku posunete. Ctrl/⌘ s + nebo − upravuje přiblížení; Ctrl/⌘ s 0 ho obnoví. Page Up a Page Down otáčejí stránky.',
			'fileSources.imagePage' => 'Komiksová stránka',
			'fileSources.resetReader' => 'Obnovit výchozí nastavení čtení',
			'fileSources.zoom' => 'Přiblížit',
			'fileSources.useFiles' => 'Použijte soubory a knihy',
			'fileSources.cancelScan' => 'Zrušit skenování',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Limit pro offline stahování',
			'fileSources.offlineQuotaHelp' => 'Nastavení maximálního místa použitého offline kopie, dovezené soubory a stažené stahování. Snížení limitu neodstraňuje stávající kopie.',
			'fileSources.offlineStorageUsage' => 'Offline skladování',
			'fileSources.reservedStorage' => 'Rezervované',
			'fileSources.downloadQueue' => 'Stáhnout Queue',
			'fileSources.downloadRunning' => 'Stáhnout',
			'fileSources.downloadQueued' => 'Čekání',
			'fileSources.downloadPaused' => 'Odpočinek',
			'fileSources.downloadFailed' => 'Potřebuji zpět',
			'fileSources.importing' => 'dovoz',
			'fileSources.importInterrupted' => 'Import přerušený · odstranit k vymazání',
			'fileSources.errorQuotaExceeded' => 'Zvýšení limitu nebo odstranění stažené kopie.',
			'fileSources.errorStorageLow' => 'Neexistuje dostatek bezplatného ukládání zařízení k zachování chráněné rezervy.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG nemohl kontrolovat bezplatné ukládání zařízení, takže psaní bylo zastaveno.',
			'fileSources.removeDownloadJob' => 'Odstranit download',
			'fileSources.downloadAlreadyComplete' => 'Toto stahování bylo dokončeno, než by mohlo být odstraněno. položka je nyní k dispozici offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Odstranit toto stahování a odstraňovat jakékoli částečně stažené údaje? Vaše poloha a poznámky zůstane.',
			'lending.title' => 'veřejné knihovny',
			'lending.add' => 'Přidejte knihovnu',
			'lending.other' => 'Další knihovna',
			'lending.libraryName' => 'Název knihovny',
			'lending.libraryUrl' => 'knihovny WEB',
			'lending.libraryUrlHint' => 'Použijte katalog své knihovny nebo její přihlašovací stránku.',
			'lending.intro' => 'Půjčte si knihu z knihovny, držte si knihy v blízkosti.',
			'lending.handoff' => 'Přihlaste se, vypůjčujte si knihy a bezpečně čtěte prostřednictvím služby své knihovny.',
			'lending.openService' => 'otevřená knihovna',
			'lending.findLibrary' => 'Najít knihovnu',
			'lending.search' => 'Vyhledávání knih a autorů',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'půjčky',
			'lending.holds' => 'Rezervace',
			'lending.signIn' => 'Přihlaste se k vaší knihovně',
			'lending.waiting' => 'Přihlaste se do svého prohlížeče a pak se vrátíte.',
			'lending.cancel' => 'Zrušit',
			'lending.disconnect' => 'Odstranit knihovnu',
			'lending.disconnectMessage' => 'Odebrat tuto knihovnu z tohoto profilu? Vaše výpůjčky a rezervace zůstanou u knihovny.',
			'lending.getBook' => 'Získejte knihu',
			'lending.checkAvailability' => 'Zkontrolujte dostupnost',
			'lending.available' => 'Dostupné k půjčování',
			'lending.unavailable' => 'V současné době nedostupné',
			'lending.borrow' => 'Vypůjčit',
			'lending.placeHold' => 'Rezervovat',
			'lending.returnBook' => 'Zpět brzy',
			'lending.cancelHold' => 'Zrušit rezervaci',
			'lending.confirmBorrow' => 'Půjčujete si tento titul z vaší knihovny?',
			'lending.confirmReturn' => 'Vrátit tento titul nyní? Abyste mohli pokračovat, možná si jej budete muset znovu vypůjčit.',
			'lending.confirmCancelHold' => 'Zrušit rezervaci tohoto titulu?',
			'lending.email' => 'Udržujte e-mail oznámení',
			'lending.due' => ({required Object date}) => 'Vrátit do ${date}',
			'lending.queue' => ({required Object position}) => 'Pozice ${position} v čáru',
			'lending.empty' => 'Zatím tu žádné tituly.',
			'lending.openLibraryNote' => 'Procházejte katalog Open Library. Možnosti čtení a vypůjčení jsou uvedeny na stránce každého titulu.',
			'lending.more' => 'Naložte více',
			'lending.gateway' => 'knihovny sign-in',
			'lending.gatewayHint' => 'Zajištěno vaší knihovnou nebo správcem PlezyNG.',
			'lending.advanced' => 'knihovny integrace',
			'lending.loadLibraries' => 'Vyberte si svou knihovnu',
			'lending.expired' => 'Tento úvěr skončil.',
			'lending.updated' => 'Aktualizovaná knihovna',
			'lending.continueService' => 'Pokračovat ve službě',
			'lending.comingSoon' => 'In-app půjčka · Brzy přijde',
			'lending.comingSoonDescription' => 'Libby integrace je na cestě.Můžete použít vaši knihovnu v Libby, zatímco my dokončujeme připojení.',
			'lending.suspendHold' => 'Pozastavit rezervaci',
			'lending.resumeHold' => 'Obnovit rezervaci',
			'lending.suspendMessage' => 'Ponechat si místo ve frontě a nechat dalšího čtenáře vypůjčit si tento výtisk? Rezervaci můžete později obnovit.',
			'lending.resumeMessage' => 'Obnovit rezervaci, aby vám knihovna mohla nabídnout další dostupný výtisk?',
			'lending.editEmail' => 'Změna e-mailu oznámení',
			'audiobook.syncTitle' => 'Čtení a poslouchání synchronizace',
			'audiobook.syncHelp' => 'Udržujte pozice čtení, pozice poslouchání, stav dokončení, poznámky a poznámky na vašich zařízeních. Vyberte připojený úložiště a použijte stejný synchronizační kód na každém zařízení. Čtení a poslouchání zůstávají oddělené.',
			'audiobook.addSyncSource' => 'Nejprve přidejte Google Drive, OneDrive, Dropbox, WebDAV nebo S3 do souborů a knih.',
			'audiobook.syncDestination' => 'Synchronizace účtu',
			'audiobook.syncFolder' => 'Synchronizace mapy nebo prefiksů',
			'audiobook.syncFolderHelp' => 'Použijte samostatnou stávající složku ve vašem WebDAV zdroji nebo předpisu S3.',
			'audiobook.syncCode' => 'Soukromý synchronizační kód',
			'audiobook.syncCodeHelp' => 'Vytvořte kód na prvním zařízení, pak zadejte tento kód na jiných zařízeních. Udržujte soukromou kopii: je to klíč k vašemu šifrovanému stavu. Použijte pro každou osobu jiný kód.',
			'audiobook.showCode' => 'Zobrazit nebo skrýt synchronizační kód',
			'audiobook.newSyncCode' => 'Vytvořte nový synchronizační kód',
			'audiobook.saveSync' => 'Shromažďovat a synchronizovat',
			'audiobook.disableSync' => 'Vypněte synchronizaci na tomto zařízení',
			'audiobook.syncSourceDisconnect' => 'Odstranění tohoto zdroje vypne čtení a poslouchání synchronizace zde. šifrované synchronizace soubory zůstane v poskytovateli.',
			'audiobook.syncReconnect' => 'Připojení úložného účtu',
			'audiobook.lastSynced' => ({required Object time}) => 'Poslední synchronizace na ${time}',
			'audiobook.syncPrivacy' => 'Pouze šifrovaný pokrok a poznámky jsou uloženy. Audio a ebook soubory, účet tokeny a hesla nejsou nahrány. Google Drive a OneDrive používá aplikační úložiště; Dropbox používá PlezyNG Sync. Povolit synchronizaci může požadovat další psaní přístup. Zatímco je povolen, tato destinace vlastní progres synchronizaci; serverový pokrok zůstává oddělený.',
			'audiobook.syncConflicts' => 'Vyberte si, kde se vrátit',
			'audiobook.conflictHelp' => 'Tyto změny byly provedeny nezávisle.Vyberte pozici nebo verzi štítku, kterou chcete udržet.Poslední časový rámec nebo vyšší procento automaticky nevyhraje.',
			'audiobook.syncDevice' => ({required Object device}) => 'Přístroj ${device}',
			'audiobook.syncUnknownDevice' => 'Neznámý přístroj',
			'audiobook.deletedBookmark' => 'Odstraněná knižnice',
			'audiobook.finished' => 'Dokončené',
			'audiobook.readingPosition' => ({required Object percent}) => 'Číst · ${percent}%',
			'audiobook.chapterTimeline' => 'Kapitola Pokrok',
			'audiobook.bookTimeline' => 'Celá kniha Pokrok',
			'audiobook.bookRemaining' => ({required Object time}) => 'Čas zůstává v této knize: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Čas zůstává v této kapitole: ${time}',
			'audiobook.unknownRemaining' => 'Celkový čas k dispozici, když se hrají části',
			'audiobook.undoSeek' => 'Poslední hledání',
			'audiobook.customSpeed' => 'Přizpůsobená hrací rychlost',
			'audiobook.speedHelp' => 'Vybírejte rychlost od 0,25× do 4×.',
			'audiobook.apply' => 'aplikovat',
			'audiobook.customSleep' => 'Přizpůsobený čas spánku',
			'audiobook.sleepMinutes' => 'minuty (1 – 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Zastavte se po ${count} kapitolách',
			'audiobook.extendSleep' => 'Přidejte 5 minut',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Časovač spánku: ${time}',
			'audiobook.useDefaults' => 'Použijte tyto ovládací prvky pro nové knihy',
			'audiobook.librarySort' => 'Černé knihy',
			'audiobook.sortTitle' => 'Název',
			'audiobook.sortAuthor' => 'Autorka',
			'audiobook.sortNarrator' => 'Příběh',
			'audiobook.sortSeries' => 'Seriálový příkaz',
			'audiobook.sortRecent' => 'Nedávno otevřeno',
			'audiobook.statusFilter' => 'Status čtení',
			'audiobook.statusAll' => 'Všechny knihy',
			'audiobook.statusNew' => 'Nezačíná',
			'audiobook.statusProgress' => 'V pokroku',
			'audiobook.statusFinished' => 'Dokončené',
			'audiobook.goToTime' => 'Jděte do času',
			'audiobook.timeHelp' => 'Hodiny: minuty: sekundy nebo minuty: sekundy',
			'audiobook.recoveryHelp' => 'Exportujte nedávnou šifrovanou kopii před přenesením nebo opravou synchronizačních dat. Importy se spojí s aktuálním stavem; nikdy nenahrazují místní historii synchromu.',
			'audiobook.recoveryExport' => 'Export šifrované obnovení souborů',
			'audiobook.recoveryImport' => 'Import šifrované obnovení souborů',
			'audiobook.recoveryImportConfirm' => 'Spojte tento šifrovaný obnovení soubor s aktuálními čtení pozic a poznámky? existující historie bude zachována. sdílená knihovna a ID položky nejsou zahrnuty; nastavit odpovídající ID na každém zařízení před dovozem.',
			'audiobook.recoveryExported' => 'Šifrované obnovení souboru je uloženo.',
			'audiobook.recoveryImported' => 'Údaje o obnově se smítají.',
			'sourceSetup.savedCertificate' => 'Uložený certifikát serveru',
			'sourceSetup.nfsEndpointInvalid' => 'Zadejte adresu NFS, například nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Nenalezen žádný server DLNA. Zadejte adresu popisu zařízení ručně.',
			'sourceSetup.dlnaServers' => 'Mediální servery DLNA',
			'sourceSetup.dlnaUnavailable' => 'Vyhledávání DLNA není v této síti dostupné. Zadejte adresu popisu zařízení ručně.',
			'sourceSetup.dlnaSearching' => 'Hledání serverů DLNA v místní síti',
			'sourceSetup.networkSearching' => 'Prohledávání místní sítě…',
			'sourceSetup.dlnaDiscover' => 'Najít servery DLNA',
			'sourceSetup.dlnaHelp' => 'Vyhledávání závisí na multicastu v místní síti. Pokud se žádný server nezobrazí, zadejte výše adresu jeho popisu zařízení.',
			'sourceSetup.dlnaRoot' => 'ID objektu DLNA; ponechte prázdné pro kořen zařízení.',
			'sourceSetup.passwordOrKey' => 'Zadejte heslo nebo níže přidejte soukromý klíč.',
			'sourceSetup.sshFingerprint' => 'Otisk SHA256 hostitelského klíče SSH',
			'sourceSetup.sshFingerprintHelp' => 'Ověřte jej u správce serveru. Na serveru spusťte ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub a použijte hodnotu SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Ponechte prázdné pro zachování připnutého otisku nebo zadejte nový otisk serveru.',
			'sourceSetup.sshAuthentication' => 'Ověření SSH veřejným klíčem',
			'sourceSetup.sshAuthenticationHelp' => 'Nepovinné; podporováno je i ověření heslem.',
			'sourceSetup.privateKey' => 'Soukromý klíč (formát PEM nebo OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Heslová fráze soukromého klíče',
			'sourceSetup.nfsMountPort' => 'Port TCP služby připojení NFS',
			'sourceSetup.nfsMountPortHelp' => 'Výchozí: 20048',
			'sourceSetup.nfsUserId' => 'ID uživatele NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Výchozí: 1000. Použijte ID povolené exportem NFS na NAS.',
			'sourceSetup.nfsGroupId' => 'ID skupiny NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Výchozí: 1000. Použijte ID skupiny povolené exportem NFS na NAS.',
			'sourceSetup.nfsEncryption' => 'Vyžadovat šifrované NFS (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Vyžadovat TLS 1.3 pro NFS i službu připojení. Pokud jej NAS nepodporuje, spojení bude odmítnuto.',
			'sourceSetup.nfsTrustCertificate' => 'Vlastní CA NFS nebo certifikát serveru (PEM, nepovinné)',
			'sourceSetup.nfsTrustHelp' => 'Ponechte prázdné pro certifikáty, kterým toto zařízení důvěřuje. V případě potřeby přidejte certifikát soukromé CA nebo certifikát serveru podepsaný sebou samým; jeho názvy se musí shodovat s hostitelem v adrese NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Použijte certifikát CA nebo serveru ve formátu PEM. Nevkládejte soukromý klíč.',
			'sourceSetup.addTrustCertificate' => 'Přidat vlastní důvěryhodný certifikát',
			'sourceSetup.replaceTrustCertificate' => 'Nahradit uložený vlastní certifikát',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS používá běžné porty NFS a služby připojení a vyžaduje podporu RFC 9289 na NAS. Je nutné TLS 1.3. Název hostitele nebo IP adresa musí odpovídat certifikátu. UID/GID AUTH_SYS nadále platí i v šifrovaném kanálu.',
			'sourceSetup.clientCertificate' => 'Klientský certifikát (nepovinné)',
			'sourceSetup.clientCertificateHelp' => 'Umožňuje NAS ověřit tohoto klienta; ID AUTH_SYS stále podléhají pravidlům exportu NFS na NAS.',
			'sourceSetup.savedIdentity' => 'Bude použita uložená identita klienta.',
			'sourceSetup.replaceIdentity' => 'Nahradit uloženou identitu klienta',
			'sourceSetup.chooseIdentity' => 'Vybrat identitu klienta PKCS#12',
			'sourceSetup.identityPassphrase' => 'Heslová fráze identity klienta',
			'sourceSetup.identityPassphraseHelp' => 'Ponechte prázdné, pokud soubor nemá heslovou frázi.',
			'sourceSetup.removeIdentity' => 'Odebrat případnou uloženou identitu klienta',
			'sourceSetup.identityStorageHelp' => 'Identity klienta se ukládají do šifrovaného úložiště přihlašovacích údajů zdroje. Pokud chcete uloženou identitu zachovat, tuto část neměňte.',
			'sourceSetup.nfsLimitations' => 'NFSv3 přes TCP, pouze pro čtení. Bez RPC-with-TLS není provoz NFS šifrovaný. NAS musí povolit vybraná ID AUTH_SYS a neprivilegované klientské porty (často volba exportu „insecure“). NFSv4 ani UDP nejsou podporovány.',
			'sourceSetup.nfsSetupHelp' => 'Nápověda k nastavení NFS',
			'sourceSetup.nfsSetupHint' => 'Pokud se připojení nenaváže, zkontrolujte tato nastavení.',
			'sourceSetup.nfsSetupDetails' => 'Použijte export NFSv3 přes TCP. Je-li vyžadováno šifrování, musí NFS i služba připojení podporovat RPC-with-TLS. Vlastní certifikát ponechte prázdný pro certifikát serveru, kterému toto zařízení důvěřuje, nebo přidejte certifikát CA NAS či certifikát podepsaný sebou samým. Název v certifikátu musí odpovídat hostiteli koncového bodu. Pokud NAS vyžaduje vzájemné TLS, přidejte jeho identitu klienta PKCS#12. Nakonec ověřte, že export povoluje nastavená UID/GID AUTH_SYS a pravidla klientských portů.',
			'sourceSetup.ftpHelp' => 'FTP používá pasivní režim. Použijte ftp:// pro nešifrované FTP, ftpes:// pro explicitní TLS nebo ftps:// pro TLS (implicitní na portu 990; explicitní na ostatních portech).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Volitelné hledání titulků pro samostatná videa.',
			'sourceSetup.apiKey' => 'Klíč API',
			'sourceSetup.optionalUsername' => 'Uživatelské jméno účtu (nepovinné)',
			'sourceSetup.optionalPassword' => 'Heslo účtu (nepovinné)',
			'sourceSetup.subtitlePrivacy' => 'Získejte klíč API na opensubtitles.com. Hledání odesílá název videa a dostupná ID IMDb/TMDB, nikdy videosoubor. Klíč a volitelné přihlašovací údaje účtu jsou šifrovány spolu s tímto zdrojem.',
			'sourceSetup.automaticMetadata' => 'Automatická online metadata videa',
			'sourceSetup.metadataPrivacy' => 'Odesílá pouze název/rok z názvu souboru a čísla epizod nebo ID NFO, nikdy média ani přihlašovací údaje. Pole NFO mají nadále přednost.',
			'sourceSetup.nfsEncryptionFailure' => 'U šifrovaného NFS ověřte podporu RFC 9289 a TLS 1.3 u obou služeb NAS, název v certifikátu a UID/GID exportu. PlezyNG se nepokusí toto spojení zopakovat bez šifrování.',
			'sourceSetup.sourceConnecting' => 'Připojování ke zdroji',
			'sourceSetup.metadataSearchPrivacy' => 'Toto hledání názvu se odesílá do Trakt. Odesílá zadaný název, nikoli video ani přihlašovací údaje zdroje.',
			'sourceSetup.chooseMatch' => 'Vybrat shodu',
			'sourceSetup.metadataMatchHelp' => 'Před výběrem zkontrolujte název a rok. Trakt obdrží hledaný název; video zůstává ve svém zdroji.',
			'sourceSetup.metadataNoMatches' => 'Online nebyl nalezen odpovídající název. Zkuste jiný název.',
			'sourceSetup.metadataSearch' => 'Hledat online metadata',
			'sourceSetup.metadataLoading' => 'Vyhledávání online informací o filmech a seriálech…',
			'sourceSetup.metadataFromTrakt' => 'Online metadata z Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Nebyla nalezena automatická shoda názvu. Vyhledejte název a vyberte shodu.',
			'sourceSetup.metadataFailed' => 'Online metadata se nepodařilo načíst. Přehrávání i místní informace jsou stále dostupné.',
			'sourceSetup.videoDetailsLoading' => 'Načítání informací o videu',
			'sourceSetup.subtitleKeyRequired' => 'Je vyžadován klíč API OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Upravte tento souborový zdroj a přidejte klíč API OpenSubtitles do volitelných nastavení titulků.',
			'sourceSetup.subtitleSearchFailed' => 'Hledání titulků selhalo. Zkontrolujte klíč API, připojení a přístup ke službě.',
			'sourceSetup.subtitleApplyFailed' => 'Titulky se nepodařilo stáhnout nebo použít. Zkontrolujte připojení a zkuste jiný výsledek.',
			'sourceSetup.subtitleSearch' => 'Hledat na OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'Hledání používá název a dostupná ID IMDb/TMDB. Videosoubor zůstává ve svém zdroji. Před výběrem zkontrolujte jazyk, označení vynucených titulků či titulků pro sluchově postižené a hodnocení.',
			'sourceSetup.movieOrShow' => 'Film nebo seriál',
			'sourceSetup.subtitleTitleHint' => 'Zadejte název pro upřesnění výsledků',
			'sourceSetup.subtitleLanguage' => 'Jazyk titulků',
			'sourceSetup.subtitleSearching' => 'Hledání na OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Odpovídající titulky nebyly nalezeny. Zkuste jiný název nebo jazyk.',
			'sourceSetup.downloadSubtitle' => 'Stáhnout titulky',
			'sourceSetup.subtitle' => 'Titulky',
			'sourceSetup.nfsTlsRequired' => 'Vyžadováno RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => 'Nešifrované NFS',
			'sourceSetup.tlsEncrypted' => 'Šifrováno pomocí TLS',
			'sourceSetup.ftpPlain' => 'Nešifrované FTP',
			'sourceSetup.sshPinned' => 'Šifrované SSH · připnutý hostitelský klíč',
			'sourceSetup.smbEncrypted' => 'Šifrování SMB3 zapnuto',
			'sourceSetup.smbUnencrypted' => 'Šifrování SMB3 vypnuto',
			'sourceSetup.httpUnencrypted' => 'HTTP bez šifrování přenosu',
			'sourceSetup.checkEndpointSecurity' => 'Zkontrolovat zabezpečení koncového bodu',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Povinné pole: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Pro pole „${label}“ zadejte hodnotu od ${min} do ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Nahradit ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Vybraná identita klienta: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Hodnocení ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Stahování titulků: ${title}',
			'sourceSetup.sharedEntryPair' => 'Porovnejte tuto položku',
			'sourceSetup.sharedEntryPairHelp' => 'Vložte stejný ID pro tento položka na každém zařízení. Použijte stabilní sdílený identifikátor nebo vytvořte jeden a kopírujte ho do odpovídajícího položky. Pokrok se páří pouze tehdy, když typy souboru vydání, velikosti a objednávky se shodují. Blank odstraní toto mapování.',
			'sourceSetup.sharedEntryId' => 'Sdílené položky ID',
			'sourceSetup.generateSharedEntryId' => 'Vytvoření sdíleného ID položky',
			'sourceSetup.sharedLibraryId' => 'ID sdílené knihovny (volitelné)',
			'sourceSetup.sharedLibraryHelp' => 'Použijte stejný ID na zařízeních, které otevírají stejnou knihovnu.Tento veřejný ID pomáhá přenášet postup čtení a poznámky přes různé zdrojové připojení; není to heslo.Když poskytovatelé používají různé položky ID, páry těchto položek z jejich detailních obrazovek.',
			'sourceSetup.sharedLibraryInvalid' => 'Použijte 8 až 100 písmen, čísel, bodů, podkoží nebo hyfen.',
			'sourceSetup.generateSharedLibraryId' => 'Vytvoření sdíleného ID knihovny',
			'sourceSetup.nfsReadAhead' => 'Žádosti o čtení NFS',
			'sourceSetup.nfsReadAheadHelp' => 'Více paralelních čtení může zlepšit průchod na rychlém NAS nebo síti. Použijte 1 pokud server omezuje souběžné požadavky.',
			'sourceSetup.nfsReadTest' => 'Měření NFS čtení výkonu',
			'sourceSetup.nfsReadTestHelp' => 'Čte až 64 MiB z největšího souboru pro měření tohoto připojení NAS. To používá síťovou šířku pásma.',
			'sourceSetup.nfsQualificationResult' => 'NFS číst měření',
			'sourceSetup.nfsReadBytes' => 'Data čtení',
			'sourceSetup.nfsReadSpeed' => 'měřená rychlost',
			'sourceSetup.nfsReadRequests' => 'Čtěte žádosti',
			'sourceSetup.sharedEntryConflict' => 'Tento sdílený ID položky je již připojen k dalším položkám v této knihovně.',
			'comics.fitHeight' => 'Přizpůsobit výšce',
			'comics.readingMode' => 'Režim čtení',
			'comics.paged' => 'Stránky',
			'comics.webtoon' => 'Plynulé posouvání',
			'comics.coverAlone' => 'Zobrazit obálku samostatně',
			'comics.splitWide' => 'Rozdělit široké stránky',
			'comics.splitWideHelp' => 'Zobrazí každou polovinu samostatně v pořadí čtení. Při zapnutí se stránky nezobrazují ve dvojicích.',
			'comics.thumbnails' => 'Náhledy stránek',
			'comics.controlsHelp' => 'Přejetím otočíte stránku. Dvojitým klepnutím změníte přizpůsobení. Při plynulém posouvání přejeďte svisle nebo použijte Page Up a Page Down.',
			'comics.savedForComic' => 'Nastavení zobrazení se pro tento komiks ukládá v tomto profilu.',
			'comics.readLists' => 'Seznamy četby',
			'comics.collections' => 'Kolekce',
			'games.title' => 'Games',
			'games.enable' => 'Show Games for this profile',
			'games.enableDescription' => 'Discover your gaming computers and play with an embedded streaming engine.',
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
			'games.recent' => 'Recently opened',
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
			'games.libraryHint' => 'Choose a computer to connect and load its games. Once connected, choose a game to play inside PlezyNG.',
			'games.touchControls' => 'On-screen controller',
			'games.touchDescription' => 'Show the native controller during a stream. It supports multiple fingers, sticks, buttons and triggers.',
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
			'games.helpBody' => 'Enable Games for your profile, choose a computer and approve the first connection. Sunshine-compatible hosts load their app list into the game grid. On Android, Steam pairing opens Big Picture inside PlezyNG; saved Steam app-ID shortcuts launch directly. Steam pairing does not grant access to a private account library.\n\nBoth Android engines include touch controls and gamepad input. Pyrowave is an experimental Android option; other native platforms remain in development.\n\nPairing requires the host’s approval. Sunshine QR codes open its PIN page without carrying credentials. For access away from home, use the computer’s VPN address. Automatic discovery normally stays on the local network.\n\nDisconnecting leaves the game running on the computer.',
			'games.cancel' => 'Cancel',
			'games.scanning' => 'Looking for computers…',
			'games.saveShortcut' => 'Save shortcut',
			'games.manualHint' => 'For Moonlight use the host’s GameStream HTTP port (usually 47989), not its web settings port. Steam normally advertises on 27036.',
			'games.engineUnavailable' => 'In-app streaming is not available here yet',
			'games.nativeEnginePending' => 'This build does not include a streaming engine for this platform. You can save the computer, but it cannot play here yet.',
			'games.steamEnginePending' => 'This build does not include the embedded Steam engine. Android builds with Games enabled bundle device pairing and in-app H.264/HEVC playback. Pyrowave is experimental on Android; other platforms remain under development.',
			'games.steamBetaTitle' => 'Steam beta · Pyrowave',
			'games.steamBetaDescription' => 'Experimental Steam beta codec. Off by default; it uses 5–10× more bandwidth than H.264/HEVC, and Valve recommends gigabit Ethernet. Android playback is limited to SDR 4:2:0 with CPU readback and has not been device-qualified.',
			'games.steamLibrary' => 'Steam library',
			'games.linkSteamAccount' => 'Link Steam account',
			'games.refreshSteamAccount' => 'Refresh Steam account',
			'games.unlinkSteamAccount' => 'Unlink Steam account',
			'games.unlinkSteamAccountConfirm' => 'Remove this account and its imported catalog from this profile? Your paired computers and shortcuts stay available.',
			'games.steamAccountLinked' => 'Steam account linked. Games imported.',
			'games.steamLibraryPrivate' => 'Steam account linked. Its library is private or unavailable, so no games were imported.',
			'games.steamAppId' => 'Steam App ID',
			'games.steamLibraryStale' => 'Steam could not refresh the library. Showing the last available catalog.',
			'games.steamLibraryTruncated' => 'Showing up to 2,000 games. The Steam catalog was truncated.',
			'games.connecting' => 'Connecting…',
			'games.disconnect' => 'Disconnect',
			'games.streamControls' => 'Stream controls',
			'games.steamPairInstructions' => 'Enter this code in Steam’s Remote Play pairing prompt on your computer. Keep this screen open until Steam approves.',
			'games.steamLibraryHint' => 'Steam device pairing opens its library inside the stream. Add a shortcut with a Steam app ID for direct launch. Importing a private account library as game cards requires a separate authenticated catalog connection.',
			'deepLinks.invalid' => 'Tento odkaz Plezy není platný.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Žádný profil se neshoduje s "${profile}".',
			'deepLinks.serverUnavailable' => 'Nemohla jsem se dostat na server pro tento odkaz.',
			'deepLinks.notFound' => 'Tento název v knihovně nenajdete.',
			'deepLinks.unsupportedItem' => 'Tento odkaz nelze hrát.',
			'deepLinks.noLiveTv' => 'Žádný Live TV server není k dispozici pro tento odkaz.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Nemohla jsem najít kanál "${channel}".',
			'deepLinks.showLink' => 'Zobrazit link',
			_ => null,
		} ?? switch (path) {
			'deepLinks.showProfileLink' => 'Zobrazit profilový link',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Otevření tohoto odkazu hraje další epizodu. Přidejte &mode=shuffle k hraní show na shuffle.',
			'deepLinks.movieHint' => 'Otevření tohoto odkazu hraje film.',
			'deepLinks.episodeHint' => 'Otvírání tohoto odkazu hraje tento epizod.',
			'deepLinks.profileHint' => 'Otevření tohoto odkazu přepíná na tento profil.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Otevřete jako ${name}',
			'deepLinks.copy' => 'Kopírování',
			'deepLinks.copied' => 'Link kopírovaný',
			'householdSetup.title' => 'Nastavení domácnosti',
			'issueReport.title' => 'Nahlásit problém',
			'issueReport.instructions' => 'Naskenujte QR kód a otevřete předvyplněný návrh na GitHubu. Před odesláním ho zkontrolujte.',
			'issueReport.privacy' => 'Návrh obsahuje verzi aplikace, platformu a počty připojení. Neobsahuje adresy serverů, názvy účtů a profilů, názvy médií ani cesty k souborům.',
			'issueReport.logPrivacy' => 'Protokoly jsou volitelné. Před nahráním je zkontrolujte. Jejich ID se přidá do návrhu, který může být veřejný.',
			'issueReport.openDraft' => 'Otevřít návrh na GitHubu',
			_ => null,
		};
	}
}
