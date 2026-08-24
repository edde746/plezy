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
	@override late final _Translations$auth$de auth = _Translations$auth$de._(_root);
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$screens$de screens = _Translations$screens$de._(_root);
	@override late final _Translations$update$de update = _Translations$update$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
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
}

// Path: app
class _Translations$app$de extends Translations$app$en {
	_Translations$app$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
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
	@override String get useQuickConnect => 'Quick Connect verwenden';
	@override String get quickConnectInstructions => 'Öffne Quick Connect in Jellyfin und gib diesen Code ein.';
	@override String get quickConnectWaiting => 'Warte auf Bestätigung…';
	@override String get quickConnectCancel => 'Abbrechen';
	@override String get quickConnectExpired => 'Quick Connect ist abgelaufen. Versuche es erneut.';
	@override String get localDataRecoveryRequired => 'Plezy konnte lokale Anmeldedaten und ausstehende Wiedergabedaten nicht sicher wiederherstellen. Bitte melde dich erneut an.';
	@override String get pinCheckRejected => 'Die Plex-PIN-Prüfung wurde abgelehnt';
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get close => 'Schließen';
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
	@override String get supportDeveloper => 'Plezy unterstützen';
	@override String get supportDeveloperDescription => 'Per Liberapay spenden, um die Entwicklung zu fördern';
	@override String get language => 'Sprache';
	@override String get theme => 'Design';
	@override String get appearance => 'Darstellung';
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
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Hell';
	@override String get darkTheme => 'Dunkel';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Darstellungsdichte der Mediathek';
	@override String get displayScale => 'Skalierung';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Großzügig';
	@override String get tvCornerSpotlightBackdrop => 'Backdrop in der Ecke';
	@override String get tvCornerSpotlightBackdropDescription => 'Zeigt das Spotlight-Artwork oben rechts statt bildschirmfüllend';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Empfehlungsbereich anzeigen';
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
	@override String get bufferSize => 'Puffergröße';
	@override String bufferSizeMB({required Object size}) => '${size} MB';
	@override String get bufferSizeAuto => 'Automatisch (empfohlen)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap} MB Speicher verfügbar. Ein Puffer von ${size} MB kann die Wiedergabe beeinträchtigen.';
	@override String get playbackBuffer => 'Wiedergabepuffer';
	@override String get playbackBufferAuto => 'Automatisch (empfohlen)';
	@override String get playbackBufferLarge => 'Groß';
	@override String get playbackBufferExtraLarge => 'Extra groß';
	@override String get playbackBufferDescription => 'Puffert mehr gegen instabile Verbindungen. Zusätzlich durch die Puffergröße begrenzt.';
	@override String get defaultQualityTitle => 'Standardqualität';
	@override String get musicQualityTitle => 'Musikqualität';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleines Sprungintervall';
	@override String get largeSkipDuration => 'Großes Sprungintervall';
	@override String get rewindOnResume => 'Zurückspulen bei Fortsetzung';
	@override String secondsUnit({required Object seconds}) => '${seconds} Sekunden';
	@override String get defaultSleepTimer => 'Standard-Schlaftimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} Minuten';
	@override String get rememberTrackSelections => 'Spurauswahl pro Serie/Film merken';
	@override String get rememberTrackSelectionsDescription => 'Audio- und Untertitelauswahl je Titel merken';
	@override String get followServerTrackSelections => 'Serverseitige Spurauswahl pro Episode verwenden';
	@override String get followServerTrackSelectionsDescription => 'Beim Episodenwechsel die auf dem Server ausgewählten Audio- und Untertitelspuren übernehmen, statt die aktuelle Auswahl zu übertragen';
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
	@override String get watchTogetherRelayDescription => 'Eigenes Relay festlegen. Alle müssen denselben Server verwenden.';
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
	@override String get importSettingsInvalidFile => 'Diese Datei ist kein gültiger Plezy-Einstellungsexport';
	@override String get importSettingsNoUser => 'Vor dem Import bitte anmelden';
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
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
	@override String get autoSkip => 'Automatisches Überspringen';
	@override String get autoSkipIntro => 'Intro automatisch überspringen';
	@override String get autoSkipIntroDescription => 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
	@override String get autoSkipCredits => 'Abspann automatisch überspringen';
	@override String get autoSkipCreditsDescription => 'Abspann automatisch überspringen und nächste Episode abspielen';
	@override String get forceSkipMarkerFallback => 'Ersatzmarkierungen erzwingen';
	@override String get forceSkipMarkerFallbackDescription => 'Kapitel-Titelmuster auch dann verwenden, wenn Plex über Markierungen verfügt';
	@override String get autoSkipDelay => 'Verzögerung für automatisches Überspringen';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
	@override String get introPattern => 'Intro-Markierungsmuster';
	@override String get introPatternDescription => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln';
	@override String get creditsPattern => 'Abspann-Markierungsmuster';
	@override String get creditsPatternDescription => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln';
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
	@override String get tunneledPlaybackDescription => 'Video-Tunneling verwenden. Deaktivieren, wenn HDR-Wiedergabe schwarzes Video zeigt.';
	@override String get audioPassthrough => 'Audio-Durchleitung';
	@override String get audioPassthroughDescription => 'Dolby/DTS-Audio ohne Neukodierung an deinen Receiver oder Fernseher senden und Surround-Sound erhalten. Deaktivieren, wenn kein Ton zu hören ist.';
	@override String get audioPassthroughDescriptionAppleTv => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. DTS und TrueHD werden weiterhin als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.';
	@override String get audioDownmix => 'Auf Stereo heruntermischen';
	@override String get audioDownmixDescription => 'Surround-Ton für Stereolautsprecher oder Kopfhörer auf zwei Kanäle heruntermischen';
	@override String get downmixCenterBoost => 'Verstärkung des Center-Kanals';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Verstärkung (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Lautstärke beim Downmix normalisieren';
	@override String get audioDownmixNormalizeDescription => 'Senkt den Mix ab, um Übersteuerung zu vermeiden. Deaktivieren, um die Originallautstärke zu behalten (laute Szenen können verzerren).';
	@override String get dvConversionMode => 'Dolby-Vision-Konvertierung';
	@override String get dvConversionModeDescription => 'Wähle, wie ExoPlayer Dateien mit Dolby-Vision-Profil 7 behandelt.';
	@override String get dvConversionAuto => 'Automatisch';
	@override String get dvConversionNative => 'Nativ / deaktiviert';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Gerätefähigkeiten erkennen und normales Fallback-Verhalten verwenden';
	@override String get dvConversionNativeDescription => 'Natives DV7 erzwingen und einen erneuten DV-Konvertierungsversuch unterdrücken';
	@override String get dvConversionDv81Description => 'Inline-RPU-Konvertierung in Dolby-Vision-Profil 8.1 erzwingen';
	@override String get dvConversionHevcStripDescription => 'Dolby-Vision-RPU/EL-Schichten entfernen und reines HEVC ausgeben';
	@override String get demuxer => 'Container-Demuxer';
	@override String get demuxerDescription => 'Welcher Demuxer direkt abgespielte Dateien einliest. Wechsle zu media3, wenn eine Datei Probleme macht.';
	@override String get demuxerFfmpeg => 'FFmpeg (empfohlen)';
	@override String get demuxerMedia3 => 'media3';
	@override String get requireProfileSelectionOnOpen => 'Profil beim Öffnen abfragen';
	@override String get requireProfileSelectionOnOpenDescription => 'Profilauswahl bei jedem Öffnen der App anzeigen';
	@override String get forceTvMode => 'TV-Modus erzwingen';
	@override String get forceTvModeDescription => 'TV-Layout erzwingen. Für Geräte ohne automatische Erkennung. Neustart erforderlich.';
	@override String get startInFullscreen => 'Im Vollbildmodus starten';
	@override String get startInFullscreenDescription => 'Plezy beim Start im Vollbildmodus öffnen';
	@override String get exitFullscreenOnPlayerClose => 'Vollbild beim Schließen des Players beenden';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Vollbildmodus automatisch beenden, wenn der Videoplayer geschlossen wird';
	@override String get autoHidePerformanceOverlay => 'Leistungsoverlay automatisch ausblenden';
	@override String get autoHidePerformanceOverlayDescription => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden';
	@override String get showNavBarLabels => 'Navigationsleisten-Beschriftungen anzeigen';
	@override String get showNavBarLabelsDescription => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen';
	@override String get startupSection => 'Startbereich';
	@override String get showExploreTab => 'Tab „Entdecken“ anzeigen';
	@override String get showExploreTabDescription => 'Zeigt den Tab „Entdecken“ mit Inhalten aus Plex Discover und verbundenen Trackern an';
	@override String get liveTvDefaultFavorites => 'Standardmäßig Favoritenkanäle';
	@override String get liveTvDefaultFavoritesDescription => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen';
	@override String get display => 'Anzeige';
	@override String get homeScreen => 'Startseite';
	@override String get navigation => 'Navigation';
	@override String get window => 'Fenster';
	@override String get content => 'Inhalt';
	@override String get player => 'Wiedergabe';
	@override String get subtitlesAndConfig => 'Untertitel und Konfiguration';
	@override String get seekAndTiming => 'Spulen & Timing';
	@override String get behavior => 'Verhalten';
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
	@override String get exportDialogTitle => 'Plezy-Einstellungen exportieren';
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
	@override String get flagDub => 'Dub';
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
		one: 'Dies löscht alle ${n} Folge darin sowie ihre Datei.',
		other: 'Dies löscht alle ${n} Folgen darin sowie ihre Dateien.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Dieses Element ist als ${n} Datei gespeichert, die gelöscht wird.',
		other: 'Dieses Element ist über ${n} Dateien verteilt gespeichert, die alle gelöscht werden.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} weitere Folge ist in derselben Datei gespeichert und wird ebenfalls gelöscht:',
		other: '${n} weitere Folgen sind in derselben Datei gespeichert und werden ebenfalls gelöscht:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy konnte nicht prüfen, welche Dateien dadurch entfernt werden. Es könnte also mehr gelöscht werden als das oben genannte Element. Brich ab und versuche es erneut, oder lösche trotzdem.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Dein Server hat für dieses Element keine Dateidetails bereitgestellt, daher kann Plezy nicht prüfen, welche Dateien entfernt werden. Es könnte mehr gelöscht werden als das oben genannte Element.';
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
	@override String get longPressToUnlock => 'Lange drücken zum Entsperren';
	@override String get timelineSlider => 'Videozeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String endsAt({required Object time}) => 'Endet um ${time}';
	@override String get pipActive => 'Wiedergabe im Bild-in-Bild-Modus';
	@override String get pipFailed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override String get screenshotSaved => 'Screenshot gespeichert';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
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
		one: 'Automatisch entfernt: ${n} angesehener Download',
		other: 'Automatisch entfernt: ${n} angesehene Downloads',
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
	@override String get logsUploaded => 'Protokolle hochgeladen';
	@override String get logsUploadFailed => 'Protokolle konnten nicht hochgeladen werden';
	@override String get logId => 'Protokoll-ID';
	@override String get burnedSubtitlesUseMenu => 'Die Untertitel sind in diesen Stream eingebrannt. Ändere sie über das Untertitelmenü.';
	@override String get noVideoUrl => 'Keine Video-URL verfügbar';
	@override String get playbackNoMediaSources => 'Der Server hat keine abspielbaren Medienquellen zurückgegeben';
	@override String get playbackDataNotPrepared => 'Die Wiedergabe wurde gestartet, bevor die Daten bereit waren';
	@override String get streamSelectionUnavailable => 'Die Streamauswahl ist für diese Quelle nicht verfügbar';
	@override String get streamSelectionFailed => 'Die ausgewählten Streams konnten nicht angewendet werden';
	@override String get serverUnavailableForProfile => 'Für das aktive Profil ist kein Server verfügbar';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$de extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
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
	@override String get anchorToScreen => 'Am Bildschirm verankern';
	@override String get anchorToScreenDescription => 'Textuntertitel in den schwarzen Balken unter Breitbildvideos anzeigen';
	@override String get bold => 'Fett';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Render-Auflösung';
	@override String get renderResolutionScreen => 'Bildschirmauflösung';
	@override String get renderResolutionVideo => 'Videoauflösung';
}

// Path: mpvConfig
class _Translations$mpvConfig$de extends Translations$mpvConfig$en {
	_Translations$mpvConfig$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv-Konfiguration';
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
	@override String get addPlezyProfile => 'Plezy-Profil hinzufügen';
	@override String get switchingProfile => 'Profil wird gewechselt…';
	@override String get deleteThisProfileTitle => 'Dieses Profil löschen?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} entfernen. Verbindungen bleiben unberührt.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Verwalten';
	@override String get delete => 'Löschen';
	@override String get signOut => 'Abmelden';
	@override String get signOutPlexTitle => 'Von Plex abmelden?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} und alle Plex Home-Benutzer entfernen? Du kannst dich jederzeit wieder anmelden.';
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
	@override String get borrowEmptySubtitle => 'Verbinde zuerst Plex oder Jellyfin mit einem anderen Profil.';
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
}

// Path: connections
class _Translations$connections$de extends Translations$connections$en {
	_Translations$connections$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Verbindungen';
	@override String get addConnection => 'Verbindung hinzufügen';
	@override String get addConnectionSubtitleNoProfile => 'Mit Plex anmelden oder mit einem Jellyfin-Server verbinden';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Zu ${displayName} hinzufügen: Plex, Jellyfin oder eine andere Profilverbindung';
	@override String sessionExpiredOne({required Object name}) => 'Sitzung für ${name} abgelaufen';
	@override String sessionExpiredMany({required Object count}) => 'Sitzungen für ${count} Server abgelaufen';
	@override String get signInAgain => 'Erneut anmelden';
	@override String editMediaBrowserTitle({required Object product}) => 'Verbindung zu ${product} bearbeiten';
	@override String editMediaBrowserIntro({required Object serverName}) => 'URLs für ${serverName} hinzufügen oder entfernen. Plezy verwendet die erreichbare URL mit der geringsten Latenz.';
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
		one: '${n} Titel',
		other: '${n} Titel',
	);
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
}

