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
class TranslationsNb with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsNb({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.nb,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <nb>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsPinEntryNb pinEntry = _TranslationsPinEntryNb._(_root);
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
}

// Path: app
class _TranslationsAppNb implements TranslationsAppEn {
	_TranslationsAppNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthNb implements TranslationsAuthEn {
	_TranslationsAuthNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logg inn med Plex';
	@override String get showQRCode => 'Vis QR-kode';
	@override String get authenticate => 'Autentiser';
	@override String get authenticationTimeout => 'Autentiseringen ble tidsavbrutt. Prøv igjen.';
	@override String get scanQRToSignIn => 'Skann denne QR-koden for å logge inn';
	@override String get waitingForAuth => 'Venter på autentisering...\nFullfør innloggingen i nettleseren din.';
	@override String get useBrowser => 'Bruk nettleser';
}

// Path: common
class _TranslationsCommonNb implements TranslationsCommonEn {
	_TranslationsCommonNb._(this._root);

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
	@override String get remove => 'Fjern';
	@override String get paste => 'Lim inn';
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
	@override String get loading => 'Laster...';
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
}

// Path: screens
class _TranslationsScreensNb implements TranslationsScreensEn {
	_TranslationsScreensNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisenser';
	@override String get switchProfile => 'Bytt profil';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logger';
}

// Path: update
class _TranslationsUpdateNb implements TranslationsUpdateEn {
	_TranslationsUpdateNb._(this._root);

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
class _TranslationsSettingsNb implements TranslationsSettingsEn {
	_TranslationsSettingsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Innstillinger';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videoavspilling';
	@override String get advanced => 'Avansert';
	@override String get episodePosterMode => 'Episodeplakatstil';
	@override String get seriesPoster => 'Serieplakat';
	@override String get seriesPosterDescription => 'Vis serieplakaten for alle episoder';
	@override String get seasonPoster => 'Sesongplakat';
	@override String get seasonPosterDescription => 'Vis den sesongspesifikke plakaten for episoder';
	@override String get episodeThumbnail => 'Episodeminiatyrbilde';
	@override String get episodeThumbnailDescription => 'Vis 16:9 episodeskjermbilder som miniatyrbilder';
	@override String get showHeroSectionDescription => 'Vis fremhevet innholdskarusell på hjemmeskjermen';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minutter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Angi varighet (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get systemThemeDescription => 'Følg systeminnstillinger';
	@override String get lightTheme => 'Lyst';
	@override String get darkTheme => 'Mørkt';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Helsvart for OLED-skjermer';
	@override String get libraryDensity => 'Bibliotekets tetthet';
	@override String get compact => 'Kompakt';
	@override String get compactDescription => 'Mindre kort, flere elementer synlige';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Standard størrelse';
	@override String get comfortable => 'Komfortabel';
	@override String get comfortableDescription => 'Større kort, færre elementer synlige';
	@override String get viewMode => 'Visningsmodus';
	@override String get gridView => 'Rutenett';
	@override String get gridViewDescription => 'Vis elementer i rutenettoppsett';
	@override String get listView => 'Liste';
	@override String get listViewDescription => 'Vis elementer i listeoppsett';
	@override String get showHeroSection => 'Vis fremhevet seksjon';
	@override String get useGlobalHubs => 'Bruk Plex Home-layout';
	@override String get useGlobalHubsDescription => 'Vis hjemmeside-huber som den offisielle Plex-klienten. Når av, vises per-bibliotek-anbefalinger i stedet.';
	@override String get showServerNameOnHubs => 'Vis servernavn på huber';
	@override String get showServerNameOnHubsDescription => 'Vis alltid servernavnet i hubtitler. Når av, vises kun for dupliserte hubnavn.';
	@override String get alwaysKeepSidebarOpen => 'Hold sidefeltet alltid åpent';
	@override String get alwaysKeepSidebarOpenDescription => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg';
	@override String get showUnwatchedCount => 'Vis antall usette';
	@override String get showUnwatchedCountDescription => 'Vis antall usette episoder på serier og sesonger';
	@override String get hideSpoilers => 'Skjul spoilere for usette episoder';
	@override String get hideSpoilersDescription => 'Slør miniatyrbilder og skjul beskrivelser for episoder du ikke har sett ennå';
	@override String get playerBackend => 'Spillermotor';
	@override String get exoPlayer => 'ExoPlayer (Anbefalt)';
	@override String get exoPlayerDescription => 'Android-innebygd spiller med bedre maskinvarestøtte';
	@override String get mpv => 'mpv';
	@override String get mpvDescription => 'Avansert spiller med flere funksjoner og ASS-undertekststøtte';
	@override String get hardwareDecoding => 'Maskinvaredekoding';
	@override String get hardwareDecodingDescription => 'Bruk maskinvareakselerasjon når tilgjengelig';
	@override String get bufferSize => 'Bufferstørrelse';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Anbefalt)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Enheten din har ${heap}MB minne. En ${size}MB buffer kan forårsake avspillingsproblemer.';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpass utseendet på undertekster';
	@override String get smallSkipDuration => 'Kort hoppvarighet';
	@override String get largeSkipDuration => 'Lang hoppvarighet';
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
	@override String get shortcutsReset => 'Snarveier tilbakestilt til standard';
	@override String get about => 'Om';
	@override String get aboutDescription => 'Appinformasjon og lisenser';
	@override String get updates => 'Oppdateringer';
	@override String get updateAvailable => 'Oppdatering tilgjengelig';
	@override String get checkForUpdates => 'Se etter oppdateringer';
	@override String get validationErrorEnterNumber => 'Vennligst skriv inn et gyldig tall';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Varigheten må være mellom ${min} og ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Snarvei allerede tilordnet til ${action}';
	@override String shortcutUpdated({required Object action}) => 'Snarvei oppdatert for ${action}';
	@override String get autoSkip => 'Automatisk hopp';
	@override String get autoSkipIntro => 'Hopp over intro automatisk';
	@override String get autoSkipIntroDescription => 'Hopp automatisk over intromarkører etter noen sekunder';
	@override String get autoSkipCredits => 'Hopp over rulletekst automatisk';
	@override String get autoSkipCreditsDescription => 'Hopp automatisk over rulletekst og spill neste episode';
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
	@override String get cellularDownloadBlocked => 'Nedlastinger er deaktivert på mobildata. Koble til WiFi eller endre innstillingen.';
	@override String get maxVolume => 'Maks volum';
	@override String get maxVolumeDescription => 'Tillat volumforsterkning over 100% for stille media';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Vis hva du ser på Discord';
	@override String get autoPip => 'Auto bilde-i-bilde';
	@override String get autoPipDescription => 'Gå automatisk til bilde-i-bilde når du forlater appen under avspilling';
	@override String get matchContentFrameRate => 'Tilpass innholdets bildefrekvens';
	@override String get matchContentFrameRateDescription => 'Juster skjermens oppdateringsfrekvens for å matche videoinnhold, reduserer hakking og sparer batteri';
	@override String get tunneledPlayback => 'Tunnelert avspilling';
	@override String get tunneledPlaybackDescription => 'Bruk maskinvareakselerert videotunnelering. Deaktiver hvis du ser svart skjerm med lyd på HDR-innhold';
	@override String get requireProfileSelectionOnOpen => 'Spør om profil ved appåpning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åpnes';
	@override String get confirmExitOnBack => 'Bekreft før avslutning';
	@override String get confirmExitOnBackDescription => 'Vis en bekreftelsesdialog når du trykker tilbake for å avslutte appen';
	@override String get showNavBarLabels => 'Vis navigasjonsfeltlabeler';
	@override String get showNavBarLabelsDescription => 'Vis tekstlabeler under navigasjonsfeltikoner';
}

// Path: search
class _TranslationsSearchNb implements TranslationsSearchEn {
	_TranslationsSearchNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Søk i filmer, serier, musikk...';
	@override String get tryDifferentTerm => 'Prøv et annet søkeord';
	@override String get searchYourMedia => 'Søk i mediene dine';
	@override String get enterTitleActorOrKeyword => 'Skriv inn tittel, skuespiller eller nøkkelord';
}

// Path: hotkeys
class _TranslationsHotkeysNb implements TranslationsHotkeysEn {
	_TranslationsHotkeysNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Angi snarvei for ${actionName}';
	@override String get clearShortcut => 'Fjern snarvei';
	@override late final _TranslationsHotkeysActionsNb actions = _TranslationsHotkeysActionsNb._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryNb implements TranslationsPinEntryEn {
	_TranslationsPinEntryNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Skriv inn PIN';
	@override String get showPin => 'Vis PIN';
	@override String get hidePin => 'Skjul PIN';
}

// Path: fileInfo
class _TranslationsFileInfoNb implements TranslationsFileInfoEn {
	_TranslationsFileInfoNb._(this._root);

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
	@override String get path => 'Sti';
	@override String get size => 'Størrelse';
	@override String get container => 'Beholder';
	@override String get duration => 'Varighet';
	@override String get optimizedForStreaming => 'Optimalisert for strømming';
	@override String get has64bitOffsets => '64-biters forskyvninger';
}

// Path: mediaMenu
class _TranslationsMediaMenuNb implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuNb._(this._root);

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
}

// Path: accessibility
class _TranslationsAccessibilityNb implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityNb._(this._root);

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
class _TranslationsTooltipsNb implements TranslationsTooltipsEn {
	_TranslationsTooltipsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get playTrailer => 'Spill trailer';
	@override String get markAsWatched => 'Merk som sett';
	@override String get markAsUnwatched => 'Merk som usett';
}

// Path: videoControls
class _TranslationsVideoControlsNb implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsNb._(this._root);

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
	@override String get sleepTimerCompleted => 'Søvntimer fullført – avspilling satt på pause';
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
	@override String get audioTrackButton => 'Lydspor';
	@override String get subtitlesButton => 'Undertekster';
	@override String get tracksButton => 'Lyd og undertekster';
	@override String get chaptersButton => 'Kapitler';
	@override String get versionsButton => 'Videoversjoner';
	@override String get pipButton => 'Bilde-i-bilde-modus';
	@override String get aspectRatioButton => 'Sideforhold';
	@override String get ambientLighting => 'Omgivelseslys';
	@override String get ambientLightingOn => 'Aktiver omgivelseslys';
	@override String get ambientLightingOff => 'Deaktiver omgivelseslys';
	@override String get fullscreenButton => 'Gå til fullskjerm';
	@override String get exitFullscreenButton => 'Avslutt fullskjerm';
	@override String get alwaysOnTopButton => 'Alltid øverst';
	@override String get rotationLockButton => 'Rotasjonslås';
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
}

// Path: userStatus
class _TranslationsUserStatusNb implements TranslationsUserStatusEn {
	_TranslationsUserStatusNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Administrator';
	@override String get restricted => 'Begrenset';
	@override String get protected => 'Beskyttet';
	@override String get current => 'GJELDENDE';
}

// Path: messages
class _TranslationsMessagesNb implements TranslationsMessagesEn {
	_TranslationsMessagesNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Merket som sett';
	@override String get markedAsUnwatched => 'Merket som usett';
	@override String get markedAsWatchedOffline => 'Merket som sett (synkroniseres når tilkoblet)';
	@override String get markedAsUnwatchedOffline => 'Merket som usett (synkroniseres når tilkoblet)';
	@override String get removedFromContinueWatching => 'Fjernet fra Fortsett å se';
	@override String errorLoading({required Object error}) => 'Feil: ${error}';
	@override String get fileInfoNotAvailable => 'Filinformasjon ikke tilgjengelig';
	@override String errorLoadingFileInfo({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}';
	@override String get errorLoadingSeries => 'Feil ved lasting av serie';
	@override String get errorLoadingSeason => 'Feil ved lasting av sesong';
	@override String get musicNotSupported => 'Musikkavspilling støttes ikke ennå';
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
	@override String get logsUploaded => 'Logger lastet opp';
	@override String get logsUploadFailed => 'Kunne ikke laste opp logger';
	@override String get logId => 'Logg-ID';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingNb implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Stilalternativer';
	@override String get fontSize => 'Skriftstørrelse';
	@override String get textColor => 'Tekstfarge';
	@override String get borderSize => 'Kantstørrelse';
	@override String get borderColor => 'Kantfarge';
	@override String get backgroundOpacity => 'Bakgrunnsopasitet';
	@override String get backgroundColor => 'Bakgrunnsfarge';
	@override String get position => 'Posisjon';
}

// Path: mpvConfig
class _TranslationsMpvConfigNb implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigNb._(this._root);

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
class _TranslationsDialogNb implements TranslationsDialogEn {
	_TranslationsDialogNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekreft handling';
}

// Path: discover
class _TranslationsDiscoverNb implements TranslationsDiscoverEn {
	_TranslationsDiscoverNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oppdag';
	@override String get switchProfile => 'Bytt profil';
	@override String get noContentAvailable => 'Ingen innhold tilgjengelig';
	@override String get addMediaToLibraries => 'Legg til medier i bibliotekene dine';
	@override String get continueWatching => 'Fortsett å se';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Oversikt';
	@override String get cast => 'Skuespillere';
	@override String get extras => 'Trailere og ekstra';
	@override String get seasons => 'Sesonger';
	@override String get studio => 'Studio';
	@override String get rating => 'Vurdering';
	@override String episodeCount({required Object count}) => '${count} episoder';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} sett';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min igjen';
}

// Path: errors
class _TranslationsErrorsNb implements TranslationsErrorsEn {
	_TranslationsErrorsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Søk mislyktes: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tidsavbrudd ved lasting av ${context}';
	@override String get connectionFailed => 'Kunne ikke koble til Plex-server';
	@override String failedToLoad({required Object context, required Object error}) => 'Kunne ikke laste ${context}: ${error}';
	@override String get noClientAvailable => 'Ingen klient tilgjengelig';
	@override String authenticationFailed({required Object error}) => 'Autentisering mislyktes: ${error}';
	@override String get couldNotLaunchUrl => 'Kunne ikke åpne autentiserings-URL';
	@override String get pleaseEnterToken => 'Vennligst skriv inn et token';
	@override String get invalidToken => 'Ugyldig token';
	@override String failedToVerifyToken({required Object error}) => 'Kunne ikke verifisere token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Kunne ikke bytte til ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesNb implements TranslationsLibrariesEn {
	_TranslationsLibrariesNb._(this._root);

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
}

// Path: about
class _TranslationsAboutNb implements TranslationsAboutEn {
	_TranslationsAboutNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Åpen kildekode-lisenser';
	@override String versionLabel({required Object version}) => 'Versjon ${version}';
	@override String get appDescription => 'En vakker Plex-klient for Flutter';
	@override String get viewLicensesDescription => 'Vis lisenser for tredjepartsbiblioteker';
}

// Path: serverSelection
class _TranslationsServerSelectionNb implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Kunne ikke koble til noen servere. Sjekk nettverket ditt og prøv igjen.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kunne ikke laste servere: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailNb implements TranslationsHubDetailEn {
	_TranslationsHubDetailNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittel';
	@override String get releaseYear => 'Utgivelsesår';
	@override String get dateAdded => 'Dato lagt til';
	@override String get rating => 'Vurdering';
	@override String get noItemsFound => 'Ingen elementer funnet';
}

// Path: logs
class _TranslationsLogsNb implements TranslationsLogsEn {
	_TranslationsLogsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Tøm logger';
	@override String get copyLogs => 'Kopier logger';
	@override String get uploadLogs => 'Last opp logger';
	@override String get error => 'Feil:';
	@override String get stackTrace => 'Stabelsporing:';
}

// Path: licenses
class _TranslationsLicensesNb implements TranslationsLicensesEn {
	_TranslationsLicensesNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterte pakker';
	@override String get license => 'Lisens';
	@override String licenseNumber({required Object number}) => 'Lisens ${number}';
	@override String licensesCount({required Object count}) => '${count} lisenser';
}

// Path: navigation
class _TranslationsNavigationNb implements TranslationsNavigationEn {
	_TranslationsNavigationNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteker';
	@override String get downloads => 'Nedlastinger';
	@override String get liveTv => 'Direkte-TV';
}

// Path: liveTv
class _TranslationsLiveTvNb implements TranslationsLiveTvEn {
	_TranslationsLiveTvNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Direkte-TV';
	@override String get channels => 'Kanaler';
	@override String get guide => 'Programguide';
	@override String get noChannels => 'Ingen kanaler tilgjengelig';
	@override String get noDvr => 'Ingen DVR konfigurert på noen server';
	@override String get tuneFailed => 'Kunne ikke stille inn kanal';
	@override String get loading => 'Laster kanaler...';
	@override String get nowPlaying => 'Spilles nå';
	@override String get noPrograms => 'Ingen programdata tilgjengelig';
	@override String channelNumber({required Object number}) => 'Kanal ${number}';
	@override String get live => 'DIREKTE';
	@override String get hd => 'HD';
	@override String get premiere => 'NY';
	@override String get reloadGuide => 'Last inn programguide på nytt';
	@override String get allChannels => 'Alle kanaler';
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
}

// Path: collections
class _TranslationsCollectionsNb implements TranslationsCollectionsEn {
	_TranslationsCollectionsNb._(this._root);

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
}

// Path: playlists
class _TranslationsPlaylistsNb implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsNb._(this._root);

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
class _TranslationsWatchTogetherNb implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherNb._(this._root);

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
	@override String get enterCodeHint => 'Skriv inn 8-tegns kode';
	@override String get pasteFromClipboard => 'Lim inn fra utklippstavle';
	@override String get pleaseEnterCode => 'Vennligst skriv inn en øktkode';
	@override String get codeMustBe8Chars => 'Øktkoden må være 8 tegn';
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
}

// Path: downloads
class _TranslationsDownloadsNb implements TranslationsDownloadsEn {
	_TranslationsDownloadsNb._(this._root);

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
	@override String episodesQueued({required Object count}) => '${count} episoder i nedlastingskø';
	@override String get downloadDeleted => 'Nedlasting slettet';
	@override String deleteConfirm({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Dette vil fjerne den nedlastede filen fra enheten din.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})';
	@override String get noDownloadsTree => 'Ingen nedlastinger';
	@override String get pauseAll => 'Pause alle';
	@override String get resumeAll => 'Gjenoppta alle';
	@override String get deleteAll => 'Slett alle';
}

// Path: shaders
class _TranslationsShadersNb implements TranslationsShadersEn {
	_TranslationsShadersNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shadere';
	@override String get noShaderDescription => 'Ingen videoforbedring';
	@override String get nvscalerDescription => 'NVIDIA bildeskalering for skarpere video';
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
class _TranslationsCompanionRemoteNb implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Følgesvenn-fjernkontroll';
	@override String get connectToDevice => 'Koble til enhet';
	@override String get hostRemoteSession => 'Vær vert for fjernøkt';
	@override String get controlThisDevice => 'Kontroller denne enheten med telefonen din';
	@override String get remoteControl => 'Fjernkontroll';
	@override String get controlDesktop => 'Kontroller en stasjonær enhet';
	@override String connectedTo({required Object name}) => 'Tilkoblet ${name}';
	@override late final _TranslationsCompanionRemoteSessionNb session = _TranslationsCompanionRemoteSessionNb._(_root);
	@override late final _TranslationsCompanionRemotePairingNb pairing = _TranslationsCompanionRemotePairingNb._(_root);
	@override late final _TranslationsCompanionRemoteRemoteNb remote = _TranslationsCompanionRemoteRemoteNb._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsNb implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsNb._(this._root);

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
	@override String get audioNormalization => 'Lydnormalisering';
}

// Path: externalPlayer
class _TranslationsExternalPlayerNb implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ekstern spiller';
	@override String get useExternalPlayer => 'Bruk ekstern spiller';
	@override String get useExternalPlayerDescription => 'Åpne videoer i en ekstern app i stedet for den innebygde spilleren';
	@override String get selectPlayer => 'Velg spiller';
	@override String get systemDefault => 'Systemstandard';
	@override String get addCustomPlayer => 'Legg til egendefinert spiller';
	@override String get playerName => 'Spillernavn';
	@override String get playerCommand => 'Kommando';
	@override String get playerPackage => 'Pakkenavn';
	@override String get playerUrlScheme => 'URL-skjema';
	@override String get customPlayer => 'Egendefinert spiller';
	@override String get off => 'Av';
	@override String get launchFailed => 'Kunne ikke åpne ekstern spiller';
	@override String appNotInstalled({required Object name}) => '${name} er ikke installert';
	@override String get playInExternalPlayer => 'Spill av i ekstern spiller';
}

