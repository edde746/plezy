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
	@override late final _TranslationsAccessibilityNb accessibility = _TranslationsAccessibilityNb._(_root);
	@override late final _TranslationsTooltipsNb tooltips = _TranslationsTooltipsNb._(_root);
	@override late final _TranslationsVideoControlsNb videoControls = _TranslationsVideoControlsNb._(_root);
	@override late final _TranslationsUserStatusNb userStatus = _TranslationsUserStatusNb._(_root);
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
	@override late final _TranslationsLiveTvNb liveTv = _TranslationsLiveTvNb._(_root);
	@override late final _TranslationsCollectionsNb collections = _TranslationsCollectionsNb._(_root);
	@override late final _TranslationsPlaylistsNb playlists = _TranslationsPlaylistsNb._(_root);
	@override late final _TranslationsWatchTogetherNb watchTogether = _TranslationsWatchTogetherNb._(_root);
	@override late final _TranslationsDownloadsNb downloads = _TranslationsDownloadsNb._(_root);
	@override late final _TranslationsShadersNb shaders = _TranslationsShadersNb._(_root);
	@override late final _TranslationsCompanionRemoteNb companionRemote = _TranslationsCompanionRemoteNb._(_root);
	@override late final _TranslationsVideoSettingsNb videoSettings = _TranslationsVideoSettingsNb._(_root);
	@override late final _TranslationsExternalPlayerNb externalPlayer = _TranslationsExternalPlayerNb._(_root);
	@override late final _TranslationsMetadataEditNb metadataEdit = _TranslationsMetadataEditNb._(_root);
	@override late final _TranslationsMatchScreenNb matchScreen = _TranslationsMatchScreenNb._(_root);
	@override late final _TranslationsServerTasksNb serverTasks = _TranslationsServerTasksNb._(_root);
	@override late final _TranslationsTraktNb trakt = _TranslationsTraktNb._(_root);
	@override late final _TranslationsTrackersNb trackers = _TranslationsTrackersNb._(_root);
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
	@override String get signIn => 'Logg på';
	@override String get signInWithPlex => 'Logg inn med Plex';
	@override String get showQRCode => 'Vis QR-kode';
	@override String get authenticate => 'Autentiser';
	@override String get authenticationTimeout => 'Autentiseringen ble tidsavbrutt. Prøv igjen.';
	@override String get scanQRToSignIn => 'Skann denne QR-koden for å logge inn';
	@override String get waitingForAuth => 'Venter på autentisering...\nFullfør innloggingen i nettleseren din.';
	@override String get useBrowser => 'Bruk nettleser';
	@override String get or => 'eller';
	@override String get connectToJellyfin => 'Koble til Jellyfin';
	@override String get useQuickConnect => 'Bruk Quick Connect';
	@override String get quickConnectCode => 'Quick Connect-kode';
	@override String get quickConnectInstructions => 'Åpne Jellyfin-serveren din i en nettleser, logg inn, og velg Quick Connect i brukermenyen. Skriv inn denne koden for å godkjenne påloggingen.';
	@override String get quickConnectWaiting => 'Venter på godkjenning…';
	@override String get quickConnectCancel => 'Avbryt';
	@override String get quickConnectExpired => 'Quick Connect-koden utløp før godkjenning. Prøv igjen.';
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
	@override String get reconnect => 'Koble til på nytt';
	@override String get exitConfirmTitle => 'Avslutte appen?';
	@override String get exitConfirmMessage => 'Er du sikker på at du vil avslutte?';
	@override String get dontAskAgain => 'Ikke spør igjen';
	@override String get exit => 'Avslutt';
	@override String get viewAll => 'Vis alle';
	@override String get checkingNetwork => 'Sjekker nettverk...';
	@override String get refreshingServers => 'Oppdaterer servere...';
	@override String get loadingServers => 'Laster servere...';
	@override String get connectingToServers => 'Kobler til servere...';
	@override String get startingOfflineMode => 'Starter frakoblet modus...';
	@override String get loading => 'Laster...';
	@override String get fullscreen => 'Fullskjerm';
	@override String get exitFullscreen => 'Avslutt fullskjerm';
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
	@override String get useGlobalHubs => 'Bruk startoppsett';
	@override String get useGlobalHubsDescription => 'Vis startside-hubber som den offisielle klienten. Når av, vises anbefalinger per bibliotek i stedet.';
	@override String get showServerNameOnHubs => 'Vis servernavn på huber';
	@override String get showServerNameOnHubsDescription => 'Vis alltid servernavnet i hubtitler. Når av, vises kun for dupliserte hubnavn.';
	@override String get groupLibrariesByServer => 'Grupper biblioteker etter server';
	@override String get groupLibrariesByServerDescription => 'Vis en overskrift for hver medieserver i sidefeltet når du er koblet til flere servere.';
	@override String get alwaysKeepSidebarOpen => 'Hold sidefeltet alltid åpent';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg';
	@override String get showUnwatchedCount => 'Vis antall usette';
	@override String get showUnwatchedCountDescription => 'Vis antall usette episoder på serier og sesonger';
	@override String get showEpisodeNumberOnCards => 'Vis episodenummer på kort';
	@override String get showEpisodeNumberOnCardsDescription => 'Vis episodenummer ved siden av sesongen (f.eks. S2 E3) på episodekort';
	@override String get showSeasonPostersOnTabs => 'Vis sesongplakater på faner';
	@override String get showSeasonPostersOnTabsDescription => 'Vis sesongens plakat over hver sesongfane på en series detaljside';
	@override String get hideSpoilers => 'Skjul spoilere for usette episoder';
	@override String get hideSpoilersDescription => 'Slør miniatyrbilder og skjul beskrivelser for episoder du ikke har sett ennå';
	@override String get playerBackend => 'Spillermotor';
	@override String get exoPlayer => 'ExoPlayer (Anbefalt)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Maskinvaredekoding';
	@override String get hardwareDecodingDescription => 'Bruk maskinvareakselerasjon når tilgjengelig';
	@override String get bufferSize => 'Bufferstørrelse';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Anbefalt)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Enheten din har ${heap}MB minne. En ${size}MB buffer kan forårsake avspillingsproblemer.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get defaultQualityDescription => 'Brukes ved start av avspilling. Lavere verdier reduserer båndbredden.';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpass utseendet på undertekster';
	@override String get smallSkipDuration => 'Kort hoppvarighet';
	@override String get largeSkipDuration => 'Lang hoppvarighet';
	@override String get rewindOnResume => 'Spol tilbake ved gjenopptakelse';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard søvntimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutter';
	@override String get rememberTrackSelections => 'Husk sporvalg per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Lagre automatisk lyd- og undertekstspråkpreferanser når du bytter spor under avspilling';
	@override String get clickVideoTogglesPlayback => 'Klikk på video for å veksle avspilling';
	@override String get clickVideoTogglesPlaybackDescription => 'Hvis aktivert, vil klikk på videospilleren spille av/pause videoen. Ellers vil klikk vise/skjule avspillingskontrollene.';
	@override String get videoPlayerControls => 'Videospillerkontroller';
	@override String get keyboardShortcuts => 'Tastatursnarveier';
	@override String get keyboardShortcutsDescription => 'Tilpass tastatursnarveier';
	@override String get videoPlayerNavigation => 'Videospillernavigering';
	@override String get videoPlayerNavigationDescription => 'Bruk piltaster for å navigere videospillerkontroller';
	@override String get watchTogetherRelay => 'Se Sammen-relay';
	@override String get watchTogetherRelayDescription => 'Angi en egendefinert relay-server for Se Sammen. Alle deltakere må bruke den samme serveren.';
	@override String get watchTogetherRelayHint => 'https://min-relay.eksempel.no';
	@override String get crashReporting => 'Krasjrapportering';
	@override String get crashReportingDescription => 'Send krasjrapporter for å hjelpe med å forbedre appen';
	@override String get debugLogging => 'Feilsøkingslogging';
	@override String get debugLoggingDescription => 'Aktiver detaljert logging for feilsøking';
	@override String get viewLogs => 'Vis logger';
	@override String get viewLogsDescription => 'Vis applikasjonslogger';
	@override String get clearCache => 'Tøm hurtigbuffer';
	@override String get clearCacheDescription => 'Dette vil tømme alle hurtigbufrede bilder og data. Appen kan bruke lengre tid på å laste innhold etter tømming.';
	@override String get clearCacheSuccess => 'Hurtigbuffer tømt';
	@override String get resetSettings => 'Tilbakestill innstillinger';
	@override String get resetSettingsDescription => 'Dette vil tilbakestille alle innstillinger til standardverdier. Denne handlingen kan ikke angres.';
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
	@override String get autoCheckUpdatesOnStartupDescription => 'Vis et varsel når en ny versjon er tilgjengelig ved oppstart';
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
	@override String get forceSkipMarkerFallbackDescription => 'Bruk kapitteltittel-mønstre for hoppmarkører selv når Plex leverer innebygde markører';
	@override String get autoSkipDelay => 'Forsinkelse for automatisk hopp';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping';
	@override String get introPattern => 'Intromarkørmønster';
	@override String get introPatternDescription => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler';
	@override String get creditsPattern => 'Rulletekstmarkørmønster';
	@override String get creditsPatternDescription => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler';
	@override String get invalidRegex => 'Ugyldig regulært uttrykk';
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
	@override String get autoRemoveWatchedDownloadsDescription => 'Slett nedlastede episoder og filmer automatisk når de er markert som sett';
	@override String get cellularDownloadBlocked => 'Nedlastinger er deaktivert på mobildata. Koble til WiFi eller endre innstillingen.';
	@override String get maxVolume => 'Maks volum';
	@override String get maxVolumeDescription => 'Tillat volumforsterkning over 100% for stille media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Vis hva du ser på Discord';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Synkroniser visningshistorikk med Trakt';
	@override String get trackers => 'Trackere';
	@override String get trackersDescription => 'Synkroniser fremdrift til Trakt, MyAnimeList, AniList og Simkl';
	@override String get companionRemoteServer => 'Companion Remote-server';
	@override String get companionRemoteServerDescription => 'Tillat mobilenheter på nettverket ditt å styre denne appen';
	@override String get autoPip => 'Auto bilde-i-bilde';
	@override String get autoPipDescription => 'Gå automatisk til bilde-i-bilde når du forlater appen under avspilling';
	@override String get matchContentFrameRate => 'Tilpass innholdets bildefrekvens';
	@override String get matchContentFrameRateDescription => 'Juster skjermens oppdateringsfrekvens for å matche videoinnhold, reduserer hakking og sparer batteri';
	@override String get matchRefreshRate => 'Tilpass oppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Bytt skjermens oppdateringsfrekvens for å matche videoinnhold i fullskjerm';
	@override String get matchDynamicRange => 'Tilpass dynamisk område';
	@override String get matchDynamicRangeDescription => 'Aktiver HDR automatisk for HDR-innhold og gå tilbake til SDR når spilleren lukkes';
	@override String get displaySwitchDelay => 'Forsinkelse ved skjermbytte';
	@override String get tunneledPlayback => 'Tunnelert avspilling';
	@override String get tunneledPlaybackDescription => 'Bruk maskinvareakselerert videotunnelering. Deaktiver hvis du ser svart skjerm med lyd på HDR-innhold';
	@override String get requireProfileSelectionOnOpen => 'Spør om profil ved appåpning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åpnes';
	@override String get confirmExitOnBack => 'Bekreft før avslutning';
	@override String get confirmExitOnBackDescription => 'Vis en bekreftelsesdialog når du trykker tilbake for å avslutte appen';
	@override String get forceTvMode => 'Tving TV-modus';
	@override String get forceTvModeDescription => 'Bruk TV-oppsettet uavhengig av automatisk gjenkjenning. Nyttig på Android TV-enheter som ikke rapporterer leanback-funksjonen. Starter appen på nytt ved endring.';
	@override String get startInFullscreen => 'Start i fullskjerm';
	@override String get startInFullscreenDescription => 'Åpne Plezy i fullskjermmodus ved oppstart';
	@override String get autoHidePerformanceOverlay => 'Skjul ytelsesoverlegg automatisk';
	@override String get autoHidePerformanceOverlayDescription => 'Fade ytelsesoverlegget med avspillingskontrollene';
	@override String get showNavBarLabels => 'Vis navigasjonsfeltlabeler';
	@override String get showNavBarLabelsDescription => 'Vis tekstlabeler under navigasjonsfeltikoner';
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
	@override String get goToSeries => 'Gå til serie';
	@override String get goToSeason => 'Gå til sesong';
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get fileInfo => 'Filinformasjon';
	@override String get deleteFromServer => 'Slett fra server';
	@override String get confirmDelete => 'Dette vil permanent slette dette mediet og filene fra serveren din. Dette kan ikke angres.';
	@override String get deleteMultipleWarning => 'Dette inkluderer alle episoder og deres filer.';
	@override String get mediaDeletedSuccessfully => 'Medieelement slettet';
	@override String get mediaFailedToDelete => 'Kunne ikke slette medieelement';
	@override String get rate => 'Vurder';
	@override String get playFromBeginning => 'Spill fra begynnelsen';
	@override String get playVersion => 'Spill av versjon...';
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
	@override String get settingsButton => 'Videoinnstillinger';
	@override String get tracksButton => 'Lyd og undertekster';
	@override String get chaptersButton => 'Kapitler';
	@override String get versionsButton => 'Videoversjoner';
	@override String get versionQualityButton => 'Versjon og kvalitet';
	@override String get versionColumnHeader => 'Versjon';
	@override String get qualityColumnHeader => 'Kvalitet';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
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
	@override late final _TranslationsVideoControlsPipErrorsNb pipErrors = _TranslationsVideoControlsPipErrorsNb._(_root);
	@override String get chapters => 'Kapitler';
	@override String get noChaptersAvailable => 'Ingen kapitler tilgjengelig';
	@override String get queue => 'Kø';
	@override String get noQueueItems => 'Ingen elementer i kø';
	@override String get searchSubtitles => 'Søk etter undertekster';
	@override String get language => 'Språk';
	@override String get noSubtitlesFound => 'Ingen undertekster funnet';
	@override String get subtitleDownloaded => 'Undertekst lastet ned';
	@override String get subtitleDownloadFailed => 'Kunne ikke laste ned undertekst';
	@override String get searchLanguages => 'Søk etter språk...';
}

