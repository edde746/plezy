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
	@override late final _TranslationsPinEntryDe pinEntry = _TranslationsPinEntryDe._(_root);
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
	@override late final _TranslationsDownloadsDe downloads = _TranslationsDownloadsDe._(_root);
	@override late final _TranslationsPlaylistsDe playlists = _TranslationsPlaylistsDe._(_root);
	@override late final _TranslationsCollectionsDe collections = _TranslationsCollectionsDe._(_root);
	@override late final _TranslationsWatchTogetherDe watchTogether = _TranslationsWatchTogetherDe._(_root);
}

// Path: app
class _TranslationsAppDe implements TranslationsAppEn {
	_TranslationsAppDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Lädt...';
}

// Path: auth
class _TranslationsAuthDe implements TranslationsAuthEn {
	_TranslationsAuthDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Mit Plex anmelden';
	@override String get showQRCode => 'QR-Code anzeigen';
	@override String get cancel => 'Abbrechen';
	@override String get authenticate => 'Authentifizieren';
	@override String get retry => 'Erneut versuchen';
	@override String get debugEnterToken => 'Debug: Plex-Token eingeben';
	@override String get plexTokenLabel => 'Plex-Auth-Token';
	@override String get plexTokenHint => 'Plex.tv-Token eingeben';
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
}

