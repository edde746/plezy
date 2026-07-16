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
class TranslationsNb extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsNb({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.nb,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <nb>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsNb _root = this; // ignore: unused_field

	@override 
	TranslationsNb $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsNb(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppNb app = _TranslationsAppNb._(_root);
	@override late final _TranslationsAuthNb auth = _TranslationsAuthNb._(_root);
	@override late final _TranslationsCommonNb common = _TranslationsCommonNb._(_root);
	@override late final _TranslationsScreensNb screens = _TranslationsScreensNb._(_root);
	@override late final _TranslationsUpdateNb update = _TranslationsUpdateNb._(_root);
	@override late final _TranslationsSettingsNb settings = _TranslationsSettingsNb._(_root);
	@override late final _TranslationsSearchNb search = _TranslationsSearchNb._(_root);
	@override late final _TranslationsHotkeysNb hotkeys = _TranslationsHotkeysNb._(_root);
	@override late final _TranslationsFileInfoNb fileInfo = _TranslationsFileInfoNb._(_root);
	@override late final _TranslationsMediaMenuNb mediaMenu = _TranslationsMediaMenuNb._(_root);
	@override late final _TranslationsRateSheetNb rateSheet = _TranslationsRateSheetNb._(_root);
	@override late final _TranslationsAccessibilityNb accessibility = _TranslationsAccessibilityNb._(_root);
	@override late final _TranslationsTooltipsNb tooltips = _TranslationsTooltipsNb._(_root);
	@override late final _TranslationsVideoControlsNb videoControls = _TranslationsVideoControlsNb._(_root);
	@override late final _TranslationsMessagesNb messages = _TranslationsMessagesNb._(_root);
	@override late final _TranslationsSubtitlingStylingNb subtitlingStyling = _TranslationsSubtitlingStylingNb._(_root);
	@override late final _TranslationsMpvConfigNb mpvConfig = _TranslationsMpvConfigNb._(_root);
	@override late final _TranslationsDialogNb dialog = _TranslationsDialogNb._(_root);
	@override late final _TranslationsProfilesNb profiles = _TranslationsProfilesNb._(_root);
	@override late final _TranslationsConnectionsNb connections = _TranslationsConnectionsNb._(_root);
	@override late final _TranslationsDiscoverNb discover = _TranslationsDiscoverNb._(_root);
	@override late final _TranslationsErrorsNb errors = _TranslationsErrorsNb._(_root);
	@override late final _TranslationsLibrariesNb libraries = _TranslationsLibrariesNb._(_root);
	@override late final _TranslationsAboutNb about = _TranslationsAboutNb._(_root);
	@override late final _TranslationsServerSelectionNb serverSelection = _TranslationsServerSelectionNb._(_root);
	@override late final _TranslationsHubDetailNb hubDetail = _TranslationsHubDetailNb._(_root);
	@override late final _TranslationsLogsNb logs = _TranslationsLogsNb._(_root);
	@override late final _TranslationsLicensesNb licenses = _TranslationsLicensesNb._(_root);
	@override late final _TranslationsNavigationNb navigation = _TranslationsNavigationNb._(_root);
	@override late final _TranslationsExploreNb explore = _TranslationsExploreNb._(_root);
	@override late final _TranslationsLiveTvNb liveTv = _TranslationsLiveTvNb._(_root);
	@override late final _TranslationsCollectionsNb collections = _TranslationsCollectionsNb._(_root);
	@override late final _TranslationsPlaylistsNb playlists = _TranslationsPlaylistsNb._(_root);
	@override late final _TranslationsMusicNb music = _TranslationsMusicNb._(_root);
	@override late final _TranslationsWatchTogetherNb watchTogether = _TranslationsWatchTogetherNb._(_root);
	@override late final _TranslationsDownloadsNb downloads = _TranslationsDownloadsNb._(_root);
	@override late final _TranslationsShadersNb shaders = _TranslationsShadersNb._(_root);
	@override late final _TranslationsCompanionRemoteNb companionRemote = _TranslationsCompanionRemoteNb._(_root);
	@override late final _TranslationsVideoSettingsNb videoSettings = _TranslationsVideoSettingsNb._(_root);
	@override late final _TranslationsPerformanceOverlayNb performanceOverlay = _TranslationsPerformanceOverlayNb._(_root);
	@override late final _TranslationsExternalPlayerNb externalPlayer = _TranslationsExternalPlayerNb._(_root);
	@override late final _TranslationsMetadataEditNb metadataEdit = _TranslationsMetadataEditNb._(_root);
	@override late final _TranslationsMatchScreenNb matchScreen = _TranslationsMatchScreenNb._(_root);
	@override late final _TranslationsServerTasksNb serverTasks = _TranslationsServerTasksNb._(_root);
	@override late final _TranslationsTraktNb trakt = _TranslationsTraktNb._(_root);
	@override late final _TranslationsSeerrNb seerr = _TranslationsSeerrNb._(_root);
	@override late final _TranslationsServicesNb services = _TranslationsServicesNb._(_root);
	@override late final _TranslationsAddServerNb addServer = _TranslationsAddServerNb._(_root);
}

// Path: app
class _TranslationsAppNb extends TranslationsAppEn {
	_TranslationsAppNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthNb extends TranslationsAuthEn {
	_TranslationsAuthNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logg inn med Plex';
	@override String get showQRCode => 'Vis QR-kode';
	@override String get authenticate => 'Autentiser';
	@override String get authenticationTimeout => 'Autentiseringen ble tidsavbrutt. Prøv igjen.';
	@override String get scanQRToSignIn => 'Skann denne QR-koden for å logge inn';
	@override String get waitingForAuth => 'Venter på autentisering...\nLogg inn fra nettleseren.';
	@override String get useBrowser => 'Bruk nettleser';
	@override String get or => 'eller';
	@override String get connectToJellyfin => 'Koble til Jellyfin';
	@override String get useQuickConnect => 'Bruk Quick Connect';
	@override String get quickConnectInstructions => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.';
	@override String get quickConnectWaiting => 'Venter på godkjenning…';
	@override String get quickConnectCancel => 'Avbryt';
	@override String get quickConnectExpired => 'Quick Connect er utløpt. Prøv igjen.';
}

// Path: common
class _TranslationsCommonNb extends TranslationsCommonEn {
	_TranslationsCommonNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Avbryt';
	@override String get save => 'Lagre';
	@override String get close => 'Lukk';
	@override String get clear => 'Tøm';
	@override String get reset => 'Tilbakestill';
	@override String get later => 'Senere';
	@override String get submit => 'Send inn';
	@override String get confirm => 'Bekreft';
	@override String get retry => 'Prøv igjen';
	@override String get logout => 'Logg ut';
	@override String get unknown => 'Ukjent';
	@override String get refresh => 'Oppdater';
	@override String get yes => 'Ja';
	@override String get no => 'Nei';
	@override String get delete => 'Slett';
	@override String get edit => 'Rediger';
	@override String get shuffle => 'Tilfeldig';
	@override String get addTo => 'Legg til i...';
	@override String get createNew => 'Opprett ny';
	@override String get connect => 'Koble til';
	@override String get disconnect => 'Koble fra';
	@override String get play => 'Spill av';
	@override String get pause => 'Pause';
	@override String get resume => 'Gjenoppta';
	@override String get error => 'Feil';
	@override String get search => 'Søk';
	@override String get home => 'Hjem';
	@override String get back => 'Tilbake';
	@override String get settings => 'Innstillinger';
	@override String get mute => 'Demp';
	@override String get ok => 'OK';
	@override String get off => 'Av';
	@override String seasonNumber({required Object number}) => 'Sesong ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episode ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Kapittel ${number}';
	@override String get reconnect => 'Koble til på nytt';
	@override String get viewAll => 'Vis alle';
	@override String get checkingNetwork => 'Sjekker nettverk...';
	@override String get loadingServers => 'Laster servere...';
	@override String get connectingToServers => 'Kobler til servere...';
	@override String get startingOfflineMode => 'Starter frakoblet modus...';
	@override String get loading => 'Laster...';
	@override String get fullscreen => 'Fullskjerm';
	@override String get exitFullscreen => 'Avslutt fullskjerm';
	@override String get pressBackAgainToExit => 'Trykk tilbake igjen for å avslutte';
}

// Path: screens
class _TranslationsScreensNb extends TranslationsScreensEn {
	_TranslationsScreensNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisenser';
	@override String get switchProfile => 'Bytt profil';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logger';
}

// Path: update
class _TranslationsUpdateNb extends TranslationsUpdateEn {
	_TranslationsUpdateNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get available => 'Oppdatering tilgjengelig';
	@override String versionAvailable({required Object version}) => 'Versjon ${version} er tilgjengelig';
	@override String currentVersion({required Object version}) => 'Gjeldende: ${version}';
	@override String get skipVersion => 'Hopp over denne versjonen';
	@override String get viewRelease => 'Vis utgivelse';
	@override String get latestVersion => 'Du har den nyeste versjonen';
	@override String get checkFailed => 'Kunne ikke se etter oppdateringer';
}

// Path: settings
class _TranslationsSettingsNb extends TranslationsSettingsEn {
	_TranslationsSettingsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Innstillinger';
	@override String get supportDeveloper => 'Støtt Plezy';
	@override String get supportDeveloperDescription => 'Doner via Liberapay for å finansiere utviklingen';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videoavspilling';
	@override String get videoPlaybackDescription => 'Konfigurer avspillingsatferd';
	@override String get advanced => 'Avansert';
	@override String get episodePosterMode => 'Episodeplakatstil';
	@override String get seriesPoster => 'Serieplakat';
	@override String get seasonPoster => 'Sesongplakat';
	@override String get episodeThumbnail => 'Miniatyrbilde';
	@override String get showHeroSectionDescription => 'Vis fremhevet innholdskarusell på hjemmeskjermen';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minutter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Angi varighet (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Lyst';
	@override String get darkTheme => 'Mørkt';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Bibliotekets tetthet';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Komfortabel';
	@override String get viewMode => 'Visningsmodus';
	@override String get gridView => 'Rutenett';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Vis fremhevet seksjon';
	@override String get continueWatchingAction => 'Handling for Fortsett å se';
	@override String get continueWatchingPlay => 'Spill av';
	@override String get continueWatchingDetails => 'Åpne detaljer';
	@override String get episodeAction => 'Handling for episoder';
	@override String get episodePlay => 'Spill av';
	@override String get episodeDetails => 'Åpne detaljer';
	@override String get useGlobalHubs => 'Bruk startoppsett';
	@override String get useGlobalHubsDescription => 'Vis samlet startinnhold. Ellers brukes bibliotekanbefalinger.';
	@override String get showServerNameOnHubs => 'Vis servernavn på huber';
	@override String get showServerNameOnHubsDescription => 'Vis alltid servernavn i hubtitler.';
	@override String get groupLibrariesByServer => 'Grupper biblioteker etter server';
	@override String get groupLibrariesByServerDescription => 'Grupper sidepanelbiblioteker under hver medieserver.';
	@override String get alwaysKeepSidebarOpen => 'Hold sidefeltet alltid åpent';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg';
	@override String get showUnwatchedCount => 'Vis antall usette';
	@override String get showUnwatchedCountDescription => 'Vis antall usette episoder på serier og sesonger';
	@override String get showEpisodeNumberOnCards => 'Vis episodenummer på kort';
	@override String get showEpisodeNumberOnCardsDescription => 'Vis sesong- og episodenummer på episodekort';
	@override String get showSeasonPostersOnTabs => 'Vis sesongplakater på faner';
	@override String get showSeasonPostersOnTabsDescription => 'Vis hver sesongs plakat over fanen';
	@override String get tvFullCardLayout => 'Fulle TV-kort';
	@override String get tvFullCardLayoutDescription => 'Bruk bildebaserte TV-kort med skuespillernavn lagt over';
	@override String get focusGlow => 'Fokusglød';
	@override String get focusGlowDescription => 'Vis en myk glød rundt kortet i fokus';
	@override String get visualEffects => 'Visuelle effekter';
	@override String get visualEffectsAuto => 'Automatisk';
	@override String get visualEffectsAutoDescription => 'Reduser effekter automatisk på enheter med lavt strømforbruk';
	@override String get visualEffectsFull => 'Full';
	@override String get visualEffectsReduced => 'Redusert';
	@override String get visualEffectsReducedDescription => 'Færre animasjoner og grafikk med lavere oppløsning';
	@override String get hideSpoilers => 'Skjul spoilere for usette episoder';
	@override String get hideSpoilersDescription => 'Slør miniatyrbilder og beskrivelser for usette episoder';
	@override String get playerBackend => 'Spillermotor';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Maskinvaredekoding';
	@override String get hardwareDecodingDescription => 'Bruk maskinvareakselerasjon når tilgjengelig';
	@override String get bufferSize => 'Bufferstørrelse';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Anbefalt)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB minne tilgjengelig. En buffer på ${size}MB kan påvirke avspilling.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get musicQualityTitle => 'Musikkvalitet';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpass utseendet på undertekster';
	@override String get smallSkipDuration => 'Kort hoppvarighet';
	@override String get largeSkipDuration => 'Lang hoppvarighet';
	@override String get rewindOnResume => 'Spol tilbake ved gjenopptakelse';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard søvntimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutter';
	@override String get rememberTrackSelections => 'Husk sporvalg per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Husk lyd- og undertekstvalg per tittel';
	@override String get showChapterMarkersOnTimeline => 'Vis kapittelmarkører på tidslinjen';
	@override String get showChapterMarkersOnTimelineDescription => 'Del tidslinjen ved kapittelgrenser';
	@override String get clickVideoTogglesPlayback => 'Klikk på video for å veksle avspilling';
	@override String get clickVideoTogglesPlaybackDescription => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.';
	@override String get videoPlayerControls => 'Videospillerkontroller';
	@override String get keyboardShortcuts => 'Tastatursnarveier';
	@override String get keyboardShortcutsDescription => 'Tilpass tastatursnarveier';
	@override String get videoPlayerNavigation => 'Videospillernavigering';
	@override String get videoPlayerNavigationDescription => 'Bruk piltaster for å navigere videospillerkontroller';
	@override String get watchTogetherRelay => 'Se Sammen-relay';
	@override String get watchTogetherRelayDescription => 'Angi en egendefinert relay. Alle må bruke samme server.';
	@override String get watchTogetherRelayHint => 'https://min-relay.eksempel.no';
	@override String get crashReporting => 'Krasjrapportering';
	@override String get crashReportingDescription => 'Send krasjrapporter for å hjelpe med å forbedre appen';
	@override String get debugLogging => 'Feilsøkingslogging';
	@override String get debugLoggingDescription => 'Aktiver detaljert logging for feilsøking';
	@override String get viewLogs => 'Vis logger';
	@override String get viewLogsDescription => 'Vis applikasjonslogger';
	@override String get clearCache => 'Tøm hurtigbuffer';
	@override String get clearCacheDescription => 'Tøm bufrede bilder og data. Innhold kan lastes tregere.';
	@override String get clearCacheSuccess => 'Hurtigbuffer tømt';
	@override String get resetSettings => 'Tilbakestill innstillinger';
	@override String get resetSettingsDescription => 'Gjenopprett standardinnstillinger. Dette kan ikke angres.';
	@override String get resetSettingsSuccess => 'Innstillinger tilbakestilt';
	@override String get backup => 'Sikkerhetskopi';
	@override String get exportSettings => 'Eksporter innstillinger';
	@override String get exportSettingsDescription => 'Lagre innstillingene i en fil';
	@override String get exportSettingsSuccess => 'Innstillinger eksportert';
	@override String get exportSettingsFailed => 'Kunne ikke eksportere innstillinger';
	@override String get importSettings => 'Importer innstillinger';
	@override String get importSettingsDescription => 'Gjenopprett innstillinger fra en fil';
	@override String get importSettingsConfirm => 'Dette vil erstatte nåværende innstillinger. Fortsette?';
	@override String get importSettingsSuccess => 'Innstillinger importert';
	@override String get importSettingsFailed => 'Kunne ikke importere innstillinger';
	@override String get importSettingsInvalidFile => 'Denne filen er ikke en gyldig Plezy-innstillingseksport';
	@override String get importSettingsNoUser => 'Logg inn før import av innstillinger';
	@override String get shortcutsReset => 'Snarveier tilbakestilt til standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'Appinformasjon og lisenser';
	@override String get updates => 'Oppdateringer';
	@override String get updateAvailable => 'Oppdatering tilgjengelig';
	@override String get checkForUpdates => 'Se etter oppdateringer';
	@override String get autoCheckUpdatesOnStartup => 'Se automatisk etter oppdateringer ved oppstart';
	@override String get autoCheckUpdatesOnStartupDescription => 'Varsle når en oppdatering er tilgjengelig ved oppstart';
	@override String get validationErrorEnterNumber => 'Vennligst skriv inn et gyldig tall';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Varigheten må være mellom ${min} og ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Snarvei allerede tilordnet til ${action}';
	@override String shortcutUpdated({required Object action}) => 'Snarvei oppdatert for ${action}';
	@override String get autoSkip => 'Automatisk hopp';
	@override String get autoSkipIntro => 'Hopp over intro automatisk';
	@override String get autoSkipIntroDescription => 'Hopp automatisk over intromarkører etter noen sekunder';
	@override String get autoSkipCredits => 'Hopp over rulletekst automatisk';
	@override String get autoSkipCreditsDescription => 'Hopp automatisk over rulletekst og spill neste episode';
	@override String get forceSkipMarkerFallback => 'Tving reservemarkører';
	@override String get forceSkipMarkerFallbackDescription => 'Bruk mønstre i kapiteltitler selv når Plex har markører';
	@override String get autoSkipDelay => 'Forsinkelse for automatisk hopp';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping';
	@override String get introPattern => 'Intromarkørmønster';
	@override String get introPatternDescription => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler';
	@override String get creditsPattern => 'Rulletekstmarkørmønster';
	@override String get creditsPatternDescription => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler';
	@override String get invalidRegex => 'Ugyldig regulært uttrykk';
	@override String get regex => 'Regulært uttrykk';
	@override String get downloads => 'Nedlastinger';
	@override String get downloadLocationDescription => 'Velg hvor nedlastet innhold skal lagres';
	@override String get downloadLocationDefault => 'Standard (App-lagring)';
	@override String get downloadLocationCustom => 'Egendefinert plassering';
	@override String get selectFolder => 'Velg mappe';
	@override String get resetToDefault => 'Tilbakestill til standard';
	@override String currentPath({required Object path}) => 'Gjeldende: ${path}';
	@override String get downloadLocationChanged => 'Nedlastingsplassering endret';
	@override String get downloadLocationReset => 'Nedlastingsplassering tilbakestilt til standard';
	@override String get downloadLocationInvalid => 'Valgt mappe er ikke skrivbar';
	@override String get downloadLocationSelectError => 'Kunne ikke velge mappe';
	@override String get downloadOnWifiOnly => 'Last ned kun på WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Forhindre nedlastinger på mobildata';
	@override String get autoRemoveWatchedDownloads => 'Fjern sette nedlastinger automatisk';
	@override String get autoRemoveWatchedDownloadsDescription => 'Slett sette nedlastinger automatisk';
	@override String get cellularDownloadBlocked => 'Nedlastinger er blokkert på mobilnett. Bruk WiFi eller endre innstillingen.';
	@override String get maxVolume => 'Maks volum';
	@override String get maxVolumeDescription => 'Tillat volumforsterkning over 100% for stille media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Vis hva du ser på Discord';
	@override String get services => 'Tjenester';
	@override String get servicesDescription => 'Koble til Trakt, MyAnimeList, Seerr og mer';
	@override String get manageLibrariesDescription => 'Omorganiser og skjul biblioteker';
	@override String get companionRemoteServer => 'Companion Remote-server';
	@override String get companionRemoteServerDescription => 'Tillat mobilenheter på nettverket ditt å styre denne appen';
	@override String get autoPip => 'Auto bilde-i-bilde';
	@override String get autoPipDescription => 'Gå til bilde-i-bilde når du forlater under avspilling';
	@override String get matchContentFrameRate => 'Tilpass innholdets bildefrekvens';
	@override String get matchContentFrameRateDescription => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold';
	@override String get matchRefreshRate => 'Tilpass oppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm';
	@override String get matchDynamicRange => 'Tilpass dynamisk område';
	@override String get matchDynamicRangeDescription => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR';
	@override String get displaySwitchDelay => 'Forsinkelse ved skjermbytte';
	@override String get tunneledPlayback => 'Tunnelert avspilling';
	@override String get tunneledPlaybackDescription => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video.';
	@override String get audioPassthrough => 'Lydgjennomgang';
	@override String get audioPassthroughDescription => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.';
	@override String get audioPassthroughDescriptionAppleTv => 'Overlater Dolby Digital Plus (inkl. Atmos) til systemet som bitstream. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Korte lydbrudd kan forekomme ved søking.';
	@override String get audioDownmix => 'Nedmiks til stereo';
	@override String get audioDownmixDescription => 'Mikser surroundlyd ned til to kanaler for stereohøyttalere eller hodetelefoner';
	@override String get downmixCenterBoost => 'Forsterkning av senterkanal';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Forsterkning (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normaliser lydstyrke ved nedmiks';
	@override String get audioDownmixNormalizeDescription => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).';
	@override String get atmosDiagnostics => 'Atmos-utgangstest';
	@override String get atmosDiagnosticsDescription => 'Diagnostiser Dolby Atmos-utgangen ved å spille testsignaler gjennom systemspilleren';
	@override String get atmosTestHlsAtmos => 'Apple Atmos-strøm';
	@override String get atmosTestHlsAtmosDescription => 'Kjent god Dolby Atmos-strøm. Mottakeren bør vise Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Apple surround-strøm';
	@override String get atmosTestHlsControlDescription => 'Kontrollstrøm uten Atmos. Mottakeren bør vise surround uten Atmos.';
	@override String get atmosTestRawStream => 'Rå EAC3-strøm';
	@override String get atmosTestRawStreamDescription => 'Strømmer testfilen akkurat som Atmos-avspilling i spilleren. Krever testfilens URL.';
	@override String get atmosTestRawFile => 'Rå EAC3-fil';
	@override String get atmosTestRawFileDescription => 'Spiller av testfilen med kjent lengde. Krever testfilens URL.';
	@override String get atmosTestStop => 'Stopp test';
	@override String get atmosTestUrl => 'Testfilens URL';
	@override String get atmosTestUrlDescription => 'HTTP-URL til en rå .ec3 Dolby Atmos-fil (f.eks. hentet ut med ffmpeg)';
	@override String get atmosTestUrlMissing => 'Angi testfilens URL først';
	@override String get atmosTestStatus => 'Status';
	@override String get dvConversionMode => 'Dolby Vision-konvertering';
	@override String get dvConversionModeDescription => 'Velg hvordan ExoPlayer håndterer Dolby Vision Profile 7-filer.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Innebygd / deaktivert';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Bruk enhetens kapabilitetsdeteksjon og normal reserveoppførsel';
	@override String get dvConversionNativeDescription => 'Tving native DV7 og undertrykk forsøk på DV-konvertering';
	@override String get dvConversionDv81Description => 'Tving inline RPU-konvertering til Dolby Vision profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Fjern Dolby Vision RPU/EL-lag og presenter vanlig HEVC';
	@override String get requireProfileSelectionOnOpen => 'Spør om profil ved appåpning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åpnes';
	@override String get forceTvMode => 'Tving TV-modus';
	@override String get forceTvModeDescription => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.';
	@override String get startInFullscreen => 'Start i fullskjerm';
	@override String get startInFullscreenDescription => 'Åpne Plezy i fullskjermmodus ved oppstart';
	@override String get exitFullscreenOnPlayerClose => 'Avslutt fullskjerm ved lukking av avspiller';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Avslutt fullskjerm automatisk når videospilleren lukkes';
	@override String get autoHidePerformanceOverlay => 'Skjul ytelsesoverlegg automatisk';
	@override String get autoHidePerformanceOverlayDescription => 'Fade ytelsesoverlegget med avspillingskontrollene';
	@override String get showNavBarLabels => 'Vis navigasjonsfeltlabeler';
	@override String get showNavBarLabelsDescription => 'Vis tekstlabeler under navigasjonsfeltikoner';
	@override String get startupSection => 'Oppstartsseksjon';
	@override String get liveTvDefaultFavorites => 'Standard til favorittkanaler';
	@override String get liveTvDefaultFavoritesDescription => 'Vis kun favorittkanaler når du åpner Live TV';
	@override String get display => 'Skjerm';
	@override String get homeScreen => 'Hjemmeskjerm';
	@override String get navigation => 'Navigering';
	@override String get window => 'Vindu';
	@override String get content => 'Innhold';
	@override String get player => 'Spiller';
	@override String get subtitlesAndConfig => 'Undertekster og konfigurasjon';
	@override String get seekAndTiming => 'Søk og tidtaking';
	@override String get behavior => 'Atferd';
}

// Path: search
class _TranslationsSearchNb extends TranslationsSearchEn {
	_TranslationsSearchNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Søk i filmer, serier, musikk...';
	@override String get tryDifferentTerm => 'Prøv et annet søkeord';
	@override String get searchYourMedia => 'Søk i mediene dine';
	@override String get enterTitleActorOrKeyword => 'Skriv inn tittel, skuespiller eller nøkkelord';
}

// Path: hotkeys
class _TranslationsHotkeysNb extends TranslationsHotkeysEn {
	_TranslationsHotkeysNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Angi snarvei for ${actionName}';
	@override String get clearShortcut => 'Fjern snarvei';
	@override String get noShortcutSet => 'Ingen snarvei satt';
	@override String get currentShortcut => 'Gjeldende snarvei:';
	@override String get pressToRecord => 'Velg for å registrere en snarvei';
	@override String get recordingShortcut => 'Trykk på snarveien nå';
	@override late final _TranslationsHotkeysActionsNb actions = _TranslationsHotkeysActionsNb._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoNb extends TranslationsFileInfoEn {
	_TranslationsFileInfoNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filinformasjon';
	@override String get video => 'Video';
	@override String get audio => 'Lyd';
	@override String get file => 'Fil';
	@override String get advanced => 'Avansert';
	@override String get codec => 'Kodek';
	@override String get resolution => 'Oppløsning';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildefrekvens';
	@override String get aspectRatio => 'Sideforhold';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Bitdybde';
	@override String get colorSpace => 'Fargerom';
	@override String get colorRange => 'Fargeområde';
	@override String get colorPrimaries => 'Fargeprimærer';
	@override String get chromaSubsampling => 'Krominansnedsampling';
	@override String get channels => 'Kanaler';
	@override String get subtitles => 'Undertekster';
	@override String get overallBitrate => 'Total bitrate';
	@override String get path => 'Sti';
	@override String get size => 'Størrelse';
	@override String get container => 'Beholder';
	@override String get duration => 'Varighet';
	@override String get optimizedForStreaming => 'Optimalisert for strømming';
	@override String get has64bitOffsets => '64-biters forskyvninger';
}

// Path: mediaMenu
class _TranslationsMediaMenuNb extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Merk som sett';
	@override String get markAsUnwatched => 'Merk som usett';
	@override String get removeFromContinueWatching => 'Fjern fra Fortsett å se';
	@override String get viewDetails => 'Vis detaljer';
	@override String get goToSeries => 'Gå til serie';
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get shuffleNotAvailableOffline => 'Tilfeldig avspilling er ikke tilgjengelig offline';
	@override String get fileInfo => 'Filinformasjon';
	@override String get deleteFromServer => 'Slett fra server';
	@override String get confirmDelete => 'Slette dette mediet og filene fra serveren?';
	@override String get deleteMultipleWarning => 'Dette inkluderer alle episoder og deres filer.';
	@override String get mediaDeletedSuccessfully => 'Medieelement slettet';
	@override String get mediaFailedToDelete => 'Kunne ikke slette medieelement';
	@override String get rate => 'Vurder';
	@override String get playFromBeginning => 'Spill fra begynnelsen';
	@override String get playVersion => 'Spill av versjon...';
}

// Path: rateSheet
class _TranslationsRateSheetNb extends TranslationsRateSheetEn {
	_TranslationsRateSheetNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vurder';
	@override String get server => 'Server';
	@override String get favorite => 'Favoritt';
	@override String get favorited => 'Lagt til i favoritter';
	@override String get saved => 'Lagret';
	@override String get notAvailable => 'Ingen treff';
	@override String get noConnectedServices => 'Koble til en tjeneste i Innstillinger for å vurdere her.';
}

// Path: accessibility
class _TranslationsAccessibilityNb extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, TV-serie';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'sett';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} prosent sett';
	@override String get mediaCardUnwatched => 'usett';
	@override String get tapToPlay => 'Trykk for å spille';
	@override String get decrease => 'Reduser';
	@override String get increase => 'Øk';
	@override String decreaseValue({required Object label}) => 'Reduser ${label}';
	@override String increaseValue({required Object label}) => 'Øk ${label}';
	@override String get hue => 'Fargetone';
	@override String get saturation => 'Metning';
	@override String get brightness => 'Lysstyrke';
	@override String get hexColor => 'Heksadesimal farge';
	@override String get expandText => 'Utvid tekst';
	@override String get collapseText => 'Fold sammen tekst';
}

// Path: tooltips
class _TranslationsTooltipsNb extends TranslationsTooltipsEn {
	_TranslationsTooltipsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get playTrailer => 'Spill trailer';
	@override String get markAsWatched => 'Merk som sett';
	@override String get markAsUnwatched => 'Merk som usett';
}

// Path: videoControls
class _TranslationsVideoControlsNb extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Lyd';
	@override String get subtitlesLabel => 'Undertekster';
	@override String get resetToZero => 'Tilbakestill til 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} spilles senere';
	@override String playsEarlier({required Object label}) => '${label} spilles tidligere';
	@override String get noOffset => 'Ingen forskyvning';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Fyll skjerm';
	@override String get stretch => 'Strekk';
	@override String get lockRotation => 'Lås rotasjon';
	@override String get unlockRotation => 'Lås opp rotasjon';
	@override String get timerActive => 'Timer aktiv';
	@override String playbackWillPauseIn({required Object duration}) => 'Avspilling vil pause om ${duration}';
	@override String get sleepTimerEndOfVideo => 'Slutten av gjeldende video';
	@override String get sleepTimerStopAtHeader => 'Stopp ved';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'Avspilling vil pause på slutten av denne videoen';
	@override String get stillWatching => 'Ser du fortsatt?';
	@override String pausingIn({required Object seconds}) => 'Pauser om ${seconds}s';
	@override String get continueWatching => 'Fortsett';
	@override String get autoPlayNext => 'Spill neste automatisk';
	@override String get playNext => 'Spill neste';
	@override String get playButton => 'Spill av';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => 'Spol tilbake ${seconds} sekunder';
	@override String seekForwardButton({required Object seconds}) => 'Spol fremover ${seconds} sekunder';
	@override String get previousButton => 'Forrige episode';
	@override String get nextButton => 'Neste episode';
	@override String get previousChapterButton => 'Forrige kapittel';
	@override String get nextChapterButton => 'Neste kapittel';
	@override String get muteButton => 'Demp';
	@override String get unmuteButton => 'Opphev demping';
	@override String get settingsButton => 'Avspillingsinnstillinger';
	@override String get tracksButton => 'Lyd og undertekster';
	@override String get chaptersButton => 'Kapitler';
	@override String get versionQualityButton => 'Versjon og kvalitet';
	@override String get versionColumnHeader => 'Versjon';
	@override String get qualityColumnHeader => 'Kvalitet';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transkoding utilgjengelig — spiller av i original kvalitet';
	@override String get pipButton => 'Bilde-i-bilde-modus';
	@override String get aspectRatioButton => 'Sideforhold';
	@override String get ambientLighting => 'Omgivelseslys';
	@override String get fullscreenButton => 'Gå til fullskjerm';
	@override String get exitFullscreenButton => 'Avslutt fullskjerm';
	@override String get alwaysOnTopButton => 'Alltid øverst';
	@override String get rotationLockButton => 'Rotasjonslås';
	@override String get lockScreen => 'Lås skjerm';
	@override String get screenLockButton => 'Skjermlås';
	@override String get longPressToUnlock => 'Langt trykk for å låse opp';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volumnivå';
	@override String endsAt({required Object time}) => 'Slutter kl. ${time}';
	@override String get pipActive => 'Spiller i bilde-i-bilde';
	@override String get pipFailed => 'Bilde-i-bilde kunne ikke starte';
	@override String get screenshotSaved => 'Skjermbilde lagret';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _TranslationsVideoControlsPipErrorsNb pipErrors = _TranslationsVideoControlsPipErrorsNb._(_root);
	@override String get chapters => 'Kapitler';
	@override String get noChaptersAvailable => 'Ingen kapitler tilgjengelig';
	@override String get queue => 'Kø';
	@override String get noQueueItems => 'Ingen elementer i kø';
	@override String get searchSubtitles => 'Søk etter undertekster';
	@override String get language => 'Språk';
	@override String get noSubtitlesFound => 'Ingen undertekster funnet';
	@override String get downloadedSubtitle => 'Lastet ned';
	@override String get noSubtitlesAvailable => 'Ingen undertekster tilgjengelig';
	@override String get noAudioTracksAvailable => 'Ingen lydspor tilgjengelig';
	@override String get noTracksAvailable => 'Ingen spor tilgjengelig';
	@override String get subtitleDownloaded => 'Undertekst lastet ned';
	@override String get subtitleDownloadFailed => 'Kunne ikke laste ned undertekst';
	@override String get searchLanguages => 'Søk etter språk...';
}

// Path: messages
class _TranslationsMessagesNb extends TranslationsMessagesEn {
	_TranslationsMessagesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Merket som sett';
	@override String get markedAsUnwatched => 'Merket som usett';
	@override String get markedAsWatchedOffline => 'Merket som sett (synkroniseres når tilkoblet)';
	@override String get markedAsUnwatchedOffline => 'Merket som usett (synkroniseres når tilkoblet)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisk fjernet: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Fjernet automatisk ${n} sett nedlasting',
		other: 'Fjernet automatisk ${n} sette nedlastinger',
	);
	@override String get removedFromContinueWatching => 'Fjernet fra Fortsett å se';
	@override String errorLoading({required Object error}) => 'Feil: ${error}';
	@override String get streamInterrupted => 'Avspillingen ble avbrutt. Trykk på Spill av eller spol for å prøve på nytt.';
	@override String get liveStreamInterrupted => 'Direktesendingen ble avbrutt. Trykk på Spill av for å prøve på nytt.';
	@override String get fileInfoNotAvailable => 'Filinformasjon ikke tilgjengelig';
	@override String errorLoadingFileInfo({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}';
	@override String get errorLoadingSeries => 'Feil ved lasting av serie';
	@override String get musicNotSupported => 'Musikkavspilling støttes ikke ennå';
	@override String get noDescriptionAvailable => 'Ingen beskrivelse tilgjengelig';
	@override String get noProfilesAvailable => 'Ingen profiler tilgjengelige';
	@override String get contactAdminForProfiles => 'Kontakt serveradministratoren din for å legge til profiler';
	@override String get unableToDetermineLibrarySection => 'Kan ikke fastslå bibliotekseksjonen for dette elementet';
	@override String get logsCleared => 'Logger tømt';
	@override String get logsCopied => 'Logger kopiert til utklippstavle';
	@override String get noLogsAvailable => 'Ingen logger tilgjengelig';
	@override String libraryScanning({required Object title}) => 'Skanner "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Bibliotekkanning startet for "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Kunne ikke skanne bibliotek: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Oppdaterer metadata for "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Metadataoppdatering startet for "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Kunne ikke oppdatere metadata: ${error}';
	@override String get logoutConfirm => 'Er du sikker på at du vil logge ut?';
	@override String get noSeasonsFound => 'Ingen sesonger funnet';
	@override String get seasonsLoadFailed => 'Kunne ikke laste sesonger';
	@override String get noEpisodesFound => 'Ingen episoder funnet i første sesong';
	@override String get noEpisodesFoundGeneral => 'Ingen episoder funnet';
	@override String get episodesLoadFailed => 'Kunne ikke laste episoder';
	@override String get noResultsFound => 'Ingen resultater funnet';
	@override String sleepTimerSet({required Object label}) => 'Søvntimer satt til ${label}';
	@override String get noItemsAvailable => 'Ingen elementer tilgjengelig';
	@override String get failedToCreatePlayQueueNoItems => 'Kunne ikke opprette avspillingskø – ingen elementer';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Bytter til kompatibel spiller...';
	@override String get serverLimitTitle => 'Avspilling mislyktes';
	@override String get serverLimitBody => 'Serverfeil (HTTP 500). En båndbredde-/transkodingsgrense avviste trolig økten. Be eieren justere den.';
	@override String get logsUploaded => 'Logger lastet opp';
	@override String get logsUploadFailed => 'Kunne ikke laste opp logger';
	@override String get logId => 'Logg-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingNb extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get text => 'Tekst';
	@override String get border => 'Kantlinje';
	@override String get background => 'Bakgrunn';
	@override String get fontSize => 'Skriftstørrelse';
	@override String get textColor => 'Tekstfarge';
	@override String get borderSize => 'Kantstørrelse';
	@override String get borderColor => 'Kantfarge';
	@override String get backgroundOpacity => 'Bakgrunnsopasitet';
	@override String get backgroundColor => 'Bakgrunnsfarge';
	@override String get position => 'Posisjon';
	@override String get assOverride => 'ASS-overstyring';
	@override String get overrideScale => 'Skaler';
	@override String get overrideForce => 'Tving';
	@override String get overrideStrip => 'Fjern formatering';
	@override String get positionTop => 'Øverst';
	@override String get positionBottom => 'Nederst';
	@override String get bold => 'Fet';
	@override String get italic => 'Kursiv';
	@override String get renderResolution => 'Gjengivelsesoppløsning';
	@override String get renderResolutionScreen => 'Skjermoppløsning';
	@override String get renderResolutionVideo => 'Videooppløsning';
}

// Path: mpvConfig
class _TranslationsMpvConfigNb extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Avanserte videospillerinnstillinger';
	@override String get presets => 'Forhåndsinnstillinger';
	@override String get noPresets => 'Ingen lagrede forhåndsinnstillinger';
	@override String get saveAsPreset => 'Lagre som forhåndsinnstilling...';
	@override String get presetName => 'Forhåndsinnstillingsnavn';
	@override String get presetNameHint => 'Skriv inn et navn for denne forhåndsinnstillingen';
	@override String get loadPreset => 'Last inn';
	@override String get deletePreset => 'Slett';
	@override String get presetSaved => 'Forhåndsinnstilling lagret';
	@override String get presetLoaded => 'Forhåndsinnstilling lastet inn';
	@override String get presetDeleted => 'Forhåndsinnstilling slettet';
	@override String get confirmDeletePreset => 'Er du sikker på at du vil slette denne forhåndsinnstillingen?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# kommentar';
}

