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
class TranslationsDa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.da,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <da>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsDa _root = this; // ignore: unused_field

	@override 
	TranslationsDa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDa(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppDa app = _TranslationsAppDa._(_root);
	@override late final _TranslationsAuthDa auth = _TranslationsAuthDa._(_root);
	@override late final _TranslationsCommonDa common = _TranslationsCommonDa._(_root);
	@override late final _TranslationsScreensDa screens = _TranslationsScreensDa._(_root);
	@override late final _TranslationsUpdateDa update = _TranslationsUpdateDa._(_root);
	@override late final _TranslationsSettingsDa settings = _TranslationsSettingsDa._(_root);
	@override late final _TranslationsSearchDa search = _TranslationsSearchDa._(_root);
	@override late final _TranslationsHotkeysDa hotkeys = _TranslationsHotkeysDa._(_root);
	@override late final _TranslationsFileInfoDa fileInfo = _TranslationsFileInfoDa._(_root);
	@override late final _TranslationsMediaMenuDa mediaMenu = _TranslationsMediaMenuDa._(_root);
	@override late final _TranslationsAccessibilityDa accessibility = _TranslationsAccessibilityDa._(_root);
	@override late final _TranslationsTooltipsDa tooltips = _TranslationsTooltipsDa._(_root);
	@override late final _TranslationsVideoControlsDa videoControls = _TranslationsVideoControlsDa._(_root);
	@override late final _TranslationsUserStatusDa userStatus = _TranslationsUserStatusDa._(_root);
	@override late final _TranslationsMessagesDa messages = _TranslationsMessagesDa._(_root);
	@override late final _TranslationsSubtitlingStylingDa subtitlingStyling = _TranslationsSubtitlingStylingDa._(_root);
	@override late final _TranslationsMpvConfigDa mpvConfig = _TranslationsMpvConfigDa._(_root);
	@override late final _TranslationsDialogDa dialog = _TranslationsDialogDa._(_root);
	@override late final _TranslationsDiscoverDa discover = _TranslationsDiscoverDa._(_root);
	@override late final _TranslationsErrorsDa errors = _TranslationsErrorsDa._(_root);
	@override late final _TranslationsLibrariesDa libraries = _TranslationsLibrariesDa._(_root);
	@override late final _TranslationsAboutDa about = _TranslationsAboutDa._(_root);
	@override late final _TranslationsServerSelectionDa serverSelection = _TranslationsServerSelectionDa._(_root);
	@override late final _TranslationsHubDetailDa hubDetail = _TranslationsHubDetailDa._(_root);
	@override late final _TranslationsLogsDa logs = _TranslationsLogsDa._(_root);
	@override late final _TranslationsLicensesDa licenses = _TranslationsLicensesDa._(_root);
	@override late final _TranslationsNavigationDa navigation = _TranslationsNavigationDa._(_root);
	@override late final _TranslationsLiveTvDa liveTv = _TranslationsLiveTvDa._(_root);
	@override late final _TranslationsCollectionsDa collections = _TranslationsCollectionsDa._(_root);
	@override late final _TranslationsPlaylistsDa playlists = _TranslationsPlaylistsDa._(_root);
	@override late final _TranslationsWatchTogetherDa watchTogether = _TranslationsWatchTogetherDa._(_root);
	@override late final _TranslationsDownloadsDa downloads = _TranslationsDownloadsDa._(_root);
	@override late final _TranslationsShadersDa shaders = _TranslationsShadersDa._(_root);
	@override late final _TranslationsCompanionRemoteDa companionRemote = _TranslationsCompanionRemoteDa._(_root);
	@override late final _TranslationsVideoSettingsDa videoSettings = _TranslationsVideoSettingsDa._(_root);
	@override late final _TranslationsExternalPlayerDa externalPlayer = _TranslationsExternalPlayerDa._(_root);
	@override late final _TranslationsMetadataEditDa metadataEdit = _TranslationsMetadataEditDa._(_root);
	@override late final _TranslationsMatchScreenDa matchScreen = _TranslationsMatchScreenDa._(_root);
	@override late final _TranslationsServerTasksDa serverTasks = _TranslationsServerTasksDa._(_root);
	@override late final _TranslationsTraktDa trakt = _TranslationsTraktDa._(_root);
	@override late final _TranslationsTrackersDa trackers = _TranslationsTrackersDa._(_root);
}

// Path: app
class _TranslationsAppDa implements TranslationsAppEn {
	_TranslationsAppDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthDa implements TranslationsAuthEn {
	_TranslationsAuthDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Log ind med Plex';
	@override String get showQRCode => 'Vis QR-kode';
	@override String get authenticate => 'Godkend';
	@override String get authenticationTimeout => 'Godkendelse fik timeout. Prøv igen.';
	@override String get scanQRToSignIn => 'Scan denne QR-kode for at logge ind';
	@override String get waitingForAuth => 'Venter på godkendelse...\nFærdiggør login i din browser.';
	@override String get useBrowser => 'Brug browser';
}

// Path: common
class _TranslationsCommonDa implements TranslationsCommonEn {
	_TranslationsCommonDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuller';
	@override String get save => 'Gem';
	@override String get close => 'Luk';
	@override String get clear => 'Ryd';
	@override String get reset => 'Nulstil';
	@override String get later => 'Senere';
	@override String get submit => 'Indsend';
	@override String get confirm => 'Bekræft';
	@override String get retry => 'Prøv igen';
	@override String get logout => 'Log ud';
	@override String get unknown => 'Ukendt';
	@override String get refresh => 'Opdater';
	@override String get yes => 'Ja';
	@override String get no => 'Nej';
	@override String get delete => 'Slet';
	@override String get shuffle => 'Bland';
	@override String get addTo => 'Tilføj til...';
	@override String get createNew => 'Opret ny';
	@override String get connect => 'Forbind';
	@override String get disconnect => 'Afbryd';
	@override String get play => 'Afspil';
	@override String get pause => 'Pause';
	@override String get resume => 'Genoptag';
	@override String get error => 'Fejl';
	@override String get search => 'Søg';
	@override String get home => 'Hjem';
	@override String get back => 'Tilbage';
	@override String get settings => 'Indstillinger';
	@override String get mute => 'Lydløs';
	@override String get ok => 'OK';
	@override String get reconnect => 'Genopret forbindelse';
	@override String get exitConfirmTitle => 'Luk app?';
	@override String get exitConfirmMessage => 'Er du sikker på, at du vil afslutte?';
	@override String get dontAskAgain => 'Spørg ikke igen';
	@override String get exit => 'Afslut';
	@override String get viewAll => 'Vis alle';
	@override String get checkingNetwork => 'Tjekker netværk...';
	@override String get refreshingServers => 'Opdaterer servere...';
	@override String get loadingServers => 'Indlæser servere...';
	@override String get connectingToServers => 'Forbinder til servere...';
	@override String get startingOfflineMode => 'Starter offlinetilstand...';
	@override String get loading => 'Indlæser...';
	@override String get fullscreen => 'Fuldskærm';
	@override String get exitFullscreen => 'Forlad fuldskærm';
}

// Path: screens
class _TranslationsScreensDa implements TranslationsScreensEn {
	_TranslationsScreensDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenser';
	@override String get switchProfile => 'Skift profil';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdateDa implements TranslationsUpdateEn {
	_TranslationsUpdateDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get available => 'Opdatering tilgængelig';
	@override String versionAvailable({required Object version}) => 'Version ${version} er tilgængelig';
	@override String currentVersion({required Object version}) => 'Nuværende: ${version}';
	@override String get skipVersion => 'Spring denne version over';
	@override String get viewRelease => 'Vis udgivelse';
	@override String get latestVersion => 'Du har den nyeste version';
	@override String get checkFailed => 'Kunne ikke søge efter opdateringer';
}

// Path: settings
class _TranslationsSettingsDa implements TranslationsSettingsEn {
	_TranslationsSettingsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Indstillinger';
	@override String get supportDeveloper => 'Støt Plezy';
	@override String get supportDeveloperDescription => 'Doner via Liberapay for at finansiere udviklingen';
	@override String get language => 'Sprog';
	@override String get theme => 'Tema';
	@override String get appearance => 'Udseende';
	@override String get videoPlayback => 'Videoafspilning';
	@override String get videoPlaybackDescription => 'Konfigurer afspilningsadfærd';
	@override String get advanced => 'Avanceret';
	@override String get episodePosterMode => 'Episodeplakatstil';
	@override String get seriesPoster => 'Serieplakat';
	@override String get seasonPoster => 'Sæsonplakat';
	@override String get episodeThumbnail => 'Miniature';
	@override String get showHeroSectionDescription => 'Vis karrusel med udvalgt indhold på startskærmen';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minutter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Indtast varighed (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Lys';
	@override String get darkTheme => 'Mørk';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Bibliotekstæthed';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Komfortabel';
	@override String get viewMode => 'Visningstilstand';
	@override String get gridView => 'Gitter';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Vis hero-sektion';
	@override String get useGlobalHubs => 'Brug Plex Home-layout';
	@override String get useGlobalHubsDescription => 'Vis startsidehubbe som den officielle Plex-klient. Når slået fra, vises anbefalinger per bibliotek.';
	@override String get showServerNameOnHubs => 'Vis servernavn på hubbe';
	@override String get showServerNameOnHubsDescription => 'Vis altid servernavnet i hubtitler. Når slået fra, vises kun ved duplikerede navne.';
	@override String get alwaysKeepSidebarOpen => 'Hold altid sidepanelet åbent';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidepanelet forbliver udvidet, og indholdsområdet tilpasser sig';
	@override String get showUnwatchedCount => 'Vis antal usete';
	@override String get showUnwatchedCountDescription => 'Vis antal usete episoder på serier og sæsoner';
	@override String get showEpisodeNumberOnCards => 'Vis episodenummer på kort';
	@override String get showEpisodeNumberOnCardsDescription => 'Vis episodenummer ved siden af sæsonen (f.eks. S2 E3) på episodekort';
	@override String get hideSpoilers => 'Skjul spoilere for usete episoder';
	@override String get hideSpoilersDescription => 'Slør miniaturebilleder og skjul beskrivelser for episoder, du ikke har set endnu';
	@override String get playerBackend => 'Afspillerbackend';
	@override String get exoPlayer => 'ExoPlayer (Anbefalet)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Hardwaredekodning';
	@override String get hardwareDecodingDescription => 'Brug hardwareacceleration når tilgængelig';
	@override String get bufferSize => 'Bufferstørrelse';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Anbefalet)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Din enhed har ${heap}MB hukommelse. En buffer på ${size}MB kan forårsage afspilningsproblemer.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get defaultQualityDescription => 'Bruges ved start af afspilning. Lavere værdier reducerer båndbredden.';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpas underteksters udseende';
	@override String get smallSkipDuration => 'Kort spring-varighed';
	@override String get largeSkipDuration => 'Lang spring-varighed';
	@override String get rewindOnResume => 'Spol tilbage ved genoptagelse';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard sove-timer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutter';
	@override String get rememberTrackSelections => 'Husk sporvalg per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Gem automatisk lyd- og undertekstsprogpræferencer når du skifter spor under afspilning';
	@override String get clickVideoTogglesPlayback => 'Klik på video skifter afspil/pause';
	@override String get clickVideoTogglesPlaybackDescription => 'Når aktiveret, afspiller/pauser klik på videoen. Ellers vises/skjules betjeningselementer.';
	@override String get videoPlayerControls => 'Videoafspillerkontroller';
	@override String get keyboardShortcuts => 'Tastaturgenveje';
	@override String get keyboardShortcutsDescription => 'Tilpas tastaturgenveje';
	@override String get videoPlayerNavigation => 'Videoafspillernavigation';
	@override String get videoPlayerNavigationDescription => 'Brug piletaster til at navigere videoafspillerkontroller';
	@override String get watchTogetherRelay => 'Watch Together-relay';
	@override String get watchTogetherRelayDescription => 'Angiv en brugerdefineret relay-server til Watch Together. Alle deltagere skal bruge den samme server.';
	@override String get watchTogetherRelayHint => 'https://min-relay.eksempel.dk';
	@override String get crashReporting => 'Fejlrapportering';
	@override String get crashReportingDescription => 'Send fejlrapporter for at hjælpe med at forbedre appen';
	@override String get debugLogging => 'Fejlfindingslogning';
	@override String get debugLoggingDescription => 'Aktiver detaljeret logning til fejlfinding';
	@override String get viewLogs => 'Vis logs';
	@override String get viewLogsDescription => 'Vis applikationslogs';
	@override String get clearCache => 'Ryd cache';
	@override String get clearCacheDescription => 'Dette rydder alle cachelagrede billeder og data. Appen kan tage længere tid om at indlæse indhold efter rydning.';
	@override String get clearCacheSuccess => 'Cache ryddet';
	@override String get resetSettings => 'Nulstil indstillinger';
	@override String get resetSettingsDescription => 'Alle indstillinger nulstilles til standardværdier. Denne handling kan ikke fortrydes.';
	@override String get resetSettingsSuccess => 'Indstillinger nulstillet';
	@override String get backup => 'Sikkerhedskopi';
	@override String get exportSettings => 'Eksportér indstillinger';
	@override String get exportSettingsDescription => 'Gem dine præferencer i en fil';
	@override String get exportSettingsSuccess => 'Indstillinger eksporteret';
	@override String get exportSettingsFailed => 'Kunne ikke eksportere indstillinger';
	@override String get importSettings => 'Importér indstillinger';
	@override String get importSettingsDescription => 'Gendan præferencer fra en fil';
	@override String get importSettingsConfirm => 'Dette vil erstatte dine nuværende indstillinger. Fortsæt?';
	@override String get importSettingsSuccess => 'Indstillinger importeret';
	@override String get importSettingsFailed => 'Kunne ikke importere indstillinger';
	@override String get importSettingsInvalidFile => 'Denne fil er ikke en gyldig Plezy-indstillingseksport';
	@override String get importSettingsNoUser => 'Log ind før import af indstillinger';
	@override String get shortcutsReset => 'Genveje nulstillet til standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'App-information og licenser';
	@override String get updates => 'Opdateringer';
	@override String get updateAvailable => 'Opdatering tilgængelig';
	@override String get checkForUpdates => 'Søg efter opdateringer';
	@override String get autoCheckUpdatesOnStartup => 'Søg automatisk efter opdateringer ved opstart';
	@override String get autoCheckUpdatesOnStartupDescription => 'Vis en notifikation, når en ny version er tilgængelig ved opstart';
	@override String get validationErrorEnterNumber => 'Indtast et gyldigt tal';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Varighed skal være mellem ${min} og ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Genvej allerede tildelt til ${action}';
	@override String shortcutUpdated({required Object action}) => 'Genvej opdateret for ${action}';
	@override String get autoSkip => 'Auto-spring';
	@override String get autoSkipIntro => 'Auto-spring intro';
	@override String get autoSkipIntroDescription => 'Spring automatisk intromarkører over efter få sekunder';
	@override String get autoSkipCredits => 'Auto-spring rulletekster';
	@override String get autoSkipCreditsDescription => 'Spring automatisk rulletekster over og afspil næste episode';
	@override String get autoSkipDelay => 'Auto-spring forsinkelse';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk spring';
	@override String get introPattern => 'Intromarkørmønster';
	@override String get introPatternDescription => 'Regulært udtryk til at genkende intromarkører i kapiteltitler';
	@override String get creditsPattern => 'Rulletekstmarkørmønster';
	@override String get creditsPatternDescription => 'Regulært udtryk til at genkende rulletekstmarkører i kapiteltitler';
	@override String get invalidRegex => 'Ugyldigt regulært udtryk';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Vælg hvor downloadet indhold skal gemmes';
	@override String get downloadLocationDefault => 'Standard (App-lagring)';
	@override String get downloadLocationCustom => 'Brugerdefineret placering';
	@override String get selectFolder => 'Vælg mappe';
	@override String get resetToDefault => 'Nulstil til standard';
	@override String currentPath({required Object path}) => 'Nuværende: ${path}';
	@override String get downloadLocationChanged => 'Downloadplacering ændret';
	@override String get downloadLocationReset => 'Downloadplacering nulstillet';
	@override String get downloadLocationInvalid => 'Valgt mappe er ikke skrivbar';
	@override String get downloadLocationSelectError => 'Kunne ikke vælge mappe';
	@override String get downloadOnWifiOnly => 'Download kun på WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Forhindre downloads på mobildata';
	@override String get autoRemoveWatchedDownloads => 'Fjern sete downloads automatisk';
	@override String get autoRemoveWatchedDownloadsDescription => 'Slet automatisk downloadede episoder og film, når de markeres som set';
	@override String get cellularDownloadBlocked => 'Downloads er deaktiveret på mobildata. Opret forbindelse til WiFi eller ændr indstillingen.';
	@override String get maxVolume => 'Maksimal lydstyrke';
	@override String get maxVolumeDescription => 'Tillad lydstyrkeforstærkning over 100% for stille medier';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Vis hvad du ser på Discord';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Synkroniser visningshistorik med Trakt';
	@override String get trackers => 'Trackere';
	@override String get trackersDescription => 'Synkroniser fremgang til Trakt, MyAnimeList, AniList og Simkl';
	@override String get companionRemoteServer => 'Companion Remote Server';
	@override String get companionRemoteServerDescription => 'Tillad mobilenheder på dit netværk at styre denne app';
	@override String get autoPip => 'Auto billede-i-billede';
	@override String get autoPipDescription => 'Gå automatisk til billede-i-billede når du forlader appen under afspilning';
	@override String get matchContentFrameRate => 'Match indholdets billedhastighed';
	@override String get matchContentFrameRateDescription => 'Juster skærmens opdateringshastighed til videoindhold for at reducere hakken og spare batteri';
	@override String get matchRefreshRate => 'Match opdateringshastighed';
	@override String get matchRefreshRateDescription => 'Skift skærmens opdateringshastighed til at matche videoindhold i fuldskærm';
	@override String get matchDynamicRange => 'Match dynamisk område';
	@override String get matchDynamicRangeDescription => 'Aktiver automatisk HDR for HDR-indhold og gendan SDR når afspilleren lukkes';
	@override String get displaySwitchDelay => 'Forsinkelse ved skærmskift';
	@override String get tunneledPlayback => 'Tunneleret afspilning';
	@override String get tunneledPlaybackDescription => 'Brug hardwareaccelereret videotunneling. Deaktiver hvis du ser sort skærm med lyd på HDR-indhold';
	@override String get requireProfileSelectionOnOpen => 'Spørg om profil ved åbning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åbnes';
	@override String get confirmExitOnBack => 'Bekræft før lukning';
	@override String get confirmExitOnBackDescription => 'Vis bekræftelsesdialog ved tryk på tilbage for at lukke appen';
	@override String get forceTvMode => 'Gennemtving TV-tilstand';
	@override String get forceTvModeDescription => 'Brug TV-layoutet uanset automatisk registrering. Nyttigt på Android TV-enheder, der ikke rapporterer leanback-funktionen. Genstarter appen ved ændring.';
	@override String get autoHidePerformanceOverlay => 'Skjul ydelses-overlay automatisk';
	@override String get autoHidePerformanceOverlayDescription => 'Fade ydelses-overlayet med afspilningskontrollerne';
	@override String get showNavBarLabels => 'Vis navigationsbarlabels';
	@override String get showNavBarLabelsDescription => 'Vis tekstlabels under navigationsbarikoner';
	@override String get liveTvDefaultFavorites => 'Standard til favoritkanaler';
	@override String get liveTvDefaultFavoritesDescription => 'Vis kun favoritkanaler ved åbning af Live TV';
	@override String get display => 'Display';
	@override String get homeScreen => 'Home Screen';
	@override String get navigation => 'Navigation';
	@override String get content => 'Content';
	@override String get player => 'Player';
	@override String get subtitlesAndConfig => 'Subtitles & Configuration';
	@override String get seekAndTiming => 'Seek & Timing';
	@override String get behavior => 'Behavior';
}

// Path: search
class _TranslationsSearchDa implements TranslationsSearchEn {
	_TranslationsSearchDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Søg film, serier, musik...';
	@override String get tryDifferentTerm => 'Prøv en anden søgning';
	@override String get searchYourMedia => 'Søg i dine medier';
	@override String get enterTitleActorOrKeyword => 'Indtast titel, skuespiller eller nøgleord';
}

// Path: hotkeys
class _TranslationsHotkeysDa implements TranslationsHotkeysEn {
	_TranslationsHotkeysDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Indstil genvej for ${actionName}';
	@override String get clearShortcut => 'Ryd genvej';
	@override late final _TranslationsHotkeysActionsDa actions = _TranslationsHotkeysActionsDa._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoDa implements TranslationsFileInfoEn {
	_TranslationsFileInfoDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filinfo';
	@override String get video => 'Video';
	@override String get audio => 'Lyd';
	@override String get file => 'Fil';
	@override String get advanced => 'Avanceret';
	@override String get codec => 'Codec';
	@override String get resolution => 'Opløsning';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Billedhastighed';
	@override String get aspectRatio => 'Billedformat';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bitdybde';
	@override String get colorSpace => 'Farverum';
	@override String get colorRange => 'Farveområde';
	@override String get colorPrimaries => 'Farveprimærer';
	@override String get chromaSubsampling => 'Chroma-subsampling';
	@override String get channels => 'Kanaler';
	@override String get subtitles => 'Undertekster';
	@override String get overallBitrate => 'Samlet bitrate';
	@override String get path => 'Sti';
	@override String get size => 'Størrelse';
	@override String get container => 'Container';
	@override String get duration => 'Varighed';
	@override String get optimizedForStreaming => 'Optimeret til streaming';
	@override String get has64bitOffsets => '64-bit offsets';
}

// Path: mediaMenu
class _TranslationsMediaMenuDa implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Markér som set';
	@override String get markAsUnwatched => 'Markér som uset';
	@override String get removeFromContinueWatching => 'Fjern fra Fortsæt med at se';
	@override String get goToSeries => 'Gå til serie';
	@override String get goToSeason => 'Gå til sæson';
	@override String get shufflePlay => 'Afspil tilfældigt';
	@override String get fileInfo => 'Filinfo';
	@override String get deleteFromServer => 'Slet fra server';
	@override String get confirmDelete => 'Dette sletter permanent disse medier og filer fra din server. Dette kan ikke fortrydes.';
	@override String get deleteMultipleWarning => 'Dette inkluderer alle episoder og deres filer.';
	@override String get mediaDeletedSuccessfully => 'Medieelement slettet';
	@override String get mediaFailedToDelete => 'Kunne ikke slette medieelement';
	@override String get rate => 'Bedøm';
	@override String get playFromBeginning => 'Afspil fra begyndelsen';
	@override String get playVersion => 'Afspil version...';
}

// Path: accessibility
class _TranslationsAccessibilityDa implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'set';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} procent set';
	@override String get mediaCardUnwatched => 'uset';
	@override String get tapToPlay => 'Tryk for at afspille';
}

