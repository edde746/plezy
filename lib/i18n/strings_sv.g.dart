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
class TranslationsSv extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsSv({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.sv,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sv>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsSv _root = this; // ignore: unused_field

	@override 
	TranslationsSv $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsSv(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppSv app = _TranslationsAppSv._(_root);
	@override late final _TranslationsAuthSv auth = _TranslationsAuthSv._(_root);
	@override late final _TranslationsCommonSv common = _TranslationsCommonSv._(_root);
	@override late final _TranslationsScreensSv screens = _TranslationsScreensSv._(_root);
	@override late final _TranslationsUpdateSv update = _TranslationsUpdateSv._(_root);
	@override late final _TranslationsSettingsSv settings = _TranslationsSettingsSv._(_root);
	@override late final _TranslationsSearchSv search = _TranslationsSearchSv._(_root);
	@override late final _TranslationsHotkeysSv hotkeys = _TranslationsHotkeysSv._(_root);
	@override late final _TranslationsFileInfoSv fileInfo = _TranslationsFileInfoSv._(_root);
	@override late final _TranslationsMediaMenuSv mediaMenu = _TranslationsMediaMenuSv._(_root);
	@override late final _TranslationsRateSheetSv rateSheet = _TranslationsRateSheetSv._(_root);
	@override late final _TranslationsAccessibilitySv accessibility = _TranslationsAccessibilitySv._(_root);
	@override late final _TranslationsTooltipsSv tooltips = _TranslationsTooltipsSv._(_root);
	@override late final _TranslationsVideoControlsSv videoControls = _TranslationsVideoControlsSv._(_root);
	@override late final _TranslationsMessagesSv messages = _TranslationsMessagesSv._(_root);
	@override late final _TranslationsSubtitlingStylingSv subtitlingStyling = _TranslationsSubtitlingStylingSv._(_root);
	@override late final _TranslationsMpvConfigSv mpvConfig = _TranslationsMpvConfigSv._(_root);
	@override late final _TranslationsDialogSv dialog = _TranslationsDialogSv._(_root);
	@override late final _TranslationsProfilesSv profiles = _TranslationsProfilesSv._(_root);
	@override late final _TranslationsConnectionsSv connections = _TranslationsConnectionsSv._(_root);
	@override late final _TranslationsDiscoverSv discover = _TranslationsDiscoverSv._(_root);
	@override late final _TranslationsErrorsSv errors = _TranslationsErrorsSv._(_root);
	@override late final _TranslationsLibrariesSv libraries = _TranslationsLibrariesSv._(_root);
	@override late final _TranslationsAboutSv about = _TranslationsAboutSv._(_root);
	@override late final _TranslationsServerSelectionSv serverSelection = _TranslationsServerSelectionSv._(_root);
	@override late final _TranslationsHubDetailSv hubDetail = _TranslationsHubDetailSv._(_root);
	@override late final _TranslationsLogsSv logs = _TranslationsLogsSv._(_root);
	@override late final _TranslationsLicensesSv licenses = _TranslationsLicensesSv._(_root);
	@override late final _TranslationsNavigationSv navigation = _TranslationsNavigationSv._(_root);
	@override late final _TranslationsExploreSv explore = _TranslationsExploreSv._(_root);
	@override late final _TranslationsLiveTvSv liveTv = _TranslationsLiveTvSv._(_root);
	@override late final _TranslationsCollectionsSv collections = _TranslationsCollectionsSv._(_root);
	@override late final _TranslationsPlaylistsSv playlists = _TranslationsPlaylistsSv._(_root);
	@override late final _TranslationsMusicSv music = _TranslationsMusicSv._(_root);
	@override late final _TranslationsWatchTogetherSv watchTogether = _TranslationsWatchTogetherSv._(_root);
	@override late final _TranslationsDownloadsSv downloads = _TranslationsDownloadsSv._(_root);
	@override late final _TranslationsShadersSv shaders = _TranslationsShadersSv._(_root);
	@override late final _TranslationsCompanionRemoteSv companionRemote = _TranslationsCompanionRemoteSv._(_root);
	@override late final _TranslationsVideoSettingsSv videoSettings = _TranslationsVideoSettingsSv._(_root);
	@override late final _TranslationsPerformanceOverlaySv performanceOverlay = _TranslationsPerformanceOverlaySv._(_root);
	@override late final _TranslationsExternalPlayerSv externalPlayer = _TranslationsExternalPlayerSv._(_root);
	@override late final _TranslationsMetadataEditSv metadataEdit = _TranslationsMetadataEditSv._(_root);
	@override late final _TranslationsMatchScreenSv matchScreen = _TranslationsMatchScreenSv._(_root);
	@override late final _TranslationsServerTasksSv serverTasks = _TranslationsServerTasksSv._(_root);
	@override late final _TranslationsTraktSv trakt = _TranslationsTraktSv._(_root);
	@override late final _TranslationsSeerrSv seerr = _TranslationsSeerrSv._(_root);
	@override late final _TranslationsServicesSv services = _TranslationsServicesSv._(_root);
	@override late final _TranslationsAddServerSv addServer = _TranslationsAddServerSv._(_root);
}

// Path: app
class _TranslationsAppSv extends TranslationsAppEn {
	_TranslationsAppSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthSv extends TranslationsAuthEn {
	_TranslationsAuthSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logga in med Plex';
	@override String get showQRCode => 'Visa QR-kod';
	@override String get authenticate => 'Autentisera';
	@override String get authenticationTimeout => 'Autentisering tog för lång tid. Försök igen.';
	@override String get scanQRToSignIn => 'Skanna QR-koden för att logga in';
	@override String get waitingForAuth => 'Väntar på autentisering...\nLogga in från din webbläsare.';
	@override String get useBrowser => 'Använd webbläsare';
	@override String get or => 'eller';
	@override String get connectToJellyfin => 'Anslut till Jellyfin';
	@override String get useQuickConnect => 'Använd Quick Connect';
	@override String get quickConnectInstructions => 'Öppna Quick Connect i Jellyfin och ange den här koden.';
	@override String get quickConnectWaiting => 'Väntar på godkännande…';
	@override String get quickConnectCancel => 'Avbryt';
	@override String get quickConnectExpired => 'Quick Connect har gått ut. Försök igen.';
}

// Path: common
class _TranslationsCommonSv extends TranslationsCommonEn {
	_TranslationsCommonSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Avbryt';
	@override String get save => 'Spara';
	@override String get close => 'Stäng';
	@override String get clear => 'Rensa';
	@override String get reset => 'Återställ';
	@override String get later => 'Senare';
	@override String get submit => 'Skicka';
	@override String get confirm => 'Bekräfta';
	@override String get retry => 'Försök igen';
	@override String get logout => 'Logga ut';
	@override String get unknown => 'Okänd';
	@override String get refresh => 'Uppdatera';
	@override String get yes => 'Ja';
	@override String get no => 'Nej';
	@override String get delete => 'Ta bort';
	@override String get edit => 'Redigera';
	@override String get shuffle => 'Blanda';
	@override String get addTo => 'Lägg till i...';
	@override String get createNew => 'Skapa ny';
	@override String get connect => 'Anslut';
	@override String get disconnect => 'Koppla från';
	@override String get play => 'Spela';
	@override String get pause => 'Pausa';
	@override String get resume => 'Återuppta';
	@override String get error => 'Fel';
	@override String get search => 'Sök';
	@override String get home => 'Hem';
	@override String get back => 'Tillbaka';
	@override String get settings => 'Mer';
	@override String get mute => 'Ljud av';
	@override String get ok => 'OK';
	@override String get off => 'Av';
	@override String seasonNumber({required Object number}) => 'Säsong ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Avsnitt ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Kapitel ${number}';
	@override String get reconnect => 'Återanslut';
	@override String get viewAll => 'Visa alla';
	@override String get checkingNetwork => 'Kontrollerar nätverk...';
	@override String get loadingServers => 'Laddar servrar...';
	@override String get connectingToServers => 'Ansluter till servrar...';
	@override String get startingOfflineMode => 'Startar offlineläge...';
	@override String get loading => 'Laddar...';
	@override String get fullscreen => 'Helskärm';
	@override String get exitFullscreen => 'Avsluta helskärm';
	@override String get pressBackAgainToExit => 'Tryck bakåt igen för att avsluta';
}

// Path: screens
class _TranslationsScreensSv extends TranslationsScreensEn {
	_TranslationsScreensSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get switchProfile => 'Byt profil';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Loggar';
}

// Path: update
class _TranslationsUpdateSv extends TranslationsUpdateEn {
	_TranslationsUpdateSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get available => 'Uppdatering tillgänglig';
	@override String versionAvailable({required Object version}) => 'Version ${version} är tillgänglig';
	@override String currentVersion({required Object version}) => 'Nuvarande: ${version}';
	@override String get skipVersion => 'Hoppa över denna version';
	@override String get viewRelease => 'Visa release';
	@override String get latestVersion => 'Du har den senaste versionen';
	@override String get checkFailed => 'Misslyckades att kontrollera uppdateringar';
}

// Path: settings
class _TranslationsSettingsSv extends TranslationsSettingsEn {
	_TranslationsSettingsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Inställningar';
	@override String get supportDeveloper => 'Stöd Plezy';
	@override String get supportDeveloperDescription => 'Donera via Liberapay för att finansiera utvecklingen';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videouppspelning';
	@override String get videoPlaybackDescription => 'Konfigurera uppspelningsbeteende';
	@override String get advanced => 'Avancerat';
	@override String get episodePosterMode => 'Avsnittsaffisch-stil';
	@override String get seriesPoster => 'Serieaffisch';
	@override String get seasonPoster => 'Säsongsaffisch';
	@override String get episodeThumbnail => 'Miniatyr';
	@override String get showHeroSectionDescription => 'Visa utvalda innehållskarusell på startsidan';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minuter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Ange tid (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Ljust';
	@override String get darkTheme => 'Mörkt';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Biblioteksdensitet';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Bekväm';
	@override String get viewMode => 'Visningsläge';
	@override String get gridView => 'Rutnät';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Visa hjältesektion';
	@override String get continueWatchingAction => 'Åtgärd för Fortsätt titta';
	@override String get continueWatchingPlay => 'Spela';
	@override String get continueWatchingDetails => 'Öppna detaljer';
	@override String get episodeAction => 'Åtgärd för avsnitt';
	@override String get episodePlay => 'Spela';
	@override String get episodeDetails => 'Öppna detaljer';
	@override String get useGlobalHubs => 'Använd startlayout';
	@override String get useGlobalHubsDescription => 'Visa enhetliga startsideshubbar. Annars används biblioteksrekommendationer.';
	@override String get showServerNameOnHubs => 'Visa servernamn på hubbar';
	@override String get showServerNameOnHubsDescription => 'Visa alltid servernamn i hubbtitlar.';
	@override String get groupLibrariesByServer => 'Gruppera bibliotek efter server';
	@override String get groupLibrariesByServerDescription => 'Gruppera sidofältsbibliotek under varje medieserver.';
	@override String get alwaysKeepSidebarOpen => 'Håll sidofältet alltid öppet';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidofältet förblir expanderat och innehållsytan anpassas';
	@override String get showUnwatchedCount => 'Visa antal osedda';
	@override String get showUnwatchedCountDescription => 'Visa antal osedda avsnitt för serier och säsonger';
	@override String get showEpisodeNumberOnCards => 'Visa avsnittsnummer på kort';
	@override String get showEpisodeNumberOnCardsDescription => 'Visa säsongs- och avsnittsnummer på avsnittskort';
	@override String get showSeasonPostersOnTabs => 'Visa säsongsaffischer på flikar';
	@override String get showSeasonPostersOnTabsDescription => 'Visa varje säsongs affisch ovanför fliken';
	@override String get tvFullCardLayout => 'Heltäckande TV-kort';
	@override String get tvFullCardLayoutDescription => 'Använd TV-kort med enbart bild och skådespelarnamn ovanpå';
	@override String get focusGlow => 'Fokusglöd';
	@override String get focusGlowDescription => 'Visa en mjuk glöd runt kortet i fokus';
	@override String get visualEffects => 'Visuella effekter';
	@override String get visualEffectsAuto => 'Automatiskt';
	@override String get visualEffectsAutoDescription => 'Minska effekter automatiskt på enheter med låg effekt';
	@override String get visualEffectsFull => 'Fullständiga';
	@override String get visualEffectsReduced => 'Minskade';
	@override String get visualEffectsReducedDescription => 'Färre animationer och grafik med lägre upplösning';
	@override String get hideSpoilers => 'Dölj spoilers för osedda avsnitt';
	@override String get hideSpoilersDescription => 'Sudda miniatyrbilder och beskrivningar för osedda avsnitt';
	@override String get playerBackend => 'Spelarmotor';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hårdvaruavkodning';
	@override String get hardwareDecodingDescription => 'Använd hårdvaruacceleration när tillgängligt';
	@override String get bufferSize => 'Bufferstorlek';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Rekommenderat)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB minne tillgängligt. En buffert på ${size}MB kan påverka uppspelningen.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get musicQualityTitle => 'Musikkvalitet';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get subtitleStylingDescription => 'Anpassa undertextutseende';
	@override String get smallSkipDuration => 'Kort hoppvaraktighet';
	@override String get largeSkipDuration => 'Lång hoppvaraktighet';
	@override String get rewindOnResume => 'Spola tillbaka vid återupptagning';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard sovtimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuter';
	@override String get rememberTrackSelections => 'Kom ihåg spårval per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Kom ihåg ljud- och undertextval per titel';
	@override String get showChapterMarkersOnTimeline => 'Visa kapitelmarkörer på tidslinjen';
	@override String get showChapterMarkersOnTimelineDescription => 'Dela upp tidslinjen vid kapitelgränser';
	@override String get clickVideoTogglesPlayback => 'Klicka på videon för att växla mellan spela upp och pausa.';
	@override String get clickVideoTogglesPlaybackDescription => 'Klicka på video för att spela/pausa istället för att visa kontroller.';
	@override String get videoPlayerControls => 'Videospelar-kontroller';
	@override String get keyboardShortcuts => 'Tangentbordsgenvägar';
	@override String get keyboardShortcutsDescription => 'Anpassa tangentbordsgenvägar';
	@override String get videoPlayerNavigation => 'Navigering i videospelaren';
	@override String get videoPlayerNavigationDescription => 'Använd piltangenter för att navigera videospelarens kontroller';
	@override String get watchTogetherRelay => 'Titta Tillsammans-relay';
	@override String get watchTogetherRelayDescription => 'Ange en anpassad relay. Alla måste använda samma server.';
	@override String get watchTogetherRelayHint => 'https://min-relay.exempel.se';
	@override String get crashReporting => 'Kraschrapportering';
	@override String get crashReportingDescription => 'Skicka kraschrapporter för att förbättra appen';
	@override String get debugLogging => 'Felsökningsloggning';
	@override String get debugLoggingDescription => 'Aktivera detaljerad loggning för felsökning';
	@override String get viewLogs => 'Visa loggar';
	@override String get viewLogsDescription => 'Visa applikationsloggar';
	@override String get clearCache => 'Rensa cache';
	@override String get clearCacheDescription => 'Rensa cachade bilder och data. Innehåll kan laddas långsammare.';
	@override String get clearCacheSuccess => 'Cache rensad framgångsrikt';
	@override String get resetSettings => 'Återställ inställningar';
	@override String get resetSettingsDescription => 'Återställ standardinställningar. Detta kan inte ångras.';
	@override String get resetSettingsSuccess => 'Inställningar återställda framgångsrikt';
	@override String get backup => 'Säkerhetskopia';
	@override String get exportSettings => 'Exportera inställningar';
	@override String get exportSettingsDescription => 'Spara dina inställningar till en fil';
	@override String get exportSettingsSuccess => 'Inställningar exporterade';
	@override String get exportSettingsFailed => 'Kunde inte exportera inställningar';
	@override String get importSettings => 'Importera inställningar';
	@override String get importSettingsDescription => 'Återställ inställningar från en fil';
	@override String get importSettingsConfirm => 'Detta ersätter dina nuvarande inställningar. Fortsätta?';
	@override String get importSettingsSuccess => 'Inställningar importerade';
	@override String get importSettingsFailed => 'Kunde inte importera inställningar';
	@override String get importSettingsInvalidFile => 'Denna fil är inte en giltig Plezy-export';
	@override String get importSettingsNoUser => 'Logga in innan du importerar inställningar';
	@override String get shortcutsReset => 'Genvägar återställda till standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'Appinformation och licenser';
	@override String get updates => 'Uppdateringar';
	@override String get updateAvailable => 'Uppdatering tillgänglig';
	@override String get checkForUpdates => 'Kontrollera uppdateringar';
	@override String get autoCheckUpdatesOnStartup => 'Kontrollera uppdateringar automatiskt vid start';
	@override String get autoCheckUpdatesOnStartupDescription => 'Meddela när en uppdatering finns vid start';
	@override String get validationErrorEnterNumber => 'Vänligen ange ett giltigt nummer';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Genväg redan tilldelad ${action}';
	@override String shortcutUpdated({required Object action}) => 'Genväg uppdaterad för ${action}';
	@override String get autoSkip => 'Auto Hoppa Över';
	@override String get autoSkipIntro => 'Hoppa Över Intro Automatiskt';
	@override String get autoSkipIntroDescription => 'Hoppa automatiskt över intro-markörer efter några sekunder';
	@override String get autoSkipCredits => 'Hoppa Över Credits Automatiskt';
	@override String get autoSkipCreditsDescription => 'Hoppa automatiskt över credits och spela nästa avsnitt';
	@override String get forceSkipMarkerFallback => 'Tvinga reservmarkörer';
	@override String get forceSkipMarkerFallbackDescription => 'Använd mönster i kapiteltitlar även när Plex har markörer';
	@override String get autoSkipDelay => 'Fördröjning Auto Hoppa Över';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning';
	@override String get introPattern => 'Intromarkörsmönster';
	@override String get introPatternDescription => 'Reguljärt uttryck för att matcha intromarkörer i kapiteltitlar';
	@override String get creditsPattern => 'Eftertextmarkörsmönster';
	@override String get creditsPatternDescription => 'Reguljärt uttryck för att matcha eftertextmarkörer i kapiteltitlar';
	@override String get invalidRegex => 'Ogiltigt reguljärt uttryck';
	@override String get regex => 'Reguljärt uttryck';
	@override String get downloads => 'Nedladdningar';
	@override String get downloadLocationDescription => 'Välj var nedladdat innehåll ska lagras';
	@override String get downloadLocationDefault => 'Standard (App-lagring)';
	@override String get downloadLocationCustom => 'Anpassad Plats';
	@override String get selectFolder => 'Välj Mapp';
	@override String get resetToDefault => 'Återställ till Standard';
	@override String currentPath({required Object path}) => 'Nuvarande: ${path}';
	@override String get downloadLocationChanged => 'Nedladdningsplats ändrad';
	@override String get downloadLocationReset => 'Nedladdningsplats återställd till standard';
	@override String get downloadLocationInvalid => 'Vald mapp är inte skrivbar';
	@override String get downloadLocationSelectError => 'Kunde inte välja mapp';
	@override String get downloadOnWifiOnly => 'Ladda ner endast på WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Förhindra nedladdningar vid användning av mobildata';
	@override String get autoRemoveWatchedDownloads => 'Ta bort sedda nedladdningar automatiskt';
	@override String get autoRemoveWatchedDownloadsDescription => 'Ta bort sedda nedladdningar automatiskt';
	@override String get cellularDownloadBlocked => 'Nedladdningar är blockerade via mobilnät. Använd WiFi eller ändra inställningen.';
	@override String get maxVolume => 'Maximal volym';
	@override String get maxVolumeDescription => 'Tillåt volym över 100% för tyst media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Visa vad du tittar på i Discord';
	@override String get services => 'Tjänster';
	@override String get servicesDescription => 'Anslut Trakt, MyAnimeList, Seerr med mera';
	@override String get manageLibrariesDescription => 'Ordna om och dölj bibliotek';
	@override String get companionRemoteServer => 'Companion Remote-server';
	@override String get companionRemoteServerDescription => 'Tillåt mobila enheter i ditt nätverk att styra denna app';
	@override String get autoPip => 'Automatisk bild-i-bild';
	@override String get autoPipDescription => 'Gå till bild-i-bild när du lämnar under uppspelning';
	@override String get matchContentFrameRate => 'Matcha innehållets bildfrekvens';
	@override String get matchContentFrameRateDescription => 'Matcha skärmens uppdateringsfrekvens med videoinnehållet';
	@override String get matchRefreshRate => 'Matcha uppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Matcha skärmens uppdateringsfrekvens i helskärm';
	@override String get matchDynamicRange => 'Matcha dynamiskt omfång';
	@override String get matchDynamicRangeDescription => 'Slå på HDR för HDR-innehåll och sedan tillbaka till SDR';
	@override String get displaySwitchDelay => 'Fördröjning vid skärmbyte';
	@override String get tunneledPlayback => 'Tunneluppspelning';
	@override String get tunneledPlaybackDescription => 'Använd videotunnling. Inaktivera om HDR-uppspelning visar svart video.';
	@override String get audioPassthrough => 'Ljudgenomkoppling';
	@override String get audioPassthroughDescription => 'Skicka Dolby/DTS-ljud till din receiver eller TV utan omkodning och bevara surroundljudet. Stäng av om du inte har något ljud.';
	@override String get audioPassthroughDescriptionAppleTv => 'Lämnar Dolby Digital Plus (inkl. Atmos) till systemet som bitstream. DTS och TrueHD spelas fortfarande upp som flerkanals-PCM. Korta ljudavbrott kan förekomma vid sökning.';
	@override String get audioDownmix => 'Nedmixning till stereo';
	@override String get audioDownmixDescription => 'Mixar ner surroundljud till två kanaler för stereohögtalare eller hörlurar';
	@override String get downmixCenterBoost => 'Förstärkning av centerkanal';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Förstärkning (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalisera ljudstyrka vid nedmixning';
	@override String get audioDownmixNormalizeDescription => 'Sänker mixen för att undvika klippning. Stäng av för att behålla originalvolymen (höga scener kan förvrängas).';
	@override String get atmosDiagnostics => 'Atmos-utgångstest';
	@override String get atmosDiagnosticsDescription => 'Diagnostisera Dolby Atmos-utgången genom att spela testsignaler via systemspelaren';
	@override String get atmosTestHlsAtmos => 'Apple Atmos-ström';
	@override String get atmosTestHlsAtmosDescription => 'Känd fungerande Dolby Atmos-ström. Receivern bör visa Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Apple surround-ström';
	@override String get atmosTestHlsControlDescription => 'Kontrollström utan Atmos. Receivern bör visa surround utan Atmos.';
	@override String get atmosTestRawStream => 'Rå EAC3-ström';
	@override String get atmosTestRawStreamDescription => 'Strömmar testfilen precis som Atmos-uppspelning i spelaren. Kräver testfilens URL.';
	@override String get atmosTestRawFile => 'Rå EAC3-fil';
	@override String get atmosTestRawFileDescription => 'Spelar upp testfilen med känd längd. Kräver testfilens URL.';
	@override String get atmosTestStop => 'Stoppa test';
	@override String get atmosTestUrl => 'Testfilens URL';
	@override String get atmosTestUrlDescription => 'HTTP-URL till en rå .ec3 Dolby Atmos-fil (t.ex. extraherad med ffmpeg)';
	@override String get atmosTestUrlMissing => 'Ange testfilens URL först';
	@override String get atmosTestStatus => 'Status';
	@override String get dvConversionMode => 'Dolby Vision-konvertering';
	@override String get dvConversionModeDescription => 'Välj hur ExoPlayer hanterar Dolby Vision Profile 7-filer.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Inbyggt / inaktiverat';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Använd enhetens kapabilitetsdetektering och normalt reservbeteende';
	@override String get dvConversionNativeDescription => 'Tvinga native DV7 och undertryck försök till DV-konvertering';
	@override String get dvConversionDv81Description => 'Tvinga inline RPU-konvertering till Dolby Vision profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Ta bort Dolby Vision RPU/EL-lager och presentera vanlig HEVC';
	@override String get requireProfileSelectionOnOpen => 'Fråga efter profil vid appstart';
	@override String get requireProfileSelectionOnOpenDescription => 'Visa profilval varje gång appen öppnas';
	@override String get forceTvMode => 'Tvinga TV-läge';
	@override String get forceTvModeDescription => 'Tvinga TV-layout. För enheter som inte upptäcks automatiskt. Kräver omstart.';
	@override String get startInFullscreen => 'Starta i helskärm';
	@override String get startInFullscreenDescription => 'Öppna Plezy i helskärm vid start';
	@override String get exitFullscreenOnPlayerClose => 'Avsluta helskärm vid stängning av spelare';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Avslutar automatiskt helskärmsläge när videospelaren stängs';
	@override String get autoHidePerformanceOverlay => 'Dölj prestandaöverlagring automatiskt';
	@override String get autoHidePerformanceOverlayDescription => 'Tona prestandaöverlagringen med uppspelningskontrollerna';
	@override String get showNavBarLabels => 'Visa navigeringsfältets etiketter';
	@override String get showNavBarLabelsDescription => 'Visa textetiketter under navigeringsfältets ikoner';
	@override String get startupSection => 'Startsektion';
	@override String get liveTvDefaultFavorites => 'Standard till favoritkanaler';
	@override String get liveTvDefaultFavoritesDescription => 'Visa bara favoritkanaler när du öppnar Live TV';
	@override String get display => 'Skärm';
	@override String get homeScreen => 'Hemskärm';
	@override String get navigation => 'Navigering';
	@override String get window => 'Fönster';
	@override String get content => 'Innehåll';
	@override String get player => 'Spelare';
	@override String get subtitlesAndConfig => 'Undertexter och konfiguration';
	@override String get seekAndTiming => 'Sök och timing';
	@override String get behavior => 'Beteende';
}

// Path: search
class _TranslationsSearchSv extends TranslationsSearchEn {
	_TranslationsSearchSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Sök filmer, serier, musik...';
	@override String get tryDifferentTerm => 'Prova en annan sökterm';
	@override String get searchYourMedia => 'Sök i dina media';
	@override String get enterTitleActorOrKeyword => 'Ange en titel, skådespelare eller nyckelord';
}

// Path: hotkeys
class _TranslationsHotkeysSv extends TranslationsHotkeysEn {
	_TranslationsHotkeysSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Sätt genväg för ${actionName}';
	@override String get clearShortcut => 'Rensa genväg';
	@override String get noShortcutSet => 'Ingen genväg angiven';
	@override String get currentShortcut => 'Aktuell genväg:';
	@override String get pressToRecord => 'Välj för att registrera en genväg';
	@override String get recordingShortcut => 'Tryck på genvägen nu';
	@override late final _TranslationsHotkeysActionsSv actions = _TranslationsHotkeysActionsSv._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoSv extends TranslationsFileInfoEn {
	_TranslationsFileInfoSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filinformation';
	@override String get video => 'Video';
	@override String get audio => 'Ljud';
	@override String get file => 'Fil';
	@override String get advanced => 'Avancerat';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Upplösning';
	@override String get bitrate => 'Bithastighet';
	@override String get frameRate => 'Bildfrekvens';
	@override String get aspectRatio => 'Bildförhållande';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bitdjup';
	@override String get colorSpace => 'Färgrymd';
	@override String get colorRange => 'Färgområde';
	@override String get colorPrimaries => 'Färggrunder';
	@override String get chromaSubsampling => 'Kroma-undersampling';
	@override String get channels => 'Kanaler';
	@override String get subtitles => 'Undertexter';
	@override String get overallBitrate => 'Total bithastighet';
	@override String get path => 'Sökväg';
	@override String get size => 'Storlek';
	@override String get container => 'Container';
	@override String get duration => 'Varaktighet';
	@override String get optimizedForStreaming => 'Optimerad för streaming';
	@override String get has64bitOffsets => '64-bit offset';
}

// Path: mediaMenu
class _TranslationsMediaMenuSv extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
	@override String get removeFromContinueWatching => 'Ta bort från Fortsätt titta';
	@override String get viewDetails => 'Visa detaljer';
	@override String get goToSeries => 'Gå till serie';
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get shuffleNotAvailableOffline => 'Blandad uppspelning är inte tillgänglig offline';
	@override String get fileInfo => 'Filinformation';
	@override String get deleteFromServer => 'Ta bort från servern';
	@override String get confirmDelete => 'Ta bort detta media och dess filer från din server?';
	@override String get deleteMultipleWarning => 'Detta inkluderar alla avsnitt och deras filer.';
	@override String get mediaDeletedSuccessfully => 'Mediaobjekt borttaget';
	@override String get mediaFailedToDelete => 'Kunde inte ta bort mediaobjekt';
	@override String get rate => 'Betygsätt';
	@override String get playFromBeginning => 'Spela från början';
	@override String get playVersion => 'Spela version...';
}

// Path: rateSheet
class _TranslationsRateSheetSv extends TranslationsRateSheetEn {
	_TranslationsRateSheetSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Betygsätt';
	@override String get server => 'Server';
	@override String get favorite => 'Favorit';
	@override String get favorited => 'Tillagd i favoriter';
	@override String get saved => 'Sparat';
	@override String get notAvailable => 'Ingen matchning hittades';
	@override String get noConnectedServices => 'Anslut en tjänst i Inställningar för att betygsätta där.';
}

// Path: accessibility
class _TranslationsAccessibilitySv extends TranslationsAccessibilityEn {
	_TranslationsAccessibilitySv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'sedd';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent sedd';
	@override String get mediaCardUnwatched => 'osedd';
	@override String get tapToPlay => 'Tryck för att spela';
	@override String get decrease => 'Minska';
	@override String get increase => 'Öka';
	@override String decreaseValue({required Object label}) => 'Minska ${label}';
	@override String increaseValue({required Object label}) => 'Öka ${label}';
	@override String get hue => 'Nyans';
	@override String get saturation => 'Mättnad';
	@override String get brightness => 'Ljusstyrka';
	@override String get hexColor => 'Hexfärg';
	@override String get expandText => 'Expandera text';
	@override String get collapseText => 'Fäll ihop text';
}

// Path: tooltips
class _TranslationsTooltipsSv extends TranslationsTooltipsEn {
	_TranslationsTooltipsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get playTrailer => 'Spela trailer';
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
}

// Path: videoControls
class _TranslationsVideoControlsSv extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Ljud';
	@override String get subtitlesLabel => 'Undertexter';
	@override String get resetToZero => 'Återställ till 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spelas senare';
	@override String playsEarlier({required Object label}) => '${label} spelas tidigare';
	@override String get noOffset => 'Ingen offset';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Fyll skärm';
	@override String get stretch => 'Sträck';
	@override String get lockRotation => 'Lås rotation';
	@override String get unlockRotation => 'Lås upp rotation';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Uppspelningen pausas om ${duration}';
	@override String get sleepTimerEndOfVideo => 'Slutet av aktuell video';
	@override String get sleepTimerStopAtHeader => 'Stoppa vid';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'Uppspelningen pausas i slutet av denna video';
	@override String get stillWatching => 'Tittar du fortfarande?';
	@override String pausingIn({required Object seconds}) => 'Pausar om ${seconds}s';
	@override String get continueWatching => 'Fortsätt';
	@override String get autoPlayNext => 'Spela nästa automatiskt';
	@override String get playNext => 'Spela nästa';
	@override String get playButton => 'Spela';
	@override String get pauseButton => 'Pausa';
	@override String seekBackwardButton({required Object seconds}) => 'Spola bakåt ${seconds} sekunder';
	@override String seekForwardButton({required Object seconds}) => 'Spola framåt ${seconds} sekunder';
	@override String get previousButton => 'Föregående avsnitt';
	@override String get nextButton => 'Nästa avsnitt';
	@override String get previousChapterButton => 'Föregående kapitel';
	@override String get nextChapterButton => 'Nästa kapitel';
	@override String get muteButton => 'Tysta';
	@override String get unmuteButton => 'Slå på ljud';
	@override String get settingsButton => 'Uppspelningsinställningar';
	@override String get tracksButton => 'Ljud och undertexter';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionQualityButton => 'Version och kvalitet';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Kvalitet';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkodning otillgänglig — spelar upp i originalkvalitet';
	@override String get pipButton => 'Bild-i-bild läge';
	@override String get aspectRatioButton => 'Bildförhållande';
	@override String get ambientLighting => 'Ambientbelysning';
	@override String get fullscreenButton => 'Aktivera helskärm';
	@override String get exitFullscreenButton => 'Avsluta helskärm';
	@override String get alwaysOnTopButton => 'Alltid överst';
	@override String get rotationLockButton => 'Rotationslås';
	@override String get lockScreen => 'Lås skärm';
	@override String get screenLockButton => 'Skärmlås';
	@override String get longPressToUnlock => 'Tryck länge för att låsa upp';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volymnivå';
	@override String endsAt({required Object time}) => 'Slutar ${time}';
	@override String get pipActive => 'Spelar i bild-i-bild';
	@override String get pipFailed => 'Bild-i-bild kunde inte starta';
	@override String get screenshotSaved => 'Skärmbild sparad';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _TranslationsVideoControlsPipErrorsSv pipErrors = _TranslationsVideoControlsPipErrorsSv._(_root);
	@override String get chapters => 'Kapitel';
	@override String get noChaptersAvailable => 'Inga kapitel tillgängliga';
	@override String get queue => 'Kö';
	@override String get noQueueItems => 'Inga objekt i kön';
	@override String get searchSubtitles => 'Sök undertexter';
	@override String get language => 'Språk';
	@override String get noSubtitlesFound => 'Inga undertexter hittades';
	@override String get downloadedSubtitle => 'Nedladdad';
	@override String get noSubtitlesAvailable => 'Inga undertexter tillgängliga';
	@override String get noAudioTracksAvailable => 'Inga ljudspår tillgängliga';
	@override String get noTracksAvailable => 'Inga spår tillgängliga';
	@override String get subtitleDownloaded => 'Undertext nedladdad';
	@override String get subtitleDownloadFailed => 'Kunde inte ladda ner undertext';
	@override String get searchLanguages => 'Sök språk...';
}

// Path: messages
class _TranslationsMessagesSv extends TranslationsMessagesEn {
	_TranslationsMessagesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Markerad som sedd';
	@override String get markedAsUnwatched => 'Markerad som osedd';
	@override String get markedAsWatchedOffline => 'Markerad som sedd (synkroniseras när online)';
	@override String get markedAsUnwatchedOffline => 'Markerad som osedd (synkroniseras när online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatiskt borttagen: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n,
		one: 'Tog automatiskt bort ${n} sedd nedladdning',
		other: 'Tog automatiskt bort ${n} sedda nedladdningar',
	);
	@override String get removedFromContinueWatching => 'Borttagen från Fortsätt titta';
	@override String errorLoading({required Object error}) => 'Fel: ${error}';
	@override String get streamInterrupted => 'Uppspelningen avbröts. Tryck på play eller spola för att försöka igen.';
	@override String get liveStreamInterrupted => 'Livestreamen avbröts. Tryck på play för att försöka igen.';
	@override String get fileInfoNotAvailable => 'Filinformation inte tillgänglig';
	@override String errorLoadingFileInfo({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
	@override String get errorLoadingSeries => 'Fel vid laddning av serie';
	@override String get musicNotSupported => 'Musikuppspelning stöds inte ännu';
	@override String get noDescriptionAvailable => 'Ingen beskrivning tillgänglig';
	@override String get noProfilesAvailable => 'Inga profiler tillgängliga';
	@override String get contactAdminForProfiles => 'Kontakta din serveradministratör för att lägga till profiler';
	@override String get unableToDetermineLibrarySection => 'Kan inte avgöra biblioteksavdelningen för detta objekt';
	@override String get logsCleared => 'Loggar rensade';
	@override String get logsCopied => 'Loggar kopierade till urklipp';
	@override String get noLogsAvailable => 'Inga loggar tillgängliga';
	@override String libraryScanning({required Object title}) => 'Skannar "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Biblioteksskanning startad för "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Misslyckades att skanna bibliotek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Uppdaterar metadata för "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadata-uppdatering startad för "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Misslyckades att uppdatera metadata: ${error}';
	@override String get logoutConfirm => 'Är du säker på att du vill logga ut?';
	@override String get noSeasonsFound => 'Inga säsonger hittades';
	@override String get seasonsLoadFailed => 'Det gick inte att läsa in säsonger';
	@override String get noEpisodesFound => 'Inga avsnitt hittades i första säsongen';
	@override String get noEpisodesFoundGeneral => 'Inga avsnitt hittades';
	@override String get episodesLoadFailed => 'Det gick inte att läsa in avsnitt';
	@override String get noResultsFound => 'Inga resultat hittades';
	@override String sleepTimerSet({required Object label}) => 'Sovtimer inställd för ${label}';
	@override String get noItemsAvailable => 'Inga objekt tillgängliga';
	@override String get failedToCreatePlayQueueNoItems => 'Det gick inte att skapa uppspelningskö – inga objekt';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Byter till kompatibel spelare...';
	@override String get serverLimitTitle => 'Uppspelningen misslyckades';
	@override String get serverLimitBody => 'Serverfel (HTTP 500). En bandbredds-/transkodningsgräns avvisade troligen sessionen. Be ägaren justera den.';
	@override String get logsUploaded => 'Loggar uppladdade';
	@override String get logsUploadFailed => 'Uppladdning av loggar misslyckades';
	@override String get logId => 'Logg-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingSv extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get text => 'Text';
	@override String get border => 'Kantlinje';
	@override String get background => 'Bakgrund';
	@override String get fontSize => 'Teckenstorlek';
	@override String get textColor => 'Textfärg';
	@override String get borderSize => 'Kantstorlek';
	@override String get borderColor => 'Kantfärg';
	@override String get backgroundOpacity => 'Bakgrundsopacitet';
	@override String get backgroundColor => 'Bakgrundsfärg';
	@override String get position => 'Position';
	@override String get assOverride => 'ASS-åsidosättning';
	@override String get overrideScale => 'Skala';
	@override String get overrideForce => 'Tvinga';
	@override String get overrideStrip => 'Ta bort formatering';
	@override String get positionTop => 'Överst';
	@override String get positionBottom => 'Nederst';
	@override String get bold => 'Fet';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Renderingsupplösning';
	@override String get renderResolutionScreen => 'Skärmupplösning';
	@override String get renderResolutionVideo => 'Videoupplösning';
}

// Path: mpvConfig
class _TranslationsMpvConfigSv extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv-konfiguration';
	@override String get description => 'Avancerade videospelares inställningar';
	@override String get presets => 'Förval';
	@override String get noPresets => 'Inga sparade förval';
	@override String get saveAsPreset => 'Spara som förval...';
	@override String get presetName => 'Förvalnamn';
	@override String get presetNameHint => 'Ange ett namn för detta förval';
	@override String get loadPreset => 'Ladda';
	@override String get deletePreset => 'Ta bort';
	@override String get presetSaved => 'Förval sparat';
	@override String get presetLoaded => 'Förval laddat';
	@override String get presetDeleted => 'Förval borttaget';
	@override String get confirmDeletePreset => 'Är du säker på att du vill ta bort detta förval?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogSv extends TranslationsDialogEn {
	_TranslationsDialogSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekräfta åtgärd';
}

// Path: profiles
class _TranslationsProfilesSv extends TranslationsProfilesEn {
	_TranslationsProfilesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Lägg till Plezy-profil';
	@override String get switchingProfile => 'Byter profil…';
	@override String get deleteThisProfileTitle => 'Ta bort denna profil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Ta bort ${displayName}. Anslutningar påverkas inte.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Hantera';
	@override String get delete => 'Ta bort';
	@override String get signOut => 'Logga ut';
	@override String get signOutPlexTitle => 'Logga ut från Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Ta bort ${displayName} och alla Plex Home-användare? Du kan logga in igen när som helst.';
	@override String get signedOutPlex => 'Utloggad från Plex.';
	@override String get signOutFailed => 'Utloggningen misslyckades.';
	@override String get sectionTitle => 'Profiler';
	@override String get summarySingle => 'Lägg till profiler för att blanda hanterade användare och lokala identiteter';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profiler';
	@override String get removeConnectionTitle => 'Ta bort anslutning?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Ta bort ${displayName}s åtkomst till ${connectionLabel}. Andra profiler behåller den.';
	@override String get deleteProfileTitle => 'Ta bort profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Ta bort ${displayName} och dess anslutningar. Servrar förblir tillgängliga.';
	@override String get profileNameLabel => 'Profilnamn';
	@override String get pinProtectionLabel => 'PIN-skydd';
	@override String get pinManagedByPlex => 'PIN hanteras av Plex. Redigera på plex.tv.';
	@override String get noPinSetEditOnPlex => 'Ingen PIN angiven. För att kräva en, redigera Home-användaren på plex.tv.';
	@override String get setPin => 'Ange PIN';
	@override String get setPinTitle => 'Ange PIN';
	@override String get confirmPinTitle => 'Bekräfta PIN';
	@override String get pinSet => 'PIN angiven';
	@override String get changePin => 'Ändra';
	@override String get removePin => 'Ta bort';
	@override String get connectionsLabel => 'Anslutningar';
	@override String get add => 'Lägg till';
	@override String get deleteProfileButton => 'Ta bort profil';
	@override String get noConnectionsHint => 'Inga anslutningar — lägg till en för att använda den här profilen.';
	@override String get noConnections => 'Inga anslutningar';
	@override String get plexHomeAccount => 'Plex Home-konto';
	@override String get connectionDefault => 'Standard';
	@override String connectionAs({required Object displayName}) => 'som ${displayName}';
	@override String get makeDefault => 'Gör till standard';
	@override String get removeConnection => 'Ta bort';
	@override String get profileRenamed => 'Profilen har bytt namn.';
	@override String borrowAddTo({required Object displayName}) => 'Lägg till i ${displayName}';
	@override String get borrowExplain => 'Låna en annan profils anslutning. PIN-skyddade profiler kräver en PIN.';
	@override String get borrowEmpty => 'Inget att låna ännu.';
	@override String get borrowEmptySubtitle => 'Anslut Plex eller Jellyfin till en annan profil först.';
	@override String borrowFromProfile({required Object displayName}) => 'Från ${displayName}';
	@override String get borrowConnectionBorrowed => 'Anslutning lånad.';
	@override String get borrowFailed => 'Kunde inte låna anslutningen.';
	@override String get incorrectPin => 'Fel PIN.';
	@override String get incorrectPinTryAgain => 'Fel PIN. Försök igen.';
	@override String get sourceProfileMissingParentAccount => 'Källprofilen saknar sitt överordnade konto.';
	@override String get failedToLoadHomeUsers => 'Kunde inte läsa in dina Plex Home-användare. Kontrollera anslutningen och försök igen.';
	@override String get failedToVerifyPin => 'Kunde inte verifiera PIN.';
	@override String get newProfile => 'Ny profil';
	@override String get profileNameHint => 't.ex. Gäster, Barn, Familjerum';
	@override String get pinProtectionOptional => 'PIN-skydd (valfritt)';
	@override String get pinExplain => '4-siffrig PIN krävs för att byta profiler.';
	@override String get continueButton => 'Fortsätt';
	@override String get pinsDontMatch => 'PIN-koderna stämmer inte överens';
}

// Path: connections
class _TranslationsConnectionsSv extends TranslationsConnectionsEn {
	_TranslationsConnectionsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Anslutningar';
	@override String get addConnection => 'Lägg till anslutning';
	@override String get addConnectionSubtitleNoProfile => 'Logga in med Plex eller anslut en Jellyfin-server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Lägg till för ${displayName}: Plex, Jellyfin eller en annan profilanslutning';
	@override String sessionExpiredOne({required Object name}) => 'Sessionen har gått ut för ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sessionen har gått ut för ${count} servrar';
	@override String get signInAgain => 'Logga in igen';
	@override String get editJellyfinTitle => 'Redigera Jellyfin-anslutning';
	@override String editJellyfinIntro({required Object serverName}) => 'Lägg till eller ta bort URL:er för ${serverName}. Plezy använder den nåbara URL:en med lägst latens.';
}

// Path: discover
class _TranslationsDiscoverSv extends TranslationsDiscoverEn {
	_TranslationsDiscoverSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Upptäck';
	@override String get noContentAvailable => 'Inget innehåll tillgängligt';
	@override String get addMediaToLibraries => 'Lägg till media till dina bibliotek';
	@override String get continueWatching => 'Fortsätt titta';
	@override String continueWatchingIn({required Object library}) => 'Fortsätt titta i ${library}';
	@override String get nextUp => 'Nästa';
	@override String nextUpIn({required Object library}) => 'Nästa i ${library}';
	@override String get recentlyAdded => 'Nyligen tillagda';
	@override String recentlyAddedIn({required Object library}) => 'Nyligen tillagda i ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Senaste albumen i ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Nyligen spelade i ${library}';
	@override String mostPlayedIn({required Object library}) => 'Mest spelade i ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Översikt';
	@override String get cast => 'Rollbesättning';
	@override String get extras => 'Trailers och Extra';
	@override String get studio => 'Studio';
	@override String get rating => 'Åldersgräns';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min kvar';
	@override String get moreLikeThis => 'Mer som detta';
}

// Path: errors
class _TranslationsErrorsSv extends TranslationsErrorsEn {
	_TranslationsErrorsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Sökning misslyckades: ${error}';
	@override String connectionTimeout({required Object context}) => 'Anslutnings-timeout vid laddning ${context}';
	@override String get connectionFailed => 'Kan inte ansluta till mediaserver';
	@override String unableToLoad({required Object context}) => 'Det gick inte att läsa in ${context}. Försök igen.';
	@override String get noClientAvailable => 'Ingen klient tillgänglig';
	@override String get pleaseEnterToken => 'Vänligen ange en token';
	@override String get invalidToken => 'Ogiltig token';
	@override String failedToVerifyToken({required Object error}) => 'Misslyckades att verifiera token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Misslyckades att ta bort ${displayName}';
	@override String get failedToRate => 'Det gick inte att uppdatera betyget';
}

// Path: libraries
class _TranslationsLibrariesSv extends TranslationsLibrariesEn {
	_TranslationsLibrariesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotek';
	@override String get fallbackTitle => 'Bibliotek';
	@override String get scanLibraryFiles => 'Skanna biblioteksfiler';
	@override String get scanLibrary => 'Skanna bibliotek';
	@override String get analyze => 'Analysera';
	@override String get analyzeLibrary => 'Analysera bibliotek';
	@override String get refreshMetadata => 'Uppdatera metadata';
	@override String get emptyTrash => 'Töm papperskorg';
	@override String emptyingTrash({required Object title}) => 'Tömmer papperskorg för "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papperskorg tömd för "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Misslyckades att tömma papperskorg: ${error}';
	@override String analyzing({required Object title}) => 'Analyserar "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analys startad för "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Misslyckades att analysera bibliotek: ${error}';
	@override String get noLibrariesFound => 'Inga bibliotek hittades';
	@override String get allLibrariesHidden => 'Alla bibliotek är dolda';
	@override String hiddenLibrariesCount({required Object count}) => 'Dolda bibliotek (${count})';
	@override String get thisLibraryIsEmpty => 'Detta bibliotek är tomt';
	@override String get noItemsMatchFilters => 'Inga objekt matchar de aktiva filtren';
	@override String get resetFilters => 'Återställ filter';
	@override String get all => 'Alla';
	@override String get clearAll => 'Rensa alla';
	@override String scanLibraryConfirm({required Object title}) => 'Är du säker på att du vill skanna "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Är du säker på att du vill analysera "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Är du säker på att du vill uppdatera metadata för "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Är du säker på att du vill tömma papperskorgen för "${title}"?';
	@override String get manageLibraries => 'Hantera bibliotek';
	@override String get sort => 'Sortera';
	@override String get sortBy => 'Sortera efter';
	@override String get filters => 'Filter';
	@override String get confirmActionMessage => 'Är du säker på att du vill utföra denna åtgärd?';
	@override String get showLibrary => 'Visa bibliotek';
	@override String get hideLibrary => 'Dölj bibliotek';
	@override String get libraryOptions => 'Biblioteksalternativ';
	@override String get content => 'bibliotekets innehåll';
	@override String get selectLibrary => 'Välj bibliotek';
	@override String filtersWithCount({required Object count}) => 'Filter (${count})';
	@override String get noRecommendations => 'Inga rekommendationer tillgängliga';
	@override String get noCollections => 'Inga samlingar i det här biblioteket';
	@override String get noFoldersFound => 'Inga mappar hittades';
	@override String get folders => 'mappar';
	@override late final _TranslationsLibrariesTabsSv tabs = _TranslationsLibrariesTabsSv._(_root);
	@override late final _TranslationsLibrariesGroupingsSv groupings = _TranslationsLibrariesGroupingsSv._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesSv filterCategories = _TranslationsLibrariesFilterCategoriesSv._(_root);
	@override late final _TranslationsLibrariesSortLabelsSv sortLabels = _TranslationsLibrariesSortLabelsSv._(_root);
}

// Path: about
class _TranslationsAboutSv extends TranslationsAboutEn {
	_TranslationsAboutSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Öppen källkod-licenser';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'En vacker Plex- och Jellyfin-klient för Flutter';
	@override String get viewLicensesDescription => 'Visa licenser för tredjepartsbibliotek';
}

// Path: serverSelection
class _TranslationsServerSelectionSv extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Inga servrar hittades för ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailSv extends TranslationsHubDetailEn {
	_TranslationsHubDetailSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Utgivningsår';
	@override String get dateAdded => 'Datum tillagd';
	@override String get rating => 'Betyg';
	@override String get noItemsFound => 'Inga objekt hittades';
}

// Path: logs
class _TranslationsLogsSv extends TranslationsLogsEn {
	_TranslationsLogsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Rensa loggar';
	@override String get copyLogs => 'Kopiera loggar';
	@override String get uploadLogs => 'Ladda upp loggar';
}

// Path: licenses
class _TranslationsLicensesSv extends TranslationsLicensesEn {
	_TranslationsLicensesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterade paket';
	@override String get license => 'Licens';
	@override String licenseNumber({required Object number}) => 'Licens ${number}';
	@override String licensesCount({required Object count}) => '${count} licenser';
}

// Path: navigation
class _TranslationsNavigationSv extends TranslationsNavigationEn {
	_TranslationsNavigationSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotek';
	@override String get downloads => 'Nerladdat';
	@override String get liveTv => 'Live-TV';
	@override String get explore => 'Utforska';
}

// Path: explore
class _TranslationsExploreSv extends TranslationsExploreEn {
	_TranslationsExploreSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Utforska';
	@override String get selectSource => 'Välj källa';
	@override late final _TranslationsExploreRowsSv rows = _TranslationsExploreRowsSv._(_root);
	@override late final _TranslationsExploreStatusSv status = _TranslationsExploreStatusSv._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n,
		one: '${n} avsnitt',
		other: '${n} avsnitt',
	);
	@override String get cast => 'Rollbesättning';
	@override String get characters => 'Karaktärer';
	@override String get addToWatchlist => 'Lägg till i bevakningslista';
	@override String get removeFromWatchlist => 'Ta bort från bevakningslista';
	@override String get watchlistUpdateFailed => 'Det gick inte att uppdatera bevakningslistan';
	@override String get notInLibrary => 'Finns inte i ditt bibliotek';
	@override String get inTheseLibraries => 'I dessa bibliotek';
	@override String get checkingLibrary => 'Kontrollerar ditt bibliotek...';
	@override String get emptyTitle => 'Inget här ännu';
	@override String emptyMessage({required Object source}) => 'Rader från ${source} visas här när de har innehåll.';
	@override String searchHint({required Object source}) => 'Sök i ${source}';
	@override String searchEmpty({required Object query}) => 'Inga resultat för "${query}"';
	@override String searchPrompt({required Object source}) => 'Sök efter filmer och serier på ${source}.';
	@override String get searchFailed => 'Sökningen misslyckades. Kontrollera din anslutning och försök igen.';
}

// Path: liveTv
class _TranslationsLiveTvSv extends TranslationsLiveTvEn {
	_TranslationsLiveTvSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-TV';
	@override String get guide => 'Programguide';
	@override String get noChannels => 'Inga kanaler tillgängliga';
	@override String get noDvr => 'Ingen DVR konfigurerad på någon server';
	@override String get serverUnavailable => 'Live-tv-servern är inte tillgänglig.';
	@override String get serverNotConnected => 'Live-tv-servern är inte ansluten.';
	@override String get noPrograms => 'Ingen programdata tillgänglig';
	@override String get liveStreamFailed => 'Liveström misslyckades';
	@override String get unknownProgram => 'Okänt program';
	@override String get unknownHub => 'Okänt';
	@override String get unknownError => 'Okänt fel';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Okänd kanal';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'Ladda om programguide';
	@override String get now => 'Nu';
	@override String get today => 'Idag';
	@override String get tomorrow => 'I morgon';
	@override String get midnight => 'Midnatt';
	@override String get overnight => 'Natt';
	@override String get morning => 'Morgon';
	@override String get daytime => 'Dagtid';
	@override String get evening => 'Kväll';
	@override String get lateNight => 'Sen kväll';
	@override String get whatsOn => 'På TV nu';
	@override String get watchChannel => 'Titta på kanal';
	@override String get favorites => 'Favoriter';
	@override String get reorderFavorites => 'Ordna om favoriter';
	@override String get favoritesLoadFailed => 'Det gick inte att läsa in favoriter. Kontrollera anslutningen och försök igen.';
	@override String get joinSession => 'Gå med i pågående session';
	@override String watchFromStart({required Object minutes}) => 'Titta från början (${minutes} min sedan)';
	@override String get watchLive => 'Titta live';
	@override String get goToLive => 'Gå till live';
	@override String get record => 'Spela in';
	@override String get recordEpisode => 'Spela in avsnitt';
	@override String get recordSeries => 'Spela in serie';
	@override String get recordOptions => 'Inspelningsalternativ';
	@override String get saveTo => 'Spara till';
	@override String get recordings => 'Inspelningar';
	@override String get scheduledRecordings => 'Schemalagda';
	@override String get recordingRules => 'Inspelningsregler';
	@override String get noScheduledRecordings => 'Inga schemalagda inspelningar';
	@override String get manageRecording => 'Hantera inspelning';
	@override String get cancelRecording => 'Avbryt inspelning';
	@override String get cancelRecordingTitle => 'Avbryt denna inspelning?';
	@override String cancelRecordingMessage({required Object title}) => '${title} kommer inte längre att spelas in.';
	@override String get deleteRule => 'Ta bort regel';
	@override String get deleteRuleTitle => 'Ta bort inspelningsregel?';
	@override String deleteRuleMessage({required Object title}) => 'Kommande avsnitt av ${title} kommer inte att spelas in.';
	@override String get recordingScheduled => 'Inspelning schemalagd';
	@override String get alreadyScheduled => 'Detta program är redan schemalagt';
	@override String get dvrAdminRequired => 'DVR-inställningar kräver ett administratörskonto';
	@override String get recordingFailed => 'Det gick inte att schemalägga inspelning';
	@override String get recordingTargetMissing => 'Det gick inte att hitta inspelningsbibliotek';
	@override String get recordNotAvailable => 'Inspelning är inte tillgänglig för detta program';
	@override String get recordingCancelled => 'Inspelning avbruten';
	@override String get recordingRuleDeleted => 'Inspelningsregel borttagen';
	@override String get processRecordingRules => 'Utvärdera regler igen';
	@override String get recordingInProgress => 'Spelar in nu';
	@override String recordingsCount({required Object count}) => '${count} schemalagda';
	@override String get editRule => 'Redigera regel';
	@override String get editRuleAction => 'Redigera';
	@override String get recordingRuleUpdated => 'Inspelningsregel uppdaterad';
	@override String get guideReloadRequested => 'Begärde guidens uppdatering';
	@override String get rulesProcessRequested => 'Begärde regelutvärdering';
	@override String get recordShow => 'Spela in program';
}

// Path: collections
class _TranslationsCollectionsSv extends TranslationsCollectionsEn {
	_TranslationsCollectionsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlingar';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen är tom';
	@override String get deleteCollection => 'Ta bort samling';
	@override String deleteConfirm({required Object title}) => 'Ta bort "${title}"? Detta kan inte ångras.';
	@override String get deleted => 'Samling borttagen';
	@override String get deleteFailed => 'Det gick inte att ta bort samlingen';
	@override String deleteFailedWithError({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}';
	@override String get selectCollection => 'Välj samling';
	@override String get collectionName => 'Samlingsnamn';
	@override String get enterCollectionName => 'Ange samlingsnamn';
	@override String get addedToCollection => 'Tillagd i samling';
	@override String get errorAddingToCollection => 'Fel vid tillägg i samling';
	@override String get created => 'Samling skapad';
	@override String get removeFromCollection => 'Ta bort från samling';
	@override String removeFromCollectionConfirm({required Object title}) => 'Ta bort "${title}" från denna samling?';
	@override String get removedFromCollection => 'Borttagen från samling';
	@override String get removeFromCollectionFailed => 'Misslyckades med att ta bort från samling';
	@override String removeFromCollectionError({required Object error}) => 'Fel vid borttagning från samling: ${error}';
	@override String get searchCollections => 'Sök samlingar...';
}

// Path: playlists
class _TranslationsPlaylistsSv extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spellistor';
	@override String get playlist => 'Spellista';
	@override String get noPlaylists => 'Inga spellistor hittades';
	@override String get create => 'Skapa spellista';
	@override String get playlistName => 'Spellistans namn';
	@override String get enterPlaylistName => 'Ange spellistans namn';
	@override String get delete => 'Ta bort spellista';
	@override String get removeItem => 'Ta bort från spellista';
	@override String get smartPlaylist => 'Smart spellista';
	@override String itemCount({required Object count}) => '${count} objekt';
	@override String get oneItem => '1 objekt';
	@override String get emptyPlaylist => 'Denna spellista är tom';
	@override String get deleteConfirm => 'Ta bort spellista?';
	@override String deleteMessage({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?';
	@override String get created => 'Spellista skapad';
	@override String get deleted => 'Spellista borttagen';
	@override String get itemAdded => 'Tillagd i spellista';
	@override String get itemRemoved => 'Borttagen från spellista';
	@override String get selectPlaylist => 'Välj spellista';
	@override String get searchPlaylists => 'Sök i spellistor...';
	@override String get errorCreating => 'Det gick inte att skapa spellista';
	@override String get errorDeleting => 'Det gick inte att ta bort spellista';
	@override String get errorLoading => 'Det gick inte att ladda spellistor';
	@override String get errorAdding => 'Det gick inte att lägga till i spellista';
	@override String get errorReordering => 'Det gick inte att omordna spellisteobjekt';
	@override String get errorRemoving => 'Det gick inte att ta bort från spellista';
}

// Path: music
class _TranslationsMusicSv extends TranslationsMusicEn {
	_TranslationsMusicSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Gå till album';
	@override String get goToArtist => 'Gå till artist';
	@override String get instantMix => 'Snabbmix';
	@override String get playNext => 'Spela härnäst';
	@override String get addToQueue => 'Lägg till i kö';
	@override String discNumber({required Object n}) => 'Skiva ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n,
		one: '${n} låt',
		other: '${n} låtar',
	);
	@override String get nowPlaying => 'Spelas nu';
	@override String playingFrom({required Object title}) => 'Spelar från ${title}';
	@override String get queue => 'Kö';
	@override String get clearQueue => 'Rensa kön';
	@override String get lyrics => 'Låttext';
	@override String get noLyrics => 'Ingen låttext tillgänglig';
	@override String get sleepTimer => 'Insomningstimer';
	@override String get sleepTimerEndOfTrack => 'Slutet av låten';
	@override String sleepTimerMinutes({required Object n}) => '${n} minuter';
	@override String get stopPlayback => 'Stoppa uppspelning';
	@override String get previousTrack => 'Föregående låt';
	@override String get nextTrack => 'Nästa låt';
	@override String get repeat => 'Upprepa';
	@override String get repeatAll => 'Upprepa alla';
	@override String get repeatOne => 'Upprepa en låt';
}

// Path: watchTogether
class _TranslationsWatchTogetherSv extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titta Tillsammans';
	@override String get description => 'Titta på innehåll synkroniserat med vänner och familj';
	@override String get createSession => 'Skapa Session';
	@override String get creating => 'Skapar...';
	@override String get joinSession => 'Gå med i Session';
	@override String get joining => 'Ansluter...';
	@override String get controlMode => 'Kontrollläge';
	@override String get controlModeQuestion => 'Vem kan styra uppspelningen?';
	@override String get hostOnly => 'Endast Värd';
	@override String get anyone => 'Alla';
	@override String get hostingSession => 'Värd för Session';
	@override String get inSession => 'I Session';
	@override String get sessionCode => 'Sessionskod';
	@override String get openSessionControls => 'Öppna sessionskontroller för Titta Tillsammans';
	@override String get copySessionCode => 'Kopiera sessionskod';
	@override String get hostControlsPlayback => 'Värden styr uppspelningen';
	@override String get anyoneCanControl => 'Alla kan styra uppspelningen';
	@override String get hostControls => 'Värd styr';
	@override String get anyoneControls => 'Alla styr';
	@override String get participants => 'Deltagare';
	@override String get host => 'Värd';
	@override String get hostBadge => 'VÄRD';
	@override String get youAreHost => 'Du är värden';
	@override String get watchingWithOthers => 'Tittar med andra';
	@override String get endSession => 'Avsluta Session';
	@override String get leaveSession => 'Lämna Session';
	@override String get endSessionQuestion => 'Avsluta Session?';
	@override String get leaveSessionQuestion => 'Lämna Session?';
	@override String get endSessionConfirm => 'Detta avslutar sessionen för alla deltagare.';
	@override String get leaveSessionConfirm => 'Du kommer att tas bort från sessionen.';
	@override String get endSessionConfirmOverlay => 'Detta avslutar tittarsessionen för alla deltagare.';
	@override String get leaveSessionConfirmOverlay => 'Du kommer att kopplas bort från tittarsessionen.';
	@override String get end => 'Avsluta';
	@override String get leave => 'Lämna';
	@override String get syncing => 'Synkroniserar...';
	@override String get joinWatchSession => 'Gå med i Tittarsession';
	@override String get enterCodeHint => 'Ange 5-teckens kod';
	@override String get pasteFromClipboard => 'Klistra in från urklipp';
	@override String get pleaseEnterCode => 'Vänligen ange en sessionskod';
	@override String get codeMustBe5Chars => 'Sessionskod måste vara 5 tecken';
	@override String get joinInstructions => 'Ange värdens sessionskod för att gå med.';
	@override String get failedToCreate => 'Det gick inte att skapa session';
	@override String get failedToJoin => 'Det gick inte att gå med i session';
	@override String get sessionCodeCopied => 'Sessionskod kopierad till urklipp';
	@override String get relayUnreachable => 'Relay-servern kan inte nås. ISP-blockering kan hindra Watch Together.';
	@override String get reconnectingToHost => 'Återansluter till värd...';
	@override String get currentPlayback => 'Aktuell uppspelning';
	@override String get joinCurrentPlayback => 'Gå med i aktuell uppspelning';
	@override String get joinCurrentPlaybackDescription => 'Hoppa tillbaka till det värden tittar på just nu';
	@override String get failedToOpenCurrentPlayback => 'Kunde inte öppna aktuell uppspelning';
	@override String participantJoined({required Object name}) => '${name} gick med';
	@override String participantLeft({required Object name}) => '${name} lämnade';
	@override String participantPaused({required Object name}) => '${name} pausade';
	@override String participantResumed({required Object name}) => '${name} återupptog';
	@override String participantSeeked({required Object name}) => '${name} spolade';
	@override String participantBuffering({required Object name}) => '${name} buffrar';
	@override String participantNeedsUpdate({required Object name}) => '${name} använder en äldre appversion — synkronisering är inte tillgänglig';
	@override String resumingWithout({required Object name}) => 'Återupptar utan ${name}';
	@override String get waitingForParticipants => 'Väntar på att andra laddar...';
	@override String waitingForName({required Object name}) => 'Väntar på ${name}...';
	@override String get recentRooms => 'Senaste rum';
	@override String get renameRoom => 'Byt namn på rum';
	@override String get removeRoom => 'Ta bort';
	@override String get guestSwitchUnavailable => 'Kunde inte byta — server inte tillgänglig för synkronisering';
	@override String get guestSwitchFailed => 'Kunde inte byta — innehåll hittades inte på denna server';
}

// Path: downloads
class _TranslationsDownloadsSv extends TranslationsDownloadsEn {
	_TranslationsDownloadsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nedladdningar';
	@override String get manage => 'Hantera';
	@override String get tvShows => 'TV-serier';
	@override String get movies => 'Filmer';
	@override String get music => 'Musik';
	@override String tracksQueued({required Object count}) => '${count} låtar i nedladdningskö';
	@override String get noDownloads => 'Inga nedladdningar ännu';
	@override String get noDownloadsDescription => 'Nedladdat innehåll visas här för offline-visning';
	@override String get downloadNow => 'Ladda ner';
	@override String get deleteDownload => 'Ta bort nedladdning';
	@override String get retryDownload => 'Försök igen';
	@override String get downloadQueued => 'Nedladdning köad';
	@override String get downloadResumed => 'Nedladdning återupptagen';
	@override String get serverErrorBitrate => 'Serverfel: filen kan överskrida gränsen för fjärrbitrate';
	@override String episodesQueued({required Object count}) => '${count} avsnitt köade för nedladdning';
	@override String get downloadDeleted => 'Nedladdning borttagen';
	@override String deleteConfirm({required Object title}) => 'Ta bort "${title}" från den här enheten?';
	@override String get cancelledDownloadTitle => 'Avbruten nedladdning';
	@override String get cancelledDownloadMessage => 'Den här nedladdningen avbröts. Vad vill du göra?';
	@override String get allEpisodesAlreadyDownloaded => 'Alla avsnitt är redan nedladdade';
	@override String get resumeDownload => 'Återuppta nedladdning';
	@override String get cancelledDownload => 'Avbruten nedladdning';
	@override String syncingFile({required Object file, required Object status}) => '${file} (synkroniserar ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} nedladdad – klicka för att slutföra';
	@override String get partialDownloadClickToComplete => 'Delvis nedladdad – klicka för att slutföra';
	@override String get deleting => 'Tar bort...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})';
	@override String get queuedTooltip => 'I kö';
	@override String queuedFilesTooltip({required Object files}) => 'I kö: ${files}';
	@override String get downloadingTooltip => 'Laddar ned...';
	@override String downloadingFilesTooltip({required Object files}) => 'Laddar ned ${files}';
	@override String get noDownloadsTree => 'Inga nedladdningar';
	@override String get pauseAll => 'Pausa alla';
	@override String get resumeAll => 'Återuppta alla';
	@override String get deleteAll => 'Ta bort alla';
	@override String get selectVersion => 'Välj version';
	@override String get allEpisodes => 'Alla avsnitt';
	@override String get unwatchedOnly => 'Endast osedda';
	@override String nextNUnwatched({required Object count}) => 'Nästa ${count} osedda';
	@override String get customAmount => 'Ange antal...';
	@override String get includeSpecials => 'Inkludera specialavsnitt';
	@override String get howManyEpisodes => 'Hur många avsnitt?';
	@override String get invalidEpisodeCount => 'Ange ett giltigt antal avsnitt.';
	@override String get keepSynced => 'Håll synkroniserad';
	@override String get downloadOnce => 'Ladda ner en gång';
	@override String keepNUnwatched({required Object count}) => 'Behåll ${count} osedda';
	@override String get editSyncRule => 'Redigera synkregel';
	@override String get removeSyncRule => 'Ta bort synkregel';
	@override String removeSyncRuleConfirm({required Object title}) => 'Sluta synkronisera "${title}"? Nedladdade avsnitt behålls.';
	@override String syncRuleCreated({required Object count}) => 'Synkregel skapad — behåller ${count} osedda avsnitt';
	@override String get syncRuleUpdated => 'Synkregel uppdaterad';
	@override String get syncRuleRemoved => 'Synkregel borttagen';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Synkroniserade ${count} nya avsnitt för ${title}';
	@override String get activeSyncRules => 'Synkregler';
	@override String get noSyncRules => 'Inga synkregler';
	@override String get manageSyncRule => 'Hantera synkronisering';
	@override String get editEpisodeCount => 'Antal avsnitt';
	@override String get editSyncFilter => 'Synkroniseringsfilter';
	@override String get syncAllItems => 'Synkroniserar alla objekt';
	@override String get syncUnwatchedItems => 'Synkroniserar osedda objekt';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Tillgänglig';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Inloggning krävs';
	@override String get syncRuleNotAvailableForProfile => 'Inte tillgänglig för aktuell profil';
	@override String get syncRuleUnknownServer => 'Okänd server';
	@override String get syncRuleListCreated => 'Synkroniseringsregel skapad';
}

// Path: shaders
class _TranslationsShadersSv extends TranslationsShadersEn {
	_TranslationsShadersSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Ingen videoförbättring';
	@override String get nvscalerDescription => 'NVIDIA-bildskalning för skarpare video';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Brusreducering';
	@override String get artcnnVariantDenoiseSharpen => 'Brusreducering + skärpa';
	@override String get qualityFast => 'Snabb';
	@override String get qualityHQ => 'Hög kvalitet';
	@override String get mode => 'Läge';
	@override String get importShader => 'Importera shader';
	@override String get customShaderDescription => 'Anpassad GLSL-shader';
	@override String get shaderImported => 'Shader importerad';
	@override String get shaderImportFailed => 'Kunde inte importera shader';
	@override String get deleteShader => 'Ta bort shader';
	@override String deleteShaderConfirm({required Object name}) => 'Ta bort "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteSv extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fjärrkontroll';
	@override String connectedTo({required Object name}) => 'Ansluten till ${name}';
	@override String get unknownDevice => 'Okänd enhet';
	@override late final _TranslationsCompanionRemoteSessionSv session = _TranslationsCompanionRemoteSessionSv._(_root);
	@override late final _TranslationsCompanionRemotePairingSv pairing = _TranslationsCompanionRemotePairingSv._(_root);
	@override late final _TranslationsCompanionRemoteRemoteSv remote = _TranslationsCompanionRemoteRemoteSv._(_root);
	@override late final _TranslationsCompanionRemoteErrorsSv errors = _TranslationsCompanionRemoteErrorsSv._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsSv extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Uppspelningshastighet';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktiv (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Sovtimer';
	@override String get audioSync => 'Ljudsynkronisering';
	@override String get subtitleSync => 'Undertextsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Ljudutgång';
	@override String get performanceOverlay => 'Prestandaöverlägg';
	@override String get audioPassthrough => 'Ljudgenomkoppling';
	@override String get audioNormalization => 'Normalisera ljudstyrka';
	@override String get audioDownmix => 'Nedmixning till stereo';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlaySv extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlaySv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get color => 'Färg';
	@override String get performance => 'Prestanda';
	@override String get buffer => 'Buffert';
	@override String get app => 'App';
	@override String get decoder => 'Dekoder';
	@override String get rawDecoder => 'Rå dekoder';
	@override String get tunneling => 'Tunneling';
	@override String get aspect => 'Bildformat';
	@override String get rotation => 'Rotation';
	@override String get dvSource => 'DV-källa';
	@override String get dvPath => 'DV-sökväg';
	@override String get p7Conversion => 'P7-konv.';
	@override String get sampleRate => 'Samplingsfrekvens';
	@override String get pixelFormat => 'Pixelformat';
	@override String get hwFormat => 'HW-format';
	@override String get matrix => 'Matris';
	@override String get primaries => 'Primärfärger';
	@override String get transfer => 'Transfer';
	@override String get renderFps => 'Render-FPS';
	@override String get displayFps => 'Skärm-FPS';
	@override String get avSync => 'A/V-synk';
	@override String get dropped => 'Tappade';
	@override String get dvRpus => 'DV RPU:er';
	@override String get dvRpuAverage => 'DV RPU snitt';
	@override String get dvSampleAverage => 'DV-sample snitt';
	@override String get maxLuma => 'Max luma';
	@override String get minLuma => 'Min luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache använd';
	@override String get cacheLimit => 'Cachegräns';
	@override String get speed => 'Hastighet';
	@override String get player => 'Spelare';
	@override String get memory => 'Minne';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _TranslationsExternalPlayerSv extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Extern spelare';
	@override String get useExternalPlayer => 'Använd extern spelare';
	@override String get useExternalPlayerDescription => 'Öppna videor i en annan app';
	@override String get selectPlayer => 'Välj spelare';
	@override String get customPlayers => 'Anpassade spelare';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Lägg till anpassad spelare';
	@override String get playerName => 'Spelarnamn';
	@override String get playerNameHint => 'Min spelare';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Paketnamn';
	@override String get playerUrlScheme => 'URL-schema';
	@override String get off => 'Av';
	@override String get launchFailed => 'Kunde inte öppna extern spelare';
	@override String appNotInstalled({required Object name}) => '${name} är inte installerad';
	@override String get playInExternalPlayer => 'Spela i extern spelare';
}

// Path: metadataEdit
class _TranslationsMetadataEditSv extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Redigera...';
	@override String get screenTitle => 'Redigera metadata';
	@override String get basicInfo => 'Grundläggande info';
	@override String get artwork => 'Artwork';
	@override String get advancedSettings => 'Avancerade inställningar';
	@override String get title => 'Titel';
	@override String get sortTitle => 'Sorteringstitel';
	@override String get originalTitle => 'Originaltitel';
	@override String get releaseDate => 'Utgivningsdatum';
	@override String get contentRating => 'Åldersgräns';
	@override String get studio => 'Studio';
	@override String get tagline => 'Tagline';
	@override String get summary => 'Sammanfattning';
	@override String get poster => 'Poster';
	@override String get background => 'Bakgrund';
	@override String get logo => 'Logotyp';
	@override String get squareArt => 'Kvadratisk bild';
	@override String get selectPoster => 'Välj poster';
	@override String get selectBackground => 'Välj bakgrund';
	@override String get selectLogo => 'Välj logotyp';
	@override String get selectSquareArt => 'Välj kvadratisk bild';
	@override String get fromUrl => 'Från URL';
	@override String get uploadFile => 'Ladda upp fil';
	@override String get enterImageUrl => 'Ange bild-URL';
	@override String get imageUrl => 'Bild-URL';
	@override String get metadataUpdated => 'Metadata uppdaterad';
	@override String get metadataUpdateFailed => 'Kunde inte uppdatera metadata';
	@override String get artworkUpdated => 'Artwork uppdaterad';
	@override String get artworkUpdateFailed => 'Kunde inte uppdatera artwork';
	@override String get noArtworkAvailable => 'Ingen artwork tillgänglig';
	@override String artworkOption({required Object index}) => 'Bildalternativ ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Bildalternativ ${index}, valt';
	@override String get notSet => 'Inte angiven';
	@override String get libraryDefault => 'Biblioteksstandard';
	@override String get accountDefault => 'Kontostandard';
	@override String get seriesDefault => 'Seriestandard';
	@override String get episodeSorting => 'Avsnittsortering';
	@override String get oldestFirst => 'Äldst först';
	@override String get newestFirst => 'Nyast först';
	@override String get keep => 'Behåll';
	@override String get allEpisodes => 'Alla avsnitt';
	@override String latestEpisodes({required Object count}) => '${count} senaste avsnitten';
	@override String get latestEpisode => 'Senaste avsnittet';
	@override String episodesAddedPastDays({required Object count}) => 'Avsnitt tillagda de senaste ${count} dagarna';
	@override String get deleteAfterPlaying => 'Ta bort avsnitt efter uppspelning';
	@override String get never => 'Aldrig';
	@override String get afterADay => 'Efter en dag';
	@override String get afterAWeek => 'Efter en vecka';
	@override String get afterAMonth => 'Efter en månad';
	@override String get onNextRefresh => 'Vid nästa uppdatering';
	@override String get seasons => 'Säsonger';
	@override String get show => 'Visa';
	@override String get hide => 'Dölj';
	@override String get episodeOrdering => 'Avsnittsordning';
	@override String get tmdbAiring => 'The Movie Database (Sändning)';
	@override String get tvdbAiring => 'TheTVDB (Sändning)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolut)';
	@override String get metadataLanguage => 'Metadataspråk';
	@override String get useOriginalTitle => 'Använd originaltitel';
	@override String get preferredAudioLanguage => 'Föredraget ljudspråk';
	@override String get preferredSubtitleLanguage => 'Föredraget undertextspråk';
	@override String get subtitleMode => 'Automatiskt val av undertexter';
	@override String get manuallySelected => 'Manuellt vald';
	@override String get shownWithForeignAudio => 'Visas vid främmande ljud';
	@override String get alwaysEnabled => 'Alltid aktiverad';
	@override String get tags => 'Taggar';
	@override String get addTag => 'Lägg till tagg';
	@override String get genre => 'Genre';
	@override String get director => 'Regissör';
	@override String get writer => 'Författare';
	@override String get producer => 'Producent';
	@override String get country => 'Land';
	@override String get collection => 'Samling';
	@override String get label => 'Etikett';
	@override String get style => 'Stil';
	@override String get mood => 'Stämning';
}

// Path: matchScreen
class _TranslationsMatchScreenSv extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get match => 'Matcha...';
	@override String get fixMatch => 'Rätta matchning...';
	@override String get unmatch => 'Ta bort matchning';
	@override String get unmatchConfirm => 'Rensa denna matchning? Plex behandlar den som omatchad tills den matchas igen.';
	@override String get unmatchSuccess => 'Matchning borttagen';
	@override String get unmatchFailed => 'Det gick inte att ta bort matchningen';
	@override String get matchApplied => 'Matchning tillämpad';
	@override String get matchFailed => 'Det gick inte att tillämpa matchningen';
	@override String get titleHint => 'Titel';
	@override String get yearHint => 'År';
	@override String get search => 'Sök';
	@override String get noMatchesFound => 'Inga matchningar hittades';
}