// Path: dialog
class _TranslationsDialogNb extends TranslationsDialogEn {
	_TranslationsDialogNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekreft handling';
}

// Path: profiles
class _TranslationsProfilesNb extends TranslationsProfilesEn {
	_TranslationsProfilesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Legg til Plezy-profil';
	@override String get switchingProfile => 'Bytter profil…';
	@override String get deleteThisProfileTitle => 'Slett denne profilen?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Fjern ${displayName}. Tilkoblinger påvirkes ikke.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Administrer';
	@override String get delete => 'Slett';
	@override String get signOut => 'Logg ut';
	@override String get signOutPlexTitle => 'Logge ut av Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Fjerne ${displayName} og alle Plex Home-brukere? Du kan logge inn igjen når som helst.';
	@override String get signedOutPlex => 'Logget ut av Plex.';
	@override String get signOutFailed => 'Utlogging mislyktes.';
	@override String get sectionTitle => 'Profiler';
	@override String get summarySingle => 'Legg til profiler for å blande administrerte brukere og lokale identiteter';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profiler';
	@override String get removeConnectionTitle => 'Fjerne tilkobling?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Fjern ${displayName}s tilgang til ${connectionLabel}. Andre profiler beholder den.';
	@override String get deleteProfileTitle => 'Slette profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Fjern ${displayName} og tilkoblingene. Servere forblir tilgjengelige.';
	@override String get profileNameLabel => 'Profilnavn';
	@override String get pinProtectionLabel => 'PIN-beskyttelse';
	@override String get pinManagedByPlex => 'PIN administreres av Plex. Rediger på plex.tv.';
	@override String get noPinSetEditOnPlex => 'Ingen PIN er satt. For å kreve én, rediger Home-brukeren på plex.tv.';
	@override String get setPin => 'Sett PIN';
	@override String get setPinTitle => 'Sett PIN';
	@override String get confirmPinTitle => 'Bekreft PIN';
	@override String get pinSet => 'PIN satt';
	@override String get changePin => 'Endre';
	@override String get removePin => 'Fjern';
	@override String get connectionsLabel => 'Tilkoblinger';
	@override String get add => 'Legg til';
	@override String get deleteProfileButton => 'Slett profil';
	@override String get noConnectionsHint => 'Ingen tilkoblinger — legg til én for å bruke denne profilen.';
	@override String get noConnections => 'Ingen tilkoblinger';
	@override String get plexHomeAccount => 'Plex Home-konto';
	@override String get connectionDefault => 'Standard';
	@override String connectionAs({required Object displayName}) => 'som ${displayName}';
	@override String get makeDefault => 'Gjør til standard';
	@override String get removeConnection => 'Fjern';
	@override String get profileRenamed => 'Profilen er omdøpt.';
	@override String borrowAddTo({required Object displayName}) => 'Legg til ${displayName}';
	@override String get borrowExplain => 'Lån en annen profils tilkobling. PIN-beskyttede profiler krever PIN.';
	@override String get borrowEmpty => 'Ingenting å låne enda.';
	@override String get borrowEmptySubtitle => 'Koble Plex eller Jellyfin til en annen profil først.';
	@override String borrowFromProfile({required Object displayName}) => 'Fra ${displayName}';
	@override String get borrowConnectionBorrowed => 'Tilkobling lånt.';
	@override String get borrowFailed => 'Kunne ikke låne tilkoblingen.';
	@override String get incorrectPin => 'Feil PIN.';
	@override String get incorrectPinTryAgain => 'Feil PIN. Prøv igjen.';
	@override String get sourceProfileMissingParentAccount => 'Kildeprofilen mangler foreldrekontoen sin.';
	@override String get failedToLoadHomeUsers => 'Kunne ikke laste inn Plex Home-brukerne dine. Sjekk tilkoblingen og prøv igjen.';
	@override String get failedToVerifyPin => 'Kunne ikke bekrefte PIN.';
	@override String get newProfile => 'Ny profil';
	@override String get profileNameHint => 'f.eks. Gjester, Barn, Familierom';
	@override String get pinProtectionOptional => 'PIN-beskyttelse (valgfri)';
	@override String get pinExplain => '4-sifret PIN kreves for å bytte profiler.';
	@override String get continueButton => 'Fortsett';
	@override String get pinsDontMatch => 'PIN-ene samsvarer ikke';
}