// Path: tooltips
class _TranslationsTooltipsDa implements TranslationsTooltipsEn {
	_TranslationsTooltipsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Afspil tilfældigt';
	@override String get playTrailer => 'Afspil trailer';
	@override String get markAsWatched => 'Markér som set';
	@override String get markAsUnwatched => 'Markér som uset';
}

// Path: videoControls
class _TranslationsVideoControlsDa implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Lyd';
	@override String get subtitlesLabel => 'Undertekster';
	@override String get resetToZero => 'Nulstil til 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} afspilles senere';
	@override String playsEarlier({required Object label}) => '${label} afspilles tidligere';
	@override String get noOffset => 'Ingen forskydning';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Fyld skærm';
	@override String get stretch => 'Stræk';
	@override String get lockRotation => 'Lås rotation';
	@override String get unlockRotation => 'Lås rotation op';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Afspilning pauses om ${duration}';
	@override String get stillWatching => 'Ser du stadig?';
	@override String pausingIn({required Object seconds}) => 'Pauser om ${seconds}s';
	@override String get continueWatching => 'Fortsæt';
	@override String get autoPlayNext => 'Auto-afspil næste';
	@override String get playNext => 'Afspil næste';
	@override String get playButton => 'Afspil';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => 'Spol ${seconds} sekunder tilbage';
	@override String seekForwardButton({required Object seconds}) => 'Spol ${seconds} sekunder frem';
	@override String get previousButton => 'Forrige episode';
	@override String get nextButton => 'Næste episode';
	@override String get previousChapterButton => 'Forrige kapitel';
	@override String get nextChapterButton => 'Næste kapitel';
	@override String get muteButton => 'Lydløs';
	@override String get unmuteButton => 'Slå lyd til';
	@override String get settingsButton => 'Videoindstillinger';
	@override String get tracksButton => 'Lyd og undertekster';
	@override String get chaptersButton => 'Kapitler';
	@override String get versionsButton => 'Videoversioner';
	@override String get versionQualityButton => 'Version og kvalitet';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Kvalitet';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkodning utilgængelig — afspiller original kvalitet';
	@override String get pipButton => 'Billede-i-billede-tilstand';
	@override String get aspectRatioButton => 'Billedformat';
	@override String get ambientLighting => 'Omgivelsesbelysning';
	@override String get fullscreenButton => 'Fuldskærm';
	@override String get exitFullscreenButton => 'Forlad fuldskærm';
	@override String get alwaysOnTopButton => 'Altid øverst';
	@override String get rotationLockButton => 'Rotationslås';
	@override String get lockScreen => 'Lås skærm';
	@override String get screenLockButton => 'Skærmlås';
	@override String get longPressToUnlock => 'Langt tryk for at låse op';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Lydstyrkeniveau';
	@override String endsAt({required Object time}) => 'Slutter kl. ${time}';
	@override String get pipActive => 'Afspiller i billede-i-billede';
	@override String get pipFailed => 'Billede-i-billede kunne ikke starte';
	@override late final _TranslationsVideoControlsPipErrorsDa pipErrors = _TranslationsVideoControlsPipErrorsDa._(_root);
	@override String get chapters => 'Kapitler';
	@override String get noChaptersAvailable => 'Ingen kapitler tilgængelige';
	@override String get queue => 'Kø';
	@override String get noQueueItems => 'Ingen elementer i køen';
	@override String get searchSubtitles => 'Søg undertekster';
	@override String get language => 'Sprog';
	@override String get noSubtitlesFound => 'Ingen undertekster fundet';
	@override String get subtitleDownloaded => 'Undertekst downloadet';
	@override String get subtitleDownloadFailed => 'Kunne ikke downloade undertekst';
	@override String get searchLanguages => 'Søg sprog...';
}

// Path: userStatus
class _TranslationsUserStatusDa implements TranslationsUserStatusEn {
	_TranslationsUserStatusDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Administrator';
	@override String get restricted => 'Begrænset';
	@override String get protected => 'Beskyttet';
	@override String get current => 'NUVÆRENDE';
}

// Path: messages
class _TranslationsMessagesDa implements TranslationsMessagesEn {
	_TranslationsMessagesDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Markeret som set';
	@override String get markedAsUnwatched => 'Markeret som uset';
	@override String get markedAsWatchedOffline => 'Markeret som set (synkroniseres online)';
	@override String get markedAsUnwatchedOffline => 'Markeret som uset (synkroniseres online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisk fjernet: ${title}';
	@override String get removedFromContinueWatching => 'Fjernet fra Fortsæt med at se';
	@override String errorLoading({required Object error}) => 'Fejl: ${error}';
	@override String get fileInfoNotAvailable => 'Filinfo ikke tilgængelig';
	@override String errorLoadingFileInfo({required Object error}) => 'Fejl ved indlæsning af filinfo: ${error}';
	@override String get errorLoadingSeries => 'Fejl ved indlæsning af serie';
	@override String get errorLoadingSeason => 'Fejl ved indlæsning af sæson';
	@override String get musicNotSupported => 'Musikafspilning understøttes endnu ikke';
	@override String get noDescriptionAvailable => 'Ingen beskrivelse tilgængelig';
	@override String get noProfilesAvailable => 'Ingen profiler tilgængelige';
	@override String get contactAdminForProfiles => 'Kontakt din Plex-administrator for at tilføje profiler';
	@override String get unableToDetermineLibrarySection => 'Kan ikke bestemme biblioteksafdeling for dette element';
	@override String get logsCleared => 'Logs ryddet';
	@override String get logsCopied => 'Logs kopieret til udklipsholder';
	@override String get noLogsAvailable => 'Ingen logs tilgængelige';
	@override String libraryScanning({required Object title}) => 'Scanner "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Biblioteksscanning startet for "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Kunne ikke scanne bibliotek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Opdaterer metadata for "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadataopdatering startet for "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Kunne ikke opdatere metadata: ${error}';
	@override String get logoutConfirm => 'Er du sikker på, at du vil logge ud?';
	@override String get noSeasonsFound => 'Ingen sæsoner fundet';
	@override String get noEpisodesFound => 'Ingen episoder fundet i første sæson';
	@override String get noEpisodesFoundGeneral => 'Ingen episoder fundet';
	@override String get noResultsFound => 'Ingen resultater fundet';
	@override String sleepTimerSet({required Object label}) => 'Sove-timer indstillet til ${label}';
	@override String get noItemsAvailable => 'Ingen elementer tilgængelige';
	@override String get failedToCreatePlayQueueNoItems => 'Kunne ikke oprette afspilningskø — ingen elementer';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Skifter til kompatibel afspiller...';
	@override String get serverLimitTitle => 'Afspilning mislykkedes';
	@override String get serverLimitBody => 'Serveren returnerede en fejl (HTTP 500). Det betyder som regel, at serverejeren har sat en båndbredde- eller transkodningsgrænse, der afviser din session. Der er intet at gøre fra klienten — serverejeren skal justere sine indstillinger.';
	@override String get logsUploaded => 'Logs uploadet';
	@override String get logsUploadFailed => 'Kunne ikke uploade logs';
	@override String get logId => 'Log-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingDa implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get text => 'Tekst';
	@override String get border => 'Kant';
	@override String get background => 'Baggrund';
	@override String get fontSize => 'Skriftstørrelse';
	@override String get textColor => 'Tekstfarve';
	@override String get borderSize => 'Kantstørrelse';
	@override String get borderColor => 'Kantfarve';
	@override String get backgroundOpacity => 'Baggrundsgennemsigtighed';
	@override String get backgroundColor => 'Baggrundsfarve';
	@override String get position => 'Position';
	@override String get assOverride => 'ASS-tilsidesættelse';
	@override String get bold => 'Fed';
	@override String get italic => 'Kursiv';
}

// Path: mpvConfig
class _TranslationsMpvConfigDa implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Avancerede videoafspillerindstillinger';
	@override String get presets => 'Forudindstillinger';
	@override String get noPresets => 'Ingen gemte forudindstillinger';
	@override String get saveAsPreset => 'Gem som forudindstilling...';
	@override String get presetName => 'Forudindstillingsnavn';
	@override String get presetNameHint => 'Indtast et navn for denne forudindstilling';
	@override String get loadPreset => 'Indlæs';
	@override String get deletePreset => 'Slet';
	@override String get presetSaved => 'Forudindstilling gemt';
	@override String get presetLoaded => 'Forudindstilling indlæst';
	@override String get presetDeleted => 'Forudindstilling slettet';
	@override String get confirmDeletePreset => 'Er du sikker på, at du vil slette denne forudindstilling?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogDa implements TranslationsDialogEn {
	_TranslationsDialogDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekræft handling';
}