// Path: serverTasks
class _TranslationsServerTasksSv extends TranslationsServerTasksEn {
	_TranslationsServerTasksSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveruppgifter';
	@override String get failedToLoad => 'Kunde inte ladda uppgifter';
	@override String get noTasks => 'Inga pågående uppgifter';
}

// Path: trakt
class _TranslationsTraktSv extends TranslationsTraktEn {
	_TranslationsTraktSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Ansluten';
	@override String connectedAs({required Object username}) => 'Ansluten som @${username}';
	@override String get disconnectConfirm => 'Koppla från Trakt-konto?';
	@override String get disconnectConfirmBody => 'Plezy slutar skicka händelser till Trakt. Du kan återansluta när som helst.';
	@override String get scrobble => 'Realtids-scrobbling';
	@override String get scrobbleDescription => 'Skicka uppspelnings-, paus- och stopphändelser till Trakt under uppspelning.';
	@override String get watchedSync => 'Synkronisera tittad-status';
	@override String get watchedSyncDescription => 'När du markerar något som tittat i Plezy markeras det också på Trakt.';
}

// Path: seerr
class _TranslationsSeerrSv extends TranslationsSeerrEn {
	_TranslationsSeerrSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Anslut Seerr';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHelper => 'Adressen till din Seerr-instans';
	@override String get checkServer => 'Fortsätt';
	@override String get signInWithJellyfin => 'Logga in med Jellyfin';
	@override String get signInWithEmby => 'Logga in med Emby';
	@override String get signInWithLocal => 'Använd ett lokalt konto';
	@override String get email => 'E-post';
	@override String get noSignInMethods => 'Den här Seerr-instansen erbjuder ingen inloggningsmetod som Plezy stöder.';
	@override String get instance => 'Instans';
	@override String get disconnectConfirm => 'Koppla från Seerr?';
	@override String get disconnectConfirmBody => 'Plezy glömmer den här Seerr-instansen. Återanslut när som helst.';
	@override String get request => 'Begär';
	@override String get request4k => 'Begär i 4K';
	@override String get seasons => 'Säsonger';
	@override String get allSeasons => 'Alla säsonger';
	@override String get advancedOptions => 'Avancerat';
	@override String get destinationServer => 'Målserver';
	@override String get qualityProfile => 'Kvalitetsprofil';
	@override String get rootFolder => 'Rotmapp';
	@override String get languageProfile => 'Språkprofil';
	@override String get requestSubmitted => 'Begäran skickad';
	@override String requestFailed({required Object error}) => 'Begäran misslyckades: ${error}';
	@override String get requestsLoadFailed => 'Det gick inte att läsa in alternativ för begäran';
	@override String get nothingToRequest => 'Allt är redan tillgängligt eller begärt.';
	@override String get statusAvailable => 'Tillgänglig';
	@override String get statusPartiallyAvailable => 'Delvis tillgänglig';
	@override String get statusRequested => 'Begärd';
	@override String get statusProcessing => 'Bearbetas';
}