// Path: connections
class _TranslationsConnectionsNb extends TranslationsConnectionsEn {
	_TranslationsConnectionsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Tilkoblinger';
	@override String get addConnection => 'Legg til tilkobling';
	@override String get addConnectionSubtitleNoProfile => 'Logg inn med Plex eller koble til en Jellyfin-server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Legg til for ${displayName}: Plex, Jellyfin eller en annen profiltilkobling';
	@override String sessionExpiredOne({required Object name}) => 'Økten er utløpt for ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Økten er utløpt for ${count} servere';
	@override String get signInAgain => 'Logg inn igjen';
	@override String get editJellyfinTitle => 'Rediger Jellyfin-tilkobling';
	@override String editJellyfinIntro({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. Plezy bruker den tilgjengelige URL-en med lavest forsinkelse.';
}

// Path: discover
class _TranslationsDiscoverNb extends TranslationsDiscoverEn {
	_TranslationsDiscoverNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oppdag';
	@override String get noContentAvailable => 'Ingen innhold tilgjengelig';
	@override String get addMediaToLibraries => 'Legg til medier i bibliotekene dine';
	@override String get continueWatching => 'Fortsett å se';
	@override String continueWatchingIn({required Object library}) => 'Fortsett å se i ${library}';
	@override String get nextUp => 'Neste opp';
	@override String nextUpIn({required Object library}) => 'Neste opp i ${library}';
	@override String get recentlyAdded => 'Nylig lagt til';
	@override String recentlyAddedIn({required Object library}) => 'Nylig lagt til i ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Nyeste album i ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Nylig spilt i ${library}';
	@override String mostPlayedIn({required Object library}) => 'Mest spilt i ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Oversikt';
	@override String get cast => 'Skuespillere';
	@override String get extras => 'Trailere og ekstra';
	@override String get studio => 'Studio';
	@override String get rating => 'Vurdering';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min igjen';
	@override String get moreLikeThis => 'Mer som dette';
}

// Path: errors
class _TranslationsErrorsNb extends TranslationsErrorsEn {
	_TranslationsErrorsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Søk mislyktes: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tidsavbrudd ved lasting av ${context}';
	@override String get connectionFailed => 'Kan ikke koble til medieserver';
	@override String unableToLoad({required Object context}) => 'Kunne ikke laste ${context}. Prøv igjen.';
	@override String get noClientAvailable => 'Ingen klient tilgjengelig';
	@override String get pleaseEnterToken => 'Vennligst skriv inn et token';
	@override String get invalidToken => 'Ugyldig token';
	@override String failedToVerifyToken({required Object error}) => 'Kunne ikke verifisere token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kunne ikke bytte til ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Kunne ikke slette ${displayName}';
	@override String get failedToRate => 'Kunne ikke oppdatere vurderingen';
}

// Path: libraries
class _TranslationsLibrariesNb extends TranslationsLibrariesEn {
	_TranslationsLibrariesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteker';
	@override String get fallbackTitle => 'Bibliotek';
	@override String get scanLibraryFiles => 'Skann bibliotekfiler';
	@override String get scanLibrary => 'Skann bibliotek';
	@override String get analyze => 'Analyser';
	@override String get analyzeLibrary => 'Analyser bibliotek';
	@override String get refreshMetadata => 'Oppdater metadata';
	@override String get emptyTrash => 'Tøm papirkurv';
	@override String emptyingTrash({required Object title}) => 'Tømmer papirkurv for "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papirkurv tømt for "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Kunne ikke tømme papirkurv: ${error}';
	@override String analyzing({required Object title}) => 'Analyserer "${title}"...';
	@override String analysisStarted({required Object title}) => 'Analyse startet for "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Kunne ikke analysere bibliotek: ${error}';
	@override String get noLibrariesFound => 'Ingen biblioteker funnet';
	@override String get allLibrariesHidden => 'Alle biblioteker er skjult';
	@override String hiddenLibrariesCount({required Object count}) => 'Skjulte biblioteker (${count})';
	@override String get thisLibraryIsEmpty => 'Dette biblioteket er tomt';
	@override String get noItemsMatchFilters => 'Ingen elementer samsvarer med de aktive filtrene';
	@override String get resetFilters => 'Tilbakestill filtre';
	@override String get all => 'Alle';
	@override String get clearAll => 'Tøm alle';
	@override String scanLibraryConfirm({required Object title}) => 'Er du sikker på at du vil skanne "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Er du sikker på at du vil analysere "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Er du sikker på at du vil oppdatere metadata for "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Er du sikker på at du vil tømme papirkurven for "${title}"?';
	@override String get manageLibraries => 'Administrer biblioteker';
	@override String get sort => 'Sorter';
	@override String get sortBy => 'Sorter etter';
	@override String get filters => 'Filtre';
	@override String get confirmActionMessage => 'Er du sikker på at du vil utføre denne handlingen?';
	@override String get showLibrary => 'Vis bibliotek';
	@override String get hideLibrary => 'Skjul bibliotek';
	@override String get libraryOptions => 'Bibliotekalternativer';
	@override String get content => 'bibliotekinnhold';
	@override String get selectLibrary => 'Velg bibliotek';
	@override String filtersWithCount({required Object count}) => 'Filtre (${count})';
	@override String get noRecommendations => 'Ingen anbefalinger tilgjengelig';
	@override String get noCollections => 'Ingen samlinger i dette biblioteket';
	@override String get noFoldersFound => 'Ingen mapper funnet';
	@override String get folders => 'mapper';
	@override late final _TranslationsLibrariesTabsNb tabs = _TranslationsLibrariesTabsNb._(_root);
	@override late final _TranslationsLibrariesGroupingsNb groupings = _TranslationsLibrariesGroupingsNb._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesNb filterCategories = _TranslationsLibrariesFilterCategoriesNb._(_root);
	@override late final _TranslationsLibrariesSortLabelsNb sortLabels = _TranslationsLibrariesSortLabelsNb._(_root);
}

// Path: about
class _TranslationsAboutNb extends TranslationsAboutEn {
	_TranslationsAboutNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Åpen kildekode-lisenser';
	@override String versionLabel({required Object version}) => 'Versjon ${version}';
	@override String get appDescription => 'En vakker Plex- og Jellyfin-klient for Flutter';
	@override String get viewLicensesDescription => 'Vis lisenser for tredjepartsbiblioteker';
}

// Path: serverSelection
class _TranslationsServerSelectionNb extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kunne ikke laste servere: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailNb extends TranslationsHubDetailEn {
	_TranslationsHubDetailNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittel';
	@override String get releaseYear => 'Utgivelsesår';
	@override String get dateAdded => 'Dato lagt til';
	@override String get rating => 'Vurdering';
	@override String get noItemsFound => 'Ingen elementer funnet';
}

// Path: logs
class _TranslationsLogsNb extends TranslationsLogsEn {
	_TranslationsLogsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Tøm logger';
	@override String get copyLogs => 'Kopier logger';
	@override String get uploadLogs => 'Last opp logger';
}

// Path: licenses
class _TranslationsLicensesNb extends TranslationsLicensesEn {
	_TranslationsLicensesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterte pakker';
	@override String get license => 'Lisens';
	@override String licenseNumber({required Object number}) => 'Lisens ${number}';
	@override String licensesCount({required Object count}) => '${count} lisenser';
}

// Path: navigation
class _TranslationsNavigationNb extends TranslationsNavigationEn {
	_TranslationsNavigationNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteker';
	@override String get downloads => 'Nedlastinger';
	@override String get liveTv => 'Direkte-TV';
	@override String get explore => 'Utforsk';
}

// Path: explore
class _TranslationsExploreNb extends TranslationsExploreEn {
	_TranslationsExploreNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Utforsk';
	@override String get selectSource => 'Velg kilde';
	@override late final _TranslationsExploreRowsNb rows = _TranslationsExploreRowsNb._(_root);
	@override late final _TranslationsExploreStatusNb status = _TranslationsExploreStatusNb._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${n} episode',
		other: '${n} episoder',
	);
	@override String get cast => 'Skuespillere';
	@override String get characters => 'Figurer';
	@override String get addToWatchlist => 'Legg til i ønskeliste';
	@override String get removeFromWatchlist => 'Fjern fra ønskeliste';
	@override String get watchlistUpdateFailed => 'Kunne ikke oppdatere ønskelisten';
	@override String get notInLibrary => 'Ikke i biblioteket ditt';
	@override String get inTheseLibraries => 'I disse bibliotekene';
	@override String get checkingLibrary => 'Sjekker biblioteket ditt...';
	@override String get emptyTitle => 'Ingenting her ennå';
	@override String emptyMessage({required Object source}) => 'Rader fra ${source} vises her når de har innhold.';
	@override String searchHint({required Object source}) => 'Søk i ${source}';
	@override String searchEmpty({required Object query}) => 'Ingen treff for "${query}"';
	@override String searchPrompt({required Object source}) => 'Søk etter filmer og serier på ${source}.';
	@override String get searchFailed => 'Søk mislyktes. Sjekk tilkoblingen og prøv igjen.';
}

// Path: liveTv
class _TranslationsLiveTvNb extends TranslationsLiveTvEn {
	_TranslationsLiveTvNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Direkte-TV';
	@override String get guide => 'Programguide';
	@override String get noChannels => 'Ingen kanaler tilgjengelig';
	@override String get noDvr => 'Ingen DVR konfigurert på noen server';
	@override String get serverUnavailable => 'Direkte-TV-serveren er ikke tilgjengelig.';
	@override String get serverNotConnected => 'Direkte-TV-serveren er ikke tilkoblet.';
	@override String get noPrograms => 'Ingen programdata tilgjengelig';
	@override String get liveStreamFailed => 'Direktesending mislyktes';
	@override String get unknownProgram => 'Ukjent program';
	@override String get unknownHub => 'Ukjent';
	@override String get unknownError => 'Ukjent feil';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get unknownChannel => 'Ukjent kanal';
	@override String get live => 'DIREKTE';
	@override String get reloadGuide => 'Last inn programguide på nytt';
	@override String get now => 'Nå';
	@override String get today => 'I dag';
	@override String get tomorrow => 'I morgen';
	@override String get midnight => 'Midnatt';
	@override String get overnight => 'Natt';
	@override String get morning => 'Morgen';
	@override String get daytime => 'Dagtid';
	@override String get evening => 'Kveld';
	@override String get lateNight => 'Sen kveld';
	@override String get whatsOn => 'Hva går nå';
	@override String get watchChannel => 'Se kanal';
	@override String get favorites => 'Favoritter';
	@override String get reorderFavorites => 'Endre rekkefølge på favoritter';
	@override String get favoritesLoadFailed => 'Kunne ikke laste inn favoritter. Kontroller tilkoblingen og prøv på nytt.';
	@override String get joinSession => 'Bli med i pågående økt';
	@override String watchFromStart({required Object minutes}) => 'Se fra starten (${minutes} min siden)';
	@override String get watchLive => 'Se direkte';
	@override String get goToLive => 'Gå til direkte';
	@override String get record => 'Ta opp';
	@override String get recordEpisode => 'Ta opp episode';
	@override String get recordSeries => 'Ta opp serie';
	@override String get recordOptions => 'Opptaksvalg';
	@override String get saveTo => 'Lagre i';
	@override String get recordings => 'Opptak';
	@override String get scheduledRecordings => 'Planlagt';
	@override String get recordingRules => 'Opptaksregler';
	@override String get noScheduledRecordings => 'Ingen planlagte opptak';
	@override String get manageRecording => 'Administrer opptak';
	@override String get cancelRecording => 'Avbryt opptak';
	@override String get cancelRecordingTitle => 'Avbryte dette opptaket?';
	@override String cancelRecordingMessage({required Object title}) => '${title} blir ikke lenger tatt opp.';
	@override String get deleteRule => 'Slett regel';
	@override String get deleteRuleTitle => 'Slette opptaksregel?';
	@override String deleteRuleMessage({required Object title}) => 'Fremtidige episoder av ${title} blir ikke tatt opp.';
	@override String get recordingScheduled => 'Opptak planlagt';
	@override String get alreadyScheduled => 'Dette programmet er allerede planlagt';
	@override String get dvrAdminRequired => 'DVR-innstillinger krever en administratorkonto';
	@override String get recordingFailed => 'Kunne ikke planlegge opptak';
	@override String get recordingTargetMissing => 'Kunne ikke finne opptaksbibliotek';
	@override String get recordNotAvailable => 'Opptak er ikke tilgjengelig for dette programmet';
	@override String get recordingCancelled => 'Opptak avbrutt';
	@override String get recordingRuleDeleted => 'Opptaksregel slettet';
	@override String get processRecordingRules => 'Vurder regler på nytt';
	@override String get recordingInProgress => 'Tar opp nå';
	@override String recordingsCount({required Object count}) => '${count} planlagt';
	@override String get editRule => 'Rediger regel';
	@override String get editRuleAction => 'Rediger';
	@override String get recordingRuleUpdated => 'Opptaksregel oppdatert';
	@override String get guideReloadRequested => 'Forespurte guide-oppdatering';
	@override String get rulesProcessRequested => 'Forespurte regelevaluering';
	@override String get recordShow => 'Ta opp program';
}

// Path: collections
class _TranslationsCollectionsNb extends TranslationsCollectionsEn {
	_TranslationsCollectionsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlinger';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen er tom';
	@override String get deleteCollection => 'Slett samling';
	@override String deleteConfirm({required Object title}) => 'Slette "${title}"? Dette kan ikke angres.';
	@override String get deleted => 'Samling slettet';
	@override String get deleteFailed => 'Kunne ikke slette samling';
	@override String deleteFailedWithError({required Object error}) => 'Kunne ikke slette samling: ${error}';
	@override String get selectCollection => 'Velg samling';
	@override String get collectionName => 'Samlingsnavn';
	@override String get enterCollectionName => 'Skriv inn samlingsnavn';
	@override String get addedToCollection => 'Lagt til i samling';
	@override String get errorAddingToCollection => 'Kunne ikke legge til i samling';
	@override String get created => 'Samling opprettet';
	@override String get removeFromCollection => 'Fjern fra samling';
	@override String removeFromCollectionConfirm({required Object title}) => 'Fjerne "${title}" fra denne samlingen?';
	@override String get removedFromCollection => 'Fjernet fra samling';
	@override String get removeFromCollectionFailed => 'Kunne ikke fjerne fra samling';
	@override String removeFromCollectionError({required Object error}) => 'Feil ved fjerning fra samling: ${error}';
	@override String get searchCollections => 'Søk i samlinger...';
}

// Path: playlists
class _TranslationsPlaylistsNb extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Spillelister';
	@override String get playlist => 'Spilleliste';
	@override String get noPlaylists => 'Ingen spillelister funnet';
	@override String get create => 'Opprett spilleliste';
	@override String get playlistName => 'Spillelistenavn';
	@override String get enterPlaylistName => 'Skriv inn spillelistenavn';
	@override String get delete => 'Slett spilleliste';
	@override String get removeItem => 'Fjern fra spilleliste';
	@override String get smartPlaylist => 'Smart spilleliste';
	@override String itemCount({required Object count}) => '${count} elementer';
	@override String get oneItem => '1 element';
	@override String get emptyPlaylist => 'Denne spillelisten er tom';
	@override String get deleteConfirm => 'Slett spilleliste?';
	@override String deleteMessage({required Object name}) => 'Er du sikker på at du vil slette "${name}"?';
	@override String get created => 'Spilleliste opprettet';
	@override String get deleted => 'Spilleliste slettet';
	@override String get itemAdded => 'Lagt til i spilleliste';
	@override String get itemRemoved => 'Fjernet fra spilleliste';
	@override String get selectPlaylist => 'Velg spilleliste';
	@override String get searchPlaylists => 'Søk i spillelister...';
	@override String get errorCreating => 'Kunne ikke opprette spilleliste';
	@override String get errorDeleting => 'Kunne ikke slette spilleliste';
	@override String get errorLoading => 'Kunne ikke laste spillelister';
	@override String get errorAdding => 'Kunne ikke legge til i spilleliste';
	@override String get errorReordering => 'Kunne ikke omorganisere spillelisteelement';
	@override String get errorRemoving => 'Kunne ikke fjerne fra spilleliste';
}

// Path: music
class _TranslationsMusicNb extends TranslationsMusicEn {
	_TranslationsMusicNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Gå til album';
	@override String get goToArtist => 'Gå til artist';
	@override String get instantMix => 'Direktemiks';
	@override String get playNext => 'Spill neste';
	@override String get addToQueue => 'Legg til i kø';
	@override String discNumber({required Object n}) => 'Plate ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${n} spor',
		other: '${n} spor',
	);
	@override String get nowPlaying => 'Spilles nå';
	@override String playingFrom({required Object title}) => 'Spiller fra ${title}';
	@override String get queue => 'Kø';
	@override String get clearQueue => 'Tøm kø';
	@override String get lyrics => 'Sangtekst';
	@override String get noLyrics => 'Ingen sangtekst tilgjengelig';
	@override String get sleepTimer => 'Innsovningstimer';
	@override String get sleepTimerEndOfTrack => 'Slutten av sporet';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutter';
	@override String get stopPlayback => 'Stopp avspilling';
	@override String get previousTrack => 'Forrige spor';
	@override String get nextTrack => 'Neste spor';
	@override String get repeat => 'Gjenta';
	@override String get repeatAll => 'Gjenta alle';
	@override String get repeatOne => 'Gjenta ett spor';
}

// Path: watchTogether
class _TranslationsWatchTogetherNb extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Se sammen';
	@override String get description => 'Se innhold synkronisert med venner og familie';
	@override String get createSession => 'Opprett økt';
	@override String get creating => 'Oppretter...';
	@override String get joinSession => 'Bli med i økt';
	@override String get joining => 'Blir med...';
	@override String get controlMode => 'Kontrollmodus';
	@override String get controlModeQuestion => 'Hvem kan kontrollere avspilling?';
	@override String get hostOnly => 'Kun vert';
	@override String get anyone => 'Alle';
	@override String get hostingSession => 'Er vert for økt';
	@override String get inSession => 'I økt';
	@override String get sessionCode => 'Øktkode';
	@override String get openSessionControls => 'Åpne øktkontroller for Se sammen';
	@override String get copySessionCode => 'Kopier øktkode';
	@override String get hostControlsPlayback => 'Verten kontrollerer avspilling';
	@override String get anyoneCanControl => 'Alle kan kontrollere avspilling';
	@override String get hostControls => 'Vertskontroll';
	@override String get anyoneControls => 'Alle kontrollerer';
	@override String get participants => 'Deltakere';
	@override String get host => 'Vert';
	@override String get hostBadge => 'VERT';
	@override String get youAreHost => 'Du er verten';
	@override String get watchingWithOthers => 'Ser med andre';
	@override String get endSession => 'Avslutt økt';
	@override String get leaveSession => 'Forlat økt';
	@override String get endSessionQuestion => 'Avslutte økt?';
	@override String get leaveSessionQuestion => 'Forlate økt?';
	@override String get endSessionConfirm => 'Dette vil avslutte økten for alle deltakere.';
	@override String get leaveSessionConfirm => 'Du vil bli fjernet fra økten.';
	@override String get endSessionConfirmOverlay => 'Dette vil avslutte se sammen-økten for alle deltakere.';
	@override String get leaveSessionConfirmOverlay => 'Du vil bli frakoblet fra se sammen-økten.';
	@override String get end => 'Avslutt';
	@override String get leave => 'Forlat';
	@override String get syncing => 'Synkroniserer...';
	@override String get joinWatchSession => 'Bli med i se sammen-økt';
	@override String get enterCodeHint => 'Skriv inn 5-tegns kode';
	@override String get pasteFromClipboard => 'Lim inn fra utklippstavle';
	@override String get pleaseEnterCode => 'Vennligst skriv inn en øktkode';
	@override String get codeMustBe5Chars => 'Øktkoden må være 5 tegn';
	@override String get joinInstructions => 'Skriv inn vertens øktkode for å bli med.';
	@override String get failedToCreate => 'Kunne ikke opprette økt';
	@override String get failedToJoin => 'Kunne ikke bli med i økt';
	@override String get sessionCodeCopied => 'Øktkode kopiert til utklippstavle';
	@override String get relayUnreachable => 'Relay-serveren kan ikke nås. ISP-blokkering kan hindre Watch Together.';
	@override String get reconnectingToHost => 'Kobler til verten på nytt...';
	@override String get currentPlayback => 'Gjeldende avspilling';
	@override String get joinCurrentPlayback => 'Bli med i gjeldende avspilling';
	@override String get joinCurrentPlaybackDescription => 'Hopp tilbake til det verten ser på nå';
	@override String get failedToOpenCurrentPlayback => 'Kunne ikke åpne gjeldende avspilling';
	@override String participantJoined({required Object name}) => '${name} ble med';
	@override String participantLeft({required Object name}) => '${name} forlot';
	@override String participantPaused({required Object name}) => '${name} pauset';
	@override String participantResumed({required Object name}) => '${name} gjenopptok';
	@override String participantSeeked({required Object name}) => '${name} spolet';
	@override String participantBuffering({required Object name}) => '${name} buffrer';
	@override String participantNeedsUpdate({required Object name}) => '${name} bruker en eldre appversjon — synkronisering er ikke tilgjengelig';
	@override String resumingWithout({required Object name}) => 'Fortsetter uten ${name}';
	@override String get waitingForParticipants => 'Venter på at andre laster inn...';
	@override String waitingForName({required Object name}) => 'Venter på ${name}...';
	@override String get recentRooms => 'Nylige rom';
	@override String get renameRoom => 'Gi nytt navn til rom';
	@override String get removeRoom => 'Fjern';
	@override String get guestSwitchUnavailable => 'Kunne ikke bytte — server ikke tilgjengelig for synkronisering';
	@override String get guestSwitchFailed => 'Kunne ikke bytte — innhold ble ikke funnet på denne serveren';
}

// Path: downloads
class _TranslationsDownloadsNb extends TranslationsDownloadsEn {
	_TranslationsDownloadsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nedlastinger';
	@override String get manage => 'Administrer';
	@override String get tvShows => 'TV-serier';
	@override String get movies => 'Filmer';
	@override String get music => 'Musikk';
	@override String tracksQueued({required Object count}) => '${count} spor i nedlastingskø';
	@override String get noDownloads => 'Ingen nedlastinger ennå';
	@override String get noDownloadsDescription => 'Nedlastet innhold vil vises her for frakoblet visning';
	@override String get downloadNow => 'Last ned';
	@override String get deleteDownload => 'Slett nedlasting';
	@override String get retryDownload => 'Prøv nedlasting på nytt';
	@override String get downloadQueued => 'Nedlasting i kø';
	@override String get downloadResumed => 'Nedlasting gjenopptatt';
	@override String get serverErrorBitrate => 'Serverfeil: filen kan overskride grensen for ekstern bitrate';
	@override String episodesQueued({required Object count}) => '${count} episoder i nedlastingskø';
	@override String get downloadDeleted => 'Nedlasting slettet';
	@override String deleteConfirm({required Object title}) => 'Slette "${title}" fra denne enheten?';
	@override String get cancelledDownloadTitle => 'Avbrutt nedlasting';
	@override String get cancelledDownloadMessage => 'Denne nedlastingen ble avbrutt. Hva vil du gjøre?';
	@override String get allEpisodesAlreadyDownloaded => 'Alle episoder er allerede lastet ned';
	@override String get resumeDownload => 'Gjenoppta nedlasting';
	@override String get cancelledDownload => 'Avbrutt nedlasting';
	@override String syncingFile({required Object file, required Object status}) => '${file} (synkroniserer ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} lastet ned – klikk for å fullføre';
	@override String get partialDownloadClickToComplete => 'Delvis lastet ned – klikk for å fullføre';
	@override String get deleting => 'Sletter...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})';
	@override String get queuedTooltip => 'I kø';
	@override String queuedFilesTooltip({required Object files}) => 'I kø: ${files}';
	@override String get downloadingTooltip => 'Laster ned...';
	@override String downloadingFilesTooltip({required Object files}) => 'Laster ned ${files}';
	@override String get noDownloadsTree => 'Ingen nedlastinger';
	@override String get pauseAll => 'Pause alle';
	@override String get resumeAll => 'Gjenoppta alle';
	@override String get deleteAll => 'Slett alle';
	@override String get selectVersion => 'Velg versjon';
	@override String get allEpisodes => 'Alle episoder';
	@override String get unwatchedOnly => 'Kun usette';
	@override String nextNUnwatched({required Object count}) => 'Neste ${count} usette';
	@override String get customAmount => 'Egendefinert antall...';
	@override String get includeSpecials => 'Inkluder spesialepisoder';
	@override String get howManyEpisodes => 'Hvor mange episoder?';
	@override String get invalidEpisodeCount => 'Angi et gyldig antall episoder.';
	@override String get keepSynced => 'Hold synkronisert';
	@override String get downloadOnce => 'Last ned én gang';
	@override String keepNUnwatched({required Object count}) => 'Behold ${count} usette';
	@override String get editSyncRule => 'Rediger synkroniseringsregel';
	@override String get removeSyncRule => 'Fjern synkroniseringsregel';
	@override String removeSyncRuleConfirm({required Object title}) => 'Slutte å synkronisere "${title}"? Nedlastede episoder beholdes.';
	@override String syncRuleCreated({required Object count}) => 'Synkroniseringsregel opprettet — beholder ${count} usette episoder';
	@override String get syncRuleUpdated => 'Synkroniseringsregel oppdatert';
	@override String get syncRuleRemoved => 'Synkroniseringsregel fjernet';
	@override String syncedNewEpisodes({required Object count, required Object title}) => 'Synkroniserte ${count} nye episoder for ${title}';
	@override String get activeSyncRules => 'Synkroniseringsregler';
	@override String get noSyncRules => 'Ingen synkroniseringsregler';
	@override String get manageSyncRule => 'Administrer synkronisering';
	@override String get editEpisodeCount => 'Antall episoder';
	@override String get editSyncFilter => 'Synkroniseringsfilter';
	@override String get syncAllItems => 'Synkroniserer alle elementer';
	@override String get syncUnwatchedItems => 'Synkroniserer usette elementer';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Server: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Tilgjengelig';
	@override String get syncRuleOffline => 'Frakoblet';
	@override String get syncRuleSignInRequired => 'Innlogging kreves';
	@override String get syncRuleNotAvailableForProfile => 'Ikke tilgjengelig for gjeldende profil';
	@override String get syncRuleUnknownServer => 'Ukjent server';
	@override String get syncRuleListCreated => 'Synkroniseringsregel opprettet';
}