// Path: discover
class _TranslationsDiscoverDa implements TranslationsDiscoverEn {
	_TranslationsDiscoverDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Opdag';
	@override String get switchProfile => 'Skift profil';
	@override String get noContentAvailable => 'Intet indhold tilgængeligt';
	@override String get addMediaToLibraries => 'Tilføj medier til dine biblioteker';
	@override String get continueWatching => 'Fortsæt med at se';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Oversigt';
	@override String get cast => 'Rollebesætning';
	@override String get extras => 'Trailere og ekstra';
	@override String get studio => 'Studie';
	@override String get rating => 'Bedømmelse';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min tilbage';
}

// Path: errors
class _TranslationsErrorsDa implements TranslationsErrorsEn {
	_TranslationsErrorsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Søgning mislykkedes: ${error}';
	@override String connectionTimeout({required Object context}) => 'Forbindelsestimeout ved indlæsning af ${context}';
	@override String get connectionFailed => 'Kunne ikke forbinde til Plex-server';
	@override String failedToLoad({required Object context, required Object error}) => 'Kunne ikke indlæse ${context}: ${error}';
	@override String get noClientAvailable => 'Ingen klient tilgængelig';
	@override String authenticationFailed({required Object error}) => 'Godkendelse mislykkedes: ${error}';
	@override String get couldNotLaunchUrl => 'Kunne ikke åbne godkendelses-URL';
	@override String get pleaseEnterToken => 'Indtast et token';
	@override String get invalidToken => 'Ugyldigt token';
	@override String failedToVerifyToken({required Object error}) => 'Kunne ikke verificere token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kunne ikke skifte til ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesDa implements TranslationsLibrariesEn {
	_TranslationsLibrariesDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteker';
	@override String get scanLibraryFiles => 'Scan biblioteksfiler';
	@override String get scanLibrary => 'Scan bibliotek';
	@override String get analyze => 'Analysér';
	@override String get analyzeLibrary => 'Analysér bibliotek';
	@override String get refreshMetadata => 'Opdater metadata';
	@override String get emptyTrash => 'Tøm papirkurv';
	@override String emptyingTrash({required Object title}) => 'Tømmer papirkurv for "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papirkurv tømt for "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kunne ikke tømme papirkurv: ${error}';
	@override String analyzing({required Object title}) => 'Analyserer "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analyse startet for "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kunne ikke analysere bibliotek: ${error}';
	@override String get noLibrariesFound => 'Ingen biblioteker fundet';
	@override String get thisLibraryIsEmpty => 'Dette bibliotek er tomt';
	@override String get all => 'Alle';
	@override String get clearAll => 'Ryd alle';
	@override String scanLibraryConfirm({required Object title}) => 'Er du sikker på, at du vil scanne "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Er du sikker på, at du vil analysere "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Er du sikker på, at du vil opdatere metadata for "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Er du sikker på, at du vil tømme papirkurven for "${title}"?';
	@override String get manageLibraries => 'Administrer biblioteker';
	@override String get sort => 'Sortér';
	@override String get sortBy => 'Sortér efter';
	@override String get filters => 'Filtre';
	@override String get confirmActionMessage => 'Er du sikker på, at du vil udføre denne handling?';
	@override String get showLibrary => 'Vis bibliotek';
	@override String get hideLibrary => 'Skjul bibliotek';
	@override String get libraryOptions => 'Biblioteksindstillinger';
	@override String get content => 'biblioteksindhold';
	@override String get selectLibrary => 'Vælg bibliotek';
	@override String filtersWithCount({required Object count}) => 'Filtre (${count})';
	@override String get noRecommendations => 'Ingen anbefalinger tilgængelige';
	@override String get noCollections => 'Ingen samlinger i dette bibliotek';
	@override String get noFoldersFound => 'Ingen mapper fundet';
	@override String get folders => 'mapper';
	@override late final _TranslationsLibrariesTabsDa tabs = _TranslationsLibrariesTabsDa._(_root);
	@override late final _TranslationsLibrariesGroupingsDa groupings = _TranslationsLibrariesGroupingsDa._(_root);
}

// Path: about
class _TranslationsAboutDa implements TranslationsAboutEn {
	_TranslationsAboutDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Open source-licenser';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'En smuk Plex-klient til Flutter';
	@override String get viewLicensesDescription => 'Se licenser for tredjepartsbiblioteker';
}

// Path: serverSelection
class _TranslationsServerSelectionDa implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Kunne ikke forbinde til nogen servere. Tjek dit netværk og prøv igen.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Ingen servere fundet for ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kunne ikke indlæse servere: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailDa implements TranslationsHubDetailEn {
	_TranslationsHubDetailDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get releaseYear => 'Udgivelsesår';
	@override String get dateAdded => 'Tilføjelsesdato';
	@override String get rating => 'Bedømmelse';
	@override String get noItemsFound => 'Ingen elementer fundet';
}

// Path: logs
class _TranslationsLogsDa implements TranslationsLogsEn {
	_TranslationsLogsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Ryd logs';
	@override String get copyLogs => 'Kopiér logs';
	@override String get uploadLogs => 'Upload logs';
}

// Path: licenses
class _TranslationsLicensesDa implements TranslationsLicensesEn {
	_TranslationsLicensesDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterede pakker';
	@override String get license => 'Licens';
	@override String licenseNumber({required Object number}) => 'Licens ${number}';
	@override String licensesCount({required Object count}) => '${count} licenser';
}

// Path: navigation
class _TranslationsNavigationDa implements TranslationsNavigationEn {
	_TranslationsNavigationDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteker';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'Live TV';
}

// Path: liveTv
class _TranslationsLiveTvDa implements TranslationsLiveTvEn {
	_TranslationsLiveTvDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live TV';
	@override String get guide => 'Guide';
	@override String get noChannels => 'Ingen kanaler tilgængelige';
	@override String get noDvr => 'Ingen DVR konfigureret på nogen server';
	@override String get noPrograms => 'Ingen programdata tilgængelig';
	@override String get live => 'LIVE';
	@override String get reloadGuide => 'Genindlæs guide';
	@override String get now => 'Nu';
	@override String get today => 'I dag';
	@override String get midnight => 'Midnat';
	@override String get overnight => 'Nat';
	@override String get morning => 'Morgen';
	@override String get daytime => 'Dagtid';
	@override String get evening => 'Aften';
	@override String get lateNight => 'Sen aften';
	@override String get whatsOn => 'Hvad der kører';
	@override String get watchChannel => 'Se kanal';
	@override String get favorites => 'Favoritter';
	@override String get reorderFavorites => 'Omarranger favoritter';
	@override String get joinSession => 'Deltag i igangværende session';
	@override String watchFromStart({required Object minutes}) => 'Se fra start (${minutes} min siden)';
	@override String get watchLive => 'Se live';
	@override String get goToLive => 'Gå til live';
}

// Path: collections
class _TranslationsCollectionsDa implements TranslationsCollectionsEn {
	_TranslationsCollectionsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlinger';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen er tom';
	@override String get unknownLibrarySection => 'Kan ikke slette: Ukendt bibliotekssektion';
	@override String get deleteCollection => 'Slet samling';
	@override String deleteConfirm({required Object title}) => 'Er du sikker på, at du vil slette "${title}"? Denne handling kan ikke fortrydes.';
	@override String get deleted => 'Samling slettet';
	@override String get deleteFailed => 'Kunne ikke slette samling';
	@override String deleteFailedWithError({required Object error}) => 'Kunne ikke slette samling: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Kunne ikke indlæse samlingselementer: ${error}';
	@override String get selectCollection => 'Vælg samling';
	@override String get collectionName => 'Samlingsnavn';
	@override String get enterCollectionName => 'Indtast samlingsnavn';
	@override String get addedToCollection => 'Tilføjet til samling';
	@override String get errorAddingToCollection => 'Kunne ikke tilføje til samling';
	@override String get created => 'Samling oprettet';
	@override String get removeFromCollection => 'Fjern fra samling';
	@override String removeFromCollectionConfirm({required Object title}) => 'Fjern "${title}" fra denne samling?';
	@override String get removedFromCollection => 'Fjernet fra samling';
	@override String get removeFromCollectionFailed => 'Kunne ikke fjerne fra samling';
	@override String removeFromCollectionError({required Object error}) => 'Fejl ved fjernelse fra samling: ${error}';
	@override String get searchCollections => 'Søg i samlinger...';
}

// Path: playlists
class _TranslationsPlaylistsDa implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlister';
	@override String get playlist => 'Playliste';
	@override String get noPlaylists => 'Ingen playlister fundet';
	@override String get create => 'Opret playliste';
	@override String get playlistName => 'Playlistenavn';
	@override String get enterPlaylistName => 'Indtast playlistenavn';
	@override String get delete => 'Slet playliste';
	@override String get removeItem => 'Fjern fra playliste';
	@override String get smartPlaylist => 'Smart playliste';
	@override String itemCount({required Object count}) => '${count} elementer';
	@override String get oneItem => '1 element';
	@override String get emptyPlaylist => 'Denne playliste er tom';
	@override String get deleteConfirm => 'Slet playliste?';
	@override String deleteMessage({required Object name}) => 'Er du sikker på, at du vil slette "${name}"?';
	@override String get created => 'Playliste oprettet';
	@override String get deleted => 'Playliste slettet';
	@override String get itemAdded => 'Tilføjet til playliste';
	@override String get itemRemoved => 'Fjernet fra playliste';
	@override String get selectPlaylist => 'Vælg playliste';
	@override String get errorCreating => 'Kunne ikke oprette playliste';
	@override String get errorDeleting => 'Kunne ikke slette playliste';
	@override String get errorLoading => 'Kunne ikke indlæse playlister';
	@override String get errorAdding => 'Kunne ikke tilføje til playliste';
	@override String get errorReordering => 'Kunne ikke ændre rækkefølge på playlisteelement';
	@override String get errorRemoving => 'Kunne ikke fjerne fra playliste';
}

// Path: watchTogether
class _TranslationsWatchTogetherDa implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Se sammen';
	@override String get description => 'Se indhold synkroniseret med venner og familie';
	@override String get createSession => 'Opret session';
	@override String get creating => 'Opretter...';
	@override String get joinSession => 'Deltag i session';
	@override String get joining => 'Deltager...';
	@override String get controlMode => 'Kontroltilstand';
	@override String get controlModeQuestion => 'Hvem kan styre afspilning?';
	@override String get hostOnly => 'Kun vært';
	@override String get anyone => 'Alle';
	@override String get hostingSession => 'Vært for session';
	@override String get inSession => 'I session';
	@override String get sessionCode => 'Sessionskode';
	@override String get hostControlsPlayback => 'Vært styrer afspilning';
	@override String get anyoneCanControl => 'Alle kan styre afspilning';
	@override String get hostControls => 'Værtskontrol';
	@override String get anyoneControls => 'Alle styrer';
	@override String get participants => 'Deltagere';
	@override String get host => 'Vært';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Du er vært';
	@override String get watchingWithOthers => 'Ser med andre';
	@override String get endSession => 'Afslut session';
	@override String get leaveSession => 'Forlad session';
	@override String get endSessionQuestion => 'Afslut session?';
	@override String get leaveSessionQuestion => 'Forlad session?';
	@override String get endSessionConfirm => 'Dette afslutter sessionen for alle deltagere.';
	@override String get leaveSessionConfirm => 'Du vil blive fjernet fra sessionen.';
	@override String get endSessionConfirmOverlay => 'Dette afslutter se-sessionen for alle deltagere.';
	@override String get leaveSessionConfirmOverlay => 'Du vil blive afbrudt fra se-sessionen.';
	@override String get end => 'Afslut';
	@override String get leave => 'Forlad';
	@override String get syncing => 'Synkroniserer...';
	@override String get joinWatchSession => 'Deltag i se-session';
	@override String get enterCodeHint => 'Indtast 5-tegns kode';
	@override String get pasteFromClipboard => 'Indsæt fra udklipsholder';
	@override String get pleaseEnterCode => 'Indtast en sessionskode';
	@override String get codeMustBe5Chars => 'Sessionskode skal være 5 tegn';
	@override String get joinInstructions => 'Indtast sessionskoden delt af værten for at deltage i se-sessionen.';
	@override String get failedToCreate => 'Kunne ikke oprette session';
	@override String get failedToJoin => 'Kunne ikke deltage i session';
	@override String get sessionCodeCopied => 'Sessionskode kopieret til udklipsholder';
	@override String get relayUnreachable => 'Relay-serveren kan ikke nås. Dette kan skyldes, at din udbyder blokerer forbindelsen. Du kan stadig prøve, men Se sammen virker muligvis ikke.';
	@override String get reconnectingToHost => 'Genopretter forbindelse til vært...';
	@override String get currentPlayback => 'Nuværende afspilning';
	@override String get joinCurrentPlayback => 'Deltag i nuværende afspilning';
	@override String get joinCurrentPlaybackDescription => 'Hop tilbage til det værten ser nu';
	@override String get failedToOpenCurrentPlayback => 'Kunne ikke åbne nuværende afspilning';
	@override String participantJoined({required Object name}) => '${name} deltog';
	@override String participantLeft({required Object name}) => '${name} forlod';
	@override String participantPaused({required Object name}) => '${name} satte på pause';
	@override String participantResumed({required Object name}) => '${name} genoptog';
	@override String participantSeeked({required Object name}) => '${name} spoled';
	@override String participantBuffering({required Object name}) => '${name} bufferer';
	@override String get waitingForParticipants => 'Venter på at andre indlæser...';
	@override String get recentRooms => 'Seneste rum';
	@override String get renameRoom => 'Omdøb rum';
	@override String get removeRoom => 'Fjern';
}

// Path: downloads
class _TranslationsDownloadsDa implements TranslationsDownloadsEn {
	_TranslationsDownloadsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Administrer';
	@override String get tvShows => 'TV-serier';
	@override String get movies => 'Film';
	@override String get noDownloads => 'Ingen downloads endnu';
	@override String get noDownloadsDescription => 'Downloadet indhold vises her til offlinevisning';
	@override String get downloadNow => 'Download';
	@override String get deleteDownload => 'Slet download';
	@override String get retryDownload => 'Prøv download igen';
	@override String get downloadQueued => 'Download i kø';
	@override String get serverErrorBitrate => 'Serverfejl — filen overskrider muligvis grænsen for fjernstreaming-bitrate';
	@override String episodesQueued({required Object count}) => '${count} episoder i downloadkø';
	@override String get downloadDeleted => 'Download slettet';
	@override String deleteConfirm({required Object title}) => 'Er du sikker på, at du vil slette "${title}"? Den downloadede fil fjernes fra din enhed.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} af ${total})';
	@override String get noDownloadsTree => 'Ingen downloads';
	@override String get pauseAll => 'Pause alle';
	@override String get resumeAll => 'Genoptag alle';
	@override String get deleteAll => 'Slet alle';
	@override String get selectVersion => 'Vælg version';
	@override String get allEpisodes => 'Alle episoder';
	@override String get unwatchedOnly => 'Kun usete';
	@override String nextNUnwatched({required Object count}) => 'Næste ${count} usete';
	@override String get customAmount => 'Angiv antal...';
	@override String get howManyEpisodes => 'Hvor mange episoder?';
	@override String itemsQueued({required Object count}) => '${count} elementer sat i kø til download';
	@override String get keepSynced => 'Hold synkroniseret';
	@override String get downloadOnce => 'Download én gang';
	@override String keepNUnwatched({required Object count}) => 'Behold ${count} usete';
	@override String get editSyncRule => 'Rediger synkroniseringsregel';
	@override String get removeSyncRule => 'Fjern synkroniseringsregel';
	@override String removeSyncRuleConfirm({required Object title}) => 'Stop synkronisering af "${title}"? Downloadede episoder beholdes.';
	@override String syncRuleCreated({required Object count}) => 'Synkroniseringsregel oprettet — beholder ${count} usete episoder';
	@override String get syncRuleUpdated => 'Synkroniseringsregel opdateret';
	@override String get syncRuleRemoved => 'Synkroniseringsregel fjernet';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Synkroniserede ${count} nye episoder for ${title}';
	@override String get activeSyncRules => 'Synkroniseringsregler';
	@override String get noSyncRules => 'Ingen synkroniseringsregler';
	@override String get manageSyncRule => 'Administrer synkronisering';
	@override String get editEpisodeCount => 'Antal episoder';
	@override String get editSyncFilter => 'Synkroniseringsfilter';
	@override String get syncAllItems => 'Synkroniserer alle elementer';
	@override String get syncUnwatchedItems => 'Synkroniserer usete elementer';
	@override String get syncRuleListCreated => 'Synkroniseringsregel oprettet';
}