// Path: userStatus
class _TranslationsUserStatusNb extends TranslationsUserStatusEn {
	_TranslationsUserStatusNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Administrator';
	@override String get restricted => 'Begrenset';
	@override String get protected => 'Beskyttet';
	@override String get current => 'GJELDENDE';
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
	@override String get removedFromContinueWatching => 'Fjernet fra Fortsett å se';
	@override String errorLoading({required Object error}) => 'Feil: ${error}';
	@override String get fileInfoNotAvailable => 'Filinformasjon ikke tilgjengelig';
	@override String errorLoadingFileInfo({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}';
	@override String get errorLoadingSeries => 'Feil ved lasting av serie';
	@override String get errorLoadingSeason => 'Feil ved lasting av sesong';
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
	@override String get noEpisodesFound => 'Ingen episoder funnet i første sesong';
	@override String get noEpisodesFoundGeneral => 'Ingen episoder funnet';
	@override String get noResultsFound => 'Ingen resultater funnet';
	@override String sleepTimerSet({required Object label}) => 'Søvntimer satt til ${label}';
	@override String get noItemsAvailable => 'Ingen elementer tilgjengelig';
	@override String get failedToCreatePlayQueueNoItems => 'Kunne ikke opprette avspillingskø – ingen elementer';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Bytter til kompatibel spiller...';
	@override String get serverLimitTitle => 'Avspilling mislyktes';
	@override String get serverLimitBody => 'Serveren returnerte en feil (HTTP 500). Det betyr vanligvis at servereieren har satt en båndbredde- eller transkodingsgrense som avviser økten din. Det er ingenting du kan gjøre fra klienten — servereieren må justere innstillingene sine.';
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
	@override String get bold => 'Fet';
	@override String get italic => 'Kursiv';
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
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} fjernes. Tilkoblinger påvirkes ikke.';
	@override String get active => 'Aktiv';
	@override String get manage => 'Administrer';
	@override String get delete => 'Slett';
	@override String get signOut => 'Logg ut';
	@override String get signOutPlexTitle => 'Logge ut av Plex?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} og alle Plex Home-brukere på denne kontoen fjernes fra denne enheten. Du kan logge inn igjen når som helst.';
	@override String get signedOutPlex => 'Logget ut av Plex.';
	@override String get signOutFailed => 'Utlogging mislyktes.';
	@override String get sectionTitle => 'Profiler';
	@override String get summarySingle => 'Legg til profiler for å blande administrerte brukere og lokale identiteter';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} profiler';
	@override String get removeConnectionTitle => 'Fjerne tilkobling?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} mister tilgang til ${connectionLabel}. Tilkoblingen er fortsatt tilgjengelig for andre profiler.';
	@override String get deleteProfileTitle => 'Slette profil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Dette fjerner ${displayName} og alle dens tilkoblinger fra denne enheten. De underliggende Plex/Jellyfin-serverne berøres ikke.';
	@override String get profileNameLabel => 'Profilnavn';
	@override String get pinProtectionLabel => 'PIN-beskyttelse';
	@override String get pinManagedByPlex => 'PIN administreres av Plex. Rediger på plex.tv.';
	@override String get noPinSetEditOnPlex => 'Ingen PIN er satt. For å kreve én, rediger Home-brukeren på plex.tv.';
	@override String get setPin => 'Sett PIN';
	@override String get connectionsLabel => 'Tilkoblinger';
	@override String get add => 'Legg til';
	@override String get deleteProfileButton => 'Slett profil';
	@override String get noConnectionsHint => 'Ingen tilkoblinger — legg til én for å bruke denne profilen.';
	@override String get plexHomeAccount => 'Plex Home-konto';
	@override String get connectionDefault => 'Standard';
	@override String get makeDefault => 'Gjør til standard';
	@override String get removeConnection => 'Fjern';
	@override String borrowAddTo({required Object displayName}) => 'Legg til ${displayName}';
	@override String get borrowExplain => 'Lån en tilkobling fra en annen profil. PIN-beskyttede kildeprofiler ber om PIN før deling.';
	@override String get borrowEmpty => 'Ingenting å låne enda.';
	@override String get borrowEmptySubtitle => 'Koble først en Plex-konto eller Jellyfin-server til en annen profil, og kom så tilbake hit.';
	@override String get newProfile => 'Ny profil';
	@override String get profileNameHint => 'f.eks. Gjester, Barn, Familierom';
	@override String get pinProtectionOptional => 'PIN-beskyttelse (valgfri)';
	@override String get pinExplain => '4-sifret PIN kreves for å bytte til denne profilen. Myk barriere — alle som kan fjerne appdata kan omgå den.';
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
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Legg til ${displayName} — Plex-konto, Jellyfin-server eller lån fra en annen profil';
	@override String sessionExpiredOne({required Object name}) => 'Økten er utløpt for ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Økten er utløpt for ${count} servere';
	@override String get signInAgain => 'Logg inn igjen';
}