// Path: shaders
class _TranslationsShadersNb extends TranslationsShadersEn {
	_TranslationsShadersNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadere';
	@override String get noShaderDescription => 'Ingen videoforbedring';
	@override String get nvscalerDescription => 'NVIDIA bildeskalering for skarpere video';
	@override String get artcnnVariantNeutral => 'Nøytral';
	@override String get artcnnVariantDenoise => 'Støyreduksjon';
	@override String get artcnnVariantDenoiseSharpen => 'Støyreduksjon + skarphet';
	@override String get qualityFast => 'Rask';
	@override String get qualityHQ => 'Høy kvalitet';
	@override String get mode => 'Modus';
	@override String get importShader => 'Importer shader';
	@override String get customShaderDescription => 'Egendefinert GLSL-shader';
	@override String get shaderImported => 'Shader importert';
	@override String get shaderImportFailed => 'Kunne ikke importere shader';
	@override String get deleteShader => 'Slett shader';
	@override String deleteShaderConfirm({required Object name}) => 'Slette "${name}"?';
}

// Path: companionRemote
class _TranslationsCompanionRemoteNb extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Følgesvenn-fjernkontroll';
	@override String connectedTo({required Object name}) => 'Tilkoblet ${name}';
	@override String get unknownDevice => 'Ukjent enhet';
	@override late final _TranslationsCompanionRemoteSessionNb session = _TranslationsCompanionRemoteSessionNb._(_root);
	@override late final _TranslationsCompanionRemotePairingNb pairing = _TranslationsCompanionRemotePairingNb._(_root);
	@override late final _TranslationsCompanionRemoteRemoteNb remote = _TranslationsCompanionRemoteRemoteNb._(_root);
	@override late final _TranslationsCompanionRemoteErrorsNb errors = _TranslationsCompanionRemoteErrorsNb._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsNb extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Avspillingshastighet';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktiv (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Søvntimer';
	@override String get audioSync => 'Lydsynkronisering';
	@override String get subtitleSync => 'Undertekstsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Lydutgang';
	@override String get performanceOverlay => 'Ytelsesoverlegg';
	@override String get audioPassthrough => 'Lydgjennomgang';
	@override String get audioNormalization => 'Normaliser lydstyrke';
	@override String get audioDownmix => 'Nedmiks til stereo';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlayNb extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlayNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get color => 'Farge';
	@override String get performance => 'Ytelse';
	@override String get buffer => 'Buffer';
	@override String get app => 'App';
	@override String get decoder => 'Dekoder';
	@override String get rawDecoder => 'Rå dekoder';
	@override String get tunneling => 'Tunneling';
	@override String get aspect => 'Format';
	@override String get rotation => 'Rotasjon';
	@override String get dvSource => 'DV-kilde';
	@override String get dvPath => 'DV-sti';
	@override String get p7Conversion => 'P7-konv.';
	@override String get sampleRate => 'Samplingsrate';
	@override String get pixelFormat => 'Pikselformat';
	@override String get hwFormat => 'HW-format';
	@override String get matrix => 'Matrise';
	@override String get primaries => 'Primærfarger';
	@override String get transfer => 'Overføring';
	@override String get renderFps => 'Render-FPS';
	@override String get displayFps => 'Skjerm-FPS';
	@override String get avSync => 'A/V-synk';
	@override String get dropped => 'Droppet';
	@override String get dvRpus => 'DV RPU-er';
	@override String get dvRpuAverage => 'DV RPU snitt';
	@override String get dvSampleAverage => 'DV-sample snitt';
	@override String get maxLuma => 'Maks luma';
	@override String get minLuma => 'Min luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache brukt';
	@override String get cacheLimit => 'Cachegrense';
	@override String get speed => 'Hastighet';
	@override String get player => 'Spiller';
	@override String get memory => 'Minne';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _TranslationsExternalPlayerNb extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ekstern spiller';
	@override String get useExternalPlayer => 'Bruk ekstern spiller';
	@override String get useExternalPlayerDescription => 'Åpne videoer i en annen app';
	@override String get selectPlayer => 'Velg spiller';
	@override String get customPlayers => 'Egendefinerte spillere';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Legg til egendefinert spiller';
	@override String get playerName => 'Spillernavn';
	@override String get playerNameHint => 'Min spiller';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Pakkenavn';
	@override String get playerUrlScheme => 'URL-skjema';
	@override String get off => 'Av';
	@override String get launchFailed => 'Kunne ikke åpne ekstern spiller';
	@override String appNotInstalled({required Object name}) => '${name} er ikke installert';
	@override String get playInExternalPlayer => 'Spill av i ekstern spiller';
}

// Path: metadataEdit
class _TranslationsMetadataEditNb extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Rediger...';
	@override String get screenTitle => 'Rediger metadata';
	@override String get basicInfo => 'Grunnleggende info';
	@override String get artwork => 'Kunstverk';
	@override String get advancedSettings => 'Avanserte innstillinger';
	@override String get title => 'Tittel';
	@override String get sortTitle => 'Sorteringsstittel';
	@override String get originalTitle => 'Originaltittel';
	@override String get releaseDate => 'Utgivelsesdato';
	@override String get contentRating => 'Innholdsvurdering';
	@override String get studio => 'Studio';
	@override String get tagline => 'Slagord';
	@override String get summary => 'Sammendrag';
	@override String get poster => 'Plakat';
	@override String get background => 'Bakgrunn';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Kvadratisk bilde';
	@override String get selectPoster => 'Velg plakat';
	@override String get selectBackground => 'Velg bakgrunn';
	@override String get selectLogo => 'Velg logo';
	@override String get selectSquareArt => 'Velg kvadratisk bilde';
	@override String get fromUrl => 'Fra URL';
	@override String get uploadFile => 'Last opp fil';
	@override String get enterImageUrl => 'Skriv inn bilde-URL';
	@override String get imageUrl => 'Bilde-URL';
	@override String get metadataUpdated => 'Metadata oppdatert';
	@override String get metadataUpdateFailed => 'Kunne ikke oppdatere metadata';
	@override String get artworkUpdated => 'Kunstverk oppdatert';
	@override String get artworkUpdateFailed => 'Kunne ikke oppdatere kunstverk';
	@override String get noArtworkAvailable => 'Ingen kunstverk tilgjengelig';
	@override String artworkOption({required Object index}) => 'Alternativ for kunstverk ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Alternativ for kunstverk ${index}, valgt';
	@override String get notSet => 'Ikke angitt';
	@override String get libraryDefault => 'Bibliotekstandard';
	@override String get accountDefault => 'Kontostandard';
	@override String get seriesDefault => 'Seriestandard';
	@override String get episodeSorting => 'Episodesortering';
	@override String get oldestFirst => 'Eldste først';
	@override String get newestFirst => 'Nyeste først';
	@override String get keep => 'Behold';
	@override String get allEpisodes => 'Alle episoder';
	@override String latestEpisodes({required Object count}) => '${count} nyeste episoder';
	@override String get latestEpisode => 'Nyeste episode';
	@override String episodesAddedPastDays({required Object count}) => 'Episoder lagt til de siste ${count} dagene';
	@override String get deleteAfterPlaying => 'Slett episoder etter avspilling';
	@override String get never => 'Aldri';
	@override String get afterADay => 'Etter en dag';
	@override String get afterAWeek => 'Etter en uke';
	@override String get afterAMonth => 'Etter en måned';
	@override String get onNextRefresh => 'Ved neste oppdatering';
	@override String get seasons => 'Sesonger';
	@override String get show => 'Vis';
	@override String get hide => 'Skjul';
	@override String get episodeOrdering => 'Episoderekkefølge';
	@override String get tmdbAiring => 'The Movie Database (Sendt)';
	@override String get tvdbAiring => 'TheTVDB (Sendt)';
	@override String get tvdbAbsolute => 'TheTVDB (Absolutt)';
	@override String get metadataLanguage => 'Metadataspråk';
	@override String get useOriginalTitle => 'Bruk originaltittel';
	@override String get preferredAudioLanguage => 'Foretrukket lydspråk';
	@override String get preferredSubtitleLanguage => 'Foretrukket undertekstspråk';
	@override String get subtitleMode => 'Automatisk valg av undertekstmodus';
	@override String get manuallySelected => 'Manuelt valgt';
	@override String get shownWithForeignAudio => 'Vist med fremmedspråklig lyd';
	@override String get alwaysEnabled => 'Alltid aktivert';
	@override String get tags => 'Tagger';
	@override String get addTag => 'Legg til tagg';
	@override String get genre => 'Sjanger';
	@override String get director => 'Regissør';
	@override String get writer => 'Forfatter';
	@override String get producer => 'Produsent';
	@override String get country => 'Land';
	@override String get collection => 'Samling';
	@override String get label => 'Etikett';
	@override String get style => 'Stil';
	@override String get mood => 'Stemning';
}

// Path: matchScreen
class _TranslationsMatchScreenNb extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get match => 'Match...';
	@override String get fixMatch => 'Rett match...';
	@override String get unmatch => 'Fjern match';
	@override String get unmatchConfirm => 'Fjerne denne matchen? Plex behandler den som umatchet til den matches igjen.';
	@override String get unmatchSuccess => 'Match fjernet';
	@override String get unmatchFailed => 'Kunne ikke fjerne match';
	@override String get matchApplied => 'Match anvendt';
	@override String get matchFailed => 'Kunne ikke anvende match';
	@override String get titleHint => 'Tittel';
	@override String get yearHint => 'År';
	@override String get search => 'Søk';
	@override String get noMatchesFound => 'Ingen treff funnet';
}

// Path: serverTasks
class _TranslationsServerTasksNb extends TranslationsServerTasksEn {
	_TranslationsServerTasksNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveroppgaver';
	@override String get failedToLoad => 'Kunne ikke laste oppgaver';
	@override String get noTasks => 'Ingen oppgaver kjører';
}

// Path: trakt
class _TranslationsTraktNb extends TranslationsTraktEn {
	_TranslationsTraktNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Tilkoblet';
	@override String connectedAs({required Object username}) => 'Tilkoblet som @${username}';
	@override String get disconnectConfirm => 'Koble fra Trakt-konto?';
	@override String get disconnectConfirmBody => 'Plezy slutter å sende hendelser til Trakt. Du kan koble til igjen når som helst.';
	@override String get scrobble => 'Sanntids-scrobbling';
	@override String get scrobbleDescription => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.';
	@override String get watchedSync => 'Synkroniser sett-status';
	@override String get watchedSyncDescription => 'Når du markerer noe som sett i Plezy, markeres det også på Trakt.';
}

// Path: seerr
class _TranslationsSeerrNb extends TranslationsSeerrEn {
	_TranslationsSeerrNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Koble til Seerr';
	@override String get serverUrl => 'Server-URL';
	@override String get serverUrlHelper => 'Adressen til Seerr-instansen din';
	@override String get checkServer => 'Fortsett';
	@override String get signInWithJellyfin => 'Logg inn med Jellyfin';
	@override String get signInWithEmby => 'Logg inn med Emby';
	@override String get signInWithLocal => 'Bruk en lokal konto';
	@override String get email => 'E-post';
	@override String get noSignInMethods => 'Denne Seerr-instansen tilbyr ingen innloggingsmetode som Plezy støtter.';
	@override String get instance => 'Instans';
	@override String get disconnectConfirm => 'Koble fra Seerr?';
	@override String get disconnectConfirmBody => 'Plezy glemmer denne Seerr-instansen. Koble til igjen når som helst.';
	@override String get request => 'Forespør';
	@override String get request4k => 'Forespør i 4K';
	@override String get seasons => 'Sesonger';
	@override String get allSeasons => 'Alle sesonger';
	@override String get advancedOptions => 'Avansert';
	@override String get destinationServer => 'Målserver';
	@override String get qualityProfile => 'Kvalitetsprofil';
	@override String get rootFolder => 'Rotmappe';
	@override String get languageProfile => 'Språkprofil';
	@override String get requestSubmitted => 'Forespørsel sendt';
	@override String requestFailed({required Object error}) => 'Forespørsel mislyktes: ${error}';
	@override String get requestsLoadFailed => 'Kunne ikke laste forespørselsalternativer';
	@override String get nothingToRequest => 'Alt er allerede tilgjengelig eller forespurt.';
	@override String get statusAvailable => 'Tilgjengelig';
	@override String get statusPartiallyAvailable => 'Delvis tilgjengelig';
	@override String get statusRequested => 'Forespurt';
	@override String get statusProcessing => 'Behandler';
}

// Path: services
class _TranslationsServicesNb extends TranslationsServicesEn {
	_TranslationsServicesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tjenester';
	@override String get hubSubtitle => 'Synkroniser fremdrift og forespør nye titler.';
	@override String get notConnected => 'Ikke tilkoblet';
	@override String connectedAs({required Object username}) => 'Tilkoblet som @${username}';
	@override String get scrobble => 'Registrer fremdrift automatisk';
	@override String get scrobbleDescription => 'Oppdater listen din når du er ferdig med en episode eller film.';
	@override String disconnectConfirm({required Object service}) => 'Koble fra ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy slutter å oppdatere ${service}. Koble til igjen når som helst.';
	@override String connectFailed({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.';
	@override late final _TranslationsServicesNamesNb names = _TranslationsServicesNamesNb._(_root);
	@override late final _TranslationsServicesDeviceCodeNb deviceCode = _TranslationsServicesDeviceCodeNb._(_root);
	@override late final _TranslationsServicesOauthProxyNb oauthProxy = _TranslationsServicesOauthProxyNb._(_root);
	@override late final _TranslationsServicesLibraryFilterNb libraryFilter = _TranslationsServicesLibraryFilterNb._(_root);
}

// Path: addServer
class _TranslationsAddServerNb extends TranslationsAddServerEn {
	_TranslationsAddServerNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Legg til Jellyfin-server';
	@override String get serverUrls => 'Server-URL-er';
	@override String get serverUrlsHelper => 'Flere URL-er er tillatt, atskilt med komma.';
	@override String get findServer => 'Finn server';
	@override String get searchingLocalServers => 'Søker etter lokale Jellyfin-servere...';
	@override String get localServers => 'Lokale Jellyfin-servere';
	@override String get username => 'Brukernavn';
	@override String get password => 'Passord';
	@override String get signIn => 'Logg på';
	@override String get change => 'Endre';
	@override String get required => 'Påkrevd';
	@override String couldNotReachServer({required Object error}) => 'Kunne ikke nå serveren: ${error}';
	@override String signInFailed({required Object error}) => 'Pålogging mislyktes: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect mislyktes: ${error}';
	@override String get addPlexTitle => 'Logg på med Plex';
	@override String get pinExpired => 'PIN-koden gikk ut før pålogging. Prøv igjen.';
	@override String failedToRegisterAccount({required Object error}) => 'Kunne ikke registrere kontoen: ${error}';
	@override String get enterJellyfinUrlError => 'Oppgi URL-en til Jellyfin-serveren din';
	@override String get addConnectionTitle => 'Legg til tilkobling';
	@override String addConnectionTitleScoped({required Object name}) => 'Legg til i ${name}';
	@override String get signInWithPlexCard => 'Logg på med Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriser denne enheten. Delte servere legges til.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriser en Plex-konto. Home-brukere blir profiler.';
	@override String get connectToJellyfinCard => 'Koble til Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Skriv inn server-URL, brukernavn og passord.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Logg på en Jellyfin-server. Knyttes til ${name}.';
	@override String get borrowFromAnotherProfile => 'Lån fra en annen profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Gjenbruk en annen profils tilkobling. PIN-beskyttede profiler krever PIN.';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsNb extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Spill av/Pause';
	@override String get volumeUp => 'Volum opp';
	@override String get volumeDown => 'Volum ned';
	@override String seekForward({required Object seconds}) => 'Spol fremover (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Spol bakover (${seconds}s)';
	@override String get fullscreenToggle => 'Veksle fullskjerm';
	@override String get muteToggle => 'Veksle demping';
	@override String get subtitleToggle => 'Veksle undertekster';
	@override String get audioTrackNext => 'Neste lydspor';
	@override String get subtitleTrackNext => 'Neste undertekstspor';
	@override String get chapterNext => 'Neste kapittel';
	@override String get chapterPrevious => 'Forrige kapittel';
	@override String get episodeNext => 'Neste episode';
	@override String get episodePrevious => 'Forrige episode';
	@override String get speedIncrease => 'Øk hastighet';
	@override String get speedDecrease => 'Reduser hastighet';
	@override String get speedReset => 'Tilbakestill hastighet';
	@override String get zoomIn => 'Zoom inn';
	@override String get zoomOut => 'Zoom ut';
	@override String get zoomReset => 'Tilbakestill zoom';
	@override String get subSeekNext => 'Spol til neste undertekst';
	@override String get subSeekPrev => 'Spol til forrige undertekst';
	@override String get shaderToggle => 'Veksle shadere';
	@override String get skipMarker => 'Hopp over intro/rulletekst';
	@override String get screenshot => 'Ta skjermbilde';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsNb extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Krever Android 8.0 eller nyere';
	@override String get iosVersion => 'Krever iOS 15.0 eller nyere';
	@override String get permissionDisabled => 'Bilde-i-bilde er deaktivert. Slå det på i systeminnstillinger.';
	@override String get notSupported => 'Enheten støtter ikke bilde-i-bilde-modus';
	@override String get voSwitchFailed => 'Kunne ikke bytte videoutgang for bilde-i-bilde';
	@override String get failed => 'Bilde-i-bilde kunne ikke starte';
	@override String unknown({required Object error}) => 'En feil oppstod: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsNb extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Anbefalt';
	@override String get browse => 'Bla gjennom';
	@override String get collections => 'Samlinger';
	@override String get playlists => 'Spillelister';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsNb extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gruppering';
	@override String get all => 'Alle';
	@override String get movies => 'Filmer';
	@override String get shows => 'TV-serier';
	@override String get seasons => 'Sesonger';
	@override String get episodes => 'Episoder';
	@override String get artists => 'Artister';
	@override String get albums => 'Album';
	@override String get tracks => 'Spor';
	@override String get folders => 'Mapper';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesNb extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Sjanger';
	@override String get year => 'År';
	@override String get contentRating => 'Aldersgrense';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Usette';
	@override String get unplayed => 'Ikke avspilt';
	@override String get favorites => 'Favoritter';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsNb extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittel';
	@override String get dateAdded => 'Lagt til-dato';
	@override String get releaseDate => 'Utgivelsesdato';
	@override String get rating => 'Vurdering';
	@override String get communityRating => 'Fellesskapsvurdering';
	@override String get criticRating => 'Kritikervurdering';
	@override String get userRating => 'Brukervurdering';
	@override String get datePlayed => 'Avspillingsdato';
	@override String get playCount => 'Avspillinger';
	@override String get productionYear => 'Produksjonsår';
	@override String get runtime => 'Varighet';
	@override String get officialRating => 'Offisiell vurdering';
	@override String get premiereDate => 'Premieredato';
	@override String get startDate => 'Startdato';
	@override String get airTime => 'Sendetid';
	@override String get studio => 'Studio';
	@override String get random => 'Tilfeldig';
	@override String get dateShared => 'Delingsdato';
	@override String get latestEpisodeAirDate => 'Siste episodes sendedato';
	@override String get lastEpisodeDateAdded => 'Dato for sist lagt til episode';
}

// Path: explore.rows
class _TranslationsExploreRowsNb extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Ønskeliste';
	@override String get recommendedMovies => 'Anbefalte filmer';
	@override String get recommendedShows => 'Anbefalte serier';
	@override String get trendingMovies => 'Trending filmer';
	@override String get trendingShows => 'Trending serier';
	@override String get popularMovies => 'Populære filmer';
	@override String get popularShows => 'Populære serier';
	@override String get suggestedAnime => 'Foreslått anime';
	@override String get airingAnime => 'Topp pågående anime';
	@override String get popularAnime => 'Mest populære anime';
	@override String get trending => 'Trending';
	@override String get upcomingMovies => 'Kommende filmer';
	@override String get upcomingShows => 'Kommende serier';
}

// Path: explore.status
class _TranslationsExploreStatusNb extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Sendes';
	@override String get ended => 'Avsluttet';
	@override String get canceled => 'Avlyst';
	@override String get upcoming => 'Kommende';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionNb extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Starter fjernserver...';
	@override String get hostAddress => 'Vertsadresse';
	@override String get connected => 'Tilkoblet';
	@override String get serverRunning => 'Fjernserver aktiv';
	@override String get serverStopped => 'Fjernserver stoppet';
	@override String get serverRunningDescription => 'Mobile enheter på nettverket ditt kan koble til denne appen';
	@override String get serverStoppedDescription => 'Start serveren for å la mobilenheter koble til';
	@override String get usePhoneToControl => 'Bruk mobilenheten din til å styre denne appen';
	@override String get startServer => 'Start server';
	@override String get stopServer => 'Stopp server';
	@override String get minimize => 'Minimer';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingNb extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Plezy-enheter med samme Plex-konto vises her';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Kobler til...';
	@override String get searchingForDevices => 'Søker etter enheter...';
	@override String get noDevicesFound => 'Ingen enheter funnet på nettverket ditt';
	@override String get noDevicesHint => 'Åpne Plezy på desktop og bruk samme WiFi';
	@override String get availableDevices => 'Tilgjengelige enheter';
	@override String get manualConnection => 'Manuell tilkobling';
	@override String get cryptoInitFailed => 'Kunne ikke starte sikker tilkobling. Logg inn på Plex først.';
	@override String get validationHostRequired => 'Vennligst oppgi vertsadresse';
	@override String get validationHostFormat => 'Format må være IP:port (f.eks. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tilkoblingen fikk tidsavbrudd. Bruk samme nettverk på begge enheter.';
	@override String get sessionNotFound => 'Enhet ikke funnet. Sørg for at Plezy kjører på verten.';
	@override String get authFailed => 'Autentisering mislyktes. Begge enheter må bruke samme Plex-konto.';
	@override String failedToConnect({required Object error}) => 'Kunne ikke koble til: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteNb extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vil du koble fra fjernøkten?';
	@override String get reconnecting => 'Kobler til på nytt...';
	@override String attemptOf({required Object current}) => 'Forsøk ${current} av 5';
	@override String get retryNow => 'Prøv nå';
	@override String get tabRemote => 'Fjernkontroll';
	@override String get tabPlay => 'Spill av';
	@override String get tabMore => 'Mer';
	@override String get menu => 'Meny';
	@override String get tabNavigation => 'Fanenavigering';
	@override String get tabDiscover => 'Oppdag';
	@override String get tabLibraries => 'Biblioteker';
	@override String get tabSearch => 'Søk';
	@override String get tabDownloads => 'Nedlastinger';
	@override String get tabSettings => 'Innstillinger';
	@override String get previous => 'Forrige';
	@override String get playPause => 'Spill av/Pause';
	@override String get next => 'Neste';
	@override String get seekBack => 'Spol tilbake';
	@override String get stop => 'Stopp';
	@override String get seekForward => 'Spol fremover';
	@override String get volume => 'Volum';
	@override String get volumeDown => 'Ned';
	@override String get volumeUp => 'Opp';
	@override String get fullscreen => 'Fullskjerm';
	@override String get subtitles => 'Undertekster';
	@override String get audio => 'Lyd';
	@override String get searchHint => 'Søk på stasjonær...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsNb extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Fant ingen nettverksgrensesnitt';
	@override String get authenticationFailed => 'Autentisering mislyktes';
	@override String serverStartFailed({required Object error}) => 'Kunne ikke starte fjernserveren: ${error}';
	@override String commandFailed({required Object error}) => 'Kunne ikke sende fjernkommando: ${error}';
	@override String get joinTimedOut => 'Tidsavbrudd ved tilkobling til økt';
	@override String get failedToConnectAnyAddress => 'Kunne ikke koble til noen adresse';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Tilkobling mistet etter ${attempts} forsøk';
	@override String get connectionLost => 'Tilkobling mistet';
}