// Path: services
class _TranslationsServicesSv extends TranslationsServicesEn {
	_TranslationsServicesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tjänster';
	@override String get hubSubtitle => 'Synkronisera dina framsteg och begär nya titlar.';
	@override String get notConnected => 'Ej ansluten';
	@override String connectedAs({required Object username}) => 'Ansluten som @${username}';
	@override String get scrobble => 'Spåra framsteg automatiskt';
	@override String get scrobbleDescription => 'Uppdaterar din lista när du är klar med ett avsnitt eller en film.';
	@override String disconnectConfirm({required Object service}) => 'Koppla från ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy slutar uppdatera ${service}. Återanslut när som helst.';
	@override String connectFailed({required Object service}) => 'Kunde inte ansluta till ${service}. Försök igen.';
	@override late final _TranslationsServicesNamesSv names = _TranslationsServicesNamesSv._(_root);
	@override late final _TranslationsServicesDeviceCodeSv deviceCode = _TranslationsServicesDeviceCodeSv._(_root);
	@override late final _TranslationsServicesOauthProxySv oauthProxy = _TranslationsServicesOauthProxySv._(_root);
	@override late final _TranslationsServicesLibraryFilterSv libraryFilter = _TranslationsServicesLibraryFilterSv._(_root);
}

// Path: addServer
class _TranslationsAddServerSv extends TranslationsAddServerEn {
	_TranslationsAddServerSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Lägg till Jellyfin-server';
	@override String get serverUrls => 'Server-URL:er';
	@override String get serverUrlsHelper => 'Flera URL:er tillåtna, separerade med kommatecken.';
	@override String get findServer => 'Hitta server';
	@override String get searchingLocalServers => 'Söker efter lokala Jellyfin-servrar...';
	@override String get localServers => 'Lokala Jellyfin-servrar';
	@override String get username => 'Användarnamn';
	@override String get password => 'Lösenord';
	@override String get signIn => 'Logga in';
	@override String get change => 'Ändra';
	@override String get required => 'Krävs';
	@override String couldNotReachServer({required Object error}) => 'Kunde inte nå servern: ${error}';
	@override String signInFailed({required Object error}) => 'Inloggning misslyckades: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect misslyckades: ${error}';
	@override String get addPlexTitle => 'Logga in med Plex';
	@override String get pinExpired => 'PIN-koden gick ut innan inloggning. Försök igen.';
	@override String failedToRegisterAccount({required Object error}) => 'Kunde inte registrera kontot: ${error}';
	@override String get enterJellyfinUrlError => 'Ange URL till din Jellyfin-server';
	@override String get addConnectionTitle => 'Lägg till anslutning';
	@override String addConnectionTitleScoped({required Object name}) => 'Lägg till i ${name}';
	@override String get signInWithPlexCard => 'Logga in med Plex';
	@override String get signInWithPlexCardSubtitle => 'Auktorisera den här enheten. Delade servrar läggs till.';
	@override String get signInWithPlexCardSubtitleScoped => 'Auktorisera ett Plex-konto. Home-användare blir profiler.';
	@override String get connectToJellyfinCard => 'Anslut till Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Ange server-URL, användarnamn och lösenord.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Logga in på en Jellyfin-server. Kopplas till ${name}.';
	@override String get borrowFromAnotherProfile => 'Låna från en annan profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Återanvänd en annan profils anslutning. PIN-skyddade profiler kräver en PIN.';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsSv extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Spela/Pausa';
	@override String get volumeUp => 'Höj volym';
	@override String get volumeDown => 'Sänk volym';
	@override String seekForward({required Object seconds}) => 'Spola framåt (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Spola bakåt (${seconds}s)';
	@override String get fullscreenToggle => 'Växla helskärm';
	@override String get muteToggle => 'Växla ljud av';
	@override String get subtitleToggle => 'Växla undertexter';
	@override String get audioTrackNext => 'Nästa ljudspår';
	@override String get subtitleTrackNext => 'Nästa undertextspår';
	@override String get chapterNext => 'Nästa kapitel';
	@override String get chapterPrevious => 'Föregående kapitel';
	@override String get episodeNext => 'Nästa avsnitt';
	@override String get episodePrevious => 'Föregående avsnitt';
	@override String get speedIncrease => 'Öka hastighet';
	@override String get speedDecrease => 'Minska hastighet';
	@override String get speedReset => 'Återställ hastighet';
	@override String get zoomIn => 'Zooma in';
	@override String get zoomOut => 'Zooma ut';
	@override String get zoomReset => 'Återställ zoom';
	@override String get subSeekNext => 'Hoppa till nästa undertext';
	@override String get subSeekPrev => 'Hoppa till föregående undertext';
	@override String get shaderToggle => 'Växla shaders';
	@override String get skipMarker => 'Hoppa över intro/eftertexter';
	@override String get screenshot => 'Ta skärmbild';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsSv extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Kräver Android 8.0 eller nyare';
	@override String get iosVersion => 'Kräver iOS 15.0 eller nyare';
	@override String get permissionDisabled => 'Bild-i-bild är inaktiverat. Aktivera det i systeminställningarna.';
	@override String get notSupported => 'Denna enhet stöder inte bild-i-bild-läge';
	@override String get voSwitchFailed => 'Kunde inte byta videoutgång för bild-i-bild';
	@override String get failed => 'Bild-i-bild kunde inte starta';
	@override String unknown({required Object error}) => 'Ett fel uppstod: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsSv extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekommenderat';
	@override String get browse => 'Bläddra';
	@override String get collections => 'Samlingar';
	@override String get playlists => 'Spellistor';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsSv extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppering';
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get shows => 'Serier';
	@override String get seasons => 'Säsonger';
	@override String get episodes => 'Avsnitt';
	@override String get artists => 'Artister';
	@override String get albums => 'Album';
	@override String get tracks => 'Låtar';
	@override String get folders => 'Mappar';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesSv extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genre';
	@override String get year => 'År';
	@override String get contentRating => 'Åldersgräns';
	@override String get tag => 'Tagg';
	@override String get unwatched => 'Osedda';
	@override String get unplayed => 'Ospelat';
	@override String get favorites => 'Favoriter';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsSv extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get dateAdded => 'Tillagd';
	@override String get releaseDate => 'Releasedatum';
	@override String get rating => 'Betyg';
	@override String get communityRating => 'Användarbetyg';
	@override String get criticRating => 'Kritikerbetyg';
	@override String get userRating => 'Användarbetyg';
	@override String get datePlayed => 'Speldatum';
	@override String get playCount => 'Antal spelningar';
	@override String get productionYear => 'Produktionsår';
	@override String get runtime => 'Speltid';
	@override String get officialRating => 'Officiell klassificering';
	@override String get premiereDate => 'Premiärdatum';
	@override String get startDate => 'Startdatum';
	@override String get airTime => 'Sändningstid';
	@override String get studio => 'Studio';
	@override String get random => 'Slumpmässigt';
	@override String get dateShared => 'Delningsdatum';
	@override String get latestEpisodeAirDate => 'Senaste avsnittets sändningsdatum';
	@override String get lastEpisodeDateAdded => 'Datum då senaste avsnittet lades till';
}