// Path: shaders
class _TranslationsShadersDa implements TranslationsShadersEn {
	_TranslationsShadersDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadere';
	@override String get noShaderDescription => 'Ingen videoforbedring';
	@override String get nvscalerDescription => 'NVIDIA-billedskalering for skarpere video';
	@override String get qualityFast => 'Hurtig';
	@override String get qualityHQ => 'Høj kvalitet';
	@override String get mode => 'Tilstand';
	@override String get importShader => 'Importér shader';
	@override String get customShaderDescription => 'Brugerdefineret GLSL-shader';
	@override String get shaderImported => 'Shader importeret';
	@override String get shaderImportFailed => 'Kunne ikke importere shader';
	@override String get deleteShader => 'Slet shader';
	@override String deleteShaderConfirm({required Object name}) => 'Slet "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteDa implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fjernbetjening';
	@override String connectedTo({required Object name}) => 'Forbundet til ${name}';
	@override late final _TranslationsCompanionRemoteSessionDa session = _TranslationsCompanionRemoteSessionDa._(_root);
	@override late final _TranslationsCompanionRemotePairingDa pairing = _TranslationsCompanionRemotePairingDa._(_root);
	@override late final _TranslationsCompanionRemoteRemoteDa remote = _TranslationsCompanionRemoteRemoteDa._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsDa implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Afspilningsindstillinger';
	@override String get playbackSpeed => 'Afspilningshastighed';
	@override String get sleepTimer => 'Sove-timer';
	@override String get audioSync => 'Lydsynkronisering';
	@override String get subtitleSync => 'Undertekstsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Lydoutput';
	@override String get performanceOverlay => 'Ydelsesoverlay';
	@override String get audioPassthrough => 'Lyd-passthrough';
	@override String get audioNormalization => 'Normalisér lydstyrke';
}

// Path: externalPlayer
class _TranslationsExternalPlayerDa implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ekstern afspiller';
	@override String get useExternalPlayer => 'Brug ekstern afspiller';
	@override String get useExternalPlayerDescription => 'Åbn videoer i en ekstern app i stedet for den indbyggede afspiller';
	@override String get selectPlayer => 'Vælg afspiller';
	@override String get customPlayers => 'Brugerdefinerede afspillere';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Tilføj brugerdefineret afspiller';
	@override String get playerName => 'Afspillernavn';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Pakkenavn';
	@override String get playerUrlScheme => 'URL-skema';
	@override String get off => 'Fra';
	@override String get launchFailed => 'Kunne ikke åbne ekstern afspiller';
	@override String appNotInstalled({required Object name}) => '${name} er ikke installeret';
	@override String get playInExternalPlayer => 'Afspil i ekstern afspiller';
}

// Path: metadataEdit
class _TranslationsMetadataEditDa implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Redigér...';
	@override String get screenTitle => 'Redigér metadata';
	@override String get basicInfo => 'Grundlæggende info';
	@override String get artwork => 'Grafik';
	@override String get advancedSettings => 'Avancerede indstillinger';
	@override String get title => 'Titel';
	@override String get sortTitle => 'Sorteringstitel';
	@override String get originalTitle => 'Originaltitel';
	@override String get releaseDate => 'Udgivelsesdato';
	@override String get contentRating => 'Aldersgrænse';
	@override String get studio => 'Studie';
	@override String get tagline => 'Tagline';
	@override String get summary => 'Resumé';
	@override String get poster => 'Plakat';
	@override String get background => 'Baggrund';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Kvadratisk billede';
	@override String get selectPoster => 'Vælg plakat';
	@override String get selectBackground => 'Vælg baggrund';
	@override String get selectLogo => 'Vælg logo';
	@override String get selectSquareArt => 'Vælg kvadratisk billede';
	@override String get fromUrl => 'Fra URL';
	@override String get uploadFile => 'Upload fil';
	@override String get enterImageUrl => 'Indtast billed-URL';
	@override String get imageUrl => 'Billed-URL';
	@override String get metadataUpdated => 'Metadata opdateret';
	@override String get metadataUpdateFailed => 'Kunne ikke opdatere metadata';
	@override String get artworkUpdated => 'Grafik opdateret';
	@override String get artworkUpdateFailed => 'Kunne ikke opdatere grafik';
	@override String get noArtworkAvailable => 'Ingen grafik tilgængelig';
	@override String get notSet => 'Ikke indstillet';
	@override String get libraryDefault => 'Biblioteksstandard';
	@override String get accountDefault => 'Kontostandard';
	@override String get seriesDefault => 'Seriestandard';
	@override String get episodeSorting => 'Episodesortering';
	@override String get oldestFirst => 'Ældste først';
	@override String get newestFirst => 'Nyeste først';
	@override String get keep => 'Behold';
	@override String get allEpisodes => 'Alle episoder';
	@override String latestEpisodes({required Object count}) => '${count} seneste episoder';
	@override String get latestEpisode => 'Seneste episode';
	@override String episodesAddedPastDays({required Object count}) => 'Episoder tilføjet de seneste ${count} dage';
	@override String get deleteAfterPlaying => 'Slet episoder efter afspilning';
	@override String get never => 'Aldrig';
	@override String get afterADay => 'Efter en dag';
	@override String get afterAWeek => 'Efter en uge';
	@override String get afterAMonth => 'Efter en måned';
	@override String get onNextRefresh => 'Ved næste opdatering';
	@override String get seasons => 'Sæsoner';
	@override String get show => 'Vis';
	@override String get hide => 'Skjul';
	@override String get episodeOrdering => 'Episoderækkefølge';
	@override String get tmdbAiring => 'The Movie Database (Sendt)';
	@override String get tvdbAiring => 'TheTVDB (Sendt)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolut)';
	@override String get metadataLanguage => 'Metadatasprog';
	@override String get useOriginalTitle => 'Brug originaltitel';
	@override String get preferredAudioLanguage => 'Foretrukket lydsprog';
	@override String get preferredSubtitleLanguage => 'Foretrukket undertekstsprog';
	@override String get subtitleMode => 'Auto-vælg underteksttilstand';
	@override String get manuallySelected => 'Manuelt valgt';
	@override String get shownWithForeignAudio => 'Vist med fremmedsproget lyd';
	@override String get alwaysEnabled => 'Altid aktiveret';
	@override String get tags => 'Tags';
	@override String get addTag => 'Tilføj tag';
	@override String get genre => 'Genre';
	@override String get director => 'Instruktør';
	@override String get writer => 'Forfatter';
	@override String get producer => 'Producer';
	@override String get country => 'Land';
	@override String get collection => 'Samling';
	@override String get label => 'Etiket';
	@override String get style => 'Stil';
	@override String get mood => 'Stemning';
}

// Path: matchScreen
class _TranslationsMatchScreenDa implements TranslationsMatchScreenEn {
	_TranslationsMatchScreenDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get match => 'Match...';
	@override String get fixMatch => 'Ret match...';
	@override String get unmatch => 'Fjern match';
	@override String get unmatchConfirm => 'Ryd det aktuelle match for dette element? Plex behandler det som ikke matchet, indtil du matcher det igen.';
	@override String get unmatchSuccess => 'Match fjernet';
	@override String get unmatchFailed => 'Kunne ikke fjerne match';
	@override String get matchApplied => 'Match anvendt';
	@override String get matchFailed => 'Kunne ikke anvende match';
	@override String get titleHint => 'Titel';
	@override String get yearHint => 'År';
	@override String get search => 'Søg';
	@override String get noMatchesFound => 'Ingen match fundet';
}

// Path: serverTasks
class _TranslationsServerTasksDa implements TranslationsServerTasksEn {
	_TranslationsServerTasksDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveropgaver';
	@override String get failedToLoad => 'Kunne ikke indlæse opgaver';
	@override String get noTasks => 'Ingen opgaver kører';
}

// Path: trakt
class _TranslationsTraktDa implements TranslationsTraktEn {
	_TranslationsTraktDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Forbundet';
	@override String connectedAs({required Object username}) => 'Forbundet som @${username}';
	@override String get disconnectConfirm => 'Frakobl Trakt-konto?';
	@override String get disconnectConfirmBody => 'Plezy stopper med at sende afspilningsbegivenheder til Trakt. Du kan genoprette forbindelse når som helst.';
	@override String get scrobble => 'Realtids-scrobbling';
	@override String get scrobbleDescription => 'Send afspil-, pause- og stop-begivenheder til Trakt under afspilning.';
	@override String get watchedSync => 'Synkroniser sét-status';
	@override String get watchedSyncDescription => 'Når du markerer ting som sét i Plezy, markeres de også på Trakt.';
	@override String get connectFailed => 'Kunne ikke forbinde til Trakt. Prøv igen.';
}

// Path: trackers
class _TranslationsTrackersDa implements TranslationsTrackersEn {
	_TranslationsTrackersDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trackere';
	@override String get hubSubtitle => 'Hold din visningsfremgang synkroniseret med Trakt og andre tjenester.';
	@override String get notConnected => 'Ikke forbundet';
	@override String connectedAs({required Object username}) => 'Forbundet som @${username}';
	@override String get scrobble => 'Registrer fremgang automatisk';
	@override String get scrobbleDescription => 'Opdater din liste når du er færdig med et afsnit eller en film.';
	@override String disconnectConfirm({required Object service}) => 'Afbryd ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy stopper med at opdatere din ${service}-liste. Du kan forbinde igen når som helst.';
	@override String connectFailed({required Object service}) => 'Kunne ikke forbinde til ${service}. Prøv igen.';
	@override late final _TranslationsTrackersServicesDa services = _TranslationsTrackersServicesDa._(_root);
	@override late final _TranslationsTrackersDeviceCodeDa deviceCode = _TranslationsTrackersDeviceCodeDa._(_root);
	@override late final _TranslationsTrackersOauthProxyDa oauthProxy = _TranslationsTrackersOauthProxyDa._(_root);
	@override late final _TranslationsTrackersLibraryFilterDa libraryFilter = _TranslationsTrackersLibraryFilterDa._(_root);
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsDa implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Afspil/Pause';
	@override String get volumeUp => 'Lydstyrke op';
	@override String get volumeDown => 'Lydstyrke ned';
	@override String seekForward({required Object seconds}) => 'Spol frem (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Spol tilbage (${seconds}s)';
	@override String get fullscreenToggle => 'Skift fuldskærm';
	@override String get muteToggle => 'Skift lydløs';
	@override String get subtitleToggle => 'Skift undertekster';
	@override String get audioTrackNext => 'Næste lydspor';
	@override String get subtitleTrackNext => 'Næste undertekstspor';
	@override String get chapterNext => 'Næste kapitel';
	@override String get chapterPrevious => 'Forrige kapitel';
	@override String get episodeNext => 'Næste afsnit';
	@override String get episodePrevious => 'Forrige afsnit';
	@override String get speedIncrease => 'Øg hastighed';
	@override String get speedDecrease => 'Sænk hastighed';
	@override String get speedReset => 'Nulstil hastighed';
	@override String get subSeekNext => 'Søg til næste undertekst';
	@override String get subSeekPrev => 'Søg til forrige undertekst';
	@override String get shaderToggle => 'Skift shadere';
	@override String get skipMarker => 'Spring intro/rulletekster over';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsDa implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Kræver Android 8.0 eller nyere';
	@override String get iosVersion => 'Kræver iOS 15.0 eller nyere';
	@override String get permissionDisabled => 'Billede-i-billede-tilladelse er deaktiveret. Aktivér i Indstillinger > Apps > Plezy > Billede-i-billede';
	@override String get notSupported => 'Enheden understøtter ikke billede-i-billede';
	@override String get voSwitchFailed => 'Kunne ikke skifte videooutput til billede-i-billede';
	@override String get failed => 'Billede-i-billede kunne ikke starte';
	@override String unknown({required Object error}) => 'Der opstod en fejl: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsDa implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Anbefalet';
	@override String get browse => 'Gennemse';
	@override String get collections => 'Samlinger';
	@override String get playlists => 'Playlister';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsDa implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppering';
	@override String get all => 'Alle';
	@override String get movies => 'Film';
	@override String get shows => 'TV-serier';
	@override String get seasons => 'Sæsoner';
	@override String get episodes => 'Episoder';
	@override String get folders => 'Mapper';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionDa implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Starter fjernserver...';
	@override String get failedToCreate => 'Kunne ikke starte fjernserver:';
	@override String get hostAddress => 'Værtsadresse';
	@override String get connected => 'Forbundet';
	@override String get serverRunning => 'Fjernserver aktiv';
	@override String get serverStopped => 'Fjernserver stoppet';
	@override String get serverRunningDescription => 'Mobilenheder på dit netværk kan finde og oprette forbindelse til denne app';
	@override String get serverStoppedDescription => 'Start serveren for at tillade mobilenheder at oprette forbindelse';
	@override String get usePhoneToControl => 'Brug din mobilenhed til at styre denne app';
	@override String get startServer => 'Start server';
	@override String get stopServer => 'Stop server';
	@override String get minimize => 'Minimér';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingDa implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Enheder på dit netværk, der kører Plezy med den samme Plex-konto, vises automatisk';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Opretter forbindelse...';
	@override String get searchingForDevices => 'Søger efter enheder...';
	@override String get noDevicesFound => 'Ingen enheder fundet på dit netværk';
	@override String get noDevicesHint => 'Sørg for, at Plezy er åben på din computer, og at begge enheder er på det samme WiFi-netværk';
	@override String get availableDevices => 'Tilgængelige enheder';
	@override String get manualConnection => 'Manuel forbindelse';
	@override String get cryptoInitFailed => 'Kunne ikke initialisere sikker forbindelse. Sørg for, at du er logget ind på en Plex-konto.';
	@override String get validationHostRequired => 'Angiv venligst værtsadresse';
	@override String get validationHostFormat => 'Format skal være IP:port (f.eks. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Forbindelsen udløb. Sørg for, at begge enheder er på det samme netværk.';
	@override String get sessionNotFound => 'Kunne ikke finde enheden. Sørg for, at Plezy kører på værten.';
	@override String get authFailed => 'Godkendelse mislykkedes. Sørg for, at begge enheder bruger den samme Plex-konto.';
	@override String failedToConnect({required Object error}) => 'Kunne ikke oprette forbindelse: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteDa implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vil du afbryde fra fjernsessionen?';
	@override String get reconnecting => 'Genopretter forbindelse...';
	@override String attemptOf({required Object current}) => 'Forsøg ${current} af 5';
	@override String get retryNow => 'Prøv igen nu';
	@override String get tabRemote => 'Fjernbetjening';
	@override String get tabPlay => 'Afspil';
	@override String get tabMore => 'Mere';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Fanenavigation';
	@override String get tabDiscover => 'Opdag';
	@override String get tabLibraries => 'Biblioteker';
	@override String get tabSearch => 'Søg';
	@override String get tabDownloads => 'Downloads';
	@override String get tabSettings => 'Indstillinger';
	@override String get previous => 'Forrige';
	@override String get playPause => 'Afspil/Pause';
	@override String get next => 'Næste';
	@override String get seekBack => 'Spol tilbage';
	@override String get stop => 'Stop';
	@override String get seekForward => 'Spol frem';
	@override String get volume => 'Lydstyrke';
	@override String get volumeDown => 'Ned';
	@override String get volumeUp => 'Op';
	@override String get fullscreen => 'Fuldskærm';
	@override String get subtitles => 'Undertekster';
	@override String get audio => 'Lyd';
	@override String get searchHint => 'Søg på desktop...';
}

