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
class TranslationsDe with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppDe app = _TranslationsAppDe._(_root);
	@override late final _TranslationsAuthDe auth = _TranslationsAuthDe._(_root);
	@override late final _TranslationsCommonDe common = _TranslationsCommonDe._(_root);
	@override late final _TranslationsScreensDe screens = _TranslationsScreensDe._(_root);
	@override late final _TranslationsUpdateDe update = _TranslationsUpdateDe._(_root);
	@override late final _TranslationsSettingsDe settings = _TranslationsSettingsDe._(_root);
	@override late final _TranslationsSearchDe search = _TranslationsSearchDe._(_root);
	@override late final _TranslationsHotkeysDe hotkeys = _TranslationsHotkeysDe._(_root);
	@override late final _TranslationsFileInfoDe fileInfo = _TranslationsFileInfoDe._(_root);
	@override late final _TranslationsMediaMenuDe mediaMenu = _TranslationsMediaMenuDe._(_root);
	@override late final _TranslationsAccessibilityDe accessibility = _TranslationsAccessibilityDe._(_root);
	@override late final _TranslationsTooltipsDe tooltips = _TranslationsTooltipsDe._(_root);
	@override late final _TranslationsVideoControlsDe videoControls = _TranslationsVideoControlsDe._(_root);
	@override late final _TranslationsUserStatusDe userStatus = _TranslationsUserStatusDe._(_root);
	@override late final _TranslationsMessagesDe messages = _TranslationsMessagesDe._(_root);
	@override late final _TranslationsSubtitlingStylingDe subtitlingStyling = _TranslationsSubtitlingStylingDe._(_root);
	@override late final _TranslationsMpvConfigDe mpvConfig = _TranslationsMpvConfigDe._(_root);
	@override late final _TranslationsDialogDe dialog = _TranslationsDialogDe._(_root);
	@override late final _TranslationsDiscoverDe discover = _TranslationsDiscoverDe._(_root);
	@override late final _TranslationsErrorsDe errors = _TranslationsErrorsDe._(_root);
	@override late final _TranslationsLibrariesDe libraries = _TranslationsLibrariesDe._(_root);
	@override late final _TranslationsAboutDe about = _TranslationsAboutDe._(_root);
	@override late final _TranslationsServerSelectionDe serverSelection = _TranslationsServerSelectionDe._(_root);
	@override late final _TranslationsHubDetailDe hubDetail = _TranslationsHubDetailDe._(_root);
	@override late final _TranslationsLogsDe logs = _TranslationsLogsDe._(_root);
	@override late final _TranslationsLicensesDe licenses = _TranslationsLicensesDe._(_root);
	@override late final _TranslationsNavigationDe navigation = _TranslationsNavigationDe._(_root);
	@override late final _TranslationsLiveTvDe liveTv = _TranslationsLiveTvDe._(_root);
	@override late final _TranslationsCollectionsDe collections = _TranslationsCollectionsDe._(_root);
	@override late final _TranslationsPlaylistsDe playlists = _TranslationsPlaylistsDe._(_root);
	@override late final _TranslationsWatchTogetherDe watchTogether = _TranslationsWatchTogetherDe._(_root);
	@override late final _TranslationsDownloadsDe downloads = _TranslationsDownloadsDe._(_root);
	@override late final _TranslationsShadersDe shaders = _TranslationsShadersDe._(_root);
	@override late final _TranslationsCompanionRemoteDe companionRemote = _TranslationsCompanionRemoteDe._(_root);
	@override late final _TranslationsVideoSettingsDe videoSettings = _TranslationsVideoSettingsDe._(_root);
	@override late final _TranslationsExternalPlayerDe externalPlayer = _TranslationsExternalPlayerDe._(_root);
	@override late final _TranslationsMetadataEditDe metadataEdit = _TranslationsMetadataEditDe._(_root);
	@override late final _TranslationsMatchScreenDe matchScreen = _TranslationsMatchScreenDe._(_root);
	@override late final _TranslationsServerTasksDe serverTasks = _TranslationsServerTasksDe._(_root);
	@override late final _TranslationsTraktDe trakt = _TranslationsTraktDe._(_root);
	@override late final _TranslationsTrackersDe trackers = _TranslationsTrackersDe._(_root);
}

// Path: app
class _TranslationsAppDe implements TranslationsAppEn {
	_TranslationsAppDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthDe implements TranslationsAuthEn {
	_TranslationsAuthDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mit Plex anmelden';
	@override String get showQRCode => 'QR-Code anzeigen';
	@override String get authenticate => 'Authentifizieren';
	@override String get authenticationTimeout => 'Authentifizierung abgelaufen. Bitte erneut versuchen.';
	@override String get scanQRToSignIn => 'QR-Code scannen zum Anmelden';
	@override String get waitingForAuth => 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.';
	@override String get useBrowser => 'Browser verwenden';
}

// Path: common
class _TranslationsCommonDe implements TranslationsCommonEn {
	_TranslationsCommonDe._(this._root);

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
	@override String get shuffle => 'Zufall';
	@override String get addTo => 'Hinzufügen zu...';
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
	@override String get settings => 'Optionen';
	@override String get mute => 'Stumm';
	@override String get ok => 'OK';
	@override String get reconnect => 'Erneut verbinden';
	@override String get exitConfirmTitle => 'App beenden?';
	@override String get exitConfirmMessage => 'Möchtest du die App wirklich beenden?';
	@override String get dontAskAgain => 'Nicht erneut fragen';
	@override String get exit => 'Beenden';
	@override String get viewAll => 'Alle anzeigen';
	@override String get checkingNetwork => 'Netzwerk wird geprüft...';
	@override String get refreshingServers => 'Server werden aktualisiert...';
	@override String get loadingServers => 'Server werden geladen...';
	@override String get connectingToServers => 'Verbindung zu Servern...';
	@override String get startingOfflineMode => 'Offlinemodus wird gestartet...';
	@override String get loading => 'Laden...';
	@override String get fullscreen => 'Vollbild';
	@override String get exitFullscreen => 'Vollbild verlassen';
}

// Path: screens
class _TranslationsScreensDe implements TranslationsScreensEn {
	_TranslationsScreensDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lizenzen';
	@override String get switchProfile => 'Profil wechseln';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Protokolle';
}

// Path: update
class _TranslationsUpdateDe implements TranslationsUpdateEn {
	_TranslationsUpdateDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get available => 'Update verfügbar';
	@override String versionAvailable({required Object version}) => 'Version ${version} ist verfügbar';
	@override String currentVersion({required Object version}) => 'Aktuell: ${version}';
	@override String get skipVersion => 'Diese Version überspringen';
	@override String get viewRelease => 'Release anzeigen';
	@override String get latestVersion => 'Aktuellste Version installiert';
	@override String get checkFailed => 'Fehler bei der Updateprüfung';
}

// Path: settings
class _TranslationsSettingsDe implements TranslationsSettingsEn {
	_TranslationsSettingsDe._(this._root);

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
	@override String get episodePosterMode => 'Episoden-Poster-Stil';
	@override String get seriesPoster => 'Serienposter';
	@override String get seasonPoster => 'Staffelposter';
	@override String get episodeThumbnail => 'Miniatur';
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
	@override String get libraryDensity => 'Mediathekdichte';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Großzügig';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Hero-Bereich anzeigen';
	@override String get useGlobalHubs => 'Plex-Startseiten-Layout verwenden';
	@override String get useGlobalHubsDescription => 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.';
	@override String get showServerNameOnHubs => 'Servername bei Hubs anzeigen';
	@override String get showServerNameOnHubsDescription => 'Zeigt immer den Servernamen in Hub-Titeln an. Wenn deaktiviert, nur bei doppelten Hub-Namen.';
	@override String get groupLibrariesByServer => 'Mediatheken nach Server gruppieren';
	@override String get groupLibrariesByServerDescription => 'Zeigt eine Überschrift für jeden Plex-Server in der Seitenleiste an, wenn du mit mehreren Servern verbunden bist.';
	@override String get alwaysKeepSidebarOpen => 'Seitenleiste immer geöffnet halten';
	@override String get alwaysKeepSidebarOpenDescription => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an';
	@override String get showUnwatchedCount => 'Anzahl nicht gesehener Folgen anzeigen';
	@override String get showUnwatchedCountDescription => 'Zeigt die Anzahl nicht gesehener Episoden bei Serien und Staffeln an';
	@override String get showEpisodeNumberOnCards => 'Episodennummer auf Karten anzeigen';
	@override String get showEpisodeNumberOnCardsDescription => 'Episodennummer neben der Staffel (z. B. S2 E3) auf Episodenkarten anzeigen';
	@override String get hideSpoilers => 'Spoiler für nicht gesehene Episoden verbergen';
	@override String get hideSpoilersDescription => 'Vorschaubilder unscharf machen und Beschreibungen für noch nicht gesehene Episoden ausblenden';
	@override String get playerBackend => 'Player-Backend';
	@override String get exoPlayer => 'ExoPlayer (Empfohlen)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardware-Decodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, sofern verfügbar';
	@override String get bufferSize => 'Puffergröße';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Empfohlen)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Ihr Gerät hat ${heap}MB Speicher. Ein ${size}MB-Puffer kann Wiedergabeprobleme verursachen.';
	@override String get defaultQualityTitle => 'Standardqualität';
	@override String get defaultQualityDescription => 'Wird beim Starten der Wiedergabe verwendet. Niedrigere Werte reduzieren die Bandbreite.';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleine Sprungdauer';
	@override String get largeSkipDuration => 'Große Sprungdauer';
	@override String get rewindOnResume => 'Zurückspulen bei Fortsetzung';
	@override String secondsUnit({required Object seconds}) => '${seconds} Sekunden';
	@override String get defaultSleepTimer => 'Standard-Sleep-Timer';
	@override String minutesUnit({required Object minutes}) => '${minutes} Minuten';
	@override String get rememberTrackSelections => 'Spurauswahl pro Serie/Film merken';
	@override String get rememberTrackSelectionsDescription => 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert';
	@override String get clickVideoTogglesPlayback => 'Klicken Sie auf das Video, um die Wiedergabe zu starten oder zu pausieren.';
	@override String get clickVideoTogglesPlaybackDescription => 'Wenn diese Option aktiviert ist, wird durch Klicken auf den Videoplayer die Wiedergabe gestartet oder pausiert. Andernfalls werden durch Klicken die Wiedergabesteuerungen ein- oder ausgeblendet.';
	@override String get videoPlayerControls => 'Videoplayer-Steuerung';
	@override String get keyboardShortcuts => 'Tastenkürzel';
	@override String get keyboardShortcutsDescription => 'Tastenkürzel anpassen';
	@override String get videoPlayerNavigation => 'Videoplayer-Navigation';
	@override String get videoPlayerNavigationDescription => 'Pfeiltasten zur Navigation der Videoplayer-Steuerung verwenden';
	@override String get watchTogetherRelay => 'Gemeinsam Schauen Relay';
	@override String get watchTogetherRelayDescription => 'Einen benutzerdefinierten Relay-Server für Gemeinsam Schauen festlegen. Alle Teilnehmer müssen denselben Server verwenden.';
	@override String get watchTogetherRelayHint => 'https://mein-relay.beispiel.de';
	@override String get crashReporting => 'Absturzberichte';
	@override String get crashReportingDescription => 'Absturzberichte senden, um die App zu verbessern';
	@override String get debugLogging => 'Debug-Protokollierung';
	@override String get debugLoggingDescription => 'Detaillierte Protokolle zur Fehleranalyse aktivieren';
	@override String get viewLogs => 'Protokolle anzeigen';
	@override String get viewLogsDescription => 'App-Protokolle anzeigen';
	@override String get clearCache => 'Cache löschen';
	@override String get clearCacheDescription => 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.';
	@override String get clearCacheSuccess => 'Cache erfolgreich gelöscht';
	@override String get resetSettings => 'Einstellungen zurücksetzen';
	@override String get resetSettingsDescription => 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.';
	@override String get resetSettingsSuccess => 'Einstellungen erfolgreich zurückgesetzt';
	@override String get backup => 'Sicherung';
	@override String get exportSettings => 'Einstellungen exportieren';
	@override String get exportSettingsDescription => 'Speichere deine Einstellungen in einer Datei';
	@override String get exportSettingsSuccess => 'Einstellungen exportiert';
	@override String get exportSettingsFailed => 'Einstellungen konnten nicht exportiert werden';
	@override String get importSettings => 'Einstellungen importieren';
	@override String get importSettingsDescription => 'Einstellungen aus einer Datei wiederherstellen';
	@override String get importSettingsConfirm => 'Dies ersetzt deine aktuellen Einstellungen. Fortfahren?';
	@override String get importSettingsSuccess => 'Einstellungen importiert';
	@override String get importSettingsFailed => 'Einstellungen konnten nicht importiert werden';
	@override String get importSettingsInvalidFile => 'Diese Datei ist kein gültiger Plezy-Einstellungsexport';
	@override String get importSettingsNoUser => 'Vor dem Import bitte anmelden';
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
	@override String get about => 'Über';
	@override String get aboutDescription => 'App-Informationen und Lizenzen';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update verfügbar';
	@override String get checkForUpdates => 'Nach Updates suchen';
	@override String get autoCheckUpdatesOnStartup => 'Beim Start automatisch nach Updates suchen';
	@override String get autoCheckUpdatesOnStartupDescription => 'Benachrichtigung anzeigen, wenn beim Start eine neue Version verfügbar ist';
	@override String get validationErrorEnterNumber => 'Bitte eine gültige Zahl eingeben';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}';
	@override String shortcutUpdated({required Object action}) => 'Tastenkürzel aktualisiert für ${action}';
	@override String get autoSkip => 'Automatisches Überspringen';
	@override String get autoSkipIntro => 'Intro automatisch überspringen';
	@override String get autoSkipIntroDescription => 'Intro-Marker nach wenigen Sekunden automatisch überspringen';
	@override String get autoSkipCredits => 'Abspann automatisch überspringen';
	@override String get autoSkipCreditsDescription => 'Abspann automatisch überspringen und nächste Episode abspielen';
	@override String get autoSkipDelay => 'Verzögerung für automatisches Überspringen';
	@override String autoSkipDelayDescription({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten';
	@override String get introPattern => 'Intro-Markierungsmuster';
	@override String get introPatternDescription => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln';
	@override String get creditsPattern => 'Abspann-Markierungsmuster';
	@override String get creditsPatternDescription => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln';
	@override String get invalidRegex => 'Ungültiger regulärer Ausdruck';
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
	@override String get downloadLocationSelectError => 'Ordnerauswahl fehlgeschlagen';
	@override String get downloadOnWifiOnly => 'Nur über WLAN herunterladen';
	@override String get downloadOnWifiOnlyDescription => 'Downloads über mobile Daten verhindern';
	@override String get autoRemoveWatchedDownloads => 'Gesehene Downloads automatisch entfernen';
	@override String get autoRemoveWatchedDownloadsDescription => 'Heruntergeladene Episoden und Filme automatisch löschen, wenn sie als gesehen markiert werden';
	@override String get cellularDownloadBlocked => 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.';
	@override String get maxVolume => 'Maximale Lautstärke';
	@override String get maxVolumeDescription => 'Lautstärke über 100% für leise Medien erlauben';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Zeige auf Discord, was du gerade schaust';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Wiedergabeverlauf mit Trakt synchronisieren';
	@override String get trackers => 'Tracker';
	@override String get trackersDescription => 'Fortschritt mit Trakt, MyAnimeList, AniList und Simkl synchronisieren';
	@override String get companionRemoteServer => 'Companion Remote Server';
	@override String get companionRemoteServerDescription => 'Mobilgeräten in deinem Netzwerk erlauben, diese App zu steuern';
	@override String get autoPip => 'Automatisches Bild-in-Bild';
	@override String get autoPipDescription => 'Automatisch Bild-in-Bild aktivieren, wenn die App während der Wiedergabe verlassen wird';
	@override String get matchContentFrameRate => 'Inhalts-Bildrate anpassen';
	@override String get matchContentFrameRateDescription => 'Bildwiederholfrequenz des Displays an den Videoinhalt anpassen, reduziert Ruckeln und spart Akku';
	@override String get matchRefreshRate => 'Bildwiederholrate anpassen';
	@override String get matchRefreshRateDescription => 'Bildwiederholrate des Displays an den Videoinhalt im Vollbildmodus anpassen';
	@override String get matchDynamicRange => 'Dynamikumfang anpassen';
	@override String get matchDynamicRangeDescription => 'HDR für HDR-Inhalte automatisch aktivieren und beim Verlassen des Players auf SDR zurücksetzen';
	@override String get displaySwitchDelay => 'Verzögerung beim Displaywechsel';
	@override String get tunneledPlayback => 'Tunnelwiedergabe';
	@override String get tunneledPlaybackDescription => 'Hardware-beschleunigte Video-Tunnelierung verwenden. Deaktivieren, wenn bei HDR-Inhalten ein schwarzer Bildschirm mit Ton erscheint';
	@override String get requireProfileSelectionOnOpen => 'Profil beim Öffnen abfragen';
	@override String get requireProfileSelectionOnOpenDescription => 'Profilauswahl bei jedem Öffnen der App anzeigen';
	@override String get confirmExitOnBack => 'Vor dem Beenden bestätigen';
	@override String get confirmExitOnBackDescription => 'Bestätigungsdialog anzeigen, wenn Zurück zum Beenden der App gedrückt wird';
	@override String get forceTvMode => 'TV-Modus erzwingen';
	@override String get forceTvModeDescription => 'TV-Layout unabhängig von der automatischen Erkennung verwenden. Nützlich für Android-TV-Geräte, die das Leanback-Feature nicht melden. Startet die App bei Änderung neu.';
	@override String get startInFullscreen => 'Im Vollbildmodus starten';
	@override String get startInFullscreenDescription => 'Plezy beim Start im Vollbildmodus öffnen';
	@override String get autoHidePerformanceOverlay => 'Leistungsoverlay automatisch ausblenden';
	@override String get autoHidePerformanceOverlayDescription => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden';
	@override String get showNavBarLabels => 'Navigationsleisten-Beschriftungen anzeigen';
	@override String get showNavBarLabelsDescription => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen';
	@override String get liveTvDefaultFavorites => 'Standardmäßig Favoritenkanäle';
	@override String get liveTvDefaultFavoritesDescription => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen';
	@override String get display => 'Display';
	@override String get homeScreen => 'Home Screen';
	@override String get navigation => 'Navigation';
	@override String get window => 'Window';
	@override String get content => 'Content';
	@override String get player => 'Player';
	@override String get subtitlesAndConfig => 'Subtitles & Configuration';
	@override String get seekAndTiming => 'Seek & Timing';
	@override String get behavior => 'Behavior';
}

// Path: search
class _TranslationsSearchDe implements TranslationsSearchEn {
	_TranslationsSearchDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Filme, Serien, Musik suchen...';
	@override String get tryDifferentTerm => 'Anderen Suchbegriff versuchen';
	@override String get searchYourMedia => 'In den eigenen Medien suchen';
	@override String get enterTitleActorOrKeyword => 'Titel, Schauspieler oder Stichwort eingeben';
}

// Path: hotkeys
class _TranslationsHotkeysDe implements TranslationsHotkeysEn {
	_TranslationsHotkeysDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}';
	@override String get clearShortcut => 'Kürzel löschen';
	@override late final _TranslationsHotkeysActionsDe actions = _TranslationsHotkeysActionsDe._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoDe implements TranslationsFileInfoEn {
	_TranslationsFileInfoDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Dateiinfo';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get file => 'Datei';
	@override String get advanced => 'Erweitert';
	@override String get codec => 'Codec';
	@override String get resolution => 'Auflösung';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildrate';
	@override String get aspectRatio => 'Seitenverhältnis';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Farbtiefe';
	@override String get colorSpace => 'Farbraum';
	@override String get colorRange => 'Farbbereich';
	@override String get colorPrimaries => 'Primärfarben';
	@override String get chromaSubsampling => 'Chroma-Subsampling';
	@override String get channels => 'Kanäle';
	@override String get subtitles => 'Untertitel';
	@override String get overallBitrate => 'Gesamt-Bitrate';
	@override String get path => 'Pfad';
	@override String get size => 'Größe';
	@override String get container => 'Container';
	@override String get duration => 'Dauer';
	@override String get optimizedForStreaming => 'Für Streaming optimiert';
	@override String get has64bitOffsets => '64-Bit-Offsets';
}

// Path: mediaMenu
class _TranslationsMediaMenuDe implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
	@override String get removeFromContinueWatching => 'Aus ‚Weiterschauen‘ entfernen';
	@override String get goToSeries => 'Zur Serie';
	@override String get goToSeason => 'Zur Staffel';
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get fileInfo => 'Dateiinfo';
	@override String get deleteFromServer => 'Vom Server löschen';
	@override String get confirmDelete => 'Dieses Medium und seine Dateien werden dauerhaft von Ihrem Server gelöscht. Dies kann nicht rückgängig gemacht werden.';
	@override String get deleteMultipleWarning => 'Dies umfasst alle Episoden und deren Dateien.';
	@override String get mediaDeletedSuccessfully => 'Medienelement erfolgreich gelöscht';
	@override String get mediaFailedToDelete => 'Löschen des Medienelements fehlgeschlagen';
	@override String get rate => 'Bewerten';
	@override String get playFromBeginning => 'Von Anfang an abspielen';
	@override String get playVersion => 'Version abspielen...';
}

