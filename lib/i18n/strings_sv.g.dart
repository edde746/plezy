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
class TranslationsSv with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsSv({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.sv,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sv>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsAccessibilitySv accessibility = _TranslationsAccessibilitySv._(_root);
	@override late final _TranslationsTooltipsSv tooltips = _TranslationsTooltipsSv._(_root);
	@override late final _TranslationsVideoControlsSv videoControls = _TranslationsVideoControlsSv._(_root);
	@override late final _TranslationsUserStatusSv userStatus = _TranslationsUserStatusSv._(_root);
	@override late final _TranslationsMessagesSv messages = _TranslationsMessagesSv._(_root);
	@override late final _TranslationsSubtitlingStylingSv subtitlingStyling = _TranslationsSubtitlingStylingSv._(_root);
	@override late final _TranslationsMpvConfigSv mpvConfig = _TranslationsMpvConfigSv._(_root);
	@override late final _TranslationsDialogSv dialog = _TranslationsDialogSv._(_root);
	@override late final _TranslationsDiscoverSv discover = _TranslationsDiscoverSv._(_root);
	@override late final _TranslationsErrorsSv errors = _TranslationsErrorsSv._(_root);
	@override late final _TranslationsLibrariesSv libraries = _TranslationsLibrariesSv._(_root);
	@override late final _TranslationsAboutSv about = _TranslationsAboutSv._(_root);
	@override late final _TranslationsServerSelectionSv serverSelection = _TranslationsServerSelectionSv._(_root);
	@override late final _TranslationsHubDetailSv hubDetail = _TranslationsHubDetailSv._(_root);
	@override late final _TranslationsLogsSv logs = _TranslationsLogsSv._(_root);
	@override late final _TranslationsLicensesSv licenses = _TranslationsLicensesSv._(_root);
	@override late final _TranslationsNavigationSv navigation = _TranslationsNavigationSv._(_root);
	@override late final _TranslationsLiveTvSv liveTv = _TranslationsLiveTvSv._(_root);
	@override late final _TranslationsCollectionsSv collections = _TranslationsCollectionsSv._(_root);
	@override late final _TranslationsPlaylistsSv playlists = _TranslationsPlaylistsSv._(_root);
	@override late final _TranslationsWatchTogetherSv watchTogether = _TranslationsWatchTogetherSv._(_root);
	@override late final _TranslationsDownloadsSv downloads = _TranslationsDownloadsSv._(_root);
	@override late final _TranslationsShadersSv shaders = _TranslationsShadersSv._(_root);
	@override late final _TranslationsCompanionRemoteSv companionRemote = _TranslationsCompanionRemoteSv._(_root);
	@override late final _TranslationsVideoSettingsSv videoSettings = _TranslationsVideoSettingsSv._(_root);
	@override late final _TranslationsExternalPlayerSv externalPlayer = _TranslationsExternalPlayerSv._(_root);
	@override late final _TranslationsMetadataEditSv metadataEdit = _TranslationsMetadataEditSv._(_root);
	@override late final _TranslationsMatchScreenSv matchScreen = _TranslationsMatchScreenSv._(_root);
	@override late final _TranslationsServerTasksSv serverTasks = _TranslationsServerTasksSv._(_root);
	@override late final _TranslationsTraktSv trakt = _TranslationsTraktSv._(_root);
	@override late final _TranslationsTrackersSv trackers = _TranslationsTrackersSv._(_root);
}

// Path: app
class _TranslationsAppSv implements TranslationsAppEn {
	_TranslationsAppSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthSv implements TranslationsAuthEn {
	_TranslationsAuthSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logga in med Plex';
	@override String get showQRCode => 'Visa QR-kod';
	@override String get authenticate => 'Autentisera';
	@override String get authenticationTimeout => 'Autentisering tog för lång tid. Försök igen.';
	@override String get scanQRToSignIn => 'Skanna QR-koden för att logga in';
	@override String get waitingForAuth => 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.';
	@override String get useBrowser => 'Använd webbläsare';
}

// Path: common
class _TranslationsCommonSv implements TranslationsCommonEn {
	_TranslationsCommonSv._(this._root);

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
	@override String get reconnect => 'Återanslut';
	@override String get exitConfirmTitle => 'Avsluta appen?';
	@override String get exitConfirmMessage => 'Är du säker på att du vill avsluta?';
	@override String get dontAskAgain => 'Fråga inte igen';
	@override String get exit => 'Avsluta';
	@override String get viewAll => 'Visa alla';
	@override String get checkingNetwork => 'Kontrollerar nätverk...';
	@override String get refreshingServers => 'Uppdaterar servrar...';
	@override String get loadingServers => 'Laddar servrar...';
	@override String get connectingToServers => 'Ansluter till servrar...';
	@override String get startingOfflineMode => 'Startar offlineläge...';
	@override String get loading => 'Laddar...';
	@override String get fullscreen => 'Helskärm';
	@override String get exitFullscreen => 'Avsluta helskärm';
}

// Path: screens
class _TranslationsScreensSv implements TranslationsScreensEn {
	_TranslationsScreensSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get switchProfile => 'Byt profil';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Loggar';
}

// Path: update
class _TranslationsUpdateSv implements TranslationsUpdateEn {
	_TranslationsUpdateSv._(this._root);

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
class _TranslationsSettingsSv implements TranslationsSettingsEn {
	_TranslationsSettingsSv._(this._root);

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
	@override String get useGlobalHubs => 'Använd Plex hem-layout';
	@override String get useGlobalHubsDescription => 'Visar startsidans hubbar som den officiella Plex-klienten. När av visas rekommendationer per bibliotek istället.';
	@override String get showServerNameOnHubs => 'Visa servernamn på hubbar';
	@override String get showServerNameOnHubsDescription => 'Visa alltid servernamnet i hubbtitlar. När av visas endast för duplicerade hubbnamn.';
	@override String get groupLibrariesByServer => 'Gruppera bibliotek efter server';
	@override String get groupLibrariesByServerDescription => 'Visa en rubrik för varje Plex-server i sidofältet när du är ansluten till flera servrar.';
	@override String get alwaysKeepSidebarOpen => 'Håll sidofältet alltid öppet';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidofältet förblir expanderat och innehållsytan anpassas';
	@override String get showUnwatchedCount => 'Visa antal osedda';
	@override String get showUnwatchedCountDescription => 'Visa antal osedda avsnitt för serier och säsonger';
	@override String get showEpisodeNumberOnCards => 'Visa avsnittsnummer på kort';
	@override String get showEpisodeNumberOnCardsDescription => 'Visa avsnittsnummer tillsammans med säsongen (t.ex. S2 E3) på avsnittskort';
	@override String get hideSpoilers => 'Dölj spoilers för osedda avsnitt';
	@override String get hideSpoilersDescription => 'Gör miniatyrer suddiga och dölj beskrivningar för avsnitt du inte har sett ännu';
	@override String get playerBackend => 'Spelarmotor';
	@override String get exoPlayer => 'ExoPlayer (Rekommenderad)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hårdvaruavkodning';
	@override String get hardwareDecodingDescription => 'Använd hårdvaruacceleration när tillgängligt';
	@override String get bufferSize => 'Bufferstorlek';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Rekommenderat)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Din enhet har ${heap}MB minne. En buffert på ${size}MB kan orsaka uppspelningsproblem.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get defaultQualityDescription => 'Används vid start av uppspelning. Lägre värden minskar bandbredden.';
	@override String get subtitleStyling => 'Undertext-styling';
	@override String get subtitleStylingDescription => 'Anpassa undertextutseende';
	@override String get smallSkipDuration => 'Kort hoppvaraktighet';
	@override String get largeSkipDuration => 'Lång hoppvaraktighet';
	@override String get rewindOnResume => 'Spola tillbaka vid återupptagning';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard sovtimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minuter';
	@override String get rememberTrackSelections => 'Kom ihåg spårval per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Spara automatiskt ljud- och undertextspråkpreferenser när du ändrar spår under uppspelning';
	@override String get clickVideoTogglesPlayback => 'Klicka på videon för att växla mellan spela upp och pausa.';
	@override String get clickVideoTogglesPlaybackDescription => 'Om detta är aktiverat kommer ett klick på videospelaren att starta eller pausa videon. Annars visas eller döljs uppspelningskontrollerna när du klickar.';
	@override String get videoPlayerControls => 'Videospelar-kontroller';
	@override String get keyboardShortcuts => 'Tangentbordsgenvägar';
	@override String get keyboardShortcutsDescription => 'Anpassa tangentbordsgenvägar';
	@override String get videoPlayerNavigation => 'Navigering i videospelaren';
	@override String get videoPlayerNavigationDescription => 'Använd piltangenter för att navigera videospelarens kontroller';
	@override String get watchTogetherRelay => 'Titta Tillsammans-relay';
	@override String get watchTogetherRelayDescription => 'Ange en anpassad relay-server för Titta Tillsammans. Alla deltagare måste använda samma server.';
	@override String get watchTogetherRelayHint => 'https://min-relay.exempel.se';
	@override String get crashReporting => 'Kraschrapportering';
	@override String get crashReportingDescription => 'Skicka kraschrapporter för att förbättra appen';
	@override String get debugLogging => 'Felsökningsloggning';
	@override String get debugLoggingDescription => 'Aktivera detaljerad loggning för felsökning';
	@override String get viewLogs => 'Visa loggar';
	@override String get viewLogsDescription => 'Visa applikationsloggar';
	@override String get clearCache => 'Rensa cache';
	@override String get clearCacheDescription => 'Detta rensar alla cachade bilder och data. Appen kan ta längre tid att ladda innehåll efter cache-rensning.';
	@override String get clearCacheSuccess => 'Cache rensad framgångsrikt';
	@override String get resetSettings => 'Återställ inställningar';
	@override String get resetSettingsDescription => 'Detta återställer alla inställningar till standardvärden. Denna åtgärd kan inte ångras.';
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
	@override String get autoCheckUpdatesOnStartupDescription => 'Visa en avisering när en ny version är tillgänglig vid start';
	@override String get validationErrorEnterNumber => 'Vänligen ange ett giltigt nummer';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Genväg redan tilldelad ${action}';
	@override String shortcutUpdated({required Object action}) => 'Genväg uppdaterad för ${action}';
	@override String get autoSkip => 'Auto Hoppa Över';
	@override String get autoSkipIntro => 'Hoppa Över Intro Automatiskt';
	@override String get autoSkipIntroDescription => 'Hoppa automatiskt över intro-markörer efter några sekunder';
	@override String get autoSkipCredits => 'Hoppa Över Credits Automatiskt';
	@override String get autoSkipCreditsDescription => 'Hoppa automatiskt över credits och spela nästa avsnitt';
	@override String get autoSkipDelay => 'Fördröjning Auto Hoppa Över';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning';
	@override String get introPattern => 'Intromarkörsmönster';
	@override String get introPatternDescription => 'Reguljärt uttryck för att matcha intromarkörer i kapiteltitlar';
	@override String get creditsPattern => 'Eftertextmarkörsmönster';
	@override String get creditsPatternDescription => 'Reguljärt uttryck för att matcha eftertextmarkörer i kapiteltitlar';
	@override String get invalidRegex => 'Ogiltigt reguljärt uttryck';
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
	@override String get autoRemoveWatchedDownloadsDescription => 'Ta automatiskt bort nedladdade avsnitt och filmer när de markerats som sedda';
	@override String get cellularDownloadBlocked => 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.';
	@override String get maxVolume => 'Maximal volym';
	@override String get maxVolumeDescription => 'Tillåt volym över 100% för tyst media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Visa vad du tittar på i Discord';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Synkronisera visningshistorik med Trakt';
	@override String get trackers => 'Spårare';
	@override String get trackersDescription => 'Synkronisera framsteg till Trakt, MyAnimeList, AniList och Simkl';
	@override String get companionRemoteServer => 'Companion Remote-server';
	@override String get companionRemoteServerDescription => 'Tillåt mobila enheter i ditt nätverk att styra denna app';
	@override String get autoPip => 'Automatisk bild-i-bild';
	@override String get autoPipDescription => 'Aktivera bild-i-bild automatiskt när appen lämnas under uppspelning';
	@override String get matchContentFrameRate => 'Matcha innehållets bildfrekvens';
	@override String get matchContentFrameRateDescription => 'Justera skärmens uppdateringsfrekvens för att matcha videoinnehållet, minskar hackighet och sparar batteri';
	@override String get matchRefreshRate => 'Matcha uppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Byt skärmens uppdateringsfrekvens för att matcha videoinnehåll i helskärm';
	@override String get matchDynamicRange => 'Matcha dynamiskt omfång';
	@override String get matchDynamicRangeDescription => 'Aktivera HDR automatiskt för HDR-innehåll och återgå till SDR när spelaren stängs';
	@override String get displaySwitchDelay => 'Fördröjning vid skärmbyte';
	@override String get tunneledPlayback => 'Tunneluppspelning';
	@override String get tunneledPlaybackDescription => 'Använd hårdvaruaccelererad videotunnling. Inaktivera om du ser en svart skärm med ljud vid HDR-innehåll';
	@override String get requireProfileSelectionOnOpen => 'Fråga efter profil vid appstart';
	@override String get requireProfileSelectionOnOpenDescription => 'Visa profilval varje gång appen öppnas';
	@override String get confirmExitOnBack => 'Bekräfta innan avslut';
	@override String get confirmExitOnBackDescription => 'Visa en bekräftelsedialog när du trycker tillbaka för att avsluta appen';
	@override String get forceTvMode => 'Tvinga TV-läge';
	@override String get forceTvModeDescription => 'Använd TV-layouten oavsett automatisk identifiering. Användbart på Android TV-enheter som inte rapporterar leanback-funktionen. Startar om appen vid ändring.';
	@override String get startInFullscreen => 'Starta i helskärm';
	@override String get startInFullscreenDescription => 'Öppna Plezy i helskärm vid start';
	@override String get autoHidePerformanceOverlay => 'Dölj prestandaöverlagring automatiskt';
	@override String get autoHidePerformanceOverlayDescription => 'Tona prestandaöverlagringen med uppspelningskontrollerna';
	@override String get showNavBarLabels => 'Visa navigeringsfältets etiketter';
	@override String get showNavBarLabelsDescription => 'Visa textetiketter under navigeringsfältets ikoner';
	@override String get liveTvDefaultFavorites => 'Standard till favoritkanaler';
	@override String get liveTvDefaultFavoritesDescription => 'Visa bara favoritkanaler när du öppnar Live TV';
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
class _TranslationsSearchSv implements TranslationsSearchEn {
	_TranslationsSearchSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Sök filmer, serier, musik...';
	@override String get tryDifferentTerm => 'Prova en annan sökterm';
	@override String get searchYourMedia => 'Sök i dina media';
	@override String get enterTitleActorOrKeyword => 'Ange en titel, skådespelare eller nyckelord';
}

// Path: hotkeys
class _TranslationsHotkeysSv implements TranslationsHotkeysEn {
	_TranslationsHotkeysSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Sätt genväg för ${actionName}';
	@override String get clearShortcut => 'Rensa genväg';
	@override late final _TranslationsHotkeysActionsSv actions = _TranslationsHotkeysActionsSv._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoSv implements TranslationsFileInfoEn {
	_TranslationsFileInfoSv._(this._root);

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
class _TranslationsMediaMenuSv implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
	@override String get removeFromContinueWatching => 'Ta bort från Fortsätt titta';
	@override String get goToSeries => 'Gå till serie';
	@override String get goToSeason => 'Gå till säsong';
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get fileInfo => 'Filinformation';
	@override String get deleteFromServer => 'Ta bort från servern';
	@override String get confirmDelete => 'Detta kommer permanent ta bort detta media och dess filer från din server. Detta kan inte ångras.';
	@override String get deleteMultipleWarning => 'Detta inkluderar alla avsnitt och deras filer.';
	@override String get mediaDeletedSuccessfully => 'Mediaobjekt borttaget';
	@override String get mediaFailedToDelete => 'Kunde inte ta bort mediaobjekt';
	@override String get rate => 'Betygsätt';
	@override String get playFromBeginning => 'Spela från början';
	@override String get playVersion => 'Spela version...';
}

// Path: accessibility
class _TranslationsAccessibilitySv implements TranslationsAccessibilityEn {
	_TranslationsAccessibilitySv._(this._root);

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
}

// Path: tooltips
class _TranslationsTooltipsSv implements TranslationsTooltipsEn {
	_TranslationsTooltipsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Blanda uppspelning';
	@override String get playTrailer => 'Spela trailer';
	@override String get markAsWatched => 'Markera som sedd';
	@override String get markAsUnwatched => 'Markera som osedd';
}

// Path: videoControls
class _TranslationsVideoControlsSv implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsSv._(this._root);

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
	@override String get settingsButton => 'Videoinställningar';
	@override String get tracksButton => 'Ljud och undertexter';
	@override String get chaptersButton => 'Kapitel';
	@override String get versionsButton => 'Videoversioner';
	@override String get versionQualityButton => 'Version och kvalitet';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Kvalitet';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
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
	@override late final _TranslationsVideoControlsPipErrorsSv pipErrors = _TranslationsVideoControlsPipErrorsSv._(_root);
	@override String get chapters => 'Kapitel';
	@override String get noChaptersAvailable => 'Inga kapitel tillgängliga';
	@override String get queue => 'Kö';
	@override String get noQueueItems => 'Inga objekt i kön';
	@override String get searchSubtitles => 'Sök undertexter';
	@override String get language => 'Språk';
	@override String get noSubtitlesFound => 'Inga undertexter hittades';
	@override String get subtitleDownloaded => 'Undertext nedladdad';
	@override String get subtitleDownloadFailed => 'Kunde inte ladda ner undertext';
	@override String get searchLanguages => 'Sök språk...';
}

// Path: userStatus
class _TranslationsUserStatusSv implements TranslationsUserStatusEn {
	_TranslationsUserStatusSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Begränsad';
	@override String get protected => 'Skyddad';
	@override String get current => 'NUVARANDE';
}

// Path: messages
class _TranslationsMessagesSv implements TranslationsMessagesEn {
	_TranslationsMessagesSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Markerad som sedd';
	@override String get markedAsUnwatched => 'Markerad som osedd';
	@override String get markedAsWatchedOffline => 'Markerad som sedd (synkroniseras när online)';
	@override String get markedAsUnwatchedOffline => 'Markerad som osedd (synkroniseras när online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatiskt borttagen: ${title}';
	@override String get removedFromContinueWatching => 'Borttagen från Fortsätt titta';
	@override String errorLoading({required Object error}) => 'Fel: ${error}';
	@override String get fileInfoNotAvailable => 'Filinformation inte tillgänglig';
	@override String errorLoadingFileInfo({required Object error}) => 'Fel vid laddning av filinformation: ${error}';
	@override String get errorLoadingSeries => 'Fel vid laddning av serie';
	@override String get errorLoadingSeason => 'Fel vid laddning av säsong';
	@override String get musicNotSupported => 'Musikuppspelning stöds inte ännu';
	@override String get noDescriptionAvailable => 'Ingen beskrivning tillgänglig';
	@override String get noProfilesAvailable => 'Inga profiler tillgängliga';
	@override String get contactAdminForProfiles => 'Kontakta din Plex-administratör för att lägga till profiler';
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
	@override String get noEpisodesFound => 'Inga avsnitt hittades i första säsongen';
	@override String get noEpisodesFoundGeneral => 'Inga avsnitt hittades';
	@override String get noResultsFound => 'Inga resultat hittades';
	@override String sleepTimerSet({required Object label}) => 'Sovtimer inställd för ${label}';
	@override String get noItemsAvailable => 'Inga objekt tillgängliga';
	@override String get failedToCreatePlayQueueNoItems => 'Det gick inte att skapa uppspelningskö – inga objekt';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Byter till kompatibel spelare...';
	@override String get serverLimitTitle => 'Uppspelningen misslyckades';
	@override String get serverLimitBody => 'Servern returnerade ett fel (HTTP 500). Det betyder oftast att serverägaren har satt en gräns för bandbredd eller transkodning som avvisar din session. Det finns inget du kan göra från klienten — serverägaren behöver justera sina inställningar.';
	@override String get logsUploaded => 'Loggar uppladdade';
	@override String get logsUploadFailed => 'Uppladdning av loggar misslyckades';
	@override String get logId => 'Logg-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingSv implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingSv._(this._root);

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
	@override String get bold => 'Fet';
	@override String get italic => 'Kursiv';
}

// Path: mpvConfig
class _TranslationsMpvConfigSv implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigSv._(this._root);

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
class _TranslationsDialogSv implements TranslationsDialogEn {
	_TranslationsDialogSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekräfta åtgärd';
}

// Path: discover
class _TranslationsDiscoverSv implements TranslationsDiscoverEn {
	_TranslationsDiscoverSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Upptäck';
	@override String get switchProfile => 'Byt profil';
	@override String get noContentAvailable => 'Inget innehåll tillgängligt';
	@override String get addMediaToLibraries => 'Lägg till media till dina bibliotek';
	@override String get continueWatching => 'Fortsätt titta';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Översikt';
	@override String get cast => 'Rollbesättning';
	@override String get extras => 'Trailers och Extra';
	@override String get studio => 'Studio';
	@override String get rating => 'Åldersgräns';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min kvar';
}

// Path: errors
class _TranslationsErrorsSv implements TranslationsErrorsEn {
	_TranslationsErrorsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Sökning misslyckades: ${error}';
	@override String connectionTimeout({required Object context}) => 'Anslutnings-timeout vid laddning ${context}';
	@override String get connectionFailed => 'Kan inte ansluta till Plex-server';
	@override String failedToLoad({required Object context, required Object error}) => 'Misslyckades att ladda ${context}: ${error}';
	@override String get noClientAvailable => 'Ingen klient tillgänglig';
	@override String authenticationFailed({required Object error}) => 'Autentisering misslyckades: ${error}';
	@override String get couldNotLaunchUrl => 'Kunde inte öppna autentiserings-URL';
	@override String get pleaseEnterToken => 'Vänligen ange en token';
	@override String get invalidToken => 'Ogiltig token';
	@override String failedToVerifyToken({required Object error}) => 'Misslyckades att verifiera token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Misslyckades att byta till ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesSv implements TranslationsLibrariesEn {
	_TranslationsLibrariesSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotek';
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
}

// Path: about
class _TranslationsAboutSv implements TranslationsAboutEn {
	_TranslationsAboutSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Öppen källkod-licenser';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'En vacker Plex-klient för Flutter';
	@override String get viewLicensesDescription => 'Visa licenser för tredjepartsbibliotek';
}

// Path: serverSelection
class _TranslationsServerSelectionSv implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Inga servrar hittades för ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Misslyckades att ladda servrar: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailSv implements TranslationsHubDetailEn {
	_TranslationsHubDetailSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Utgivningsår';
	@override String get dateAdded => 'Datum tillagd';
	@override String get rating => 'Betyg';
	@override String get noItemsFound => 'Inga objekt hittades';
}

// Path: logs
class _TranslationsLogsSv implements TranslationsLogsEn {
	_TranslationsLogsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Rensa loggar';
	@override String get copyLogs => 'Kopiera loggar';
	@override String get uploadLogs => 'Ladda upp loggar';
}

// Path: licenses
class _TranslationsLicensesSv implements TranslationsLicensesEn {
	_TranslationsLicensesSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterade paket';
	@override String get license => 'Licens';
	@override String licenseNumber({required Object number}) => 'Licens ${number}';
	@override String licensesCount({required Object count}) => '${count} licenser';
}

// Path: navigation
class _TranslationsNavigationSv implements TranslationsNavigationEn {
	_TranslationsNavigationSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotek';
	@override String get downloads => 'Nerladdat';
	@override String get liveTv => 'Live-TV';
}

// Path: liveTv
class _TranslationsLiveTvSv implements TranslationsLiveTvEn {
	_TranslationsLiveTvSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-TV';
	@override String get guide => 'Programguide';
	@override String get noChannels => 'Inga kanaler tillgängliga';
	@override String get noDvr => 'Ingen DVR konfigurerad på någon server';
	@override String get noPrograms => 'Ingen programdata tillgänglig';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'Ladda om programguide';
	@override String get now => 'Nu';
	@override String get today => 'Idag';
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
	@override String get joinSession => 'Gå med i pågående session';
	@override String watchFromStart({required Object minutes}) => 'Titta från början (${minutes} min sedan)';
	@override String get watchLive => 'Titta live';
	@override String get goToLive => 'Gå till live';
}

// Path: collections
class _TranslationsCollectionsSv implements TranslationsCollectionsEn {
	_TranslationsCollectionsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlingar';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen är tom';
	@override String get unknownLibrarySection => 'Kan inte ta bort: okänd bibliotekssektion';
	@override String get deleteCollection => 'Ta bort samling';
	@override String deleteConfirm({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Detta går inte att ångra.';
	@override String get deleted => 'Samling borttagen';
	@override String get deleteFailed => 'Det gick inte att ta bort samlingen';
	@override String deleteFailedWithError({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Det gick inte att läsa in samlingsobjekt: ${error}';
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
class _TranslationsPlaylistsSv implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsSv._(this._root);

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
	@override String get errorCreating => 'Det gick inte att skapa spellista';
	@override String get errorDeleting => 'Det gick inte att ta bort spellista';
	@override String get errorLoading => 'Det gick inte att ladda spellistor';
	@override String get errorAdding => 'Det gick inte att lägga till i spellista';
	@override String get errorReordering => 'Det gick inte att omordna spellisteobjekt';
	@override String get errorRemoving => 'Det gick inte att ta bort från spellista';
}

// Path: watchTogether
class _TranslationsWatchTogetherSv implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherSv._(this._root);

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
	@override String get joinInstructions => 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.';
	@override String get failedToCreate => 'Det gick inte att skapa session';
	@override String get failedToJoin => 'Det gick inte att gå med i session';
	@override String get sessionCodeCopied => 'Sessionskod kopierad till urklipp';
	@override String get relayUnreachable => 'Reläservern kan inte nås. Detta kan bero på att din internetleverantör blockerar anslutningen. Du kan fortfarande försöka, men Watch Together kanske inte fungerar.';
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
	@override String get waitingForParticipants => 'Väntar på att andra laddar...';
	@override String get recentRooms => 'Senaste rum';
	@override String get renameRoom => 'Byt namn på rum';
	@override String get removeRoom => 'Ta bort';
}

// Path: downloads
class _TranslationsDownloadsSv implements TranslationsDownloadsEn {
	_TranslationsDownloadsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nedladdningar';
	@override String get manage => 'Hantera';
	@override String get tvShows => 'TV-serier';
	@override String get movies => 'Filmer';
	@override String get noDownloads => 'Inga nedladdningar ännu';
	@override String get noDownloadsDescription => 'Nedladdat innehåll visas här för offline-visning';
	@override String get downloadNow => 'Ladda ner';
	@override String get deleteDownload => 'Ta bort nedladdning';
	@override String get retryDownload => 'Försök igen';
	@override String get downloadQueued => 'Nedladdning köad';
	@override String get serverErrorBitrate => 'Serverfel — filen överskrider möjligen gränsen för fjärrströmning-bitrate';
	@override String episodesQueued({required Object count}) => '${count} avsnitt köade för nedladdning';
	@override String get downloadDeleted => 'Nedladdning borttagen';
	@override String deleteConfirm({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Den nedladdade filen kommer att tas bort från din enhet.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})';
	@override String get deleting => 'Tar bort...';
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
	@override String get howManyEpisodes => 'Hur många avsnitt?';
	@override String itemsQueued({required Object count}) => '${count} objekt köade för nedladdning';
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
	@override String get syncRuleListCreated => 'Synkroniseringsregel skapad';
}

// Path: shaders
class _TranslationsShadersSv implements TranslationsShadersEn {
	_TranslationsShadersSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Ingen videoförbättring';
	@override String get nvscalerDescription => 'NVIDIA-bildskalning för skarpare video';
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
class _TranslationsCompanionRemoteSv implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fjärrkontroll';
	@override String connectedTo({required Object name}) => 'Ansluten till ${name}';
	@override late final _TranslationsCompanionRemoteSessionSv session = _TranslationsCompanionRemoteSessionSv._(_root);
	@override late final _TranslationsCompanionRemotePairingSv pairing = _TranslationsCompanionRemotePairingSv._(_root);
	@override late final _TranslationsCompanionRemoteRemoteSv remote = _TranslationsCompanionRemoteRemoteSv._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsSv implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Uppspelningsinställningar';
	@override String get playbackSpeed => 'Uppspelningshastighet';
	@override String get sleepTimer => 'Sovtimer';
	@override String get audioSync => 'Ljudsynkronisering';
	@override String get subtitleSync => 'Undertextsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Ljudutgång';
	@override String get performanceOverlay => 'Prestandaöverlägg';
	@override String get audioPassthrough => 'Ljudgenomkoppling';
	@override String get audioNormalization => 'Normalisera ljudstyrka';
}

// Path: externalPlayer
class _TranslationsExternalPlayerSv implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Extern spelare';
	@override String get useExternalPlayer => 'Använd extern spelare';
	@override String get useExternalPlayerDescription => 'Öppna videor i en extern app istället för den inbyggda spelaren';
	@override String get selectPlayer => 'Välj spelare';
	@override String get customPlayers => 'Anpassade spelare';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Lägg till anpassad spelare';
	@override String get playerName => 'Spelarnamn';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Paketnamn';
	@override String get playerUrlScheme => 'URL-schema';
	@override String get off => 'Av';
	@override String get launchFailed => 'Kunde inte öppna extern spelare';
	@override String appNotInstalled({required Object name}) => '${name} är inte installerad';
	@override String get playInExternalPlayer => 'Spela i extern spelare';
}

// Path: metadataEdit
class _TranslationsMetadataEditSv implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditSv._(this._root);

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
class _TranslationsMatchScreenSv implements TranslationsMatchScreenEn {
	_TranslationsMatchScreenSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get match => 'Matcha...';
	@override String get fixMatch => 'Rätta matchning...';
	@override String get unmatch => 'Ta bort matchning';
	@override String get unmatchConfirm => 'Ta bort den aktuella matchningen för det här objektet? Plex behandlar det som omatchat tills du matchar det igen.';
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
class _TranslationsServerTasksSv implements TranslationsServerTasksEn {
	_TranslationsServerTasksSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveruppgifter';
	@override String get failedToLoad => 'Kunde inte ladda uppgifter';
	@override String get noTasks => 'Inga pågående uppgifter';
}

// Path: trakt
class _TranslationsTraktSv implements TranslationsTraktEn {
	_TranslationsTraktSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Ansluten';
	@override String connectedAs({required Object username}) => 'Ansluten som @${username}';
	@override String get disconnectConfirm => 'Koppla från Trakt-konto?';
	@override String get disconnectConfirmBody => 'Plezy slutar skicka uppspelningshändelser till Trakt. Du kan ansluta igen när som helst.';
	@override String get scrobble => 'Realtids-scrobbling';
	@override String get scrobbleDescription => 'Skicka uppspelnings-, paus- och stopphändelser till Trakt under uppspelning.';
	@override String get watchedSync => 'Synkronisera tittad-status';
	@override String get watchedSyncDescription => 'När du markerar något som tittat i Plezy markeras det också på Trakt.';
}

// Path: trackers
class _TranslationsTrackersSv implements TranslationsTrackersEn {
	_TranslationsTrackersSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spårare';
	@override String get hubSubtitle => 'Håll ditt tittarprogress synkroniserat med Trakt och andra tjänster.';
	@override String get notConnected => 'Ej ansluten';
	@override String connectedAs({required Object username}) => 'Ansluten som @${username}';
	@override String get scrobble => 'Spåra framsteg automatiskt';
	@override String get scrobbleDescription => 'Uppdaterar din lista när du är klar med ett avsnitt eller en film.';
	@override String disconnectConfirm({required Object service}) => 'Koppla från ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy slutar uppdatera din ${service}-lista. Du kan ansluta igen när som helst.';
	@override String connectFailed({required Object service}) => 'Kunde inte ansluta till ${service}. Försök igen.';
	@override late final _TranslationsTrackersServicesSv services = _TranslationsTrackersServicesSv._(_root);
	@override late final _TranslationsTrackersDeviceCodeSv deviceCode = _TranslationsTrackersDeviceCodeSv._(_root);
	@override late final _TranslationsTrackersOauthProxySv oauthProxy = _TranslationsTrackersOauthProxySv._(_root);
	@override late final _TranslationsTrackersLibraryFilterSv libraryFilter = _TranslationsTrackersLibraryFilterSv._(_root);
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsSv implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsSv._(this._root);

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
	@override String get subSeekNext => 'Hoppa till nästa undertext';
	@override String get subSeekPrev => 'Hoppa till föregående undertext';
	@override String get shaderToggle => 'Växla shaders';
	@override String get skipMarker => 'Hoppa över intro/eftertexter';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsSv implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Kräver Android 8.0 eller nyare';
	@override String get iosVersion => 'Kräver iOS 15.0 eller nyare';
	@override String get permissionDisabled => 'Bild-i-bild-behörighet är inaktiverad. Aktivera den i Inställningar > Appar > Plezy > Bild-i-bild';
	@override String get notSupported => 'Denna enhet stöder inte bild-i-bild-läge';
	@override String get voSwitchFailed => 'Kunde inte byta videoutgång för bild-i-bild';
	@override String get failed => 'Bild-i-bild kunde inte starta';
	@override String unknown({required Object error}) => 'Ett fel uppstod: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsSv implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Rekommenderat';
	@override String get browse => 'Bläddra';
	@override String get collections => 'Samlingar';
	@override String get playlists => 'Spellistor';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsSv implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppering';
	@override String get all => 'Alla';
	@override String get movies => 'Filmer';
	@override String get shows => 'Serier';
	@override String get seasons => 'Säsonger';
	@override String get episodes => 'Avsnitt';
	@override String get folders => 'Mappar';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionSv implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Startar fjärrserver...';
	@override String get failedToCreate => 'Kunde inte starta fjärrserver:';
	@override String get hostAddress => 'Värdadress';
	@override String get connected => 'Ansluten';
	@override String get serverRunning => 'Fjärrserver aktiv';
	@override String get serverStopped => 'Fjärrserver stoppad';
	@override String get serverRunningDescription => 'Mobila enheter i ditt nätverk kan upptäcka och ansluta till denna app';
	@override String get serverStoppedDescription => 'Starta servern för att tillåta mobila enheter att ansluta';
	@override String get usePhoneToControl => 'Använd din mobila enhet för att styra denna app';
	@override String get startServer => 'Starta server';
	@override String get stopServer => 'Stoppa server';
	@override String get minimize => 'Minimera';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingSv implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Enheter i ditt nätverk som kör Plezy med samma Plex-konto visas automatiskt';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Ansluter...';
	@override String get searchingForDevices => 'Söker efter enheter...';
	@override String get noDevicesFound => 'Inga enheter hittades i ditt nätverk';
	@override String get noDevicesHint => 'Se till att Plezy är öppet på din dator och att båda enheterna är på samma WiFi-nätverk';
	@override String get availableDevices => 'Tillgängliga enheter';
	@override String get manualConnection => 'Manuell anslutning';
	@override String get cryptoInitFailed => 'Kunde inte initiera säker anslutning. Se till att du är inloggad på ett Plex-konto.';
	@override String get validationHostRequired => 'Ange värdadress';
	@override String get validationHostFormat => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Anslutningen tog för lång tid. Se till att båda enheterna är på samma nätverk.';
	@override String get sessionNotFound => 'Kunde inte hitta enheten. Se till att Plezy körs på värden.';
	@override String get authFailed => 'Autentisering misslyckades. Se till att båda enheterna använder samma Plex-konto.';
	@override String failedToConnect({required Object error}) => 'Kunde inte ansluta: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteSv implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteSv._(this._root);

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

// Path: trackers.services
class _TranslationsTrackersServicesSv implements TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeSv implements TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeSv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktivera Plezy på ${service}';
	@override String body({required Object url}) => 'Besök ${url} och ange den här koden:';
	@override String openToActivate({required Object service}) => 'Öppna ${service} för att aktivera';
	@override String get waitingForAuthorization => 'Väntar på auktorisering…';
	@override String get codeCopied => 'Kod kopierad';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxySv implements TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxySv._(this._root);

	final TranslationsSv _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Logga in på ${service}';
	@override String get body => 'Skanna den här QR-koden med din telefon, eller öppna URL:en nedan på en enhet med webbläsare.';
	@override String openToSignIn({required Object service}) => 'Öppna ${service} för att logga in';
	@override String get urlCopied => 'URL kopierad';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterSv implements TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterSv._(this._root);

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
			'auth.waitingForAuth' => 'Väntar på autentisering...\nVänligen slutför inloggning i din webbläsare.',
			'auth.useBrowser' => 'Använd webbläsare',
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
			'common.reconnect' => 'Återanslut',
			'common.exitConfirmTitle' => 'Avsluta appen?',
			'common.exitConfirmMessage' => 'Är du säker på att du vill avsluta?',
			'common.dontAskAgain' => 'Fråga inte igen',
			'common.exit' => 'Avsluta',
			'common.viewAll' => 'Visa alla',
			'common.checkingNetwork' => 'Kontrollerar nätverk...',
			'common.refreshingServers' => 'Uppdaterar servrar...',
			'common.loadingServers' => 'Laddar servrar...',
			'common.connectingToServers' => 'Ansluter till servrar...',
			'common.startingOfflineMode' => 'Startar offlineläge...',
			'common.loading' => 'Laddar...',
			'common.fullscreen' => 'Helskärm',
			'common.exitFullscreen' => 'Avsluta helskärm',
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
			'settings.useGlobalHubs' => 'Använd Plex hem-layout',
			'settings.useGlobalHubsDescription' => 'Visar startsidans hubbar som den officiella Plex-klienten. När av visas rekommendationer per bibliotek istället.',
			'settings.showServerNameOnHubs' => 'Visa servernamn på hubbar',
			'settings.showServerNameOnHubsDescription' => 'Visa alltid servernamnet i hubbtitlar. När av visas endast för duplicerade hubbnamn.',
			'settings.groupLibrariesByServer' => 'Gruppera bibliotek efter server',
			'settings.groupLibrariesByServerDescription' => 'Visa en rubrik för varje Plex-server i sidofältet när du är ansluten till flera servrar.',
			'settings.alwaysKeepSidebarOpen' => 'Håll sidofältet alltid öppet',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidofältet förblir expanderat och innehållsytan anpassas',
			'settings.showUnwatchedCount' => 'Visa antal osedda',
			'settings.showUnwatchedCountDescription' => 'Visa antal osedda avsnitt för serier och säsonger',
			'settings.showEpisodeNumberOnCards' => 'Visa avsnittsnummer på kort',
			'settings.showEpisodeNumberOnCardsDescription' => 'Visa avsnittsnummer tillsammans med säsongen (t.ex. S2 E3) på avsnittskort',
			'settings.hideSpoilers' => 'Dölj spoilers för osedda avsnitt',
			'settings.hideSpoilersDescription' => 'Gör miniatyrer suddiga och dölj beskrivningar för avsnitt du inte har sett ännu',
			'settings.playerBackend' => 'Spelarmotor',
			'settings.exoPlayer' => 'ExoPlayer (Rekommenderad)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hårdvaruavkodning',
			'settings.hardwareDecodingDescription' => 'Använd hårdvaruacceleration när tillgängligt',
			'settings.bufferSize' => 'Bufferstorlek',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Rekommenderat)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Din enhet har ${heap}MB minne. En buffert på ${size}MB kan orsaka uppspelningsproblem.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.defaultQualityDescription' => 'Används vid start av uppspelning. Lägre värden minskar bandbredden.',
			'settings.subtitleStyling' => 'Undertext-styling',
			'settings.subtitleStylingDescription' => 'Anpassa undertextutseende',
			'settings.smallSkipDuration' => 'Kort hoppvaraktighet',
			'settings.largeSkipDuration' => 'Lång hoppvaraktighet',
			'settings.rewindOnResume' => 'Spola tillbaka vid återupptagning',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard sovtimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minuter',
			'settings.rememberTrackSelections' => 'Kom ihåg spårval per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Spara automatiskt ljud- och undertextspråkpreferenser när du ändrar spår under uppspelning',
			'settings.clickVideoTogglesPlayback' => 'Klicka på videon för att växla mellan spela upp och pausa.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Om detta är aktiverat kommer ett klick på videospelaren att starta eller pausa videon. Annars visas eller döljs uppspelningskontrollerna när du klickar.',
			'settings.videoPlayerControls' => 'Videospelar-kontroller',
			'settings.keyboardShortcuts' => 'Tangentbordsgenvägar',
			'settings.keyboardShortcutsDescription' => 'Anpassa tangentbordsgenvägar',
			'settings.videoPlayerNavigation' => 'Navigering i videospelaren',
			'settings.videoPlayerNavigationDescription' => 'Använd piltangenter för att navigera videospelarens kontroller',
			'settings.watchTogetherRelay' => 'Titta Tillsammans-relay',
			'settings.watchTogetherRelayDescription' => 'Ange en anpassad relay-server för Titta Tillsammans. Alla deltagare måste använda samma server.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.exempel.se',
			'settings.crashReporting' => 'Kraschrapportering',
			'settings.crashReportingDescription' => 'Skicka kraschrapporter för att förbättra appen',
			'settings.debugLogging' => 'Felsökningsloggning',
			'settings.debugLoggingDescription' => 'Aktivera detaljerad loggning för felsökning',
			'settings.viewLogs' => 'Visa loggar',
			'settings.viewLogsDescription' => 'Visa applikationsloggar',
			'settings.clearCache' => 'Rensa cache',
			'settings.clearCacheDescription' => 'Detta rensar alla cachade bilder och data. Appen kan ta längre tid att ladda innehåll efter cache-rensning.',
			'settings.clearCacheSuccess' => 'Cache rensad framgångsrikt',
			'settings.resetSettings' => 'Återställ inställningar',
			'settings.resetSettingsDescription' => 'Detta återställer alla inställningar till standardvärden. Denna åtgärd kan inte ångras.',
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
			'settings.autoCheckUpdatesOnStartupDescription' => 'Visa en avisering när en ny version är tillgänglig vid start',
			'settings.validationErrorEnterNumber' => 'Vänligen ange ett giltigt nummer',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Tiden måste vara mellan ${min} och ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Genväg redan tilldelad ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Genväg uppdaterad för ${action}',
			'settings.autoSkip' => 'Auto Hoppa Över',
			'settings.autoSkipIntro' => 'Hoppa Över Intro Automatiskt',
			'settings.autoSkipIntroDescription' => 'Hoppa automatiskt över intro-markörer efter några sekunder',
			'settings.autoSkipCredits' => 'Hoppa Över Credits Automatiskt',
			'settings.autoSkipCreditsDescription' => 'Hoppa automatiskt över credits och spela nästa avsnitt',
			'settings.autoSkipDelay' => 'Fördröjning Auto Hoppa Över',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vänta ${seconds} sekunder innan automatisk överhoppning',
			'settings.introPattern' => 'Intromarkörsmönster',
			'settings.introPatternDescription' => 'Reguljärt uttryck för att matcha intromarkörer i kapiteltitlar',
			'settings.creditsPattern' => 'Eftertextmarkörsmönster',
			'settings.creditsPatternDescription' => 'Reguljärt uttryck för att matcha eftertextmarkörer i kapiteltitlar',
			'settings.invalidRegex' => 'Ogiltigt reguljärt uttryck',
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
			'settings.autoRemoveWatchedDownloadsDescription' => 'Ta automatiskt bort nedladdade avsnitt och filmer när de markerats som sedda',
			'settings.cellularDownloadBlocked' => 'Nedladdningar är inaktiverade på mobildata. Anslut till WiFi eller ändra inställningen.',
			'settings.maxVolume' => 'Maximal volym',
			'settings.maxVolumeDescription' => 'Tillåt volym över 100% för tyst media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Visa vad du tittar på i Discord',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Synkronisera visningshistorik med Trakt',
			'settings.trackers' => 'Spårare',
			'settings.trackersDescription' => 'Synkronisera framsteg till Trakt, MyAnimeList, AniList och Simkl',
			'settings.companionRemoteServer' => 'Companion Remote-server',
			'settings.companionRemoteServerDescription' => 'Tillåt mobila enheter i ditt nätverk att styra denna app',
			'settings.autoPip' => 'Automatisk bild-i-bild',
			'settings.autoPipDescription' => 'Aktivera bild-i-bild automatiskt när appen lämnas under uppspelning',
			'settings.matchContentFrameRate' => 'Matcha innehållets bildfrekvens',
			'settings.matchContentFrameRateDescription' => 'Justera skärmens uppdateringsfrekvens för att matcha videoinnehållet, minskar hackighet och sparar batteri',
			'settings.matchRefreshRate' => 'Matcha uppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Byt skärmens uppdateringsfrekvens för att matcha videoinnehåll i helskärm',
			'settings.matchDynamicRange' => 'Matcha dynamiskt omfång',
			'settings.matchDynamicRangeDescription' => 'Aktivera HDR automatiskt för HDR-innehåll och återgå till SDR när spelaren stängs',
			'settings.displaySwitchDelay' => 'Fördröjning vid skärmbyte',
			'settings.tunneledPlayback' => 'Tunneluppspelning',
			'settings.tunneledPlaybackDescription' => 'Använd hårdvaruaccelererad videotunnling. Inaktivera om du ser en svart skärm med ljud vid HDR-innehåll',
			'settings.requireProfileSelectionOnOpen' => 'Fråga efter profil vid appstart',
			'settings.requireProfileSelectionOnOpenDescription' => 'Visa profilval varje gång appen öppnas',
			'settings.confirmExitOnBack' => 'Bekräfta innan avslut',
			'settings.confirmExitOnBackDescription' => 'Visa en bekräftelsedialog när du trycker tillbaka för att avsluta appen',
			'settings.forceTvMode' => 'Tvinga TV-läge',
			'settings.forceTvModeDescription' => 'Använd TV-layouten oavsett automatisk identifiering. Användbart på Android TV-enheter som inte rapporterar leanback-funktionen. Startar om appen vid ändring.',
			'settings.startInFullscreen' => 'Starta i helskärm',
			'settings.startInFullscreenDescription' => 'Öppna Plezy i helskärm vid start',
			'settings.autoHidePerformanceOverlay' => 'Dölj prestandaöverlagring automatiskt',
			'settings.autoHidePerformanceOverlayDescription' => 'Tona prestandaöverlagringen med uppspelningskontrollerna',
			'settings.showNavBarLabels' => 'Visa navigeringsfältets etiketter',
			'settings.showNavBarLabelsDescription' => 'Visa textetiketter under navigeringsfältets ikoner',
			'settings.liveTvDefaultFavorites' => 'Standard till favoritkanaler',
			'settings.liveTvDefaultFavoritesDescription' => 'Visa bara favoritkanaler när du öppnar Live TV',
			'settings.display' => 'Display',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Window',
			'settings.content' => 'Content',
			'settings.player' => 'Player',
			'settings.subtitlesAndConfig' => 'Subtitles & Configuration',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'search.hint' => 'Sök filmer, serier, musik...',
			'search.tryDifferentTerm' => 'Prova en annan sökterm',
			'search.searchYourMedia' => 'Sök i dina media',
			'search.enterTitleActorOrKeyword' => 'Ange en titel, skådespelare eller nyckelord',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Sätt genväg för ${actionName}',
			'hotkeys.clearShortcut' => 'Rensa genväg',
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
			'hotkeys.actions.subSeekNext' => 'Hoppa till nästa undertext',
			'hotkeys.actions.subSeekPrev' => 'Hoppa till föregående undertext',
			'hotkeys.actions.shaderToggle' => 'Växla shaders',
			'hotkeys.actions.skipMarker' => 'Hoppa över intro/eftertexter',
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
			'mediaMenu.goToSeries' => 'Gå till serie',
			'mediaMenu.goToSeason' => 'Gå till säsong',
			'mediaMenu.shufflePlay' => 'Blanda uppspelning',
			'mediaMenu.fileInfo' => 'Filinformation',
			'mediaMenu.deleteFromServer' => 'Ta bort från servern',
			'mediaMenu.confirmDelete' => 'Detta kommer permanent ta bort detta media och dess filer från din server. Detta kan inte ångras.',
			'mediaMenu.deleteMultipleWarning' => 'Detta inkluderar alla avsnitt och deras filer.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Mediaobjekt borttaget',
			'mediaMenu.mediaFailedToDelete' => 'Kunde inte ta bort mediaobjekt',
			'mediaMenu.rate' => 'Betygsätt',
			'mediaMenu.playFromBeginning' => 'Spela från början',
			'mediaMenu.playVersion' => 'Spela version...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'sedd',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent sedd',
			'accessibility.mediaCardUnwatched' => 'osedd',
			'accessibility.tapToPlay' => 'Tryck för att spela',
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
			'videoControls.settingsButton' => 'Videoinställningar',
			'videoControls.tracksButton' => 'Ljud och undertexter',
			'videoControls.chaptersButton' => 'Kapitel',
			'videoControls.versionsButton' => 'Videoversioner',
			'videoControls.versionQualityButton' => 'Version och kvalitet',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Kvalitet',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
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
			'videoControls.pipErrors.androidVersion' => 'Kräver Android 8.0 eller nyare',
			'videoControls.pipErrors.iosVersion' => 'Kräver iOS 15.0 eller nyare',
			'videoControls.pipErrors.permissionDisabled' => 'Bild-i-bild-behörighet är inaktiverad. Aktivera den i Inställningar > Appar > Plezy > Bild-i-bild',
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
			'videoControls.subtitleDownloaded' => 'Undertext nedladdad',
			'videoControls.subtitleDownloadFailed' => 'Kunde inte ladda ner undertext',
			'videoControls.searchLanguages' => 'Sök språk...',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Begränsad',
			'userStatus.protected' => 'Skyddad',
			'userStatus.current' => 'NUVARANDE',
			'messages.markedAsWatched' => 'Markerad som sedd',
			'messages.markedAsUnwatched' => 'Markerad som osedd',
			'messages.markedAsWatchedOffline' => 'Markerad som sedd (synkroniseras när online)',
			'messages.markedAsUnwatchedOffline' => 'Markerad som osedd (synkroniseras när online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatiskt borttagen: ${title}',
			'messages.removedFromContinueWatching' => 'Borttagen från Fortsätt titta',
			'messages.errorLoading' => ({required Object error}) => 'Fel: ${error}',
			'messages.fileInfoNotAvailable' => 'Filinformation inte tillgänglig',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fel vid laddning av filinformation: ${error}',
			'messages.errorLoadingSeries' => 'Fel vid laddning av serie',
			'messages.errorLoadingSeason' => 'Fel vid laddning av säsong',
			'messages.musicNotSupported' => 'Musikuppspelning stöds inte ännu',
			'messages.noDescriptionAvailable' => 'Ingen beskrivning tillgänglig',
			'messages.noProfilesAvailable' => 'Inga profiler tillgängliga',
			'messages.contactAdminForProfiles' => 'Kontakta din Plex-administratör för att lägga till profiler',
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
			'messages.noEpisodesFound' => 'Inga avsnitt hittades i första säsongen',
			'messages.noEpisodesFoundGeneral' => 'Inga avsnitt hittades',
			'messages.noResultsFound' => 'Inga resultat hittades',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sovtimer inställd för ${label}',
			'messages.noItemsAvailable' => 'Inga objekt tillgängliga',
			'messages.failedToCreatePlayQueueNoItems' => 'Det gick inte att skapa uppspelningskö – inga objekt',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunde inte ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Byter till kompatibel spelare...',
			'messages.serverLimitTitle' => 'Uppspelningen misslyckades',
			'messages.serverLimitBody' => 'Servern returnerade ett fel (HTTP 500). Det betyder oftast att serverägaren har satt en gräns för bandbredd eller transkodning som avvisar din session. Det finns inget du kan göra från klienten — serverägaren behöver justera sina inställningar.',
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
			'subtitlingStyling.bold' => 'Fet',
			'subtitlingStyling.italic' => 'Kursiv',
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
			'discover.title' => 'Upptäck',
			'discover.switchProfile' => 'Byt profil',
			'discover.noContentAvailable' => 'Inget innehåll tillgängligt',
			'discover.addMediaToLibraries' => 'Lägg till media till dina bibliotek',
			'discover.continueWatching' => 'Fortsätt titta',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Översikt',
			'discover.cast' => 'Rollbesättning',
			'discover.extras' => 'Trailers och Extra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Åldersgräns',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min kvar',
			'errors.searchFailed' => ({required Object error}) => 'Sökning misslyckades: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Anslutnings-timeout vid laddning ${context}',
			'errors.connectionFailed' => 'Kan inte ansluta till Plex-server',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Misslyckades att ladda ${context}: ${error}',
			'errors.noClientAvailable' => 'Ingen klient tillgänglig',
			'errors.authenticationFailed' => ({required Object error}) => 'Autentisering misslyckades: ${error}',
			'errors.couldNotLaunchUrl' => 'Kunde inte öppna autentiserings-URL',
			'errors.pleaseEnterToken' => 'Vänligen ange en token',
			'errors.invalidToken' => 'Ogiltig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Misslyckades att verifiera token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Misslyckades att byta till ${displayName}',
			'libraries.title' => 'Bibliotek',
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
			_ => null,
		} ?? switch (path) {
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Dolda bibliotek (${count})',
			'libraries.thisLibraryIsEmpty' => 'Detta bibliotek är tomt',
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
			'libraries.groupings.folders' => 'Mappar',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Öppen källkod-licenser',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'En vacker Plex-klient för Flutter',
			'about.viewLicensesDescription' => 'Visa licenser för tredjepartsbibliotek',
			'serverSelection.allServerConnectionsFailed' => 'Misslyckades att ansluta till servrar. Kontrollera ditt nätverk och försök igen.',
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
			'liveTv.title' => 'Live-TV',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Inga kanaler tillgängliga',
			'liveTv.noDvr' => 'Ingen DVR konfigurerad på någon server',
			'liveTv.noPrograms' => 'Ingen programdata tillgänglig',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Ladda om programguide',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'Idag',
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
			'liveTv.joinSession' => 'Gå med i pågående session',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Titta från början (${minutes} min sedan)',
			'liveTv.watchLive' => 'Titta live',
			'liveTv.goToLive' => 'Gå till live',
			'collections.title' => 'Samlingar',
			'collections.collection' => 'Samling',
			'collections.empty' => 'Samlingen är tom',
			'collections.unknownLibrarySection' => 'Kan inte ta bort: okänd bibliotekssektion',
			'collections.deleteCollection' => 'Ta bort samling',
			'collections.deleteConfirm' => ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Detta går inte att ångra.',
			'collections.deleted' => 'Samling borttagen',
			'collections.deleteFailed' => 'Det gick inte att ta bort samlingen',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Det gick inte att ta bort samlingen: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Det gick inte att läsa in samlingsobjekt: ${error}',
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
			'playlists.errorCreating' => 'Det gick inte att skapa spellista',
			'playlists.errorDeleting' => 'Det gick inte att ta bort spellista',
			'playlists.errorLoading' => 'Det gick inte att ladda spellistor',
			'playlists.errorAdding' => 'Det gick inte att lägga till i spellista',
			'playlists.errorReordering' => 'Det gick inte att omordna spellisteobjekt',
			'playlists.errorRemoving' => 'Det gick inte att ta bort från spellista',
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
			'watchTogether.joinInstructions' => 'Ange sessionskoden som delats av värden för att gå med i deras tittarsession.',
			'watchTogether.failedToCreate' => 'Det gick inte att skapa session',
			'watchTogether.failedToJoin' => 'Det gick inte att gå med i session',
			'watchTogether.sessionCodeCopied' => 'Sessionskod kopierad till urklipp',
			'watchTogether.relayUnreachable' => 'Reläservern kan inte nås. Detta kan bero på att din internetleverantör blockerar anslutningen. Du kan fortfarande försöka, men Watch Together kanske inte fungerar.',
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
			'watchTogether.waitingForParticipants' => 'Väntar på att andra laddar...',
			'watchTogether.recentRooms' => 'Senaste rum',
			'watchTogether.renameRoom' => 'Byt namn på rum',
			'watchTogether.removeRoom' => 'Ta bort',
			'downloads.title' => 'Nedladdningar',
			'downloads.manage' => 'Hantera',
			'downloads.tvShows' => 'TV-serier',
			'downloads.movies' => 'Filmer',
			'downloads.noDownloads' => 'Inga nedladdningar ännu',
			'downloads.noDownloadsDescription' => 'Nedladdat innehåll visas här för offline-visning',
			'downloads.downloadNow' => 'Ladda ner',
			'downloads.deleteDownload' => 'Ta bort nedladdning',
			'downloads.retryDownload' => 'Försök igen',
			'downloads.downloadQueued' => 'Nedladdning köad',
			'downloads.serverErrorBitrate' => 'Serverfel — filen överskrider möjligen gränsen för fjärrströmning-bitrate',
			'downloads.episodesQueued' => ({required Object count}) => '${count} avsnitt köade för nedladdning',
			'downloads.downloadDeleted' => 'Nedladdning borttagen',
			'downloads.deleteConfirm' => ({required Object title}) => 'Är du säker på att du vill ta bort "${title}"? Den nedladdade filen kommer att tas bort från din enhet.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Tar bort ${title}... (${current} av ${total})',
			'downloads.deleting' => 'Tar bort...',
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
			'downloads.howManyEpisodes' => 'Hur många avsnitt?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} objekt köade för nedladdning',
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
			'downloads.syncRuleListCreated' => 'Synkroniseringsregel skapad',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Ingen videoförbättring',
			'shaders.nvscalerDescription' => 'NVIDIA-bildskalning för skarpare video',
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
			'companionRemote.session.startingServer' => 'Startar fjärrserver...',
			'companionRemote.session.failedToCreate' => 'Kunde inte starta fjärrserver:',
			'companionRemote.session.hostAddress' => 'Värdadress',
			'companionRemote.session.connected' => 'Ansluten',
			'companionRemote.session.serverRunning' => 'Fjärrserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjärrserver stoppad',
			'companionRemote.session.serverRunningDescription' => 'Mobila enheter i ditt nätverk kan upptäcka och ansluta till denna app',
			'companionRemote.session.serverStoppedDescription' => 'Starta servern för att tillåta mobila enheter att ansluta',
			'companionRemote.session.usePhoneToControl' => 'Använd din mobila enhet för att styra denna app',
			'companionRemote.session.startServer' => 'Starta server',
			'companionRemote.session.stopServer' => 'Stoppa server',
			'companionRemote.session.minimize' => 'Minimera',
			'companionRemote.pairing.discoveryDescription' => 'Enheter i ditt nätverk som kör Plezy med samma Plex-konto visas automatiskt',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Ansluter...',
			'companionRemote.pairing.searchingForDevices' => 'Söker efter enheter...',
			'companionRemote.pairing.noDevicesFound' => 'Inga enheter hittades i ditt nätverk',
			'companionRemote.pairing.noDevicesHint' => 'Se till att Plezy är öppet på din dator och att båda enheterna är på samma WiFi-nätverk',
			'companionRemote.pairing.availableDevices' => 'Tillgängliga enheter',
			'companionRemote.pairing.manualConnection' => 'Manuell anslutning',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunde inte initiera säker anslutning. Se till att du är inloggad på ett Plex-konto.',
			'companionRemote.pairing.validationHostRequired' => 'Ange värdadress',
			'companionRemote.pairing.validationHostFormat' => 'Format måste vara IP:port (t.ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Anslutningen tog för lång tid. Se till att båda enheterna är på samma nätverk.',
			'companionRemote.pairing.sessionNotFound' => 'Kunde inte hitta enheten. Se till att Plezy körs på värden.',
			'companionRemote.pairing.authFailed' => 'Autentisering misslyckades. Se till att båda enheterna använder samma Plex-konto.',
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
			'videoSettings.playbackSettings' => 'Uppspelningsinställningar',
			'videoSettings.playbackSpeed' => 'Uppspelningshastighet',
			'videoSettings.sleepTimer' => 'Sovtimer',
			'videoSettings.audioSync' => 'Ljudsynkronisering',
			'videoSettings.subtitleSync' => 'Undertextsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Ljudutgång',
			'videoSettings.performanceOverlay' => 'Prestandaöverlägg',
			'videoSettings.audioPassthrough' => 'Ljudgenomkoppling',
			'videoSettings.audioNormalization' => 'Normalisera ljudstyrka',
			'externalPlayer.title' => 'Extern spelare',
			'externalPlayer.useExternalPlayer' => 'Använd extern spelare',
			'externalPlayer.useExternalPlayerDescription' => 'Öppna videor i en extern app istället för den inbyggda spelaren',
			'externalPlayer.selectPlayer' => 'Välj spelare',
			'externalPlayer.customPlayers' => 'Anpassade spelare',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Lägg till anpassad spelare',
			'externalPlayer.playerName' => 'Spelarnamn',
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
			'matchScreen.unmatchConfirm' => 'Ta bort den aktuella matchningen för det här objektet? Plex behandlar det som omatchat tills du matchar det igen.',
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
			'trakt.disconnectConfirmBody' => 'Plezy slutar skicka uppspelningshändelser till Trakt. Du kan ansluta igen när som helst.',
			'trakt.scrobble' => 'Realtids-scrobbling',
			'trakt.scrobbleDescription' => 'Skicka uppspelnings-, paus- och stopphändelser till Trakt under uppspelning.',
			'trakt.watchedSync' => 'Synkronisera tittad-status',
			'trakt.watchedSyncDescription' => 'När du markerar något som tittat i Plezy markeras det också på Trakt.',
			'trackers.title' => 'Spårare',
			'trackers.hubSubtitle' => 'Håll ditt tittarprogress synkroniserat med Trakt och andra tjänster.',
			'trackers.notConnected' => 'Ej ansluten',
			'trackers.connectedAs' => ({required Object username}) => 'Ansluten som @${username}',
			'trackers.scrobble' => 'Spåra framsteg automatiskt',
			'trackers.scrobbleDescription' => 'Uppdaterar din lista när du är klar med ett avsnitt eller en film.',
			'trackers.disconnectConfirm' => ({required Object service}) => 'Koppla från ${service}?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy slutar uppdatera din ${service}-lista. Du kan ansluta igen när som helst.',
			'trackers.connectFailed' => ({required Object service}) => 'Kunde inte ansluta till ${service}. Försök igen.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Aktivera Plezy på ${service}',
			'trackers.deviceCode.body' => ({required Object url}) => 'Besök ${url} och ange den här koden:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => 'Öppna ${service} för att aktivera',
			'trackers.deviceCode.waitingForAuthorization' => 'Väntar på auktorisering…',
			'trackers.deviceCode.codeCopied' => 'Kod kopierad',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Logga in på ${service}',
			'trackers.oauthProxy.body' => 'Skanna den här QR-koden med din telefon, eller öppna URL:en nedan på en enhet med webbläsare.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => 'Öppna ${service} för att logga in',
			'trackers.oauthProxy.urlCopied' => 'URL kopierad',
			'trackers.libraryFilter.title' => 'Biblioteksfilter',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Synkroniserar alla bibliotek',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Ingenting synkroniseras',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blockerade',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} tillåtna',
			'trackers.libraryFilter.mode' => 'Filterläge',
			'trackers.libraryFilter.modeBlacklist' => 'Svartlista',
			'trackers.libraryFilter.modeWhitelist' => 'Vitlista',
			'trackers.libraryFilter.modeHintBlacklist' => 'Synkronisera alla bibliotek utom de som markerats nedan.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Synkronisera endast de bibliotek som markerats nedan.',
			'trackers.libraryFilter.libraries' => 'Bibliotek',
			'trackers.libraryFilter.noLibraries' => 'Inga bibliotek tillgängliga',
			_ => null,
		};
	}
}