// Path: explore.rows
class _TranslationsExploreRowsSv extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Bevakningslista';
	@override String get recommendedMovies => 'Rekommenderade filmer';
	@override String get recommendedShows => 'Rekommenderade serier';
	@override String get trendingMovies => 'Trendande filmer';
	@override String get trendingShows => 'Trendande serier';
	@override String get popularMovies => 'Populära filmer';
	@override String get popularShows => 'Populära serier';
	@override String get suggestedAnime => 'Föreslagna anime';
	@override String get airingAnime => 'Bästa pågående anime';
	@override String get popularAnime => 'Mest populära anime';
	@override String get trending => 'Trendar nu';
	@override String get upcomingMovies => 'Kommande filmer';
	@override String get upcomingShows => 'Kommande serier';
}

// Path: explore.status
class _TranslationsExploreStatusSv extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Pågår';
	@override String get ended => 'Avslutad';
	@override String get canceled => 'Nedlagd';
	@override String get upcoming => 'Kommande';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionSv extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Startar fjärrserver...';
	@override String get hostAddress => 'Värdadress';
	@override String get connected => 'Ansluten';
	@override String get serverRunning => 'Fjärrserver aktiv';
	@override String get serverStopped => 'Fjärrserver stoppad';
	@override String get serverRunningDescription => 'Mobila enheter i ditt nätverk kan ansluta till den här appen';
	@override String get serverStoppedDescription => 'Starta servern för att tillåta mobila enheter att ansluta';
	@override String get usePhoneToControl => 'Använd din mobila enhet för att styra denna app';
	@override String get startServer => 'Starta server';
	@override String get stopServer => 'Stoppa server';
	@override String get minimize => 'Minimera';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingSv extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Plezy-enheter med samma Plex-konto visas här';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Ansluter...';
	@override String get searchingForDevices => 'Söker efter enheter...';
	@override String get noDevicesFound => 'Inga enheter hittades i ditt nätverk';
	@override String get noDevicesHint => 'Öppna Plezy på desktop och använd samma WiFi';
	@override String get availableDevices => 'Tillgängliga enheter';
	@override String get manualConnection => 'Manuell anslutning';
	@override String get cryptoInitFailed => 'Kunde inte starta säker anslutning. Logga in på Plex först.';
	@override String get validationHostRequired => 'Ange värdadress';
	@override String get validationHostFormat => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Anslutningen tog för lång tid. Använd samma nätverk på båda enheter.';
	@override String get sessionNotFound => 'Enhet hittades inte. Kontrollera att Plezy körs på värden.';
	@override String get authFailed => 'Autentisering misslyckades. Båda enheter behöver samma Plex-konto.';
	@override String failedToConnect({required Object error}) => 'Kunde inte ansluta: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteSv extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vill du koppla från fjärrsessionen?';
	@override String get reconnecting => 'Återansluter...';
	@override String attemptOf({required Object current}) => 'Försök ${current} av 5';
	@override String get retryNow => 'Försök nu';
	@override String get tabRemote => 'Fjärrkontroll';
	@override String get tabPlay => 'Spela';
	@override String get tabMore => 'Mer';
	@override String get menu => 'Meny';
	@override String get tabNavigation => 'Fliknavigering';
	@override String get tabDiscover => 'Upptäck';
	@override String get tabLibraries => 'Bibliotek';
	@override String get tabSearch => 'Sök';
	@override String get tabDownloads => 'Nedladdningar';
	@override String get tabSettings => 'Inställningar';
	@override String get previous => 'Föregående';
	@override String get playPause => 'Spela/Pausa';
	@override String get next => 'Nästa';
	@override String get seekBack => 'Spola bakåt';
	@override String get stop => 'Stopp';
	@override String get seekForward => 'Spola framåt';
	@override String get volume => 'Volym';
	@override String get volumeDown => 'Ner';
	@override String get volumeUp => 'Upp';
	@override String get fullscreen => 'Helskärm';
	@override String get subtitles => 'Undertexter';
	@override String get audio => 'Ljud';
	@override String get searchHint => 'Sök på datorn...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsSv extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Inget nätverksgränssnitt hittades';
	@override String get authenticationFailed => 'Autentisering misslyckades';
	@override String serverStartFailed({required Object error}) => 'Det gick inte att starta fjärrservern: ${error}';
	@override String commandFailed({required Object error}) => 'Det gick inte att skicka fjärrkommandot: ${error}';
	@override String get joinTimedOut => 'Tidsgräns vid anslutning till session';
	@override String get failedToConnectAnyAddress => 'Kunde inte ansluta till någon adress';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Anslutning förlorad efter ${attempts} försök';
	@override String get connectionLost => 'Anslutning förlorad';
}