// Path: accessibility
class _TranslationsAccessibilityDe implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, Film';
	@override String mediaCardShow({required Object title}) => '${title}, Serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'angesehen';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} Prozent angesehen';
	@override String get mediaCardUnwatched => 'ungeschaut';
	@override String get tapToPlay => 'Zum Abspielen tippen';
}

// Path: tooltips
class _TranslationsTooltipsDe implements TranslationsTooltipsEn {
	_TranslationsTooltipsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Zufallswiedergabe';
	@override String get playTrailer => 'Trailer abspielen';
	@override String get markAsWatched => 'Als gesehen markieren';
	@override String get markAsUnwatched => 'Als ungesehen markieren';
}

// Path: videoControls
class _TranslationsVideoControlsDe implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Untertitel';
	@override String get resetToZero => 'Auf 0 ms zurücksetzen';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spielt später';
	@override String playsEarlier({required Object label}) => '${label} spielt früher';
	@override String get noOffset => 'Kein Offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Bild füllen';
	@override String get stretch => 'Strecken';
	@override String get lockRotation => 'Rotation sperren';
	@override String get unlockRotation => 'Rotation entsperren';
	@override String get timerActive => 'Schlaftimer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
	@override String get stillWatching => 'Schaust du noch?';
	@override String pausingIn({required Object seconds}) => 'Pause in ${seconds}s';
	@override String get continueWatching => 'Weiter';
	@override String get autoPlayNext => 'Nächstes automatisch abspielen';
	@override String get playNext => 'Nächstes abspielen';
	@override String get playButton => 'Wiedergeben';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => '${seconds} Sekunden zurück';
	@override String seekForwardButton({required Object seconds}) => '${seconds} Sekunden vor';
	@override String get previousButton => 'Vorherige Episode';
	@override String get nextButton => 'Nächste Episode';
	@override String get previousChapterButton => 'Vorheriges Kapitel';
	@override String get nextChapterButton => 'Nächstes Kapitel';
	@override String get muteButton => 'Stumm schalten';
	@override String get unmuteButton => 'Stummschaltung aufheben';
	@override String get settingsButton => 'Videoeinstellungen';
	@override String get tracksButton => 'Audio und Untertitel';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversionen';
	@override String get versionQualityButton => 'Version & Qualität';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Qualität';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkodierung nicht verfügbar — Wiedergabe in Originalqualität';
	@override String get pipButton => 'Bild-in-Bild Modus';
	@override String get aspectRatioButton => 'Seitenverhältnis';
	@override String get ambientLighting => 'Umgebungsbeleuchtung';
	@override String get fullscreenButton => 'Vollbild aktivieren';
	@override String get exitFullscreenButton => 'Vollbild verlassen';
	@override String get alwaysOnTopButton => 'Immer im Vordergrund';
	@override String get rotationLockButton => 'Dreh­sperre';
	@override String get lockScreen => 'Bildschirm sperren';
	@override String get screenLockButton => 'Bildschirmsperre';
	@override String get longPressToUnlock => 'Lange drücken zum Entsperren';
	@override String get timelineSlider => 'Video-Zeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String endsAt({required Object time}) => 'Endet um ${time}';
	@override String get pipActive => 'Wiedergabe im Bild-in-Bild-Modus';
	@override String get pipFailed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override late final _TranslationsVideoControlsPipErrorsDe pipErrors = _TranslationsVideoControlsPipErrorsDe._(_root);
	@override String get chapters => 'Kapitel';
	@override String get noChaptersAvailable => 'Keine Kapitel verfügbar';
	@override String get queue => 'Warteschlange';
	@override String get noQueueItems => 'Keine Elemente in der Warteschlange';
	@override String get searchSubtitles => 'Untertitel suchen';
	@override String get language => 'Sprache';
	@override String get noSubtitlesFound => 'Keine Untertitel gefunden';
	@override String get subtitleDownloaded => 'Untertitel heruntergeladen';
	@override String get subtitleDownloadFailed => 'Untertitel konnte nicht heruntergeladen werden';
	@override String get searchLanguages => 'Sprachen suchen...';
}

// Path: userStatus
class _TranslationsUserStatusDe implements TranslationsUserStatusEn {
	_TranslationsUserStatusDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Eigentümer';
	@override String get restricted => 'Eingeschränkt';
	@override String get protected => 'Geschützt';
	@override String get current => 'AKTUELL';
}