// Path: discover
class _TranslationsDiscoverNb extends TranslationsDiscoverEn {
	_TranslationsDiscoverNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oppdag';
	@override String get switchProfile => 'Bytt profil';
	@override String get noContentAvailable => 'Ingen innhold tilgjengelig';
	@override String get addMediaToLibraries => 'Legg til medier i bibliotekene dine';
	@override String get continueWatching => 'Fortsett å se';
	@override String get nextUp => 'Neste opp';
	@override String get recentlyAdded => 'Nylig lagt til';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Oversikt';
	@override String get cast => 'Skuespillere';
	@override String get extras => 'Trailere og ekstra';
	@override String get studio => 'Studio';
	@override String get rating => 'Vurdering';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min igjen';
}

// Path: errors
class _TranslationsErrorsNb extends TranslationsErrorsEn {
	_TranslationsErrorsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Søk mislyktes: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tidsavbrudd ved lasting av ${context}';
	@override String get connectionFailed => 'Kan ikke koble til medieserver';
	@override String failedToLoad({required Object context, required Object error}) => 'Kunne ikke laste ${context}: ${error}';
	@override String get noClientAvailable => 'Ingen klient tilgjengelig';
	@override String authenticationFailed({required Object error}) => 'Autentisering mislyktes: ${error}';
	@override String get couldNotLaunchUrl => 'Kunne ikke åpne autentiserings-URL';
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
	@override String get allServerConnectionsFailed => 'Kunne ikke koble til noen servere. Sjekk nettverket ditt og prøv igjen.';
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
	@override String get noPrograms => 'Ingen programdata tilgjengelig';
	@override String get live => 'DIREKTE';
	@override String get reloadGuide => 'Last inn programguide på nytt';
	@override String get now => 'Nå';
	@override String get today => 'I dag';
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
	@override String get joinSession => 'Bli med i pågående økt';
	@override String watchFromStart({required Object minutes}) => 'Se fra starten (${minutes} min siden)';
	@override String get watchLive => 'Se direkte';
	@override String get goToLive => 'Gå til direkte';
}