// Path: trackers.services
class _TranslationsTrackersServicesDa implements TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeDa implements TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktiver Plezy på ${service}';
	@override String body({required Object url}) => 'Besøg ${url} og indtast denne kode:';
	@override String openToActivate({required Object service}) => 'Åbn ${service} for at aktivere';
	@override String get waitingForAuthorization => 'Venter på godkendelse…';
	@override String get codeCopied => 'Kode kopieret';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyDa implements TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Log ind på ${service}';
	@override String get body => 'Scan denne QR-kode med din telefon, eller åbn URL\'en nedenfor på en enhed med browser.';
	@override String openToSignIn({required Object service}) => 'Åbn ${service} for at logge ind';
	@override String get urlCopied => 'URL kopieret';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterDa implements TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterDa._(this._root);

	final TranslationsDa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotekfilter';
	@override String get subtitleAllSyncing => 'Synkroniserer alle biblioteker';
	@override String get subtitleNoneSyncing => 'Intet synkroniseres';
	@override String subtitleBlocked({required Object count}) => '${count} blokeret';
	@override String subtitleAllowed({required Object count}) => '${count} tilladt';
	@override String get mode => 'Filtertilstand';
	@override String get modeBlacklist => 'Sortliste';
	@override String get modeWhitelist => 'Hvidliste';
	@override String get modeHintBlacklist => 'Synkroniser alle biblioteker undtagen dem du markerer nedenfor.';
	@override String get modeHintWhitelist => 'Synkroniser kun de biblioteker du markerer nedenfor.';
	@override String get libraries => 'Biblioteker';
	@override String get noLibraries => 'Ingen biblioteker tilgængelige';
}