// Path: services.names
class _TranslationsServicesNamesSv extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeSv extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktivera Plezy på ${service}';
	@override String body({required Object url}) => 'Besök ${url} och ange den här koden:';
	@override String openToActivate({required Object service}) => 'Öppna ${service} för att aktivera';
	@override String get copyCode => 'Kopiera aktiveringskod';
	@override String get waitingForAuthorization => 'Väntar på auktorisering…';
	@override String get codeCopied => 'Kod kopierad';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxySv extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxySv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Logga in på ${service}';
	@override String get body => 'Skanna den här QR-koden eller öppna URL:en på valfri enhet.';
	@override String openToSignIn({required Object service}) => 'Öppna ${service} för att logga in';
	@override String get copyUrl => 'Kopiera inloggnings-URL';
	@override String get urlCopied => 'URL kopierad';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterSv extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterSv._(TranslationsSv root) : this._root = root, super.internal(root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteksfilter';
	@override String get subtitleAllSyncing => 'Synkroniserar alla bibliotek';
	@override String get subtitleNoneSyncing => 'Ingenting synkroniseras';
	@override String subtitleBlocked({required Object count}) => '${count} blockerade';
	@override String subtitleAllowed({required Object count}) => '${count} tillåtna';
	@override String get mode => 'Filterläge';
	@override String get modeBlacklist => 'Svartlista';
	@override String get modeWhitelist => 'Vitlista';
	@override String get modeHintBlacklist => 'Synkronisera alla bibliotek utom de som markerats nedan.';
	@override String get modeHintWhitelist => 'Synkronisera endast de bibliotek som markerats nedan.';
	@override String get libraries => 'Bibliotek';
	@override String get noLibraries => 'Inga bibliotek tillgängliga';
}

