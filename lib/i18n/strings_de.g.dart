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
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$de app = _Translations$app$de._(_root);
	@override late final _Translations$appIcon$de appIcon = _Translations$appIcon$de._(_root);
	@override late final _Translations$auth$de auth = _Translations$auth$de._(_root);
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$screens$de screens = _Translations$screens$de._(_root);
	@override late final _Translations$update$de update = _Translations$update$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$themeEditor$de themeEditor = _Translations$themeEditor$de._(_root);
	@override late final _Translations$search$de search = _Translations$search$de._(_root);
	@override late final _Translations$hotkeys$de hotkeys = _Translations$hotkeys$de._(_root);
	@override late final _Translations$fileInfo$de fileInfo = _Translations$fileInfo$de._(_root);
	@override late final _Translations$mediaMenu$de mediaMenu = _Translations$mediaMenu$de._(_root);
	@override late final _Translations$rateSheet$de rateSheet = _Translations$rateSheet$de._(_root);
	@override late final _Translations$accessibility$de accessibility = _Translations$accessibility$de._(_root);
	@override late final _Translations$tooltips$de tooltips = _Translations$tooltips$de._(_root);
	@override late final _Translations$audioTracks$de audioTracks = _Translations$audioTracks$de._(_root);
	@override late final _Translations$videoControls$de videoControls = _Translations$videoControls$de._(_root);
	@override late final _Translations$messages$de messages = _Translations$messages$de._(_root);
	@override late final _Translations$subtitlingStyling$de subtitlingStyling = _Translations$subtitlingStyling$de._(_root);
	@override late final _Translations$mpvConfig$de mpvConfig = _Translations$mpvConfig$de._(_root);
	@override late final _Translations$dialog$de dialog = _Translations$dialog$de._(_root);
	@override late final _Translations$profiles$de profiles = _Translations$profiles$de._(_root);
	@override late final _Translations$connections$de connections = _Translations$connections$de._(_root);
	@override late final _Translations$accountPreferences$de accountPreferences = _Translations$accountPreferences$de._(_root);
	@override late final _Translations$discover$de discover = _Translations$discover$de._(_root);
	@override late final _Translations$errors$de errors = _Translations$errors$de._(_root);
	@override late final _Translations$libraries$de libraries = _Translations$libraries$de._(_root);
	@override late final _Translations$about$de about = _Translations$about$de._(_root);
	@override late final _Translations$serverSelection$de serverSelection = _Translations$serverSelection$de._(_root);
	@override late final _Translations$hubDetail$de hubDetail = _Translations$hubDetail$de._(_root);
	@override late final _Translations$logs$de logs = _Translations$logs$de._(_root);
	@override late final _Translations$startup$de startup = _Translations$startup$de._(_root);
	@override late final _Translations$licenses$de licenses = _Translations$licenses$de._(_root);
	@override late final _Translations$navigation$de navigation = _Translations$navigation$de._(_root);
	@override late final _Translations$explore$de explore = _Translations$explore$de._(_root);
	@override late final _Translations$liveTv$de liveTv = _Translations$liveTv$de._(_root);
	@override late final _Translations$collections$de collections = _Translations$collections$de._(_root);
	@override late final _Translations$playlists$de playlists = _Translations$playlists$de._(_root);
	@override late final _Translations$music$de music = _Translations$music$de._(_root);
	@override late final _Translations$watchTogether$de watchTogether = _Translations$watchTogether$de._(_root);
	@override late final _Translations$downloads$de downloads = _Translations$downloads$de._(_root);
	@override late final _Translations$shaders$de shaders = _Translations$shaders$de._(_root);
	@override late final _Translations$companionRemote$de companionRemote = _Translations$companionRemote$de._(_root);
	@override late final _Translations$videoSettings$de videoSettings = _Translations$videoSettings$de._(_root);
	@override late final _Translations$performanceOverlay$de performanceOverlay = _Translations$performanceOverlay$de._(_root);
	@override late final _Translations$externalPlayer$de externalPlayer = _Translations$externalPlayer$de._(_root);
	@override late final _Translations$metadataEdit$de metadataEdit = _Translations$metadataEdit$de._(_root);
	@override late final _Translations$matchScreen$de matchScreen = _Translations$matchScreen$de._(_root);
	@override late final _Translations$serverTasks$de serverTasks = _Translations$serverTasks$de._(_root);
	@override late final _Translations$trakt$de trakt = _Translations$trakt$de._(_root);
	@override late final _Translations$seerr$de seerr = _Translations$seerr$de._(_root);
	@override late final _Translations$services$de services = _Translations$services$de._(_root);
	@override late final _Translations$addServer$de addServer = _Translations$addServer$de._(_root);
	@override late final _Translations$cast$de cast = _Translations$cast$de._(_root);
	@override late final _Translations$automation$de automation = _Translations$automation$de._(_root);
	@override late final _Translations$notifications$de notifications = _Translations$notifications$de._(_root);
	@override late final _Translations$appAccess$de appAccess = _Translations$appAccess$de._(_root);
	@override late final _Translations$detail$de detail = _Translations$detail$de._(_root);
	@override late final _Translations$watchLink$de watchLink = _Translations$watchLink$de._(_root);
	@override late final _Translations$homeLayout$de homeLayout = _Translations$homeLayout$de._(_root);
	@override late final _Translations$platform$de platform = _Translations$platform$de._(_root);
	@override late final _Translations$universalMedia$de universalMedia = _Translations$universalMedia$de._(_root);
	@override late final _Translations$fileSources$de fileSources = _Translations$fileSources$de._(_root);
	@override late final _Translations$lending$de lending = _Translations$lending$de._(_root);
	@override late final _Translations$audiobook$de audiobook = _Translations$audiobook$de._(_root);
	@override late final _Translations$sourceSetup$de sourceSetup = _Translations$sourceSetup$de._(_root);
	@override late final _Translations$comics$de comics = _Translations$comics$de._(_root);
	@override late final _Translations$games$de games = _Translations$games$de._(_root);
	@override late final _Translations$deepLinks$de deepLinks = _Translations$deepLinks$de._(_root);
}

// Path: app
class _Translations$app$de extends Translations$app$en {
	_Translations$app$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class _Translations$appIcon$de extends Translations$appIcon$en {
	_Translations$appIcon$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'App-Symbol';
	@override String get defaultIcon => 'Standard';
	@override String get current => 'Aktuelles Symbol';
	@override String get locked => 'Lebensdauer Zugang erforderlich';
	@override String get lockedHint => 'Beginnen Sie Ihre 7-tägige Prüfung oder löschen Sie PlezyNG für das Leben, um alternative Ikonen zu verwenden.';
	@override String get changeFailed => 'App-Symbol konnte nicht geändert werden';
	@override String get launcherHint => 'Das neue Symbol erscheint auf deinem Startbildschirm, sobald du PlezyNG verlässt.';
	@override String get tvLauncherHint => 'Das neue Banner erscheint, sobald du PlezyNG verlässt. Android TV zeigt eventuell noch das alte an, bis der Fernseher neu gestartet wird.';
	@override late final _Translations$appIcon$names$de names = _Translations$appIcon$names$de._(_root);
	@override String get description => 'Wählen Sie die von Ihrem Gerät Launcher angegebene Ikon aus. Die Vorgänge zeigen, wie jede Option sieht.';
}

// Path: auth
class _Translations$auth$de extends Translations$auth$en {
	_Translations$auth$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mit Plex anmelden';
	@override String get showQRCode => 'QR-Code anzeigen';
	@override String get authenticate => 'Authentifizieren';
	@override String get authenticationTimeout => 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
	@override String get scanQRToSignIn => 'Scanne diesen QR-Code, um dich anzumelden';
	@override String get waitingForAuth => 'Warte auf die Authentifizierung …\nMelde dich über deinen Browser an.';
	@override String get useBrowser => 'Browser verwenden';
	@override String get or => 'oder';
	@override String connectToMediaBrowser({required Object product}) => 'Mit ${product} verbinden';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Quick Connect verwenden';
	@override String get quickConnectInstructions => 'Öffne Quick Connect in Jellyfin und gib diesen Code ein.';
	@override String get quickConnectWaiting => 'Warte auf Bestätigung…';
	@override String get quickConnectCancel => 'Abbrechen';
	@override String get quickConnectExpired => 'Quick Connect ist abgelaufen. Versuche es erneut.';
	@override String get localDataRecoveryRequired => 'PlezyNG konnte lokale Anmeldedaten und ausstehende Wiedergabedaten nicht sicher wiederherstellen. Bitte melde dich erneut an.';
	@override String get pinCheckRejected => 'Die Plex-PIN-Prüfung wurde abgelehnt';
	@override String get connectToDirectPlex => 'Anschluss an den lokalen Server Plex';
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
	@override String get closeMiniPlayer => 'Nächste Mini-Spieler';
	@override String get closeWorkspaceWindow => 'Nächstes Fenster';
	@override String get returnToFullView => 'Zurück zum vollständigen Blick';
	@override String get manageMediaSessions => 'Media-Sitzungen verwalten';
	@override String get hideMediaSessions => 'Media-Sitzungen verstecken';
	@override String get mediaSessions => 'Medienveranstaltungen';
	@override String get mediaSessionsHint => 'Wählen Sie aus, um eine Sitzung voran zu bringen. Park verbergt sein Fenster, aber hält es offen. Return öffnet es in vollem Blick; nahe endet es.';
	@override String get sessionInWorkspace => 'im Workspace';
	@override String get sessionParked => 'parken';
	@override String get sessionFullscreen => 'Vollbildschirm';
	@override String get switchToNextWindow => 'Swap mit dem nächsten Fenster';
	@override String get moveWindow => 'Fenster bewegt';
	@override String get finishMovingWindow => 'Beenden Sie das bewegende Fenster';
	@override String get moveWindowHint => 'Lange Druck und ziehen Sie das Fenster, um es zu bewegen. Diese Steuerung ermöglicht auch die Schild-Schlüsselbewegung.';
	@override String get movingWindowHelp => 'Drücken zu bewegen · Schießen Schlüssel angepasst · Enter Saves · Escape Cancels';
	@override String get resizeWindow => 'Wiederaufbau Fenster';
	@override String get resizeWindowHint => 'Drücken Sie diese Handschrift oder verwenden Sie die Schildschlüssel, um das Fenster zurückzuziehen.';
	@override String get workspaceWindowHint => 'Verwenden Sie die Bewegungskontrolle oder lange Druck und ziehen, um sich zu bewegen.';
	@override String get workspacePaneHint => 'Wählen Sie dieses Panel aus, um es zu konzentrieren. Verwenden Sie seine Vollbildschirmkontrolle, um sie zu erweitern.';
	@override String workspaceWindowLabel({required Object title}) => 'Sitzungsfenster: ${title}';
	@override String get workspaceTitleHint => 'Wählen Sie, um sich zu konzentrieren. Drücken Sie die Titelkarte zu bewegen; Verwenden Sie den vollbildschirmknopf, um sie zu erweitern.';
	@override String get moveToSessionTray => 'Bewegen Sie sich nach Session Tray';
	@override String get moveToSessionTrayHint => 'Keeps diese Sitzung verfügbar, ohne das Fenster anzuzeigen.';
	@override String get closeSessionHint => 'Schließen Sie dieses Fenster und beenden Sie seine Sitzung.';
	@override String get sideBySideLayout => 'Wechsel zum Side-by-Side Layout';
	@override String get floatingWindows => 'Switch zum Fließen von Fenstern';
	@override String get clear => 'Leeren';
	@override String get reset => 'Zurücksetzen';
	@override String get later => 'Später';
	@override String get submit => 'Senden';
	@override String get confirm => 'Bestätigen';
	@override String get retry => 'Erneut versuchen';
	@override String get logout => 'Abmelden';
	@override String get unknown => 'Unbekannt';
	@override String get refresh => 'Aktualisieren';
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String get delete => 'Löschen';
	@override String get edit => 'Bearbeiten';
	@override String get shuffle => 'Zufallswiedergabe';
	@override String get addTo => 'Hinzufügen zu …';
	@override String get createNew => 'Neu erstellen';
	@override String get connect => 'Verbinden';
	@override String get disconnect => 'Trennen';
	@override String get play => 'Abspielen';
	@override String get pause => 'Pause';
	@override String get resume => 'Fortsetzen';
	@override String get error => 'Fehler';
	@override String get search => 'Suche';
	@override String get home => 'Start';
	@override String get back => 'Zurück';
	@override String get settings => 'Einstellungen';
	@override String get mute => 'Stumm';
	@override String get ok => 'OK';
	@override String get off => 'Aus';
	@override String get options => 'Optionen';
	@override String seasonNumber({required Object number}) => 'Staffel ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Folge ${number} – ${title}';
	@override String chapterNumber({required Object number}) => 'Kapitel ${number}';
	@override String get reconnect => 'Erneut verbinden';
	@override String get viewAll => 'Alle anzeigen';
	@override String get checkingNetwork => 'Netzwerk wird geprüft...';
	@override String get loadingServers => 'Server werden geladen...';
	@override String get connectingToServers => 'Verbindung zu Servern wird hergestellt …';
	@override String get startingOfflineMode => 'Offlinemodus wird gestartet...';
	@override String get loading => 'Wird geladen …';
	@override String get fullscreen => 'Vollbild';
	@override String get exitFullscreen => 'Vollbild verlassen';
	@override String get pressBackAgainToExit => 'Zum Beenden erneut Zurück drücken';
	@override late final _Translations$common$ratingSource$de ratingSource = _Translations$common$ratingSource$de._(_root);
	@override String get notAvailable => 'N. v.';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$de mediaKind = _Translations$common$mediaKind$de._(_root);
}

// Path: screens
class _Translations$screens$de extends Translations$screens$en {
	_Translations$screens$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lizenzen';
	@override String get switchProfile => 'Profil wechseln';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Protokolle';
}

// Path: update
class _Translations$update$de extends Translations$update$en {
	_Translations$update$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update verfügbar';
	@override String versionAvailable({required Object version}) => 'Version ${version} ist verfügbar';
	@override String currentVersion({required Object version}) => 'Aktuell: ${version}';
	@override String get skipVersion => 'Diese Version überspringen';
	@override String get viewRelease => 'Versionshinweise anzeigen';
	@override String get latestVersion => 'Aktuellste Version installiert';
	@override String get checkFailed => 'Fehler bei der Updateprüfung';
}

// Path: settings
class _Translations$settings$de extends Translations$settings$en {
	_Translations$settings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get supportDeveloper => 'PlezyNG unterstützen';
	@override String get supportDeveloperDescription => 'Spenden Sie, um die Entwicklung zu unterstützen';
	@override String get lifetimeAccess => 'PlezyNG Lebensdauer Zugang';
	@override String get language => 'Sprache';
	@override String get theme => 'Design';
	@override String get appearance => 'Darstellung';
	@override String get detailPage => 'Detailseite';
	@override String get themeSongsEnabled => 'Spielen Theme Songs';
	@override String get themeSongsEnabledDescription => 'Spielen Sie verfügbare thematische Songs während Sie Mediendetails ansehen.';
	@override String get themeSongVolume => 'Song Volume Themen';
	@override String get videoPlayback => 'Videowiedergabe';
	@override String get videoPlaybackDescription => 'Wiedergabeverhalten konfigurieren';
	@override String get advanced => 'Erweitert';
	@override String get episodePosterMode => 'Episodenposter-Stil';
	@override String get seriesPoster => 'Serienposter';
	@override String get seasonPoster => 'Staffelposter';
	@override String get episodeThumbnail => 'Vorschaubild';
	@override String get showHeroSectionDescription => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
	@override String get secondsLabel => 'Sekunden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'min';
	@override String durationHint({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Hell';
	@override String get darkTheme => 'Dunkel';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Glut';
	@override String get glacierTheme => 'Gletscher';
	@override String get forestTheme => 'Wald';
	@override String get plumTheme => 'Pflaume';
	@override String get paperTheme => 'Papier';
	@override String get libraryDensity => 'Darstellungsdichte der Mediathek';
	@override String get displayScale => 'Skalierung';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Großzügig';
	@override String get gridSpacing => 'Rasterabstand';
	@override String get gridSpacingTight => 'Eng';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Großzügig';
	@override String get tvCornerSpotlightBackdrop => 'Backdrop in der Ecke';
	@override String get tvCornerSpotlightBackdropDescription => 'Zeigt das Spotlight-Artwork oben rechts statt bildschirmfüllend';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Empfehlungsbereich anzeigen';
	@override String get showHomeBackdrop => 'Home Backdrop Kunstwerk zeigen';
	@override String get showHomeBackdropDescription => 'Zeigen Sie große Kunstwerke hinter featured Home Rings';
	@override String get contentScreensaverEnabled => 'Inhalt Screensaver';
	@override String get contentScreensaverEnabledDescription => 'Show Full-Screen Artwork nach der App ist idle';
	@override String get contentScreensaverDelay => 'Start Screensaver nach';
	@override String get contentScreensaverLibraries => 'Screensaver Bibliothek';
	@override String get contentScreensaverLibrariesDescription => 'Wählen Sie die Bibliotheken aus, deren Bilder der Bildschirmschoner verwenden soll. Wenn keine ausgewählt ist, werden Bilder aus allen Bibliotheken verwendet.';
	@override String get contentScreensaverAllLibraries => 'Alle Bibliotheken';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} Bibliotheken ausgewählt';
	@override String get contentScreensaverNoLibraries => 'Keine verbundenen Medienbibliotheken sind verfügbar.';
	@override String get contentScreensaverDismissHint => 'Drücken Sie jeden Button oder drücken Sie, um abzulehnen';
	@override String get newEpisodeNotifications => 'Neue Episode-Nachrichten';
	@override String get newEpisodeNotificationsDescription => 'Warnen Sie, wenn ein neues Episode zu einem Show hinzugefügt wird, dass Sie aufgenommen werden. Überprüfen Sie, während Plezy geöffnet ist.';
	@override String get continueWatchingRowSize => 'Weiterlesen Überblick über die Größe der Reihe';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} Karten';
	@override String get rowSizeCompact => 'Kompakt';
	@override String get rowSizeStandard => 'Standard';
	@override String get rowSizeLarge => 'Groß';
	@override String get continueWatchingAction => 'Aktion für Weiterschauen';
	@override String get continueWatchingPlay => 'Abspielen';
	@override String get continueWatchingDetails => 'Details öffnen';
	@override String get episodeAction => 'Episodenaktion';
	@override String get episodePlay => 'Abspielen';
	@override String get episodeDetails => 'Details öffnen';
	@override String get useGlobalHubs => 'Startlayout verwenden';
	@override String get useGlobalHubsDescription => 'Einheitliche Start-Hubs anzeigen. Sonst Bibliotheksempfehlungen verwenden.';
	@override String get showServerNameOnHubs => 'Servername bei Hubs anzeigen';
	@override String get showServerNameOnHubsDescription => 'Servernamen immer in Hub-Titeln anzeigen.';
	@override String get groupLibrariesByServer => 'Mediatheken nach Server gruppieren';
	@override String get groupLibrariesByServerDescription => 'Sidebar-Bibliotheken nach Medienserver gruppieren.';
	@override String get alwaysKeepSidebarOpen => 'Seitenleiste immer geöffnet halten';
	@override String get alwaysKeepSidebarOpenDescription => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an';
	@override String get showUnwatchedCount => 'Anzahl nicht gesehener Folgen anzeigen';
	@override String get showUnwatchedCountDescription => 'Zeigt die Anzahl nicht gesehener Episoden bei Serien und Staffeln an';
	@override String get showWatchedIndicators => 'Gesehen-Markierungen anzeigen';
	@override String get showWatchedIndicatorsDescription => 'Zeigt ein Häkchen bei gesehenen Filmen, Serien und Episoden an';
	@override String get showEpisodeNumberOnCards => 'Episodennummer auf Karten anzeigen';
	@override String get showEpisodeNumberOnCardsDescription => 'Staffel- und Episodennummer auf Episodenkarten anzeigen';
	@override String get showSeasonPostersOnTabs => 'Staffelposter auf Tabs anzeigen';
	@override String get showSeasonPostersOnTabsDescription => 'Poster jeder Staffel über ihrem Tab anzeigen';
	@override String get tvFullCardLayout => 'Vollflächige TV-Karten';
	@override String get tvFullCardLayoutDescription => 'TV-Karten nur mit Bild verwenden und Darstellernamen einblenden';
	@override String get focusGlow => 'Fokusleuchten';
	@override String get focusGlowDescription => 'Sanftes Leuchten um die fokussierte Karte anzeigen';
	@override String get visualEffects => 'Visuelle Effekte';
	@override String get visualEffectsAuto => 'Automatisch';
	@override String get visualEffectsAutoDescription => 'Effekte auf leistungsschwachen Geräten automatisch reduzieren';
	@override String get visualEffectsFull => 'Vollständig';
	@override String get visualEffectsReduced => 'Reduziert';
	@override String get visualEffectsReducedDescription => 'Weniger Animationen und Grafiken mit niedrigerer Auflösung';
	@override String get hideSpoilers => 'Spoiler für nicht gesehene Episoden verbergen';
	@override String get hideSpoilersDescription => 'Vorschaubilder und Beschreibungen ungesehener Episoden verwischen';
	@override String get playerBackend => 'Wiedergabe-Engine';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardwaredekodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, sofern verfügbar';
	@override String get playbackBuffer => 'Wiedergabepuffer';
	@override String get playbackBufferAuto => 'Automatisch (empfohlen)';
	@override String get playbackBufferLarge => 'Groß';
	@override String get playbackBufferExtraLarge => 'Extra groß';
	@override String get playbackBufferDescription => 'Puffert mehr gegen instabile Verbindungen. Zusätzlich durch die Puffergröße begrenzt.';
	@override String get streamBufferSize => 'Buffer Größe';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Wie viel Video zu laden, wenn direkt spielt. Transcodes stoppen auf dem eigenen Transcode-Buffert des Servern. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Ersatz der Playback Buffer beim Setup, auf halb der Speichergrenze der App abgeschaltet';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Standardqualität';
	@override String get cellularQualityTitle => 'Standardqualität im Mobilfunknetz';
	@override String get remoteQualityTitle => 'Qualitätsstreaming von Fern';
	@override String get remoteQualitySameAsDefault => 'So wie die Standardqualität';
	@override String get cellularQualitySameAsDefault => 'Wie Standardqualität';
	@override String get directPlayCoveredQuality => 'Kleinere Videos in Originalqualität abspielen';
	@override String get directPlayCoveredQualityDescription => 'Videos, die bereits innerhalb des Qualitätslimits liegen, per Direct Play abspielen, statt sie zu transkodieren';
	@override String get videoCodecs => 'Video-Codecs';
	@override String get videoCodecsDescription => 'Nicht ausgewählte Codecs transkodiert der Server';
	@override String get videoCodecsAlwaysAccepted => 'Immer akzeptiert';
	@override String get musicQualityTitle => 'Musikqualität';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleines Sprungintervall';
	@override String get largeSkipDuration => 'Großes Sprungintervall';
	@override String get rewindOnResume => 'Zurückspulen bei Fortsetzung';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} Sekunde',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} Sekunden',
	);
	@override String get defaultSleepTimer => 'Standard-Schlaftimer';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} Minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} Minuten',
	);
	@override String get rememberTrackSelections => 'Spurauswahl pro Serie/Film merken';
	@override String get chooseTracksBeforePlayback => 'Wählen Sie Audio und Untertitel vor dem Playback aus';
	@override String get chooseTracksBeforePlaybackDescription => 'Wählen Sie die Quell-Audio und Subtitle-Track vor jedem Video starten.';
	@override String get alwaysShowSubtitlesOnDevice => 'Sie zeigen immer Untertitel auf diesem Gerät';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Wenn der Server keinen Untertitel ausgewählt hat, wählen Sie eine Spur lokal. Dies ändert niemals die Server-Preferenz.';
	@override String get autoDownloadPreferredSubtitle => 'Fettch fehlt bevorzugte Sprachuntertiteln';
	@override String get autoDownloadPreferredSubtitleDescription => 'Wählen Sie einen verfügbaren Untertitel in Ihrer bevorzugten Sprache lokal aus. Wenn kein vorhanden ist, bitten Sie den Server, einen zu fangen, wenn unterstützt wird.';
	@override String get rememberTrackSelectionsDescription => 'Audio- und Untertitelauswahl je Titel merken';
	@override String get rememberTrackSelectionsBackendRule => 'Plex speichert jede Auswahl pro Datei auf dem Server; Jellyfin aktiviert außerdem die Kontooption „Auswahl merken“; Emby wird nicht unterstützt';
	@override String get followServerTrackSelections => 'Serverseitige Spurauswahl pro Episode verwenden';
	@override String get followServerTrackSelectionsDescription => 'Beim Episodenwechsel die auf dem Server ausgewählten Audio- und Untertitelspuren übernehmen, statt die aktuelle Auswahl zu übertragen';
	@override String get resumeMusicOnLaunch => 'Musiksitzung merken';
	@override String get resumeMusicOnLaunchDescription => 'Beim App-Start den letzten Titel pausiert an der letzten Stelle wieder öffnen';
	@override String get showChapterMarkersOnTimeline => 'Kapitelmarkierungen auf der Suchleiste anzeigen';
	@override String get showChapterMarkersOnTimelineDescription => 'Die Suchleiste an Kapitelgrenzen unterteilen';
	@override String get specialsOrdering => 'Specials in Episodenreihenfolge';
	@override String get specialsOrderingDescription => 'Wo Specials in der Wiedergabereihenfolge einer Serie abgespielt werden';
	@override String get specialsOrderingServer => 'Serverreihenfolge folgen';
	@override String get specialsOrderingAirDate => 'Nach Ausstrahlungsdatum einfügen';
	@override String get specialsOrderingLast => 'Nach den regulären Staffeln';
	@override String get clickVideoTogglesPlayback => 'Video zum Abspielen oder Pausieren anklicken';
	@override String get clickVideoTogglesPlaybackDescription => 'Video zum Abspielen oder Pausieren anklicken, statt die Steuerung anzuzeigen.';
	@override String get videoPlayerControls => 'Videoplayer-Steuerung';
	@override String get keyboardShortcuts => 'Tastenkürzel';
	@override String get keyboardShortcutsDescription => 'Tastenkürzel anpassen';
	@override String get videoPlayerNavigation => 'Videoplayer-Navigation';
	@override String get videoPlayerNavigationDescription => 'Mit den Pfeiltasten durch die Videoplayer-Steuerung navigieren';
	@override String get watchTogetherRelay => 'Relay für gemeinsames Schauen';
	@override String get watchTogetherRelayDescription => 'Öffentliche Relays von Open Watch Party, sofern du kein eigenes festlegst';
	@override String get watchTogetherRelayHint => 'https://mein-relay.beispiel.de';
	@override String get watchTogetherRelayInvalid => 'Gib eine gültige HTTP- oder HTTPS-Basis-URL für das Relay ein.';
	@override String get crashReporting => 'Absturzberichte';
	@override String get crashReportingDescription => 'Absturzberichte senden, um die App zu verbessern';
	@override String get debugLogging => 'Debug-Protokollierung';
	@override String get debugLoggingDescription => 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
	@override String get viewLogs => 'Protokolle anzeigen';
	@override String get viewLogsDescription => 'App-Protokolle anzeigen';
	@override String get clearImageCache => 'Bildercache leeren';
	@override String get clearImageCacheDescription => 'Zwischengespeicherte Artworks und Vorschaubilder löschen. Bilder können langsamer laden, bis sie erneut heruntergeladen werden.';
	@override String get clearImageCacheSuccess => 'Bildercache erfolgreich geleert';
	@override String get resetSettings => 'Einstellungen zurücksetzen';
	@override String get resetSettingsDescription => 'Standardeinstellungen wiederherstellen. Dies kann nicht rückgängig gemacht werden.';
	@override String get resetSettingsSuccess => 'Einstellungen erfolgreich zurückgesetzt';
	@override String get backup => 'Sicherung';
	@override String get exportSettings => 'Einstellungen exportieren';
	@override String get exportSettingsDescription => 'Einstellungen in einer Datei speichern';
	@override String get exportSettingsSuccess => 'Einstellungen exportiert';
	@override String get importSettings => 'Einstellungen importieren';
	@override String get importSettingsDescription => 'Einstellungen aus einer Datei wiederherstellen';
	@override String get importSettingsConfirm => 'Dies ersetzt deine aktuellen Einstellungen. Fortfahren?';
	@override String get importSettingsSuccess => 'Einstellungen importiert';
	@override String get importSettingsInvalidFile => 'Diese Datei ist kein gültiger PlezyNG-Einstellungsexport';
	@override String get importSettingsNoUser => 'Vor dem Import bitte anmelden';
	@override String get cloudBackup => 'Cloud-Sicherung';
	@override String get cloudBackupDescription => 'Sichere übertragbare Einstellungen über HTTPS an einer WebDAV-Adresse. Serververbindungen und Anmeldedaten bleiben auf diesem Gerät.';
	@override String get cloudBackupUrl => 'WebDAV JSON Datei URL';
	@override String get cloudBackupUsername => 'Benutzername';
	@override String get cloudBackupPassword => 'Passwort';
	@override String get cloudBackupSaved => 'Cloud Backup-Destination gesichert';
	@override String get cloudBackupNow => 'Zurück jetzt';
	@override String get cloudBackupComplete => 'Backup-Einstellungen hochgeladen';
	@override String get cloudBackupRestore => 'Backup wiederherstellen';
	@override String get cloudBackupRestoreConfirm => 'Dies ersetzt die entsprechenden Portable-Einstellungen auf diesem Gerät.';
	@override String get cloudBackupRestored => 'Einstellungen wiederhergestellt von Cloud Backup';
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
	@override String get resetShortcutsConfirm => 'Dadurch werden deine eigenen Tastenkürzel durch die Standardwerte ersetzt. Fortfahren?';
	@override String get about => 'Über';
	@override String get aboutDescription => 'App-Informationen und Lizenzen';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update verfügbar';
	@override String get checkForUpdates => 'Nach Updates suchen';
	@override String get autoCheckUpdatesOnStartup => 'Beim Start automatisch nach Updates suchen';
	@override String get autoCheckUpdatesOnStartupDescription => 'Beim Start benachrichtigen, wenn ein Update verfügbar ist';
	@override String get validationErrorEnterNumber => 'Bitte eine gültige Zahl eingeben';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
	@override String shortcutUpdated({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
	@override String get saveFailed => 'Änderungen konnten nicht gespeichert werden. Versuche es erneut.';
	@override String get autoPlayAndSkip => 'Autoplay & Überspringen';
	@override String get autoPlayNextEpisode => 'Nächste Episode automatisch abspielen';
	@override String get autoPlayNextEpisodeDescription => 'Die nächste Episode automatisch starten, wenn die aktuelle endet';
	@override String get shuffleStartsFromBeginning => 'Zufallswiedergabe beginnt am Anfang';
	@override String get shuffleStartsFromBeginningDescription => 'Bei Zufallswiedergabe jede Episode von Anfang an abspielen, statt sie fortzusetzen';
	@override String get plexCinemaPreRoll => 'Anwendung von Server Cinema Intros';
	@override String get plexCinemaPreRollDescription => 'Spielen Sie vor dem Film konfigurierte Plex Pre-Rolls oder Jellyfin und Emby Inträge.';
	@override String get playNextCountdown => 'Countdown bis zur nächsten Episode';
	@override String get playNextCountdownImmediate => 'Sofort abspielen';
	@override String get skipIntroMode => 'Intro überspringen';
	@override String get skipIntroModeOffDescription => 'Intros normal abspielen, ohne Schaltfläche zum Überspringen';
	@override String get skipIntroModeButtonDescription => 'Schaltfläche zum Überspringen anzeigen, wenn ein Intro beginnt';
	@override String get skipIntroModeAutoDescription => 'Intros nach der untenstehenden Verzögerung automatisch überspringen';
	@override String get skipCreditsMode => 'Abspann überspringen';
	@override String get skipCreditsModeOffDescription => 'Abspann normal abspielen, ohne Schaltfläche zum Überspringen';
	@override String get skipCreditsModeButtonDescription => 'Schaltfläche zum Überspringen anzeigen, wenn der Abspann beginnt';
	@override String get skipCreditsModeAutoDescription => 'Abspann automatisch überspringen und die nächste Episode abspielen';
	@override String get skipAdsMode => 'Werbung überspringen';
	@override String get skipAdsModeOffDescription => 'Spielen Sie aufgeführte Werbung normalerweise ohne einen Skip-Button';
	@override String get skipAdsModeButtonDescription => 'Zeigen Sie einen Skip-Button an, wenn Plex eine Werbung erkennt';
	@override String get skipAdsModeAutoDescription => 'Entfernen Sie die aufgezeigten Anzeigen automatisch nach der Verzögerung unten';
	@override String get musicPlayback => 'Musik Playback';
	@override String get musicSweetFades => 'Süße Faden';
	@override String get musicSweetFadesDescription => 'Fade Musik an Spurenräumen, wenn Plex Lautstärke-Daten hat. Album-Playback bleibt unverändert.';
	@override String get skipMarkerModeOff => 'Aus';
	@override String get skipMarkerModeButton => 'Schaltfläche anzeigen';
	@override String get skipMarkerModeAuto => 'Automatisch';
	@override String get forceSkipMarkerFallback => 'Ersatzmarkierungen erzwingen';
	@override String get forceSkipMarkerFallbackDescription => 'Kapitel-Titelmuster auch dann verwenden, wenn Plex über Markierungen verfügt';
	@override String get theIntroDbFallback => 'Verwenden Sie TheIntroDB als Eintröpfungsfall';
	@override String get theIntroDbFallbackDescription => 'Verwenden Sie Community Timings nur, wenn der Server keinen Eintrommer hat.';
	@override String get autoSkipDelay => 'Verzögerung für automatisches Überspringen';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
	@override String get introPattern => 'Intro-Markierungsmuster';
	@override String get introPatternDescription => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln';
	@override String get creditsPattern => 'Abspann-Markierungsmuster';
	@override String get creditsPatternDescription => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln';
	@override String get prerolls => 'Vorliegen';
	@override String get playPrerollsBeforeMovies => 'Spielen Sie Prerolls vor den Filmen';
	@override String get playPrerollsBeforeMoviesDescription => 'Spielen Sie einen Random-Clip aus Ihrer Auswahl unten vor jedem Film.';
	@override String get prerollLibrary => 'Preroll Bibliothek';
	@override String get prerollLibraryNotSet => 'Nicht festgelegt';
	@override String get prerollLibraryNoneFound => 'Keine Bibliotheken auf Ihren Servern gefunden.';
	@override String get prerollSelection => 'ausgewählte Prerolle';
	@override String get prerollSelectionPickLibraryFirst => 'Wählen Sie zuerst eine Bibliothek';
	@override String get prerollSelectionNoneSelected => 'Keine Prerolle ausgewählt';
	@override String prerollSelectionCount({required Object count}) => '${count} ausgewählt';
	@override String get prerollItemPicker => 'Prerolle auswählen';
	@override String get prerollItemPickerLoadFailed => 'Ich konnte keine Artikel aus dieser Bibliothek laden.';
	@override String get invalidRegex => 'Ungültiger regulärer Ausdruck';
	@override String get regex => 'Regulärer Ausdruck';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Speicherort für heruntergeladene Inhalte wählen';
	@override String get downloadLocationDefault => 'Standard (App-Speicher)';
	@override String get downloadLocationCustom => 'Benutzerdefinierter Speicherort';
	@override String get selectFolder => 'Ordner auswählen';
	@override String get resetToDefault => 'Auf Standard zurücksetzen';
	@override String currentPath({required Object path}) => 'Aktuell: ${path}';
	@override String get downloadLocationChanged => 'Download-Speicherort geändert';
	@override String get downloadLocationReset => 'Download-Speicherort auf Standard zurückgesetzt';
	@override String get downloadLocationInvalid => 'Ausgewählter Ordner ist nicht beschreibbar';
	@override String get downloadLocationPickerUnavailable => 'Die Ordnerauswahl ist auf diesem Gerät nicht verfügbar';
	@override String get downloadOnWifiOnly => 'Nur über WLAN herunterladen';
	@override String get downloadOnWifiOnlyDescription => 'Downloads über mobile Daten verhindern';
	@override String get autoRemoveWatchedDownloads => 'Gesehene Downloads automatisch entfernen';
	@override String get autoRemoveWatchedDownloadsDescription => 'Angesehene Downloads automatisch löschen';
	@override String get autoDownloadContinueWatching => 'Auto-Download Weiterlesen';
	@override String get autoDownloadContinueWatchingDescription => 'Halten Sie die Elemente auf Ihrem Continue Watching Schild heruntergeladen und entfernen Sie sie, sobald sie die Schild verlassen';
	@override String get downloadQuality => 'Download Qualität';
	@override String get downloadQualityDescription => 'Plex bereitet eine konvertierte Kopie in seinem Download-Quelle vor. Jellyfin und Emby Transcode während der Datei heruntergeladen wird; geschlossenen Übertragungen können neu gestartet werden müssen.';
	@override String get askDownloadQualityEachTime => 'Qualität für jede Download';
	@override String get askDownloadQualityEachTimeDescription => 'Zeigen Sie den Qualitätspiker vor der Abrechnung jedes Video herunterladen';
	@override String get cellularDownloadBlocked => 'Downloads über das Mobilfunknetz sind blockiert. Nutze WLAN oder ändere die Einstellung.';
	@override String get maxVolume => 'Maximale Lautstärke';
	@override String get maxVolumeDescription => 'Lautstärkeanhebung über 100 % für leise Medien erlauben';
	@override String maxVolumePercent({required Object percent}) => '${percent} %';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Auf Discord anzeigen, was du gerade schaust';
	@override String get services => 'Dienste';
	@override String get servicesDescription => 'Trakt, MyAnimeList, Seerr und mehr verbinden';
	@override String get manageLibrariesDescription => 'Mediatheken neu anordnen und ausblenden';
	@override String get companionRemoteServer => 'Companion-Fernbedienungsserver';
	@override String get companionRemoteServerDescription => 'Mobilgeräten in deinem Netzwerk erlauben, diese App zu steuern';
	@override String get companionRemoteServerStartFailed => 'Companion-Fernbedienungsserver konnte nicht gestartet werden';
	@override String get companionRemoteServerStopFailed => 'Companion-Fernbedienungsserver konnte nicht gestoppt werden';
	@override String get autoPip => 'Automatisches Bild-in-Bild';
	@override String get autoPipDescription => 'Beim Verlassen der App während der Wiedergabe automatisch Bild-in-Bild starten';
	@override String get matchContentFrameRate => 'Inhalts-Bildrate anpassen';
	@override String get matchContentFrameRateDescription => 'Bildwiederholrate des Displays an Videoinhalt anpassen';
	@override String get matchContentResolution => 'An Auflösung des Inhalts anpassen';
	@override String get matchContentResolutionDescription => 'Wechselt die Anzeige auf die native Auflösung des Videos, damit dein Fernseher das Hochskalieren übernimmt. Menüs und Untertitel werden während der Wiedergabe ebenfalls hochskaliert';
	@override String get matchRefreshRate => 'Bildwiederholrate anpassen';
	@override String get matchRefreshRateDescription => 'Bildwiederholrate im Vollbild anpassen';
	@override String get matchDynamicRange => 'Dynamikumfang anpassen';
	@override String get matchDynamicRangeDescription => 'HDR für HDR-Inhalte einschalten, danach zurück zu SDR';
	@override String get displaySwitchDelay => 'Verzögerung beim Displaywechsel';
	@override String get tunneledPlayback => 'Tunnelwiedergabe';
	@override String get tunneledPlaybackDescription => 'Video-Tunneling verwenden. Deaktivieren, wenn HDR-Wiedergabe schwarzes Video zeigt oder Bewegungen ruckeln.';
	@override String get audioPassthrough => 'Audio-Durchleitung';
	@override String get audioPassthroughDescription => 'Dolby/DTS-Audio ohne Neukodierung an deinen Receiver oder Fernseher senden und Surround-Sound erhalten. Deaktivieren, wenn kein Ton zu hören ist.';
	@override String get audioPassthroughDescriptionApple => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. DTS und TrueHD werden weiterhin als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. Unter iOS, iPadOS und tvOS 26 oder neuer werden TrueHD Atmos und DTS:X als 3D-Audio wiedergegeben. Andere DTS- und TrueHD-Spuren werden als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.';
	@override String get audioPassthroughOverriddenByNormalization => 'Aus, solange die Lautstärkenormalisierung aktiv ist';
	@override String get audioChannelLimit => 'Audiokanäle';
	@override String get audioChannelLimitDescription => 'Dekodierten Ton für Lautsprecher, Kopfhörer oder HDMI-Setups heruntermischen, die nicht alle Kanäle wiedergeben können';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Alle Kanäle der Spur wiedergeben';
	@override String get audioChannelLimitSurround51 => 'Bis zu 5.1';
	@override String get audioChannelLimitSurround51Description => '7.1 auf 5.1 heruntermischen für Fernseher und Receiver, die nur 5.1-PCM annehmen. Die Durchleitung ist davon nicht betroffen.';
	@override String get audioChannelLimitStereo => 'Stereo';
	@override String get audioChannelLimitStereoDescription => 'Auf zwei Kanäle für Stereolautsprecher oder Kopfhörer heruntermischen. Deaktiviert die Durchleitung.';
	@override String get downmixCenterBoost => 'Verstärkung des Center-Kanals';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Verstärkung (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Lautstärke beim Downmix normalisieren';
	@override String get audioDownmixNormalizeDescription => 'Senkt den Mix ab, um Übersteuerung zu vermeiden. Deaktivieren, um die Originallautstärke zu behalten (laute Szenen können verzerren).';
	@override String get dvConversionMode => 'Dolby-Vision-Konvertierung';
	@override String get dvConversionModeDescription => 'Wähle, wie Dateien mit Dolby-Vision-Profil 7 behandelt werden.';
	@override String get dvConversionAuto => 'Automatisch';
	@override String get dvConversionNative => 'Nativ / deaktiviert';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Gerätefähigkeiten erkennen und normales Fallback-Verhalten verwenden';
	@override String get dvConversionNativeDescription => 'Natives DV7 erzwingen und einen erneuten DV-Konvertierungsversuch unterdrücken';
	@override String get dvConversionDv81Description => 'Inline-RPU-Konvertierung in Dolby-Vision-Profil 8.1 erzwingen';
	@override String get dvConversionHevcStripDescription => 'Dolby-Vision-RPU/EL-Schichten entfernen und reines HEVC ausgeben';
	@override String get experimentalDolbyVision => 'Experimentelles Dolby Vision';
	@override String get experimentalDolbyVisionDescription => 'Bei der nächsten Wiedergabe den experimentellen FEL-Renderer verwenden. Erfordert einen separat erstellten Wiedergabekern.';
	@override String get dvExperimentUnavailableDescription => 'Dieses Experiment ist derzeit nur unter Linux verfügbar.';
	@override String get dvCompatibilityFallback => 'Kompatibilitätsfallback';
	@override String get dvCompatibilityFallbackDescription => 'Den Standard-Renderer verwenden, falls das Experiment nicht startet. FEL-Daten können verloren gehen.';
	@override String get dvExperimentDiagnostics => 'Videoexperiment protokollieren';
	@override String get dvExperimentDiagnosticsDescription => 'Bei der nächsten Wiedergabe ausführliche Player-Protokolle aktivieren.';
	@override String get disableDolbyVision => 'Dolby Vision deaktivieren';
	@override String get disableDolbyVisionDescription => 'Statt Dolby Vision die HDR10- oder HLG-Ebene der Datei abspielen, sofern vorhanden';
	@override String get hdrSdrConversion => 'HDR-zu-SDR-Konvertierung';
	@override String get hdrSdrConversionDescription => 'Wähle, was HDR-Videos umwandelt, wenn das Display kein HDR darstellen kann.';
	@override String get hdrSdrConversionAuto => 'Automatisch';
	@override String get hdrSdrConversionAutoDescription => 'Gerät ab Android 9, Player bei älteren Versionen';
	@override String get hdrSdrConversionDevice => 'Gerät';
	@override String get hdrSdrConversionDeviceDescription => 'Die Videohardware des Geräts wandelt um. Am schnellsten, die Farben hängen aber vom Gerät ab';
	@override String get hdrSdrConversionPlayer => 'Player';
	@override String get hdrSdrConversionPlayerDescription => 'Der Player wandelt um. Einheitliche Farben, aber 4K kann auf schwachen TV-Boxen ruckeln';
	@override String get deinterlace => 'Deinterlacing';
	@override String get deinterlaceDescription => 'Kammartefakte aus interlaced Videos entfernen (nur mpv-Player)';
	@override String get deinterlaceOff => 'Aus';
	@override String get deinterlaceOffDescription => 'Interlaced Video so anzeigen, wie es dekodiert wird';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Jedes Halbbild zu einem Vollbild machen. Für TV-Aufnahmen wie Sport, Nachrichten und Konzerte';
	@override String get deinterlaceFilm => 'Film';
	@override String get deinterlaceFilmDescription => 'Die Originalbilder von Filmen und Animationen wiederherstellen, die per Telecine auf 29,97 fps gebracht wurden – üblich bei NTSC-DVDs. TV-Aufnahmen ruckeln dabei. Live TV verwendet „Video“';
	@override String get requireProfileSelectionOnOpen => 'Profil beim Öffnen abfragen';
	@override String get requireProfileSelectionOnOpenDescription => 'Profilauswahl bei jedem Öffnen der App anzeigen';
	@override String get forceTvMode => 'TV-Modus erzwingen';
	@override String get forceTvModeDescription => 'TV-Layout erzwingen. Für Geräte ohne automatische Erkennung. Neustart erforderlich.';
	@override String get startInFullscreen => 'Im Vollbildmodus starten';
	@override String get startInFullscreenDescription => 'PlezyNG beim Start im Vollbildmodus öffnen';
	@override String get exitFullscreenOnPlayerClose => 'Vollbild beim Schließen des Players beenden';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Vollbildmodus automatisch beenden, wenn der Videoplayer geschlossen wird';
	@override String get autoHidePerformanceOverlay => 'Leistungsoverlay automatisch ausblenden';
	@override String get autoHidePerformanceOverlayDescription => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden';
	@override String get showNavBarLabels => 'Navigationsleisten-Beschriftungen anzeigen';
	@override String get showNavBarLabelsDescription => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen';
	@override String get startupSection => 'Startbereich';
	@override String get preferredServer => 'Vorliegende Server';
	@override String get preferredServerDescription => 'Prioritieren Sie die Ergebnisse dieses Servers und halten Sie jeden verbundenen Server zur Verfügung.';
	@override String get preferredServerAutomatic => 'Automatisch';
	@override String get showExploreTab => 'Tab „Entdecken“ anzeigen';
	@override String get showExploreTabDescription => 'Zeigt den Tab „Entdecken“ mit Inhalten aus Plex Discover und verbundenen Trackern an';
	@override String get hideEmptyLibraries => 'Die leeren Bibliotheken verstecken';
	@override String get hideEmptyLibrariesDescription => 'Entfernen Sie Bibliotheken mit einem Server-berichten von Null-Einheiten aus der Navigation.';
	@override String get liveTvDefaultFavorites => 'Standardmäßig Favoritenkanäle';
	@override String get liveTvDefaultFavoritesDescription => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen';
	@override String get general => 'Allgemein';
	@override String get generalDescription => 'Sprache, Start und Fensterverhalten';
	@override String get languageAndRegion => 'Sprache & Region';
	@override String get startup => 'Start';
	@override String get display => 'Anzeige';
	@override String get libraryAndCards => 'Mediathek & Karten';
	@override String get homeScreen => 'Startseite';
	@override String get navigation => 'Navigation';
	@override String get window => 'Fenster';
	@override String get liveTv => 'Live-TV';
	@override String get player => 'Wiedergabe';
	@override String get videoAndDisplay => 'Video & Anzeige';
	@override String get audio => 'Audio';
	@override String get quality => 'Qualität';
	@override String get subtitles => 'Untertitel';
	@override String get seekAndTiming => 'Spulen & Timing';
	@override String get behavior => 'Verhalten';
	@override String get gestures => 'Gesten';
	@override String get gestureBrightnessSwipe => 'Wischen für Helligkeit';
	@override String get gestureBrightnessSwipeDescription => 'Wische am linken Rand nach oben oder unten, um die Helligkeit anzupassen';
	@override String get gestureVolumeSwipe => 'Wischen für Lautstärke';
	@override String get gestureVolumeSwipeDescription => 'Wische am rechten Rand nach oben oder unten, um die Lautstärke anzupassen';
	@override String get gesturePinchToZoom => 'Zum Zoomen kneifen';
	@override String get gesturePinchToZoomDescription => 'Kneife auf dem Video, um hinein- oder herauszuzoomen';
	@override String get gestureSeekSwipe => 'Suche Swipe';
	@override String get gestureSeekSwipeDescription => 'Schieben Sie links oder rechts überall auf dem Video, um zu suchen; freigeben Sie zum Springen';
	@override String get rememberBrightnessLevel => 'Helligkeitsstufe merken';
	@override String get rememberBrightnessLevelDescription => 'Wiedergabe mit der zuletzt per Wischgeste eingestellten Helligkeit starten';
	@override String get controls => 'Steuerung';
	@override String get rememberPlayerChanges => 'Playeränderungen merken';
	@override String get rememberPlayerChangesDescription => 'Wo eine während der Wiedergabe vorgenommene Änderung gespeichert und erneut angewendet wird';
	@override String get scopePlaybackSpeed => 'Wiedergabegeschwindigkeit';
	@override String get scopeShaderPreset => 'Shader-Voreinstellung';
	@override String get scopeAspectRatio => 'Seitenverhältnis';
	@override String get scopeSyncOffsets => 'Audio- und Untertitelsynchronisierung';
	@override String get playerScopeOff => 'Nicht speichern';
	@override String get playerScopeGlobal => 'Überall';
	@override String get playerScopeLibrary => 'Pro Bibliothek';
	@override String get playerScopeTitle => 'Pro Serie oder Film';
	@override String get exportDialogTitle => 'PlezyNG-Einstellungen exportieren';
	@override String get followSystem => 'Systemsprache verwenden';
	@override String get followAppLanguage => 'Wie die Sprache der Oberfläche';
	@override String get regionFormat => 'Regionale Formate';
	@override String get regionFormatDescription => 'Wähle, wie Datumsangaben, Zahlen und Maßeinheiten angezeigt werden.';
	@override String get metadataLanguage => 'Sprache der Metadaten';
	@override String get metadataLanguageDescription => 'Bevorzugte Sprache für Titel und Beschreibungen, sofern vom Server unterstützt. Audio- und Untertitelsprachen werden separat eingestellt.';
	@override String get enterFullscreenOnPlaybackStart => 'Geben Sie den Vollbildschirm ein, wenn das Playback beginnt';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Öffnen Sie Desktop-Video auf Vollbildschirm, wenn der Playback beginnt';
	@override String get extendVideoIntoDisplayCutout => 'Erweiterung des Videos in Display Cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Lassen Sie Full-Screen-Videos die Kamera auf Android-Telefonen verwenden';
	@override String get languageDescription => 'Wählen Sie die für PlezyNG-Kontrollen und Nachrichten verwendete Sprache aus. Folgen Sie dem System, der Ihre Gerätesprache verfolgt.';
	@override String get themeDescription => 'Wählen Sie die Farben und Kontraste, die in der gesamten App verwendet werden.';
	@override String get libraryDensityDescription => 'Ändern Sie, wie viele Bibliothekkarten in jeder Reihe passen.';
	@override String get displayScaleDescription => 'Wiederherstellen Sie die Schnittstelle auf diesem Auto-Display, ohne die Textgröße Ihres Geräts zu ändern.';
	@override String get themeSongVolumeDescription => 'Setzen Sie das Volumen der thematischen Songs im Verhältnis zu anderen Audio.';
	@override String get viewModeDescription => 'Wählen Sie aus, ob Bibliothek-Elemente als Poster in einem Netzwerk oder als kompakte Liste erscheinen.';
	@override String get gridViewDescription => 'Ordnen Sie Bibliothekartikel in Zeilen und Spalten von Postern.';
	@override String get listViewDescription => 'Zeigen Sie Bibliothek-Elemente in einer vertikalen Liste mit mehr Text pro Artikel.';
	@override String get gridSpacingDescription => 'Setzen Sie den Abstand zwischen Postern in Bibliotheknetzwerken.';
	@override String get gridSpacingTightDescription => 'Fügen Sie mehr Poster über dem Bildschirm mit kleineren Lücken.';
	@override String get gridSpacingNormalDescription => 'Verwenden Sie den Standardverhältnis zwischen Postern.';
	@override String get gridSpacingSpaciousDescription => 'Hinzufügen Sie größere Lücken zwischen Postern für mehr Trennung.';
	@override String get episodePosterModeDescription => 'Wählen Sie aus, welches Kunstwerk auf Episodkarten erscheint.';
	@override String get seriesPosterDescription => 'Verwenden Sie die Serie-Poster für jede Episode.';
	@override String get seasonPosterDescription => 'Verwenden Sie den Saisonplakat für jede Episode, wenn verfügbar.';
	@override String get episodeThumbnailDescription => 'Verwenden Sie ein Rahmen aus der Episode, wenn verfügbar.';
	@override String get continueWatchingActionDescription => 'Wählen Sie aus, was passiert, wenn Sie eine Continue Watching-Karte aktivieren.';
	@override String get continueWatchingPlayDescription => 'Beginnen Sie den Film oder die Episode sofort.';
	@override String get continueWatchingDetailsDescription => 'Öffnen Sie zunächst die Titelseite, damit Sie Details überprüfen und eine Aktion wählen können.';
	@override String get episodeActionDescription => 'Wählen Sie aus, was passiert, wenn Sie eine Episode-Karte aktivieren.';
	@override String get episodePlayDescription => 'Beginnen Sie die Episode sofort.';
	@override String get episodeDetailsDescription => 'Öffnen Sie die Episode-Seite vor dem Playback.';
	@override String get contentScreensaverDelayDescription => 'Wählen Sie aus, wie lange PlezyNG ohne Eintritt wartet, bevor Sie Kunstwerke zeigen.';
	@override String get continueWatchingRowSizeDescription => 'Wählen Sie aus, wie groß die Karten in der Folge-Beobachtung-Reihe sind.';
	@override String get rowSizeCompactDescription => 'Zeigen Sie kleinere Karten, so dass mehr Elemente über die Reihe passen.';
	@override String get rowSizeStandardDescription => 'Verwenden Sie die Standardkarte Größe.';
	@override String get rowSizeLargeDescription => 'Zeigen Sie größere Karten mit mehr Kunstwerke Details.';
	@override String get visualEffectsDescription => 'Wählen Sie den Animations- und Kunstwerkeffekte Budget für dieses Gerät aus.';
	@override String get visualEffectsFullDescription => 'Verwenden Sie die vollständigen Animations- und Kunstwerkeffekte auf jedem Gerät.';
	@override String get startupSectionDescription => 'Wählen Sie aus, welcher Abschnitt sich öffnet, wenn PlezyNG beginnt.';
	@override late final _Translations$settings$startupSectionOptions$de startupSectionOptions = _Translations$settings$startupSectionOptions$de._(_root);
	@override String get smallSkipDurationDescription => 'Setzen Sie die Entfernung, die durch den kurzen Rückweg und vorwärts nach Kontrolle bewegt wird.';
	@override String get largeSkipDurationDescription => 'Setzen Sie die Entfernung, die durch den langen Rückweg und vorwärts nach Kontrolle bewegt wird.';
	@override String get rewindOnResumeDescription => 'Move Playback zurück mit diesem Betrag, wenn Sie ein Video wiederholen.';
	@override String get defaultSleepTimerDescription => 'Setzen Sie die ursprüngliche Dauer, die verwendet wird, wenn Sie den Schlaftimeter starten.';
	@override String get playNextCountdownDescription => 'Warten Sie lange darauf, bevor die nächste Episode beginnt. Set auf 0 um sofort zu beginnen.';
	@override String get autoSkipDelaySettingDescription => 'Geltend ist, wenn eine Einführung, Kredit oder Werbung automatisch ausgeschieden wird.';
	@override String get downmixCenterBoostDescription => 'Erhöhen Sie den Dialog im Zentralkanal, wenn das umliegende Audio nach unten in Stereo gemischt wird.';
	@override String get displaySwitchDelayDescription => 'Warten Sie, bevor Sie den Displaymodus ändern, damit der Fernseher oder Empfänger seinen vorherigen Schalter beenden kann.';
	@override String get playerBackendDescription => 'Wählen Sie aus, welcher Playback-Motor Video auf diesem Gerät dekodiert und rendiert.';
	@override String get exoPlayerDescription => 'Verwenden Sie Android native Media3-basierte Player und unterstützte Hardware-Paths.';
	@override String get mpvDescription => 'Verwenden Sie MPV, die zusätzliche Playback, Subtitle und Video-Verarbeitungskontrolle exponiert.';
	@override String get scopeOffDescription => 'Behalten Sie Änderungen für die aktuelle Playback-Sitzung nur.';
	@override String get scopeGlobalDescription => 'Wieder verwenden Sie den gleichen Wert für jede Bibliothek und Titel.';
	@override String get scopeLibraryDescription => 'Erinnern Sie sich an einen separaten Wert für jede Bibliothek.';
	@override String get scopeTitleDescription => 'Erinnern Sie sich an einen separaten Wert für jede Show oder Film.';
	@override String get specialsOrderingServerDescription => 'Halten Sie die Episode Order, die vom Medien-Server bereitgestellt wird.';
	@override String get specialsOrderingAirDateDescription => 'Stellen Sie spezielle unter regelmäßigen Episoden nach ihrem Flugdatum.';
	@override String get specialsOrderingLastDescription => 'Platzieren Sie alle speziellen nach den regelmäßigen Jahreszeiten.';
	@override String get skipIntroModeDescription => 'Wählen Sie aus, ob die Intro-Marker normalerweise spielen, einen Skip-Button anzeigen oder automatisch springen.';
	@override String get skipCreditsModeDescription => 'Wählen Sie aus, ob die Credits normalerweise spielen, zeigen Sie einen Skip-Button oder automatisch springen.';
	@override String get skipAdsModeDescription => 'Wählen Sie aus, ob die aufgezeigten Anzeigen normalerweise gespielt werden, einen Skip-Button anzeigen oder automatisch springen.';
	@override String get playbackBufferAutoDescription => 'Lassen Sie den aktiven Spieler seine normale Buffergröße wählen.';
	@override String get playbackBufferLargeDescription => 'Halten Sie mehr Medien vor dem Playback bereit; dies nutzt mehr Speicher.';
	@override String get playbackBufferExtraLargeDescription => 'Halten Sie den größten Read-ahead Buffer; dies nutzt die meisten Gedächtnis.';
	@override String get defaultQualityDescription => 'Setzen Sie die standardmäßige Video-Resolution und Bitrate Dach für Streams, die der Server transcodiert.';
	@override String get cellularQualityDescription => 'Übertreiben Sie die Standardqualität, wenn das Gerät eine cellular-only Verbindung verwendet.';
	@override String get remoteQualityDescription => 'Override Default Quality bei der Verbindung zu einem Server über eine Fernverbindung.';
	@override String get qualityPresetOriginalDescription => 'Spielen Sie die Quelle in ihrer verfügbaren Qualität, ohne den Server um Transcode zu bitten.';
	@override String get qualityPresetTranscodeOptionDescription => 'Befragen Sie den Server für einen konvertierten Stream mit der oben angezeigten Auflösung und Bitrate.';
	@override String get qualityPresetSameAsDefaultDescription => 'Verwenden Sie die in Default Quality ausgewählte Qualität.';
	@override String get musicQualityDescription => 'Setzen Sie die maximale Audio-Bitrate, die vom Server angefordert wird; Original behält den Quellstrom.';
	@override String get musicQualityOriginalDescription => 'Speichern Sie das Quell-Audio ohne einen Bitrate-Capped Transcode.';
	@override String get musicQualityTranscodeOptionDescription => 'Erfordern Sie einen Server-Transcode, der in der Nähe des oben angezeigten Bitrate gefasst ist; die tatsächliche Ausgabe kann sich ändern.';
	@override String get maxVolumeInputLabel => 'Höchstvolumen ( % )';
	@override String get checkForUpdatesDescription => 'Überprüfen Sie jetzt, ob eine neuere Version von PlezyNG verfügbar ist.';
	@override String get appearanceDescription => 'Wählen Sie das App-Theme aus und bearbeiten Sie Bibliothekkarte, Heimräume und Navigation.';
	@override String get prerollLibraryDescription => 'Wählen Sie die Bibliothek aus, in der die Clips als Filmpre-Rolls verfügbar sind.';
	@override String get prerollSelectionDescription => 'Wählen Sie, welche Clips aus der ausgewählten Bibliothek vor den Filmen spielen können.';
	@override String get contentScreensaverDelayOptionDescription => 'Warten Sie viele Minuten ohne Eingabe, bevor Sie Screensaver Artwork anzeigen.';
	@override String get videoCodecOptionDescription => 'Erlauben Sie Live-Playback für diesen Codec, wenn er unterstützt wird. Unchecked Codecs werden vom Media Server überkodiert.';
}

// Path: themeEditor
class _Translations$themeEditor$de extends Translations$themeEditor$en {
	_Translations$themeEditor$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Integriert';
	@override String get presets => 'Vorlagen';
	@override String get custom => 'Benutzerdefiniert';
	@override String get customEmpty => 'Noch nicht erstellt';
	@override String get editCustom => 'Eigenes Design bearbeiten';
	@override String get editCustomDescription => 'Jede Farbe selbst wählen';
	@override String get locked => 'Lebensdauer Zugang erforderlich';
	@override String get savedLocked => 'Sparen – mit lebenslangem Zugang verfügbar';
	@override String get title => 'Eigenes Design';
	@override String get startFrom => 'Basierend auf';
	@override String get startFromDescription => 'Alle Farben aus einem anderen Design übernehmen';
	@override String get colors => 'Farben';
	@override String get preview => 'Vorschau';
	@override late final _Translations$themeEditor$slots$de slots = _Translations$themeEditor$slots$de._(_root);
	@override String get opacity => 'Deckkraft';
	@override String get hexHint => '#RRGGBB oder #AARRGGBB';
	@override String get fromOtherThemes => 'Aus anderen Designs';
	@override String swatchLabel({required Object theme, required Object color}) => '${theme}: ${color}';
	@override late final _Translations$themeEditor$contrast$de contrast = _Translations$themeEditor$contrast$de._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, unter den empfohlenen ${minimum}:1';
	@override String get discardTitle => 'Änderungen verwerfen?';
	@override String get discardMessage => 'Deine nicht gespeicherten Farbänderungen gehen verloren.';
	@override String get discard => 'Verwerfen';
	@override String previewCardTitle({required Object number}) => 'Folge ${number}';
	@override String previewCardSubtitle({required Object minutes}) => 'Noch ${minutes} Min.';
	@override String get previewSwitch => 'Autoplay';
	@override String get previewMutedText => 'So sieht Sekundärtext aus';
	@override String get themeSystemDescription => 'Folgen Sie dem Aussehen Ihres Geräts und wechseln Sie automatisch zwischen Licht und Dunkel.';
	@override String get themeLightDescription => 'Verwenden Sie einen hellen Hintergrund mit dunkler Text.';
	@override String get themeDarkDescription => 'Verwenden Sie einen dunklen Hintergrund mit leichten Texten.';
	@override String get themeOledDescription => 'Verwenden Sie nahschwarze Oberflächen, die Licht auf OLED-Displays reduzieren.';
	@override String get themeEmberDescription => 'Verwenden Sie warme rote und amber-Accentfarben.';
	@override String get themeGlacierDescription => 'Verwenden Sie cool blaue Akzente Farben.';
	@override String get themeForestDescription => 'Verwenden Sie gemütete grüne und natürliche Accent Farben.';
	@override String get themePlumDescription => 'Verwenden Sie violette und plum accent Farben.';
	@override String get themePaperDescription => 'Verwenden Sie warme Papierflächen und Ink-inspirierte Farben.';
	@override String get themeCustomDescription => 'Verwenden Sie die Farbpalette, die Sie in der angepassten Theme-Editor erstellt haben.';
	@override String get editorDescription => 'Wählen Sie eine Palettefarbe, bearbeiten Sie ihre Farbe, Sättigung, Glanz oder Offenheit und sehen Sie die Aktualisierung des Vorgangs vor dem Speichern.';
}

// Path: search
class _Translations$search$de extends Translations$search$en {
	_Translations$search$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Filme, Serien und Musik suchen …';
	@override String get tryDifferentTerm => 'Anderen Suchbegriff versuchen';
	@override String get searchYourMedia => 'In den eigenen Medien suchen';
	@override String get enterTitleActorOrKeyword => 'Titel, Schauspieler oder Stichwort eingeben';
	@override String get people => 'Personen';
}

// Path: hotkeys
class _Translations$hotkeys$de extends Translations$hotkeys$en {
	_Translations$hotkeys$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
	@override String get clearShortcut => 'Kürzel löschen';
	@override String get noShortcutSet => 'Kein Tastenkürzel festgelegt';
	@override String get currentShortcut => 'Aktuelle Tastenkombination:';
	@override String get pressToRecord => 'Auswählen, um eine Tastenkombination aufzuzeichnen';
	@override String get recordingShortcut => 'Jetzt die Tastenkombination drücken';
	@override late final _Translations$hotkeys$actions$de actions = _Translations$hotkeys$actions$de._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$de extends Translations$fileInfo$en {
	_Translations$fileInfo$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dateiinformationen';
	@override String get overview => 'Übersicht';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Untertitel';
	@override String get images => 'Eingebettete Bilder';
	@override String get dataStreams => 'Datenstreams';
	@override String get lyrics => 'Songtexte';
	@override String get file => 'Datei';
	@override String get attachments => 'Anhänge';
	@override String get delivery => 'Bereitstellung';
	@override String versionCounter({required Object index, required Object count}) => 'Version ${index} von ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Datei ${index} von ${count}';
	@override String get noStreams => 'Der Server hat für diese Datei keine Streams gemeldet.';
	@override String get copyPath => 'Pfad kopieren';
	@override String get pathCopied => 'Dateipfad kopiert';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Codec-Tag';
	@override String get resolution => 'Auflösung';
	@override String get codedResolution => 'Codierte Auflösung';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildrate';
	@override String get rotation => 'Rotation';
	@override String get comment => 'Kommentar';
	@override String get audioDescription => 'Audiodeskription';
	@override String get headerCompression => 'Header-Komprimierung';
	@override String get sidecarFile => 'Sidecar-Datei';
	@override String get transportTimestamp => 'Transport-Zeitstempel';
	@override String get displayOffset => 'Anzeige-Offset';
	@override String get previewFailureCode => 'Fehlercode der Vorschau';
	@override String get previewRetries => 'Vorschau-Wiederholungsversuche';
	@override String get aspectRatio => 'Seitenverhältnis';
	@override String get pixelAspectRatio => 'Pixel-Seitenverhältnis';
	@override String get profile => 'Profil';
	@override String get level => 'Level';
	@override String get bitDepth => 'Bittiefe';
	@override String get pixelFormat => 'Pixelformat';
	@override String get colorSpace => 'Farbraum';
	@override String get colorRange => 'Farbbereich';
	@override String get colorPrimaries => 'Primärfarben';
	@override String get colorTransfer => 'Farbübertragung';
	@override String get chromaSubsampling => 'Chroma-Subsampling';
	@override String get chromaLocation => 'Chroma-Position';
	@override String get scanType => 'Scan-Typ';
	@override String get interlaced => 'Interlaced';
	@override String get anamorphic => 'Anamorph';
	@override String get referenceFrames => 'Referenzbilder';
	@override String get dynamicRange => 'Dynamikbereich';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby-Vision-Level';
	@override String get dolbyVisionVersion => 'Dolby-Vision-Version';
	@override String get dolbyVisionLayers => 'Dolby-Vision-Ebenen';
	@override String get baseLayerCompatibility => 'Kompatibilität der Basisebene';
	@override String get avcBitstream => 'AVC-Bitstream';
	@override String get nalLengthSize => 'NAL-Längengröße';
	@override String get scalingMatrix => 'Benutzerdefinierte Skalierungsmatrix';
	@override String get streamIdentifier => 'Stream-Kennung';
	@override String get streamIndex => 'Stream-Index';
	@override String get streamId => 'Stream-ID';
	@override String get language => 'Sprache';
	@override String get languageCode => 'Sprachcode';
	@override String get streamTitle => 'Track-Titel';
	@override String get channels => 'Kanäle';
	@override String get sampleRate => 'Abtastrate';
	@override String get spatialAudio => 'Räumliches Audio';
	@override String get textBased => 'Textbasiert';
	@override String get subtitleFormat => 'Sidecar-Format';
	@override String get provider => 'Anbieter';
	@override String get matchScore => 'Übereinstimmungswert';
	@override String get externalDelivery => 'Kann separat bereitgestellt werden';
	@override String get sidecarPath => 'Sidecar-Pfad';
	@override String get sourceStream => 'Kopiert von';
	@override String get temporary => 'Temporär';
	@override String get timeBase => 'Zeitbasis';
	@override String get overallBitrate => 'Gesamtbitrate';
	@override String get path => 'Pfad';
	@override String get fileName => 'Dateiname';
	@override String get size => 'Größe';
	@override String get totalSize => 'Gesamtgröße';
	@override String get container => 'Container';
	@override String get duration => 'Dauer';
	@override String get previewThumbnails => 'Vorschaubilder';
	@override String get previewIndex => 'Vorschau-Index';
	@override String get packetLength => 'Paketlänge';
	@override String get filePresent => 'Datei vorhanden';
	@override String get fileReadable => 'Vom Server lesbar';
	@override String get streamPath => 'Stream-Pfad';
	@override String get optimizedForStreaming => 'Für Streaming optimiert';
	@override String get has64bitOffsets => '64-Bit-Offsets';
	@override String get protocol => 'Protokoll';
	@override String get mediaType => 'Medientyp';
	@override String get sourceKind => 'Quellenart';
	@override String get optimizedVersion => 'Optimierte Version';
	@override String get optimizationTarget => 'Optimierungsziel';
	@override String get deletedAt => 'Gelöscht';
	@override String get remoteSource => 'Remote-Quelle';
	@override String get infiniteStream => 'Endlos-Stream';
	@override String get directPlay => 'Direct Play';
	@override String get directStream => 'Direct Stream';
	@override String get transcoding => 'Transkodierung';
	@override String get etag => 'ETag';
	@override String get versionId => 'Versions-ID';
	@override String get fileId => 'Datei-ID';
	@override String get defaultAudioTrack => 'Standard-Audiospur';
	@override String get defaultSubtitleTrack => 'Standard-Untertitelspur';
	@override String get subtitlesOff => 'Aus';
	@override String get flagDefault => 'Standard';
	@override String get flagForced => 'Erzwungen';
	@override String get flagSelected => 'Ausgewählt';
	@override String get flagExternal => 'Extern';
	@override String get flagHearingImpaired => 'Für Hörgeschädigte';
	@override String get flagDub => 'Synchronfassung';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Profil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$de extends Translations$mediaMenu$en {
	_Translations$mediaMenu$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
	@override String get removeFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernen';
	@override String get viewDetails => 'Details anzeigen';
	@override String get goToSeries => 'Zur Serie';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get shuffleNotAvailableOffline => 'Zufallswiedergabe ist offline nicht verfügbar';
	@override String get fileInfo => 'Dateiinfo';
	@override String get deleteEpisodeFromServer => 'Folge vom Server löschen';
	@override String get deleteSeasonFromServer => 'Staffel vom Server löschen';
	@override String get deleteShowFromServer => 'Serie vom Server löschen';
	@override String get deleteMovieFromServer => 'Film vom Server löschen';
	@override String get deleteEpisodeTitle => 'Diese Folge löschen?';
	@override String get deleteSeasonTitle => 'Diese Staffel löschen?';
	@override String get deleteShowTitle => 'Diese Serie löschen?';
	@override String get deleteMovieTitle => 'Diesen Film löschen?';
	@override String get deleteEpisodeConfirm => 'Folge löschen';
	@override String get deleteSeasonConfirm => 'Staffel löschen';
	@override String get deleteShowConfirm => 'Serie löschen';
	@override String get deleteMovieConfirm => 'Film löschen';
	@override String get deleteAnyway => 'Trotzdem löschen';
	@override String confirmDeleteTarget({required Object title}) => '„${title}“ dauerhaft von deinem Server löschen?';
	@override String get deleteMultipleWarning => 'Dies umfasst alle Episoden und deren Dateien.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Dies löscht die ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} enthaltene Folge und ihre Datei.',
		other: 'Dies löscht alle ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folgen darin sowie ihre Dateien.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Dieses Element ist als ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Datei gespeichert, die gelöscht wird.',
		other: 'Dieses Element ist über ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Dateien verteilt gespeichert, die alle gelöscht werden.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} weitere Folge ist in derselben Datei gespeichert und wird ebenfalls gelöscht:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} weitere Folgen sind in derselben Datei gespeichert und werden ebenfalls gelöscht:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG konnte nicht prüfen, welche Dateien dadurch entfernt werden. Es könnte also mehr gelöscht werden als das oben genannte Element. Brich ab und versuche es erneut, oder lösche trotzdem.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Dein Server hat für dieses Element keine Dateidetails bereitgestellt, daher kann PlezyNG nicht prüfen, welche Dateien entfernt werden. Es könnte mehr gelöscht werden als das oben genannte Element.';
	@override String get mediaDeletedSuccessfully => 'Medienelement gelöscht';
	@override String get mediaFailedToDelete => 'Medienelement konnte nicht gelöscht werden';
	@override String get rate => 'Bewerten';
	@override String get playFromBeginning => 'Von Anfang an abspielen';
	@override String get playVersion => 'Version abspielen …';
}

// Path: rateSheet
class _Translations$rateSheet$de extends Translations$rateSheet$en {
	_Translations$rateSheet$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bewerten';
	@override String get server => 'Server';
	@override String get favorite => 'Favorit';
	@override String get favorited => 'Favorisiert';
	@override String get saved => 'Gespeichert';
	@override String get notAvailable => 'Keine Übereinstimmung gefunden';
	@override String get noConnectedServices => 'Verbinde einen Dienst in den Einstellungen, um dort zu bewerten.';
}

// Path: accessibility
class _Translations$accessibility$de extends Translations$accessibility$en {
	_Translations$accessibility$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, Film';
	@override String mediaCardShow({required Object title}) => '${title}, Serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'gesehen';
	@override String mediaCardPartiallyWatched({required Object percent}) => 'zu ${percent} Prozent gesehen';
	@override String get mediaCardUnwatched => 'ungesehen';
	@override String get tapToPlay => 'Zum Abspielen tippen';
	@override String get decrease => 'Verringern';
	@override String get increase => 'Erhöhen';
	@override String decreaseValue({required Object label}) => '${label} verringern';
	@override String increaseValue({required Object label}) => '${label} erhöhen';
	@override String get hue => 'Farbton';
	@override String get saturation => 'Sättigung';
	@override String get brightness => 'Helligkeit';
	@override String get hexColor => 'Hexadezimalfarbe';
	@override String get expandText => 'Text ausklappen';
	@override String get collapseText => 'Text einklappen';
	@override String get alphabetNavigation => 'Alphabetische Navigation';
	@override String get alphabetScrollHint => 'Nach oben oder unten wischen, um einen Buchstaben weiterzugehen';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Zeile ${row} von ${rowCount}, Spalte ${column} von ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Zeile ${row} von ${rowCount}';
	@override String get autoScrollPlay => 'Automatisches Scrollen starten';
	@override String get autoScrollPause => 'Automatisches Scrollen pausieren';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'rote';
	@override String get green => 'Grün';
	@override String get blue => 'Blau';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Zugänglichkeit';
	@override String get summary => 'Text, Kontrast, Bewegung und Kontrolle';
	@override String get systemHint => 'Die Zugänglichkeitssatzungen Ihres Geräts gelten immer. Diese Optionen fügen Anpassungen über PlezyNG hinzu.';
	@override String get readability => 'Lesen und Sehbarkeit';
	@override String get textSize => 'Zusatztextgröße';
	@override String get preview => 'Finden Sie Ihre nächste Geschichte. Lesen, hören und sehen Sie in Ihrem eigenen Tempo.';
	@override String get boldText => 'Schöne Interface Text';
	@override String get highContrast => 'hohe Kontrast';
	@override String get highContrastHint => 'Stärkeres Text, Auszeichnungen und Fokusindikatoren auf leichten oder dunklen Oberflächen.';
	@override String get interaction => 'Bewegung und Interaktion';
	@override String get reduceMotion => 'Bewegung reduzieren';
	@override String get reduceMotionHint => 'Animationen der Fokusanzeige, Seitenübergänge und dekorative Effekte anhalten.';
	@override String get largeTargets => 'Großer Touch-Ziel';
	@override String get largeTargetsHint => 'Geben Sie den gemeinsamen Kontroll mehr Platz für Berührung und assistive Navigation.';
	@override String get navigationHint => 'Mit Tab und Shift+Tab wechselst du zwischen Bedienelementen, mit Enter oder der Leertaste aktivierst du sie, und mit Escape oder Zurück schließt du sie. Wenn ein Buch geöffnet ist, kannst du den Zoom und die Leseeinstellungen anpassen.';
	@override String get textSizeDescription => 'Scale-Interface Text in PlezyNG neben der Systemtextgröße Einstellung Ihres Geräts.';
	@override String get boldTextHint => 'Verwenden Sie ein schwerer Gewicht für Interface-Label und Nachrichten, um sie leichter zu unterscheiden.';
}

// Path: tooltips
class _Translations$tooltips$de extends Translations$tooltips$en {
	_Translations$tooltips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get playTrailer => 'Trailer abspielen';
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
}

// Path: audioTracks
class _Translations$audioTracks$de extends Translations$audioTracks$en {
	_Translations$audioTracks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Audiospur ${n}';
}

// Path: videoControls
class _Translations$videoControls$de extends Translations$videoControls$en {
	_Translations$videoControls$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Untertitel';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Bild füllen';
	@override String get stretch => 'Strecken';
	@override String get lockRotation => 'Rotation sperren';
	@override String get unlockRotation => 'Rotation entsperren';
	@override String get timerActive => 'Schlaftimer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
	@override String get sleepTimerEndOfVideo => 'Ende des aktuellen Videos';
	@override String get sleepTimerStopAtHeader => 'Beenden bei';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'Wiedergabe wird am Ende dieses Videos pausiert';
	@override String get stillWatching => 'Schaust du noch?';
	@override String pausingIn({required Object seconds}) => 'Pause in ${seconds}s';
	@override String get continueWatching => 'Weiter';
	@override String get autoPlayNext => 'Nächstes automatisch abspielen';
	@override String get playNext => 'Nächstes abspielen';
	@override String get playButton => 'Abspielen';
	@override String get pauseButton => 'Pause';
	@override String get playbackPaused => 'Pausiert';
	@override String get playbackResumed => 'Wird abgespielt';
	@override String get loadingVideo => 'Video wird geladen';
	@override String get showPlaybackControls => 'Wiedergabesteuerung anzeigen';
	@override String get hidePlaybackControls => 'Wiedergabesteuerung ausblenden';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} Sekunden zurück';
	@override String seekForwardButton({required Object seconds}) => '${seconds} Sekunden vorwärts';
	@override String get previousButton => 'Vorherige Episode';
	@override String get nextButton => 'Nächste Episode';
	@override String get previousChapterButton => 'Vorheriges Kapitel';
	@override String get nextChapterButton => 'Nächstes Kapitel';
	@override String get muteButton => 'Stumm schalten';
	@override String get unmuteButton => 'Stummschaltung aufheben';
	@override String get settingsButton => 'Wiedergabeeinstellungen';
	@override String get tracksButton => 'Audio und Untertitel';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionQualityButton => 'Version & Qualität';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Qualität';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkodierung nicht verfügbar – Wiedergabe in Originalqualität';
	@override String get subtitleUnavailableFallback => 'Die ausgewählten Untertitel konnten nicht geladen werden – die Wiedergabe wird ohne Untertitel fortgesetzt';
	@override String get pipButton => 'Bild-in-Bild-Modus';
	@override String get aspectRatioButton => 'Seitenverhältnis';
	@override String get ambientLighting => 'Umgebungsbeleuchtung';
	@override String get fullscreenButton => 'Vollbild aktivieren';
	@override String get exitFullscreenButton => 'Vollbild verlassen';
	@override String get alwaysOnTopButton => 'Immer im Vordergrund';
	@override String get rotationLockButton => 'Drehsperre';
	@override String get lockScreen => 'Bildschirm sperren';
	@override String get screenLockButton => 'Bildschirmsperre';
	@override String get timelineSlider => 'Videozeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String endsAt({required Object time}) => 'Endet um ${time}';
	@override String get pipActive => 'Wiedergabe im Bild-in-Bild-Modus';
	@override String get pipFailed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override String get screenshotSaved => 'Screenshot gespeichert';
	@override String get screenshotFailed => 'Screenshot konnte nicht aufgenommen werden';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Lautstärke ${percent}%';
	@override late final _Translations$videoControls$pipErrors$de pipErrors = _Translations$videoControls$pipErrors$de._(_root);
	@override String get chapters => 'Kapitel';
	@override String get noChaptersAvailable => 'Keine Kapitel verfügbar';
	@override String get queue => 'Warteschlange';
	@override String get noQueueItems => 'Keine Elemente in der Warteschlange';
	@override String get noAudioDevicesAvailable => 'Keine Audiogeräte verfügbar';
	@override String get searchSubtitles => 'Untertitel suchen';
	@override String get language => 'Sprache';
	@override String get noSubtitlesFound => 'Keine Untertitel gefunden';
	@override String get subtitleDownloaded => 'Untertitel heruntergeladen';
	@override String get subtitleDownloadedNotApplied => 'Der Untertitel wurde heruntergeladen, konnte aber nicht ausgewählt werden';
	@override String get subtitleDownloadFailed => 'Untertitel konnte nicht heruntergeladen werden';
	@override String get searchLanguages => 'Sprachen suchen...';
	@override String get skipIntro => 'Intro überspringen';
	@override String get skipCredits => 'Abspann überspringen';
	@override String get nextEpisode => 'Nächste Episode';
	@override String subtitleTrack({required Object n}) => 'Spur ${n}';
	@override String subtitleFile({required Object name}) => 'Untertitel ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Erzwungen)';
	@override String get osdSubtitlesOff => 'Untertitel: Aus';
	@override String osdSubtitles({required Object track}) => 'Untertitel: ${track}';
	@override String osdAudio({required Object track}) => 'Audio: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame',
	);
	@override String get trackSelectionTitle => 'Track vor Playback auswählen';
	@override String get trackSelectionAuto => 'Automatische Auswahl';
	@override String get openMiniPlayer => 'Open Mini-Spieler';
	@override String get returnToFullPlayer => 'Zurück zum Vollspieler';
	@override String get loadSubtitleFile => 'Download Subtitle Datei ...';
	@override String get subtitleLoadFailed => 'Laden Sie nicht die Subtitle-Datei';
	@override String get skipAds => 'Werbung überspringen';
	@override String get tapToUnlock => 'Zum Entsperren tippen';
	@override String get tapAgainToUnlock => 'Zum Entsperren erneut tippen';
	@override String get segmentLoopHelp => 'Set A, dann set B später in der Timeline.';
	@override String get setLoopStart => 'Set loop start (A)';
	@override String get setLoopEnd => 'Set loop end (B)';
	@override String get clearSegmentLoop => 'Klares Segment Lauf';
	@override String get setLoopStartFirst => 'Set Loop Start (A) vor dem Ende (B).';
	@override String get loopEndAfterStart => 'Das Ende des Laufens muss später als der Anfang sein.';
	@override String get segmentLoopUnavailable => 'Segment looping ist für diesen playback nicht verfügbar.';
	@override String get bookmarksHelp => 'Buchmarken werden auf diesem Gerät gespeichert. Wählen Sie einen, um zu dieser Zeit zu gehen.';
	@override String get bookmarksButton => 'Buchmarken';
	@override String get chaptersAndBookmarks => 'Kapitel und Buchmarken';
	@override String get segmentLoop => 'Segment Lauf';
	@override String get addBookmark => 'Bookmark hinzufügen';
	@override String get bookmarkName => 'Bookmark Name';
	@override String get bookmarkNameHint => 'Zum Beispiel die Öffnungszene';
	@override String bookmarkDefaultName({required Object n}) => 'Buchmarke ${n}';
	@override String get bookmarkNameRequired => 'Geben Sie einen Namen für diese Buchmarke ein.';
	@override String get deleteBookmark => 'Buchmarke löschen';
	@override String get bookmarkLimitReached => 'Dieser Artikel hat bereits 100 Buchmarken.';
	@override String get bookmarkUnavailable => 'Ich konnte diese Buchmarke nicht speichern oder entfernen.';
	@override String get bookmarkSaved => 'Bookmark gerettet wurde.';
	@override String get bookmarkDeleted => 'Bookmark gelöscht wurde.';
	@override String loopPointSet({required Object point, required Object time}) => 'Laufpunkt ${point} Set auf ${time}.';
	@override String get noChaptersOrBookmarks => 'Keine Kapitel oder Buchmarken verfügbar.';
	@override String get loopPointNotSet => 'nicht set';
}

// Path: messages
class _Translations$messages$de extends Translations$messages$en {
	_Translations$messages$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Als gesehen markiert';
	@override String get markedAsUnwatched => 'Als ungesehen markiert';
	@override String get markedAsWatchedOffline => 'Als gesehen markiert (wird synchronisiert, wenn online)';
	@override String get markedAsUnwatchedOffline => 'Als ungesehen markiert (wird synchronisiert, wenn online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisch entfernt: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Automatisch entfernt: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} angesehener Download',
		other: 'Automatisch entfernt: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} angesehene Downloads',
	);
	@override String get removedFromContinueWatching => 'Aus „Weiterschauen“ entfernt';
	@override String errorLoading({required Object error}) => 'Fehler: ${error}';
	@override String get searchPartialResults => 'Einige Medienserver konnten nicht durchsucht werden. Verfügbare Ergebnisse werden angezeigt.';
	@override String get streamInterrupted => 'Der Stream wurde unterbrochen. Drücke auf Wiedergabe oder spule, um es erneut zu versuchen.';
	@override String get liveStreamInterrupted => 'Der Livestream wurde unterbrochen. Drücke auf Wiedergabe, um es erneut zu versuchen.';
	@override String get fileInfoNotAvailable => 'Dateiinfo nicht verfügbar';
	@override String get playbackAuthenticationRequired => 'Melde dich erneut beim Medienserver an, um dieses Element abzuspielen.';
	@override String get playbackServerUnavailable => 'Der Medienserver ist nicht verfügbar. Versuche es später erneut.';
	@override String get playbackDataInvalid => 'Der Server hat ungültige Wiedergabeinformationen zurückgegeben.';
	@override String get playbackCancelled => 'Die Wiedergabe wurde abgebrochen.';
	@override String get playbackFailed => 'Die Wiedergabe konnte nicht gestartet werden.';
	@override String playbackFailedDetail({required Object error}) => 'Die Wiedergabe konnte nicht gestartet werden: ${error}';
	@override String get audioOutputFailed => 'Die Audioausgabe reagiert nicht mehr. Prüfe die Audioverbindung des Fernsehers oder Receivers; wenn auch andere Apps keinen Ton haben, starte das Gerät neu.';
	@override String get mediaUnavailable => 'Dieser Inhalt ist nicht mehr verfügbar.';
	@override String errorLoadingFileInfo({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
	@override String get errorLoadingSeries => 'Fehler beim Laden der Serie';
	@override String get musicNotSupported => 'Musikwiedergabe wird noch nicht unterstützt';
	@override String get noDescriptionAvailable => 'Keine Beschreibung verfügbar';
	@override String get noProfilesAvailable => 'Keine Profile verfügbar';
	@override String get contactAdminForProfiles => 'Wende dich an deinen Serveradministrator, um Profile hinzuzufügen';
	@override String get unableToDetermineLibrarySection => 'Der Mediatheksbereich für dieses Element konnte nicht ermittelt werden';
	@override String get logsCleared => 'Protokolle gelöscht';
	@override String get logsCopied => 'Protokolle in Zwischenablage kopiert';
	@override String get noLogsAvailable => 'Keine Protokolle verfügbar';
	@override String libraryScanning({required Object title}) => '„${title}“ wird gescannt …';
	@override String libraryScanStarted({required Object title}) => 'Mediathekscan gestartet für „${title}“';
	@override String libraryScanFailed({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadaten für „${title}“ werden aktualisiert …';
	@override String metadataRefreshStarted({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
	@override String metadataRefreshFailed({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
	@override String get logoutConfirm => 'Abmeldung wirklich durchführen?';
	@override String get noSeasonsFound => 'Keine Staffeln gefunden';
	@override String get seasonsLoadFailed => 'Staffeln konnten nicht geladen werden';
	@override String get noEpisodesFound => 'Keine Episoden in der ersten Staffel gefunden';
	@override String get noEpisodesFoundGeneral => 'Keine Episoden gefunden';
	@override String get episodesLoadFailed => 'Episoden konnten nicht geladen werden';
	@override String get noResultsFound => 'Keine Ergebnisse gefunden';
	@override String sleepTimerSet({required Object label}) => 'Schlaftimer auf ${label} eingestellt';
	@override String get noItemsAvailable => 'Keine Elemente verfügbar';
	@override String get failedToCreatePlayQueueNoItems => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
	@override String failedPlayback({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
	@override String get switchingToCompatiblePlayer => 'Wechsel zu einem kompatiblen Player …';
	@override String get serverLimitTitle => 'Wiedergabe fehlgeschlagen';
	@override String get serverLimitBody => 'Serverfehler (HTTP 500). Vermutlich hat ein Bandbreiten- oder Transkodierungslimit diese Sitzung abgelehnt. Bitte den Besitzer, das Limit anzupassen.';
	@override String get mediaUnreadableTitle => 'Datei nicht verfügbar';
	@override String get mediaUnreadableBody => 'Der Server hat dieses Element gefunden, konnte seine Datei aber nicht lesen (HTTP 404). Die Datei wurde wahrscheinlich verschoben oder gelöscht, oder ihr Speicher ist offline. Bitte den Serverbesitzer, die Datei zu prüfen und die Mediathek neu zu scannen.';
	@override String get serverBusyTitle => 'Stream nicht verfügbar';
	@override String get serverBusyBody => 'Der Server hat das Streamen dieser Datei wiederholt abgelehnt (HTTP 503). Möglicherweise wird er neu gestartet, ist ausgelastet oder der Speicherort der Datei ist offline. Versuche es gleich noch einmal. Falls das Problem weiterhin auftritt, bitte den Serverbetreiber, den Server und den Speicherort der Datei zu überprüfen.';
	@override String get playbackNotAllowedTitle => 'Wiedergabe nicht erlaubt';
	@override String get playbackNotAllowedBody => 'Der Server hat das Streamen dieses Elements abgelehnt (HTTP 403). Dein Konto hat möglicherweise keine Berechtigung, es abzuspielen, oder der Server erlaubt die Wiedergabe nur in seinem lokalen Netzwerk.';
	@override String get logsUploaded => 'Protokolle hochgeladen';
	@override String get logsUploadFailed => 'Protokolle konnten nicht hochgeladen werden';
	@override String get logId => 'Protokoll-ID';
	@override String get burnedSubtitlesUseMenu => 'Die Untertitel sind in diesen Stream eingebrannt. Ändere sie über das Untertitelmenü.';
	@override String get noVideoUrl => 'Keine Video-URL verfügbar';
	@override String get playbackNoMediaSources => 'Der Server hat keine abspielbaren Medienquellen zurückgegeben';
	@override String get playbackDataNotPrepared => 'Die Wiedergabe wurde gestartet, bevor die Daten bereit waren';
	@override String get streamSelectionUnavailable => 'Die Streamauswahl ist für diese Quelle nicht verfügbar';
	@override String get streamSelectionFailed => 'Die ausgewählten Streams konnten nicht angewendet werden';
	@override String get trackSelectionNotRemembered => 'Diese Spurauswahl gilt nur für die aktuelle Wiedergabe.';
	@override String get serverUnavailableForProfile => 'Für das aktive Profil ist kein Server verfügbar';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$de extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'Der schnelle braune Fox springt über den lazy hund';
	@override String get text => 'Text';
	@override String get border => 'Rahmen';
	@override String get background => 'Hintergrund';
	@override String get fontSize => 'Schriftgröße';
	@override String get textColor => 'Textfarbe';
	@override String get borderSize => 'Rahmengröße';
	@override String get borderColor => 'Rahmenfarbe';
	@override String get backgroundOpacity => 'Hintergrunddeckkraft';
	@override String get backgroundColor => 'Hintergrundfarbe';
	@override String get position => 'Position';
	@override String get assOverride => 'ASS-Überschreibung';
	@override String get overrideScale => 'Skalieren';
	@override String get overrideForce => 'Erzwingen';
	@override String get overrideStrip => 'Formatierung entfernen';
	@override String get positionTop => 'Oben';
	@override String get positionBottom => 'Unten';
	@override String get useMargins => 'Ränder verwenden';
	@override String get useMarginsDescription => 'Textuntertitel im Bereich außerhalb des Videos zulassen. Gestylte Untertitel behalten möglicherweise ihre ursprüngliche Position.';
	@override String get anchorToScreen => 'Am Bildschirm verankern';
	@override String get anchorToScreenDescription => 'Textuntertitel in den schwarzen Balken unter Breitbildvideos anzeigen';
	@override String get bold => 'Fett';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Render-Auflösung';
	@override String get renderResolutionScreen => 'Bildschirmauflösung';
	@override String get renderResolutionVideo => 'Videoauflösung';
	@override String get fontSizeDescription => 'Setzen Sie die Subtitle Textgröße auf diesem Gerät.';
	@override String get textColorDescription => 'Wählen Sie die für Subtitle Text verwendete Farbe aus.';
	@override String get borderSizeDescription => 'Setzen Sie die Dicke der Ausgabe um Subtitle Text.';
	@override String get borderColorDescription => 'Wählen Sie die verwendete Farbe für die Subtitle-Ausgabe aus.';
	@override String get backgroundColorDescription => 'Wählen Sie die Farbe hinter dem Subtitle Text aus.';
	@override String get backgroundOpacityDescription => 'Stellen Sie fest, wie transparent der Untertitel Hintergrund ist: 0% ist klar und 100% fester.';
	@override String get positionDescription => 'Move Subtitles vertikal. 0% ist die Spitze des Videos und 100% ist die Unterseite.';
	@override String get assOverrideDescription => 'Wählen Sie aus, ob der Spieler folgt, angepasst, ersetzt oder Styling in ASS Subtitles eingebaut entfernt.';
	@override late final _Translations$subtitlingStyling$assOverrideOptions$de assOverrideOptions = _Translations$subtitlingStyling$assOverrideOptions$de._(_root);
	@override String get renderResolutionDescription => 'Wählen Sie die Auflösung, die verwendet wird, um Bild und ASS Untertitel zu rasterisieren. Die niedrigeren Android-Skala können Rendering Arbeit reduzieren, aber leichter aussehen.';
	@override late final _Translations$subtitlingStyling$renderResolutionOptions$de renderResolutionOptions = _Translations$subtitlingStyling$renderResolutionOptions$de._(_root);
	@override String get boldDescription => 'Zeichnen Sie Subtiteltext in einem schwereren Gewicht.';
	@override String get italicDescription => 'Untertitel Text in Italienisch zu entwerfen.';
}

// Path: mpvConfig
class _Translations$mpvConfig$de extends Translations$mpvConfig$en {
	_Translations$mpvConfig$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Erweiterte Videoplayer-Einstellungen';
	@override String get presets => 'Voreinstellungen';
	@override String get noPresets => 'Keine gespeicherten Voreinstellungen';
	@override String get saveAsPreset => 'Als Voreinstellung speichern …';
	@override String get presetName => 'Name der Voreinstellung';
	@override String get presetNameHint => 'Namen für diese Voreinstellung eingeben';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Löschen';
	@override String get presetSaved => 'Voreinstellung gespeichert';
	@override String get presetLoaded => 'Voreinstellung geladen';
	@override String get presetDeleted => 'Voreinstellung gelöscht';
	@override String get confirmDeletePreset => 'Diese Voreinstellung wirklich löschen?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Zeile hinzufügen';
	@override String get removeLine => 'Zeile entfernen';
	@override String get embeddedVoHint => 'vo, gpu-context und gpu-api werden unter Linux ignoriert: eingebettetes Video wird immer über vo=libmpv auf der Videoebene gerendert, und gpu-next (das Compute-Shader wie ArtCNN benötigen) kann nicht eingebettet ausgeführt werden.';
}

// Path: dialog
class _Translations$dialog$de extends Translations$dialog$en {
	_Translations$dialog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
}

// Path: profiles
class _Translations$profiles$de extends Translations$profiles$en {
	_Translations$profiles$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'PlezyNG-Profil hinzufügen';
	@override String get switchingProfile => 'Profil wird gewechselt…';
	@override String get deleteThisProfileTitle => 'Dieses Profil löschen?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} entfernen. Verbindungen bleiben unberührt.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Verwalten';
	@override String get delete => 'Löschen';
	@override String get signOut => 'Abmelden';
	@override String get signOutPlexTitle => 'Von Plex abmelden?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} und alle Plex Home-Benutzer entfernen? Du kannst dich jederzeit wieder anmelden.';
	@override String get signOutPlexDeleteDownloads => 'Downloads ebenfalls löschen';
	@override String get signOutPlexDeleteDownloadsDescription => 'Andernfalls bleiben sie auf diesem Gerät und sind wieder da, wenn du dich erneut bei diesem Konto anmeldest.';
	@override String get signedOutPlex => 'Von Plex abgemeldet.';
	@override String get signOutFailed => 'Abmeldung fehlgeschlagen.';
	@override String get sectionTitle => 'Profile';
	@override String get summarySingle => 'Profile hinzufügen, um verwaltete Benutzer mit lokalen Identitäten zu kombinieren';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} Profile · aktiv: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} Profile';
	@override String get removeConnectionTitle => 'Verbindung entfernen?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Zugriff von ${displayName} auf ${connectionLabel} entfernen. Andere Profile behalten ihn.';
	@override String get deleteProfileTitle => 'Profil löschen?';
	@override String deleteProfileMessage({required Object displayName}) => '${displayName} und Verbindungen entfernen. Server bleiben verfügbar.';
	@override String get profileNameLabel => 'Profilname';
	@override String get pinProtectionLabel => 'PIN-Schutz';
	@override String get copyAutomationLink => 'Kopieren Android Automatisierung Link';
	@override String get copyAutomationLinkDescription => 'Wählen Sie dieses Profil aus einer Android Absicht oder Automatisierung aus. Profil-PIN-Checks gelten noch.';
	@override String get automationLinkCopied => 'Profil-Automatisierung Link kopiert.';
	@override String get pinManagedByPlex => 'PIN wird von Plex verwaltet. Auf plex.tv bearbeiten.';
	@override String get noPinSetEditOnPlex => 'Keine PIN festgelegt. Um eine zu verlangen, bearbeite den Home-Benutzer auf plex.tv.';
	@override String get setPin => 'PIN festlegen';
	@override String get setPinTitle => 'PIN festlegen';
	@override String get confirmPinTitle => 'PIN bestätigen';
	@override String get pinSet => 'PIN festgelegt';
	@override String get changePin => 'Ändern';
	@override String get removePin => 'Entfernen';
	@override String get connectionsLabel => 'Verbindungen';
	@override String get add => 'Hinzufügen';
	@override String get deleteProfileButton => 'Profil löschen';
	@override String get noConnectionsHint => 'Keine Verbindungen — füge eine hinzu, um dieses Profil zu nutzen.';
	@override String get noConnections => 'Keine Verbindungen';
	@override String get plexHomeAccount => 'Plex Home-Konto';
	@override String plexAccountChip({required Object account}) => 'Plex-Konto: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} über ${account}';
	@override String get connectionDefault => 'Standard';
	@override String connectionAs({required Object displayName}) => 'als ${displayName}';
	@override String get makeDefault => 'Als Standard festlegen';
	@override String get removeConnection => 'Entfernen';
	@override String get profileRenamed => 'Profil umbenannt.';
	@override String borrowAddTo({required Object displayName}) => 'Zu ${displayName} hinzufügen';
	@override String get borrowExplain => 'Verbindung eines anderen Profils übernehmen. PIN-geschützte Profile erfordern eine PIN.';
	@override String get borrowEmpty => 'Keine Verbindungen zum Übernehmen verfügbar.';
	@override String get borrowEmptySubtitle => 'Verbinde zuerst Plex, Jellyfin oder Emby mit einem anderen Profil.';
	@override String get borrowLoadFailed => 'Verfügbare Verbindungen konnten nicht geladen werden. Versuche es erneut.';
	@override String borrowFromProfile({required Object displayName}) => 'Von ${displayName}';
	@override String get borrowConnectionBorrowed => 'Verbindung übernommen.';
	@override String get borrowFailed => 'Verbindung konnte nicht übernommen werden.';
	@override String get incorrectPin => 'Falsche PIN.';
	@override String get incorrectPinTryAgain => 'Falsche PIN. Bitte erneut versuchen.';
	@override String get sourceProfileMissingParentAccount => 'Dem Quellprofil fehlt das übergeordnete Konto.';
	@override String get failedToLoadHomeUsers => 'Deine Plex-Home-Benutzer konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';
	@override String get failedToVerifyPin => 'PIN konnte nicht verifiziert werden.';
	@override String get newProfile => 'Neues Profil';
	@override String get profileNameHint => 'z. B. Gäste, Kinder, Wohnzimmer';
	@override String get pinProtectionOptional => 'PIN-Schutz (optional)';
	@override String get pinExplain => '4-stellige PIN zum Profilwechsel erforderlich.';
	@override String get continueButton => 'Weiter';
	@override String get pinsDontMatch => 'PINs stimmen nicht überein';
	@override String get tokenIdentityMismatch => 'Das Plex-Profil-Token wurde einem unerwarteten Server zugeordnet';
	@override String get settingsLocked => 'Die Einstellungen sind für diesen Profil gesperrt.';
	@override String get unlockSettings => 'Unlock Settings';
	@override String get showExploreForProfile => 'Show Explore für dieses Profil';
	@override String get showExploreForProfileDescription => 'Stopp aus, um Explore aus der Navigation dieses Profils zu entfernen.';
}

// Path: connections
class _Translations$connections$de extends Translations$connections$en {
	_Translations$connections$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Verbindungen';
	@override String get addConnection => 'Verbindung hinzufügen';
	@override String get addConnectionSubtitleNoProfile => 'Mit Plex anmelden oder mit einem Jellyfin- oder Emby-Server verbinden';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Zu ${displayName} hinzufügen: Plex, Jellyfin, Emby oder eine andere Profilverbindung';
	@override String sessionExpiredOne({required Object name}) => 'Sitzung für ${name} abgelaufen';
	@override String sessionExpiredMany({required Object count}) => 'Sitzungen für ${count} Server abgelaufen';
	@override String accessDeniedOne({required Object name}) => '${name} verweigert diesem Konto den Zugriff';
	@override String accessDeniedMany({required Object count}) => '${count} Server verweigern diesem Konto den Zugriff';
	@override String get signInAgain => 'Erneut anmelden';
	@override String editMediaBrowserTitle({required Object product}) => 'Verbindung zu ${product} bearbeiten';
	@override String editMediaBrowserIntro({required Object serverName}) => 'URLs für ${serverName} hinzufügen oder entfernen. PlezyNG verwendet die erreichbare URL mit der geringsten Latenz.';
}

// Path: accountPreferences
class _Translations$accountPreferences$de extends Translations$accountPreferences$en {
	_Translations$accountPreferences$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Kontoeinstellungen';
	@override String hubSubtitleSingle({required Object account}) => 'Audio-, Untertitel- und Mediathek-Optionen werden auf ${account} gespeichert';
	@override String hubSubtitleMultiple({required Object count}) => 'Audio-, Untertitel- und Mediathek-Optionen werden auf ${count} Konten gespeichert';
	@override String get pickAccount => 'Jedes Konto speichert seine eigenen Einstellungen. Wähle das Konto, das du bearbeiten möchtest.';
	@override String get storedOnAccount => 'Diese Optionen werden auf dem Konto selbst gespeichert, sodass jede damit angemeldete App sie verwendet — auch PlezyNG auf deinen anderen Geräten.';
	@override String get noAccounts => 'Keine Konten zum Konfigurieren';
	@override String get noAccountsHint => 'Melde dich bei Plex an oder verbinde einen Jellyfin- oder Emby-Server — die auf diesem Konto gespeicherten Einstellungen erscheinen dann hier.';
	@override String get unavailable => 'Dieses Konto ist nicht erreichbar';
	@override String get loadFailed => 'Diese Einstellungen konnten nicht geladen werden';
	@override String get noPreference => 'Keine Einstellung';
	@override String get notSet => 'Nicht festgelegt';
	@override late final _Translations$accountPreferences$groups$de groups = _Translations$accountPreferences$groups$de._(_root);
	@override String get preferredAudioLanguage => 'Bevorzugte Audiosprache';
	@override String get autoSelectAudio => 'Audio nach Sprache auswählen';
	@override String get autoSelectAudioDescription => 'Bei „Aus“ wird die Audiospur verwendet, die die Datei als Standard markiert.';
	@override String get preferredSubtitleLanguage => 'Bevorzugte Untertitelsprache';
	@override String get subtitleMode => 'Untertitel einschalten';
	@override late final _Translations$accountPreferences$subtitleModes$de subtitleModes = _Translations$accountPreferences$subtitleModes$de._(_root);
	@override String get subtitleAccessibility => 'SDH-Untertitel';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$de subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$de._(_root);
	@override String get forcedSubtitles => 'Erzwungene Untertitel';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$de forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$de._(_root);
	@override String get displayMissingEpisodes => 'Fehlende Episoden anzeigen';
	@override String get displayMissingEpisodesDescription => 'Episoden auflisten, die dem Server bekannt sind, für die aber keine Datei vorliegt.';
	@override String get hidePlayedInLatest => 'Gesehene Elemente in „Neueste“ ausblenden';
	@override String get hidePlayedInLatestDescription => 'Elemente, die du bereits gesehen hast, erscheinen nicht mehr in den „Neueste“-Zeilen des Servers.';
	@override String get displayCollectionsView => 'Sammlungsansicht anzeigen';
	@override String get displayCollectionsViewDescription => 'Die Sammlungsansicht des Servers zusätzlich zu deinen Mediatheken anzeigen.';
	@override String get rewatchingInNextUp => 'Erneut geschaute Serien in „Als Nächstes“ behalten';
	@override String get rewatchingInNextUpDescription => 'Beendest du eine Serie und startest sie erneut, folgt „Als Nächstes“ dem erneuten Anschauen, statt die Serie zu verwerfen.';
	@override String get watchedIndicator => 'Gesehen-Markierung';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$de watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$de._(_root);
	@override String get mediaReviewsVisibility => 'Bewertungen & Rezensionen';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$de mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$de._(_root);
	@override String get preferredAudioLanguageDescription => 'Sie bevorzugen Audio-Track in dieser Sprache, wenn der Server oder Player automatisch einen Track auswählt.';
	@override String get preferredSubtitleLanguageDescription => 'Sie bevorzugen Untertitel-Track in dieser Sprache, wenn Subtitles automatisch ausgewählt werden.';
	@override String get subtitleAccessibilityDescription => 'Wählen Sie aus, ob SDH-Kaptionen während der automatischen Subtitelwahl bevorzugt oder erforderlich sind.';
	@override String get forcedSubtitleDescription => 'Wählen Sie aus, ob gezwungenen Subtitle-Stracken während der automatischen Auswahl bevorzugt oder erforderlich sind.';
	@override String get watchedIndicatorDescription => 'Wählen Sie aus, welche Medienarten eine beobachtete Checkmarke in der Server-Interface erhalten.';
	@override String get mediaReviewsVisibilityDescription => 'Wählen Sie aus, welche Publikum und kritische Bewertungen der Server auf Medienseiten anzeigt.';
	@override String get subtitleModeDescription => 'Wählen Sie aus, wann die Untertitel automatisch für diesen Server-Konto aktiviert werden.';
	@override String get hubDescription => 'Diese Präferenzen werden auf Ihrem Media-Server-Konto gespeichert und können auch für andere Kunden gelten.';
}

// Path: discover
class _Translations$discover$de extends Translations$discover$en {
	_Translations$discover$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entdecken';
	@override String get noContentAvailable => 'Kein Inhalt verfügbar';
	@override String get addMediaToLibraries => 'Medien zur Mediathek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String continueWatchingIn({required Object library}) => 'Weiterschauen in ${library}';
	@override String get nextUp => 'Als Nächstes';
	@override String nextUpIn({required Object library}) => 'Als Nächstes in ${library}';
	@override String get recentlyAdded => 'Kürzlich hinzugefügt';
	@override String recentlyAddedIn({required Object library}) => 'Kürzlich hinzugefügt in ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Neueste Alben in ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Kürzlich gespielt in ${library}';
	@override String mostPlayedIn({required Object library}) => 'Am häufigsten gespielt in ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override late final _Translations$discover$findNext$de findNext = _Translations$discover$findNext$de._(_root);
	@override String get extras => 'Trailer & Extras';
	@override String get studio => 'Studio';
	@override String get rating => 'Altersfreigabe';
	@override String get director => 'Regisseur';
	@override String get directors => 'Regisseure';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie';
	@override String minutesLeft({required Object minutes}) => 'Noch ${minutes} Min.';
	@override String get moreLikeThis => 'Ähnliche Inhalte';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel',
	);
	@override late final _Translations$discover$person$de person = _Translations$discover$person$de._(_root);
}

// Path: errors
class _Translations$errors$de extends Translations$errors$en {
	_Translations$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Suche fehlgeschlagen: ${error}';
	@override String get searchUnavailable => 'Die Suche konnte keinen Medienserver erreichen.';
	@override String connectionTimeout({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
	@override String get connectionFailed => 'Keine Verbindung zum Medienserver möglich';
	@override String unableToLoad({required Object context}) => '${context} konnte nicht geladen werden. Bitte erneut versuchen.';
	@override String get noClientAvailable => 'Kein Client verfügbar';
	@override String get pleaseEnterToken => 'Bitte Token eingeben';
	@override String get invalidToken => 'Ungültiges Token';
	@override String failedToVerifyToken({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
	@override String failedToDeleteProfile({required Object displayName}) => 'Löschen von ${displayName} fehlgeschlagen';
	@override String get failedToRate => 'Bewertung konnte nicht aktualisiert werden';
	@override String get reasonTimedOut => 'Zeitüberschreitung bei der Verbindung';
	@override String get reasonUnreachable => 'der Medienserver konnte nicht erreicht werden';
	@override String get reasonRefused => 'der Medienserver hat die Anfrage abgelehnt';
	@override String get reasonNotFound => 'das Element befindet sich nicht mehr auf dem Medienserver';
	@override String get reasonServerError => 'der Medienserver hat einen Fehler gemeldet';
	@override String get reasonCancelled => 'die Anfrage wurde abgebrochen';
	@override String get reasonUnexpected => 'ein unerwarteter Fehler ist aufgetreten';
}

// Path: libraries
class _Translations$libraries$de extends Translations$libraries$en {
	_Translations$libraries$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Spielen Sie einen Random-Film';
	@override String get randomPickFailed => 'Ich kann nicht einen Film aus dieser Bibliothek wählen.';
	@override String get title => 'Mediatheken';
	@override String get fallbackTitle => 'Mediathek';
	@override String get scanLibraryFiles => 'Mediatheksdateien scannen';
	@override String get scanLibrary => 'Mediathek scannen';
	@override String get analyze => 'Analysieren';
	@override String get analyzeLibrary => 'Mediathek analysieren';
	@override String get refreshMetadata => 'Metadaten aktualisieren';
	@override String get emptyTrash => 'Papierkorb leeren';
	@override String emptyingTrash({required Object title}) => 'Papierkorb für „${title}“ wird geleert...';
	@override String trashEmptied({required Object title}) => 'Papierkorb für „${title}“ geleert';
	@override String failedToEmptyTrash({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}';
	@override String analyzing({required Object title}) => 'Analysiere „${title}“...';
	@override String analysisStarted({required Object title}) => 'Analyse gestartet für „${title}“';
	@override String failedToAnalyze({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}';
	@override String get noLibrariesFound => 'Keine Mediatheken gefunden';
	@override String get allLibrariesHidden => 'Alle Mediatheken sind ausgeblendet';
	@override String hiddenLibrariesCount({required Object count}) => 'Ausgeblendete Mediatheken (${count})';
	@override String get thisLibraryIsEmpty => 'Diese Mediathek ist leer';
	@override String get noItemsMatchFilters => 'Keine Elemente entsprechen den aktiven Filtern';
	@override String get resetFilters => 'Filter zurücksetzen';
	@override String get all => 'Alle';
	@override String get clearAll => 'Alle Filter entfernen';
	@override String scanLibraryConfirm({required Object title}) => '„${title}“ wirklich scannen?';
	@override String analyzeLibraryConfirm({required Object title}) => '„${title}“ wirklich analysieren?';
	@override String refreshMetadataConfirm({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?';
	@override String emptyTrashConfirm({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?';
	@override String get manageLibraries => 'Mediatheken verwalten';
	@override String get sort => 'Sortieren';
	@override String get sortBy => 'Sortieren nach';
	@override String get filters => 'Filter';
	@override String get confirmActionMessage => 'Aktion wirklich durchführen?';
	@override String get showLibrary => 'Mediathek anzeigen';
	@override String get hideLibrary => 'Mediathek ausblenden';
	@override String get libraryOptions => 'Mediatheksoptionen';
	@override String get content => 'Mediatheksinhalt';
	@override String get selectLibrary => 'Mediathek auswählen';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Keine Empfehlungen verfügbar';
	@override String get noCollections => 'Keine Sammlungen in dieser Mediathek';
	@override String get noFoldersFound => 'Keine Ordner gefunden';
	@override String get folders => 'Ordner';
	@override late final _Translations$libraries$tabs$de tabs = _Translations$libraries$tabs$de._(_root);
	@override late final _Translations$libraries$groupings$de groupings = _Translations$libraries$groupings$de._(_root);
	@override late final _Translations$libraries$filterCategories$de filterCategories = _Translations$libraries$filterCategories$de._(_root);
	@override late final _Translations$libraries$sortLabels$de sortLabels = _Translations$libraries$sortLabels$de._(_root);
	@override late final _Translations$libraries$advancedFilters$de advancedFilters = _Translations$libraries$advancedFilters$de._(_root);
	@override late final _Translations$libraries$selection$de selection = _Translations$libraries$selection$de._(_root);
}

// Path: about
class _Translations$about$de extends Translations$about$en {
	_Translations$about$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über';
	@override String get openSourceLicenses => 'Open-Source-Lizenzen';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Ein schöner, mit Flutter entwickelter Plex-, Jellyfin- und Emby-Client';
	@override String get viewLicensesDescription => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
	@override String get privacyPolicy => 'Datenschutzerklärung';
}

// Path: serverSelection
class _Translations$serverSelection$de extends Translations$serverSelection$en {
	_Translations$serverSelection$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
	@override String get noValidServers => 'Für dieses Konto wurden keine nutzbaren Server gefunden';
}

// Path: hubDetail
class _Translations$hubDetail$de extends Translations$hubDetail$en {
	_Translations$hubDetail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Erscheinungsjahr';
	@override String get dateAdded => 'Hinzugefügt am';
	@override String get rating => 'Bewertung';
	@override String get noItemsFound => 'Keine Elemente gefunden';
}

// Path: logs
class _Translations$logs$de extends Translations$logs$en {
	_Translations$logs$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Protokolle löschen';
	@override String get copyLogs => 'Protokolle kopieren';
	@override String get uploadLogs => 'Protokolle hochladen';
	@override String get saveLogs => 'Speichern Sie Logs auf Dateien';
	@override String logsSaved({required Object path}) => 'Logs gespeichert auf ${path}';
	@override String get saveLogsFailed => 'Ich konnte die Log-Datei nicht speichern.';
}

// Path: startup
class _Translations$startup$de extends Translations$startup$en {
	_Translations$startup$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG konnte nicht gestartet werden';
	@override String get failedBody => 'Beim Start ist etwas schiefgelaufen. Die Details unten zeigen, was fehlgeschlagen ist.';
	@override String get failedBodyRepairable => 'Die gespeicherte Einstellungsdatei von PlezyNG ist beschädigt und muss neu aufgebaut werden, bevor PlezyNG starten kann. Erneutes Versuchen hilft nicht – wähle „Speicher reparieren“.';
	@override String get phaseLabel => 'Schritt';
	@override String get showDetails => 'Details anzeigen';
	@override String get hideDetails => 'Details ausblenden';
	@override String get copyDetails => 'Details kopieren';
	@override String get detailsCopied => 'Details in die Zwischenablage kopiert';
	@override String get uploadDetails => 'Details hochladen';
	@override String get repairStorage => 'Speicher reparieren';
	@override String get repairTitle => 'Gespeicherte Daten reparieren?';
	@override String get repairBodyCommon => 'Die Einstellungsdatei von PlezyNG ist beschädigt und kann nicht gelesen werden. Beim Reparieren werden alle Einstellungen auf ihre Standardwerte zurückgesetzt.';
	@override String get repairBodyOneCredential => 'Eine gespeicherte Anmeldung ist beschädigt und kann nicht gelesen werden. Beim Reparieren wird nur diese entfernt; deine übrigen Einstellungen bleiben unangetastet.';
	@override String get repairBodySignInsKept => 'Deine Server und Profile sollten angemeldet bleiben.';
	@override String get repairBodySignInsLost => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, kann aus dieser Datei nicht wiederhergestellt werden. Du musst dich daher bei jedem Server und Profil erneut anmelden. Auf deinem Medienserver ändert sich nichts.';
	@override String get repairBodySessionsUncertain => 'Tracker (MAL, AniList, Simkl, Trakt) und Seerr werden separat gespeichert und können erhalten bleiben oder auch nicht. PlezyNG teilt dir genau mit, was erhalten blieb.';
	@override String get repairConfirm => 'Reparieren';
	@override String get repairSucceeded => 'Speicher repariert';
	@override String get repairNeedsRestart => 'Speicher repariert – Neustart erforderlich';
	@override String get restartRequiredBody => 'Deine Daten wurden repariert, aber PlezyNG muss neu starten, bevor es sie verwenden kann. Schließe PlezyNG und öffne es erneut.';
	@override String get quitPlezy => 'PlezyNG beenden';
	@override String get repairFailed => 'Reparatur fehlgeschlagen';
	@override String get repairKeptSignIns => 'Deine Server und Profile sind weiterhin angemeldet.';
	@override String get repairLostSignIns => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, konnte nicht wiederhergestellt werden. Du musst dich bei jedem Server und Profil erneut anmelden.';
	@override String get repairLostSessions => 'Mindestens eine Tracker- oder Seerr-Verbindung ging verloren und muss neu verbunden werden.';
	@override String get backupTitle => 'Eine Kopie der beschädigten Datei wurde aufbewahrt';
	@override String get backupWarning => 'Sie enthält deine Anmeldedaten. Lade sie nicht hoch und teile sie nicht.';
	@override String get deleteBackup => 'Kopie löschen';
	@override String get backupDeleted => 'Kopie gelöscht.';
	@override String get previousFailureTitle => 'PlezyNG konnte beim letzten Mal nicht starten';
}

// Path: licenses
class _Translations$licenses$de extends Translations$licenses$en {
	_Translations$licenses$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Verwandte Pakete';
	@override String get license => 'Lizenz';
	@override String licenseNumber({required Object number}) => 'Lizenz ${number}';
	@override String licensesCount({required Object count}) => '${count} Lizenzen';
}

// Path: navigation
class _Translations$navigation$de extends Translations$navigation$en {
	_Translations$navigation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Mediatheken';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'Live-TV';
	@override String get explore => 'Erkunden';
}

// Path: explore
class _Translations$explore$de extends Translations$explore$en {
	_Translations$explore$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$mdblistShelves$de mdblistShelves = _Translations$explore$mdblistShelves$de._(_root);
	@override String get title => 'Erkunden';
	@override String get selectSource => 'Quelle auswählen';
	@override late final _Translations$explore$rows$de rows = _Translations$explore$rows$de._(_root);
	@override late final _Translations$explore$status$de status = _Translations$explore$status$de._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folge',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folgen',
	);
	@override String get cast => 'Besetzung';
	@override String get characters => 'Charaktere';
	@override String get addToWatchlist => 'Zur Merkliste hinzufügen';
	@override String get removeFromWatchlist => 'Von Merkliste entfernen';
	@override String get addedToWatchlist => 'Zur Watchlist hinzugefügt';
	@override String get removedFromWatchlist => 'Von der Watchlist entfernt';
	@override String get watchlistUpdateFailed => 'Merkliste konnte nicht aktualisiert werden';
	@override String get watchlistNoMatch => 'Dieser Eintrag konnte keiner Watchlist zugeordnet werden';
	@override String get notInLibrary => 'Nicht in deiner Mediathek';
	@override String get inTheseLibraries => 'In diesen Mediatheken';
	@override String get checkingLibrary => 'Deine Mediathek wird überprüft …';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Server konnte nicht geprüft werden',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Server konnten nicht geprüft werden',
	);
	@override String get emptyTitle => 'Hier ist noch nichts';
	@override String emptyMessage({required Object source}) => 'Zeilen aus ${source} erscheinen hier, sobald sie Inhalte enthalten.';
	@override String searchHint({required Object source}) => '${source} durchsuchen';
	@override String searchEmpty({required Object query}) => 'Keine Ergebnisse für „${query}“';
	@override String searchPrompt({required Object source}) => 'Suche nach Filmen und Serien auf ${source}.';
	@override String get searchFailed => 'Suche fehlgeschlagen. Prüfe deine Verbindung und versuche es erneut.';
	@override late final _Translations$explore$badge$de badge = _Translations$explore$badge$de._(_root);
	@override late final _Translations$explore$stats$de stats = _Translations$explore$stats$de._(_root);
	@override late final _Translations$explore$season$de season = _Translations$explore$season$de._(_root);
	@override late final _Translations$explore$format$de format = _Translations$explore$format$de._(_root);
	@override late final _Translations$explore$sourceMaterial$de sourceMaterial = _Translations$explore$sourceMaterial$de._(_root);
	@override late final _Translations$explore$creditRole$de creditRole = _Translations$explore$creditRole$de._(_root);
	@override late final _Translations$explore$relation$de relation = _Translations$explore$relation$de._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Läuft ${day} um ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Läuft ${day} um ${time} ${timezone}';
	@override late final _Translations$explore$detail$de detail = _Translations$explore$detail$de._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ergebnis',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ergebnisse',
	);
}

// Path: liveTv
class _Translations$liveTv$de extends Translations$liveTv$en {
	_Translations$liveTv$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-TV';
	@override String get guide => 'TV-Programm';
	@override String get noChannels => 'Keine Kanäle verfügbar';
	@override String get noDvr => 'Auf keinem Server ist ein DVR konfiguriert';
	@override String get serverUnavailable => 'Der Live-TV-Server ist nicht verfügbar.';
	@override String get serverNotConnected => 'Der Live-TV-Server ist nicht verbunden.';
	@override String get noPrograms => 'Keine Programmdaten verfügbar';
	@override String get liveStreamFailed => 'Livestream fehlgeschlagen';
	@override String get unknownProgram => 'Unbekannte Sendung';
	@override String get timelineLiveProgram => 'Live-Programm (Playback kann außerhalb dieses Programms sein)';
	@override String get timelineBuffer => 'Buffer Timeline';
	@override String get timelineUnavailable => 'Timeline nicht verfügbar';
	@override String get timelineEstimated => 'Bewertung des Playback';
	@override String get timelinePending => 'Nachsuchen';
	@override String get timelineStale => 'Der Zeitplan kann verlängert werden';
	@override String get unknownHub => 'Unbekannt';
	@override String get unknownError => 'Unbekannter Fehler';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Unbekannter Kanal';
	@override String get live => 'LIVE';
	@override String get premiereBadge => 'Neues';
	@override String get reloadGuide => 'TV-Programm neu laden';
	@override String get searchGuide => 'TV-Programm durchsuchen';
	@override String get searchHint => 'Kanäle & Sendungen suchen';
	@override String searchNoResults({required Object query}) => 'Keine Treffer für „${query}“';
	@override String get channelsSection => 'Kanäle';
	@override String get programsSection => 'Sendungen';
	@override String get now => 'Jetzt';
	@override String get today => 'Heute';
	@override String get tomorrow => 'Morgen';
	@override String get midnight => 'Mitternacht';
	@override String get overnight => 'Nacht';
	@override String get morning => 'Morgen';
	@override String get daytime => 'Tagsüber';
	@override String get evening => 'Abend';
	@override String get lateNight => 'Spätnacht';
	@override String get whatsOn => 'Jetzt im TV';
	@override String get watchChannel => 'Kanal ansehen';
	@override String get favorites => 'Favoriten';
	@override String get reorderFavorites => 'Favoriten sortieren';
	@override String get noFavoriteChannels => 'Keine Lieblingssender';
	@override String get noFavoriteChannelsHint => 'Zeige alle Sender an und halte dann einen Sender gedrückt, um ihn zu deinen Favoriten hinzuzufügen.';
	@override String get showAllChannels => 'Alle Sender anzeigen';
	@override String get favoritesLoadFailed => 'Favoriten konnten nicht geladen werden. Überprüfe deine Verbindung und versuche es erneut.';
	@override String get favoritesUpdateFailed => 'Favoriten konnten nicht aktualisiert werden. Prüfe deine Verbindung und versuche es erneut.';
	@override String get joinSession => 'Aktueller Sitzung beitreten';
	@override String watchFromStart({required Object minutes}) => 'Von Anfang an ansehen (vor ${minutes} Min.)';
	@override String get watchLive => 'Live ansehen';
	@override String get goToLive => 'Zum Live-Bild';
	@override String get record => 'Aufnehmen';
	@override String get recordEpisode => 'Episode aufnehmen';
	@override String get recordSeries => 'Serie aufnehmen';
	@override String get recordOptions => 'Aufnahmeoptionen';
	@override String get saveTo => 'Speichern in';
	@override String get recordings => 'Aufnahmen';
	@override String get scheduledRecordings => 'Geplant';
	@override String get recordingRules => 'Aufnahmeregeln';
	@override String get noScheduledRecordings => 'Keine geplanten Aufnahmen';
	@override String get manageRecording => 'Aufnahme verwalten';
	@override String get cancelRecording => 'Aufnahme abbrechen';
	@override String get cancelRecordingTitle => 'Diese Aufnahme abbrechen?';
	@override String cancelRecordingMessage({required Object title}) => '${title} wird nicht mehr aufgenommen.';
	@override String get deleteRule => 'Regel löschen';
	@override String get deleteRuleTitle => 'Aufnahmeregel löschen?';
	@override String deleteRuleMessage({required Object title}) => 'Zukünftige Episoden von ${title} werden nicht aufgenommen.';
	@override String get recordingScheduled => 'Aufnahme geplant';
	@override String get alreadyScheduled => 'Dieses Programm ist bereits geplant';
	@override String get dvrAdminRequired => 'DVR-Einstellungen erfordern ein Administratorkonto';
	@override String get recordingFailed => 'Aufnahme konnte nicht geplant werden';
	@override String get recordingTargetMissing => 'Aufnahmebibliothek konnte nicht ermittelt werden';
	@override String get recordNotAvailable => 'Aufnahme für dieses Programm nicht verfügbar';
	@override String get recordingCancelled => 'Aufnahme abgebrochen';
	@override String get recordingRuleDeleted => 'Aufnahmeregel gelöscht';
	@override String get processRecordingRules => 'Regeln neu bewerten';
	@override String get recordingInProgress => 'Wird jetzt aufgenommen';
	@override String recordingsCount({required Object count}) => '${count} geplant';
	@override String get editRule => 'Regel bearbeiten';
	@override String get editRuleAction => 'Bearbeiten';
	@override String get recordingRuleUpdated => 'Aufnahmeregel aktualisiert';
	@override String get guideReloadRequested => 'Aktualisierung des TV-Programms angefordert';
	@override String get guideReloadFailed => 'TV-Programm konnte nicht aktualisiert werden';
	@override String get rulesProcessRequested => 'Regelauswertung angefordert';
	@override String get rulesProcessFailed => 'Aufnahmeregeln konnten nicht neu ausgewertet werden';
	@override String get recordShow => 'Sendung aufnehmen';
	@override late final _Translations$liveTv$recordSettings$de recordSettings = _Translations$liveTv$recordSettings$de._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Beginnt in ${minutes} Min.';
	@override String dayAtTime({required Object day, required Object time}) => '${day} um ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} hat ungültige Live-TV-Wiedergabedaten zurückgegeben';
	@override String get failedToStartChannel => 'Der Live-Sender konnte nicht gestartet werden';
	@override String get failedToBuildStreamUrl => 'Die Stream-URL konnte nicht erstellt werden';
	@override String playbackStartFailed({required Object reason}) => 'Sender konnte nicht gestartet werden: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Sender konnte nicht gewechselt werden: ${reason}';
}

// Path: collections
class _Translations$collections$de extends Translations$collections$en {
	_Translations$collections$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sammlungen';
	@override String get collection => 'Sammlung';
	@override String get empty => 'Sammlung ist leer';
	@override String get deleteCollection => 'Sammlung löschen';
	@override String deleteConfirm({required Object title}) => '„${title}“ löschen? Dies kann nicht rückgängig gemacht werden.';
	@override String get deleted => 'Sammlung gelöscht';
	@override String get deleteFailed => 'Sammlung konnte nicht gelöscht werden';
	@override String deleteFailedWithError({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
	@override String get selectCollection => 'Sammlung auswählen';
	@override String get collectionName => 'Sammlungsname';
	@override String get enterCollectionName => 'Sammlungsnamen eingeben';
	@override String get addedToCollection => 'Zur Sammlung hinzugefügt';
	@override String get errorAddingToCollection => 'Fehler beim Hinzufügen zur Sammlung';
	@override String get created => 'Sammlung erstellt';
	@override String get removeFromCollection => 'Aus Sammlung entfernen';
	@override String removeFromCollectionConfirm({required Object title}) => '„${title}“ aus dieser Sammlung entfernen?';
	@override String get removedFromCollection => 'Aus Sammlung entfernt';
	@override String get removeFromCollectionFailed => 'Entfernen aus Sammlung fehlgeschlagen';
	@override String removeFromCollectionError({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
	@override String get searchCollections => 'Sammlungen durchsuchen...';
}

// Path: playlists
class _Translations$playlists$de extends Translations$playlists$en {
	_Translations$playlists$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wiedergabelisten';
	@override String get playlist => 'Wiedergabeliste';
	@override String get noPlaylists => 'Keine Wiedergabelisten gefunden';
	@override String get create => 'Wiedergabeliste erstellen';
	@override String get playlistName => 'Name der Wiedergabeliste';
	@override String get enterPlaylistName => 'Name der Wiedergabeliste eingeben';
	@override String get delete => 'Wiedergabeliste löschen';
	@override String get removeItem => 'Aus Wiedergabeliste entfernen';
	@override String get smartPlaylist => 'Intelligente Wiedergabeliste';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Element',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Elemente',
	);
	@override String get emptyPlaylist => 'Diese Wiedergabeliste ist leer';
	@override String get deleteConfirm => 'Wiedergabeliste löschen?';
	@override String deleteMessage({required Object name}) => '„${name}“ wirklich löschen?';
	@override String get created => 'Wiedergabeliste erstellt';
	@override String get deleted => 'Wiedergabeliste gelöscht';
	@override String get itemAdded => 'Zur Wiedergabeliste hinzugefügt';
	@override String get itemRemoved => 'Aus Wiedergabeliste entfernt';
	@override String get selectPlaylist => 'Wiedergabeliste auswählen';
	@override String get searchPlaylists => 'Wiedergabelisten durchsuchen...';
	@override String get errorCreating => 'Wiedergabeliste konnte nicht erstellt werden';
	@override String get errorDeleting => 'Wiedergabeliste konnte nicht gelöscht werden';
	@override String get errorLoading => 'Wiedergabelisten konnten nicht geladen werden';
	@override String get errorAdding => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
	@override String get errorReordering => 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
	@override String get errorRemoving => 'Konnte nicht aus der Wiedergabeliste entfernt werden';
}

// Path: music
class _Translations$music$de extends Translations$music$en {
	_Translations$music$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Zum Album';
	@override String get goToArtist => 'Zum Interpreten';
	@override String get instantMix => 'Instant-Mix';
	@override String get playNext => 'Als Nächstes abspielen';
	@override String get addToQueue => 'Zur Warteschlange hinzufügen';
	@override String discNumber({required Object n}) => 'Disc ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel',
	);
	@override String get nowPlaying => 'Wird wiedergegeben';
	@override String playingFrom({required Object title}) => 'Wiedergabe von ${title}';
	@override String get queue => 'Warteschlange';
	@override String get clearQueue => 'Warteschlange leeren';
	@override String get lyrics => 'Songtext';
	@override String get visualizer => 'Visualisieren';
	@override String get visualizerProfileLoading => 'Lesen Sie Track Analysen ...';
	@override String get visualizerAmbientMotion => 'Umweltbewegung';
	@override String get visualizerPlexLoudness => 'Plex Lautstärke';
	@override String get visualizerPreviousPreset => 'Vorheriger ArtikelVisuelle Art';
	@override String get visualizerNextPreset => 'Nächster Beitrag Visual Style';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blum';
	@override String get visualizerPresetOrbitals => 'Orbitale';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Tunnel';
	@override String get visualizerPresetTrackMap => 'Track Karte';
	@override String get noLyrics => 'Kein Songtext verfügbar';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get sleepTimerEndOfTrack => 'Ende des Titels';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Minuten',
	);
	@override String get stopPlayback => 'Wiedergabe stoppen';
	@override String get previousTrack => 'Vorheriger Titel';
	@override String get nextTrack => 'Nächster Titel';
	@override String get repeat => 'Wiederholen';
	@override String get repeatAll => 'Alle wiederholen';
	@override String get repeatOne => 'Titel wiederholen';
	@override String get instantMixNoServer => 'Für einen Instant Mix ist kein Server verfügbar';
	@override String get instantMixFailed => 'Instant-Mix konnte nicht geladen werden';
	@override String get instantMixEmpty => 'Der Instant-Mix enthält keine Titel';
	@override String noAudioUrl({required Object track}) => 'Für ${track} ist keine Audio-URL verfügbar';
	@override late final _Translations$music$discography$de discography = _Translations$music$discography$de._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$de extends Translations$watchTogether$en {
	_Translations$watchTogether$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gemeinsam Schauen';
	@override String get description => 'Inhalte synchron mit Freunden und Familie schauen';
	@override String get createRoom => 'Raum erstellen';
	@override String get creatingRoom => 'Raum wird erstellt …';
	@override String get joinRoom => 'Raum beitreten';
	@override String get joiningRoom => 'Beitritt zum Raum …';
	@override String get connecting => 'Verbindung wird hergestellt …';
	@override String get relayPublic => 'Räume nutzen die öffentlichen Relays von Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Räume nutzen dein Relay unter ${url}.';
	@override String get recentRooms => 'Zuletzt verwendete Räume';
	@override String get roomActions => 'Raumaktionen';
	@override String get renameRoom => 'Raum umbenennen';
	@override String get removeRoom => 'Entfernen';
	@override String get enterRoomCode => 'Gib den 6-stelligen Code vom Host ein.';
	@override String get roomCode => 'Raumcode';
	@override String get paste => 'Einfügen';
	@override String get noCodeInClipboard => 'Die Zwischenablage enthält keinen Raumcode';
	@override String get copyCode => 'Code kopieren';
	@override String get codeCopied => 'Raumcode kopiert';
	@override String get shareInvite => 'Einladung teilen';
	@override String get inviteCopied => 'Einladung kopiert. Füge sie in eine Nachricht ein.';
	@override String inviteMessage({required Object code}) => 'Komm in meinen Raum für Gemeinsam Schauen in PlezyNG: Öffne „Gemeinsam Schauen“, wähle „Raum beitreten“ und gib ${code} ein.';
	@override String get openSessionControls => 'Sitzungssteuerung für Gemeinsam Schauen öffnen';
	@override String get reconnecting => 'Verbindung wird wiederhergestellt …';
	@override String get reconnectingDescription => 'Die Verbindung wurde unterbrochen. Du trittst dem Raum automatisch wieder bei.';
	@override String get connected => 'Verbunden';
	@override String get disconnected => 'Getrennt';
	@override String get youAreHost => 'Du bist der Host';
	@override String hostedBy({required Object name}) => 'Gehostet von ${name}';
	@override String get hostControlsPlayback => 'Host steuert die Wiedergabe';
	@override String get anyoneCanControl => 'Alle können die Wiedergabe steuern';
	@override String get roomLocked => 'Raum gesperrt';
	@override String get nowPlaying => 'Wird wiedergegeben';
	@override String get nothingPlaying => 'Es läuft nichts';
	@override String get nothingPlayingHost => 'Spiele etwas aus einer beliebigen Mediathek ab, um es mit dem Raum zu teilen.';
	@override String get nothingPlayingGuest => 'Wenn der Host etwas abspielt, wird es hier geöffnet.';
	@override String get notShareable => 'Für dieses Video gibt es keinen Katalogtreffer, daher können es nur Personen mit Zugriff auf denselben Server abspielen.';
	@override String get searching => 'Dieses Video wird in deinen Mediatheken gesucht …';
	@override String get yourCopy => 'Deine Kopie';
	@override String get sharingYourCopy => 'Du teilst deine Kopie';
	@override String playingOtherLength({required Object difference}) => 'Deine Kopie wird abgespielt (${difference})';
	@override String get mismatchTitle => 'Deine Kopie hat eine andere Länge';
	@override String mismatchDescription({required Object difference}) => 'Deine am besten passende Kopie ist ${difference} als das Video im Raum. Möglicherweise ist es eine andere Schnittfassung oder Version.';
	@override String get playAnyway => 'Trotzdem abspielen';
	@override String get chooseAnotherCopy => 'Andere Kopie wählen';
	@override String get dontPlay => 'Nicht abspielen';
	@override String get unavailableTitle => 'Du hast dieses Video nicht';
	@override String get unavailableDescription => 'PlezyNG hat es nicht in deinen Mediatheken gefunden. Wähle selbst eine Kopie oder suche erneut.';
	@override String get chooseCopy => 'Kopie wählen';
	@override String get searchAgain => 'Erneut suchen';
	@override String get noCandidates => 'Keine Kopien in deinen Mediatheken gefunden.';
	@override String get choiceFailed => 'Diese Kopie konnte nicht für den Raum abgespielt werden';
	@override String lengthLonger({required Object duration}) => '${duration} länger';
	@override String lengthShorter({required Object duration}) => '${duration} kürzer';
	@override String get lengthSame => 'Gleiche Länge';
	@override String get lengthUnknown => 'Länge unbekannt';
	@override String get joinCurrentPlayback => 'Aktueller Wiedergabe beitreten';
	@override String get joinCurrentPlaybackDescription => 'Zu dem Inhalt wechseln, den der Host gerade ansieht';
	@override String get stopMedia => 'Video für alle stoppen';
	@override String get syncOffset => 'Zeitversatz';
	@override String get syncOffsetDescription => 'Verschiebe dein Video, wenn es dem Raum voraus ist oder hinterherhinkt.';
	@override String offsetHint({required Object difference}) => 'Deine Kopie ist ${difference} als das Video im Raum.';
	@override String applyDifference({required Object offset}) => '${offset} übernehmen';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Teilnehmer';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Teilnehmer',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Teilnehmer',
	);
	@override String get hostBadge => 'HOST';
	@override String nameYou({required Object name}) => '${name} (du)';
	@override String get playerIdle => 'Inaktiv';
	@override String get playerLoading => 'Lädt';
	@override String get playerReady => 'Bereit';
	@override String get playerBuffering => 'Puffert';
	@override String get matchSearching => 'Sucht';
	@override String get matchMatched => 'Hat das Video';
	@override String get matchMismatched => 'Andere Länge';
	@override String get matchUnavailable => 'Hat das Video nicht';
	@override String participantOffset({required Object offset}) => 'Versatz ${offset}';
	@override String get makeHost => 'Zum Host machen';
	@override String get makeHostQuestion => 'Host übertragen?';
	@override String makeHostConfirm({required Object name}) => '${name} steuert dann die Wiedergabe und die Sitzung für alle.';
	@override String get transfer => 'Übertragen';
	@override String get removeParticipant => 'Aus dem Raum entfernen';
	@override String removeParticipantQuestion({required Object name}) => '${name} entfernen?';
	@override String removeParticipantConfirm({required Object name}) => '${name} wird aus dem Raum entfernt und kann mit dem Code erneut beitreten, sofern du den Raum nicht sperrst.';
	@override String get remove => 'Entfernen';
	@override String get roomSettings => 'Raumeinstellungen';
	@override String get letEveryoneControl => 'Alle dürfen die Wiedergabe steuern';
	@override String get lockRoom => 'Raum sperren';
	@override String get lockRoomDescription => 'Niemand Neues kann beitreten';
	@override String get leaveRoom => 'Raum verlassen';
	@override String get leaveRoomQuestion => 'Raum verlassen?';
	@override String get leaveRoomConfirm => 'Du kannst mit dem Raumcode erneut beitreten.';
	@override String get leave => 'Verlassen';
	@override String get endRoom => 'Raum beenden';
	@override String get endRoomQuestion => 'Raum beenden?';
	@override String get endRoomConfirm => 'Damit wird der Raum für alle beendet.';
	@override String get end => 'Beenden';
	@override String get playBlockedTitle => 'Wiedergabe wurde nicht gestartet';
	@override String get playBlockedDescription => 'Drücke auf Abspielen, um gemeinsam mit dem Raum zu schauen.';
	@override late final _Translations$watchTogether$notices$de notices = _Translations$watchTogether$notices$de._(_root);
	@override late final _Translations$watchTogether$ended$de ended = _Translations$watchTogether$ended$de._(_root);
	@override late final _Translations$watchTogether$errors$de errors = _Translations$watchTogether$errors$de._(_root);
	@override String untitledEpisode({required Object number}) => 'Folge ${number}';
}

// Path: downloads
class _Translations$downloads$de extends Translations$downloads$en {
	_Translations$downloads$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Verwalten';
	@override String get tvShows => 'Serien';
	@override String get movies => 'Filme';
	@override String get music => 'Musik';
	@override String tracksQueued({required Object count}) => '${count} Titel zum Download in Warteschlange';
	@override String get noDownloads => 'Noch keine Downloads';
	@override String get noDownloadsDescription => 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt';
	@override String get downloadNow => 'Herunterladen';
	@override String get deleteDownload => 'Download löschen';
	@override String get retryDownload => 'Download wiederholen';
	@override String get downloadQueued => 'Download in Warteschlange';
	@override String get downloadResumed => 'Download fortgesetzt';
	@override String get serverErrorBitrate => 'Serverfehler: Datei überschreitet möglicherweise das Remote-Bitrate-Limit';
	@override String get storageFull => 'Die Downloads wurden angehalten, um den freien Speicherplatz zu schützen. Gib Speicherplatz frei oder wähle einen anderen Download-Speicherort und versuche es erneut.';
	@override String get storageUnavailable => 'Downloads wurden angehalten, weil der verfügbare Speicherplatz nicht geprüft werden konnte. Prüfe den Download-Speicherort und versuche es erneut.';
	@override String episodesQueued({required Object count}) => '${count} Episoden zum Download hinzugefügt';
	@override String get downloadDeleted => 'Download gelöscht';
	@override String deleteConfirm({required Object title}) => '"${title}" von diesem Gerät löschen?';
	@override String get deleteCollectionDownloads => 'Downloads löschen';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Alle Downloads in „${title}“ von diesem Gerät löschen?';
	@override String get collectionDownloadsDeleted => 'Downloads gelöscht';
	@override String get cancelledDownloadTitle => 'Abgebrochener Download';
	@override String get cancelledDownloadMessage => 'Dieser Download wurde abgebrochen. Was möchtest du tun?';
	@override String get allEpisodesAlreadyDownloaded => 'Alle Episoden sind bereits heruntergeladen';
	@override String get resumeDownload => 'Download fortsetzen';
	@override String get cancelledDownload => 'Abgebrochener Download';
	@override String syncingFile({required Object file, required Object status}) => '${file} (${status} wird synchronisiert)';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} heruntergeladen — zum Abschließen klicken';
	@override String get partialDownloadClickToComplete => 'Teilweise heruntergeladen — zum Abschließen klicken';
	@override String get deleting => 'Wird gelöscht …';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => '${title} wird gelöscht … (${current} von ${total})';
	@override String get queuedTooltip => 'In Warteschlange';
	@override String queuedFilesTooltip({required Object files}) => 'In Warteschlange: ${files}';
	@override String get downloadingTooltip => 'Wird heruntergeladen …';
	@override String downloadingFilesTooltip({required Object files}) => '${files} werden heruntergeladen';
	@override String get noDownloadsTree => 'Keine Downloads';
	@override String get pauseAll => 'Alle pausieren';
	@override String get resumeAll => 'Alle fortsetzen';
	@override String get retryAll => 'Alle wiederholen';
	@override String get retryFailed => 'Fehlgeschlagene Downloads wiederholen';
	@override String get deleteAll => 'Alle löschen';
	@override String get selectVersion => 'Version auswählen';
	@override String get allEpisodes => 'Alle Episoden';
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override String nextNUnwatched({required Object count}) => 'Nächste ${count} ungesehene';
	@override String get customAmount => 'Eigene Anzahl...';
	@override String get customAmountAny => 'Ein bestimmtes Betrag (ein einzelnes ...';
	@override String get randomEpisodes => 'Random-Episode';
	@override String get includeSpecials => 'Sonderfolgen einschließen';
	@override String get howManyEpisodes => 'Wie viele Episoden?';
	@override String get invalidEpisodeCount => 'Gib eine gültige Episodenanzahl ein.';
	@override String get keepSynced => 'Synchronisiert halten';
	@override String get downloadOnce => 'Einmal herunterladen';
	@override String keepNUnwatched({required Object count}) => '${count} ungesehene behalten';
	@override String get editSyncRule => 'Synchronisierungsregel bearbeiten';
	@override String get removeSyncRule => 'Synchronisierungsregel entfernen';
	@override String removeSyncRuleConfirm({required Object title}) => 'Synchronisierung von „${title}“ beenden? Heruntergeladene Episoden werden behalten.';
	@override String removeListSyncRuleConfirm({required Object title}) => '„${title}“ nicht mehr synchronisieren?';
	@override String get deleteSyncRuleDownloads => 'Zugehörige Downloads ebenfalls löschen';
	@override String get deleteSyncRuleDownloadsDescription => 'Downloads, die von einer anderen Synchronisierungsregel oder einem Profil verwendet werden, bleiben erhalten.';
	@override String syncRuleCreated({required Object count}) => 'Synchronisierungsregel erstellt – ${count} ungesehene Episoden werden behalten';
	@override String get syncRuleUpdated => 'Synchronisierungsregel aktualisiert';
	@override String get syncRuleRemoved => 'Synchronisierungsregel entfernt';
	@override String get syncRuleAndDownloadsRemoved => 'Synchronisierungsregel und zugehörige Downloads entfernt';
	@override String get syncRuleCleanupBusy => 'Synchronisierungsregeln werden gerade aktualisiert. Versuche es gleich noch einmal.';
	@override String get syncRuleCleanupUnavailable => 'Zugehörige Downloads konnten nicht sicher ermittelt werden. Verbinde den Server erneut und versuche es noch einmal, oder entferne die Regel, ohne die Downloads zu löschen.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} neue Episoden für ${title} synchronisiert';
	@override String get syncNow => 'Synchronisierung jetzt';
	@override String get downloadsUpToDate => 'Die Downloads sind bis zum aktuellen Zeitpunkt';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync vollständig · ${queued} quued, ${removed} entfernt';
	@override String get activeSyncRules => 'Synchronisierungsregeln';
	@override String get reviewOrphanFiles => 'Verwaiste Downloads prüfen';
	@override String get orphanReviewTitle => 'Verwaiste Downloads prüfen';
	@override String get orphanReviewDescription => 'Diese markierten Dateien liegen in PlezyNGs standardmäßigen, von der App verwalteten Downloadordnern. Es gibt keinen passenden Download-Eintrag und keinen aktiven Auftrag. Prüfen Sie die Liste, bevor Sie die Dateien löschen.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} Dateien · ${size}';
	@override String orphanDeleteFiles({required Object count}) => '${count} Dateien löschen';
	@override String get orphanCleanupNone => 'Keine verwaisten Download-Dateien gefunden';
	@override String get orphanCleanupFailed => 'PlezyNG konnte den verwalteten Downloadordner nicht sicher scannen. Es wurden keine Dateien gelöscht.';
	@override String get orphanCleanupChanged => 'Die Downloadliste hat sich während der Prüfung geändert. Prüfen Sie die Dateien erneut, bevor Sie aufräumen.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => '${count} verwaiste Download-Dateien gelöscht · ${size} freigegeben';
	@override String get noSyncRules => 'Keine Synchronisierungsregeln';
	@override String get manageSyncRule => 'Synchronisierung verwalten';
	@override String get editEpisodeCount => 'Episodenanzahl';
	@override String get editSyncFilter => 'Synchronisierungsfilter';
	@override String get syncAllItems => 'Alle Elemente synchronisieren';
	@override String get syncUnwatchedItems => 'Ungesehene Elemente synchronisieren';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Verfügbar';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Anmeldung erforderlich';
	@override String get syncRuleAccessDenied => 'Zugriff verweigert';
	@override String get syncRuleNotAvailableForProfile => 'Für das aktuelle Profil nicht verfügbar';
	@override String get syncRuleUnknownServer => 'Unbekannter Server';
	@override String get syncRuleListCreated => 'Synchronisierungsregel erstellt';
	@override late final _Translations$downloads$backgroundWarning$de backgroundWarning = _Translations$downloads$backgroundWarning$de._(_root);
	@override String get options => 'Download-Optionen';
	@override late final _Translations$downloads$groupings$de groupings = _Translations$downloads$groupings$de._(_root);
	@override String get unknownLibrary => 'Unbekannte Mediathek';
	@override String get unknownShow => 'Unbekannte Serie';
	@override String get unknownSeason => 'Unbekannte Staffel';
	@override String get unknownAlbum => 'Unbekanntes Album';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} abgeschlossen';
	@override String storageUsed({required Object size}) => 'Speicher verwendet: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Download',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Downloads',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ausstellung',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ausstellungen',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Film',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Filme',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Album',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Alben',
	);
	@override String get errorFileNotFound => 'Datei nicht gefunden (404)';
	@override String get errorDownloadNotAllowed => 'Download vom Server nicht erlaubt (403)';
	@override String get errorDownloadFailed => 'Download fehlgeschlagen';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Download fehlgeschlagen: ${reason}';
	@override String get convertingOnServer => 'Umwandeln auf den Server...';
	@override String convertingOnServerPercent({required Object percent}) => 'Konvertierung auf Server · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Download fehlgeschlagen (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Nachbearbeitung fehlgeschlagen: ${reason}';
	@override String get reasonFileNotSaved => 'die Datei konnte auf diesem Gerät nicht gespeichert werden';
	@override String get reasonCannotResume => 'der unvollständige Download konnte nicht fortgesetzt werden';
	@override String get reasonDeviceStorageFull => 'auf diesem Gerät ist kein Speicherplatz mehr frei';
	@override String get notificationDownloading => 'Wird heruntergeladen …';
	@override String get notificationComplete => 'Download abgeschlossen';
	@override String get notificationPaused => 'Download pausiert';
}

// Path: shaders
class _Translations$shaders$de extends Translations$shaders$en {
	_Translations$shaders$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shader';
	@override String get noShaderDescription => 'Keine Videoverbesserung';
	@override String get nvscalerDescription => 'NVIDIA-Bildskalierung für schärferes Video';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Rauschreduzierung';
	@override String get artcnnVariantDenoiseSharpen => 'Rauschreduzierung + Schärfen';
	@override String get qualityFast => 'Schnell';
	@override String get qualityHQ => 'Hohe Qualität';
	@override String get mode => 'Modus';
	@override String get importShader => 'Shader importieren';
	@override String get customShaderDescription => 'Benutzerdefinierter GLSL-Shader';
	@override String get shaderImported => 'Shader importiert';
	@override String get shaderImportFailed => 'Shader konnte nicht importiert werden';
	@override String get deleteShader => 'Shader löschen';
	@override String deleteShaderConfirm({required Object name}) => '"${name}" löschen?';
}

// Path: companionRemote
class _Translations$companionRemote$de extends Translations$companionRemote$en {
	_Translations$companionRemote$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion-Fernbedienung';
	@override String connectedTo({required Object name}) => 'Verbunden mit ${name}';
	@override String get unknownDevice => 'Unbekanntes Gerät';
	@override late final _Translations$companionRemote$session$de session = _Translations$companionRemote$session$de._(_root);
	@override late final _Translations$companionRemote$pairing$de pairing = _Translations$companionRemote$pairing$de._(_root);
	@override late final _Translations$companionRemote$remote$de remote = _Translations$companionRemote$remote$de._(_root);
	@override late final _Translations$companionRemote$errors$de errors = _Translations$companionRemote$errors$de._(_root);
	@override String get closedBeforeAuth => 'Die Verbindung wurde vor der Authentifizierung geschlossen';
}

// Path: videoSettings
class _Translations$videoSettings$de extends Translations$videoSettings$en {
	_Translations$videoSettings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Wiedergabegeschwindigkeit';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktiv (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get audioSync => 'Audio-Synchronisation';
	@override String get subtitleSync => 'Untertitel-Synchronisation';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR ist hier nicht verfügbar – dieser Desktop-Compositor oder Videoausgang kann es nicht übertragen.';
	@override String get hdrToneMapping => 'HDR-Tone-Mapping';
	@override String get hdrToneMappingCompositor => 'Compositor';
	@override String get hdrToneMappingCompositorDescription => 'Die HDR-Metadaten der Quelle durchreichen und vom Desktop-Compositor anpassen lassen.';
	@override String get hdrToneMappingPlayer => 'Player';
	@override String get hdrToneMappingPlayerDescription => 'Im Player an die maximale Helligkeit des Displays anpassen und das Ergebnis anschließend an den Compositor melden.';
	@override String get hdrToneMappingFailed => 'Das HDR-Tone-Mapping konnte nicht geändert werden – der vorherige Modus ist weiterhin aktiv.';
	@override String get audioOutput => 'Audioausgabe';
	@override String get performanceOverlay => 'Leistungsanzeige';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Räumliches Audio';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioEqualizer => 'Audio-Equalizer';
	@override String get audioEqualizerDescription => '10-Band Equalizer für MPV. Audiofilter verwenden dekodierte Audio und deaktivieren passthrough.';
	@override String get audioEqualizerFlat => 'Neutral';
	@override String get audioEqualizerActive => 'Benutzerdefiniert';
	@override String get audioEqualizerSaveFailed => 'Es könnte keine Audio-Equalizer-Einstellungen speichern.';
	@override String get backgroundVideoAudio => 'Hintergrund Video Audio';
	@override String get backgroundVideoAudioDescription => 'Halten Sie das Video-Audio-Play, wenn Sie den Player verlassen; das Bild wird verborgen, bis Sie zurückkehren. Android verwendet eine Medien-Playback-Nachricht.';
	@override String get audioNormalization => 'Lautstärke normalisieren';
	@override String get audioNormalizationDisablesPassthrough => 'Dekodiert Audio zu PCM; Durchleitung ist aus, solange dies aktiv ist';
	@override String get audioEffectsDescription => 'Effekte verwenden verschlüsselt Audio, so passthrough dreht sich ab. Raumumgebung und Stereo-Erweiterung hängt von der MPV Bau und Track.';
	@override String get audioStereoWidth => 'Stereo Erweiterung';
	@override String get audioSpatializer => 'Raum Umgebung';
	@override String get audioSpatializerDescription => 'Hinzufügen Sie ruhige Raum Reflektionen.';
	@override String get audioPitch => 'Pitch wechseln';
	@override String get audioPitchDescription => 'Veränderung des Plats, ohne die Geschwindigkeit zu ändern. MPV Bau muss einschließen Rubber Band.';
	@override String get audioEffectUnavailable => 'Dieser Effekt ist für diesen Track nicht verfügbar oder MPV aufbauen .';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$de extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get color => 'Farbe';
	@override String get performance => 'Leistung';
	@override String get buffer => 'Puffer';
	@override String get app => 'App';
	@override String get decoder => 'Decoder';
	@override String get rawDecoder => 'Raw-Decoder';
	@override String get tunneling => 'Tunneling';
	@override String get passthrough => 'Durchleitung';
	@override String get aspect => 'Seitenverhältnis';
	@override String get rotation => 'Drehung';
	@override String get dvSource => 'DV-Quelle';
	@override String get dvPath => 'DV-Pfad';
	@override String get dvRouteDecoder => 'Dolby-Vision-Decoder';
	@override String get dvRouteDecoderP81 => 'Dolby-Vision-Decoder (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Basisschicht';
	@override String get dvRouteBaseLayerHdr10 => 'HDR10-Basisschicht';
	@override String get dvRouteBaseLayerHlg => 'HLG-Basisschicht';
	@override String get dvRouteBaseLayerSdr => 'SDR-Basisschicht';
	@override String get dvRouteReshaped => 'RPU-Reshaping (gpu-next)';
	@override String get dvRouteFelGraphActive => 'Experimenteller P7 FEL-Grafik (unqualifiziert)';
	@override String get p7Conversion => 'P7-Konv.';
	@override String get sampleRate => 'Abtastrate';
	@override String get pixelFormat => 'Pixelformat';
	@override String get hwFormat => 'HW-Format';
	@override String get matrix => 'Matrix';
	@override String get primaries => 'Primärfarben';
	@override String get transfer => 'Transfer';
	@override String get renderFps => 'Render-FPS';
	@override String get displayFps => 'Display-FPS';
	@override String get avSync => 'A/V-Sync';
	@override String get dropped => 'Verworfen';
	@override String get dvRpus => 'DV-RPUs';
	@override String get dvRpuAverage => 'DV-RPU Ø';
	@override String get dvSampleAverage => 'DV-Sample Ø';
	@override String get maxLuma => 'Max. Luma';
	@override String get minLuma => 'Min. Luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache genutzt';
	@override String get cacheLimit => 'Cache-Limit';
	@override String get speed => 'Geschwindigkeit';
	@override String get player => 'Player';
	@override String get playMethod => 'Spielen Methode';
	@override String get memory => 'Speicher';
	@override String get uiFps => 'UI-FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'Hardware';
	@override String get tunnelingActive => 'Aktiv';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} fehlgeschlagen)';
}

// Path: externalPlayer
class _Translations$externalPlayer$de extends Translations$externalPlayer$en {
	_Translations$externalPlayer$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Externer Player';
	@override String get useExternalPlayer => 'Externen Player verwenden';
	@override String get useExternalPlayerDescription => 'Videos in einer anderen App öffnen';
	@override String get selectPlayer => 'Player auswählen';
	@override String get customPlayers => 'Benutzerdefinierte Player';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Benutzerdefinierten Player hinzufügen';
	@override String get playerName => 'Playername';
	@override String get playerNameHint => 'Mein Player';
	@override String get playerCommand => 'Befehl';
	@override String get playerPackage => 'Paketname';
	@override String get playerUrlScheme => 'URL-Schema';
	@override String get off => 'Aus';
	@override String get launchFailed => 'Externer Player konnte nicht geöffnet werden';
	@override String appNotInstalled({required Object name}) => '${name} ist nicht installiert';
	@override String get playInExternalPlayer => 'In externem Player abspielen';
	@override String get description => 'Wählen Sie eine andere App, um Videos zu öffnen. Verfügbare Spieler hängen von Ihrem Gerät und installierten Apps ab.';
	@override String get systemDefaultDescription => 'Lassen Sie das Betriebssystem das Video mit seiner Standard-App öffnen.';
	@override String playerOptionDescription({required Object player}) => 'Öffnen Sie Videos mit ${player}.';
	@override String get playerNameDescription => 'Das Etikett, das in der Spielerliste angezeigt wird.';
	@override String get playerPackageDescription => 'Geben Sie den Android-Paketnamen der Player-App ein, wie zum Beispiel com.example.player.';
	@override String get playerCommandDescription => 'Geben Sie die installierte Spielerkommando oder die Ausführbare Path für dieses Gerät ein.';
	@override String get playerUrlSchemeDescription => 'Geben Sie das URL-Schema und die optionale URL-Template ein, die zum Start des Spielers verwendet wird.';
}

// Path: metadataEdit
class _Translations$metadataEdit$de extends Translations$metadataEdit$en {
	_Translations$metadataEdit$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Bearbeiten...';
	@override String get screenTitle => 'Metadaten bearbeiten';
	@override String get basicInfo => 'Grundinformationen';
	@override String get artwork => 'Grafiken';
	@override String get advancedSettings => 'Erweiterte Einstellungen';
	@override String get title => 'Titel';
	@override String get sortTitle => 'Sortiertitel';
	@override String get originalTitle => 'Originaltitel';
	@override String get releaseDate => 'Erscheinungsdatum';
	@override String get contentRating => 'Altersfreigabe';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Zusammenfassung';
	@override String get poster => 'Poster';
	@override String get background => 'Hintergrund';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Quadratisches Bild';
	@override String get selectPoster => 'Poster auswählen';
	@override String get selectBackground => 'Hintergrund auswählen';
	@override String get selectLogo => 'Logo auswählen';
	@override String get selectSquareArt => 'Quadratisches Bild auswählen';
	@override String get fromUrl => 'Über URL';
	@override String get uploadFile => 'Datei hochladen';
	@override String get enterImageUrl => 'Bild-URL eingeben';
	@override String get imageUrl => 'Bild-URL';
	@override String get metadataUpdated => 'Metadaten aktualisiert';
	@override String get metadataUpdateFailed => 'Metadaten konnten nicht aktualisiert werden';
	@override String get artworkUpdated => 'Grafiken aktualisiert';
	@override String get artworkUpdateFailed => 'Grafiken konnten nicht aktualisiert werden';
	@override String get noArtworkAvailable => 'Keine Grafiken verfügbar';
	@override String artworkOption({required Object index}) => 'Grafikoption ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Grafikoption ${index}, ausgewählt';
	@override String get notSet => 'Nicht festgelegt';
	@override String get libraryDefault => 'Mediatheksstandard';
	@override String get accountDefault => 'Kontostandard';
	@override String get seriesDefault => 'Serienstandard';
	@override String get episodeSorting => 'Episodensortierung';
	@override String get oldestFirst => 'Älteste zuerst';
	@override String get newestFirst => 'Neueste zuerst';
	@override String get keep => 'Behalten';
	@override String get allEpisodes => 'Alle Episoden';
	@override String latestEpisodes({required Object count}) => '${count} neueste Episoden';
	@override String get latestEpisode => 'Neueste Episode';
	@override String episodesAddedPastDays({required Object count}) => 'Episoden der letzten ${count} Tage';
	@override String get deleteAfterPlaying => 'Episoden nach Wiedergabe löschen';
	@override String get never => 'Nie';
	@override String get afterADay => 'Nach einem Tag';
	@override String get afterAWeek => 'Nach einer Woche';
	@override String get afterAMonth => 'Nach einem Monat';
	@override String get onNextRefresh => 'Bei nächster Aktualisierung';
	@override String get seasons => 'Staffeln';
	@override String get show => 'Anzeigen';
	@override String get hide => 'Ausblenden';
	@override String get episodeOrdering => 'Episodenreihenfolge';
	@override String get tmdbAiring => 'The Movie Database (Ausstrahlung)';
	@override String get tvdbAiring => 'TheTVDB (Ausstrahlung)';
	@override String get tvdbAbsolute => 'TheTVDB (absolut)';
	@override String get metadataLanguage => 'Metadaten-Sprache';
	@override String get useOriginalTitle => 'Originaltitel verwenden';
	@override String get preferredAudioLanguage => 'Bevorzugte Audiosprache';
	@override String get preferredSubtitleLanguage => 'Bevorzugte Untertitelsprache';
	@override String get subtitleMode => 'Automatische Untertitelauswahl';
	@override String get manuallySelected => 'Manuell ausgewählt';
	@override String get shownWithForeignAudio => 'Bei fremdsprachigem Audio anzeigen';
	@override String get alwaysEnabled => 'Immer aktiviert';
	@override String get tags => 'Tags';
	@override String get addTag => 'Tag hinzufügen';
	@override String get genre => 'Genre';
	@override String get director => 'Regisseur';
	@override String get writer => 'Autor';
	@override String get producer => 'Produzent';
	@override String get country => 'Land';
	@override String get collection => 'Sammlung';
	@override String get label => 'Label';
	@override String get quickTag => 'Schnell-Tag...';
}

// Path: matchScreen
class _Translations$matchScreen$de extends Translations$matchScreen$en {
	_Translations$matchScreen$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get match => 'Zuordnen...';
	@override String get fixMatch => 'Zuordnung korrigieren...';
	@override String get unmatch => 'Zuordnung aufheben';
	@override String get unmatchConfirm => 'Diese Zuordnung löschen? Plex behandelt sie als nicht zugeordnet, bis sie neu zugeordnet wird.';
	@override String get unmatchSuccess => 'Zuordnung aufgehoben';
	@override String get unmatchFailed => 'Zuordnung konnte nicht aufgehoben werden';
	@override String get matchApplied => 'Zuordnung angewendet';
	@override String get matchFailed => 'Zuordnung konnte nicht angewendet werden';
	@override String get titleHint => 'Titel';
	@override String get yearHint => 'Jahr';
	@override String get search => 'Suchen';
	@override String get noMatchesFound => 'Keine Treffer gefunden';
}

// Path: serverTasks
class _Translations$serverTasks$de extends Translations$serverTasks$en {
	_Translations$serverTasks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveraufgaben';
	@override String get failedToLoad => 'Aufgaben konnten nicht geladen werden';
	@override String get noTasks => 'Keine laufenden Aufgaben';
}

// Path: trakt
class _Translations$trakt$de extends Translations$trakt$en {
	_Translations$trakt$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Verbunden';
	@override String connectedAs({required Object username}) => 'Verbunden als @${username}';
	@override String get disconnectConfirm => 'Trakt-Konto trennen?';
	@override String get disconnectConfirmBody => 'PlezyNG sendet keine Ereignisse mehr an Trakt. Du kannst jederzeit erneut verbinden.';
	@override String get scrobble => 'Echtzeit-Scrobbling';
	@override String get scrobbleDescription => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.';
	@override String get watchedSync => 'Gesehen-Status synchronisieren';
	@override String get watchedSyncDescription => 'Wenn du Inhalte in PlezyNG als gesehen markierst, werden sie auch auf Trakt markiert.';
}

// Path: seerr
class _Translations$seerr$de extends Translations$seerr$en {
	_Translations$seerr$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Seerr verbinden';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHelper => 'Die Adresse deiner Seerr-Instanz';
	@override String get checkServer => 'Weiter';
	@override String get signInWithJellyfin => 'Mit Jellyfin anmelden';
	@override String get signInWithEmby => 'Mit Emby anmelden';
	@override String get signInWithLocal => 'Lokales Konto verwenden';
	@override String get email => 'E-Mail';
	@override String get noSignInMethods => 'Diese Seerr-Instanz bietet keine von PlezyNG unterstützte Anmeldemethode.';
	@override String get instance => 'Instanz';
	@override String get disconnectConfirm => 'Seerr trennen?';
	@override String get disconnectConfirmBody => 'PlezyNG vergisst diese Seerr-Instanz. Jederzeit erneut verbinden.';
	@override String get request => 'Anfragen';
	@override String get request4k => 'In 4K anfragen';
	@override String get seasons => 'Staffeln';
	@override String get allSeasons => 'Alle Staffeln';
	@override String get advancedOptions => 'Erweitert';
	@override String get destinationServer => 'Zielserver';
	@override String get qualityProfile => 'Qualitätsprofil';
	@override String get rootFolder => 'Stammordner';
	@override String get languageProfile => 'Sprachprofil';
	@override String get tags => 'Tags';
	@override String get noTags => 'Keine Tags';
	@override String defaultOption({required Object name}) => '${name} (Standard)';
	@override String get animeNote => 'Diese Serie ist ein Anime.';
	@override String get requestSubmitted => 'Anfrage gesendet';
	@override String requestFailed({required Object error}) => 'Anfrage fehlgeschlagen: ${error}';
	@override String get requestsLoadFailed => 'Anfrageoptionen konnten nicht geladen werden';
	@override String get nothingToRequest => 'Alles ist bereits verfügbar oder angefragt.';
	@override String get statusAvailable => 'Verfügbar';
	@override String get statusPartiallyAvailable => 'Teilweise verfügbar';
	@override String get statusRequested => 'Angefragt';
	@override String get statusProcessing => 'Wird verarbeitet';
	@override String get statusBlocklisted => 'Auf der Sperrliste';
	@override String couldNotReach({required Object url, required Object error}) => '${url} nicht erreichbar: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Keine Seerr-Instanz unter ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Ein authentifizierender Reverse-Proxy (SSO oder HTTP-Auth) hat anstelle von Seerr geantwortet. PlezyNG kann sich nicht dadurch anmelden: Lass den Pfad /api/v1 von Seerr den Proxy für diese App umgehen, oder verwende eine Adresse, die Seerr direkt erreicht.';
	@override String get invalidUrl => 'Gib eine Serveradresse ein, z. B. https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Diese Seerr-Instanz unterstützt Quick Connect nicht. Dafür ist Seerr 3.4 oder neuer erforderlich.';
	@override String get notInitialized => 'Die Ersteinrichtung dieser Seerr-Instanz wurde noch nicht abgeschlossen';
	@override String get noPlexTokenForReauth => 'Für die erneute Anmeldung ist kein Plex-Token verfügbar';
	@override String get noStoredCredentials => 'Für die erneute Anmeldung sind keine gespeicherten Anmeldedaten verfügbar';
	@override String get signInRejected => 'Die Anmeldung wurde abgelehnt';
	@override String get noSessionCookie => 'Seerr hat kein Sitzungscookie ausgestellt';
	@override String get freshCookieRejected => 'Seerr hat das neue Sitzungscookie abgelehnt';
	@override String get noUserInformation => 'Seerr hat keine Benutzerinformationen zurückgegeben';
	@override String get sessionRejectedAfterReauth => 'Die Sitzung wurde nach der erneuten Anmeldung abgelehnt';
	@override String get permissionDenied => 'Seerr hat diese Aktion abgelehnt: Dein Konto hat nicht mehr die erforderliche Berechtigung';
	@override String get permissionRevoked => 'Du hast keine Berechtigung mehr, dies anzufragen';
}

// Path: services
class _Translations$services$de extends Translations$services$en {
	_Translations$services$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dienste';
	@override String get hubSubtitle => 'Wiedergabefortschritt synchronisieren und neue Titel anfragen.';
	@override String get integrations => 'Integrationen';
	@override String get notConnected => 'Nicht verbunden';
	@override String connectedAs({required Object username}) => 'Verbunden als @${username}';
	@override String get scrobble => 'Fortschritt automatisch verfolgen';
	@override String get scrobbleDescription => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.';
	@override String disconnectConfirm({required Object service}) => '${service} trennen?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG aktualisiert ${service} nicht mehr. Jederzeit erneut verbinden.';
	@override String connectFailed({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.';
	@override late final _Translations$services$names$de names = _Translations$services$names$de._(_root);
	@override late final _Translations$services$simklReconnect$de simklReconnect = _Translations$services$simklReconnect$de._(_root);
	@override late final _Translations$services$deviceCode$de deviceCode = _Translations$services$deviceCode$de._(_root);
	@override late final _Translations$services$oauthProxy$de oauthProxy = _Translations$services$oauthProxy$de._(_root);
	@override late final _Translations$services$pendingAuth$de pendingAuth = _Translations$services$pendingAuth$de._(_root);
	@override late final _Translations$services$libraryFilter$de libraryFilter = _Translations$services$libraryFilter$de._(_root);
	@override String get seerrDescription => 'Verbinden Sie sich mit Seerr oder Overseerr, um Titel zu suchen und Medienanfragen vorzulegen.';
	@override late final _Translations$services$trackerDescriptions$de trackerDescriptions = _Translations$services$trackerDescriptions$de._(_root);
}

// Path: addServer
class _Translations$addServer$de extends Translations$addServer$en {
	_Translations$addServer$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => '${product}-Server hinzufügen';
	@override String get serverUrls => 'Server-URLs';
	@override String get serverUrlsHelper => 'Mehrere URLs möglich, durch Kommas getrennt.';
	@override String get findServer => 'Server finden';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Suche nach lokalen ${product}-Servern …';
	@override String localMediaBrowserServers({required Object product}) => 'Lokale ${product}-Server';
	@override String get username => 'Benutzername';
	@override String get password => 'Passwort';
	@override String get signIn => 'Anmelden';
	@override String get change => 'Ändern';
	@override String get required => 'Erforderlich';
	@override String couldNotReachServer({required Object error}) => 'Server nicht erreichbar: ${error}';
	@override String signInFailed({required Object error}) => 'Anmeldung fehlgeschlagen: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect fehlgeschlagen: ${error}';
	@override String get addPlexTitle => 'Mit Plex anmelden';
	@override String get pinExpired => 'PIN ist vor der Anmeldung abgelaufen. Bitte erneut versuchen.';
	@override String failedToRegisterAccount({required Object error}) => 'Konto konnte nicht registriert werden: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Gib die URL deines ${product}-Servers ein';
	@override String get addConnectionTitle => 'Verbindung hinzufügen';
	@override String addConnectionTitleScoped({required Object name}) => 'Zu ${name} hinzufügen';
	@override String get signInWithPlexCard => 'Mit Plex anmelden';
	@override String get signInWithPlexCardSubtitle => 'Dieses Gerät autorisieren. Geteilte Server werden hinzugefügt.';
	@override String get signInWithPlexCardSubtitleScoped => 'Ein Plex-Konto autorisieren. Home-Benutzer werden zu Profilen.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Mit ${product} verbinden';
	@override String get connectToMediaBrowserCardSubtitle => 'Gib Server-URL, Benutzername und Passwort ein.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Melde dich bei deinem ${product}-Server an. Wird mit ${name} verknüpft.';
	@override String get borrowFromAnotherProfile => 'Von einem anderen Profil ausleihen';
	@override String get borrowFromAnotherProfileSubtitle => 'Verbindung eines anderen Profils wiederverwenden. PIN-geschützte Profile erfordern eine PIN.';
	@override String get invalidCredentials => 'Ungültiger Benutzername oder ungültiges Passwort';
	@override String get authResponseNotJson => 'Die Authentifizierungsantwort war kein gültiges JSON';
	@override String get authResponseIncomplete => 'Die Anmeldeantwort des Servers war unvollständig';
	@override String get quickConnectRejected => 'Quick Connect wurde vom Server abgelehnt';
	@override String get quickConnectNotJson => 'Die Quick Connect-Antwort war kein gültiges JSON';
	@override String get quickConnectMissingFields => 'In der Quick Connect-Antwort fehlt ein Code oder Geheimnis';
	@override String get quickConnectPollRejected => 'Die Quick Connect-Abfrage wurde vom Server abgelehnt';
	@override String get serverTimedOut => 'Der Server hat nicht rechtzeitig geantwortet';
	@override String get responseNotJson => 'Die Serverantwort war kein gültiges JSON';
	@override String responseMissingIdentity({required Object product}) => 'In der Antwort fehlt eine ID oder ein Servername – ist dies ein ${product}-Server?';
	@override String probeFailed({required Object error}) => 'Server nicht erreichbar: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Gib mindestens eine URL eines ${product}-Servers ein';
	@override String noReachableServer({required Object product}) => 'Es wurde kein erreichbarer ${product}-Server gefunden';
	@override String urlsPointToDifferentServers({required Object product}) => 'Diese URLs verweisen auf verschiedene ${product}-Server';
	@override String urlDoesNotMatchServer({required Object product}) => 'Diese URL gehört nicht zum ${product}-Server';
	@override String get redirectUnsupported => 'Der Server hat zu einer nicht unterstützten URL weitergeleitet';
	@override String redirectDifferentHost({required Object product}) => 'Der Server hat zu einem anderen Host weitergeleitet. Gib die endgültige ${product}-URL direkt ein.';
	@override String get redirectInsecure => 'Der Server hat von HTTPS zu einer unsicheren URL weitergeleitet';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'Der Server hat zu einer nicht unterstützten URL weitergeleitet. Gib die endgültige ${product}-URL direkt ein.';
	@override String get directPlexServerUrl => 'Plex-Server-URL';
	@override String get directPlexServerUrlHelper => 'Geben Sie die lokale IP und Port Ihres Plex Media Server ein.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (optional)';
	@override String get plexTokenHelper => 'Lassen Sie es leer, wenn Zugriff ohne Auth auf diesem Server erlaubt ist.';
	@override String get plexTokenRequired => 'Bitte geben Sie Ihren Token Plex (X-Plex-Token) ein.';
	@override String get connectDirectPlexCard => 'Plex Media Server (Direkt / Lokal)';
	@override String get connectDirectPlexCardSubtitle => 'Verbindet Sie sich direkt mit lokaler IP oder URL ohne Plex.tv-Konto.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Verbindet Sie direkt mit lokaler IP oder URL. Verbindet Sie zu ${name}.';
	@override String get insecureTitle => 'Unschlüsselte Verbindung';
	@override String insecureDescription({required Object url}) => '${url} verwendet HTTP. Personen im Netzwerk können dein Passwort, deine Tokens und deine Medien lesen oder verändern. Verwende nach Möglichkeit HTTPS. Fahre nur fort, wenn du diesem Netzwerk vertraust und das Risiko akzeptierst.';
	@override String get allowHttp => 'HTTP erlauben';
	@override String get httpsRequired => 'Verwenden Sie HTTPS oder erlauben Sie ausdrücklich eine unschlüsselte Verbindung.';
}

// Path: cast
class _Translations$cast$de extends Translations$cast$en {
	_Translations$cast$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Kasten auf ein Gerät';
	@override String get searching => 'Suche nach Kastengeräten...';
	@override String connectedTo({required Object device}) => 'Anschluss an ${device}';
	@override String get device => 'Cast Gerät';
	@override String get readyToCast => 'Bereit zum Ausführen';
	@override String get subtitle => 'Untertitel';
	@override String get serverNotAvailable => 'Der Media-Server ist nicht verfügbar.';
	@override String get stopCasting => 'Stoppen Sie Casting';
	@override String get castToDevice => 'Kasten auf Gerät';
	@override String get noEpisodeAvailable => 'Es gibt keine Episoden zur Verfügung, um zu zählen.';
	@override String get startFailed => 'Kann nicht starten, die Kasten. prüfen Sie den Server und versuchen Sie es wieder.';
}

// Path: automation
class _Translations$automation$de extends Translations$automation$en {
	_Translations$automation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Es gibt keine aktive Video-Sitzung zu kontrollieren.';
}

// Path: notifications
class _Translations$notifications$de extends Translations$notifications$en {
	_Translations$notifications$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Neue Episode';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class _Translations$appAccess$de extends Translations$appAccess$en {
	_Translations$appAccess$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Versuchen Sie alle Funktionen für 7 Tage kostenlos';
	@override String get description => 'Beginnen Sie eine sieben Tage lang mit vollem Zugang zu jeder PlezyNG Funktion. Es gibt keine Gebühr während der Prüfung und keine Abonnement. Nach der Prüffel, ein Lebensdauer Kauf zu Ihrem Geschäft Preis enthüllt PlezyNG für das Leben.';
	@override String get trialEndedDescription => 'Entfernen Sie jede Funktion in PlezyNG für das Leben mit einem Kauf zum Preis Ihres Geschäcks.';
	@override String get startTrial => 'Start mein 7-tägiges kostenloses Prüfung';
	@override String get trialActive => 'Ihr 7-Tage-Full-Feature-Test ist aktiv.';
	@override String get trialEnded => 'Ihr 7-Tage-Test ist abgeschlossen';
	@override String get trialStartFailed => 'Ich konnte das Test auf diesem Gerät nicht speichern. versuchen Sie bitte erneut.';
	@override String get lifetimeTitle => 'PlezyNG Unlocked für das Leben';
	@override String get lifetimeBody => 'Dank! Sie haben den lebenslangen Zugriff auf jede PlezyNG Funktion.';
	@override String get manageTitle => 'PlezyNG Lebensdauer Zugang';
	@override String get manageDescription => 'Versuchen Sie jede Funktion für 7 Tage kostenlos, dann alles für das Leben mit einem einzigen Zahlung zu Ihrem Geschäft Preis entschließen.';
	@override String buy({required Object price}) => 'Entfernen Sie alle Funktionen für ${price}';
	@override String get loadingPrice => 'Die Ladung im Shoppreis...';
	@override String get retryPrice => 'Rückkehr Preis Lookup';
	@override String get restore => 'Lebensdauer Kauf wiederherstellen';
	@override String get pending => 'Ihr Kauf wartet auf Zahlung oder Genehmigung. Lifetime-Zugang wird abgeschlossen, sobald der Shop es abgeschlossen hat.';
	@override String get storeUnavailable => 'Überprüfen Sie, dass Sie im Laden eingeloggt sind und die Einkaufsmöglichkeiten auf diesem Gerät erlaubt sind.';
	@override String get productNotFound => 'Die PlezyNG Lebensdauer-Unlock ist noch nicht in diesem Shop erhältlich.';
	@override String get productQueryFailed => 'Kann den Shoppreis nicht laden. Überprüfen Sie Ihre Verbindung und versuchen Sie es wieder.';
	@override String get purchaseFailed => 'Der Kauf ist nicht durchgeführt worden. versuchen Sie erneut.';
	@override String get restoreFailed => 'Ich konnte nicht zum Shop kommen, um Ihren Kauf wiederherzustellen. versuchen Sie erneut.';
	@override String get nothingToRestore => 'No. PlezyNG Lebensdauer Kauf wurde für diesen Store-Konto gefunden.';
}

// Path: detail
class _Translations$detail$de extends Translations$detail$en {
	_Translations$detail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Endet um ${time}';
}

// Path: watchLink
class _Translations$watchLink$de extends Translations$watchLink$en {
	_Translations$watchLink$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Ich konnte nicht auf einen Server Plex für diesen Link erreichen.';
	@override String get notFound => 'Ich konnte diese Show oder Film nicht auf Ihren Server Plex finden.';
	@override String get ambiguous => 'Dieser Link entspricht den Elementen auf mehr als einem Server.Hinzufügen eines Server zum Link.';
	@override String get plexOnly => 'Die Watch Links unterstützen derzeit nur Plex Server.';
	@override String get unsupportedItem => 'Die Anzeige-Links können nur eine Show oder einen Film öffnen.';
	@override String get menuItem => 'Sehen Sie den Link';
	@override String get dialogTitle => 'Sehen Sie Link';
	@override String get dialogShowHint => 'Öffnen dieser Link spielt die nächste Episode. Add &mode=shuffle to the end, um die Show auf shuffle zu spielen.';
	@override String get dialogMovieHint => 'Mit diesem Link öffnet der Film.';
	@override String get copy => 'Kopie';
	@override String get copied => 'Link kopiert';
}

// Path: homeLayout
class _Translations$homeLayout$de extends Translations$homeLayout$en {
	_Translations$homeLayout$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home Reset auf die ursprüngliche Plezy Hero-Layout';
	@override String get resetHeroTitle => 'Wiederherstellen Sie die Hero-Layout auf Lager Plezy?';
	@override String get resetHeroBody => 'Sie dreht die Heldinstellung jeder Reihe ab und bringt die einzige Rotation Banner wieder auf der Spitze des Hauses, wie vor der Hero-Raden existiert.';
	@override String get removeRowTitle => 'Home Range entfernen?';
	@override String removeRowBody({required Object title}) => '${title} wird gelöscht. dies kann nicht abgesagt werden.';
	@override String get sync => 'Synchronisierung';
	@override String get syncAccountTitle => 'Synchronisieren Sie die Layout mit Ihrem Konto Plex';
	@override String get syncAccountOn => 'Auf: Dieses Gerät teilt die Reihenfolge, Reihenfolgen, Hero und Auto-Slide mit Ihren anderen Geräten.';
	@override String get syncAccountOff => 'Off: Dieses Gerät hält seine eigene Layout.';
	@override String get syncNow => 'Synchronisierung jetzt';
	@override String get plexHomeManager => 'Plex Hausverwalter';
	@override String get managePlexRows => 'Verwaltung Plex Zeilen in Plezy';
	@override String get managePlexRowsDescription => 'Öffnen Sie die Home-Selected Routes';
	@override String get organizeHomeRows => 'Home Runden organisieren';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} Zeilen: Bewegung, Hero, Auto-Slide, entfernen';
	@override String organizeLibraryRows({required Object library}) => '${library} Runden zu organisieren';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Weiterlesen + ${n} Zeilen: Bewegung, Bibliothek, Home, Hero, Auto-Slide';
	@override String get renderAsHero => 'Render als Heldkarte';
	@override String get heroOnlySingleCollection => 'Erhältlich nur, wenn diese Reihe auf die tatsächlichen Titel einer einzelnen Sammlung gelöst wird';
	@override String get hero => 'Helden';
	@override String get autoSlide => 'Auto-Slide';
	@override String get autoSlideDescription => 'Auch schlägt sie alle paar Sekunden auf sich. Arrows (PC) und d-pad (TV) arbeiten immer und starten die Timer neu.';
	@override String get autoSlideEditDescription => 'Auch schlägt sie alle paar Sekunden auf sich. Off: bewegt sich nur, wenn Sie auf eine Pfeile (PC) klicken oder links/recht auf die Fernseher (TV) drücken.';
	@override String get enableHeroFirst => 'Helden erstmal gestalten';
	@override String get showOnHome => 'Show auf Home Screen';
	@override String get home => 'Start';
	@override String get removeFromHome => 'Entfernen von zu Hause';
	@override String get selectRowsFirst => 'Wählen Sie die Home-Raden unten zuerst aus.';
	@override String plexManagedRows({required Object n}) => '${n} Plex verwaltete Zeilen';
	@override String get continueWatching => 'Weiterschauen';
	@override String get continueWatchingLibraryDescription => 'Diese eigene Bibliothek-Rehmen-Vorgang-Reihe';
	@override String get continueWatchingHomeDescription => 'Die Wiederholung-Vorgang-Reihe auf Home angezeigt';
	@override String get nextUpHomeDescription => 'Die nächste unbeobachtete Episode-Reihe separat auf Home angezeigt';
	@override String get library => 'Mediathek';
	@override String get showInRecommended => 'Show in der Bibliothek empfohlen';
	@override String get customPlexRow => 'Anpassung Plex Runde';
	@override String get heroNeedsLibrary => 'Schauen Sie sich die Bibliothek zuerst an – Hero braucht irgendwo zu zeigen';
	@override String get heroNeedsSurface => 'Schauen Sie sich die Bibliothek oder Home zuerst an – Hero braucht irgendwo zu zeigen';
	@override String get removeHub => 'Hub entfernen';
	@override String get noPlexRows => 'Nr. Plex-verwaltete Zeilen zurückkehren für diese Bibliothek.';
	@override String get openDetails => 'Offene Details';
	@override String get heroCards => 'Hero Karten';
	@override String get tapHeroCard => 'Ein Hero-Karte zu schlagen';
	@override String get tvPlayFocus => 'Fernseher: Highlight Play-Button';
	@override String get tvPlayFocusDescription => 'D-Pad Down stoppt auf der Play-Taste, bevor Sie in die nächste Reihe gehen.';
	@override String get tvWrap => 'Fernseher Fernseher: Lauf-Hero-Karten';
	@override String get tvWrapDescription => 'Direkt auf der letzten Karte geht zurück zum ersten. Off stops auf der letzten. Links auf der ersten Karte geht immer zur Seite.';
	@override String get castOnHero => 'Banner auf Hero Banner';
	@override String get castOnHeroDescription => 'Zeigt die Ausgabe entlang der Unterseite eines Hero Banner. Off hält nur den Titel und Zusammenfassung.';
	@override String get customRows => 'Custom Routen';
	@override String get loading => 'Home Layout Layout ...';
	@override String get noCustomRows => 'Keine Standard-Rennen noch';
	@override String get addRowHint => 'Verwenden Sie Add Home Range, um einen zu erstellen.';
	@override String get addHomeRow => 'Home Rue hinzufügen';
	@override String get addHomeRowDescription => 'Wählen Sie eine Kategorie aus; die neue Reihe wird automatisch an den Organizer hinzugefügt';
	@override String get removeRow => 'Rückschluss entfernen';
	@override String get recentlyAdded => 'Kürzlich hinzugefügt';
	@override String get recentlyReleased => 'kürzlich veröffentlicht';
	@override String get movieCollections => 'Filmkollektionen';
	@override String get showCollections => 'Show Kollektionen';
	@override String get rowTitle => 'Röhrtitel';
	@override String get content => 'Inhalt';
	@override String get showThisRowIn => 'Zeigen Sie diese Reihe in:';
	@override String get libraryRecommended => 'Bibliothek empfohlen';
	@override String get heroCard => 'Hero Karten';
	@override String get heroCardDescription => 'Zeigt als eine vollbreite Rotationskarte anstelle eines Posterschilds an.';
	@override String get heroUnavailableDescription => 'Nur dann verfügbar, wenn diese Reihe auf die tatsächlichen Titel einer einzelnen Sammlung gelöst wird – mit mehr als einer Sammlung ausgewählt, gibt es keine einzige Titel, die durchzuführen ist.';
	@override String get librariesSelection => 'Bibliotheken (alle nicht überprüften, um jede Bibliothek zu enthalten)';
	@override String get librariesMergedDescription => 'Jede hier überprüfte Bibliothek ist in diese eine Reihe zusammengefasst.';
	@override String get movieCollectionsSelection => 'Filmkollektionen (alle uncheckten für jede ausgewählte Bibliothek hinterlassen)';
	@override String get showCollectionsSelection => 'Zeigen Sie Sammlungen (alle uncheckten für jede ausgewählte Bibliothek abgeben)';
	@override String get collectionRowsDescription => 'Wenn genau eine Sammlung matzt, zeigen ihre Titel direkt in der Reihe. Wenn mehr als eine matzt, zeigt jede Sammlung als ein einziges Poster - drücken Sie es, um diese Sammlung zu öffnen.';
	@override String get allCollections => 'Alle Kollektionen';
	@override String get noRowsHere => 'Noch keine Runden hier.';
	@override String get hideWatchedRows => 'Verbergen Sie beobachtete Gegenstände in Zeilen';
	@override String get hideWatchedRowsDescription => 'Vollständig beobachtete Titel verlassen Home und Bibliothek Empfohlene Zeilen.';
	@override String get untitledCollection => 'Untitelte Sammlung';
	@override String get moveRowHint => 'Up/Down: Schalten Sie die Reihenfolge · Wählen Sie aus: Schalten sie hier · Rückkehr: Kündigen';
	@override String get organizeRowsHint => 'Wählen Sie auf einer Reihe (oder halten Sie Sie wählen Sie): bewegen Sie es · Links/Richt: Reihe Optionen · Rückkehr: getan';
	@override String get layoutNavDescription => 'Wählen Sie Zeilen, Bibliotheken und Sammlungskategorien aus';
	@override String get editHomeRow => 'Edit Home Rue zu lesen';
	@override String get resetHeroButton => 'Wiederherstellen des Hero-Layout auf Lager Plezy';
	@override String get reorderingUnlocked => 'Wiederverzeichnis unlocked';
	@override String get reorderingLocked => 'Umzug verborgen';
	@override String get rowsCanBeDragged => 'Die Wellen können abgeschaltet werden – das Lock aufschreiben, um zu verhindern, dass';
	@override String get tapLockToDrag => 'Tippen Sie den Lock, um Runden zu ziehen';
	@override String customRowLabel({required Object title}) => 'Anzahl: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Ausblenden';
	@override String get remove => 'Entfernen';
	@override String get libraryResumeRow => 'Die Bibliothek wird wiederum';
	@override String get pressAgainToDelete => 'Drücken Sie wieder, um zu löschen';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'auf';
	@override String get resetHeroButtonDescription => 'Sie dreht die Heldinstellung jeder Reihe ab und bringt die einzige Rotation Banner wieder oben, wie vor der Hero-Rennen existiert.';
	@override String get tapHeroCardDescription => 'Wählen Sie aus, ob das Tippen oder die Auswahl einer Hero-Karte eine Wiedergabe beginnt oder seine Details öffnet.';
	@override String get heroTapPlayDescription => 'Beginnen Sie das ausgewählte Element sofort.';
	@override String get heroTapDetailsDescription => 'Öffnen Sie die Details des ausgewählten Elements, bevor Sie eine Aktion wählen.';
}

// Path: platform
class _Translations$platform$de extends Translations$platform$en {
	_Translations$platform$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG verbindet sich mit Ihren Medien-Server und Playback-Geräten auf Ihrem lokalen Netzwerk.';
	@override String get locationPermission => 'PlezyNG verwendet Standortzugang, wenn iOS es benötigt, um Ihr lokales Netzwerk zu erkennen und mit Ihren Medien-Server zu verbinden.';
	@override String get photoLibraryPermission => 'Wähle Bilder aus deiner Fotomediathek aus, um sie als Mediencover und andere Medienbilder zu verwenden.';
	@override String get cameraPermission => 'QR-Codes scannen, um eine Companion Remote zu koppeln.';
}

// Path: universalMedia
class _Translations$universalMedia$de extends Translations$universalMedia$en {
	_Translations$universalMedia$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Öffnete Medien';
	@override String get shortcutHelp => 'Spielen Sie einen Link, eine Playlist oder eine Datei für diese Sitzung.';
	@override String get intro => 'Öffnen Sie einen Link, eine Playlist oder eine Datei.Playback verwendet den Standard-Player von PlezyNG und fügt keine Geschichte in Ihre Bibliothek hinzu.';
	@override String get openWhat => 'Was würdest du gerne öffnen?';
	@override String get stream => 'Stream Adresse';
	@override String get playlist => 'Spielliste';
	@override String get files => 'Geräte Datei';
	@override String get favorites => 'Sparen Stream Favoriten';
	@override String get address => 'Medienadresse';
	@override String get addressHelp => 'URLs mit anerkannten Kennzeichnungs- oder Signaturparameter werden nur für diese Sitzung verwendet und können nicht als Favoriten gespeichert werden.';
	@override String get displayName => 'Anzeige Name (optional)';
	@override String get displayNameHelp => 'Wählen Sie einen kurzen Namen für den Spieler und System-Media-Controls aus.';
	@override String get allowHttp => 'Erlauben Sie eine unschlüsselte HTTP-Verbindung';
	@override String get allowHttpHelp => 'HTTP verschlüsselt die Verbindung nicht. Erlauben Sie es nur auf einem vertrauenswürdigen Netzwerk. Verwenden Sie HTTPS, wenn möglich.';
	@override String get advancedProtocols => 'MPV nur: Geben Sie eine RTSP, RTMP/RTMPS, UDP oder RTP-Adresse ein. Diese Adressen können nicht als Favoriten gespeichert werden.';
	@override String get liveStream => 'Behandeln Sie als lebend';
	@override String get liveStreamHelp => 'Verwenden Sie dies für Live-Video oder Radio. Die App verbergt die Zeitbar, Skip-Button und Go-to-Time-Option.';
	@override String get privateSession => 'Nur dieses Playback verwendet die Adresse. Speichern Sie einen qualifizierten Stream Favorit, um es in diesem Profil zu halten.';
	@override String get saveFavorite => 'Speichern Sie Favoriten';
	@override String get playNow => 'Jetzt spielen';
	@override String get favoriteSaved => 'Stream Favoriten auf diesem Profil gespeichert';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Skipped ${count} ununterstützte oder sichere Playlist-Einträge.',
		other: 'Skipped ${count} nicht unterstützte oder unsichere Playlist-Einträge.',
	);
	@override String get playlistAddress => 'Playlist Adresse';
	@override String get playlistAddressHelp => 'Öffnen Sie eine M3U, M3u8 oder PLS-Playliste von einer Webadresse. Direct Stream Links speichern die Playlist nicht.';
	@override String get choosePlaylist => 'Wählen Sie Playlist-Datei';
	@override String get openPlaylist => 'Öffnen der Playlist';
	@override String get playlistFormatsHelp => 'Eine Playlist kann bis zu 1.000 Elemente und 2 MB enthalten. HLS manifestiert sich als Streams öffnet, so dass der Spieler eine Qualität wählen kann.';
	@override String get noFavorites => 'Keine gespeicherten Stream-Favorites noch. Favorites bleiben in diesem Profil.';
	@override String get removeFavorite => 'Stream Favoriten entfernen';
	@override String get filesHelp => 'Wählen Sie Audio, Video oder ISO-Dateien für eine vorübergehende Quelle. Dateien und URLs werden nicht in die Bibliothekgeschichte hinzugefügt.';
	@override String get chooseFiles => 'Wählen Sie Dateien';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '1 ausgewählte Datei',
		other: '${count} ausgewählte Dateien',
	);
	@override String get wifiTransfer => 'Dateien über Wi-Fi senden';
	@override String get wifiTransferHelp => 'Übertragen von unterstützten Dateien aus einem Browser auf das gleiche vertrauenswürdige Netzwerk.';
	@override String get wifiTransferIntro => 'Öffnen Sie diese Adresse in einem Browser auf einem anderen Gerät. Wählen Sie Dateien, um sie in die Datei- und Bücherbibliothek dieses Geräts hinzuzufügen.';
	@override String get wifiTransferPrivacy => 'Dieses Gerät erhält Dateien über Ihr lokales Netzwerk. Jeder, der diese Adresse kennt, kann Dateien senden, bis Sie die Übertragung stoppen oder die Adresse nach 15 Minuten endet. Maximum: 100 Dateien, 4 GiB pro Datei, 10 GiB insgesamt.';
	@override String get wifiTransferStarting => 'Eine private, zeitlich begrenzte Übertragung...';
	@override String get wifiTransferUnavailable => 'Sie können die Übertragung nicht starten. Überprüfen Sie den lokalen Netzwerkzugang und versuchen Sie erneut.';
	@override String get openThisAddress => 'Öffnen Sie eine dieser Adressen auf dem Versandgerät';
	@override String get copyAddress => 'Kopie der Transferadresse';
	@override String get addressCopied => 'Übertragungsadresse kopiert';
	@override String transferExpires({required Object time}) => 'Diese Adresse endet in ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${count} Datei erhalten',
		other: '${count} Dateien erhalten',
	);
	@override String uploadedData({required Object size}) => 'Erhalt ${size}';
	@override String get stopTransfer => 'Übertragung und Invalidierung der Adresse stoppen';
	@override String get startTransfer => 'Beginn der Transfer';
	@override String get wifiImportedFiles => 'Wi-Fi Übertragung';
	@override String get wifiBrowserTitle => 'Dateien an PlezyNG senden';
	@override String get wifiBrowserIntro => 'Wählen Sie Audio, Video, Ebook oder Comic-Dateien zur Sendung aus. Die Dateien werden in der Datei- und Bücherbibliothek dieses Geräts gespeichert. Maximum: 100 Dateien, 4 GiB pro Datei, 10 GiB insgesamt.';
	@override String get uploadFilesLabel => 'Dateien zu senden';
	@override String get uploadSelected => 'Laden Sie ausgewählte Dateien';
	@override String get uploadSelectFirst => 'Wählen Sie zuerst eine oder mehrere Dateien aus.';
	@override String get uploading => 'Senden';
	@override String get uploadComplete => 'Datei zu PlezyNG hinzugefügt.';
	@override String get uploadFailed => 'Die Datei kann nicht hinzugefügt werden.Halten Sie diese Seite offen und versuchen Sie erneut.';
	@override String get liveCue => 'live';
	@override String get liveSession => 'Live Stream';
	@override String get liveCueHelp => 'Für Live-Video oder Radio versteckt die App die Zeitraumbar und schlägt die Button. Es speichert nicht die Adresse oder die Geschichte der Uhrzeit.';
	@override String get sessionOnly => 'Dieser Playback ist Session-Only';
	@override String get sessionOnlyHelp => 'Playback speichert niemals Fortschritte oder Geschichte.Save the stream as a favorite to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Bild Anpassungen';
	@override String get pictureHelp => 'Diese Bildänderungen beeinflussen nur diesen Playback. Sie reset, wenn das Playback endet.';
	@override String get resetPicture => 'Reset Bild';
	@override String get brightness => 'Brightheit';
	@override String get contrast => 'Kontrast';
	@override String get gamma => 'Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturation';
	@override String get view360 => 'Flat View für 360° Video';
	@override String get view360Help => 'Verwenden Sie dies für gleichwertige 360°-Video. MPV benötigt FFmpeg\'s v360-Filter für diesen Ausblick.';
	@override String get view360Unavailable => 'Diese MPV-Konstruktion konnte das 360°-Filter nicht anwenden.';
	@override String get view360Yaw => 'Horizontale Sicht';
	@override String get view360Pitch => 'Vertikale Sicht';
	@override String get view360FieldOfView => 'Feld der Sicht';
	@override String get recordStream => 'Live Stream Rekord';
	@override String get stopRecording => 'Stoppen und speichern Sie die Aufzeichnung';
	@override String get recordingStarted => 'Die Aufnahme ist aktiv.Leaving playback stoppt und speichert die Aufnahme.';
	@override String get recordingSaved => 'Die Aufzeichnung wurde abgeschlossen und gerettet.';
	@override String get recordingActive => 'Auf diesem Gerät aufzeichnen.Leaving playback stoppt und speichert es.';
	@override String get recordingFormatHelp => 'Wählen Sie für Video MKV oder MPEG-TS. Für Audio wählen Sie MKA oder MKV aus.';
	@override String get replaceRecordingTitle => 'Ersetzen Sie diese Aufzeichnung?';
	@override String get replaceRecordingHelp => 'PlezyNG backt die bestehende Datei während der Aufzeichnung auf. Wenn sie die neue Aufnahme nicht speichern kann, wiederherstellt plezyNG die Backup.';
	@override String get replaceRecording => 'Datei ersetzen';
	@override String get discHelp => 'Öffnen Sie einen Disk im optischen Laufwerk dieses Computers. Sie können auch ein ISO-Bild aus Device-Dateien öffnen.';
	@override String get discs => 'Optische Disk';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-Ray';
	@override String get audioCd => 'Audio CD';
	@override String get discAvailability => 'Disk-Playback benötigt eine kompatible MPV-Konstruktion, unterstütztes Drive und Betriebssystemsgenehmigung. Es kann nicht den kommerziellen Diskschutz überschreiten.';
	@override String get converterTitle => 'Umwandeln einer lokalen Mediendatei';
	@override String get converterHelp => 'Umwandeln Sie eine lokale Datei oder remucken Sie sie mit FFmpeg.';
	@override String get converterIntro => 'Konvertieren Sie eine lokale Audio- oder Video-Datei in ein Format, das auf mehreren Geräten funktioniert.';
	@override String get converterPrivacy => 'FFmpeg muss auf diesem Computer installiert werden. Conversion liest nur lokale Dateien. Es herunterladen Streams oder entfernen DRM nicht.';
	@override String get converterChooseInput => 'Wählen Sie eine lokale Mediendatei';
	@override String get converterFormat => 'Ausgangsformat';
	@override String get converterMp4 => 'MP4 · H.264 und AAC';
	@override String get converterM4a => 'M4A · AAC Audio';
	@override String get converterMp3 => 'MP3 - Audio';
	@override String get converterSaveAs => 'Speichern Sie konvertierte Medien als';
	@override String get converterExtensionMismatch => 'Wählen Sie einen Filennamen mit der ausgewählten Ausgangserweiterung aus.';
	@override String get converterUnsupportedInput => 'Wählen Sie eine Audio oder Video-Datei aus.';
	@override String get converterLocalOnly => 'Die ausgewählte Datei ist nicht als lokaler Gerätstraße verfügbar.';
	@override String get converterReplaceTitle => 'Ersetzen Sie diese Datei?';
	@override String get converterReplaceHelp => 'PlezyNG backs up die bestehende Datei, bis die konvertierte Kopie gespeichert wird.';
	@override String get converterStarting => 'Beginnen Sie mit FFmpeg...';
	@override String get converterProgress => 'Umwandeln Sie auf diesen Computer ...';
	@override String get converterComplete => 'Konvertierung abgeschlossen. die neue Datei ist bereit.';
	@override String get converterFfmpegMissing => 'FFmpeg Es fehlt oder unterstützt dieses Format nicht.';
	@override String get converterFailed => 'Überprüfen Sie, dass die Quelldatei gelesen werden kann und der Reiseziel genügend freie Platz hat.';
	@override String get converterCancelled => 'Konvertierung abgesagt. Der unvollständige Ausgang wurde entfernt.';
	@override String get converterDesktopOnly => 'Lokale Konvertierung ist auf Desktop-Computer mit FFmpeg installiert.';
	@override String get converterStart => 'Konvertierung Datei';
	@override String get mediaToolsTitle => 'Medieninstrumente';
	@override String get mediaToolsShortcut => 'Fangen oder teilen Sie Medien, fügen Sie Suchergänzungen hinzu oder verwenden Sie die Befehllinie.';
	@override String get mediaToolsIntro => 'Wählen Sie ein fokussiertes Werkzeug. Fangen und Streaming-out verwenden FFmpeg auf diesem Desktop installiert. Erweiterungen und CLI Befehl verwenden begrenzte HTTPS Anfragen und die bestehende Open media Fluss.';
	@override String get mediaToolsAccessibility => 'Tool-Wahlen und Steuerungen arbeiten mit Touch, Indikator, Tastatur und D-pad Fokus. Aufzeichnung, Teilen und Suchstatus Änderungen werden angekündigt.';
	@override String get mediaTool => 'Medienwerkzeug';
	@override String get captureIntro => 'Aufzeichnen Sie Ihren Bildschirm oder eine Kamera auf einem MP4-Datei auf diesem Computer. FFmpeg muss installiert und den H.264-Coder enthält.';
	@override String get captureNoDevices => 'Kein Bildschirm oder Kamera gefunden wurde. Überprüfen Sie FFmpeg Aufnahmeunterstützung und Betriebssystem-Privacy-Erlaubnisse.';
	@override String get captureSource => 'Bildschirm oder Kamera';
	@override String get captureAudioSource => 'Audio Input (optional)';
	@override String get captureAudioHelp => 'Hinzufügen von Audio aus einem Mikrofon oder verfügbaren Eingang. Gerätewahl hängt von FFmpeg und Systemgenehmigungen ab.';
	@override String get captureAudioNone => 'Kein Audio';
	@override String get captureWaylandHelp => 'Wayland beschränkt diese XWayland Aufnahme auf die X display. Windows außerhalb von XWayland erscheinen nicht.';
	@override String get captureFrameRate => 'Aufzeichnung Frame Rate';
	@override String get capturePrivacy => 'Die Aufzeichnung wird nur auf die von Ihnen gewählte Datei gespeichert. Microphone-Fangen ist optionell. PlezyNG laden die Aufzeichnung nicht auf.';
	@override String get captureSaveAs => 'Speichern Sie die Screenshots als';
	@override String get captureExtensionMismatch => 'Wählen Sie einen Filennamen, der in .mp4 endet.';
	@override String get captureFfmpegMissing => 'FFmpeg oder der H.264 Video-Coder ist nicht verfügbar. Einrichten Sie eine unterstützte FFmpeg Bau, dann versuchen Sie erneut.';
	@override String get captureFailed => 'Die Aufzeichnung konnte nicht gespeichert werden. Überprüfen Sie die Gerätgenehmigung, verfügbare Speicherung und FFmpeg Support.';
	@override String get captureSaved => 'Bildschirmaufnahmen gerettet.';
	@override String get captureElapsedLabel => 'Aufzeichnungszeit';
	@override String get captureStart => 'Beginnen Sie mit der Aufzeichnung';
	@override String get captureStop => 'Stoppen und retten';
	@override String get captureMode => 'Gefangene';
	@override String get shareMode => 'Teilen';
	@override String get shareIntro => 'Senden Sie eine lokale Mediendatei an ein anderes Gerät auf Ihrem privaten Netzwerk. PlezyNG erstellt einen vorübergehenden HLS Stream.';
	@override String get sharePrivacy => 'Jeder auf Ihrem lokalen Netzwerk, der den privaten Link erhält, kann den Link beobachten, während er aktiv ist. Der Link verschwindet nach 60 Minuten.';
	@override String get shareChooseFile => 'Media Datei auswählen';
	@override String get shareChooseHelp => 'Wählen Sie eine lokale Audio- oder Video-Datei aus. Die Datei bleibt auf diesem Computer.';
	@override String get shareFfmpegMissing => 'FFmpeg oder die H.264/AAC Codern sind nicht verfügbar. Installieren Sie FFmpeg mit H.264 und AAC Codern Unterstützung.';
	@override String get shareFailed => 'Der Stream konnte nicht beginnen oder unerwartet gestoppt werden. Überprüfen Sie FFmpeg und Netzwerkzugang.';
	@override String get shareActive => 'Der Stream ist bereit auf Ihrem privaten Netzwerk.';
	@override String get shareEnded => 'Die Medien haben das Ende erreicht und werden nicht mehr geteilt.';
	@override String get shareStopped => 'Die Teilen sind gestoppt.Der vorübergehende Link ist nicht mehr gültig.';
	@override String get shareUrlCopied => 'Stream Adresse kopiert.';
	@override String get shareOpenUrl => 'Öffnen Sie diese Adresse in einem Spieler auf dem anderen Gerät';
	@override String get shareCopyUrl => 'Kopieren von Stream-Adresse';
	@override String get shareExpiresLabel => 'Link endet ab';
	@override String get shareStarting => 'Bereiten Sie den Stream vor...';
	@override String get shareStart => 'Beginnen Sie mit Teilen';
	@override String get shareStop => 'Stoppen Sie mit dem Teilen';
	@override String get extensionsMode => 'Erweiterungen und CLI';
	@override String get extensionsIntro => 'Hinzufügen Sie eine Daten-nur-Suche-Erweiterung, um Medien zu finden. Wählen Sie ein Ergebnis, um es in das bekannte Open media Formular zu laden.';
	@override String get extensionsPrivacy => 'Ein Manifest kann eine HTTPS-Suche endpoint und map-responsfelder definieren. Es kann nicht Code ausführen, Antrag-Titel hinzufügen, Dateien lesen oder Start-Shell-Kommandos.';
	@override String get extensionImport => 'Erweiterung manifestiert';
	@override String get extensionEmpty => 'Keine Suchdienstleistungen noch. Wählen Sie eine vertrauenswürdige Manifest JSON Datei, um eine hinzuzufügen.';
	@override String get extensionChoose => 'Suchdienst';
	@override String get extensionSearchConsent => 'Jede Suche sendet Ihre Worte an diesen HTTPS Service. Ergebnisse öffnen sich nur nachdem Sie einen auswählen.';
	@override String get extensionSearchLabel => 'Suche nach Medien';
	@override String get extensionSearch => 'Suche';
	@override String get extensionSearching => 'Suchen...';
	@override String get extensionNoResults => 'Keine sicheren Medienergebnisse wurden zurückgegeben. versuchen Sie eine weitere Suche.';
	@override String get extensionInstallTitle => 'Geben Sie diesen Suchdienst hinzu?';
	@override String get extensionReplaceTitle => 'Aktualisieren Sie diesen Suchdienst?';
	@override String get extensionService => 'Dienstleistung';
	@override String get extensionEndpoint => 'HTTPS Endpunkt';
	@override String get extensionConsent => 'Ihr Suchtext wird an diesen Service gesendet. Das Manifest enthält keinen executable Code. Weiter nur, wenn Sie diesem Endpunkt vertrauen.';
	@override String get extensionInstall => 'Service hinzufügen';
	@override String get extensionReplace => 'Aktualisierung Service';
	@override String get extensionRemoveTitle => 'Entfernen Sie diesen Suchdienst?';
	@override String get extensionRemoveHelp => 'Dies entfernt den Service aus diesem Profil. PlezyNG kontaktiert nicht seinen Endpunkt.';
	@override String get extensionRemove => 'Service entfernen';
	@override String get extensionInvalidManifest => 'Dieser Datei ist kein unterstütztes Extension manifesto. siehe die Open media-Günderung für das Format.';
	@override String get extensionSaveFailed => 'Die Erweiterung konnte nicht auf das aktive Profil gespeichert werden.';
	@override String get extensionSearchFailed => 'Der Suchdienst hat keine gültige Antwort zurückgegeben. prüfen Sie das Endpunkt und versuchen Sie es erneut.';
	@override String get cliTitle => 'Kommando Linie';
	@override String get cliHelp => 'Verwenden Sie den plezyctl-Guide, um ein Manifest zu validieren oder die gleiche Erweiterung zu suchen. Überprüfen Sie den HTTPS-Service vor jeder Suche. Ergebnisse öffnen sich im bestehenden Medienformular; wählen Sie den Playback-Taste aus, um zu starten.';
	@override String get cliCopyExample => 'Kopieren von Command Example';
	@override String get cliCopied => 'Das Beispiel der Kopie.';
	@override String get captureScreen => 'Bildschirm';
	@override String get captureDefaultAudio => 'Default Audio-Eintrag';
	@override String get shareQrLabel => 'QR-Code für die temporäre Stream-Adresse';
	@override String get shareQrHelp => 'Scan mit einem kompatiblen Player, der mit demselben privaten Netzwerk verbunden ist.';
	@override String get shareHttpHint => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.';
	@override String get allowFtp => 'FTP erlaubt';
	@override String get allowFtpHelp => 'FTP sendet Medien ohne Verschlüsselung. Verwenden Sie nur auf vertrauenswürdigen Netzwerken.';
}

// Path: fileSources
class _Translations$fileSources$de extends Translations$fileSources$en {
	_Translations$fileSources$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dateien und Bücher';
	@override String get subtitle => 'Lesen, hören und aus Ihren eigenen Dateien beobachten.';
	@override String get add => 'Quelle hinzufügen';
	@override String get importFiles => 'Importierung von Dateien';
	@override String get localFiles => 'Auf diesem Gerät';
	@override String get source => 'Quelle';
	@override String get name => 'Name';
	@override String get endpoint => 'Server-URL';
	@override String get smbEndpointHint => 'Beispiel: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Gib einen SMB-Server und eine Freigabe ein.';
	@override String get root => 'Folder oder Prefix';
	@override String get smbFolderHelp => 'Lass das Feld leer, um die gesamte Freigabe zu verwenden, oder gib einen Ordner darin ein.';
	@override String get username => 'Benutzername';
	@override String get smbDomain => 'Domäne (optional)';
	@override String get password => 'Passwort';
	@override String get token => 'API Token';
	@override String get accessKey => 'Zugriffs-Key ID';
	@override String get secretKey => 'Geheimen Zugriffsschlüssel';
	@override String get sessionToken => 'Session Token (Optional)';
	@override String get region => 'Region';
	@override String get clientId => 'OAuth Client ID';
	@override String get clientSecret => 'OAuth Client Secret (nur Google Desktop)';
	@override String get allowHttp => 'Unverschlüsseltes HTTP in einem vertrauenswürdigen Netzwerk erlauben';
	@override String get smbEncryption => 'SMB3-Verbindung verschlüsseln';
	@override String get smbEncryptionHint => 'SMB3-Verschlüsselung verwenden, wenn das NAS sie unterstützt.';
	@override String get connect => 'Verbinden';
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
	@override String get removeSource => 'Abschließen Quelle';
	@override String get disconnectMessage => 'Verbindung zu dieser Quelle trennen? Heruntergeladene Dateien sowie dein Lese- und Hörverlauf bleiben auf diesem Gerät.';
	@override String get localFolder => 'Wählen Sie die Folder';
	@override String get empty => 'Hier ist noch nichts';
	@override String get emptyHint => 'Ein Quell hinzufügen oder ein Buch, Audiobook, Musik oder Video importieren.';
	@override String get search => 'Suche nach diesem Ordner';
	@override String get searchCached => 'Suche nach der Rettung Bibliothek';
	@override String get refresh => 'Aktualisieren';
	@override String get loadMore => 'Laden Sie mehr';
	@override String get offline => 'Offline verfügbar';
	@override String get download => 'Offline bleiben';
	@override String get removeDownload => 'Offline Kopie entfernen';
	@override String get continueReading => 'Weiterlesen →';
	@override String get continueListening => 'Weiterlesen Listen';
	@override String get continueWatching => 'Weiter zu beobachten';
	@override String get read => 'Lesen';
	@override String get listen => 'Anhören';
	@override String get play => 'Abspielen';
	@override String get pause => 'Pause';
	@override String get stop => 'Stopp';
	@override String get startOver => 'Beginnen Sie über';
	@override String get finished => 'Beendet';
	@override String get markFinished => 'Mark ist fertig';
	@override String get markUnfinished => 'Mark unendlich';
	@override String get editions => 'Veröffentlichungen und Dateien';
	@override String get chapters => 'Kapitel';
	@override String get bookmarks => 'Buchmarken und Notizen';
	@override String get bookmark => 'Buchmarke hinzufügen';
	@override String get highlight => 'Markieren';
	@override String get note => 'Note zu';
	@override String get delete => 'Löschen';
	@override String get export => 'Export Notizen';
	@override String get exported => 'Notizen exportiert';
	@override String get sync => 'Synchronisierung Fortschritte';
	@override String get synced => 'Fortschritt synchronisiert';
	@override String get conflict => 'Ein anderes Gerät hat eine andere Position. wählen Sie, wo Sie weitergehen.';
	@override String get useLocal => 'Verwenden Sie dieses Gerät';
	@override String get useRemote => 'Andere Geräte verwenden';
	@override String get history => 'Position Geschichte';
	@override String get groupAudio => 'Lernen Sie als ein Audiobook';
	@override String get groupHint => 'Kombinieren Sie die Audio-Dateien, die derzeit in dieser Ordnung geladen sind.Laden Sie zuerst alle Seiten.';
	@override String get order => 'Datei Ordnung';
	@override String get moveUp => 'Bewegung auf';
	@override String get moveDown => 'Bewegung nach unten';
	@override String get speed => 'Spielback Geschwindigkeit';
	@override String get sleep => 'Schlaftimer';
	@override String get sleepOff => 'Aus';
	@override String get endChapter => 'Ende des Kapitels';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Minuten',
	);
	@override String get skipBack => 'Skip zurück';
	@override String get skipForward => 'Skip voran';
	@override String get smartRewind => 'Smart Revenge nach einer Pause';
	@override String get playbackOptions => 'Listen Optionen';
	@override String remaining({required Object time}) => '${time} übrig geblieben';
	@override String get contents => 'Inhalt';
	@override String get readerSettings => 'Lesen Settings';
	@override String get fontSize => 'Textgröße';
	@override String get lineHeight => 'Line Spaziergang';
	@override String get margin => 'Seitenränder';
	@override String get font => 'Typfass';
	@override String get serif => 'Seriö';
	@override String get sans => 'ohne Serien';
	@override String get mono => 'Monospaß';
	@override String get columns => 'Kolumne';
	@override String get scroll => 'Vertikal Scroll';
	@override String get justify => 'Text rechtfertigen';
	@override String get readerTheme => 'Seite Aussehen';
	@override String get appTheme => 'Folgen Sie dem App-Theme';
	@override String get paper => 'Papier';
	@override String get sepia => 'Sepia';
	@override String get night => 'Nacht';
	@override String get readAloud => 'Diese Seite vorlesen';
	@override String get readAlong => 'Lesen Sie weiter';
	@override String get stopReading => 'Stoppen Sie mit Narration';
	@override String get searchBook => 'Suche in Buch';
	@override String get noMatches => 'Keine Spiele';
	@override String get previousPage => 'Vorherige Seite';
	@override String get nextPage => 'Nächster Seite';
	@override String page({required Object number}) => 'Seite ${number}';
	@override String get externalBlocked => 'Externe Buchverbindungen sind im Leser deaktiviert.';
	@override String get loading => 'Öffnen...';
	@override String get narrator => 'Narrater';
	@override String get audio => 'Audio';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebooks';
	@override String get all => 'Alle';
	@override String get downloads => 'Offline Datei';
	@override String get confirmDelete => 'Entfernen Sie die ausgewählte Offline-Kopie? Ihre Position und Notizen bleiben.';
	@override String get errorAuthentication => 'Sign in erneut, um diese Quelle wieder zu verknüpfen.';
	@override String get errorPermission => 'Diese Quelle erteilt keinen Zugang zum angeforderten Datei.';
	@override String get errorUnavailable => 'Versuchen Sie erneut oder öffnen Sie eine Offline-Kopie.';
	@override String get errorUnsupported => 'Dieses Format oder die Verbindung wird auf diesem Gerät nicht unterstützt. prüfen Sie den Quellinstellungsguide.';
	@override String get errorInvalidData => 'Diese Datei oder Server-Reaktion kann nicht sicher gelesen werden.';
	@override String get errorCancelled => 'Die Operation wurde abgesagt.';
	@override String get errorConflict => 'Die Position wurde in einer anderen Sitzung geändert. Wieder öffnen Sie das Element, um eine Position auszuwählen.';
	@override String get signIn => 'Anmelden';
	@override String get reconnect => 'Erneut verbinden';
	@override String get folderHelp => 'Lassen Sie das Wurzeln auf dem Quellwurzel beginnen. URLs S3 enthalten das Bucket.';
	@override String get preferences => 'Vorlieben';
	@override String get timePosition => 'Position';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Untertitel Track';
	@override String get none => 'Keiner';
	@override String get fullscreen => 'Vollbildschirm';
	@override String get syncLocation => 'Progress Sync Folder (optional)';
	@override String get syncLocationHint => 'Eine dedizierte WebDAV Folder für PlezyNG Status. verwendet bedingte Schreiben; Medien bleiben unverändert.';
	@override String get audiobooks => 'Audiobücher';
	@override String get comics => 'Comics';
	@override String get scan => 'Scan für Bücher und Medien';
	@override String get browserReader => 'Öffnen Leser';
	@override String get browserReaderHelp => 'Der Leser ist in Ihrem Browser geöffnet.Halten Sie PlezyNG offen, um Ihre Platz und Notizen zu speichern.';
	@override String get on => 'auf';
	@override String get advancedSetup => 'App Registrierung';
	@override String get microsoftSignIn => 'Unterschreiben Sie sich mit Microsoft';
	@override String get zoomIn => 'Vergrößern';
	@override String get zoomOut => 'Zoom aus';
	@override String get fitPage => 'Fit Seite';
	@override String get fitWidth => 'Fit Breite';
	@override String get actualSize => 'Aktuelle Größe';
	@override String get goToPage => 'Gehen Sie zu Seite';
	@override String get goToSection => 'Gehen Sie zum Kapitel';
	@override String pageRange({required Object count}) => 'Einzahlung von 1 bis ${count}';
	@override String get pageLayout => 'Seite Layout';
	@override String get automatic => 'Automatisch';
	@override String get singlePage => 'Single Seite';
	@override String get twoPages => 'Zwei Seiten';
	@override String get readingDirection => 'Lesen Richtung';
	@override String get leftToRight => 'links nach rechts';
	@override String get rightToLeft => 'Von rechts nach links';
	@override String get letterSpacing => 'Brief Spazier';
	@override String get wordSpacing => 'Spazierend Wort';
	@override String get readerControlsHelp => 'Ziehe zwei Finger auseinander oder nutze die Zoom-Steuerung, um Seiten zu vergrößern. Ziehe die Seite, um sie zu verschieben. Ctrl/⌘ mit + oder − ändert den Zoom; Ctrl/⌘ mit 0 setzt ihn zurück. Page Up und Page Down blättern um.';
	@override String get imagePage => 'Comicseite';
	@override String get resetReader => 'Lesen Preferenzen wiederherstellen';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Dateien und Bücher verwenden';
	@override String get cancelScan => 'Scan abgeben';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Limit für Offline-Downloads';
	@override String get offlineQuotaHelp => 'Setzen Sie den maximalen Raum, der von Offline-Kopien, importierten Dateien und abgelaufenen Downloads verwendet wird. Die Reduzierung des Limites entfernt nicht bestehende Kopien.';
	@override String get offlineStorageUsage => 'Offline Lagerung';
	@override String get reservedStorage => 'reserviert';
	@override String get downloadQueue => 'Download von Queue';
	@override String get downloadRunning => 'Downloaden';
	@override String get downloadQueued => 'warten';
	@override String get downloadPaused => 'Pause';
	@override String get downloadFailed => 'Rückkehr benötigt';
	@override String get importing => 'Einfuhr';
	@override String get importInterrupted => 'Einfuhren unterbrochen · entfernen zu klären';
	@override String get errorQuotaExceeded => 'Die Offline Speichergrenze wurde erreicht. Erhöhen Sie die Grenze oder entfernen Sie eine heruntergeladenen Kopie.';
	@override String get errorStorageLow => 'Es gibt nicht genügend freie Geräte-Speicher, um die geschützte Reservierung zu halten.';
	@override String get errorStorageUnavailable => 'PlezyNG konnte die kostenlose Geräte-Speicher nicht überprüfen, so dass das Schreiben gestoppt wurde.';
	@override String get removeDownloadJob => 'Entfernen Download';
	@override String get downloadAlreadyComplete => 'Dieses Download ist fertig, bevor es entfernt werden kann. Das Element ist jetzt offline verfügbar.';
	@override String get confirmRemoveDownloadJob => 'Entfernen Sie diesen Download und löschen Sie alle teilweise heruntergeladenen Daten? Ihre Position und Notizen bleiben.';
}

// Path: lending
class _Translations$lending$de extends Translations$lending$en {
	_Translations$lending$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'öffentliche Bibliotheken';
	@override String get add => 'Ein Bücherei hinzufügen';
	@override String get other => 'Eine weitere Bibliothek';
	@override String get libraryName => 'Bibliothek Name';
	@override String get libraryUrl => 'Bibliothek Website';
	@override String get libraryUrlHint => 'Verwenden Sie den Katalog Ihrer Bibliothek oder die Sign-in-Seite.';
	@override String get intro => 'Lene deine Bibliothek, halten deine Bücher dicht.';
	@override String get handoff => 'Anmeldung, Darlehen und Lesen sicher mit der eigenen Bibliothek-Service.';
	@override String get openService => 'Öffnete Bibliothek';
	@override String get findLibrary => 'Suche eine Bibliothek';
	@override String get search => 'Suche nach Büchern und Autoren';
	@override String get catalogue => 'Katalog';
	@override String get loans => 'Darlehen';
	@override String get holds => 'Vormerkungen';
	@override String get signIn => 'Anmeldung mit Ihrer Bibliothek';
	@override String get waiting => 'Beenden Sie die Anmeldung in Ihrem Browser und dann zurück.';
	@override String get cancel => 'Abbrechen';
	@override String get disconnect => 'Bibliothek entfernen';
	@override String get disconnectMessage => 'Diese Bibliothek aus diesem Profil entfernen? Deine Ausleihen und Vormerkungen bleiben bei der Bibliothek erhalten.';
	@override String get getBook => 'Buch bekommen';
	@override String get checkAvailability => 'Überprüfen Sie Verfügbarkeit';
	@override String get available => 'zur Verfügung zum Darlehen';
	@override String get unavailable => 'Aktuell unzugänglich';
	@override String get borrow => 'Ausleihen';
	@override String get placeHold => 'Vormerken';
	@override String get returnBook => 'früh zurück';
	@override String get cancelHold => 'Vormerkung stornieren';
	@override String get confirmBorrow => 'Löhnen Sie diesen Titel aus Ihrer Bibliothek?';
	@override String get confirmReturn => 'Geben Sie diesen Titel jetzt zurück? Sie müssen es vielleicht erneut leihen, um weiterzuführen.';
	@override String get confirmCancelHold => 'Deine Vormerkung für diesen Titel stornieren?';
	@override String get email => 'E-Mail Nachricht halten';
	@override String due({required Object date}) => 'Die Anzahl ${date}';
	@override String queue({required Object position}) => 'Position ${position} in der Linie';
	@override String get empty => 'Keine Titel hier noch.';
	@override String get openLibraryNote => 'Entdecken Sie den Katalog der Open Library. Lesen und Darlehen Optionen sind auf der Seite jedes Titels angezeigt.';
	@override String get more => 'Laden Sie mehr';
	@override String get gateway => 'Bibliothek Sign-in Service';
	@override String get gatewayHint => 'Sie werden von Ihrer Bibliothek oder dem Administrator PlezyNG bereitgestellt.';
	@override String get advanced => 'Bibliothekintegration';
	@override String get loadLibraries => 'Wählen Sie Ihre Bibliothek';
	@override String get expired => 'Dieses Darlehen ist abgeschlossen.';
	@override String get updated => 'Bibliothek aktualisiert';
	@override String get continueService => 'Weiter in Service';
	@override String get comingSoon => 'In-app Darlehen · Kommen bald';
	@override String get comingSoonDescription => 'Sie können Ihre Bibliothek in Libby verwenden, während wir sie verbinden.';
	@override String get suspendHold => 'Halt aufhören';
	@override String get resumeHold => 'Resume halten';
	@override String get suspendMessage => 'Deinen Platz in der Warteschlange behalten und den nächsten Leser dieses Exemplar ausleihen lassen? Du kannst die Vormerkung später fortsetzen.';
	@override String get resumeMessage => 'Diese Vormerkung fortsetzen, damit dir die Bibliothek das nächste verfügbare Exemplar anbieten kann?';
	@override String get editEmail => 'Änderung der E-Mail-Nachricht';
}

// Path: audiobook
class _Translations$audiobook$de extends Translations$audiobook$en {
	_Translations$audiobook$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Lesen und Hören Sync';
	@override String get syncHelp => 'Halten Sie Lesungspositionen, Listenpositionen, Vollendungsstatus, Buchmarken und Notizen über Ihre Geräte. Wählen Sie ein angeschlossenes Speicherkonto und verwenden Sie den gleichen Sync-Code auf jedem Gerät. Lesen und Listen bleiben getrennt.';
	@override String get addSyncSource => 'Zunächst Google Drive, OneDrive, Dropbox, WebDAV oder S3 in Dateien und Bücher hinzufügen.';
	@override String get syncDestination => 'Sync Speicherkonto';
	@override String get syncFolder => 'Synchronisierung von Ordnern oder Prefix';
	@override String get syncFolderHelp => 'Verwenden Sie eine separate bestehende Ordner innerhalb Ihrer WebDAV-Quelle oder eine dedizierte S3 Vorwahl. Buchdateien werden nie geändert.';
	@override String get syncCode => 'Private Synchronisierungscode';
	@override String get syncCodeHelp => 'Erstellen Sie einen Code auf Ihrem ersten Gerät, dann geben Sie diesen Code auf Ihren anderen Geräten ein. Halten Sie eine private Kopie: Es ist der Schlüssel zu Ihrem verschlüsselten Zustand. Verwenden Sie für jede Person einen anderen Code.';
	@override String get showCode => 'Zeigen oder verstecken Sie Sync-Code';
	@override String get newSyncCode => 'Erstellen eines neuen Sync-Codes';
	@override String get saveSync => 'Speichern und synchronisieren';
	@override String get disableSync => 'Synchronisierung auf diesem Gerät deaktivieren';
	@override String get syncSourceDisconnect => 'Wenn Sie diese Quelle entfernen, wird das Lesen und Hören von Sync hier ausgeschaltet. Verschlüsselte Sync-Dateien bleiben im Anbieter.';
	@override String get syncReconnect => 'Wiederverbindung des Speicherkontoes';
	@override String lastSynced({required Object time}) => 'Letzte Synchronisierung bei ${time}';
	@override String get syncPrivacy => 'Nur verschlüsselte Fortschritte und Notizen werden gespeichert. Audio- und E-Book-Dateien, Konto-Token und Passwörter werden nicht hochgeladen. Google Drive und OneDrive verwenden App-Speicher; Dropbox verwendet PlezyNG Sync. Sync ermöglichen kann zusätzliche Schreibzugang verlangen. Während aktiviert, besitzt dieses Ziel Fortschritt Sync; Server Fortschritt bleibt getrennt. Sync-Off-Speicher hält die lokale Geschichte und Entfernung-Status.';
	@override String get syncConflicts => 'Wählen Sie, wo Sie wiederholen';
	@override String get conflictHelp => 'Diese Änderungen wurden unabhängig durchgeführt. Wählen Sie die Position oder Buchmarke Version zu halten. Eine spätere Timestamp oder ein höheres Prozentsatz gewinnt nicht automatisch.';
	@override String syncDevice({required Object device}) => 'Gerät ${device}';
	@override String get syncUnknownDevice => 'Unbekannte Geräte';
	@override String get deletedBookmark => 'Löschte Buchmarke';
	@override String get finished => 'abgeschlossen';
	@override String readingPosition({required Object percent}) => 'Lesen · ${percent}%';
	@override String get chapterTimeline => 'Kapitel Fortschritt';
	@override String get bookTimeline => 'Das ganze Buch Fortschritt';
	@override String bookRemaining({required Object time}) => 'Zeit bleibt in diesem Buch: ${time}';
	@override String chapterRemaining({required Object time}) => 'Zeit bleibt in diesem Kapitel: ${time}';
	@override String get unknownRemaining => 'Gesamtzeit verfügbar, da Teile gespielt werden';
	@override String get undoSeek => 'Undo letzte Suche';
	@override String get customSpeed => 'Custom Playback Geschwindigkeit';
	@override String get speedHelp => 'Wählen Sie eine Geschwindigkeit von 0,25× bis 4×.';
	@override String get apply => 'Anwendung';
	@override String get customSleep => 'Personalisierter Schlaf Timer';
	@override String get sleepMinutes => '1 Minute (1 bis 1440)';
	@override String sleepChapters({required Object count}) => 'Stopp nach ${count} Kapiteln';
	@override String get extendSleep => '5 Minuten hinzufügen';
	@override String sleepRemaining({required Object time}) => 'Schlaftimeter: ${time}';
	@override String get useDefaults => 'Verwenden Sie diese Hörkontrollen für neue Bücher';
	@override String get librarySort => 'Sorte Bücher';
	@override String get sortTitle => 'Titel';
	@override String get sortAuthor => 'Autorin';
	@override String get sortNarrator => 'Sprichwort';
	@override String get sortSeries => 'Serie Ordnung';
	@override String get sortRecent => 'kürzlich geöffnet';
	@override String get statusFilter => 'Status des Lesens';
	@override String get statusAll => 'Alle Bücher';
	@override String get statusNew => 'nicht begonnen';
	@override String get statusProgress => 'Im Fortschritt';
	@override String get statusFinished => 'abgeschlossen';
	@override String get goToTime => 'Gehen Sie zur Zeit';
	@override String get timeHelp => 'Stunden: Minuten: Sekunden oder Minuten: Sekunden';
	@override String get recoveryHelp => 'Exportieren Sie eine kürzlich verschlüsselte Kopie, bevor Sie Sync-Daten bewegen oder reparieren.Importe fusionieren mit dem aktuellen Zustand; sie ersetzen niemals die lokale Sync Geschichte.';
	@override String get recoveryExport => 'Export verschlüsselte Recovery Datei';
	@override String get recoveryImport => 'Import verschlüsselte Recovery-Datei';
	@override String get recoveryImportConfirm => 'Kombinieren Sie diese verschlüsselte Recovery-Datei mit aktuellen Lesepositionen und Notizen? bestehende Geschichte wird beibehalten. gemeinsame Bibliothek und Element-IDs sind nicht enthalten; Set matching IDs on each device before importing.';
	@override String get recoveryExported => 'Verschlüsselte Recovery-Datei wurde gespeichert.';
	@override String get recoveryImported => 'Wiederherstellungsdaten sind zusammengefasst.';
}

// Path: sourceSetup
class _Translations$sourceSetup$de extends Translations$sourceSetup$en {
	_Translations$sourceSetup$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Gespeichertes Serverzertifikat';
	@override String get nfsEndpointInvalid => 'Gib eine NFS-URL wie nfs://nas:2049/export ein.';
	@override String get dlnaNone => 'Keine DLNA-Server gefunden. Gib die URL der Gerätebeschreibung manuell ein.';
	@override String get dlnaServers => 'DLNA-Medienserver';
	@override String get dlnaUnavailable => 'Die DLNA-Suche ist in diesem Netzwerk nicht verfügbar. Gib die URL der Gerätebeschreibung manuell ein.';
	@override String get dlnaSearching => 'Lokales Netzwerk wird nach DLNA-Servern durchsucht';
	@override String get networkSearching => 'Lokales Netzwerk wird durchsucht…';
	@override String get dlnaDiscover => 'DLNA-Server finden';
	@override String get dlnaHelp => 'Die Suche benötigt Multicast im lokalen Netzwerk. Falls kein Server erscheint, gib oben die URL seiner Gerätebeschreibung ein.';
	@override String get dlnaRoot => 'DLNA-Objekt-ID; leer lassen, um das Stammverzeichnis des Geräts zu verwenden.';
	@override String get passwordOrKey => 'Gib ein Passwort ein oder füge unten einen privaten Schlüssel hinzu.';
	@override String get sshFingerprint => 'SHA256-Fingerabdruck des SSH-Hostschlüssels';
	@override String get sshFingerprintHelp => 'Prüfe ihn mit dem Serveradministrator. Führe auf dem Server ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub aus und verwende den SHA256-Wert.';
	@override String get sshFingerprintKeep => 'Leer lassen, um den aktuell festgelegten Fingerabdruck beizubehalten, oder einen neuen Serverfingerabdruck eingeben.';
	@override String get sshAuthentication => 'SSH-Authentifizierung mit öffentlichem Schlüssel';
	@override String get sshAuthenticationHelp => 'Optional; die Authentifizierung mit Passwort wird ebenfalls unterstützt.';
	@override String get privateKey => 'Privater Schlüssel (PEM- oder OpenSSH-Format)';
	@override String get privateKeyPassphrase => 'Passphrase des privaten Schlüssels';
	@override String get nfsMountPort => 'TCP-Port des NFS-Mount-Dienstes';
	@override String get nfsMountPortHelp => 'Standard: 20048';
	@override String get nfsUserId => 'NFS-Benutzer-ID (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Standard: 1000. Verwende die ID, die die NFS-Freigabe des NAS erlaubt.';
	@override String get nfsGroupId => 'NFS-Gruppen-ID (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Standard: 1000. Verwende die Gruppen-ID, die die NFS-Freigabe des NAS erlaubt.';
	@override String get nfsEncryption => 'Verschlüsseltes NFS verlangen (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'TLS 1.3 für NFS und den Mount-Dienst verlangen. Unterstützt das NAS dies nicht, wird die Verbindung abgelehnt.';
	@override String get nfsTrustCertificate => 'Benutzerdefinierte NFS-CA oder Serverzertifikat (PEM, optional)';
	@override String get nfsTrustHelp => 'Leer lassen, um Zertifikate zu verwenden, denen dieses Gerät vertraut. Füge bei Bedarf ein Zertifikat einer privaten CA oder ein selbstsigniertes Serverzertifikat hinzu; dessen Namen müssen zum Host der NFS-URL passen.';
	@override String get nfsTrustInvalid => 'Verwende ein CA- oder Serverzertifikat im PEM-Format. Füge keinen privaten Schlüssel ein.';
	@override String get addTrustCertificate => 'Benutzerdefiniertes Vertrauenszertifikat hinzufügen';
	@override String get replaceTrustCertificate => 'Gespeichertes benutzerdefiniertes Zertifikat ersetzen';
	@override String get nfsTlsHelp => 'RPC-with-TLS verwendet die üblichen NFS- und Mount-Dienst-Ports und benötigt RFC 9289-Unterstützung auf dem NAS. TLS 1.3 ist erforderlich. Hostname oder IP-Adresse müssen zum Zertifikat passen. AUTH_SYS-UID/GID gelten auch im verschlüsselten Kanal.';
	@override String get clientCertificate => 'Clientzertifikat (optional)';
	@override String get clientCertificateHelp => 'Damit kann das NAS diesen Client authentifizieren; AUTH_SYS-IDs unterliegen weiterhin den Regeln der NFS-Freigabe des NAS.';
	@override String get savedIdentity => 'Eine gespeicherte Clientidentität wird verwendet.';
	@override String get replaceIdentity => 'Gespeicherte Clientidentität ersetzen';
	@override String get chooseIdentity => 'PKCS#12-Clientidentität auswählen';
	@override String get identityPassphrase => 'Passphrase der Clientidentität';
	@override String get identityPassphraseHelp => 'Leer lassen, wenn die Datei keine Passphrase hat.';
	@override String get removeIdentity => 'Gespeicherte Clientidentität entfernen';
	@override String get identityStorageHelp => 'Clientidentitäten werden im verschlüsselten Zugangsdaten-Speicher der Quelle abgelegt. Lass diesen Abschnitt unverändert, um die gespeicherte Identität beizubehalten.';
	@override String get nfsLimitations => 'NFSv3 über TCP, nur lesend. Ohne RPC-with-TLS ist der NFS-Verkehr unverschlüsselt. Das NAS muss die gewählten AUTH_SYS-IDs und unprivilegierte Clientports zulassen (oft als Exportoption „insecure“ bezeichnet). NFSv4 und UDP werden nicht unterstützt.';
	@override String get nfsSetupHelp => 'Hilfe zur NFS-Einrichtung';
	@override String get nfsSetupHint => 'Prüfe diese Einstellungen, wenn die Verbindung nicht zustande kommt.';
	@override String get nfsSetupDetails => 'Verwende eine NFSv3-Freigabe über TCP. Wenn Verschlüsselung verlangt wird, müssen der NFS- und der Mount-Dienst beide RPC-with-TLS unterstützen. Lass das benutzerdefinierte Zertifikat leer, um ein Serverzertifikat zu verwenden, dem dieses Gerät vertraut, oder füge das CA- bzw. selbstsignierte Zertifikat des NAS hinzu. Der Zertifikatsname muss zum Host des Endpunkts passen. Verlangt das NAS gegenseitiges TLS, füge seine PKCS#12-Clientidentität hinzu. Prüfe abschließend, dass die Freigabe die eingestellten AUTH_SYS-UID/GID und die Clientport-Regeln zulässt.';
	@override String get ftpHelp => 'FTP verwendet den passiven Modus. Nutze ftp:// für unverschlüsseltes FTP, ftpes:// für explizites TLS oder ftps:// für TLS (implizit auf Port 990, explizit auf anderen Ports).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Optionale Untertitelsuche für eigenständige Videos.';
	@override String get apiKey => 'API-Schlüssel';
	@override String get optionalUsername => 'Benutzername des Kontos (optional)';
	@override String get optionalPassword => 'Passwort des Kontos (optional)';
	@override String get subtitlePrivacy => 'Hole dir einen API-Schlüssel von opensubtitles.com. Die Suche sendet den Videotitel und verfügbare IMDb/TMDB-IDs, niemals die Videodatei. Der Schlüssel und optionale Kontozugangsdaten werden zusammen mit dieser Quelle verschlüsselt.';
	@override String get automaticMetadata => 'Automatische Online-Videometadaten';
	@override String get metadataPrivacy => 'Sendet nur Titel/Jahr aus dem Dateinamen und Episodennummern oder eine NFO-ID, niemals Medien oder Zugangsdaten. NFO-Felder behalten Vorrang.';
	@override String get nfsEncryptionFailure => 'Prüfe für verschlüsseltes NFS die Unterstützung von RFC 9289 und TLS 1.3 bei beiden NAS-Diensten, den Zertifikatsnamen und die UID/GID der Freigabe. PlezyNG wird diese Verbindung nicht ohne Verschlüsselung erneut versuchen.';
	@override String get sourceConnecting => 'Verbindung zur Quelle wird hergestellt';
	@override String get metadataSearchPrivacy => 'Diese Titelsuche wird an Trakt gesendet. Übermittelt wird der eingegebene Titel, nicht das Video oder die Zugangsdaten der Quelle.';
	@override String get chooseMatch => 'Treffer auswählen';
	@override String get metadataMatchHelp => 'Prüfe Titel und Jahr vor der Auswahl. Trakt erhält den Suchbegriff; das Video bleibt auf seiner Quelle.';
	@override String get metadataNoMatches => 'Keine passenden Titel online gefunden. Probiere einen anderen Titel.';
	@override String get metadataSearch => 'Online-Metadaten suchen';
	@override String get metadataLoading => 'Online-Details zu Filmen und Serien werden gesucht…';
	@override String get metadataFromTrakt => 'Online-Metadaten von Trakt';
	@override String get metadataNoAutomaticMatch => 'Kein automatischer Titeltreffer gefunden. Suche nach dem Titel, um einen Treffer auszuwählen.';
	@override String get metadataFailed => 'Online-Metadaten konnten nicht geladen werden. Wiedergabe und lokale Details sind weiterhin verfügbar.';
	@override String get videoDetailsLoading => 'Videodetails werden geladen';
	@override String get subtitleKeyRequired => 'OpenSubtitles-API-Schlüssel erforderlich';
	@override String get subtitleKeyHelp => 'Bearbeite diese Dateiquelle und füge in ihren optionalen Untertiteleinstellungen einen OpenSubtitles-API-Schlüssel hinzu.';
	@override String get subtitleSearchFailed => 'Untertitelsuche fehlgeschlagen. Prüfe API-Schlüssel, Verbindung und Dienstzugriff.';
	@override String get subtitleApplyFailed => 'Dieser Untertitel konnte nicht heruntergeladen oder angewendet werden. Prüfe deine Verbindung und versuche ein anderes Ergebnis.';
	@override String get subtitleSearch => 'OpenSubtitles durchsuchen';
	@override String get subtitleSearchPrivacy => 'Die Suche verwendet den Titel und verfügbare IMDb/TMDB-IDs. Die Videodatei bleibt auf ihrer Quelle. Prüfe vor der Auswahl Sprache, Kennzeichnungen für erzwungene oder hörgeschädigtengerechte Untertitel sowie die Bewertung.';
	@override String get movieOrShow => 'Film oder Serie';
	@override String get subtitleTitleHint => 'Titel eingeben, um die Ergebnisse einzugrenzen';
	@override String get subtitleLanguage => 'Untertitelsprache';
	@override String get subtitleSearching => 'OpenSubtitles wird durchsucht';
	@override String get subtitleNoMatches => 'Keine passenden Untertitel gefunden. Probiere einen anderen Titel oder eine andere Sprache.';
	@override String get downloadSubtitle => 'Untertitel herunterladen';
	@override String get subtitle => 'Untertitel';
	@override String get nfsTlsRequired => 'RPC-with-TLS erforderlich';
	@override String get nfsUnencrypted => 'Unverschlüsseltes NFS';
	@override String get tlsEncrypted => 'TLS-verschlüsselt';
	@override String get ftpPlain => 'Unverschlüsseltes FTP';
	@override String get sshPinned => 'SSH-verschlüsselt · Hostschlüssel festgelegt';
	@override String get smbEncrypted => 'SMB3-Verschlüsselung an';
	@override String get smbUnencrypted => 'SMB3-Verschlüsselung aus';
	@override String get httpUnencrypted => 'HTTP ohne Transportverschlüsselung';
	@override String get checkEndpointSecurity => 'Sicherheit des Endpunkts prüfen';
	@override String fieldRequired({required Object label}) => '${label} ist erforderlich.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Gib ${label} von ${min} bis ${max} ein.';
	@override String replaceFile({required Object name}) => '${name} ersetzen';
	@override String selectedIdentity({required Object name}) => 'Ausgewählte Clientidentität: ${name}';
	@override String subtitleRating({required Object rating}) => 'Bewertung ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Untertitel wird heruntergeladen: ${title}';
	@override String get sharedEntryPair => 'Paar dieses Element';
	@override String get sharedEntryPairHelp => 'Geben Sie das gleiche ID für dieses Element auf jedem Gerät ein. Verwenden Sie einen stabilen geteilten Identifikator oder generieren Sie einen und kopieren Sie es zu dem matching item. Progress Pairs nur, wenn die Edition-Datei Typen, Größen und Ordnungen entsprechen. Blank entfernt diese Karte.';
	@override String get sharedEntryId => 'Teilen von Element ID';
	@override String get generateSharedEntryId => 'Erzeugen von gemeinsamen Element-ID';
	@override String get sharedLibraryId => 'Gemeinsame Bibliothek-ID (optional)';
	@override String get sharedLibraryHelp => 'Verwenden Sie das gleiche ID auf Geräten, die die gleiche Bibliothek öffnen. Dieses öffentliche ID hilft, den Leseprogramm und Notizen über verschiedene Quellverbindungen zu führen; es ist kein Passwort. Wenn Anbieter unterschiedliche Element-IDs verwenden, Paare diese Elemente aus ihren Detailbildschirmen.';
	@override String get sharedLibraryInvalid => 'Verwenden Sie 8 bis 100 Buchstaben, Zahlen, Punkte, Unterschriften oder Hyphen.';
	@override String get generateSharedLibraryId => 'Erstellen eines gemeinsamen Bibliothek-ID';
	@override String get nfsReadAhead => 'NFS Read-ahead Anträge';
	@override String get nfsReadAheadHelp => 'Mehr parallele Lesen kann den Durchgang auf einem schnellen NAS oder Netzwerk verbessern. Verwenden Sie 1 wenn der Server die gleichzeitigen Anfragen beschränkt.';
	@override String get nfsReadTest => 'Messung NFS Lesenleistungen';
	@override String get nfsReadTestHelp => 'Es liest bis zu 64 MiB von der größten Datei, um diese NAS-Verbindung zu messen.';
	@override String get nfsQualificationResult => 'NFS Lesen Messungen';
	@override String get nfsReadBytes => 'Daten lesen';
	@override String get nfsReadSpeed => 'Messung der Geschwindigkeit';
	@override String get nfsReadRequests => 'Lesen Sie Anfragen';
	@override String get sharedEntryConflict => 'Dieses geteilte Element-ID wird bereits mit einem anderen Element in dieser Bibliothek vereinigt.';
}

// Path: comics
class _Translations$comics$de extends Translations$comics$en {
	_Translations$comics$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'An Höhe anpassen';
	@override String get readingMode => 'Lesemodus';
	@override String get paged => 'Seiten';
	@override String get webtoon => 'Fortlaufendes Scrollen';
	@override String get coverAlone => 'Cover einzeln anzeigen';
	@override String get splitWide => 'Breite Seiten teilen';
	@override String get splitWideHelp => 'Zeigt jede Hälfte einzeln in Leserichtung an. Solange dies aktiviert ist, werden Seiten nicht als Doppelseiten angezeigt.';
	@override String get thumbnails => 'Seitenvorschauen';
	@override String get controlsHelp => 'Zum Umblättern wischen. Doppeltippen ändert die Anpassung. Beim fortlaufenden Scrollen senkrecht wischen oder Bild auf und Bild ab verwenden.';
	@override String get savedForComic => 'Die Anzeigeeinstellungen werden für diesen Comic in diesem Profil gespeichert.';
	@override String get readLists => 'Leselisten';
	@override String get collections => 'Sammlungen';
}

// Path: games
class _Translations$games$de extends Translations$games$en {
	_Translations$games$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$deepLinks$de extends Translations$deepLinks$en {
	_Translations$deepLinks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Dieser Plezy Link ist nicht gültig.';
	@override String profileNotFound({required Object profile}) => 'Kein Profil entspricht „${profile}“.';
	@override String get serverUnavailable => 'Ich konnte den Server für diesen Link nicht erreichen.';
	@override String get notFound => 'Ich konnte diesen Titel nicht in deinen Bibliotheken finden.';
	@override String get unsupportedItem => 'Dieser Link kann nicht gespielt werden.';
	@override String get noLiveTv => 'Kein Live TV-Server ist für diesen Link verfügbar.';
	@override String channelNotFound({required Object channel}) => 'Ich konnte kein Kanal "${channel}" finden.';
	@override String get showLink => 'zeigen Link';
	@override String get showProfileLink => 'Profil Link anzeigen';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Beim Öffnen dieses Links wird die nächste Folge abgespielt. Fügen Sie am Ende &mode=shuffle hinzu, um die Serie in zufälliger Reihenfolge abzuspielen.';
	@override String get movieHint => 'Der Link öffnet den Film.';
	@override String get episodeHint => 'Das Öffnen dieser Link spielt diese Episode.';
	@override String get profileHint => 'Öffnen dieser Link Switches zu diesem Profil.';
	@override String openAsProfile({required Object name}) => 'Öffnen Sie als ${name}';
	@override String get copy => 'Kopieren';
	@override String get copied => 'Link kopiert';
}

// Path: appIcon.names
class _Translations$appIcon$names$de extends Translations$appIcon$names$en {
	_Translations$appIcon$names$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Mitternacht';
	@override String get ember => 'Glut';
	@override String get paper => 'Papier';
	@override String get oled => 'OLED';
	@override String get line => 'Linie';
	@override String get ocean => 'Ozean';
	@override String get ultraviolet => 'Ultraviolett';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Abendrot';
	@override String get gold => 'Gold';
	@override String get titanium => 'Titan';
	@override String get glass => 'Glas';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Sticker';
	@override String get ticket => 'Ticket';
	@override String get pop => 'Pop';
	@override String get strata => 'Schichten';
	@override String get facet => 'Facette';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$de extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$common$mediaKind$de extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get show => 'Serie';
	@override String get season => 'Staffel';
	@override String get episode => 'Episode';
	@override String get artist => 'Interpret';
	@override String get album => 'Album';
	@override String get track => 'Titel';
	@override String get collection => 'Sammlung';
	@override String get playlist => 'Wiedergabeliste';
	@override String get clip => 'Clip';
	@override String get photo => 'Foto';
	@override String get folder => 'Ordner';
}

// Path: settings.startupSectionOptions
class _Translations$settings$startupSectionOptions$de extends Translations$settings$startupSectionOptions$en {
	_Translations$settings$startupSectionOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Öffnen Sie Empfehlungen und Artikel aus verbundenen Entdeckungsquellen.';
	@override String get libraries => 'Öffnen Sie Ihre verbundenen Medienbibliotheken.';
	@override String get liveTv => 'Öffnen Sie Live TV, wenn ein Server es bereitstellt; sonst fällt das Startup zurück zu Home.';
	@override String get search => 'Öffnen Medien suchen.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$de extends Translations$themeEditor$slots$en {
	_Translations$themeEditor$slots$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Hintergrund';
	@override String get surface => 'Oberfläche';
	@override String get outline => 'Kontur';
	@override String get text => 'Text';
	@override String get textMuted => 'Sekundärtext';
	@override String get accent => 'Akzent';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$de extends Translations$themeEditor$contrast$en {
	_Translations$themeEditor$contrast$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Text auf Hintergrund';
	@override String get textOnSurface => 'Text auf Oberfläche';
	@override String get textMutedOnBg => 'Sekundärtext auf Hintergrund';
	@override String get textMutedOnSurface => 'Sekundärtext auf Oberfläche';
	@override String get accentOnBg => 'Akzent auf Hintergrund';
	@override String get accentOnSurface => 'Akzent auf Oberfläche';
	@override String get labelOnAccent => 'Schaltflächentext auf Akzent';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$de extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Wiedergabe/Pause';
	@override String get volumeUp => 'Lauter';
	@override String get volumeDown => 'Leiser';
	@override String seekForward({required Object seconds}) => 'Vorspulen (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Zurückspulen (${seconds}s)';
	@override String get fullscreenToggle => 'Vollbild umschalten';
	@override String get muteToggle => 'Stumm umschalten';
	@override String get subtitleToggle => 'Untertitel umschalten';
	@override String get audioTrackNext => 'Nächste Audiospur';
	@override String get subtitleTrackNext => 'Nächste Untertitelspur';
	@override String get chapterNext => 'Nächstes Kapitel';
	@override String get chapterPrevious => 'Vorheriges Kapitel';
	@override String get episodeNext => 'Nächste Episode';
	@override String get episodePrevious => 'Vorherige Episode';
	@override String get speedIncrease => 'Geschwindigkeit erhöhen';
	@override String get speedDecrease => 'Geschwindigkeit verringern';
	@override String get speedReset => 'Geschwindigkeit zurücksetzen';
	@override String get zoomIn => 'Vergrößern';
	@override String get zoomOut => 'Verkleinern';
	@override String get zoomReset => 'Zoom zurücksetzen';
	@override String get subSeekNext => 'Zum nächsten Untertitel springen';
	@override String get subSeekPrev => 'Zum vorherigen Untertitel springen';
	@override String get subtitleDelayIncrease => 'Untertitel verzögern';
	@override String get subtitleDelayDecrease => 'Untertitel vorziehen';
	@override String get shaderToggle => 'Shader umschalten';
	@override String get skipMarker => 'Intro/Abspann überspringen';
	@override String get screenshot => 'Screenshot aufnehmen';
	@override String get framePrevious => 'Vorheriger Frame';
	@override String get frameNext => 'Nächstes Frame';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$de extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Erfordert Android 8.0 oder neuer';
	@override String get iosVersion => 'Erfordert iOS 15.0 oder neuer';
	@override String get permissionDisabled => 'Bild-in-Bild ist deaktiviert. Aktiviere es in den Systemeinstellungen.';
	@override String get notSupported => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht';
	@override String get voSwitchFailed => 'Videoausgabe für Bild-in-Bild konnte nicht umgeschaltet werden';
	@override String get failed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override String get prepareFailed => 'Bild-in-Bild konnte nicht vorbereitet werden';
	@override String unknown({required Object error}) => 'Ein Fehler ist aufgetreten: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class _Translations$subtitlingStyling$assOverrideOptions$de extends Translations$subtitlingStyling$assOverrideOptions$en {
	_Translations$subtitlingStyling$assOverrideOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get no => 'Halten Sie die Buchstaben, Farben, Größen und Platzierung in der Subtitle-Datei geschrieben.';
	@override String get yes => 'Erlauben Sie, dass die Subtitle-Stil-Einstellungen des Spielers ASS-Subtitles anpassen.';
	@override String get scale => 'Anwenden Sie Player-Stiling und Skala eingebettete Größen, um die Video Dimensionen zu entsprechen.';
	@override String get force => 'Ersetzen Sie die eingebauten ASS-Style mit dem Subtitle-Stil des Spielers.';
	@override String get strip => 'Entfernen Sie das eingebettete ASS-Format und machen Sie den Untertiteltext klar.';
}

// Path: subtitlingStyling.renderResolutionOptions
class _Translations$subtitlingStyling$renderResolutionOptions$de extends Translations$subtitlingStyling$renderResolutionOptions$en {
	_Translations$subtitlingStyling$renderResolutionOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render auf der vollständigen Displayoberflächenlösung für das scharfe Ergebnis.';
	@override String get video => 'Render verwendet die Video-Resolution als Referenz, die Arbeit auf High-Resolution-Displays reduzieren kann.';
	@override String get threeQuarter => 'Render auf 75% der Displayoberflächenlösung für eine bescheidenen Leistungsbesparung.';
	@override String get half => 'Render auf 50% der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit weicheren Wänden.';
	@override String get third => 'Render auf ein Drittel der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit weicheren Randen.';
	@override String get quarter => 'Render auf ein Viertel der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit dem weichsten Ergebnis.';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$de extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio & Untertitel';
	@override String get libraryDisplay => 'Mediathek';
	@override String get personalMedia => 'Persönliche Medien';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$de extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get none => 'Manuell ausgewählt';
	@override String get noneDescription => 'Untertitel niemals von selbst einschalten.';
	@override String get defaultMode => 'Spurmarkierungen folgen';
	@override String get defaultModeDescription => 'Die Standard- und Erzwungen-Markierungen jeder Untertitelspur verwenden.';
	@override String get always => 'Immer aktiviert';
	@override String get alwaysDescription => 'Eine Untertitelspur in der bevorzugten Sprache einschalten, sofern eine vorhanden ist.';
	@override String get onlyForced => 'Nur erzwungene Untertitel';
	@override String get onlyForcedDescription => 'Nur die als erzwungen markierten Spuren laden.';
	@override String get smart => 'Bei fremdsprachigem Audio anzeigen';
	@override String get smartDescription => 'Untertitel nur einschalten, wenn das Audio in einer anderen Sprache ist.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$de extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Nicht-SDH-Untertitel bevorzugen';
	@override String get preferSdh => 'SDH-Untertitel bevorzugen';
	@override String get onlySdh => 'Nur SDH-Untertitel';
	@override String get onlyNonSdh => 'Nur Nicht-SDH-Untertitel';
	@override String get preferNonSdhDescription => 'Standard-Subtitles bevorzugen, wenn sowohl Standard- als auch SDH-Versionen verfügbar sind.';
	@override String get preferSdhDescription => 'Sie bevorzugen SDH-Subtitles, wenn sie verfügbar sind, aber ermöglichen standardische Subtitles als Fallback.';
	@override String get onlySdhDescription => 'Verwenden Sie SDH-Subtitles nur; fallen Sie nicht zurück zu standard Subtitles.';
	@override String get onlyNonSdhDescription => 'Verwenden Sie nur standardisierte Untertitel; SDH-Subtitel ausgeschlossen.';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$de extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Nicht erzwungene Untertitel bevorzugen';
	@override String get preferForced => 'Erzwungene Untertitel bevorzugen';
	@override String get onlyForced => 'Nur erzwungene Untertitel';
	@override String get onlyNonForced => 'Nur nicht erzwungene Untertitel';
	@override String get preferNonForcedDescription => 'Sie bevorzugen regelmäßige Untertitel, aber erlauben zwingende Spuren als Fallback.';
	@override String get preferForcedDescription => 'Sie bevorzugen zwingende Spuren, wenn sie verfügbar sind, aber erlauben regelmäßige Untertitel als Fallback.';
	@override String get onlyForcedDescription => 'Verwenden Sie nur Spuren, die als gezwungen markiert sind.';
	@override String get onlyNonForcedDescription => 'Ausnahme von Spuren, die als gezwungen markiert werden.';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$de extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nie';
	@override String get moviesAndShows => 'Filme und Serien';
	@override String get movies => 'Nur Filme';
	@override String get shows => 'Nur Serien';
	@override String get noneDescription => 'Zeigen Sie nicht beobachtete Checkmarken an.';
	@override String get moviesAndShowsDescription => 'Show watched checkmarks für Filme und TV-Shows.';
	@override String get moviesDescription => 'Show watched checkmarks only für Filme.';
	@override String get showsDescription => 'Show watched checkmarks for TV shows nur.';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$de extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Benutzer und Kritiker';
	@override String get usersOnly => 'Nur Benutzer';
	@override String get criticsOnly => 'Nur Kritiker';
	@override String get nobody => 'Ausgeblendet';
	@override String get usersAndCriticsDescription => 'Zeigen Sie sowohl Benutzerbewertungen als auch kritische Bewertungen.';
	@override String get usersOnlyDescription => 'Zeigen Sie Ratings und Bewertungen, die von Nutzern vorgelegt wurden.';
	@override String get criticsOnlyDescription => 'Zeigen Sie kritische Ratings und Bewertungen an.';
	@override String get nobodyDescription => 'Verbergen Sie Ratings und Bewertungen.';
}

// Path: discover.findNext
class _Translations$discover$findNext$de extends Translations$discover$findNext$en {
	_Translations$discover$findNext$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Finde deinen nächsten Favoriten';
	@override String get open => 'Finde deinen nächsten Favoriten';
	@override String get anyTime => 'Beliebige Dauer';
	@override String get timeAvailable => 'Wie viel Zeit hast du?';
	@override String get filters => 'Passend für deinen Moment';
	@override String get watch => 'Ansehen';
	@override String get listen => 'Anhören';
	@override String get read => 'Lesen';
	@override String finishable({required Object duration}) => 'In ${duration} zu schaffen';
	@override String aboutDuration({required Object duration}) => 'Etwa ${duration}';
	@override String nextUnit({required Object duration}) => 'Nächstes Kapitel · ${duration}';
	@override String totalDuration({required Object duration}) => 'Insgesamt ${duration}';
	@override String get timingVaries => 'Dauer kann variieren';
	@override String get notNow => 'Jetzt nicht';
	@override String get swipeHint => 'Wische das Cover in Pfeilrichtung oder nutze die Schaltflächen darunter.';
	@override String get saved => 'Gespeicherte Vorschläge';
	@override String savedCount({required Object count}) => 'Gespeicherte Vorschläge · ${count}';
	@override String get undo => 'Rückgängig';
	@override String get details => 'Details';
	@override String get noPicks => 'Noch nichts zur Auswahl';
	@override String get noPicksHint => 'Verbinde eine Bibliothek oder füge eine Medienquelle hinzu, um loszulegen.';
	@override String get noMatches => 'Nichts passt gerade';
	@override String get noMatchesHint => 'Probiere eine andere Medienart oder nimm dir etwas mehr Zeit.';
	@override String get allDone => 'Du hast alle Vorschläge gesehen';
	@override String get allDoneHint => 'Starte eine neue Auswahl, um diese Vorschläge noch einmal zu sehen.';
	@override String get refresh => 'Andere Auswahl finden';
	@override String sourceReason({required Object source}) => 'Aus ${source}';
	@override String libraryReason({required Object library}) => 'Aus ${library}';
	@override String get ownedReason => 'Aus deiner Bibliothek';
	@override String get liveNow => 'Läuft gerade';
	@override String get watchLive => 'Live ansehen';
	@override String get filterAnything => 'Alles';
	@override String get filterWatch => 'Ansehen';
	@override String get filterListen => 'Anhören';
	@override String get filterRead => 'Lesen';
	@override String get twentyMinutes => '20 Min.';
	@override String get fortyFiveMinutes => '45 Min.';
	@override String get ninetyMinutes => '90 Min.';
	@override String get apply => 'Anwenden';
	@override String get openFailed => 'Diese Auswahl ist nicht mehr verfügbar. Aktualisiere, um erneut nachzusehen.';
	@override String get changeFailed => 'Die Änderung konnte nicht gespeichert werden. Versuche es erneut.';
	@override String get savedLimit => 'Die Liste gespeicherter Vorschläge ist voll. Entferne einen Vorschlag, um einen weiteren zu speichern.';
	@override String get chooseHint => 'Öffne einen Vorschlag, speichere ihn für später oder überspringe ihn.';
	@override String get howItWorks => 'So funktioniert’s';
	@override String get notNowHelp => 'Überspringe diesen Vorschlag vorerst. Er bleibt in deiner Mediathek.';
	@override String get saveHelp => 'Speichere ihn unter „Gespeicherte Vorschläge“ für dieses Profil auf diesem Gerät. Dabei wird nichts heruntergeladen.';
	@override String get openHelp => 'Wähle das Cover für Details. Mit der Hauptaktion kannst du den Titel abspielen, lesen oder öffnen.';
	@override String get controlsHelp => 'Tastatur oder Fernbedienung: Wähle eine Schaltfläche und drücke Enter oder die Auswahltaste. Rückgängig stellt deine letzte Auswahl wieder her.';
	@override String get artworkLoading => 'Cover wird geladen…';
	@override String get artworkUnavailable => 'Cover nicht verfügbar';
	@override String get savedFeedback => 'Zu den gespeicherten Vorschlägen hinzugefügt';
	@override String get skippedFeedback => 'Vorerst übersprungen';
	@override String get releaseToConfirm => 'Zum Bestätigen loslassen';
	@override String get remoteHint => 'Cover im Fokus: ← / → wählen · Auswahltaste: Details · ↑ / ↓: Fokus bewegen';
}

// Path: discover.person
class _Translations$discover$person$de extends Translations$discover$person$en {
	_Translations$discover$person$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get born => 'Geboren';
	@override String get died => 'Gestorben';
	@override String get birthplace => 'Geburtsort';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} Jahre)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (im Alter von ${age} Jahren)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$de extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Empfohlen';
	@override String get browse => 'Durchsuchen';
	@override String get collections => 'Sammlungen';
	@override String get playlists => 'Wiedergabelisten';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$de extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppierung';
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get seasons => 'Staffeln';
	@override String get episodes => 'Episoden';
	@override String get artists => 'Interpreten';
	@override String get albums => 'Alben';
	@override String get tracks => 'Titel';
	@override String get folders => 'Ordner';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$de extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genre';
	@override String get year => 'Jahr';
	@override String get contentRating => 'Altersfreigabe';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Ungesehene';
	@override String get unplayed => 'Nicht abgespielt';
	@override String get favorites => 'Favoriten';
	@override String get filePath => 'Dateipfad';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$de extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get dateAdded => 'Hinzugefügt am';
	@override String get releaseDate => 'Erscheinungsdatum';
	@override String get rating => 'Bewertung';
	@override String get communityRating => 'Communitybewertung';
	@override String get criticRating => 'Kritikerbewertung';
	@override String get userRating => 'Benutzerbewertung';
	@override String get datePlayed => 'Wiedergabedatum';
	@override String get playCount => 'Wiedergaben';
	@override String get productionYear => 'Produktionsjahr';
	@override String get runtime => 'Laufzeit';
	@override String get officialRating => 'Offizielle Bewertung';
	@override String get premiereDate => 'Veröffentlichungsdatum';
	@override String get startDate => 'Startdatum';
	@override String get airTime => 'Sendezeit';
	@override String get studio => 'Studio';
	@override String get random => 'Zufällig';
	@override String get dateShared => 'Datum geteilt';
	@override String get latestEpisodeAirDate => 'Ausstrahlungsdatum der neuesten Folge';
	@override String get lastEpisodeDateAdded => 'Hinzugefügt am (neueste Folge)';
	@override String get dateDownloaded => 'Heruntergeladen am';
	@override String get size => 'Größe';
	@override String get library => 'Mediathek';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$de extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get include => 'Einschließen';
	@override String get exclude => 'Ausschließen';
	@override String get any => 'Beliebig';
	@override String get yes => 'Ja';
	@override String get no => 'Nein';
	@override String not({required Object value}) => 'Nicht ${value}';
	@override String valueCount({required Object count}) => '${count} ausgewählt';
	@override String valueCountExcluded({required Object count}) => '${count} ausgeschlossen';
	@override String get searchValues => 'Werte suchen';
	@override String get noValues => 'Keine Werte';
	@override String get matchContains => 'Enthält';
	@override String get matchNotContains => 'Enthält nicht';
	@override String get matchIs => 'Ist';
	@override String get matchIsNot => 'Ist nicht';
	@override String get matchBeginsWith => 'Beginnt mit';
	@override String get matchEndsWith => 'Endet mit';
	@override String get textHint => 'Suchtext eingeben';
	@override String get from => 'Von';
	@override String get to => 'Bis';
	@override String range({required Object from, required Object to}) => '${from} bis ${to}';
	@override String atLeast({required Object value}) => 'Ab ${value}';
	@override String atMost({required Object value}) => 'Bis ${value}';
	@override String dateLastDays({required Object count}) => 'Letzte ${count} Tage';
	@override String get dateLastYear => 'Im letzten Jahr';
	@override String dateOlderThanDays({required Object count}) => 'Älter als ${count} Tage';
	@override String get dateOlderThanYear => 'Älter als ein Jahr';
}

// Path: libraries.selection
class _Translations$libraries$selection$de extends Translations$libraries$selection$en {
	_Translations$libraries$selection$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Wählen Sie die Elemente';
	@override String selectedCount({required Object count}) => '${count} ausgewählt';
	@override String get actions => 'Auswahl Aktionen';
	@override String get confirmDescendants => 'Dies ändert alle Episoden in den ausgewählten Shows und Jahreszeiten.';
	@override String get confirmUnwatched => 'Dabei wird auch der Wiedergabefortschritt der ausgewählten Elemente gelöscht.';
	@override String confirmCount({required Object count}) => 'Auswählte Artikel: ${count}.';
	@override String completed({required Object count}) => 'Aktualisierte Artikel: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Aktualisiert ${succeeded}; versagt ${failed}. Versagtes Produkt bleibt ausgewählt.';
}

// Path: explore.mdblistShelves
class _Translations$explore$mdblistShelves$de extends Translations$explore$mdblistShelves$en {
	_Translations$explore$mdblistShelves$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Führung Explore Schiffe';
	@override String get manageDescription => 'Wählen und sortieren Sie Listen aus Ihrem Konto MDBList';
	@override String get description => 'Wählen Sie öffentliche Film- und TV-Listen aus Ihrem Konto MDBList aus. Erstellen oder Kopieren Sie Listen auf MDBList, dann aktualisieren.';
	@override String get selected => 'ausgewählte Schichten';
	@override String get available => 'Verfügbare Konto-Listen';
	@override String get noLists => 'Keine öffentlichen Filme oder TV-Listen zurückgegeben. Erstellen oder kopieren Sie eine Liste auf MDBList, dann erneuern.';
	@override String get displayName => 'Shelf Display Name';
	@override String get nameHint => 'Lassen Sie das Schalt, um den Quelllistenamen zu verwenden.';
	@override String get add => 'Schalke hinzufügen';
	@override String get save => 'Sparen Sie Schiffe';
	@override String moveUp({required Object title}) => '${title} nach oben verschieben';
	@override String moveDown({required Object title}) => '${title} nach unten';
	@override String get unavailable => 'Diese Liste ist nicht verfügbar. Rückkehr oder Entfernen der Schale in Einstellungen.';
	@override String get rateLimited => 'MDBList Anfrage Limit erreicht. Bitte zurückkehren später.';
	@override String get loadFailed => 'Kann nicht Laden Schichten. Überprüfen Sie Ihre Verbindung und Retry.';
	@override String get saveFailed => 'Ich kann nicht die Schlange retten. bitte zurück.';
	@override String get accountChanged => 'Das Konto oder das Profil geändert. Wieder öffnen Sie diese Einstellungen.';
	@override String get settingsUnreadable => 'Speicherte Schalen können nicht gelesen werden. Wählen Sie Ihre Listen erneut aus, um diese Einstellungen zu ersetzen.';
}

// Path: explore.rows
class _Translations$explore$rows$de extends Translations$explore$rows$en {
	_Translations$explore$rows$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Merkliste';
	@override String get recommendedMovies => 'Empfohlene Filme';
	@override String get recommendedShows => 'Empfohlene Serien';
	@override String get trendingMovies => 'Angesagte Filme';
	@override String get trendingShows => 'Angesagte Serien';
	@override String get popularMovies => 'Beliebte Filme';
	@override String get popularShows => 'Beliebte Serien';
	@override String get trendingAnime => 'Angesagte Anime';
	@override String get suggestedAnime => 'Empfohlene Anime';
	@override String get airingAnime => 'Beste derzeit laufende Anime';
	@override String get popularAnime => 'Beliebteste Anime';
	@override String get trending => 'Angesagt';
	@override String get upcomingMovies => 'Kommende Filme';
	@override String get upcomingShows => 'Kommende Serien';
}

// Path: explore.status
class _Translations$explore$status$de extends Translations$explore$status$en {
	_Translations$explore$status$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Laufend';
	@override String get ended => 'Beendet';
	@override String get canceled => 'Abgesetzt';
	@override String get upcoming => 'Demnächst';
}

// Path: explore.badge
class _Translations$explore$badge$de extends Translations$explore$badge$en {
	_Translations$explore$badge$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} beliebt';
	@override String rankAiring({required Object n}) => '#${n} derzeit ausgestrahlt';
	@override String rankRated({required Object n}) => '#${n} bewertet';
	@override String rankTrending({required Object n}) => '#${n} angesagt';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} in ${season}';
	@override String watchingNow({required Object n}) => '${n} schauen gerade';
	@override String get available => 'Verfügbar';
	@override String get partiallyAvailable => 'Teilweise verfügbar';
	@override String get availableIn4k => '4K verfügbar';
	@override String get requested => 'Angefragt';
	@override String get pendingApproval => 'Genehmigung ausstehend';
	@override String get processing => 'Wird verarbeitet';
	@override String get declined => 'Abgelehnt';
	@override String get requestFailed => 'Anfrage fehlgeschlagen';
	@override String get requested4k => '4K angefragt';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} Staffeln';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Folge ${episode} in ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Nächste in ${duration}';
	@override String episodesShort({required Object n}) => '${n} Folgen';
	@override String minutesPerEpisode({required Object n}) => '${n} Min./Folge';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$de extends Translations$explore$stats$en {
	_Translations$explore$stats$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} gelistet';
	@override String viewersDay({required Object n}) => '${n} heute gesehen';
	@override String viewersWeek({required Object n}) => '${n} diese Woche gesehen';
	@override String viewersMonth({required Object n}) => '${n} diesen Monat gesehen';
	@override String viewersYear({required Object n}) => '${n} dieses Jahr gesehen';
	@override String viewersAllTime({required Object n}) => '${n} Zuschauer';
	@override String planning({required Object n}) => '${n} haben es geplant';
	@override String favorited({required Object n}) => '${n} Favoriten';
	@override String dropRate({required Object percent}) => '${percent} haben es abgebrochen';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Kommentar',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Kommentare',
	);
	@override String votes({required Object n}) => '${n} Stimmen';
	@override String watching({required Object n}) => '${n} schauen es gerade';
	@override String completed({required Object n}) => '${n} abgeschlossen';
	@override String onHold({required Object n}) => '${n} pausiert';
	@override String dropped({required Object n}) => '${n} abgebrochen';
}

// Path: explore.season
class _Translations$explore$season$de extends Translations$explore$season$en {
	_Translations$explore$season$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Winter';
	@override String get spring => 'Frühling';
	@override String get summer => 'Sommer';
	@override String get fall => 'Herbst';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$de extends Translations$explore$format$en {
	_Translations$explore$format$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV-Kurzfilm';
	@override String get movie => 'Film';
	@override String get special => 'Special';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musik';
	@override String get other => 'Sonstiges';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$de extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light Novel';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Visual Novel';
	@override String get game => 'Spiel';
	@override String get webComic => 'Webcomic';
	@override String get musicRelease => 'Musik';
	@override String get otherMedia => 'Sonstiges';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$de extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Darsteller';
	@override String get director => 'Regisseur';
	@override String get writer => 'Autor';
	@override String get producer => 'Produzent';
	@override String get creator => 'Schöpfer';
	@override String get composer => 'Komponist';
}

// Path: explore.relation
class _Translations$explore$relation$de extends Translations$explore$relation$en {
	_Translations$explore$relation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequel';
	@override String get sequel => 'Fortsetzung';
	@override String get sideStory => 'Nebengeschichte';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Alternative Version';
	@override String get summary => 'Zusammenfassung';
	@override String get parentStory => 'Hauptgeschichte';
	@override String get adaptation => 'Adaption';
	@override String get other => 'Verwandt';
}

// Path: explore.detail
class _Translations$explore$detail$de extends Translations$explore$detail$en {
	_Translations$explore$detail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Originaltitel';
	@override String get alsoKnownAs => 'Auch bekannt als';
	@override String get studios => 'Studios';
	@override String get country => 'Land';
	@override String get language => 'Sprache';
	@override String get released => 'Erschienen';
	@override String get physicalRelease => 'Auf Disc';
	@override String get ended => 'Beendet';
	@override String addedOn({required Object date}) => 'Hinzugefügt am ${date}';
	@override String get yourRating => 'Deine Bewertung';
	@override String get budget => 'Budget';
	@override String get revenue => 'Einspielergebnis';
	@override String get contentAdvisory => 'Altersfreigabe';
	@override String get tags => 'Tags';
	@override String get revealSpoilerTags => 'Spoiler-Tags anzeigen';
	@override String get links => 'Links';
	@override String get watchOn => 'Ansehen auf';
	@override String get watchTrailer => 'Trailer ansehen';
	@override String openOn({required Object site}) => 'Auf ${site} öffnen';
	@override String get crew => 'Crew';
	@override String get ratings => 'Bewertungen';
	@override String get schedule => 'Sendetermine';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Von ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Nutzer empfohlen',
		other: 'Von ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Nutzern empfohlen',
	);
	@override String recommendedBy({required Object who}) => 'Empfohlen von ${who}';
	@override String favoritedBy({required Object who}) => 'Favorisiert von ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} noch nicht ausgestrahlt';
	@override String recommendedByPercent({required Object percent}) => 'Von ${percent} der Zuschauer empfohlen';
	@override String get relatedTitles => 'Verwandte Titel';
	@override String get background => 'Hintergrund';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$de extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Früher starten (Sekunden)';
	@override String get endLate => 'Später beenden (Sekunden)';
	@override String get newOnly => 'Nur neue Episoden';
	@override String get anyChannel => 'Auf jedem Sender aufnehmen';
	@override String get anyTime => 'Zu jeder Zeit aufnehmen';
	@override String get skipInLibrary => 'Episoden überspringen, die schon in der Bibliothek sind';
	@override String get keepUpTo => 'Zu behaltende Episoden';
	@override String get keepUpToHint => '0 behält alle Episoden';
}

// Path: music.discography
class _Translations$music$discography$de extends Translations$music$discography$en {
	_Translations$music$discography$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles & EPs';
	@override String get live => 'Live';
	@override String get compilations => 'Kompilationen';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$de extends Translations$watchTogether$notices$en {
	_Translations$watchTogether$notices$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} hat auf Abspielen gedrückt';
	@override String get playbackStarted => 'Wiedergabe gestartet';
	@override String paused({required Object name}) => '${name} hat pausiert';
	@override String get playbackPaused => 'Wiedergabe pausiert';
	@override String jumpedTo({required Object name, required Object position}) => '${name} ist zu ${position} gesprungen';
	@override String roomJumpedTo({required Object position}) => 'Zu ${position} gesprungen';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} hat die Geschwindigkeit auf ${speed} gesetzt';
	@override String speedChanged({required Object speed}) => 'Geschwindigkeit auf ${speed} gesetzt';
	@override String startedMedia({required Object name, required Object title}) => '${name} hat ${title} gestartet';
	@override String mediaStarted({required Object title}) => 'Jetzt läuft ${title}';
	@override String stoppedMedia({required Object name}) => '${name} hat das Video gestoppt';
	@override String get mediaStopped => 'Das Video wurde gestoppt';
	@override String waitingFor({required Object name}) => 'Warten auf ${name} …';
	@override String get waitingForSomeone => 'Warten, bis alle aufgeholt haben …';
	@override String get finished => 'Beendet';
	@override String hostChangedTo({required Object name}) => '${name} ist jetzt der Host';
	@override String get youAreNowHost => 'Du bist jetzt der Host';
	@override String joined({required Object name}) => '${name} ist beigetreten';
	@override String left({required Object name}) => '${name} hat die Sitzung verlassen';
	@override String get controlRefused => 'Nur der Host kann die Wiedergabe steuern';
	@override String get searchFailed => 'Einige Server konnten nicht nach dem Video des Raums durchsucht werden';
	@override String get playBlocked => 'Zum Starten auf Abspielen drücken';
	@override String get shareFailed => 'Dieses Video konnte nicht mit dem Raum geteilt werden';
	@override String get downloadNotShared => 'Downloads werden nicht mit dem Raum geteilt, solange ihr Server offline ist';
	@override String get openFailed => 'Das Video des Raums konnte nicht geöffnet werden';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$de extends Translations$watchTogether$ended$en {
	_Translations$watchTogether$ended$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Der Host hat den Raum beendet';
	@override String get kicked => 'Du wurdest aus dem Raum entfernt';
	@override String get expired => 'Der Raum ist abgelaufen';
	@override String get replaced => 'Du bist diesem Raum auf einem anderen Gerät beigetreten';
	@override String get lost => 'Verbindung zum Raum verloren';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$de extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Das ist kein Raumcode. Codes bestehen aus 6 Buchstaben und Ziffern, ohne 0, 1, I, L oder O.';
	@override String get roomNotFound => 'Es gibt keinen Raum mit diesem Code. Möglicherweise wurde er beendet.';
	@override String get roomFull => 'Dieser Raum ist voll.';
	@override String get roomLocked => 'Der Host hat diesen Raum gesperrt.';
	@override String get relayFull => 'Gemeinsam Schauen ist gerade ausgelastet. Versuche es später erneut.';
	@override String get unreachable => 'Das Relay für Gemeinsam Schauen ist nicht erreichbar. Prüfe deine Verbindung.';
	@override String get rateLimited => 'Zu viele Versuche. Warte einen Moment und versuche es erneut.';
	@override String get clientBlocked => 'Diese Version von PlezyNG kann das Relay nicht verwenden. Aktualisiere die App.';
	@override String get forbidden => 'Das kann nur der Host.';
	@override String get notInRoom => 'Du bist in keinem Raum.';
	@override String get alreadyInRoom => 'Du bist bereits in einem Raum.';
	@override String get resumeFailed => 'Erneuter Beitritt zum Raum fehlgeschlagen.';
	@override String get unsupported => 'Das Relay unterstützt das nicht.';
	@override String get generic => 'Etwas ist schiefgelaufen. Versuche es erneut.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$de extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Downloads werden gestoppt, wenn du die App verlässt';
	@override String get bannerDegraded => 'Downloads im Hintergrund sind möglicherweise eingeschränkt';
	@override String get bannerAction => 'Details';
	@override String get sheetTitle => 'Downloads im Hintergrund sind blockiert';
	@override String get sheetTitleDegraded => 'Downloads im Hintergrund sind möglicherweise eingeschränkt';
	@override String get sheetIntro => 'Android verhindert, dass PlezyNG zuverlässig im Hintergrund herunterlädt.';
	@override String get sheetIntroDegraded => 'Dein Gerät schränkt ein, wann PlezyNG im Hintergrund herunterladen kann.';
	@override String get reasonBackgroundRestricted => 'Die Hintergrundnutzung von PlezyNG ist eingeschränkt. Stelle die Akku- oder Hintergrundnutzung auf „Uneingeschränkt“.';
	@override String get reasonStandbyRestricted => 'Android hat PlezyNG in einen eingeschränkten Standby-Modus versetzt. Stelle die Akkunutzung auf „Uneingeschränkt“.';
	@override String get reasonDownloadChannelBlocked => 'Download-Benachrichtigungen sind deaktiviert. Fortschritt und Steuerelemente sind daher möglicherweise nicht verfügbar.';
	@override String get reasonNotificationsDisabled => 'Benachrichtigungen sind deaktiviert. Ab Android 13 sind sie für lange Downloads im Hintergrund erforderlich.';
	@override String get reasonDataSaver => 'Der Datensparmodus ist aktiviert und blockiert Downloads im Hintergrund über mobile Daten. Über Wi-Fi sollten Downloads weiterhin funktionieren.';
	@override String get reasonOemUnknown => 'Downloads wurden wiederholt gestoppt, während PlezyNG im Hintergrund war. Prüfe die Einstellungen zur Akku- oder Hintergrundnutzung von PlezyNG.';
	@override String get openSettings => 'Einstellungen öffnen';
	@override String get stillNotWorking => 'Gerätespezifische Hilfe';
	@override String get stillNotWorkingDescription => 'Sieh dir die Schritte für dein Gerät an oder sende bei anhaltendem Problem ein Protokoll über Einstellungen › Protokolle anzeigen.';
	@override String get dialogTitle => 'Downloads werden möglicherweise nicht abgeschlossen';
	@override String get dialogDownloadAnyway => 'Trotzdem herunterladen';
	@override String get dialogFixFirst => 'Zuerst beheben';
	@override String get statusTile => 'Downloads im Hintergrund';
	@override String get statusOk => 'Ausführung im Hintergrund erlaubt';
	@override String get statusBlocked => 'Durch Systemeinstellungen blockiert';
	@override String get statusDegraded => 'Durch Systemeinstellungen eingeschränkt';
	@override String get statusUnknown => 'Noch nicht geprüft';
	@override String get settingsUnavailable => 'Die Systemeinstellungen konnten auf diesem Gerät nicht geöffnet werden';
	@override String get linkUnavailable => 'dontkillmyapp.com konnte auf diesem Gerät nicht geöffnet werden';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$de extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get library => 'Mediathek';
	@override String get collections => 'Sammlungen';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$de extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Remote-Server wird gestartet...';
	@override String get hostAddress => 'Host-Adresse';
	@override String get connected => 'Verbunden';
	@override String get serverRunning => 'Remote-Server aktiv';
	@override String get serverStopped => 'Remote-Server gestoppt';
	@override String get serverRunningDescription => 'Mobilgeräte in deinem Netzwerk können sich mit dieser App verbinden';
	@override String get serverStoppedDescription => 'Starte den Server, um Mobilgeräten die Verbindung zu ermöglichen';
	@override String get usePhoneToControl => 'Verwende dein Mobilgerät, um diese App zu steuern';
	@override String get startServer => 'Server starten';
	@override String get stopServer => 'Server stoppen';
	@override String get minimize => 'Minimieren';
	@override String get manualAddressHint => 'Manuelle Verbindungsadresse:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$de extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'PlezyNG-Geräte mit demselben Plex-Konto erscheinen hier';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Verbinden...';
	@override String get searchingForDevices => 'Suche nach Geräten...';
	@override String get noDevicesFound => 'Keine Geräte in deinem Netzwerk gefunden';
	@override String get noDevicesHint => 'Öffne PlezyNG auf dem Desktop und nutze dasselbe WLAN';
	@override String get availableDevices => 'Verfügbare Geräte';
	@override String get manualConnection => 'Manuelle Verbindung';
	@override String get cryptoInitFailed => 'Sichere Verbindung konnte nicht gestartet werden. Melde dich zuerst bei Plex an.';
	@override String get validationHostRequired => 'Bitte Host-Adresse eingeben';
	@override String get validationHostFormat => 'Format muss IP:Port sein (z. B. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Zeitüberschreitung bei der Verbindung. Nutze auf beiden Geräten dasselbe Netzwerk.';
	@override String get sessionNotFound => 'Gerät nicht gefunden. Stelle sicher, dass PlezyNG auf dem Host läuft.';
	@override String get authFailed => 'Authentifizierung fehlgeschlagen. Beide Geräte benötigen dasselbe Plex-Konto.';
	@override String failedToConnect({required Object error}) => 'Verbindung fehlgeschlagen: ${error}';
	@override String get codeTitle => 'Paar Code';
	@override String get codeDescription => 'Geben Sie den Code in Companion Remote auf dem Host-Gerät ein. Beide Geräte müssen eine Version verwenden, die sichere Paarung unterstützt.';
	@override String get codeInvalid => 'Geben Sie alle 32 Buchstaben und Zahlen aus dem Hostcode ein.';
	@override String get updateRequired => 'Beide Geräte aktualisieren auf eine Version, die sichere Paarung unterstützt.';
	@override String get hostDescription => 'Geben Sie diesen Code einmal auf jedem Fernseher ein. Halten Sie ihn privat: es gibt Kontrolle über diesen Profil.';
	@override String get resetCode => 'Pairing Code wiederherstellen';
	@override String get resetDescription => 'Entfernen Sie alle Entfernungsteile und erstellen Sie einen neuen Code. Jeder Entfernung muss wieder Paar.';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$de extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Möchtest du die Verbindung zur Fernsteuerungssitzung trennen?';
	@override String get reconnecting => 'Verbindung wird wiederhergestellt...';
	@override String attemptOf({required Object current}) => 'Versuch ${current} von 5';
	@override String get retryNow => 'Jetzt wiederholen';
	@override String get tabRemote => 'Fernbedienung';
	@override String get tabPlay => 'Wiedergabe';
	@override String get tabMore => 'Mehr';
	@override String get menu => 'Menü';
	@override String get tabNavigation => 'Tab-Navigation';
	@override String get tabDiscover => 'Entdecken';
	@override String get tabLibraries => 'Mediatheken';
	@override String get tabSearch => 'Suche';
	@override String get tabDownloads => 'Downloads';
	@override String get tabSettings => 'Einstellungen';
	@override String get previous => 'Zurück';
	@override String get playPause => 'Wiedergabe/Pause';
	@override String get next => 'Weiter';
	@override String get seekBack => 'Zurückspulen';
	@override String get stop => 'Stopp';
	@override String get seekForward => 'Vorspulen';
	@override String get volume => 'Lautstärke';
	@override String get volumeDown => 'Leiser';
	@override String get volumeUp => 'Lauter';
	@override String get fullscreen => 'Vollbild';
	@override String get subtitles => 'Untertitel';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Auf dem Desktop suchen …';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$de extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Keine Netzwerkschnittstelle gefunden';
	@override String get authenticationFailed => 'Authentifizierung fehlgeschlagen';
	@override String serverStartFailed({required Object error}) => 'Remote-Server konnte nicht gestartet werden: ${error}';
	@override String commandFailed({required Object error}) => 'Remote-Befehl konnte nicht gesendet werden: ${error}';
	@override String get joinTimedOut => 'Zeitüberschreitung beim Beitreten zur Sitzung';
	@override String get failedToConnectAnyAddress => 'Keine Verbindung zu einer Adresse möglich';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Verbindung nach ${attempts} Versuchen verloren';
	@override String get connectionLost => 'Verbindung verloren';
}

// Path: services.names
class _Translations$services$names$de extends Translations$services$names$en {
	_Translations$services$names$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$de extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Simkl erneut verbinden';
	@override String get subtitle => 'Simkl stellt die Anmeldemethode ein, die diese Verbindung nutzt. Beim erneuten Verbinden wird simkl.com geöffnet, um PlezyNG zu autorisieren – PlezyNG sieht dein Passwort nie. Dein Wiedergabeverlauf bleibt bei Simkl erhalten.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$de extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'PlezyNG auf ${service} aktivieren';
	@override String get instructions => 'Scanne den QR-Code oder rufe die unten angegebene Adresse auf und gib diesen Code ein:';
	@override String openToActivate({required Object service}) => '${service} zum Aktivieren öffnen';
	@override String get copyCode => 'Aktivierungscode kopieren';
	@override String get waitingForAuthorization => 'Warte auf Autorisierung…';
	@override String get codeCopied => 'Code kopiert';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$de extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Bei ${service} anmelden';
	@override String get body => 'Scanne diesen QR-Code oder öffne die URL auf einem beliebigen Gerät.';
	@override String openToSignIn({required Object service}) => '${service} zum Anmelden öffnen';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$de extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Anmelde-URL kopieren';
	@override String get urlCopied => 'URL kopiert';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$de extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mediatheksfilter';
	@override String get subtitleAllSyncing => 'Alle Mediatheken werden synchronisiert';
	@override String get subtitleNoneSyncing => 'Nichts wird synchronisiert';
	@override String subtitleBlocked({required Object count}) => '${count} ausgeschlossen';
	@override String subtitleAllowed({required Object count}) => '${count} zugelassen';
	@override String get mode => 'Filtermodus';
	@override String get modeBlacklist => 'Ausschlussliste';
	@override String get modeWhitelist => 'Zulassungsliste';
	@override String get modeHintBlacklist => 'Alle Mediatheken außer den unten markierten synchronisieren.';
	@override String get modeHintWhitelist => 'Nur die unten markierten Mediatheken synchronisieren.';
	@override String get libraries => 'Mediatheken';
	@override String get noLibraries => 'Keine Mediatheken verfügbar';
	@override String get modeDescription => 'Wählen Sie aus, ob die überprüften Bibliotheken von Synchronisierung blockiert sind oder die einzigen Bibliothek ist, die synchroniziert.';
}

// Path: services.trackerDescriptions
class _Translations$services$trackerDescriptions$de extends Translations$services$trackerDescriptions$en {
	_Translations$services$trackerDescriptions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Synchronisieren Sie aufgezeichnete Episoden und Filme mit Ihrem Trakt-Konto.';
	@override String get mal => 'Synchronisieren Sie anime-Listen und beobachten Sie den Fortschritt mit MyAnimeList.';
	@override String get anilist => 'Synchronisieren Sie anime-Listen und beobachten Sie den Fortschritt mit AniList.';
	@override String get simkl => 'Sync sah Filme, TV-Shows und Anime mit Simkl.';
	@override String get mdblist => 'Zeigen Sie MDBList Bewertungen und Listen in Empfehlungen und Entdecken.';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'App-Symbol',
			'appIcon.defaultIcon' => 'Standard',
			'appIcon.current' => 'Aktuelles Symbol',
			'appIcon.locked' => 'Lebensdauer Zugang erforderlich',
			'appIcon.lockedHint' => 'Beginnen Sie Ihre 7-tägige Prüfung oder löschen Sie PlezyNG für das Leben, um alternative Ikonen zu verwenden.',
			'appIcon.changeFailed' => 'App-Symbol konnte nicht geändert werden',
			'appIcon.launcherHint' => 'Das neue Symbol erscheint auf deinem Startbildschirm, sobald du PlezyNG verlässt.',
			'appIcon.tvLauncherHint' => 'Das neue Banner erscheint, sobald du PlezyNG verlässt. Android TV zeigt eventuell noch das alte an, bis der Fernseher neu gestartet wird.',
			'appIcon.names.midnight' => 'Mitternacht',
			'appIcon.names.ember' => 'Glut',
			'appIcon.names.paper' => 'Papier',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Linie',
			'appIcon.names.ocean' => 'Ozean',
			'appIcon.names.ultraviolet' => 'Ultraviolett',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Abendrot',
			'appIcon.names.gold' => 'Gold',
			'appIcon.names.titanium' => 'Titan',
			'appIcon.names.glass' => 'Glas',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Sticker',
			'appIcon.names.ticket' => 'Ticket',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Schichten',
			'appIcon.names.facet' => 'Facette',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Wählen Sie die von Ihrem Gerät Launcher angegebene Ikon aus. Die Vorgänge zeigen, wie jede Option sieht.',
			'auth.signInWithPlex' => 'Mit Plex anmelden',
			'auth.showQRCode' => 'QR-Code anzeigen',
			'auth.authenticate' => 'Authentifizieren',
			'auth.authenticationTimeout' => 'Authentifizierung abgelaufen. Bitte erneut versuchen.',
			'auth.scanQRToSignIn' => 'Scanne diesen QR-Code, um dich anzumelden',
			'auth.waitingForAuth' => 'Warte auf die Authentifizierung …\nMelde dich über deinen Browser an.',
			'auth.useBrowser' => 'Browser verwenden',
			'auth.or' => 'oder',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Mit ${product} verbinden',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Quick Connect verwenden',
			'auth.quickConnectInstructions' => 'Öffne Quick Connect in Jellyfin und gib diesen Code ein.',
			'auth.quickConnectWaiting' => 'Warte auf Bestätigung…',
			'auth.quickConnectCancel' => 'Abbrechen',
			'auth.quickConnectExpired' => 'Quick Connect ist abgelaufen. Versuche es erneut.',
			'auth.localDataRecoveryRequired' => 'PlezyNG konnte lokale Anmeldedaten und ausstehende Wiedergabedaten nicht sicher wiederherstellen. Bitte melde dich erneut an.',
			'auth.pinCheckRejected' => 'Die Plex-PIN-Prüfung wurde abgelehnt',
			'auth.connectToDirectPlex' => 'Anschluss an den lokalen Server Plex',
			'common.cancel' => 'Abbrechen',
			'common.save' => 'Speichern',
			'common.close' => 'Schließen',
			'common.closeMiniPlayer' => 'Nächste Mini-Spieler',
			'common.closeWorkspaceWindow' => 'Nächstes Fenster',
			'common.returnToFullView' => 'Zurück zum vollständigen Blick',
			'common.manageMediaSessions' => 'Media-Sitzungen verwalten',
			'common.hideMediaSessions' => 'Media-Sitzungen verstecken',
			'common.mediaSessions' => 'Medienveranstaltungen',
			'common.mediaSessionsHint' => 'Wählen Sie aus, um eine Sitzung voran zu bringen. Park verbergt sein Fenster, aber hält es offen. Return öffnet es in vollem Blick; nahe endet es.',
			'common.sessionInWorkspace' => 'im Workspace',
			'common.sessionParked' => 'parken',
			'common.sessionFullscreen' => 'Vollbildschirm',
			'common.switchToNextWindow' => 'Swap mit dem nächsten Fenster',
			'common.moveWindow' => 'Fenster bewegt',
			'common.finishMovingWindow' => 'Beenden Sie das bewegende Fenster',
			'common.moveWindowHint' => 'Lange Druck und ziehen Sie das Fenster, um es zu bewegen. Diese Steuerung ermöglicht auch die Schild-Schlüsselbewegung.',
			'common.movingWindowHelp' => 'Drücken zu bewegen · Schießen Schlüssel angepasst · Enter Saves · Escape Cancels',
			'common.resizeWindow' => 'Wiederaufbau Fenster',
			'common.resizeWindowHint' => 'Drücken Sie diese Handschrift oder verwenden Sie die Schildschlüssel, um das Fenster zurückzuziehen.',
			'common.workspaceWindowHint' => 'Verwenden Sie die Bewegungskontrolle oder lange Druck und ziehen, um sich zu bewegen.',
			'common.workspacePaneHint' => 'Wählen Sie dieses Panel aus, um es zu konzentrieren. Verwenden Sie seine Vollbildschirmkontrolle, um sie zu erweitern.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Sitzungsfenster: ${title}',
			'common.workspaceTitleHint' => 'Wählen Sie, um sich zu konzentrieren. Drücken Sie die Titelkarte zu bewegen; Verwenden Sie den vollbildschirmknopf, um sie zu erweitern.',
			'common.moveToSessionTray' => 'Bewegen Sie sich nach Session Tray',
			'common.moveToSessionTrayHint' => 'Keeps diese Sitzung verfügbar, ohne das Fenster anzuzeigen.',
			'common.closeSessionHint' => 'Schließen Sie dieses Fenster und beenden Sie seine Sitzung.',
			'common.sideBySideLayout' => 'Wechsel zum Side-by-Side Layout',
			'common.floatingWindows' => 'Switch zum Fließen von Fenstern',
			'common.clear' => 'Leeren',
			'common.reset' => 'Zurücksetzen',
			'common.later' => 'Später',
			'common.submit' => 'Senden',
			'common.confirm' => 'Bestätigen',
			'common.retry' => 'Erneut versuchen',
			'common.logout' => 'Abmelden',
			'common.unknown' => 'Unbekannt',
			'common.refresh' => 'Aktualisieren',
			'common.yes' => 'Ja',
			'common.no' => 'Nein',
			'common.delete' => 'Löschen',
			'common.edit' => 'Bearbeiten',
			'common.shuffle' => 'Zufallswiedergabe',
			'common.addTo' => 'Hinzufügen zu …',
			'common.createNew' => 'Neu erstellen',
			'common.connect' => 'Verbinden',
			'common.disconnect' => 'Trennen',
			'common.play' => 'Abspielen',
			'common.pause' => 'Pause',
			'common.resume' => 'Fortsetzen',
			'common.error' => 'Fehler',
			'common.search' => 'Suche',
			'common.home' => 'Start',
			'common.back' => 'Zurück',
			'common.settings' => 'Einstellungen',
			'common.mute' => 'Stumm',
			'common.ok' => 'OK',
			'common.off' => 'Aus',
			'common.options' => 'Optionen',
			'common.seasonNumber' => ({required Object number}) => 'Staffel ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Folge ${number} – ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Kapitel ${number}',
			'common.reconnect' => 'Erneut verbinden',
			'common.viewAll' => 'Alle anzeigen',
			'common.checkingNetwork' => 'Netzwerk wird geprüft...',
			'common.loadingServers' => 'Server werden geladen...',
			'common.connectingToServers' => 'Verbindung zu Servern wird hergestellt …',
			'common.startingOfflineMode' => 'Offlinemodus wird gestartet...',
			'common.loading' => 'Wird geladen …',
			'common.fullscreen' => 'Vollbild',
			'common.exitFullscreen' => 'Vollbild verlassen',
			'common.pressBackAgainToExit' => 'Zum Beenden erneut Zurück drücken',
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
			'common.notAvailable' => 'N. v.',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.show' => 'Serie',
			'common.mediaKind.season' => 'Staffel',
			'common.mediaKind.episode' => 'Episode',
			'common.mediaKind.artist' => 'Interpret',
			'common.mediaKind.album' => 'Album',
			'common.mediaKind.track' => 'Titel',
			'common.mediaKind.collection' => 'Sammlung',
			'common.mediaKind.playlist' => 'Wiedergabeliste',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Ordner',
			'screens.licenses' => 'Lizenzen',
			'screens.switchProfile' => 'Profil wechseln',
			'screens.subtitleStyling' => 'Untertitel-Stil',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Protokolle',
			'update.available' => 'Update verfügbar',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} ist verfügbar',
			'update.currentVersion' => ({required Object version}) => 'Aktuell: ${version}',
			'update.skipVersion' => 'Diese Version überspringen',
			'update.viewRelease' => 'Versionshinweise anzeigen',
			'update.latestVersion' => 'Aktuellste Version installiert',
			'update.checkFailed' => 'Fehler bei der Updateprüfung',
			'settings.title' => 'Einstellungen',
			'settings.supportDeveloper' => 'PlezyNG unterstützen',
			'settings.supportDeveloperDescription' => 'Spenden Sie, um die Entwicklung zu unterstützen',
			'settings.lifetimeAccess' => 'PlezyNG Lebensdauer Zugang',
			'settings.language' => 'Sprache',
			'settings.theme' => 'Design',
			'settings.appearance' => 'Darstellung',
			'settings.detailPage' => 'Detailseite',
			'settings.themeSongsEnabled' => 'Spielen Theme Songs',
			'settings.themeSongsEnabledDescription' => 'Spielen Sie verfügbare thematische Songs während Sie Mediendetails ansehen.',
			'settings.themeSongVolume' => 'Song Volume Themen',
			'settings.videoPlayback' => 'Videowiedergabe',
			'settings.videoPlaybackDescription' => 'Wiedergabeverhalten konfigurieren',
			'settings.advanced' => 'Erweitert',
			'settings.episodePosterMode' => 'Episodenposter-Stil',
			'settings.seriesPoster' => 'Serienposter',
			'settings.seasonPoster' => 'Staffelposter',
			'settings.episodeThumbnail' => 'Vorschaubild',
			'settings.showHeroSectionDescription' => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen',
			'settings.secondsLabel' => 'Sekunden',
			'settings.minutesLabel' => 'Minuten',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'min',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Hell',
			'settings.darkTheme' => 'Dunkel',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Glut',
			'settings.glacierTheme' => 'Gletscher',
			'settings.forestTheme' => 'Wald',
			'settings.plumTheme' => 'Pflaume',
			'settings.paperTheme' => 'Papier',
			'settings.libraryDensity' => 'Darstellungsdichte der Mediathek',
			'settings.displayScale' => 'Skalierung',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Großzügig',
			'settings.gridSpacing' => 'Rasterabstand',
			'settings.gridSpacingTight' => 'Eng',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Großzügig',
			'settings.tvCornerSpotlightBackdrop' => 'Backdrop in der Ecke',
			'settings.tvCornerSpotlightBackdropDescription' => 'Zeigt das Spotlight-Artwork oben rechts statt bildschirmfüllend',
			'settings.viewMode' => 'Ansichtsmodus',
			'settings.gridView' => 'Raster',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Empfehlungsbereich anzeigen',
			'settings.showHomeBackdrop' => 'Home Backdrop Kunstwerk zeigen',
			'settings.showHomeBackdropDescription' => 'Zeigen Sie große Kunstwerke hinter featured Home Rings',
			'settings.contentScreensaverEnabled' => 'Inhalt Screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Show Full-Screen Artwork nach der App ist idle',
			'settings.contentScreensaverDelay' => 'Start Screensaver nach',
			'settings.contentScreensaverLibraries' => 'Screensaver Bibliothek',
			'settings.contentScreensaverLibrariesDescription' => 'Wählen Sie die Bibliotheken aus, deren Bilder der Bildschirmschoner verwenden soll. Wenn keine ausgewählt ist, werden Bilder aus allen Bibliotheken verwendet.',
			'settings.contentScreensaverAllLibraries' => 'Alle Bibliotheken',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} Bibliotheken ausgewählt',
			'settings.contentScreensaverNoLibraries' => 'Keine verbundenen Medienbibliotheken sind verfügbar.',
			'settings.contentScreensaverDismissHint' => 'Drücken Sie jeden Button oder drücken Sie, um abzulehnen',
			'settings.newEpisodeNotifications' => 'Neue Episode-Nachrichten',
			'settings.newEpisodeNotificationsDescription' => 'Warnen Sie, wenn ein neues Episode zu einem Show hinzugefügt wird, dass Sie aufgenommen werden. Überprüfen Sie, während Plezy geöffnet ist.',
			'settings.continueWatchingRowSize' => 'Weiterlesen Überblick über die Größe der Reihe',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} Karten',
			'settings.rowSizeCompact' => 'Kompakt',
			'settings.rowSizeStandard' => 'Standard',
			'settings.rowSizeLarge' => 'Groß',
			'settings.continueWatchingAction' => 'Aktion für Weiterschauen',
			'settings.continueWatchingPlay' => 'Abspielen',
			'settings.continueWatchingDetails' => 'Details öffnen',
			'settings.episodeAction' => 'Episodenaktion',
			'settings.episodePlay' => 'Abspielen',
			'settings.episodeDetails' => 'Details öffnen',
			'settings.useGlobalHubs' => 'Startlayout verwenden',
			'settings.useGlobalHubsDescription' => 'Einheitliche Start-Hubs anzeigen. Sonst Bibliotheksempfehlungen verwenden.',
			'settings.showServerNameOnHubs' => 'Servername bei Hubs anzeigen',
			'settings.showServerNameOnHubsDescription' => 'Servernamen immer in Hub-Titeln anzeigen.',
			'settings.groupLibrariesByServer' => 'Mediatheken nach Server gruppieren',
			'settings.groupLibrariesByServerDescription' => 'Sidebar-Bibliotheken nach Medienserver gruppieren.',
			'settings.alwaysKeepSidebarOpen' => 'Seitenleiste immer geöffnet halten',
			'settings.alwaysKeepSidebarOpenDescription' => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an',
			'settings.showUnwatchedCount' => 'Anzahl nicht gesehener Folgen anzeigen',
			'settings.showUnwatchedCountDescription' => 'Zeigt die Anzahl nicht gesehener Episoden bei Serien und Staffeln an',
			'settings.showWatchedIndicators' => 'Gesehen-Markierungen anzeigen',
			'settings.showWatchedIndicatorsDescription' => 'Zeigt ein Häkchen bei gesehenen Filmen, Serien und Episoden an',
			'settings.showEpisodeNumberOnCards' => 'Episodennummer auf Karten anzeigen',
			'settings.showEpisodeNumberOnCardsDescription' => 'Staffel- und Episodennummer auf Episodenkarten anzeigen',
			'settings.showSeasonPostersOnTabs' => 'Staffelposter auf Tabs anzeigen',
			'settings.showSeasonPostersOnTabsDescription' => 'Poster jeder Staffel über ihrem Tab anzeigen',
			'settings.tvFullCardLayout' => 'Vollflächige TV-Karten',
			'settings.tvFullCardLayoutDescription' => 'TV-Karten nur mit Bild verwenden und Darstellernamen einblenden',
			'settings.focusGlow' => 'Fokusleuchten',
			'settings.focusGlowDescription' => 'Sanftes Leuchten um die fokussierte Karte anzeigen',
			'settings.visualEffects' => 'Visuelle Effekte',
			'settings.visualEffectsAuto' => 'Automatisch',
			'settings.visualEffectsAutoDescription' => 'Effekte auf leistungsschwachen Geräten automatisch reduzieren',
			'settings.visualEffectsFull' => 'Vollständig',
			'settings.visualEffectsReduced' => 'Reduziert',
			'settings.visualEffectsReducedDescription' => 'Weniger Animationen und Grafiken mit niedrigerer Auflösung',
			'settings.hideSpoilers' => 'Spoiler für nicht gesehene Episoden verbergen',
			'settings.hideSpoilersDescription' => 'Vorschaubilder und Beschreibungen ungesehener Episoden verwischen',
			'settings.playerBackend' => 'Wiedergabe-Engine',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardwaredekodierung',
			'settings.hardwareDecodingDescription' => 'Hardwarebeschleunigung verwenden, sofern verfügbar',
			'settings.playbackBuffer' => 'Wiedergabepuffer',
			'settings.playbackBufferAuto' => 'Automatisch (empfohlen)',
			'settings.playbackBufferLarge' => 'Groß',
			'settings.playbackBufferExtraLarge' => 'Extra groß',
			'settings.playbackBufferDescription' => 'Puffert mehr gegen instabile Verbindungen. Zusätzlich durch die Puffergröße begrenzt.',
			'settings.streamBufferSize' => 'Buffer Größe',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Wie viel Video zu laden, wenn direkt spielt. Transcodes stoppen auf dem eigenen Transcode-Buffert des Servern. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Ersatz der Playback Buffer beim Setup, auf halb der Speichergrenze der App abgeschaltet',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Standardqualität',
			'settings.cellularQualityTitle' => 'Standardqualität im Mobilfunknetz',
			'settings.remoteQualityTitle' => 'Qualitätsstreaming von Fern',
			'settings.remoteQualitySameAsDefault' => 'So wie die Standardqualität',
			'settings.cellularQualitySameAsDefault' => 'Wie Standardqualität',
			'settings.directPlayCoveredQuality' => 'Kleinere Videos in Originalqualität abspielen',
			'settings.directPlayCoveredQualityDescription' => 'Videos, die bereits innerhalb des Qualitätslimits liegen, per Direct Play abspielen, statt sie zu transkodieren',
			'settings.videoCodecs' => 'Video-Codecs',
			'settings.videoCodecsDescription' => 'Nicht ausgewählte Codecs transkodiert der Server',
			'settings.videoCodecsAlwaysAccepted' => 'Immer akzeptiert',
			'settings.musicQualityTitle' => 'Musikqualität',
			'settings.subtitleStyling' => 'Untertitel-Stil',
			'settings.subtitleStylingDescription' => 'Aussehen von Untertiteln anpassen',
			'settings.smallSkipDuration' => 'Kleines Sprungintervall',
			'settings.largeSkipDuration' => 'Großes Sprungintervall',
			'settings.rewindOnResume' => 'Zurückspulen bei Fortsetzung',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} Sekunde', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} Sekunden', ), 
			'settings.defaultSleepTimer' => 'Standard-Schlaftimer',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} Minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} Minuten', ), 
			'settings.rememberTrackSelections' => 'Spurauswahl pro Serie/Film merken',
			'settings.chooseTracksBeforePlayback' => 'Wählen Sie Audio und Untertitel vor dem Playback aus',
			'settings.chooseTracksBeforePlaybackDescription' => 'Wählen Sie die Quell-Audio und Subtitle-Track vor jedem Video starten.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Sie zeigen immer Untertitel auf diesem Gerät',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Wenn der Server keinen Untertitel ausgewählt hat, wählen Sie eine Spur lokal. Dies ändert niemals die Server-Preferenz.',
			'settings.autoDownloadPreferredSubtitle' => 'Fettch fehlt bevorzugte Sprachuntertiteln',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Wählen Sie einen verfügbaren Untertitel in Ihrer bevorzugten Sprache lokal aus. Wenn kein vorhanden ist, bitten Sie den Server, einen zu fangen, wenn unterstützt wird.',
			'settings.rememberTrackSelectionsDescription' => 'Audio- und Untertitelauswahl je Titel merken',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex speichert jede Auswahl pro Datei auf dem Server; Jellyfin aktiviert außerdem die Kontooption „Auswahl merken“; Emby wird nicht unterstützt',
			'settings.followServerTrackSelections' => 'Serverseitige Spurauswahl pro Episode verwenden',
			'settings.followServerTrackSelectionsDescription' => 'Beim Episodenwechsel die auf dem Server ausgewählten Audio- und Untertitelspuren übernehmen, statt die aktuelle Auswahl zu übertragen',
			'settings.resumeMusicOnLaunch' => 'Musiksitzung merken',
			'settings.resumeMusicOnLaunchDescription' => 'Beim App-Start den letzten Titel pausiert an der letzten Stelle wieder öffnen',
			'settings.showChapterMarkersOnTimeline' => 'Kapitelmarkierungen auf der Suchleiste anzeigen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Die Suchleiste an Kapitelgrenzen unterteilen',
			'settings.specialsOrdering' => 'Specials in Episodenreihenfolge',
			'settings.specialsOrderingDescription' => 'Wo Specials in der Wiedergabereihenfolge einer Serie abgespielt werden',
			'settings.specialsOrderingServer' => 'Serverreihenfolge folgen',
			'settings.specialsOrderingAirDate' => 'Nach Ausstrahlungsdatum einfügen',
			'settings.specialsOrderingLast' => 'Nach den regulären Staffeln',
			'settings.clickVideoTogglesPlayback' => 'Video zum Abspielen oder Pausieren anklicken',
			'settings.clickVideoTogglesPlaybackDescription' => 'Video zum Abspielen oder Pausieren anklicken, statt die Steuerung anzuzeigen.',
			'settings.videoPlayerControls' => 'Videoplayer-Steuerung',
			'settings.keyboardShortcuts' => 'Tastenkürzel',
			'settings.keyboardShortcutsDescription' => 'Tastenkürzel anpassen',
			'settings.videoPlayerNavigation' => 'Videoplayer-Navigation',
			'settings.videoPlayerNavigationDescription' => 'Mit den Pfeiltasten durch die Videoplayer-Steuerung navigieren',
			'settings.watchTogetherRelay' => 'Relay für gemeinsames Schauen',
			'settings.watchTogetherRelayDescription' => 'Öffentliche Relays von Open Watch Party, sofern du kein eigenes festlegst',
			'settings.watchTogetherRelayHint' => 'https://mein-relay.beispiel.de',
			'settings.watchTogetherRelayInvalid' => 'Gib eine gültige HTTP- oder HTTPS-Basis-URL für das Relay ein.',
			'settings.crashReporting' => 'Absturzberichte',
			'settings.crashReportingDescription' => 'Absturzberichte senden, um die App zu verbessern',
			'settings.debugLogging' => 'Debug-Protokollierung',
			'settings.debugLoggingDescription' => 'Detaillierte Protokolle zur Fehleranalyse aktivieren',
			'settings.viewLogs' => 'Protokolle anzeigen',
			'settings.viewLogsDescription' => 'App-Protokolle anzeigen',
			'settings.clearImageCache' => 'Bildercache leeren',
			'settings.clearImageCacheDescription' => 'Zwischengespeicherte Artworks und Vorschaubilder löschen. Bilder können langsamer laden, bis sie erneut heruntergeladen werden.',
			'settings.clearImageCacheSuccess' => 'Bildercache erfolgreich geleert',
			'settings.resetSettings' => 'Einstellungen zurücksetzen',
			'settings.resetSettingsDescription' => 'Standardeinstellungen wiederherstellen. Dies kann nicht rückgängig gemacht werden.',
			'settings.resetSettingsSuccess' => 'Einstellungen erfolgreich zurückgesetzt',
			'settings.backup' => 'Sicherung',
			'settings.exportSettings' => 'Einstellungen exportieren',
			'settings.exportSettingsDescription' => 'Einstellungen in einer Datei speichern',
			'settings.exportSettingsSuccess' => 'Einstellungen exportiert',
			'settings.importSettings' => 'Einstellungen importieren',
			'settings.importSettingsDescription' => 'Einstellungen aus einer Datei wiederherstellen',
			'settings.importSettingsConfirm' => 'Dies ersetzt deine aktuellen Einstellungen. Fortfahren?',
			'settings.importSettingsSuccess' => 'Einstellungen importiert',
			'settings.importSettingsInvalidFile' => 'Diese Datei ist kein gültiger PlezyNG-Einstellungsexport',
			'settings.importSettingsNoUser' => 'Vor dem Import bitte anmelden',
			'settings.cloudBackup' => 'Cloud-Sicherung',
			'settings.cloudBackupDescription' => 'Sichere übertragbare Einstellungen über HTTPS an einer WebDAV-Adresse. Serververbindungen und Anmeldedaten bleiben auf diesem Gerät.',
			'settings.cloudBackupUrl' => 'WebDAV JSON Datei URL',
			'settings.cloudBackupUsername' => 'Benutzername',
			'settings.cloudBackupPassword' => 'Passwort',
			'settings.cloudBackupSaved' => 'Cloud Backup-Destination gesichert',
			'settings.cloudBackupNow' => 'Zurück jetzt',
			'settings.cloudBackupComplete' => 'Backup-Einstellungen hochgeladen',
			'settings.cloudBackupRestore' => 'Backup wiederherstellen',
			'settings.cloudBackupRestoreConfirm' => 'Dies ersetzt die entsprechenden Portable-Einstellungen auf diesem Gerät.',
			'settings.cloudBackupRestored' => 'Einstellungen wiederhergestellt von Cloud Backup',
			'settings.shortcutsReset' => 'Tastenkürzel auf Standard zurückgesetzt',
			'settings.resetShortcutsConfirm' => 'Dadurch werden deine eigenen Tastenkürzel durch die Standardwerte ersetzt. Fortfahren?',
			'settings.about' => 'Über',
			'settings.aboutDescription' => 'App-Informationen und Lizenzen',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update verfügbar',
			'settings.checkForUpdates' => 'Nach Updates suchen',
			'settings.autoCheckUpdatesOnStartup' => 'Beim Start automatisch nach Updates suchen',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Beim Start benachrichtigen, wenn ein Update verfügbar ist',
			'settings.validationErrorEnterNumber' => 'Bitte eine gültige Zahl eingeben',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Tastenkürzel aktualisiert für ${action}',
			'settings.saveFailed' => 'Änderungen konnten nicht gespeichert werden. Versuche es erneut.',
			'settings.autoPlayAndSkip' => 'Autoplay & Überspringen',
			'settings.autoPlayNextEpisode' => 'Nächste Episode automatisch abspielen',
			'settings.autoPlayNextEpisodeDescription' => 'Die nächste Episode automatisch starten, wenn die aktuelle endet',
			'settings.shuffleStartsFromBeginning' => 'Zufallswiedergabe beginnt am Anfang',
			'settings.shuffleStartsFromBeginningDescription' => 'Bei Zufallswiedergabe jede Episode von Anfang an abspielen, statt sie fortzusetzen',
			'settings.plexCinemaPreRoll' => 'Anwendung von Server Cinema Intros',
			'settings.plexCinemaPreRollDescription' => 'Spielen Sie vor dem Film konfigurierte Plex Pre-Rolls oder Jellyfin und Emby Inträge.',
			'settings.playNextCountdown' => 'Countdown bis zur nächsten Episode',
			'settings.playNextCountdownImmediate' => 'Sofort abspielen',
			'settings.skipIntroMode' => 'Intro überspringen',
			'settings.skipIntroModeOffDescription' => 'Intros normal abspielen, ohne Schaltfläche zum Überspringen',
			'settings.skipIntroModeButtonDescription' => 'Schaltfläche zum Überspringen anzeigen, wenn ein Intro beginnt',
			'settings.skipIntroModeAutoDescription' => 'Intros nach der untenstehenden Verzögerung automatisch überspringen',
			'settings.skipCreditsMode' => 'Abspann überspringen',
			'settings.skipCreditsModeOffDescription' => 'Abspann normal abspielen, ohne Schaltfläche zum Überspringen',
			'settings.skipCreditsModeButtonDescription' => 'Schaltfläche zum Überspringen anzeigen, wenn der Abspann beginnt',
			'settings.skipCreditsModeAutoDescription' => 'Abspann automatisch überspringen und die nächste Episode abspielen',
			'settings.skipAdsMode' => 'Werbung überspringen',
			'settings.skipAdsModeOffDescription' => 'Spielen Sie aufgeführte Werbung normalerweise ohne einen Skip-Button',
			'settings.skipAdsModeButtonDescription' => 'Zeigen Sie einen Skip-Button an, wenn Plex eine Werbung erkennt',
			'settings.skipAdsModeAutoDescription' => 'Entfernen Sie die aufgezeigten Anzeigen automatisch nach der Verzögerung unten',
			'settings.musicPlayback' => 'Musik Playback',
			'settings.musicSweetFades' => 'Süße Faden',
			'settings.musicSweetFadesDescription' => 'Fade Musik an Spurenräumen, wenn Plex Lautstärke-Daten hat. Album-Playback bleibt unverändert.',
			'settings.skipMarkerModeOff' => 'Aus',
			'settings.skipMarkerModeButton' => 'Schaltfläche anzeigen',
			'settings.skipMarkerModeAuto' => 'Automatisch',
			'settings.forceSkipMarkerFallback' => 'Ersatzmarkierungen erzwingen',
			'settings.forceSkipMarkerFallbackDescription' => 'Kapitel-Titelmuster auch dann verwenden, wenn Plex über Markierungen verfügt',
			'settings.theIntroDbFallback' => 'Verwenden Sie TheIntroDB als Eintröpfungsfall',
			'settings.theIntroDbFallbackDescription' => 'Verwenden Sie Community Timings nur, wenn der Server keinen Eintrommer hat.',
			'settings.autoSkipDelay' => 'Verzögerung für automatisches Überspringen',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten',
			'settings.introPattern' => 'Intro-Markierungsmuster',
			'settings.introPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln',
			'settings.creditsPattern' => 'Abspann-Markierungsmuster',
			'settings.creditsPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln',
			'settings.prerolls' => 'Vorliegen',
			'settings.playPrerollsBeforeMovies' => 'Spielen Sie Prerolls vor den Filmen',
			'settings.playPrerollsBeforeMoviesDescription' => 'Spielen Sie einen Random-Clip aus Ihrer Auswahl unten vor jedem Film.',
			'settings.prerollLibrary' => 'Preroll Bibliothek',
			'settings.prerollLibraryNotSet' => 'Nicht festgelegt',
			'settings.prerollLibraryNoneFound' => 'Keine Bibliotheken auf Ihren Servern gefunden.',
			'settings.prerollSelection' => 'ausgewählte Prerolle',
			'settings.prerollSelectionPickLibraryFirst' => 'Wählen Sie zuerst eine Bibliothek',
			'settings.prerollSelectionNoneSelected' => 'Keine Prerolle ausgewählt',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} ausgewählt',
			'settings.prerollItemPicker' => 'Prerolle auswählen',
			'settings.prerollItemPickerLoadFailed' => 'Ich konnte keine Artikel aus dieser Bibliothek laden.',
			'settings.invalidRegex' => 'Ungültiger regulärer Ausdruck',
			'settings.regex' => 'Regulärer Ausdruck',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Speicherort für heruntergeladene Inhalte wählen',
			'settings.downloadLocationDefault' => 'Standard (App-Speicher)',
			'settings.downloadLocationCustom' => 'Benutzerdefinierter Speicherort',
			'settings.selectFolder' => 'Ordner auswählen',
			'settings.resetToDefault' => 'Auf Standard zurücksetzen',
			'settings.currentPath' => ({required Object path}) => 'Aktuell: ${path}',
			'settings.downloadLocationChanged' => 'Download-Speicherort geändert',
			'settings.downloadLocationReset' => 'Download-Speicherort auf Standard zurückgesetzt',
			'settings.downloadLocationInvalid' => 'Ausgewählter Ordner ist nicht beschreibbar',
			'settings.downloadLocationPickerUnavailable' => 'Die Ordnerauswahl ist auf diesem Gerät nicht verfügbar',
			'settings.downloadOnWifiOnly' => 'Nur über WLAN herunterladen',
			'settings.downloadOnWifiOnlyDescription' => 'Downloads über mobile Daten verhindern',
			'settings.autoRemoveWatchedDownloads' => 'Gesehene Downloads automatisch entfernen',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Angesehene Downloads automatisch löschen',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Weiterlesen',
			'settings.autoDownloadContinueWatchingDescription' => 'Halten Sie die Elemente auf Ihrem Continue Watching Schild heruntergeladen und entfernen Sie sie, sobald sie die Schild verlassen',
			'settings.downloadQuality' => 'Download Qualität',
			'settings.downloadQualityDescription' => 'Plex bereitet eine konvertierte Kopie in seinem Download-Quelle vor. Jellyfin und Emby Transcode während der Datei heruntergeladen wird; geschlossenen Übertragungen können neu gestartet werden müssen.',
			'settings.askDownloadQualityEachTime' => 'Qualität für jede Download',
			'settings.askDownloadQualityEachTimeDescription' => 'Zeigen Sie den Qualitätspiker vor der Abrechnung jedes Video herunterladen',
			'settings.cellularDownloadBlocked' => 'Downloads über das Mobilfunknetz sind blockiert. Nutze WLAN oder ändere die Einstellung.',
			'settings.maxVolume' => 'Maximale Lautstärke',
			'settings.maxVolumeDescription' => 'Lautstärkeanhebung über 100 % für leise Medien erlauben',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent} %',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Auf Discord anzeigen, was du gerade schaust',
			'settings.services' => 'Dienste',
			'settings.servicesDescription' => 'Trakt, MyAnimeList, Seerr und mehr verbinden',
			'settings.manageLibrariesDescription' => 'Mediatheken neu anordnen und ausblenden',
			'settings.companionRemoteServer' => 'Companion-Fernbedienungsserver',
			'settings.companionRemoteServerDescription' => 'Mobilgeräten in deinem Netzwerk erlauben, diese App zu steuern',
			'settings.companionRemoteServerStartFailed' => 'Companion-Fernbedienungsserver konnte nicht gestartet werden',
			'settings.companionRemoteServerStopFailed' => 'Companion-Fernbedienungsserver konnte nicht gestoppt werden',
			'settings.autoPip' => 'Automatisches Bild-in-Bild',
			'settings.autoPipDescription' => 'Beim Verlassen der App während der Wiedergabe automatisch Bild-in-Bild starten',
			'settings.matchContentFrameRate' => 'Inhalts-Bildrate anpassen',
			'settings.matchContentFrameRateDescription' => 'Bildwiederholrate des Displays an Videoinhalt anpassen',
			'settings.matchContentResolution' => 'An Auflösung des Inhalts anpassen',
			'settings.matchContentResolutionDescription' => 'Wechselt die Anzeige auf die native Auflösung des Videos, damit dein Fernseher das Hochskalieren übernimmt. Menüs und Untertitel werden während der Wiedergabe ebenfalls hochskaliert',
			'settings.matchRefreshRate' => 'Bildwiederholrate anpassen',
			'settings.matchRefreshRateDescription' => 'Bildwiederholrate im Vollbild anpassen',
			'settings.matchDynamicRange' => 'Dynamikumfang anpassen',
			'settings.matchDynamicRangeDescription' => 'HDR für HDR-Inhalte einschalten, danach zurück zu SDR',
			'settings.displaySwitchDelay' => 'Verzögerung beim Displaywechsel',
			'settings.tunneledPlayback' => 'Tunnelwiedergabe',
			'settings.tunneledPlaybackDescription' => 'Video-Tunneling verwenden. Deaktivieren, wenn HDR-Wiedergabe schwarzes Video zeigt oder Bewegungen ruckeln.',
			'settings.audioPassthrough' => 'Audio-Durchleitung',
			'settings.audioPassthroughDescription' => 'Dolby/DTS-Audio ohne Neukodierung an deinen Receiver oder Fernseher senden und Surround-Sound erhalten. Deaktivieren, wenn kein Ton zu hören ist.',
			'settings.audioPassthroughDescriptionApple' => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. DTS und TrueHD werden weiterhin als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. Unter iOS, iPadOS und tvOS 26 oder neuer werden TrueHD Atmos und DTS:X als 3D-Audio wiedergegeben. Andere DTS- und TrueHD-Spuren werden als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Aus, solange die Lautstärkenormalisierung aktiv ist',
			'settings.audioChannelLimit' => 'Audiokanäle',
			'settings.audioChannelLimitDescription' => 'Dekodierten Ton für Lautsprecher, Kopfhörer oder HDMI-Setups heruntermischen, die nicht alle Kanäle wiedergeben können',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Alle Kanäle der Spur wiedergeben',
			'settings.audioChannelLimitSurround51' => 'Bis zu 5.1',
			'settings.audioChannelLimitSurround51Description' => '7.1 auf 5.1 heruntermischen für Fernseher und Receiver, die nur 5.1-PCM annehmen. Die Durchleitung ist davon nicht betroffen.',
			'settings.audioChannelLimitStereo' => 'Stereo',
			'settings.audioChannelLimitStereoDescription' => 'Auf zwei Kanäle für Stereolautsprecher oder Kopfhörer heruntermischen. Deaktiviert die Durchleitung.',
			'settings.downmixCenterBoost' => 'Verstärkung des Center-Kanals',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Verstärkung (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Lautstärke beim Downmix normalisieren',
			'settings.audioDownmixNormalizeDescription' => 'Senkt den Mix ab, um Übersteuerung zu vermeiden. Deaktivieren, um die Originallautstärke zu behalten (laute Szenen können verzerren).',
			'settings.dvConversionMode' => 'Dolby-Vision-Konvertierung',
			'settings.dvConversionModeDescription' => 'Wähle, wie Dateien mit Dolby-Vision-Profil 7 behandelt werden.',
			'settings.dvConversionAuto' => 'Automatisch',
			'settings.dvConversionNative' => 'Nativ / deaktiviert',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Gerätefähigkeiten erkennen und normales Fallback-Verhalten verwenden',
			'settings.dvConversionNativeDescription' => 'Natives DV7 erzwingen und einen erneuten DV-Konvertierungsversuch unterdrücken',
			'settings.dvConversionDv81Description' => 'Inline-RPU-Konvertierung in Dolby-Vision-Profil 8.1 erzwingen',
			'settings.dvConversionHevcStripDescription' => 'Dolby-Vision-RPU/EL-Schichten entfernen und reines HEVC ausgeben',
			'settings.experimentalDolbyVision' => 'Experimentelles Dolby Vision',
			'settings.experimentalDolbyVisionDescription' => 'Bei der nächsten Wiedergabe den experimentellen FEL-Renderer verwenden. Erfordert einen separat erstellten Wiedergabekern.',
			'settings.dvExperimentUnavailableDescription' => 'Dieses Experiment ist derzeit nur unter Linux verfügbar.',
			'settings.dvCompatibilityFallback' => 'Kompatibilitätsfallback',
			'settings.dvCompatibilityFallbackDescription' => 'Den Standard-Renderer verwenden, falls das Experiment nicht startet. FEL-Daten können verloren gehen.',
			'settings.dvExperimentDiagnostics' => 'Videoexperiment protokollieren',
			'settings.dvExperimentDiagnosticsDescription' => 'Bei der nächsten Wiedergabe ausführliche Player-Protokolle aktivieren.',
			'settings.disableDolbyVision' => 'Dolby Vision deaktivieren',
			'settings.disableDolbyVisionDescription' => 'Statt Dolby Vision die HDR10- oder HLG-Ebene der Datei abspielen, sofern vorhanden',
			'settings.hdrSdrConversion' => 'HDR-zu-SDR-Konvertierung',
			'settings.hdrSdrConversionDescription' => 'Wähle, was HDR-Videos umwandelt, wenn das Display kein HDR darstellen kann.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automatisch',
			'settings.hdrSdrConversionAutoDescription' => 'Gerät ab Android 9, Player bei älteren Versionen',
			'settings.hdrSdrConversionDevice' => 'Gerät',
			'settings.hdrSdrConversionDeviceDescription' => 'Die Videohardware des Geräts wandelt um. Am schnellsten, die Farben hängen aber vom Gerät ab',
			'settings.hdrSdrConversionPlayer' => 'Player',
			'settings.hdrSdrConversionPlayerDescription' => 'Der Player wandelt um. Einheitliche Farben, aber 4K kann auf schwachen TV-Boxen ruckeln',
			'settings.deinterlace' => 'Deinterlacing',
			'settings.deinterlaceDescription' => 'Kammartefakte aus interlaced Videos entfernen (nur mpv-Player)',
			'settings.deinterlaceOff' => 'Aus',
			'settings.deinterlaceOffDescription' => 'Interlaced Video so anzeigen, wie es dekodiert wird',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Jedes Halbbild zu einem Vollbild machen. Für TV-Aufnahmen wie Sport, Nachrichten und Konzerte',
			'settings.deinterlaceFilm' => 'Film',
			'settings.deinterlaceFilmDescription' => 'Die Originalbilder von Filmen und Animationen wiederherstellen, die per Telecine auf 29,97 fps gebracht wurden – üblich bei NTSC-DVDs. TV-Aufnahmen ruckeln dabei. Live TV verwendet „Video“',
			'settings.requireProfileSelectionOnOpen' => 'Profil beim Öffnen abfragen',
			'settings.requireProfileSelectionOnOpenDescription' => 'Profilauswahl bei jedem Öffnen der App anzeigen',
			'settings.forceTvMode' => 'TV-Modus erzwingen',
			'settings.forceTvModeDescription' => 'TV-Layout erzwingen. Für Geräte ohne automatische Erkennung. Neustart erforderlich.',
			'settings.startInFullscreen' => 'Im Vollbildmodus starten',
			'settings.startInFullscreenDescription' => 'PlezyNG beim Start im Vollbildmodus öffnen',
			'settings.exitFullscreenOnPlayerClose' => 'Vollbild beim Schließen des Players beenden',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Vollbildmodus automatisch beenden, wenn der Videoplayer geschlossen wird',
			'settings.autoHidePerformanceOverlay' => 'Leistungsoverlay automatisch ausblenden',
			'settings.autoHidePerformanceOverlayDescription' => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden',
			'settings.showNavBarLabels' => 'Navigationsleisten-Beschriftungen anzeigen',
			'settings.showNavBarLabelsDescription' => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen',
			'settings.startupSection' => 'Startbereich',
			'settings.preferredServer' => 'Vorliegende Server',
			'settings.preferredServerDescription' => 'Prioritieren Sie die Ergebnisse dieses Servers und halten Sie jeden verbundenen Server zur Verfügung.',
			'settings.preferredServerAutomatic' => 'Automatisch',
			'settings.showExploreTab' => 'Tab „Entdecken“ anzeigen',
			'settings.showExploreTabDescription' => 'Zeigt den Tab „Entdecken“ mit Inhalten aus Plex Discover und verbundenen Trackern an',
			'settings.hideEmptyLibraries' => 'Die leeren Bibliotheken verstecken',
			'settings.hideEmptyLibrariesDescription' => 'Entfernen Sie Bibliotheken mit einem Server-berichten von Null-Einheiten aus der Navigation.',
			'settings.liveTvDefaultFavorites' => 'Standardmäßig Favoritenkanäle',
			'settings.liveTvDefaultFavoritesDescription' => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen',
			'settings.general' => 'Allgemein',
			'settings.generalDescription' => 'Sprache, Start und Fensterverhalten',
			'settings.languageAndRegion' => 'Sprache & Region',
			'settings.startup' => 'Start',
			'settings.display' => 'Anzeige',
			'settings.libraryAndCards' => 'Mediathek & Karten',
			'settings.homeScreen' => 'Startseite',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Fenster',
			'settings.liveTv' => 'Live-TV',
			'settings.player' => 'Wiedergabe',
			'settings.videoAndDisplay' => 'Video & Anzeige',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Qualität',
			'settings.subtitles' => 'Untertitel',
			'settings.seekAndTiming' => 'Spulen & Timing',
			'settings.behavior' => 'Verhalten',
			'settings.gestures' => 'Gesten',
			'settings.gestureBrightnessSwipe' => 'Wischen für Helligkeit',
			'settings.gestureBrightnessSwipeDescription' => 'Wische am linken Rand nach oben oder unten, um die Helligkeit anzupassen',
			'settings.gestureVolumeSwipe' => 'Wischen für Lautstärke',
			'settings.gestureVolumeSwipeDescription' => 'Wische am rechten Rand nach oben oder unten, um die Lautstärke anzupassen',
			'settings.gesturePinchToZoom' => 'Zum Zoomen kneifen',
			'settings.gesturePinchToZoomDescription' => 'Kneife auf dem Video, um hinein- oder herauszuzoomen',
			'settings.gestureSeekSwipe' => 'Suche Swipe',
			'settings.gestureSeekSwipeDescription' => 'Schieben Sie links oder rechts überall auf dem Video, um zu suchen; freigeben Sie zum Springen',
			'settings.rememberBrightnessLevel' => 'Helligkeitsstufe merken',
			'settings.rememberBrightnessLevelDescription' => 'Wiedergabe mit der zuletzt per Wischgeste eingestellten Helligkeit starten',
			'settings.controls' => 'Steuerung',
			'settings.rememberPlayerChanges' => 'Playeränderungen merken',
			'settings.rememberPlayerChangesDescription' => 'Wo eine während der Wiedergabe vorgenommene Änderung gespeichert und erneut angewendet wird',
			'settings.scopePlaybackSpeed' => 'Wiedergabegeschwindigkeit',
			'settings.scopeShaderPreset' => 'Shader-Voreinstellung',
			'settings.scopeAspectRatio' => 'Seitenverhältnis',
			'settings.scopeSyncOffsets' => 'Audio- und Untertitelsynchronisierung',
			'settings.playerScopeOff' => 'Nicht speichern',
			'settings.playerScopeGlobal' => 'Überall',
			'settings.playerScopeLibrary' => 'Pro Bibliothek',
			'settings.playerScopeTitle' => 'Pro Serie oder Film',
			'settings.exportDialogTitle' => 'PlezyNG-Einstellungen exportieren',
			'settings.followSystem' => 'Systemsprache verwenden',
			'settings.followAppLanguage' => 'Wie die Sprache der Oberfläche',
			'settings.regionFormat' => 'Regionale Formate',
			'settings.regionFormatDescription' => 'Wähle, wie Datumsangaben, Zahlen und Maßeinheiten angezeigt werden.',
			'settings.metadataLanguage' => 'Sprache der Metadaten',
			'settings.metadataLanguageDescription' => 'Bevorzugte Sprache für Titel und Beschreibungen, sofern vom Server unterstützt. Audio- und Untertitelsprachen werden separat eingestellt.',
			'settings.enterFullscreenOnPlaybackStart' => 'Geben Sie den Vollbildschirm ein, wenn das Playback beginnt',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Öffnen Sie Desktop-Video auf Vollbildschirm, wenn der Playback beginnt',
			'settings.extendVideoIntoDisplayCutout' => 'Erweiterung des Videos in Display Cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Lassen Sie Full-Screen-Videos die Kamera auf Android-Telefonen verwenden',
			'settings.languageDescription' => 'Wählen Sie die für PlezyNG-Kontrollen und Nachrichten verwendete Sprache aus. Folgen Sie dem System, der Ihre Gerätesprache verfolgt.',
			'settings.themeDescription' => 'Wählen Sie die Farben und Kontraste, die in der gesamten App verwendet werden.',
			'settings.libraryDensityDescription' => 'Ändern Sie, wie viele Bibliothekkarten in jeder Reihe passen.',
			'settings.displayScaleDescription' => 'Wiederherstellen Sie die Schnittstelle auf diesem Auto-Display, ohne die Textgröße Ihres Geräts zu ändern.',
			'settings.themeSongVolumeDescription' => 'Setzen Sie das Volumen der thematischen Songs im Verhältnis zu anderen Audio.',
			'settings.viewModeDescription' => 'Wählen Sie aus, ob Bibliothek-Elemente als Poster in einem Netzwerk oder als kompakte Liste erscheinen.',
			'settings.gridViewDescription' => 'Ordnen Sie Bibliothekartikel in Zeilen und Spalten von Postern.',
			'settings.listViewDescription' => 'Zeigen Sie Bibliothek-Elemente in einer vertikalen Liste mit mehr Text pro Artikel.',
			'settings.gridSpacingDescription' => 'Setzen Sie den Abstand zwischen Postern in Bibliotheknetzwerken.',
			'settings.gridSpacingTightDescription' => 'Fügen Sie mehr Poster über dem Bildschirm mit kleineren Lücken.',
			'settings.gridSpacingNormalDescription' => 'Verwenden Sie den Standardverhältnis zwischen Postern.',
			'settings.gridSpacingSpaciousDescription' => 'Hinzufügen Sie größere Lücken zwischen Postern für mehr Trennung.',
			'settings.episodePosterModeDescription' => 'Wählen Sie aus, welches Kunstwerk auf Episodkarten erscheint.',
			'settings.seriesPosterDescription' => 'Verwenden Sie die Serie-Poster für jede Episode.',
			'settings.seasonPosterDescription' => 'Verwenden Sie den Saisonplakat für jede Episode, wenn verfügbar.',
			'settings.episodeThumbnailDescription' => 'Verwenden Sie ein Rahmen aus der Episode, wenn verfügbar.',
			'settings.continueWatchingActionDescription' => 'Wählen Sie aus, was passiert, wenn Sie eine Continue Watching-Karte aktivieren.',
			'settings.continueWatchingPlayDescription' => 'Beginnen Sie den Film oder die Episode sofort.',
			'settings.continueWatchingDetailsDescription' => 'Öffnen Sie zunächst die Titelseite, damit Sie Details überprüfen und eine Aktion wählen können.',
			'settings.episodeActionDescription' => 'Wählen Sie aus, was passiert, wenn Sie eine Episode-Karte aktivieren.',
			'settings.episodePlayDescription' => 'Beginnen Sie die Episode sofort.',
			'settings.episodeDetailsDescription' => 'Öffnen Sie die Episode-Seite vor dem Playback.',
			'settings.contentScreensaverDelayDescription' => 'Wählen Sie aus, wie lange PlezyNG ohne Eintritt wartet, bevor Sie Kunstwerke zeigen.',
			'settings.continueWatchingRowSizeDescription' => 'Wählen Sie aus, wie groß die Karten in der Folge-Beobachtung-Reihe sind.',
			'settings.rowSizeCompactDescription' => 'Zeigen Sie kleinere Karten, so dass mehr Elemente über die Reihe passen.',
			'settings.rowSizeStandardDescription' => 'Verwenden Sie die Standardkarte Größe.',
			'settings.rowSizeLargeDescription' => 'Zeigen Sie größere Karten mit mehr Kunstwerke Details.',
			'settings.visualEffectsDescription' => 'Wählen Sie den Animations- und Kunstwerkeffekte Budget für dieses Gerät aus.',
			'settings.visualEffectsFullDescription' => 'Verwenden Sie die vollständigen Animations- und Kunstwerkeffekte auf jedem Gerät.',
			'settings.startupSectionDescription' => 'Wählen Sie aus, welcher Abschnitt sich öffnet, wenn PlezyNG beginnt.',
			'settings.startupSectionOptions.discover' => 'Öffnen Sie Empfehlungen und Artikel aus verbundenen Entdeckungsquellen.',
			'settings.startupSectionOptions.libraries' => 'Öffnen Sie Ihre verbundenen Medienbibliotheken.',
			'settings.startupSectionOptions.liveTv' => 'Öffnen Sie Live TV, wenn ein Server es bereitstellt; sonst fällt das Startup zurück zu Home.',
			'settings.startupSectionOptions.search' => 'Öffnen Medien suchen.',
			'settings.smallSkipDurationDescription' => 'Setzen Sie die Entfernung, die durch den kurzen Rückweg und vorwärts nach Kontrolle bewegt wird.',
			'settings.largeSkipDurationDescription' => 'Setzen Sie die Entfernung, die durch den langen Rückweg und vorwärts nach Kontrolle bewegt wird.',
			'settings.rewindOnResumeDescription' => 'Move Playback zurück mit diesem Betrag, wenn Sie ein Video wiederholen.',
			'settings.defaultSleepTimerDescription' => 'Setzen Sie die ursprüngliche Dauer, die verwendet wird, wenn Sie den Schlaftimeter starten.',
			'settings.playNextCountdownDescription' => 'Warten Sie lange darauf, bevor die nächste Episode beginnt. Set auf 0 um sofort zu beginnen.',
			'settings.autoSkipDelaySettingDescription' => 'Geltend ist, wenn eine Einführung, Kredit oder Werbung automatisch ausgeschieden wird.',
			'settings.downmixCenterBoostDescription' => 'Erhöhen Sie den Dialog im Zentralkanal, wenn das umliegende Audio nach unten in Stereo gemischt wird.',
			'settings.displaySwitchDelayDescription' => 'Warten Sie, bevor Sie den Displaymodus ändern, damit der Fernseher oder Empfänger seinen vorherigen Schalter beenden kann.',
			'settings.playerBackendDescription' => 'Wählen Sie aus, welcher Playback-Motor Video auf diesem Gerät dekodiert und rendiert.',
			'settings.exoPlayerDescription' => 'Verwenden Sie Android native Media3-basierte Player und unterstützte Hardware-Paths.',
			'settings.mpvDescription' => 'Verwenden Sie MPV, die zusätzliche Playback, Subtitle und Video-Verarbeitungskontrolle exponiert.',
			'settings.scopeOffDescription' => 'Behalten Sie Änderungen für die aktuelle Playback-Sitzung nur.',
			'settings.scopeGlobalDescription' => 'Wieder verwenden Sie den gleichen Wert für jede Bibliothek und Titel.',
			'settings.scopeLibraryDescription' => 'Erinnern Sie sich an einen separaten Wert für jede Bibliothek.',
			'settings.scopeTitleDescription' => 'Erinnern Sie sich an einen separaten Wert für jede Show oder Film.',
			'settings.specialsOrderingServerDescription' => 'Halten Sie die Episode Order, die vom Medien-Server bereitgestellt wird.',
			'settings.specialsOrderingAirDateDescription' => 'Stellen Sie spezielle unter regelmäßigen Episoden nach ihrem Flugdatum.',
			'settings.specialsOrderingLastDescription' => 'Platzieren Sie alle speziellen nach den regelmäßigen Jahreszeiten.',
			'settings.skipIntroModeDescription' => 'Wählen Sie aus, ob die Intro-Marker normalerweise spielen, einen Skip-Button anzeigen oder automatisch springen.',
			'settings.skipCreditsModeDescription' => 'Wählen Sie aus, ob die Credits normalerweise spielen, zeigen Sie einen Skip-Button oder automatisch springen.',
			'settings.skipAdsModeDescription' => 'Wählen Sie aus, ob die aufgezeigten Anzeigen normalerweise gespielt werden, einen Skip-Button anzeigen oder automatisch springen.',
			'settings.playbackBufferAutoDescription' => 'Lassen Sie den aktiven Spieler seine normale Buffergröße wählen.',
			'settings.playbackBufferLargeDescription' => 'Halten Sie mehr Medien vor dem Playback bereit; dies nutzt mehr Speicher.',
			'settings.playbackBufferExtraLargeDescription' => 'Halten Sie den größten Read-ahead Buffer; dies nutzt die meisten Gedächtnis.',
			'settings.defaultQualityDescription' => 'Setzen Sie die standardmäßige Video-Resolution und Bitrate Dach für Streams, die der Server transcodiert.',
			'settings.cellularQualityDescription' => 'Übertreiben Sie die Standardqualität, wenn das Gerät eine cellular-only Verbindung verwendet.',
			'settings.remoteQualityDescription' => 'Override Default Quality bei der Verbindung zu einem Server über eine Fernverbindung.',
			'settings.qualityPresetOriginalDescription' => 'Spielen Sie die Quelle in ihrer verfügbaren Qualität, ohne den Server um Transcode zu bitten.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Befragen Sie den Server für einen konvertierten Stream mit der oben angezeigten Auflösung und Bitrate.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Verwenden Sie die in Default Quality ausgewählte Qualität.',
			'settings.musicQualityDescription' => 'Setzen Sie die maximale Audio-Bitrate, die vom Server angefordert wird; Original behält den Quellstrom.',
			'settings.musicQualityOriginalDescription' => 'Speichern Sie das Quell-Audio ohne einen Bitrate-Capped Transcode.',
			'settings.musicQualityTranscodeOptionDescription' => 'Erfordern Sie einen Server-Transcode, der in der Nähe des oben angezeigten Bitrate gefasst ist; die tatsächliche Ausgabe kann sich ändern.',
			'settings.maxVolumeInputLabel' => 'Höchstvolumen ( % )',
			'settings.checkForUpdatesDescription' => 'Überprüfen Sie jetzt, ob eine neuere Version von PlezyNG verfügbar ist.',
			'settings.appearanceDescription' => 'Wählen Sie das App-Theme aus und bearbeiten Sie Bibliothekkarte, Heimräume und Navigation.',
			'settings.prerollLibraryDescription' => 'Wählen Sie die Bibliothek aus, in der die Clips als Filmpre-Rolls verfügbar sind.',
			'settings.prerollSelectionDescription' => 'Wählen Sie, welche Clips aus der ausgewählten Bibliothek vor den Filmen spielen können.',
			'settings.contentScreensaverDelayOptionDescription' => 'Warten Sie viele Minuten ohne Eingabe, bevor Sie Screensaver Artwork anzeigen.',
			'settings.videoCodecOptionDescription' => 'Erlauben Sie Live-Playback für diesen Codec, wenn er unterstützt wird. Unchecked Codecs werden vom Media Server überkodiert.',
			'themeEditor.builtIn' => 'Integriert',
			'themeEditor.presets' => 'Vorlagen',
			'themeEditor.custom' => 'Benutzerdefiniert',
			'themeEditor.customEmpty' => 'Noch nicht erstellt',
			'themeEditor.editCustom' => 'Eigenes Design bearbeiten',
			'themeEditor.editCustomDescription' => 'Jede Farbe selbst wählen',
			'themeEditor.locked' => 'Lebensdauer Zugang erforderlich',
			'themeEditor.savedLocked' => 'Sparen – mit lebenslangem Zugang verfügbar',
			'themeEditor.title' => 'Eigenes Design',
			'themeEditor.startFrom' => 'Basierend auf',
			'themeEditor.startFromDescription' => 'Alle Farben aus einem anderen Design übernehmen',
			'themeEditor.colors' => 'Farben',
			'themeEditor.preview' => 'Vorschau',
			'themeEditor.slots.bg' => 'Hintergrund',
			'themeEditor.slots.surface' => 'Oberfläche',
			'themeEditor.slots.outline' => 'Kontur',
			'themeEditor.slots.text' => 'Text',
			'themeEditor.slots.textMuted' => 'Sekundärtext',
			'themeEditor.slots.accent' => 'Akzent',
			'themeEditor.opacity' => 'Deckkraft',
			'themeEditor.hexHint' => '#RRGGBB oder #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'Aus anderen Designs',
			'themeEditor.swatchLabel' => ({required Object theme, required Object color}) => '${theme}: ${color}',
			'themeEditor.contrast.textOnBg' => 'Text auf Hintergrund',
			'themeEditor.contrast.textOnSurface' => 'Text auf Oberfläche',
			'themeEditor.contrast.textMutedOnBg' => 'Sekundärtext auf Hintergrund',
			'themeEditor.contrast.textMutedOnSurface' => 'Sekundärtext auf Oberfläche',
			'themeEditor.contrast.accentOnBg' => 'Akzent auf Hintergrund',
			'themeEditor.contrast.accentOnSurface' => 'Akzent auf Oberfläche',
			'themeEditor.contrast.labelOnAccent' => 'Schaltflächentext auf Akzent',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, unter den empfohlenen ${minimum}:1',
			'themeEditor.discardTitle' => 'Änderungen verwerfen?',
			'themeEditor.discardMessage' => 'Deine nicht gespeicherten Farbänderungen gehen verloren.',
			'themeEditor.discard' => 'Verwerfen',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Folge ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => 'Noch ${minutes} Min.',
			'themeEditor.previewSwitch' => 'Autoplay',
			'themeEditor.previewMutedText' => 'So sieht Sekundärtext aus',
			'themeEditor.themeSystemDescription' => 'Folgen Sie dem Aussehen Ihres Geräts und wechseln Sie automatisch zwischen Licht und Dunkel.',
			'themeEditor.themeLightDescription' => 'Verwenden Sie einen hellen Hintergrund mit dunkler Text.',
			'themeEditor.themeDarkDescription' => 'Verwenden Sie einen dunklen Hintergrund mit leichten Texten.',
			'themeEditor.themeOledDescription' => 'Verwenden Sie nahschwarze Oberflächen, die Licht auf OLED-Displays reduzieren.',
			'themeEditor.themeEmberDescription' => 'Verwenden Sie warme rote und amber-Accentfarben.',
			'themeEditor.themeGlacierDescription' => 'Verwenden Sie cool blaue Akzente Farben.',
			'themeEditor.themeForestDescription' => 'Verwenden Sie gemütete grüne und natürliche Accent Farben.',
			'themeEditor.themePlumDescription' => 'Verwenden Sie violette und plum accent Farben.',
			'themeEditor.themePaperDescription' => 'Verwenden Sie warme Papierflächen und Ink-inspirierte Farben.',
			'themeEditor.themeCustomDescription' => 'Verwenden Sie die Farbpalette, die Sie in der angepassten Theme-Editor erstellt haben.',
			'themeEditor.editorDescription' => 'Wählen Sie eine Palettefarbe, bearbeiten Sie ihre Farbe, Sättigung, Glanz oder Offenheit und sehen Sie die Aktualisierung des Vorgangs vor dem Speichern.',
			'search.hint' => 'Filme, Serien und Musik suchen …',
			'search.tryDifferentTerm' => 'Anderen Suchbegriff versuchen',
			'search.searchYourMedia' => 'In den eigenen Medien suchen',
			'search.enterTitleActorOrKeyword' => 'Titel, Schauspieler oder Stichwort eingeben',
			'search.people' => 'Personen',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}',
			'hotkeys.clearShortcut' => 'Kürzel löschen',
			'hotkeys.noShortcutSet' => 'Kein Tastenkürzel festgelegt',
			'hotkeys.currentShortcut' => 'Aktuelle Tastenkombination:',
			'hotkeys.pressToRecord' => 'Auswählen, um eine Tastenkombination aufzuzeichnen',
			'hotkeys.recordingShortcut' => 'Jetzt die Tastenkombination drücken',
			'hotkeys.actions.playPause' => 'Wiedergabe/Pause',
			'hotkeys.actions.volumeUp' => 'Lauter',
			'hotkeys.actions.volumeDown' => 'Leiser',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Vorspulen (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Zurückspulen (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Vollbild umschalten',
			'hotkeys.actions.muteToggle' => 'Stumm umschalten',
			'hotkeys.actions.subtitleToggle' => 'Untertitel umschalten',
			'hotkeys.actions.audioTrackNext' => 'Nächste Audiospur',
			'hotkeys.actions.subtitleTrackNext' => 'Nächste Untertitelspur',
			'hotkeys.actions.chapterNext' => 'Nächstes Kapitel',
			'hotkeys.actions.chapterPrevious' => 'Vorheriges Kapitel',
			'hotkeys.actions.episodeNext' => 'Nächste Episode',
			'hotkeys.actions.episodePrevious' => 'Vorherige Episode',
			'hotkeys.actions.speedIncrease' => 'Geschwindigkeit erhöhen',
			'hotkeys.actions.speedDecrease' => 'Geschwindigkeit verringern',
			'hotkeys.actions.speedReset' => 'Geschwindigkeit zurücksetzen',
			'hotkeys.actions.zoomIn' => 'Vergrößern',
			'hotkeys.actions.zoomOut' => 'Verkleinern',
			'hotkeys.actions.zoomReset' => 'Zoom zurücksetzen',
			'hotkeys.actions.subSeekNext' => 'Zum nächsten Untertitel springen',
			'hotkeys.actions.subSeekPrev' => 'Zum vorherigen Untertitel springen',
			'hotkeys.actions.subtitleDelayIncrease' => 'Untertitel verzögern',
			'hotkeys.actions.subtitleDelayDecrease' => 'Untertitel vorziehen',
			'hotkeys.actions.shaderToggle' => 'Shader umschalten',
			'hotkeys.actions.skipMarker' => 'Intro/Abspann überspringen',
			'hotkeys.actions.screenshot' => 'Screenshot aufnehmen',
			'hotkeys.actions.framePrevious' => 'Vorheriger Frame',
			'hotkeys.actions.frameNext' => 'Nächstes Frame',
			'fileInfo.title' => 'Dateiinformationen',
			'fileInfo.overview' => 'Übersicht',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Untertitel',
			'fileInfo.images' => 'Eingebettete Bilder',
			'fileInfo.dataStreams' => 'Datenstreams',
			'fileInfo.lyrics' => 'Songtexte',
			'fileInfo.file' => 'Datei',
			'fileInfo.attachments' => 'Anhänge',
			'fileInfo.delivery' => 'Bereitstellung',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Version ${index} von ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Datei ${index} von ${count}',
			'fileInfo.noStreams' => 'Der Server hat für diese Datei keine Streams gemeldet.',
			'fileInfo.copyPath' => 'Pfad kopieren',
			'fileInfo.pathCopied' => 'Dateipfad kopiert',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Codec-Tag',
			'fileInfo.resolution' => 'Auflösung',
			'fileInfo.codedResolution' => 'Codierte Auflösung',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Bildrate',
			'fileInfo.rotation' => 'Rotation',
			'fileInfo.comment' => 'Kommentar',
			'fileInfo.audioDescription' => 'Audiodeskription',
			'fileInfo.headerCompression' => 'Header-Komprimierung',
			'fileInfo.sidecarFile' => 'Sidecar-Datei',
			'fileInfo.transportTimestamp' => 'Transport-Zeitstempel',
			'fileInfo.displayOffset' => 'Anzeige-Offset',
			'fileInfo.previewFailureCode' => 'Fehlercode der Vorschau',
			'fileInfo.previewRetries' => 'Vorschau-Wiederholungsversuche',
			'fileInfo.aspectRatio' => 'Seitenverhältnis',
			'fileInfo.pixelAspectRatio' => 'Pixel-Seitenverhältnis',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Level',
			'fileInfo.bitDepth' => 'Bittiefe',
			'fileInfo.pixelFormat' => 'Pixelformat',
			'fileInfo.colorSpace' => 'Farbraum',
			'fileInfo.colorRange' => 'Farbbereich',
			'fileInfo.colorPrimaries' => 'Primärfarben',
			'fileInfo.colorTransfer' => 'Farbübertragung',
			'fileInfo.chromaSubsampling' => 'Chroma-Subsampling',
			'fileInfo.chromaLocation' => 'Chroma-Position',
			'fileInfo.scanType' => 'Scan-Typ',
			'fileInfo.interlaced' => 'Interlaced',
			'fileInfo.anamorphic' => 'Anamorph',
			'fileInfo.referenceFrames' => 'Referenzbilder',
			'fileInfo.dynamicRange' => 'Dynamikbereich',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby-Vision-Level',
			'fileInfo.dolbyVisionVersion' => 'Dolby-Vision-Version',
			'fileInfo.dolbyVisionLayers' => 'Dolby-Vision-Ebenen',
			'fileInfo.baseLayerCompatibility' => 'Kompatibilität der Basisebene',
			'fileInfo.avcBitstream' => 'AVC-Bitstream',
			'fileInfo.nalLengthSize' => 'NAL-Längengröße',
			'fileInfo.scalingMatrix' => 'Benutzerdefinierte Skalierungsmatrix',
			'fileInfo.streamIdentifier' => 'Stream-Kennung',
			'fileInfo.streamIndex' => 'Stream-Index',
			'fileInfo.streamId' => 'Stream-ID',
			'fileInfo.language' => 'Sprache',
			'fileInfo.languageCode' => 'Sprachcode',
			'fileInfo.streamTitle' => 'Track-Titel',
			'fileInfo.channels' => 'Kanäle',
			'fileInfo.sampleRate' => 'Abtastrate',
			'fileInfo.spatialAudio' => 'Räumliches Audio',
			'fileInfo.textBased' => 'Textbasiert',
			'fileInfo.subtitleFormat' => 'Sidecar-Format',
			'fileInfo.provider' => 'Anbieter',
			'fileInfo.matchScore' => 'Übereinstimmungswert',
			'fileInfo.externalDelivery' => 'Kann separat bereitgestellt werden',
			'fileInfo.sidecarPath' => 'Sidecar-Pfad',
			'fileInfo.sourceStream' => 'Kopiert von',
			'fileInfo.temporary' => 'Temporär',
			'fileInfo.timeBase' => 'Zeitbasis',
			'fileInfo.overallBitrate' => 'Gesamtbitrate',
			'fileInfo.path' => 'Pfad',
			'fileInfo.fileName' => 'Dateiname',
			'fileInfo.size' => 'Größe',
			'fileInfo.totalSize' => 'Gesamtgröße',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Dauer',
			'fileInfo.previewThumbnails' => 'Vorschaubilder',
			'fileInfo.previewIndex' => 'Vorschau-Index',
			'fileInfo.packetLength' => 'Paketlänge',
			'fileInfo.filePresent' => 'Datei vorhanden',
			'fileInfo.fileReadable' => 'Vom Server lesbar',
			'fileInfo.streamPath' => 'Stream-Pfad',
			'fileInfo.optimizedForStreaming' => 'Für Streaming optimiert',
			'fileInfo.has64bitOffsets' => '64-Bit-Offsets',
			'fileInfo.protocol' => 'Protokoll',
			'fileInfo.mediaType' => 'Medientyp',
			'fileInfo.sourceKind' => 'Quellenart',
			'fileInfo.optimizedVersion' => 'Optimierte Version',
			'fileInfo.optimizationTarget' => 'Optimierungsziel',
			'fileInfo.deletedAt' => 'Gelöscht',
			'fileInfo.remoteSource' => 'Remote-Quelle',
			'fileInfo.infiniteStream' => 'Endlos-Stream',
			'fileInfo.directPlay' => 'Direct Play',
			'fileInfo.directStream' => 'Direct Stream',
			'fileInfo.transcoding' => 'Transkodierung',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Versions-ID',
			'fileInfo.fileId' => 'Datei-ID',
			'fileInfo.defaultAudioTrack' => 'Standard-Audiospur',
			'fileInfo.defaultSubtitleTrack' => 'Standard-Untertitelspur',
			'fileInfo.subtitlesOff' => 'Aus',
			'fileInfo.flagDefault' => 'Standard',
			'fileInfo.flagForced' => 'Erzwungen',
			'fileInfo.flagSelected' => 'Ausgewählt',
			'fileInfo.flagExternal' => 'Extern',
			'fileInfo.flagHearingImpaired' => 'Für Hörgeschädigte',
			'fileInfo.flagDub' => 'Synchronfassung',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			'mediaMenu.markAsWatched' => 'Als gesehen markieren',
			'mediaMenu.markAsUnwatched' => 'Als ungesehen markieren',
			'mediaMenu.removeFromContinueWatching' => 'Aus ‚Weiterschauen‘ entfernen',
			'mediaMenu.viewDetails' => 'Details anzeigen',
			'mediaMenu.goToSeries' => 'Zur Serie',
			'mediaMenu.shufflePlay' => 'Zufallswiedergabe',
			'mediaMenu.shuffleNotAvailableOffline' => 'Zufallswiedergabe ist offline nicht verfügbar',
			'mediaMenu.fileInfo' => 'Dateiinfo',
			'mediaMenu.deleteEpisodeFromServer' => 'Folge vom Server löschen',
			'mediaMenu.deleteSeasonFromServer' => 'Staffel vom Server löschen',
			'mediaMenu.deleteShowFromServer' => 'Serie vom Server löschen',
			'mediaMenu.deleteMovieFromServer' => 'Film vom Server löschen',
			'mediaMenu.deleteEpisodeTitle' => 'Diese Folge löschen?',
			'mediaMenu.deleteSeasonTitle' => 'Diese Staffel löschen?',
			'mediaMenu.deleteShowTitle' => 'Diese Serie löschen?',
			'mediaMenu.deleteMovieTitle' => 'Diesen Film löschen?',
			'mediaMenu.deleteEpisodeConfirm' => 'Folge löschen',
			'mediaMenu.deleteSeasonConfirm' => 'Staffel löschen',
			'mediaMenu.deleteShowConfirm' => 'Serie löschen',
			'mediaMenu.deleteMovieConfirm' => 'Film löschen',
			'mediaMenu.deleteAnyway' => 'Trotzdem löschen',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '„${title}“ dauerhaft von deinem Server löschen?',
			'mediaMenu.deleteMultipleWarning' => 'Dies umfasst alle Episoden und deren Dateien.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Dies löscht die ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} enthaltene Folge und ihre Datei.', other: 'Dies löscht alle ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folgen darin sowie ihre Dateien.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Dieses Element ist als ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Datei gespeichert, die gelöscht wird.', other: 'Dieses Element ist über ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Dateien verteilt gespeichert, die alle gelöscht werden.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} weitere Folge ist in derselben Datei gespeichert und wird ebenfalls gelöscht:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} weitere Folgen sind in derselben Datei gespeichert und werden ebenfalls gelöscht:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG konnte nicht prüfen, welche Dateien dadurch entfernt werden. Es könnte also mehr gelöscht werden als das oben genannte Element. Brich ab und versuche es erneut, oder lösche trotzdem.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Dein Server hat für dieses Element keine Dateidetails bereitgestellt, daher kann PlezyNG nicht prüfen, welche Dateien entfernt werden. Es könnte mehr gelöscht werden als das oben genannte Element.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medienelement gelöscht',
			'mediaMenu.mediaFailedToDelete' => 'Medienelement konnte nicht gelöscht werden',
			'mediaMenu.rate' => 'Bewerten',
			'mediaMenu.playFromBeginning' => 'Von Anfang an abspielen',
			'mediaMenu.playVersion' => 'Version abspielen …',
			'rateSheet.title' => 'Bewerten',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Favorit',
			'rateSheet.favorited' => 'Favorisiert',
			'rateSheet.saved' => 'Gespeichert',
			'rateSheet.notAvailable' => 'Keine Übereinstimmung gefunden',
			'rateSheet.noConnectedServices' => 'Verbinde einen Dienst in den Einstellungen, um dort zu bewerten.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, Film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, Serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'gesehen',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => 'zu ${percent} Prozent gesehen',
			'accessibility.mediaCardUnwatched' => 'ungesehen',
			'accessibility.tapToPlay' => 'Zum Abspielen tippen',
			'accessibility.decrease' => 'Verringern',
			'accessibility.increase' => 'Erhöhen',
			'accessibility.decreaseValue' => ({required Object label}) => '${label} verringern',
			'accessibility.increaseValue' => ({required Object label}) => '${label} erhöhen',
			'accessibility.hue' => 'Farbton',
			'accessibility.saturation' => 'Sättigung',
			'accessibility.brightness' => 'Helligkeit',
			'accessibility.hexColor' => 'Hexadezimalfarbe',
			'accessibility.expandText' => 'Text ausklappen',
			'accessibility.collapseText' => 'Text einklappen',
			'accessibility.alphabetNavigation' => 'Alphabetische Navigation',
			'accessibility.alphabetScrollHint' => 'Nach oben oder unten wischen, um einen Buchstaben weiterzugehen',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Zeile ${row} von ${rowCount}, Spalte ${column} von ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Zeile ${row} von ${rowCount}',
			'accessibility.autoScrollPlay' => 'Automatisches Scrollen starten',
			'accessibility.autoScrollPause' => 'Automatisches Scrollen pausieren',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'rote',
			'accessibility.green' => 'Grün',
			'accessibility.blue' => 'Blau',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Zugänglichkeit',
			'accessibility.summary' => 'Text, Kontrast, Bewegung und Kontrolle',
			'accessibility.systemHint' => 'Die Zugänglichkeitssatzungen Ihres Geräts gelten immer. Diese Optionen fügen Anpassungen über PlezyNG hinzu.',
			'accessibility.readability' => 'Lesen und Sehbarkeit',
			'accessibility.textSize' => 'Zusatztextgröße',
			'accessibility.preview' => 'Finden Sie Ihre nächste Geschichte. Lesen, hören und sehen Sie in Ihrem eigenen Tempo.',
			'accessibility.boldText' => 'Schöne Interface Text',
			'accessibility.highContrast' => 'hohe Kontrast',
			'accessibility.highContrastHint' => 'Stärkeres Text, Auszeichnungen und Fokusindikatoren auf leichten oder dunklen Oberflächen.',
			'accessibility.interaction' => 'Bewegung und Interaktion',
			'accessibility.reduceMotion' => 'Bewegung reduzieren',
			'accessibility.reduceMotionHint' => 'Animationen der Fokusanzeige, Seitenübergänge und dekorative Effekte anhalten.',
			'accessibility.largeTargets' => 'Großer Touch-Ziel',
			'accessibility.largeTargetsHint' => 'Geben Sie den gemeinsamen Kontroll mehr Platz für Berührung und assistive Navigation.',
			'accessibility.navigationHint' => 'Mit Tab und Shift+Tab wechselst du zwischen Bedienelementen, mit Enter oder der Leertaste aktivierst du sie, und mit Escape oder Zurück schließt du sie. Wenn ein Buch geöffnet ist, kannst du den Zoom und die Leseeinstellungen anpassen.',
			'accessibility.textSizeDescription' => 'Scale-Interface Text in PlezyNG neben der Systemtextgröße Einstellung Ihres Geräts.',
			'accessibility.boldTextHint' => 'Verwenden Sie ein schwerer Gewicht für Interface-Label und Nachrichten, um sie leichter zu unterscheiden.',
			'tooltips.shufflePlay' => 'Zufallswiedergabe',
			'tooltips.playTrailer' => 'Trailer abspielen',
			'tooltips.markAsWatched' => 'Als gesehen markieren',
			'tooltips.markAsUnwatched' => 'Als ungesehen markieren',
			'audioTracks.track' => ({required Object n}) => 'Audiospur ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Untertitel',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Bild füllen',
			'videoControls.stretch' => 'Strecken',
			'videoControls.lockRotation' => 'Rotation sperren',
			'videoControls.unlockRotation' => 'Rotation entsperren',
			'videoControls.timerActive' => 'Schlaftimer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert',
			'videoControls.sleepTimerEndOfVideo' => 'Ende des aktuellen Videos',
			'videoControls.sleepTimerStopAtHeader' => 'Beenden bei',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Wiedergabe wird am Ende dieses Videos pausiert',
			'videoControls.stillWatching' => 'Schaust du noch?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pause in ${seconds}s',
			'videoControls.continueWatching' => 'Weiter',
			'videoControls.autoPlayNext' => 'Nächstes automatisch abspielen',
			'videoControls.playNext' => 'Nächstes abspielen',
			'videoControls.playButton' => 'Abspielen',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.playbackPaused' => 'Pausiert',
			'videoControls.playbackResumed' => 'Wird abgespielt',
			'videoControls.loadingVideo' => 'Video wird geladen',
			'videoControls.showPlaybackControls' => 'Wiedergabesteuerung anzeigen',
			'videoControls.hidePlaybackControls' => 'Wiedergabesteuerung ausblenden',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} Sekunden zurück',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} Sekunden vorwärts',
			'videoControls.previousButton' => 'Vorherige Episode',
			'videoControls.nextButton' => 'Nächste Episode',
			'videoControls.previousChapterButton' => 'Vorheriges Kapitel',
			'videoControls.nextChapterButton' => 'Nächstes Kapitel',
			'videoControls.muteButton' => 'Stumm schalten',
			'videoControls.unmuteButton' => 'Stummschaltung aufheben',
			'videoControls.settingsButton' => 'Wiedergabeeinstellungen',
			'videoControls.tracksButton' => 'Audio und Untertitel',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionQualityButton' => 'Version & Qualität',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Qualität',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkodierung nicht verfügbar – Wiedergabe in Originalqualität',
			'videoControls.subtitleUnavailableFallback' => 'Die ausgewählten Untertitel konnten nicht geladen werden – die Wiedergabe wird ohne Untertitel fortgesetzt',
			'videoControls.pipButton' => 'Bild-in-Bild-Modus',
			'videoControls.aspectRatioButton' => 'Seitenverhältnis',
			'videoControls.ambientLighting' => 'Umgebungsbeleuchtung',
			'videoControls.fullscreenButton' => 'Vollbild aktivieren',
			'videoControls.exitFullscreenButton' => 'Vollbild verlassen',
			'videoControls.alwaysOnTopButton' => 'Immer im Vordergrund',
			'videoControls.rotationLockButton' => 'Drehsperre',
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => 'Bildschirm sperren',
			'videoControls.screenLockButton' => 'Bildschirmsperre',
			'videoControls.timelineSlider' => 'Videozeitleiste',
			'videoControls.volumeSlider' => 'Lautstärkepegel',
			'videoControls.endsAt' => ({required Object time}) => 'Endet um ${time}',
			'videoControls.pipActive' => 'Wiedergabe im Bild-in-Bild-Modus',
			'videoControls.pipFailed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.screenshotSaved' => 'Screenshot gespeichert',
			'videoControls.screenshotFailed' => 'Screenshot konnte nicht aufgenommen werden',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Lautstärke ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Erfordert Android 8.0 oder neuer',
			'videoControls.pipErrors.iosVersion' => 'Erfordert iOS 15.0 oder neuer',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-in-Bild ist deaktiviert. Aktiviere es in den Systemeinstellungen.',
			'videoControls.pipErrors.notSupported' => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht',
			'videoControls.pipErrors.voSwitchFailed' => 'Videoausgabe für Bild-in-Bild konnte nicht umgeschaltet werden',
			'videoControls.pipErrors.failed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.pipErrors.prepareFailed' => 'Bild-in-Bild konnte nicht vorbereitet werden',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ein Fehler ist aufgetreten: ${error}',
			'videoControls.chapters' => 'Kapitel',
			'videoControls.noChaptersAvailable' => 'Keine Kapitel verfügbar',
			'videoControls.queue' => 'Warteschlange',
			'videoControls.noQueueItems' => 'Keine Elemente in der Warteschlange',
			'videoControls.noAudioDevicesAvailable' => 'Keine Audiogeräte verfügbar',
			'videoControls.searchSubtitles' => 'Untertitel suchen',
			'videoControls.language' => 'Sprache',
			'videoControls.noSubtitlesFound' => 'Keine Untertitel gefunden',
			'videoControls.subtitleDownloaded' => 'Untertitel heruntergeladen',
			'videoControls.subtitleDownloadedNotApplied' => 'Der Untertitel wurde heruntergeladen, konnte aber nicht ausgewählt werden',
			'videoControls.subtitleDownloadFailed' => 'Untertitel konnte nicht heruntergeladen werden',
			'videoControls.searchLanguages' => 'Sprachen suchen...',
			'videoControls.skipIntro' => 'Intro überspringen',
			'videoControls.skipCredits' => 'Abspann überspringen',
			'videoControls.nextEpisode' => 'Nächste Episode',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Spur ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Untertitel ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Erzwungen)',
			'videoControls.osdSubtitlesOff' => 'Untertitel: Aus',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Untertitel: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame', ), 
			'videoControls.trackSelectionTitle' => 'Track vor Playback auswählen',
			'videoControls.trackSelectionAuto' => 'Automatische Auswahl',
			'videoControls.openMiniPlayer' => 'Open Mini-Spieler',
			'videoControls.returnToFullPlayer' => 'Zurück zum Vollspieler',
			'videoControls.loadSubtitleFile' => 'Download Subtitle Datei ...',
			'videoControls.subtitleLoadFailed' => 'Laden Sie nicht die Subtitle-Datei',
			'videoControls.skipAds' => 'Werbung überspringen',
			'videoControls.tapToUnlock' => 'Zum Entsperren tippen',
			'videoControls.tapAgainToUnlock' => 'Zum Entsperren erneut tippen',
			'videoControls.segmentLoopHelp' => 'Set A, dann set B später in der Timeline.',
			'videoControls.setLoopStart' => 'Set loop start (A)',
			'videoControls.setLoopEnd' => 'Set loop end (B)',
			'videoControls.clearSegmentLoop' => 'Klares Segment Lauf',
			'videoControls.setLoopStartFirst' => 'Set Loop Start (A) vor dem Ende (B).',
			'videoControls.loopEndAfterStart' => 'Das Ende des Laufens muss später als der Anfang sein.',
			'videoControls.segmentLoopUnavailable' => 'Segment looping ist für diesen playback nicht verfügbar.',
			'videoControls.bookmarksHelp' => 'Buchmarken werden auf diesem Gerät gespeichert. Wählen Sie einen, um zu dieser Zeit zu gehen.',
			'videoControls.bookmarksButton' => 'Buchmarken',
			'videoControls.chaptersAndBookmarks' => 'Kapitel und Buchmarken',
			'videoControls.segmentLoop' => 'Segment Lauf',
			'videoControls.addBookmark' => 'Bookmark hinzufügen',
			'videoControls.bookmarkName' => 'Bookmark Name',
			'videoControls.bookmarkNameHint' => 'Zum Beispiel die Öffnungszene',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Buchmarke ${n}',
			'videoControls.bookmarkNameRequired' => 'Geben Sie einen Namen für diese Buchmarke ein.',
			'videoControls.deleteBookmark' => 'Buchmarke löschen',
			'videoControls.bookmarkLimitReached' => 'Dieser Artikel hat bereits 100 Buchmarken.',
			'videoControls.bookmarkUnavailable' => 'Ich konnte diese Buchmarke nicht speichern oder entfernen.',
			'videoControls.bookmarkSaved' => 'Bookmark gerettet wurde.',
			'videoControls.bookmarkDeleted' => 'Bookmark gelöscht wurde.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Laufpunkt ${point} Set auf ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'Keine Kapitel oder Buchmarken verfügbar.',
			'videoControls.loopPointNotSet' => 'nicht set',
			'messages.markedAsWatched' => 'Als gesehen markiert',
			'messages.markedAsUnwatched' => 'Als ungesehen markiert',
			'messages.markedAsWatchedOffline' => 'Als gesehen markiert (wird synchronisiert, wenn online)',
			'messages.markedAsUnwatchedOffline' => 'Als ungesehen markiert (wird synchronisiert, wenn online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisch entfernt: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Automatisch entfernt: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} angesehener Download', other: 'Automatisch entfernt: ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} angesehene Downloads', ), 
			'messages.removedFromContinueWatching' => 'Aus „Weiterschauen“ entfernt',
			'messages.errorLoading' => ({required Object error}) => 'Fehler: ${error}',
			'messages.searchPartialResults' => 'Einige Medienserver konnten nicht durchsucht werden. Verfügbare Ergebnisse werden angezeigt.',
			'messages.streamInterrupted' => 'Der Stream wurde unterbrochen. Drücke auf Wiedergabe oder spule, um es erneut zu versuchen.',
			'messages.liveStreamInterrupted' => 'Der Livestream wurde unterbrochen. Drücke auf Wiedergabe, um es erneut zu versuchen.',
			'messages.fileInfoNotAvailable' => 'Dateiinfo nicht verfügbar',
			'messages.playbackAuthenticationRequired' => 'Melde dich erneut beim Medienserver an, um dieses Element abzuspielen.',
			'messages.playbackServerUnavailable' => 'Der Medienserver ist nicht verfügbar. Versuche es später erneut.',
			'messages.playbackDataInvalid' => 'Der Server hat ungültige Wiedergabeinformationen zurückgegeben.',
			'messages.playbackCancelled' => 'Die Wiedergabe wurde abgebrochen.',
			'messages.playbackFailed' => 'Die Wiedergabe konnte nicht gestartet werden.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Die Wiedergabe konnte nicht gestartet werden: ${error}',
			'messages.audioOutputFailed' => 'Die Audioausgabe reagiert nicht mehr. Prüfe die Audioverbindung des Fernsehers oder Receivers; wenn auch andere Apps keinen Ton haben, starte das Gerät neu.',
			'messages.mediaUnavailable' => 'Dieser Inhalt ist nicht mehr verfügbar.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}',
			'messages.errorLoadingSeries' => 'Fehler beim Laden der Serie',
			'messages.musicNotSupported' => 'Musikwiedergabe wird noch nicht unterstützt',
			'messages.noDescriptionAvailable' => 'Keine Beschreibung verfügbar',
			'messages.noProfilesAvailable' => 'Keine Profile verfügbar',
			'messages.contactAdminForProfiles' => 'Wende dich an deinen Serveradministrator, um Profile hinzuzufügen',
			'messages.unableToDetermineLibrarySection' => 'Der Mediatheksbereich für dieses Element konnte nicht ermittelt werden',
			'messages.logsCleared' => 'Protokolle gelöscht',
			'messages.logsCopied' => 'Protokolle in Zwischenablage kopiert',
			'messages.noLogsAvailable' => 'Keine Protokolle verfügbar',
			'messages.libraryScanning' => ({required Object title}) => '„${title}“ wird gescannt …',
			'messages.libraryScanStarted' => ({required Object title}) => 'Mediathekscan gestartet für „${title}“',
			'messages.libraryScanFailed' => ({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metadaten für „${title}“ werden aktualisiert …',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}',
			'messages.logoutConfirm' => 'Abmeldung wirklich durchführen?',
			'messages.noSeasonsFound' => 'Keine Staffeln gefunden',
			'messages.seasonsLoadFailed' => 'Staffeln konnten nicht geladen werden',
			'messages.noEpisodesFound' => 'Keine Episoden in der ersten Staffel gefunden',
			'messages.noEpisodesFoundGeneral' => 'Keine Episoden gefunden',
			'messages.episodesLoadFailed' => 'Episoden konnten nicht geladen werden',
			'messages.noResultsFound' => 'Keine Ergebnisse gefunden',
			'messages.sleepTimerSet' => ({required Object label}) => 'Schlaftimer auf ${label} eingestellt',
			'messages.noItemsAvailable' => 'Keine Elemente verfügbar',
			'messages.failedToCreatePlayQueueNoItems' => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Wechsel zu einem kompatiblen Player …',
			'messages.serverLimitTitle' => 'Wiedergabe fehlgeschlagen',
			'messages.serverLimitBody' => 'Serverfehler (HTTP 500). Vermutlich hat ein Bandbreiten- oder Transkodierungslimit diese Sitzung abgelehnt. Bitte den Besitzer, das Limit anzupassen.',
			'messages.mediaUnreadableTitle' => 'Datei nicht verfügbar',
			'messages.mediaUnreadableBody' => 'Der Server hat dieses Element gefunden, konnte seine Datei aber nicht lesen (HTTP 404). Die Datei wurde wahrscheinlich verschoben oder gelöscht, oder ihr Speicher ist offline. Bitte den Serverbesitzer, die Datei zu prüfen und die Mediathek neu zu scannen.',
			'messages.serverBusyTitle' => 'Stream nicht verfügbar',
			'messages.serverBusyBody' => 'Der Server hat das Streamen dieser Datei wiederholt abgelehnt (HTTP 503). Möglicherweise wird er neu gestartet, ist ausgelastet oder der Speicherort der Datei ist offline. Versuche es gleich noch einmal. Falls das Problem weiterhin auftritt, bitte den Serverbetreiber, den Server und den Speicherort der Datei zu überprüfen.',
			'messages.playbackNotAllowedTitle' => 'Wiedergabe nicht erlaubt',
			'messages.playbackNotAllowedBody' => 'Der Server hat das Streamen dieses Elements abgelehnt (HTTP 403). Dein Konto hat möglicherweise keine Berechtigung, es abzuspielen, oder der Server erlaubt die Wiedergabe nur in seinem lokalen Netzwerk.',
			'messages.logsUploaded' => 'Protokolle hochgeladen',
			'messages.logsUploadFailed' => 'Protokolle konnten nicht hochgeladen werden',
			'messages.logId' => 'Protokoll-ID',
			'messages.burnedSubtitlesUseMenu' => 'Die Untertitel sind in diesen Stream eingebrannt. Ändere sie über das Untertitelmenü.',
			'messages.noVideoUrl' => 'Keine Video-URL verfügbar',
			'messages.playbackNoMediaSources' => 'Der Server hat keine abspielbaren Medienquellen zurückgegeben',
			'messages.playbackDataNotPrepared' => 'Die Wiedergabe wurde gestartet, bevor die Daten bereit waren',
			'messages.streamSelectionUnavailable' => 'Die Streamauswahl ist für diese Quelle nicht verfügbar',
			'messages.streamSelectionFailed' => 'Die ausgewählten Streams konnten nicht angewendet werden',
			'messages.trackSelectionNotRemembered' => 'Diese Spurauswahl gilt nur für die aktuelle Wiedergabe.',
			'messages.serverUnavailableForProfile' => 'Für das aktive Profil ist kein Server verfügbar',
			'subtitlingStyling.previewSample' => 'Der schnelle braune Fox springt über den lazy hund',
			'subtitlingStyling.text' => 'Text',
			'subtitlingStyling.border' => 'Rahmen',
			'subtitlingStyling.background' => 'Hintergrund',
			'subtitlingStyling.fontSize' => 'Schriftgröße',
			'subtitlingStyling.textColor' => 'Textfarbe',
			'subtitlingStyling.borderSize' => 'Rahmengröße',
			'subtitlingStyling.borderColor' => 'Rahmenfarbe',
			'subtitlingStyling.backgroundOpacity' => 'Hintergrunddeckkraft',
			'subtitlingStyling.backgroundColor' => 'Hintergrundfarbe',
			'subtitlingStyling.position' => 'Position',
			'subtitlingStyling.assOverride' => 'ASS-Überschreibung',
			'subtitlingStyling.overrideScale' => 'Skalieren',
			'subtitlingStyling.overrideForce' => 'Erzwingen',
			'subtitlingStyling.overrideStrip' => 'Formatierung entfernen',
			'subtitlingStyling.positionTop' => 'Oben',
			'subtitlingStyling.positionBottom' => 'Unten',
			'subtitlingStyling.useMargins' => 'Ränder verwenden',
			'subtitlingStyling.useMarginsDescription' => 'Textuntertitel im Bereich außerhalb des Videos zulassen. Gestylte Untertitel behalten möglicherweise ihre ursprüngliche Position.',
			'subtitlingStyling.anchorToScreen' => 'Am Bildschirm verankern',
			'subtitlingStyling.anchorToScreenDescription' => 'Textuntertitel in den schwarzen Balken unter Breitbildvideos anzeigen',
			'subtitlingStyling.bold' => 'Fett',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Render-Auflösung',
			'subtitlingStyling.renderResolutionScreen' => 'Bildschirmauflösung',
			'subtitlingStyling.renderResolutionVideo' => 'Videoauflösung',
			'subtitlingStyling.fontSizeDescription' => 'Setzen Sie die Subtitle Textgröße auf diesem Gerät.',
			'subtitlingStyling.textColorDescription' => 'Wählen Sie die für Subtitle Text verwendete Farbe aus.',
			'subtitlingStyling.borderSizeDescription' => 'Setzen Sie die Dicke der Ausgabe um Subtitle Text.',
			'subtitlingStyling.borderColorDescription' => 'Wählen Sie die verwendete Farbe für die Subtitle-Ausgabe aus.',
			'subtitlingStyling.backgroundColorDescription' => 'Wählen Sie die Farbe hinter dem Subtitle Text aus.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Stellen Sie fest, wie transparent der Untertitel Hintergrund ist: 0% ist klar und 100% fester.',
			'subtitlingStyling.positionDescription' => 'Move Subtitles vertikal. 0% ist die Spitze des Videos und 100% ist die Unterseite.',
			'subtitlingStyling.assOverrideDescription' => 'Wählen Sie aus, ob der Spieler folgt, angepasst, ersetzt oder Styling in ASS Subtitles eingebaut entfernt.',
			'subtitlingStyling.assOverrideOptions.no' => 'Halten Sie die Buchstaben, Farben, Größen und Platzierung in der Subtitle-Datei geschrieben.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Erlauben Sie, dass die Subtitle-Stil-Einstellungen des Spielers ASS-Subtitles anpassen.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Anwenden Sie Player-Stiling und Skala eingebettete Größen, um die Video Dimensionen zu entsprechen.',
			'subtitlingStyling.assOverrideOptions.force' => 'Ersetzen Sie die eingebauten ASS-Style mit dem Subtitle-Stil des Spielers.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Entfernen Sie das eingebettete ASS-Format und machen Sie den Untertiteltext klar.',
			'subtitlingStyling.renderResolutionDescription' => 'Wählen Sie die Auflösung, die verwendet wird, um Bild und ASS Untertitel zu rasterisieren. Die niedrigeren Android-Skala können Rendering Arbeit reduzieren, aber leichter aussehen.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render auf der vollständigen Displayoberflächenlösung für das scharfe Ergebnis.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render verwendet die Video-Resolution als Referenz, die Arbeit auf High-Resolution-Displays reduzieren kann.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render auf 75% der Displayoberflächenlösung für eine bescheidenen Leistungsbesparung.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render auf 50% der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit weicheren Wänden.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render auf ein Drittel der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit weicheren Randen.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render auf ein Viertel der Displayoberflächenlösung, um die Arbeit zu reduzieren, mit dem weichsten Ergebnis.',
			'subtitlingStyling.boldDescription' => 'Zeichnen Sie Subtiteltext in einem schwereren Gewicht.',
			'subtitlingStyling.italicDescription' => 'Untertitel Text in Italienisch zu entwerfen.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Erweiterte Videoplayer-Einstellungen',
			'mpvConfig.presets' => 'Voreinstellungen',
			'mpvConfig.noPresets' => 'Keine gespeicherten Voreinstellungen',
			'mpvConfig.saveAsPreset' => 'Als Voreinstellung speichern …',
			'mpvConfig.presetName' => 'Name der Voreinstellung',
			'mpvConfig.presetNameHint' => 'Namen für diese Voreinstellung eingeben',
			'mpvConfig.loadPreset' => 'Laden',
			'mpvConfig.deletePreset' => 'Löschen',
			'mpvConfig.presetSaved' => 'Voreinstellung gespeichert',
			'mpvConfig.presetLoaded' => 'Voreinstellung geladen',
			'mpvConfig.presetDeleted' => 'Voreinstellung gelöscht',
			'mpvConfig.confirmDeletePreset' => 'Diese Voreinstellung wirklich löschen?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Zeile hinzufügen',
			'mpvConfig.removeLine' => 'Zeile entfernen',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context und gpu-api werden unter Linux ignoriert: eingebettetes Video wird immer über vo=libmpv auf der Videoebene gerendert, und gpu-next (das Compute-Shader wie ArtCNN benötigen) kann nicht eingebettet ausgeführt werden.',
			'dialog.confirmAction' => 'Aktion bestätigen',
			'profiles.addPlezyProfile' => 'PlezyNG-Profil hinzufügen',
			'profiles.switchingProfile' => 'Profil wird gewechselt…',
			'profiles.deleteThisProfileTitle' => 'Dieses Profil löschen?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} entfernen. Verbindungen bleiben unberührt.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Verwalten',
			'profiles.delete' => 'Löschen',
			'profiles.signOut' => 'Abmelden',
			'profiles.signOutPlexTitle' => 'Von Plex abmelden?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} und alle Plex Home-Benutzer entfernen? Du kannst dich jederzeit wieder anmelden.',
			'profiles.signOutPlexDeleteDownloads' => 'Downloads ebenfalls löschen',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Andernfalls bleiben sie auf diesem Gerät und sind wieder da, wenn du dich erneut bei diesem Konto anmeldest.',
			'profiles.signedOutPlex' => 'Von Plex abgemeldet.',
			'profiles.signOutFailed' => 'Abmeldung fehlgeschlagen.',
			'profiles.sectionTitle' => 'Profile',
			'profiles.summarySingle' => 'Profile hinzufügen, um verwaltete Benutzer mit lokalen Identitäten zu kombinieren',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} Profile · aktiv: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} Profile',
			'profiles.removeConnectionTitle' => 'Verbindung entfernen?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Zugriff von ${displayName} auf ${connectionLabel} entfernen. Andere Profile behalten ihn.',
			'profiles.deleteProfileTitle' => 'Profil löschen?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => '${displayName} und Verbindungen entfernen. Server bleiben verfügbar.',
			'profiles.profileNameLabel' => 'Profilname',
			'profiles.pinProtectionLabel' => 'PIN-Schutz',
			'profiles.copyAutomationLink' => 'Kopieren Android Automatisierung Link',
			'profiles.copyAutomationLinkDescription' => 'Wählen Sie dieses Profil aus einer Android Absicht oder Automatisierung aus. Profil-PIN-Checks gelten noch.',
			'profiles.automationLinkCopied' => 'Profil-Automatisierung Link kopiert.',
			'profiles.pinManagedByPlex' => 'PIN wird von Plex verwaltet. Auf plex.tv bearbeiten.',
			'profiles.noPinSetEditOnPlex' => 'Keine PIN festgelegt. Um eine zu verlangen, bearbeite den Home-Benutzer auf plex.tv.',
			'profiles.setPin' => 'PIN festlegen',
			'profiles.setPinTitle' => 'PIN festlegen',
			'profiles.confirmPinTitle' => 'PIN bestätigen',
			'profiles.pinSet' => 'PIN festgelegt',
			'profiles.changePin' => 'Ändern',
			'profiles.removePin' => 'Entfernen',
			'profiles.connectionsLabel' => 'Verbindungen',
			'profiles.add' => 'Hinzufügen',
			'profiles.deleteProfileButton' => 'Profil löschen',
			'profiles.noConnectionsHint' => 'Keine Verbindungen — füge eine hinzu, um dieses Profil zu nutzen.',
			'profiles.noConnections' => 'Keine Verbindungen',
			'profiles.plexHomeAccount' => 'Plex Home-Konto',
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex-Konto: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} über ${account}',
			'profiles.connectionDefault' => 'Standard',
			'profiles.connectionAs' => ({required Object displayName}) => 'als ${displayName}',
			'profiles.makeDefault' => 'Als Standard festlegen',
			'profiles.removeConnection' => 'Entfernen',
			'profiles.profileRenamed' => 'Profil umbenannt.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Zu ${displayName} hinzufügen',
			'profiles.borrowExplain' => 'Verbindung eines anderen Profils übernehmen. PIN-geschützte Profile erfordern eine PIN.',
			'profiles.borrowEmpty' => 'Keine Verbindungen zum Übernehmen verfügbar.',
			'profiles.borrowEmptySubtitle' => 'Verbinde zuerst Plex, Jellyfin oder Emby mit einem anderen Profil.',
			'profiles.borrowLoadFailed' => 'Verfügbare Verbindungen konnten nicht geladen werden. Versuche es erneut.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Von ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Verbindung übernommen.',
			'profiles.borrowFailed' => 'Verbindung konnte nicht übernommen werden.',
			'profiles.incorrectPin' => 'Falsche PIN.',
			'profiles.incorrectPinTryAgain' => 'Falsche PIN. Bitte erneut versuchen.',
			'profiles.sourceProfileMissingParentAccount' => 'Dem Quellprofil fehlt das übergeordnete Konto.',
			'profiles.failedToLoadHomeUsers' => 'Deine Plex-Home-Benutzer konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.',
			'profiles.failedToVerifyPin' => 'PIN konnte nicht verifiziert werden.',
			'profiles.newProfile' => 'Neues Profil',
			'profiles.profileNameHint' => 'z. B. Gäste, Kinder, Wohnzimmer',
			'profiles.pinProtectionOptional' => 'PIN-Schutz (optional)',
			'profiles.pinExplain' => '4-stellige PIN zum Profilwechsel erforderlich.',
			'profiles.continueButton' => 'Weiter',
			'profiles.pinsDontMatch' => 'PINs stimmen nicht überein',
			'profiles.tokenIdentityMismatch' => 'Das Plex-Profil-Token wurde einem unerwarteten Server zugeordnet',
			'profiles.settingsLocked' => 'Die Einstellungen sind für diesen Profil gesperrt.',
			'profiles.unlockSettings' => 'Unlock Settings',
			'profiles.showExploreForProfile' => 'Show Explore für dieses Profil',
			'profiles.showExploreForProfileDescription' => 'Stopp aus, um Explore aus der Navigation dieses Profils zu entfernen.',
			'connections.sectionTitle' => 'Verbindungen',
			'connections.addConnection' => 'Verbindung hinzufügen',
			'connections.addConnectionSubtitleNoProfile' => 'Mit Plex anmelden oder mit einem Jellyfin- oder Emby-Server verbinden',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Zu ${displayName} hinzufügen: Plex, Jellyfin, Emby oder eine andere Profilverbindung',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sitzung für ${name} abgelaufen',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sitzungen für ${count} Server abgelaufen',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} verweigert diesem Konto den Zugriff',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} Server verweigern diesem Konto den Zugriff',
			'connections.signInAgain' => 'Erneut anmelden',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Verbindung zu ${product} bearbeiten',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'URLs für ${serverName} hinzufügen oder entfernen. PlezyNG verwendet die erreichbare URL mit der geringsten Latenz.',
			'accountPreferences.sectionTitle' => 'Kontoeinstellungen',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Audio-, Untertitel- und Mediathek-Optionen werden auf ${account} gespeichert',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Audio-, Untertitel- und Mediathek-Optionen werden auf ${count} Konten gespeichert',
			'accountPreferences.pickAccount' => 'Jedes Konto speichert seine eigenen Einstellungen. Wähle das Konto, das du bearbeiten möchtest.',
			'accountPreferences.storedOnAccount' => 'Diese Optionen werden auf dem Konto selbst gespeichert, sodass jede damit angemeldete App sie verwendet — auch PlezyNG auf deinen anderen Geräten.',
			'accountPreferences.noAccounts' => 'Keine Konten zum Konfigurieren',
			'accountPreferences.noAccountsHint' => 'Melde dich bei Plex an oder verbinde einen Jellyfin- oder Emby-Server — die auf diesem Konto gespeicherten Einstellungen erscheinen dann hier.',
			'accountPreferences.unavailable' => 'Dieses Konto ist nicht erreichbar',
			'accountPreferences.loadFailed' => 'Diese Einstellungen konnten nicht geladen werden',
			'accountPreferences.noPreference' => 'Keine Einstellung',
			'accountPreferences.notSet' => 'Nicht festgelegt',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio & Untertitel',
			'accountPreferences.groups.libraryDisplay' => 'Mediathek',
			'accountPreferences.groups.personalMedia' => 'Persönliche Medien',
			'accountPreferences.preferredAudioLanguage' => 'Bevorzugte Audiosprache',
			'accountPreferences.autoSelectAudio' => 'Audio nach Sprache auswählen',
			'accountPreferences.autoSelectAudioDescription' => 'Bei „Aus“ wird die Audiospur verwendet, die die Datei als Standard markiert.',
			'accountPreferences.preferredSubtitleLanguage' => 'Bevorzugte Untertitelsprache',
			'accountPreferences.subtitleMode' => 'Untertitel einschalten',
			'accountPreferences.subtitleModes.none' => 'Manuell ausgewählt',
			'accountPreferences.subtitleModes.noneDescription' => 'Untertitel niemals von selbst einschalten.',
			'accountPreferences.subtitleModes.defaultMode' => 'Spurmarkierungen folgen',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Die Standard- und Erzwungen-Markierungen jeder Untertitelspur verwenden.',
			'accountPreferences.subtitleModes.always' => 'Immer aktiviert',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Eine Untertitelspur in der bevorzugten Sprache einschalten, sofern eine vorhanden ist.',
			'accountPreferences.subtitleModes.onlyForced' => 'Nur erzwungene Untertitel',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Nur die als erzwungen markierten Spuren laden.',
			'accountPreferences.subtitleModes.smart' => 'Bei fremdsprachigem Audio anzeigen',
			'accountPreferences.subtitleModes.smartDescription' => 'Untertitel nur einschalten, wenn das Audio in einer anderen Sprache ist.',
			'accountPreferences.subtitleAccessibility' => 'SDH-Untertitel',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Nicht-SDH-Untertitel bevorzugen',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'SDH-Untertitel bevorzugen',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Nur SDH-Untertitel',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Nur Nicht-SDH-Untertitel',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Standard-Subtitles bevorzugen, wenn sowohl Standard- als auch SDH-Versionen verfügbar sind.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Sie bevorzugen SDH-Subtitles, wenn sie verfügbar sind, aber ermöglichen standardische Subtitles als Fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Verwenden Sie SDH-Subtitles nur; fallen Sie nicht zurück zu standard Subtitles.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Verwenden Sie nur standardisierte Untertitel; SDH-Subtitel ausgeschlossen.',
			'accountPreferences.forcedSubtitles' => 'Erzwungene Untertitel',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Nicht erzwungene Untertitel bevorzugen',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Erzwungene Untertitel bevorzugen',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Nur erzwungene Untertitel',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Nur nicht erzwungene Untertitel',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Sie bevorzugen regelmäßige Untertitel, aber erlauben zwingende Spuren als Fallback.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Sie bevorzugen zwingende Spuren, wenn sie verfügbar sind, aber erlauben regelmäßige Untertitel als Fallback.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Verwenden Sie nur Spuren, die als gezwungen markiert sind.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Ausnahme von Spuren, die als gezwungen markiert werden.',
			'accountPreferences.displayMissingEpisodes' => 'Fehlende Episoden anzeigen',
			'accountPreferences.displayMissingEpisodesDescription' => 'Episoden auflisten, die dem Server bekannt sind, für die aber keine Datei vorliegt.',
			'accountPreferences.hidePlayedInLatest' => 'Gesehene Elemente in „Neueste“ ausblenden',
			'accountPreferences.hidePlayedInLatestDescription' => 'Elemente, die du bereits gesehen hast, erscheinen nicht mehr in den „Neueste“-Zeilen des Servers.',
			'accountPreferences.displayCollectionsView' => 'Sammlungsansicht anzeigen',
			'accountPreferences.displayCollectionsViewDescription' => 'Die Sammlungsansicht des Servers zusätzlich zu deinen Mediatheken anzeigen.',
			'accountPreferences.rewatchingInNextUp' => 'Erneut geschaute Serien in „Als Nächstes“ behalten',
			'accountPreferences.rewatchingInNextUpDescription' => 'Beendest du eine Serie und startest sie erneut, folgt „Als Nächstes“ dem erneuten Anschauen, statt die Serie zu verwerfen.',
			'accountPreferences.watchedIndicator' => 'Gesehen-Markierung',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nie',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filme und Serien',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Nur Filme',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Nur Serien',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Zeigen Sie nicht beobachtete Checkmarken an.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Show watched checkmarks für Filme und TV-Shows.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Show watched checkmarks only für Filme.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Show watched checkmarks for TV shows nur.',
			'accountPreferences.mediaReviewsVisibility' => 'Bewertungen & Rezensionen',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Benutzer und Kritiker',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Nur Benutzer',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Nur Kritiker',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Ausgeblendet',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Zeigen Sie sowohl Benutzerbewertungen als auch kritische Bewertungen.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Zeigen Sie Ratings und Bewertungen, die von Nutzern vorgelegt wurden.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Zeigen Sie kritische Ratings und Bewertungen an.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Verbergen Sie Ratings und Bewertungen.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Sie bevorzugen Audio-Track in dieser Sprache, wenn der Server oder Player automatisch einen Track auswählt.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Sie bevorzugen Untertitel-Track in dieser Sprache, wenn Subtitles automatisch ausgewählt werden.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Wählen Sie aus, ob SDH-Kaptionen während der automatischen Subtitelwahl bevorzugt oder erforderlich sind.',
			'accountPreferences.forcedSubtitleDescription' => 'Wählen Sie aus, ob gezwungenen Subtitle-Stracken während der automatischen Auswahl bevorzugt oder erforderlich sind.',
			'accountPreferences.watchedIndicatorDescription' => 'Wählen Sie aus, welche Medienarten eine beobachtete Checkmarke in der Server-Interface erhalten.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Wählen Sie aus, welche Publikum und kritische Bewertungen der Server auf Medienseiten anzeigt.',
			'accountPreferences.subtitleModeDescription' => 'Wählen Sie aus, wann die Untertitel automatisch für diesen Server-Konto aktiviert werden.',
			'accountPreferences.hubDescription' => 'Diese Präferenzen werden auf Ihrem Media-Server-Konto gespeichert und können auch für andere Kunden gelten.',
			'discover.title' => 'Entdecken',
			'discover.noContentAvailable' => 'Kein Inhalt verfügbar',
			'discover.addMediaToLibraries' => 'Medien zur Mediathek hinzufügen',
			'discover.continueWatching' => 'Weiterschauen',
			'discover.continueWatchingIn' => ({required Object library}) => 'Weiterschauen in ${library}',
			'discover.nextUp' => 'Als Nächstes',
			'discover.nextUpIn' => ({required Object library}) => 'Als Nächstes in ${library}',
			'discover.recentlyAdded' => 'Kürzlich hinzugefügt',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Kürzlich hinzugefügt in ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Neueste Alben in ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Kürzlich gespielt in ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Am häufigsten gespielt in ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Übersicht',
			'discover.cast' => 'Besetzung',
			'discover.findNext.title' => 'Finde deinen nächsten Favoriten',
			'discover.findNext.open' => 'Finde deinen nächsten Favoriten',
			'discover.findNext.anyTime' => 'Beliebige Dauer',
			'discover.findNext.timeAvailable' => 'Wie viel Zeit hast du?',
			'discover.findNext.filters' => 'Passend für deinen Moment',
			'discover.findNext.watch' => 'Ansehen',
			'discover.findNext.listen' => 'Anhören',
			'discover.findNext.read' => 'Lesen',
			'discover.findNext.finishable' => ({required Object duration}) => 'In ${duration} zu schaffen',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Etwa ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Nächstes Kapitel · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => 'Insgesamt ${duration}',
			'discover.findNext.timingVaries' => 'Dauer kann variieren',
			'discover.findNext.notNow' => 'Jetzt nicht',
			'discover.findNext.swipeHint' => 'Wische das Cover in Pfeilrichtung oder nutze die Schaltflächen darunter.',
			'discover.findNext.saved' => 'Gespeicherte Vorschläge',
			'discover.findNext.savedCount' => ({required Object count}) => 'Gespeicherte Vorschläge · ${count}',
			'discover.findNext.undo' => 'Rückgängig',
			'discover.findNext.details' => 'Details',
			'discover.findNext.noPicks' => 'Noch nichts zur Auswahl',
			'discover.findNext.noPicksHint' => 'Verbinde eine Bibliothek oder füge eine Medienquelle hinzu, um loszulegen.',
			'discover.findNext.noMatches' => 'Nichts passt gerade',
			'discover.findNext.noMatchesHint' => 'Probiere eine andere Medienart oder nimm dir etwas mehr Zeit.',
			'discover.findNext.allDone' => 'Du hast alle Vorschläge gesehen',
			'discover.findNext.allDoneHint' => 'Starte eine neue Auswahl, um diese Vorschläge noch einmal zu sehen.',
			'discover.findNext.refresh' => 'Andere Auswahl finden',
			'discover.findNext.sourceReason' => ({required Object source}) => 'Aus ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'Aus ${library}',
			'discover.findNext.ownedReason' => 'Aus deiner Bibliothek',
			'discover.findNext.liveNow' => 'Läuft gerade',
			'discover.findNext.watchLive' => 'Live ansehen',
			'discover.findNext.filterAnything' => 'Alles',
			'discover.findNext.filterWatch' => 'Ansehen',
			'discover.findNext.filterListen' => 'Anhören',
			'discover.findNext.filterRead' => 'Lesen',
			'discover.findNext.twentyMinutes' => '20 Min.',
			'discover.findNext.fortyFiveMinutes' => '45 Min.',
			'discover.findNext.ninetyMinutes' => '90 Min.',
			'discover.findNext.apply' => 'Anwenden',
			'discover.findNext.openFailed' => 'Diese Auswahl ist nicht mehr verfügbar. Aktualisiere, um erneut nachzusehen.',
			'discover.findNext.changeFailed' => 'Die Änderung konnte nicht gespeichert werden. Versuche es erneut.',
			'discover.findNext.savedLimit' => 'Die Liste gespeicherter Vorschläge ist voll. Entferne einen Vorschlag, um einen weiteren zu speichern.',
			'discover.findNext.chooseHint' => 'Öffne einen Vorschlag, speichere ihn für später oder überspringe ihn.',
			'discover.findNext.howItWorks' => 'So funktioniert’s',
			'discover.findNext.notNowHelp' => 'Überspringe diesen Vorschlag vorerst. Er bleibt in deiner Mediathek.',
			'discover.findNext.saveHelp' => 'Speichere ihn unter „Gespeicherte Vorschläge“ für dieses Profil auf diesem Gerät. Dabei wird nichts heruntergeladen.',
			'discover.findNext.openHelp' => 'Wähle das Cover für Details. Mit der Hauptaktion kannst du den Titel abspielen, lesen oder öffnen.',
			'discover.findNext.controlsHelp' => 'Tastatur oder Fernbedienung: Wähle eine Schaltfläche und drücke Enter oder die Auswahltaste. Rückgängig stellt deine letzte Auswahl wieder her.',
			'discover.findNext.artworkLoading' => 'Cover wird geladen…',
			'discover.findNext.artworkUnavailable' => 'Cover nicht verfügbar',
			'discover.findNext.savedFeedback' => 'Zu den gespeicherten Vorschlägen hinzugefügt',
			'discover.findNext.skippedFeedback' => 'Vorerst übersprungen',
			'discover.findNext.releaseToConfirm' => 'Zum Bestätigen loslassen',
			'discover.findNext.remoteHint' => 'Cover im Fokus: ← / → wählen · Auswahltaste: Details · ↑ / ↓: Fokus bewegen',
			'discover.extras' => 'Trailer & Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Altersfreigabe',
			'discover.director' => 'Regisseur',
			'discover.directors' => 'Regisseure',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie',
			'discover.minutesLeft' => ({required Object minutes}) => 'Noch ${minutes} Min.',
			'discover.moreLikeThis' => 'Ähnliche Inhalte',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel', ), 
			'discover.person.born' => 'Geboren',
			'discover.person.died' => 'Gestorben',
			'discover.person.birthplace' => 'Geburtsort',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} Jahre)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (im Alter von ${age} Jahren)',
			'errors.searchFailed' => ({required Object error}) => 'Suche fehlgeschlagen: ${error}',
			'errors.searchUnavailable' => 'Die Suche konnte keinen Medienserver erreichen.',
			'errors.connectionTimeout' => ({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}',
			'errors.connectionFailed' => 'Keine Verbindung zum Medienserver möglich',
			'errors.unableToLoad' => ({required Object context}) => '${context} konnte nicht geladen werden. Bitte erneut versuchen.',
			'errors.noClientAvailable' => 'Kein Client verfügbar',
			'errors.pleaseEnterToken' => 'Bitte Token eingeben',
			'errors.invalidToken' => 'Ungültiges Token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Löschen von ${displayName} fehlgeschlagen',
			'errors.failedToRate' => 'Bewertung konnte nicht aktualisiert werden',
			'errors.reasonTimedOut' => 'Zeitüberschreitung bei der Verbindung',
			'errors.reasonUnreachable' => 'der Medienserver konnte nicht erreicht werden',
			'errors.reasonRefused' => 'der Medienserver hat die Anfrage abgelehnt',
			'errors.reasonNotFound' => 'das Element befindet sich nicht mehr auf dem Medienserver',
			'errors.reasonServerError' => 'der Medienserver hat einen Fehler gemeldet',
			'errors.reasonCancelled' => 'die Anfrage wurde abgebrochen',
			'errors.reasonUnexpected' => 'ein unerwarteter Fehler ist aufgetreten',
			'libraries.playRandomMovie' => 'Spielen Sie einen Random-Film',
			'libraries.randomPickFailed' => 'Ich kann nicht einen Film aus dieser Bibliothek wählen.',
			'libraries.title' => 'Mediatheken',
			'libraries.fallbackTitle' => 'Mediathek',
			'libraries.scanLibraryFiles' => 'Mediatheksdateien scannen',
			'libraries.scanLibrary' => 'Mediathek scannen',
			'libraries.analyze' => 'Analysieren',
			'libraries.analyzeLibrary' => 'Mediathek analysieren',
			'libraries.refreshMetadata' => 'Metadaten aktualisieren',
			'libraries.emptyTrash' => 'Papierkorb leeren',
			'libraries.emptyingTrash' => ({required Object title}) => 'Papierkorb für „${title}“ wird geleert...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papierkorb für „${title}“ geleert',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Papierkorb konnte nicht geleert werden: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analysiere „${title}“...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse gestartet für „${title}“',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Analyse der Mediathek fehlgeschlagen: ${error}',
			'libraries.noLibrariesFound' => 'Keine Mediatheken gefunden',
			'libraries.allLibrariesHidden' => 'Alle Mediatheken sind ausgeblendet',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Ausgeblendete Mediatheken (${count})',
			'libraries.thisLibraryIsEmpty' => 'Diese Mediathek ist leer',
			'libraries.noItemsMatchFilters' => 'Keine Elemente entsprechen den aktiven Filtern',
			'libraries.resetFilters' => 'Filter zurücksetzen',
			'libraries.all' => 'Alle',
			'libraries.clearAll' => 'Alle Filter entfernen',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '„${title}“ wirklich scannen?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '„${title}“ wirklich analysieren?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Metadaten für „${title}“ wirklich aktualisieren?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Papierkorb für „${title}“ wirklich leeren?',
			'libraries.manageLibraries' => 'Mediatheken verwalten',
			'libraries.sort' => 'Sortieren',
			'libraries.sortBy' => 'Sortieren nach',
			'libraries.filters' => 'Filter',
			'libraries.confirmActionMessage' => 'Aktion wirklich durchführen?',
			'libraries.showLibrary' => 'Mediathek anzeigen',
			'libraries.hideLibrary' => 'Mediathek ausblenden',
			'libraries.libraryOptions' => 'Mediatheksoptionen',
			'libraries.content' => 'Mediatheksinhalt',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Mediathek auswählen',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filter (${count})',
			'libraries.noRecommendations' => 'Keine Empfehlungen verfügbar',
			'libraries.noCollections' => 'Keine Sammlungen in dieser Mediathek',
			'libraries.noFoldersFound' => 'Keine Ordner gefunden',
			'libraries.folders' => 'Ordner',
			'libraries.tabs.recommended' => 'Empfohlen',
			'libraries.tabs.browse' => 'Durchsuchen',
			'libraries.tabs.collections' => 'Sammlungen',
			'libraries.tabs.playlists' => 'Wiedergabelisten',
			'libraries.groupings.title' => 'Gruppierung',
			'libraries.groupings.all' => 'Alle',
			'libraries.groupings.movies' => 'Filme',
			'libraries.groupings.shows' => 'Serien',
			'libraries.groupings.seasons' => 'Staffeln',
			'libraries.groupings.episodes' => 'Episoden',
			'libraries.groupings.artists' => 'Interpreten',
			'libraries.groupings.albums' => 'Alben',
			'libraries.groupings.tracks' => 'Titel',
			'libraries.groupings.folders' => 'Ordner',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'Jahr',
			'libraries.filterCategories.contentRating' => 'Altersfreigabe',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Ungesehene',
			'libraries.filterCategories.unplayed' => 'Nicht abgespielt',
			'libraries.filterCategories.favorites' => 'Favoriten',
			'libraries.filterCategories.filePath' => 'Dateipfad',
			'libraries.sortLabels.title' => 'Titel',
			'libraries.sortLabels.dateAdded' => 'Hinzugefügt am',
			'libraries.sortLabels.releaseDate' => 'Erscheinungsdatum',
			'libraries.sortLabels.rating' => 'Bewertung',
			'libraries.sortLabels.communityRating' => 'Communitybewertung',
			'libraries.sortLabels.criticRating' => 'Kritikerbewertung',
			'libraries.sortLabels.userRating' => 'Benutzerbewertung',
			'libraries.sortLabels.datePlayed' => 'Wiedergabedatum',
			'libraries.sortLabels.playCount' => 'Wiedergaben',
			'libraries.sortLabels.productionYear' => 'Produktionsjahr',
			'libraries.sortLabels.runtime' => 'Laufzeit',
			'libraries.sortLabels.officialRating' => 'Offizielle Bewertung',
			'libraries.sortLabels.premiereDate' => 'Veröffentlichungsdatum',
			'libraries.sortLabels.startDate' => 'Startdatum',
			'libraries.sortLabels.airTime' => 'Sendezeit',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Zufällig',
			'libraries.sortLabels.dateShared' => 'Datum geteilt',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Ausstrahlungsdatum der neuesten Folge',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Hinzugefügt am (neueste Folge)',
			'libraries.sortLabels.dateDownloaded' => 'Heruntergeladen am',
			'libraries.sortLabels.size' => 'Größe',
			'libraries.sortLabels.library' => 'Mediathek',
			'libraries.advancedFilters.include' => 'Einschließen',
			'libraries.advancedFilters.exclude' => 'Ausschließen',
			'libraries.advancedFilters.any' => 'Beliebig',
			'libraries.advancedFilters.yes' => 'Ja',
			'libraries.advancedFilters.no' => 'Nein',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Nicht ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} ausgewählt',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} ausgeschlossen',
			'libraries.advancedFilters.searchValues' => 'Werte suchen',
			'libraries.advancedFilters.noValues' => 'Keine Werte',
			'libraries.advancedFilters.matchContains' => 'Enthält',
			'libraries.advancedFilters.matchNotContains' => 'Enthält nicht',
			'libraries.advancedFilters.matchIs' => 'Ist',
			'libraries.advancedFilters.matchIsNot' => 'Ist nicht',
			'libraries.advancedFilters.matchBeginsWith' => 'Beginnt mit',
			'libraries.advancedFilters.matchEndsWith' => 'Endet mit',
			'libraries.advancedFilters.textHint' => 'Suchtext eingeben',
			'libraries.advancedFilters.from' => 'Von',
			'libraries.advancedFilters.to' => 'Bis',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} bis ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => 'Ab ${value}',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Bis ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Letzte ${count} Tage',
			'libraries.advancedFilters.dateLastYear' => 'Im letzten Jahr',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Älter als ${count} Tage',
			'libraries.advancedFilters.dateOlderThanYear' => 'Älter als ein Jahr',
			'libraries.selection.selectItems' => 'Wählen Sie die Elemente',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} ausgewählt',
			'libraries.selection.actions' => 'Auswahl Aktionen',
			'libraries.selection.confirmDescendants' => 'Dies ändert alle Episoden in den ausgewählten Shows und Jahreszeiten.',
			'libraries.selection.confirmUnwatched' => 'Dabei wird auch der Wiedergabefortschritt der ausgewählten Elemente gelöscht.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Auswählte Artikel: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Aktualisierte Artikel: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Aktualisiert ${succeeded}; versagt ${failed}. Versagtes Produkt bleibt ausgewählt.',
			'about.title' => 'Über',
			'about.openSourceLicenses' => 'Open-Source-Lizenzen',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Ein schöner, mit Flutter entwickelter Plex-, Jellyfin- und Emby-Client',
			'about.viewLicensesDescription' => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen',
			'about.privacyPolicy' => 'Datenschutzerklärung',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Server konnten nicht geladen werden: ${error}',
			'serverSelection.noValidServers' => 'Für dieses Konto wurden keine nutzbaren Server gefunden',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Erscheinungsjahr',
			'hubDetail.dateAdded' => 'Hinzugefügt am',
			'hubDetail.rating' => 'Bewertung',
			'hubDetail.noItemsFound' => 'Keine Elemente gefunden',
			'logs.clearLogs' => 'Protokolle löschen',
			'logs.copyLogs' => 'Protokolle kopieren',
			'logs.uploadLogs' => 'Protokolle hochladen',
			'logs.saveLogs' => 'Speichern Sie Logs auf Dateien',
			'logs.logsSaved' => ({required Object path}) => 'Logs gespeichert auf ${path}',
			'logs.saveLogsFailed' => 'Ich konnte die Log-Datei nicht speichern.',
			'startup.failedTitle' => 'PlezyNG konnte nicht gestartet werden',
			'startup.failedBody' => 'Beim Start ist etwas schiefgelaufen. Die Details unten zeigen, was fehlgeschlagen ist.',
			'startup.failedBodyRepairable' => 'Die gespeicherte Einstellungsdatei von PlezyNG ist beschädigt und muss neu aufgebaut werden, bevor PlezyNG starten kann. Erneutes Versuchen hilft nicht – wähle „Speicher reparieren“.',
			'startup.phaseLabel' => 'Schritt',
			'startup.showDetails' => 'Details anzeigen',
			'startup.hideDetails' => 'Details ausblenden',
			'startup.copyDetails' => 'Details kopieren',
			'startup.detailsCopied' => 'Details in die Zwischenablage kopiert',
			'startup.uploadDetails' => 'Details hochladen',
			'startup.repairStorage' => 'Speicher reparieren',
			'startup.repairTitle' => 'Gespeicherte Daten reparieren?',
			'startup.repairBodyCommon' => 'Die Einstellungsdatei von PlezyNG ist beschädigt und kann nicht gelesen werden. Beim Reparieren werden alle Einstellungen auf ihre Standardwerte zurückgesetzt.',
			'startup.repairBodyOneCredential' => 'Eine gespeicherte Anmeldung ist beschädigt und kann nicht gelesen werden. Beim Reparieren wird nur diese entfernt; deine übrigen Einstellungen bleiben unangetastet.',
			'startup.repairBodySignInsKept' => 'Deine Server und Profile sollten angemeldet bleiben.',
			'startup.repairBodySignInsLost' => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, kann aus dieser Datei nicht wiederhergestellt werden. Du musst dich daher bei jedem Server und Profil erneut anmelden. Auf deinem Medienserver ändert sich nichts.',
			'startup.repairBodySessionsUncertain' => 'Tracker (MAL, AniList, Simkl, Trakt) und Seerr werden separat gespeichert und können erhalten bleiben oder auch nicht. PlezyNG teilt dir genau mit, was erhalten blieb.',
			'startup.repairConfirm' => 'Reparieren',
			'startup.repairSucceeded' => 'Speicher repariert',
			'startup.repairNeedsRestart' => 'Speicher repariert – Neustart erforderlich',
			'startup.restartRequiredBody' => 'Deine Daten wurden repariert, aber PlezyNG muss neu starten, bevor es sie verwenden kann. Schließe PlezyNG und öffne es erneut.',
			'startup.quitPlezy' => 'PlezyNG beenden',
			'startup.repairFailed' => 'Reparatur fehlgeschlagen',
			'startup.repairKeptSignIns' => 'Deine Server und Profile sind weiterhin angemeldet.',
			'startup.repairLostSignIns' => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, konnte nicht wiederhergestellt werden. Du musst dich bei jedem Server und Profil erneut anmelden.',
			'startup.repairLostSessions' => 'Mindestens eine Tracker- oder Seerr-Verbindung ging verloren und muss neu verbunden werden.',
			'startup.backupTitle' => 'Eine Kopie der beschädigten Datei wurde aufbewahrt',
			'startup.backupWarning' => 'Sie enthält deine Anmeldedaten. Lade sie nicht hoch und teile sie nicht.',
			'startup.deleteBackup' => 'Kopie löschen',
			'startup.backupDeleted' => 'Kopie gelöscht.',
			'startup.previousFailureTitle' => 'PlezyNG konnte beim letzten Mal nicht starten',
			'licenses.relatedPackages' => 'Verwandte Pakete',
			'licenses.license' => 'Lizenz',
			'licenses.licenseNumber' => ({required Object number}) => 'Lizenz ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} Lizenzen',
			'navigation.libraries' => 'Mediatheken',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live-TV',
			'navigation.explore' => 'Erkunden',
			'explore.mdblistShelves.manage' => 'Führung Explore Schiffe',
			'explore.mdblistShelves.manageDescription' => 'Wählen und sortieren Sie Listen aus Ihrem Konto MDBList',
			'explore.mdblistShelves.description' => 'Wählen Sie öffentliche Film- und TV-Listen aus Ihrem Konto MDBList aus. Erstellen oder Kopieren Sie Listen auf MDBList, dann aktualisieren.',
			'explore.mdblistShelves.selected' => 'ausgewählte Schichten',
			'explore.mdblistShelves.available' => 'Verfügbare Konto-Listen',
			'explore.mdblistShelves.noLists' => 'Keine öffentlichen Filme oder TV-Listen zurückgegeben. Erstellen oder kopieren Sie eine Liste auf MDBList, dann erneuern.',
			'explore.mdblistShelves.displayName' => 'Shelf Display Name',
			'explore.mdblistShelves.nameHint' => 'Lassen Sie das Schalt, um den Quelllistenamen zu verwenden.',
			'explore.mdblistShelves.add' => 'Schalke hinzufügen',
			'explore.mdblistShelves.save' => 'Sparen Sie Schiffe',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => '${title} nach oben verschieben',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => '${title} nach unten',
			'explore.mdblistShelves.unavailable' => 'Diese Liste ist nicht verfügbar. Rückkehr oder Entfernen der Schale in Einstellungen.',
			'explore.mdblistShelves.rateLimited' => 'MDBList Anfrage Limit erreicht. Bitte zurückkehren später.',
			'explore.mdblistShelves.loadFailed' => 'Kann nicht Laden Schichten. Überprüfen Sie Ihre Verbindung und Retry.',
			'explore.mdblistShelves.saveFailed' => 'Ich kann nicht die Schlange retten. bitte zurück.',
			'explore.mdblistShelves.accountChanged' => 'Das Konto oder das Profil geändert. Wieder öffnen Sie diese Einstellungen.',
			'explore.mdblistShelves.settingsUnreadable' => 'Speicherte Schalen können nicht gelesen werden. Wählen Sie Ihre Listen erneut aus, um diese Einstellungen zu ersetzen.',
			'explore.title' => 'Erkunden',
			'explore.selectSource' => 'Quelle auswählen',
			'explore.rows.watchlist' => 'Merkliste',
			'explore.rows.recommendedMovies' => 'Empfohlene Filme',
			'explore.rows.recommendedShows' => 'Empfohlene Serien',
			'explore.rows.trendingMovies' => 'Angesagte Filme',
			'explore.rows.trendingShows' => 'Angesagte Serien',
			'explore.rows.popularMovies' => 'Beliebte Filme',
			'explore.rows.popularShows' => 'Beliebte Serien',
			'explore.rows.trendingAnime' => 'Angesagte Anime',
			'explore.rows.suggestedAnime' => 'Empfohlene Anime',
			'explore.rows.airingAnime' => 'Beste derzeit laufende Anime',
			'explore.rows.popularAnime' => 'Beliebteste Anime',
			'explore.rows.trending' => 'Angesagt',
			'explore.rows.upcomingMovies' => 'Kommende Filme',
			'explore.rows.upcomingShows' => 'Kommende Serien',
			'explore.status.airing' => 'Laufend',
			'explore.status.ended' => 'Beendet',
			'explore.status.canceled' => 'Abgesetzt',
			'explore.status.upcoming' => 'Demnächst',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folge', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Folgen', ), 
			'explore.cast' => 'Besetzung',
			'explore.characters' => 'Charaktere',
			'explore.addToWatchlist' => 'Zur Merkliste hinzufügen',
			'explore.removeFromWatchlist' => 'Von Merkliste entfernen',
			'explore.addedToWatchlist' => 'Zur Watchlist hinzugefügt',
			'explore.removedFromWatchlist' => 'Von der Watchlist entfernt',
			'explore.watchlistUpdateFailed' => 'Merkliste konnte nicht aktualisiert werden',
			'explore.watchlistNoMatch' => 'Dieser Eintrag konnte keiner Watchlist zugeordnet werden',
			'explore.notInLibrary' => 'Nicht in deiner Mediathek',
			'explore.inTheseLibraries' => 'In diesen Mediatheken',
			'explore.checkingLibrary' => 'Deine Mediathek wird überprüft …',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Server konnte nicht geprüft werden', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Server konnten nicht geprüft werden', ), 
			'explore.emptyTitle' => 'Hier ist noch nichts',
			'explore.emptyMessage' => ({required Object source}) => 'Zeilen aus ${source} erscheinen hier, sobald sie Inhalte enthalten.',
			'explore.searchHint' => ({required Object source}) => '${source} durchsuchen',
			'explore.searchEmpty' => ({required Object query}) => 'Keine Ergebnisse für „${query}“',
			'explore.searchPrompt' => ({required Object source}) => 'Suche nach Filmen und Serien auf ${source}.',
			'explore.searchFailed' => 'Suche fehlgeschlagen. Prüfe deine Verbindung und versuche es erneut.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} beliebt',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} derzeit ausgestrahlt',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} bewertet',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} angesagt',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} in ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} schauen gerade',
			'explore.badge.available' => 'Verfügbar',
			'explore.badge.partiallyAvailable' => 'Teilweise verfügbar',
			'explore.badge.availableIn4k' => '4K verfügbar',
			'explore.badge.requested' => 'Angefragt',
			'explore.badge.pendingApproval' => 'Genehmigung ausstehend',
			'explore.badge.processing' => 'Wird verarbeitet',
			'explore.badge.declined' => 'Abgelehnt',
			'explore.badge.requestFailed' => 'Anfrage fehlgeschlagen',
			'explore.badge.requested4k' => '4K angefragt',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} Staffeln',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Folge ${episode} in ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Nächste in ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} Folgen',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} Min./Folge',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} gelistet',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} heute gesehen',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} diese Woche gesehen',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} diesen Monat gesehen',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} dieses Jahr gesehen',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} Zuschauer',
			'explore.stats.planning' => ({required Object n}) => '${n} haben es geplant',
			'explore.stats.favorited' => ({required Object n}) => '${n} Favoriten',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} haben es abgebrochen',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Kommentar', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Kommentare', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} Stimmen',
			'explore.stats.watching' => ({required Object n}) => '${n} schauen es gerade',
			'explore.stats.completed' => ({required Object n}) => '${n} abgeschlossen',
			'explore.stats.onHold' => ({required Object n}) => '${n} pausiert',
			'explore.stats.dropped' => ({required Object n}) => '${n} abgebrochen',
			'explore.season.winter' => 'Winter',
			'explore.season.spring' => 'Frühling',
			'explore.season.summer' => 'Sommer',
			'explore.season.fall' => 'Herbst',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV-Kurzfilm',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Special',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musik',
			'explore.format.other' => 'Sonstiges',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light Novel',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Visual Novel',
			'explore.sourceMaterial.game' => 'Spiel',
			'explore.sourceMaterial.webComic' => 'Webcomic',
			'explore.sourceMaterial.musicRelease' => 'Musik',
			'explore.sourceMaterial.otherMedia' => 'Sonstiges',
			'explore.creditRole.actor' => 'Darsteller',
			'explore.creditRole.director' => 'Regisseur',
			'explore.creditRole.writer' => 'Autor',
			'explore.creditRole.producer' => 'Produzent',
			'explore.creditRole.creator' => 'Schöpfer',
			'explore.creditRole.composer' => 'Komponist',
			'explore.relation.prequel' => 'Prequel',
			'explore.relation.sequel' => 'Fortsetzung',
			'explore.relation.sideStory' => 'Nebengeschichte',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternative Version',
			'explore.relation.summary' => 'Zusammenfassung',
			'explore.relation.parentStory' => 'Hauptgeschichte',
			'explore.relation.adaptation' => 'Adaption',
			'explore.relation.other' => 'Verwandt',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Läuft ${day} um ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Läuft ${day} um ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Originaltitel',
			'explore.detail.alsoKnownAs' => 'Auch bekannt als',
			'explore.detail.studios' => 'Studios',
			'explore.detail.country' => 'Land',
			'explore.detail.language' => 'Sprache',
			'explore.detail.released' => 'Erschienen',
			'explore.detail.physicalRelease' => 'Auf Disc',
			'explore.detail.ended' => 'Beendet',
			'explore.detail.addedOn' => ({required Object date}) => 'Hinzugefügt am ${date}',
			'explore.detail.yourRating' => 'Deine Bewertung',
			'explore.detail.budget' => 'Budget',
			'explore.detail.revenue' => 'Einspielergebnis',
			'explore.detail.contentAdvisory' => 'Altersfreigabe',
			'explore.detail.tags' => 'Tags',
			'explore.detail.revealSpoilerTags' => 'Spoiler-Tags anzeigen',
			'explore.detail.links' => 'Links',
			'explore.detail.watchOn' => 'Ansehen auf',
			'explore.detail.watchTrailer' => 'Trailer ansehen',
			'explore.detail.openOn' => ({required Object site}) => 'Auf ${site} öffnen',
			'explore.detail.crew' => 'Crew',
			'explore.detail.ratings' => 'Bewertungen',
			'explore.detail.schedule' => 'Sendetermine',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Von ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Nutzer empfohlen', other: 'Von ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Nutzern empfohlen', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Empfohlen von ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorisiert von ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} noch nicht ausgestrahlt',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Von ${percent} der Zuschauer empfohlen',
			'explore.detail.relatedTitles' => 'Verwandte Titel',
			'explore.detail.background' => 'Hintergrund',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ergebnis', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ergebnisse', ), 
			'liveTv.title' => 'Live-TV',
			'liveTv.guide' => 'TV-Programm',
			'liveTv.noChannels' => 'Keine Kanäle verfügbar',
			'liveTv.noDvr' => 'Auf keinem Server ist ein DVR konfiguriert',
			'liveTv.serverUnavailable' => 'Der Live-TV-Server ist nicht verfügbar.',
			'liveTv.serverNotConnected' => 'Der Live-TV-Server ist nicht verbunden.',
			'liveTv.noPrograms' => 'Keine Programmdaten verfügbar',
			'liveTv.liveStreamFailed' => 'Livestream fehlgeschlagen',
			'liveTv.unknownProgram' => 'Unbekannte Sendung',
			'liveTv.timelineLiveProgram' => 'Live-Programm (Playback kann außerhalb dieses Programms sein)',
			'liveTv.timelineBuffer' => 'Buffer Timeline',
			'liveTv.timelineUnavailable' => 'Timeline nicht verfügbar',
			'liveTv.timelineEstimated' => 'Bewertung des Playback',
			'liveTv.timelinePending' => 'Nachsuchen',
			'liveTv.timelineStale' => 'Der Zeitplan kann verlängert werden',
			'liveTv.unknownHub' => 'Unbekannt',
			'liveTv.unknownError' => 'Unbekannter Fehler',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Unbekannter Kanal',
			'liveTv.live' => 'LIVE',
			'liveTv.premiereBadge' => 'Neues',
			'liveTv.reloadGuide' => 'TV-Programm neu laden',
			'liveTv.searchGuide' => 'TV-Programm durchsuchen',
			'liveTv.searchHint' => 'Kanäle & Sendungen suchen',
			'liveTv.searchNoResults' => ({required Object query}) => 'Keine Treffer für „${query}“',
			'liveTv.channelsSection' => 'Kanäle',
			'liveTv.programsSection' => 'Sendungen',
			'liveTv.now' => 'Jetzt',
			'liveTv.today' => 'Heute',
			'liveTv.tomorrow' => 'Morgen',
			'liveTv.midnight' => 'Mitternacht',
			'liveTv.overnight' => 'Nacht',
			'liveTv.morning' => 'Morgen',
			'liveTv.daytime' => 'Tagsüber',
			'liveTv.evening' => 'Abend',
			'liveTv.lateNight' => 'Spätnacht',
			'liveTv.whatsOn' => 'Jetzt im TV',
			'liveTv.watchChannel' => 'Kanal ansehen',
			'liveTv.favorites' => 'Favoriten',
			'liveTv.reorderFavorites' => 'Favoriten sortieren',
			'liveTv.noFavoriteChannels' => 'Keine Lieblingssender',
			'liveTv.noFavoriteChannelsHint' => 'Zeige alle Sender an und halte dann einen Sender gedrückt, um ihn zu deinen Favoriten hinzuzufügen.',
			'liveTv.showAllChannels' => 'Alle Sender anzeigen',
			'liveTv.favoritesLoadFailed' => 'Favoriten konnten nicht geladen werden. Überprüfe deine Verbindung und versuche es erneut.',
			'liveTv.favoritesUpdateFailed' => 'Favoriten konnten nicht aktualisiert werden. Prüfe deine Verbindung und versuche es erneut.',
			'liveTv.joinSession' => 'Aktueller Sitzung beitreten',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Von Anfang an ansehen (vor ${minutes} Min.)',
			'liveTv.watchLive' => 'Live ansehen',
			'liveTv.goToLive' => 'Zum Live-Bild',
			'liveTv.record' => 'Aufnehmen',
			'liveTv.recordEpisode' => 'Episode aufnehmen',
			'liveTv.recordSeries' => 'Serie aufnehmen',
			'liveTv.recordOptions' => 'Aufnahmeoptionen',
			'liveTv.saveTo' => 'Speichern in',
			'liveTv.recordings' => 'Aufnahmen',
			'liveTv.scheduledRecordings' => 'Geplant',
			'liveTv.recordingRules' => 'Aufnahmeregeln',
			'liveTv.noScheduledRecordings' => 'Keine geplanten Aufnahmen',
			'liveTv.manageRecording' => 'Aufnahme verwalten',
			'liveTv.cancelRecording' => 'Aufnahme abbrechen',
			'liveTv.cancelRecordingTitle' => 'Diese Aufnahme abbrechen?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} wird nicht mehr aufgenommen.',
			'liveTv.deleteRule' => 'Regel löschen',
			'liveTv.deleteRuleTitle' => 'Aufnahmeregel löschen?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Zukünftige Episoden von ${title} werden nicht aufgenommen.',
			'liveTv.recordingScheduled' => 'Aufnahme geplant',
			'liveTv.alreadyScheduled' => 'Dieses Programm ist bereits geplant',
			'liveTv.dvrAdminRequired' => 'DVR-Einstellungen erfordern ein Administratorkonto',
			'liveTv.recordingFailed' => 'Aufnahme konnte nicht geplant werden',
			'liveTv.recordingTargetMissing' => 'Aufnahmebibliothek konnte nicht ermittelt werden',
			'liveTv.recordNotAvailable' => 'Aufnahme für dieses Programm nicht verfügbar',
			'liveTv.recordingCancelled' => 'Aufnahme abgebrochen',
			'liveTv.recordingRuleDeleted' => 'Aufnahmeregel gelöscht',
			'liveTv.processRecordingRules' => 'Regeln neu bewerten',
			'liveTv.recordingInProgress' => 'Wird jetzt aufgenommen',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} geplant',
			'liveTv.editRule' => 'Regel bearbeiten',
			'liveTv.editRuleAction' => 'Bearbeiten',
			'liveTv.recordingRuleUpdated' => 'Aufnahmeregel aktualisiert',
			'liveTv.guideReloadRequested' => 'Aktualisierung des TV-Programms angefordert',
			'liveTv.guideReloadFailed' => 'TV-Programm konnte nicht aktualisiert werden',
			'liveTv.rulesProcessRequested' => 'Regelauswertung angefordert',
			'liveTv.rulesProcessFailed' => 'Aufnahmeregeln konnten nicht neu ausgewertet werden',
			'liveTv.recordShow' => 'Sendung aufnehmen',
			'liveTv.recordSettings.startEarly' => 'Früher starten (Sekunden)',
			'liveTv.recordSettings.endLate' => 'Später beenden (Sekunden)',
			'liveTv.recordSettings.newOnly' => 'Nur neue Episoden',
			'liveTv.recordSettings.anyChannel' => 'Auf jedem Sender aufnehmen',
			'liveTv.recordSettings.anyTime' => 'Zu jeder Zeit aufnehmen',
			'liveTv.recordSettings.skipInLibrary' => 'Episoden überspringen, die schon in der Bibliothek sind',
			'liveTv.recordSettings.keepUpTo' => 'Zu behaltende Episoden',
			'liveTv.recordSettings.keepUpToHint' => '0 behält alle Episoden',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Beginnt in ${minutes} Min.',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} um ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} hat ungültige Live-TV-Wiedergabedaten zurückgegeben',
			'liveTv.failedToStartChannel' => 'Der Live-Sender konnte nicht gestartet werden',
			'liveTv.failedToBuildStreamUrl' => 'Die Stream-URL konnte nicht erstellt werden',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Sender konnte nicht gestartet werden: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Sender konnte nicht gewechselt werden: ${reason}',
			'collections.title' => 'Sammlungen',
			'collections.collection' => 'Sammlung',
			'collections.empty' => 'Sammlung ist leer',
			'collections.deleteCollection' => 'Sammlung löschen',
			'collections.deleteConfirm' => ({required Object title}) => '„${title}“ löschen? Dies kann nicht rückgängig gemacht werden.',
			'collections.deleted' => 'Sammlung gelöscht',
			'collections.deleteFailed' => 'Sammlung konnte nicht gelöscht werden',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}',
			'collections.selectCollection' => 'Sammlung auswählen',
			'collections.collectionName' => 'Sammlungsname',
			'collections.enterCollectionName' => 'Sammlungsnamen eingeben',
			'collections.addedToCollection' => 'Zur Sammlung hinzugefügt',
			'collections.errorAddingToCollection' => 'Fehler beim Hinzufügen zur Sammlung',
			'collections.created' => 'Sammlung erstellt',
			'collections.removeFromCollection' => 'Aus Sammlung entfernen',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '„${title}“ aus dieser Sammlung entfernen?',
			'collections.removedFromCollection' => 'Aus Sammlung entfernt',
			'collections.removeFromCollectionFailed' => 'Entfernen aus Sammlung fehlgeschlagen',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}',
			'collections.searchCollections' => 'Sammlungen durchsuchen...',
			'playlists.title' => 'Wiedergabelisten',
			'playlists.playlist' => 'Wiedergabeliste',
			'playlists.noPlaylists' => 'Keine Wiedergabelisten gefunden',
			'playlists.create' => 'Wiedergabeliste erstellen',
			'playlists.playlistName' => 'Name der Wiedergabeliste',
			'playlists.enterPlaylistName' => 'Name der Wiedergabeliste eingeben',
			'playlists.delete' => 'Wiedergabeliste löschen',
			'playlists.removeItem' => 'Aus Wiedergabeliste entfernen',
			'playlists.smartPlaylist' => 'Intelligente Wiedergabeliste',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Element', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Elemente', ), 
			'playlists.emptyPlaylist' => 'Diese Wiedergabeliste ist leer',
			'playlists.deleteConfirm' => 'Wiedergabeliste löschen?',
			'playlists.deleteMessage' => ({required Object name}) => '„${name}“ wirklich löschen?',
			'playlists.created' => 'Wiedergabeliste erstellt',
			'playlists.deleted' => 'Wiedergabeliste gelöscht',
			'playlists.itemAdded' => 'Zur Wiedergabeliste hinzugefügt',
			'playlists.itemRemoved' => 'Aus Wiedergabeliste entfernt',
			'playlists.selectPlaylist' => 'Wiedergabeliste auswählen',
			'playlists.searchPlaylists' => 'Wiedergabelisten durchsuchen...',
			'playlists.errorCreating' => 'Wiedergabeliste konnte nicht erstellt werden',
			'playlists.errorDeleting' => 'Wiedergabeliste konnte nicht gelöscht werden',
			'playlists.errorLoading' => 'Wiedergabelisten konnten nicht geladen werden',
			'playlists.errorAdding' => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden',
			'playlists.errorReordering' => 'Element der Wiedergabeliste konnte nicht neu geordnet werden',
			'playlists.errorRemoving' => 'Konnte nicht aus der Wiedergabeliste entfernt werden',
			'music.goToAlbum' => 'Zum Album',
			'music.goToArtist' => 'Zum Interpreten',
			'music.instantMix' => 'Instant-Mix',
			'music.playNext' => 'Als Nächstes abspielen',
			'music.addToQueue' => 'Zur Warteschlange hinzufügen',
			'music.discNumber' => ({required Object n}) => 'Disc ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Titel', ), 
			'music.nowPlaying' => 'Wird wiedergegeben',
			'music.playingFrom' => ({required Object title}) => 'Wiedergabe von ${title}',
			'music.queue' => 'Warteschlange',
			'music.clearQueue' => 'Warteschlange leeren',
			'music.lyrics' => 'Songtext',
			'music.visualizer' => 'Visualisieren',
			'music.visualizerProfileLoading' => 'Lesen Sie Track Analysen ...',
			'music.visualizerAmbientMotion' => 'Umweltbewegung',
			'music.visualizerPlexLoudness' => 'Plex Lautstärke',
			'music.visualizerPreviousPreset' => 'Vorheriger ArtikelVisuelle Art',
			'music.visualizerNextPreset' => 'Nächster Beitrag Visual Style',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blum',
			'music.visualizerPresetOrbitals' => 'Orbitale',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Tunnel',
			'music.visualizerPresetTrackMap' => 'Track Karte',
			'music.noLyrics' => 'Kein Songtext verfügbar',
			'music.sleepTimer' => 'Schlaftimer',
			'music.sleepTimerEndOfTrack' => 'Ende des Titels',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Minuten', ), 
			'music.stopPlayback' => 'Wiedergabe stoppen',
			'music.previousTrack' => 'Vorheriger Titel',
			'music.nextTrack' => 'Nächster Titel',
			'music.repeat' => 'Wiederholen',
			'music.repeatAll' => 'Alle wiederholen',
			'music.repeatOne' => 'Titel wiederholen',
			'music.instantMixNoServer' => 'Für einen Instant Mix ist kein Server verfügbar',
			'music.instantMixFailed' => 'Instant-Mix konnte nicht geladen werden',
			'music.instantMixEmpty' => 'Der Instant-Mix enthält keine Titel',
			'music.noAudioUrl' => ({required Object track}) => 'Für ${track} ist keine Audio-URL verfügbar',
			'music.discography.singlesAndEps' => 'Singles & EPs',
			'music.discography.live' => 'Live',
			'music.discography.compilations' => 'Kompilationen',
			'watchTogether.title' => 'Gemeinsam Schauen',
			'watchTogether.description' => 'Inhalte synchron mit Freunden und Familie schauen',
			'watchTogether.createRoom' => 'Raum erstellen',
			'watchTogether.creatingRoom' => 'Raum wird erstellt …',
			'watchTogether.joinRoom' => 'Raum beitreten',
			'watchTogether.joiningRoom' => 'Beitritt zum Raum …',
			'watchTogether.connecting' => 'Verbindung wird hergestellt …',
			'watchTogether.relayPublic' => 'Räume nutzen die öffentlichen Relays von Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Räume nutzen dein Relay unter ${url}.',
			'watchTogether.recentRooms' => 'Zuletzt verwendete Räume',
			'watchTogether.roomActions' => 'Raumaktionen',
			'watchTogether.renameRoom' => 'Raum umbenennen',
			'watchTogether.removeRoom' => 'Entfernen',
			'watchTogether.enterRoomCode' => 'Gib den 6-stelligen Code vom Host ein.',
			'watchTogether.roomCode' => 'Raumcode',
			'watchTogether.paste' => 'Einfügen',
			'watchTogether.noCodeInClipboard' => 'Die Zwischenablage enthält keinen Raumcode',
			'watchTogether.copyCode' => 'Code kopieren',
			'watchTogether.codeCopied' => 'Raumcode kopiert',
			'watchTogether.shareInvite' => 'Einladung teilen',
			'watchTogether.inviteCopied' => 'Einladung kopiert. Füge sie in eine Nachricht ein.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Komm in meinen Raum für Gemeinsam Schauen in PlezyNG: Öffne „Gemeinsam Schauen“, wähle „Raum beitreten“ und gib ${code} ein.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => 'Sitzungssteuerung für Gemeinsam Schauen öffnen',
			'watchTogether.reconnecting' => 'Verbindung wird wiederhergestellt …',
			'watchTogether.reconnectingDescription' => 'Die Verbindung wurde unterbrochen. Du trittst dem Raum automatisch wieder bei.',
			'watchTogether.connected' => 'Verbunden',
			'watchTogether.disconnected' => 'Getrennt',
			'watchTogether.youAreHost' => 'Du bist der Host',
			'watchTogether.hostedBy' => ({required Object name}) => 'Gehostet von ${name}',
			'watchTogether.hostControlsPlayback' => 'Host steuert die Wiedergabe',
			'watchTogether.anyoneCanControl' => 'Alle können die Wiedergabe steuern',
			'watchTogether.roomLocked' => 'Raum gesperrt',
			'watchTogether.nowPlaying' => 'Wird wiedergegeben',
			'watchTogether.nothingPlaying' => 'Es läuft nichts',
			'watchTogether.nothingPlayingHost' => 'Spiele etwas aus einer beliebigen Mediathek ab, um es mit dem Raum zu teilen.',
			'watchTogether.nothingPlayingGuest' => 'Wenn der Host etwas abspielt, wird es hier geöffnet.',
			'watchTogether.notShareable' => 'Für dieses Video gibt es keinen Katalogtreffer, daher können es nur Personen mit Zugriff auf denselben Server abspielen.',
			'watchTogether.searching' => 'Dieses Video wird in deinen Mediatheken gesucht …',
			'watchTogether.yourCopy' => 'Deine Kopie',
			'watchTogether.sharingYourCopy' => 'Du teilst deine Kopie',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Deine Kopie wird abgespielt (${difference})',
			'watchTogether.mismatchTitle' => 'Deine Kopie hat eine andere Länge',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Deine am besten passende Kopie ist ${difference} als das Video im Raum. Möglicherweise ist es eine andere Schnittfassung oder Version.',
			'watchTogether.playAnyway' => 'Trotzdem abspielen',
			'watchTogether.chooseAnotherCopy' => 'Andere Kopie wählen',
			'watchTogether.dontPlay' => 'Nicht abspielen',
			'watchTogether.unavailableTitle' => 'Du hast dieses Video nicht',
			'watchTogether.unavailableDescription' => 'PlezyNG hat es nicht in deinen Mediatheken gefunden. Wähle selbst eine Kopie oder suche erneut.',
			'watchTogether.chooseCopy' => 'Kopie wählen',
			'watchTogether.searchAgain' => 'Erneut suchen',
			'watchTogether.noCandidates' => 'Keine Kopien in deinen Mediatheken gefunden.',
			'watchTogether.choiceFailed' => 'Diese Kopie konnte nicht für den Raum abgespielt werden',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} länger',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} kürzer',
			'watchTogether.lengthSame' => 'Gleiche Länge',
			'watchTogether.lengthUnknown' => 'Länge unbekannt',
			'watchTogether.joinCurrentPlayback' => 'Aktueller Wiedergabe beitreten',
			'watchTogether.joinCurrentPlaybackDescription' => 'Zu dem Inhalt wechseln, den der Host gerade ansieht',
			'watchTogether.stopMedia' => 'Video für alle stoppen',
			'watchTogether.syncOffset' => 'Zeitversatz',
			'watchTogether.syncOffsetDescription' => 'Verschiebe dein Video, wenn es dem Raum voraus ist oder hinterherhinkt.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Deine Kopie ist ${difference} als das Video im Raum.',
			'watchTogether.applyDifference' => ({required Object offset}) => '${offset} übernehmen',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Teilnehmer',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Teilnehmer', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Teilnehmer', ), 
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (du)',
			'watchTogether.playerIdle' => 'Inaktiv',
			'watchTogether.playerLoading' => 'Lädt',
			'watchTogether.playerReady' => 'Bereit',
			'watchTogether.playerBuffering' => 'Puffert',
			'watchTogether.matchSearching' => 'Sucht',
			'watchTogether.matchMatched' => 'Hat das Video',
			'watchTogether.matchMismatched' => 'Andere Länge',
			'watchTogether.matchUnavailable' => 'Hat das Video nicht',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Versatz ${offset}',
			'watchTogether.makeHost' => 'Zum Host machen',
			'watchTogether.makeHostQuestion' => 'Host übertragen?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} steuert dann die Wiedergabe und die Sitzung für alle.',
			'watchTogether.transfer' => 'Übertragen',
			'watchTogether.removeParticipant' => 'Aus dem Raum entfernen',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '${name} entfernen?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} wird aus dem Raum entfernt und kann mit dem Code erneut beitreten, sofern du den Raum nicht sperrst.',
			'watchTogether.remove' => 'Entfernen',
			'watchTogether.roomSettings' => 'Raumeinstellungen',
			'watchTogether.letEveryoneControl' => 'Alle dürfen die Wiedergabe steuern',
			'watchTogether.lockRoom' => 'Raum sperren',
			'watchTogether.lockRoomDescription' => 'Niemand Neues kann beitreten',
			'watchTogether.leaveRoom' => 'Raum verlassen',
			'watchTogether.leaveRoomQuestion' => 'Raum verlassen?',
			'watchTogether.leaveRoomConfirm' => 'Du kannst mit dem Raumcode erneut beitreten.',
			'watchTogether.leave' => 'Verlassen',
			'watchTogether.endRoom' => 'Raum beenden',
			'watchTogether.endRoomQuestion' => 'Raum beenden?',
			'watchTogether.endRoomConfirm' => 'Damit wird der Raum für alle beendet.',
			'watchTogether.end' => 'Beenden',
			'watchTogether.playBlockedTitle' => 'Wiedergabe wurde nicht gestartet',
			'watchTogether.playBlockedDescription' => 'Drücke auf Abspielen, um gemeinsam mit dem Raum zu schauen.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} hat auf Abspielen gedrückt',
			'watchTogether.notices.playbackStarted' => 'Wiedergabe gestartet',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} hat pausiert',
			'watchTogether.notices.playbackPaused' => 'Wiedergabe pausiert',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} ist zu ${position} gesprungen',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Zu ${position} gesprungen',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} hat die Geschwindigkeit auf ${speed} gesetzt',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Geschwindigkeit auf ${speed} gesetzt',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} hat ${title} gestartet',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Jetzt läuft ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} hat das Video gestoppt',
			'watchTogether.notices.mediaStopped' => 'Das Video wurde gestoppt',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Warten auf ${name} …',
			'watchTogether.notices.waitingForSomeone' => 'Warten, bis alle aufgeholt haben …',
			'watchTogether.notices.finished' => 'Beendet',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} ist jetzt der Host',
			'watchTogether.notices.youAreNowHost' => 'Du bist jetzt der Host',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} ist beigetreten',
			'watchTogether.notices.left' => ({required Object name}) => '${name} hat die Sitzung verlassen',
			'watchTogether.notices.controlRefused' => 'Nur der Host kann die Wiedergabe steuern',
			'watchTogether.notices.searchFailed' => 'Einige Server konnten nicht nach dem Video des Raums durchsucht werden',
			'watchTogether.notices.playBlocked' => 'Zum Starten auf Abspielen drücken',
			'watchTogether.notices.shareFailed' => 'Dieses Video konnte nicht mit dem Raum geteilt werden',
			'watchTogether.notices.downloadNotShared' => 'Downloads werden nicht mit dem Raum geteilt, solange ihr Server offline ist',
			'watchTogether.notices.openFailed' => 'Das Video des Raums konnte nicht geöffnet werden',
			'watchTogether.ended.ended' => 'Der Host hat den Raum beendet',
			'watchTogether.ended.kicked' => 'Du wurdest aus dem Raum entfernt',
			'watchTogether.ended.expired' => 'Der Raum ist abgelaufen',
			'watchTogether.ended.replaced' => 'Du bist diesem Raum auf einem anderen Gerät beigetreten',
			'watchTogether.ended.lost' => 'Verbindung zum Raum verloren',
			'watchTogether.errors.invalidCode' => 'Das ist kein Raumcode. Codes bestehen aus 6 Buchstaben und Ziffern, ohne 0, 1, I, L oder O.',
			'watchTogether.errors.roomNotFound' => 'Es gibt keinen Raum mit diesem Code. Möglicherweise wurde er beendet.',
			'watchTogether.errors.roomFull' => 'Dieser Raum ist voll.',
			'watchTogether.errors.roomLocked' => 'Der Host hat diesen Raum gesperrt.',
			'watchTogether.errors.relayFull' => 'Gemeinsam Schauen ist gerade ausgelastet. Versuche es später erneut.',
			'watchTogether.errors.unreachable' => 'Das Relay für Gemeinsam Schauen ist nicht erreichbar. Prüfe deine Verbindung.',
			'watchTogether.errors.rateLimited' => 'Zu viele Versuche. Warte einen Moment und versuche es erneut.',
			'watchTogether.errors.clientBlocked' => 'Diese Version von PlezyNG kann das Relay nicht verwenden. Aktualisiere die App.',
			'watchTogether.errors.forbidden' => 'Das kann nur der Host.',
			'watchTogether.errors.notInRoom' => 'Du bist in keinem Raum.',
			'watchTogether.errors.alreadyInRoom' => 'Du bist bereits in einem Raum.',
			'watchTogether.errors.resumeFailed' => 'Erneuter Beitritt zum Raum fehlgeschlagen.',
			'watchTogether.errors.unsupported' => 'Das Relay unterstützt das nicht.',
			'watchTogether.errors.generic' => 'Etwas ist schiefgelaufen. Versuche es erneut.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Folge ${number}',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Verwalten',
			'downloads.tvShows' => 'Serien',
			'downloads.movies' => 'Filme',
			'downloads.music' => 'Musik',
			'downloads.tracksQueued' => ({required Object count}) => '${count} Titel zum Download in Warteschlange',
			'downloads.noDownloads' => 'Noch keine Downloads',
			'downloads.noDownloadsDescription' => 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt',
			'downloads.downloadNow' => 'Herunterladen',
			'downloads.deleteDownload' => 'Download löschen',
			'downloads.retryDownload' => 'Download wiederholen',
			'downloads.downloadQueued' => 'Download in Warteschlange',
			'downloads.downloadResumed' => 'Download fortgesetzt',
			'downloads.serverErrorBitrate' => 'Serverfehler: Datei überschreitet möglicherweise das Remote-Bitrate-Limit',
			'downloads.storageFull' => 'Die Downloads wurden angehalten, um den freien Speicherplatz zu schützen. Gib Speicherplatz frei oder wähle einen anderen Download-Speicherort und versuche es erneut.',
			'downloads.storageUnavailable' => 'Downloads wurden angehalten, weil der verfügbare Speicherplatz nicht geprüft werden konnte. Prüfe den Download-Speicherort und versuche es erneut.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} Episoden zum Download hinzugefügt',
			'downloads.downloadDeleted' => 'Download gelöscht',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" von diesem Gerät löschen?',
			'downloads.deleteCollectionDownloads' => 'Downloads löschen',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Alle Downloads in „${title}“ von diesem Gerät löschen?',
			'downloads.collectionDownloadsDeleted' => 'Downloads gelöscht',
			'downloads.cancelledDownloadTitle' => 'Abgebrochener Download',
			'downloads.cancelledDownloadMessage' => 'Dieser Download wurde abgebrochen. Was möchtest du tun?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Alle Episoden sind bereits heruntergeladen',
			'downloads.resumeDownload' => 'Download fortsetzen',
			'downloads.cancelledDownload' => 'Abgebrochener Download',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (${status} wird synchronisiert)',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} heruntergeladen — zum Abschließen klicken',
			'downloads.partialDownloadClickToComplete' => 'Teilweise heruntergeladen — zum Abschließen klicken',
			'downloads.deleting' => 'Wird gelöscht …',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => '${title} wird gelöscht … (${current} von ${total})',
			'downloads.queuedTooltip' => 'In Warteschlange',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'In Warteschlange: ${files}',
			'downloads.downloadingTooltip' => 'Wird heruntergeladen …',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => '${files} werden heruntergeladen',
			'downloads.noDownloadsTree' => 'Keine Downloads',
			'downloads.pauseAll' => 'Alle pausieren',
			'downloads.resumeAll' => 'Alle fortsetzen',
			'downloads.retryAll' => 'Alle wiederholen',
			'downloads.retryFailed' => 'Fehlgeschlagene Downloads wiederholen',
			'downloads.deleteAll' => 'Alle löschen',
			'downloads.selectVersion' => 'Version auswählen',
			'downloads.allEpisodes' => 'Alle Episoden',
			'downloads.unwatchedOnly' => 'Nur ungesehene',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Nächste ${count} ungesehene',
			'downloads.customAmount' => 'Eigene Anzahl...',
			'downloads.customAmountAny' => 'Ein bestimmtes Betrag (ein einzelnes ...',
			'downloads.randomEpisodes' => 'Random-Episode',
			'downloads.includeSpecials' => 'Sonderfolgen einschließen',
			'downloads.howManyEpisodes' => 'Wie viele Episoden?',
			'downloads.invalidEpisodeCount' => 'Gib eine gültige Episodenanzahl ein.',
			'downloads.keepSynced' => 'Synchronisiert halten',
			'downloads.downloadOnce' => 'Einmal herunterladen',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} ungesehene behalten',
			'downloads.editSyncRule' => 'Synchronisierungsregel bearbeiten',
			'downloads.removeSyncRule' => 'Synchronisierungsregel entfernen',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Synchronisierung von „${title}“ beenden? Heruntergeladene Episoden werden behalten.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '„${title}“ nicht mehr synchronisieren?',
			'downloads.deleteSyncRuleDownloads' => 'Zugehörige Downloads ebenfalls löschen',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Downloads, die von einer anderen Synchronisierungsregel oder einem Profil verwendet werden, bleiben erhalten.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synchronisierungsregel erstellt – ${count} ungesehene Episoden werden behalten',
			'downloads.syncRuleUpdated' => 'Synchronisierungsregel aktualisiert',
			'downloads.syncRuleRemoved' => 'Synchronisierungsregel entfernt',
			'downloads.syncRuleAndDownloadsRemoved' => 'Synchronisierungsregel und zugehörige Downloads entfernt',
			'downloads.syncRuleCleanupBusy' => 'Synchronisierungsregeln werden gerade aktualisiert. Versuche es gleich noch einmal.',
			'downloads.syncRuleCleanupUnavailable' => 'Zugehörige Downloads konnten nicht sicher ermittelt werden. Verbinde den Server erneut und versuche es noch einmal, oder entferne die Regel, ohne die Downloads zu löschen.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} neue Episoden für ${title} synchronisiert',
			'downloads.syncNow' => 'Synchronisierung jetzt',
			'downloads.downloadsUpToDate' => 'Die Downloads sind bis zum aktuellen Zeitpunkt',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync vollständig · ${queued} quued, ${removed} entfernt',
			'downloads.activeSyncRules' => 'Synchronisierungsregeln',
			'downloads.reviewOrphanFiles' => 'Verwaiste Downloads prüfen',
			'downloads.orphanReviewTitle' => 'Verwaiste Downloads prüfen',
			'downloads.orphanReviewDescription' => 'Diese markierten Dateien liegen in PlezyNGs standardmäßigen, von der App verwalteten Downloadordnern. Es gibt keinen passenden Download-Eintrag und keinen aktiven Auftrag. Prüfen Sie die Liste, bevor Sie die Dateien löschen.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} Dateien · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => '${count} Dateien löschen',
			'downloads.orphanCleanupNone' => 'Keine verwaisten Download-Dateien gefunden',
			'downloads.orphanCleanupFailed' => 'PlezyNG konnte den verwalteten Downloadordner nicht sicher scannen. Es wurden keine Dateien gelöscht.',
			'downloads.orphanCleanupChanged' => 'Die Downloadliste hat sich während der Prüfung geändert. Prüfen Sie die Dateien erneut, bevor Sie aufräumen.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => '${count} verwaiste Download-Dateien gelöscht · ${size} freigegeben',
			'downloads.noSyncRules' => 'Keine Synchronisierungsregeln',
			'downloads.manageSyncRule' => 'Synchronisierung verwalten',
			'downloads.editEpisodeCount' => 'Episodenanzahl',
			'downloads.editSyncFilter' => 'Synchronisierungsfilter',
			'downloads.syncAllItems' => 'Alle Elemente synchronisieren',
			'downloads.syncUnwatchedItems' => 'Ungesehene Elemente synchronisieren',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Verfügbar',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Anmeldung erforderlich',
			'downloads.syncRuleAccessDenied' => 'Zugriff verweigert',
			'downloads.syncRuleNotAvailableForProfile' => 'Für das aktuelle Profil nicht verfügbar',
			'downloads.syncRuleUnknownServer' => 'Unbekannter Server',
			'downloads.syncRuleListCreated' => 'Synchronisierungsregel erstellt',
			'downloads.backgroundWarning.bannerBlocked' => 'Downloads werden gestoppt, wenn du die App verlässt',
			'downloads.backgroundWarning.bannerDegraded' => 'Downloads im Hintergrund sind möglicherweise eingeschränkt',
			'downloads.backgroundWarning.bannerAction' => 'Details',
			'downloads.backgroundWarning.sheetTitle' => 'Downloads im Hintergrund sind blockiert',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Downloads im Hintergrund sind möglicherweise eingeschränkt',
			'downloads.backgroundWarning.sheetIntro' => 'Android verhindert, dass PlezyNG zuverlässig im Hintergrund herunterlädt.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Dein Gerät schränkt ein, wann PlezyNG im Hintergrund herunterladen kann.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Die Hintergrundnutzung von PlezyNG ist eingeschränkt. Stelle die Akku- oder Hintergrundnutzung auf „Uneingeschränkt“.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android hat PlezyNG in einen eingeschränkten Standby-Modus versetzt. Stelle die Akkunutzung auf „Uneingeschränkt“.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Download-Benachrichtigungen sind deaktiviert. Fortschritt und Steuerelemente sind daher möglicherweise nicht verfügbar.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Benachrichtigungen sind deaktiviert. Ab Android 13 sind sie für lange Downloads im Hintergrund erforderlich.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Der Datensparmodus ist aktiviert und blockiert Downloads im Hintergrund über mobile Daten. Über Wi-Fi sollten Downloads weiterhin funktionieren.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Downloads wurden wiederholt gestoppt, während PlezyNG im Hintergrund war. Prüfe die Einstellungen zur Akku- oder Hintergrundnutzung von PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Einstellungen öffnen',
			'downloads.backgroundWarning.stillNotWorking' => 'Gerätespezifische Hilfe',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Sieh dir die Schritte für dein Gerät an oder sende bei anhaltendem Problem ein Protokoll über Einstellungen › Protokolle anzeigen.',
			'downloads.backgroundWarning.dialogTitle' => 'Downloads werden möglicherweise nicht abgeschlossen',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Trotzdem herunterladen',
			'downloads.backgroundWarning.dialogFixFirst' => 'Zuerst beheben',
			'downloads.backgroundWarning.statusTile' => 'Downloads im Hintergrund',
			'downloads.backgroundWarning.statusOk' => 'Ausführung im Hintergrund erlaubt',
			'downloads.backgroundWarning.statusBlocked' => 'Durch Systemeinstellungen blockiert',
			'downloads.backgroundWarning.statusDegraded' => 'Durch Systemeinstellungen eingeschränkt',
			'downloads.backgroundWarning.statusUnknown' => 'Noch nicht geprüft',
			'downloads.backgroundWarning.settingsUnavailable' => 'Die Systemeinstellungen konnten auf diesem Gerät nicht geöffnet werden',
			'downloads.backgroundWarning.linkUnavailable' => 'dontkillmyapp.com konnte auf diesem Gerät nicht geöffnet werden',
			'downloads.options' => 'Download-Optionen',
			'downloads.groupings.library' => 'Mediathek',
			'downloads.groupings.collections' => 'Sammlungen',
			'downloads.unknownLibrary' => 'Unbekannte Mediathek',
			'downloads.unknownShow' => 'Unbekannte Serie',
			'downloads.unknownSeason' => 'Unbekannte Staffel',
			'downloads.unknownAlbum' => 'Unbekanntes Album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} abgeschlossen',
			'downloads.storageUsed' => ({required Object size}) => 'Speicher verwendet: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Download', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Downloads', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ausstellung', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Ausstellungen', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Film', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Filme', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Album', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Alben', ), 
			'downloads.errorFileNotFound' => 'Datei nicht gefunden (404)',
			'downloads.errorDownloadNotAllowed' => 'Download vom Server nicht erlaubt (403)',
			'downloads.errorDownloadFailed' => 'Download fehlgeschlagen',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Download fehlgeschlagen: ${reason}',
			'downloads.convertingOnServer' => 'Umwandeln auf den Server...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Konvertierung auf Server · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Download fehlgeschlagen (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Nachbearbeitung fehlgeschlagen: ${reason}',
			'downloads.reasonFileNotSaved' => 'die Datei konnte auf diesem Gerät nicht gespeichert werden',
			'downloads.reasonCannotResume' => 'der unvollständige Download konnte nicht fortgesetzt werden',
			'downloads.reasonDeviceStorageFull' => 'auf diesem Gerät ist kein Speicherplatz mehr frei',
			'downloads.notificationDownloading' => 'Wird heruntergeladen …',
			'downloads.notificationComplete' => 'Download abgeschlossen',
			'downloads.notificationPaused' => 'Download pausiert',
			'shaders.title' => 'Shader',
			'shaders.noShaderDescription' => 'Keine Videoverbesserung',
			'shaders.nvscalerDescription' => 'NVIDIA-Bildskalierung für schärferes Video',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Rauschreduzierung',
			'shaders.artcnnVariantDenoiseSharpen' => 'Rauschreduzierung + Schärfen',
			'shaders.qualityFast' => 'Schnell',
			'shaders.qualityHQ' => 'Hohe Qualität',
			'shaders.mode' => 'Modus',
			'shaders.importShader' => 'Shader importieren',
			'shaders.customShaderDescription' => 'Benutzerdefinierter GLSL-Shader',
			'shaders.shaderImported' => 'Shader importiert',
			'shaders.shaderImportFailed' => 'Shader konnte nicht importiert werden',
			'shaders.deleteShader' => 'Shader löschen',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '"${name}" löschen?',
			'companionRemote.title' => 'Companion-Fernbedienung',
			'companionRemote.connectedTo' => ({required Object name}) => 'Verbunden mit ${name}',
			'companionRemote.unknownDevice' => 'Unbekanntes Gerät',
			'companionRemote.session.startingServer' => 'Remote-Server wird gestartet...',
			'companionRemote.session.hostAddress' => 'Host-Adresse',
			'companionRemote.session.connected' => 'Verbunden',
			'companionRemote.session.serverRunning' => 'Remote-Server aktiv',
			'companionRemote.session.serverStopped' => 'Remote-Server gestoppt',
			'companionRemote.session.serverRunningDescription' => 'Mobilgeräte in deinem Netzwerk können sich mit dieser App verbinden',
			'companionRemote.session.serverStoppedDescription' => 'Starte den Server, um Mobilgeräten die Verbindung zu ermöglichen',
			'companionRemote.session.usePhoneToControl' => 'Verwende dein Mobilgerät, um diese App zu steuern',
			'companionRemote.session.startServer' => 'Server starten',
			'companionRemote.session.stopServer' => 'Server stoppen',
			'companionRemote.session.minimize' => 'Minimieren',
			'companionRemote.session.manualAddressHint' => 'Manuelle Verbindungsadresse:',
			'companionRemote.pairing.discoveryDescription' => 'PlezyNG-Geräte mit demselben Plex-Konto erscheinen hier',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Verbinden...',
			'companionRemote.pairing.searchingForDevices' => 'Suche nach Geräten...',
			'companionRemote.pairing.noDevicesFound' => 'Keine Geräte in deinem Netzwerk gefunden',
			'companionRemote.pairing.noDevicesHint' => 'Öffne PlezyNG auf dem Desktop und nutze dasselbe WLAN',
			'companionRemote.pairing.availableDevices' => 'Verfügbare Geräte',
			'companionRemote.pairing.manualConnection' => 'Manuelle Verbindung',
			'companionRemote.pairing.cryptoInitFailed' => 'Sichere Verbindung konnte nicht gestartet werden. Melde dich zuerst bei Plex an.',
			'companionRemote.pairing.validationHostRequired' => 'Bitte Host-Adresse eingeben',
			'companionRemote.pairing.validationHostFormat' => 'Format muss IP:Port sein (z. B. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Zeitüberschreitung bei der Verbindung. Nutze auf beiden Geräten dasselbe Netzwerk.',
			'companionRemote.pairing.sessionNotFound' => 'Gerät nicht gefunden. Stelle sicher, dass PlezyNG auf dem Host läuft.',
			'companionRemote.pairing.authFailed' => 'Authentifizierung fehlgeschlagen. Beide Geräte benötigen dasselbe Plex-Konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Verbindung fehlgeschlagen: ${error}',
			'companionRemote.pairing.codeTitle' => 'Paar Code',
			'companionRemote.pairing.codeDescription' => 'Geben Sie den Code in Companion Remote auf dem Host-Gerät ein. Beide Geräte müssen eine Version verwenden, die sichere Paarung unterstützt.',
			'companionRemote.pairing.codeInvalid' => 'Geben Sie alle 32 Buchstaben und Zahlen aus dem Hostcode ein.',
			'companionRemote.pairing.updateRequired' => 'Beide Geräte aktualisieren auf eine Version, die sichere Paarung unterstützt.',
			'companionRemote.pairing.hostDescription' => 'Geben Sie diesen Code einmal auf jedem Fernseher ein. Halten Sie ihn privat: es gibt Kontrolle über diesen Profil.',
			'companionRemote.pairing.resetCode' => 'Pairing Code wiederherstellen',
			'companionRemote.pairing.resetDescription' => 'Entfernen Sie alle Entfernungsteile und erstellen Sie einen neuen Code. Jeder Entfernung muss wieder Paar.',
			'companionRemote.remote.disconnectConfirm' => 'Möchtest du die Verbindung zur Fernsteuerungssitzung trennen?',
			'companionRemote.remote.reconnecting' => 'Verbindung wird wiederhergestellt...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Versuch ${current} von 5',
			'companionRemote.remote.retryNow' => 'Jetzt wiederholen',
			'companionRemote.remote.tabRemote' => 'Fernbedienung',
			'companionRemote.remote.tabPlay' => 'Wiedergabe',
			'companionRemote.remote.tabMore' => 'Mehr',
			'companionRemote.remote.menu' => 'Menü',
			'companionRemote.remote.tabNavigation' => 'Tab-Navigation',
			'companionRemote.remote.tabDiscover' => 'Entdecken',
			'companionRemote.remote.tabLibraries' => 'Mediatheken',
			'companionRemote.remote.tabSearch' => 'Suche',
			'companionRemote.remote.tabDownloads' => 'Downloads',
			'companionRemote.remote.tabSettings' => 'Einstellungen',
			'companionRemote.remote.previous' => 'Zurück',
			'companionRemote.remote.playPause' => 'Wiedergabe/Pause',
			'companionRemote.remote.next' => 'Weiter',
			'companionRemote.remote.seekBack' => 'Zurückspulen',
			'companionRemote.remote.stop' => 'Stopp',
			'companionRemote.remote.seekForward' => 'Vorspulen',
			'companionRemote.remote.volume' => 'Lautstärke',
			'companionRemote.remote.volumeDown' => 'Leiser',
			'companionRemote.remote.volumeUp' => 'Lauter',
			'companionRemote.remote.fullscreen' => 'Vollbild',
			'companionRemote.remote.subtitles' => 'Untertitel',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Auf dem Desktop suchen …',
			'companionRemote.errors.noNetworkInterface' => 'Keine Netzwerkschnittstelle gefunden',
			'companionRemote.errors.authenticationFailed' => 'Authentifizierung fehlgeschlagen',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Remote-Server konnte nicht gestartet werden: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Remote-Befehl konnte nicht gesendet werden: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Zeitüberschreitung beim Beitreten zur Sitzung',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Keine Verbindung zu einer Adresse möglich',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Verbindung nach ${attempts} Versuchen verloren',
			'companionRemote.errors.connectionLost' => 'Verbindung verloren',
			'companionRemote.closedBeforeAuth' => 'Die Verbindung wurde vor der Authentifizierung geschlossen',
			'videoSettings.playbackSpeed' => 'Wiedergabegeschwindigkeit',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktiv (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Schlaftimer',
			'videoSettings.audioSync' => 'Audio-Synchronisation',
			'videoSettings.subtitleSync' => 'Untertitel-Synchronisation',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR ist hier nicht verfügbar – dieser Desktop-Compositor oder Videoausgang kann es nicht übertragen.',
			'videoSettings.hdrToneMapping' => 'HDR-Tone-Mapping',
			'videoSettings.hdrToneMappingCompositor' => 'Compositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Die HDR-Metadaten der Quelle durchreichen und vom Desktop-Compositor anpassen lassen.',
			'videoSettings.hdrToneMappingPlayer' => 'Player',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Im Player an die maximale Helligkeit des Displays anpassen und das Ergebnis anschließend an den Compositor melden.',
			'videoSettings.hdrToneMappingFailed' => 'Das HDR-Tone-Mapping konnte nicht geändert werden – der vorherige Modus ist weiterhin aktiv.',
			'videoSettings.audioOutput' => 'Audioausgabe',
			'videoSettings.performanceOverlay' => 'Leistungsanzeige',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Räumliches Audio',
			'videoSettings.audioOutputStereo' => 'Stereo',
			'videoSettings.audioEqualizer' => 'Audio-Equalizer',
			'videoSettings.audioEqualizerDescription' => '10-Band Equalizer für MPV. Audiofilter verwenden dekodierte Audio und deaktivieren passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Neutral',
			'videoSettings.audioEqualizerActive' => 'Benutzerdefiniert',
			'videoSettings.audioEqualizerSaveFailed' => 'Es könnte keine Audio-Equalizer-Einstellungen speichern.',
			'videoSettings.backgroundVideoAudio' => 'Hintergrund Video Audio',
			'videoSettings.backgroundVideoAudioDescription' => 'Halten Sie das Video-Audio-Play, wenn Sie den Player verlassen; das Bild wird verborgen, bis Sie zurückkehren. Android verwendet eine Medien-Playback-Nachricht.',
			'videoSettings.audioNormalization' => 'Lautstärke normalisieren',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Dekodiert Audio zu PCM; Durchleitung ist aus, solange dies aktiv ist',
			'videoSettings.audioEffectsDescription' => 'Effekte verwenden verschlüsselt Audio, so passthrough dreht sich ab. Raumumgebung und Stereo-Erweiterung hängt von der MPV Bau und Track.',
			'videoSettings.audioStereoWidth' => 'Stereo Erweiterung',
			'videoSettings.audioSpatializer' => 'Raum Umgebung',
			'videoSettings.audioSpatializerDescription' => 'Hinzufügen Sie ruhige Raum Reflektionen.',
			'videoSettings.audioPitch' => 'Pitch wechseln',
			'videoSettings.audioPitchDescription' => 'Veränderung des Plats, ohne die Geschwindigkeit zu ändern. MPV Bau muss einschließen Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'Dieser Effekt ist für diesen Track nicht verfügbar oder MPV aufbauen .',
			'performanceOverlay.color' => 'Farbe',
			'performanceOverlay.performance' => 'Leistung',
			'performanceOverlay.buffer' => 'Puffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decoder',
			'performanceOverlay.rawDecoder' => 'Raw-Decoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.passthrough' => 'Durchleitung',
			'performanceOverlay.aspect' => 'Seitenverhältnis',
			'performanceOverlay.rotation' => 'Drehung',
			'performanceOverlay.dvSource' => 'DV-Quelle',
			'performanceOverlay.dvPath' => 'DV-Pfad',
			'performanceOverlay.dvRouteDecoder' => 'Dolby-Vision-Decoder',
			'performanceOverlay.dvRouteDecoderP81' => 'Dolby-Vision-Decoder (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Basisschicht',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'HDR10-Basisschicht',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'HLG-Basisschicht',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'SDR-Basisschicht',
			'performanceOverlay.dvRouteReshaped' => 'RPU-Reshaping (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'Experimenteller P7 FEL-Grafik (unqualifiziert)',
			'performanceOverlay.p7Conversion' => 'P7-Konv.',
			'performanceOverlay.sampleRate' => 'Abtastrate',
			'performanceOverlay.pixelFormat' => 'Pixelformat',
			'performanceOverlay.hwFormat' => 'HW-Format',
			'performanceOverlay.matrix' => 'Matrix',
			'performanceOverlay.primaries' => 'Primärfarben',
			'performanceOverlay.transfer' => 'Transfer',
			'performanceOverlay.renderFps' => 'Render-FPS',
			'performanceOverlay.displayFps' => 'Display-FPS',
			'performanceOverlay.avSync' => 'A/V-Sync',
			'performanceOverlay.dropped' => 'Verworfen',
			'performanceOverlay.dvRpus' => 'DV-RPUs',
			'performanceOverlay.dvRpuAverage' => 'DV-RPU Ø',
			'performanceOverlay.dvSampleAverage' => 'DV-Sample Ø',
			'performanceOverlay.maxLuma' => 'Max. Luma',
			'performanceOverlay.minLuma' => 'Min. Luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache genutzt',
			'performanceOverlay.cacheLimit' => 'Cache-Limit',
			'performanceOverlay.speed' => 'Geschwindigkeit',
			'performanceOverlay.player' => 'Player',
			'performanceOverlay.playMethod' => 'Spielen Methode',
			'performanceOverlay.memory' => 'Speicher',
			'performanceOverlay.uiFps' => 'UI-FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Aktiv',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} fehlgeschlagen)',
			'externalPlayer.title' => 'Externer Player',
			'externalPlayer.useExternalPlayer' => 'Externen Player verwenden',
			'externalPlayer.useExternalPlayerDescription' => 'Videos in einer anderen App öffnen',
			'externalPlayer.selectPlayer' => 'Player auswählen',
			'externalPlayer.customPlayers' => 'Benutzerdefinierte Player',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Benutzerdefinierten Player hinzufügen',
			'externalPlayer.playerName' => 'Playername',
			'externalPlayer.playerNameHint' => 'Mein Player',
			'externalPlayer.playerCommand' => 'Befehl',
			'externalPlayer.playerPackage' => 'Paketname',
			'externalPlayer.playerUrlScheme' => 'URL-Schema',
			'externalPlayer.off' => 'Aus',
			'externalPlayer.launchFailed' => 'Externer Player konnte nicht geöffnet werden',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} ist nicht installiert',
			'externalPlayer.playInExternalPlayer' => 'In externem Player abspielen',
			'externalPlayer.description' => 'Wählen Sie eine andere App, um Videos zu öffnen. Verfügbare Spieler hängen von Ihrem Gerät und installierten Apps ab.',
			'externalPlayer.systemDefaultDescription' => 'Lassen Sie das Betriebssystem das Video mit seiner Standard-App öffnen.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Öffnen Sie Videos mit ${player}.',
			'externalPlayer.playerNameDescription' => 'Das Etikett, das in der Spielerliste angezeigt wird.',
			'externalPlayer.playerPackageDescription' => 'Geben Sie den Android-Paketnamen der Player-App ein, wie zum Beispiel com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Geben Sie die installierte Spielerkommando oder die Ausführbare Path für dieses Gerät ein.',
			'externalPlayer.playerUrlSchemeDescription' => 'Geben Sie das URL-Schema und die optionale URL-Template ein, die zum Start des Spielers verwendet wird.',
			'metadataEdit.editMetadata' => 'Bearbeiten...',
			'metadataEdit.screenTitle' => 'Metadaten bearbeiten',
			'metadataEdit.basicInfo' => 'Grundinformationen',
			'metadataEdit.artwork' => 'Grafiken',
			'metadataEdit.advancedSettings' => 'Erweiterte Einstellungen',
			'metadataEdit.title' => 'Titel',
			'metadataEdit.sortTitle' => 'Sortiertitel',
			'metadataEdit.originalTitle' => 'Originaltitel',
			'metadataEdit.releaseDate' => 'Erscheinungsdatum',
			'metadataEdit.contentRating' => 'Altersfreigabe',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Zusammenfassung',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Hintergrund',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Quadratisches Bild',
			'metadataEdit.selectPoster' => 'Poster auswählen',
			'metadataEdit.selectBackground' => 'Hintergrund auswählen',
			'metadataEdit.selectLogo' => 'Logo auswählen',
			'metadataEdit.selectSquareArt' => 'Quadratisches Bild auswählen',
			'metadataEdit.fromUrl' => 'Über URL',
			'metadataEdit.uploadFile' => 'Datei hochladen',
			'metadataEdit.enterImageUrl' => 'Bild-URL eingeben',
			'metadataEdit.imageUrl' => 'Bild-URL',
			'metadataEdit.metadataUpdated' => 'Metadaten aktualisiert',
			'metadataEdit.metadataUpdateFailed' => 'Metadaten konnten nicht aktualisiert werden',
			'metadataEdit.artworkUpdated' => 'Grafiken aktualisiert',
			'metadataEdit.artworkUpdateFailed' => 'Grafiken konnten nicht aktualisiert werden',
			'metadataEdit.noArtworkAvailable' => 'Keine Grafiken verfügbar',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Grafikoption ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Grafikoption ${index}, ausgewählt',
			'metadataEdit.notSet' => 'Nicht festgelegt',
			'metadataEdit.libraryDefault' => 'Mediatheksstandard',
			'metadataEdit.accountDefault' => 'Kontostandard',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.seriesDefault' => 'Serienstandard',
			'metadataEdit.episodeSorting' => 'Episodensortierung',
			'metadataEdit.oldestFirst' => 'Älteste zuerst',
			'metadataEdit.newestFirst' => 'Neueste zuerst',
			'metadataEdit.keep' => 'Behalten',
			'metadataEdit.allEpisodes' => 'Alle Episoden',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} neueste Episoden',
			'metadataEdit.latestEpisode' => 'Neueste Episode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episoden der letzten ${count} Tage',
			'metadataEdit.deleteAfterPlaying' => 'Episoden nach Wiedergabe löschen',
			'metadataEdit.never' => 'Nie',
			'metadataEdit.afterADay' => 'Nach einem Tag',
			'metadataEdit.afterAWeek' => 'Nach einer Woche',
			'metadataEdit.afterAMonth' => 'Nach einem Monat',
			'metadataEdit.onNextRefresh' => 'Bei nächster Aktualisierung',
			'metadataEdit.seasons' => 'Staffeln',
			'metadataEdit.show' => 'Anzeigen',
			'metadataEdit.hide' => 'Ausblenden',
			'metadataEdit.episodeOrdering' => 'Episodenreihenfolge',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Ausstrahlung)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Ausstrahlung)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (absolut)',
			'metadataEdit.metadataLanguage' => 'Metadaten-Sprache',
			'metadataEdit.useOriginalTitle' => 'Originaltitel verwenden',
			'metadataEdit.preferredAudioLanguage' => 'Bevorzugte Audiosprache',
			'metadataEdit.preferredSubtitleLanguage' => 'Bevorzugte Untertitelsprache',
			'metadataEdit.subtitleMode' => 'Automatische Untertitelauswahl',
			'metadataEdit.manuallySelected' => 'Manuell ausgewählt',
			'metadataEdit.shownWithForeignAudio' => 'Bei fremdsprachigem Audio anzeigen',
			'metadataEdit.alwaysEnabled' => 'Immer aktiviert',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Tag hinzufügen',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Regisseur',
			'metadataEdit.writer' => 'Autor',
			'metadataEdit.producer' => 'Produzent',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Sammlung',
			'metadataEdit.label' => 'Label',
			'metadataEdit.quickTag' => 'Schnell-Tag...',
			'matchScreen.match' => 'Zuordnen...',
			'matchScreen.fixMatch' => 'Zuordnung korrigieren...',
			'matchScreen.unmatch' => 'Zuordnung aufheben',
			'matchScreen.unmatchConfirm' => 'Diese Zuordnung löschen? Plex behandelt sie als nicht zugeordnet, bis sie neu zugeordnet wird.',
			'matchScreen.unmatchSuccess' => 'Zuordnung aufgehoben',
			'matchScreen.unmatchFailed' => 'Zuordnung konnte nicht aufgehoben werden',
			'matchScreen.matchApplied' => 'Zuordnung angewendet',
			'matchScreen.matchFailed' => 'Zuordnung konnte nicht angewendet werden',
			'matchScreen.titleHint' => 'Titel',
			'matchScreen.yearHint' => 'Jahr',
			'matchScreen.search' => 'Suchen',
			'matchScreen.noMatchesFound' => 'Keine Treffer gefunden',
			'serverTasks.title' => 'Serveraufgaben',
			'serverTasks.failedToLoad' => 'Aufgaben konnten nicht geladen werden',
			'serverTasks.noTasks' => 'Keine laufenden Aufgaben',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Verbunden',
			'trakt.connectedAs' => ({required Object username}) => 'Verbunden als @${username}',
			'trakt.disconnectConfirm' => 'Trakt-Konto trennen?',
			'trakt.disconnectConfirmBody' => 'PlezyNG sendet keine Ereignisse mehr an Trakt. Du kannst jederzeit erneut verbinden.',
			'trakt.scrobble' => 'Echtzeit-Scrobbling',
			'trakt.scrobbleDescription' => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.',
			'trakt.watchedSync' => 'Gesehen-Status synchronisieren',
			'trakt.watchedSyncDescription' => 'Wenn du Inhalte in PlezyNG als gesehen markierst, werden sie auch auf Trakt markiert.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr verbinden',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Die Adresse deiner Seerr-Instanz',
			'seerr.checkServer' => 'Weiter',
			'seerr.signInWithJellyfin' => 'Mit Jellyfin anmelden',
			'seerr.signInWithEmby' => 'Mit Emby anmelden',
			'seerr.signInWithLocal' => 'Lokales Konto verwenden',
			'seerr.email' => 'E-Mail',
			'seerr.noSignInMethods' => 'Diese Seerr-Instanz bietet keine von PlezyNG unterstützte Anmeldemethode.',
			'seerr.instance' => 'Instanz',
			'seerr.disconnectConfirm' => 'Seerr trennen?',
			'seerr.disconnectConfirmBody' => 'PlezyNG vergisst diese Seerr-Instanz. Jederzeit erneut verbinden.',
			'seerr.request' => 'Anfragen',
			'seerr.request4k' => 'In 4K anfragen',
			'seerr.seasons' => 'Staffeln',
			'seerr.allSeasons' => 'Alle Staffeln',
			'seerr.advancedOptions' => 'Erweitert',
			'seerr.destinationServer' => 'Zielserver',
			'seerr.qualityProfile' => 'Qualitätsprofil',
			'seerr.rootFolder' => 'Stammordner',
			'seerr.languageProfile' => 'Sprachprofil',
			'seerr.tags' => 'Tags',
			'seerr.noTags' => 'Keine Tags',
			'seerr.defaultOption' => ({required Object name}) => '${name} (Standard)',
			'seerr.animeNote' => 'Diese Serie ist ein Anime.',
			'seerr.requestSubmitted' => 'Anfrage gesendet',
			'seerr.requestFailed' => ({required Object error}) => 'Anfrage fehlgeschlagen: ${error}',
			'seerr.requestsLoadFailed' => 'Anfrageoptionen konnten nicht geladen werden',
			'seerr.nothingToRequest' => 'Alles ist bereits verfügbar oder angefragt.',
			'seerr.statusAvailable' => 'Verfügbar',
			'seerr.statusPartiallyAvailable' => 'Teilweise verfügbar',
			'seerr.statusRequested' => 'Angefragt',
			'seerr.statusProcessing' => 'Wird verarbeitet',
			'seerr.statusBlocklisted' => 'Auf der Sperrliste',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => '${url} nicht erreichbar: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Keine Seerr-Instanz unter ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Ein authentifizierender Reverse-Proxy (SSO oder HTTP-Auth) hat anstelle von Seerr geantwortet. PlezyNG kann sich nicht dadurch anmelden: Lass den Pfad /api/v1 von Seerr den Proxy für diese App umgehen, oder verwende eine Adresse, die Seerr direkt erreicht.',
			'seerr.invalidUrl' => 'Gib eine Serveradresse ein, z. B. https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Diese Seerr-Instanz unterstützt Quick Connect nicht. Dafür ist Seerr 3.4 oder neuer erforderlich.',
			'seerr.notInitialized' => 'Die Ersteinrichtung dieser Seerr-Instanz wurde noch nicht abgeschlossen',
			'seerr.noPlexTokenForReauth' => 'Für die erneute Anmeldung ist kein Plex-Token verfügbar',
			'seerr.noStoredCredentials' => 'Für die erneute Anmeldung sind keine gespeicherten Anmeldedaten verfügbar',
			'seerr.signInRejected' => 'Die Anmeldung wurde abgelehnt',
			'seerr.noSessionCookie' => 'Seerr hat kein Sitzungscookie ausgestellt',
			'seerr.freshCookieRejected' => 'Seerr hat das neue Sitzungscookie abgelehnt',
			'seerr.noUserInformation' => 'Seerr hat keine Benutzerinformationen zurückgegeben',
			'seerr.sessionRejectedAfterReauth' => 'Die Sitzung wurde nach der erneuten Anmeldung abgelehnt',
			'seerr.permissionDenied' => 'Seerr hat diese Aktion abgelehnt: Dein Konto hat nicht mehr die erforderliche Berechtigung',
			'seerr.permissionRevoked' => 'Du hast keine Berechtigung mehr, dies anzufragen',
			'services.title' => 'Dienste',
			'services.hubSubtitle' => 'Wiedergabefortschritt synchronisieren und neue Titel anfragen.',
			'services.integrations' => 'Integrationen',
			'services.notConnected' => 'Nicht verbunden',
			'services.connectedAs' => ({required Object username}) => 'Verbunden als @${username}',
			'services.scrobble' => 'Fortschritt automatisch verfolgen',
			'services.scrobbleDescription' => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} trennen?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG aktualisiert ${service} nicht mehr. Jederzeit erneut verbinden.',
			'services.connectFailed' => ({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Simkl erneut verbinden',
			'services.simklReconnect.subtitle' => 'Simkl stellt die Anmeldemethode ein, die diese Verbindung nutzt. Beim erneuten Verbinden wird simkl.com geöffnet, um PlezyNG zu autorisieren – PlezyNG sieht dein Passwort nie. Dein Wiedergabeverlauf bleibt bei Simkl erhalten.',
			'services.deviceCode.title' => ({required Object service}) => 'PlezyNG auf ${service} aktivieren',
			'services.deviceCode.instructions' => 'Scanne den QR-Code oder rufe die unten angegebene Adresse auf und gib diesen Code ein:',
			'services.deviceCode.openToActivate' => ({required Object service}) => '${service} zum Aktivieren öffnen',
			'services.deviceCode.copyCode' => 'Aktivierungscode kopieren',
			'services.deviceCode.waitingForAuthorization' => 'Warte auf Autorisierung…',
			'services.deviceCode.codeCopied' => 'Code kopiert',
			'services.oauthProxy.title' => ({required Object service}) => 'Bei ${service} anmelden',
			'services.oauthProxy.body' => 'Scanne diesen QR-Code oder öffne die URL auf einem beliebigen Gerät.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => '${service} zum Anmelden öffnen',
			'services.pendingAuth.copyUrl' => 'Anmelde-URL kopieren',
			'services.pendingAuth.urlCopied' => 'URL kopiert',
			'services.libraryFilter.title' => 'Mediatheksfilter',
			'services.libraryFilter.subtitleAllSyncing' => 'Alle Mediatheken werden synchronisiert',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nichts wird synchronisiert',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} ausgeschlossen',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} zugelassen',
			'services.libraryFilter.mode' => 'Filtermodus',
			'services.libraryFilter.modeBlacklist' => 'Ausschlussliste',
			'services.libraryFilter.modeWhitelist' => 'Zulassungsliste',
			'services.libraryFilter.modeHintBlacklist' => 'Alle Mediatheken außer den unten markierten synchronisieren.',
			'services.libraryFilter.modeHintWhitelist' => 'Nur die unten markierten Mediatheken synchronisieren.',
			'services.libraryFilter.libraries' => 'Mediatheken',
			'services.libraryFilter.noLibraries' => 'Keine Mediatheken verfügbar',
			'services.libraryFilter.modeDescription' => 'Wählen Sie aus, ob die überprüften Bibliotheken von Synchronisierung blockiert sind oder die einzigen Bibliothek ist, die synchroniziert.',
			'services.seerrDescription' => 'Verbinden Sie sich mit Seerr oder Overseerr, um Titel zu suchen und Medienanfragen vorzulegen.',
			'services.trackerDescriptions.trakt' => 'Synchronisieren Sie aufgezeichnete Episoden und Filme mit Ihrem Trakt-Konto.',
			'services.trackerDescriptions.mal' => 'Synchronisieren Sie anime-Listen und beobachten Sie den Fortschritt mit MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Synchronisieren Sie anime-Listen und beobachten Sie den Fortschritt mit AniList.',
			'services.trackerDescriptions.simkl' => 'Sync sah Filme, TV-Shows und Anime mit Simkl.',
			'services.trackerDescriptions.mdblist' => 'Zeigen Sie MDBList Bewertungen und Listen in Empfehlungen und Entdecken.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => '${product}-Server hinzufügen',
			'addServer.serverUrls' => 'Server-URLs',
			'addServer.serverUrlsHelper' => 'Mehrere URLs möglich, durch Kommas getrennt.',
			'addServer.findServer' => 'Server finden',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Suche nach lokalen ${product}-Servern …',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Lokale ${product}-Server',
			'addServer.username' => 'Benutzername',
			'addServer.password' => 'Passwort',
			'addServer.signIn' => 'Anmelden',
			'addServer.change' => 'Ändern',
			'addServer.required' => 'Erforderlich',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Server nicht erreichbar: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Anmeldung fehlgeschlagen: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect fehlgeschlagen: ${error}',
			'addServer.addPlexTitle' => 'Mit Plex anmelden',
			'addServer.pinExpired' => 'PIN ist vor der Anmeldung abgelaufen. Bitte erneut versuchen.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Konto konnte nicht registriert werden: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Gib die URL deines ${product}-Servers ein',
			'addServer.addConnectionTitle' => 'Verbindung hinzufügen',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Zu ${name} hinzufügen',
			'addServer.signInWithPlexCard' => 'Mit Plex anmelden',
			'addServer.signInWithPlexCardSubtitle' => 'Dieses Gerät autorisieren. Geteilte Server werden hinzugefügt.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Ein Plex-Konto autorisieren. Home-Benutzer werden zu Profilen.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Mit ${product} verbinden',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Gib Server-URL, Benutzername und Passwort ein.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Melde dich bei deinem ${product}-Server an. Wird mit ${name} verknüpft.',
			'addServer.borrowFromAnotherProfile' => 'Von einem anderen Profil ausleihen',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Verbindung eines anderen Profils wiederverwenden. PIN-geschützte Profile erfordern eine PIN.',
			'addServer.invalidCredentials' => 'Ungültiger Benutzername oder ungültiges Passwort',
			'addServer.authResponseNotJson' => 'Die Authentifizierungsantwort war kein gültiges JSON',
			'addServer.authResponseIncomplete' => 'Die Anmeldeantwort des Servers war unvollständig',
			'addServer.quickConnectRejected' => 'Quick Connect wurde vom Server abgelehnt',
			'addServer.quickConnectNotJson' => 'Die Quick Connect-Antwort war kein gültiges JSON',
			'addServer.quickConnectMissingFields' => 'In der Quick Connect-Antwort fehlt ein Code oder Geheimnis',
			'addServer.quickConnectPollRejected' => 'Die Quick Connect-Abfrage wurde vom Server abgelehnt',
			'addServer.serverTimedOut' => 'Der Server hat nicht rechtzeitig geantwortet',
			'addServer.responseNotJson' => 'Die Serverantwort war kein gültiges JSON',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'In der Antwort fehlt eine ID oder ein Servername – ist dies ein ${product}-Server?',
			'addServer.probeFailed' => ({required Object error}) => 'Server nicht erreichbar: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Gib mindestens eine URL eines ${product}-Servers ein',
			'addServer.noReachableServer' => ({required Object product}) => 'Es wurde kein erreichbarer ${product}-Server gefunden',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Diese URLs verweisen auf verschiedene ${product}-Server',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Diese URL gehört nicht zum ${product}-Server',
			'addServer.redirectUnsupported' => 'Der Server hat zu einer nicht unterstützten URL weitergeleitet',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'Der Server hat zu einem anderen Host weitergeleitet. Gib die endgültige ${product}-URL direkt ein.',
			'addServer.redirectInsecure' => 'Der Server hat von HTTPS zu einer unsicheren URL weitergeleitet',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'Der Server hat zu einer nicht unterstützten URL weitergeleitet. Gib die endgültige ${product}-URL direkt ein.',
			'addServer.directPlexServerUrl' => 'Plex-Server-URL',
			'addServer.directPlexServerUrlHelper' => 'Geben Sie die lokale IP und Port Ihres Plex Media Server ein.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (optional)',
			'addServer.plexTokenHelper' => 'Lassen Sie es leer, wenn Zugriff ohne Auth auf diesem Server erlaubt ist.',
			'addServer.plexTokenRequired' => 'Bitte geben Sie Ihren Token Plex (X-Plex-Token) ein.',
			'addServer.connectDirectPlexCard' => 'Plex Media Server (Direkt / Lokal)',
			'addServer.connectDirectPlexCardSubtitle' => 'Verbindet Sie sich direkt mit lokaler IP oder URL ohne Plex.tv-Konto.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Verbindet Sie direkt mit lokaler IP oder URL. Verbindet Sie zu ${name}.',
			'addServer.insecureTitle' => 'Unschlüsselte Verbindung',
			'addServer.insecureDescription' => ({required Object url}) => '${url} verwendet HTTP. Personen im Netzwerk können dein Passwort, deine Tokens und deine Medien lesen oder verändern. Verwende nach Möglichkeit HTTPS. Fahre nur fort, wenn du diesem Netzwerk vertraust und das Risiko akzeptierst.',
			'addServer.allowHttp' => 'HTTP erlauben',
			'addServer.httpsRequired' => 'Verwenden Sie HTTPS oder erlauben Sie ausdrücklich eine unschlüsselte Verbindung.',
			'cast.chooseDevice' => 'Kasten auf ein Gerät',
			'cast.searching' => 'Suche nach Kastengeräten...',
			'cast.connectedTo' => ({required Object device}) => 'Anschluss an ${device}',
			'cast.device' => 'Cast Gerät',
			'cast.readyToCast' => 'Bereit zum Ausführen',
			'cast.subtitle' => 'Untertitel',
			'cast.serverNotAvailable' => 'Der Media-Server ist nicht verfügbar.',
			'cast.stopCasting' => 'Stoppen Sie Casting',
			'cast.castToDevice' => 'Kasten auf Gerät',
			'cast.noEpisodeAvailable' => 'Es gibt keine Episoden zur Verfügung, um zu zählen.',
			'cast.startFailed' => 'Kann nicht starten, die Kasten. prüfen Sie den Server und versuchen Sie es wieder.',
			'automation.noActivePlayback' => 'Es gibt keine aktive Video-Sitzung zu kontrollieren.',
			'notifications.newEpisodeTitle' => 'Neue Episode',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Versuchen Sie alle Funktionen für 7 Tage kostenlos',
			'appAccess.description' => 'Beginnen Sie eine sieben Tage lang mit vollem Zugang zu jeder PlezyNG Funktion. Es gibt keine Gebühr während der Prüfung und keine Abonnement. Nach der Prüffel, ein Lebensdauer Kauf zu Ihrem Geschäft Preis enthüllt PlezyNG für das Leben.',
			'appAccess.trialEndedDescription' => 'Entfernen Sie jede Funktion in PlezyNG für das Leben mit einem Kauf zum Preis Ihres Geschäcks.',
			'appAccess.startTrial' => 'Start mein 7-tägiges kostenloses Prüfung',
			'appAccess.trialActive' => 'Ihr 7-Tage-Full-Feature-Test ist aktiv.',
			'appAccess.trialEnded' => 'Ihr 7-Tage-Test ist abgeschlossen',
			'appAccess.trialStartFailed' => 'Ich konnte das Test auf diesem Gerät nicht speichern. versuchen Sie bitte erneut.',
			'appAccess.lifetimeTitle' => 'PlezyNG Unlocked für das Leben',
			'appAccess.lifetimeBody' => 'Dank! Sie haben den lebenslangen Zugriff auf jede PlezyNG Funktion.',
			'appAccess.manageTitle' => 'PlezyNG Lebensdauer Zugang',
			'appAccess.manageDescription' => 'Versuchen Sie jede Funktion für 7 Tage kostenlos, dann alles für das Leben mit einem einzigen Zahlung zu Ihrem Geschäft Preis entschließen.',
			'appAccess.buy' => ({required Object price}) => 'Entfernen Sie alle Funktionen für ${price}',
			'appAccess.loadingPrice' => 'Die Ladung im Shoppreis...',
			'appAccess.retryPrice' => 'Rückkehr Preis Lookup',
			'appAccess.restore' => 'Lebensdauer Kauf wiederherstellen',
			'appAccess.pending' => 'Ihr Kauf wartet auf Zahlung oder Genehmigung. Lifetime-Zugang wird abgeschlossen, sobald der Shop es abgeschlossen hat.',
			'appAccess.storeUnavailable' => 'Überprüfen Sie, dass Sie im Laden eingeloggt sind und die Einkaufsmöglichkeiten auf diesem Gerät erlaubt sind.',
			'appAccess.productNotFound' => 'Die PlezyNG Lebensdauer-Unlock ist noch nicht in diesem Shop erhältlich.',
			'appAccess.productQueryFailed' => 'Kann den Shoppreis nicht laden. Überprüfen Sie Ihre Verbindung und versuchen Sie es wieder.',
			'appAccess.purchaseFailed' => 'Der Kauf ist nicht durchgeführt worden. versuchen Sie erneut.',
			'appAccess.restoreFailed' => 'Ich konnte nicht zum Shop kommen, um Ihren Kauf wiederherzustellen. versuchen Sie erneut.',
			'appAccess.nothingToRestore' => 'No. PlezyNG Lebensdauer Kauf wurde für diesen Store-Konto gefunden.',
			'detail.endsAt' => ({required Object time}) => 'Endet um ${time}',
			'watchLink.serverUnavailable' => 'Ich konnte nicht auf einen Server Plex für diesen Link erreichen.',
			'watchLink.notFound' => 'Ich konnte diese Show oder Film nicht auf Ihren Server Plex finden.',
			'watchLink.ambiguous' => 'Dieser Link entspricht den Elementen auf mehr als einem Server.Hinzufügen eines Server zum Link.',
			'watchLink.plexOnly' => 'Die Watch Links unterstützen derzeit nur Plex Server.',
			'watchLink.unsupportedItem' => 'Die Anzeige-Links können nur eine Show oder einen Film öffnen.',
			'watchLink.menuItem' => 'Sehen Sie den Link',
			'watchLink.dialogTitle' => 'Sehen Sie Link',
			'watchLink.dialogShowHint' => 'Öffnen dieser Link spielt die nächste Episode. Add &mode=shuffle to the end, um die Show auf shuffle zu spielen.',
			'watchLink.dialogMovieHint' => 'Mit diesem Link öffnet der Film.',
			'watchLink.copy' => 'Kopie',
			'watchLink.copied' => 'Link kopiert',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home Reset auf die ursprüngliche Plezy Hero-Layout',
			'homeLayout.resetHeroTitle' => 'Wiederherstellen Sie die Hero-Layout auf Lager Plezy?',
			'homeLayout.resetHeroBody' => 'Sie dreht die Heldinstellung jeder Reihe ab und bringt die einzige Rotation Banner wieder auf der Spitze des Hauses, wie vor der Hero-Raden existiert.',
			'homeLayout.removeRowTitle' => 'Home Range entfernen?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} wird gelöscht. dies kann nicht abgesagt werden.',
			'homeLayout.sync' => 'Synchronisierung',
			'homeLayout.syncAccountTitle' => 'Synchronisieren Sie die Layout mit Ihrem Konto Plex',
			'homeLayout.syncAccountOn' => 'Auf: Dieses Gerät teilt die Reihenfolge, Reihenfolgen, Hero und Auto-Slide mit Ihren anderen Geräten.',
			'homeLayout.syncAccountOff' => 'Off: Dieses Gerät hält seine eigene Layout.',
			'homeLayout.syncNow' => 'Synchronisierung jetzt',
			'homeLayout.plexHomeManager' => 'Plex Hausverwalter',
			'homeLayout.managePlexRows' => 'Verwaltung Plex Zeilen in Plezy',
			'homeLayout.managePlexRowsDescription' => 'Öffnen Sie die Home-Selected Routes',
			'homeLayout.organizeHomeRows' => 'Home Runden organisieren',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} Zeilen: Bewegung, Hero, Auto-Slide, entfernen',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => '${library} Runden zu organisieren',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Weiterlesen + ${n} Zeilen: Bewegung, Bibliothek, Home, Hero, Auto-Slide',
			'homeLayout.renderAsHero' => 'Render als Heldkarte',
			'homeLayout.heroOnlySingleCollection' => 'Erhältlich nur, wenn diese Reihe auf die tatsächlichen Titel einer einzelnen Sammlung gelöst wird',
			'homeLayout.hero' => 'Helden',
			'homeLayout.autoSlide' => 'Auto-Slide',
			'homeLayout.autoSlideDescription' => 'Auch schlägt sie alle paar Sekunden auf sich. Arrows (PC) und d-pad (TV) arbeiten immer und starten die Timer neu.',
			'homeLayout.autoSlideEditDescription' => 'Auch schlägt sie alle paar Sekunden auf sich. Off: bewegt sich nur, wenn Sie auf eine Pfeile (PC) klicken oder links/recht auf die Fernseher (TV) drücken.',
			'homeLayout.enableHeroFirst' => 'Helden erstmal gestalten',
			'homeLayout.showOnHome' => 'Show auf Home Screen',
			'homeLayout.home' => 'Start',
			'homeLayout.removeFromHome' => 'Entfernen von zu Hause',
			'homeLayout.selectRowsFirst' => 'Wählen Sie die Home-Raden unten zuerst aus.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex verwaltete Zeilen',
			'homeLayout.continueWatching' => 'Weiterschauen',
			'homeLayout.continueWatchingLibraryDescription' => 'Diese eigene Bibliothek-Rehmen-Vorgang-Reihe',
			'homeLayout.continueWatchingHomeDescription' => 'Die Wiederholung-Vorgang-Reihe auf Home angezeigt',
			'homeLayout.nextUpHomeDescription' => 'Die nächste unbeobachtete Episode-Reihe separat auf Home angezeigt',
			'homeLayout.library' => 'Mediathek',
			'homeLayout.showInRecommended' => 'Show in der Bibliothek empfohlen',
			'homeLayout.customPlexRow' => 'Anpassung Plex Runde',
			'homeLayout.heroNeedsLibrary' => 'Schauen Sie sich die Bibliothek zuerst an – Hero braucht irgendwo zu zeigen',
			'homeLayout.heroNeedsSurface' => 'Schauen Sie sich die Bibliothek oder Home zuerst an – Hero braucht irgendwo zu zeigen',
			'homeLayout.removeHub' => 'Hub entfernen',
			'homeLayout.noPlexRows' => 'Nr. Plex-verwaltete Zeilen zurückkehren für diese Bibliothek.',
			'homeLayout.openDetails' => 'Offene Details',
			'homeLayout.heroCards' => 'Hero Karten',
			'homeLayout.tapHeroCard' => 'Ein Hero-Karte zu schlagen',
			'homeLayout.tvPlayFocus' => 'Fernseher: Highlight Play-Button',
			'homeLayout.tvPlayFocusDescription' => 'D-Pad Down stoppt auf der Play-Taste, bevor Sie in die nächste Reihe gehen.',
			'homeLayout.tvWrap' => 'Fernseher Fernseher: Lauf-Hero-Karten',
			'homeLayout.tvWrapDescription' => 'Direkt auf der letzten Karte geht zurück zum ersten. Off stops auf der letzten. Links auf der ersten Karte geht immer zur Seite.',
			'homeLayout.castOnHero' => 'Banner auf Hero Banner',
			'homeLayout.castOnHeroDescription' => 'Zeigt die Ausgabe entlang der Unterseite eines Hero Banner. Off hält nur den Titel und Zusammenfassung.',
			'homeLayout.customRows' => 'Custom Routen',
			'homeLayout.loading' => 'Home Layout Layout ...',
			'homeLayout.noCustomRows' => 'Keine Standard-Rennen noch',
			'homeLayout.addRowHint' => 'Verwenden Sie Add Home Range, um einen zu erstellen.',
			'homeLayout.addHomeRow' => 'Home Rue hinzufügen',
			'homeLayout.addHomeRowDescription' => 'Wählen Sie eine Kategorie aus; die neue Reihe wird automatisch an den Organizer hinzugefügt',
			'homeLayout.removeRow' => 'Rückschluss entfernen',
			'homeLayout.recentlyAdded' => 'Kürzlich hinzugefügt',
			'homeLayout.recentlyReleased' => 'kürzlich veröffentlicht',
			'homeLayout.movieCollections' => 'Filmkollektionen',
			'homeLayout.showCollections' => 'Show Kollektionen',
			'homeLayout.rowTitle' => 'Röhrtitel',
			'homeLayout.content' => 'Inhalt',
			'homeLayout.showThisRowIn' => 'Zeigen Sie diese Reihe in:',
			'homeLayout.libraryRecommended' => 'Bibliothek empfohlen',
			'homeLayout.heroCard' => 'Hero Karten',
			'homeLayout.heroCardDescription' => 'Zeigt als eine vollbreite Rotationskarte anstelle eines Posterschilds an.',
			'homeLayout.heroUnavailableDescription' => 'Nur dann verfügbar, wenn diese Reihe auf die tatsächlichen Titel einer einzelnen Sammlung gelöst wird – mit mehr als einer Sammlung ausgewählt, gibt es keine einzige Titel, die durchzuführen ist.',
			'homeLayout.librariesSelection' => 'Bibliotheken (alle nicht überprüften, um jede Bibliothek zu enthalten)',
			'homeLayout.librariesMergedDescription' => 'Jede hier überprüfte Bibliothek ist in diese eine Reihe zusammengefasst.',
			'homeLayout.movieCollectionsSelection' => 'Filmkollektionen (alle uncheckten für jede ausgewählte Bibliothek hinterlassen)',
			'homeLayout.showCollectionsSelection' => 'Zeigen Sie Sammlungen (alle uncheckten für jede ausgewählte Bibliothek abgeben)',
			'homeLayout.collectionRowsDescription' => 'Wenn genau eine Sammlung matzt, zeigen ihre Titel direkt in der Reihe. Wenn mehr als eine matzt, zeigt jede Sammlung als ein einziges Poster - drücken Sie es, um diese Sammlung zu öffnen.',
			'homeLayout.allCollections' => 'Alle Kollektionen',
			'homeLayout.noRowsHere' => 'Noch keine Runden hier.',
			'homeLayout.hideWatchedRows' => 'Verbergen Sie beobachtete Gegenstände in Zeilen',
			'homeLayout.hideWatchedRowsDescription' => 'Vollständig beobachtete Titel verlassen Home und Bibliothek Empfohlene Zeilen.',
			'homeLayout.untitledCollection' => 'Untitelte Sammlung',
			'homeLayout.moveRowHint' => 'Up/Down: Schalten Sie die Reihenfolge · Wählen Sie aus: Schalten sie hier · Rückkehr: Kündigen',
			'homeLayout.organizeRowsHint' => 'Wählen Sie auf einer Reihe (oder halten Sie Sie wählen Sie): bewegen Sie es · Links/Richt: Reihe Optionen · Rückkehr: getan',
			'homeLayout.layoutNavDescription' => 'Wählen Sie Zeilen, Bibliotheken und Sammlungskategorien aus',
			'homeLayout.editHomeRow' => 'Edit Home Rue zu lesen',
			'homeLayout.resetHeroButton' => 'Wiederherstellen des Hero-Layout auf Lager Plezy',
			'homeLayout.reorderingUnlocked' => 'Wiederverzeichnis unlocked',
			'homeLayout.reorderingLocked' => 'Umzug verborgen',
			'homeLayout.rowsCanBeDragged' => 'Die Wellen können abgeschaltet werden – das Lock aufschreiben, um zu verhindern, dass',
			'homeLayout.tapLockToDrag' => 'Tippen Sie den Lock, um Runden zu ziehen',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Anzahl: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Ausblenden',
			'homeLayout.remove' => 'Entfernen',
			'homeLayout.libraryResumeRow' => 'Die Bibliothek wird wiederum',
			'homeLayout.pressAgainToDelete' => 'Drücken Sie wieder, um zu löschen',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'auf',
			'homeLayout.resetHeroButtonDescription' => 'Sie dreht die Heldinstellung jeder Reihe ab und bringt die einzige Rotation Banner wieder oben, wie vor der Hero-Rennen existiert.',
			'homeLayout.tapHeroCardDescription' => 'Wählen Sie aus, ob das Tippen oder die Auswahl einer Hero-Karte eine Wiedergabe beginnt oder seine Details öffnet.',
			'homeLayout.heroTapPlayDescription' => 'Beginnen Sie das ausgewählte Element sofort.',
			'homeLayout.heroTapDetailsDescription' => 'Öffnen Sie die Details des ausgewählten Elements, bevor Sie eine Aktion wählen.',
			'platform.localNetworkPermission' => 'PlezyNG verbindet sich mit Ihren Medien-Server und Playback-Geräten auf Ihrem lokalen Netzwerk.',
			'platform.locationPermission' => 'PlezyNG verwendet Standortzugang, wenn iOS es benötigt, um Ihr lokales Netzwerk zu erkennen und mit Ihren Medien-Server zu verbinden.',
			'platform.photoLibraryPermission' => 'Wähle Bilder aus deiner Fotomediathek aus, um sie als Mediencover und andere Medienbilder zu verwenden.',
			'platform.cameraPermission' => 'QR-Codes scannen, um eine Companion Remote zu koppeln.',
			'universalMedia.title' => 'Öffnete Medien',
			'universalMedia.shortcutHelp' => 'Spielen Sie einen Link, eine Playlist oder eine Datei für diese Sitzung.',
			'universalMedia.intro' => 'Öffnen Sie einen Link, eine Playlist oder eine Datei.Playback verwendet den Standard-Player von PlezyNG und fügt keine Geschichte in Ihre Bibliothek hinzu.',
			'universalMedia.openWhat' => 'Was würdest du gerne öffnen?',
			'universalMedia.stream' => 'Stream Adresse',
			'universalMedia.playlist' => 'Spielliste',
			'universalMedia.files' => 'Geräte Datei',
			'universalMedia.favorites' => 'Sparen Stream Favoriten',
			'universalMedia.address' => 'Medienadresse',
			'universalMedia.addressHelp' => 'URLs mit anerkannten Kennzeichnungs- oder Signaturparameter werden nur für diese Sitzung verwendet und können nicht als Favoriten gespeichert werden.',
			'universalMedia.displayName' => 'Anzeige Name (optional)',
			'universalMedia.displayNameHelp' => 'Wählen Sie einen kurzen Namen für den Spieler und System-Media-Controls aus.',
			'universalMedia.allowHttp' => 'Erlauben Sie eine unschlüsselte HTTP-Verbindung',
			'universalMedia.allowHttpHelp' => 'HTTP verschlüsselt die Verbindung nicht. Erlauben Sie es nur auf einem vertrauenswürdigen Netzwerk. Verwenden Sie HTTPS, wenn möglich.',
			'universalMedia.advancedProtocols' => 'MPV nur: Geben Sie eine RTSP, RTMP/RTMPS, UDP oder RTP-Adresse ein. Diese Adressen können nicht als Favoriten gespeichert werden.',
			'universalMedia.liveStream' => 'Behandeln Sie als lebend',
			'universalMedia.liveStreamHelp' => 'Verwenden Sie dies für Live-Video oder Radio. Die App verbergt die Zeitbar, Skip-Button und Go-to-Time-Option.',
			'universalMedia.privateSession' => 'Nur dieses Playback verwendet die Adresse. Speichern Sie einen qualifizierten Stream Favorit, um es in diesem Profil zu halten.',
			'universalMedia.saveFavorite' => 'Speichern Sie Favoriten',
			'universalMedia.playNow' => 'Jetzt spielen',
			'universalMedia.favoriteSaved' => 'Stream Favoriten auf diesem Profil gespeichert',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Skipped ${count} ununterstützte oder sichere Playlist-Einträge.', other: 'Skipped ${count} nicht unterstützte oder unsichere Playlist-Einträge.', ), 
			'universalMedia.playlistAddress' => 'Playlist Adresse',
			'universalMedia.playlistAddressHelp' => 'Öffnen Sie eine M3U, M3u8 oder PLS-Playliste von einer Webadresse. Direct Stream Links speichern die Playlist nicht.',
			'universalMedia.choosePlaylist' => 'Wählen Sie Playlist-Datei',
			'universalMedia.openPlaylist' => 'Öffnen der Playlist',
			'universalMedia.playlistFormatsHelp' => 'Eine Playlist kann bis zu 1.000 Elemente und 2 MB enthalten. HLS manifestiert sich als Streams öffnet, so dass der Spieler eine Qualität wählen kann.',
			'universalMedia.noFavorites' => 'Keine gespeicherten Stream-Favorites noch. Favorites bleiben in diesem Profil.',
			'universalMedia.removeFavorite' => 'Stream Favoriten entfernen',
			'universalMedia.filesHelp' => 'Wählen Sie Audio, Video oder ISO-Dateien für eine vorübergehende Quelle. Dateien und URLs werden nicht in die Bibliothekgeschichte hinzugefügt.',
			'universalMedia.chooseFiles' => 'Wählen Sie Dateien',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '1 ausgewählte Datei', other: '${count} ausgewählte Dateien', ), 
			'universalMedia.wifiTransfer' => 'Dateien über Wi-Fi senden',
			'universalMedia.wifiTransferHelp' => 'Übertragen von unterstützten Dateien aus einem Browser auf das gleiche vertrauenswürdige Netzwerk.',
			'universalMedia.wifiTransferIntro' => 'Öffnen Sie diese Adresse in einem Browser auf einem anderen Gerät. Wählen Sie Dateien, um sie in die Datei- und Bücherbibliothek dieses Geräts hinzuzufügen.',
			'universalMedia.wifiTransferPrivacy' => 'Dieses Gerät erhält Dateien über Ihr lokales Netzwerk. Jeder, der diese Adresse kennt, kann Dateien senden, bis Sie die Übertragung stoppen oder die Adresse nach 15 Minuten endet. Maximum: 100 Dateien, 4 GiB pro Datei, 10 GiB insgesamt.',
			'universalMedia.wifiTransferStarting' => 'Eine private, zeitlich begrenzte Übertragung...',
			'universalMedia.wifiTransferUnavailable' => 'Sie können die Übertragung nicht starten. Überprüfen Sie den lokalen Netzwerkzugang und versuchen Sie erneut.',
			'universalMedia.openThisAddress' => 'Öffnen Sie eine dieser Adressen auf dem Versandgerät',
			'universalMedia.copyAddress' => 'Kopie der Transferadresse',
			'universalMedia.addressCopied' => 'Übertragungsadresse kopiert',
			'universalMedia.transferExpires' => ({required Object time}) => 'Diese Adresse endet in ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${count} Datei erhalten', other: '${count} Dateien erhalten', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Erhalt ${size}',
			'universalMedia.stopTransfer' => 'Übertragung und Invalidierung der Adresse stoppen',
			'universalMedia.startTransfer' => 'Beginn der Transfer',
			'universalMedia.wifiImportedFiles' => 'Wi-Fi Übertragung',
			'universalMedia.wifiBrowserTitle' => 'Dateien an PlezyNG senden',
			'universalMedia.wifiBrowserIntro' => 'Wählen Sie Audio, Video, Ebook oder Comic-Dateien zur Sendung aus. Die Dateien werden in der Datei- und Bücherbibliothek dieses Geräts gespeichert. Maximum: 100 Dateien, 4 GiB pro Datei, 10 GiB insgesamt.',
			'universalMedia.uploadFilesLabel' => 'Dateien zu senden',
			'universalMedia.uploadSelected' => 'Laden Sie ausgewählte Dateien',
			'universalMedia.uploadSelectFirst' => 'Wählen Sie zuerst eine oder mehrere Dateien aus.',
			'universalMedia.uploading' => 'Senden',
			'universalMedia.uploadComplete' => 'Datei zu PlezyNG hinzugefügt.',
			'universalMedia.uploadFailed' => 'Die Datei kann nicht hinzugefügt werden.Halten Sie diese Seite offen und versuchen Sie erneut.',
			'universalMedia.liveCue' => 'live',
			'universalMedia.liveSession' => 'Live Stream',
			'universalMedia.liveCueHelp' => 'Für Live-Video oder Radio versteckt die App die Zeitraumbar und schlägt die Button. Es speichert nicht die Adresse oder die Geschichte der Uhrzeit.',
			'universalMedia.sessionOnly' => 'Dieser Playback ist Session-Only',
			'universalMedia.sessionOnlyHelp' => 'Playback speichert niemals Fortschritte oder Geschichte.Save the stream as a favorite to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Bild Anpassungen',
			'universalMedia.pictureHelp' => 'Diese Bildänderungen beeinflussen nur diesen Playback. Sie reset, wenn das Playback endet.',
			'universalMedia.resetPicture' => 'Reset Bild',
			'universalMedia.brightness' => 'Brightheit',
			'universalMedia.contrast' => 'Kontrast',
			'universalMedia.gamma' => 'Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturation',
			'universalMedia.view360' => 'Flat View für 360° Video',
			'universalMedia.view360Help' => 'Verwenden Sie dies für gleichwertige 360°-Video. MPV benötigt FFmpeg\'s v360-Filter für diesen Ausblick.',
			'universalMedia.view360Unavailable' => 'Diese MPV-Konstruktion konnte das 360°-Filter nicht anwenden.',
			'universalMedia.view360Yaw' => 'Horizontale Sicht',
			'universalMedia.view360Pitch' => 'Vertikale Sicht',
			'universalMedia.view360FieldOfView' => 'Feld der Sicht',
			'universalMedia.recordStream' => 'Live Stream Rekord',
			'universalMedia.stopRecording' => 'Stoppen und speichern Sie die Aufzeichnung',
			'universalMedia.recordingStarted' => 'Die Aufnahme ist aktiv.Leaving playback stoppt und speichert die Aufnahme.',
			'universalMedia.recordingSaved' => 'Die Aufzeichnung wurde abgeschlossen und gerettet.',
			'universalMedia.recordingActive' => 'Auf diesem Gerät aufzeichnen.Leaving playback stoppt und speichert es.',
			'universalMedia.recordingFormatHelp' => 'Wählen Sie für Video MKV oder MPEG-TS. Für Audio wählen Sie MKA oder MKV aus.',
			'universalMedia.replaceRecordingTitle' => 'Ersetzen Sie diese Aufzeichnung?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG backt die bestehende Datei während der Aufzeichnung auf. Wenn sie die neue Aufnahme nicht speichern kann, wiederherstellt plezyNG die Backup.',
			'universalMedia.replaceRecording' => 'Datei ersetzen',
			'universalMedia.discHelp' => 'Öffnen Sie einen Disk im optischen Laufwerk dieses Computers. Sie können auch ein ISO-Bild aus Device-Dateien öffnen.',
			'universalMedia.discs' => 'Optische Disk',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-Ray',
			'universalMedia.audioCd' => 'Audio CD',
			'universalMedia.discAvailability' => 'Disk-Playback benötigt eine kompatible MPV-Konstruktion, unterstütztes Drive und Betriebssystemsgenehmigung. Es kann nicht den kommerziellen Diskschutz überschreiten.',
			'universalMedia.converterTitle' => 'Umwandeln einer lokalen Mediendatei',
			'universalMedia.converterHelp' => 'Umwandeln Sie eine lokale Datei oder remucken Sie sie mit FFmpeg.',
			'universalMedia.converterIntro' => 'Konvertieren Sie eine lokale Audio- oder Video-Datei in ein Format, das auf mehreren Geräten funktioniert.',
			'universalMedia.converterPrivacy' => 'FFmpeg muss auf diesem Computer installiert werden. Conversion liest nur lokale Dateien. Es herunterladen Streams oder entfernen DRM nicht.',
			'universalMedia.converterChooseInput' => 'Wählen Sie eine lokale Mediendatei',
			'universalMedia.converterFormat' => 'Ausgangsformat',
			'universalMedia.converterMp4' => 'MP4 · H.264 und AAC',
			'universalMedia.converterM4a' => 'M4A · AAC Audio',
			'universalMedia.converterMp3' => 'MP3 - Audio',
			'universalMedia.converterSaveAs' => 'Speichern Sie konvertierte Medien als',
			'universalMedia.converterExtensionMismatch' => 'Wählen Sie einen Filennamen mit der ausgewählten Ausgangserweiterung aus.',
			'universalMedia.converterUnsupportedInput' => 'Wählen Sie eine Audio oder Video-Datei aus.',
			'universalMedia.converterLocalOnly' => 'Die ausgewählte Datei ist nicht als lokaler Gerätstraße verfügbar.',
			'universalMedia.converterReplaceTitle' => 'Ersetzen Sie diese Datei?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG backs up die bestehende Datei, bis die konvertierte Kopie gespeichert wird.',
			'universalMedia.converterStarting' => 'Beginnen Sie mit FFmpeg...',
			'universalMedia.converterProgress' => 'Umwandeln Sie auf diesen Computer ...',
			'universalMedia.converterComplete' => 'Konvertierung abgeschlossen. die neue Datei ist bereit.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg Es fehlt oder unterstützt dieses Format nicht.',
			'universalMedia.converterFailed' => 'Überprüfen Sie, dass die Quelldatei gelesen werden kann und der Reiseziel genügend freie Platz hat.',
			'universalMedia.converterCancelled' => 'Konvertierung abgesagt. Der unvollständige Ausgang wurde entfernt.',
			'universalMedia.converterDesktopOnly' => 'Lokale Konvertierung ist auf Desktop-Computer mit FFmpeg installiert.',
			'universalMedia.converterStart' => 'Konvertierung Datei',
			'universalMedia.mediaToolsTitle' => 'Medieninstrumente',
			'universalMedia.mediaToolsShortcut' => 'Fangen oder teilen Sie Medien, fügen Sie Suchergänzungen hinzu oder verwenden Sie die Befehllinie.',
			'universalMedia.mediaToolsIntro' => 'Wählen Sie ein fokussiertes Werkzeug. Fangen und Streaming-out verwenden FFmpeg auf diesem Desktop installiert. Erweiterungen und CLI Befehl verwenden begrenzte HTTPS Anfragen und die bestehende Open media Fluss.',
			'universalMedia.mediaToolsAccessibility' => 'Tool-Wahlen und Steuerungen arbeiten mit Touch, Indikator, Tastatur und D-pad Fokus. Aufzeichnung, Teilen und Suchstatus Änderungen werden angekündigt.',
			'universalMedia.mediaTool' => 'Medienwerkzeug',
			'universalMedia.captureIntro' => 'Aufzeichnen Sie Ihren Bildschirm oder eine Kamera auf einem MP4-Datei auf diesem Computer. FFmpeg muss installiert und den H.264-Coder enthält.',
			'universalMedia.captureNoDevices' => 'Kein Bildschirm oder Kamera gefunden wurde. Überprüfen Sie FFmpeg Aufnahmeunterstützung und Betriebssystem-Privacy-Erlaubnisse.',
			'universalMedia.captureSource' => 'Bildschirm oder Kamera',
			'universalMedia.captureAudioSource' => 'Audio Input (optional)',
			'universalMedia.captureAudioHelp' => 'Hinzufügen von Audio aus einem Mikrofon oder verfügbaren Eingang. Gerätewahl hängt von FFmpeg und Systemgenehmigungen ab.',
			'universalMedia.captureAudioNone' => 'Kein Audio',
			'universalMedia.captureWaylandHelp' => 'Wayland beschränkt diese XWayland Aufnahme auf die X display. Windows außerhalb von XWayland erscheinen nicht.',
			'universalMedia.captureFrameRate' => 'Aufzeichnung Frame Rate',
			'universalMedia.capturePrivacy' => 'Die Aufzeichnung wird nur auf die von Ihnen gewählte Datei gespeichert. Microphone-Fangen ist optionell. PlezyNG laden die Aufzeichnung nicht auf.',
			'universalMedia.captureSaveAs' => 'Speichern Sie die Screenshots als',
			'universalMedia.captureExtensionMismatch' => 'Wählen Sie einen Filennamen, der in .mp4 endet.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg oder der H.264 Video-Coder ist nicht verfügbar. Einrichten Sie eine unterstützte FFmpeg Bau, dann versuchen Sie erneut.',
			'universalMedia.captureFailed' => 'Die Aufzeichnung konnte nicht gespeichert werden. Überprüfen Sie die Gerätgenehmigung, verfügbare Speicherung und FFmpeg Support.',
			'universalMedia.captureSaved' => 'Bildschirmaufnahmen gerettet.',
			'universalMedia.captureElapsedLabel' => 'Aufzeichnungszeit',
			'universalMedia.captureStart' => 'Beginnen Sie mit der Aufzeichnung',
			'universalMedia.captureStop' => 'Stoppen und retten',
			'universalMedia.captureMode' => 'Gefangene',
			'universalMedia.shareMode' => 'Teilen',
			'universalMedia.shareIntro' => 'Senden Sie eine lokale Mediendatei an ein anderes Gerät auf Ihrem privaten Netzwerk. PlezyNG erstellt einen vorübergehenden HLS Stream.',
			'universalMedia.sharePrivacy' => 'Jeder auf Ihrem lokalen Netzwerk, der den privaten Link erhält, kann den Link beobachten, während er aktiv ist. Der Link verschwindet nach 60 Minuten.',
			'universalMedia.shareChooseFile' => 'Media Datei auswählen',
			'universalMedia.shareChooseHelp' => 'Wählen Sie eine lokale Audio- oder Video-Datei aus. Die Datei bleibt auf diesem Computer.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.shareFfmpegMissing' => 'FFmpeg oder die H.264/AAC Codern sind nicht verfügbar. Installieren Sie FFmpeg mit H.264 und AAC Codern Unterstützung.',
			'universalMedia.shareFailed' => 'Der Stream konnte nicht beginnen oder unerwartet gestoppt werden. Überprüfen Sie FFmpeg und Netzwerkzugang.',
			'universalMedia.shareActive' => 'Der Stream ist bereit auf Ihrem privaten Netzwerk.',
			'universalMedia.shareEnded' => 'Die Medien haben das Ende erreicht und werden nicht mehr geteilt.',
			'universalMedia.shareStopped' => 'Die Teilen sind gestoppt.Der vorübergehende Link ist nicht mehr gültig.',
			'universalMedia.shareUrlCopied' => 'Stream Adresse kopiert.',
			'universalMedia.shareOpenUrl' => 'Öffnen Sie diese Adresse in einem Spieler auf dem anderen Gerät',
			'universalMedia.shareCopyUrl' => 'Kopieren von Stream-Adresse',
			'universalMedia.shareExpiresLabel' => 'Link endet ab',
			'universalMedia.shareStarting' => 'Bereiten Sie den Stream vor...',
			'universalMedia.shareStart' => 'Beginnen Sie mit Teilen',
			'universalMedia.shareStop' => 'Stoppen Sie mit dem Teilen',
			'universalMedia.extensionsMode' => 'Erweiterungen und CLI',
			'universalMedia.extensionsIntro' => 'Hinzufügen Sie eine Daten-nur-Suche-Erweiterung, um Medien zu finden. Wählen Sie ein Ergebnis, um es in das bekannte Open media Formular zu laden.',
			'universalMedia.extensionsPrivacy' => 'Ein Manifest kann eine HTTPS-Suche endpoint und map-responsfelder definieren. Es kann nicht Code ausführen, Antrag-Titel hinzufügen, Dateien lesen oder Start-Shell-Kommandos.',
			'universalMedia.extensionImport' => 'Erweiterung manifestiert',
			'universalMedia.extensionEmpty' => 'Keine Suchdienstleistungen noch. Wählen Sie eine vertrauenswürdige Manifest JSON Datei, um eine hinzuzufügen.',
			'universalMedia.extensionChoose' => 'Suchdienst',
			'universalMedia.extensionSearchConsent' => 'Jede Suche sendet Ihre Worte an diesen HTTPS Service. Ergebnisse öffnen sich nur nachdem Sie einen auswählen.',
			'universalMedia.extensionSearchLabel' => 'Suche nach Medien',
			'universalMedia.extensionSearch' => 'Suche',
			'universalMedia.extensionSearching' => 'Suchen...',
			'universalMedia.extensionNoResults' => 'Keine sicheren Medienergebnisse wurden zurückgegeben. versuchen Sie eine weitere Suche.',
			'universalMedia.extensionInstallTitle' => 'Geben Sie diesen Suchdienst hinzu?',
			'universalMedia.extensionReplaceTitle' => 'Aktualisieren Sie diesen Suchdienst?',
			'universalMedia.extensionService' => 'Dienstleistung',
			'universalMedia.extensionEndpoint' => 'HTTPS Endpunkt',
			'universalMedia.extensionConsent' => 'Ihr Suchtext wird an diesen Service gesendet. Das Manifest enthält keinen executable Code. Weiter nur, wenn Sie diesem Endpunkt vertrauen.',
			'universalMedia.extensionInstall' => 'Service hinzufügen',
			'universalMedia.extensionReplace' => 'Aktualisierung Service',
			'universalMedia.extensionRemoveTitle' => 'Entfernen Sie diesen Suchdienst?',
			'universalMedia.extensionRemoveHelp' => 'Dies entfernt den Service aus diesem Profil. PlezyNG kontaktiert nicht seinen Endpunkt.',
			'universalMedia.extensionRemove' => 'Service entfernen',
			'universalMedia.extensionInvalidManifest' => 'Dieser Datei ist kein unterstütztes Extension manifesto. siehe die Open media-Günderung für das Format.',
			'universalMedia.extensionSaveFailed' => 'Die Erweiterung konnte nicht auf das aktive Profil gespeichert werden.',
			'universalMedia.extensionSearchFailed' => 'Der Suchdienst hat keine gültige Antwort zurückgegeben. prüfen Sie das Endpunkt und versuchen Sie es erneut.',
			'universalMedia.cliTitle' => 'Kommando Linie',
			'universalMedia.cliHelp' => 'Verwenden Sie den plezyctl-Guide, um ein Manifest zu validieren oder die gleiche Erweiterung zu suchen. Überprüfen Sie den HTTPS-Service vor jeder Suche. Ergebnisse öffnen sich im bestehenden Medienformular; wählen Sie den Playback-Taste aus, um zu starten.',
			'universalMedia.cliCopyExample' => 'Kopieren von Command Example',
			'universalMedia.cliCopied' => 'Das Beispiel der Kopie.',
			'universalMedia.captureScreen' => 'Bildschirm',
			'universalMedia.captureDefaultAudio' => 'Default Audio-Eintrag',
			'universalMedia.shareQrLabel' => 'QR-Code für die temporäre Stream-Adresse',
			'universalMedia.shareQrHelp' => 'Scan mit einem kompatiblen Player, der mit demselben privaten Netzwerk verbunden ist.',
			'universalMedia.shareHttpHint' => 'This stream uses unencrypted HTTP. In PlezyNG, allow HTTP before opening it.',
			'universalMedia.allowFtp' => 'FTP erlaubt',
			'universalMedia.allowFtpHelp' => 'FTP sendet Medien ohne Verschlüsselung. Verwenden Sie nur auf vertrauenswürdigen Netzwerken.',
			'fileSources.title' => 'Dateien und Bücher',
			'fileSources.subtitle' => 'Lesen, hören und aus Ihren eigenen Dateien beobachten.',
			'fileSources.add' => 'Quelle hinzufügen',
			'fileSources.importFiles' => 'Importierung von Dateien',
			'fileSources.localFiles' => 'Auf diesem Gerät',
			'fileSources.source' => 'Quelle',
			'fileSources.name' => 'Name',
			'fileSources.endpoint' => 'Server-URL',
			'fileSources.smbEndpointHint' => 'Beispiel: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Gib einen SMB-Server und eine Freigabe ein.',
			'fileSources.root' => 'Folder oder Prefix',
			'fileSources.smbFolderHelp' => 'Lass das Feld leer, um die gesamte Freigabe zu verwenden, oder gib einen Ordner darin ein.',
			'fileSources.username' => 'Benutzername',
			'fileSources.smbDomain' => 'Domäne (optional)',
			'fileSources.password' => 'Passwort',
			'fileSources.token' => 'API Token',
			'fileSources.accessKey' => 'Zugriffs-Key ID',
			'fileSources.secretKey' => 'Geheimen Zugriffsschlüssel',
			'fileSources.sessionToken' => 'Session Token (Optional)',
			'fileSources.region' => 'Region',
			'fileSources.clientId' => 'OAuth Client ID',
			'fileSources.clientSecret' => 'OAuth Client Secret (nur Google Desktop)',
			'fileSources.allowHttp' => 'Unverschlüsseltes HTTP in einem vertrauenswürdigen Netzwerk erlauben',
			'fileSources.smbEncryption' => 'SMB3-Verbindung verschlüsseln',
			'fileSources.smbEncryptionHint' => 'SMB3-Verschlüsselung verwenden, wenn das NAS sie unterstützt.',
			'fileSources.connect' => 'Verbinden',
			'fileSources.cancel' => 'Abbrechen',
			'fileSources.save' => 'Speichern',
			'fileSources.close' => 'Schließen',
			'fileSources.removeSource' => 'Abschließen Quelle',
			'fileSources.disconnectMessage' => 'Verbindung zu dieser Quelle trennen? Heruntergeladene Dateien sowie dein Lese- und Hörverlauf bleiben auf diesem Gerät.',
			'fileSources.localFolder' => 'Wählen Sie die Folder',
			'fileSources.empty' => 'Hier ist noch nichts',
			'fileSources.emptyHint' => 'Ein Quell hinzufügen oder ein Buch, Audiobook, Musik oder Video importieren.',
			'fileSources.search' => 'Suche nach diesem Ordner',
			'fileSources.searchCached' => 'Suche nach der Rettung Bibliothek',
			'fileSources.refresh' => 'Aktualisieren',
			'fileSources.loadMore' => 'Laden Sie mehr',
			'fileSources.offline' => 'Offline verfügbar',
			'fileSources.download' => 'Offline bleiben',
			'fileSources.removeDownload' => 'Offline Kopie entfernen',
			'fileSources.continueReading' => 'Weiterlesen →',
			'fileSources.continueListening' => 'Weiterlesen Listen',
			'fileSources.continueWatching' => 'Weiter zu beobachten',
			'fileSources.read' => 'Lesen',
			'fileSources.listen' => 'Anhören',
			'fileSources.play' => 'Abspielen',
			'fileSources.pause' => 'Pause',
			'fileSources.stop' => 'Stopp',
			'fileSources.startOver' => 'Beginnen Sie über',
			'fileSources.finished' => 'Beendet',
			'fileSources.markFinished' => 'Mark ist fertig',
			'fileSources.markUnfinished' => 'Mark unendlich',
			'fileSources.editions' => 'Veröffentlichungen und Dateien',
			'fileSources.chapters' => 'Kapitel',
			'fileSources.bookmarks' => 'Buchmarken und Notizen',
			'fileSources.bookmark' => 'Buchmarke hinzufügen',
			'fileSources.highlight' => 'Markieren',
			'fileSources.note' => 'Note zu',
			'fileSources.delete' => 'Löschen',
			'fileSources.export' => 'Export Notizen',
			'fileSources.exported' => 'Notizen exportiert',
			'fileSources.sync' => 'Synchronisierung Fortschritte',
			'fileSources.synced' => 'Fortschritt synchronisiert',
			'fileSources.conflict' => 'Ein anderes Gerät hat eine andere Position. wählen Sie, wo Sie weitergehen.',
			'fileSources.useLocal' => 'Verwenden Sie dieses Gerät',
			'fileSources.useRemote' => 'Andere Geräte verwenden',
			'fileSources.history' => 'Position Geschichte',
			'fileSources.groupAudio' => 'Lernen Sie als ein Audiobook',
			'fileSources.groupHint' => 'Kombinieren Sie die Audio-Dateien, die derzeit in dieser Ordnung geladen sind.Laden Sie zuerst alle Seiten.',
			'fileSources.order' => 'Datei Ordnung',
			'fileSources.moveUp' => 'Bewegung auf',
			'fileSources.moveDown' => 'Bewegung nach unten',
			'fileSources.speed' => 'Spielback Geschwindigkeit',
			'fileSources.sleep' => 'Schlaftimer',
			'fileSources.sleepOff' => 'Aus',
			'fileSources.endChapter' => 'Ende des Kapitels',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} Minuten', ), 
			'fileSources.skipBack' => 'Skip zurück',
			'fileSources.skipForward' => 'Skip voran',
			'fileSources.smartRewind' => 'Smart Revenge nach einer Pause',
			'fileSources.playbackOptions' => 'Listen Optionen',
			'fileSources.remaining' => ({required Object time}) => '${time} übrig geblieben',
			'fileSources.contents' => 'Inhalt',
			'fileSources.readerSettings' => 'Lesen Settings',
			'fileSources.fontSize' => 'Textgröße',
			'fileSources.lineHeight' => 'Line Spaziergang',
			'fileSources.margin' => 'Seitenränder',
			'fileSources.font' => 'Typfass',
			'fileSources.serif' => 'Seriö',
			'fileSources.sans' => 'ohne Serien',
			'fileSources.mono' => 'Monospaß',
			'fileSources.columns' => 'Kolumne',
			'fileSources.scroll' => 'Vertikal Scroll',
			'fileSources.justify' => 'Text rechtfertigen',
			'fileSources.readerTheme' => 'Seite Aussehen',
			'fileSources.appTheme' => 'Folgen Sie dem App-Theme',
			'fileSources.paper' => 'Papier',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Nacht',
			'fileSources.readAloud' => 'Diese Seite vorlesen',
			'fileSources.readAlong' => 'Lesen Sie weiter',
			'fileSources.stopReading' => 'Stoppen Sie mit Narration',
			'fileSources.searchBook' => 'Suche in Buch',
			'fileSources.noMatches' => 'Keine Spiele',
			'fileSources.previousPage' => 'Vorherige Seite',
			'fileSources.nextPage' => 'Nächster Seite',
			'fileSources.page' => ({required Object number}) => 'Seite ${number}',
			'fileSources.externalBlocked' => 'Externe Buchverbindungen sind im Leser deaktiviert.',
			'fileSources.loading' => 'Öffnen...',
			'fileSources.narrator' => 'Narrater',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebooks',
			'fileSources.all' => 'Alle',
			'fileSources.downloads' => 'Offline Datei',
			'fileSources.confirmDelete' => 'Entfernen Sie die ausgewählte Offline-Kopie? Ihre Position und Notizen bleiben.',
			'fileSources.errorAuthentication' => 'Sign in erneut, um diese Quelle wieder zu verknüpfen.',
			'fileSources.errorPermission' => 'Diese Quelle erteilt keinen Zugang zum angeforderten Datei.',
			'fileSources.errorUnavailable' => 'Versuchen Sie erneut oder öffnen Sie eine Offline-Kopie.',
			'fileSources.errorUnsupported' => 'Dieses Format oder die Verbindung wird auf diesem Gerät nicht unterstützt. prüfen Sie den Quellinstellungsguide.',
			'fileSources.errorInvalidData' => 'Diese Datei oder Server-Reaktion kann nicht sicher gelesen werden.',
			'fileSources.errorCancelled' => 'Die Operation wurde abgesagt.',
			'fileSources.errorConflict' => 'Die Position wurde in einer anderen Sitzung geändert. Wieder öffnen Sie das Element, um eine Position auszuwählen.',
			'fileSources.signIn' => 'Anmelden',
			'fileSources.reconnect' => 'Erneut verbinden',
			'fileSources.folderHelp' => 'Lassen Sie das Wurzeln auf dem Quellwurzel beginnen. URLs S3 enthalten das Bucket.',
			'fileSources.preferences' => 'Vorlieben',
			'fileSources.timePosition' => 'Position',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Untertitel Track',
			'fileSources.none' => 'Keiner',
			'fileSources.fullscreen' => 'Vollbildschirm',
			'fileSources.syncLocation' => 'Progress Sync Folder (optional)',
			'fileSources.syncLocationHint' => 'Eine dedizierte WebDAV Folder für PlezyNG Status. verwendet bedingte Schreiben; Medien bleiben unverändert.',
			'fileSources.audiobooks' => 'Audiobücher',
			'fileSources.comics' => 'Comics',
			'fileSources.scan' => 'Scan für Bücher und Medien',
			'fileSources.browserReader' => 'Öffnen Leser',
			'fileSources.browserReaderHelp' => 'Der Leser ist in Ihrem Browser geöffnet.Halten Sie PlezyNG offen, um Ihre Platz und Notizen zu speichern.',
			'fileSources.on' => 'auf',
			'fileSources.advancedSetup' => 'App Registrierung',
			'fileSources.microsoftSignIn' => 'Unterschreiben Sie sich mit Microsoft',
			'fileSources.zoomIn' => 'Vergrößern',
			'fileSources.zoomOut' => 'Zoom aus',
			'fileSources.fitPage' => 'Fit Seite',
			'fileSources.fitWidth' => 'Fit Breite',
			'fileSources.actualSize' => 'Aktuelle Größe',
			'fileSources.goToPage' => 'Gehen Sie zu Seite',
			'fileSources.goToSection' => 'Gehen Sie zum Kapitel',
			'fileSources.pageRange' => ({required Object count}) => 'Einzahlung von 1 bis ${count}',
			'fileSources.pageLayout' => 'Seite Layout',
			'fileSources.automatic' => 'Automatisch',
			'fileSources.singlePage' => 'Single Seite',
			'fileSources.twoPages' => 'Zwei Seiten',
			'fileSources.readingDirection' => 'Lesen Richtung',
			'fileSources.leftToRight' => 'links nach rechts',
			'fileSources.rightToLeft' => 'Von rechts nach links',
			'fileSources.letterSpacing' => 'Brief Spazier',
			'fileSources.wordSpacing' => 'Spazierend Wort',
			'fileSources.readerControlsHelp' => 'Ziehe zwei Finger auseinander oder nutze die Zoom-Steuerung, um Seiten zu vergrößern. Ziehe die Seite, um sie zu verschieben. Ctrl/⌘ mit + oder − ändert den Zoom; Ctrl/⌘ mit 0 setzt ihn zurück. Page Up und Page Down blättern um.',
			'fileSources.imagePage' => 'Comicseite',
			'fileSources.resetReader' => 'Lesen Preferenzen wiederherstellen',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Dateien und Bücher verwenden',
			'fileSources.cancelScan' => 'Scan abgeben',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Limit für Offline-Downloads',
			'fileSources.offlineQuotaHelp' => 'Setzen Sie den maximalen Raum, der von Offline-Kopien, importierten Dateien und abgelaufenen Downloads verwendet wird. Die Reduzierung des Limites entfernt nicht bestehende Kopien.',
			'fileSources.offlineStorageUsage' => 'Offline Lagerung',
			'fileSources.reservedStorage' => 'reserviert',
			'fileSources.downloadQueue' => 'Download von Queue',
			'fileSources.downloadRunning' => 'Downloaden',
			'fileSources.downloadQueued' => 'warten',
			'fileSources.downloadPaused' => 'Pause',
			'fileSources.downloadFailed' => 'Rückkehr benötigt',
			'fileSources.importing' => 'Einfuhr',
			'fileSources.importInterrupted' => 'Einfuhren unterbrochen · entfernen zu klären',
			'fileSources.errorQuotaExceeded' => 'Die Offline Speichergrenze wurde erreicht. Erhöhen Sie die Grenze oder entfernen Sie eine heruntergeladenen Kopie.',
			'fileSources.errorStorageLow' => 'Es gibt nicht genügend freie Geräte-Speicher, um die geschützte Reservierung zu halten.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG konnte die kostenlose Geräte-Speicher nicht überprüfen, so dass das Schreiben gestoppt wurde.',
			'fileSources.removeDownloadJob' => 'Entfernen Download',
			'fileSources.downloadAlreadyComplete' => 'Dieses Download ist fertig, bevor es entfernt werden kann. Das Element ist jetzt offline verfügbar.',
			'fileSources.confirmRemoveDownloadJob' => 'Entfernen Sie diesen Download und löschen Sie alle teilweise heruntergeladenen Daten? Ihre Position und Notizen bleiben.',
			'lending.title' => 'öffentliche Bibliotheken',
			'lending.add' => 'Ein Bücherei hinzufügen',
			'lending.other' => 'Eine weitere Bibliothek',
			'lending.libraryName' => 'Bibliothek Name',
			'lending.libraryUrl' => 'Bibliothek Website',
			'lending.libraryUrlHint' => 'Verwenden Sie den Katalog Ihrer Bibliothek oder die Sign-in-Seite.',
			'lending.intro' => 'Lene deine Bibliothek, halten deine Bücher dicht.',
			'lending.handoff' => 'Anmeldung, Darlehen und Lesen sicher mit der eigenen Bibliothek-Service.',
			'lending.openService' => 'Öffnete Bibliothek',
			'lending.findLibrary' => 'Suche eine Bibliothek',
			'lending.search' => 'Suche nach Büchern und Autoren',
			'lending.catalogue' => 'Katalog',
			'lending.loans' => 'Darlehen',
			'lending.holds' => 'Vormerkungen',
			'lending.signIn' => 'Anmeldung mit Ihrer Bibliothek',
			'lending.waiting' => 'Beenden Sie die Anmeldung in Ihrem Browser und dann zurück.',
			'lending.cancel' => 'Abbrechen',
			'lending.disconnect' => 'Bibliothek entfernen',
			'lending.disconnectMessage' => 'Diese Bibliothek aus diesem Profil entfernen? Deine Ausleihen und Vormerkungen bleiben bei der Bibliothek erhalten.',
			'lending.getBook' => 'Buch bekommen',
			'lending.checkAvailability' => 'Überprüfen Sie Verfügbarkeit',
			'lending.available' => 'zur Verfügung zum Darlehen',
			'lending.unavailable' => 'Aktuell unzugänglich',
			'lending.borrow' => 'Ausleihen',
			'lending.placeHold' => 'Vormerken',
			'lending.returnBook' => 'früh zurück',
			'lending.cancelHold' => 'Vormerkung stornieren',
			'lending.confirmBorrow' => 'Löhnen Sie diesen Titel aus Ihrer Bibliothek?',
			'lending.confirmReturn' => 'Geben Sie diesen Titel jetzt zurück? Sie müssen es vielleicht erneut leihen, um weiterzuführen.',
			'lending.confirmCancelHold' => 'Deine Vormerkung für diesen Titel stornieren?',
			'lending.email' => 'E-Mail Nachricht halten',
			'lending.due' => ({required Object date}) => 'Die Anzahl ${date}',
			'lending.queue' => ({required Object position}) => 'Position ${position} in der Linie',
			'lending.empty' => 'Keine Titel hier noch.',
			'lending.openLibraryNote' => 'Entdecken Sie den Katalog der Open Library. Lesen und Darlehen Optionen sind auf der Seite jedes Titels angezeigt.',
			'lending.more' => 'Laden Sie mehr',
			'lending.gateway' => 'Bibliothek Sign-in Service',
			'lending.gatewayHint' => 'Sie werden von Ihrer Bibliothek oder dem Administrator PlezyNG bereitgestellt.',
			'lending.advanced' => 'Bibliothekintegration',
			'lending.loadLibraries' => 'Wählen Sie Ihre Bibliothek',
			'lending.expired' => 'Dieses Darlehen ist abgeschlossen.',
			'lending.updated' => 'Bibliothek aktualisiert',
			'lending.continueService' => 'Weiter in Service',
			'lending.comingSoon' => 'In-app Darlehen · Kommen bald',
			'lending.comingSoonDescription' => 'Sie können Ihre Bibliothek in Libby verwenden, während wir sie verbinden.',
			'lending.suspendHold' => 'Halt aufhören',
			'lending.resumeHold' => 'Resume halten',
			'lending.suspendMessage' => 'Deinen Platz in der Warteschlange behalten und den nächsten Leser dieses Exemplar ausleihen lassen? Du kannst die Vormerkung später fortsetzen.',
			'lending.resumeMessage' => 'Diese Vormerkung fortsetzen, damit dir die Bibliothek das nächste verfügbare Exemplar anbieten kann?',
			'lending.editEmail' => 'Änderung der E-Mail-Nachricht',
			'audiobook.syncTitle' => 'Lesen und Hören Sync',
			'audiobook.syncHelp' => 'Halten Sie Lesungspositionen, Listenpositionen, Vollendungsstatus, Buchmarken und Notizen über Ihre Geräte. Wählen Sie ein angeschlossenes Speicherkonto und verwenden Sie den gleichen Sync-Code auf jedem Gerät. Lesen und Listen bleiben getrennt.',
			'audiobook.addSyncSource' => 'Zunächst Google Drive, OneDrive, Dropbox, WebDAV oder S3 in Dateien und Bücher hinzufügen.',
			'audiobook.syncDestination' => 'Sync Speicherkonto',
			'audiobook.syncFolder' => 'Synchronisierung von Ordnern oder Prefix',
			'audiobook.syncFolderHelp' => 'Verwenden Sie eine separate bestehende Ordner innerhalb Ihrer WebDAV-Quelle oder eine dedizierte S3 Vorwahl. Buchdateien werden nie geändert.',
			'audiobook.syncCode' => 'Private Synchronisierungscode',
			'audiobook.syncCodeHelp' => 'Erstellen Sie einen Code auf Ihrem ersten Gerät, dann geben Sie diesen Code auf Ihren anderen Geräten ein. Halten Sie eine private Kopie: Es ist der Schlüssel zu Ihrem verschlüsselten Zustand. Verwenden Sie für jede Person einen anderen Code.',
			'audiobook.showCode' => 'Zeigen oder verstecken Sie Sync-Code',
			'audiobook.newSyncCode' => 'Erstellen eines neuen Sync-Codes',
			'audiobook.saveSync' => 'Speichern und synchronisieren',
			'audiobook.disableSync' => 'Synchronisierung auf diesem Gerät deaktivieren',
			'audiobook.syncSourceDisconnect' => 'Wenn Sie diese Quelle entfernen, wird das Lesen und Hören von Sync hier ausgeschaltet. Verschlüsselte Sync-Dateien bleiben im Anbieter.',
			'audiobook.syncReconnect' => 'Wiederverbindung des Speicherkontoes',
			'audiobook.lastSynced' => ({required Object time}) => 'Letzte Synchronisierung bei ${time}',
			'audiobook.syncPrivacy' => 'Nur verschlüsselte Fortschritte und Notizen werden gespeichert. Audio- und E-Book-Dateien, Konto-Token und Passwörter werden nicht hochgeladen. Google Drive und OneDrive verwenden App-Speicher; Dropbox verwendet PlezyNG Sync. Sync ermöglichen kann zusätzliche Schreibzugang verlangen. Während aktiviert, besitzt dieses Ziel Fortschritt Sync; Server Fortschritt bleibt getrennt. Sync-Off-Speicher hält die lokale Geschichte und Entfernung-Status.',
			'audiobook.syncConflicts' => 'Wählen Sie, wo Sie wiederholen',
			'audiobook.conflictHelp' => 'Diese Änderungen wurden unabhängig durchgeführt. Wählen Sie die Position oder Buchmarke Version zu halten. Eine spätere Timestamp oder ein höheres Prozentsatz gewinnt nicht automatisch.',
			'audiobook.syncDevice' => ({required Object device}) => 'Gerät ${device}',
			'audiobook.syncUnknownDevice' => 'Unbekannte Geräte',
			'audiobook.deletedBookmark' => 'Löschte Buchmarke',
			'audiobook.finished' => 'abgeschlossen',
			'audiobook.readingPosition' => ({required Object percent}) => 'Lesen · ${percent}%',
			'audiobook.chapterTimeline' => 'Kapitel Fortschritt',
			'audiobook.bookTimeline' => 'Das ganze Buch Fortschritt',
			'audiobook.bookRemaining' => ({required Object time}) => 'Zeit bleibt in diesem Buch: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Zeit bleibt in diesem Kapitel: ${time}',
			'audiobook.unknownRemaining' => 'Gesamtzeit verfügbar, da Teile gespielt werden',
			'audiobook.undoSeek' => 'Undo letzte Suche',
			'audiobook.customSpeed' => 'Custom Playback Geschwindigkeit',
			'audiobook.speedHelp' => 'Wählen Sie eine Geschwindigkeit von 0,25× bis 4×.',
			'audiobook.apply' => 'Anwendung',
			'audiobook.customSleep' => 'Personalisierter Schlaf Timer',
			'audiobook.sleepMinutes' => '1 Minute (1 bis 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Stopp nach ${count} Kapiteln',
			'audiobook.extendSleep' => '5 Minuten hinzufügen',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Schlaftimeter: ${time}',
			'audiobook.useDefaults' => 'Verwenden Sie diese Hörkontrollen für neue Bücher',
			'audiobook.librarySort' => 'Sorte Bücher',
			'audiobook.sortTitle' => 'Titel',
			'audiobook.sortAuthor' => 'Autorin',
			'audiobook.sortNarrator' => 'Sprichwort',
			'audiobook.sortSeries' => 'Serie Ordnung',
			'audiobook.sortRecent' => 'kürzlich geöffnet',
			'audiobook.statusFilter' => 'Status des Lesens',
			'audiobook.statusAll' => 'Alle Bücher',
			'audiobook.statusNew' => 'nicht begonnen',
			'audiobook.statusProgress' => 'Im Fortschritt',
			'audiobook.statusFinished' => 'abgeschlossen',
			'audiobook.goToTime' => 'Gehen Sie zur Zeit',
			'audiobook.timeHelp' => 'Stunden: Minuten: Sekunden oder Minuten: Sekunden',
			'audiobook.recoveryHelp' => 'Exportieren Sie eine kürzlich verschlüsselte Kopie, bevor Sie Sync-Daten bewegen oder reparieren.Importe fusionieren mit dem aktuellen Zustand; sie ersetzen niemals die lokale Sync Geschichte.',
			'audiobook.recoveryExport' => 'Export verschlüsselte Recovery Datei',
			'audiobook.recoveryImport' => 'Import verschlüsselte Recovery-Datei',
			'audiobook.recoveryImportConfirm' => 'Kombinieren Sie diese verschlüsselte Recovery-Datei mit aktuellen Lesepositionen und Notizen? bestehende Geschichte wird beibehalten. gemeinsame Bibliothek und Element-IDs sind nicht enthalten; Set matching IDs on each device before importing.',
			'audiobook.recoveryExported' => 'Verschlüsselte Recovery-Datei wurde gespeichert.',
			'audiobook.recoveryImported' => 'Wiederherstellungsdaten sind zusammengefasst.',
			'sourceSetup.savedCertificate' => 'Gespeichertes Serverzertifikat',
			'sourceSetup.nfsEndpointInvalid' => 'Gib eine NFS-URL wie nfs://nas:2049/export ein.',
			'sourceSetup.dlnaNone' => 'Keine DLNA-Server gefunden. Gib die URL der Gerätebeschreibung manuell ein.',
			'sourceSetup.dlnaServers' => 'DLNA-Medienserver',
			'sourceSetup.dlnaUnavailable' => 'Die DLNA-Suche ist in diesem Netzwerk nicht verfügbar. Gib die URL der Gerätebeschreibung manuell ein.',
			'sourceSetup.dlnaSearching' => 'Lokales Netzwerk wird nach DLNA-Servern durchsucht',
			'sourceSetup.networkSearching' => 'Lokales Netzwerk wird durchsucht…',
			'sourceSetup.dlnaDiscover' => 'DLNA-Server finden',
			'sourceSetup.dlnaHelp' => 'Die Suche benötigt Multicast im lokalen Netzwerk. Falls kein Server erscheint, gib oben die URL seiner Gerätebeschreibung ein.',
			'sourceSetup.dlnaRoot' => 'DLNA-Objekt-ID; leer lassen, um das Stammverzeichnis des Geräts zu verwenden.',
			'sourceSetup.passwordOrKey' => 'Gib ein Passwort ein oder füge unten einen privaten Schlüssel hinzu.',
			'sourceSetup.sshFingerprint' => 'SHA256-Fingerabdruck des SSH-Hostschlüssels',
			'sourceSetup.sshFingerprintHelp' => 'Prüfe ihn mit dem Serveradministrator. Führe auf dem Server ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub aus und verwende den SHA256-Wert.',
			'sourceSetup.sshFingerprintKeep' => 'Leer lassen, um den aktuell festgelegten Fingerabdruck beizubehalten, oder einen neuen Serverfingerabdruck eingeben.',
			'sourceSetup.sshAuthentication' => 'SSH-Authentifizierung mit öffentlichem Schlüssel',
			'sourceSetup.sshAuthenticationHelp' => 'Optional; die Authentifizierung mit Passwort wird ebenfalls unterstützt.',
			'sourceSetup.privateKey' => 'Privater Schlüssel (PEM- oder OpenSSH-Format)',
			'sourceSetup.privateKeyPassphrase' => 'Passphrase des privaten Schlüssels',
			'sourceSetup.nfsMountPort' => 'TCP-Port des NFS-Mount-Dienstes',
			'sourceSetup.nfsMountPortHelp' => 'Standard: 20048',
			'sourceSetup.nfsUserId' => 'NFS-Benutzer-ID (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Standard: 1000. Verwende die ID, die die NFS-Freigabe des NAS erlaubt.',
			'sourceSetup.nfsGroupId' => 'NFS-Gruppen-ID (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Standard: 1000. Verwende die Gruppen-ID, die die NFS-Freigabe des NAS erlaubt.',
			'sourceSetup.nfsEncryption' => 'Verschlüsseltes NFS verlangen (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'TLS 1.3 für NFS und den Mount-Dienst verlangen. Unterstützt das NAS dies nicht, wird die Verbindung abgelehnt.',
			'sourceSetup.nfsTrustCertificate' => 'Benutzerdefinierte NFS-CA oder Serverzertifikat (PEM, optional)',
			'sourceSetup.nfsTrustHelp' => 'Leer lassen, um Zertifikate zu verwenden, denen dieses Gerät vertraut. Füge bei Bedarf ein Zertifikat einer privaten CA oder ein selbstsigniertes Serverzertifikat hinzu; dessen Namen müssen zum Host der NFS-URL passen.',
			'sourceSetup.nfsTrustInvalid' => 'Verwende ein CA- oder Serverzertifikat im PEM-Format. Füge keinen privaten Schlüssel ein.',
			'sourceSetup.addTrustCertificate' => 'Benutzerdefiniertes Vertrauenszertifikat hinzufügen',
			'sourceSetup.replaceTrustCertificate' => 'Gespeichertes benutzerdefiniertes Zertifikat ersetzen',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS verwendet die üblichen NFS- und Mount-Dienst-Ports und benötigt RFC 9289-Unterstützung auf dem NAS. TLS 1.3 ist erforderlich. Hostname oder IP-Adresse müssen zum Zertifikat passen. AUTH_SYS-UID/GID gelten auch im verschlüsselten Kanal.',
			'sourceSetup.clientCertificate' => 'Clientzertifikat (optional)',
			'sourceSetup.clientCertificateHelp' => 'Damit kann das NAS diesen Client authentifizieren; AUTH_SYS-IDs unterliegen weiterhin den Regeln der NFS-Freigabe des NAS.',
			'sourceSetup.savedIdentity' => 'Eine gespeicherte Clientidentität wird verwendet.',
			'sourceSetup.replaceIdentity' => 'Gespeicherte Clientidentität ersetzen',
			'sourceSetup.chooseIdentity' => 'PKCS#12-Clientidentität auswählen',
			'sourceSetup.identityPassphrase' => 'Passphrase der Clientidentität',
			'sourceSetup.identityPassphraseHelp' => 'Leer lassen, wenn die Datei keine Passphrase hat.',
			'sourceSetup.removeIdentity' => 'Gespeicherte Clientidentität entfernen',
			'sourceSetup.identityStorageHelp' => 'Clientidentitäten werden im verschlüsselten Zugangsdaten-Speicher der Quelle abgelegt. Lass diesen Abschnitt unverändert, um die gespeicherte Identität beizubehalten.',
			'sourceSetup.nfsLimitations' => 'NFSv3 über TCP, nur lesend. Ohne RPC-with-TLS ist der NFS-Verkehr unverschlüsselt. Das NAS muss die gewählten AUTH_SYS-IDs und unprivilegierte Clientports zulassen (oft als Exportoption „insecure“ bezeichnet). NFSv4 und UDP werden nicht unterstützt.',
			'sourceSetup.nfsSetupHelp' => 'Hilfe zur NFS-Einrichtung',
			'sourceSetup.nfsSetupHint' => 'Prüfe diese Einstellungen, wenn die Verbindung nicht zustande kommt.',
			'sourceSetup.nfsSetupDetails' => 'Verwende eine NFSv3-Freigabe über TCP. Wenn Verschlüsselung verlangt wird, müssen der NFS- und der Mount-Dienst beide RPC-with-TLS unterstützen. Lass das benutzerdefinierte Zertifikat leer, um ein Serverzertifikat zu verwenden, dem dieses Gerät vertraut, oder füge das CA- bzw. selbstsignierte Zertifikat des NAS hinzu. Der Zertifikatsname muss zum Host des Endpunkts passen. Verlangt das NAS gegenseitiges TLS, füge seine PKCS#12-Clientidentität hinzu. Prüfe abschließend, dass die Freigabe die eingestellten AUTH_SYS-UID/GID und die Clientport-Regeln zulässt.',
			'sourceSetup.ftpHelp' => 'FTP verwendet den passiven Modus. Nutze ftp:// für unverschlüsseltes FTP, ftpes:// für explizites TLS oder ftps:// für TLS (implizit auf Port 990, explizit auf anderen Ports).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Optionale Untertitelsuche für eigenständige Videos.',
			'sourceSetup.apiKey' => 'API-Schlüssel',
			'sourceSetup.optionalUsername' => 'Benutzername des Kontos (optional)',
			'sourceSetup.optionalPassword' => 'Passwort des Kontos (optional)',
			'sourceSetup.subtitlePrivacy' => 'Hole dir einen API-Schlüssel von opensubtitles.com. Die Suche sendet den Videotitel und verfügbare IMDb/TMDB-IDs, niemals die Videodatei. Der Schlüssel und optionale Kontozugangsdaten werden zusammen mit dieser Quelle verschlüsselt.',
			'sourceSetup.automaticMetadata' => 'Automatische Online-Videometadaten',
			'sourceSetup.metadataPrivacy' => 'Sendet nur Titel/Jahr aus dem Dateinamen und Episodennummern oder eine NFO-ID, niemals Medien oder Zugangsdaten. NFO-Felder behalten Vorrang.',
			'sourceSetup.nfsEncryptionFailure' => 'Prüfe für verschlüsseltes NFS die Unterstützung von RFC 9289 und TLS 1.3 bei beiden NAS-Diensten, den Zertifikatsnamen und die UID/GID der Freigabe. PlezyNG wird diese Verbindung nicht ohne Verschlüsselung erneut versuchen.',
			'sourceSetup.sourceConnecting' => 'Verbindung zur Quelle wird hergestellt',
			'sourceSetup.metadataSearchPrivacy' => 'Diese Titelsuche wird an Trakt gesendet. Übermittelt wird der eingegebene Titel, nicht das Video oder die Zugangsdaten der Quelle.',
			'sourceSetup.chooseMatch' => 'Treffer auswählen',
			'sourceSetup.metadataMatchHelp' => 'Prüfe Titel und Jahr vor der Auswahl. Trakt erhält den Suchbegriff; das Video bleibt auf seiner Quelle.',
			'sourceSetup.metadataNoMatches' => 'Keine passenden Titel online gefunden. Probiere einen anderen Titel.',
			'sourceSetup.metadataSearch' => 'Online-Metadaten suchen',
			'sourceSetup.metadataLoading' => 'Online-Details zu Filmen und Serien werden gesucht…',
			'sourceSetup.metadataFromTrakt' => 'Online-Metadaten von Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Kein automatischer Titeltreffer gefunden. Suche nach dem Titel, um einen Treffer auszuwählen.',
			'sourceSetup.metadataFailed' => 'Online-Metadaten konnten nicht geladen werden. Wiedergabe und lokale Details sind weiterhin verfügbar.',
			'sourceSetup.videoDetailsLoading' => 'Videodetails werden geladen',
			'sourceSetup.subtitleKeyRequired' => 'OpenSubtitles-API-Schlüssel erforderlich',
			'sourceSetup.subtitleKeyHelp' => 'Bearbeite diese Dateiquelle und füge in ihren optionalen Untertiteleinstellungen einen OpenSubtitles-API-Schlüssel hinzu.',
			'sourceSetup.subtitleSearchFailed' => 'Untertitelsuche fehlgeschlagen. Prüfe API-Schlüssel, Verbindung und Dienstzugriff.',
			'sourceSetup.subtitleApplyFailed' => 'Dieser Untertitel konnte nicht heruntergeladen oder angewendet werden. Prüfe deine Verbindung und versuche ein anderes Ergebnis.',
			'sourceSetup.subtitleSearch' => 'OpenSubtitles durchsuchen',
			'sourceSetup.subtitleSearchPrivacy' => 'Die Suche verwendet den Titel und verfügbare IMDb/TMDB-IDs. Die Videodatei bleibt auf ihrer Quelle. Prüfe vor der Auswahl Sprache, Kennzeichnungen für erzwungene oder hörgeschädigtengerechte Untertitel sowie die Bewertung.',
			'sourceSetup.movieOrShow' => 'Film oder Serie',
			'sourceSetup.subtitleTitleHint' => 'Titel eingeben, um die Ergebnisse einzugrenzen',
			'sourceSetup.subtitleLanguage' => 'Untertitelsprache',
			'sourceSetup.subtitleSearching' => 'OpenSubtitles wird durchsucht',
			'sourceSetup.subtitleNoMatches' => 'Keine passenden Untertitel gefunden. Probiere einen anderen Titel oder eine andere Sprache.',
			'sourceSetup.downloadSubtitle' => 'Untertitel herunterladen',
			'sourceSetup.subtitle' => 'Untertitel',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS erforderlich',
			'sourceSetup.nfsUnencrypted' => 'Unverschlüsseltes NFS',
			'sourceSetup.tlsEncrypted' => 'TLS-verschlüsselt',
			'sourceSetup.ftpPlain' => 'Unverschlüsseltes FTP',
			'sourceSetup.sshPinned' => 'SSH-verschlüsselt · Hostschlüssel festgelegt',
			'sourceSetup.smbEncrypted' => 'SMB3-Verschlüsselung an',
			'sourceSetup.smbUnencrypted' => 'SMB3-Verschlüsselung aus',
			'sourceSetup.httpUnencrypted' => 'HTTP ohne Transportverschlüsselung',
			'sourceSetup.checkEndpointSecurity' => 'Sicherheit des Endpunkts prüfen',
			'sourceSetup.fieldRequired' => ({required Object label}) => '${label} ist erforderlich.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Gib ${label} von ${min} bis ${max} ein.',
			'sourceSetup.replaceFile' => ({required Object name}) => '${name} ersetzen',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Ausgewählte Clientidentität: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Bewertung ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Untertitel wird heruntergeladen: ${title}',
			'sourceSetup.sharedEntryPair' => 'Paar dieses Element',
			'sourceSetup.sharedEntryPairHelp' => 'Geben Sie das gleiche ID für dieses Element auf jedem Gerät ein. Verwenden Sie einen stabilen geteilten Identifikator oder generieren Sie einen und kopieren Sie es zu dem matching item. Progress Pairs nur, wenn die Edition-Datei Typen, Größen und Ordnungen entsprechen. Blank entfernt diese Karte.',
			'sourceSetup.sharedEntryId' => 'Teilen von Element ID',
			'sourceSetup.generateSharedEntryId' => 'Erzeugen von gemeinsamen Element-ID',
			'sourceSetup.sharedLibraryId' => 'Gemeinsame Bibliothek-ID (optional)',
			'sourceSetup.sharedLibraryHelp' => 'Verwenden Sie das gleiche ID auf Geräten, die die gleiche Bibliothek öffnen. Dieses öffentliche ID hilft, den Leseprogramm und Notizen über verschiedene Quellverbindungen zu führen; es ist kein Passwort. Wenn Anbieter unterschiedliche Element-IDs verwenden, Paare diese Elemente aus ihren Detailbildschirmen.',
			'sourceSetup.sharedLibraryInvalid' => 'Verwenden Sie 8 bis 100 Buchstaben, Zahlen, Punkte, Unterschriften oder Hyphen.',
			'sourceSetup.generateSharedLibraryId' => 'Erstellen eines gemeinsamen Bibliothek-ID',
			'sourceSetup.nfsReadAhead' => 'NFS Read-ahead Anträge',
			'sourceSetup.nfsReadAheadHelp' => 'Mehr parallele Lesen kann den Durchgang auf einem schnellen NAS oder Netzwerk verbessern. Verwenden Sie 1 wenn der Server die gleichzeitigen Anfragen beschränkt.',
			'sourceSetup.nfsReadTest' => 'Messung NFS Lesenleistungen',
			'sourceSetup.nfsReadTestHelp' => 'Es liest bis zu 64 MiB von der größten Datei, um diese NAS-Verbindung zu messen.',
			'sourceSetup.nfsQualificationResult' => 'NFS Lesen Messungen',
			'sourceSetup.nfsReadBytes' => 'Daten lesen',
			'sourceSetup.nfsReadSpeed' => 'Messung der Geschwindigkeit',
			'sourceSetup.nfsReadRequests' => 'Lesen Sie Anfragen',
			'sourceSetup.sharedEntryConflict' => 'Dieses geteilte Element-ID wird bereits mit einem anderen Element in dieser Bibliothek vereinigt.',
			'comics.fitHeight' => 'An Höhe anpassen',
			'comics.readingMode' => 'Lesemodus',
			'comics.paged' => 'Seiten',
			'comics.webtoon' => 'Fortlaufendes Scrollen',
			'comics.coverAlone' => 'Cover einzeln anzeigen',
			'comics.splitWide' => 'Breite Seiten teilen',
			'comics.splitWideHelp' => 'Zeigt jede Hälfte einzeln in Leserichtung an. Solange dies aktiviert ist, werden Seiten nicht als Doppelseiten angezeigt.',
			'comics.thumbnails' => 'Seitenvorschauen',
			'comics.controlsHelp' => 'Zum Umblättern wischen. Doppeltippen ändert die Anpassung. Beim fortlaufenden Scrollen senkrecht wischen oder Bild auf und Bild ab verwenden.',
			'comics.savedForComic' => 'Die Anzeigeeinstellungen werden für diesen Comic in diesem Profil gespeichert.',
			'comics.readLists' => 'Leselisten',
			'comics.collections' => 'Sammlungen',
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
			_ => null,
		} ?? switch (path) {
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
			'deepLinks.invalid' => 'Dieser Plezy Link ist nicht gültig.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Kein Profil entspricht „${profile}“.',
			'deepLinks.serverUnavailable' => 'Ich konnte den Server für diesen Link nicht erreichen.',
			'deepLinks.notFound' => 'Ich konnte diesen Titel nicht in deinen Bibliotheken finden.',
			'deepLinks.unsupportedItem' => 'Dieser Link kann nicht gespielt werden.',
			'deepLinks.noLiveTv' => 'Kein Live TV-Server ist für diesen Link verfügbar.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Ich konnte kein Kanal "${channel}" finden.',
			'deepLinks.showLink' => 'zeigen Link',
			'deepLinks.showProfileLink' => 'Profil Link anzeigen',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Beim Öffnen dieses Links wird die nächste Folge abgespielt. Fügen Sie am Ende &mode=shuffle hinzu, um die Serie in zufälliger Reihenfolge abzuspielen.',
			'deepLinks.movieHint' => 'Der Link öffnet den Film.',
			'deepLinks.episodeHint' => 'Das Öffnen dieser Link spielt diese Episode.',
			'deepLinks.profileHint' => 'Öffnen dieser Link Switches zu diesem Profil.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Öffnen Sie als ${name}',
			'deepLinks.copy' => 'Kopieren',
			'deepLinks.copied' => 'Link kopiert',
			_ => null,
		};
	}
}