// Path: libraries
class _Translations$libraries$de extends Translations$libraries$en {
	_Translations$libraries$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
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
}

// Path: about
class _Translations$about$de extends Translations$about$en {
	_Translations$about$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über';
	@override String get openSourceLicenses => 'Open-Source-Lizenzen';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Ein schöner, mit Flutter entwickelter Plex- und Jellyfin-Client';
	@override String get viewLicensesDescription => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
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
}

// Path: startup
class _Translations$startup$de extends Translations$startup$en {
	_Translations$startup$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy konnte nicht gestartet werden';
	@override String get failedBody => 'Beim Start ist etwas schiefgelaufen. Die Details unten zeigen, was fehlgeschlagen ist.';
	@override String get failedBodyRepairable => 'Die gespeicherte Einstellungsdatei von Plezy ist beschädigt und muss neu aufgebaut werden, bevor Plezy starten kann. Erneutes Versuchen hilft nicht – wähle „Speicher reparieren“.';
	@override String get phaseLabel => 'Schritt';
	@override String get showDetails => 'Details anzeigen';
	@override String get hideDetails => 'Details ausblenden';
	@override String get copyDetails => 'Details kopieren';
	@override String get detailsCopied => 'Details in die Zwischenablage kopiert';
	@override String get uploadDetails => 'Details hochladen';
	@override String get repairStorage => 'Speicher reparieren';
	@override String get repairTitle => 'Gespeicherte Daten reparieren?';
	@override String get repairBodyCommon => 'Die Einstellungsdatei von Plezy ist beschädigt und kann nicht gelesen werden. Beim Reparieren werden alle Einstellungen auf ihre Standardwerte zurückgesetzt.';
	@override String get repairBodyOneCredential => 'Eine gespeicherte Anmeldung ist beschädigt und kann nicht gelesen werden. Beim Reparieren wird nur diese entfernt; deine übrigen Einstellungen bleiben unangetastet.';
	@override String get repairBodySignInsKept => 'Deine Server und Profile sollten angemeldet bleiben.';
	@override String get repairBodySignInsLost => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, kann aus dieser Datei nicht wiederhergestellt werden. Du musst dich daher bei jedem Server und Profil erneut anmelden. Auf deinem Medienserver ändert sich nichts.';
	@override String get repairBodySessionsUncertain => 'Tracker (MAL, AniList, Simkl, Trakt) und Seerr werden separat gespeichert und können erhalten bleiben oder auch nicht. Plezy teilt dir genau mit, was erhalten blieb.';
	@override String get repairConfirm => 'Reparieren';
	@override String get repairSucceeded => 'Speicher repariert';
	@override String get repairNeedsRestart => 'Speicher repariert – Neustart erforderlich';
	@override String get restartRequiredBody => 'Deine Daten wurden repariert, aber Plezy muss neu starten, bevor es sie verwenden kann. Schließe Plezy und öffne es erneut.';
	@override String get quitPlezy => 'Plezy beenden';
	@override String get repairFailed => 'Reparatur fehlgeschlagen';
	@override String get repairKeptSignIns => 'Deine Server und Profile sind weiterhin angemeldet.';
	@override String get repairLostSignIns => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, konnte nicht wiederhergestellt werden. Du musst dich bei jedem Server und Profil erneut anmelden.';
	@override String get repairLostSessions => 'Mindestens eine Tracker- oder Seerr-Verbindung ging verloren und muss neu verbunden werden.';
	@override String get backupTitle => 'Eine Kopie der beschädigten Datei wurde aufbewahrt';
	@override String get backupWarning => 'Sie enthält deine Anmeldedaten. Lade sie nicht hoch und teile sie nicht.';
	@override String get deleteBackup => 'Kopie löschen';
	@override String get backupDeleted => 'Kopie gelöscht.';
	@override String get previousFailureTitle => 'Plezy konnte beim letzten Mal nicht starten';
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
	@override String get title => 'Erkunden';
	@override String get selectSource => 'Quelle auswählen';
	@override late final _Translations$explore$rows$de rows = _Translations$explore$rows$de._(_root);
	@override late final _Translations$explore$status$de status = _Translations$explore$status$de._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Folge',
		other: '${n} Folgen',
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
		one: '${n} Ergebnis',
		other: '${n} Ergebnisse',
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
	@override String get unknownHub => 'Unbekannt';
	@override String get unknownError => 'Unbekannter Fehler';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Unbekannter Kanal';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'TV-Programm neu laden';
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
	@override String get rulesProcessRequested => 'Regelauswertung angefordert';
	@override String get recordShow => 'Sendung aufnehmen';
	@override late final _Translations$liveTv$recordSettings$de recordSettings = _Translations$liveTv$recordSettings$de._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Beginnt in ${minutes} Min.';
	@override String dayAtTime({required Object day, required Object time}) => '${day} um ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} hat ungültige Live-TV-Wiedergabedaten zurückgegeben';
	@override String get failedToStartChannel => 'Der Live-Sender konnte nicht gestartet werden';
	@override String get failedToBuildStreamUrl => 'Die Stream-URL konnte nicht erstellt werden';
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
	@override String itemCount({required Object count}) => '${count} Elemente';
	@override String get oneItem => '1 Element';
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
		one: '${n} Titel',
		other: '${n} Titel',
	);
	@override String get nowPlaying => 'Wird wiedergegeben';
	@override String playingFrom({required Object title}) => 'Wiedergabe von ${title}';
	@override String get queue => 'Warteschlange';
	@override String get clearQueue => 'Warteschlange leeren';
	@override String get lyrics => 'Songtext';
	@override String get noLyrics => 'Kein Songtext verfügbar';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get sleepTimerEndOfTrack => 'Ende des Titels';
	@override String sleepTimerMinutes({required Object n}) => '${n} Minuten';
	@override String get stopPlayback => 'Wiedergabe stoppen';
	@override String get previousTrack => 'Vorheriger Titel';
	@override String get nextTrack => 'Nächster Titel';
	@override String get repeat => 'Wiederholen';
	@override String get repeatAll => 'Alle wiederholen';
	@override String get repeatOne => 'Titel wiederholen';
	@override String get instantMixNoServer => 'Für einen Instant Mix ist kein Server verfügbar';
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
	@override String get createSession => 'Sitzung erstellen';
	@override String get creating => 'Wird erstellt …';
	@override String get joinSession => 'Sitzung beitreten';
	@override String get joining => 'Beitritt läuft …';
	@override String get controlMode => 'Steuerungsmodus';
	@override String get controlModeQuestion => 'Wer kann die Wiedergabe steuern?';
	@override String get hostOnly => 'Nur Host';
	@override String get anyone => 'Alle';
	@override String get hostingSession => 'Sitzung wird gehostet';
	@override String get inSession => 'In einer Sitzung';
	@override String get sessionCode => 'Sitzungscode';
	@override String get openSessionControls => 'Sitzungssteuerung für Gemeinsam Schauen öffnen';
	@override String get copySessionCode => 'Sitzungscode kopieren';
	@override String get hostControlsPlayback => 'Host steuert die Wiedergabe';
	@override String get anyoneCanControl => 'Alle können die Wiedergabe steuern';
	@override String get hostControls => 'Host steuert';
	@override String get anyoneControls => 'Alle steuern';
	@override String get participants => 'Teilnehmer';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Du bist der Host';
	@override String get watchingWithOthers => 'Mit anderen schauen';
	@override String get endSession => 'Sitzung beenden';
	@override String get leaveSession => 'Sitzung verlassen';
	@override String get endSessionQuestion => 'Sitzung beenden?';
	@override String get leaveSessionQuestion => 'Sitzung verlassen?';
	@override String get endSessionConfirm => 'Dies beendet die Sitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirm => 'Du wirst aus der Sitzung entfernt.';
	@override String get endSessionConfirmOverlay => 'Dies beendet die Schausitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirmOverlay => 'Du wirst von der Schausitzung getrennt.';
	@override String get end => 'Beenden';
	@override String get leave => 'Verlassen';
	@override String get syncing => 'Wird synchronisiert …';
	@override String get joinWatchSession => 'Schausitzung beitreten';
	@override String get enterCodeHint => '5-stelligen Code eingeben';
	@override String get pasteFromClipboard => 'Aus Zwischenablage einfügen';
	@override String get pleaseEnterCode => 'Bitte gib einen Sitzungscode ein';
	@override String get codeMustBe5Chars => 'Sitzungscode muss 5 Zeichen haben';
	@override String get joinInstructions => 'Gib den Sitzungscode des Hosts ein, um beizutreten.';
	@override String get failedToCreate => 'Sitzung konnte nicht erstellt werden';
	@override String get failedToJoin => 'Beitritt zur Sitzung fehlgeschlagen';
	@override String get sessionCodeCopied => 'Sitzungscode in Zwischenablage kopiert';
	@override String get relayUnreachable => 'Relay-Server nicht erreichbar. Eine Sperre durch den Internetanbieter kann gemeinsames Schauen verhindern.';
	@override String get reconnectingToHost => 'Verbindung zum Host wird wiederhergestellt …';
	@override String get currentPlayback => 'Aktuelle Wiedergabe';
	@override String get joinCurrentPlayback => 'Aktueller Wiedergabe beitreten';
	@override String get joinCurrentPlaybackDescription => 'Zu dem Inhalt wechseln, den der Host gerade ansieht';
	@override String get failedToOpenCurrentPlayback => 'Aktuelle Wiedergabe konnte nicht geöffnet werden';
	@override String participantJoined({required Object name}) => '${name} ist beigetreten';
	@override String participantLeft({required Object name}) => '${name} hat die Sitzung verlassen';
	@override String participantPaused({required Object name}) => '${name} hat pausiert';
	@override String participantResumed({required Object name}) => '${name} hat fortgesetzt';
	@override String participantSeeked({required Object name}) => '${name} hat die Wiedergabeposition geändert';
	@override String participantBuffering({required Object name}) => '${name} puffert';
	@override String participantNeedsUpdate({required Object name}) => '${name} verwendet eine ältere Appversion — Synchronisierung nicht verfügbar';
	@override String resumingWithout({required Object name}) => 'Fortfahren ohne ${name}';
	@override String get waitingForParticipants => 'Warten, bis die anderen bereit sind …';
	@override String waitingForName({required Object name}) => 'Warten auf ${name} …';
	@override String get recentRooms => 'Zuletzt verwendete Räume';
	@override String get renameRoom => 'Raum umbenennen';
	@override String get removeRoom => 'Entfernen';
	@override String get guestSwitchUnavailable => 'Wechsel fehlgeschlagen — Server nicht für Synchronisierung verfügbar';
	@override String get guestSwitchFailed => 'Wechsel fehlgeschlagen — Inhalt auf diesem Server nicht gefunden';
	@override String get defaultDisplayName => 'Benutzer';
	@override late final _Translations$watchTogether$errors$de errors = _Translations$watchTogether$errors$de._(_root);
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
	@override String get storageFull => 'Die Downloads wurden angehalten, weil der Gerätespeicher voll ist. Gib Speicherplatz frei und versuche es erneut.';
	@override String episodesQueued({required Object count}) => '${count} Episoden zum Download hinzugefügt';
	@override String get downloadDeleted => 'Download gelöscht';
	@override String deleteConfirm({required Object title}) => '"${title}" von diesem Gerät löschen?';
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
	@override String get deleteAll => 'Alle löschen';
	@override String get selectVersion => 'Version auswählen';
	@override String get allEpisodes => 'Alle Episoden';
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override String nextNUnwatched({required Object count}) => 'Nächste ${count} ungesehene';
	@override String get customAmount => 'Eigene Anzahl...';
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
	@override String get activeSyncRules => 'Synchronisierungsregeln';
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
	@override String get syncRuleNotAvailableForProfile => 'Für das aktuelle Profil nicht verfügbar';
	@override String get syncRuleUnknownServer => 'Unbekannter Server';
	@override String get syncRuleListCreated => 'Synchronisierungsregel erstellt';
	@override late final _Translations$downloads$backgroundWarning$de backgroundWarning = _Translations$downloads$backgroundWarning$de._(_root);
	@override String get unknownShow => 'Unbekannte Serie';
	@override String get unknownSeason => 'Unbekannte Staffel';
	@override String get unknownAlbum => 'Unbekanntes Album';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} abgeschlossen';
	@override String get errorFileNotFound => 'Datei nicht gefunden (404)';
	@override String get errorDownloadFailed => 'Download fehlgeschlagen';
	@override String errorPostProcessing({required Object error}) => 'Nachbearbeitung fehlgeschlagen: ${error}';
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
	@override String get audioNormalization => 'Lautstärke normalisieren';
	@override String get audioDownmix => 'Downmix auf Stereo';
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
	@override String get disconnectConfirmBody => 'Plezy sendet keine Ereignisse mehr an Trakt. Du kannst jederzeit erneut verbinden.';
	@override String get scrobble => 'Echtzeit-Scrobbling';
	@override String get scrobbleDescription => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.';
	@override String get watchedSync => 'Gesehen-Status synchronisieren';
	@override String get watchedSyncDescription => 'Wenn du Inhalte in Plezy als gesehen markierst, werden sie auch auf Trakt markiert.';
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
	@override String get noSignInMethods => 'Diese Seerr-Instanz bietet keine von Plezy unterstützte Anmeldemethode.';
	@override String get instance => 'Instanz';
	@override String get disconnectConfirm => 'Seerr trennen?';
	@override String get disconnectConfirmBody => 'Plezy vergisst diese Seerr-Instanz. Jederzeit erneut verbinden.';
	@override String get request => 'Anfragen';
	@override String get request4k => 'In 4K anfragen';
	@override String get seasons => 'Staffeln';
	@override String get allSeasons => 'Alle Staffeln';
	@override String get advancedOptions => 'Erweitert';
	@override String get destinationServer => 'Zielserver';
	@override String get qualityProfile => 'Qualitätsprofil';
	@override String get rootFolder => 'Stammordner';
	@override String get languageProfile => 'Sprachprofil';
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
	@override String get notInitialized => 'Die Ersteinrichtung dieser Seerr-Instanz wurde noch nicht abgeschlossen';
	@override String get noPlexTokenForReauth => 'Für die erneute Anmeldung ist kein Plex-Token verfügbar';
	@override String get noStoredCredentials => 'Für die erneute Anmeldung sind keine gespeicherten Anmeldedaten verfügbar';
	@override String get signInRejected => 'Die Anmeldung wurde abgelehnt';
	@override String get noSessionCookie => 'Seerr hat kein Sitzungscookie ausgestellt';
	@override String get freshCookieRejected => 'Seerr hat das neue Sitzungscookie abgelehnt';
	@override String get noUserInformation => 'Seerr hat keine Benutzerinformationen zurückgegeben';
	@override String get sessionRejectedAfterReauth => 'Die Sitzung wurde nach der erneuten Anmeldung abgelehnt';
}