// Path: services.names
class _TranslationsServicesNamesNb extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeNb extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktiver Plezy på ${service}';
	@override String body({required Object url}) => 'Besøk ${url} og skriv inn denne koden:';
	@override String openToActivate({required Object service}) => 'Åpne ${service} for å aktivere';
	@override String get copyCode => 'Kopier aktiveringskode';
	@override String get waitingForAuthorization => 'Venter på godkjenning…';
	@override String get codeCopied => 'Kode kopiert';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxyNb extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxyNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Logg inn på ${service}';
	@override String get body => 'Skann denne QR-koden eller åpne URL-en på en enhet.';
	@override String openToSignIn({required Object service}) => 'Åpne ${service} for å logge inn';
	@override String get copyUrl => 'Kopier URL for pålogging';
	@override String get urlCopied => 'URL kopiert';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterNb extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteksfilter';
	@override String get subtitleAllSyncing => 'Synkroniserer alle biblioteker';
	@override String get subtitleNoneSyncing => 'Ingenting synkroniseres';
	@override String subtitleBlocked({required Object count}) => '${count} blokkert';
	@override String subtitleAllowed({required Object count}) => '${count} tillatt';
	@override String get mode => 'Filtermodus';
	@override String get modeBlacklist => 'Svarteliste';
	@override String get modeWhitelist => 'Hviteliste';
	@override String get modeHintBlacklist => 'Synkroniser alle biblioteker bortsett fra dem du markerer nedenfor.';
	@override String get modeHintWhitelist => 'Synkroniser kun bibliotekene du markerer nedenfor.';
	@override String get libraries => 'Biblioteker';
	@override String get noLibraries => 'Ingen biblioteker tilgjengelige';
}