// Path: messages
class _TranslationsMessagesDe implements TranslationsMessagesEn {
	_TranslationsMessagesDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Als gesehen markiert';
	@override String get markedAsUnwatched => 'Als ungesehen markiert';
	@override String get markedAsWatchedOffline => 'Als gesehen markiert (wird synchronisiert, wenn online)';
	@override String get markedAsUnwatchedOffline => 'Als ungesehen markiert (wird synchronisiert, wenn online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisch entfernt: ${title}';
	@override String get removedFromContinueWatching => 'Aus ‚Weiterschauen\' entfernt';
	@override String errorLoading({required Object error}) => 'Fehler: ${error}';
	@override String get fileInfoNotAvailable => 'Dateiinfo nicht verfügbar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
	@override String get errorLoadingSeries => 'Fehler beim Laden der Serie';
	@override String get errorLoadingSeason => 'Fehler beim Laden der Staffel';
	@override String get musicNotSupported => 'Musikwiedergabe wird noch nicht unterstützt';
	@override String get noDescriptionAvailable => 'Keine Beschreibung verfügbar';
	@override String get noProfilesAvailable => 'Keine Profile verfügbar';
	@override String get contactAdminForProfiles => 'Kontaktiere deinen Plex-Administrator, um Profile hinzuzufügen';
	@override String get unableToDetermineLibrarySection => 'Bibliotheksbereich für dieses Element kann nicht ermittelt werden';
	@override String get logsCleared => 'Protokolle gelöscht';
	@override String get logsCopied => 'Protokolle in Zwischenablage kopiert';
	@override String get noLogsAvailable => 'Keine Protokolle verfügbar';
	@override String libraryScanning({required Object title}) => 'Scanne „${title}“...';
	@override String libraryScanStarted({required Object title}) => 'Mediathekscan gestartet für „${title}“';
	@override String libraryScanFailed({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“';
	@override String metadataRefreshFailed({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}';
	@override String get logoutConfirm => 'Abmeldung wirklich durchführen?';
	@override String get noSeasonsFound => 'Keine Staffeln gefunden';
	@override String get noEpisodesFound => 'Keine Episoden in der ersten Staffel gefunden';
	@override String get noEpisodesFoundGeneral => 'Keine Episoden gefunden';
	@override String get noResultsFound => 'Keine Ergebnisse gefunden';
	@override String sleepTimerSet({required Object label}) => 'Sleep-Timer gesetzt auf ${label}';
	@override String get noItemsAvailable => 'Keine Elemente verfügbar';
	@override String get failedToCreatePlayQueueNoItems => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
	@override String failedPlayback({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
	@override String get switchingToCompatiblePlayer => 'Wechsle zu kompatiblem Player...';
	@override String get serverLimitTitle => 'Wiedergabe fehlgeschlagen';
	@override String get serverLimitBody => 'Der Server hat einen Fehler zurückgegeben (HTTP 500). Das bedeutet meist, dass der Serverbesitzer ein Bandbreiten- oder Transcoding-Limit festgelegt hat, das deine Sitzung ablehnt. Vom Client aus lässt sich nichts machen — der Serverbesitzer muss seine Einstellungen anpassen.';
	@override String get logsUploaded => 'Protokolle hochgeladen';
	@override String get logsUploadFailed => 'Protokolle konnten nicht hochgeladen werden';
	@override String get logId => 'Protokoll-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingDe implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingDe._(this._root);

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
	@override String get bold => 'Fett';
	@override String get italic => 'Kursiv';
}

// Path: mpvConfig
class _TranslationsMpvConfigDe implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv-Konfiguration';
	@override String get description => 'Erweiterte Videoplayer-Einstellungen';
	@override String get presets => 'Voreinstellungen';
	@override String get noPresets => 'Keine gespeicherten Voreinstellungen';
	@override String get saveAsPreset => 'Als Voreinstellung speichern...';
	@override String get presetName => 'Name der Voreinstellung';
	@override String get presetNameHint => 'Namen für diese Voreinstellung eingeben';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Löschen';
	@override String get presetSaved => 'Voreinstellung gespeichert';
	@override String get presetLoaded => 'Voreinstellung geladen';
	@override String get presetDeleted => 'Voreinstellung gelöscht';
	@override String get confirmDeletePreset => 'Möchten Sie diese Voreinstellung wirklich löschen?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogDe implements TranslationsDialogEn {
	_TranslationsDialogDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
}

// Path: discover
class _TranslationsDiscoverDe implements TranslationsDiscoverEn {
	_TranslationsDiscoverDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entdecken';
	@override String get switchProfile => 'Profil wechseln';
	@override String get noContentAvailable => 'Kein Inhalt verfügbar';
	@override String get addMediaToLibraries => 'Medien zur Mediathek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override String get extras => 'Trailer & Extras';
	@override String get studio => 'Studio';
	@override String get rating => 'Altersfreigabe';
	@override String get movie => 'Film';
	@override String get tvShow => 'Serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} Min übrig';
}

// Path: errors
class _TranslationsErrorsDe implements TranslationsErrorsEn {
	_TranslationsErrorsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Suche fehlgeschlagen: ${error}';
	@override String connectionTimeout({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}';
	@override String get connectionFailed => 'Verbindung zum Plex-Server fehlgeschlagen';
	@override String failedToLoad({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}';
	@override String get noClientAvailable => 'Kein Client verfügbar';
	@override String authenticationFailed({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}';
	@override String get couldNotLaunchUrl => 'Auth-URL konnte nicht geöffnet werden';
	@override String get pleaseEnterToken => 'Bitte Token eingeben';
	@override String get invalidToken => 'Ungültiges Token';
	@override String failedToVerifyToken({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen';
}

// Path: libraries
class _TranslationsLibrariesDe implements TranslationsLibrariesEn {
	_TranslationsLibrariesDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mediatheken';
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
	@override String get all => 'Alle';
	@override String get clearAll => 'Alle löschen';
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
	@override String get content => 'Bibliotheksinhalt';
	@override String get selectLibrary => 'Bibliothek auswählen';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Keine Empfehlungen verfügbar';
	@override String get noCollections => 'Keine Sammlungen in dieser Mediathek';
	@override String get noFoldersFound => 'Keine Ordner gefunden';
	@override String get folders => 'Ordner';
	@override late final _TranslationsLibrariesTabsDe tabs = _TranslationsLibrariesTabsDe._(_root);
	@override late final _TranslationsLibrariesGroupingsDe groupings = _TranslationsLibrariesGroupingsDe._(_root);
}

// Path: about
class _TranslationsAboutDe implements TranslationsAboutEn {
	_TranslationsAboutDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über';
	@override String get openSourceLicenses => 'Open-Source-Lizenzen';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Ein schöner Plex-Client für Flutter';
	@override String get viewLicensesDescription => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen';
}

// Path: serverSelection
class _TranslationsServerSelectionDe implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Server konnten nicht geladen werden: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailDe implements TranslationsHubDetailEn {
	_TranslationsHubDetailDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Erscheinungsjahr';
	@override String get dateAdded => 'Hinzugefügt am';
	@override String get rating => 'Bewertung';
	@override String get noItemsFound => 'Keine Elemente gefunden';
}

// Path: logs
class _TranslationsLogsDe implements TranslationsLogsEn {
	_TranslationsLogsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Protokolle löschen';
	@override String get copyLogs => 'Protokolle kopieren';
	@override String get uploadLogs => 'Protokolle hochladen';
}

// Path: licenses
class _TranslationsLicensesDe implements TranslationsLicensesEn {
	_TranslationsLicensesDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Verwandte Pakete';
	@override String get license => 'Lizenz';
	@override String licenseNumber({required Object number}) => 'Lizenz ${number}';
	@override String licensesCount({required Object count}) => '${count} Lizenzen';
}

// Path: navigation
class _TranslationsNavigationDe implements TranslationsNavigationEn {
	_TranslationsNavigationDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Medien';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'Live-TV';
}

// Path: liveTv
class _TranslationsLiveTvDe implements TranslationsLiveTvEn {
	_TranslationsLiveTvDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-TV';
	@override String get guide => 'Programmführer';
	@override String get noChannels => 'Keine Kanäle verfügbar';
	@override String get noDvr => 'Kein DVR auf einem Server konfiguriert';
	@override String get noPrograms => 'Keine Programmdaten verfügbar';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'Programmführer neu laden';
	@override String get now => 'Jetzt';
	@override String get today => 'Heute';
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
	@override String get joinSession => 'Laufender Sitzung beitreten';
	@override String watchFromStart({required Object minutes}) => 'Von Anfang an ansehen (vor ${minutes} Min.)';
	@override String get watchLive => 'Live ansehen';
	@override String get goToLive => 'Zum Live-Bild';
}

// Path: collections
class _TranslationsCollectionsDe implements TranslationsCollectionsEn {
	_TranslationsCollectionsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sammlungen';
	@override String get collection => 'Sammlung';
	@override String get empty => 'Sammlung ist leer';
	@override String get unknownLibrarySection => 'Löschen nicht möglich: Unbekannte Bibliothekssektion';
	@override String get deleteCollection => 'Sammlung löschen';
	@override String deleteConfirm({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.';
	@override String get deleted => 'Sammlung gelöscht';
	@override String get deleteFailed => 'Sammlung konnte nicht gelöscht werden';
	@override String deleteFailedWithError({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}';
	@override String get selectCollection => 'Sammlung auswählen';
	@override String get collectionName => 'Sammlungsname';
	@override String get enterCollectionName => 'Sammlungsnamen eingeben';
	@override String get addedToCollection => 'Zur Sammlung hinzugefügt';
	@override String get errorAddingToCollection => 'Fehler beim Hinzufügen zur Sammlung';
	@override String get created => 'Sammlung erstellt';
	@override String get removeFromCollection => 'Aus Sammlung entfernen';
	@override String removeFromCollectionConfirm({required Object title}) => '"${title}" aus dieser Sammlung entfernen?';
	@override String get removedFromCollection => 'Aus Sammlung entfernt';
	@override String get removeFromCollectionFailed => 'Entfernen aus Sammlung fehlgeschlagen';
	@override String removeFromCollectionError({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}';
	@override String get searchCollections => 'Sammlungen durchsuchen...';
}

// Path: playlists
class _TranslationsPlaylistsDe implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsDe._(this._root);

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
	@override String deleteMessage({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?';
	@override String get created => 'Wiedergabeliste erstellt';
	@override String get deleted => 'Wiedergabeliste gelöscht';
	@override String get itemAdded => 'Zur Wiedergabeliste hinzugefügt';
	@override String get itemRemoved => 'Aus Wiedergabeliste entfernt';
	@override String get selectPlaylist => 'Wiedergabeliste auswählen';
	@override String get errorCreating => 'Wiedergabeliste konnte nicht erstellt werden';
	@override String get errorDeleting => 'Wiedergabeliste konnte nicht gelöscht werden';
	@override String get errorLoading => 'Wiedergabelisten konnten nicht geladen werden';
	@override String get errorAdding => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
	@override String get errorReordering => 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
	@override String get errorRemoving => 'Konnte nicht aus der Wiedergabeliste entfernt werden';
}

// Path: watchTogether
class _TranslationsWatchTogetherDe implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gemeinsam Schauen';
	@override String get description => 'Inhalte synchron mit Freunden und Familie schauen';
	@override String get createSession => 'Sitzung Erstellen';
	@override String get creating => 'Erstellen...';
	@override String get joinSession => 'Sitzung Beitreten';
	@override String get joining => 'Beitreten...';
	@override String get controlMode => 'Steuerungsmodus';
	@override String get controlModeQuestion => 'Wer kann die Wiedergabe steuern?';
	@override String get hostOnly => 'Nur Host';
	@override String get anyone => 'Alle';
	@override String get hostingSession => 'Sitzung Hosten';
	@override String get inSession => 'In Sitzung';
	@override String get sessionCode => 'Sitzungscode';
	@override String get hostControlsPlayback => 'Host steuert die Wiedergabe';
	@override String get anyoneCanControl => 'Alle können die Wiedergabe steuern';
	@override String get hostControls => 'Host steuert';
	@override String get anyoneControls => 'Alle steuern';
	@override String get participants => 'Teilnehmer';
	@override String get host => 'Host';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Du bist der Host';
	@override String get watchingWithOthers => 'Mit anderen schauen';
	@override String get endSession => 'Sitzung Beenden';
	@override String get leaveSession => 'Sitzung Verlassen';
	@override String get endSessionQuestion => 'Sitzung Beenden?';
	@override String get leaveSessionQuestion => 'Sitzung Verlassen?';
	@override String get endSessionConfirm => 'Dies beendet die Sitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirm => 'Du wirst aus der Sitzung entfernt.';
	@override String get endSessionConfirmOverlay => 'Dies beendet die Schausitzung für alle Teilnehmer.';
	@override String get leaveSessionConfirmOverlay => 'Du wirst von der Schausitzung getrennt.';
	@override String get end => 'Beenden';
	@override String get leave => 'Verlassen';
	@override String get syncing => 'Synchronisieren...';
	@override String get joinWatchSession => 'Schausitzung Beitreten';
	@override String get enterCodeHint => '5-stelligen Code eingeben';
	@override String get pasteFromClipboard => 'Aus Zwischenablage einfügen';
	@override String get pleaseEnterCode => 'Bitte gib einen Sitzungscode ein';
	@override String get codeMustBe5Chars => 'Sitzungscode muss 5 Zeichen haben';
	@override String get joinInstructions => 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.';
	@override String get failedToCreate => 'Sitzung konnte nicht erstellt werden';
	@override String get failedToJoin => 'Sitzung konnte nicht beigetreten werden';
	@override String get sessionCodeCopied => 'Sitzungscode in Zwischenablage kopiert';
	@override String get relayUnreachable => 'Der Relay-Server ist nicht erreichbar. Möglicherweise blockiert dein Internetanbieter die Verbindung. Du kannst es trotzdem versuchen, aber Watch Together funktioniert eventuell nicht.';
	@override String get reconnectingToHost => 'Verbindung zum Host wird wiederhergestellt...';
	@override String get currentPlayback => 'Aktuelle Wiedergabe';
	@override String get joinCurrentPlayback => 'Aktuelle Wiedergabe beitreten';
	@override String get joinCurrentPlaybackDescription => 'Springe zurück zu dem, was der Host gerade ansieht';
	@override String get failedToOpenCurrentPlayback => 'Aktuelle Wiedergabe konnte nicht geöffnet werden';
	@override String participantJoined({required Object name}) => '${name} ist beigetreten';
	@override String participantLeft({required Object name}) => '${name} hat die Sitzung verlassen';
	@override String participantPaused({required Object name}) => '${name} hat pausiert';
	@override String participantResumed({required Object name}) => '${name} hat fortgesetzt';
	@override String participantSeeked({required Object name}) => '${name} hat gespult';
	@override String participantBuffering({required Object name}) => '${name} puffert';
	@override String get waitingForParticipants => 'Warte auf andere zum Laden...';
	@override String get recentRooms => 'Letzte Räume';
	@override String get renameRoom => 'Raum umbenennen';
	@override String get removeRoom => 'Entfernen';
}

// Path: downloads
class _TranslationsDownloadsDe implements TranslationsDownloadsEn {
	_TranslationsDownloadsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Verwalten';
	@override String get tvShows => 'Serien';
	@override String get movies => 'Filme';
	@override String get noDownloads => 'Noch keine Downloads';
	@override String get noDownloadsDescription => 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt';
	@override String get downloadNow => 'Herunterladen';
	@override String get deleteDownload => 'Download löschen';
	@override String get retryDownload => 'Download wiederholen';
	@override String get downloadQueued => 'Download in Warteschlange';
	@override String get serverErrorBitrate => 'Serverfehler — die Datei überschreitet möglicherweise das Remote-Streaming-Bitratenlimit';
	@override String episodesQueued({required Object count}) => '${count} Episoden zum Download hinzugefügt';
	@override String get downloadDeleted => 'Download gelöscht';
	@override String deleteConfirm({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})';
	@override String get deleting => 'Lösche...';
	@override String get queuedTooltip => 'In Warteschlange';
	@override String queuedFilesTooltip({required Object files}) => 'In Warteschlange: ${files}';
	@override String get downloadingTooltip => 'Lädt herunter...';
	@override String downloadingFilesTooltip({required Object files}) => 'Lädt ${files} herunter';
	@override String get noDownloadsTree => 'Keine Downloads';
	@override String get pauseAll => 'Alle pausieren';
	@override String get resumeAll => 'Alle fortsetzen';
	@override String get deleteAll => 'Alle löschen';
	@override String get selectVersion => 'Version auswählen';
	@override String get allEpisodes => 'Alle Episoden';
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override String nextNUnwatched({required Object count}) => 'Nächste ${count} ungesehene';
	@override String get customAmount => 'Eigene Anzahl...';
	@override String get howManyEpisodes => 'Wie viele Episoden?';
	@override String itemsQueued({required Object count}) => '${count} Elemente zum Download eingereiht';
	@override String get keepSynced => 'Synchronisiert halten';
	@override String get downloadOnce => 'Einmal herunterladen';
	@override String keepNUnwatched({required Object count}) => '${count} ungesehene behalten';
	@override String get editSyncRule => 'Sync-Regel bearbeiten';
	@override String get removeSyncRule => 'Sync-Regel entfernen';
	@override String removeSyncRuleConfirm({required Object title}) => 'Synchronisierung von "${title}" beenden? Heruntergeladene Episoden werden behalten.';
	@override String syncRuleCreated({required Object count}) => 'Sync-Regel erstellt — ${count} ungesehene Episoden werden behalten';
	@override String get syncRuleUpdated => 'Sync-Regel aktualisiert';
	@override String get syncRuleRemoved => 'Sync-Regel entfernt';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} neue Episoden für ${title} synchronisiert';
	@override String get activeSyncRules => 'Sync-Regeln';
	@override String get noSyncRules => 'Keine Sync-Regeln';
	@override String get manageSyncRule => 'Synchronisierung verwalten';
	@override String get editEpisodeCount => 'Episodenanzahl';
	@override String get editSyncFilter => 'Synchronisierungsfilter';
	@override String get syncAllItems => 'Alle Einträge synchronisieren';
	@override String get syncUnwatchedItems => 'Ungesehene Einträge synchronisieren';
	@override String get syncRuleListCreated => 'Sync-Regel erstellt';
}

// Path: shaders
class _TranslationsShadersDe implements TranslationsShadersEn {
	_TranslationsShadersDe._(this._root);

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
class _TranslationsCompanionRemoteDe implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Companion-Fernbedienung';
	@override String connectedTo({required Object name}) => 'Verbunden mit ${name}';
	@override late final _TranslationsCompanionRemoteSessionDe session = _TranslationsCompanionRemoteSessionDe._(_root);
	@override late final _TranslationsCompanionRemotePairingDe pairing = _TranslationsCompanionRemotePairingDe._(_root);
	@override late final _TranslationsCompanionRemoteRemoteDe remote = _TranslationsCompanionRemoteRemoteDe._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsDe implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Wiedergabeeinstellungen';
	@override String get playbackSpeed => 'Wiedergabegeschwindigkeit';
	@override String get sleepTimer => 'Schlaftimer';
	@override String get audioSync => 'Audio-Synchronisation';
	@override String get subtitleSync => 'Untertitel-Synchronisation';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Audioausgabe';
	@override String get performanceOverlay => 'Leistungsanzeige';
	@override String get audioPassthrough => 'Audio-Durchleitung';
	@override String get audioNormalization => 'Lautstärke normalisieren';
}

// Path: externalPlayer
class _TranslationsExternalPlayerDe implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Externer Player';
	@override String get useExternalPlayer => 'Externen Player verwenden';
	@override String get useExternalPlayerDescription => 'Videos in einer externen App statt im integrierten Player öffnen';
	@override String get selectPlayer => 'Player auswählen';
	@override String get customPlayers => 'Benutzerdefinierte Player';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Benutzerdefinierten Player hinzufügen';
	@override String get playerName => 'Playername';
	@override String get playerCommand => 'Befehl';
	@override String get playerPackage => 'Paketname';
	@override String get playerUrlScheme => 'URL-Schema';
	@override String get off => 'Aus';
	@override String get launchFailed => 'Externer Player konnte nicht geöffnet werden';
	@override String appNotInstalled({required Object name}) => '${name} ist nicht installiert';
	@override String get playInExternalPlayer => 'In externem Player abspielen';
}

// Path: metadataEdit
class _TranslationsMetadataEditDe implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Bearbeiten...';
	@override String get screenTitle => 'Metadaten bearbeiten';
	@override String get basicInfo => 'Grundlegende Infos';
	@override String get artwork => 'Artwork';
	@override String get advancedSettings => 'Erweiterte Einstellungen';
	@override String get title => 'Titel';
	@override String get sortTitle => 'Sortiertitel';
	@override String get originalTitle => 'Originaltitel';
	@override String get releaseDate => 'Erscheinungsdatum';
	@override String get contentRating => 'Altersfreigabe';
	@override String get studio => 'Studio';
	@override String get tagline => 'Tagline';
	@override String get summary => 'Zusammenfassung';
	@override String get poster => 'Poster';
	@override String get background => 'Hintergrund';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Quadratisches Bild';
	@override String get selectPoster => 'Poster auswählen';
	@override String get selectBackground => 'Hintergrund auswählen';
	@override String get selectLogo => 'Logo auswählen';
	@override String get selectSquareArt => 'Quadratisches Bild auswählen';
	@override String get fromUrl => 'Von URL';
	@override String get uploadFile => 'Datei hochladen';
	@override String get enterImageUrl => 'Bild-URL eingeben';
	@override String get imageUrl => 'Bild-URL';
	@override String get metadataUpdated => 'Metadaten aktualisiert';
	@override String get metadataUpdateFailed => 'Metadaten konnten nicht aktualisiert werden';
	@override String get artworkUpdated => 'Artwork aktualisiert';
	@override String get artworkUpdateFailed => 'Artwork konnte nicht aktualisiert werden';
	@override String get noArtworkAvailable => 'Kein Artwork verfügbar';
	@override String get notSet => 'Nicht festgelegt';
	@override String get libraryDefault => 'Bibliotheksstandard';
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
	@override String get tmdbAiring => 'The Movie Database (Ausgestrahlt)';
	@override String get tvdbAiring => 'TheTVDB (Ausgestrahlt)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolut)';
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
	@override String get style => 'Stil';
	@override String get mood => 'Stimmung';
}

// Path: matchScreen
class _TranslationsMatchScreenDe implements TranslationsMatchScreenEn {
	_TranslationsMatchScreenDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get match => 'Zuordnen...';
	@override String get fixMatch => 'Zuordnung korrigieren...';
	@override String get unmatch => 'Zuordnung aufheben';
	@override String get unmatchConfirm => 'Die aktuelle Zuordnung dieses Eintrags entfernen? Plex behandelt ihn als nicht zugeordnet, bis du ihn erneut zuordnest.';
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
class _TranslationsServerTasksDe implements TranslationsServerTasksEn {
	_TranslationsServerTasksDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveraufgaben';
	@override String get failedToLoad => 'Aufgaben konnten nicht geladen werden';
	@override String get noTasks => 'Keine laufenden Aufgaben';
}

// Path: trakt
class _TranslationsTraktDe implements TranslationsTraktEn {
	_TranslationsTraktDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Verbunden';
	@override String connectedAs({required Object username}) => 'Verbunden als @${username}';
	@override String get disconnectConfirm => 'Trakt-Konto trennen?';
	@override String get disconnectConfirmBody => 'Plezy sendet keine Wiedergabe-Ereignisse mehr an Trakt. Du kannst dich jederzeit erneut verbinden.';
	@override String get scrobble => 'Echtzeit-Scrobbling';
	@override String get scrobbleDescription => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.';
	@override String get watchedSync => 'Gesehen-Status synchronisieren';
	@override String get watchedSyncDescription => 'Wenn du Inhalte in Plezy als gesehen markierst, werden sie auch auf Trakt markiert.';
}

// Path: trackers
class _TranslationsTrackersDe implements TranslationsTrackersEn {
	_TranslationsTrackersDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tracker';
	@override String get hubSubtitle => 'Halte deinen Wiedergabefortschritt mit Trakt und anderen Diensten synchron.';
	@override String get notConnected => 'Nicht verbunden';
	@override String connectedAs({required Object username}) => 'Verbunden als @${username}';
	@override String get scrobble => 'Fortschritt automatisch verfolgen';
	@override String get scrobbleDescription => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.';
	@override String disconnectConfirm({required Object service}) => '${service} trennen?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy aktualisiert deine ${service}-Liste nicht mehr. Du kannst jederzeit wieder verbinden.';
	@override String connectFailed({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.';
	@override late final _TranslationsTrackersServicesDe services = _TranslationsTrackersServicesDe._(_root);
	@override late final _TranslationsTrackersDeviceCodeDe deviceCode = _TranslationsTrackersDeviceCodeDe._(_root);
	@override late final _TranslationsTrackersOauthProxyDe oauthProxy = _TranslationsTrackersOauthProxyDe._(_root);
	@override late final _TranslationsTrackersLibraryFilterDe libraryFilter = _TranslationsTrackersLibraryFilterDe._(_root);
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsDe implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsDe._(this._root);

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
	@override String get subSeekNext => 'Zum nächsten Untertitel springen';
	@override String get subSeekPrev => 'Zum vorherigen Untertitel springen';
	@override String get shaderToggle => 'Shader umschalten';
	@override String get skipMarker => 'Intro/Abspann überspringen';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsDe implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Erfordert Android 8.0 oder neuer';
	@override String get iosVersion => 'Erfordert iOS 15.0 oder neuer';
	@override String get permissionDisabled => 'Bild-in-Bild-Berechtigung ist deaktiviert. Aktiviere sie unter Einstellungen > Apps > Plezy > Bild-in-Bild';
	@override String get notSupported => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht';
	@override String get voSwitchFailed => 'Videoausgabe für Bild-in-Bild konnte nicht umgeschaltet werden';
	@override String get failed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override String unknown({required Object error}) => 'Ein Fehler ist aufgetreten: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsDe implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Empfohlen';
	@override String get browse => 'Durchsuchen';
	@override String get collections => 'Sammlungen';
	@override String get playlists => 'Wiedergabelisten';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsDe implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppierung';
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get seasons => 'Staffeln';
	@override String get episodes => 'Episoden';
	@override String get folders => 'Ordner';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionDe implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Remote-Server wird gestartet...';
	@override String get failedToCreate => 'Remote-Server konnte nicht gestartet werden:';
	@override String get hostAddress => 'Host-Adresse';
	@override String get connected => 'Verbunden';
	@override String get serverRunning => 'Remote-Server aktiv';
	@override String get serverStopped => 'Remote-Server gestoppt';
	@override String get serverRunningDescription => 'Mobilgeräte in deinem Netzwerk können diese App finden und sich verbinden';
	@override String get serverStoppedDescription => 'Starte den Server, um Mobilgeräten die Verbindung zu ermöglichen';
	@override String get usePhoneToControl => 'Verwende dein Mobilgerät, um diese App zu steuern';
	@override String get startServer => 'Server starten';
	@override String get stopServer => 'Server stoppen';
	@override String get minimize => 'Minimieren';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingDe implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Geräte in deinem Netzwerk, die Plezy mit demselben Plex-Konto nutzen, erscheinen automatisch';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Verbinden...';
	@override String get searchingForDevices => 'Suche nach Geräten...';
	@override String get noDevicesFound => 'Keine Geräte in deinem Netzwerk gefunden';
	@override String get noDevicesHint => 'Stelle sicher, dass Plezy auf deinem Desktop geöffnet ist und beide Geräte im selben WLAN sind';
	@override String get availableDevices => 'Verfügbare Geräte';
	@override String get manualConnection => 'Manuelle Verbindung';
	@override String get cryptoInitFailed => 'Sichere Verbindung konnte nicht initialisiert werden. Stelle sicher, dass du bei einem Plex-Konto angemeldet bist.';
	@override String get validationHostRequired => 'Bitte Host-Adresse eingeben';
	@override String get validationHostFormat => 'Format muss IP:Port sein (z.B. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Verbindung abgelaufen. Stelle sicher, dass beide Geräte im selben Netzwerk sind.';
	@override String get sessionNotFound => 'Gerät nicht gefunden. Stelle sicher, dass Plezy auf dem Host läuft.';
	@override String get authFailed => 'Authentifizierung fehlgeschlagen. Stelle sicher, dass beide Geräte dasselbe Plex-Konto verwenden.';
	@override String failedToConnect({required Object error}) => 'Verbindung fehlgeschlagen: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteDe implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteDe._(this._root);

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
	@override String get searchHint => 'Auf Desktop suchen...';
}

// Path: trackers.services
class _TranslationsTrackersServicesDe implements TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeDe implements TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Plezy auf ${service} aktivieren';
	@override String body({required Object url}) => 'Gehe zu ${url} und gib diesen Code ein:';
	@override String openToActivate({required Object service}) => '${service} zum Aktivieren öffnen';
	@override String get waitingForAuthorization => 'Warte auf Autorisierung…';
	@override String get codeCopied => 'Code kopiert';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyDe implements TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Bei ${service} anmelden';
	@override String get body => 'Scanne diesen QR-Code mit deinem Handy oder öffne die URL unten auf einem Gerät mit Browser.';
	@override String openToSignIn({required Object service}) => '${service} zum Anmelden öffnen';
	@override String get urlCopied => 'URL kopiert';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterDe implements TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliothekfilter';
	@override String get subtitleAllSyncing => 'Alle Bibliotheken werden synchronisiert';
	@override String get subtitleNoneSyncing => 'Nichts wird synchronisiert';
	@override String subtitleBlocked({required Object count}) => '${count} blockiert';
	@override String subtitleAllowed({required Object count}) => '${count} erlaubt';
	@override String get mode => 'Filtermodus';
	@override String get modeBlacklist => 'Blacklist';
	@override String get modeWhitelist => 'Whitelist';
	@override String get modeHintBlacklist => 'Alle Bibliotheken außer den unten markierten synchronisieren.';
	@override String get modeHintWhitelist => 'Nur die unten markierten Bibliotheken synchronisieren.';
	@override String get libraries => 'Bibliotheken';
	@override String get noLibraries => 'Keine Bibliotheken verfügbar';
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
			'auth.scanQRToSignIn' => 'QR-Code scannen zum Anmelden',
			'auth.waitingForAuth' => 'Warte auf Authentifizierung...\nBitte Anmeldung im Browser abschließen.',
			'auth.useBrowser' => 'Browser verwenden',
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
			'common.shuffle' => 'Zufall',
			'common.addTo' => 'Hinzufügen zu...',
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
			'common.settings' => 'Optionen',
			'common.mute' => 'Stumm',
			'common.ok' => 'OK',
			'common.reconnect' => 'Erneut verbinden',
			'common.exitConfirmTitle' => 'App beenden?',
			'common.exitConfirmMessage' => 'Möchtest du die App wirklich beenden?',
			'common.dontAskAgain' => 'Nicht erneut fragen',
			'common.exit' => 'Beenden',
			'common.viewAll' => 'Alle anzeigen',
			'common.checkingNetwork' => 'Netzwerk wird geprüft...',
			'common.refreshingServers' => 'Server werden aktualisiert...',
			'common.loadingServers' => 'Server werden geladen...',
			'common.connectingToServers' => 'Verbindung zu Servern...',
			'common.startingOfflineMode' => 'Offlinemodus wird gestartet...',
			'common.loading' => 'Laden...',
			'common.fullscreen' => 'Vollbild',
			'common.exitFullscreen' => 'Vollbild verlassen',
			'screens.licenses' => 'Lizenzen',
			'screens.switchProfile' => 'Profil wechseln',
			'screens.subtitleStyling' => 'Untertitel-Stil',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Protokolle',
			'update.available' => 'Update verfügbar',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} ist verfügbar',
			'update.currentVersion' => ({required Object version}) => 'Aktuell: ${version}',
			'update.skipVersion' => 'Diese Version überspringen',
			'update.viewRelease' => 'Release anzeigen',
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
			'settings.episodePosterMode' => 'Episoden-Poster-Stil',
			'settings.seriesPoster' => 'Serienposter',
			'settings.seasonPoster' => 'Staffelposter',
			'settings.episodeThumbnail' => 'Miniatur',
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
			'settings.libraryDensity' => 'Mediathekdichte',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Großzügig',
			'settings.viewMode' => 'Ansichtsmodus',
			'settings.gridView' => 'Raster',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Hero-Bereich anzeigen',
			'settings.useGlobalHubs' => 'Plex-Startseiten-Layout verwenden',
			'settings.useGlobalHubsDescription' => 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.',
			'settings.showServerNameOnHubs' => 'Servername bei Hubs anzeigen',
			'settings.showServerNameOnHubsDescription' => 'Zeigt immer den Servernamen in Hub-Titeln an. Wenn deaktiviert, nur bei doppelten Hub-Namen.',
			'settings.groupLibrariesByServer' => 'Mediatheken nach Server gruppieren',
			'settings.groupLibrariesByServerDescription' => 'Zeigt eine Überschrift für jeden Plex-Server in der Seitenleiste an, wenn du mit mehreren Servern verbunden bist.',
			'settings.alwaysKeepSidebarOpen' => 'Seitenleiste immer geöffnet halten',
			'settings.alwaysKeepSidebarOpenDescription' => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an',
			'settings.showUnwatchedCount' => 'Anzahl nicht gesehener Folgen anzeigen',
			'settings.showUnwatchedCountDescription' => 'Zeigt die Anzahl nicht gesehener Episoden bei Serien und Staffeln an',
			'settings.showEpisodeNumberOnCards' => 'Episodennummer auf Karten anzeigen',
			'settings.showEpisodeNumberOnCardsDescription' => 'Episodennummer neben der Staffel (z. B. S2 E3) auf Episodenkarten anzeigen',
			'settings.hideSpoilers' => 'Spoiler für nicht gesehene Episoden verbergen',
			'settings.hideSpoilersDescription' => 'Vorschaubilder unscharf machen und Beschreibungen für noch nicht gesehene Episoden ausblenden',
			'settings.playerBackend' => 'Player-Backend',
			'settings.exoPlayer' => 'ExoPlayer (Empfohlen)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardware-Decodierung',
			'settings.hardwareDecodingDescription' => 'Hardwarebeschleunigung verwenden, sofern verfügbar',
			'settings.bufferSize' => 'Puffergröße',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Empfohlen)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Ihr Gerät hat ${heap}MB Speicher. Ein ${size}MB-Puffer kann Wiedergabeprobleme verursachen.',
			'settings.defaultQualityTitle' => 'Standardqualität',
			'settings.defaultQualityDescription' => 'Wird beim Starten der Wiedergabe verwendet. Niedrigere Werte reduzieren die Bandbreite.',
			'settings.subtitleStyling' => 'Untertitel-Stil',
			'settings.subtitleStylingDescription' => 'Aussehen von Untertiteln anpassen',
			'settings.smallSkipDuration' => 'Kleine Sprungdauer',
			'settings.largeSkipDuration' => 'Große Sprungdauer',
			'settings.rewindOnResume' => 'Zurückspulen bei Fortsetzung',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} Sekunden',
			'settings.defaultSleepTimer' => 'Standard-Sleep-Timer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} Minuten',
			'settings.rememberTrackSelections' => 'Spurauswahl pro Serie/Film merken',
			'settings.rememberTrackSelectionsDescription' => 'Audio- und Untertitelsprache automatisch speichern, wenn während der Wiedergabe geändert',
			'settings.clickVideoTogglesPlayback' => 'Klicken Sie auf das Video, um die Wiedergabe zu starten oder zu pausieren.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Wenn diese Option aktiviert ist, wird durch Klicken auf den Videoplayer die Wiedergabe gestartet oder pausiert. Andernfalls werden durch Klicken die Wiedergabesteuerungen ein- oder ausgeblendet.',
			'settings.videoPlayerControls' => 'Videoplayer-Steuerung',
			'settings.keyboardShortcuts' => 'Tastenkürzel',
			'settings.keyboardShortcutsDescription' => 'Tastenkürzel anpassen',
			'settings.videoPlayerNavigation' => 'Videoplayer-Navigation',
			'settings.videoPlayerNavigationDescription' => 'Pfeiltasten zur Navigation der Videoplayer-Steuerung verwenden',
			'settings.watchTogetherRelay' => 'Gemeinsam Schauen Relay',
			'settings.watchTogetherRelayDescription' => 'Einen benutzerdefinierten Relay-Server für Gemeinsam Schauen festlegen. Alle Teilnehmer müssen denselben Server verwenden.',
			'settings.watchTogetherRelayHint' => 'https://mein-relay.beispiel.de',
			'settings.crashReporting' => 'Absturzberichte',
			'settings.crashReportingDescription' => 'Absturzberichte senden, um die App zu verbessern',
			'settings.debugLogging' => 'Debug-Protokollierung',
			'settings.debugLoggingDescription' => 'Detaillierte Protokolle zur Fehleranalyse aktivieren',
			'settings.viewLogs' => 'Protokolle anzeigen',
			'settings.viewLogsDescription' => 'App-Protokolle anzeigen',
			'settings.clearCache' => 'Cache löschen',
			'settings.clearCacheDescription' => 'Löscht alle zwischengespeicherten Bilder und Daten. Die App kann danach langsamer laden.',
			'settings.clearCacheSuccess' => 'Cache erfolgreich gelöscht',
			'settings.resetSettings' => 'Einstellungen zurücksetzen',
			'settings.resetSettingsDescription' => 'Alle Einstellungen auf Standard zurücksetzen. Dies kann nicht rückgängig gemacht werden.',
			'settings.resetSettingsSuccess' => 'Einstellungen erfolgreich zurückgesetzt',
			'settings.backup' => 'Sicherung',
			'settings.exportSettings' => 'Einstellungen exportieren',
			'settings.exportSettingsDescription' => 'Speichere deine Einstellungen in einer Datei',
			'settings.exportSettingsSuccess' => 'Einstellungen exportiert',
			'settings.exportSettingsFailed' => 'Einstellungen konnten nicht exportiert werden',
			'settings.importSettings' => 'Einstellungen importieren',
			'settings.importSettingsDescription' => 'Einstellungen aus einer Datei wiederherstellen',
			'settings.importSettingsConfirm' => 'Dies ersetzt deine aktuellen Einstellungen. Fortfahren?',
			'settings.importSettingsSuccess' => 'Einstellungen importiert',
			'settings.importSettingsFailed' => 'Einstellungen konnten nicht importiert werden',
			'settings.importSettingsInvalidFile' => 'Diese Datei ist kein gültiger Plezy-Einstellungsexport',
			'settings.importSettingsNoUser' => 'Vor dem Import bitte anmelden',
			'settings.shortcutsReset' => 'Tastenkürzel auf Standard zurückgesetzt',
			'settings.about' => 'Über',
			'settings.aboutDescription' => 'App-Informationen und Lizenzen',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update verfügbar',
			'settings.checkForUpdates' => 'Nach Updates suchen',
			'settings.autoCheckUpdatesOnStartup' => 'Beim Start automatisch nach Updates suchen',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Benachrichtigung anzeigen, wenn beim Start eine neue Version verfügbar ist',
			'settings.validationErrorEnterNumber' => 'Bitte eine gültige Zahl eingeben',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Dauer muss zwischen ${min} und ${max} ${unit} liegen',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Tastenkürzel bereits zugewiesen an ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Tastenkürzel aktualisiert für ${action}',
			'settings.autoSkip' => 'Automatisches Überspringen',
			'settings.autoSkipIntro' => 'Intro automatisch überspringen',
			'settings.autoSkipIntroDescription' => 'Intro-Marker nach wenigen Sekunden automatisch überspringen',
			'settings.autoSkipCredits' => 'Abspann automatisch überspringen',
			'settings.autoSkipCreditsDescription' => 'Abspann automatisch überspringen und nächste Episode abspielen',
			'settings.autoSkipDelay' => 'Verzögerung für automatisches Überspringen',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => '${seconds} Sekunden vor dem automatischen Überspringen warten',
			'settings.introPattern' => 'Intro-Markierungsmuster',
			'settings.introPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Intro-Markierungen in Kapiteltiteln',
			'settings.creditsPattern' => 'Abspann-Markierungsmuster',
			'settings.creditsPatternDescription' => 'Regulärer Ausdruck zum Erkennen von Abspann-Markierungen in Kapiteltiteln',
			'settings.invalidRegex' => 'Ungültiger regulärer Ausdruck',
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
			'settings.downloadLocationSelectError' => 'Ordnerauswahl fehlgeschlagen',
			'settings.downloadOnWifiOnly' => 'Nur über WLAN herunterladen',
			'settings.downloadOnWifiOnlyDescription' => 'Downloads über mobile Daten verhindern',
			'settings.autoRemoveWatchedDownloads' => 'Gesehene Downloads automatisch entfernen',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Heruntergeladene Episoden und Filme automatisch löschen, wenn sie als gesehen markiert werden',
			'settings.cellularDownloadBlocked' => 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.',
			'settings.maxVolume' => 'Maximale Lautstärke',
			'settings.maxVolumeDescription' => 'Lautstärke über 100% für leise Medien erlauben',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Zeige auf Discord, was du gerade schaust',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Wiedergabeverlauf mit Trakt synchronisieren',
			'settings.trackers' => 'Tracker',
			'settings.trackersDescription' => 'Fortschritt mit Trakt, MyAnimeList, AniList und Simkl synchronisieren',
			'settings.companionRemoteServer' => 'Companion Remote Server',
			'settings.companionRemoteServerDescription' => 'Mobilgeräten in deinem Netzwerk erlauben, diese App zu steuern',
			'settings.autoPip' => 'Automatisches Bild-in-Bild',
			'settings.autoPipDescription' => 'Automatisch Bild-in-Bild aktivieren, wenn die App während der Wiedergabe verlassen wird',
			'settings.matchContentFrameRate' => 'Inhalts-Bildrate anpassen',
			'settings.matchContentFrameRateDescription' => 'Bildwiederholfrequenz des Displays an den Videoinhalt anpassen, reduziert Ruckeln und spart Akku',
			'settings.matchRefreshRate' => 'Bildwiederholrate anpassen',
			'settings.matchRefreshRateDescription' => 'Bildwiederholrate des Displays an den Videoinhalt im Vollbildmodus anpassen',
			'settings.matchDynamicRange' => 'Dynamikumfang anpassen',
			'settings.matchDynamicRangeDescription' => 'HDR für HDR-Inhalte automatisch aktivieren und beim Verlassen des Players auf SDR zurücksetzen',
			'settings.displaySwitchDelay' => 'Verzögerung beim Displaywechsel',
			'settings.tunneledPlayback' => 'Tunnelwiedergabe',
			'settings.tunneledPlaybackDescription' => 'Hardware-beschleunigte Video-Tunnelierung verwenden. Deaktivieren, wenn bei HDR-Inhalten ein schwarzer Bildschirm mit Ton erscheint',
			'settings.requireProfileSelectionOnOpen' => 'Profil beim Öffnen abfragen',
			'settings.requireProfileSelectionOnOpenDescription' => 'Profilauswahl bei jedem Öffnen der App anzeigen',
			'settings.confirmExitOnBack' => 'Vor dem Beenden bestätigen',
			'settings.confirmExitOnBackDescription' => 'Bestätigungsdialog anzeigen, wenn Zurück zum Beenden der App gedrückt wird',
			'settings.forceTvMode' => 'TV-Modus erzwingen',
			'settings.forceTvModeDescription' => 'TV-Layout unabhängig von der automatischen Erkennung verwenden. Nützlich für Android-TV-Geräte, die das Leanback-Feature nicht melden. Startet die App bei Änderung neu.',
			'settings.startInFullscreen' => 'Im Vollbildmodus starten',
			'settings.startInFullscreenDescription' => 'Plezy beim Start im Vollbildmodus öffnen',
			'settings.autoHidePerformanceOverlay' => 'Leistungsoverlay automatisch ausblenden',
			'settings.autoHidePerformanceOverlayDescription' => 'Leistungsoverlay mit den Wiedergabesteuerungen ein-/ausblenden',
			'settings.showNavBarLabels' => 'Navigationsleisten-Beschriftungen anzeigen',
			'settings.showNavBarLabelsDescription' => 'Textbeschriftungen unter den Symbolen der Navigationsleiste anzeigen',
			'settings.liveTvDefaultFavorites' => 'Standardmäßig Favoritenkanäle',
			'settings.liveTvDefaultFavoritesDescription' => 'Beim Öffnen von Live TV nur Favoritenkanäle anzeigen',
			'settings.display' => 'Display',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Window',
			'settings.content' => 'Content',
			'settings.player' => 'Player',
			'settings.subtitlesAndConfig' => 'Subtitles & Configuration',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'search.hint' => 'Filme, Serien, Musik suchen...',
			'search.tryDifferentTerm' => 'Anderen Suchbegriff versuchen',
			'search.searchYourMedia' => 'In den eigenen Medien suchen',
			'search.enterTitleActorOrKeyword' => 'Titel, Schauspieler oder Stichwort eingeben',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Tastenkürzel festlegen für ${actionName}',
			'hotkeys.clearShortcut' => 'Kürzel löschen',
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
			'hotkeys.actions.subSeekNext' => 'Zum nächsten Untertitel springen',
			'hotkeys.actions.subSeekPrev' => 'Zum vorherigen Untertitel springen',
			'hotkeys.actions.shaderToggle' => 'Shader umschalten',
			'hotkeys.actions.skipMarker' => 'Intro/Abspann überspringen',
			'fileInfo.title' => 'Dateiinfo',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Datei',
			'fileInfo.advanced' => 'Erweitert',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Auflösung',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Bildrate',
			'fileInfo.aspectRatio' => 'Seitenverhältnis',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Farbtiefe',
			'fileInfo.colorSpace' => 'Farbraum',
			'fileInfo.colorRange' => 'Farbbereich',
			'fileInfo.colorPrimaries' => 'Primärfarben',
			'fileInfo.chromaSubsampling' => 'Chroma-Subsampling',
			'fileInfo.channels' => 'Kanäle',
			'fileInfo.subtitles' => 'Untertitel',
			'fileInfo.overallBitrate' => 'Gesamt-Bitrate',
			'fileInfo.path' => 'Pfad',
			'fileInfo.size' => 'Größe',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Dauer',
			'fileInfo.optimizedForStreaming' => 'Für Streaming optimiert',
			'fileInfo.has64bitOffsets' => '64-Bit-Offsets',
			'mediaMenu.markAsWatched' => 'Als gesehen markieren',
			'mediaMenu.markAsUnwatched' => 'Als ungesehen markieren',
			'mediaMenu.removeFromContinueWatching' => 'Aus ‚Weiterschauen‘ entfernen',
			'mediaMenu.goToSeries' => 'Zur Serie',
			'mediaMenu.goToSeason' => 'Zur Staffel',
			'mediaMenu.shufflePlay' => 'Zufallswiedergabe',
			'mediaMenu.fileInfo' => 'Dateiinfo',
			'mediaMenu.deleteFromServer' => 'Vom Server löschen',
			'mediaMenu.confirmDelete' => 'Dieses Medium und seine Dateien werden dauerhaft von Ihrem Server gelöscht. Dies kann nicht rückgängig gemacht werden.',
			'mediaMenu.deleteMultipleWarning' => 'Dies umfasst alle Episoden und deren Dateien.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medienelement erfolgreich gelöscht',
			'mediaMenu.mediaFailedToDelete' => 'Löschen des Medienelements fehlgeschlagen',
			'mediaMenu.rate' => 'Bewerten',
			'mediaMenu.playFromBeginning' => 'Von Anfang an abspielen',
			'mediaMenu.playVersion' => 'Version abspielen...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, Film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, Serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'angesehen',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} Prozent angesehen',
			'accessibility.mediaCardUnwatched' => 'ungeschaut',
			'accessibility.tapToPlay' => 'Zum Abspielen tippen',
			'tooltips.shufflePlay' => 'Zufallswiedergabe',
			'tooltips.playTrailer' => 'Trailer abspielen',
			'tooltips.markAsWatched' => 'Als gesehen markieren',
			'tooltips.markAsUnwatched' => 'Als ungesehen markieren',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Untertitel',
			'videoControls.resetToZero' => 'Auf 0 ms zurücksetzen',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} spielt später',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} spielt früher',
			'videoControls.noOffset' => 'Kein Offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Bild füllen',
			'videoControls.stretch' => 'Strecken',
			'videoControls.lockRotation' => 'Rotation sperren',
			'videoControls.unlockRotation' => 'Rotation entsperren',
			'videoControls.timerActive' => 'Schlaftimer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert',
			'videoControls.stillWatching' => 'Schaust du noch?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pause in ${seconds}s',
			'videoControls.continueWatching' => 'Weiter',
			'videoControls.autoPlayNext' => 'Nächstes automatisch abspielen',
			'videoControls.playNext' => 'Nächstes abspielen',
			'videoControls.playButton' => 'Wiedergeben',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => '${seconds} Sekunden zurück',
			'videoControls.seekForwardButton' => ({required Object seconds}) => '${seconds} Sekunden vor',
			'videoControls.previousButton' => 'Vorherige Episode',
			'videoControls.nextButton' => 'Nächste Episode',
			'videoControls.previousChapterButton' => 'Vorheriges Kapitel',
			'videoControls.nextChapterButton' => 'Nächstes Kapitel',
			'videoControls.muteButton' => 'Stumm schalten',
			'videoControls.unmuteButton' => 'Stummschaltung aufheben',
			'videoControls.settingsButton' => 'Videoeinstellungen',
			'videoControls.tracksButton' => 'Audio und Untertitel',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionsButton' => 'Videoversionen',
			'videoControls.versionQualityButton' => 'Version & Qualität',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Qualität',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkodierung nicht verfügbar — Wiedergabe in Originalqualität',
			'videoControls.pipButton' => 'Bild-in-Bild Modus',
			'videoControls.aspectRatioButton' => 'Seitenverhältnis',
			'videoControls.ambientLighting' => 'Umgebungsbeleuchtung',
			'videoControls.fullscreenButton' => 'Vollbild aktivieren',
			'videoControls.exitFullscreenButton' => 'Vollbild verlassen',
			'videoControls.alwaysOnTopButton' => 'Immer im Vordergrund',
			'videoControls.rotationLockButton' => 'Dreh­sperre',
			'videoControls.lockScreen' => 'Bildschirm sperren',
			'videoControls.screenLockButton' => 'Bildschirmsperre',
			'videoControls.longPressToUnlock' => 'Lange drücken zum Entsperren',
			'videoControls.timelineSlider' => 'Video-Zeitleiste',
			'videoControls.volumeSlider' => 'Lautstärkepegel',
			'videoControls.endsAt' => ({required Object time}) => 'Endet um ${time}',
			'videoControls.pipActive' => 'Wiedergabe im Bild-in-Bild-Modus',
			'videoControls.pipFailed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.pipErrors.androidVersion' => 'Erfordert Android 8.0 oder neuer',
			'videoControls.pipErrors.iosVersion' => 'Erfordert iOS 15.0 oder neuer',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-in-Bild-Berechtigung ist deaktiviert. Aktiviere sie unter Einstellungen > Apps > Plezy > Bild-in-Bild',
			'videoControls.pipErrors.notSupported' => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht',
			'videoControls.pipErrors.voSwitchFailed' => 'Videoausgabe für Bild-in-Bild konnte nicht umgeschaltet werden',
			'videoControls.pipErrors.failed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ein Fehler ist aufgetreten: ${error}',
			'videoControls.chapters' => 'Kapitel',
			'videoControls.noChaptersAvailable' => 'Keine Kapitel verfügbar',
			'videoControls.queue' => 'Warteschlange',
			'videoControls.noQueueItems' => 'Keine Elemente in der Warteschlange',
			'videoControls.searchSubtitles' => 'Untertitel suchen',
			'videoControls.language' => 'Sprache',
			'videoControls.noSubtitlesFound' => 'Keine Untertitel gefunden',
			'videoControls.subtitleDownloaded' => 'Untertitel heruntergeladen',
			'videoControls.subtitleDownloadFailed' => 'Untertitel konnte nicht heruntergeladen werden',
			'videoControls.searchLanguages' => 'Sprachen suchen...',
			'userStatus.admin' => 'Eigentümer',
			'userStatus.restricted' => 'Eingeschränkt',
			'userStatus.protected' => 'Geschützt',
			'userStatus.current' => 'AKTUELL',
			'messages.markedAsWatched' => 'Als gesehen markiert',
			'messages.markedAsUnwatched' => 'Als ungesehen markiert',
			'messages.markedAsWatchedOffline' => 'Als gesehen markiert (wird synchronisiert, wenn online)',
			'messages.markedAsUnwatchedOffline' => 'Als ungesehen markiert (wird synchronisiert, wenn online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisch entfernt: ${title}',
			'messages.removedFromContinueWatching' => 'Aus ‚Weiterschauen\' entfernt',
			'messages.errorLoading' => ({required Object error}) => 'Fehler: ${error}',
			'messages.fileInfoNotAvailable' => 'Dateiinfo nicht verfügbar',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}',
			'messages.errorLoadingSeries' => 'Fehler beim Laden der Serie',
			'messages.errorLoadingSeason' => 'Fehler beim Laden der Staffel',
			'messages.musicNotSupported' => 'Musikwiedergabe wird noch nicht unterstützt',
			'messages.noDescriptionAvailable' => 'Keine Beschreibung verfügbar',
			'messages.noProfilesAvailable' => 'Keine Profile verfügbar',
			'messages.contactAdminForProfiles' => 'Kontaktiere deinen Plex-Administrator, um Profile hinzuzufügen',
			'messages.unableToDetermineLibrarySection' => 'Bibliotheksbereich für dieses Element kann nicht ermittelt werden',
			'messages.logsCleared' => 'Protokolle gelöscht',
			'messages.logsCopied' => 'Protokolle in Zwischenablage kopiert',
			'messages.noLogsAvailable' => 'Keine Protokolle verfügbar',
			'messages.libraryScanning' => ({required Object title}) => 'Scanne „${title}“...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Mediathekscan gestartet für „${title}“',
			'messages.libraryScanFailed' => ({required Object error}) => 'Fehler beim Scannen der Mediathek: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Metadaten werden aktualisiert für „${title}“...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadaten-Aktualisierung gestartet für „${title}“',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Metadaten konnten nicht aktualisiert werden: ${error}',
			'messages.logoutConfirm' => 'Abmeldung wirklich durchführen?',
			'messages.noSeasonsFound' => 'Keine Staffeln gefunden',
			'messages.noEpisodesFound' => 'Keine Episoden in der ersten Staffel gefunden',
			'messages.noEpisodesFoundGeneral' => 'Keine Episoden gefunden',
			'messages.noResultsFound' => 'Keine Ergebnisse gefunden',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sleep-Timer gesetzt auf ${label}',
			'messages.noItemsAvailable' => 'Keine Elemente verfügbar',
			'messages.failedToCreatePlayQueueNoItems' => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Wechsle zu kompatiblem Player...',
			'messages.serverLimitTitle' => 'Wiedergabe fehlgeschlagen',
			'messages.serverLimitBody' => 'Der Server hat einen Fehler zurückgegeben (HTTP 500). Das bedeutet meist, dass der Serverbesitzer ein Bandbreiten- oder Transcoding-Limit festgelegt hat, das deine Sitzung ablehnt. Vom Client aus lässt sich nichts machen — der Serverbesitzer muss seine Einstellungen anpassen.',
			'messages.logsUploaded' => 'Protokolle hochgeladen',
			'messages.logsUploadFailed' => 'Protokolle konnten nicht hochgeladen werden',
			'messages.logId' => 'Protokoll-ID',
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
			'subtitlingStyling.bold' => 'Fett',
			'subtitlingStyling.italic' => 'Kursiv',
			'mpvConfig.title' => 'mpv-Konfiguration',
			'mpvConfig.description' => 'Erweiterte Videoplayer-Einstellungen',
			'mpvConfig.presets' => 'Voreinstellungen',
			'mpvConfig.noPresets' => 'Keine gespeicherten Voreinstellungen',
			'mpvConfig.saveAsPreset' => 'Als Voreinstellung speichern...',
			'mpvConfig.presetName' => 'Name der Voreinstellung',
			'mpvConfig.presetNameHint' => 'Namen für diese Voreinstellung eingeben',
			'mpvConfig.loadPreset' => 'Laden',
			'mpvConfig.deletePreset' => 'Löschen',
			'mpvConfig.presetSaved' => 'Voreinstellung gespeichert',
			'mpvConfig.presetLoaded' => 'Voreinstellung geladen',
			'mpvConfig.presetDeleted' => 'Voreinstellung gelöscht',
			'mpvConfig.confirmDeletePreset' => 'Möchten Sie diese Voreinstellung wirklich löschen?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Aktion bestätigen',
			'discover.title' => 'Entdecken',
			'discover.switchProfile' => 'Profil wechseln',
			'discover.noContentAvailable' => 'Kein Inhalt verfügbar',
			'discover.addMediaToLibraries' => 'Medien zur Mediathek hinzufügen',
			'discover.continueWatching' => 'Weiterschauen',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Übersicht',
			'discover.cast' => 'Besetzung',
			'discover.extras' => 'Trailer & Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Altersfreigabe',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} Min übrig',
			'errors.searchFailed' => ({required Object error}) => 'Suche fehlgeschlagen: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Zeitüberschreitung beim Laden von ${context}',
			'errors.connectionFailed' => 'Verbindung zum Plex-Server fehlgeschlagen',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Fehler beim Laden von ${context}: ${error}',
			'errors.noClientAvailable' => 'Kein Client verfügbar',
			'errors.authenticationFailed' => ({required Object error}) => 'Authentifizierung fehlgeschlagen: ${error}',
			'errors.couldNotLaunchUrl' => 'Auth-URL konnte nicht geöffnet werden',
			'errors.pleaseEnterToken' => 'Bitte Token eingeben',
			'errors.invalidToken' => 'Ungültiges Token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Token-Verifizierung fehlgeschlagen: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Profilwechsel zu ${displayName} fehlgeschlagen',
			'libraries.title' => 'Mediatheken',
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
			_ => null,
		} ?? switch (path) {
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Ausgeblendete Mediatheken (${count})',
			'libraries.thisLibraryIsEmpty' => 'Diese Mediathek ist leer',
			'libraries.all' => 'Alle',
			'libraries.clearAll' => 'Alle löschen',
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
			'libraries.content' => 'Bibliotheksinhalt',
			'libraries.selectLibrary' => 'Bibliothek auswählen',
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
			'libraries.groupings.folders' => 'Ordner',
			'about.title' => 'Über',
			'about.openSourceLicenses' => 'Open-Source-Lizenzen',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Ein schöner Plex-Client für Flutter',
			'about.viewLicensesDescription' => 'Lizenzen von Drittanbieter-Bibliotheken anzeigen',
			'serverSelection.allServerConnectionsFailed' => 'Verbindung zu allen Servern fehlgeschlagen. Bitte Netzwerk prüfen und erneut versuchen.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Server konnten nicht geladen werden: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Erscheinungsjahr',
			'hubDetail.dateAdded' => 'Hinzugefügt am',
			'hubDetail.rating' => 'Bewertung',
			'hubDetail.noItemsFound' => 'Keine Elemente gefunden',
			'logs.clearLogs' => 'Protokolle löschen',
			'logs.copyLogs' => 'Protokolle kopieren',
			'logs.uploadLogs' => 'Protokolle hochladen',
			'licenses.relatedPackages' => 'Verwandte Pakete',
			'licenses.license' => 'Lizenz',
			'licenses.licenseNumber' => ({required Object number}) => 'Lizenz ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} Lizenzen',
			'navigation.libraries' => 'Medien',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live-TV',
			'liveTv.title' => 'Live-TV',
			'liveTv.guide' => 'Programmführer',
			'liveTv.noChannels' => 'Keine Kanäle verfügbar',
			'liveTv.noDvr' => 'Kein DVR auf einem Server konfiguriert',
			'liveTv.noPrograms' => 'Keine Programmdaten verfügbar',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Programmführer neu laden',
			'liveTv.now' => 'Jetzt',
			'liveTv.today' => 'Heute',
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
			'liveTv.joinSession' => 'Laufender Sitzung beitreten',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Von Anfang an ansehen (vor ${minutes} Min.)',
			'liveTv.watchLive' => 'Live ansehen',
			'liveTv.goToLive' => 'Zum Live-Bild',
			'collections.title' => 'Sammlungen',
			'collections.collection' => 'Sammlung',
			'collections.empty' => 'Sammlung ist leer',
			'collections.unknownLibrarySection' => 'Löschen nicht möglich: Unbekannte Bibliothekssektion',
			'collections.deleteCollection' => 'Sammlung löschen',
			'collections.deleteConfirm' => ({required Object title}) => 'Sind Sie sicher, dass Sie "${title}" löschen möchten? Dies kann nicht rückgängig gemacht werden.',
			'collections.deleted' => 'Sammlung gelöscht',
			'collections.deleteFailed' => 'Sammlung konnte nicht gelöscht werden',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Sammlung konnte nicht gelöscht werden: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Sammlungselemente konnten nicht geladen werden: ${error}',
			'collections.selectCollection' => 'Sammlung auswählen',
			'collections.collectionName' => 'Sammlungsname',
			'collections.enterCollectionName' => 'Sammlungsnamen eingeben',
			'collections.addedToCollection' => 'Zur Sammlung hinzugefügt',
			'collections.errorAddingToCollection' => 'Fehler beim Hinzufügen zur Sammlung',
			'collections.created' => 'Sammlung erstellt',
			'collections.removeFromCollection' => 'Aus Sammlung entfernen',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" aus dieser Sammlung entfernen?',
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
			'playlists.deleteMessage' => ({required Object name}) => 'Soll "${name}" wirklich gelöscht werden?',
			'playlists.created' => 'Wiedergabeliste erstellt',
			'playlists.deleted' => 'Wiedergabeliste gelöscht',
			'playlists.itemAdded' => 'Zur Wiedergabeliste hinzugefügt',
			'playlists.itemRemoved' => 'Aus Wiedergabeliste entfernt',
			'playlists.selectPlaylist' => 'Wiedergabeliste auswählen',
			'playlists.errorCreating' => 'Wiedergabeliste konnte nicht erstellt werden',
			'playlists.errorDeleting' => 'Wiedergabeliste konnte nicht gelöscht werden',
			'playlists.errorLoading' => 'Wiedergabelisten konnten nicht geladen werden',
			'playlists.errorAdding' => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden',
			'playlists.errorReordering' => 'Element der Wiedergabeliste konnte nicht neu geordnet werden',
			'playlists.errorRemoving' => 'Konnte nicht aus der Wiedergabeliste entfernt werden',
			'watchTogether.title' => 'Gemeinsam Schauen',
			'watchTogether.description' => 'Inhalte synchron mit Freunden und Familie schauen',
			'watchTogether.createSession' => 'Sitzung Erstellen',
			'watchTogether.creating' => 'Erstellen...',
			'watchTogether.joinSession' => 'Sitzung Beitreten',
			'watchTogether.joining' => 'Beitreten...',
			'watchTogether.controlMode' => 'Steuerungsmodus',
			'watchTogether.controlModeQuestion' => 'Wer kann die Wiedergabe steuern?',
			'watchTogether.hostOnly' => 'Nur Host',
			'watchTogether.anyone' => 'Alle',
			'watchTogether.hostingSession' => 'Sitzung Hosten',
			'watchTogether.inSession' => 'In Sitzung',
			'watchTogether.sessionCode' => 'Sitzungscode',
			'watchTogether.hostControlsPlayback' => 'Host steuert die Wiedergabe',
			'watchTogether.anyoneCanControl' => 'Alle können die Wiedergabe steuern',
			'watchTogether.hostControls' => 'Host steuert',
			'watchTogether.anyoneControls' => 'Alle steuern',
			'watchTogether.participants' => 'Teilnehmer',
			'watchTogether.host' => 'Host',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Du bist der Host',
			'watchTogether.watchingWithOthers' => 'Mit anderen schauen',
			'watchTogether.endSession' => 'Sitzung Beenden',
			'watchTogether.leaveSession' => 'Sitzung Verlassen',
			'watchTogether.endSessionQuestion' => 'Sitzung Beenden?',
			'watchTogether.leaveSessionQuestion' => 'Sitzung Verlassen?',
			'watchTogether.endSessionConfirm' => 'Dies beendet die Sitzung für alle Teilnehmer.',
			'watchTogether.leaveSessionConfirm' => 'Du wirst aus der Sitzung entfernt.',
			'watchTogether.endSessionConfirmOverlay' => 'Dies beendet die Schausitzung für alle Teilnehmer.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Du wirst von der Schausitzung getrennt.',
			'watchTogether.end' => 'Beenden',
			'watchTogether.leave' => 'Verlassen',
			'watchTogether.syncing' => 'Synchronisieren...',
			'watchTogether.joinWatchSession' => 'Schausitzung Beitreten',
			'watchTogether.enterCodeHint' => '5-stelligen Code eingeben',
			'watchTogether.pasteFromClipboard' => 'Aus Zwischenablage einfügen',
			'watchTogether.pleaseEnterCode' => 'Bitte gib einen Sitzungscode ein',
			'watchTogether.codeMustBe5Chars' => 'Sitzungscode muss 5 Zeichen haben',
			'watchTogether.joinInstructions' => 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.',
			'watchTogether.failedToCreate' => 'Sitzung konnte nicht erstellt werden',
			'watchTogether.failedToJoin' => 'Sitzung konnte nicht beigetreten werden',
			'watchTogether.sessionCodeCopied' => 'Sitzungscode in Zwischenablage kopiert',
			'watchTogether.relayUnreachable' => 'Der Relay-Server ist nicht erreichbar. Möglicherweise blockiert dein Internetanbieter die Verbindung. Du kannst es trotzdem versuchen, aber Watch Together funktioniert eventuell nicht.',
			'watchTogether.reconnectingToHost' => 'Verbindung zum Host wird wiederhergestellt...',
			'watchTogether.currentPlayback' => 'Aktuelle Wiedergabe',
			'watchTogether.joinCurrentPlayback' => 'Aktuelle Wiedergabe beitreten',
			'watchTogether.joinCurrentPlaybackDescription' => 'Springe zurück zu dem, was der Host gerade ansieht',
			'watchTogether.failedToOpenCurrentPlayback' => 'Aktuelle Wiedergabe konnte nicht geöffnet werden',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} ist beigetreten',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} hat die Sitzung verlassen',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} hat pausiert',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} hat fortgesetzt',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} hat gespult',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} puffert',
			'watchTogether.waitingForParticipants' => 'Warte auf andere zum Laden...',
			'watchTogether.recentRooms' => 'Letzte Räume',
			'watchTogether.renameRoom' => 'Raum umbenennen',
			'watchTogether.removeRoom' => 'Entfernen',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Verwalten',
			'downloads.tvShows' => 'Serien',
			'downloads.movies' => 'Filme',
			'downloads.noDownloads' => 'Noch keine Downloads',
			'downloads.noDownloadsDescription' => 'Heruntergeladene Inhalte werden hier für die Offline-Wiedergabe angezeigt',
			'downloads.downloadNow' => 'Herunterladen',
			'downloads.deleteDownload' => 'Download löschen',
			'downloads.retryDownload' => 'Download wiederholen',
			'downloads.downloadQueued' => 'Download in Warteschlange',
			'downloads.serverErrorBitrate' => 'Serverfehler — die Datei überschreitet möglicherweise das Remote-Streaming-Bitratenlimit',
			'downloads.episodesQueued' => ({required Object count}) => '${count} Episoden zum Download hinzugefügt',
			'downloads.downloadDeleted' => 'Download gelöscht',
			'downloads.deleteConfirm' => ({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})',
			'downloads.deleting' => 'Lösche...',
			'downloads.queuedTooltip' => 'In Warteschlange',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'In Warteschlange: ${files}',
			'downloads.downloadingTooltip' => 'Lädt herunter...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Lädt ${files} herunter',
			'downloads.noDownloadsTree' => 'Keine Downloads',
			'downloads.pauseAll' => 'Alle pausieren',
			'downloads.resumeAll' => 'Alle fortsetzen',
			'downloads.deleteAll' => 'Alle löschen',
			'downloads.selectVersion' => 'Version auswählen',
			'downloads.allEpisodes' => 'Alle Episoden',
			'downloads.unwatchedOnly' => 'Nur ungesehene',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Nächste ${count} ungesehene',
			'downloads.customAmount' => 'Eigene Anzahl...',
			'downloads.howManyEpisodes' => 'Wie viele Episoden?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} Elemente zum Download eingereiht',
			'downloads.keepSynced' => 'Synchronisiert halten',
			'downloads.downloadOnce' => 'Einmal herunterladen',
			'downloads.keepNUnwatched' => ({required Object count}) => '${count} ungesehene behalten',
			'downloads.editSyncRule' => 'Sync-Regel bearbeiten',
			'downloads.removeSyncRule' => 'Sync-Regel entfernen',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Synchronisierung von "${title}" beenden? Heruntergeladene Episoden werden behalten.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Sync-Regel erstellt — ${count} ungesehene Episoden werden behalten',
			'downloads.syncRuleUpdated' => 'Sync-Regel aktualisiert',
			'downloads.syncRuleRemoved' => 'Sync-Regel entfernt',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} neue Episoden für ${title} synchronisiert',
			'downloads.activeSyncRules' => 'Sync-Regeln',
			'downloads.noSyncRules' => 'Keine Sync-Regeln',
			'downloads.manageSyncRule' => 'Synchronisierung verwalten',
			'downloads.editEpisodeCount' => 'Episodenanzahl',
			'downloads.editSyncFilter' => 'Synchronisierungsfilter',
			'downloads.syncAllItems' => 'Alle Einträge synchronisieren',
			'downloads.syncUnwatchedItems' => 'Ungesehene Einträge synchronisieren',
			'downloads.syncRuleListCreated' => 'Sync-Regel erstellt',
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
			'companionRemote.session.startingServer' => 'Remote-Server wird gestartet...',
			'companionRemote.session.failedToCreate' => 'Remote-Server konnte nicht gestartet werden:',
			'companionRemote.session.hostAddress' => 'Host-Adresse',
			'companionRemote.session.connected' => 'Verbunden',
			'companionRemote.session.serverRunning' => 'Remote-Server aktiv',
			'companionRemote.session.serverStopped' => 'Remote-Server gestoppt',
			'companionRemote.session.serverRunningDescription' => 'Mobilgeräte in deinem Netzwerk können diese App finden und sich verbinden',
			'companionRemote.session.serverStoppedDescription' => 'Starte den Server, um Mobilgeräten die Verbindung zu ermöglichen',
			'companionRemote.session.usePhoneToControl' => 'Verwende dein Mobilgerät, um diese App zu steuern',
			'companionRemote.session.startServer' => 'Server starten',
			'companionRemote.session.stopServer' => 'Server stoppen',
			'companionRemote.session.minimize' => 'Minimieren',
			'companionRemote.pairing.discoveryDescription' => 'Geräte in deinem Netzwerk, die Plezy mit demselben Plex-Konto nutzen, erscheinen automatisch',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Verbinden...',
			'companionRemote.pairing.searchingForDevices' => 'Suche nach Geräten...',
			'companionRemote.pairing.noDevicesFound' => 'Keine Geräte in deinem Netzwerk gefunden',
			'companionRemote.pairing.noDevicesHint' => 'Stelle sicher, dass Plezy auf deinem Desktop geöffnet ist und beide Geräte im selben WLAN sind',
			'companionRemote.pairing.availableDevices' => 'Verfügbare Geräte',
			'companionRemote.pairing.manualConnection' => 'Manuelle Verbindung',
			'companionRemote.pairing.cryptoInitFailed' => 'Sichere Verbindung konnte nicht initialisiert werden. Stelle sicher, dass du bei einem Plex-Konto angemeldet bist.',
			'companionRemote.pairing.validationHostRequired' => 'Bitte Host-Adresse eingeben',
			'companionRemote.pairing.validationHostFormat' => 'Format muss IP:Port sein (z.B. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Verbindung abgelaufen. Stelle sicher, dass beide Geräte im selben Netzwerk sind.',
			'companionRemote.pairing.sessionNotFound' => 'Gerät nicht gefunden. Stelle sicher, dass Plezy auf dem Host läuft.',
			'companionRemote.pairing.authFailed' => 'Authentifizierung fehlgeschlagen. Stelle sicher, dass beide Geräte dasselbe Plex-Konto verwenden.',
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
			'companionRemote.remote.searchHint' => 'Auf Desktop suchen...',
			'videoSettings.playbackSettings' => 'Wiedergabeeinstellungen',
			'videoSettings.playbackSpeed' => 'Wiedergabegeschwindigkeit',
			'videoSettings.sleepTimer' => 'Schlaftimer',
			'videoSettings.audioSync' => 'Audio-Synchronisation',
			'videoSettings.subtitleSync' => 'Untertitel-Synchronisation',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Audioausgabe',
			'videoSettings.performanceOverlay' => 'Leistungsanzeige',
			'videoSettings.audioPassthrough' => 'Audio-Durchleitung',
			'videoSettings.audioNormalization' => 'Lautstärke normalisieren',
			'externalPlayer.title' => 'Externer Player',
			'externalPlayer.useExternalPlayer' => 'Externen Player verwenden',
			'externalPlayer.useExternalPlayerDescription' => 'Videos in einer externen App statt im integrierten Player öffnen',
			'externalPlayer.selectPlayer' => 'Player auswählen',
			'externalPlayer.customPlayers' => 'Benutzerdefinierte Player',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Benutzerdefinierten Player hinzufügen',
			'externalPlayer.playerName' => 'Playername',
			'externalPlayer.playerCommand' => 'Befehl',
			'externalPlayer.playerPackage' => 'Paketname',
			'externalPlayer.playerUrlScheme' => 'URL-Schema',
			'externalPlayer.off' => 'Aus',
			'externalPlayer.launchFailed' => 'Externer Player konnte nicht geöffnet werden',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} ist nicht installiert',
			'externalPlayer.playInExternalPlayer' => 'In externem Player abspielen',
			'metadataEdit.editMetadata' => 'Bearbeiten...',
			'metadataEdit.screenTitle' => 'Metadaten bearbeiten',
			'metadataEdit.basicInfo' => 'Grundlegende Infos',
			'metadataEdit.artwork' => 'Artwork',
			'metadataEdit.advancedSettings' => 'Erweiterte Einstellungen',
			'metadataEdit.title' => 'Titel',
			'metadataEdit.sortTitle' => 'Sortiertitel',
			'metadataEdit.originalTitle' => 'Originaltitel',
			'metadataEdit.releaseDate' => 'Erscheinungsdatum',
			'metadataEdit.contentRating' => 'Altersfreigabe',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Zusammenfassung',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Hintergrund',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Quadratisches Bild',
			'metadataEdit.selectPoster' => 'Poster auswählen',
			'metadataEdit.selectBackground' => 'Hintergrund auswählen',
			'metadataEdit.selectLogo' => 'Logo auswählen',
			'metadataEdit.selectSquareArt' => 'Quadratisches Bild auswählen',
			'metadataEdit.fromUrl' => 'Von URL',
			'metadataEdit.uploadFile' => 'Datei hochladen',
			'metadataEdit.enterImageUrl' => 'Bild-URL eingeben',
			'metadataEdit.imageUrl' => 'Bild-URL',
			'metadataEdit.metadataUpdated' => 'Metadaten aktualisiert',
			'metadataEdit.metadataUpdateFailed' => 'Metadaten konnten nicht aktualisiert werden',
			'metadataEdit.artworkUpdated' => 'Artwork aktualisiert',
			'metadataEdit.artworkUpdateFailed' => 'Artwork konnte nicht aktualisiert werden',
			'metadataEdit.noArtworkAvailable' => 'Kein Artwork verfügbar',
			'metadataEdit.notSet' => 'Nicht festgelegt',
			'metadataEdit.libraryDefault' => 'Bibliotheksstandard',
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
			'metadataEdit.tmdbAiring' => 'The Movie Database (Ausgestrahlt)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Ausgestrahlt)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolut)',
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
			'metadataEdit.style' => 'Stil',
			'metadataEdit.mood' => 'Stimmung',
			'matchScreen.match' => 'Zuordnen...',
			'matchScreen.fixMatch' => 'Zuordnung korrigieren...',
			'matchScreen.unmatch' => 'Zuordnung aufheben',
			'matchScreen.unmatchConfirm' => 'Die aktuelle Zuordnung dieses Eintrags entfernen? Plex behandelt ihn als nicht zugeordnet, bis du ihn erneut zuordnest.',
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
			'trakt.disconnectConfirmBody' => 'Plezy sendet keine Wiedergabe-Ereignisse mehr an Trakt. Du kannst dich jederzeit erneut verbinden.',
			'trakt.scrobble' => 'Echtzeit-Scrobbling',
			'trakt.scrobbleDescription' => 'Sende Play-, Pause- und Stopp-Ereignisse während der Wiedergabe an Trakt.',
			'trakt.watchedSync' => 'Gesehen-Status synchronisieren',
			'trakt.watchedSyncDescription' => 'Wenn du Inhalte in Plezy als gesehen markierst, werden sie auch auf Trakt markiert.',
			'trackers.title' => 'Tracker',
			'trackers.hubSubtitle' => 'Halte deinen Wiedergabefortschritt mit Trakt und anderen Diensten synchron.',
			'trackers.notConnected' => 'Nicht verbunden',
			'trackers.connectedAs' => ({required Object username}) => 'Verbunden als @${username}',
			'trackers.scrobble' => 'Fortschritt automatisch verfolgen',
			'trackers.scrobbleDescription' => 'Aktualisiere deine Liste, wenn du eine Folge oder einen Film beendest.',
			'trackers.disconnectConfirm' => ({required Object service}) => '${service} trennen?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy aktualisiert deine ${service}-Liste nicht mehr. Du kannst jederzeit wieder verbinden.',
			'trackers.connectFailed' => ({required Object service}) => 'Verbindung zu ${service} fehlgeschlagen. Versuche es erneut.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Plezy auf ${service} aktivieren',
			'trackers.deviceCode.body' => ({required Object url}) => 'Gehe zu ${url} und gib diesen Code ein:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => '${service} zum Aktivieren öffnen',
			'trackers.deviceCode.waitingForAuthorization' => 'Warte auf Autorisierung…',
			'trackers.deviceCode.codeCopied' => 'Code kopiert',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Bei ${service} anmelden',
			'trackers.oauthProxy.body' => 'Scanne diesen QR-Code mit deinem Handy oder öffne die URL unten auf einem Gerät mit Browser.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => '${service} zum Anmelden öffnen',
			'trackers.oauthProxy.urlCopied' => 'URL kopiert',
			'trackers.libraryFilter.title' => 'Bibliothekfilter',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Alle Bibliotheken werden synchronisiert',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Nichts wird synchronisiert',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blockiert',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} erlaubt',
			'trackers.libraryFilter.mode' => 'Filtermodus',
			'trackers.libraryFilter.modeBlacklist' => 'Blacklist',
			'trackers.libraryFilter.modeWhitelist' => 'Whitelist',
			'trackers.libraryFilter.modeHintBlacklist' => 'Alle Bibliotheken außer den unten markierten synchronisieren.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Nur die unten markierten Bibliotheken synchronisieren.',
			'trackers.libraryFilter.libraries' => 'Bibliotheken',
			'trackers.libraryFilter.noLibraries' => 'Keine Bibliotheken verfügbar',
			_ => null,
		};
	}
}