// Path: collections
class _TranslationsCollectionsNb extends TranslationsCollectionsEn {
	_TranslationsCollectionsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Samlinger';
	@override String get collection => 'Samling';
	@override String get empty => 'Samlingen er tom';
	@override String get unknownLibrarySection => 'Kan ikke slette: Ukjent bibliotekseksjon';
	@override String get deleteCollection => 'Slett samling';
	@override String deleteConfirm({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Denne handlingen kan ikke angres.';
	@override String get deleted => 'Samling slettet';
	@override String get deleteFailed => 'Kunne ikke slette samling';
	@override String deleteFailedWithError({required Object error}) => 'Kunne ikke slette samling: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Kunne ikke laste samlingselementer: ${error}';
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
	@override String get errorCreating => 'Kunne ikke opprette spilleliste';
	@override String get errorDeleting => 'Kunne ikke slette spilleliste';
	@override String get errorLoading => 'Kunne ikke laste spillelister';
	@override String get errorAdding => 'Kunne ikke legge til i spilleliste';
	@override String get errorReordering => 'Kunne ikke omorganisere spillelisteelement';
	@override String get errorRemoving => 'Kunne ikke fjerne fra spilleliste';
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
	@override String get joinInstructions => 'Skriv inn øktkoden delt av verten for å bli med i se sammen-økten.';
	@override String get failedToCreate => 'Kunne ikke opprette økt';
	@override String get failedToJoin => 'Kunne ikke bli med i økt';
	@override String get sessionCodeCopied => 'Øktkode kopiert til utklippstavle';
	@override String get relayUnreachable => 'Reléserveren er utilgjengelig. Dette kan skyldes at internettleverandøren din blokkerer tilkoblingen. Du kan fortsatt prøve, men Se sammen fungerer kanskje ikke.';
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
	@override String get waitingForParticipants => 'Venter på at andre laster inn...';
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
	@override String get noDownloads => 'Ingen nedlastinger ennå';
	@override String get noDownloadsDescription => 'Nedlastet innhold vil vises her for frakoblet visning';
	@override String get downloadNow => 'Last ned';
	@override String get deleteDownload => 'Slett nedlasting';
	@override String get retryDownload => 'Prøv nedlasting på nytt';
	@override String get downloadQueued => 'Nedlasting i kø';
	@override String get serverErrorBitrate => 'Serverfeil — filen overskrider muligens grensen for fjernstrømming-bitrate';
	@override String episodesQueued({required Object count}) => '${count} episoder i nedlastingskø';
	@override String get downloadDeleted => 'Nedlasting slettet';
	@override String deleteConfirm({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Dette vil fjerne den nedlastede filen fra enheten din.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})';
	@override String get deleting => 'Sletter...';
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
	@override String get howManyEpisodes => 'Hvor mange episoder?';
	@override String itemsQueued({required Object count}) => '${count} elementer i nedlastingskø';
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
	@override late final _TranslationsCompanionRemoteSessionNb session = _TranslationsCompanionRemoteSessionNb._(_root);
	@override late final _TranslationsCompanionRemotePairingNb pairing = _TranslationsCompanionRemotePairingNb._(_root);
	@override late final _TranslationsCompanionRemoteRemoteNb remote = _TranslationsCompanionRemoteRemoteNb._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsNb extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Avspillingsinnstillinger';
	@override String get playbackSpeed => 'Avspillingshastighet';
	@override String get sleepTimer => 'Søvntimer';
	@override String get audioSync => 'Lydsynkronisering';
	@override String get subtitleSync => 'Undertekstsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Lydutgang';
	@override String get performanceOverlay => 'Ytelsesoverlegg';
	@override String get audioPassthrough => 'Lydgjennomgang';
	@override String get audioNormalization => 'Normaliser lydstyrke';
}

// Path: externalPlayer
class _TranslationsExternalPlayerNb extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ekstern spiller';
	@override String get useExternalPlayer => 'Bruk ekstern spiller';
	@override String get useExternalPlayerDescription => 'Åpne videoer i en ekstern app i stedet for den innebygde spilleren';
	@override String get selectPlayer => 'Velg spiller';
	@override String get customPlayers => 'Egendefinerte spillere';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Legg til egendefinert spiller';
	@override String get playerName => 'Spillernavn';
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
	@override String get unmatchConfirm => 'Fjerne gjeldende match for dette elementet? Plex behandler det som umatchet til du matcher det igjen.';
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
	@override String get disconnectConfirmBody => 'Plezy slutter å sende avspillingshendelser til Trakt. Du kan koble til igjen når som helst.';
	@override String get scrobble => 'Sanntids-scrobbling';
	@override String get scrobbleDescription => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.';
	@override String get watchedSync => 'Synkroniser sett-status';
	@override String get watchedSyncDescription => 'Når du markerer noe som sett i Plezy, markeres det også på Trakt.';
}

// Path: trackers
class _TranslationsTrackersNb extends TranslationsTrackersEn {
	_TranslationsTrackersNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trackere';
	@override String get hubSubtitle => 'Hold visningsfremdriften synkronisert med Trakt og andre tjenester.';
	@override String get notConnected => 'Ikke tilkoblet';
	@override String connectedAs({required Object username}) => 'Tilkoblet som @${username}';
	@override String get scrobble => 'Registrer fremdrift automatisk';
	@override String get scrobbleDescription => 'Oppdater listen din når du er ferdig med en episode eller film.';
	@override String disconnectConfirm({required Object service}) => 'Koble fra ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy slutter å oppdatere ${service}-listen din. Du kan koble til igjen når som helst.';
	@override String connectFailed({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.';
	@override late final _TranslationsTrackersServicesNb services = _TranslationsTrackersServicesNb._(_root);
	@override late final _TranslationsTrackersDeviceCodeNb deviceCode = _TranslationsTrackersDeviceCodeNb._(_root);
	@override late final _TranslationsTrackersOauthProxyNb oauthProxy = _TranslationsTrackersOauthProxyNb._(_root);
	@override late final _TranslationsTrackersLibraryFilterNb libraryFilter = _TranslationsTrackersLibraryFilterNb._(_root);
}

// Path: addServer
class _TranslationsAddServerNb extends TranslationsAddServerEn {
	_TranslationsAddServerNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Legg til Jellyfin-server';
	@override String get jellyfinUrlIntro => 'Oppgi URL-en til Jellyfin-serveren din — f.eks. `https://jellyfin.example.com`. Du kan logge på etterpå.';
	@override String get serverUrl => 'Server-URL';
	@override String get findServer => 'Finn server';
	@override String get username => 'Brukernavn';
	@override String get password => 'Passord';
	@override String get signIn => 'Logg på';
	@override String get change => 'Endre';
	@override String get required => 'Påkrevd';
	@override String couldNotReachServer({required Object error}) => 'Kunne ikke nå serveren: ${error}';
	@override String signInFailed({required Object error}) => 'Pålogging mislyktes: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect mislyktes: ${error}';
	@override String get addPlexTitle => 'Logg på med Plex';
	@override String get plexAuthIntro => 'Velg hvordan du vil logge på Plex. Nettleserflyten åpner plex.tv der du bekrefter tilkoblingen; QR-alternativet er praktisk for TV / fjern-enheter.';
	@override String get plexQRPrompt => 'Skann denne QR-koden for å logge på.';
	@override String get waitingForPlexConfirmation => 'Venter på at plex.tv bekrefter påloggingen…';
	@override String get pinExpired => 'PIN-koden gikk ut før pålogging. Prøv igjen.';
	@override String get duplicatePlexAccount => 'Denne enheten er allerede pålogget en Plex-konto. Logg ut fra innstillingene for å bytte konto.';
	@override String failedToRegisterAccount({required Object error}) => 'Kunne ikke registrere kontoen: ${error}';
	@override String get enterJellyfinUrlError => 'Oppgi URL-en til Jellyfin-serveren din';
	@override String get addConnectionTitle => 'Legg til tilkobling';
	@override String addConnectionTitleScoped({required Object name}) => 'Legg til i ${name}';
	@override String get addConnectionIntroGlobal => 'Legg til enda en medieserver. Du kan blande Plex-kontoer og Jellyfin-servere — innhold fra alle tilkoblede backender vises sammen på startsiden.';
	@override String get addConnectionIntroScoped => 'Legg til en ny server, eller lån en fra en annen profil.';
	@override String get signInWithPlexCard => 'Logg på med Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriser denne enheten mot Plex-kontoen din. Servere delt med kontoen følger med automatisk.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriser en ny Plex-konto. Dens Home-brukere vises som profiler.';
	@override String get connectToJellyfinCard => 'Koble til Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Oppgi URL-en til Jellyfin-serveren din og logg på med brukernavn + passord (Quick Connect kommer snart).';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Logg på en Jellyfin-server. Knyttes til ${name}.';
	@override String get borrowFromAnotherProfile => 'Lån fra en annen profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Gjenbruk en tilkobling som allerede er tilknyttet en annen profil. PIN-beskyttede kildeprofiler ber om PIN.';
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
	@override String get subSeekNext => 'Spol til neste undertekst';
	@override String get subSeekPrev => 'Spol til forrige undertekst';
	@override String get shaderToggle => 'Veksle shadere';
	@override String get skipMarker => 'Hopp over intro/rulletekst';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsNb extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Krever Android 8.0 eller nyere';
	@override String get iosVersion => 'Krever iOS 15.0 eller nyere';
	@override String get permissionDisabled => 'Bilde-i-bilde-tillatelse er deaktivert. Aktiver den i Innstillinger > Apper > Plezy > Bilde-i-bilde';
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
	@override String get lastPlayed => 'Sist spilt';
	@override String get playCount => 'Avspillinger';
	@override String get random => 'Tilfeldig';
	@override String get dateShared => 'Delingsdato';
	@override String get latestEpisodeAirDate => 'Siste episodes sendedato';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionNb extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Starter fjernserver...';
	@override String get failedToCreate => 'Kunne ikke starte fjernserver:';
	@override String get hostAddress => 'Vertsadresse';
	@override String get connected => 'Tilkoblet';
	@override String get serverRunning => 'Fjernserver aktiv';
	@override String get serverStopped => 'Fjernserver stoppet';
	@override String get serverRunningDescription => 'Mobilenheter på nettverket ditt kan oppdage og koble til denne appen';
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
	@override String get discoveryDescription => 'Enheter på nettverket ditt som kjører Plezy med samme Plex-konto vil vises automatisk';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Kobler til...';
	@override String get searchingForDevices => 'Søker etter enheter...';
	@override String get noDevicesFound => 'Ingen enheter funnet på nettverket ditt';
	@override String get noDevicesHint => 'Sørg for at Plezy er åpen på datamaskinen din og at begge enhetene er på samme WiFi-nettverk';
	@override String get availableDevices => 'Tilgjengelige enheter';
	@override String get manualConnection => 'Manuell tilkobling';
	@override String get cryptoInitFailed => 'Kunne ikke initialisere sikker tilkobling. Sørg for at du er logget inn på en Plex-konto.';
	@override String get validationHostRequired => 'Vennligst oppgi vertsadresse';
	@override String get validationHostFormat => 'Format må være IP:port (f.eks. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tilkoblingen ble tidsavbrutt. Sørg for at begge enhetene er på samme nettverk.';
	@override String get sessionNotFound => 'Kunne ikke finne enheten. Sørg for at Plezy kjører på verten.';
	@override String get authFailed => 'Autentisering mislyktes. Sørg for at begge enhetene bruker samme Plex-konto.';
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

// Path: trackers.services
class _TranslationsTrackersServicesNb extends TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodeNb extends TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodeNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Aktiver Plezy på ${service}';
	@override String body({required Object url}) => 'Besøk ${url} og skriv inn denne koden:';
	@override String openToActivate({required Object service}) => 'Åpne ${service} for å aktivere';
	@override String get waitingForAuthorization => 'Venter på godkjenning…';
	@override String get codeCopied => 'Kode kopiert';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyNb extends TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyNb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Logg inn på ${service}';
	@override String get body => 'Skann denne QR-koden med telefonen din, eller åpne URL-en under på en enhet med nettleser.';
	@override String openToSignIn({required Object service}) => 'Åpne ${service} for å logge inn';
	@override String get urlCopied => 'URL kopiert';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterNb extends TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterNb._(TranslationsNb root) : this._root = root, super.internal(root);

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
			'auth.signIn' => 'Logg på',
			'auth.signInWithPlex' => 'Logg inn med Plex',
			'auth.showQRCode' => 'Vis QR-kode',
			'auth.authenticate' => 'Autentiser',
			'auth.authenticationTimeout' => 'Autentiseringen ble tidsavbrutt. Prøv igjen.',
			'auth.scanQRToSignIn' => 'Skann denne QR-koden for å logge inn',
			'auth.waitingForAuth' => 'Venter på autentisering...\nFullfør innloggingen i nettleseren din.',
			'auth.useBrowser' => 'Bruk nettleser',
			'auth.or' => 'eller',
			'auth.connectToJellyfin' => 'Koble til Jellyfin',
			'auth.useQuickConnect' => 'Bruk Quick Connect',
			'auth.quickConnectCode' => 'Quick Connect-kode',
			'auth.quickConnectInstructions' => 'Åpne Jellyfin-serveren din i en nettleser, logg inn, og velg Quick Connect i brukermenyen. Skriv inn denne koden for å godkjenne påloggingen.',
			'auth.quickConnectWaiting' => 'Venter på godkjenning…',
			'auth.quickConnectCancel' => 'Avbryt',
			'auth.quickConnectExpired' => 'Quick Connect-koden utløp før godkjenning. Prøv igjen.',
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
			'common.reconnect' => 'Koble til på nytt',
			'common.exitConfirmTitle' => 'Avslutte appen?',
			'common.exitConfirmMessage' => 'Er du sikker på at du vil avslutte?',
			'common.dontAskAgain' => 'Ikke spør igjen',
			'common.exit' => 'Avslutt',
			'common.viewAll' => 'Vis alle',
			'common.checkingNetwork' => 'Sjekker nettverk...',
			'common.refreshingServers' => 'Oppdaterer servere...',
			'common.loadingServers' => 'Laster servere...',
			'common.connectingToServers' => 'Kobler til servere...',
			'common.startingOfflineMode' => 'Starter frakoblet modus...',
			'common.loading' => 'Laster...',
			'common.fullscreen' => 'Fullskjerm',
			'common.exitFullscreen' => 'Avslutt fullskjerm',
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
			'settings.useGlobalHubs' => 'Bruk startoppsett',
			'settings.useGlobalHubsDescription' => 'Vis startside-hubber som den offisielle klienten. Når av, vises anbefalinger per bibliotek i stedet.',
			'settings.showServerNameOnHubs' => 'Vis servernavn på huber',
			'settings.showServerNameOnHubsDescription' => 'Vis alltid servernavnet i hubtitler. Når av, vises kun for dupliserte hubnavn.',
			'settings.groupLibrariesByServer' => 'Grupper biblioteker etter server',
			'settings.groupLibrariesByServerDescription' => 'Vis en overskrift for hver medieserver i sidefeltet når du er koblet til flere servere.',
			'settings.alwaysKeepSidebarOpen' => 'Hold sidefeltet alltid åpent',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg',
			'settings.showUnwatchedCount' => 'Vis antall usette',
			'settings.showUnwatchedCountDescription' => 'Vis antall usette episoder på serier og sesonger',
			'settings.showEpisodeNumberOnCards' => 'Vis episodenummer på kort',
			'settings.showEpisodeNumberOnCardsDescription' => 'Vis episodenummer ved siden av sesongen (f.eks. S2 E3) på episodekort',
			'settings.showSeasonPostersOnTabs' => 'Vis sesongplakater på faner',
			'settings.showSeasonPostersOnTabsDescription' => 'Vis sesongens plakat over hver sesongfane på en series detaljside',
			'settings.hideSpoilers' => 'Skjul spoilere for usette episoder',
			'settings.hideSpoilersDescription' => 'Slør miniatyrbilder og skjul beskrivelser for episoder du ikke har sett ennå',
			'settings.playerBackend' => 'Spillermotor',
			'settings.exoPlayer' => 'ExoPlayer (Anbefalt)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Maskinvaredekoding',
			'settings.hardwareDecodingDescription' => 'Bruk maskinvareakselerasjon når tilgjengelig',
			'settings.bufferSize' => 'Bufferstørrelse',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Anbefalt)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Enheten din har ${heap}MB minne. En ${size}MB buffer kan forårsake avspillingsproblemer.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.defaultQualityDescription' => 'Brukes ved start av avspilling. Lavere verdier reduserer båndbredden.',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpass utseendet på undertekster',
			'settings.smallSkipDuration' => 'Kort hoppvarighet',
			'settings.largeSkipDuration' => 'Lang hoppvarighet',
			'settings.rewindOnResume' => 'Spol tilbake ved gjenopptakelse',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard søvntimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutter',
			'settings.rememberTrackSelections' => 'Husk sporvalg per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Lagre automatisk lyd- og undertekstspråkpreferanser når du bytter spor under avspilling',
			'settings.clickVideoTogglesPlayback' => 'Klikk på video for å veksle avspilling',
			'settings.clickVideoTogglesPlaybackDescription' => 'Hvis aktivert, vil klikk på videospilleren spille av/pause videoen. Ellers vil klikk vise/skjule avspillingskontrollene.',
			'settings.videoPlayerControls' => 'Videospillerkontroller',
			'settings.keyboardShortcuts' => 'Tastatursnarveier',
			'settings.keyboardShortcutsDescription' => 'Tilpass tastatursnarveier',
			'settings.videoPlayerNavigation' => 'Videospillernavigering',
			'settings.videoPlayerNavigationDescription' => 'Bruk piltaster for å navigere videospillerkontroller',
			'settings.watchTogetherRelay' => 'Se Sammen-relay',
			'settings.watchTogetherRelayDescription' => 'Angi en egendefinert relay-server for Se Sammen. Alle deltakere må bruke den samme serveren.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.eksempel.no',
			'settings.crashReporting' => 'Krasjrapportering',
			'settings.crashReportingDescription' => 'Send krasjrapporter for å hjelpe med å forbedre appen',
			'settings.debugLogging' => 'Feilsøkingslogging',
			'settings.debugLoggingDescription' => 'Aktiver detaljert logging for feilsøking',
			'settings.viewLogs' => 'Vis logger',
			'settings.viewLogsDescription' => 'Vis applikasjonslogger',
			'settings.clearCache' => 'Tøm hurtigbuffer',
			'settings.clearCacheDescription' => 'Dette vil tømme alle hurtigbufrede bilder og data. Appen kan bruke lengre tid på å laste innhold etter tømming.',
			'settings.clearCacheSuccess' => 'Hurtigbuffer tømt',
			'settings.resetSettings' => 'Tilbakestill innstillinger',
			'settings.resetSettingsDescription' => 'Dette vil tilbakestille alle innstillinger til standardverdier. Denne handlingen kan ikke angres.',
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
			'settings.autoCheckUpdatesOnStartupDescription' => 'Vis et varsel når en ny versjon er tilgjengelig ved oppstart',
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
			'settings.forceSkipMarkerFallbackDescription' => 'Bruk kapitteltittel-mønstre for hoppmarkører selv når Plex leverer innebygde markører',
			'settings.autoSkipDelay' => 'Forsinkelse for automatisk hopp',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Vent ${seconds} sekunder før automatisk hopping',
			'settings.introPattern' => 'Intromarkørmønster',
			'settings.introPatternDescription' => 'Regulært uttrykk for å gjenkjenne intromarkører i kapitteltitler',
			'settings.creditsPattern' => 'Rulletekstmarkørmønster',
			'settings.creditsPatternDescription' => 'Regulært uttrykk for å gjenkjenne rulletekstmarkører i kapitteltitler',
			'settings.invalidRegex' => 'Ugyldig regulært uttrykk',
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
			'settings.autoRemoveWatchedDownloadsDescription' => 'Slett nedlastede episoder og filmer automatisk når de er markert som sett',
			'settings.cellularDownloadBlocked' => 'Nedlastinger er deaktivert på mobildata. Koble til WiFi eller endre innstillingen.',
			'settings.maxVolume' => 'Maks volum',
			'settings.maxVolumeDescription' => 'Tillat volumforsterkning over 100% for stille media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Vis hva du ser på Discord',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Synkroniser visningshistorikk med Trakt',
			'settings.trackers' => 'Trackere',
			'settings.trackersDescription' => 'Synkroniser fremdrift til Trakt, MyAnimeList, AniList og Simkl',
			'settings.companionRemoteServer' => 'Companion Remote-server',
			'settings.companionRemoteServerDescription' => 'Tillat mobilenheter på nettverket ditt å styre denne appen',
			'settings.autoPip' => 'Auto bilde-i-bilde',
			'settings.autoPipDescription' => 'Gå automatisk til bilde-i-bilde når du forlater appen under avspilling',
			'settings.matchContentFrameRate' => 'Tilpass innholdets bildefrekvens',
			'settings.matchContentFrameRateDescription' => 'Juster skjermens oppdateringsfrekvens for å matche videoinnhold, reduserer hakking og sparer batteri',
			'settings.matchRefreshRate' => 'Tilpass oppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Bytt skjermens oppdateringsfrekvens for å matche videoinnhold i fullskjerm',
			'settings.matchDynamicRange' => 'Tilpass dynamisk område',
			'settings.matchDynamicRangeDescription' => 'Aktiver HDR automatisk for HDR-innhold og gå tilbake til SDR når spilleren lukkes',
			'settings.displaySwitchDelay' => 'Forsinkelse ved skjermbytte',
			'settings.tunneledPlayback' => 'Tunnelert avspilling',
			'settings.tunneledPlaybackDescription' => 'Bruk maskinvareakselerert videotunnelering. Deaktiver hvis du ser svart skjerm med lyd på HDR-innhold',
			'settings.requireProfileSelectionOnOpen' => 'Spør om profil ved appåpning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åpnes',
			'settings.confirmExitOnBack' => 'Bekreft før avslutning',
			'settings.confirmExitOnBackDescription' => 'Vis en bekreftelsesdialog når du trykker tilbake for å avslutte appen',
			'settings.forceTvMode' => 'Tving TV-modus',
			'settings.forceTvModeDescription' => 'Bruk TV-oppsettet uavhengig av automatisk gjenkjenning. Nyttig på Android TV-enheter som ikke rapporterer leanback-funksjonen. Starter appen på nytt ved endring.',
			'settings.startInFullscreen' => 'Start i fullskjerm',
			'settings.startInFullscreenDescription' => 'Åpne Plezy i fullskjermmodus ved oppstart',
			'settings.autoHidePerformanceOverlay' => 'Skjul ytelsesoverlegg automatisk',
			'settings.autoHidePerformanceOverlayDescription' => 'Fade ytelsesoverlegget med avspillingskontrollene',
			'settings.showNavBarLabels' => 'Vis navigasjonsfeltlabeler',
			'settings.showNavBarLabelsDescription' => 'Vis tekstlabeler under navigasjonsfeltikoner',
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
			'hotkeys.actions.subSeekNext' => 'Spol til neste undertekst',
			'hotkeys.actions.subSeekPrev' => 'Spol til forrige undertekst',
			'hotkeys.actions.shaderToggle' => 'Veksle shadere',
			'hotkeys.actions.skipMarker' => 'Hopp over intro/rulletekst',
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
			'mediaMenu.goToSeries' => 'Gå til serie',
			'mediaMenu.goToSeason' => 'Gå til sesong',
			'mediaMenu.shufflePlay' => 'Tilfeldig avspilling',
			'mediaMenu.fileInfo' => 'Filinformasjon',
			'mediaMenu.deleteFromServer' => 'Slett fra server',
			'mediaMenu.confirmDelete' => 'Dette vil permanent slette dette mediet og filene fra serveren din. Dette kan ikke angres.',
			'mediaMenu.deleteMultipleWarning' => 'Dette inkluderer alle episoder og deres filer.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Medieelement slettet',
			'mediaMenu.mediaFailedToDelete' => 'Kunne ikke slette medieelement',
			'mediaMenu.rate' => 'Vurder',
			'mediaMenu.playFromBeginning' => 'Spill fra begynnelsen',
			'mediaMenu.playVersion' => 'Spill av versjon...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, TV-serie',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'sett',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} prosent sett',
			'accessibility.mediaCardUnwatched' => 'usett',
			'accessibility.tapToPlay' => 'Trykk for å spille',
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
			'videoControls.settingsButton' => 'Videoinnstillinger',
			'videoControls.tracksButton' => 'Lyd og undertekster',
			'videoControls.chaptersButton' => 'Kapitler',
			'videoControls.versionsButton' => 'Videoversjoner',
			'videoControls.versionQualityButton' => 'Versjon og kvalitet',
			'videoControls.versionColumnHeader' => 'Versjon',
			'videoControls.qualityColumnHeader' => 'Kvalitet',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
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
			'videoControls.pipErrors.androidVersion' => 'Krever Android 8.0 eller nyere',
			'videoControls.pipErrors.iosVersion' => 'Krever iOS 15.0 eller nyere',
			'videoControls.pipErrors.permissionDisabled' => 'Bilde-i-bilde-tillatelse er deaktivert. Aktiver den i Innstillinger > Apper > Plezy > Bilde-i-bilde',
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
			'videoControls.subtitleDownloaded' => 'Undertekst lastet ned',
			'videoControls.subtitleDownloadFailed' => 'Kunne ikke laste ned undertekst',
			'videoControls.searchLanguages' => 'Søk etter språk...',
			'userStatus.admin' => 'Administrator',
			'userStatus.restricted' => 'Begrenset',
			'userStatus.protected' => 'Beskyttet',
			'userStatus.current' => 'GJELDENDE',
			'messages.markedAsWatched' => 'Merket som sett',
			'messages.markedAsUnwatched' => 'Merket som usett',
			'messages.markedAsWatchedOffline' => 'Merket som sett (synkroniseres når tilkoblet)',
			'messages.markedAsUnwatchedOffline' => 'Merket som usett (synkroniseres når tilkoblet)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisk fjernet: ${title}',
			'messages.removedFromContinueWatching' => 'Fjernet fra Fortsett å se',
			'messages.errorLoading' => ({required Object error}) => 'Feil: ${error}',
			'messages.fileInfoNotAvailable' => 'Filinformasjon ikke tilgjengelig',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}',
			'messages.errorLoadingSeries' => 'Feil ved lasting av serie',
			'messages.errorLoadingSeason' => 'Feil ved lasting av sesong',
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
			'messages.noEpisodesFound' => 'Ingen episoder funnet i første sesong',
			'messages.noEpisodesFoundGeneral' => 'Ingen episoder funnet',
			'messages.noResultsFound' => 'Ingen resultater funnet',
			'messages.sleepTimerSet' => ({required Object label}) => 'Søvntimer satt til ${label}',
			'messages.noItemsAvailable' => 'Ingen elementer tilgjengelig',
			'messages.failedToCreatePlayQueueNoItems' => 'Kunne ikke opprette avspillingskø – ingen elementer',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Bytter til kompatibel spiller...',
			'messages.serverLimitTitle' => 'Avspilling mislyktes',
			'messages.serverLimitBody' => 'Serveren returnerte en feil (HTTP 500). Det betyr vanligvis at servereieren har satt en båndbredde- eller transkodingsgrense som avviser økten din. Det er ingenting du kan gjøre fra klienten — servereieren må justere innstillingene sine.',
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
			'subtitlingStyling.bold' => 'Fet',
			'subtitlingStyling.italic' => 'Kursiv',
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
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} fjernes. Tilkoblinger påvirkes ikke.',
			'profiles.active' => 'Aktiv',
			'profiles.manage' => 'Administrer',
			'profiles.delete' => 'Slett',
			'profiles.signOut' => 'Logg ut',
			'profiles.signOutPlexTitle' => 'Logge ut av Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} og alle Plex Home-brukere på denne kontoen fjernes fra denne enheten. Du kan logge inn igjen når som helst.',
			'profiles.signedOutPlex' => 'Logget ut av Plex.',
			'profiles.signOutFailed' => 'Utlogging mislyktes.',
			'profiles.sectionTitle' => 'Profiler',
			'profiles.summarySingle' => 'Legg til profiler for å blande administrerte brukere og lokale identiteter',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} profiler · aktiv: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} profiler',
			'profiles.removeConnectionTitle' => 'Fjerne tilkobling?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} mister tilgang til ${connectionLabel}. Tilkoblingen er fortsatt tilgjengelig for andre profiler.',
			'profiles.deleteProfileTitle' => 'Slette profil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Dette fjerner ${displayName} og alle dens tilkoblinger fra denne enheten. De underliggende Plex/Jellyfin-serverne berøres ikke.',
			'profiles.profileNameLabel' => 'Profilnavn',
			'profiles.pinProtectionLabel' => 'PIN-beskyttelse',
			'profiles.pinManagedByPlex' => 'PIN administreres av Plex. Rediger på plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Ingen PIN er satt. For å kreve én, rediger Home-brukeren på plex.tv.',
			'profiles.setPin' => 'Sett PIN',
			'profiles.connectionsLabel' => 'Tilkoblinger',
			'profiles.add' => 'Legg til',
			_ => null,
		} ?? switch (path) {
			'profiles.deleteProfileButton' => 'Slett profil',
			'profiles.noConnectionsHint' => 'Ingen tilkoblinger — legg til én for å bruke denne profilen.',
			'profiles.plexHomeAccount' => 'Plex Home-konto',
			'profiles.connectionDefault' => 'Standard',
			'profiles.makeDefault' => 'Gjør til standard',
			'profiles.removeConnection' => 'Fjern',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Legg til ${displayName}',
			'profiles.borrowExplain' => 'Lån en tilkobling fra en annen profil. PIN-beskyttede kildeprofiler ber om PIN før deling.',
			'profiles.borrowEmpty' => 'Ingenting å låne enda.',
			'profiles.borrowEmptySubtitle' => 'Koble først en Plex-konto eller Jellyfin-server til en annen profil, og kom så tilbake hit.',
			'profiles.newProfile' => 'Ny profil',
			'profiles.profileNameHint' => 'f.eks. Gjester, Barn, Familierom',
			'profiles.pinProtectionOptional' => 'PIN-beskyttelse (valgfri)',
			'profiles.pinExplain' => '4-sifret PIN kreves for å bytte til denne profilen. Myk barriere — alle som kan fjerne appdata kan omgå den.',
			'profiles.continueButton' => 'Fortsett',
			'profiles.pinsDontMatch' => 'PIN-ene samsvarer ikke',
			'connections.sectionTitle' => 'Tilkoblinger',
			'connections.addConnection' => 'Legg til tilkobling',
			'connections.addConnectionSubtitleNoProfile' => 'Logg inn med Plex eller koble til en Jellyfin-server',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Legg til ${displayName} — Plex-konto, Jellyfin-server eller lån fra en annen profil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Økten er utløpt for ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Økten er utløpt for ${count} servere',
			'connections.signInAgain' => 'Logg inn igjen',
			'discover.title' => 'Oppdag',
			'discover.switchProfile' => 'Bytt profil',
			'discover.noContentAvailable' => 'Ingen innhold tilgjengelig',
			'discover.addMediaToLibraries' => 'Legg til medier i bibliotekene dine',
			'discover.continueWatching' => 'Fortsett å se',
			'discover.nextUp' => 'Neste opp',
			'discover.recentlyAdded' => 'Nylig lagt til',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Oversikt',
			'discover.cast' => 'Skuespillere',
			'discover.extras' => 'Trailere og ekstra',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Vurdering',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min igjen',
			'errors.searchFailed' => ({required Object error}) => 'Søk mislyktes: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tidsavbrudd ved lasting av ${context}',
			'errors.connectionFailed' => 'Kan ikke koble til medieserver',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Kunne ikke laste ${context}: ${error}',
			'errors.noClientAvailable' => 'Ingen klient tilgjengelig',
			'errors.authenticationFailed' => ({required Object error}) => 'Autentisering mislyktes: ${error}',
			'errors.couldNotLaunchUrl' => 'Kunne ikke åpne autentiserings-URL',
			'errors.pleaseEnterToken' => 'Vennligst skriv inn et token',
			'errors.invalidToken' => 'Ugyldig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kunne ikke verifisere token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kunne ikke bytte til ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Kunne ikke slette ${displayName}',
			'errors.failedToRate' => 'Kunne ikke oppdatere vurderingen',
			'libraries.title' => 'Biblioteker',
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
			'libraries.groupings.folders' => 'Mapper',
			'libraries.filterCategories.genre' => 'Sjanger',
			'libraries.filterCategories.year' => 'År',
			'libraries.filterCategories.contentRating' => 'Aldersgrense',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.sortLabels.title' => 'Tittel',
			'libraries.sortLabels.dateAdded' => 'Lagt til-dato',
			'libraries.sortLabels.releaseDate' => 'Utgivelsesdato',
			'libraries.sortLabels.rating' => 'Vurdering',
			'libraries.sortLabels.lastPlayed' => 'Sist spilt',
			'libraries.sortLabels.playCount' => 'Avspillinger',
			'libraries.sortLabels.random' => 'Tilfeldig',
			'libraries.sortLabels.dateShared' => 'Delingsdato',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Siste episodes sendedato',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Åpen kildekode-lisenser',
			'about.versionLabel' => ({required Object version}) => 'Versjon ${version}',
			'about.appDescription' => 'En vakker Plex- og Jellyfin-klient for Flutter',
			'about.viewLicensesDescription' => 'Vis lisenser for tredjepartsbiblioteker',
			'serverSelection.allServerConnectionsFailed' => 'Kunne ikke koble til noen servere. Sjekk nettverket ditt og prøv igjen.',
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
			'liveTv.title' => 'Direkte-TV',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Ingen kanaler tilgjengelig',
			'liveTv.noDvr' => 'Ingen DVR konfigurert på noen server',
			'liveTv.noPrograms' => 'Ingen programdata tilgjengelig',
			'liveTv.live' => 'DIREKTE',
			'liveTv.reloadGuide' => 'Last inn programguide på nytt',
			'liveTv.now' => 'Nå',
			'liveTv.today' => 'I dag',
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
			'liveTv.joinSession' => 'Bli med i pågående økt',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Se fra starten (${minutes} min siden)',
			'liveTv.watchLive' => 'Se direkte',
			'liveTv.goToLive' => 'Gå til direkte',
			'collections.title' => 'Samlinger',
			'collections.collection' => 'Samling',
			'collections.empty' => 'Samlingen er tom',
			'collections.unknownLibrarySection' => 'Kan ikke slette: Ukjent bibliotekseksjon',
			'collections.deleteCollection' => 'Slett samling',
			'collections.deleteConfirm' => ({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Denne handlingen kan ikke angres.',
			'collections.deleted' => 'Samling slettet',
			'collections.deleteFailed' => 'Kunne ikke slette samling',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Kunne ikke slette samling: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Kunne ikke laste samlingselementer: ${error}',
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
			'playlists.errorCreating' => 'Kunne ikke opprette spilleliste',
			'playlists.errorDeleting' => 'Kunne ikke slette spilleliste',
			'playlists.errorLoading' => 'Kunne ikke laste spillelister',
			'playlists.errorAdding' => 'Kunne ikke legge til i spilleliste',
			'playlists.errorReordering' => 'Kunne ikke omorganisere spillelisteelement',
			'playlists.errorRemoving' => 'Kunne ikke fjerne fra spilleliste',
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
			'watchTogether.joinInstructions' => 'Skriv inn øktkoden delt av verten for å bli med i se sammen-økten.',
			'watchTogether.failedToCreate' => 'Kunne ikke opprette økt',
			'watchTogether.failedToJoin' => 'Kunne ikke bli med i økt',
			'watchTogether.sessionCodeCopied' => 'Øktkode kopiert til utklippstavle',
			'watchTogether.relayUnreachable' => 'Reléserveren er utilgjengelig. Dette kan skyldes at internettleverandøren din blokkerer tilkoblingen. Du kan fortsatt prøve, men Se sammen fungerer kanskje ikke.',
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
			'watchTogether.waitingForParticipants' => 'Venter på at andre laster inn...',
			'watchTogether.recentRooms' => 'Nylige rom',
			'watchTogether.renameRoom' => 'Gi nytt navn til rom',
			'watchTogether.removeRoom' => 'Fjern',
			'watchTogether.guestSwitchUnavailable' => 'Kunne ikke bytte — server ikke tilgjengelig for synkronisering',
			'watchTogether.guestSwitchFailed' => 'Kunne ikke bytte — innhold ble ikke funnet på denne serveren',
			'downloads.title' => 'Nedlastinger',
			'downloads.manage' => 'Administrer',
			'downloads.tvShows' => 'TV-serier',
			'downloads.movies' => 'Filmer',
			'downloads.noDownloads' => 'Ingen nedlastinger ennå',
			'downloads.noDownloadsDescription' => 'Nedlastet innhold vil vises her for frakoblet visning',
			'downloads.downloadNow' => 'Last ned',
			'downloads.deleteDownload' => 'Slett nedlasting',
			'downloads.retryDownload' => 'Prøv nedlasting på nytt',
			'downloads.downloadQueued' => 'Nedlasting i kø',
			'downloads.serverErrorBitrate' => 'Serverfeil — filen overskrider muligens grensen for fjernstrømming-bitrate',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episoder i nedlastingskø',
			'downloads.downloadDeleted' => 'Nedlasting slettet',
			'downloads.deleteConfirm' => ({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Dette vil fjerne den nedlastede filen fra enheten din.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})',
			'downloads.deleting' => 'Sletter...',
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
			'downloads.howManyEpisodes' => 'Hvor mange episoder?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} elementer i nedlastingskø',
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
			'companionRemote.session.startingServer' => 'Starter fjernserver...',
			'companionRemote.session.failedToCreate' => 'Kunne ikke starte fjernserver:',
			'companionRemote.session.hostAddress' => 'Vertsadresse',
			'companionRemote.session.connected' => 'Tilkoblet',
			'companionRemote.session.serverRunning' => 'Fjernserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjernserver stoppet',
			'companionRemote.session.serverRunningDescription' => 'Mobilenheter på nettverket ditt kan oppdage og koble til denne appen',
			'companionRemote.session.serverStoppedDescription' => 'Start serveren for å la mobilenheter koble til',
			'companionRemote.session.usePhoneToControl' => 'Bruk mobilenheten din til å styre denne appen',
			'companionRemote.session.startServer' => 'Start server',
			'companionRemote.session.stopServer' => 'Stopp server',
			'companionRemote.session.minimize' => 'Minimer',
			'companionRemote.pairing.discoveryDescription' => 'Enheter på nettverket ditt som kjører Plezy med samme Plex-konto vil vises automatisk',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Kobler til...',
			'companionRemote.pairing.searchingForDevices' => 'Søker etter enheter...',
			'companionRemote.pairing.noDevicesFound' => 'Ingen enheter funnet på nettverket ditt',
			'companionRemote.pairing.noDevicesHint' => 'Sørg for at Plezy er åpen på datamaskinen din og at begge enhetene er på samme WiFi-nettverk',
			'companionRemote.pairing.availableDevices' => 'Tilgjengelige enheter',
			'companionRemote.pairing.manualConnection' => 'Manuell tilkobling',
			'companionRemote.pairing.cryptoInitFailed' => 'Kunne ikke initialisere sikker tilkobling. Sørg for at du er logget inn på en Plex-konto.',
			'companionRemote.pairing.validationHostRequired' => 'Vennligst oppgi vertsadresse',
			'companionRemote.pairing.validationHostFormat' => 'Format må være IP:port (f.eks. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tilkoblingen ble tidsavbrutt. Sørg for at begge enhetene er på samme nettverk.',
			'companionRemote.pairing.sessionNotFound' => 'Kunne ikke finne enheten. Sørg for at Plezy kjører på verten.',
			'companionRemote.pairing.authFailed' => 'Autentisering mislyktes. Sørg for at begge enhetene bruker samme Plex-konto.',
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
			'videoSettings.playbackSettings' => 'Avspillingsinnstillinger',
			'videoSettings.playbackSpeed' => 'Avspillingshastighet',
			'videoSettings.sleepTimer' => 'Søvntimer',
			'videoSettings.audioSync' => 'Lydsynkronisering',
			'videoSettings.subtitleSync' => 'Undertekstsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Lydutgang',
			'videoSettings.performanceOverlay' => 'Ytelsesoverlegg',
			'videoSettings.audioPassthrough' => 'Lydgjennomgang',
			'videoSettings.audioNormalization' => 'Normaliser lydstyrke',
			'externalPlayer.title' => 'Ekstern spiller',
			'externalPlayer.useExternalPlayer' => 'Bruk ekstern spiller',
			'externalPlayer.useExternalPlayerDescription' => 'Åpne videoer i en ekstern app i stedet for den innebygde spilleren',
			'externalPlayer.selectPlayer' => 'Velg spiller',
			'externalPlayer.customPlayers' => 'Egendefinerte spillere',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Legg til egendefinert spiller',
			'externalPlayer.playerName' => 'Spillernavn',
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
			'matchScreen.unmatchConfirm' => 'Fjerne gjeldende match for dette elementet? Plex behandler det som umatchet til du matcher det igjen.',
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
			'trakt.disconnectConfirmBody' => 'Plezy slutter å sende avspillingshendelser til Trakt. Du kan koble til igjen når som helst.',
			_ => null,
		} ?? switch (path) {
			'trakt.scrobble' => 'Sanntids-scrobbling',
			'trakt.scrobbleDescription' => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.',
			'trakt.watchedSync' => 'Synkroniser sett-status',
			'trakt.watchedSyncDescription' => 'Når du markerer noe som sett i Plezy, markeres det også på Trakt.',
			'trackers.title' => 'Trackere',
			'trackers.hubSubtitle' => 'Hold visningsfremdriften synkronisert med Trakt og andre tjenester.',
			'trackers.notConnected' => 'Ikke tilkoblet',
			'trackers.connectedAs' => ({required Object username}) => 'Tilkoblet som @${username}',
			'trackers.scrobble' => 'Registrer fremdrift automatisk',
			'trackers.scrobbleDescription' => 'Oppdater listen din når du er ferdig med en episode eller film.',
			'trackers.disconnectConfirm' => ({required Object service}) => 'Koble fra ${service}?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy slutter å oppdatere ${service}-listen din. Du kan koble til igjen når som helst.',
			'trackers.connectFailed' => ({required Object service}) => 'Kunne ikke koble til ${service}. Prøv igjen.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Aktiver Plezy på ${service}',
			'trackers.deviceCode.body' => ({required Object url}) => 'Besøk ${url} og skriv inn denne koden:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => 'Åpne ${service} for å aktivere',
			'trackers.deviceCode.waitingForAuthorization' => 'Venter på godkjenning…',
			'trackers.deviceCode.codeCopied' => 'Kode kopiert',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Logg inn på ${service}',
			'trackers.oauthProxy.body' => 'Skann denne QR-koden med telefonen din, eller åpne URL-en under på en enhet med nettleser.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => 'Åpne ${service} for å logge inn',
			'trackers.oauthProxy.urlCopied' => 'URL kopiert',
			'trackers.libraryFilter.title' => 'Biblioteksfilter',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Synkroniserer alle biblioteker',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Ingenting synkroniseres',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} blokkert',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} tillatt',
			'trackers.libraryFilter.mode' => 'Filtermodus',
			'trackers.libraryFilter.modeBlacklist' => 'Svarteliste',
			'trackers.libraryFilter.modeWhitelist' => 'Hviteliste',
			'trackers.libraryFilter.modeHintBlacklist' => 'Synkroniser alle biblioteker bortsett fra dem du markerer nedenfor.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Synkroniser kun bibliotekene du markerer nedenfor.',
			'trackers.libraryFilter.libraries' => 'Biblioteker',
			'trackers.libraryFilter.noLibraries' => 'Ingen biblioteker tilgjengelige',
			'addServer.addJellyfinTitle' => 'Legg til Jellyfin-server',
			'addServer.jellyfinUrlIntro' => 'Oppgi URL-en til Jellyfin-serveren din — f.eks. `https://jellyfin.example.com`. Du kan logge på etterpå.',
			'addServer.serverUrl' => 'Server-URL',
			'addServer.findServer' => 'Finn server',
			'addServer.username' => 'Brukernavn',
			'addServer.password' => 'Passord',
			'addServer.signIn' => 'Logg på',
			'addServer.change' => 'Endre',
			'addServer.required' => 'Påkrevd',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Kunne ikke nå serveren: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Pålogging mislyktes: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect mislyktes: ${error}',
			'addServer.addPlexTitle' => 'Logg på med Plex',
			'addServer.plexAuthIntro' => 'Velg hvordan du vil logge på Plex. Nettleserflyten åpner plex.tv der du bekrefter tilkoblingen; QR-alternativet er praktisk for TV / fjern-enheter.',
			'addServer.plexQRPrompt' => 'Skann denne QR-koden for å logge på.',
			'addServer.waitingForPlexConfirmation' => 'Venter på at plex.tv bekrefter påloggingen…',
			'addServer.pinExpired' => 'PIN-koden gikk ut før pålogging. Prøv igjen.',
			'addServer.duplicatePlexAccount' => 'Denne enheten er allerede pålogget en Plex-konto. Logg ut fra innstillingene for å bytte konto.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Kunne ikke registrere kontoen: ${error}',
			'addServer.enterJellyfinUrlError' => 'Oppgi URL-en til Jellyfin-serveren din',
			'addServer.addConnectionTitle' => 'Legg til tilkobling',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Legg til i ${name}',
			'addServer.addConnectionIntroGlobal' => 'Legg til enda en medieserver. Du kan blande Plex-kontoer og Jellyfin-servere — innhold fra alle tilkoblede backender vises sammen på startsiden.',
			'addServer.addConnectionIntroScoped' => 'Legg til en ny server, eller lån en fra en annen profil.',
			'addServer.signInWithPlexCard' => 'Logg på med Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriser denne enheten mot Plex-kontoen din. Servere delt med kontoen følger med automatisk.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriser en ny Plex-konto. Dens Home-brukere vises som profiler.',
			'addServer.connectToJellyfinCard' => 'Koble til Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Oppgi URL-en til Jellyfin-serveren din og logg på med brukernavn + passord (Quick Connect kommer snart).',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Logg på en Jellyfin-server. Knyttes til ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Lån fra en annen profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Gjenbruk en tilkobling som allerede er tilknyttet en annen profil. PIN-beskyttede kildeprofiler ber om PIN.',
			_ => null,
		};
	}
}