// Path: services
class _Translations$services$de extends Translations$services$en {
	_Translations$services$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dienste';
	@override String get hubSubtitle => 'Wiedergabefortschritt synchronisieren und neue Titel anfragen.';
	@override String get notConnected => 'Nicht verbunden';
	@override String connectedAs({required Object username}) => 'Verbunden als @${username}';
	@override String get scrobble => 'Fortschritt automatisch verfolgen';
	@override String get scrobbleDescription => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.';
	@override String disconnectConfirm({required Object service}) => '${service} trennen?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy aktualisiert ${service} nicht mehr. Jederzeit erneut verbinden.';
	@override String connectFailed({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.';
	@override late final _Translations$services$names$de names = _Translations$services$names$de._(_root);
	@override late final _Translations$services$deviceCode$de deviceCode = _Translations$services$deviceCode$de._(_root);
	@override late final _Translations$services$oauthProxy$de oauthProxy = _Translations$services$oauthProxy$de._(_root);
	@override late final _Translations$services$pendingAuth$de pendingAuth = _Translations$services$pendingAuth$de._(_root);
	@override late final _Translations$services$libraryFilter$de libraryFilter = _Translations$services$libraryFilter$de._(_root);
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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$de extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Kritiker';
	@override String get audience => 'Publikum';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten-Tomatoes-Kritiker';
	@override String get rottenTomatoesAudience => 'Rotten-Tomatoes-Publikum';
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
	@override String get shaderToggle => 'Shader umschalten';
	@override String get skipMarker => 'Intro/Abspann überspringen';
	@override String get screenshot => 'Screenshot aufnehmen';
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
	@override String get premiereDate => 'Premierendatum';
	@override String get startDate => 'Startdatum';
	@override String get airTime => 'Sendezeit';
	@override String get studio => 'Studio';
	@override String get random => 'Zufällig';
	@override String get dateShared => 'Datum geteilt';
	@override String get latestEpisodeAirDate => 'Ausstrahlungsdatum der neuesten Folge';
	@override String get lastEpisodeDateAdded => 'Hinzugefügt am (neueste Folge)';
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
		one: '${n} Kommentar',
		other: '${n} Kommentare',
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
		one: 'Von ${n} Nutzer empfohlen',
		other: 'Von ${n} Nutzern empfohlen',
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

// Path: watchTogether.errors
class _Translations$watchTogether$errors$de extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get timedOut => 'Der Relay-Server hat nicht rechtzeitig geantwortet';
	@override String get connectionLost => 'Die Verbindung wurde geschlossen, bevor die Sitzung bereit war';
	@override String get invalidRelayResponse => 'Der Relay-Server hat eine unerwartete Antwort gesendet';
	@override String get sessionEnded => 'Der Host hat die Sitzung beendet';
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
	@override String get sheetIntro => 'Android verhindert, dass Plezy zuverlässig im Hintergrund herunterlädt.';
	@override String get sheetIntroDegraded => 'Dein Gerät schränkt ein, wann Plezy im Hintergrund herunterladen kann.';
	@override String get reasonBackgroundRestricted => 'Die Hintergrundnutzung von Plezy ist eingeschränkt. Stelle die Akku- oder Hintergrundnutzung auf „Uneingeschränkt“.';
	@override String get reasonStandbyRestricted => 'Android hat Plezy in einen eingeschränkten Standby-Modus versetzt. Stelle die Akkunutzung auf „Uneingeschränkt“.';
	@override String get reasonDownloadChannelBlocked => 'Download-Benachrichtigungen sind deaktiviert. Fortschritt und Steuerelemente sind daher möglicherweise nicht verfügbar.';
	@override String get reasonNotificationsDisabled => 'Benachrichtigungen sind deaktiviert. Ab Android 13 sind sie für lange Downloads im Hintergrund erforderlich.';
	@override String get reasonDataSaver => 'Der Datensparmodus ist aktiviert und blockiert Downloads im Hintergrund über mobile Daten. Über Wi-Fi sollten Downloads weiterhin funktionieren.';
	@override String get reasonOemUnknown => 'Downloads wurden wiederholt gestoppt, während Plezy im Hintergrund war. Prüfe die Einstellungen zur Akku- oder Hintergrundnutzung von Plezy.';
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
	@override String get discoveryDescription => 'Plezy-Geräte mit demselben Plex-Konto erscheinen hier';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Verbinden...';
	@override String get searchingForDevices => 'Suche nach Geräten...';
	@override String get noDevicesFound => 'Keine Geräte in deinem Netzwerk gefunden';
	@override String get noDevicesHint => 'Öffne Plezy auf dem Desktop und nutze dasselbe WLAN';
	@override String get availableDevices => 'Verfügbare Geräte';
	@override String get manualConnection => 'Manuelle Verbindung';
	@override String get cryptoInitFailed => 'Sichere Verbindung konnte nicht gestartet werden. Melde dich zuerst bei Plex an.';
	@override String get validationHostRequired => 'Bitte Host-Adresse eingeben';
	@override String get validationHostFormat => 'Format muss IP:Port sein (z. B. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Zeitüberschreitung bei der Verbindung. Nutze auf beiden Geräten dasselbe Netzwerk.';
	@override String get sessionNotFound => 'Gerät nicht gefunden. Stelle sicher, dass Plezy auf dem Host läuft.';
	@override String get authFailed => 'Authentifizierung fehlgeschlagen. Beide Geräte benötigen dasselbe Plex-Konto.';
	@override String failedToConnect({required Object error}) => 'Verbindung fehlgeschlagen: ${error}';
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

// Path: services.deviceCode
class _Translations$services$deviceCode$de extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy auf ${service} aktivieren';
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
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Mit Plex anmelden',
			'auth.showQRCode' => 'QR-Code anzeigen',
			'auth.authenticate' => 'Authentifizieren',
			'auth.authenticationTimeout' => 'Authentifizierung abgelaufen. Bitte erneut versuchen.',
			'auth.scanQRToSignIn' => 'Scanne diesen QR-Code, um dich anzumelden',
			'auth.waitingForAuth' => 'Warte auf die Authentifizierung …\nMelde dich über deinen Browser an.',
			'auth.useBrowser' => 'Browser verwenden',
			'auth.or' => 'oder',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Mit ${product} verbinden',
			'auth.useQuickConnect' => 'Quick Connect verwenden',
			'auth.quickConnectInstructions' => 'Öffne Quick Connect in Jellyfin und gib diesen Code ein.',
			'auth.quickConnectWaiting' => 'Warte auf Bestätigung…',
			'auth.quickConnectCancel' => 'Abbrechen',
			'auth.quickConnectExpired' => 'Quick Connect ist abgelaufen. Versuche es erneut.',
			'auth.localDataRecoveryRequired' => 'Plezy konnte lokale Anmeldedaten und ausstehende Wiedergabedaten nicht sicher wiederherstellen. Bitte melde dich erneut an.',
			'auth.pinCheckRejected' => 'Die Plex-PIN-Prüfung wurde abgelehnt',
			'common.cancel' => 'Abbrechen',
			'common.save' => 'Speichern',
			'common.close' => 'Schließen',
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
			'common.ratingSource.critic' => 'Kritiker',
			'common.ratingSource.audience' => 'Publikum',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten-Tomatoes-Kritiker',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten-Tomatoes-Publikum',
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
			'settings.supportDeveloper' => 'Plezy unterstützen',
			'settings.supportDeveloperDescription' => 'Per Liberapay spenden, um die Entwicklung zu fördern',
			'settings.language' => 'Sprache',
			'settings.theme' => 'Design',
			'settings.appearance' => 'Darstellung',
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
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Hell',
			'settings.darkTheme' => 'Dunkel',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Darstellungsdichte der Mediathek',
			'settings.displayScale' => 'Skalierung',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Großzügig',
			'settings.tvCornerSpotlightBackdrop' => 'Backdrop in der Ecke',
			'settings.tvCornerSpotlightBackdropDescription' => 'Zeigt das Spotlight-Artwork oben rechts statt bildschirmfüllend',
			'settings.viewMode' => 'Ansichtsmodus',
			'settings.gridView' => 'Raster',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Empfehlungsbereich anzeigen',
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
			'settings.bufferSize' => 'Puffergröße',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} MB',
			'settings.bufferSizeAuto' => 'Automatisch (empfohlen)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap} MB Speicher verfügbar. Ein Puffer von ${size} MB kann die Wiedergabe beeinträchtigen.',
			'settings.playbackBuffer' => 'Wiedergabepuffer',
			'settings.playbackBufferAuto' => 'Automatisch (empfohlen)',
			'settings.playbackBufferLarge' => 'Groß',
			'settings.playbackBufferExtraLarge' => 'Extra groß',
			'settings.playbackBufferDescription' => 'Puffert mehr gegen instabile Verbindungen. Zusätzlich durch die Puffergröße begrenzt.',
			'settings.defaultQualityTitle' => 'Standardqualität',
			'settings.musicQualityTitle' => 'Musikqualität',
			'settings.subtitleStyling' => 'Untertitel-Stil',
			'settings.subtitleStylingDescription' => 'Aussehen von Untertiteln anpassen',
			'settings.smallSkipDuration' => 'Kleines Sprungintervall',
			'settings.largeSkipDuration' => 'Großes Sprungintervall',
			'settings.rewindOnResume' => 'Zurückspulen bei Fortsetzung',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} Sekunden',
			'settings.defaultSleepTimer' => 'Standard-Schlaftimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} Minuten',
			'settings.rememberTrackSelections' => 'Spurauswahl pro Serie/Film merken',
			'settings.rememberTrackSelectionsDescription' => 'Audio- und Untertitelauswahl je Titel merken',
			'settings.followServerTrackSelections' => 'Serverseitige Spurauswahl pro Episode verwenden',
			'settings.followServerTrackSelectionsDescription' => 'Beim Episodenwechsel die auf dem Server ausgewählten Audio- und Untertitelspuren übernehmen, statt die aktuelle Auswahl zu übertragen',
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
			'settings.watchTogetherRelayDescription' => 'Eigenes Relay festlegen. Alle müssen denselben Server verwenden.',
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
			'settings.importSettingsInvalidFile' => 'Diese Datei ist kein gültiger Plezy-Einstellungsexport',
			'settings.importSettingsNoUser' => 'Vor dem Import bitte anmelden',
			'settings.shortcutsReset' => 'Tastenkürzel auf Standard zurückgesetzt',
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
			'settings.autoSkip' => 'Automatisches Überspringen',
			'settings.autoSkipIntro' => 'Intro automatisch überspringen',
			'settings.autoSkipIntroDescription' => 'Intro-Marker nach wenigen Sekunden automatisch überspringen',
			'settings.autoSkipCredits' => 'Abspann automatisch überspringen',
			'settings.autoSkipCreditsDescription' => 'Abspann automatisch überspringen und nächste Episode abspielen',
			'settings.forceSkipMarkerFallback' => 'Ersatzmarkierungen erzwingen',
			'settings.forceSkipMarkerFallbackDescription' => 'Kapitel-Titelmuster auch dann verwenden, wenn Plex über Markierungen verfügt',
			'settings.autoSkipDelay' => 'Verzögerung für automatisches Überspringen',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten',
			'settings.introPattern' => 'Intro-Markierungsmuster',
			'settings.introPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln',
			'settings.creditsPattern' => 'Abspann-Markierungsmuster',
			'settings.creditsPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln',
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
			'settings.tunneledPlaybackDescription' => 'Video-Tunneling verwenden. Deaktivieren, wenn HDR-Wiedergabe schwarzes Video zeigt.',
			'settings.audioPassthrough' => 'Audio-Durchleitung',
			'settings.audioPassthroughDescription' => 'Dolby/DTS-Audio ohne Neukodierung an deinen Receiver oder Fernseher senden und Surround-Sound erhalten. Deaktivieren, wenn kein Ton zu hören ist.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Apples nativen Dolby-Decoder für Dolby Digital Plus einschließlich Atmos verwenden. DTS und TrueHD werden weiterhin als Mehrkanal-PCM wiedergegeben. Deaktivieren, wenn kein Ton zu hören ist.',
			'settings.audioDownmix' => 'Auf Stereo heruntermischen',
			'settings.audioDownmixDescription' => 'Surround-Ton für Stereolautsprecher oder Kopfhörer auf zwei Kanäle heruntermischen',
			'settings.downmixCenterBoost' => 'Verstärkung des Center-Kanals',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Verstärkung (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Lautstärke beim Downmix normalisieren',
			'settings.audioDownmixNormalizeDescription' => 'Senkt den Mix ab, um Übersteuerung zu vermeiden. Deaktivieren, um die Originallautstärke zu behalten (laute Szenen können verzerren).',
			'settings.dvConversionMode' => 'Dolby-Vision-Konvertierung',
			'settings.dvConversionModeDescription' => 'Wähle, wie ExoPlayer Dateien mit Dolby-Vision-Profil 7 behandelt.',
			'settings.dvConversionAuto' => 'Automatisch',
			'settings.dvConversionNative' => 'Nativ / deaktiviert',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Gerätefähigkeiten erkennen und normales Fallback-Verhalten verwenden',
			'settings.dvConversionNativeDescription' => 'Natives DV7 erzwingen und einen erneuten DV-Konvertierungsversuch unterdrücken',
			'settings.dvConversionDv81Description' => 'Inline-RPU-Konvertierung in Dolby-Vision-Profil 8.1 erzwingen',
			'settings.dvConversionHevcStripDescription' => 'Dolby-Vision-RPU/EL-Schichten entfernen und reines HEVC ausgeben',
			'settings.demuxer' => 'Container-Demuxer',
			'settings.demuxerDescription' => 'Welcher Demuxer direkt abgespielte Dateien einliest. Wechsle zu media3, wenn eine Datei Probleme macht.',
			'settings.demuxerFfmpeg' => 'FFmpeg (empfohlen)',
			'settings.demuxerMedia3' => 'media3',
			'settings.requireProfileSelectionOnOpen' => 'Profil beim Öffnen abfragen',
			'settings.requireProfileSelectionOnOpenDescription' => 'Profilauswahl bei jedem Öffnen der App anzeigen',
			'settings.forceTvMode' => 'TV-Modus erzwingen',
			'settings.forceTvModeDescription' => 'TV-Layout erzwingen. Für Geräte ohne automatische Erkennung. Neustart erforderlich.',
			'settings.startInFullscreen' => 'Im Vollbildmodus starten',
			'settings.startInFullscreenDescription' => 'Plezy beim Start im Vollbildmodus öffnen',
			'settings.exitFullscreenOnPlayerClose' => 'Vollbild beim Schließen des Players beenden',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Vollbildmodus automatisch beenden, wenn der Videoplayer geschlossen wird',
			'settings.autoHidePerformanceOverlay' => 'Leistungsoverlay automatisch ausblenden',
			'settings.autoHidePerformanceOverlayDescription' => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden',
			'settings.showNavBarLabels' => 'Navigationsleisten-Beschriftungen anzeigen',
			'settings.showNavBarLabelsDescription' => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen',
			'settings.startupSection' => 'Startbereich',
			'settings.showExploreTab' => 'Tab „Entdecken“ anzeigen',
			'settings.showExploreTabDescription' => 'Zeigt den Tab „Entdecken“ mit Inhalten aus Plex Discover und verbundenen Trackern an',
			'settings.liveTvDefaultFavorites' => 'Standardmäßig Favoritenkanäle',
			'settings.liveTvDefaultFavoritesDescription' => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen',
			'settings.display' => 'Anzeige',
			'settings.homeScreen' => 'Startseite',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Fenster',
			'settings.content' => 'Inhalt',
			'settings.player' => 'Wiedergabe',
			'settings.subtitlesAndConfig' => 'Untertitel und Konfiguration',
			'settings.seekAndTiming' => 'Spulen & Timing',
			'settings.behavior' => 'Verhalten',
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
			'settings.exportDialogTitle' => 'Plezy-Einstellungen exportieren',
			'search.hint' => 'Filme, Serien und Musik suchen …',
			'search.tryDifferentTerm' => 'Anderen Suchbegriff versuchen',
			'search.searchYourMedia' => 'In den eigenen Medien suchen',
			'search.enterTitleActorOrKeyword' => 'Titel, Schauspieler oder Stichwort eingeben',
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
			'hotkeys.actions.shaderToggle' => 'Shader umschalten',
			'hotkeys.actions.skipMarker' => 'Intro/Abspann überspringen',
			'hotkeys.actions.screenshot' => 'Screenshot aufnehmen',
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
			'fileInfo.flagDub' => 'Dub',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Profil ${profile}',
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Dies löscht alle ${n} Folge darin sowie ihre Datei.', other: 'Dies löscht alle ${n} Folgen darin sowie ihre Dateien.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Dieses Element ist als ${n} Datei gespeichert, die gelöscht wird.', other: 'Dieses Element ist über ${n} Dateien verteilt gespeichert, die alle gelöscht werden.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} weitere Folge ist in derselben Datei gespeichert und wird ebenfalls gelöscht:', other: '${n} weitere Folgen sind in derselben Datei gespeichert und werden ebenfalls gelöscht:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy konnte nicht prüfen, welche Dateien dadurch entfernt werden. Es könnte also mehr gelöscht werden als das oben genannte Element. Brich ab und versuche es erneut, oder lösche trotzdem.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Dein Server hat für dieses Element keine Dateidetails bereitgestellt, daher kann Plezy nicht prüfen, welche Dateien entfernt werden. Es könnte mehr gelöscht werden als das oben genannte Element.',
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
			'videoControls.lockScreen' => 'Bildschirm sperren',
			'videoControls.screenLockButton' => 'Bildschirmsperre',
			'videoControls.longPressToUnlock' => 'Lange drücken zum Entsperren',
			'videoControls.timelineSlider' => 'Videozeitleiste',
			'videoControls.volumeSlider' => 'Lautstärkepegel',
			'videoControls.endsAt' => ({required Object time}) => 'Endet um ${time}',
			'videoControls.pipActive' => 'Wiedergabe im Bild-in-Bild-Modus',
			'videoControls.pipFailed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.screenshotSaved' => 'Screenshot gespeichert',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
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
			'messages.markedAsWatched' => 'Als gesehen markiert',
			'messages.markedAsUnwatched' => 'Als ungesehen markiert',
			'messages.markedAsWatchedOffline' => 'Als gesehen markiert (wird synchronisiert, wenn online)',
			'messages.markedAsUnwatchedOffline' => 'Als ungesehen markiert (wird synchronisiert, wenn online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisch entfernt: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Automatisch entfernt: ${n} angesehener Download', other: 'Automatisch entfernt: ${n} angesehene Downloads', ), 
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
			'messages.logsUploaded' => 'Protokolle hochgeladen',
			'messages.logsUploadFailed' => 'Protokolle konnten nicht hochgeladen werden',
			'messages.logId' => 'Protokoll-ID',
			'messages.burnedSubtitlesUseMenu' => 'Die Untertitel sind in diesen Stream eingebrannt. Ändere sie über das Untertitelmenü.',
			'messages.noVideoUrl' => 'Keine Video-URL verfügbar',
			'messages.playbackNoMediaSources' => 'Der Server hat keine abspielbaren Medienquellen zurückgegeben',
			'messages.playbackDataNotPrepared' => 'Die Wiedergabe wurde gestartet, bevor die Daten bereit waren',
			'messages.streamSelectionUnavailable' => 'Die Streamauswahl ist für diese Quelle nicht verfügbar',
			'messages.streamSelectionFailed' => 'Die ausgewählten Streams konnten nicht angewendet werden',
			'messages.serverUnavailableForProfile' => 'Für das aktive Profil ist kein Server verfügbar',
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
			'subtitlingStyling.anchorToScreen' => 'Am Bildschirm verankern',
			'subtitlingStyling.anchorToScreenDescription' => 'Textuntertitel in den schwarzen Balken unter Breitbildvideos anzeigen',
			'subtitlingStyling.bold' => 'Fett',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Render-Auflösung',
			'subtitlingStyling.renderResolutionScreen' => 'Bildschirmauflösung',
			'subtitlingStyling.renderResolutionVideo' => 'Videoauflösung',
			'mpvConfig.title' => 'mpv-Konfiguration',
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
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context und gpu-api werden unter Linux ignoriert: eingebettetes Video wird immer über vo=libmpv auf der Videoebene gerendert, und gpu-next (das Compute-Shader wie ArtCNN benötigen) kann nicht eingebettet ausgeführt werden.',
			'dialog.confirmAction' => 'Aktion bestätigen',
			'profiles.addPlezyProfile' => 'Plezy-Profil hinzufügen',
			'profiles.switchingProfile' => 'Profil wird gewechselt…',
			'profiles.deleteThisProfileTitle' => 'Dieses Profil löschen?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} entfernen. Verbindungen bleiben unberührt.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Verwalten',
			'profiles.delete' => 'Löschen',
			'profiles.signOut' => 'Abmelden',
			'profiles.signOutPlexTitle' => 'Von Plex abmelden?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} und alle Plex Home-Benutzer entfernen? Du kannst dich jederzeit wieder anmelden.',
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
			'profiles.borrowEmptySubtitle' => 'Verbinde zuerst Plex oder Jellyfin mit einem anderen Profil.',
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
			'connections.sectionTitle' => 'Verbindungen',
			'connections.addConnection' => 'Verbindung hinzufügen',
			'connections.addConnectionSubtitleNoProfile' => 'Mit Plex anmelden oder mit einem Jellyfin-Server verbinden',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Zu ${displayName} hinzufügen: Plex, Jellyfin oder eine andere Profilverbindung',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sitzung für ${name} abgelaufen',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sitzungen für ${count} Server abgelaufen',
			'connections.signInAgain' => 'Erneut anmelden',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Verbindung zu ${product} bearbeiten',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'URLs für ${serverName} hinzufügen oder entfernen. Plezy verwendet die erreichbare URL mit der geringsten Latenz.',
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
			'discover.extras' => 'Trailer & Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Altersfreigabe',
			'discover.director' => 'Regisseur',
			'discover.directors' => 'Regisseure',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie',
			'discover.minutesLeft' => ({required Object minutes}) => 'Noch ${minutes} Min.',
			'discover.moreLikeThis' => 'Ähnliche Inhalte',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Titel', other: '${n} Titel', ), 
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
			'libraries.sortLabels.premiereDate' => 'Premierendatum',
			'libraries.sortLabels.startDate' => 'Startdatum',
			'libraries.sortLabels.airTime' => 'Sendezeit',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Zufällig',
			'libraries.sortLabels.dateShared' => 'Datum geteilt',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Ausstrahlungsdatum der neuesten Folge',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Hinzugefügt am (neueste Folge)',
			'about.title' => 'Über',
			'about.openSourceLicenses' => 'Open-Source-Lizenzen',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Ein schöner, mit Flutter entwickelter Plex- und Jellyfin-Client',
			'about.viewLicensesDescription' => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen',
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
			'startup.failedTitle' => 'Plezy konnte nicht gestartet werden',
			'startup.failedBody' => 'Beim Start ist etwas schiefgelaufen. Die Details unten zeigen, was fehlgeschlagen ist.',
			'startup.failedBodyRepairable' => 'Die gespeicherte Einstellungsdatei von Plezy ist beschädigt und muss neu aufgebaut werden, bevor Plezy starten kann. Erneutes Versuchen hilft nicht – wähle „Speicher reparieren“.',
			'startup.phaseLabel' => 'Schritt',
			'startup.showDetails' => 'Details anzeigen',
			'startup.hideDetails' => 'Details ausblenden',
			'startup.copyDetails' => 'Details kopieren',
			'startup.detailsCopied' => 'Details in die Zwischenablage kopiert',
			'startup.uploadDetails' => 'Details hochladen',
			'startup.repairStorage' => 'Speicher reparieren',
			'startup.repairTitle' => 'Gespeicherte Daten reparieren?',
			'startup.repairBodyCommon' => 'Die Einstellungsdatei von Plezy ist beschädigt und kann nicht gelesen werden. Beim Reparieren werden alle Einstellungen auf ihre Standardwerte zurückgesetzt.',
			'startup.repairBodyOneCredential' => 'Eine gespeicherte Anmeldung ist beschädigt und kann nicht gelesen werden. Beim Reparieren wird nur diese entfernt; deine übrigen Einstellungen bleiben unangetastet.',
			'startup.repairBodySignInsKept' => 'Deine Server und Profile sollten angemeldet bleiben.',
			'startup.repairBodySignInsLost' => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, kann aus dieser Datei nicht wiederhergestellt werden. Du musst dich daher bei jedem Server und Profil erneut anmelden. Auf deinem Medienserver ändert sich nichts.',
			'startup.repairBodySessionsUncertain' => 'Tracker (MAL, AniList, Simkl, Trakt) und Seerr werden separat gespeichert und können erhalten bleiben oder auch nicht. Plezy teilt dir genau mit, was erhalten blieb.',
			'startup.repairConfirm' => 'Reparieren',
			'startup.repairSucceeded' => 'Speicher repariert',
			'startup.repairNeedsRestart' => 'Speicher repariert – Neustart erforderlich',
			'startup.restartRequiredBody' => 'Deine Daten wurden repariert, aber Plezy muss neu starten, bevor es sie verwenden kann. Schließe Plezy und öffne es erneut.',
			'startup.quitPlezy' => 'Plezy beenden',
			'startup.repairFailed' => 'Reparatur fehlgeschlagen',
			'startup.repairKeptSignIns' => 'Deine Server und Profile sind weiterhin angemeldet.',
			'startup.repairLostSignIns' => 'Der Schlüssel, der deine gespeicherten Anmeldungen schützt, konnte nicht wiederhergestellt werden. Du musst dich bei jedem Server und Profil erneut anmelden.',
			'startup.repairLostSessions' => 'Mindestens eine Tracker- oder Seerr-Verbindung ging verloren und muss neu verbunden werden.',
			'startup.backupTitle' => 'Eine Kopie der beschädigten Datei wurde aufbewahrt',
			'startup.backupWarning' => 'Sie enthält deine Anmeldedaten. Lade sie nicht hoch und teile sie nicht.',
			'startup.deleteBackup' => 'Kopie löschen',
			'startup.backupDeleted' => 'Kopie gelöscht.',
			'startup.previousFailureTitle' => 'Plezy konnte beim letzten Mal nicht starten',
			'licenses.relatedPackages' => 'Verwandte Pakete',
			'licenses.license' => 'Lizenz',
			'licenses.licenseNumber' => ({required Object number}) => 'Lizenz ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} Lizenzen',
			'navigation.libraries' => 'Mediatheken',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live-TV',
			'navigation.explore' => 'Erkunden',
			'explore.title' => 'Erkunden',
			'explore.selectSource' => 'Quelle auswählen',
			'explore.rows.watchlist' => 'Merkliste',
			'explore.rows.recommendedMovies' => 'Empfohlene Filme',
			'explore.rows.recommendedShows' => 'Empfohlene Serien',
			_ => null,
		} ?? switch (path) {
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Folge', other: '${n} Folgen', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Kommentar', other: '${n} Kommentare', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Von ${n} Nutzer empfohlen', other: 'Von ${n} Nutzern empfohlen', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Empfohlen von ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorisiert von ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} noch nicht ausgestrahlt',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Von ${percent} der Zuschauer empfohlen',
			'explore.detail.relatedTitles' => 'Verwandte Titel',
			'explore.detail.background' => 'Hintergrund',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Ergebnis', other: '${n} Ergebnisse', ), 
			'liveTv.title' => 'Live-TV',
			'liveTv.guide' => 'TV-Programm',
			'liveTv.noChannels' => 'Keine Kanäle verfügbar',
			'liveTv.noDvr' => 'Auf keinem Server ist ein DVR konfiguriert',
			'liveTv.serverUnavailable' => 'Der Live-TV-Server ist nicht verfügbar.',
			'liveTv.serverNotConnected' => 'Der Live-TV-Server ist nicht verbunden.',
			'liveTv.noPrograms' => 'Keine Programmdaten verfügbar',
			'liveTv.liveStreamFailed' => 'Livestream fehlgeschlagen',
			'liveTv.unknownProgram' => 'Unbekannte Sendung',
			'liveTv.unknownHub' => 'Unbekannt',
			'liveTv.unknownError' => 'Unbekannter Fehler',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Unbekannter Kanal',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'TV-Programm neu laden',
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
			'liveTv.rulesProcessRequested' => 'Regelauswertung angefordert',
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
			'playlists.itemCount' => ({required Object count}) => '${count} Elemente',
			'playlists.oneItem' => '1 Element',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Titel', other: '${n} Titel', ), 
			'music.nowPlaying' => 'Wird wiedergegeben',
			'music.playingFrom' => ({required Object title}) => 'Wiedergabe von ${title}',
			'music.queue' => 'Warteschlange',
			'music.clearQueue' => 'Warteschlange leeren',
			'music.lyrics' => 'Songtext',
			'music.noLyrics' => 'Kein Songtext verfügbar',
			'music.sleepTimer' => 'Schlaftimer',
			'music.sleepTimerEndOfTrack' => 'Ende des Titels',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} Minuten',
			'music.stopPlayback' => 'Wiedergabe stoppen',
			'music.previousTrack' => 'Vorheriger Titel',
			'music.nextTrack' => 'Nächster Titel',
			'music.repeat' => 'Wiederholen',
			'music.repeatAll' => 'Alle wiederholen',
			'music.repeatOne' => 'Titel wiederholen',
			'music.instantMixNoServer' => 'Für einen Instant Mix ist kein Server verfügbar',
			'music.noAudioUrl' => ({required Object track}) => 'Für ${track} ist keine Audio-URL verfügbar',
			'music.discography.singlesAndEps' => 'Singles & EPs',
			'music.discography.live' => 'Live',
			'music.discography.compilations' => 'Kompilationen',
			'watchTogether.title' => 'Gemeinsam Schauen',
			'watchTogether.description' => 'Inhalte synchron mit Freunden und Familie schauen',
			'watchTogether.createSession' => 'Sitzung erstellen',
			'watchTogether.creating' => 'Wird erstellt …',
			'watchTogether.joinSession' => 'Sitzung beitreten',
			'watchTogether.joining' => 'Beitritt läuft …',
			'watchTogether.controlMode' => 'Steuerungsmodus',
			'watchTogether.controlModeQuestion' => 'Wer kann die Wiedergabe steuern?',
			'watchTogether.hostOnly' => 'Nur Host',
			'watchTogether.anyone' => 'Alle',
			'watchTogether.hostingSession' => 'Sitzung wird gehostet',
			'watchTogether.inSession' => 'In einer Sitzung',
			'watchTogether.sessionCode' => 'Sitzungscode',
			'watchTogether.openSessionControls' => 'Sitzungssteuerung für Gemeinsam Schauen öffnen',
			'watchTogether.copySessionCode' => 'Sitzungscode kopieren',
			'watchTogether.hostControlsPlayback' => 'Host steuert die Wiedergabe',
			'watchTogether.anyoneCanControl' => 'Alle können die Wiedergabe steuern',
			'watchTogether.hostControls' => 'Host steuert',
			'watchTogether.anyoneControls' => 'Alle steuern',
			'watchTogether.participants' => 'Teilnehmer',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Du bist der Host',
			'watchTogether.watchingWithOthers' => 'Mit anderen schauen',
			'watchTogether.endSession' => 'Sitzung beenden',
			'watchTogether.leaveSession' => 'Sitzung verlassen',
			'watchTogether.endSessionQuestion' => 'Sitzung beenden?',
			'watchTogether.leaveSessionQuestion' => 'Sitzung verlassen?',
			'watchTogether.endSessionConfirm' => 'Dies beendet die Sitzung für alle Teilnehmer.',
			'watchTogether.leaveSessionConfirm' => 'Du wirst aus der Sitzung entfernt.',
			'watchTogether.endSessionConfirmOverlay' => 'Dies beendet die Schausitzung für alle Teilnehmer.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Du wirst von der Schausitzung getrennt.',
			'watchTogether.end' => 'Beenden',
			'watchTogether.leave' => 'Verlassen',
			'watchTogether.syncing' => 'Wird synchronisiert …',
			'watchTogether.joinWatchSession' => 'Schausitzung beitreten',
			'watchTogether.enterCodeHint' => '5-stelligen Code eingeben',
			'watchTogether.pasteFromClipboard' => 'Aus Zwischenablage einfügen',
			'watchTogether.pleaseEnterCode' => 'Bitte gib einen Sitzungscode ein',
			'watchTogether.codeMustBe5Chars' => 'Sitzungscode muss 5 Zeichen haben',
			'watchTogether.joinInstructions' => 'Gib den Sitzungscode des Hosts ein, um beizutreten.',
			'watchTogether.failedToCreate' => 'Sitzung konnte nicht erstellt werden',
			'watchTogether.failedToJoin' => 'Beitritt zur Sitzung fehlgeschlagen',
			'watchTogether.sessionCodeCopied' => 'Sitzungscode in Zwischenablage kopiert',
			'watchTogether.relayUnreachable' => 'Relay-Server nicht erreichbar. Eine Sperre durch den Internetanbieter kann gemeinsames Schauen verhindern.',
			'watchTogether.reconnectingToHost' => 'Verbindung zum Host wird wiederhergestellt …',
			'watchTogether.currentPlayback' => 'Aktuelle Wiedergabe',
			'watchTogether.joinCurrentPlayback' => 'Aktueller Wiedergabe beitreten',
			'watchTogether.joinCurrentPlaybackDescription' => 'Zu dem Inhalt wechseln, den der Host gerade ansieht',
			'watchTogether.failedToOpenCurrentPlayback' => 'Aktuelle Wiedergabe konnte nicht geöffnet werden',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} ist beigetreten',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} hat die Sitzung verlassen',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} hat pausiert',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} hat fortgesetzt',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} hat die Wiedergabeposition geändert',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} puffert',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} verwendet eine ältere Appversion — Synchronisierung nicht verfügbar',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Fortfahren ohne ${name}',
			'watchTogether.waitingForParticipants' => 'Warten, bis die anderen bereit sind …',
			'watchTogether.waitingForName' => ({required Object name}) => 'Warten auf ${name} …',
			'watchTogether.recentRooms' => 'Zuletzt verwendete Räume',
			'watchTogether.renameRoom' => 'Raum umbenennen',
			'watchTogether.removeRoom' => 'Entfernen',
			'watchTogether.guestSwitchUnavailable' => 'Wechsel fehlgeschlagen — Server nicht für Synchronisierung verfügbar',
			'watchTogether.guestSwitchFailed' => 'Wechsel fehlgeschlagen — Inhalt auf diesem Server nicht gefunden',
			'watchTogether.defaultDisplayName' => 'Benutzer',
			'watchTogether.errors.timedOut' => 'Der Relay-Server hat nicht rechtzeitig geantwortet',
			'watchTogether.errors.connectionLost' => 'Die Verbindung wurde geschlossen, bevor die Sitzung bereit war',
			'watchTogether.errors.invalidRelayResponse' => 'Der Relay-Server hat eine unerwartete Antwort gesendet',
			'watchTogether.errors.sessionEnded' => 'Der Host hat die Sitzung beendet',
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
			'downloads.storageFull' => 'Die Downloads wurden angehalten, weil der Gerätespeicher voll ist. Gib Speicherplatz frei und versuche es erneut.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} Episoden zum Download hinzugefügt',
			'downloads.downloadDeleted' => 'Download gelöscht',
			'downloads.deleteConfirm' => ({required Object title}) => '"${title}" von diesem Gerät löschen?',
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
			'downloads.deleteAll' => 'Alle löschen',
			'downloads.selectVersion' => 'Version auswählen',
			'downloads.allEpisodes' => 'Alle Episoden',
			'downloads.unwatchedOnly' => 'Nur ungesehene',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Nächste ${count} ungesehene',
			'downloads.customAmount' => 'Eigene Anzahl...',
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
			'downloads.activeSyncRules' => 'Synchronisierungsregeln',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Für das aktuelle Profil nicht verfügbar',
			'downloads.syncRuleUnknownServer' => 'Unbekannter Server',
			'downloads.syncRuleListCreated' => 'Synchronisierungsregel erstellt',
			'downloads.backgroundWarning.bannerBlocked' => 'Downloads werden gestoppt, wenn du die App verlässt',
			'downloads.backgroundWarning.bannerDegraded' => 'Downloads im Hintergrund sind möglicherweise eingeschränkt',
			'downloads.backgroundWarning.bannerAction' => 'Details',
			'downloads.backgroundWarning.sheetTitle' => 'Downloads im Hintergrund sind blockiert',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Downloads im Hintergrund sind möglicherweise eingeschränkt',
			'downloads.backgroundWarning.sheetIntro' => 'Android verhindert, dass Plezy zuverlässig im Hintergrund herunterlädt.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Dein Gerät schränkt ein, wann Plezy im Hintergrund herunterladen kann.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Die Hintergrundnutzung von Plezy ist eingeschränkt. Stelle die Akku- oder Hintergrundnutzung auf „Uneingeschränkt“.',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android hat Plezy in einen eingeschränkten Standby-Modus versetzt. Stelle die Akkunutzung auf „Uneingeschränkt“.',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Download-Benachrichtigungen sind deaktiviert. Fortschritt und Steuerelemente sind daher möglicherweise nicht verfügbar.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Benachrichtigungen sind deaktiviert. Ab Android 13 sind sie für lange Downloads im Hintergrund erforderlich.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Der Datensparmodus ist aktiviert und blockiert Downloads im Hintergrund über mobile Daten. Über Wi-Fi sollten Downloads weiterhin funktionieren.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Downloads wurden wiederholt gestoppt, während Plezy im Hintergrund war. Prüfe die Einstellungen zur Akku- oder Hintergrundnutzung von Plezy.',
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
			'downloads.unknownShow' => 'Unbekannte Serie',
			'downloads.unknownSeason' => 'Unbekannte Staffel',
			'downloads.unknownAlbum' => 'Unbekanntes Album',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} abgeschlossen',
			'downloads.errorFileNotFound' => 'Datei nicht gefunden (404)',
			'downloads.errorDownloadFailed' => 'Download fehlgeschlagen',
			'downloads.errorPostProcessing' => ({required Object error}) => 'Nachbearbeitung fehlgeschlagen: ${error}',
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
			'companionRemote.pairing.discoveryDescription' => 'Plezy-Geräte mit demselben Plex-Konto erscheinen hier',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Verbinden...',
			'companionRemote.pairing.searchingForDevices' => 'Suche nach Geräten...',
			'companionRemote.pairing.noDevicesFound' => 'Keine Geräte in deinem Netzwerk gefunden',
			'companionRemote.pairing.noDevicesHint' => 'Öffne Plezy auf dem Desktop und nutze dasselbe WLAN',
			'companionRemote.pairing.availableDevices' => 'Verfügbare Geräte',
			'companionRemote.pairing.manualConnection' => 'Manuelle Verbindung',
			'companionRemote.pairing.cryptoInitFailed' => 'Sichere Verbindung konnte nicht gestartet werden. Melde dich zuerst bei Plex an.',
			_ => null,
		} ?? switch (path) {
			'companionRemote.pairing.validationHostRequired' => 'Bitte Host-Adresse eingeben',
			'companionRemote.pairing.validationHostFormat' => 'Format muss IP:Port sein (z. B. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Zeitüberschreitung bei der Verbindung. Nutze auf beiden Geräten dasselbe Netzwerk.',
			'companionRemote.pairing.sessionNotFound' => 'Gerät nicht gefunden. Stelle sicher, dass Plezy auf dem Host läuft.',
			'companionRemote.pairing.authFailed' => 'Authentifizierung fehlgeschlagen. Beide Geräte benötigen dasselbe Plex-Konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Verbindung fehlgeschlagen: ${error}',
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
			'videoSettings.audioNormalization' => 'Lautstärke normalisieren',
			'videoSettings.audioDownmix' => 'Downmix auf Stereo',
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
			'trakt.disconnectConfirmBody' => 'Plezy sendet keine Ereignisse mehr an Trakt. Du kannst jederzeit erneut verbinden.',
			'trakt.scrobble' => 'Echtzeit-Scrobbling',
			'trakt.scrobbleDescription' => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.',
			'trakt.watchedSync' => 'Gesehen-Status synchronisieren',
			'trakt.watchedSyncDescription' => 'Wenn du Inhalte in Plezy als gesehen markierst, werden sie auch auf Trakt markiert.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Seerr verbinden',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Die Adresse deiner Seerr-Instanz',
			'seerr.checkServer' => 'Weiter',
			'seerr.signInWithJellyfin' => 'Mit Jellyfin anmelden',
			'seerr.signInWithEmby' => 'Mit Emby anmelden',
			'seerr.signInWithLocal' => 'Lokales Konto verwenden',
			'seerr.email' => 'E-Mail',
			'seerr.noSignInMethods' => 'Diese Seerr-Instanz bietet keine von Plezy unterstützte Anmeldemethode.',
			'seerr.instance' => 'Instanz',
			'seerr.disconnectConfirm' => 'Seerr trennen?',
			'seerr.disconnectConfirmBody' => 'Plezy vergisst diese Seerr-Instanz. Jederzeit erneut verbinden.',
			'seerr.request' => 'Anfragen',
			'seerr.request4k' => 'In 4K anfragen',
			'seerr.seasons' => 'Staffeln',
			'seerr.allSeasons' => 'Alle Staffeln',
			'seerr.advancedOptions' => 'Erweitert',
			'seerr.destinationServer' => 'Zielserver',
			'seerr.qualityProfile' => 'Qualitätsprofil',
			'seerr.rootFolder' => 'Stammordner',
			'seerr.languageProfile' => 'Sprachprofil',
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
			'seerr.notInitialized' => 'Die Ersteinrichtung dieser Seerr-Instanz wurde noch nicht abgeschlossen',
			'seerr.noPlexTokenForReauth' => 'Für die erneute Anmeldung ist kein Plex-Token verfügbar',
			'seerr.noStoredCredentials' => 'Für die erneute Anmeldung sind keine gespeicherten Anmeldedaten verfügbar',
			'seerr.signInRejected' => 'Die Anmeldung wurde abgelehnt',
			'seerr.noSessionCookie' => 'Seerr hat kein Sitzungscookie ausgestellt',
			'seerr.freshCookieRejected' => 'Seerr hat das neue Sitzungscookie abgelehnt',
			'seerr.noUserInformation' => 'Seerr hat keine Benutzerinformationen zurückgegeben',
			'seerr.sessionRejectedAfterReauth' => 'Die Sitzung wurde nach der erneuten Anmeldung abgelehnt',
			'services.title' => 'Dienste',
			'services.hubSubtitle' => 'Wiedergabefortschritt synchronisieren und neue Titel anfragen.',
			'services.notConnected' => 'Nicht verbunden',
			'services.connectedAs' => ({required Object username}) => 'Verbunden als @${username}',
			'services.scrobble' => 'Fortschritt automatisch verfolgen',
			'services.scrobbleDescription' => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.',
			'services.disconnectConfirm' => ({required Object service}) => '${service} trennen?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy aktualisiert ${service} nicht mehr. Jederzeit erneut verbinden.',
			'services.connectFailed' => ({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Plezy auf ${service} aktivieren',
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
			_ => null,
		};
	}
}