/// The flat map containing all translations for locale <sv>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsSv {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Logga in med Plex',
			'auth.showQRCode' => 'Visa QR-kod',
			'auth.authenticate' => 'Autentisera',
			'auth.authenticationTimeout' => 'Autentisering tog för lång tid. Försök igen.',
			'auth.scanQRToSignIn' => 'Skanna QR-koden för att logga in',
			'auth.waitingForAuth' => 'Väntar på autentisering...\nLogga in från din webbläsare.',
			'auth.useBrowser' => 'Använd webbläsare',
			'auth.or' => 'eller',
			'auth.connectToJellyfin' => 'Anslut till Jellyfin',
			'auth.useQuickConnect' => 'Använd Quick Connect',
			'auth.quickConnectInstructions' => 'Öppna Quick Connect i Jellyfin och ange den här koden.',
			'auth.quickConnectWaiting' => 'Väntar på godkännande…',
			'auth.quickConnectCancel' => 'Avbryt',
			'auth.quickConnectExpired' => 'Quick Connect har gått ut. Försök igen.',
			'common.cancel' => 'Avbryt',
			'common.save' => 'Spara',
			'common.close' => 'Stäng',
			'common.clear' => 'Rensa',
			'common.reset' => 'Återställ',
			'common.later' => 'Senare',
			'common.submit' => 'Skicka',
			'common.confirm' => 'Bekräfta',
			'common.retry' => 'Försök igen',
			'common.logout' => 'Logga ut',
			'common.unknown' => 'Okänd',
			'common.refresh' => 'Uppdatera',
			'common.yes' => 'Ja',
			'common.no' => 'Nej',
			'common.delete' => 'Ta bort',
			'common.edit' => 'Redigera',
			'common.shuffle' => 'Blanda',
			'common.addTo' => 'Lägg till i...',
			'common.createNew' => 'Skapa ny',
			'common.connect' => 'Anslut',
			'common.disconnect' => 'Koppla från',
			'common.play' => 'Spela',
			'common.pause' => 'Pausa',
			'common.resume' => 'Återuppta',
			'common.error' => 'Fel',
			'common.search' => 'Sök',
			'common.home' => 'Hem',
			'common.back' => 'Tillbaka',
			'common.settings' => 'Mer',
			'common.mute' => 'Ljud av',
			'common.ok' => 'OK',
			'common.off' => 'Av',
			'common.seasonNumber' => ({required Object number}) => 'Säsong ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Avsnitt ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Kapitel ${number}',
			'common.reconnect' => 'Återanslut',
			'common.viewAll' => 'Visa alla',
			'common.checkingNetwork' => 'Kontrollerar nätverk...',
			'common.loadingServers' => 'Laddar servrar...',
			'common.connectingToServers' => 'Ansluter till servrar...',
			'common.startingOfflineMode' => 'Startar offlineläge...',
			'common.loading' => 'Laddar...',
			'common.fullscreen' => 'Helskärm',
			'common.exitFullscreen' => 'Avsluta helskärm',
			'common.pressBackAgainToExit' => 'Tryck bakåt igen för att avsluta',
			'screens.licenses' => 'Licenser',
			'screens.switchProfile' => 'Byt profil',
			'screens.subtitleStyling' => 'Undertext-styling',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Loggar',
			'update.available' => 'Uppdatering tillgänglig',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} är tillgänglig',
			'update.currentVersion' => ({required Object version}) => 'Nuvarande: ${version}',
			'update.skipVersion' => 'Hoppa över denna version',
			'update.viewRelease' => 'Visa release',
			'update.latestVersion' => 'Du har den senaste versionen',
			'update.checkFailed' => 'Misslyckades att kontrollera uppdateringar',
			'settings.title' => 'Inställningar',
			'settings.supportDeveloper' => 'Stöd Plezy',
			'settings.supportDeveloperDescription' => 'Donera via Liberapay för att finansiera utvecklingen',
			'settings.language' => 'Språk',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Utseende',
			'settings.videoPlayback' => 'Videouppspelning',
			'settings.videoPlaybackDescription' => 'Konfigurera uppspelningsbeteende',
			'settings.advanced' => 'Avancerat',
			'settings.episodePosterMode' => 'Avsnittsaffisch-stil',
			'settings.seriesPoster' => 'Serieaffisch',
			'settings.seasonPoster' => 'Säsongsaffisch',
			'settings.episodeThumbnail' => 'Miniatyr',
			'settings.showHeroSectionDescription' => 'Visa utvalda innehållskarusell på startsidan',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minuter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Ange tid (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Ljust',
			'settings.darkTheme' => 'Mörkt',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Biblioteksdensitet',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Bekväm',
			'settings.viewMode' => 'Visningsläge',
			'settings.gridView' => 'Rutnät',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Visa hjältesektion',
			'settings.continueWatchingAction' => 'Åtgärd för Fortsätt titta',
			'settings.continueWatchingPlay' => 'Spela',
			'settings.continueWatchingDetails' => 'Öppna detaljer',
			'settings.episodeAction' => 'Åtgärd för avsnitt',
			'settings.episodePlay' => 'Spela',
			'settings.episodeDetails' => 'Öppna detaljer',
			'settings.useGlobalHubs' => 'Använd startlayout',
			'settings.useGlobalHubsDescription' => 'Visa enhetliga startsideshubbar. Annars används biblioteksrekommendationer.',
			'settings.showServerNameOnHubs' => 'Visa servernamn på hubbar',
			'settings.showServerNameOnHubsDescription' => 'Visa alltid servernamn i hubbtitlar.',
			'settings.groupLibrariesByServer' => 'Gruppera bibliotek efter server',
			'settings.groupLibrariesByServerDescription' => 'Gruppera sidofältsbibliotek under varje medieserver.',
			'settings.alwaysKeepSidebarOpen' => 'Håll sidofältet alltid öppet',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidofältet förblir expanderat och innehållsytan anpassas',
			'settings.showUnwatchedCount' => 'Visa antal osedda',
			'settings.showUnwatchedCountDescription' => 'Visa antal osedda avsnitt för serier och säsonger',
			'settings.showEpisodeNumberOnCards' => 'Visa avsnittsnummer på kort',
			'settings.showEpisodeNumberOnCardsDescription' => 'Visa säsongs- och avsnittsnummer på avsnittskort',
			'settings.showSeasonPostersOnTabs' => 'Visa säsongsaffischer på flikar',
			'settings.showSeasonPostersOnTabsDescription' => 'Visa varje säsongs affisch ovanför fliken',
			'settings.tvFullCardLayout' => 'Heltäckande TV-kort',
			'settings.tvFullCardLayoutDescription' => 'Använd TV-kort med enbart bild och skådespelarnamn ovanpå',
			'settings.focusGlow' => 'Fokusglöd',
			'settings.focusGlowDescription' => 'Visa en mjuk glöd runt kortet i fokus',
			'settings.visualEffects' => 'Visuella effekter',
			'settings.visualEffectsAuto' => 'Automatiskt',
			'settings.visualEffectsAutoDescription' => 'Minska effekter automatiskt på enheter med låg effekt',
			'settings.visualEffectsFull' => 'Fullständiga',
			'settings.visualEffectsReduced' => 'Minskade',
			'settings.visualEffectsReducedDescription' => 'Färre animationer och grafik med lägre upplösning',
			'settings.hideSpoilers' => 'Dölj spoilers för osedda avsnitt',
			'settings.hideSpoilersDescription' => 'Sudda miniatyrbilder och beskrivningar för osedda avsnitt',
			'settings.playerBackend' => 'Spelarmotor',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hårdvaruavkodning',
			'settings.hardwareDecodingDescription' => 'Använd hårdvaruacceleration när tillgängligt',
			'settings.bufferSize' => 'Bufferstorlek',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Rekommenderat)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB minne tillgängligt. En buffert på ${size}MB kan påverka uppspelningen.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.musicQualityTitle' => 'Musikkvalitet',
			'settings.subtitleStyling' => 'Undertext-styling',
			'settings.subtitleStylingDescription' => 'Anpassa undertextutseende',
			'settings.smallSkipDuration' => 'Kort hoppvaraktighet',
			'settings.largeSkipDuration' => 'Lång hoppvaraktighet',
			'settings.rewindOnResume' => 'Spola tillbaka vid återupptagning',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard sovtimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minuter',
			'settings.rememberTrackSelections' => 'Kom ihåg spårval per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Kom ihåg ljud- och undertextval per titel',
			'settings.showChapterMarkersOnTimeline' => 'Visa kapitelmarkörer på tidslinjen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Dela upp tidslinjen vid kapitelgränser',
			'settings.clickVideoTogglesPlayback' => 'Klicka på videon för att växla mellan spela upp och pausa.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klicka på video för att spela/pausa istället för att visa kontroller.',
			'settings.videoPlayerControls' => 'Videospelar-kontroller',
			'settings.keyboardShortcuts' => 'Tangentbordsgenvägar',
			'settings.keyboardShortcutsDescription' => 'Anpassa tangentbordsgenvägar',
			'settings.videoPlayerNavigation' => 'Navigering i videospelaren',
			'settings.videoPlayerNavigationDescription' => 'Använd piltangenter för att navigera videospelarens kontroller',
			'settings.watchTogetherRelay' => 'Titta Tillsammans-relay',
			'settings.watchTogetherRelayDescription' => 'Ange en anpassad relay. Alla måste använda samma server.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.exempel.se',
			'settings.crashReporting' => 'Kraschrapportering',
			'settings.crashReportingDescription' => 'Skicka kraschrapporter för att förbättra appen',
			'settings.debugLogging' => 'Felsökningsloggning',
			'settings.debugLoggingDescription' => 'Aktivera detaljerad loggning för felsökning',
			'settings.viewLogs' => 'Visa loggar',
			'settings.viewLogsDescription' => 'Visa applikationsloggar',
			'settings.clearCache' => 'Rensa cache',
			'settings.clearCacheDescription' => 'Rensa cachade bilder och data. Innehåll kan laddas långsammare.',
			'settings.clearCacheSuccess' => 'Cache rensad framgångsrikt',
			'settings.resetSettings' => 'Återställ inställningar',
			'settings.resetSettingsDescription' => 'Återställ standardinställningar. Detta kan inte ångras.',
			'settings.resetSettingsSuccess' => 'Inställningar återställda framgångsrikt',
			'settings.backup' => 'Säkerhetskopia',
			'settings.exportSettings' => 'Exportera inställningar',
			'settings.exportSettingsDescription' => 'Spara dina inställningar till en fil',
			'settings.exportSettingsSuccess' => 'Inställningar exporterade',
			'settings.exportSettingsFailed' => 'Kunde inte exportera inställningar',
			'settings.importSettings' => 'Importera inställningar',
			'settings.importSettingsDescription' => 'Återställ inställningar från en fil',
			'settings.importSettingsConfirm' => 'Detta ersätter dina nuvarande inställningar. Fortsätta?',
			'settings.importSettingsSuccess' => 'Inställningar importerade',
			'settings.importSettingsFailed' => 'Kunde inte importera inställningar',
			'settings.importSettingsInvalidFile' => 'Denna fil är inte en giltig Plezy-export',
			'settings.importSettingsNoUser' => 'Logga in innan du importerar inställningar',
			'settings.shortcutsReset' => 'Genvägar återställda till standard',
			'settings.about' => 'Om',
			'settings.aboutDescription' => 'Appinformation och licenser',
			'settings.updates' => 'Uppdateringar',
			'settings.updateAvailable' => 'Uppdatering tillgänglig',
			'settings.checkForUpdates' => 'Kontrollera uppdateringar',
			'settings.autoCheckUpdatesOnStartup' => 'Kontrollera uppdateringar automatiskt vid start',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Meddela när en uppdatering finns vid start',
			'settings.validationErrorEnterNumber' => 'Vänligen ange ett giltigt nummer',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Genväg redan tilldelad ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Genväg uppdaterad för ${action}',
			'settings.autoSkip' => 'Auto Hoppa Över',
			'settings.autoSkipIntro' => 'Hoppa Över Intro Automatiskt',
			'settings.autoSkipIntroDescription' => 'Hoppa automatiskt över intro-markörer efter några sekunder',
			'settings.autoSkipCredits' => 'Hoppa Över Credits Automatiskt',
			'settings.autoSkipCreditsDescription' => 'Hoppa automatiskt över credits och spela nästa avsnitt',
			'settings.forceSkipMarkerFallback' => 'Tvinga reservmarkörer',
			'settings.forceSkipMarkerFallbackDescription' => 'Använd mönster i kapiteltitlar även när Plex har markörer',
			'settings.autoSkipDelay' => 'Fördröjning Auto Hoppa Över',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning',
			'settings.introPattern' => 'Intromarkörsmönster',
			'settings.introPatternDescription' => 'Reguljärt uttryck för att matcha intromarkörer i kapiteltitlar',
			'settings.creditsPattern' => 'Eftertextmarkörsmönster',
			'settings.creditsPatternDescription' => 'Reguljärt uttryck för att matcha eftertextmarkörer i kapiteltitlar',
			'settings.invalidRegex' => 'Ogiltigt reguljärt uttryck',
			'settings.regex' => 'Reguljärt uttryck',
			'settings.downloads' => 'Nedladdningar',
			'settings.downloadLocationDescription' => 'Välj var nedladdat innehåll ska lagras',
			'settings.downloadLocationDefault' => 'Standard (App-lagring)',
			'settings.downloadLocationCustom' => 'Anpassad Plats',
			'settings.selectFolder' => 'Välj Mapp',
			'settings.resetToDefault' => 'Återställ till Standard',
			'settings.currentPath' => ({required Object path}) => 'Nuvarande: ${path}',
			'settings.downloadLocationChanged' => 'Nedladdningsplats ändrad',
			'settings.downloadLocationReset' => 'Nedladdningsplats återställd till standard',
			'settings.downloadLocationInvalid' => 'Vald mapp är inte skrivbar',
			'settings.downloadLocationSelectError' => 'Kunde inte välja mapp',
			'settings.downloadOnWifiOnly' => 'Ladda ner endast på WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Förhindra nedladdningar vid användning av mobildata',
			'settings.autoRemoveWatchedDownloads' => 'Ta bort sedda nedladdningar automatiskt',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Ta bort sedda nedladdningar automatiskt',
			'settings.cellularDownloadBlocked' => 'Nedladdningar är blockerade via mobilnät. Använd WiFi eller ändra inställningen.',
			'settings.maxVolume' => 'Maximal volym',
			'settings.maxVolumeDescription' => 'Tillåt volym över 100% för tyst media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Visa vad du tittar på i Discord',
			'settings.services' => 'Tjänster',
			'settings.servicesDescription' => 'Anslut Trakt, MyAnimeList, Seerr med mera',
			'settings.manageLibrariesDescription' => 'Ordna om och dölj bibliotek',
			'settings.companionRemoteServer' => 'Companion Remote-server',
			'settings.companionRemoteServerDescription' => 'Tillåt mobila enheter i ditt nätverk att styra denna app',
			'settings.autoPip' => 'Automatisk bild-i-bild',
			'settings.autoPipDescription' => 'Gå till bild-i-bild när du lämnar under uppspelning',
			'settings.matchContentFrameRate' => 'Matcha innehållets bildfrekvens',
			'settings.matchContentFrameRateDescription' => 'Matcha skärmens uppdateringsfrekvens med videoinnehållet',
			'settings.matchRefreshRate' => 'Matcha uppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Matcha skärmens uppdateringsfrekvens i helskärm',
			'settings.matchDynamicRange' => 'Matcha dynamiskt omfång',
			'settings.matchDynamicRangeDescription' => 'Slå på HDR för HDR-innehåll och sedan tillbaka till SDR',
			'settings.displaySwitchDelay' => 'Fördröjning vid skärmbyte',
			'settings.tunneledPlayback' => 'Tunneluppspelning',
			'settings.tunneledPlaybackDescription' => 'Använd videotunnling. Inaktivera om HDR-uppspelning visar svart video.',
			'settings.audioPassthrough' => 'Ljudgenomkoppling',
			'settings.audioPassthroughDescription' => 'Skicka Dolby/DTS-ljud till din receiver eller TV utan omkodning och bevara surroundljudet. Stäng av om du inte har något ljud.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Lämnar Dolby Digital Plus (inkl. Atmos) till systemet som bitstream. DTS och TrueHD spelas fortfarande upp som flerkanals-PCM. Korta ljudavbrott kan förekomma vid sökning.',
			'settings.audioDownmix' => 'Nedmixning till stereo',
			'settings.audioDownmixDescription' => 'Mixar ner surroundljud till två kanaler för stereohögtalare eller hörlurar',
			'settings.downmixCenterBoost' => 'Förstärkning av centerkanal',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Förstärkning (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalisera ljudstyrka vid nedmixning',
			'settings.audioDownmixNormalizeDescription' => 'Sänker mixen för att undvika klippning. Stäng av för att behålla originalvolymen (höga scener kan förvrängas).',
			'settings.atmosDiagnostics' => 'Atmos-utgångstest',
			'settings.atmosDiagnosticsDescription' => 'Diagnostisera Dolby Atmos-utgången genom att spela testsignaler via systemspelaren',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos-ström',
			'settings.atmosTestHlsAtmosDescription' => 'Känd fungerande Dolby Atmos-ström. Receivern bör visa Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Apple surround-ström',
			'settings.atmosTestHlsControlDescription' => 'Kontrollström utan Atmos. Receivern bör visa surround utan Atmos.',
			'settings.atmosTestRawStream' => 'Rå EAC3-ström',
			'settings.atmosTestRawStreamDescription' => 'Strömmar testfilen precis som Atmos-uppspelning i spelaren. Kräver testfilens URL.',
			'settings.atmosTestRawFile' => 'Rå EAC3-fil',
			'settings.atmosTestRawFileDescription' => 'Spelar upp testfilen med känd längd. Kräver testfilens URL.',
			'settings.atmosTestStop' => 'Stoppa test',
			'settings.atmosTestUrl' => 'Testfilens URL',
			'settings.atmosTestUrlDescription' => 'HTTP-URL till en rå .ec3 Dolby Atmos-fil (t.ex. extraherad med ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Ange testfilens URL först',
			'settings.atmosTestStatus' => 'Status',
			'settings.dvConversionMode' => 'Dolby Vision-konvertering',
			'settings.dvConversionModeDescription' => 'Välj hur ExoPlayer hanterar Dolby Vision Profile 7-filer.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Inbyggt / inaktiverat',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Använd enhetens kapabilitetsdetektering och normalt reservbeteende',
			'settings.dvConversionNativeDescription' => 'Tvinga native DV7 och undertryck försök till DV-konvertering',
			'settings.dvConversionDv81Description' => 'Tvinga inline RPU-konvertering till Dolby Vision profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Ta bort Dolby Vision RPU/EL-lager och presentera vanlig HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Fråga efter profil vid appstart',
			'settings.requireProfileSelectionOnOpenDescription' => 'Visa profilval varje gång appen öppnas',
			'settings.forceTvMode' => 'Tvinga TV-läge',
			'settings.forceTvModeDescription' => 'Tvinga TV-layout. För enheter som inte upptäcks automatiskt. Kräver omstart.',
			'settings.startInFullscreen' => 'Starta i helskärm',
			'settings.startInFullscreenDescription' => 'Öppna Plezy i helskärm vid start',
			'settings.exitFullscreenOnPlayerClose' => 'Avsluta helskärm vid stängning av spelare',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Avslutar automatiskt helskärmsläge när videospelaren stängs',
			'settings.autoHidePerformanceOverlay' => 'Dölj prestandaöverlagring automatiskt',
			'settings.autoHidePerformanceOverlayDescription' => 'Tona prestandaöverlagringen med uppspelningskontrollerna',
			'settings.showNavBarLabels' => 'Visa navigeringsfältets etiketter',
			'settings.showNavBarLabelsDescription' => 'Visa textetiketter under navigeringsfältets ikoner',
			'settings.startupSection' => 'Startsektion',
			'settings.liveTvDefaultFavorites' => 'Standard till favoritkanaler',
			'settings.liveTvDefaultFavoritesDescription' => 'Visa bara favoritkanaler när du öppnar Live TV',
			'settings.display' => 'Skärm',
			'settings.homeScreen' => 'Hemskärm',
			'settings.navigation' => 'Navigering',
			'settings.window' => 'Fönster',
			'settings.content' => 'Innehåll',
			'settings.player' => 'Spelare',
			'settings.subtitlesAndConfig' => 'Undertexter och konfiguration',
			'settings.seekAndTiming' => 'Sök och timing',
			'settings.behavior' => 'Beteende',
			'search.hint' => 'Sök filmer, serier, musik...',
			'search.tryDifferentTerm' => 'Prova en annan sökterm',
			'search.searchYourMedia' => 'Sök i dina media',
			'search.enterTitleActorOrKeyword' => 'Ange en titel, skådespelare eller nyckelord',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Sätt genväg för ${actionName}',
			'hotkeys.clearShortcut' => 'Rensa genväg',
			'hotkeys.noShortcutSet' => 'Ingen genväg angiven',
			'hotkeys.currentShortcut' => 'Aktuell genväg:',
			'hotkeys.pressToRecord' => 'Välj för att registrera en genväg',
			'hotkeys.recordingShortcut' => 'Tryck på genvägen nu',
			'hotkeys.actions.playPause' => 'Spela/Pausa',
			'hotkeys.actions.volumeUp' => 'Höj volym',
			'hotkeys.actions.volumeDown' => 'Sänk volym',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Spola framåt (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Spola bakåt (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Växla helskärm',
			'hotkeys.actions.muteToggle' => 'Växla ljud av',
			'hotkeys.actions.subtitleToggle' => 'Växla undertexter',
			'hotkeys.actions.audioTrackNext' => 'Nästa ljudspår',
			'hotkeys.actions.subtitleTrackNext' => 'Nästa undertextspår',
			'hotkeys.actions.chapterNext' => 'Nästa kapitel',
			'hotkeys.actions.chapterPrevious' => 'Föregående kapitel',
			'hotkeys.actions.episodeNext' => 'Nästa avsnitt',
			'hotkeys.actions.episodePrevious' => 'Föregående avsnitt',
			'hotkeys.actions.speedIncrease' => 'Öka hastighet',
			'hotkeys.actions.speedDecrease' => 'Minska hastighet',
			'hotkeys.actions.speedReset' => 'Återställ hastighet',
			'hotkeys.actions.zoomIn' => 'Zooma in',
			'hotkeys.actions.zoomOut' => 'Zooma ut',
			'hotkeys.actions.zoomReset' => 'Återställ zoom',
			'hotkeys.actions.subSeekNext' => 'Hoppa till nästa undertext',
			'hotkeys.actions.subSeekPrev' => 'Hoppa till föregående undertext',
			'hotkeys.actions.shaderToggle' => 'Växla shaders',
			'hotkeys.actions.skipMarker' => 'Hoppa över intro/eftertexter',
			'hotkeys.actions.screenshot' => 'Ta skärmbild',
			'fileInfo.title' => 'Filinformation',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Ljud',
			'fileInfo.file' => 'Fil',
			'fileInfo.advanced' => 'Avancerat',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.resolution' => 'Upplösning',
			'fileInfo.bitrate' => 'Bithastighet',
			'fileInfo.frameRate' => 'Bildfrekvens',
			'fileInfo.aspectRatio' => 'Bildförhållande',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Bitdjup',
			'fileInfo.colorSpace' => 'Färgrymd',
			'fileInfo.colorRange' => 'Färgområde',
			'fileInfo.colorPrimaries' => 'Färggrunder',
			'fileInfo.chromaSubsampling' => 'Kroma-undersampling',
			'fileInfo.channels' => 'Kanaler',
			'fileInfo.subtitles' => 'Undertexter',
			'fileInfo.overallBitrate' => 'Total bithastighet',
			'fileInfo.path' => 'Sökväg',
			'fileInfo.size' => 'Storlek',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Varaktighet',
			'fileInfo.optimizedForStreaming' => 'Optimerad för streaming',
			'fileInfo.has64bitOffsets' => '64-bit offset',
			'mediaMenu.markAsWatched' => 'Markera som sedd',
			'mediaMenu.markAsUnwatched' => 'Markera som osedd',
			'mediaMenu.removeFromContinueWatching' => 'Ta bort från Fortsätt titta',
			'mediaMenu.viewDetails' => 'Visa detaljer',
			'mediaMenu.goToSeries' => 'Gå till serie',
			'mediaMenu.shufflePlay' => 'Blanda uppspelning',
			'mediaMenu.shuffleNotAvailableOffline' => 'Blandad uppspelning är inte tillgänglig offline',
			'mediaMenu.fileInfo' => 'Filinformation',
			'mediaMenu.deleteFromServer' => 'Ta bort från servern',
			'mediaMenu.confirmDelete' => 'Ta bort detta media och dess filer från din server?',
			'mediaMenu.deleteMultipleWarning' => 'Detta inkluderar alla avsnitt och deras filer.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Mediaobjekt borttaget',
			'mediaMenu.mediaFailedToDelete' => 'Kunde inte ta bort mediaobjekt',
			'mediaMenu.rate' => 'Betygsätt',
			'mediaMenu.playFromBeginning' => 'Spela från början',
			'mediaMenu.playVersion' => 'Spela version...',
			'rateSheet.title' => 'Betygsätt',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Favorit',
			'rateSheet.favorited' => 'Tillagd i favoriter',
			'rateSheet.saved' => 'Sparat',
			'rateSheet.notAvailable' => 'Ingen matchning hittades',
			'rateSheet.noConnectedServices' => 'Anslut en tjänst i Inställningar för att betygsätta där.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'sedd',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent sedd',
			'accessibility.mediaCardUnwatched' => 'osedd',
			'accessibility.tapToPlay' => 'Tryck för att spela',
			'accessibility.decrease' => 'Minska',
			'accessibility.increase' => 'Öka',
			'accessibility.decreaseValue' => ({required Object label}) => 'Minska ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Öka ${label}',
			'accessibility.hue' => 'Nyans',
			'accessibility.saturation' => 'Mättnad',
			'accessibility.brightness' => 'Ljusstyrka',
			'accessibility.hexColor' => 'Hexfärg',
			'accessibility.expandText' => 'Expandera text',
			'accessibility.collapseText' => 'Fäll ihop text',
			'tooltips.shufflePlay' => 'Blanda uppspelning',
			'tooltips.playTrailer' => 'Spela trailer',
			'tooltips.markAsWatched' => 'Markera som sedd',
			'tooltips.markAsUnwatched' => 'Markera som osedd',
			'videoControls.audioLabel' => 'Ljud',
			'videoControls.subtitlesLabel' => 'Undertexter',
			'videoControls.resetToZero' => 'Återställ till 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} spelas senare',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} spelas tidigare',
			'videoControls.noOffset' => 'Ingen offset',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fyll skärm',
			'videoControls.stretch' => 'Sträck',
			'videoControls.lockRotation' => 'Lås rotation',
			'videoControls.unlockRotation' => 'Lås upp rotation',
			'videoControls.timerActive' => 'Timer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Uppspelningen pausas om ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Slutet av aktuell video',
			'videoControls.sleepTimerStopAtHeader' => 'Stoppa vid',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Uppspelningen pausas i slutet av denna video',
			'videoControls.stillWatching' => 'Tittar du fortfarande?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausar om ${seconds}s',
			'videoControls.continueWatching' => 'Fortsätt',
			'videoControls.autoPlayNext' => 'Spela nästa automatiskt',
			'videoControls.playNext' => 'Spela nästa',
			'videoControls.playButton' => 'Spela',
			'videoControls.pauseButton' => 'Pausa',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Spola bakåt ${seconds} sekunder',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Spola framåt ${seconds} sekunder',
			'videoControls.previousButton' => 'Föregående avsnitt',
			'videoControls.nextButton' => 'Nästa avsnitt',
			'videoControls.previousChapterButton' => 'Föregående kapitel',
			'videoControls.nextChapterButton' => 'Nästa kapitel',
			'videoControls.muteButton' => 'Tysta',
			'videoControls.unmuteButton' => 'Slå på ljud',
			'videoControls.settingsButton' => 'Uppspelningsinställningar',
			'videoControls.tracksButton' => 'Ljud och undertexter',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionQualityButton' => 'Version och kvalitet',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Kvalitet',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkodning otillgänglig — spelar upp i originalkvalitet',
			'videoControls.pipButton' => 'Bild-i-bild läge',
			'videoControls.aspectRatioButton' => 'Bildförhållande',
			'videoControls.ambientLighting' => 'Ambientbelysning',
			'videoControls.fullscreenButton' => 'Aktivera helskärm',
			'videoControls.exitFullscreenButton' => 'Avsluta helskärm',
			'videoControls.alwaysOnTopButton' => 'Alltid överst',
			'videoControls.rotationLockButton' => 'Rotationslås',
			'videoControls.lockScreen' => 'Lås skärm',
			'videoControls.screenLockButton' => 'Skärmlås',
			'videoControls.longPressToUnlock' => 'Tryck länge för att låsa upp',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Volymnivå',
			'videoControls.endsAt' => ({required Object time}) => 'Slutar ${time}',
			'videoControls.pipActive' => 'Spelar i bild-i-bild',
			'videoControls.pipFailed' => 'Bild-i-bild kunde inte starta',
			'videoControls.screenshotSaved' => 'Skärmbild sparad',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Kräver Android 8.0 eller nyare',
			'videoControls.pipErrors.iosVersion' => 'Kräver iOS 15.0 eller nyare',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-i-bild är inaktiverat. Aktivera det i systeminställningarna.',
			'videoControls.pipErrors.notSupported' => 'Denna enhet stöder inte bild-i-bild-läge',
			'videoControls.pipErrors.voSwitchFailed' => 'Kunde inte byta videoutgång för bild-i-bild',
			'videoControls.pipErrors.failed' => 'Bild-i-bild kunde inte starta',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ett fel uppstod: ${error}',
			'videoControls.chapters' => 'Kapitel',
			'videoControls.noChaptersAvailable' => 'Inga kapitel tillgängliga',
			'videoControls.queue' => 'Kö',
			'videoControls.noQueueItems' => 'Inga objekt i kön',
			'videoControls.searchSubtitles' => 'Sök undertexter',
			'videoControls.language' => 'Språk',
			'videoControls.noSubtitlesFound' => 'Inga undertexter hittades',
			'videoControls.downloadedSubtitle' => 'Nedladdad',
			'videoControls.noSubtitlesAvailable' => 'Inga undertexter tillgängliga',
			'videoControls.noAudioTracksAvailable' => 'Inga ljudspår tillgängliga',
			'videoControls.noTracksAvailable' => 'Inga spår tillgängliga',
			'videoControls.subtitleDownloaded' => 'Undertext nedladdad',
			'videoControls.subtitleDownloadFailed' => 'Kunde inte ladda ner undertext',
			'videoControls.searchLanguages' => 'Sök språk...',
			'messages.markedAsWatched' => 'Markerad som sedd',
			'messages.markedAsUnwatched' => 'Markerad som osedd',
			'messages.markedAsWatchedOffline' => 'Markerad som sedd (synkroniseras när online)',
			'messages.markedAsUnwatchedOffline' => 'Markerad som osedd (synkroniseras när online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatiskt borttagen: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n, one: 'Tog automatiskt bort ${n} sedd nedladdning', other: 'Tog automatiskt bort ${n} sedda nedladdningar', ), 
			'messages.removedFromContinueWatching' => 'Borttagen från Fortsätt titta',
			'messages.errorLoading' => ({required Object error}) => 'Fel: ${error}',
			'messages.streamInterrupted' => 'Uppspelningen avbröts. Tryck på play eller spola för att försöka igen.',
			'messages.liveStreamInterrupted' => 'Livestreamen avbröts. Tryck på play för att försöka igen.',
			'messages.fileInfoNotAvailable' => 'Filinformation inte tillgänglig',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fel vid laddning av filinformation: ${error}',
			'messages.errorLoadingSeries' => 'Fel vid laddning av serie',
			'messages.musicNotSupported' => 'Musikuppspelning stöds inte ännu',
			'messages.noDescriptionAvailable' => 'Ingen beskrivning tillgänglig',
			'messages.noProfilesAvailable' => 'Inga profiler tillgängliga',
			'messages.contactAdminForProfiles' => 'Kontakta din serveradministratör för att lägga till profiler',
			'messages.unableToDetermineLibrarySection' => 'Kan inte avgöra biblioteksavdelningen för detta objekt',
			'messages.logsCleared' => 'Loggar rensade',
			'messages.logsCopied' => 'Loggar kopierade till urklipp',
			'messages.noLogsAvailable' => 'Inga loggar tillgängliga',
			'messages.libraryScanning' => ({required Object title}) => 'Skannar "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Biblioteksskanning startad för "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Misslyckades att skanna bibliotek: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Uppdaterar metadata för "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadata-uppdatering startad för "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Misslyckades att uppdatera metadata: ${error}',
			'messages.logoutConfirm' => 'Är du säker på att du vill logga ut?',
			'messages.noSeasonsFound' => 'Inga säsonger hittades',
			'messages.seasonsLoadFailed' => 'Det gick inte att läsa in säsonger',
			'messages.noEpisodesFound' => 'Inga avsnitt hittades i första säsongen',
			'messages.noEpisodesFoundGeneral' => 'Inga avsnitt hittades',
			'messages.episodesLoadFailed' => 'Det gick inte att läsa in avsnitt',
			'messages.noResultsFound' => 'Inga resultat hittades',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sovtimer inställd för ${label}',
			'messages.noItemsAvailable' => 'Inga objekt tillgängliga',
			'messages.failedToCreatePlayQueueNoItems' => 'Det gick inte att skapa uppspelningskö – inga objekt',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Byter till kompatibel spelare...',
			'messages.serverLimitTitle' => 'Uppspelningen misslyckades',
			'messages.serverLimitBody' => 'Serverfel (HTTP 500). En bandbredds-/transkodningsgräns avvisade troligen sessionen. Be ägaren justera den.',
			'messages.logsUploaded' => 'Loggar uppladdade',
			'messages.logsUploadFailed' => 'Uppladdning av loggar misslyckades',
			'messages.logId' => 'Logg-ID',
			'subtitlingStyling.text' => 'Text',
			'subtitlingStyling.border' => 'Kantlinje',
			'subtitlingStyling.background' => 'Bakgrund',
			'subtitlingStyling.fontSize' => 'Teckenstorlek',
			'subtitlingStyling.textColor' => 'Textfärg',
			'subtitlingStyling.borderSize' => 'Kantstorlek',
			'subtitlingStyling.borderColor' => 'Kantfärg',
			'subtitlingStyling.backgroundOpacity' => 'Bakgrundsopacitet',
			'subtitlingStyling.backgroundColor' => 'Bakgrundsfärg',
			'subtitlingStyling.position' => 'Position',
			'subtitlingStyling.assOverride' => 'ASS-åsidosättning',
			'subtitlingStyling.overrideScale' => 'Skala',
			'subtitlingStyling.overrideForce' => 'Tvinga',
			'subtitlingStyling.overrideStrip' => 'Ta bort formatering',
			'subtitlingStyling.positionTop' => 'Överst',
			'subtitlingStyling.positionBottom' => 'Nederst',
			'subtitlingStyling.bold' => 'Fet',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Renderingsupplösning',
			'subtitlingStyling.renderResolutionScreen' => 'Skärmupplösning',
			'subtitlingStyling.renderResolutionVideo' => 'Videoupplösning',
			'mpvConfig.title' => 'mpv-konfiguration',
			'mpvConfig.description' => 'Avancerade videospelares inställningar',
			'mpvConfig.presets' => 'Förval',
			'mpvConfig.noPresets' => 'Inga sparade förval',
			'mpvConfig.saveAsPreset' => 'Spara som förval...',
			'mpvConfig.presetName' => 'Förvalnamn',
			'mpvConfig.presetNameHint' => 'Ange ett namn för detta förval',
			'mpvConfig.loadPreset' => 'Ladda',
			'mpvConfig.deletePreset' => 'Ta bort',
			'mpvConfig.presetSaved' => 'Förval sparat',
			'mpvConfig.presetLoaded' => 'Förval laddat',
			'mpvConfig.presetDeleted' => 'Förval borttaget',
			'mpvConfig.confirmDeletePreset' => 'Är du säker på att du vill ta bort detta förval?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Bekräfta åtgärd',
			'profiles.addPlezyProfile' => 'Lägg till Plezy-profil',
			'profiles.switchingProfile' => 'Byter profil…',
			'profiles.deleteThisProfileTitle' => 'Ta bort denna profil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Ta bort ${displayName}. Anslutningar påverkas inte.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Hantera',
			'profiles.delete' => 'Ta bort',
			'profiles.signOut' => 'Logga ut',
			'profiles.signOutPlexTitle' => 'Logga ut från Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Ta bort ${displayName} och alla Plex Home-användare? Du kan logga in igen när som helst.',
			'profiles.signedOutPlex' => 'Utloggad från Plex.',
			'profiles.signOutFailed' => 'Utloggningen misslyckades.',
			'profiles.sectionTitle' => 'Profiler',
			'profiles.summarySingle' => 'Lägg till profiler för att blanda hanterade användare och lokala identiteter',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profiler',
			'profiles.removeConnectionTitle' => 'Ta bort anslutning?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Ta bort ${displayName}s åtkomst till ${connectionLabel}. Andra profiler behåller den.',
			'profiles.deleteProfileTitle' => 'Ta bort profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Ta bort ${displayName} och dess anslutningar. Servrar förblir tillgängliga.',
			'profiles.profileNameLabel' => 'Profilnamn',
			'profiles.pinProtectionLabel' => 'PIN-skydd',
			'profiles.pinManagedByPlex' => 'PIN hanteras av Plex. Redigera på plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Ingen PIN angiven. För att kräva en, redigera Home-användaren på plex.tv.',
			'profiles.setPin' => 'Ange PIN',
			'profiles.setPinTitle' => 'Ange PIN',
			'profiles.confirmPinTitle' => 'Bekräfta PIN',
			'profiles.pinSet' => 'PIN angiven',
			'profiles.changePin' => 'Ändra',
			'profiles.removePin' => 'Ta bort',
			'profiles.connectionsLabel' => 'Anslutningar',
			'profiles.add' => 'Lägg till',
			'profiles.deleteProfileButton' => 'Ta bort profil',
			'profiles.noConnectionsHint' => 'Inga anslutningar — lägg till en för att använda den här profilen.',
			'profiles.noConnections' => 'Inga anslutningar',
			'profiles.plexHomeAccount' => 'Plex Home-konto',
			'profiles.connectionDefault' => 'Standard',
			'profiles.connectionAs' => ({required Object displayName}) => 'som ${displayName}',
			'profiles.makeDefault' => 'Gör till standard',
			'profiles.removeConnection' => 'Ta bort',
			'profiles.profileRenamed' => 'Profilen har bytt namn.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Lägg till i ${displayName}',
			'profiles.borrowExplain' => 'Låna en annan profils anslutning. PIN-skyddade profiler kräver en PIN.',
			'profiles.borrowEmpty' => 'Inget att låna ännu.',
			'profiles.borrowEmptySubtitle' => 'Anslut Plex eller Jellyfin till en annan profil först.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Från ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Anslutning lånad.',
			'profiles.borrowFailed' => 'Kunde inte låna anslutningen.',
			'profiles.incorrectPin' => 'Fel PIN.',
			'profiles.incorrectPinTryAgain' => 'Fel PIN. Försök igen.',
			'profiles.sourceProfileMissingParentAccount' => 'Källprofilen saknar sitt överordnade konto.',
			'profiles.failedToLoadHomeUsers' => 'Kunde inte läsa in dina Plex Home-användare. Kontrollera anslutningen och försök igen.',
			'profiles.failedToVerifyPin' => 'Kunde inte verifiera PIN.',
			'profiles.newProfile' => 'Ny profil',
			'profiles.profileNameHint' => 't.ex. Gäster, Barn, Familjerum',
			'profiles.pinProtectionOptional' => 'PIN-skydd (valfritt)',
			'profiles.pinExplain' => '4-siffrig PIN krävs för att byta profiler.',
			'profiles.continueButton' => 'Fortsätt',
			'profiles.pinsDontMatch' => 'PIN-koderna stämmer inte överens',
			'connections.sectionTitle' => 'Anslutningar',
			'connections.addConnection' => 'Lägg till anslutning',
			'connections.addConnectionSubtitleNoProfile' => 'Logga in med Plex eller anslut en Jellyfin-server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Lägg till för ${displayName}: Plex, Jellyfin eller en annan profilanslutning',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessionen har gått ut för ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessionen har gått ut för ${count} servrar',
			'connections.signInAgain' => 'Logga in igen',
			'connections.editJellyfinTitle' => 'Redigera Jellyfin-anslutning',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Lägg till eller ta bort URL:er för ${serverName}. Plezy använder den nåbara URL:en med lägst latens.',
			'discover.title' => 'Upptäck',
			'discover.noContentAvailable' => 'Inget innehåll tillgängligt',
			'discover.addMediaToLibraries' => 'Lägg till media till dina bibliotek',
			'discover.continueWatching' => 'Fortsätt titta',
			'discover.continueWatchingIn' => ({required Object library}) => 'Fortsätt titta i ${library}',
			'discover.nextUp' => 'Nästa',
			'discover.nextUpIn' => ({required Object library}) => 'Nästa i ${library}',
			'discover.recentlyAdded' => 'Nyligen tillagda',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Nyligen tillagda i ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Senaste albumen i ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Nyligen spelade i ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Mest spelade i ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Översikt',
			'discover.cast' => 'Rollbesättning',
			'discover.extras' => 'Trailers och Extra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Åldersgräns',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min kvar',
			'discover.moreLikeThis' => 'Mer som detta',
			'errors.searchFailed' => ({required Object error}) => 'Sökning misslyckades: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Anslutnings-timeout vid laddning ${context}',
			'errors.connectionFailed' => 'Kan inte ansluta till mediaserver',
			'errors.unableToLoad' => ({required Object context}) => 'Det gick inte att läsa in ${context}. Försök igen.',
			'errors.noClientAvailable' => 'Ingen klient tillgänglig',
			'errors.pleaseEnterToken' => 'Vänligen ange en token',
			'errors.invalidToken' => 'Ogiltig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Misslyckades att verifiera token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Misslyckades att byta till ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Misslyckades att ta bort ${displayName}',
			'errors.failedToRate' => 'Det gick inte att uppdatera betyget',
			'libraries.title' => 'Bibliotek',
			'libraries.fallbackTitle' => 'Bibliotek',
			'libraries.scanLibraryFiles' => 'Skanna biblioteksfiler',
			'libraries.scanLibrary' => 'Skanna bibliotek',
			'libraries.analyze' => 'Analysera',
			'libraries.analyzeLibrary' => 'Analysera bibliotek',
			'libraries.refreshMetadata' => 'Uppdatera metadata',
			'libraries.emptyTrash' => 'Töm papperskorg',
			'libraries.emptyingTrash' => ({required Object title}) => 'Tömmer papperskorg för "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papperskorg tömd för "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Misslyckades att tömma papperskorg: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyserar "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analys startad för "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Misslyckades att analysera bibliotek: ${error}',
			'libraries.noLibrariesFound' => 'Inga bibliotek hittades',
			'libraries.allLibrariesHidden' => 'Alla bibliotek är dolda',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Dolda bibliotek (${count})',
			'libraries.thisLibraryIsEmpty' => 'Detta bibliotek är tomt',
			'libraries.noItemsMatchFilters' => 'Inga objekt matchar de aktiva filtren',
			'libraries.resetFilters' => 'Återställ filter',
			'libraries.all' => 'Alla',
			'libraries.clearAll' => 'Rensa alla',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Är du säker på att du vill skanna "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Är du säker på att du vill analysera "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Är du säker på att du vill uppdatera metadata för "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Är du säker på att du vill tömma papperskorgen för "${title}"?',
			'libraries.manageLibraries' => 'Hantera bibliotek',
			'libraries.sort' => 'Sortera',
			'libraries.sortBy' => 'Sortera efter',
			'libraries.filters' => 'Filter',
			'libraries.confirmActionMessage' => 'Är du säker på att du vill utföra denna åtgärd?',
			'libraries.showLibrary' => 'Visa bibliotek',
			'libraries.hideLibrary' => 'Dölj bibliotek',
			'libraries.libraryOptions' => 'Biblioteksalternativ',
			'libraries.content' => 'bibliotekets innehåll',
			'libraries.selectLibrary' => 'Välj bibliotek',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filter (${count})',
			'libraries.noRecommendations' => 'Inga rekommendationer tillgängliga',
			'libraries.noCollections' => 'Inga samlingar i det här biblioteket',
			'libraries.noFoldersFound' => 'Inga mappar hittades',
			'libraries.folders' => 'mappar',
			'libraries.tabs.recommended' => 'Rekommenderat',
			'libraries.tabs.browse' => 'Bläddra',
			'libraries.tabs.collections' => 'Samlingar',
			'libraries.tabs.playlists' => 'Spellistor',
			'libraries.groupings.title' => 'Gruppering',
			'libraries.groupings.all' => 'Alla',
			'libraries.groupings.movies' => 'Filmer',
			'libraries.groupings.shows' => 'Serier',
			'libraries.groupings.seasons' => 'Säsonger',
			'libraries.groupings.episodes' => 'Avsnitt',
			'libraries.groupings.artists' => 'Artister',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Låtar',
			'libraries.groupings.folders' => 'Mappar',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'År',
			'libraries.filterCategories.contentRating' => 'Åldersgräns',
			'libraries.filterCategories.tag' => 'Tagg',
			'libraries.filterCategories.unwatched' => 'Osedda',
			'libraries.filterCategories.unplayed' => 'Ospelat',
			'libraries.filterCategories.favorites' => 'Favoriter',
			'libraries.sortLabels.title' => 'Titel',
			'libraries.sortLabels.dateAdded' => 'Tillagd',
			'libraries.sortLabels.releaseDate' => 'Releasedatum',
			'libraries.sortLabels.rating' => 'Betyg',
			'libraries.sortLabels.communityRating' => 'Användarbetyg',
			'libraries.sortLabels.criticRating' => 'Kritikerbetyg',
			'libraries.sortLabels.userRating' => 'Användarbetyg',
			'libraries.sortLabels.datePlayed' => 'Speldatum',
			'libraries.sortLabels.playCount' => 'Antal spelningar',
			'libraries.sortLabels.productionYear' => 'Produktionsår',
			'libraries.sortLabels.runtime' => 'Speltid',
			'libraries.sortLabels.officialRating' => 'Officiell klassificering',
			'libraries.sortLabels.premiereDate' => 'Premiärdatum',
			'libraries.sortLabels.startDate' => 'Startdatum',
			'libraries.sortLabels.airTime' => 'Sändningstid',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Slumpmässigt',
			'libraries.sortLabels.dateShared' => 'Delningsdatum',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Senaste avsnittets sändningsdatum',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Datum då senaste avsnittet lades till',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Öppen källkod-licenser',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'En vacker Plex- och Jellyfin-klient för Flutter',
			'about.viewLicensesDescription' => 'Visa licenser för tredjepartsbibliotek',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Inga servrar hittades för ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Misslyckades att ladda servrar: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Utgivningsår',
			'hubDetail.dateAdded' => 'Datum tillagd',
			'hubDetail.rating' => 'Betyg',
			'hubDetail.noItemsFound' => 'Inga objekt hittades',
			'logs.clearLogs' => 'Rensa loggar',
			'logs.copyLogs' => 'Kopiera loggar',
			'logs.uploadLogs' => 'Ladda upp loggar',
			'licenses.relatedPackages' => 'Relaterade paket',
			'licenses.license' => 'Licens',
			'licenses.licenseNumber' => ({required Object number}) => 'Licens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenser',
			'navigation.libraries' => 'Bibliotek',
			'navigation.downloads' => 'Nerladdat',
			'navigation.liveTv' => 'Live-TV',
			'navigation.explore' => 'Utforska',
			'explore.title' => 'Utforska',
			'explore.selectSource' => 'Välj källa',
			'explore.rows.watchlist' => 'Bevakningslista',
			'explore.rows.recommendedMovies' => 'Rekommenderade filmer',
			'explore.rows.recommendedShows' => 'Rekommenderade serier',
			'explore.rows.trendingMovies' => 'Trendande filmer',
			'explore.rows.trendingShows' => 'Trendande serier',
			'explore.rows.popularMovies' => 'Populära filmer',
			'explore.rows.popularShows' => 'Populära serier',
			'explore.rows.suggestedAnime' => 'Föreslagna anime',
			'explore.rows.airingAnime' => 'Bästa pågående anime',
			'explore.rows.popularAnime' => 'Mest populära anime',
			'explore.rows.trending' => 'Trendar nu',
			'explore.rows.upcomingMovies' => 'Kommande filmer',
			'explore.rows.upcomingShows' => 'Kommande serier',
			'explore.status.airing' => 'Pågår',
			'explore.status.ended' => 'Avslutad',
			'explore.status.canceled' => 'Nedlagd',
			'explore.status.upcoming' => 'Kommande',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n, one: '${n} avsnitt', other: '${n} avsnitt', ), 
			'explore.cast' => 'Rollbesättning',
			'explore.characters' => 'Karaktärer',
			'explore.addToWatchlist' => 'Lägg till i bevakningslista',
			'explore.removeFromWatchlist' => 'Ta bort från bevakningslista',
			'explore.watchlistUpdateFailed' => 'Det gick inte att uppdatera bevakningslistan',
			'explore.notInLibrary' => 'Finns inte i ditt bibliotek',
			'explore.inTheseLibraries' => 'I dessa bibliotek',
			'explore.checkingLibrary' => 'Kontrollerar ditt bibliotek...',
			'explore.emptyTitle' => 'Inget här ännu',
			'explore.emptyMessage' => ({required Object source}) => 'Rader från ${source} visas här när de har innehåll.',
			'explore.searchHint' => ({required Object source}) => 'Sök i ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Inga resultat för "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Sök efter filmer och serier på ${source}.',
			'explore.searchFailed' => 'Sökningen misslyckades. Kontrollera din anslutning och försök igen.',
			'liveTv.title' => 'Live-TV',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Inga kanaler tillgängliga',
			'liveTv.noDvr' => 'Ingen DVR konfigurerad på någon server',
			'liveTv.serverUnavailable' => 'Live-tv-servern är inte tillgänglig.',
			'liveTv.serverNotConnected' => 'Live-tv-servern är inte ansluten.',
			'liveTv.noPrograms' => 'Ingen programdata tillgänglig',
			'liveTv.liveStreamFailed' => 'Liveström misslyckades',
			'liveTv.unknownProgram' => 'Okänt program',
			'liveTv.unknownHub' => 'Okänt',
			'liveTv.unknownError' => 'Okänt fel',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Okänd kanal',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Ladda om programguide',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'Idag',
			'liveTv.tomorrow' => 'I morgon',
			'liveTv.midnight' => 'Midnatt',
			'liveTv.overnight' => 'Natt',
			'liveTv.morning' => 'Morgon',
			'liveTv.daytime' => 'Dagtid',
			'liveTv.evening' => 'Kväll',
			'liveTv.lateNight' => 'Sen kväll',
			'liveTv.whatsOn' => 'På TV nu',
			'liveTv.watchChannel' => 'Titta på kanal',
			'liveTv.favorites' => 'Favoriter',
			'liveTv.reorderFavorites' => 'Ordna om favoriter',
			'liveTv.favoritesLoadFailed' => 'Det gick inte att läsa in favoriter. Kontrollera anslutningen och försök igen.',
			'liveTv.joinSession' => 'Gå med i pågående session',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Titta från början (${minutes} min sedan)',
			'liveTv.watchLive' => 'Titta live',
			'liveTv.goToLive' => 'Gå till live',
			'liveTv.record' => 'Spela in',
			'liveTv.recordEpisode' => 'Spela in avsnitt',
			'liveTv.recordSeries' => 'Spela in serie',
			'liveTv.recordOptions' => 'Inspelningsalternativ',
			'liveTv.saveTo' => 'Spara till',
			'liveTv.recordings' => 'Inspelningar',
			'liveTv.scheduledRecordings' => 'Schemalagda',
			'liveTv.recordingRules' => 'Inspelningsregler',
			'liveTv.noScheduledRecordings' => 'Inga schemalagda inspelningar',
			'liveTv.manageRecording' => 'Hantera inspelning',
			'liveTv.cancelRecording' => 'Avbryt inspelning',
			'liveTv.cancelRecordingTitle' => 'Avbryt denna inspelning?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} kommer inte längre att spelas in.',
			'liveTv.deleteRule' => 'Ta bort regel',
			'liveTv.deleteRuleTitle' => 'Ta bort inspelningsregel?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Kommande avsnitt av ${title} kommer inte att spelas in.',
			'liveTv.recordingScheduled' => 'Inspelning schemalagd',
			'liveTv.alreadyScheduled' => 'Detta program är redan schemalagt',
			'liveTv.dvrAdminRequired' => 'DVR-inställningar kräver ett administratörskonto',
			'liveTv.recordingFailed' => 'Det gick inte att schemalägga inspelning',
			'liveTv.recordingTargetMissing' => 'Det gick inte att hitta inspelningsbibliotek',
			'liveTv.recordNotAvailable' => 'Inspelning är inte tillgänglig för detta program',
			'liveTv.recordingCancelled' => 'Inspelning avbruten',
			'liveTv.recordingRuleDeleted' => 'Inspelningsregel borttagen',
			'liveTv.processRecordingRules' => 'Utvärdera regler igen',
			'liveTv.recordingInProgress' => 'Spelar in nu',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} schemalagda',
			'liveTv.editRule' => 'Redigera regel',
			'liveTv.editRuleAction' => 'Redigera',
			'liveTv.recordingRuleUpdated' => 'Inspelningsregel uppdaterad',
			'liveTv.guideReloadRequested' => 'Begärde guidens uppdatering',
			'liveTv.rulesProcessRequested' => 'Begärde regelutvärdering',
			'liveTv.recordShow' => 'Spela in program',
			'collections.title' => 'Samlingar',
			'collections.collection' => 'Samling',
			'collections.empty' => 'Samlingen är tom',
			'collections.deleteCollection' => 'Ta bort samling',
			'collections.deleteConfirm' => ({required Object title}) => 'Ta bort "${title}"? Detta kan inte ångras.',
			'collections.deleted' => 'Samling borttagen',
			'collections.deleteFailed' => 'Det gick inte att ta bort samlingen',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}',
			'collections.selectCollection' => 'Välj samling',
			'collections.collectionName' => 'Samlingsnamn',
			'collections.enterCollectionName' => 'Ange samlingsnamn',
			'collections.addedToCollection' => 'Tillagd i samling',
			'collections.errorAddingToCollection' => 'Fel vid tillägg i samling',
			'collections.created' => 'Samling skapad',
			'collections.removeFromCollection' => 'Ta bort från samling',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Ta bort "${title}" från denna samling?',
			'collections.removedFromCollection' => 'Borttagen från samling',
			'collections.removeFromCollectionFailed' => 'Misslyckades med att ta bort från samling',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fel vid borttagning från samling: ${error}',
			'collections.searchCollections' => 'Sök samlingar...',
			'playlists.title' => 'Spellistor',
			'playlists.playlist' => 'Spellista',
			'playlists.noPlaylists' => 'Inga spellistor hittades',
			'playlists.create' => 'Skapa spellista',
			'playlists.playlistName' => 'Spellistans namn',
			'playlists.enterPlaylistName' => 'Ange spellistans namn',
			'playlists.delete' => 'Ta bort spellista',
			'playlists.removeItem' => 'Ta bort från spellista',
			'playlists.smartPlaylist' => 'Smart spellista',
			'playlists.itemCount' => ({required Object count}) => '${count} objekt',
			'playlists.oneItem' => '1 objekt',
			'playlists.emptyPlaylist' => 'Denna spellista är tom',
			'playlists.deleteConfirm' => 'Ta bort spellista?',
			'playlists.deleteMessage' => ({required Object name}) => 'Är du säker på att du vill ta bort "${name}"?',
			'playlists.created' => 'Spellista skapad',
			'playlists.deleted' => 'Spellista borttagen',
			'playlists.itemAdded' => 'Tillagd i spellista',
			'playlists.itemRemoved' => 'Borttagen från spellista',
			'playlists.selectPlaylist' => 'Välj spellista',
			'playlists.searchPlaylists' => 'Sök i spellistor...',
			'playlists.errorCreating' => 'Det gick inte att skapa spellista',
			'playlists.errorDeleting' => 'Det gick inte att ta bort spellista',
			'playlists.errorLoading' => 'Det gick inte att ladda spellistor',
			'playlists.errorAdding' => 'Det gick inte att lägga till i spellista',
			'playlists.errorReordering' => 'Det gick inte att omordna spellisteobjekt',
			'playlists.errorRemoving' => 'Det gick inte att ta bort från spellista',
			'music.goToAlbum' => 'Gå till album',
			'music.goToArtist' => 'Gå till artist',
			'music.instantMix' => 'Snabbmix',
			'music.playNext' => 'Spela härnäst',
			'music.addToQueue' => 'Lägg till i kö',
			'music.discNumber' => ({required Object n}) => 'Skiva ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sv'))(n, one: '${n} låt', other: '${n} låtar', ), 
			'music.nowPlaying' => 'Spelas nu',
			'music.playingFrom' => ({required Object title}) => 'Spelar från ${title}',
			'music.queue' => 'Kö',
			'music.clearQueue' => 'Rensa kön',
			'music.lyrics' => 'Låttext',
			'music.noLyrics' => 'Ingen låttext tillgänglig',
			'music.sleepTimer' => 'Insomningstimer',
			'music.sleepTimerEndOfTrack' => 'Slutet av låten',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minuter',
			'music.stopPlayback' => 'Stoppa uppspelning',
			'music.previousTrack' => 'Föregående låt',
			'music.nextTrack' => 'Nästa låt',
			'music.repeat' => 'Upprepa',
			'music.repeatAll' => 'Upprepa alla',
			'music.repeatOne' => 'Upprepa en låt',
			'watchTogether.title' => 'Titta Tillsammans',
			'watchTogether.description' => 'Titta på innehåll synkroniserat med vänner och familj',
			'watchTogether.createSession' => 'Skapa Session',
			'watchTogether.creating' => 'Skapar...',
			'watchTogether.joinSession' => 'Gå med i Session',
			'watchTogether.joining' => 'Ansluter...',
			'watchTogether.controlMode' => 'Kontrollläge',
			'watchTogether.controlModeQuestion' => 'Vem kan styra uppspelningen?',
			'watchTogether.hostOnly' => 'Endast Värd',
			'watchTogether.anyone' => 'Alla',
			'watchTogether.hostingSession' => 'Värd för Session',
			'watchTogether.inSession' => 'I Session',
			'watchTogether.sessionCode' => 'Sessionskod',
			'watchTogether.openSessionControls' => 'Öppna sessionskontroller för Titta Tillsammans',
			'watchTogether.copySessionCode' => 'Kopiera sessionskod',
			'watchTogether.hostControlsPlayback' => 'Värden styr uppspelningen',
			'watchTogether.anyoneCanControl' => 'Alla kan styra uppspelningen',
			'watchTogether.hostControls' => 'Värd styr',
			'watchTogether.anyoneControls' => 'Alla styr',
			'watchTogether.participants' => 'Deltagare',
			'watchTogether.host' => 'Värd',
			'watchTogether.hostBadge' => 'VÄRD',
			'watchTogether.youAreHost' => 'Du är värden',
			'watchTogether.watchingWithOthers' => 'Tittar med andra',
			'watchTogether.endSession' => 'Avsluta Session',
			'watchTogether.leaveSession' => 'Lämna Session',
			'watchTogether.endSessionQuestion' => 'Avsluta Session?',
			'watchTogether.leaveSessionQuestion' => 'Lämna Session?',
			'watchTogether.endSessionConfirm' => 'Detta avslutar sessionen för alla deltagare.',
			'watchTogether.leaveSessionConfirm' => 'Du kommer att tas bort från sessionen.',
			'watchTogether.endSessionConfirmOverlay' => 'Detta avslutar tittarsessionen för alla deltagare.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Du kommer att kopplas bort från tittarsessionen.',
			'watchTogether.end' => 'Avsluta',
			'watchTogether.leave' => 'Lämna',
			'watchTogether.syncing' => 'Synkroniserar...',
			'watchTogether.joinWatchSession' => 'Gå med i Tittarsession',
			'watchTogether.enterCodeHint' => 'Ange 5-teckens kod',
			'watchTogether.pasteFromClipboard' => 'Klistra in från urklipp',
			'watchTogether.pleaseEnterCode' => 'Vänligen ange en sessionskod',
			'watchTogether.codeMustBe5Chars' => 'Sessionskod måste vara 5 tecken',
			'watchTogether.joinInstructions' => 'Ange värdens sessionskod för att gå med.',
			'watchTogether.failedToCreate' => 'Det gick inte att skapa session',
			'watchTogether.failedToJoin' => 'Det gick inte att gå med i session',
			'watchTogether.sessionCodeCopied' => 'Sessionskod kopierad till urklipp',
			'watchTogether.relayUnreachable' => 'Relay-servern kan inte nås. ISP-blockering kan hindra Watch Together.',
			'watchTogether.reconnectingToHost' => 'Återansluter till värd...',
			'watchTogether.currentPlayback' => 'Aktuell uppspelning',
			'watchTogether.joinCurrentPlayback' => 'Gå med i aktuell uppspelning',
			'watchTogether.joinCurrentPlaybackDescription' => 'Hoppa tillbaka till det värden tittar på just nu',
			'watchTogether.failedToOpenCurrentPlayback' => 'Kunde inte öppna aktuell uppspelning',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} gick med',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} lämnade',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausade',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} återupptog',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} spolade',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buffrar',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} använder en äldre appversion — synkronisering är inte tillgänglig',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Återupptar utan ${name}',
			'watchTogether.waitingForParticipants' => 'Väntar på att andra laddar...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Väntar på ${name}...',
			'watchTogether.recentRooms' => 'Senaste rum',
			'watchTogether.renameRoom' => 'Byt namn på rum',
			'watchTogether.removeRoom' => 'Ta bort',
			'watchTogether.guestSwitchUnavailable' => 'Kunde inte byta — server inte tillgänglig för synkronisering',
			'watchTogether.guestSwitchFailed' => 'Kunde inte byta — innehåll hittades inte på denna server',
			'downloads.title' => 'Nedladdningar',
			'downloads.manage' => 'Hantera',
			'downloads.tvShows' => 'TV-serier',
			'downloads.movies' => 'Filmer',
			_ => null,
		} ?? switch (path) {
			'downloads.music' => 'Musik',
			'downloads.tracksQueued' => ({required Object count}) => '${count} låtar i nedladdningskö',
			'downloads.noDownloads' => 'Inga nedladdningar ännu',
			'downloads.noDownloadsDescription' => 'Nedladdat innehåll visas här för offline-visning',
			'downloads.downloadNow' => 'Ladda ner',
			'downloads.deleteDownload' => 'Ta bort nedladdning',
			'downloads.retryDownload' => 'Försök igen',
			'downloads.downloadQueued' => 'Nedladdning köad',
			'downloads.downloadResumed' => 'Nedladdning återupptagen',
			'downloads.serverErrorBitrate' => 'Serverfel: filen kan överskrida gränsen för fjärrbitrate',
			'downloads.episodesQueued' => ({required Object count}) => '${count} avsnitt köade för nedladdning',
			'downloads.downloadDeleted' => 'Nedladdning borttagen',
			'downloads.deleteConfirm' => ({required Object title}) => 'Ta bort "${title}" från den här enheten?',
			'downloads.cancelledDownloadTitle' => 'Avbruten nedladdning',
			'downloads.cancelledDownloadMessage' => 'Den här nedladdningen avbröts. Vad vill du göra?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Alla avsnitt är redan nedladdade',
			'downloads.resumeDownload' => 'Återuppta nedladdning',
			'downloads.cancelledDownload' => 'Avbruten nedladdning',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (synkroniserar ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} nedladdad – klicka för att slutföra',
			'downloads.partialDownloadClickToComplete' => 'Delvis nedladdad – klicka för att slutföra',
			'downloads.deleting' => 'Tar bort...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})',
			'downloads.queuedTooltip' => 'I kö',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'I kö: ${files}',
			'downloads.downloadingTooltip' => 'Laddar ned...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Laddar ned ${files}',
			'downloads.noDownloadsTree' => 'Inga nedladdningar',
			'downloads.pauseAll' => 'Pausa alla',
			'downloads.resumeAll' => 'Återuppta alla',
			'downloads.deleteAll' => 'Ta bort alla',
			'downloads.selectVersion' => 'Välj version',
			'downloads.allEpisodes' => 'Alla avsnitt',
			'downloads.unwatchedOnly' => 'Endast osedda',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Nästa ${count} osedda',
			'downloads.customAmount' => 'Ange antal...',
			'downloads.includeSpecials' => 'Inkludera specialavsnitt',
			'downloads.howManyEpisodes' => 'Hur många avsnitt?',
			'downloads.invalidEpisodeCount' => 'Ange ett giltigt antal avsnitt.',
			'downloads.keepSynced' => 'Håll synkroniserad',
			'downloads.downloadOnce' => 'Ladda ner en gång',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Behåll ${count} osedda',
			'downloads.editSyncRule' => 'Redigera synkregel',
			'downloads.removeSyncRule' => 'Ta bort synkregel',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Sluta synkronisera "${title}"? Nedladdade avsnitt behålls.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synkregel skapad — behåller ${count} osedda avsnitt',
			'downloads.syncRuleUpdated' => 'Synkregel uppdaterad',
			'downloads.syncRuleRemoved' => 'Synkregel borttagen',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synkroniserade ${count} nya avsnitt för ${title}',
			'downloads.activeSyncRules' => 'Synkregler',
			'downloads.noSyncRules' => 'Inga synkregler',
			'downloads.manageSyncRule' => 'Hantera synkronisering',
			'downloads.editEpisodeCount' => 'Antal avsnitt',
			'downloads.editSyncFilter' => 'Synkroniseringsfilter',
			'downloads.syncAllItems' => 'Synkroniserar alla objekt',
			'downloads.syncUnwatchedItems' => 'Synkroniserar osedda objekt',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Tillgänglig',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Inloggning krävs',
			'downloads.syncRuleNotAvailableForProfile' => 'Inte tillgänglig för aktuell profil',
			'downloads.syncRuleUnknownServer' => 'Okänd server',
			'downloads.syncRuleListCreated' => 'Synkroniseringsregel skapad',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Ingen videoförbättring',
			'shaders.nvscalerDescription' => 'NVIDIA-bildskalning för skarpare video',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Brusreducering',
			'shaders.artcnnVariantDenoiseSharpen' => 'Brusreducering + skärpa',
			'shaders.qualityFast' => 'Snabb',
			'shaders.qualityHQ' => 'Hög kvalitet',
			'shaders.mode' => 'Läge',
			'shaders.importShader' => 'Importera shader',
			'shaders.customShaderDescription' => 'Anpassad GLSL-shader',
			'shaders.shaderImported' => 'Shader importerad',
			'shaders.shaderImportFailed' => 'Kunde inte importera shader',
			'shaders.deleteShader' => 'Ta bort shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Ta bort "${name}"?',
			'companionRemote.title' => 'Fjärrkontroll',
			'companionRemote.connectedTo' => ({required Object name}) => 'Ansluten till ${name}',
			'companionRemote.unknownDevice' => 'Okänd enhet',
			'companionRemote.session.startingServer' => 'Startar fjärrserver...',
			'companionRemote.session.hostAddress' => 'Värdadress',
			'companionRemote.session.connected' => 'Ansluten',
			'companionRemote.session.serverRunning' => 'Fjärrserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjärrserver stoppad',
			'companionRemote.session.serverRunningDescription' => 'Mobila enheter i ditt nätverk kan ansluta till den här appen',
			'companionRemote.session.serverStoppedDescription' => 'Starta servern för att tillåta mobila enheter att ansluta',
			'companionRemote.session.usePhoneToControl' => 'Använd din mobila enhet för att styra denna app',
			'companionRemote.session.startServer' => 'Starta server',
			'companionRemote.session.stopServer' => 'Stoppa server',
			'companionRemote.session.minimize' => 'Minimera',
			'companionRemote.pairing.discoveryDescription' => 'Plezy-enheter med samma Plex-konto visas här',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Ansluter...',
			'companionRemote.pairing.searchingForDevices' => 'Söker efter enheter...',
			'companionRemote.pairing.noDevicesFound' => 'Inga enheter hittades i ditt nätverk',
			'companionRemote.pairing.noDevicesHint' => 'Öppna Plezy på desktop och använd samma WiFi',
			'companionRemote.pairing.availableDevices' => 'Tillgängliga enheter',
			'companionRemote.pairing.manualConnection' => 'Manuell anslutning',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunde inte starta säker anslutning. Logga in på Plex först.',
			'companionRemote.pairing.validationHostRequired' => 'Ange värdadress',
			'companionRemote.pairing.validationHostFormat' => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Anslutningen tog för lång tid. Använd samma nätverk på båda enheter.',
			'companionRemote.pairing.sessionNotFound' => 'Enhet hittades inte. Kontrollera att Plezy körs på värden.',
			'companionRemote.pairing.authFailed' => 'Autentisering misslyckades. Båda enheter behöver samma Plex-konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunde inte ansluta: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vill du koppla från fjärrsessionen?',
			'companionRemote.remote.reconnecting' => 'Återansluter...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Försök ${current} av 5',
			'companionRemote.remote.retryNow' => 'Försök nu',
			'companionRemote.remote.tabRemote' => 'Fjärrkontroll',
			'companionRemote.remote.tabPlay' => 'Spela',
			'companionRemote.remote.tabMore' => 'Mer',
			'companionRemote.remote.menu' => 'Meny',
			'companionRemote.remote.tabNavigation' => 'Fliknavigering',
			'companionRemote.remote.tabDiscover' => 'Upptäck',
			'companionRemote.remote.tabLibraries' => 'Bibliotek',
			'companionRemote.remote.tabSearch' => 'Sök',
			'companionRemote.remote.tabDownloads' => 'Nedladdningar',
			'companionRemote.remote.tabSettings' => 'Inställningar',
			'companionRemote.remote.previous' => 'Föregående',
			'companionRemote.remote.playPause' => 'Spela/Pausa',
			'companionRemote.remote.next' => 'Nästa',
			'companionRemote.remote.seekBack' => 'Spola bakåt',
			'companionRemote.remote.stop' => 'Stopp',
			'companionRemote.remote.seekForward' => 'Spola framåt',
			'companionRemote.remote.volume' => 'Volym',
			'companionRemote.remote.volumeDown' => 'Ner',
			'companionRemote.remote.volumeUp' => 'Upp',
			'companionRemote.remote.fullscreen' => 'Helskärm',
			'companionRemote.remote.subtitles' => 'Undertexter',
			'companionRemote.remote.audio' => 'Ljud',
			'companionRemote.remote.searchHint' => 'Sök på datorn...',
			'companionRemote.errors.noNetworkInterface' => 'Inget nätverksgränssnitt hittades',
			'companionRemote.errors.authenticationFailed' => 'Autentisering misslyckades',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Det gick inte att starta fjärrservern: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Det gick inte att skicka fjärrkommandot: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tidsgräns vid anslutning till session',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Kunde inte ansluta till någon adress',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Anslutning förlorad efter ${attempts} försök',
			'companionRemote.errors.connectionLost' => 'Anslutning förlorad',
			'videoSettings.playbackSpeed' => 'Uppspelningshastighet',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktiv (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Sovtimer',
			'videoSettings.audioSync' => 'Ljudsynkronisering',
			'videoSettings.subtitleSync' => 'Undertextsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Ljudutgång',
			'videoSettings.performanceOverlay' => 'Prestandaöverlägg',
			'videoSettings.audioPassthrough' => 'Ljudgenomkoppling',
			'videoSettings.audioNormalization' => 'Normalisera ljudstyrka',
			'videoSettings.audioDownmix' => 'Nedmixning till stereo',
			'performanceOverlay.color' => 'Färg',
			'performanceOverlay.performance' => 'Prestanda',
			'performanceOverlay.buffer' => 'Buffert',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Rå dekoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.aspect' => 'Bildformat',
			'performanceOverlay.rotation' => 'Rotation',
			'performanceOverlay.dvSource' => 'DV-källa',
			'performanceOverlay.dvPath' => 'DV-sökväg',
			'performanceOverlay.p7Conversion' => 'P7-konv.',
			'performanceOverlay.sampleRate' => 'Samplingsfrekvens',
			'performanceOverlay.pixelFormat' => 'Pixelformat',
			'performanceOverlay.hwFormat' => 'HW-format',
			'performanceOverlay.matrix' => 'Matris',
			'performanceOverlay.primaries' => 'Primärfärger',
			'performanceOverlay.transfer' => 'Transfer',
			'performanceOverlay.renderFps' => 'Render-FPS',
			'performanceOverlay.displayFps' => 'Skärm-FPS',
			'performanceOverlay.avSync' => 'A/V-synk',
			'performanceOverlay.dropped' => 'Tappade',
			'performanceOverlay.dvRpus' => 'DV RPU:er',
			'performanceOverlay.dvRpuAverage' => 'DV RPU snitt',
			'performanceOverlay.dvSampleAverage' => 'DV-sample snitt',
			'performanceOverlay.maxLuma' => 'Max luma',
			'performanceOverlay.minLuma' => 'Min luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache använd',
			'performanceOverlay.cacheLimit' => 'Cachegräns',
			'performanceOverlay.speed' => 'Hastighet',
			'performanceOverlay.player' => 'Spelare',
			'performanceOverlay.memory' => 'Minne',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => 'Extern spelare',
			'externalPlayer.useExternalPlayer' => 'Använd extern spelare',
			'externalPlayer.useExternalPlayerDescription' => 'Öppna videor i en annan app',
			'externalPlayer.selectPlayer' => 'Välj spelare',
			'externalPlayer.customPlayers' => 'Anpassade spelare',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Lägg till anpassad spelare',
			'externalPlayer.playerName' => 'Spelarnamn',
			'externalPlayer.playerNameHint' => 'Min spelare',
			'externalPlayer.playerCommand' => 'Kommando',
			'externalPlayer.playerPackage' => 'Paketnamn',
			'externalPlayer.playerUrlScheme' => 'URL-schema',
			'externalPlayer.off' => 'Av',
			'externalPlayer.launchFailed' => 'Kunde inte öppna extern spelare',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} är inte installerad',
			'externalPlayer.playInExternalPlayer' => 'Spela i extern spelare',
			'metadataEdit.editMetadata' => 'Redigera...',
			'metadataEdit.screenTitle' => 'Redigera metadata',
			'metadataEdit.basicInfo' => 'Grundläggande info',
			'metadataEdit.artwork' => 'Artwork',
			'metadataEdit.advancedSettings' => 'Avancerade inställningar',
			'metadataEdit.title' => 'Titel',
			'metadataEdit.sortTitle' => 'Sorteringstitel',
			'metadataEdit.originalTitle' => 'Originaltitel',
			'metadataEdit.releaseDate' => 'Utgivningsdatum',
			'metadataEdit.contentRating' => 'Åldersgräns',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Sammanfattning',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Bakgrund',
			'metadataEdit.logo' => 'Logotyp',
			'metadataEdit.squareArt' => 'Kvadratisk bild',
			'metadataEdit.selectPoster' => 'Välj poster',
			'metadataEdit.selectBackground' => 'Välj bakgrund',
			'metadataEdit.selectLogo' => 'Välj logotyp',
			'metadataEdit.selectSquareArt' => 'Välj kvadratisk bild',
			'metadataEdit.fromUrl' => 'Från URL',
			'metadataEdit.uploadFile' => 'Ladda upp fil',
			'metadataEdit.enterImageUrl' => 'Ange bild-URL',
			'metadataEdit.imageUrl' => 'Bild-URL',
			'metadataEdit.metadataUpdated' => 'Metadata uppdaterad',
			'metadataEdit.metadataUpdateFailed' => 'Kunde inte uppdatera metadata',
			'metadataEdit.artworkUpdated' => 'Artwork uppdaterad',
			'metadataEdit.artworkUpdateFailed' => 'Kunde inte uppdatera artwork',
			'metadataEdit.noArtworkAvailable' => 'Ingen artwork tillgänglig',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Bildalternativ ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Bildalternativ ${index}, valt',
			'metadataEdit.notSet' => 'Inte angiven',
			'metadataEdit.libraryDefault' => 'Biblioteksstandard',
			'metadataEdit.accountDefault' => 'Kontostandard',
			'metadataEdit.seriesDefault' => 'Seriestandard',
			'metadataEdit.episodeSorting' => 'Avsnittsortering',
			'metadataEdit.oldestFirst' => 'Äldst först',
			'metadataEdit.newestFirst' => 'Nyast först',
			'metadataEdit.keep' => 'Behåll',
			'metadataEdit.allEpisodes' => 'Alla avsnitt',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} senaste avsnitten',
			'metadataEdit.latestEpisode' => 'Senaste avsnittet',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Avsnitt tillagda de senaste ${count} dagarna',
			'metadataEdit.deleteAfterPlaying' => 'Ta bort avsnitt efter uppspelning',
			'metadataEdit.never' => 'Aldrig',
			'metadataEdit.afterADay' => 'Efter en dag',
			'metadataEdit.afterAWeek' => 'Efter en vecka',
			'metadataEdit.afterAMonth' => 'Efter en månad',
			'metadataEdit.onNextRefresh' => 'Vid nästa uppdatering',
			'metadataEdit.seasons' => 'Säsonger',
			'metadataEdit.show' => 'Visa',
			'metadataEdit.hide' => 'Dölj',
			'metadataEdit.episodeOrdering' => 'Avsnittsordning',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Sändning)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Sändning)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolut)',
			'metadataEdit.metadataLanguage' => 'Metadataspråk',
			'metadataEdit.useOriginalTitle' => 'Använd originaltitel',
			'metadataEdit.preferredAudioLanguage' => 'Föredraget ljudspråk',
			'metadataEdit.preferredSubtitleLanguage' => 'Föredraget undertextspråk',
			'metadataEdit.subtitleMode' => 'Automatiskt val av undertexter',
			'metadataEdit.manuallySelected' => 'Manuellt vald',
			'metadataEdit.shownWithForeignAudio' => 'Visas vid främmande ljud',
			'metadataEdit.alwaysEnabled' => 'Alltid aktiverad',
			'metadataEdit.tags' => 'Taggar',
			'metadataEdit.addTag' => 'Lägg till tagg',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Regissör',
			'metadataEdit.writer' => 'Författare',
			'metadataEdit.producer' => 'Producent',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Samling',
			'metadataEdit.label' => 'Etikett',
			'metadataEdit.style' => 'Stil',
			'metadataEdit.mood' => 'Stämning',
			'matchScreen.match' => 'Matcha...',
			'matchScreen.fixMatch' => 'Rätta matchning...',
			'matchScreen.unmatch' => 'Ta bort matchning',
			'matchScreen.unmatchConfirm' => 'Rensa denna matchning? Plex behandlar den som omatchad tills den matchas igen.',
			'matchScreen.unmatchSuccess' => 'Matchning borttagen',
			'matchScreen.unmatchFailed' => 'Det gick inte att ta bort matchningen',
			'matchScreen.matchApplied' => 'Matchning tillämpad',
			'matchScreen.matchFailed' => 'Det gick inte att tillämpa matchningen',
			'matchScreen.titleHint' => 'Titel',
			'matchScreen.yearHint' => 'År',
			'matchScreen.search' => 'Sök',
			'matchScreen.noMatchesFound' => 'Inga matchningar hittades',
			'serverTasks.title' => 'Serveruppgifter',
			'serverTasks.failedToLoad' => 'Kunde inte ladda uppgifter',
			'serverTasks.noTasks' => 'Inga pågående uppgifter',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Ansluten',
			'trakt.connectedAs' => ({required Object username}) => 'Ansluten som @${username}',
			'trakt.disconnectConfirm' => 'Koppla från Trakt-konto?',
			'trakt.disconnectConfirmBody' => 'Plezy slutar skicka händelser till Trakt. Du kan återansluta när som helst.',
			'trakt.scrobble' => 'Realtids-scrobbling',
			'trakt.scrobbleDescription' => 'Skicka uppspelnings-, paus- och stopphändelser till Trakt under uppspelning.',
			'trakt.watchedSync' => 'Synkronisera tittad-status',
			'trakt.watchedSyncDescription' => 'När du markerar något som tittat i Plezy markeras det också på Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Anslut Seerr',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Adressen till din Seerr-instans',
			'seerr.checkServer' => 'Fortsätt',
			'seerr.signInWithJellyfin' => 'Logga in med Jellyfin',
			'seerr.signInWithEmby' => 'Logga in med Emby',
			'seerr.signInWithLocal' => 'Använd ett lokalt konto',
			'seerr.email' => 'E-post',
			'seerr.noSignInMethods' => 'Den här Seerr-instansen erbjuder ingen inloggningsmetod som Plezy stöder.',
			'seerr.instance' => 'Instans',
			'seerr.disconnectConfirm' => 'Koppla från Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy glömmer den här Seerr-instansen. Återanslut när som helst.',
			'seerr.request' => 'Begär',
			'seerr.request4k' => 'Begär i 4K',
			'seerr.seasons' => 'Säsonger',
			'seerr.allSeasons' => 'Alla säsonger',
			'seerr.advancedOptions' => 'Avancerat',
			'seerr.destinationServer' => 'Målserver',
			'seerr.qualityProfile' => 'Kvalitetsprofil',
			'seerr.rootFolder' => 'Rotmapp',
			'seerr.languageProfile' => 'Språkprofil',
			'seerr.requestSubmitted' => 'Begäran skickad',
			'seerr.requestFailed' => ({required Object error}) => 'Begäran misslyckades: ${error}',
			'seerr.requestsLoadFailed' => 'Det gick inte att läsa in alternativ för begäran',
			'seerr.nothingToRequest' => 'Allt är redan tillgängligt eller begärt.',
			'seerr.statusAvailable' => 'Tillgänglig',
			'seerr.statusPartiallyAvailable' => 'Delvis tillgänglig',
			'seerr.statusRequested' => 'Begärd',
			'seerr.statusProcessing' => 'Bearbetas',
			'services.title' => 'Tjänster',
			'services.hubSubtitle' => 'Synkronisera dina framsteg och begär nya titlar.',
			'services.notConnected' => 'Ej ansluten',
			'services.connectedAs' => ({required Object username}) => 'Ansluten som @${username}',
			'services.scrobble' => 'Spåra framsteg automatiskt',
			'services.scrobbleDescription' => 'Uppdaterar din lista när du är klar med ett avsnitt eller en film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Koppla från ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy slutar uppdatera ${service}. Återanslut när som helst.',
			'services.connectFailed' => ({required Object service}) => 'Kunde inte ansluta till ${service}. Försök igen.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Aktivera Plezy på ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Besök ${url} och ange den här koden:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Öppna ${service} för att aktivera',
			'services.deviceCode.copyCode' => 'Kopiera aktiveringskod',
			'services.deviceCode.waitingForAuthorization' => 'Väntar på auktorisering…',
			'services.deviceCode.codeCopied' => 'Kod kopierad',
			'services.oauthProxy.title' => ({required Object service}) => 'Logga in på ${service}',
			'services.oauthProxy.body' => 'Skanna den här QR-koden eller öppna URL:en på valfri enhet.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Öppna ${service} för att logga in',
			'services.oauthProxy.copyUrl' => 'Kopiera inloggnings-URL',
			'services.oauthProxy.urlCopied' => 'URL kopierad',
			'services.libraryFilter.title' => 'Biblioteksfilter',
			'services.libraryFilter.subtitleAllSyncing' => 'Synkroniserar alla bibliotek',
			'services.libraryFilter.subtitleNoneSyncing' => 'Ingenting synkroniseras',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blockerade',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} tillåtna',
			'services.libraryFilter.mode' => 'Filterläge',
			'services.libraryFilter.modeBlacklist' => 'Svartlista',
			'services.libraryFilter.modeWhitelist' => 'Vitlista',
			'services.libraryFilter.modeHintBlacklist' => 'Synkronisera alla bibliotek utom de som markerats nedan.',
			'services.libraryFilter.modeHintWhitelist' => 'Synkronisera endast de bibliotek som markerats nedan.',
			'services.libraryFilter.libraries' => 'Bibliotek',
			'services.libraryFilter.noLibraries' => 'Inga bibliotek tillgängliga',
			'addServer.addJellyfinTitle' => 'Lägg till Jellyfin-server',
			'addServer.serverUrls' => 'Server-URL:er',
			'addServer.serverUrlsHelper' => 'Flera URL:er tillåtna, separerade med kommatecken.',
			'addServer.findServer' => 'Hitta server',
			'addServer.searchingLocalServers' => 'Söker efter lokala Jellyfin-servrar...',
			'addServer.localServers' => 'Lokala Jellyfin-servrar',
			'addServer.username' => 'Användarnamn',
			'addServer.password' => 'Lösenord',
			'addServer.signIn' => 'Logga in',
			'addServer.change' => 'Ändra',
			'addServer.required' => 'Krävs',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Kunde inte nå servern: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Inloggning misslyckades: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect misslyckades: ${error}',
			'addServer.addPlexTitle' => 'Logga in med Plex',
			'addServer.pinExpired' => 'PIN-koden gick ut innan inloggning. Försök igen.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Kunde inte registrera kontot: ${error}',
			'addServer.enterJellyfinUrlError' => 'Ange URL till din Jellyfin-server',
			'addServer.addConnectionTitle' => 'Lägg till anslutning',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Lägg till i ${name}',
			'addServer.signInWithPlexCard' => 'Logga in med Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Auktorisera den här enheten. Delade servrar läggs till.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Auktorisera ett Plex-konto. Home-användare blir profiler.',
			'addServer.connectToJellyfinCard' => 'Anslut till Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Ange server-URL, användarnamn och lösenord.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Logga in på en Jellyfin-server. Kopplas till ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Låna från en annan profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Återanvänd en annan profils anslutning. PIN-skyddade profiler kräver en PIN.',
			_ => null,
		};
	}
}