// Path: metadataEdit
class _TranslationsMetadataEditNb implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditNb._(this._root);

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
	@override String get selectPoster => 'Velg plakat';
	@override String get selectBackground => 'Velg bakgrunn';
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
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsNb implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsNb._(this._root);

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
	@override String get speedIncrease => 'Øk hastighet';
	@override String get speedDecrease => 'Reduser hastighet';
	@override String get speedReset => 'Tilbakestill hastighet';
	@override String get subSeekNext => 'Spol til neste undertekst';
	@override String get subSeekPrev => 'Spol til forrige undertekst';
	@override String get shaderToggle => 'Veksle shadere';
	@override String get skipMarker => 'Hopp over intro/rulletekst';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsNb implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsNb._(this._root);

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
class _TranslationsLibrariesTabsNb implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Anbefalt';
	@override String get browse => 'Bla gjennom';
	@override String get collections => 'Samlinger';
	@override String get playlists => 'Spillelister';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsNb implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get all => 'Alle';
	@override String get movies => 'Filmer';
	@override String get shows => 'TV-serier';
	@override String get seasons => 'Sesonger';
	@override String get episodes => 'Episoder';
	@override String get folders => 'Mapper';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionNb implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Oppretter fjernøkt...';
	@override String get failedToCreate => 'Kunne ikke opprette fjernøkt:';
	@override String get noSession => 'Ingen økt tilgjengelig';
	@override String get scanQrCode => 'Skann QR-kode';
	@override String get orEnterManually => 'Eller skriv inn manuelt';
	@override String get hostAddress => 'Vertsadresse';
	@override String get sessionId => 'Økt-ID';
	@override String get pin => 'PIN';
	@override String get connected => 'Tilkoblet';
	@override String get waitingForConnection => 'Venter på tilkobling...';
	@override String get usePhoneToControl => 'Bruk mobilenheten din til å kontrollere denne appen';
	@override String copiedToClipboard({required Object label}) => '${label} kopiert til utklippstavle';
	@override String get copyToClipboard => 'Kopier til utklippstavle';
	@override String get newSession => 'Ny økt';
	@override String get minimize => 'Minimer';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingNb implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Skann';
	@override String get manual => 'Manuell';
	@override String get pairWithDesktop => 'Koble til stasjonær';
	@override String get enterSessionDetails => 'Skriv inn øktdetaljene som vises på den stasjonære enheten din';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Skriv inn 8-tegns økt-ID';
	@override String get pinHint => 'Skriv inn 6-sifret PIN';
	@override String get connecting => 'Kobler til...';
	@override String get tips => 'Tips';
	@override String get tipDesktop => 'Åpne Plezy på datamaskinen din og aktiver Følgesvenn-fjernkontroll fra innstillinger eller meny';
	@override String get tipScan => 'Bruk Skann-fanen for å raskt koble til ved å skanne QR-koden på datamaskinen din';
	@override String get tipWifi => 'Sørg for at begge enhetene er på samme WiFi-nettverk';
	@override String get cameraPermissionRequired => 'Kameratillatelse kreves for å skanne QR-koder.\nVennligst gi kameratilgang i enhetsinnstillingene.';
	@override String cameraError({required Object error}) => 'Kunne ikke starte kamera: ${error}';
	@override String get scanInstruction => 'Pek kameraet mot QR-koden som vises på datamaskinen din';
	@override String get invalidQrCode => 'Ugyldig QR-kodeformat';
	@override String get validationHostRequired => 'Vennligst skriv inn vertsadresse';
	@override String get validationHostFormat => 'Formatet må være IP:port (f.eks. 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Vennligst skriv inn en økt-ID';
	@override String get validationSessionIdLength => 'Økt-ID må være 8 tegn';
	@override String get validationPinRequired => 'Vennligst skriv inn en PIN';
	@override String get validationPinLength => 'PIN må være 6 sifre';
	@override String get connectionTimedOut => 'Tilkoblingen ble tidsavbrutt. Sjekk økt-ID og PIN.';
	@override String get sessionNotFound => 'Kunne ikke finne økten. Sjekk legitimasjonen din.';
	@override String failedToConnect({required Object error}) => 'Kunne ikke koble til: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteNb implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteNb._(this._root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Vil du koble fra fjernøkten?';
	@override String get reconnecting => 'Kobler til på nytt...';
	@override String attemptOf({required Object current}) => 'Forsøk ${current} av 5';
	@override String get retryNow => 'Prøv nå';
	@override String get connectionError => 'Tilkoblingsfeil';
	@override String get notConnected => 'Ikke tilkoblet';
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
			'auth.waitingForAuth' => 'Venter på autentisering...\nFullfør innloggingen i nettleseren din.',
			'auth.useBrowser' => 'Bruk nettleser',
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
			'common.remove' => 'Fjern',
			'common.paste' => 'Lim inn',
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
			'common.loading' => 'Laster...',
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
			'settings.language' => 'Språk',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Utseende',
			'settings.videoPlayback' => 'Videoavspilling',
			'settings.advanced' => 'Avansert',
			'settings.episodePosterMode' => 'Episodeplakatstil',
			'settings.seriesPoster' => 'Serieplakat',
			'settings.seriesPosterDescription' => 'Vis serieplakaten for alle episoder',
			'settings.seasonPoster' => 'Sesongplakat',
			'settings.seasonPosterDescription' => 'Vis den sesongspesifikke plakaten for episoder',
			'settings.episodeThumbnail' => 'Episodeminiatyrbilde',
			'settings.episodeThumbnailDescription' => 'Vis 16:9 episodeskjermbilder som miniatyrbilder',
			'settings.showHeroSectionDescription' => 'Vis fremhevet innholdskarusell på hjemmeskjermen',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minutter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Angi varighet (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.systemThemeDescription' => 'Følg systeminnstillinger',
			'settings.lightTheme' => 'Lyst',
			'settings.darkTheme' => 'Mørkt',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Helsvart for OLED-skjermer',
			'settings.libraryDensity' => 'Bibliotekets tetthet',
			'settings.compact' => 'Kompakt',
			'settings.compactDescription' => 'Mindre kort, flere elementer synlige',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Standard størrelse',
			'settings.comfortable' => 'Komfortabel',
			'settings.comfortableDescription' => 'Større kort, færre elementer synlige',
			'settings.viewMode' => 'Visningsmodus',
			'settings.gridView' => 'Rutenett',
			'settings.gridViewDescription' => 'Vis elementer i rutenettoppsett',
			'settings.listView' => 'Liste',
			'settings.listViewDescription' => 'Vis elementer i listeoppsett',
			'settings.showHeroSection' => 'Vis fremhevet seksjon',
			'settings.useGlobalHubs' => 'Bruk Plex Home-layout',
			'settings.useGlobalHubsDescription' => 'Vis hjemmeside-huber som den offisielle Plex-klienten. Når av, vises per-bibliotek-anbefalinger i stedet.',
			'settings.showServerNameOnHubs' => 'Vis servernavn på huber',
			'settings.showServerNameOnHubsDescription' => 'Vis alltid servernavnet i hubtitler. Når av, vises kun for dupliserte hubnavn.',
			'settings.alwaysKeepSidebarOpen' => 'Hold sidefeltet alltid åpent',
			'settings.alwaysKeepSidebarOpenDescription' => 'Sidefeltet forblir utvidet og innholdsområdet tilpasser seg',
			'settings.showUnwatchedCount' => 'Vis antall usette',
			'settings.showUnwatchedCountDescription' => 'Vis antall usette episoder på serier og sesonger',
			'settings.hideSpoilers' => 'Skjul spoilere for usette episoder',
			'settings.hideSpoilersDescription' => 'Slør miniatyrbilder og skjul beskrivelser for episoder du ikke har sett ennå',
			'settings.playerBackend' => 'Spillermotor',
			'settings.exoPlayer' => 'ExoPlayer (Anbefalt)',
			'settings.exoPlayerDescription' => 'Android-innebygd spiller med bedre maskinvarestøtte',
			'settings.mpv' => 'mpv',
			'settings.mpvDescription' => 'Avansert spiller med flere funksjoner og ASS-undertekststøtte',
			'settings.hardwareDecoding' => 'Maskinvaredekoding',
			'settings.hardwareDecodingDescription' => 'Bruk maskinvareakselerasjon når tilgjengelig',
			'settings.bufferSize' => 'Bufferstørrelse',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Anbefalt)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Enheten din har ${heap}MB minne. En ${size}MB buffer kan forårsake avspillingsproblemer.',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpass utseendet på undertekster',
			'settings.smallSkipDuration' => 'Kort hoppvarighet',
			'settings.largeSkipDuration' => 'Lang hoppvarighet',
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
			'settings.shortcutsReset' => 'Snarveier tilbakestilt til standard',
			'settings.about' => 'Om',
			'settings.aboutDescription' => 'Appinformasjon og lisenser',
			'settings.updates' => 'Oppdateringer',
			'settings.updateAvailable' => 'Oppdatering tilgjengelig',
			'settings.checkForUpdates' => 'Se etter oppdateringer',
			'settings.validationErrorEnterNumber' => 'Vennligst skriv inn et gyldig tall',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Varigheten må være mellom ${min} og ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Snarvei allerede tilordnet til ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Snarvei oppdatert for ${action}',
			'settings.autoSkip' => 'Automatisk hopp',
			'settings.autoSkipIntro' => 'Hopp over intro automatisk',
			'settings.autoSkipIntroDescription' => 'Hopp automatisk over intromarkører etter noen sekunder',
			'settings.autoSkipCredits' => 'Hopp over rulletekst automatisk',
			'settings.autoSkipCreditsDescription' => 'Hopp automatisk over rulletekst og spill neste episode',
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
			'settings.cellularDownloadBlocked' => 'Nedlastinger er deaktivert på mobildata. Koble til WiFi eller endre innstillingen.',
			'settings.maxVolume' => 'Maks volum',
			'settings.maxVolumeDescription' => 'Tillat volumforsterkning over 100% for stille media',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Vis hva du ser på Discord',
			'settings.autoPip' => 'Auto bilde-i-bilde',
			'settings.autoPipDescription' => 'Gå automatisk til bilde-i-bilde når du forlater appen under avspilling',
			'settings.matchContentFrameRate' => 'Tilpass innholdets bildefrekvens',
			'settings.matchContentFrameRateDescription' => 'Juster skjermens oppdateringsfrekvens for å matche videoinnhold, reduserer hakking og sparer batteri',
			'settings.tunneledPlayback' => 'Tunnelert avspilling',
			'settings.tunneledPlaybackDescription' => 'Bruk maskinvareakselerert videotunnelering. Deaktiver hvis du ser svart skjerm med lyd på HDR-innhold',
			'settings.requireProfileSelectionOnOpen' => 'Spør om profil ved appåpning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åpnes',
			'settings.confirmExitOnBack' => 'Bekreft før avslutning',
			'settings.confirmExitOnBackDescription' => 'Vis en bekreftelsesdialog når du trykker tilbake for å avslutte appen',
			'settings.showNavBarLabels' => 'Vis navigasjonsfeltlabeler',
			'settings.showNavBarLabelsDescription' => 'Vis tekstlabeler under navigasjonsfeltikoner',
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
			'hotkeys.actions.speedIncrease' => 'Øk hastighet',
			'hotkeys.actions.speedDecrease' => 'Reduser hastighet',
			'hotkeys.actions.speedReset' => 'Tilbakestill hastighet',
			'hotkeys.actions.subSeekNext' => 'Spol til neste undertekst',
			'hotkeys.actions.subSeekPrev' => 'Spol til forrige undertekst',
			'hotkeys.actions.shaderToggle' => 'Veksle shadere',
			'hotkeys.actions.skipMarker' => 'Hopp over intro/rulletekst',
			'pinEntry.enterPin' => 'Skriv inn PIN',
			'pinEntry.showPin' => 'Vis PIN',
			'pinEntry.hidePin' => 'Skjul PIN',
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
			'videoControls.sleepTimerCompleted' => 'Søvntimer fullført – avspilling satt på pause',
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
			'videoControls.audioTrackButton' => 'Lydspor',
			'videoControls.subtitlesButton' => 'Undertekster',
			'videoControls.tracksButton' => 'Lyd og undertekster',
			'videoControls.chaptersButton' => 'Kapitler',
			'videoControls.versionsButton' => 'Videoversjoner',
			'videoControls.pipButton' => 'Bilde-i-bilde-modus',
			'videoControls.aspectRatioButton' => 'Sideforhold',
			'videoControls.ambientLighting' => 'Omgivelseslys',
			'videoControls.ambientLightingOn' => 'Aktiver omgivelseslys',
			'videoControls.ambientLightingOff' => 'Deaktiver omgivelseslys',
			'videoControls.fullscreenButton' => 'Gå til fullskjerm',
			'videoControls.exitFullscreenButton' => 'Avslutt fullskjerm',
			'videoControls.alwaysOnTopButton' => 'Alltid øverst',
			'videoControls.rotationLockButton' => 'Rotasjonslås',
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
			'userStatus.admin' => 'Administrator',
			'userStatus.restricted' => 'Begrenset',
			'userStatus.protected' => 'Beskyttet',
			'userStatus.current' => 'GJELDENDE',
			'messages.markedAsWatched' => 'Merket som sett',
			'messages.markedAsUnwatched' => 'Merket som usett',
			'messages.markedAsWatchedOffline' => 'Merket som sett (synkroniseres når tilkoblet)',
			'messages.markedAsUnwatchedOffline' => 'Merket som usett (synkroniseres når tilkoblet)',
			'messages.removedFromContinueWatching' => 'Fjernet fra Fortsett å se',
			'messages.errorLoading' => ({required Object error}) => 'Feil: ${error}',
			'messages.fileInfoNotAvailable' => 'Filinformasjon ikke tilgjengelig',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Feil ved lasting av filinformasjon: ${error}',
			'messages.errorLoadingSeries' => 'Feil ved lasting av serie',
			'messages.errorLoadingSeason' => 'Feil ved lasting av sesong',
			'messages.musicNotSupported' => 'Musikkavspilling støttes ikke ennå',
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
			'messages.logsUploaded' => 'Logger lastet opp',
			'messages.logsUploadFailed' => 'Kunne ikke laste opp logger',
			'messages.logId' => 'Logg-ID',
			'subtitlingStyling.stylingOptions' => 'Stilalternativer',
			'subtitlingStyling.fontSize' => 'Skriftstørrelse',
			'subtitlingStyling.textColor' => 'Tekstfarge',
			'subtitlingStyling.borderSize' => 'Kantstørrelse',
			'subtitlingStyling.borderColor' => 'Kantfarge',
			'subtitlingStyling.backgroundOpacity' => 'Bakgrunnsopasitet',
			'subtitlingStyling.backgroundColor' => 'Bakgrunnsfarge',
			'subtitlingStyling.position' => 'Posisjon',
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
			'discover.title' => 'Oppdag',
			'discover.switchProfile' => 'Bytt profil',
			'discover.noContentAvailable' => 'Ingen innhold tilgjengelig',
			'discover.addMediaToLibraries' => 'Legg til medier i bibliotekene dine',
			'discover.continueWatching' => 'Fortsett å se',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Oversikt',
			'discover.cast' => 'Skuespillere',
			'discover.extras' => 'Trailere og ekstra',
			'discover.seasons' => 'Sesonger',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Vurdering',
			'discover.episodeCount' => ({required Object count}) => '${count} episoder',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} sett',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min igjen',
			'errors.searchFailed' => ({required Object error}) => 'Søk mislyktes: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tidsavbrudd ved lasting av ${context}',
			'errors.connectionFailed' => 'Kunne ikke koble til Plex-server',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Kunne ikke laste ${context}: ${error}',
			'errors.noClientAvailable' => 'Ingen klient tilgjengelig',
			'errors.authenticationFailed' => ({required Object error}) => 'Autentisering mislyktes: ${error}',
			'errors.couldNotLaunchUrl' => 'Kunne ikke åpne autentiserings-URL',
			'errors.pleaseEnterToken' => 'Vennligst skriv inn et token',
			'errors.invalidToken' => 'Ugyldig token',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Kunne ikke verifisere token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Kunne ikke bytte til ${displayName}',
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
			'libraries.groupings.all' => 'Alle',
			'libraries.groupings.movies' => 'Filmer',
			'libraries.groupings.shows' => 'TV-serier',
			'libraries.groupings.seasons' => 'Sesonger',
			'libraries.groupings.episodes' => 'Episoder',
			'libraries.groupings.folders' => 'Mapper',
			'about.title' => 'Om',
			'about.openSourceLicenses' => 'Åpen kildekode-lisenser',
			'about.versionLabel' => ({required Object version}) => 'Versjon ${version}',
			'about.appDescription' => 'En vakker Plex-klient for Flutter',
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
			'logs.error' => 'Feil:',
			'logs.stackTrace' => 'Stabelsporing:',
			'licenses.relatedPackages' => 'Relaterte pakker',
			'licenses.license' => 'Lisens',
			'licenses.licenseNumber' => ({required Object number}) => 'Lisens ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} lisenser',
			'navigation.libraries' => 'Biblioteker',
			'navigation.downloads' => 'Nedlastinger',
			'navigation.liveTv' => 'Direkte-TV',
			'liveTv.title' => 'Direkte-TV',
			'liveTv.channels' => 'Kanaler',
			'liveTv.guide' => 'Programguide',
			'liveTv.noChannels' => 'Ingen kanaler tilgjengelig',
			'liveTv.noDvr' => 'Ingen DVR konfigurert på noen server',
			'liveTv.tuneFailed' => 'Kunne ikke stille inn kanal',
			'liveTv.loading' => 'Laster kanaler...',
			'liveTv.nowPlaying' => 'Spilles nå',
			'liveTv.noPrograms' => 'Ingen programdata tilgjengelig',
			'liveTv.channelNumber' => ({required Object number}) => 'Kanal ${number}',
			'liveTv.live' => 'DIREKTE',
			_ => null,
		} ?? switch (path) {
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NY',
			'liveTv.reloadGuide' => 'Last inn programguide på nytt',
			'liveTv.allChannels' => 'Alle kanaler',
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
			'watchTogether.enterCodeHint' => 'Skriv inn 8-tegns kode',
			'watchTogether.pasteFromClipboard' => 'Lim inn fra utklippstavle',
			'watchTogether.pleaseEnterCode' => 'Vennligst skriv inn en øktkode',
			'watchTogether.codeMustBe8Chars' => 'Øktkoden må være 8 tegn',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} episoder i nedlastingskø',
			'downloads.downloadDeleted' => 'Nedlasting slettet',
			'downloads.deleteConfirm' => ({required Object title}) => 'Er du sikker på at du vil slette "${title}"? Dette vil fjerne den nedlastede filen fra enheten din.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Sletter ${title}... (${current} av ${total})',
			'downloads.noDownloadsTree' => 'Ingen nedlastinger',
			'downloads.pauseAll' => 'Pause alle',
			'downloads.resumeAll' => 'Gjenoppta alle',
			'downloads.deleteAll' => 'Slett alle',
			'shaders.title' => 'Shadere',
			'shaders.noShaderDescription' => 'Ingen videoforbedring',
			'shaders.nvscalerDescription' => 'NVIDIA bildeskalering for skarpere video',
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
			'companionRemote.connectToDevice' => 'Koble til enhet',
			'companionRemote.hostRemoteSession' => 'Vær vert for fjernøkt',
			'companionRemote.controlThisDevice' => 'Kontroller denne enheten med telefonen din',
			'companionRemote.remoteControl' => 'Fjernkontroll',
			'companionRemote.controlDesktop' => 'Kontroller en stasjonær enhet',
			'companionRemote.connectedTo' => ({required Object name}) => 'Tilkoblet ${name}',
			'companionRemote.session.creatingSession' => 'Oppretter fjernøkt...',
			'companionRemote.session.failedToCreate' => 'Kunne ikke opprette fjernøkt:',
			'companionRemote.session.noSession' => 'Ingen økt tilgjengelig',
			'companionRemote.session.scanQrCode' => 'Skann QR-kode',
			'companionRemote.session.orEnterManually' => 'Eller skriv inn manuelt',
			'companionRemote.session.hostAddress' => 'Vertsadresse',
			'companionRemote.session.sessionId' => 'Økt-ID',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Tilkoblet',
			'companionRemote.session.waitingForConnection' => 'Venter på tilkobling...',
			'companionRemote.session.usePhoneToControl' => 'Bruk mobilenheten din til å kontrollere denne appen',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} kopiert til utklippstavle',
			'companionRemote.session.copyToClipboard' => 'Kopier til utklippstavle',
			'companionRemote.session.newSession' => 'Ny økt',
			'companionRemote.session.minimize' => 'Minimer',
			'companionRemote.pairing.scan' => 'Skann',
			'companionRemote.pairing.manual' => 'Manuell',
			'companionRemote.pairing.pairWithDesktop' => 'Koble til stasjonær',
			'companionRemote.pairing.enterSessionDetails' => 'Skriv inn øktdetaljene som vises på den stasjonære enheten din',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Skriv inn 8-tegns økt-ID',
			'companionRemote.pairing.pinHint' => 'Skriv inn 6-sifret PIN',
			'companionRemote.pairing.connecting' => 'Kobler til...',
			'companionRemote.pairing.tips' => 'Tips',
			'companionRemote.pairing.tipDesktop' => 'Åpne Plezy på datamaskinen din og aktiver Følgesvenn-fjernkontroll fra innstillinger eller meny',
			'companionRemote.pairing.tipScan' => 'Bruk Skann-fanen for å raskt koble til ved å skanne QR-koden på datamaskinen din',
			'companionRemote.pairing.tipWifi' => 'Sørg for at begge enhetene er på samme WiFi-nettverk',
			'companionRemote.pairing.cameraPermissionRequired' => 'Kameratillatelse kreves for å skanne QR-koder.\nVennligst gi kameratilgang i enhetsinnstillingene.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Kunne ikke starte kamera: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Pek kameraet mot QR-koden som vises på datamaskinen din',
			'companionRemote.pairing.invalidQrCode' => 'Ugyldig QR-kodeformat',
			'companionRemote.pairing.validationHostRequired' => 'Vennligst skriv inn vertsadresse',
			'companionRemote.pairing.validationHostFormat' => 'Formatet må være IP:port (f.eks. 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Vennligst skriv inn en økt-ID',
			'companionRemote.pairing.validationSessionIdLength' => 'Økt-ID må være 8 tegn',
			'companionRemote.pairing.validationPinRequired' => 'Vennligst skriv inn en PIN',
			'companionRemote.pairing.validationPinLength' => 'PIN må være 6 sifre',
			'companionRemote.pairing.connectionTimedOut' => 'Tilkoblingen ble tidsavbrutt. Sjekk økt-ID og PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Kunne ikke finne økten. Sjekk legitimasjonen din.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Kunne ikke koble til: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Vil du koble fra fjernøkten?',
			'companionRemote.remote.reconnecting' => 'Kobler til på nytt...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Forsøk ${current} av 5',
			'companionRemote.remote.retryNow' => 'Prøv nå',
			'companionRemote.remote.connectionError' => 'Tilkoblingsfeil',
			'companionRemote.remote.notConnected' => 'Ikke tilkoblet',
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
			'videoSettings.audioNormalization' => 'Lydnormalisering',
			'externalPlayer.title' => 'Ekstern spiller',
			'externalPlayer.useExternalPlayer' => 'Bruk ekstern spiller',
			'externalPlayer.useExternalPlayerDescription' => 'Åpne videoer i en ekstern app i stedet for den innebygde spilleren',
			'externalPlayer.selectPlayer' => 'Velg spiller',
			'externalPlayer.systemDefault' => 'Systemstandard',
			'externalPlayer.addCustomPlayer' => 'Legg til egendefinert spiller',
			'externalPlayer.playerName' => 'Spillernavn',
			'externalPlayer.playerCommand' => 'Kommando',
			'externalPlayer.playerPackage' => 'Pakkenavn',
			'externalPlayer.playerUrlScheme' => 'URL-skjema',
			'externalPlayer.customPlayer' => 'Egendefinert spiller',
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
			'metadataEdit.selectPoster' => 'Velg plakat',
			'metadataEdit.selectBackground' => 'Velg bakgrunn',
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
			_ => null,
		};
	}
}