/// The flat map containing all translations for locale <da>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Log ind med Plex',
			'auth.showQRCode' => 'Vis QR-kode',
			'auth.authenticate' => 'Godkend',
			'auth.authenticationTimeout' => 'Godkendelse fik timeout. Prøv igen.',
			'auth.scanQRToSignIn' => 'Scan denne QR-kode for at logge ind',
			'auth.waitingForAuth' => 'Venter på godkendelse...\nFærdiggør login i din browser.',
			'auth.useBrowser' => 'Brug browser',
			'common.cancel' => 'Annuller',
			'common.save' => 'Gem',
			'common.close' => 'Luk',
			'common.clear' => 'Ryd',
			'common.reset' => 'Nulstil',
			'common.later' => 'Senere',
			'common.submit' => 'Indsend',
			'common.confirm' => 'Bekræft',
			'common.retry' => 'Prøv igen',
			'common.logout' => 'Log ud',
			'common.unknown' => 'Ukendt',
			'common.refresh' => 'Opdater',
			'common.yes' => 'Ja',
			'common.no' => 'Nej',
			'common.delete' => 'Slet',
			'common.shuffle' => 'Bland',
			'common.addTo' => 'Tilføj til...',
			'common.createNew' => 'Opret ny',
			'common.connect' => 'Forbind',
			'common.disconnect' => 'Afbryd',
			'common.play' => 'Afspil',
			'common.pause' => 'Pause',
			'common.resume' => 'Genoptag',
			'common.error' => 'Fejl',
			'common.search' => 'Søg',
			'common.home' => 'Hjem',
			'common.back' => 'Tilbage',
			'common.settings' => 'Indstillinger',
			'common.mute' => 'Lydløs',
			'common.ok' => 'OK',
			'common.reconnect' => 'Genopret forbindelse',
			'common.exitConfirmTitle' => 'Luk app?',
			'common.exitConfirmMessage' => 'Er du sikker på, at du vil afslutte?',
			'common.dontAskAgain' => 'Spørg ikke igen',
			'common.exit' => 'Afslut',
			'common.viewAll' => 'Vis alle',
			'common.checkingNetwork' => 'Tjekker netværk...',
			'common.refreshingServers' => 'Opdaterer servere...',
			'common.loadingServers' => 'Indlæser servere...',
			'common.connectingToServers' => 'Forbinder til servere...',
			'common.startingOfflineMode' => 'Starter offlinetilstand...',
			'common.loading' => 'Indlæser...',
			'common.fullscreen' => 'Fuldskærm',
			'common.exitFullscreen' => 'Forlad fuldskærm',
			'screens.licenses' => 'Licenser',
			'screens.switchProfile' => 'Skift profil',
			'screens.subtitleStyling' => 'Undertekststil',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Opdatering tilgængelig',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} er tilgængelig',
			'update.currentVersion' => ({required Object version}) => 'Nuværende: ${version}',
			'update.skipVersion' => 'Spring denne version over',
			'update.viewRelease' => 'Vis udgivelse',
			'update.latestVersion' => 'Du har den nyeste version',
			'update.checkFailed' => 'Kunne ikke søge efter opdateringer',
			'settings.title' => 'Indstillinger',
			'settings.supportDeveloper' => 'Støt Plezy',
			'settings.supportDeveloperDescription' => 'Doner via Liberapay for at finansiere udviklingen',
			'settings.language' => 'Sprog',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Udseende',
			'settings.videoPlayback' => 'Videoafspilning',
			'settings.videoPlaybackDescription' => 'Konfigurer afspilningsadfærd',
			'settings.advanced' => 'Avanceret',
			'settings.episodePosterMode' => 'Episodeplakatstil',
			'settings.seriesPoster' => 'Serieplakat',
			'settings.seasonPoster' => 'Sæsonplakat',
			'settings.episodeThumbnail' => 'Miniature',
			'settings.showHeroSectionDescription' => 'Vis karrusel med udvalgt indhold på startskærmen',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minutter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Indtast varighed (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Lys',
			'settings.darkTheme' => 'Mørk',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Bibliotekstæthed',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Komfortabel',
			'settings.viewMode' => 'Visningstilstand',
			'settings.gridView' => 'Gitter',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Vis hero-sektion',
			'settings.useGlobalHubs' => 'Brug Plex Home-layout',
			'settings.useGlobalHubsDescription' => 'Vis startsidehubbe som den officielle Plex-klient. Når slået fra, vises anbefalinger per bibliotek.',
			'settings.showServerNameOnHubs' => 'Vis servernavn på hubbe',
			'settings.showServerNameOnHubsDescription' => 'Vis altid servernavnet i hubtitler. Når slået fra, vises kun ved duplikerede navne.',
			'settings.alwaysKeepSidebarOpen' => 'Hold altid sidepanelet åbent',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidepanelet forbliver udvidet, og indholdsområdet tilpasser sig',
			'settings.showUnwatchedCount' => 'Vis antal usete',
			'settings.showUnwatchedCountDescription' => 'Vis antal usete episoder på serier og sæsoner',
			'settings.showEpisodeNumberOnCards' => 'Vis episodenummer på kort',
			'settings.showEpisodeNumberOnCardsDescription' => 'Vis episodenummer ved siden af sæsonen (f.eks. S2 E3) på episodekort',
			'settings.hideSpoilers' => 'Skjul spoilere for usete episoder',
			'settings.hideSpoilersDescription' => 'Slør miniaturebilleder og skjul beskrivelser for episoder, du ikke har set endnu',
			'settings.playerBackend' => 'Afspillerbackend',
			'settings.exoPlayer' => 'ExoPlayer (Anbefalet)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Hardwaredekodning',
			'settings.hardwareDecodingDescription' => 'Brug hardwareacceleration når tilgængelig',
			'settings.bufferSize' => 'Bufferstørrelse',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Anbefalet)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Din enhed har ${heap}MB hukommelse. En buffer på ${size}MB kan forårsage afspilningsproblemer.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.defaultQualityDescription' => 'Bruges ved start af afspilning. Lavere værdier reducerer båndbredden.',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpas underteksters udseende',
			'settings.smallSkipDuration' => 'Kort spring-varighed',
			'settings.largeSkipDuration' => 'Lang spring-varighed',
			'settings.rewindOnResume' => 'Spol tilbage ved genoptagelse',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard sove-timer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutter',
			'settings.rememberTrackSelections' => 'Husk sporvalg per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Gem automatisk lyd- og undertekstsprogpræferencer når du skifter spor under afspilning',
			'settings.clickVideoTogglesPlayback' => 'Klik på video skifter afspil/pause',
			'settings.clickVideoTogglesPlaybackDescription' => 'Når aktiveret, afspiller/pauser klik på videoen. Ellers vises/skjules betjeningselementer.',
			'settings.videoPlayerControls' => 'Videoafspillerkontroller',
			'settings.keyboardShortcuts' => 'Tastaturgenveje',
			'settings.keyboardShortcutsDescription' => 'Tilpas tastaturgenveje',
			'settings.videoPlayerNavigation' => 'Videoafspillernavigation',
			'settings.videoPlayerNavigationDescription' => 'Brug piletaster til at navigere videoafspillerkontroller',
			'settings.watchTogetherRelay' => 'Watch Together-relay',
			'settings.watchTogetherRelayDescription' => 'Angiv en brugerdefineret relay-server til Watch Together. Alle deltagere skal bruge den samme server.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.eksempel.dk',
			'settings.crashReporting' => 'Fejlrapportering',
			'settings.crashReportingDescription' => 'Send fejlrapporter for at hjælpe med at forbedre appen',
			'settings.debugLogging' => 'Fejlfindingslogning',
			'settings.debugLoggingDescription' => 'Aktiver detaljeret logning til fejlfinding',
			'settings.viewLogs' => 'Vis logs',
			'settings.viewLogsDescription' => 'Vis applikationslogs',
			'settings.clearCache' => 'Ryd cache',
			'settings.clearCacheDescription' => 'Dette rydder alle cachelagrede billeder og data. Appen kan tage længere tid om at indlæse indhold efter rydning.',
			'settings.clearCacheSuccess' => 'Cache ryddet',
			'settings.resetSettings' => 'Nulstil indstillinger',
			'settings.resetSettingsDescription' => 'Alle indstillinger nulstilles til standardværdier. Denne handling kan ikke fortrydes.',
			'settings.resetSettingsSuccess' => 'Indstillinger nulstillet',
			'settings.backup' => 'Sikkerhedskopi',
			'settings.exportSettings' => 'Eksportér indstillinger',
			'settings.exportSettingsDescription' => 'Gem dine præferencer i en fil',
			'settings.exportSettingsSuccess' => 'Indstillinger eksporteret',
			'settings.exportSettingsFailed' => 'Kunne ikke eksportere indstillinger',
			'settings.importSettings' => 'Importér indstillinger',
			'settings.importSettingsDescription' => 'Gendan præferencer fra en fil',
			'settings.importSettingsConfirm' => 'Dette vil erstatte dine nuværende indstillinger. Fortsæt?',
			'settings.importSettingsSuccess' => 'Indstillinger importeret',
			'settings.importSettingsFailed' => 'Kunne ikke importere indstillinger',
			'settings.importSettingsInvalidFile' => 'Denne fil er ikke en gyldig Plezy-indstillingseksport',
			'settings.importSettingsNoUser' => 'Log ind før import af indstillinger',
			'settings.shortcutsReset' => 'Genveje nulstillet til standard',
			'settings.about' => 'Om',
			'settings.aboutDescription' => 'App-information og licenser',
			'settings.updates' => 'Opdateringer',
			'settings.updateAvailable' => 'Opdatering tilgængelig',
			'settings.checkForUpdates' => 'Søg efter opdateringer',
			'settings.autoCheckUpdatesOnStartup' => 'Søg automatisk efter opdateringer ved opstart',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Vis en notifikation, når en ny version er tilgængelig ved opstart',
			'settings.validationErrorEnterNumber' => 'Indtast et gyldigt tal',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Varighed skal være mellem ${min} og ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Genvej allerede tildelt til ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Genvej opdateret for ${action}',
			'settings.autoSkip' => 'Auto-spring',
			'settings.autoSkipIntro' => 'Auto-spring intro',
			'settings.autoSkipIntroDescription' => 'Spring automatisk intromarkører over efter få sekunder',
			'settings.autoSkipCredits' => 'Auto-spring rulletekster',
			'settings.autoSkipCreditsDescription' => 'Spring automatisk rulletekster over og afspil næste episode',
			'settings.autoSkipDelay' => 'Auto-spring forsinkelse',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk spring',
			'settings.introPattern' => 'Intromarkørmønster',
			'settings.introPatternDescription' => 'Regulært udtryk til at genkende intromarkører i kapiteltitler',
			'settings.creditsPattern' => 'Rulletekstmarkørmønster',
			'settings.creditsPatternDescription' => 'Regulært udtryk til at genkende rulletekstmarkører i kapiteltitler',
			'settings.invalidRegex' => 'Ugyldigt regulært udtryk',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Vælg hvor downloadet indhold skal gemmes',
			'settings.downloadLocationDefault' => 'Standard (App-lagring)',
			'settings.downloadLocationCustom' => 'Brugerdefineret placering',
			'settings.selectFolder' => 'Vælg mappe',
			'settings.resetToDefault' => 'Nulstil til standard',
			'settings.currentPath' => ({required Object path}) => 'Nuværende: ${path}',
			'settings.downloadLocationChanged' => 'Downloadplacering ændret',
			'settings.downloadLocationReset' => 'Downloadplacering nulstillet',
			'settings.downloadLocationInvalid' => 'Valgt mappe er ikke skrivbar',
			'settings.downloadLocationSelectError' => 'Kunne ikke vælge mappe',
			'settings.downloadOnWifiOnly' => 'Download kun på WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Forhindre downloads på mobildata',
			'settings.autoRemoveWatchedDownloads' => 'Fjern sete downloads automatisk',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Slet automatisk downloadede episoder og film, når de markeres som set',
			'settings.cellularDownloadBlocked' => 'Downloads er deaktiveret på mobildata. Opret forbindelse til WiFi eller ændr indstillingen.',
			'settings.maxVolume' => 'Maksimal lydstyrke',
			'settings.maxVolumeDescription' => 'Tillad lydstyrkeforstærkning over 100% for stille medier',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Vis hvad du ser på Discord',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Synkroniser visningshistorik med Trakt',
			'settings.trackers' => 'Trackere',
			'settings.trackersDescription' => 'Synkroniser fremgang til Trakt, MyAnimeList, AniList og Simkl',
			'settings.companionRemoteServer' => 'Companion Remote Server',
			'settings.companionRemoteServerDescription' => 'Tillad mobilenheder på dit netværk at styre denne app',
			'settings.autoPip' => 'Auto billede-i-billede',
			'settings.autoPipDescription' => 'Gå automatisk til billede-i-billede når du forlader appen under afspilning',
			'settings.matchContentFrameRate' => 'Match indholdets billedhastighed',
			'settings.matchContentFrameRateDescription' => 'Juster skærmens opdateringshastighed til videoindhold for at reducere hakken og spare batteri',
			'settings.matchRefreshRate' => 'Match opdateringshastighed',
			'settings.matchRefreshRateDescription' => 'Skift skærmens opdateringshastighed til at matche videoindhold i fuldskærm',
			'settings.matchDynamicRange' => 'Match dynamisk område',
			'settings.matchDynamicRangeDescription' => 'Aktiver automatisk HDR for HDR-indhold og gendan SDR når afspilleren lukkes',
			'settings.displaySwitchDelay' => 'Forsinkelse ved skærmskift',
			'settings.tunneledPlayback' => 'Tunneleret afspilning',
			'settings.tunneledPlaybackDescription' => 'Brug hardwareaccelereret videotunneling. Deaktiver hvis du ser sort skærm med lyd på HDR-indhold',
			'settings.requireProfileSelectionOnOpen' => 'Spørg om profil ved åbning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åbnes',
			'settings.confirmExitOnBack' => 'Bekræft før lukning',
			'settings.confirmExitOnBackDescription' => 'Vis bekræftelsesdialog ved tryk på tilbage for at lukke appen',
			'settings.forceTvMode' => 'Gennemtving TV-tilstand',
			'settings.forceTvModeDescription' => 'Brug TV-layoutet uanset automatisk registrering. Nyttigt på Android TV-enheder, der ikke rapporterer leanback-funktionen. Genstarter appen ved ændring.',
			'settings.autoHidePerformanceOverlay' => 'Skjul ydelses-overlay automatisk',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade ydelses-overlayet med afspilningskontrollerne',
			'settings.showNavBarLabels' => 'Vis navigationsbarlabels',
			'settings.showNavBarLabelsDescription' => 'Vis tekstlabels under navigationsbarikoner',
			'settings.liveTvDefaultFavorites' => 'Standard til favoritkanaler',
			'settings.liveTvDefaultFavoritesDescription' => 'Vis kun favoritkanaler ved åbning af Live TV',
			'settings.display' => 'Display',
			'settings.homeScreen' => 'Home Screen',
			'settings.navigation' => 'Navigation',
			'settings.content' => 'Content',
			'settings.player' => 'Player',
			'settings.subtitlesAndConfig' => 'Subtitles & Configuration',
			'settings.seekAndTiming' => 'Seek & Timing',
			'settings.behavior' => 'Behavior',
			'search.hint' => 'Søg film, serier, musik...',
			'search.tryDifferentTerm' => 'Prøv en anden søgning',
			'search.searchYourMedia' => 'Søg i dine medier',
			'search.enterTitleActorOrKeyword' => 'Indtast titel, skuespiller eller nøgleord',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Indstil genvej for ${actionName}',
			'hotkeys.clearShortcut' => 'Ryd genvej',
			'hotkeys.actions.playPause' => 'Afspil/Pause',
			'hotkeys.actions.volumeUp' => 'Lydstyrke op',
			'hotkeys.actions.volumeDown' => 'Lydstyrke ned',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Spol frem (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Spol tilbage (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Skift fuldskærm',
			'hotkeys.actions.muteToggle' => 'Skift lydløs',
			'hotkeys.actions.subtitleToggle' => 'Skift undertekster',
			'hotkeys.actions.audioTrackNext' => 'Næste lydspor',
			'hotkeys.actions.subtitleTrackNext' => 'Næste undertekstspor',
			'hotkeys.actions.chapterNext' => 'Næste kapitel',
			'hotkeys.actions.chapterPrevious' => 'Forrige kapitel',
			'hotkeys.actions.episodeNext' => 'Næste afsnit',
			'hotkeys.actions.episodePrevious' => 'Forrige afsnit',
			'hotkeys.actions.speedIncrease' => 'Øg hastighed',
			'hotkeys.actions.speedDecrease' => 'Sænk hastighed',
			'hotkeys.actions.speedReset' => 'Nulstil hastighed',
			'hotkeys.actions.subSeekNext' => 'Søg til næste undertekst',
			'hotkeys.actions.subSeekPrev' => 'Søg til forrige undertekst',
			'hotkeys.actions.shaderToggle' => 'Skift shadere',
			'hotkeys.actions.skipMarker' => 'Spring intro/rulletekster over',
			'fileInfo.title' => 'Filinfo',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Lyd',
			'fileInfo.file' => 'Fil',
			'fileInfo.advanced' => 'Avanceret',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Opløsning',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Billedhastighed',
			'fileInfo.aspectRatio' => 'Billedformat',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Bitdybde',
			'fileInfo.colorSpace' => 'Farverum',
			'fileInfo.colorRange' => 'Farveområde',
			'fileInfo.colorPrimaries' => 'Farveprimærer',
			'fileInfo.chromaSubsampling' => 'Chroma-subsampling',
			'fileInfo.channels' => 'Kanaler',
			'fileInfo.subtitles' => 'Undertekster',
			'fileInfo.overallBitrate' => 'Samlet bitrate',
			'fileInfo.path' => 'Sti',
			'fileInfo.size' => 'Størrelse',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Varighed',
			'fileInfo.optimizedForStreaming' => 'Optimeret til streaming',
			'fileInfo.has64bitOffsets' => '64-bit offsets',
			'mediaMenu.markAsWatched' => 'Markér som set',
			'mediaMenu.markAsUnwatched' => 'Markér som uset',
			'mediaMenu.removeFromContinueWatching' => 'Fjern fra Fortsæt med at se',
			'mediaMenu.goToSeries' => 'Gå til serie',
			'mediaMenu.goToSeason' => 'Gå til sæson',
			'mediaMenu.shufflePlay' => 'Afspil tilfældigt',
			'mediaMenu.fileInfo' => 'Filinfo',
			'mediaMenu.deleteFromServer' => 'Slet fra server',
			'mediaMenu.confirmDelete' => 'Dette sletter permanent disse medier og filer fra din server. Dette kan ikke fortrydes.',
			'mediaMenu.deleteMultipleWarning' => 'Dette inkluderer alle episoder og deres filer.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medieelement slettet',
			'mediaMenu.mediaFailedToDelete' => 'Kunne ikke slette medieelement',
			'mediaMenu.rate' => 'Bedøm',
			'mediaMenu.playFromBeginning' => 'Afspil fra begyndelsen',
			'mediaMenu.playVersion' => 'Afspil version...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'set',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} procent set',
			'accessibility.mediaCardUnwatched' => 'uset',
			'accessibility.tapToPlay' => 'Tryk for at afspille',
			'tooltips.shufflePlay' => 'Afspil tilfældigt',
			'tooltips.playTrailer' => 'Afspil trailer',
			'tooltips.markAsWatched' => 'Markér som set',
			'tooltips.markAsUnwatched' => 'Markér som uset',
			'videoControls.audioLabel' => 'Lyd',
			'videoControls.subtitlesLabel' => 'Undertekster',
			'videoControls.resetToZero' => 'Nulstil til 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} afspilles senere',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} afspilles tidligere',
			'videoControls.noOffset' => 'Ingen forskydning',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fyld skærm',
			'videoControls.stretch' => 'Stræk',
			'videoControls.lockRotation' => 'Lås rotation',
			'videoControls.unlockRotation' => 'Lås rotation op',
			'videoControls.timerActive' => 'Timer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Afspilning pauses om ${duration}',
			'videoControls.stillWatching' => 'Ser du stadig?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauser om ${seconds}s',
			'videoControls.continueWatching' => 'Fortsæt',
			'videoControls.autoPlayNext' => 'Auto-afspil næste',
			'videoControls.playNext' => 'Afspil næste',
			'videoControls.playButton' => 'Afspil',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Spol ${seconds} sekunder tilbage',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Spol ${seconds} sekunder frem',
			'videoControls.previousButton' => 'Forrige episode',
			'videoControls.nextButton' => 'Næste episode',
			'videoControls.previousChapterButton' => 'Forrige kapitel',
			'videoControls.nextChapterButton' => 'Næste kapitel',
			'videoControls.muteButton' => 'Lydløs',
			'videoControls.unmuteButton' => 'Slå lyd til',
			'videoControls.settingsButton' => 'Videoindstillinger',
			'videoControls.tracksButton' => 'Lyd og undertekster',
			'videoControls.chaptersButton' => 'Kapitler',
			'videoControls.versionsButton' => 'Videoversioner',
			'videoControls.versionQualityButton' => 'Version og kvalitet',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Kvalitet',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkodning utilgængelig — afspiller original kvalitet',
			'videoControls.pipButton' => 'Billede-i-billede-tilstand',
			'videoControls.aspectRatioButton' => 'Billedformat',
			'videoControls.ambientLighting' => 'Omgivelsesbelysning',
			'videoControls.fullscreenButton' => 'Fuldskærm',
			'videoControls.exitFullscreenButton' => 'Forlad fuldskærm',
			'videoControls.alwaysOnTopButton' => 'Altid øverst',
			'videoControls.rotationLockButton' => 'Rotationslås',
			'videoControls.lockScreen' => 'Lås skærm',
			'videoControls.screenLockButton' => 'Skærmlås',
			'videoControls.longPressToUnlock' => 'Langt tryk for at låse op',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Lydstyrkeniveau',
			'videoControls.endsAt' => ({required Object time}) => 'Slutter kl. ${time}',
			'videoControls.pipActive' => 'Afspiller i billede-i-billede',
			'videoControls.pipFailed' => 'Billede-i-billede kunne ikke starte',
			'videoControls.pipErrors.androidVersion' => 'Kræver Android 8.0 eller nyere',
			'videoControls.pipErrors.iosVersion' => 'Kræver iOS 15.0 eller nyere',
			'videoControls.pipErrors.permissionDisabled' => 'Billede-i-billede-tilladelse er deaktiveret. Aktivér i Indstillinger > Apps > Plezy > Billede-i-billede',
			'videoControls.pipErrors.notSupported' => 'Enheden understøtter ikke billede-i-billede',
			'videoControls.pipErrors.voSwitchFailed' => 'Kunne ikke skifte videooutput til billede-i-billede',
			'videoControls.pipErrors.failed' => 'Billede-i-billede kunne ikke starte',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Der opstod en fejl: ${error}',
			'videoControls.chapters' => 'Kapitler',
			'videoControls.noChaptersAvailable' => 'Ingen kapitler tilgængelige',
			'videoControls.queue' => 'Kø',
			'videoControls.noQueueItems' => 'Ingen elementer i køen',
			'videoControls.searchSubtitles' => 'Søg undertekster',
			'videoControls.language' => 'Sprog',
			'videoControls.noSubtitlesFound' => 'Ingen undertekster fundet',
			'videoControls.subtitleDownloaded' => 'Undertekst downloadet',
			'videoControls.subtitleDownloadFailed' => 'Kunne ikke downloade undertekst',
			'videoControls.searchLanguages' => 'Søg sprog...',
			'userStatus.admin' => 'Administrator',
			'userStatus.restricted' => 'Begrænset',
			'userStatus.protected' => 'Beskyttet',
			'userStatus.current' => 'NUVÆRENDE',
			'messages.markedAsWatched' => 'Markeret som set',
			'messages.markedAsUnwatched' => 'Markeret som uset',
			'messages.markedAsWatchedOffline' => 'Markeret som set (synkroniseres online)',
			'messages.markedAsUnwatchedOffline' => 'Markeret som uset (synkroniseres online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisk fjernet: ${title}',
			'messages.removedFromContinueWatching' => 'Fjernet fra Fortsæt med at se',
			'messages.errorLoading' => ({required Object error}) => 'Fejl: ${error}',
			'messages.fileInfoNotAvailable' => 'Filinfo ikke tilgængelig',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Fejl ved indlæsning af filinfo: ${error}',
			'messages.errorLoadingSeries' => 'Fejl ved indlæsning af serie',
			'messages.errorLoadingSeason' => 'Fejl ved indlæsning af sæson',
			'messages.musicNotSupported' => 'Musikafspilning understøttes endnu ikke',
			'messages.noDescriptionAvailable' => 'Ingen beskrivelse tilgængelig',
			'messages.noProfilesAvailable' => 'Ingen profiler tilgængelige',
			'messages.contactAdminForProfiles' => 'Kontakt din Plex-administrator for at tilføje profiler',
			'messages.unableToDetermineLibrarySection' => 'Kan ikke bestemme biblioteksafdeling for dette element',
			'messages.logsCleared' => 'Logs ryddet',
			'messages.logsCopied' => 'Logs kopieret til udklipsholder',
			'messages.noLogsAvailable' => 'Ingen logs tilgængelige',
			'messages.libraryScanning' => ({required Object title}) => 'Scanner "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Biblioteksscanning startet for "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kunne ikke scanne bibliotek: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Opdaterer metadata for "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadataopdatering startet for "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Kunne ikke opdatere metadata: ${error}',
			'messages.logoutConfirm' => 'Er du sikker på, at du vil logge ud?',
			'messages.noSeasonsFound' => 'Ingen sæsoner fundet',
			'messages.noEpisodesFound' => 'Ingen episoder fundet i første sæson',
			'messages.noEpisodesFoundGeneral' => 'Ingen episoder fundet',
			'messages.noResultsFound' => 'Ingen resultater fundet',
			'messages.sleepTimerSet' => ({required Object label}) => 'Sove-timer indstillet til ${label}',
			'messages.noItemsAvailable' => 'Ingen elementer tilgængelige',
			'messages.failedToCreatePlayQueueNoItems' => 'Kunne ikke oprette afspilningskø — ingen elementer',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Skifter til kompatibel afspiller...',
			'messages.serverLimitTitle' => 'Afspilning mislykkedes',
			'messages.serverLimitBody' => 'Serveren returnerede en fejl (HTTP 500). Det betyder som regel, at serverejeren har sat en båndbredde- eller transkodningsgrænse, der afviser din session. Der er intet at gøre fra klienten — serverejeren skal justere sine indstillinger.',
			'messages.logsUploaded' => 'Logs uploadet',
			'messages.logsUploadFailed' => 'Kunne ikke uploade logs',
			'messages.logId' => 'Log-ID',
			'subtitlingStyling.text' => 'Tekst',
			'subtitlingStyling.border' => 'Kant',
			'subtitlingStyling.background' => 'Baggrund',
			'subtitlingStyling.fontSize' => 'Skriftstørrelse',
			'subtitlingStyling.textColor' => 'Tekstfarve',
			'subtitlingStyling.borderSize' => 'Kantstørrelse',
			'subtitlingStyling.borderColor' => 'Kantfarve',
			'subtitlingStyling.backgroundOpacity' => 'Baggrundsgennemsigtighed',
			'subtitlingStyling.backgroundColor' => 'Baggrundsfarve',
			'subtitlingStyling.position' => 'Position',
			'subtitlingStyling.assOverride' => 'ASS-tilsidesættelse',
			'subtitlingStyling.bold' => 'Fed',
			'subtitlingStyling.italic' => 'Kursiv',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Avancerede videoafspillerindstillinger',
			'mpvConfig.presets' => 'Forudindstillinger',
			'mpvConfig.noPresets' => 'Ingen gemte forudindstillinger',
			'mpvConfig.saveAsPreset' => 'Gem som forudindstilling...',
			'mpvConfig.presetName' => 'Forudindstillingsnavn',
			'mpvConfig.presetNameHint' => 'Indtast et navn for denne forudindstilling',
			'mpvConfig.loadPreset' => 'Indlæs',
			'mpvConfig.deletePreset' => 'Slet',
			'mpvConfig.presetSaved' => 'Forudindstilling gemt',
			'mpvConfig.presetLoaded' => 'Forudindstilling indlæst',
			'mpvConfig.presetDeleted' => 'Forudindstilling slettet',
			'mpvConfig.confirmDeletePreset' => 'Er du sikker på, at du vil slette denne forudindstilling?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Bekræft handling',
			'discover.title' => 'Opdag',
			'discover.switchProfile' => 'Skift profil',
			'discover.noContentAvailable' => 'Intet indhold tilgængeligt',
			'discover.addMediaToLibraries' => 'Tilføj medier til dine biblioteker',
			'discover.continueWatching' => 'Fortsæt med at se',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Oversigt',
			'discover.cast' => 'Rollebesætning',
			'discover.extras' => 'Trailere og ekstra',
			'discover.studio' => 'Studie',
			'discover.rating' => 'Bedømmelse',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min tilbage',
			'errors.searchFailed' => ({required Object error}) => 'Søgning mislykkedes: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Forbindelsestimeout ved indlæsning af ${context}',
			'errors.connectionFailed' => 'Kunne ikke forbinde til Plex-server',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Kunne ikke indlæse ${context}: ${error}',
			'errors.noClientAvailable' => 'Ingen klient tilgængelig',
			'errors.authenticationFailed' => ({required Object error}) => 'Godkendelse mislykkedes: ${error}',
			'errors.couldNotLaunchUrl' => 'Kunne ikke åbne godkendelses-URL',
			'errors.pleaseEnterToken' => 'Indtast et token',
			'errors.invalidToken' => 'Ugyldigt token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kunne ikke verificere token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kunne ikke skifte til ${displayName}',
			'libraries.title' => 'Biblioteker',
			'libraries.scanLibraryFiles' => 'Scan biblioteksfiler',
			'libraries.scanLibrary' => 'Scan bibliotek',
			'libraries.analyze' => 'Analysér',
			'libraries.analyzeLibrary' => 'Analysér bibliotek',
			'libraries.refreshMetadata' => 'Opdater metadata',
			'libraries.emptyTrash' => 'Tøm papirkurv',
			'libraries.emptyingTrash' => ({required Object title}) => 'Tømmer papirkurv for "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papirkurv tømt for "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kunne ikke tømme papirkurv: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyserer "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse startet for "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kunne ikke analysere bibliotek: ${error}',
			'libraries.noLibrariesFound' => 'Ingen biblioteker fundet',
			'libraries.thisLibraryIsEmpty' => 'Dette bibliotek er tomt',
			'libraries.all' => 'Alle',
			'libraries.clearAll' => 'Ryd alle',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Er du sikker på, at du vil scanne "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Er du sikker på, at du vil analysere "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Er du sikker på, at du vil opdatere metadata for "${title}"?',
			_ => null,
		} ?? switch (path) {
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Er du sikker på, at du vil tømme papirkurven for "${title}"?',
			'libraries.manageLibraries' => 'Administrer biblioteker',
			'libraries.sort' => 'Sortér',
			'libraries.sortBy' => 'Sortér efter',
			'libraries.filters' => 'Filtre',
			'libraries.confirmActionMessage' => 'Er du sikker på, at du vil udføre denne handling?',
			'libraries.showLibrary' => 'Vis bibliotek',
			'libraries.hideLibrary' => 'Skjul bibliotek',
			'libraries.libraryOptions' => 'Biblioteksindstillinger',
			'libraries.content' => 'biblioteksindhold',
			'libraries.selectLibrary' => 'Vælg bibliotek',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtre (${count})',
			'libraries.noRecommendations' => 'Ingen anbefalinger tilgængelige',
			'libraries.noCollections' => 'Ingen samlinger i dette bibliotek',
			'libraries.noFoldersFound' => 'Ingen mapper fundet',
			'libraries.folders' => 'mapper',
			'libraries.tabs.recommended' => 'Anbefalet',
			'libraries.tabs.browse' => 'Gennemse',
			'libraries.tabs.collections' => 'Samlinger',
			'libraries.tabs.playlists' => 'Playlister',
			'libraries.groupings.title' => 'Gruppering',
			'libraries.groupings.all' => 'Alle',
			'libraries.groupings.movies' => 'Film',
			'libraries.groupings.shows' => 'TV-serier',
			'libraries.groupings.seasons' => 'Sæsoner',
			'libraries.groupings.episodes' => 'Episoder',
			'libraries.groupings.folders' => 'Mapper',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Open source-licenser',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'En smuk Plex-klient til Flutter',
			'about.viewLicensesDescription' => 'Se licenser for tredjepartsbiblioteker',
			'serverSelection.allServerConnectionsFailed' => 'Kunne ikke forbinde til nogen servere. Tjek dit netværk og prøv igen.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Ingen servere fundet for ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Kunne ikke indlæse servere: ${error}',
			'hubDetail.title' => 'Titel',
			'hubDetail.releaseYear' => 'Udgivelsesår',
			'hubDetail.dateAdded' => 'Tilføjelsesdato',
			'hubDetail.rating' => 'Bedømmelse',
			'hubDetail.noItemsFound' => 'Ingen elementer fundet',
			'logs.clearLogs' => 'Ryd logs',
			'logs.copyLogs' => 'Kopiér logs',
			'logs.uploadLogs' => 'Upload logs',
			'licenses.relatedPackages' => 'Relaterede pakker',
			'licenses.license' => 'Licens',
			'licenses.licenseNumber' => ({required Object number}) => 'Licens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenser',
			'navigation.libraries' => 'Biblioteker',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'Live TV',
			'liveTv.title' => 'Live TV',
			'liveTv.guide' => 'Guide',
			'liveTv.noChannels' => 'Ingen kanaler tilgængelige',
			'liveTv.noDvr' => 'Ingen DVR konfigureret på nogen server',
			'liveTv.noPrograms' => 'Ingen programdata tilgængelig',
			'liveTv.live' => 'LIVE',
			'liveTv.reloadGuide' => 'Genindlæs guide',
			'liveTv.now' => 'Nu',
			'liveTv.today' => 'I dag',
			'liveTv.midnight' => 'Midnat',
			'liveTv.overnight' => 'Nat',
			'liveTv.morning' => 'Morgen',
			'liveTv.daytime' => 'Dagtid',
			'liveTv.evening' => 'Aften',
			'liveTv.lateNight' => 'Sen aften',
			'liveTv.whatsOn' => 'Hvad der kører',
			'liveTv.watchChannel' => 'Se kanal',
			'liveTv.favorites' => 'Favoritter',
			'liveTv.reorderFavorites' => 'Omarranger favoritter',
			'liveTv.joinSession' => 'Deltag i igangværende session',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Se fra start (${minutes} min siden)',
			'liveTv.watchLive' => 'Se live',
			'liveTv.goToLive' => 'Gå til live',
			'collections.title' => 'Samlinger',
			'collections.collection' => 'Samling',
			'collections.empty' => 'Samlingen er tom',
			'collections.unknownLibrarySection' => 'Kan ikke slette: Ukendt bibliotekssektion',
			'collections.deleteCollection' => 'Slet samling',
			'collections.deleteConfirm' => ({required Object title}) => 'Er du sikker på, at du vil slette "${title}"? Denne handling kan ikke fortrydes.',
			'collections.deleted' => 'Samling slettet',
			'collections.deleteFailed' => 'Kunne ikke slette samling',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Kunne ikke slette samling: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Kunne ikke indlæse samlingselementer: ${error}',
			'collections.selectCollection' => 'Vælg samling',
			'collections.collectionName' => 'Samlingsnavn',
			'collections.enterCollectionName' => 'Indtast samlingsnavn',
			'collections.addedToCollection' => 'Tilføjet til samling',
			'collections.errorAddingToCollection' => 'Kunne ikke tilføje til samling',
			'collections.created' => 'Samling oprettet',
			'collections.removeFromCollection' => 'Fjern fra samling',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Fjern "${title}" fra denne samling?',
			'collections.removedFromCollection' => 'Fjernet fra samling',
			'collections.removeFromCollectionFailed' => 'Kunne ikke fjerne fra samling',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Fejl ved fjernelse fra samling: ${error}',
			'collections.searchCollections' => 'Søg i samlinger...',
			'playlists.title' => 'Playlister',
			'playlists.playlist' => 'Playliste',
			'playlists.noPlaylists' => 'Ingen playlister fundet',
			'playlists.create' => 'Opret playliste',
			'playlists.playlistName' => 'Playlistenavn',
			'playlists.enterPlaylistName' => 'Indtast playlistenavn',
			'playlists.delete' => 'Slet playliste',
			'playlists.removeItem' => 'Fjern fra playliste',
			'playlists.smartPlaylist' => 'Smart playliste',
			'playlists.itemCount' => ({required Object count}) => '${count} elementer',
			'playlists.oneItem' => '1 element',
			'playlists.emptyPlaylist' => 'Denne playliste er tom',
			'playlists.deleteConfirm' => 'Slet playliste?',
			'playlists.deleteMessage' => ({required Object name}) => 'Er du sikker på, at du vil slette "${name}"?',
			'playlists.created' => 'Playliste oprettet',
			'playlists.deleted' => 'Playliste slettet',
			'playlists.itemAdded' => 'Tilføjet til playliste',
			'playlists.itemRemoved' => 'Fjernet fra playliste',
			'playlists.selectPlaylist' => 'Vælg playliste',
			'playlists.errorCreating' => 'Kunne ikke oprette playliste',
			'playlists.errorDeleting' => 'Kunne ikke slette playliste',
			'playlists.errorLoading' => 'Kunne ikke indlæse playlister',
			'playlists.errorAdding' => 'Kunne ikke tilføje til playliste',
			'playlists.errorReordering' => 'Kunne ikke ændre rækkefølge på playlisteelement',
			'playlists.errorRemoving' => 'Kunne ikke fjerne fra playliste',
			'watchTogether.title' => 'Se sammen',
			'watchTogether.description' => 'Se indhold synkroniseret med venner og familie',
			'watchTogether.createSession' => 'Opret session',
			'watchTogether.creating' => 'Opretter...',
			'watchTogether.joinSession' => 'Deltag i session',
			'watchTogether.joining' => 'Deltager...',
			'watchTogether.controlMode' => 'Kontroltilstand',
			'watchTogether.controlModeQuestion' => 'Hvem kan styre afspilning?',
			'watchTogether.hostOnly' => 'Kun vært',
			'watchTogether.anyone' => 'Alle',
			'watchTogether.hostingSession' => 'Vært for session',
			'watchTogether.inSession' => 'I session',
			'watchTogether.sessionCode' => 'Sessionskode',
			'watchTogether.hostControlsPlayback' => 'Vært styrer afspilning',
			'watchTogether.anyoneCanControl' => 'Alle kan styre afspilning',
			'watchTogether.hostControls' => 'Værtskontrol',
			'watchTogether.anyoneControls' => 'Alle styrer',
			'watchTogether.participants' => 'Deltagere',
			'watchTogether.host' => 'Vært',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Du er vært',
			'watchTogether.watchingWithOthers' => 'Ser med andre',
			'watchTogether.endSession' => 'Afslut session',
			'watchTogether.leaveSession' => 'Forlad session',
			'watchTogether.endSessionQuestion' => 'Afslut session?',
			'watchTogether.leaveSessionQuestion' => 'Forlad session?',
			'watchTogether.endSessionConfirm' => 'Dette afslutter sessionen for alle deltagere.',
			'watchTogether.leaveSessionConfirm' => 'Du vil blive fjernet fra sessionen.',
			'watchTogether.endSessionConfirmOverlay' => 'Dette afslutter se-sessionen for alle deltagere.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Du vil blive afbrudt fra se-sessionen.',
			'watchTogether.end' => 'Afslut',
			'watchTogether.leave' => 'Forlad',
			'watchTogether.syncing' => 'Synkroniserer...',
			'watchTogether.joinWatchSession' => 'Deltag i se-session',
			'watchTogether.enterCodeHint' => 'Indtast 5-tegns kode',
			'watchTogether.pasteFromClipboard' => 'Indsæt fra udklipsholder',
			'watchTogether.pleaseEnterCode' => 'Indtast en sessionskode',
			'watchTogether.codeMustBe5Chars' => 'Sessionskode skal være 5 tegn',
			'watchTogether.joinInstructions' => 'Indtast sessionskoden delt af værten for at deltage i se-sessionen.',
			'watchTogether.failedToCreate' => 'Kunne ikke oprette session',
			'watchTogether.failedToJoin' => 'Kunne ikke deltage i session',
			'watchTogether.sessionCodeCopied' => 'Sessionskode kopieret til udklipsholder',
			'watchTogether.relayUnreachable' => 'Relay-serveren kan ikke nås. Dette kan skyldes, at din udbyder blokerer forbindelsen. Du kan stadig prøve, men Se sammen virker muligvis ikke.',
			'watchTogether.reconnectingToHost' => 'Genopretter forbindelse til vært...',
			'watchTogether.currentPlayback' => 'Nuværende afspilning',
			'watchTogether.joinCurrentPlayback' => 'Deltag i nuværende afspilning',
			'watchTogether.joinCurrentPlaybackDescription' => 'Hop tilbage til det værten ser nu',
			'watchTogether.failedToOpenCurrentPlayback' => 'Kunne ikke åbne nuværende afspilning',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} deltog',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} forlod',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} satte på pause',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} genoptog',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} spoled',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} bufferer',
			'watchTogether.waitingForParticipants' => 'Venter på at andre indlæser...',
			'watchTogether.recentRooms' => 'Seneste rum',
			'watchTogether.renameRoom' => 'Omdøb rum',
			'watchTogether.removeRoom' => 'Fjern',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Administrer',
			'downloads.tvShows' => 'TV-serier',
			'downloads.movies' => 'Film',
			'downloads.noDownloads' => 'Ingen downloads endnu',
			'downloads.noDownloadsDescription' => 'Downloadet indhold vises her til offlinevisning',
			'downloads.downloadNow' => 'Download',
			'downloads.deleteDownload' => 'Slet download',
			'downloads.retryDownload' => 'Prøv download igen',
			'downloads.downloadQueued' => 'Download i kø',
			'downloads.serverErrorBitrate' => 'Serverfejl — filen overskrider muligvis grænsen for fjernstreaming-bitrate',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episoder i downloadkø',
			'downloads.downloadDeleted' => 'Download slettet',
			'downloads.deleteConfirm' => ({required Object title}) => 'Er du sikker på, at du vil slette "${title}"? Den downloadede fil fjernes fra din enhed.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} af ${total})',
			'downloads.noDownloadsTree' => 'Ingen downloads',
			'downloads.pauseAll' => 'Pause alle',
			'downloads.resumeAll' => 'Genoptag alle',
			'downloads.deleteAll' => 'Slet alle',
			'downloads.selectVersion' => 'Vælg version',
			'downloads.allEpisodes' => 'Alle episoder',
			'downloads.unwatchedOnly' => 'Kun usete',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Næste ${count} usete',
			'downloads.customAmount' => 'Angiv antal...',
			'downloads.howManyEpisodes' => 'Hvor mange episoder?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} elementer sat i kø til download',
			'downloads.keepSynced' => 'Hold synkroniseret',
			'downloads.downloadOnce' => 'Download én gang',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Behold ${count} usete',
			'downloads.editSyncRule' => 'Rediger synkroniseringsregel',
			'downloads.removeSyncRule' => 'Fjern synkroniseringsregel',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Stop synkronisering af "${title}"? Downloadede episoder beholdes.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synkroniseringsregel oprettet — beholder ${count} usete episoder',
			'downloads.syncRuleUpdated' => 'Synkroniseringsregel opdateret',
			'downloads.syncRuleRemoved' => 'Synkroniseringsregel fjernet',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synkroniserede ${count} nye episoder for ${title}',
			'downloads.activeSyncRules' => 'Synkroniseringsregler',
			'downloads.noSyncRules' => 'Ingen synkroniseringsregler',
			'downloads.manageSyncRule' => 'Administrer synkronisering',
			'downloads.editEpisodeCount' => 'Antal episoder',
			'downloads.editSyncFilter' => 'Synkroniseringsfilter',
			'downloads.syncAllItems' => 'Synkroniserer alle elementer',
			'downloads.syncUnwatchedItems' => 'Synkroniserer usete elementer',
			'downloads.syncRuleListCreated' => 'Synkroniseringsregel oprettet',
			'shaders.title' => 'Shadere',
			'shaders.noShaderDescription' => 'Ingen videoforbedring',
			'shaders.nvscalerDescription' => 'NVIDIA-billedskalering for skarpere video',
			'shaders.qualityFast' => 'Hurtig',
			'shaders.qualityHQ' => 'Høj kvalitet',
			'shaders.mode' => 'Tilstand',
			'shaders.importShader' => 'Importér shader',
			'shaders.customShaderDescription' => 'Brugerdefineret GLSL-shader',
			'shaders.shaderImported' => 'Shader importeret',
			'shaders.shaderImportFailed' => 'Kunne ikke importere shader',
			'shaders.deleteShader' => 'Slet shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Slet "${name}"?',
			'companionRemote.title' => 'Fjernbetjening',
			'companionRemote.connectedTo' => ({required Object name}) => 'Forbundet til ${name}',
			'companionRemote.session.startingServer' => 'Starter fjernserver...',
			'companionRemote.session.failedToCreate' => 'Kunne ikke starte fjernserver:',
			'companionRemote.session.hostAddress' => 'Værtsadresse',
			'companionRemote.session.connected' => 'Forbundet',
			'companionRemote.session.serverRunning' => 'Fjernserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjernserver stoppet',
			'companionRemote.session.serverRunningDescription' => 'Mobilenheder på dit netværk kan finde og oprette forbindelse til denne app',
			'companionRemote.session.serverStoppedDescription' => 'Start serveren for at tillade mobilenheder at oprette forbindelse',
			'companionRemote.session.usePhoneToControl' => 'Brug din mobilenhed til at styre denne app',
			'companionRemote.session.startServer' => 'Start server',
			'companionRemote.session.stopServer' => 'Stop server',
			'companionRemote.session.minimize' => 'Minimér',
			'companionRemote.pairing.discoveryDescription' => 'Enheder på dit netværk, der kører Plezy med den samme Plex-konto, vises automatisk',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Opretter forbindelse...',
			'companionRemote.pairing.searchingForDevices' => 'Søger efter enheder...',
			'companionRemote.pairing.noDevicesFound' => 'Ingen enheder fundet på dit netværk',
			'companionRemote.pairing.noDevicesHint' => 'Sørg for, at Plezy er åben på din computer, og at begge enheder er på det samme WiFi-netværk',
			'companionRemote.pairing.availableDevices' => 'Tilgængelige enheder',
			'companionRemote.pairing.manualConnection' => 'Manuel forbindelse',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunne ikke initialisere sikker forbindelse. Sørg for, at du er logget ind på en Plex-konto.',
			'companionRemote.pairing.validationHostRequired' => 'Angiv venligst værtsadresse',
			'companionRemote.pairing.validationHostFormat' => 'Format skal være IP:port (f.eks. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Forbindelsen udløb. Sørg for, at begge enheder er på det samme netværk.',
			'companionRemote.pairing.sessionNotFound' => 'Kunne ikke finde enheden. Sørg for, at Plezy kører på værten.',
			'companionRemote.pairing.authFailed' => 'Godkendelse mislykkedes. Sørg for, at begge enheder bruger den samme Plex-konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunne ikke oprette forbindelse: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vil du afbryde fra fjernsessionen?',
			'companionRemote.remote.reconnecting' => 'Genopretter forbindelse...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Forsøg ${current} af 5',
			'companionRemote.remote.retryNow' => 'Prøv igen nu',
			'companionRemote.remote.tabRemote' => 'Fjernbetjening',
			'companionRemote.remote.tabPlay' => 'Afspil',
			'companionRemote.remote.tabMore' => 'Mere',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Fanenavigation',
			'companionRemote.remote.tabDiscover' => 'Opdag',
			'companionRemote.remote.tabLibraries' => 'Biblioteker',
			'companionRemote.remote.tabSearch' => 'Søg',
			'companionRemote.remote.tabDownloads' => 'Downloads',
			'companionRemote.remote.tabSettings' => 'Indstillinger',
			'companionRemote.remote.previous' => 'Forrige',
			'companionRemote.remote.playPause' => 'Afspil/Pause',
			'companionRemote.remote.next' => 'Næste',
			'companionRemote.remote.seekBack' => 'Spol tilbage',
			'companionRemote.remote.stop' => 'Stop',
			'companionRemote.remote.seekForward' => 'Spol frem',
			'companionRemote.remote.volume' => 'Lydstyrke',
			'companionRemote.remote.volumeDown' => 'Ned',
			'companionRemote.remote.volumeUp' => 'Op',
			'companionRemote.remote.fullscreen' => 'Fuldskærm',
			'companionRemote.remote.subtitles' => 'Undertekster',
			'companionRemote.remote.audio' => 'Lyd',
			'companionRemote.remote.searchHint' => 'Søg på desktop...',
			'videoSettings.playbackSettings' => 'Afspilningsindstillinger',
			'videoSettings.playbackSpeed' => 'Afspilningshastighed',
			'videoSettings.sleepTimer' => 'Sove-timer',
			'videoSettings.audioSync' => 'Lydsynkronisering',
			'videoSettings.subtitleSync' => 'Undertekstsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Lydoutput',
			'videoSettings.performanceOverlay' => 'Ydelsesoverlay',
			'videoSettings.audioPassthrough' => 'Lyd-passthrough',
			'videoSettings.audioNormalization' => 'Normalisér lydstyrke',
			'externalPlayer.title' => 'Ekstern afspiller',
			'externalPlayer.useExternalPlayer' => 'Brug ekstern afspiller',
			'externalPlayer.useExternalPlayerDescription' => 'Åbn videoer i en ekstern app i stedet for den indbyggede afspiller',
			'externalPlayer.selectPlayer' => 'Vælg afspiller',
			'externalPlayer.customPlayers' => 'Brugerdefinerede afspillere',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Tilføj brugerdefineret afspiller',
			'externalPlayer.playerName' => 'Afspillernavn',
			'externalPlayer.playerCommand' => 'Kommando',
			'externalPlayer.playerPackage' => 'Pakkenavn',
			'externalPlayer.playerUrlScheme' => 'URL-skema',
			'externalPlayer.off' => 'Fra',
			'externalPlayer.launchFailed' => 'Kunne ikke åbne ekstern afspiller',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} er ikke installeret',
			'externalPlayer.playInExternalPlayer' => 'Afspil i ekstern afspiller',
			'metadataEdit.editMetadata' => 'Redigér...',
			'metadataEdit.screenTitle' => 'Redigér metadata',
			'metadataEdit.basicInfo' => 'Grundlæggende info',
			'metadataEdit.artwork' => 'Grafik',
			'metadataEdit.advancedSettings' => 'Avancerede indstillinger',
			'metadataEdit.title' => 'Titel',
			'metadataEdit.sortTitle' => 'Sorteringstitel',
			'metadataEdit.originalTitle' => 'Originaltitel',
			'metadataEdit.releaseDate' => 'Udgivelsesdato',
			'metadataEdit.contentRating' => 'Aldersgrænse',
			'metadataEdit.studio' => 'Studie',
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Resumé',
			'metadataEdit.poster' => 'Plakat',
			'metadataEdit.background' => 'Baggrund',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Kvadratisk billede',
			'metadataEdit.selectPoster' => 'Vælg plakat',
			'metadataEdit.selectBackground' => 'Vælg baggrund',
			'metadataEdit.selectLogo' => 'Vælg logo',
			'metadataEdit.selectSquareArt' => 'Vælg kvadratisk billede',
			'metadataEdit.fromUrl' => 'Fra URL',
			'metadataEdit.uploadFile' => 'Upload fil',
			'metadataEdit.enterImageUrl' => 'Indtast billed-URL',
			'metadataEdit.imageUrl' => 'Billed-URL',
			'metadataEdit.metadataUpdated' => 'Metadata opdateret',
			'metadataEdit.metadataUpdateFailed' => 'Kunne ikke opdatere metadata',
			'metadataEdit.artworkUpdated' => 'Grafik opdateret',
			'metadataEdit.artworkUpdateFailed' => 'Kunne ikke opdatere grafik',
			'metadataEdit.noArtworkAvailable' => 'Ingen grafik tilgængelig',
			'metadataEdit.notSet' => 'Ikke indstillet',
			'metadataEdit.libraryDefault' => 'Biblioteksstandard',
			'metadataEdit.accountDefault' => 'Kontostandard',
			'metadataEdit.seriesDefault' => 'Seriestandard',
			'metadataEdit.episodeSorting' => 'Episodesortering',
			'metadataEdit.oldestFirst' => 'Ældste først',
			'metadataEdit.newestFirst' => 'Nyeste først',
			'metadataEdit.keep' => 'Behold',
			'metadataEdit.allEpisodes' => 'Alle episoder',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} seneste episoder',
			'metadataEdit.latestEpisode' => 'Seneste episode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episoder tilføjet de seneste ${count} dage',
			'metadataEdit.deleteAfterPlaying' => 'Slet episoder efter afspilning',
			'metadataEdit.never' => 'Aldrig',
			'metadataEdit.afterADay' => 'Efter en dag',
			'metadataEdit.afterAWeek' => 'Efter en uge',
			'metadataEdit.afterAMonth' => 'Efter en måned',
			'metadataEdit.onNextRefresh' => 'Ved næste opdatering',
			'metadataEdit.seasons' => 'Sæsoner',
			'metadataEdit.show' => 'Vis',
			'metadataEdit.hide' => 'Skjul',
			'metadataEdit.episodeOrdering' => 'Episoderækkefølge',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Sendt)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Sendt)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolut)',
			'metadataEdit.metadataLanguage' => 'Metadatasprog',
			'metadataEdit.useOriginalTitle' => 'Brug originaltitel',
			'metadataEdit.preferredAudioLanguage' => 'Foretrukket lydsprog',
			'metadataEdit.preferredSubtitleLanguage' => 'Foretrukket undertekstsprog',
			'metadataEdit.subtitleMode' => 'Auto-vælg underteksttilstand',
			'metadataEdit.manuallySelected' => 'Manuelt valgt',
			'metadataEdit.shownWithForeignAudio' => 'Vist med fremmedsproget lyd',
			'metadataEdit.alwaysEnabled' => 'Altid aktiveret',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Tilføj tag',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Instruktør',
			'metadataEdit.writer' => 'Forfatter',
			'metadataEdit.producer' => 'Producer',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Samling',
			'metadataEdit.label' => 'Etiket',
			'metadataEdit.style' => 'Stil',
			'metadataEdit.mood' => 'Stemning',
			'matchScreen.match' => 'Match...',
			'matchScreen.fixMatch' => 'Ret match...',
			'matchScreen.unmatch' => 'Fjern match',
			'matchScreen.unmatchConfirm' => 'Ryd det aktuelle match for dette element? Plex behandler det som ikke matchet, indtil du matcher det igen.',
			'matchScreen.unmatchSuccess' => 'Match fjernet',
			'matchScreen.unmatchFailed' => 'Kunne ikke fjerne match',
			'matchScreen.matchApplied' => 'Match anvendt',
			'matchScreen.matchFailed' => 'Kunne ikke anvende match',
			'matchScreen.titleHint' => 'Titel',
			'matchScreen.yearHint' => 'År',
			'matchScreen.search' => 'Søg',
			'matchScreen.noMatchesFound' => 'Ingen match fundet',
			'serverTasks.title' => 'Serveropgaver',
			'serverTasks.failedToLoad' => 'Kunne ikke indlæse opgaver',
			'serverTasks.noTasks' => 'Ingen opgaver kører',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Forbundet',
			'trakt.connectedAs' => ({required Object username}) => 'Forbundet som @${username}',
			'trakt.disconnectConfirm' => 'Frakobl Trakt-konto?',
			'trakt.disconnectConfirmBody' => 'Plezy stopper med at sende afspilningsbegivenheder til Trakt. Du kan genoprette forbindelse når som helst.',
			'trakt.scrobble' => 'Realtids-scrobbling',
			'trakt.scrobbleDescription' => 'Send afspil-, pause- og stop-begivenheder til Trakt under afspilning.',
			'trakt.watchedSync' => 'Synkroniser sét-status',
			'trakt.watchedSyncDescription' => 'Når du markerer ting som sét i Plezy, markeres de også på Trakt.',
			'trakt.connectFailed' => 'Kunne ikke forbinde til Trakt. Prøv igen.',
			'trackers.title' => 'Trackere',
			'trackers.hubSubtitle' => 'Hold din visningsfremgang synkroniseret med Trakt og andre tjenester.',
			'trackers.notConnected' => 'Ikke forbundet',
			'trackers.connectedAs' => ({required Object username}) => 'Forbundet som @${username}',
			'trackers.scrobble' => 'Registrer fremgang automatisk',
			'trackers.scrobbleDescription' => 'Opdater din liste når du er færdig med et afsnit eller en film.',
			'trackers.disconnectConfirm' => ({required Object service}) => 'Afbryd ${service}?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy stopper med at opdatere din ${service}-liste. Du kan forbinde igen når som helst.',
			'trackers.connectFailed' => ({required Object service}) => 'Kunne ikke forbinde til ${service}. Prøv igen.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Aktiver Plezy på ${service}',
			'trackers.deviceCode.body' => ({required Object url}) => 'Besøg ${url} og indtast denne kode:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => 'Åbn ${service} for at aktivere',
			'trackers.deviceCode.waitingForAuthorization' => 'Venter på godkendelse…',
			'trackers.deviceCode.codeCopied' => 'Kode kopieret',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Log ind på ${service}',
			'trackers.oauthProxy.body' => 'Scan denne QR-kode med din telefon, eller åbn URL\'en nedenfor på en enhed med browser.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => 'Åbn ${service} for at logge ind',
			'trackers.oauthProxy.urlCopied' => 'URL kopieret',
			'trackers.libraryFilter.title' => 'Bibliotekfilter',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Synkroniserer alle biblioteker',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Intet synkroniseres',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blokeret',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} tilladt',
			'trackers.libraryFilter.mode' => 'Filtertilstand',
			'trackers.libraryFilter.modeBlacklist' => 'Sortliste',
			'trackers.libraryFilter.modeWhitelist' => 'Hvidliste',
			'trackers.libraryFilter.modeHintBlacklist' => 'Synkroniser alle biblioteker undtagen dem du markerer nedenfor.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Synkroniser kun de biblioteker du markerer nedenfor.',
			'trackers.libraryFilter.libraries' => 'Biblioteker',
			'trackers.libraryFilter.noLibraries' => 'Ingen biblioteker tilgængelige',
			_ => null,
		};
	}
}