/// The flat map containing all translations for locale <nb>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsNb {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Logg inn med Plex',
			'auth.showQRCode' => 'Vis QR-kode',
			'auth.authenticate' => 'Autentiser',
			'auth.authenticationTimeout' => 'Autentiseringen ble tidsavbrutt. Prøv igjen.',
			'auth.scanQRToSignIn' => 'Skann denne QR-koden for å logge inn',
			'auth.waitingForAuth' => 'Venter på autentisering...\nLogg inn fra nettleseren.',
			'auth.useBrowser' => 'Bruk nettleser',
			'auth.or' => 'eller',
			'auth.connectToJellyfin' => 'Koble til Jellyfin',
			'auth.useQuickConnect' => 'Bruk Quick Connect',
			'auth.quickConnectInstructions' => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.',
			'auth.quickConnectWaiting' => 'Venter på godkjenning…',
			'auth.quickConnectCancel' => 'Avbryt',
			'auth.quickConnectExpired' => 'Quick Connect er utløpt. Prøv igjen.',
			'common.cancel' => 'Avbryt',
			'common.save' => 'Lagre',
			'common.close' => 'Lukk',
			'common.clear' => 'Tøm',
			'common.reset' => 'Tilbakestill',
			'common.later' => 'Senere',
			'common.submit' => 'Send inn',
			'common.confirm' => 'Bekreft',
			'common.retry' => 'Prøv igjen',
			'common.logout' => 'Logg ut',
			'common.unknown' => 'Ukjent',
			'common.refresh' => 'Oppdater',
			'common.yes' => 'Ja',
			'common.no' => 'Nei',
			'common.delete' => 'Slett',
			'common.edit' => 'Rediger',
			'common.shuffle' => 'Tilfeldig',
			'common.addTo' => 'Legg til i...',
			'common.createNew' => 'Opprett ny',
			'common.connect' => 'Koble til',
			'common.disconnect' => 'Koble fra',
			'common.play' => 'Spill av',
			'common.pause' => 'Pause',
			'common.resume' => 'Gjenoppta',
			'common.error' => 'Feil',
			'common.search' => 'Søk',
			'common.home' => 'Hjem',
			'common.back' => 'Tilbake',
			'common.settings' => 'Innstillinger',
			'common.mute' => 'Demp',
			'common.ok' => 'OK',
			'common.off' => 'Av',
			'common.seasonNumber' => ({required Object number}) => 'Sesong ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episode ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Kapittel ${number}',
			'common.reconnect' => 'Koble til på nytt',
			'common.viewAll' => 'Vis alle',
			'common.checkingNetwork' => 'Sjekker nettverk...',
			'common.loadingServers' => 'Laster servere...',
			'common.connectingToServers' => 'Kobler til servere...',
			'common.startingOfflineMode' => 'Starter frakoblet modus...',
			'common.loading' => 'Laster...',
			'common.fullscreen' => 'Fullskjerm',
			'common.exitFullscreen' => 'Avslutt fullskjerm',
			'common.pressBackAgainToExit' => 'Trykk tilbake igjen for å avslutte',
			'screens.licenses' => 'Lisenser',
			'screens.switchProfile' => 'Bytt profil',
			'screens.subtitleStyling' => 'Undertekststil',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logger',
			'update.available' => 'Oppdatering tilgjengelig',
			'update.versionAvailable' => ({required Object version}) => 'Versjon ${version} er tilgjengelig',
			'update.currentVersion' => ({required Object version}) => 'Gjeldende: ${version}',
			'update.skipVersion' => 'Hopp over denne versjonen',
			'update.viewRelease' => 'Vis utgivelse',
			'update.latestVersion' => 'Du har den nyeste versjonen',
			'update.checkFailed' => 'Kunne ikke se etter oppdateringer',
			'settings.title' => 'Innstillinger',
			'settings.supportDeveloper' => 'Støtt Plezy',
			'settings.supportDeveloperDescription' => 'Doner via Liberapay for å finansiere utviklingen',
			'settings.language' => 'Språk',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Utseende',
			'settings.videoPlayback' => 'Videoavspilling',
			'settings.videoPlaybackDescription' => 'Konfigurer avspillingsatferd',
			'settings.advanced' => 'Avansert',
			'settings.episodePosterMode' => 'Episodeplakatstil',
			'settings.seriesPoster' => 'Serieplakat',
			'settings.seasonPoster' => 'Sesongplakat',
			'settings.episodeThumbnail' => 'Miniatyrbilde',
			'settings.showHeroSectionDescription' => 'Vis fremhevet innholdskarusell på hjemmeskjermen',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minutter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Angi varighet (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Lyst',
			'settings.darkTheme' => 'Mørkt',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Bibliotekets tetthet',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Komfortabel',
			'settings.viewMode' => 'Visningsmodus',
			'settings.gridView' => 'Rutenett',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Vis fremhevet seksjon',
			'settings.continueWatchingAction' => 'Handling for Fortsett å se',
			'settings.continueWatchingPlay' => 'Spill av',
			'settings.continueWatchingDetails' => 'Åpne detaljer',
			'settings.episodeAction' => 'Handling for episoder',
			'settings.episodePlay' => 'Spill av',
			'settings.episodeDetails' => 'Åpne detaljer',
			'settings.useGlobalHubs' => 'Bruk startoppsett',
			'settings.useGlobalHubsDescription' => 'Vis samlet startinnhold. Ellers brukes bibliotekanbefalinger.',
			'settings.showServerNameOnHubs' => 'Vis servernavn på huber',
			'settings.showServerNameOnHubsDescription' => 'Vis alltid servernavn i hubtitler.',
			'settings.groupLibrariesByServer' => 'Grupper biblioteker etter server',
			'settings.groupLibrariesByServerDescription' => 'Grupper sidepanelbiblioteker under hver medieserver.',
			'settings.alwaysKeepSidebarOpen' => 'Hold sidefeltet alltid åpent',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg',
			'settings.showUnwatchedCount' => 'Vis antall usette',
			'settings.showUnwatchedCountDescription' => 'Vis antall usette episoder på serier og sesonger',
			'settings.showEpisodeNumberOnCards' => 'Vis episodenummer på kort',
			'settings.showEpisodeNumberOnCardsDescription' => 'Vis sesong- og episodenummer på episodekort',
			'settings.showSeasonPostersOnTabs' => 'Vis sesongplakater på faner',
			'settings.showSeasonPostersOnTabsDescription' => 'Vis hver sesongs plakat over fanen',
			'settings.tvFullCardLayout' => 'Fulle TV-kort',
			'settings.tvFullCardLayoutDescription' => 'Bruk bildebaserte TV-kort med skuespillernavn lagt over',
			'settings.focusGlow' => 'Fokusglød',
			'settings.focusGlowDescription' => 'Vis en myk glød rundt kortet i fokus',
			'settings.visualEffects' => 'Visuelle effekter',
			'settings.visualEffectsAuto' => 'Automatisk',
			'settings.visualEffectsAutoDescription' => 'Reduser effekter automatisk på enheter med lavt strømforbruk',
			'settings.visualEffectsFull' => 'Full',
			'settings.visualEffectsReduced' => 'Redusert',
			'settings.visualEffectsReducedDescription' => 'Færre animasjoner og grafikk med lavere oppløsning',
			'settings.hideSpoilers' => 'Skjul spoilere for usette episoder',
			'settings.hideSpoilersDescription' => 'Slør miniatyrbilder og beskrivelser for usette episoder',
			'settings.playerBackend' => 'Spillermotor',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Maskinvaredekoding',
			'settings.hardwareDecodingDescription' => 'Bruk maskinvareakselerasjon når tilgjengelig',
			'settings.bufferSize' => 'Bufferstørrelse',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Anbefalt)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB minne tilgjengelig. En buffer på ${size}MB kan påvirke avspilling.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.musicQualityTitle' => 'Musikkvalitet',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpass utseendet på undertekster',
			'settings.smallSkipDuration' => 'Kort hoppvarighet',
			'settings.largeSkipDuration' => 'Lang hoppvarighet',
			'settings.rewindOnResume' => 'Spol tilbake ved gjenopptakelse',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard søvntimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutter',
			'settings.rememberTrackSelections' => 'Husk sporvalg per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Husk lyd- og undertekstvalg per tittel',
			'settings.showChapterMarkersOnTimeline' => 'Vis kapittelmarkører på tidslinjen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Del tidslinjen ved kapittelgrenser',
			'settings.clickVideoTogglesPlayback' => 'Klikk på video for å veksle avspilling',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.',
			'settings.videoPlayerControls' => 'Videospillerkontroller',
			'settings.keyboardShortcuts' => 'Tastatursnarveier',
			'settings.keyboardShortcutsDescription' => 'Tilpass tastatursnarveier',
			'settings.videoPlayerNavigation' => 'Videospillernavigering',
			'settings.videoPlayerNavigationDescription' => 'Bruk piltaster for å navigere videospillerkontroller',
			'settings.watchTogetherRelay' => 'Se Sammen-relay',
			'settings.watchTogetherRelayDescription' => 'Angi en egendefinert relay. Alle må bruke samme server.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.eksempel.no',
			'settings.crashReporting' => 'Krasjrapportering',
			'settings.crashReportingDescription' => 'Send krasjrapporter for å hjelpe med å forbedre appen',
			'settings.debugLogging' => 'Feilsøkingslogging',
			'settings.debugLoggingDescription' => 'Aktiver detaljert logging for feilsøking',
			'settings.viewLogs' => 'Vis logger',
			'settings.viewLogsDescription' => 'Vis applikasjonslogger',
			'settings.clearCache' => 'Tøm hurtigbuffer',
			'settings.clearCacheDescription' => 'Tøm bufrede bilder og data. Innhold kan lastes tregere.',
			'settings.clearCacheSuccess' => 'Hurtigbuffer tømt',
			'settings.resetSettings' => 'Tilbakestill innstillinger',
			'settings.resetSettingsDescription' => 'Gjenopprett standardinnstillinger. Dette kan ikke angres.',
			'settings.resetSettingsSuccess' => 'Innstillinger tilbakestilt',
			'settings.backup' => 'Sikkerhetskopi',
			'settings.exportSettings' => 'Eksporter innstillinger',
			'settings.exportSettingsDescription' => 'Lagre innstillingene i en fil',
			'settings.exportSettingsSuccess' => 'Innstillinger eksportert',
			'settings.exportSettingsFailed' => 'Kunne ikke eksportere innstillinger',
			'settings.importSettings' => 'Importer innstillinger',
			'settings.importSettingsDescription' => 'Gjenopprett innstillinger fra en fil',
			'settings.importSettingsConfirm' => 'Dette vil erstatte nåværende innstillinger. Fortsette?',
			'settings.importSettingsSuccess' => 'Innstillinger importert',
			'settings.importSettingsFailed' => 'Kunne ikke importere innstillinger',
			'settings.importSettingsInvalidFile' => 'Denne filen er ikke en gyldig Plezy-innstillingseksport',
			'settings.importSettingsNoUser' => 'Logg inn før import av innstillinger',
			'settings.shortcutsReset' => 'Snarveier tilbakestilt til standard',
			'settings.about' => 'Om',
			'settings.aboutDescription' => 'Appinformasjon og lisenser',
			'settings.updates' => 'Oppdateringer',
			'settings.updateAvailable' => 'Oppdatering tilgjengelig',
			'settings.checkForUpdates' => 'Se etter oppdateringer',
			'settings.autoCheckUpdatesOnStartup' => 'Se automatisk etter oppdateringer ved oppstart',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Varsle når en oppdatering er tilgjengelig ved oppstart',
			'settings.validationErrorEnterNumber' => 'Vennligst skriv inn et gyldig tall',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Varigheten må være mellom ${min} og ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Snarvei allerede tilordnet til ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Snarvei oppdatert for ${action}',
			'settings.autoSkip' => 'Automatisk hopp',
			'settings.autoSkipIntro' => 'Hopp over intro automatisk',
			'settings.autoSkipIntroDescription' => 'Hopp automatisk over intromarkører etter noen sekunder',
			'settings.autoSkipCredits' => 'Hopp over rulletekst automatisk',
			'settings.autoSkipCreditsDescription' => 'Hopp automatisk over rulletekst og spill neste episode',
			'settings.forceSkipMarkerFallback' => 'Tving reservemarkører',
			'settings.forceSkipMarkerFallbackDescription' => 'Bruk mønstre i kapiteltitler selv når Plex har markører',
			'settings.autoSkipDelay' => 'Forsinkelse for automatisk hopp',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping',
			'settings.introPattern' => 'Intromarkørmønster',
			'settings.introPatternDescription' => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler',
			'settings.creditsPattern' => 'Rulletekstmarkørmønster',
			'settings.creditsPatternDescription' => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler',
			'settings.invalidRegex' => 'Ugyldig regulært uttrykk',
			'settings.regex' => 'Regulært uttrykk',
			'settings.downloads' => 'Nedlastinger',
			'settings.downloadLocationDescription' => 'Velg hvor nedlastet innhold skal lagres',
			'settings.downloadLocationDefault' => 'Standard (App-lagring)',
			'settings.downloadLocationCustom' => 'Egendefinert plassering',
			'settings.selectFolder' => 'Velg mappe',
			'settings.resetToDefault' => 'Tilbakestill til standard',
			'settings.currentPath' => ({required Object path}) => 'Gjeldende: ${path}',
			'settings.downloadLocationChanged' => 'Nedlastingsplassering endret',
			'settings.downloadLocationReset' => 'Nedlastingsplassering tilbakestilt til standard',
			'settings.downloadLocationInvalid' => 'Valgt mappe er ikke skrivbar',
			'settings.downloadLocationSelectError' => 'Kunne ikke velge mappe',
			'settings.downloadOnWifiOnly' => 'Last ned kun på WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Forhindre nedlastinger på mobildata',
			'settings.autoRemoveWatchedDownloads' => 'Fjern sette nedlastinger automatisk',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Slett sette nedlastinger automatisk',
			'settings.cellularDownloadBlocked' => 'Nedlastinger er blokkert på mobilnett. Bruk WiFi eller endre innstillingen.',
			'settings.maxVolume' => 'Maks volum',
			'settings.maxVolumeDescription' => 'Tillat volumforsterkning over 100% for stille media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Vis hva du ser på Discord',
			'settings.services' => 'Tjenester',
			'settings.servicesDescription' => 'Koble til Trakt, MyAnimeList, Seerr og mer',
			'settings.manageLibrariesDescription' => 'Omorganiser og skjul biblioteker',
			'settings.companionRemoteServer' => 'Companion Remote-server',
			'settings.companionRemoteServerDescription' => 'Tillat mobilenheter på nettverket ditt å styre denne appen',
			'settings.autoPip' => 'Auto bilde-i-bilde',
			'settings.autoPipDescription' => 'Gå til bilde-i-bilde når du forlater under avspilling',
			'settings.matchContentFrameRate' => 'Tilpass innholdets bildefrekvens',
			'settings.matchContentFrameRateDescription' => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold',
			'settings.matchRefreshRate' => 'Tilpass oppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm',
			'settings.matchDynamicRange' => 'Tilpass dynamisk område',
			'settings.matchDynamicRangeDescription' => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR',
			'settings.displaySwitchDelay' => 'Forsinkelse ved skjermbytte',
			'settings.tunneledPlayback' => 'Tunnelert avspilling',
			'settings.tunneledPlaybackDescription' => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video.',
			'settings.audioPassthrough' => 'Lydgjennomgang',
			'settings.audioPassthroughDescription' => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Overlater Dolby Digital Plus (inkl. Atmos) til systemet som bitstream. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Korte lydbrudd kan forekomme ved søking.',
			'settings.audioDownmix' => 'Nedmiks til stereo',
			'settings.audioDownmixDescription' => 'Mikser surroundlyd ned til to kanaler for stereohøyttalere eller hodetelefoner',
			'settings.downmixCenterBoost' => 'Forsterkning av senterkanal',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Forsterkning (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normaliser lydstyrke ved nedmiks',
			'settings.audioDownmixNormalizeDescription' => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).',
			'settings.atmosDiagnostics' => 'Atmos-utgangstest',
			'settings.atmosDiagnosticsDescription' => 'Diagnostiser Dolby Atmos-utgangen ved å spille testsignaler gjennom systemspilleren',
			'settings.atmosTestHlsAtmos' => 'Apple Atmos-strøm',
			'settings.atmosTestHlsAtmosDescription' => 'Kjent god Dolby Atmos-strøm. Mottakeren bør vise Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Apple surround-strøm',
			'settings.atmosTestHlsControlDescription' => 'Kontrollstrøm uten Atmos. Mottakeren bør vise surround uten Atmos.',
			'settings.atmosTestRawStream' => 'Rå EAC3-strøm',
			'settings.atmosTestRawStreamDescription' => 'Strømmer testfilen akkurat som Atmos-avspilling i spilleren. Krever testfilens URL.',
			'settings.atmosTestRawFile' => 'Rå EAC3-fil',
			'settings.atmosTestRawFileDescription' => 'Spiller av testfilen med kjent lengde. Krever testfilens URL.',
			'settings.atmosTestStop' => 'Stopp test',
			'settings.atmosTestUrl' => 'Testfilens URL',
			'settings.atmosTestUrlDescription' => 'HTTP-URL til en rå .ec3 Dolby Atmos-fil (f.eks. hentet ut med ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Angi testfilens URL først',
			'settings.atmosTestStatus' => 'Status',
			'settings.dvConversionMode' => 'Dolby Vision-konvertering',
			'settings.dvConversionModeDescription' => 'Velg hvordan ExoPlayer håndterer Dolby Vision Profile 7-filer.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Innebygd / deaktivert',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Bruk enhetens kapabilitetsdeteksjon og normal reserveoppførsel',
			'settings.dvConversionNativeDescription' => 'Tving native DV7 og undertrykk forsøk på DV-konvertering',
			'settings.dvConversionDv81Description' => 'Tving inline RPU-konvertering til Dolby Vision profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Fjern Dolby Vision RPU/EL-lag og presenter vanlig HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Spør om profil ved appåpning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åpnes',
			'settings.forceTvMode' => 'Tving TV-modus',
			'settings.forceTvModeDescription' => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.',
			'settings.startInFullscreen' => 'Start i fullskjerm',
			'settings.startInFullscreenDescription' => 'Åpne Plezy i fullskjermmodus ved oppstart',
			'settings.exitFullscreenOnPlayerClose' => 'Avslutt fullskjerm ved lukking av avspiller',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Avslutt fullskjerm automatisk når videospilleren lukkes',
			'settings.autoHidePerformanceOverlay' => 'Skjul ytelsesoverlegg automatisk',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade ytelsesoverlegget med avspillingskontrollene',
			'settings.showNavBarLabels' => 'Vis navigasjonsfeltlabeler',
			'settings.showNavBarLabelsDescription' => 'Vis tekstlabeler under navigasjonsfeltikoner',
			'settings.startupSection' => 'Oppstartsseksjon',
			'settings.liveTvDefaultFavorites' => 'Standard til favorittkanaler',
			'settings.liveTvDefaultFavoritesDescription' => 'Vis kun favorittkanaler når du åpner Live TV',
			'settings.display' => 'Skjerm',
			'settings.homeScreen' => 'Hjemmeskjerm',
			'settings.navigation' => 'Navigering',
			'settings.window' => 'Vindu',
			'settings.content' => 'Innhold',
			'settings.player' => 'Spiller',
			'settings.subtitlesAndConfig' => 'Undertekster og konfigurasjon',
			'settings.seekAndTiming' => 'Søk og tidtaking',
			'settings.behavior' => 'Atferd',
			'search.hint' => 'Søk i filmer, serier, musikk...',
			'search.tryDifferentTerm' => 'Prøv et annet søkeord',
			'search.searchYourMedia' => 'Søk i mediene dine',
			'search.enterTitleActorOrKeyword' => 'Skriv inn tittel, skuespiller eller nøkkelord',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Angi snarvei for ${actionName}',
			'hotkeys.clearShortcut' => 'Fjern snarvei',
			'hotkeys.noShortcutSet' => 'Ingen snarvei satt',
			'hotkeys.currentShortcut' => 'Gjeldende snarvei:',
			'hotkeys.pressToRecord' => 'Velg for å registrere en snarvei',
			'hotkeys.recordingShortcut' => 'Trykk på snarveien nå',
			'hotkeys.actions.playPause' => 'Spill av/Pause',
			'hotkeys.actions.volumeUp' => 'Volum opp',
			'hotkeys.actions.volumeDown' => 'Volum ned',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Spol fremover (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Spol bakover (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Veksle fullskjerm',
			'hotkeys.actions.muteToggle' => 'Veksle demping',
			'hotkeys.actions.subtitleToggle' => 'Veksle undertekster',
			'hotkeys.actions.audioTrackNext' => 'Neste lydspor',
			'hotkeys.actions.subtitleTrackNext' => 'Neste undertekstspor',
			'hotkeys.actions.chapterNext' => 'Neste kapittel',
			'hotkeys.actions.chapterPrevious' => 'Forrige kapittel',
			'hotkeys.actions.episodeNext' => 'Neste episode',
			'hotkeys.actions.episodePrevious' => 'Forrige episode',
			'hotkeys.actions.speedIncrease' => 'Øk hastighet',
			'hotkeys.actions.speedDecrease' => 'Reduser hastighet',
			'hotkeys.actions.speedReset' => 'Tilbakestill hastighet',
			'hotkeys.actions.zoomIn' => 'Zoom inn',
			'hotkeys.actions.zoomOut' => 'Zoom ut',
			'hotkeys.actions.zoomReset' => 'Tilbakestill zoom',
			'hotkeys.actions.subSeekNext' => 'Spol til neste undertekst',
			'hotkeys.actions.subSeekPrev' => 'Spol til forrige undertekst',
			'hotkeys.actions.shaderToggle' => 'Veksle shadere',
			'hotkeys.actions.skipMarker' => 'Hopp over intro/rulletekst',
			'hotkeys.actions.screenshot' => 'Ta skjermbilde',
			'fileInfo.title' => 'Filinformasjon',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Lyd',
			'fileInfo.file' => 'Fil',
			'fileInfo.advanced' => 'Avansert',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.resolution' => 'Oppløsning',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Bildefrekvens',
			'fileInfo.aspectRatio' => 'Sideforhold',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Bitdybde',
			'fileInfo.colorSpace' => 'Fargerom',
			'fileInfo.colorRange' => 'Fargeområde',
			'fileInfo.colorPrimaries' => 'Fargeprimærer',
			'fileInfo.chromaSubsampling' => 'Krominansnedsampling',
			'fileInfo.channels' => 'Kanaler',
			'fileInfo.subtitles' => 'Undertekster',
			'fileInfo.overallBitrate' => 'Total bitrate',
			'fileInfo.path' => 'Sti',
			'fileInfo.size' => 'Størrelse',
			'fileInfo.container' => 'Beholder',
			'fileInfo.duration' => 'Varighet',
			'fileInfo.optimizedForStreaming' => 'Optimalisert for strømming',
			'fileInfo.has64bitOffsets' => '64-biters forskyvninger',
			'mediaMenu.markAsWatched' => 'Merk som sett',
			'mediaMenu.markAsUnwatched' => 'Merk som usett',
			'mediaMenu.removeFromContinueWatching' => 'Fjern fra Fortsett å se',
			'mediaMenu.viewDetails' => 'Vis detaljer',
			'mediaMenu.goToSeries' => 'Gå til serie',
			'mediaMenu.shufflePlay' => 'Tilfeldig avspilling',
			'mediaMenu.shuffleNotAvailableOffline' => 'Tilfeldig avspilling er ikke tilgjengelig offline',
			'mediaMenu.fileInfo' => 'Filinformasjon',
			'mediaMenu.deleteFromServer' => 'Slett fra server',
			'mediaMenu.confirmDelete' => 'Slette dette mediet og filene fra serveren?',
			'mediaMenu.deleteMultipleWarning' => 'Dette inkluderer alle episoder og deres filer.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medieelement slettet',
			'mediaMenu.mediaFailedToDelete' => 'Kunne ikke slette medieelement',
			'mediaMenu.rate' => 'Vurder',
			'mediaMenu.playFromBeginning' => 'Spill fra begynnelsen',
			'mediaMenu.playVersion' => 'Spill av versjon...',
			'rateSheet.title' => 'Vurder',
			'rateSheet.server' => 'Server',
			'rateSheet.favorite' => 'Favoritt',
			'rateSheet.favorited' => 'Lagt til i favoritter',
			'rateSheet.saved' => 'Lagret',
			'rateSheet.notAvailable' => 'Ingen treff',
			'rateSheet.noConnectedServices' => 'Koble til en tjeneste i Innstillinger for å vurdere her.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'sett',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} prosent sett',
			'accessibility.mediaCardUnwatched' => 'usett',
			'accessibility.tapToPlay' => 'Trykk for å spille',
			'accessibility.decrease' => 'Reduser',
			'accessibility.increase' => 'Øk',
			'accessibility.decreaseValue' => ({required Object label}) => 'Reduser ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Øk ${label}',
			'accessibility.hue' => 'Fargetone',
			'accessibility.saturation' => 'Metning',
			'accessibility.brightness' => 'Lysstyrke',
			'accessibility.hexColor' => 'Heksadesimal farge',
			'accessibility.expandText' => 'Utvid tekst',
			'accessibility.collapseText' => 'Fold sammen tekst',
			'tooltips.shufflePlay' => 'Tilfeldig avspilling',
			'tooltips.playTrailer' => 'Spill trailer',
			'tooltips.markAsWatched' => 'Merk som sett',
			'tooltips.markAsUnwatched' => 'Merk som usett',
			'videoControls.audioLabel' => 'Lyd',
			'videoControls.subtitlesLabel' => 'Undertekster',
			'videoControls.resetToZero' => 'Tilbakestill til 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} spilles senere',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} spilles tidligere',
			'videoControls.noOffset' => 'Ingen forskyvning',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Fyll skjerm',
			'videoControls.stretch' => 'Strekk',
			'videoControls.lockRotation' => 'Lås rotasjon',
			'videoControls.unlockRotation' => 'Lås opp rotasjon',
			'videoControls.timerActive' => 'Timer aktiv',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Avspilling vil pause om ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Slutten av gjeldende video',
			'videoControls.sleepTimerStopAtHeader' => 'Stopp ved',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Avspilling vil pause på slutten av denne videoen',
			'videoControls.stillWatching' => 'Ser du fortsatt?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauser om ${seconds}s',
			'videoControls.continueWatching' => 'Fortsett',
			'videoControls.autoPlayNext' => 'Spill neste automatisk',
			'videoControls.playNext' => 'Spill neste',
			'videoControls.playButton' => 'Spill av',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Spol tilbake ${seconds} sekunder',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Spol fremover ${seconds} sekunder',
			'videoControls.previousButton' => 'Forrige episode',
			'videoControls.nextButton' => 'Neste episode',
			'videoControls.previousChapterButton' => 'Forrige kapittel',
			'videoControls.nextChapterButton' => 'Neste kapittel',
			'videoControls.muteButton' => 'Demp',
			'videoControls.unmuteButton' => 'Opphev demping',
			'videoControls.settingsButton' => 'Avspillingsinnstillinger',
			'videoControls.tracksButton' => 'Lyd og undertekster',
			'videoControls.chaptersButton' => 'Kapitler',
			'videoControls.versionQualityButton' => 'Versjon og kvalitet',
			'videoControls.versionColumnHeader' => 'Versjon',
			'videoControls.qualityColumnHeader' => 'Kvalitet',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transkoding utilgjengelig — spiller av i original kvalitet',
			'videoControls.pipButton' => 'Bilde-i-bilde-modus',
			'videoControls.aspectRatioButton' => 'Sideforhold',
			'videoControls.ambientLighting' => 'Omgivelseslys',
			'videoControls.fullscreenButton' => 'Gå til fullskjerm',
			'videoControls.exitFullscreenButton' => 'Avslutt fullskjerm',
			'videoControls.alwaysOnTopButton' => 'Alltid øverst',
			'videoControls.rotationLockButton' => 'Rotasjonslås',
			'videoControls.lockScreen' => 'Lås skjerm',
			'videoControls.screenLockButton' => 'Skjermlås',
			'videoControls.longPressToUnlock' => 'Langt trykk for å låse opp',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Volumnivå',
			'videoControls.endsAt' => ({required Object time}) => 'Slutter kl. ${time}',
			'videoControls.pipActive' => 'Spiller i bilde-i-bilde',
			'videoControls.pipFailed' => 'Bilde-i-bilde kunne ikke starte',
			'videoControls.screenshotSaved' => 'Skjermbilde lagret',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Krever Android 8.0 eller nyere',
			'videoControls.pipErrors.iosVersion' => 'Krever iOS 15.0 eller nyere',
			'videoControls.pipErrors.permissionDisabled' => 'Bilde-i-bilde er deaktivert. Slå det på i systeminnstillinger.',
			'videoControls.pipErrors.notSupported' => 'Enheten støtter ikke bilde-i-bilde-modus',
			'videoControls.pipErrors.voSwitchFailed' => 'Kunne ikke bytte videoutgang for bilde-i-bilde',
			'videoControls.pipErrors.failed' => 'Bilde-i-bilde kunne ikke starte',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'En feil oppstod: ${error}',
			'videoControls.chapters' => 'Kapitler',
			'videoControls.noChaptersAvailable' => 'Ingen kapitler tilgjengelig',
			'videoControls.queue' => 'Kø',
			'videoControls.noQueueItems' => 'Ingen elementer i kø',
			'videoControls.searchSubtitles' => 'Søk etter undertekster',
			'videoControls.language' => 'Språk',
			'videoControls.noSubtitlesFound' => 'Ingen undertekster funnet',
			'videoControls.downloadedSubtitle' => 'Lastet ned',
			'videoControls.noSubtitlesAvailable' => 'Ingen undertekster tilgjengelig',
			'videoControls.noAudioTracksAvailable' => 'Ingen lydspor tilgjengelig',
			'videoControls.noTracksAvailable' => 'Ingen spor tilgjengelig',
			'videoControls.subtitleDownloaded' => 'Undertekst lastet ned',
			'videoControls.subtitleDownloadFailed' => 'Kunne ikke laste ned undertekst',
			'videoControls.searchLanguages' => 'Søk etter språk...',
			'messages.markedAsWatched' => 'Merket som sett',
			'messages.markedAsUnwatched' => 'Merket som usett',
			'messages.markedAsWatchedOffline' => 'Merket som sett (synkroniseres når tilkoblet)',
			'messages.markedAsUnwatchedOffline' => 'Merket som usett (synkroniseres når tilkoblet)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisk fjernet: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Fjernet automatisk ${n} sett nedlasting', other: 'Fjernet automatisk ${n} sette nedlastinger', ), 
			'messages.removedFromContinueWatching' => 'Fjernet fra Fortsett å se',
			'messages.errorLoading' => ({required Object error}) => 'Feil: ${error}',
			'messages.streamInterrupted' => 'Avspillingen ble avbrutt. Trykk på Spill av eller spol for å prøve på nytt.',
			'messages.liveStreamInterrupted' => 'Direktesendingen ble avbrutt. Trykk på Spill av for å prøve på nytt.',
			'messages.fileInfoNotAvailable' => 'Filinformasjon ikke tilgjengelig',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}',
			'messages.errorLoadingSeries' => 'Feil ved lasting av serie',
			'messages.musicNotSupported' => 'Musikkavspilling støttes ikke ennå',
			'messages.noDescriptionAvailable' => 'Ingen beskrivelse tilgjengelig',
			'messages.noProfilesAvailable' => 'Ingen profiler tilgjengelige',
			'messages.contactAdminForProfiles' => 'Kontakt serveradministratoren din for å legge til profiler',
			'messages.unableToDetermineLibrarySection' => 'Kan ikke fastslå bibliotekseksjonen for dette elementet',
			'messages.logsCleared' => 'Logger tømt',
			'messages.logsCopied' => 'Logger kopiert til utklippstavle',
			'messages.noLogsAvailable' => 'Ingen logger tilgjengelig',
			'messages.libraryScanning' => ({required Object title}) => 'Skanner "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Bibliotekkanning startet for "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Kunne ikke skanne bibliotek: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Oppdaterer metadata for "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Metadataoppdatering startet for "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Kunne ikke oppdatere metadata: ${error}',
			'messages.logoutConfirm' => 'Er du sikker på at du vil logge ut?',
			'messages.noSeasonsFound' => 'Ingen sesonger funnet',
			'messages.seasonsLoadFailed' => 'Kunne ikke laste sesonger',
			'messages.noEpisodesFound' => 'Ingen episoder funnet i første sesong',
			'messages.noEpisodesFoundGeneral' => 'Ingen episoder funnet',
			'messages.episodesLoadFailed' => 'Kunne ikke laste episoder',
			'messages.noResultsFound' => 'Ingen resultater funnet',
			'messages.sleepTimerSet' => ({required Object label}) => 'Søvntimer satt til ${label}',
			'messages.noItemsAvailable' => 'Ingen elementer tilgjengelig',
			'messages.failedToCreatePlayQueueNoItems' => 'Kunne ikke opprette avspillingskø – ingen elementer',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Bytter til kompatibel spiller...',
			'messages.serverLimitTitle' => 'Avspilling mislyktes',
			'messages.serverLimitBody' => 'Serverfeil (HTTP 500). En båndbredde-/transkodingsgrense avviste trolig økten. Be eieren justere den.',
			'messages.logsUploaded' => 'Logger lastet opp',
			'messages.logsUploadFailed' => 'Kunne ikke laste opp logger',
			'messages.logId' => 'Logg-ID',
			'subtitlingStyling.text' => 'Tekst',
			'subtitlingStyling.border' => 'Kantlinje',
			'subtitlingStyling.background' => 'Bakgrunn',
			'subtitlingStyling.fontSize' => 'Skriftstørrelse',
			'subtitlingStyling.textColor' => 'Tekstfarge',
			'subtitlingStyling.borderSize' => 'Kantstørrelse',
			'subtitlingStyling.borderColor' => 'Kantfarge',
			'subtitlingStyling.backgroundOpacity' => 'Bakgrunnsopasitet',
			'subtitlingStyling.backgroundColor' => 'Bakgrunnsfarge',
			'subtitlingStyling.position' => 'Posisjon',
			'subtitlingStyling.assOverride' => 'ASS-overstyring',
			'subtitlingStyling.overrideScale' => 'Skaler',
			'subtitlingStyling.overrideForce' => 'Tving',
			'subtitlingStyling.overrideStrip' => 'Fjern formatering',
			'subtitlingStyling.positionTop' => 'Øverst',
			'subtitlingStyling.positionBottom' => 'Nederst',
			'subtitlingStyling.bold' => 'Fet',
			'subtitlingStyling.italic' => 'Kursiv',
			'subtitlingStyling.renderResolution' => 'Gjengivelsesoppløsning',
			'subtitlingStyling.renderResolutionScreen' => 'Skjermoppløsning',
			'subtitlingStyling.renderResolutionVideo' => 'Videooppløsning',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Avanserte videospillerinnstillinger',
			'mpvConfig.presets' => 'Forhåndsinnstillinger',
			'mpvConfig.noPresets' => 'Ingen lagrede forhåndsinnstillinger',
			'mpvConfig.saveAsPreset' => 'Lagre som forhåndsinnstilling...',
			'mpvConfig.presetName' => 'Forhåndsinnstillingsnavn',
			'mpvConfig.presetNameHint' => 'Skriv inn et navn for denne forhåndsinnstillingen',
			'mpvConfig.loadPreset' => 'Last inn',
			'mpvConfig.deletePreset' => 'Slett',
			'mpvConfig.presetSaved' => 'Forhåndsinnstilling lagret',
			'mpvConfig.presetLoaded' => 'Forhåndsinnstilling lastet inn',
			'mpvConfig.presetDeleted' => 'Forhåndsinnstilling slettet',
			'mpvConfig.confirmDeletePreset' => 'Er du sikker på at du vil slette denne forhåndsinnstillingen?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# kommentar',
			'dialog.confirmAction' => 'Bekreft handling',
			'profiles.addPlezyProfile' => 'Legg til Plezy-profil',
			'profiles.switchingProfile' => 'Bytter profil…',
			'profiles.deleteThisProfileTitle' => 'Slett denne profilen?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Fjern ${displayName}. Tilkoblinger påvirkes ikke.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Administrer',
			'profiles.delete' => 'Slett',
			'profiles.signOut' => 'Logg ut',
			'profiles.signOutPlexTitle' => 'Logge ut av Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Fjerne ${displayName} og alle Plex Home-brukere? Du kan logge inn igjen når som helst.',
			'profiles.signedOutPlex' => 'Logget ut av Plex.',
			'profiles.signOutFailed' => 'Utlogging mislyktes.',
			'profiles.sectionTitle' => 'Profiler',
			'profiles.summarySingle' => 'Legg til profiler for å blande administrerte brukere og lokale identiteter',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profiler',
			'profiles.removeConnectionTitle' => 'Fjerne tilkobling?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Fjern ${displayName}s tilgang til ${connectionLabel}. Andre profiler beholder den.',
			'profiles.deleteProfileTitle' => 'Slette profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Fjern ${displayName} og tilkoblingene. Servere forblir tilgjengelige.',
			'profiles.profileNameLabel' => 'Profilnavn',
			'profiles.pinProtectionLabel' => 'PIN-beskyttelse',
			'profiles.pinManagedByPlex' => 'PIN administreres av Plex. Rediger på plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Ingen PIN er satt. For å kreve én, rediger Home-brukeren på plex.tv.',
			'profiles.setPin' => 'Sett PIN',
			'profiles.setPinTitle' => 'Sett PIN',
			'profiles.confirmPinTitle' => 'Bekreft PIN',
			'profiles.pinSet' => 'PIN satt',
			'profiles.changePin' => 'Endre',
			'profiles.removePin' => 'Fjern',
			'profiles.connectionsLabel' => 'Tilkoblinger',
			'profiles.add' => 'Legg til',
			'profiles.deleteProfileButton' => 'Slett profil',
			'profiles.noConnectionsHint' => 'Ingen tilkoblinger — legg til én for å bruke denne profilen.',
			'profiles.noConnections' => 'Ingen tilkoblinger',
			'profiles.plexHomeAccount' => 'Plex Home-konto',
			'profiles.connectionDefault' => 'Standard',
			'profiles.connectionAs' => ({required Object displayName}) => 'som ${displayName}',
			'profiles.makeDefault' => 'Gjør til standard',
			'profiles.removeConnection' => 'Fjern',
			'profiles.profileRenamed' => 'Profilen er omdøpt.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Legg til ${displayName}',
			'profiles.borrowExplain' => 'Lån en annen profils tilkobling. PIN-beskyttede profiler krever PIN.',
			'profiles.borrowEmpty' => 'Ingenting å låne enda.',
			'profiles.borrowEmptySubtitle' => 'Koble Plex eller Jellyfin til en annen profil først.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'Fra ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Tilkobling lånt.',
			'profiles.borrowFailed' => 'Kunne ikke låne tilkoblingen.',
			'profiles.incorrectPin' => 'Feil PIN.',
			'profiles.incorrectPinTryAgain' => 'Feil PIN. Prøv igjen.',
			'profiles.sourceProfileMissingParentAccount' => 'Kildeprofilen mangler foreldrekontoen sin.',
			'profiles.failedToLoadHomeUsers' => 'Kunne ikke laste inn Plex Home-brukerne dine. Sjekk tilkoblingen og prøv igjen.',
			'profiles.failedToVerifyPin' => 'Kunne ikke bekrefte PIN.',
			'profiles.newProfile' => 'Ny profil',
			'profiles.profileNameHint' => 'f.eks. Gjester, Barn, Familierom',
			'profiles.pinProtectionOptional' => 'PIN-beskyttelse (valgfri)',
			'profiles.pinExplain' => '4-sifret PIN kreves for å bytte profiler.',
			'profiles.continueButton' => 'Fortsett',
			'profiles.pinsDontMatch' => 'PIN-ene samsvarer ikke',
			'connections.sectionTitle' => 'Tilkoblinger',
			'connections.addConnection' => 'Legg til tilkobling',
			'connections.addConnectionSubtitleNoProfile' => 'Logg inn med Plex eller koble til en Jellyfin-server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Legg til for ${displayName}: Plex, Jellyfin eller en annen profiltilkobling',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Økten er utløpt for ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Økten er utløpt for ${count} servere',
			'connections.signInAgain' => 'Logg inn igjen',
			'connections.editJellyfinTitle' => 'Rediger Jellyfin-tilkobling',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. Plezy bruker den tilgjengelige URL-en med lavest forsinkelse.',
			'discover.title' => 'Oppdag',
			'discover.noContentAvailable' => 'Ingen innhold tilgjengelig',
			'discover.addMediaToLibraries' => 'Legg til medier i bibliotekene dine',
			'discover.continueWatching' => 'Fortsett å se',
			'discover.continueWatchingIn' => ({required Object library}) => 'Fortsett å se i ${library}',
			'discover.nextUp' => 'Neste opp',
			'discover.nextUpIn' => ({required Object library}) => 'Neste opp i ${library}',
			'discover.recentlyAdded' => 'Nylig lagt til',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Nylig lagt til i ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Nyeste album i ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Nylig spilt i ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Mest spilt i ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Oversikt',
			'discover.cast' => 'Skuespillere',
			'discover.extras' => 'Trailere og ekstra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Vurdering',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min igjen',
			'discover.moreLikeThis' => 'Mer som dette',
			'errors.searchFailed' => ({required Object error}) => 'Søk mislyktes: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tidsavbrudd ved lasting av ${context}',
			'errors.connectionFailed' => 'Kan ikke koble til medieserver',
			'errors.unableToLoad' => ({required Object context}) => 'Kunne ikke laste ${context}. Prøv igjen.',
			'errors.noClientAvailable' => 'Ingen klient tilgjengelig',
			'errors.pleaseEnterToken' => 'Vennligst skriv inn et token',
			'errors.invalidToken' => 'Ugyldig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kunne ikke verifisere token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kunne ikke bytte til ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Kunne ikke slette ${displayName}',
			'errors.failedToRate' => 'Kunne ikke oppdatere vurderingen',
			'libraries.title' => 'Biblioteker',
			'libraries.fallbackTitle' => 'Bibliotek',
			'libraries.scanLibraryFiles' => 'Skann bibliotekfiler',
			'libraries.scanLibrary' => 'Skann bibliotek',
			'libraries.analyze' => 'Analyser',
			'libraries.analyzeLibrary' => 'Analyser bibliotek',
			'libraries.refreshMetadata' => 'Oppdater metadata',
			'libraries.emptyTrash' => 'Tøm papirkurv',
			'libraries.emptyingTrash' => ({required Object title}) => 'Tømmer papirkurv for "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papirkurv tømt for "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Kunne ikke tømme papirkurv: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyserer "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Analyse startet for "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Kunne ikke analysere bibliotek: ${error}',
			'libraries.noLibrariesFound' => 'Ingen biblioteker funnet',
			'libraries.allLibrariesHidden' => 'Alle biblioteker er skjult',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Skjulte biblioteker (${count})',
			'libraries.thisLibraryIsEmpty' => 'Dette biblioteket er tomt',
			'libraries.noItemsMatchFilters' => 'Ingen elementer samsvarer med de aktive filtrene',
			'libraries.resetFilters' => 'Tilbakestill filtre',
			'libraries.all' => 'Alle',
			'libraries.clearAll' => 'Tøm alle',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Er du sikker på at du vil skanne "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Er du sikker på at du vil analysere "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Er du sikker på at du vil oppdatere metadata for "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Er du sikker på at du vil tømme papirkurven for "${title}"?',
			'libraries.manageLibraries' => 'Administrer biblioteker',
			'libraries.sort' => 'Sorter',
			'libraries.sortBy' => 'Sorter etter',
			'libraries.filters' => 'Filtre',
			'libraries.confirmActionMessage' => 'Er du sikker på at du vil utføre denne handlingen?',
			'libraries.showLibrary' => 'Vis bibliotek',
			'libraries.hideLibrary' => 'Skjul bibliotek',
			'libraries.libraryOptions' => 'Bibliotekalternativer',
			'libraries.content' => 'bibliotekinnhold',
			'libraries.selectLibrary' => 'Velg bibliotek',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtre (${count})',
			'libraries.noRecommendations' => 'Ingen anbefalinger tilgjengelig',
			'libraries.noCollections' => 'Ingen samlinger i dette biblioteket',
			'libraries.noFoldersFound' => 'Ingen mapper funnet',
			'libraries.folders' => 'mapper',
			'libraries.tabs.recommended' => 'Anbefalt',
			'libraries.tabs.browse' => 'Bla gjennom',
			'libraries.tabs.collections' => 'Samlinger',
			'libraries.tabs.playlists' => 'Spillelister',
			'libraries.groupings.title' => 'Gruppering',
			'libraries.groupings.all' => 'Alle',
			'libraries.groupings.movies' => 'Filmer',
			'libraries.groupings.shows' => 'TV-serier',
			'libraries.groupings.seasons' => 'Sesonger',
			'libraries.groupings.episodes' => 'Episoder',
			'libraries.groupings.artists' => 'Artister',
			'libraries.groupings.albums' => 'Album',
			'libraries.groupings.tracks' => 'Spor',
			'libraries.groupings.folders' => 'Mapper',
			'libraries.filterCategories.genre' => 'Sjanger',
			'libraries.filterCategories.year' => 'År',
			'libraries.filterCategories.contentRating' => 'Aldersgrense',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Usette',
			'libraries.filterCategories.unplayed' => 'Ikke avspilt',
			'libraries.filterCategories.favorites' => 'Favoritter',
			'libraries.sortLabels.title' => 'Tittel',
			'libraries.sortLabels.dateAdded' => 'Lagt til-dato',
			'libraries.sortLabels.releaseDate' => 'Utgivelsesdato',
			'libraries.sortLabels.rating' => 'Vurdering',
			'libraries.sortLabels.communityRating' => 'Fellesskapsvurdering',
			'libraries.sortLabels.criticRating' => 'Kritikervurdering',
			'libraries.sortLabels.userRating' => 'Brukervurdering',
			'libraries.sortLabels.datePlayed' => 'Avspillingsdato',
			'libraries.sortLabels.playCount' => 'Avspillinger',
			'libraries.sortLabels.productionYear' => 'Produksjonsår',
			'libraries.sortLabels.runtime' => 'Varighet',
			'libraries.sortLabels.officialRating' => 'Offisiell vurdering',
			'libraries.sortLabels.premiereDate' => 'Premieredato',
			'libraries.sortLabels.startDate' => 'Startdato',
			'libraries.sortLabels.airTime' => 'Sendetid',
			'libraries.sortLabels.studio' => 'Studio',
			'libraries.sortLabels.random' => 'Tilfeldig',
			'libraries.sortLabels.dateShared' => 'Delingsdato',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Siste episodes sendedato',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Dato for sist lagt til episode',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Åpen kildekode-lisenser',
			'about.versionLabel' => ({required Object version}) => 'Versjon ${version}',
			'about.appDescription' => 'En vakker Plex- og Jellyfin-klient for Flutter',
			'about.viewLicensesDescription' => 'Vis lisenser for tredjepartsbiblioteker',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Kunne ikke laste servere: ${error}',
			'hubDetail.title' => 'Tittel',
			'hubDetail.releaseYear' => 'Utgivelsesår',
			'hubDetail.dateAdded' => 'Dato lagt til',
			'hubDetail.rating' => 'Vurdering',
			'hubDetail.noItemsFound' => 'Ingen elementer funnet',
			'logs.clearLogs' => 'Tøm logger',
			'logs.copyLogs' => 'Kopier logger',
			'logs.uploadLogs' => 'Last opp logger',
			'licenses.relatedPackages' => 'Relaterte pakker',
			'licenses.license' => 'Lisens',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisenser',
			'navigation.libraries' => 'Biblioteker',
			'navigation.downloads' => 'Nedlastinger',
			'navigation.liveTv' => 'Direkte-TV',
			'navigation.explore' => 'Utforsk',
			'explore.title' => 'Utforsk',
			'explore.selectSource' => 'Velg kilde',
			'explore.rows.watchlist' => 'Ønskeliste',
			'explore.rows.recommendedMovies' => 'Anbefalte filmer',
			'explore.rows.recommendedShows' => 'Anbefalte serier',
			'explore.rows.trendingMovies' => 'Trending filmer',
			'explore.rows.trendingShows' => 'Trending serier',
			'explore.rows.popularMovies' => 'Populære filmer',
			'explore.rows.popularShows' => 'Populære serier',
			'explore.rows.suggestedAnime' => 'Foreslått anime',
			'explore.rows.airingAnime' => 'Topp pågående anime',
			'explore.rows.popularAnime' => 'Mest populære anime',
			'explore.rows.trending' => 'Trending',
			'explore.rows.upcomingMovies' => 'Kommende filmer',
			'explore.rows.upcomingShows' => 'Kommende serier',
			'explore.status.airing' => 'Sendes',
			'explore.status.ended' => 'Avsluttet',
			'explore.status.canceled' => 'Avlyst',
			'explore.status.upcoming' => 'Kommende',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${n} episode', other: '${n} episoder', ), 
			'explore.cast' => 'Skuespillere',
			'explore.characters' => 'Figurer',
			'explore.addToWatchlist' => 'Legg til i ønskeliste',
			'explore.removeFromWatchlist' => 'Fjern fra ønskeliste',
			'explore.watchlistUpdateFailed' => 'Kunne ikke oppdatere ønskelisten',
			'explore.notInLibrary' => 'Ikke i biblioteket ditt',
			'explore.inTheseLibraries' => 'I disse bibliotekene',
			'explore.checkingLibrary' => 'Sjekker biblioteket ditt...',
			'explore.emptyTitle' => 'Ingenting her ennå',
			'explore.emptyMessage' => ({required Object source}) => 'Rader fra ${source} vises her når de har innhold.',
			'explore.searchHint' => ({required Object source}) => 'Søk i ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Ingen treff for "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Søk etter filmer og serier på ${source}.',
			'explore.searchFailed' => 'Søk mislyktes. Sjekk tilkoblingen og prøv igjen.',
			'liveTv.title' => 'Direkte-TV',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Ingen kanaler tilgjengelig',
			'liveTv.noDvr' => 'Ingen DVR konfigurert på noen server',
			'liveTv.serverUnavailable' => 'Direkte-TV-serveren er ikke tilgjengelig.',
			'liveTv.serverNotConnected' => 'Direkte-TV-serveren er ikke tilkoblet.',
			'liveTv.noPrograms' => 'Ingen programdata tilgjengelig',
			'liveTv.liveStreamFailed' => 'Direktesending mislyktes',
			'liveTv.unknownProgram' => 'Ukjent program',
			'liveTv.unknownHub' => 'Ukjent',
			'liveTv.unknownError' => 'Ukjent feil',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.unknownChannel' => 'Ukjent kanal',
			'liveTv.live' => 'DIREKTE',
			'liveTv.reloadGuide' => 'Last inn programguide på nytt',
			'liveTv.now' => 'Nå',
			'liveTv.today' => 'I dag',
			'liveTv.tomorrow' => 'I morgen',
			'liveTv.midnight' => 'Midnatt',
			'liveTv.overnight' => 'Natt',
			'liveTv.morning' => 'Morgen',
			'liveTv.daytime' => 'Dagtid',
			'liveTv.evening' => 'Kveld',
			'liveTv.lateNight' => 'Sen kveld',
			'liveTv.whatsOn' => 'Hva går nå',
			'liveTv.watchChannel' => 'Se kanal',
			'liveTv.favorites' => 'Favoritter',
			'liveTv.reorderFavorites' => 'Endre rekkefølge på favoritter',
			'liveTv.favoritesLoadFailed' => 'Kunne ikke laste inn favoritter. Kontroller tilkoblingen og prøv på nytt.',
			'liveTv.joinSession' => 'Bli med i pågående økt',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Se fra starten (${minutes} min siden)',
			'liveTv.watchLive' => 'Se direkte',
			'liveTv.goToLive' => 'Gå til direkte',
			'liveTv.record' => 'Ta opp',
			'liveTv.recordEpisode' => 'Ta opp episode',
			'liveTv.recordSeries' => 'Ta opp serie',
			'liveTv.recordOptions' => 'Opptaksvalg',
			'liveTv.saveTo' => 'Lagre i',
			'liveTv.recordings' => 'Opptak',
			'liveTv.scheduledRecordings' => 'Planlagt',
			'liveTv.recordingRules' => 'Opptaksregler',
			'liveTv.noScheduledRecordings' => 'Ingen planlagte opptak',
			'liveTv.manageRecording' => 'Administrer opptak',
			'liveTv.cancelRecording' => 'Avbryt opptak',
			'liveTv.cancelRecordingTitle' => 'Avbryte dette opptaket?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} blir ikke lenger tatt opp.',
			'liveTv.deleteRule' => 'Slett regel',
			'liveTv.deleteRuleTitle' => 'Slette opptaksregel?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Fremtidige episoder av ${title} blir ikke tatt opp.',
			'liveTv.recordingScheduled' => 'Opptak planlagt',
			'liveTv.alreadyScheduled' => 'Dette programmet er allerede planlagt',
			'liveTv.dvrAdminRequired' => 'DVR-innstillinger krever en administratorkonto',
			'liveTv.recordingFailed' => 'Kunne ikke planlegge opptak',
			'liveTv.recordingTargetMissing' => 'Kunne ikke finne opptaksbibliotek',
			'liveTv.recordNotAvailable' => 'Opptak er ikke tilgjengelig for dette programmet',
			'liveTv.recordingCancelled' => 'Opptak avbrutt',
			'liveTv.recordingRuleDeleted' => 'Opptaksregel slettet',
			'liveTv.processRecordingRules' => 'Vurder regler på nytt',
			'liveTv.recordingInProgress' => 'Tar opp nå',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} planlagt',
			'liveTv.editRule' => 'Rediger regel',
			'liveTv.editRuleAction' => 'Rediger',
			'liveTv.recordingRuleUpdated' => 'Opptaksregel oppdatert',
			'liveTv.guideReloadRequested' => 'Forespurte guide-oppdatering',
			'liveTv.rulesProcessRequested' => 'Forespurte regelevaluering',
			'liveTv.recordShow' => 'Ta opp program',
			'collections.title' => 'Samlinger',
			'collections.collection' => 'Samling',
			'collections.empty' => 'Samlingen er tom',
			'collections.deleteCollection' => 'Slett samling',
			'collections.deleteConfirm' => ({required Object title}) => 'Slette "${title}"? Dette kan ikke angres.',
			'collections.deleted' => 'Samling slettet',
			'collections.deleteFailed' => 'Kunne ikke slette samling',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Kunne ikke slette samling: ${error}',
			'collections.selectCollection' => 'Velg samling',
			'collections.collectionName' => 'Samlingsnavn',
			'collections.enterCollectionName' => 'Skriv inn samlingsnavn',
			'collections.addedToCollection' => 'Lagt til i samling',
			'collections.errorAddingToCollection' => 'Kunne ikke legge til i samling',
			'collections.created' => 'Samling opprettet',
			'collections.removeFromCollection' => 'Fjern fra samling',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Fjerne "${title}" fra denne samlingen?',
			'collections.removedFromCollection' => 'Fjernet fra samling',
			'collections.removeFromCollectionFailed' => 'Kunne ikke fjerne fra samling',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Feil ved fjerning fra samling: ${error}',
			'collections.searchCollections' => 'Søk i samlinger...',
			'playlists.title' => 'Spillelister',
			'playlists.playlist' => 'Spilleliste',
			'playlists.noPlaylists' => 'Ingen spillelister funnet',
			'playlists.create' => 'Opprett spilleliste',
			'playlists.playlistName' => 'Spillelistenavn',
			'playlists.enterPlaylistName' => 'Skriv inn spillelistenavn',
			'playlists.delete' => 'Slett spilleliste',
			'playlists.removeItem' => 'Fjern fra spilleliste',
			'playlists.smartPlaylist' => 'Smart spilleliste',
			'playlists.itemCount' => ({required Object count}) => '${count} elementer',
			'playlists.oneItem' => '1 element',
			'playlists.emptyPlaylist' => 'Denne spillelisten er tom',
			'playlists.deleteConfirm' => 'Slett spilleliste?',
			'playlists.deleteMessage' => ({required Object name}) => 'Er du sikker på at du vil slette "${name}"?',
			'playlists.created' => 'Spilleliste opprettet',
			'playlists.deleted' => 'Spilleliste slettet',
			'playlists.itemAdded' => 'Lagt til i spilleliste',
			'playlists.itemRemoved' => 'Fjernet fra spilleliste',
			'playlists.selectPlaylist' => 'Velg spilleliste',
			'playlists.searchPlaylists' => 'Søk i spillelister...',
			'playlists.errorCreating' => 'Kunne ikke opprette spilleliste',
			'playlists.errorDeleting' => 'Kunne ikke slette spilleliste',
			'playlists.errorLoading' => 'Kunne ikke laste spillelister',
			'playlists.errorAdding' => 'Kunne ikke legge til i spilleliste',
			'playlists.errorReordering' => 'Kunne ikke omorganisere spillelisteelement',
			'playlists.errorRemoving' => 'Kunne ikke fjerne fra spilleliste',
			'music.goToAlbum' => 'Gå til album',
			'music.goToArtist' => 'Gå til artist',
			'music.instantMix' => 'Direktemiks',
			'music.playNext' => 'Spill neste',
			'music.addToQueue' => 'Legg til i kø',
			'music.discNumber' => ({required Object n}) => 'Plate ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${n} spor', other: '${n} spor', ), 
			'music.nowPlaying' => 'Spilles nå',
			'music.playingFrom' => ({required Object title}) => 'Spiller fra ${title}',
			'music.queue' => 'Kø',
			'music.clearQueue' => 'Tøm kø',
			'music.lyrics' => 'Sangtekst',
			'music.noLyrics' => 'Ingen sangtekst tilgjengelig',
			'music.sleepTimer' => 'Innsovningstimer',
			'music.sleepTimerEndOfTrack' => 'Slutten av sporet',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutter',
			'music.stopPlayback' => 'Stopp avspilling',
			'music.previousTrack' => 'Forrige spor',
			'music.nextTrack' => 'Neste spor',
			'music.repeat' => 'Gjenta',
			'music.repeatAll' => 'Gjenta alle',
			'music.repeatOne' => 'Gjenta ett spor',
			'watchTogether.title' => 'Se sammen',
			'watchTogether.description' => 'Se innhold synkronisert med venner og familie',
			'watchTogether.createSession' => 'Opprett økt',
			'watchTogether.creating' => 'Oppretter...',
			'watchTogether.joinSession' => 'Bli med i økt',
			'watchTogether.joining' => 'Blir med...',
			'watchTogether.controlMode' => 'Kontrollmodus',
			'watchTogether.controlModeQuestion' => 'Hvem kan kontrollere avspilling?',
			'watchTogether.hostOnly' => 'Kun vert',
			'watchTogether.anyone' => 'Alle',
			'watchTogether.hostingSession' => 'Er vert for økt',
			'watchTogether.inSession' => 'I økt',
			'watchTogether.sessionCode' => 'Øktkode',
			'watchTogether.openSessionControls' => 'Åpne øktkontroller for Se sammen',
			'watchTogether.copySessionCode' => 'Kopier øktkode',
			'watchTogether.hostControlsPlayback' => 'Verten kontrollerer avspilling',
			'watchTogether.anyoneCanControl' => 'Alle kan kontrollere avspilling',
			'watchTogether.hostControls' => 'Vertskontroll',
			'watchTogether.anyoneControls' => 'Alle kontrollerer',
			'watchTogether.participants' => 'Deltakere',
			'watchTogether.host' => 'Vert',
			'watchTogether.hostBadge' => 'VERT',
			'watchTogether.youAreHost' => 'Du er verten',
			'watchTogether.watchingWithOthers' => 'Ser med andre',
			'watchTogether.endSession' => 'Avslutt økt',
			'watchTogether.leaveSession' => 'Forlat økt',
			'watchTogether.endSessionQuestion' => 'Avslutte økt?',
			'watchTogether.leaveSessionQuestion' => 'Forlate økt?',
			'watchTogether.endSessionConfirm' => 'Dette vil avslutte økten for alle deltakere.',
			'watchTogether.leaveSessionConfirm' => 'Du vil bli fjernet fra økten.',
			'watchTogether.endSessionConfirmOverlay' => 'Dette vil avslutte se sammen-økten for alle deltakere.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Du vil bli frakoblet fra se sammen-økten.',
			'watchTogether.end' => 'Avslutt',
			'watchTogether.leave' => 'Forlat',
			'watchTogether.syncing' => 'Synkroniserer...',
			'watchTogether.joinWatchSession' => 'Bli med i se sammen-økt',
			'watchTogether.enterCodeHint' => 'Skriv inn 5-tegns kode',
			'watchTogether.pasteFromClipboard' => 'Lim inn fra utklippstavle',
			'watchTogether.pleaseEnterCode' => 'Vennligst skriv inn en øktkode',
			'watchTogether.codeMustBe5Chars' => 'Øktkoden må være 5 tegn',
			'watchTogether.joinInstructions' => 'Skriv inn vertens øktkode for å bli med.',
			'watchTogether.failedToCreate' => 'Kunne ikke opprette økt',
			'watchTogether.failedToJoin' => 'Kunne ikke bli med i økt',
			'watchTogether.sessionCodeCopied' => 'Øktkode kopiert til utklippstavle',
			'watchTogether.relayUnreachable' => 'Relay-serveren kan ikke nås. ISP-blokkering kan hindre Watch Together.',
			'watchTogether.reconnectingToHost' => 'Kobler til verten på nytt...',
			'watchTogether.currentPlayback' => 'Gjeldende avspilling',
			'watchTogether.joinCurrentPlayback' => 'Bli med i gjeldende avspilling',
			'watchTogether.joinCurrentPlaybackDescription' => 'Hopp tilbake til det verten ser på nå',
			'watchTogether.failedToOpenCurrentPlayback' => 'Kunne ikke åpne gjeldende avspilling',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} ble med',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} forlot',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pauset',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} gjenopptok',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} spolet',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buffrer',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} bruker en eldre appversjon — synkronisering er ikke tilgjengelig',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Fortsetter uten ${name}',
			'watchTogether.waitingForParticipants' => 'Venter på at andre laster inn...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Venter på ${name}...',
			'watchTogether.recentRooms' => 'Nylige rom',
			'watchTogether.renameRoom' => 'Gi nytt navn til rom',
			'watchTogether.removeRoom' => 'Fjern',
			'watchTogether.guestSwitchUnavailable' => 'Kunne ikke bytte — server ikke tilgjengelig for synkronisering',
			'watchTogether.guestSwitchFailed' => 'Kunne ikke bytte — innhold ble ikke funnet på denne serveren',
			'downloads.title' => 'Nedlastinger',
			'downloads.manage' => 'Administrer',
			'downloads.tvShows' => 'TV-serier',
			'downloads.movies' => 'Filmer',
			_ => null,
		} ?? switch (path) {
			'downloads.music' => 'Musikk',
			'downloads.tracksQueued' => ({required Object count}) => '${count} spor i nedlastingskø',
			'downloads.noDownloads' => 'Ingen nedlastinger ennå',
			'downloads.noDownloadsDescription' => 'Nedlastet innhold vil vises her for frakoblet visning',
			'downloads.downloadNow' => 'Last ned',
			'downloads.deleteDownload' => 'Slett nedlasting',
			'downloads.retryDownload' => 'Prøv nedlasting på nytt',
			'downloads.downloadQueued' => 'Nedlasting i kø',
			'downloads.downloadResumed' => 'Nedlasting gjenopptatt',
			'downloads.serverErrorBitrate' => 'Serverfeil: filen kan overskride grensen for ekstern bitrate',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episoder i nedlastingskø',
			'downloads.downloadDeleted' => 'Nedlasting slettet',
			'downloads.deleteConfirm' => ({required Object title}) => 'Slette "${title}" fra denne enheten?',
			'downloads.cancelledDownloadTitle' => 'Avbrutt nedlasting',
			'downloads.cancelledDownloadMessage' => 'Denne nedlastingen ble avbrutt. Hva vil du gjøre?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Alle episoder er allerede lastet ned',
			'downloads.resumeDownload' => 'Gjenoppta nedlasting',
			'downloads.cancelledDownload' => 'Avbrutt nedlasting',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (synkroniserer ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} lastet ned – klikk for å fullføre',
			'downloads.partialDownloadClickToComplete' => 'Delvis lastet ned – klikk for å fullføre',
			'downloads.deleting' => 'Sletter...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})',
			'downloads.queuedTooltip' => 'I kø',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'I kø: ${files}',
			'downloads.downloadingTooltip' => 'Laster ned...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Laster ned ${files}',
			'downloads.noDownloadsTree' => 'Ingen nedlastinger',
			'downloads.pauseAll' => 'Pause alle',
			'downloads.resumeAll' => 'Gjenoppta alle',
			'downloads.deleteAll' => 'Slett alle',
			'downloads.selectVersion' => 'Velg versjon',
			'downloads.allEpisodes' => 'Alle episoder',
			'downloads.unwatchedOnly' => 'Kun usette',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Neste ${count} usette',
			'downloads.customAmount' => 'Egendefinert antall...',
			'downloads.includeSpecials' => 'Inkluder spesialepisoder',
			'downloads.howManyEpisodes' => 'Hvor mange episoder?',
			'downloads.invalidEpisodeCount' => 'Angi et gyldig antall episoder.',
			'downloads.keepSynced' => 'Hold synkronisert',
			'downloads.downloadOnce' => 'Last ned én gang',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Behold ${count} usette',
			'downloads.editSyncRule' => 'Rediger synkroniseringsregel',
			'downloads.removeSyncRule' => 'Fjern synkroniseringsregel',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Slutte å synkronisere "${title}"? Nedlastede episoder beholdes.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synkroniseringsregel opprettet — beholder ${count} usette episoder',
			'downloads.syncRuleUpdated' => 'Synkroniseringsregel oppdatert',
			'downloads.syncRuleRemoved' => 'Synkroniseringsregel fjernet',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => 'Synkroniserte ${count} nye episoder for ${title}',
			'downloads.activeSyncRules' => 'Synkroniseringsregler',
			'downloads.noSyncRules' => 'Ingen synkroniseringsregler',
			'downloads.manageSyncRule' => 'Administrer synkronisering',
			'downloads.editEpisodeCount' => 'Antall episoder',
			'downloads.editSyncFilter' => 'Synkroniseringsfilter',
			'downloads.syncAllItems' => 'Synkroniserer alle elementer',
			'downloads.syncUnwatchedItems' => 'Synkroniserer usette elementer',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Server: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Tilgjengelig',
			'downloads.syncRuleOffline' => 'Frakoblet',
			'downloads.syncRuleSignInRequired' => 'Innlogging kreves',
			'downloads.syncRuleNotAvailableForProfile' => 'Ikke tilgjengelig for gjeldende profil',
			'downloads.syncRuleUnknownServer' => 'Ukjent server',
			'downloads.syncRuleListCreated' => 'Synkroniseringsregel opprettet',
			'shaders.title' => 'Shadere',
			'shaders.noShaderDescription' => 'Ingen videoforbedring',
			'shaders.nvscalerDescription' => 'NVIDIA bildeskalering for skarpere video',
			'shaders.artcnnVariantNeutral' => 'Nøytral',
			'shaders.artcnnVariantDenoise' => 'Støyreduksjon',
			'shaders.artcnnVariantDenoiseSharpen' => 'Støyreduksjon + skarphet',
			'shaders.qualityFast' => 'Rask',
			'shaders.qualityHQ' => 'Høy kvalitet',
			'shaders.mode' => 'Modus',
			'shaders.importShader' => 'Importer shader',
			'shaders.customShaderDescription' => 'Egendefinert GLSL-shader',
			'shaders.shaderImported' => 'Shader importert',
			'shaders.shaderImportFailed' => 'Kunne ikke importere shader',
			'shaders.deleteShader' => 'Slett shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Slette "${name}"?',
			'companionRemote.title' => 'Følgesvenn-fjernkontroll',
			'companionRemote.connectedTo' => ({required Object name}) => 'Tilkoblet ${name}',
			'companionRemote.unknownDevice' => 'Ukjent enhet',
			'companionRemote.session.startingServer' => 'Starter fjernserver...',
			'companionRemote.session.hostAddress' => 'Vertsadresse',
			'companionRemote.session.connected' => 'Tilkoblet',
			'companionRemote.session.serverRunning' => 'Fjernserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjernserver stoppet',
			'companionRemote.session.serverRunningDescription' => 'Mobile enheter på nettverket ditt kan koble til denne appen',
			'companionRemote.session.serverStoppedDescription' => 'Start serveren for å la mobilenheter koble til',
			'companionRemote.session.usePhoneToControl' => 'Bruk mobilenheten din til å styre denne appen',
			'companionRemote.session.startServer' => 'Start server',
			'companionRemote.session.stopServer' => 'Stopp server',
			'companionRemote.session.minimize' => 'Minimer',
			'companionRemote.pairing.discoveryDescription' => 'Plezy-enheter med samme Plex-konto vises her',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Kobler til...',
			'companionRemote.pairing.searchingForDevices' => 'Søker etter enheter...',
			'companionRemote.pairing.noDevicesFound' => 'Ingen enheter funnet på nettverket ditt',
			'companionRemote.pairing.noDevicesHint' => 'Åpne Plezy på desktop og bruk samme WiFi',
			'companionRemote.pairing.availableDevices' => 'Tilgjengelige enheter',
			'companionRemote.pairing.manualConnection' => 'Manuell tilkobling',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunne ikke starte sikker tilkobling. Logg inn på Plex først.',
			'companionRemote.pairing.validationHostRequired' => 'Vennligst oppgi vertsadresse',
			'companionRemote.pairing.validationHostFormat' => 'Format må være IP:port (f.eks. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tilkoblingen fikk tidsavbrudd. Bruk samme nettverk på begge enheter.',
			'companionRemote.pairing.sessionNotFound' => 'Enhet ikke funnet. Sørg for at Plezy kjører på verten.',
			'companionRemote.pairing.authFailed' => 'Autentisering mislyktes. Begge enheter må bruke samme Plex-konto.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunne ikke koble til: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vil du koble fra fjernøkten?',
			'companionRemote.remote.reconnecting' => 'Kobler til på nytt...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Forsøk ${current} av 5',
			'companionRemote.remote.retryNow' => 'Prøv nå',
			'companionRemote.remote.tabRemote' => 'Fjernkontroll',
			'companionRemote.remote.tabPlay' => 'Spill av',
			'companionRemote.remote.tabMore' => 'Mer',
			'companionRemote.remote.menu' => 'Meny',
			'companionRemote.remote.tabNavigation' => 'Fanenavigering',
			'companionRemote.remote.tabDiscover' => 'Oppdag',
			'companionRemote.remote.tabLibraries' => 'Biblioteker',
			'companionRemote.remote.tabSearch' => 'Søk',
			'companionRemote.remote.tabDownloads' => 'Nedlastinger',
			'companionRemote.remote.tabSettings' => 'Innstillinger',
			'companionRemote.remote.previous' => 'Forrige',
			'companionRemote.remote.playPause' => 'Spill av/Pause',
			'companionRemote.remote.next' => 'Neste',
			'companionRemote.remote.seekBack' => 'Spol tilbake',
			'companionRemote.remote.stop' => 'Stopp',
			'companionRemote.remote.seekForward' => 'Spol fremover',
			'companionRemote.remote.volume' => 'Volum',
			'companionRemote.remote.volumeDown' => 'Ned',
			'companionRemote.remote.volumeUp' => 'Opp',
			'companionRemote.remote.fullscreen' => 'Fullskjerm',
			'companionRemote.remote.subtitles' => 'Undertekster',
			'companionRemote.remote.audio' => 'Lyd',
			'companionRemote.remote.searchHint' => 'Søk på stasjonær...',
			'companionRemote.errors.noNetworkInterface' => 'Fant ingen nettverksgrensesnitt',
			'companionRemote.errors.authenticationFailed' => 'Autentisering mislyktes',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Kunne ikke starte fjernserveren: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Kunne ikke sende fjernkommando: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tidsavbrudd ved tilkobling til økt',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Kunne ikke koble til noen adresse',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Tilkobling mistet etter ${attempts} forsøk',
			'companionRemote.errors.connectionLost' => 'Tilkobling mistet',
			'videoSettings.playbackSpeed' => 'Avspillingshastighet',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Aktiv (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Søvntimer',
			'videoSettings.audioSync' => 'Lydsynkronisering',
			'videoSettings.subtitleSync' => 'Undertekstsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Lydutgang',
			'videoSettings.performanceOverlay' => 'Ytelsesoverlegg',
			'videoSettings.audioPassthrough' => 'Lydgjennomgang',
			'videoSettings.audioNormalization' => 'Normaliser lydstyrke',
			'videoSettings.audioDownmix' => 'Nedmiks til stereo',
			'performanceOverlay.color' => 'Farge',
			'performanceOverlay.performance' => 'Ytelse',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Dekoder',
			'performanceOverlay.rawDecoder' => 'Rå dekoder',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.aspect' => 'Format',
			'performanceOverlay.rotation' => 'Rotasjon',
			'performanceOverlay.dvSource' => 'DV-kilde',
			'performanceOverlay.dvPath' => 'DV-sti',
			'performanceOverlay.p7Conversion' => 'P7-konv.',
			'performanceOverlay.sampleRate' => 'Samplingsrate',
			'performanceOverlay.pixelFormat' => 'Pikselformat',
			'performanceOverlay.hwFormat' => 'HW-format',
			'performanceOverlay.matrix' => 'Matrise',
			'performanceOverlay.primaries' => 'Primærfarger',
			'performanceOverlay.transfer' => 'Overføring',
			'performanceOverlay.renderFps' => 'Render-FPS',
			'performanceOverlay.displayFps' => 'Skjerm-FPS',
			'performanceOverlay.avSync' => 'A/V-synk',
			'performanceOverlay.dropped' => 'Droppet',
			'performanceOverlay.dvRpus' => 'DV RPU-er',
			'performanceOverlay.dvRpuAverage' => 'DV RPU snitt',
			'performanceOverlay.dvSampleAverage' => 'DV-sample snitt',
			'performanceOverlay.maxLuma' => 'Maks luma',
			'performanceOverlay.minLuma' => 'Min luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache brukt',
			'performanceOverlay.cacheLimit' => 'Cachegrense',
			'performanceOverlay.speed' => 'Hastighet',
			'performanceOverlay.player' => 'Spiller',
			'performanceOverlay.memory' => 'Minne',
			'performanceOverlay.uiFps' => 'UI FPS',
			'externalPlayer.title' => 'Ekstern spiller',
			'externalPlayer.useExternalPlayer' => 'Bruk ekstern spiller',
			'externalPlayer.useExternalPlayerDescription' => 'Åpne videoer i en annen app',
			'externalPlayer.selectPlayer' => 'Velg spiller',
			'externalPlayer.customPlayers' => 'Egendefinerte spillere',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Legg til egendefinert spiller',
			'externalPlayer.playerName' => 'Spillernavn',
			'externalPlayer.playerNameHint' => 'Min spiller',
			'externalPlayer.playerCommand' => 'Kommando',
			'externalPlayer.playerPackage' => 'Pakkenavn',
			'externalPlayer.playerUrlScheme' => 'URL-skjema',
			'externalPlayer.off' => 'Av',
			'externalPlayer.launchFailed' => 'Kunne ikke åpne ekstern spiller',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} er ikke installert',
			'externalPlayer.playInExternalPlayer' => 'Spill av i ekstern spiller',
			'metadataEdit.editMetadata' => 'Rediger...',
			'metadataEdit.screenTitle' => 'Rediger metadata',
			'metadataEdit.basicInfo' => 'Grunnleggende info',
			'metadataEdit.artwork' => 'Kunstverk',
			'metadataEdit.advancedSettings' => 'Avanserte innstillinger',
			'metadataEdit.title' => 'Tittel',
			'metadataEdit.sortTitle' => 'Sorteringsstittel',
			'metadataEdit.originalTitle' => 'Originaltittel',
			'metadataEdit.releaseDate' => 'Utgivelsesdato',
			'metadataEdit.contentRating' => 'Innholdsvurdering',
			'metadataEdit.studio' => 'Studio',
			'metadataEdit.tagline' => 'Slagord',
			'metadataEdit.summary' => 'Sammendrag',
			'metadataEdit.poster' => 'Plakat',
			'metadataEdit.background' => 'Bakgrunn',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Kvadratisk bilde',
			'metadataEdit.selectPoster' => 'Velg plakat',
			'metadataEdit.selectBackground' => 'Velg bakgrunn',
			'metadataEdit.selectLogo' => 'Velg logo',
			'metadataEdit.selectSquareArt' => 'Velg kvadratisk bilde',
			'metadataEdit.fromUrl' => 'Fra URL',
			'metadataEdit.uploadFile' => 'Last opp fil',
			'metadataEdit.enterImageUrl' => 'Skriv inn bilde-URL',
			'metadataEdit.imageUrl' => 'Bilde-URL',
			'metadataEdit.metadataUpdated' => 'Metadata oppdatert',
			'metadataEdit.metadataUpdateFailed' => 'Kunne ikke oppdatere metadata',
			'metadataEdit.artworkUpdated' => 'Kunstverk oppdatert',
			'metadataEdit.artworkUpdateFailed' => 'Kunne ikke oppdatere kunstverk',
			'metadataEdit.noArtworkAvailable' => 'Ingen kunstverk tilgjengelig',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Alternativ for kunstverk ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Alternativ for kunstverk ${index}, valgt',
			'metadataEdit.notSet' => 'Ikke angitt',
			'metadataEdit.libraryDefault' => 'Bibliotekstandard',
			'metadataEdit.accountDefault' => 'Kontostandard',
			'metadataEdit.seriesDefault' => 'Seriestandard',
			'metadataEdit.episodeSorting' => 'Episodesortering',
			'metadataEdit.oldestFirst' => 'Eldste først',
			'metadataEdit.newestFirst' => 'Nyeste først',
			'metadataEdit.keep' => 'Behold',
			'metadataEdit.allEpisodes' => 'Alle episoder',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} nyeste episoder',
			'metadataEdit.latestEpisode' => 'Nyeste episode',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episoder lagt til de siste ${count} dagene',
			'metadataEdit.deleteAfterPlaying' => 'Slett episoder etter avspilling',
			'metadataEdit.never' => 'Aldri',
			'metadataEdit.afterADay' => 'Etter en dag',
			'metadataEdit.afterAWeek' => 'Etter en uke',
			'metadataEdit.afterAMonth' => 'Etter en måned',
			'metadataEdit.onNextRefresh' => 'Ved neste oppdatering',
			'metadataEdit.seasons' => 'Sesonger',
			'metadataEdit.show' => 'Vis',
			'metadataEdit.hide' => 'Skjul',
			'metadataEdit.episodeOrdering' => 'Episoderekkefølge',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Sendt)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Sendt)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absolutt)',
			'metadataEdit.metadataLanguage' => 'Metadataspråk',
			'metadataEdit.useOriginalTitle' => 'Bruk originaltittel',
			'metadataEdit.preferredAudioLanguage' => 'Foretrukket lydspråk',
			'metadataEdit.preferredSubtitleLanguage' => 'Foretrukket undertekstspråk',
			'metadataEdit.subtitleMode' => 'Automatisk valg av undertekstmodus',
			'metadataEdit.manuallySelected' => 'Manuelt valgt',
			'metadataEdit.shownWithForeignAudio' => 'Vist med fremmedspråklig lyd',
			'metadataEdit.alwaysEnabled' => 'Alltid aktivert',
			'metadataEdit.tags' => 'Tagger',
			'metadataEdit.addTag' => 'Legg til tagg',
			'metadataEdit.genre' => 'Sjanger',
			'metadataEdit.director' => 'Regissør',
			'metadataEdit.writer' => 'Forfatter',
			'metadataEdit.producer' => 'Produsent',
			'metadataEdit.country' => 'Land',
			'metadataEdit.collection' => 'Samling',
			'metadataEdit.label' => 'Etikett',
			'metadataEdit.style' => 'Stil',
			'metadataEdit.mood' => 'Stemning',
			'matchScreen.match' => 'Match...',
			'matchScreen.fixMatch' => 'Rett match...',
			'matchScreen.unmatch' => 'Fjern match',
			'matchScreen.unmatchConfirm' => 'Fjerne denne matchen? Plex behandler den som umatchet til den matches igjen.',
			'matchScreen.unmatchSuccess' => 'Match fjernet',
			'matchScreen.unmatchFailed' => 'Kunne ikke fjerne match',
			'matchScreen.matchApplied' => 'Match anvendt',
			'matchScreen.matchFailed' => 'Kunne ikke anvende match',
			'matchScreen.titleHint' => 'Tittel',
			'matchScreen.yearHint' => 'År',
			'matchScreen.search' => 'Søk',
			'matchScreen.noMatchesFound' => 'Ingen treff funnet',
			'serverTasks.title' => 'Serveroppgaver',
			'serverTasks.failedToLoad' => 'Kunne ikke laste oppgaver',
			'serverTasks.noTasks' => 'Ingen oppgaver kjører',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Tilkoblet',
			'trakt.connectedAs' => ({required Object username}) => 'Tilkoblet som @${username}',
			'trakt.disconnectConfirm' => 'Koble fra Trakt-konto?',
			'trakt.disconnectConfirmBody' => 'Plezy slutter å sende hendelser til Trakt. Du kan koble til igjen når som helst.',
			'trakt.scrobble' => 'Sanntids-scrobbling',
			'trakt.scrobbleDescription' => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.',
			'trakt.watchedSync' => 'Synkroniser sett-status',
			'trakt.watchedSyncDescription' => 'Når du markerer noe som sett i Plezy, markeres det også på Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Koble til Seerr',
			'seerr.serverUrl' => 'Server-URL',
			'seerr.serverUrlHelper' => 'Adressen til Seerr-instansen din',
			'seerr.checkServer' => 'Fortsett',
			'seerr.signInWithJellyfin' => 'Logg inn med Jellyfin',
			'seerr.signInWithEmby' => 'Logg inn med Emby',
			'seerr.signInWithLocal' => 'Bruk en lokal konto',
			'seerr.email' => 'E-post',
			'seerr.noSignInMethods' => 'Denne Seerr-instansen tilbyr ingen innloggingsmetode som Plezy støtter.',
			'seerr.instance' => 'Instans',
			'seerr.disconnectConfirm' => 'Koble fra Seerr?',
			'seerr.disconnectConfirmBody' => 'Plezy glemmer denne Seerr-instansen. Koble til igjen når som helst.',
			'seerr.request' => 'Forespør',
			'seerr.request4k' => 'Forespør i 4K',
			'seerr.seasons' => 'Sesonger',
			'seerr.allSeasons' => 'Alle sesonger',
			'seerr.advancedOptions' => 'Avansert',
			'seerr.destinationServer' => 'Målserver',
			'seerr.qualityProfile' => 'Kvalitetsprofil',
			'seerr.rootFolder' => 'Rotmappe',
			'seerr.languageProfile' => 'Språkprofil',
			'seerr.requestSubmitted' => 'Forespørsel sendt',
			'seerr.requestFailed' => ({required Object error}) => 'Forespørsel mislyktes: ${error}',
			'seerr.requestsLoadFailed' => 'Kunne ikke laste forespørselsalternativer',
			'seerr.nothingToRequest' => 'Alt er allerede tilgjengelig eller forespurt.',
			'seerr.statusAvailable' => 'Tilgjengelig',
			'seerr.statusPartiallyAvailable' => 'Delvis tilgjengelig',
			'seerr.statusRequested' => 'Forespurt',
			'seerr.statusProcessing' => 'Behandler',
			'services.title' => 'Tjenester',
			'services.hubSubtitle' => 'Synkroniser fremdrift og forespør nye titler.',
			'services.notConnected' => 'Ikke tilkoblet',
			'services.connectedAs' => ({required Object username}) => 'Tilkoblet som @${username}',
			'services.scrobble' => 'Registrer fremdrift automatisk',
			'services.scrobbleDescription' => 'Oppdater listen din når du er ferdig med en episode eller film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Koble fra ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy slutter å oppdatere ${service}. Koble til igjen når som helst.',
			'services.connectFailed' => ({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Aktiver Plezy på ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Besøk ${url} og skriv inn denne koden:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Åpne ${service} for å aktivere',
			'services.deviceCode.copyCode' => 'Kopier aktiveringskode',
			'services.deviceCode.waitingForAuthorization' => 'Venter på godkjenning…',
			'services.deviceCode.codeCopied' => 'Kode kopiert',
			'services.oauthProxy.title' => ({required Object service}) => 'Logg inn på ${service}',
			'services.oauthProxy.body' => 'Skann denne QR-koden eller åpne URL-en på en enhet.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Åpne ${service} for å logge inn',
			'services.oauthProxy.copyUrl' => 'Kopier URL for pålogging',
			'services.oauthProxy.urlCopied' => 'URL kopiert',
			'services.libraryFilter.title' => 'Biblioteksfilter',
			'services.libraryFilter.subtitleAllSyncing' => 'Synkroniserer alle biblioteker',
			'services.libraryFilter.subtitleNoneSyncing' => 'Ingenting synkroniseres',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blokkert',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} tillatt',
			'services.libraryFilter.mode' => 'Filtermodus',
			'services.libraryFilter.modeBlacklist' => 'Svarteliste',
			'services.libraryFilter.modeWhitelist' => 'Hviteliste',
			'services.libraryFilter.modeHintBlacklist' => 'Synkroniser alle biblioteker bortsett fra dem du markerer nedenfor.',
			'services.libraryFilter.modeHintWhitelist' => 'Synkroniser kun bibliotekene du markerer nedenfor.',
			'services.libraryFilter.libraries' => 'Biblioteker',
			'services.libraryFilter.noLibraries' => 'Ingen biblioteker tilgjengelige',
			'addServer.addJellyfinTitle' => 'Legg til Jellyfin-server',
			'addServer.serverUrls' => 'Server-URL-er',
			'addServer.serverUrlsHelper' => 'Flere URL-er er tillatt, atskilt med komma.',
			'addServer.findServer' => 'Finn server',
			'addServer.searchingLocalServers' => 'Søker etter lokale Jellyfin-servere...',
			'addServer.localServers' => 'Lokale Jellyfin-servere',
			'addServer.username' => 'Brukernavn',
			'addServer.password' => 'Passord',
			'addServer.signIn' => 'Logg på',
			'addServer.change' => 'Endre',
			'addServer.required' => 'Påkrevd',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Kunne ikke nå serveren: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Pålogging mislyktes: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect mislyktes: ${error}',
			'addServer.addPlexTitle' => 'Logg på med Plex',
			'addServer.pinExpired' => 'PIN-koden gikk ut før pålogging. Prøv igjen.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Kunne ikke registrere kontoen: ${error}',
			'addServer.enterJellyfinUrlError' => 'Oppgi URL-en til Jellyfin-serveren din',
			'addServer.addConnectionTitle' => 'Legg til tilkobling',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Legg til i ${name}',
			'addServer.signInWithPlexCard' => 'Logg på med Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriser denne enheten. Delte servere legges til.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriser en Plex-konto. Home-brukere blir profiler.',
			'addServer.connectToJellyfinCard' => 'Koble til Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Skriv inn server-URL, brukernavn og passord.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Logg på en Jellyfin-server. Knyttes til ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Lån fra en annen profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Gjenbruk en annen profils tilkobling. PIN-beskyttede profiler krever PIN.',
			_ => null,
		};
	}
}