// Path: screens
class _TranslationsScreensDe implements TranslationsScreensEn {
	_TranslationsScreensDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lizenzen';
	@override String get selectServer => 'Server auswählen';
	@override String get switchProfile => 'Profil wechseln';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get mpvConfig => 'MPV-Konfiguration';
	@override String get search => 'Suche';
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
	@override String get language => 'Sprache';
	@override String get theme => 'Design';
	@override String get appearance => 'Darstellung';
	@override String get videoPlayback => 'Videowiedergabe';
	@override String get advanced => 'Erweitert';
	@override String get episodePosterMode => 'Episoden-Poster-Stil';
	@override String get seriesPoster => 'Serienposter';
	@override String get seriesPosterDescription => 'Zeige das Serienposter für alle Episoden';
	@override String get seasonPoster => 'Staffelposter';
	@override String get seasonPosterDescription => 'Zeige das staffelspezifische Poster für Episoden';
	@override String get episodeThumbnail => 'Episoden-Miniatur';
	@override String get episodeThumbnailDescription => 'Zeige 16:9 Episoden-Vorschaubilder';
	@override String get showHeroSectionDescription => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen';
	@override String get secondsLabel => 'Sekunden';
	@override String get minutesLabel => 'Minuten';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Systemeinstellungen folgen';
	@override String get lightTheme => 'Hell';
	@override String get darkTheme => 'Dunkel';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Reines Schwarz für OLED-Bildschirme';
	@override String get libraryDensity => 'Mediathekdichte';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Kleinere Karten, mehr Elemente sichtbar';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standardgröße';
	@override String get comfortable => 'Großzügig';
	@override String get comfortableDescription => 'Größere Karten, weniger Elemente sichtbar';
	@override String get viewMode => 'Ansichtsmodus';
	@override String get gridView => 'Raster';
	@override String get gridViewDescription => 'Elemente im Raster anzeigen';
	@override String get listView => 'Liste';
	@override String get listViewDescription => 'Elemente in Listenansicht anzeigen';
	@override String get showHeroSection => 'Hero-Bereich anzeigen';
	@override String get useGlobalHubs => 'Plex-Startseiten-Layout verwenden';
	@override String get useGlobalHubsDescription => 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.';
	@override String get showServerNameOnHubs => 'Servername bei Hubs anzeigen';
	@override String get showServerNameOnHubsDescription => 'Zeigt immer den Servernamen in Hub-Titeln an. Wenn deaktiviert, nur bei doppelten Hub-Namen.';
	@override String get alwaysKeepSidebarOpen => 'Seitenleiste immer geöffnet halten';
	@override String get alwaysKeepSidebarOpenDescription => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an';
	@override String get playerBackend => 'Player-Backend';
	@override String get exoPlayer => 'ExoPlayer (Empfohlen)';
	@override String get exoPlayerDescription => 'Android-nativer Player mit besserer Hardware-Unterstützung';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Erweiterter Player mit mehr Funktionen und ASS-Untertitel-Unterstützung';
	@override String get hardwareDecoding => 'Hardware-Decodierung';
	@override String get hardwareDecodingDescription => 'Hardwarebeschleunigung verwenden, sofern verfügbar';
	@override String get bufferSize => 'Puffergröße';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Untertitel-Stil';
	@override String get subtitleStylingDescription => 'Aussehen von Untertiteln anpassen';
	@override String get smallSkipDuration => 'Kleine Sprungdauer';
	@override String get largeSkipDuration => 'Große Sprungdauer';
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
	@override String get shortcutsReset => 'Tastenkürzel auf Standard zurückgesetzt';
	@override String get about => 'Über';
	@override String get aboutDescription => 'App-Informationen und Lizenzen';
	@override String get updates => 'Updates';
	@override String get updateAvailable => 'Update verfügbar';
	@override String get checkForUpdates => 'Nach Updates suchen';
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
	@override String get cellularDownloadBlocked => 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.';
	@override String get maxVolume => 'Maximale Lautstärke';
	@override String get maxVolumeDescription => 'Lautstärke über 100% für leise Medien erlauben';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => 'Maximale Lautstärke eingeben (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Zeige auf Discord, was du gerade schaust';
	@override String get matchContentFrameRate => 'Inhalts-Bildrate anpassen';
	@override String get matchContentFrameRateDescription => 'Bildwiederholfrequenz des Displays an den Videoinhalt anpassen, reduziert Ruckeln und spart Akku';
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

// Path: pinEntry
class _TranslationsPinEntryDe implements TranslationsPinEntryEn {
	_TranslationsPinEntryDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'PIN eingeben';
	@override String get showPin => 'PIN anzeigen';
	@override String get hidePin => 'PIN verbergen';
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
	@override String get sleepTimer => 'Schlaftimer';
	@override String get timerActive => 'Schlaftimer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert';
	@override String get sleepTimerCompleted => 'Schlaftimer abgelaufen – Wiedergabe pausiert';
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
	@override String get audioTrackButton => 'Tonspuren';
	@override String get subtitlesButton => 'Untertitel';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversionen';
	@override String get pipButton => 'Bild-in-Bild Modus';
	@override String get aspectRatioButton => 'Seitenverhältnis';
	@override String get fullscreenButton => 'Vollbild aktivieren';
	@override String get exitFullscreenButton => 'Vollbild verlassen';
	@override String get alwaysOnTopButton => 'Immer im Vordergrund';
	@override String get rotationLockButton => 'Dreh­sperre';
	@override String get timelineSlider => 'Video-Zeitleiste';
	@override String get volumeSlider => 'Lautstärkepegel';
	@override String get backButton => 'Zurück';
	@override String get pipFailed => 'Bild-in-Bild konnte nicht gestartet werden';
	@override late final _TranslationsVideoControlsPipErrorsDe pipErrors = _TranslationsVideoControlsPipErrorsDe._(_root);
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
	@override String get removedFromContinueWatching => 'Aus ‚Weiterschauen\' entfernt';
	@override String errorLoading({required Object error}) => 'Fehler: ${error}';
	@override String get fileInfoNotAvailable => 'Dateiinfo nicht verfügbar';
	@override String errorLoadingFileInfo({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}';
	@override String get errorLoadingSeries => 'Fehler beim Laden der Serie';
	@override String get errorLoadingSeason => 'Fehler beim Laden der Staffel';
	@override String get musicNotSupported => 'Musikwiedergabe wird noch nicht unterstützt';
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
	@override String get failedToCreatePlayQueue => 'Wiedergabewarteschlange konnte nicht erstellt werden';
	@override String get failedToCreatePlayQueueNoItems => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente';
	@override String failedPlayback({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}';
	@override String get switchingToCompatiblePlayer => 'Wechsle zu kompatiblem Player...';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingDe implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stiloptionen';
	@override String get fontSize => 'Schriftgröße';
	@override String get textColor => 'Textfarbe';
	@override String get borderSize => 'Rahmengröße';
	@override String get borderColor => 'Rahmenfarbe';
	@override String get backgroundOpacity => 'Hintergrunddeckkraft';
	@override String get backgroundColor => 'Hintergrundfarbe';
}

// Path: mpvConfig
class _TranslationsMpvConfigDe implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'MPV-Konfiguration';
	@override String get description => 'Erweiterte Videoplayer-Einstellungen';
	@override String get properties => 'Eigenschaften';
	@override String get presets => 'Voreinstellungen';
	@override String get noProperties => 'Keine Eigenschaften konfiguriert';
	@override String get noPresets => 'Keine gespeicherten Voreinstellungen';
	@override String get addProperty => 'Eigenschaft hinzufügen';
	@override String get editProperty => 'Eigenschaft bearbeiten';
	@override String get deleteProperty => 'Eigenschaft löschen';
	@override String get propertyKey => 'Eigenschaftsschlüssel';
	@override String get propertyKeyHint => 'z.B. hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Eigenschaftswert';
	@override String get propertyValueHint => 'z.B. auto, 256000000';
	@override String get saveAsPreset => 'Als Voreinstellung speichern...';
	@override String get presetName => 'Name der Voreinstellung';
	@override String get presetNameHint => 'Namen für diese Voreinstellung eingeben';
	@override String get loadPreset => 'Laden';
	@override String get deletePreset => 'Löschen';
	@override String get presetSaved => 'Voreinstellung gespeichert';
	@override String get presetLoaded => 'Voreinstellung geladen';
	@override String get presetDeleted => 'Voreinstellung gelöscht';
	@override String get confirmDeletePreset => 'Möchten Sie diese Voreinstellung wirklich löschen?';
	@override String get confirmDeleteProperty => 'Möchten Sie diese Eigenschaft wirklich löschen?';
	@override String entriesCount({required Object count}) => '${count} Einträge';
}

// Path: dialog
class _TranslationsDialogDe implements TranslationsDialogEn {
	_TranslationsDialogDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Aktion bestätigen';
	@override String get cancel => 'Abbrechen';
	@override String get playNow => 'Jetzt abspielen';
}

// Path: discover
class _TranslationsDiscoverDe implements TranslationsDiscoverEn {
	_TranslationsDiscoverDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entdecken';
	@override String get switchProfile => 'Profil wechseln';
	@override String get switchServer => 'Server wechseln';
	@override String get logout => 'Abmelden';
	@override String get noContentAvailable => 'Kein Inhalt verfügbar';
	@override String get addMediaToLibraries => 'Medien zur Mediathek hinzufügen';
	@override String get continueWatching => 'Weiterschauen';
	@override String get play => 'Abspielen';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pause';
	@override String get overview => 'Übersicht';
	@override String get cast => 'Besetzung';
	@override String get seasons => 'Staffeln';
	@override String get studio => 'Studio';
	@override String get rating => 'Altersfreigabe';
	@override String get watched => 'Gesehen';
	@override String episodeCount({required Object count}) => '${count} Episoden';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched} von ${total} gesehen';
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
	@override String get noServersFound => 'Keine Server gefunden';
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
	@override String get error => 'Fehler:';
	@override String get stackTrace => 'Stacktrace:';
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
	@override String get home => 'Start';
	@override String get search => 'Suche';
	@override String get libraries => 'Mediatheken';
	@override String get settings => 'Einstellungen';
	@override String get downloads => 'Downloads';
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
	@override String episodesQueued({required Object count}) => '${count} Episoden zum Download hinzugefügt';
	@override String get downloadDeleted => 'Download gelöscht';
	@override String deleteConfirm({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})';
}

// Path: playlists
class _TranslationsPlaylistsDe implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wiedergabelisten';
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
	@override String get createNewPlaylist => 'Neue Wiedergabeliste erstellen';
	@override String get errorCreating => 'Wiedergabeliste konnte nicht erstellt werden';
	@override String get errorDeleting => 'Wiedergabeliste konnte nicht gelöscht werden';
	@override String get errorLoading => 'Wiedergabelisten konnten nicht geladen werden';
	@override String get errorAdding => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden';
	@override String get errorReordering => 'Element der Wiedergabeliste konnte nicht neu geordnet werden';
	@override String get errorRemoving => 'Konnte nicht aus der Wiedergabeliste entfernt werden';
	@override String get playlist => 'Wiedergabeliste';
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
	@override String get createNewCollection => 'Neue Sammlung erstellen';
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
	@override String get participant => 'Teilnehmer';
	@override String get joinWatchSession => 'Schausitzung Beitreten';
	@override String get enterCodeHint => '8-stelligen Code eingeben';
	@override String get pasteFromClipboard => 'Aus Zwischenablage einfügen';
	@override String get pleaseEnterCode => 'Bitte gib einen Sitzungscode ein';
	@override String get codeMustBe8Chars => 'Sitzungscode muss 8 Zeichen haben';
	@override String get joinInstructions => 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.';
	@override String get failedToCreate => 'Sitzung konnte nicht erstellt werden';
	@override String get failedToJoin => 'Sitzung konnte nicht beigetreten werden';
	@override String get sessionCodeCopied => 'Sitzungscode in Zwischenablage kopiert';
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
	@override String get speedIncrease => 'Geschwindigkeit erhöhen';
	@override String get speedDecrease => 'Geschwindigkeit verringern';
	@override String get speedReset => 'Geschwindigkeit zurücksetzen';
	@override String get subSeekNext => 'Zum nächsten Untertitel springen';
	@override String get subSeekPrev => 'Zum vorherigen Untertitel springen';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsDe implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Erfordert Android 8.0 oder neuer';
	@override String get permissionDisabled => 'Bild-in-Bild-Berechtigung ist deaktiviert. Aktiviere sie unter Einstellungen > Apps > Plezy > Bild-in-Bild';
	@override String get notSupported => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht';
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
	@override String get all => 'Alle';
	@override String get movies => 'Filme';
	@override String get shows => 'Serien';
	@override String get seasons => 'Staffeln';
	@override String get episodes => 'Episoden';
	@override String get folders => 'Ordner';
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
			'app.loading' => 'Lädt...',
			'auth.signInWithPlex' => 'Mit Plex anmelden',
			'auth.showQRCode' => 'QR-Code anzeigen',
			'auth.cancel' => 'Abbrechen',
			'auth.authenticate' => 'Authentifizieren',
			'auth.retry' => 'Erneut versuchen',
			'auth.debugEnterToken' => 'Debug: Plex-Token eingeben',
			'auth.plexTokenLabel' => 'Plex-Auth-Token',
			'auth.plexTokenHint' => 'Plex.tv-Token eingeben',
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
			'screens.licenses' => 'Lizenzen',
			'screens.selectServer' => 'Server auswählen',
			'screens.switchProfile' => 'Profil wechseln',
			'screens.subtitleStyling' => 'Untertitel-Stil',
			'screens.mpvConfig' => 'MPV-Konfiguration',
			'screens.search' => 'Suche',
			'screens.logs' => 'Protokolle',
			'update.available' => 'Update verfügbar',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} ist verfügbar',
			'update.currentVersion' => ({required Object version}) => 'Aktuell: ${version}',
			'update.skipVersion' => 'Diese Version überspringen',
			'update.viewRelease' => 'Release anzeigen',
			'update.latestVersion' => 'Aktuellste Version installiert',
			'update.checkFailed' => 'Fehler bei der Updateprüfung',
			'settings.title' => 'Einstellungen',
			'settings.language' => 'Sprache',
			'settings.theme' => 'Design',
			'settings.appearance' => 'Darstellung',
			'settings.videoPlayback' => 'Videowiedergabe',
			'settings.advanced' => 'Erweitert',
			'settings.episodePosterMode' => 'Episoden-Poster-Stil',
			'settings.seriesPoster' => 'Serienposter',
			'settings.seriesPosterDescription' => 'Zeige das Serienposter für alle Episoden',
			'settings.seasonPoster' => 'Staffelposter',
			'settings.seasonPosterDescription' => 'Zeige das staffelspezifische Poster für Episoden',
			'settings.episodeThumbnail' => 'Episoden-Miniatur',
			'settings.episodeThumbnailDescription' => 'Zeige 16:9 Episoden-Vorschaubilder',
			'settings.showHeroSectionDescription' => 'Bereich mit empfohlenen Inhalten auf der Startseite anzeigen',
			'settings.secondsLabel' => 'Sekunden',
			'settings.minutesLabel' => 'Minuten',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Dauer eingeben (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.systemThemeDescription' => 'Systemeinstellungen folgen',
			'settings.lightTheme' => 'Hell',
			'settings.darkTheme' => 'Dunkel',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Reines Schwarz für OLED-Bildschirme',
			'settings.libraryDensity' => 'Mediathekdichte',
			'settings.compact' => 'Kompakt',
			'settings.compactDescription' => 'Kleinere Karten, mehr Elemente sichtbar',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Standardgröße',
			'settings.comfortable' => 'Großzügig',
			'settings.comfortableDescription' => 'Größere Karten, weniger Elemente sichtbar',
			'settings.viewMode' => 'Ansichtsmodus',
			'settings.gridView' => 'Raster',
			'settings.gridViewDescription' => 'Elemente im Raster anzeigen',
			'settings.listView' => 'Liste',
			'settings.listViewDescription' => 'Elemente in Listenansicht anzeigen',
			'settings.showHeroSection' => 'Hero-Bereich anzeigen',
			'settings.useGlobalHubs' => 'Plex-Startseiten-Layout verwenden',
			'settings.useGlobalHubsDescription' => 'Zeigt Startseiten-Hubs wie der offizielle Plex-Client. Wenn deaktiviert, werden stattdessen Empfehlungen pro Bibliothek angezeigt.',
			'settings.showServerNameOnHubs' => 'Servername bei Hubs anzeigen',
			'settings.showServerNameOnHubsDescription' => 'Zeigt immer den Servernamen in Hub-Titeln an. Wenn deaktiviert, nur bei doppelten Hub-Namen.',
			'settings.alwaysKeepSidebarOpen' => 'Seitenleiste immer geöffnet halten',
			'settings.alwaysKeepSidebarOpenDescription' => 'Seitenleiste bleibt erweitert und Inhaltsbereich passt sich an',
			'settings.playerBackend' => 'Player-Backend',
			'settings.exoPlayer' => 'ExoPlayer (Empfohlen)',
			'settings.exoPlayerDescription' => 'Android-nativer Player mit besserer Hardware-Unterstützung',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Erweiterter Player mit mehr Funktionen und ASS-Untertitel-Unterstützung',
			'settings.hardwareDecoding' => 'Hardware-Decodierung',
			'settings.hardwareDecodingDescription' => 'Hardwarebeschleunigung verwenden, sofern verfügbar',
			'settings.bufferSize' => 'Puffergröße',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Untertitel-Stil',
			'settings.subtitleStylingDescription' => 'Aussehen von Untertiteln anpassen',
			'settings.smallSkipDuration' => 'Kleine Sprungdauer',
			'settings.largeSkipDuration' => 'Große Sprungdauer',
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
			'settings.shortcutsReset' => 'Tastenkürzel auf Standard zurückgesetzt',
			'settings.about' => 'Über',
			'settings.aboutDescription' => 'App-Informationen und Lizenzen',
			'settings.updates' => 'Updates',
			'settings.updateAvailable' => 'Update verfügbar',
			'settings.checkForUpdates' => 'Nach Updates suchen',
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
			'settings.cellularDownloadBlocked' => 'Downloads sind über mobile Daten deaktiviert. Verbinde dich mit einem WLAN oder ändere die Einstellung.',
			'settings.maxVolume' => 'Maximale Lautstärke',
			'settings.maxVolumeDescription' => 'Lautstärke über 100% für leise Medien erlauben',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.maxVolumeHint' => 'Maximale Lautstärke eingeben (100-300)',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Zeige auf Discord, was du gerade schaust',
			'settings.matchContentFrameRate' => 'Inhalts-Bildrate anpassen',
			'settings.matchContentFrameRateDescription' => 'Bildwiederholfrequenz des Displays an den Videoinhalt anpassen, reduziert Ruckeln und spart Akku',
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
			'hotkeys.actions.speedIncrease' => 'Geschwindigkeit erhöhen',
			'hotkeys.actions.speedDecrease' => 'Geschwindigkeit verringern',
			'hotkeys.actions.speedReset' => 'Geschwindigkeit zurücksetzen',
			'hotkeys.actions.subSeekNext' => 'Zum nächsten Untertitel springen',
			'hotkeys.actions.subSeekPrev' => 'Zum vorherigen Untertitel springen',
			'pinEntry.enterPin' => 'PIN eingeben',
			'pinEntry.showPin' => 'PIN anzeigen',
			'pinEntry.hidePin' => 'PIN verbergen',
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
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, Film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, Serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'angesehen',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} Prozent angesehen',
			'accessibility.mediaCardUnwatched' => 'ungeschaut',
			'accessibility.tapToPlay' => 'Zum Abspielen tippen',
			'tooltips.shufflePlay' => 'Zufallswiedergabe',
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
			'videoControls.sleepTimer' => 'Schlaftimer',
			'videoControls.timerActive' => 'Schlaftimer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Wiedergabe wird in ${duration} pausiert',
			'videoControls.sleepTimerCompleted' => 'Schlaftimer abgelaufen – Wiedergabe pausiert',
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
			'videoControls.audioTrackButton' => 'Tonspuren',
			'videoControls.subtitlesButton' => 'Untertitel',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionsButton' => 'Videoversionen',
			'videoControls.pipButton' => 'Bild-in-Bild Modus',
			'videoControls.aspectRatioButton' => 'Seitenverhältnis',
			'videoControls.fullscreenButton' => 'Vollbild aktivieren',
			'videoControls.exitFullscreenButton' => 'Vollbild verlassen',
			'videoControls.alwaysOnTopButton' => 'Immer im Vordergrund',
			'videoControls.rotationLockButton' => 'Dreh­sperre',
			'videoControls.timelineSlider' => 'Video-Zeitleiste',
			'videoControls.volumeSlider' => 'Lautstärkepegel',
			'videoControls.backButton' => 'Zurück',
			'videoControls.pipFailed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.pipErrors.androidVersion' => 'Erfordert Android 8.0 oder neuer',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-in-Bild-Berechtigung ist deaktiviert. Aktiviere sie unter Einstellungen > Apps > Plezy > Bild-in-Bild',
			'videoControls.pipErrors.notSupported' => 'Dieses Gerät unterstützt den Bild-in-Bild-Modus nicht',
			'videoControls.pipErrors.failed' => 'Bild-in-Bild konnte nicht gestartet werden',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ein Fehler ist aufgetreten: ${error}',
			'userStatus.admin' => 'Eigentümer',
			'userStatus.restricted' => 'Eingeschränkt',
			'userStatus.protected' => 'Geschützt',
			'userStatus.current' => 'AKTUELL',
			'messages.markedAsWatched' => 'Als gesehen markiert',
			'messages.markedAsUnwatched' => 'Als ungesehen markiert',
			'messages.markedAsWatchedOffline' => 'Als gesehen markiert (wird synchronisiert, wenn online)',
			'messages.markedAsUnwatchedOffline' => 'Als ungesehen markiert (wird synchronisiert, wenn online)',
			'messages.removedFromContinueWatching' => 'Aus ‚Weiterschauen\' entfernt',
			'messages.errorLoading' => ({required Object error}) => 'Fehler: ${error}',
			'messages.fileInfoNotAvailable' => 'Dateiinfo nicht verfügbar',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fehler beim Laden der Dateiinfo: ${error}',
			'messages.errorLoadingSeries' => 'Fehler beim Laden der Serie',
			'messages.errorLoadingSeason' => 'Fehler beim Laden der Staffel',
			'messages.musicNotSupported' => 'Musikwiedergabe wird noch nicht unterstützt',
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
			'messages.failedToCreatePlayQueue' => 'Wiedergabewarteschlange konnte nicht erstellt werden',
			'messages.failedToCreatePlayQueueNoItems' => 'Wiedergabewarteschlange konnte nicht erstellt werden – keine Elemente',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Wiedergabe für ${action} fehlgeschlagen: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Wechsle zu kompatiblem Player...',
			'subtitlingStyling.stylingOptions' => 'Stiloptionen',
			'subtitlingStyling.fontSize' => 'Schriftgröße',
			'subtitlingStyling.textColor' => 'Textfarbe',
			'subtitlingStyling.borderSize' => 'Rahmengröße',
			'subtitlingStyling.borderColor' => 'Rahmenfarbe',
			'subtitlingStyling.backgroundOpacity' => 'Hintergrunddeckkraft',
			'subtitlingStyling.backgroundColor' => 'Hintergrundfarbe',
			'mpvConfig.title' => 'MPV-Konfiguration',
			'mpvConfig.description' => 'Erweiterte Videoplayer-Einstellungen',
			'mpvConfig.properties' => 'Eigenschaften',
			'mpvConfig.presets' => 'Voreinstellungen',
			'mpvConfig.noProperties' => 'Keine Eigenschaften konfiguriert',
			'mpvConfig.noPresets' => 'Keine gespeicherten Voreinstellungen',
			'mpvConfig.addProperty' => 'Eigenschaft hinzufügen',
			'mpvConfig.editProperty' => 'Eigenschaft bearbeiten',
			'mpvConfig.deleteProperty' => 'Eigenschaft löschen',
			'mpvConfig.propertyKey' => 'Eigenschaftsschlüssel',
			'mpvConfig.propertyKeyHint' => 'z.B. hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Eigenschaftswert',
			'mpvConfig.propertyValueHint' => 'z.B. auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Als Voreinstellung speichern...',
			'mpvConfig.presetName' => 'Name der Voreinstellung',
			'mpvConfig.presetNameHint' => 'Namen für diese Voreinstellung eingeben',
			'mpvConfig.loadPreset' => 'Laden',
			'mpvConfig.deletePreset' => 'Löschen',
			'mpvConfig.presetSaved' => 'Voreinstellung gespeichert',
			'mpvConfig.presetLoaded' => 'Voreinstellung geladen',
			'mpvConfig.presetDeleted' => 'Voreinstellung gelöscht',
			'mpvConfig.confirmDeletePreset' => 'Möchten Sie diese Voreinstellung wirklich löschen?',
			'mpvConfig.confirmDeleteProperty' => 'Möchten Sie diese Eigenschaft wirklich löschen?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} Einträge',
			'dialog.confirmAction' => 'Aktion bestätigen',
			'dialog.cancel' => 'Abbrechen',
			'dialog.playNow' => 'Jetzt abspielen',
			'discover.title' => 'Entdecken',
			'discover.switchProfile' => 'Profil wechseln',
			'discover.switchServer' => 'Server wechseln',
			'discover.logout' => 'Abmelden',
			'discover.noContentAvailable' => 'Kein Inhalt verfügbar',
			'discover.addMediaToLibraries' => 'Medien zur Mediathek hinzufügen',
			'discover.continueWatching' => 'Weiterschauen',
			'discover.play' => 'Abspielen',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.pause' => 'Pause',
			'discover.overview' => 'Übersicht',
			'discover.cast' => 'Besetzung',
			'discover.seasons' => 'Staffeln',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Altersfreigabe',
			'discover.watched' => 'Gesehen',
			'discover.episodeCount' => ({required Object count}) => '${count} Episoden',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched} von ${total} gesehen',
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
			'serverSelection.noServersFound' => 'Keine Server gefunden',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Keine Server gefunden für ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Server konnten nicht geladen werden: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Erscheinungsjahr',
			'hubDetail.dateAdded' => 'Hinzugefügt am',
			'hubDetail.rating' => 'Bewertung',
			'hubDetail.noItemsFound' => 'Keine Elemente gefunden',
			'logs.clearLogs' => 'Protokolle löschen',
			'logs.copyLogs' => 'Protokolle kopieren',
			'logs.error' => 'Fehler:',
			'logs.stackTrace' => 'Stacktrace:',
			'licenses.relatedPackages' => 'Verwandte Pakete',
			'licenses.license' => 'Lizenz',
			'licenses.licenseNumber' => ({required Object number}) => 'Lizenz ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} Lizenzen',
			'navigation.home' => 'Start',
			'navigation.search' => 'Suche',
			'navigation.libraries' => 'Mediatheken',
			'navigation.settings' => 'Einstellungen',
			'navigation.downloads' => 'Downloads',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} Episoden zum Download hinzugefügt',
			'downloads.downloadDeleted' => 'Download gelöscht',
			'downloads.deleteConfirm' => ({required Object title}) => 'Möchtest du "${title}" wirklich löschen? Die heruntergeladene Datei wird von deinem Gerät entfernt.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Lösche ${title}... (${current} von ${total})',
			'playlists.title' => 'Wiedergabelisten',
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
			'playlists.createNewPlaylist' => 'Neue Wiedergabeliste erstellen',
			'playlists.errorCreating' => 'Wiedergabeliste konnte nicht erstellt werden',
			'playlists.errorDeleting' => 'Wiedergabeliste konnte nicht gelöscht werden',
			'playlists.errorLoading' => 'Wiedergabelisten konnten nicht geladen werden',
			'playlists.errorAdding' => 'Konnte nicht zur Wiedergabeliste hinzugefügt werden',
			'playlists.errorReordering' => 'Element der Wiedergabeliste konnte nicht neu geordnet werden',
			'playlists.errorRemoving' => 'Konnte nicht aus der Wiedergabeliste entfernt werden',
			'playlists.playlist' => 'Wiedergabeliste',
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
			'collections.createNewCollection' => 'Neue Sammlung erstellen',
			'collections.collectionName' => 'Sammlungsname',
			'collections.enterCollectionName' => 'Sammlungsnamen eingeben',
			'collections.addedToCollection' => 'Zur Sammlung hinzugefügt',
			'collections.errorAddingToCollection' => 'Fehler beim Hinzufügen zur Sammlung',
			'collections.created' => 'Sammlung erstellt',
			'collections.removeFromCollection' => 'Aus Sammlung entfernen',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '"${title}" aus dieser Sammlung entfernen?',
			_ => null,
		} ?? switch (path) {
			'collections.removedFromCollection' => 'Aus Sammlung entfernt',
			'collections.removeFromCollectionFailed' => 'Entfernen aus Sammlung fehlgeschlagen',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fehler beim Entfernen aus der Sammlung: ${error}',
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
			'watchTogether.participant' => 'Teilnehmer',
			'watchTogether.joinWatchSession' => 'Schausitzung Beitreten',
			'watchTogether.enterCodeHint' => '8-stelligen Code eingeben',
			'watchTogether.pasteFromClipboard' => 'Aus Zwischenablage einfügen',
			'watchTogether.pleaseEnterCode' => 'Bitte gib einen Sitzungscode ein',
			'watchTogether.codeMustBe8Chars' => 'Sitzungscode muss 8 Zeichen haben',
			'watchTogether.joinInstructions' => 'Gib den vom Host geteilten Sitzungscode ein, um seiner Schausitzung beizutreten.',
			'watchTogether.failedToCreate' => 'Sitzung konnte nicht erstellt werden',
			'watchTogether.failedToJoin' => 'Sitzung konnte nicht beigetreten werden',
			'watchTogether.sessionCodeCopied' => 'Sitzungscode in Zwischenablage kopiert',
			_ => null,
		};
	}
}
