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
	@override late final _Translations$app$nb app = _Translations$app$nb._(_root);
	@override late final _Translations$auth$nb auth = _Translations$auth$nb._(_root);
	@override late final _Translations$common$nb common = _Translations$common$nb._(_root);
	@override late final _Translations$screens$nb screens = _Translations$screens$nb._(_root);
	@override late final _Translations$update$nb update = _Translations$update$nb._(_root);
	@override late final _Translations$settings$nb settings = _Translations$settings$nb._(_root);
	@override late final _Translations$search$nb search = _Translations$search$nb._(_root);
	@override late final _Translations$hotkeys$nb hotkeys = _Translations$hotkeys$nb._(_root);
	@override late final _Translations$fileInfo$nb fileInfo = _Translations$fileInfo$nb._(_root);
	@override late final _Translations$mediaMenu$nb mediaMenu = _Translations$mediaMenu$nb._(_root);
	@override late final _Translations$rateSheet$nb rateSheet = _Translations$rateSheet$nb._(_root);
	@override late final _Translations$accessibility$nb accessibility = _Translations$accessibility$nb._(_root);
	@override late final _Translations$tooltips$nb tooltips = _Translations$tooltips$nb._(_root);
	@override late final _Translations$audioTracks$nb audioTracks = _Translations$audioTracks$nb._(_root);
	@override late final _Translations$videoControls$nb videoControls = _Translations$videoControls$nb._(_root);
	@override late final _Translations$messages$nb messages = _Translations$messages$nb._(_root);
	@override late final _Translations$subtitlingStyling$nb subtitlingStyling = _Translations$subtitlingStyling$nb._(_root);
	@override late final _Translations$mpvConfig$nb mpvConfig = _Translations$mpvConfig$nb._(_root);
	@override late final _Translations$dialog$nb dialog = _Translations$dialog$nb._(_root);
	@override late final _Translations$profiles$nb profiles = _Translations$profiles$nb._(_root);
	@override late final _Translations$connections$nb connections = _Translations$connections$nb._(_root);
	@override late final _Translations$discover$nb discover = _Translations$discover$nb._(_root);
	@override late final _Translations$errors$nb errors = _Translations$errors$nb._(_root);
	@override late final _Translations$libraries$nb libraries = _Translations$libraries$nb._(_root);
	@override late final _Translations$about$nb about = _Translations$about$nb._(_root);
	@override late final _Translations$serverSelection$nb serverSelection = _Translations$serverSelection$nb._(_root);
	@override late final _Translations$hubDetail$nb hubDetail = _Translations$hubDetail$nb._(_root);
	@override late final _Translations$logs$nb logs = _Translations$logs$nb._(_root);
	@override late final _Translations$startup$nb startup = _Translations$startup$nb._(_root);
	@override late final _Translations$licenses$nb licenses = _Translations$licenses$nb._(_root);
	@override late final _Translations$navigation$nb navigation = _Translations$navigation$nb._(_root);
	@override late final _Translations$explore$nb explore = _Translations$explore$nb._(_root);
	@override late final _Translations$liveTv$nb liveTv = _Translations$liveTv$nb._(_root);
	@override late final _Translations$collections$nb collections = _Translations$collections$nb._(_root);
	@override late final _Translations$playlists$nb playlists = _Translations$playlists$nb._(_root);
	@override late final _Translations$music$nb music = _Translations$music$nb._(_root);
	@override late final _Translations$watchTogether$nb watchTogether = _Translations$watchTogether$nb._(_root);
	@override late final _Translations$downloads$nb downloads = _Translations$downloads$nb._(_root);
	@override late final _Translations$shaders$nb shaders = _Translations$shaders$nb._(_root);
	@override late final _Translations$companionRemote$nb companionRemote = _Translations$companionRemote$nb._(_root);
	@override late final _Translations$videoSettings$nb videoSettings = _Translations$videoSettings$nb._(_root);
	@override late final _Translations$performanceOverlay$nb performanceOverlay = _Translations$performanceOverlay$nb._(_root);
	@override late final _Translations$externalPlayer$nb externalPlayer = _Translations$externalPlayer$nb._(_root);
	@override late final _Translations$metadataEdit$nb metadataEdit = _Translations$metadataEdit$nb._(_root);
	@override late final _Translations$matchScreen$nb matchScreen = _Translations$matchScreen$nb._(_root);
	@override late final _Translations$serverTasks$nb serverTasks = _Translations$serverTasks$nb._(_root);
	@override late final _Translations$trakt$nb trakt = _Translations$trakt$nb._(_root);
	@override late final _Translations$seerr$nb seerr = _Translations$seerr$nb._(_root);
	@override late final _Translations$services$nb services = _Translations$services$nb._(_root);
	@override late final _Translations$addServer$nb addServer = _Translations$addServer$nb._(_root);
}

// Path: app
class _Translations$app$nb extends Translations$app$en {
	_Translations$app$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$nb extends Translations$auth$en {
	_Translations$auth$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Logg inn med Plex';
	@override String get showQRCode => 'Vis QR-kode';
	@override String get authenticate => 'Autentiser';
	@override String get authenticationTimeout => 'Autentiseringen tok for lang tid. Prøv igjen.';
	@override String get scanQRToSignIn => 'Skann denne QR-koden for å logge inn';
	@override String get waitingForAuth => 'Venter på autentisering...\nLogg inn fra nettleseren.';
	@override String get useBrowser => 'Bruk nettleser';
	@override String get or => 'eller';
	@override String connectToMediaBrowser({required Object product}) => 'Koble til ${product}';
	@override String get useQuickConnect => 'Bruk Quick Connect';
	@override String get quickConnectInstructions => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.';
	@override String get quickConnectWaiting => 'Venter på godkjenning…';
	@override String get quickConnectCancel => 'Avbryt';
	@override String get quickConnectExpired => 'Quick Connect er utløpt. Prøv igjen.';
	@override String get localDataRecoveryRequired => 'Plezy kunne ikke gjenopprette lokale innloggingsdata og ventende avspillingsdata på en sikker måte. Logg inn på nytt.';
}

// Path: common
class _Translations$common$nb extends Translations$common$en {
	_Translations$common$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get pressBackAgainToExit => 'Trykk på Tilbake en gang til for å avslutte';
	@override late final _Translations$common$ratingSource$nb ratingSource = _Translations$common$ratingSource$nb._(_root);
}

// Path: screens
class _Translations$screens$nb extends Translations$screens$en {
	_Translations$screens$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Lisenser';
	@override String get switchProfile => 'Bytt profil';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logger';
}

// Path: update
class _Translations$update$nb extends Translations$update$en {
	_Translations$update$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$settings$nb extends Translations$settings$en {
	_Translations$settings$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Innstillinger';
	@override String get supportDeveloper => 'Støtt Plezy';
	@override String get supportDeveloperDescription => 'Doner via Liberapay for å finansiere utviklingen';
	@override String get language => 'Språk';
	@override String get theme => 'Tema';
	@override String get appearance => 'Utseende';
	@override String get videoPlayback => 'Videoavspilling';
	@override String get videoPlaybackDescription => 'Tilpass avspillingen';
	@override String get advanced => 'Avansert';
	@override String get episodePosterMode => 'Type episodeplakat';
	@override String get seriesPoster => 'Serieplakat';
	@override String get seasonPoster => 'Sesongplakat';
	@override String get episodeThumbnail => 'Miniatyrbilde';
	@override String get showHeroSectionDescription => 'Vis en karusell med fremhevet innhold på startskjermen';
	@override String get secondsLabel => 'Sekunder';
	@override String get minutesLabel => 'Minutter';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Angi varighet (${min}-${max})';
	@override String get systemTheme => 'System';
	@override String get lightTheme => 'Lyst';
	@override String get darkTheme => 'Mørkt';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Innholdstetthet i biblioteket';
	@override String get displayScale => 'Skalering';
	@override String get compact => 'Kompakt';
	@override String get comfortable => 'Komfortabel';
	@override String get tvCornerSpotlightBackdrop => 'Fremhevet bakgrunn i hjørnet';
	@override String get tvCornerSpotlightBackdropDescription => 'Vis fremhevet grafikk øverst til høyre i stedet for å fylle skjermen';
	@override String get viewMode => 'Visningsmodus';
	@override String get gridView => 'Rutenett';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Vis fremhevet seksjon';
	@override String get continueWatchingAction => 'Handling for «Fortsett å se»';
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
	@override String get tvFullCardLayout => 'Heldekkende TV-kort';
	@override String get tvFullCardLayoutDescription => 'Bruk TV-kort med bare bilder og skuespillernavn lagt over';
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
	@override String get playerBackend => 'Avspillingsmotor';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Maskinvaredekoding';
	@override String get hardwareDecodingDescription => 'Bruk maskinvareakselerasjon når tilgjengelig';
	@override String get bufferSize => 'Bufferstørrelse';
	@override String bufferSizeMB({required Object size}) => '${size} MB';
	@override String get bufferSizeAuto => 'Automatisk (anbefalt)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap} MB minne tilgjengelig. En buffer på ${size} MB kan påvirke avspillingen.';
	@override String get playbackBuffer => 'Avspillingsbuffer';
	@override String get playbackBufferAuto => 'Auto (anbefalt)';
	@override String get playbackBufferLarge => 'Stor';
	@override String get playbackBufferExtraLarge => 'Ekstra stor';
	@override String get playbackBufferDescription => 'Bufrer mer mot ustabile tilkoblinger. Begrenses også av bufferstørrelsen.';
	@override String get defaultQualityTitle => 'Standardkvalitet';
	@override String get musicQualityTitle => 'Musikkvalitet';
	@override String get subtitleStyling => 'Undertekststil';
	@override String get subtitleStylingDescription => 'Tilpass utseendet på undertekster';
	@override String get smallSkipDuration => 'Kort hoppvarighet';
	@override String get largeSkipDuration => 'Lang hoppvarighet';
	@override String get rewindOnResume => 'Spol tilbake ved gjenopptakelse';
	@override String secondsUnit({required Object seconds}) => '${seconds} sekunder';
	@override String get defaultSleepTimer => 'Standard innsovningstimer';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutter';
	@override String get rememberTrackSelections => 'Husk sporvalg per serie/film';
	@override String get rememberTrackSelectionsDescription => 'Husk lyd- og undertekstvalg per tittel';
	@override String get followServerTrackSelections => 'Bruk serverens sporvalg per episode';
	@override String get followServerTrackSelectionsDescription => 'Ved episodebytte brukes lyden og undertekstene som er valgt på serveren, i stedet for å videreføre gjeldende valg';
	@override String get showChapterMarkersOnTimeline => 'Vis kapittelmarkører på tidslinjen';
	@override String get showChapterMarkersOnTimelineDescription => 'Del tidslinjen ved kapittelgrenser';
	@override String get clickVideoTogglesPlayback => 'Klikk på video for å veksle avspilling';
	@override String get clickVideoTogglesPlaybackDescription => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.';
	@override String get videoPlayerControls => 'Videospillerkontroller';
	@override String get keyboardShortcuts => 'Tastatursnarveier';
	@override String get keyboardShortcutsDescription => 'Tilpass tastatursnarveier';
	@override String get videoPlayerNavigation => 'Videospillernavigering';
	@override String get videoPlayerNavigationDescription => 'Bruk piltaster for å navigere videospillerkontroller';
	@override String get watchTogetherRelay => 'Reléserver for Se sammen';
	@override String get watchTogetherRelayDescription => 'Angi en egendefinert reléserver. Alle må bruke samme server.';
	@override String get watchTogetherRelayHint => 'https://min-relay.eksempel.no';
	@override String get watchTogetherRelayInvalid => 'Angi en gyldig HTTP- eller HTTPS-adresse til reléserveren.';
	@override String get crashReporting => 'Krasjrapportering';
	@override String get crashReportingDescription => 'Send krasjrapporter for å hjelpe med å forbedre appen';
	@override String get debugLogging => 'Feilsøkingslogging';
	@override String get debugLoggingDescription => 'Aktiver detaljert logging for feilsøking';
	@override String get viewLogs => 'Vis logger';
	@override String get viewLogsDescription => 'Vis applikasjonslogger';
	@override String get clearImageCache => 'Tøm bildebufferen';
	@override String get clearImageCacheDescription => 'Tømmer bufret kunstverk og miniatyrbilder. Bilder kan lastes langsommere til de er lastet ned på nytt.';
	@override String get clearImageCacheSuccess => 'Bildebufferen ble tømt';
	@override String get resetSettings => 'Tilbakestill innstillinger';
	@override String get resetSettingsDescription => 'Gjenopprett standardinnstillinger. Dette kan ikke angres.';
	@override String get resetSettingsSuccess => 'Innstillinger tilbakestilt';
	@override String get backup => 'Sikkerhetskopi';
	@override String get exportSettings => 'Eksporter innstillinger';
	@override String get exportSettingsDescription => 'Lagre innstillingene i en fil';
	@override String get exportSettingsSuccess => 'Innstillinger eksportert';
	@override String get importSettings => 'Importer innstillinger';
	@override String get importSettingsDescription => 'Gjenopprett innstillinger fra en fil';
	@override String get importSettingsConfirm => 'Dette vil erstatte nåværende innstillinger. Fortsette?';
	@override String get importSettingsSuccess => 'Innstillinger importert';
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
	@override String get saveFailed => 'Kunne ikke lagre endringene. Prøv igjen.';
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
	@override String get downloadLocationPickerUnavailable => 'Mappevalg er ikke tilgjengelig på denne enheten';
	@override String get downloadOnWifiOnly => 'Last bare ned via Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Forhindre nedlasting via mobildata';
	@override String get autoRemoveWatchedDownloads => 'Fjern avspilte nedlastinger automatisk';
	@override String get autoRemoveWatchedDownloadsDescription => 'Slett avspilte nedlastinger automatisk';
	@override String get cellularDownloadBlocked => 'Nedlastinger er blokkert på mobilnett. Bruk Wi-Fi eller endre innstillingen.';
	@override String get maxVolume => 'Maksvolum';
	@override String get maxVolumeDescription => 'Tillat volumforsterkning over 100 % for medier med lavt lydnivå';
	@override String maxVolumePercent({required Object percent}) => '${percent} %';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Vis hva du ser på Discord';
	@override String get services => 'Tjenester';
	@override String get servicesDescription => 'Koble til Trakt, MyAnimeList, Seerr og mer';
	@override String get manageLibrariesDescription => 'Omorganiser og skjul biblioteker';
	@override String get companionRemoteServer => 'Fjernkontrollserver';
	@override String get companionRemoteServerDescription => 'La mobilenheter på nettverket styre denne appen';
	@override String get autoPip => 'Automatisk bilde-i-bilde';
	@override String get autoPipDescription => 'Åpne bilde-i-bilde når du forlater appen under avspilling';
	@override String get matchContentFrameRate => 'Tilpass innholdets bildefrekvens';
	@override String get matchContentFrameRateDescription => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold';
	@override String get matchRefreshRate => 'Tilpass oppdateringsfrekvens';
	@override String get matchRefreshRateDescription => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm';
	@override String get matchDynamicRange => 'Tilpass dynamikkområde';
	@override String get matchDynamicRangeDescription => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR';
	@override String get displaySwitchDelay => 'Forsinkelse ved skjermbytte';
	@override String get tunneledPlayback => 'Tunnelert avspilling';
	@override String get tunneledPlaybackDescription => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video.';
	@override String get audioPassthrough => 'Direkte lydutgang';
	@override String get audioPassthroughDescription => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.';
	@override String get audioPassthroughDescriptionAppleTv => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Slå av hvis du ikke har lyd.';
	@override String get audioDownmix => 'Nedmiks til stereo';
	@override String get audioDownmixDescription => 'Miks surroundlyd ned til to kanaler for stereohøyttalere eller hodetelefoner';
	@override String get downmixCenterBoost => 'Forsterkning av senterkanal';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Forsterkning (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normaliser lydstyrke ved nedmiks';
	@override String get audioDownmixNormalizeDescription => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).';
	@override String get dvConversionMode => 'Dolby Vision-konvertering';
	@override String get dvConversionModeDescription => 'Velg hvordan ExoPlayer håndterer filer med Dolby Vision-profil 7.';
	@override String get dvConversionAuto => 'Automatisk';
	@override String get dvConversionNative => 'Nativ / deaktivert';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Oppdag enhetens egenskaper og bruk vanlig reserveoppførsel';
	@override String get dvConversionNativeDescription => 'Tving opprinnelig DV7-avspilling og ikke prøv DV-konvertering på nytt';
	@override String get dvConversionDv81Description => 'Tving direkte RPU-konvertering til Dolby Vision-profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Fjern Dolby Vision RPU/EL-lag og lever som vanlig HEVC';
	@override String get requireProfileSelectionOnOpen => 'Spør om profil ved appåpning';
	@override String get requireProfileSelectionOnOpenDescription => 'Vis profilvalg hver gang appen åpnes';
	@override String get forceTvMode => 'Tving TV-modus';
	@override String get forceTvModeDescription => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.';
	@override String get startInFullscreen => 'Start i fullskjerm';
	@override String get startInFullscreenDescription => 'Åpne Plezy i fullskjermmodus ved oppstart';
	@override String get exitFullscreenOnPlayerClose => 'Avslutt fullskjerm ved lukking av avspiller';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Avslutt fullskjerm automatisk når videospilleren lukkes';
	@override String get autoHidePerformanceOverlay => 'Skjul ytelsesoverlegg automatisk';
	@override String get autoHidePerformanceOverlayDescription => 'Ton ytelsesoverlegget ut sammen med avspillingskontrollene';
	@override String get showNavBarLabels => 'Vis etiketter i navigasjonsfeltet';
	@override String get showNavBarLabelsDescription => 'Vis tekstetiketter under ikonene i navigasjonsfeltet';
	@override String get startupSection => 'Startseksjon';
	@override String get liveTvDefaultFavorites => 'Vis favorittkanaler som standard';
	@override String get liveTvDefaultFavoritesDescription => 'Vis bare favorittkanaler når du åpner Direkte-TV';
	@override String get display => 'Skjerm';
	@override String get homeScreen => 'Hjemmeskjerm';
	@override String get navigation => 'Navigering';
	@override String get window => 'Vindu';
	@override String get content => 'Innhold';
	@override String get player => 'Spiller';
	@override String get subtitlesAndConfig => 'Undertekster og konfigurasjon';
	@override String get seekAndTiming => 'Spoling og tidsinnstillinger';
	@override String get behavior => 'Oppførsel';
}

// Path: search
class _Translations$search$nb extends Translations$search$en {
	_Translations$search$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Søk i filmer, serier, musikk...';
	@override String get tryDifferentTerm => 'Prøv et annet søkeord';
	@override String get searchYourMedia => 'Søk i mediene dine';
	@override String get enterTitleActorOrKeyword => 'Skriv inn tittel, skuespiller eller nøkkelord';
}

// Path: hotkeys
class _Translations$hotkeys$nb extends Translations$hotkeys$en {
	_Translations$hotkeys$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Angi snarvei for ${actionName}';
	@override String get clearShortcut => 'Fjern snarvei';
	@override String get noShortcutSet => 'Ingen snarvei satt';
	@override String get currentShortcut => 'Gjeldende snarvei:';
	@override String get pressToRecord => 'Velg for å registrere en snarvei';
	@override String get recordingShortcut => 'Trykk på snarveien nå';
	@override late final _Translations$hotkeys$actions$nb actions = _Translations$hotkeys$actions$nb._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$nb extends Translations$fileInfo$en {
	_Translations$fileInfo$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filinformasjon';
	@override String get overview => 'Oversikt';
	@override String get video => 'Video';
	@override String get audio => 'Lyd';
	@override String get subtitles => 'Undertekster';
	@override String get images => 'Innebygde bilder';
	@override String get dataStreams => 'Datastrømmer';
	@override String get lyrics => 'Sangtekster';
	@override String get file => 'Fil';
	@override String get attachments => 'Vedlegg';
	@override String get delivery => 'Levering';
	@override String versionCounter({required Object index, required Object count}) => 'Versjon ${index} av ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Fil ${index} av ${count}';
	@override String get noStreams => 'Serveren rapporterte ingen strømmer for denne filen.';
	@override String get copyPath => 'Kopier bane';
	@override String get pathCopied => 'Filbane kopiert';
	@override String get codec => 'Kodek';
	@override String get codecTag => 'Codec-tagg';
	@override String get resolution => 'Oppløsning';
	@override String get codedResolution => 'Kodet oppløsning';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Bildefrekvens';
	@override String get rotation => 'Rotasjon';
	@override String get comment => 'Kommentar';
	@override String get audioDescription => 'Lydbeskrivelse';
	@override String get headerCompression => 'Overskriftkomprimering';
	@override String get sidecarFile => 'Sidecar-fil';
	@override String get transportTimestamp => 'Transporttidsstempel';
	@override String get displayOffset => 'Visningsforskyvning';
	@override String get previewFailureCode => 'Forhåndsvisningsfeilkode';
	@override String get previewRetries => 'Nye forhåndsvisningsforsøk';
	@override String get aspectRatio => 'Sideforhold';
	@override String get pixelAspectRatio => 'Piksel-aspektforhold';
	@override String get profile => 'Profil';
	@override String get level => 'Nivå';
	@override String get bitDepth => 'Bitdybde';
	@override String get pixelFormat => 'Pikselformat';
	@override String get colorSpace => 'Fargerom';
	@override String get colorRange => 'Fargeområde';
	@override String get colorPrimaries => 'Fargeprimærer';
	@override String get colorTransfer => 'Fargeoverføring';
	@override String get chromaSubsampling => 'Krominansnedsampling';
	@override String get chromaLocation => 'Kroma-plassering';
	@override String get scanType => 'Skanningstype';
	@override String get interlaced => 'Interlaced';
	@override String get anamorphic => 'Anamorfisk';
	@override String get referenceFrames => 'Referanserammer';
	@override String get dynamicRange => 'Dynamisk omfang';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Dolby Vision-nivå';
	@override String get dolbyVisionVersion => 'Dolby Vision-versjon';
	@override String get dolbyVisionLayers => 'Dolby Vision-lag';
	@override String get baseLayerCompatibility => 'Kompatibilitet for basislag';
	@override String get avcBitstream => 'AVC-bitstrøm';
	@override String get nalLengthSize => 'NAL-lengdestørrelse';
	@override String get scalingMatrix => 'Egendefinert skaleringsmatrise';
	@override String get streamIdentifier => 'Strømidentifikator';
	@override String get streamIndex => 'Strømindeks';
	@override String get streamId => 'Strøm-ID';
	@override String get language => 'Språk';
	@override String get languageCode => 'Språkkode';
	@override String get streamTitle => 'Spor-tittel';
	@override String get channels => 'Kanaler';
	@override String get sampleRate => 'Samplingsfrekvens';
	@override String get spatialAudio => 'Romlig lyd';
	@override String get textBased => 'Tekstbasert';
	@override String get subtitleFormat => 'Sidecar-format';
	@override String get provider => 'Tilbyder';
	@override String get matchScore => 'Match-poengsum';
	@override String get externalDelivery => 'Kan leveres separat';
	@override String get sidecarPath => 'Sidecar-bane';
	@override String get sourceStream => 'Kopiert fra';
	@override String get temporary => 'Midlertidig';
	@override String get timeBase => 'Tidsbase';
	@override String get overallBitrate => 'Total bitrate';
	@override String get path => 'Sti';
	@override String get fileName => 'Filnavn';
	@override String get size => 'Størrelse';
	@override String get totalSize => 'Total størrelse';
	@override String get container => 'Format';
	@override String get duration => 'Varighet';
	@override String get previewThumbnails => 'Forhåndsvisningsminiatyrer';
	@override String get previewIndex => 'Forhåndsvisningsindeks';
	@override String get packetLength => 'Pakkelengde';
	@override String get filePresent => 'Fil til stede';
	@override String get fileReadable => 'Lesbar for serveren';
	@override String get streamPath => 'Strømbane';
	@override String get optimizedForStreaming => 'Optimalisert for strømming';
	@override String get has64bitOffsets => '64-biters forskyvninger';
	@override String get protocol => 'Protokoll';
	@override String get mediaType => 'Mediatype';
	@override String get sourceKind => 'Kildetype';
	@override String get optimizedVersion => 'Optimalisert versjon';
	@override String get optimizationTarget => 'Optimaliseringsmål';
	@override String get deletedAt => 'Slettet';
	@override String get remoteSource => 'Ekstern kilde';
	@override String get infiniteStream => 'Uendelig strøm';
	@override String get directPlay => 'Direct Play';
	@override String get directStream => 'Direct Stream';
	@override String get transcoding => 'Transkoding';
	@override String get etag => 'ETag';
	@override String get versionId => 'Versjons-ID';
	@override String get fileId => 'Fil-ID';
	@override String get defaultAudioTrack => 'Standard lydspor';
	@override String get defaultSubtitleTrack => 'Standard tekstspor';
	@override String get subtitlesOff => 'Av';
	@override String get flagDefault => 'Standard';
	@override String get flagForced => 'Tvunget';
	@override String get flagSelected => 'Valgt';
	@override String get flagExternal => 'Ekstern';
	@override String get flagHearingImpaired => 'Hørselshemmet';
	@override String get flagDub => 'Dub';
	@override String get flagOriginal => 'Original';
}

// Path: mediaMenu
class _Translations$mediaMenu$nb extends Translations$mediaMenu$en {
	_Translations$mediaMenu$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Merk som sett';
	@override String get markAsUnwatched => 'Merk som usett';
	@override String get removeFromContinueWatching => 'Fjern fra Fortsett å se';
	@override String get viewDetails => 'Vis detaljer';
	@override String get goToSeries => 'Gå til serie';
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get shuffleNotAvailableOffline => 'Tilfeldig avspilling er ikke tilgjengelig uten nett';
	@override String get fileInfo => 'Filinformasjon';
	@override String get deleteEpisodeFromServer => 'Slett episode fra serveren';
	@override String get deleteSeasonFromServer => 'Slett sesong fra serveren';
	@override String get deleteShowFromServer => 'Slett serie fra serveren';
	@override String get deleteMovieFromServer => 'Slett film fra serveren';
	@override String get deleteEpisodeTitle => 'Slette denne episoden?';
	@override String get deleteSeasonTitle => 'Slette denne sesongen?';
	@override String get deleteShowTitle => 'Slette denne serien?';
	@override String get deleteMovieTitle => 'Slette denne filmen?';
	@override String get deleteEpisodeConfirm => 'Slett episode';
	@override String get deleteSeasonConfirm => 'Slett sesong';
	@override String get deleteShowConfirm => 'Slett serie';
	@override String get deleteMovieConfirm => 'Slett film';
	@override String get deleteAnyway => 'Slett likevel';
	@override String confirmDeleteTarget({required Object title}) => 'Slette ${title} permanent fra serveren din?';
	@override String get deleteMultipleWarning => 'Dette inkluderer alle episoder og deres filer.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Dette sletter ${n} episode i den, og filen.',
		other: 'Dette sletter alle ${n} episodene i den, og filene deres.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Dette elementet er lagret som ${n} fil, som vil bli slettet.',
		other: 'Dette elementet er lagret på tvers av ${n} filer, og alle vil bli slettet.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${n} annen episode er lagret i samme fil og vil også bli slettet:',
		other: '${n} andre episoder er lagret i samme fil og vil også bli slettet:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'Plezy kunne ikke sjekke hvilke filer dette vil fjerne, så det kan slette mer enn elementet som er nevnt ovenfor. Avbryt og prøv igjen, eller slett likevel.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Serveren din ga ikke fildetaljer for dette elementet, så Plezy kan ikke sjekke hvilke filer dette vil fjerne. Det kan slette mer enn elementet som er nevnt ovenfor.';
	@override String get mediaDeletedSuccessfully => 'Medieelement slettet';
	@override String get mediaFailedToDelete => 'Kunne ikke slette medieelement';
	@override String get rate => 'Vurder';
	@override String get playFromBeginning => 'Spill fra begynnelsen';
	@override String get playVersion => 'Spill av versjon...';
}

// Path: rateSheet
class _Translations$rateSheet$nb extends Translations$rateSheet$en {
	_Translations$rateSheet$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$accessibility$nb extends Translations$accessibility$en {
	_Translations$accessibility$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get alphabetNavigation => 'Alfabetisk navigasjon';
	@override String get alphabetScrollHint => 'Sveip opp eller ned for å gå én bokstav om gangen';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Rad ${row} av ${rowCount}, kolonne ${column} av ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Rad ${row} av ${rowCount}';
}

// Path: tooltips
class _Translations$tooltips$nb extends Translations$tooltips$en {
	_Translations$tooltips$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Tilfeldig avspilling';
	@override String get playTrailer => 'Spill trailer';
	@override String get markAsWatched => 'Merk som sett';
	@override String get markAsUnwatched => 'Merk som usett';
}

// Path: audioTracks
class _Translations$audioTracks$nb extends Translations$audioTracks$en {
	_Translations$audioTracks$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Lydspor ${n}';
}

// Path: videoControls
class _Translations$videoControls$nb extends Translations$videoControls$en {
	_Translations$videoControls$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String playbackWillPauseIn({required Object duration}) => 'Avspillingen settes på pause om ${duration}';
	@override String get sleepTimerEndOfVideo => 'Slutten av gjeldende video';
	@override String get sleepTimerStopAtHeader => 'Stopp ved';
	@override String get sleepTimerDurationHeader => 'Timer';
	@override String get playbackWillPauseAtEnd => 'Avspilling vil pause på slutten av denne videoen';
	@override String get stillWatching => 'Ser du fortsatt?';
	@override String pausingIn({required Object seconds}) => 'Pauser om ${seconds}s';
	@override String get continueWatching => 'Fortsett';
	@override String get autoPlayNext => 'Spill av neste automatisk';
	@override String get playNext => 'Spill neste';
	@override String get playButton => 'Spill av';
	@override String get pauseButton => 'Pause';
	@override String get playbackPaused => 'Pauset';
	@override String get playbackResumed => 'Spiller';
	@override String get loadingVideo => 'Laster video';
	@override String get showPlaybackControls => 'Vis avspillingskontroller';
	@override String get hidePlaybackControls => 'Skjul avspillingskontroller';
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
	@override String get subtitleUnavailableFallback => 'De valgte undertekstene kunne ikke lastes inn — avspillingen fortsetter uten undertekster';
	@override String get pipButton => 'Bilde-i-bilde-modus';
	@override String get aspectRatioButton => 'Sideforhold';
	@override String get ambientLighting => 'Omgivelseslys';
	@override String get fullscreenButton => 'Gå til fullskjerm';
	@override String get exitFullscreenButton => 'Avslutt fullskjerm';
	@override String get alwaysOnTopButton => 'Alltid øverst';
	@override String get rotationLockButton => 'Rotasjonslås';
	@override String get lockScreen => 'Lås skjerm';
	@override String get screenLockButton => 'Skjermlås';
	@override String get longPressToUnlock => 'Trykk og hold for å låse opp';
	@override String get timelineSlider => 'Videotidslinje';
	@override String get volumeSlider => 'Volumnivå';
	@override String endsAt({required Object time}) => 'Slutter kl. ${time}';
	@override String get pipActive => 'Spiller i bilde-i-bilde';
	@override String get pipFailed => 'Bilde-i-bilde kunne ikke starte';
	@override String get screenshotSaved => 'Skjermbilde lagret';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent} %';
	@override late final _Translations$videoControls$pipErrors$nb pipErrors = _Translations$videoControls$pipErrors$nb._(_root);
	@override String get chapters => 'Kapitler';
	@override String get noChaptersAvailable => 'Ingen kapitler tilgjengelig';
	@override String get queue => 'Kø';
	@override String get noQueueItems => 'Ingen elementer i kø';
	@override String get noAudioDevicesAvailable => 'Ingen lydenheter tilgjengelig';
	@override String get searchSubtitles => 'Søk etter undertekster';
	@override String get language => 'Språk';
	@override String get noSubtitlesFound => 'Ingen undertekster funnet';
	@override String get subtitleDownloaded => 'Undertekst lastet ned';
	@override String get subtitleDownloadedNotApplied => 'Underteksten ble lastet ned, men kunne ikke velges';
	@override String get subtitleDownloadFailed => 'Kunne ikke laste ned undertekst';
	@override String get searchLanguages => 'Søk etter språk...';
}

// Path: messages
class _Translations$messages$nb extends Translations$messages$en {
	_Translations$messages$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Merket som sett';
	@override String get markedAsUnwatched => 'Merket som usett';
	@override String get markedAsWatchedOffline => 'Merket som sett (synkroniseres når tilkoblet)';
	@override String get markedAsUnwatchedOffline => 'Merket som usett (synkroniseres når tilkoblet)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Automatisk fjernet: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Fjernet automatisk ${n} avspilt nedlasting',
		other: 'Fjernet automatisk ${n} avspilte nedlastinger',
	);
	@override String get removedFromContinueWatching => 'Fjernet fra Fortsett å se';
	@override String errorLoading({required Object error}) => 'Feil: ${error}';
	@override String get searchPartialResults => 'Noen medieservere kunne ikke søkes i. Viser tilgjengelige resultater.';
	@override String get streamInterrupted => 'Avspillingen ble avbrutt. Trykk på Spill av eller spol for å prøve på nytt.';
	@override String get liveStreamInterrupted => 'Direktesendingen ble avbrutt. Trykk på Spill av for å prøve på nytt.';
	@override String get fileInfoNotAvailable => 'Filinformasjon ikke tilgjengelig';
	@override String get playbackAuthenticationRequired => 'Logg inn på medieserveren på nytt for å spille av dette elementet.';
	@override String get playbackServerUnavailable => 'Medieserveren er utilgjengelig. Prøv igjen senere.';
	@override String get playbackDataInvalid => 'Serveren returnerte ugyldig avspillingsinformasjon.';
	@override String get playbackCancelled => 'Avspillingen ble avbrutt.';
	@override String get playbackFailed => 'Kunne ikke starte avspillingen.';
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
	@override String sleepTimerSet({required Object label}) => 'Innsovningstimer satt til ${label}';
	@override String get noItemsAvailable => 'Ingen elementer tilgjengelig';
	@override String get failedToCreatePlayQueueNoItems => 'Kunne ikke opprette avspillingskø – ingen elementer';
	@override String failedPlayback({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Bytter til kompatibel spiller...';
	@override String get serverLimitTitle => 'Avspilling mislyktes';
	@override String get serverLimitBody => 'Serverfeil (HTTP 500). En båndbredde-/transkodingsgrense avviste trolig økten. Be eieren justere den.';
	@override String get mediaUnreadableTitle => 'Fil utilgjengelig';
	@override String get mediaUnreadableBody => 'Serveren fant dette elementet, men kunne ikke lese filen (HTTP 404). Filen er sannsynligvis flyttet, slettet, eller lagringen er frakoblet. Be serverens eier om å sjekke filen og skanne biblioteket på nytt.';
	@override String get logsUploaded => 'Logger lastet opp';
	@override String get logsUploadFailed => 'Kunne ikke laste opp logger';
	@override String get logId => 'Logg-ID';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$nb extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$mpvConfig$nb extends Translations$mpvConfig$en {
	_Translations$mpvConfig$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$dialog$nb extends Translations$dialog$en {
	_Translations$dialog$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Bekreft handling';
}

// Path: profiles
class _Translations$profiles$nb extends Translations$profiles$en {
	_Translations$profiles$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String plexAccountChip({required Object account}) => 'Plex-konto: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';
	@override String get connectionDefault => 'Standard';
	@override String connectionAs({required Object displayName}) => 'som ${displayName}';
	@override String get makeDefault => 'Gjør til standard';
	@override String get removeConnection => 'Fjern';
	@override String get profileRenamed => 'Profilen er omdøpt.';
	@override String borrowAddTo({required Object displayName}) => 'Legg til ${displayName}';
	@override String get borrowExplain => 'Lån en annen profils tilkobling. PIN-beskyttede profiler krever PIN.';
	@override String get borrowEmpty => 'Ingenting å låne enda.';
	@override String get borrowEmptySubtitle => 'Koble Plex eller Jellyfin til en annen profil først.';
	@override String get borrowLoadFailed => 'Kunne ikke laste inn tilgjengelige tilkoblinger. Prøv igjen.';
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
class _Translations$connections$nb extends Translations$connections$en {
	_Translations$connections$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Tilkoblinger';
	@override String get addConnection => 'Legg til tilkobling';
	@override String get addConnectionSubtitleNoProfile => 'Logg inn med Plex eller koble til en Jellyfin-server';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Legg til for ${displayName}: Plex, Jellyfin eller en annen profiltilkobling';
	@override String sessionExpiredOne({required Object name}) => 'Økten er utløpt for ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Økten er utløpt for ${count} servere';
	@override String get signInAgain => 'Logg inn igjen';
	@override String editMediaBrowserTitle({required Object product}) => 'Rediger ${product}-tilkobling';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. Plezy vil bruke den nåbare URL-en med lavest ventetid.';
}

// Path: discover
class _Translations$discover$nb extends Translations$discover$en {
	_Translations$discover$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Oppdag';
	@override String get noContentAvailable => 'Ikke noe innhold tilgjengelig';
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
	@override String get extras => 'Trailere og ekstramateriale';
	@override String get studio => 'Studio';
	@override String get rating => 'Vurdering';
	@override String get director => 'Regissør';
	@override String get directors => 'Regissører';
	@override String get movie => 'Film';
	@override String get tvShow => 'TV-serie';
	@override String minutesLeft({required Object minutes}) => '${minutes} min igjen';
	@override String get moreLikeThis => 'Mer som dette';
}

// Path: errors
class _Translations$errors$nb extends Translations$errors$en {
	_Translations$errors$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Søk mislyktes: ${error}';
	@override String get searchUnavailable => 'Søket kunne ikke nå noen medieserver.';
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
class _Translations$libraries$nb extends Translations$libraries$en {
	_Translations$libraries$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override late final _Translations$libraries$tabs$nb tabs = _Translations$libraries$tabs$nb._(_root);
	@override late final _Translations$libraries$groupings$nb groupings = _Translations$libraries$groupings$nb._(_root);
	@override late final _Translations$libraries$filterCategories$nb filterCategories = _Translations$libraries$filterCategories$nb._(_root);
	@override late final _Translations$libraries$sortLabels$nb sortLabels = _Translations$libraries$sortLabels$nb._(_root);
}

// Path: about
class _Translations$about$nb extends Translations$about$en {
	_Translations$about$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Om';
	@override String get openSourceLicenses => 'Lisenser for åpen kildekode';
	@override String versionLabel({required Object version}) => 'Versjon ${version}';
	@override String get appDescription => 'En vakker Plex- og Jellyfin-klient for Flutter';
	@override String get viewLicensesDescription => 'Vis lisenser for tredjepartsbiblioteker';
}

// Path: serverSelection
class _Translations$serverSelection$nb extends Translations$serverSelection$en {
	_Translations$serverSelection$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Ingen servere funnet for ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Kunne ikke laste servere: ${error}';
}

// Path: hubDetail
class _Translations$hubDetail$nb extends Translations$hubDetail$en {
	_Translations$hubDetail$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittel';
	@override String get releaseYear => 'Utgivelsesår';
	@override String get dateAdded => 'Dato lagt til';
	@override String get rating => 'Vurdering';
	@override String get noItemsFound => 'Ingen elementer funnet';
}

// Path: logs
class _Translations$logs$nb extends Translations$logs$en {
	_Translations$logs$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Tøm logger';
	@override String get copyLogs => 'Kopier logger';
	@override String get uploadLogs => 'Last opp logger';
}

// Path: startup
class _Translations$startup$nb extends Translations$startup$en {
	_Translations$startup$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'Plezy kunne ikke starte';
	@override String get failedBody => 'Noe gikk galt under oppstart. Detaljene nedenfor viser hva som feilet.';
	@override String get failedBodyRepairable => 'Plezy\'s lagrede innstillingsfil er skadet og må bygges på nytt før Plezy kan starte. Å prøve igjen hjelper ikke – velg Reparer lagring.';
	@override String get phaseLabel => 'Trinn';
	@override String get showDetails => 'Vis detaljer';
	@override String get hideDetails => 'Skjul detaljer';
	@override String get copyDetails => 'Kopier detaljer';
	@override String get detailsCopied => 'Detaljer kopiert til utklippstavlen';
	@override String get uploadDetails => 'Last opp detaljer';
	@override String get repairStorage => 'Reparer lagring';
	@override String get repairTitle => 'Reparere lagrede data?';
	@override String get repairBodyCommon => 'Plezy\'s innstillingsfil er skadet og kan ikke leses. Reparasjon tilbakestiller alle innstillinger til standard.';
	@override String get repairBodyOneCredential => 'Én lagret pålogging er skadet og kan ikke leses. Reparasjon fjerner bare den; de andre innstillingene dine blir urørt.';
	@override String get repairBodySignInsKept => 'Serverne og profilene dine skal forbli pålogget.';
	@override String get repairBodySignInsLost => 'Nøkkelen som beskytter de lagrede påloggingene dine kan ikke gjenvinnes fra denne filen, så du må logge på alle servere og profiler på nytt. Ingenting på medieserveren din påvirkes.';
	@override String get repairBodySessionsUncertain => 'Trackere (MAL, AniList, Simkl, Trakt) og Seerr lagres separat og kan overleve eller ikke. Plezy vil fortelle deg nøyaktig hva det beholdt.';
	@override String get repairConfirm => 'Reparer';
	@override String get repairSucceeded => 'Lagring reparert';
	@override String get repairNeedsRestart => 'Lagring reparert – omstart kreves';
	@override String get restartRequiredBody => 'Dataene dine ble reparert, men Plezy må starte på nytt før det kan bruke dem. Lukk Plezy og åpne det igjen.';
	@override String get quitPlezy => 'Avslutt Plezy';
	@override String get repairFailed => 'Reparasjon mislyktes';
	@override String get repairKeptSignIns => 'Serverne og profilene dine er fortsatt pålogget.';
	@override String get repairLostSignIns => 'Nøkkelen som beskytter de lagrede påloggingene dine kunne ikke gjenvinnes. Du må logge på alle servere og profiler på nytt.';
	@override String get repairLostSessions => 'Minst én tracker- eller Seerr-tilkobling gikk tapt og må kobles til på nytt.';
	@override String get backupTitle => 'En kopi av den skadede filen ble beholdt';
	@override String get backupWarning => 'Den inneholder påloggingsinformasjonen din. Ikke last den opp eller del den.';
	@override String get deleteBackup => 'Slett kopi';
	@override String get backupDeleted => 'Kopi slettet.';
	@override String get previousFailureTitle => 'Plezy mislyktes i å starte forrige gang';
}

// Path: licenses
class _Translations$licenses$nb extends Translations$licenses$en {
	_Translations$licenses$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Relaterte pakker';
	@override String get license => 'Lisens';
	@override String licenseNumber({required Object number}) => 'Lisens ${number}';
	@override String licensesCount({required Object count}) => '${count} lisenser';
}

// Path: navigation
class _Translations$navigation$nb extends Translations$navigation$en {
	_Translations$navigation$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Biblioteker';
	@override String get downloads => 'Nedlastinger';
	@override String get liveTv => 'Direkte-TV';
	@override String get explore => 'Utforsk';
}

// Path: explore
class _Translations$explore$nb extends Translations$explore$en {
	_Translations$explore$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Utforsk';
	@override String get selectSource => 'Velg kilde';
	@override late final _Translations$explore$rows$nb rows = _Translations$explore$rows$nb._(_root);
	@override late final _Translations$explore$status$nb status = _Translations$explore$status$nb._(_root);
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
	@override late final _Translations$explore$badge$nb badge = _Translations$explore$badge$nb._(_root);
	@override late final _Translations$explore$stats$nb stats = _Translations$explore$stats$nb._(_root);
	@override late final _Translations$explore$season$nb season = _Translations$explore$season$nb._(_root);
	@override late final _Translations$explore$format$nb format = _Translations$explore$format$nb._(_root);
	@override late final _Translations$explore$sourceMaterial$nb sourceMaterial = _Translations$explore$sourceMaterial$nb._(_root);
	@override late final _Translations$explore$creditRole$nb creditRole = _Translations$explore$creditRole$nb._(_root);
	@override late final _Translations$explore$relation$nb relation = _Translations$explore$relation$nb._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Sendes ${day} kl. ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Sendes ${day} kl. ${time} ${timezone}';
	@override late final _Translations$explore$detail$nb detail = _Translations$explore$detail$nb._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${n} resultat',
		other: '${n} resultater',
	);
}

// Path: liveTv
class _Translations$liveTv$nb extends Translations$liveTv$en {
	_Translations$liveTv$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get whatsOn => 'På TV nå';
	@override String get watchChannel => 'Se kanal';
	@override String get favorites => 'Favoritter';
	@override String get reorderFavorites => 'Endre rekkefølge på favoritter';
	@override String get favoritesLoadFailed => 'Kunne ikke laste inn favoritter. Kontroller tilkoblingen og prøv på nytt.';
	@override String get favoritesUpdateFailed => 'Kunne ikke oppdatere favorittene. Kontroller tilkoblingen og prøv på nytt.';
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
	@override String get guideReloadRequested => 'Oppdatering av programguiden er forespurt';
	@override String get rulesProcessRequested => 'Ny vurdering av reglene er forespurt';
	@override String get recordShow => 'Ta opp program';
}

// Path: collections
class _Translations$collections$nb extends Translations$collections$en {
	_Translations$collections$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$playlists$nb extends Translations$playlists$en {
	_Translations$playlists$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$music$nb extends Translations$music$en {
	_Translations$music$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$watchTogether$nb extends Translations$watchTogether$en {
	_Translations$watchTogether$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get relayUnreachable => 'Reléserveren kan ikke nås. Blokkering hos internettleverandøren kan hindre Se sammen.';
	@override String get reconnectingToHost => 'Kobler til verten på nytt...';
	@override String get currentPlayback => 'Gjeldende avspilling';
	@override String get joinCurrentPlayback => 'Bli med i gjeldende avspilling';
	@override String get joinCurrentPlaybackDescription => 'Hopp tilbake til det verten ser på nå';
	@override String get failedToOpenCurrentPlayback => 'Kunne ikke åpne gjeldende avspilling';
	@override String participantJoined({required Object name}) => '${name} ble med';
	@override String participantLeft({required Object name}) => '${name} forlot';
	@override String participantPaused({required Object name}) => '${name} satte avspillingen på pause';
	@override String participantResumed({required Object name}) => '${name} startet avspillingen igjen';
	@override String participantSeeked({required Object name}) => '${name} endret avspillingsposisjonen';
	@override String participantBuffering({required Object name}) => '${name} buffrer';
	@override String participantNeedsUpdate({required Object name}) => '${name} bruker en eldre appversjon — synkronisering er ikke tilgjengelig';
	@override String resumingWithout({required Object name}) => 'Fortsetter uten ${name}';
	@override String get waitingForParticipants => 'Venter på at de andre skal laste inn...';
	@override String waitingForName({required Object name}) => 'Venter på ${name}...';
	@override String get recentRooms => 'Nylige rom';
	@override String get renameRoom => 'Gi nytt navn til rom';
	@override String get removeRoom => 'Fjern';
	@override String get guestSwitchUnavailable => 'Kunne ikke bytte — server ikke tilgjengelig for synkronisering';
	@override String get guestSwitchFailed => 'Kunne ikke bytte — innhold ble ikke funnet på denne serveren';
}

// Path: downloads
class _Translations$downloads$nb extends Translations$downloads$en {
	_Translations$downloads$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get storageFull => 'Nedlastingene ble stoppet fordi lagringsplassen på enheten er full. Frigjør plass, og prøv igjen.';
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
	@override String removeListSyncRuleConfirm({required Object title}) => 'Slutte å synkronisere «${title}»?';
	@override String get deleteSyncRuleDownloads => 'Slett også tilknyttede nedlastinger';
	@override String get deleteSyncRuleDownloadsDescription => 'Nedlastinger som brukes av en annen synkroniseringsregel eller profil, beholdes.';
	@override String syncRuleCreated({required Object count}) => 'Synkroniseringsregel opprettet — beholder ${count} usette episoder';
	@override String get syncRuleUpdated => 'Synkroniseringsregel oppdatert';
	@override String get syncRuleRemoved => 'Synkroniseringsregel fjernet';
	@override String get syncRuleAndDownloadsRemoved => 'Synkroniseringsregel og tilknyttede nedlastinger fjernet';
	@override String get syncRuleCleanupBusy => 'Synkroniseringsreglene oppdateres for øyeblikket. Prøv igjen om et øyeblikk.';
	@override String get syncRuleCleanupUnavailable => 'Tilknyttede nedlastinger kunne ikke identifiseres på en trygg måte. Koble til serveren på nytt og prøv igjen, eller fjern regelen uten å slette nedlastingene.';
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
	@override late final _Translations$downloads$backgroundWarning$nb backgroundWarning = _Translations$downloads$backgroundWarning$nb._(_root);
}

// Path: shaders
class _Translations$shaders$nb extends Translations$shaders$en {
	_Translations$shaders$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$nb extends Translations$companionRemote$en {
	_Translations$companionRemote$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fjernkontroll';
	@override String connectedTo({required Object name}) => 'Tilkoblet ${name}';
	@override String get unknownDevice => 'Ukjent enhet';
	@override late final _Translations$companionRemote$session$nb session = _Translations$companionRemote$session$nb._(_root);
	@override late final _Translations$companionRemote$pairing$nb pairing = _Translations$companionRemote$pairing$nb._(_root);
	@override late final _Translations$companionRemote$remote$nb remote = _Translations$companionRemote$remote$nb._(_root);
	@override late final _Translations$companionRemote$errors$nb errors = _Translations$companionRemote$errors$nb._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$nb extends Translations$videoSettings$en {
	_Translations$videoSettings$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Avspillingshastighet';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Aktiv (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Innsovningstimer';
	@override String get audioSync => 'Lydsynkronisering';
	@override String get subtitleSync => 'Undertekstsynkronisering';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Lydutgang';
	@override String get performanceOverlay => 'Ytelsesoverlegg';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Romlig lyd';
	@override String get audioOutputStereo => 'Stereo';
	@override String get audioNormalization => 'Normaliser lydstyrke';
	@override String get audioDownmix => 'Nedmiks til stereo';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$nb extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get renderFps => 'Gjengivelses-FPS';
	@override String get displayFps => 'Skjerm-FPS';
	@override String get avSync => 'A/V-synk';
	@override String get dropped => 'Tapte';
	@override String get dvRpus => 'DV RPU-er';
	@override String get dvRpuAverage => 'DV RPU snitt';
	@override String get dvSampleAverage => 'DV-sample snitt';
	@override String get maxLuma => 'Maks luma';
	@override String get minLuma => 'Min luma';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Brukt hurtigbuffer';
	@override String get cacheLimit => 'Grense for hurtigbuffer';
	@override String get speed => 'Hastighet';
	@override String get player => 'Spiller';
	@override String get memory => 'Minne';
	@override String get uiFps => 'UI FPS';
}

// Path: externalPlayer
class _Translations$externalPlayer$nb extends Translations$externalPlayer$en {
	_Translations$externalPlayer$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$metadataEdit$nb extends Translations$metadataEdit$en {
	_Translations$metadataEdit$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Rediger...';
	@override String get screenTitle => 'Rediger metadata';
	@override String get basicInfo => 'Grunnleggende informasjon';
	@override String get artwork => 'Grafikk';
	@override String get advancedSettings => 'Avanserte innstillinger';
	@override String get title => 'Tittel';
	@override String get sortTitle => 'Sorteringstittel';
	@override String get originalTitle => 'Originaltittel';
	@override String get releaseDate => 'Utgivelsesdato';
	@override String get contentRating => 'Aldersgrense';
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
	@override String get artworkUpdated => 'Grafikk oppdatert';
	@override String get artworkUpdateFailed => 'Kunne ikke oppdatere grafikken';
	@override String get noArtworkAvailable => 'Ingen grafikk tilgjengelig';
	@override String artworkOption({required Object index}) => 'Grafikkalternativ ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Grafikkalternativ ${index}, valgt';
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
class _Translations$matchScreen$nb extends Translations$matchScreen$en {
	_Translations$matchScreen$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get match => 'Finn treff...';
	@override String get fixMatch => 'Korriger treff...';
	@override String get unmatch => 'Fjern treff';
	@override String get unmatchConfirm => 'Fjerne dette treffet? Plex behandler elementet som uten treff til det matches på nytt.';
	@override String get unmatchSuccess => 'Treff fjernet';
	@override String get unmatchFailed => 'Kunne ikke fjerne treff';
	@override String get matchApplied => 'Treff valgt';
	@override String get matchFailed => 'Kunne ikke velge treff';
	@override String get titleHint => 'Tittel';
	@override String get yearHint => 'År';
	@override String get search => 'Søk';
	@override String get noMatchesFound => 'Ingen treff funnet';
}

// Path: serverTasks
class _Translations$serverTasks$nb extends Translations$serverTasks$en {
	_Translations$serverTasks$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serveroppgaver';
	@override String get failedToLoad => 'Kunne ikke laste oppgaver';
	@override String get noTasks => 'Ingen oppgaver kjører';
}

// Path: trakt
class _Translations$trakt$nb extends Translations$trakt$en {
	_Translations$trakt$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Tilkoblet';
	@override String connectedAs({required Object username}) => 'Tilkoblet som @${username}';
	@override String get disconnectConfirm => 'Koble fra Trakt-konto?';
	@override String get disconnectConfirmBody => 'Plezy slutter å sende hendelser til Trakt. Du kan koble til igjen når som helst.';
	@override String get scrobble => 'Sanntids-scrobbling';
	@override String get scrobbleDescription => 'Send avspillings-, pause- og stopphendelser til Trakt under avspilling.';
	@override String get watchedSync => 'Synkroniser settstatus';
	@override String get watchedSyncDescription => 'Når du markerer elementer som sett i Plezy, markeres de også som sett på Trakt.';
}

// Path: seerr
class _Translations$seerr$nb extends Translations$seerr$en {
	_Translations$seerr$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get request => 'Be om';
	@override String get request4k => 'Be om i 4K';
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
class _Translations$services$nb extends Translations$services$en {
	_Translations$services$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override late final _Translations$services$names$nb names = _Translations$services$names$nb._(_root);
	@override late final _Translations$services$deviceCode$nb deviceCode = _Translations$services$deviceCode$nb._(_root);
	@override late final _Translations$services$oauthProxy$nb oauthProxy = _Translations$services$oauthProxy$nb._(_root);
	@override late final _Translations$services$libraryFilter$nb libraryFilter = _Translations$services$libraryFilter$nb._(_root);
}

// Path: addServer
class _Translations$addServer$nb extends Translations$addServer$en {
	_Translations$addServer$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Legg til ${product}-server';
	@override String get serverUrls => 'Server-URL-er';
	@override String get serverUrlsHelper => 'Flere URL-er er tillatt, atskilt med komma.';
	@override String get findServer => 'Finn server';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Leter etter lokale ${product}-servere...';
	@override String localMediaBrowserServers({required Object product}) => 'Lokale ${product}-servere';
	@override String get username => 'Brukernavn';
	@override String get password => 'Passord';
	@override String get signIn => 'Logg inn';
	@override String get change => 'Endre';
	@override String get required => 'Påkrevd';
	@override String couldNotReachServer({required Object error}) => 'Kunne ikke nå serveren: ${error}';
	@override String signInFailed({required Object error}) => 'Innlogging mislyktes: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect mislyktes: ${error}';
	@override String get addPlexTitle => 'Logg inn med Plex';
	@override String get pinExpired => 'PIN-koden utløp før innloggingen var fullført. Prøv igjen.';
	@override String failedToRegisterAccount({required Object error}) => 'Kunne ikke registrere kontoen: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Skriv inn URL-en til ${product}-serveren din';
	@override String get addConnectionTitle => 'Legg til tilkobling';
	@override String addConnectionTitleScoped({required Object name}) => 'Legg til for ${name}';
	@override String get signInWithPlexCard => 'Logg inn med Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriser denne enheten. Delte servere legges til.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriser en Plex-konto. Home-brukere blir profiler.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Koble til ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Skriv inn server-URL-en, brukernavnet og passordet ditt.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Logg på ${product}-serveren din. Knyttes til ${name}.';
	@override String get borrowFromAnotherProfile => 'Lån fra en annen profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Gjenbruk en annen profils tilkobling. PIN-beskyttede profiler krever PIN.';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$nb extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Kritikere';
	@override String get audience => 'Publikum';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Rotten Tomatoes-kritikere';
	@override String get rottenTomatoesAudience => 'Rotten Tomatoes-publikum';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$nb extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Spill av/Pause';
	@override String get volumeUp => 'Volum opp';
	@override String get volumeDown => 'Volum ned';
	@override String seekForward({required Object seconds}) => 'Spol fremover (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Spol bakover (${seconds}s)';
	@override String get fullscreenToggle => 'Slå fullskjerm av/på';
	@override String get muteToggle => 'Slå lyddemping av/på';
	@override String get subtitleToggle => 'Slå undertekster av/på';
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
	@override String get shaderToggle => 'Slå shadere av/på';
	@override String get skipMarker => 'Hopp over intro/rulletekst';
	@override String get screenshot => 'Ta skjermbilde';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$nb extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$libraries$tabs$nb extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Anbefalt';
	@override String get browse => 'Bla gjennom';
	@override String get collections => 'Samlinger';
	@override String get playlists => 'Spillelister';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$nb extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$libraries$filterCategories$nb extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$libraries$sortLabels$nb extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tittel';
	@override String get dateAdded => 'Dato lagt til';
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
class _Translations$explore$rows$nb extends Translations$explore$rows$en {
	_Translations$explore$rows$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Ønskeliste';
	@override String get recommendedMovies => 'Anbefalte filmer';
	@override String get recommendedShows => 'Anbefalte serier';
	@override String get trendingMovies => 'Populære filmer nå';
	@override String get trendingShows => 'Populære serier nå';
	@override String get popularMovies => 'Populære filmer';
	@override String get popularShows => 'Populære serier';
	@override String get trendingAnime => 'Populær anime nå';
	@override String get suggestedAnime => 'Foreslått anime';
	@override String get airingAnime => 'Topp pågående anime';
	@override String get popularAnime => 'Mest populær anime';
	@override String get trending => 'Populært nå';
	@override String get upcomingMovies => 'Kommende filmer';
	@override String get upcomingShows => 'Kommende serier';
}

// Path: explore.status
class _Translations$explore$status$nb extends Translations$explore$status$en {
	_Translations$explore$status$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Sendes';
	@override String get ended => 'Avsluttet';
	@override String get canceled => 'Avlyst';
	@override String get upcoming => 'Kommende';
}

// Path: explore.badge
class _Translations$explore$badge$nb extends Translations$explore$badge$en {
	_Translations$explore$badge$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} populær';
	@override String rankAiring({required Object n}) => '#${n} på lufta';
	@override String rankRated({required Object n}) => '#${n} vurdert';
	@override String rankFavorited({required Object n}) => '#${n} favorisert';
	@override String rankTrending({required Object n}) => '#${n} trendende';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} i ${season}';
	@override String watchingNow({required Object n}) => '${n} ser på';
	@override String get available => 'Tilgjengelig';
	@override String get partiallyAvailable => 'Delvis tilgjengelig';
	@override String get availableIn4k => '4K tilgjengelig';
	@override String get requested => 'Forespurt';
	@override String get pendingApproval => 'Venter på godkjenning';
	@override String get processing => 'Behandler';
	@override String get declined => 'Avslått';
	@override String get requestFailed => 'Forespørsel mislyktes';
	@override String get requested4k => '4K forespurt';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} sesonger';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} om ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Neste om ${duration}';
	@override String episodesShort({required Object n}) => '${n} ep.';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$nb extends Translations$explore$stats$en {
	_Translations$explore$stats$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} oppført';
	@override String viewersDay({required Object n}) => '${n} så på i dag';
	@override String viewersWeek({required Object n}) => '${n} så på denne uken';
	@override String viewersMonth({required Object n}) => '${n} så på denne måneden';
	@override String viewersYear({required Object n}) => '${n} så på i år';
	@override String viewersAllTime({required Object n}) => '${n} seere';
	@override String planning({required Object n}) => '${n} planlegger å se';
	@override String favorited({required Object n}) => '${n} favoritter';
	@override String dropRate({required Object percent}) => '${percent} droppet den';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: '${n} kommentar',
		other: '${n} kommentarer',
	);
	@override String votes({required Object n}) => '${n} stemmer';
	@override String watching({required Object n}) => '${n} ser på den';
	@override String completed({required Object n}) => '${n} fullførte';
	@override String onHold({required Object n}) => '${n} på pause';
	@override String dropped({required Object n}) => '${n} droppet';
}

// Path: explore.season
class _Translations$explore$season$nb extends Translations$explore$season$en {
	_Translations$explore$season$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Vinter';
	@override String get spring => 'Vår';
	@override String get summer => 'Sommer';
	@override String get fall => 'Høst';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$nb extends Translations$explore$format$en {
	_Translations$explore$format$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'TV-kort';
	@override String get movie => 'Film';
	@override String get special => 'Spesial';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Musikk';
	@override String get other => 'Annet';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$nb extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Roman';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Spill';
	@override String get webComic => 'Nettserie';
	@override String get musicRelease => 'Musikk';
	@override String get otherMedia => 'Annet';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$nb extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get director => 'Regissør';
	@override String get writer => 'Forfatter';
	@override String get producer => 'Produsent';
	@override String get creator => 'Skaper';
	@override String get composer => 'Komponist';
}

// Path: explore.relation
class _Translations$explore$relation$nb extends Translations$explore$relation$en {
	_Translations$explore$relation$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequel';
	@override String get sequel => 'Sequel';
	@override String get sideStory => 'Bihistorie';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Alternativ versjon';
	@override String get summary => 'Sammendrag';
	@override String get parentStory => 'Hovedhistorie';
	@override String get adaptation => 'Adaptasjon';
	@override String get other => 'Relatert';
}

// Path: explore.detail
class _Translations$explore$detail$nb extends Translations$explore$detail$en {
	_Translations$explore$detail$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Originaltittel';
	@override String get alsoKnownAs => 'Også kjent som';
	@override String get studios => 'Studioer';
	@override String get country => 'Land';
	@override String get language => 'Språk';
	@override String get released => 'Utgitt';
	@override String get physicalRelease => 'På disk';
	@override String get ended => 'Avsluttet';
	@override String addedOn({required Object date}) => 'Lagt til ${date}';
	@override String get yourRating => 'Din vurdering';
	@override String get budget => 'Budsjett';
	@override String get revenue => 'Billettinntekter';
	@override String get contentAdvisory => 'Aldersveiledning';
	@override String get tags => 'Tagger';
	@override String get revealSpoilerTags => 'Vis spoilertagger';
	@override String get links => 'Lenker';
	@override String get watchOn => 'Se på';
	@override String get watchTrailer => 'Se trailer';
	@override String openOn({required Object site}) => 'Åpne på ${site}';
	@override String get crew => 'Mannskap';
	@override String get ratings => 'Vurderinger';
	@override String get schedule => 'Sendeskjema';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n,
		one: 'Anbefalt av ${n} bruker',
		other: 'Anbefalt av ${n} brukere',
	);
	@override String recommendedBy({required Object who}) => 'Anbefalt av ${who}';
	@override String favoritedBy({required Object who}) => 'Favorisert av ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} har ikke blitt sendt ennå';
	@override String recommendedByPercent({required Object percent}) => 'Anbefalt av ${percent} av seerne';
	@override String get relatedTitles => 'Relaterte titler';
	@override String get background => 'Bakgrunn';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$nb extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Nedlastinger stopper når du forlater appen';
	@override String get bannerDegraded => 'Bakgrunnsnedlastinger kan være begrenset';
	@override String get bannerAction => 'Detaljer';
	@override String get sheetTitle => 'Bakgrunnsnedlastinger er blokkert';
	@override String get sheetTitleDegraded => 'Bakgrunnsnedlastinger kan være begrenset';
	@override String get sheetIntro => 'Android hindrer Plezy i å laste ned pålitelig i bakgrunnen.';
	@override String get sheetIntroDegraded => 'Enheten din begrenser når Plezy kan laste ned i bakgrunnen.';
	@override String get reasonBackgroundRestricted => 'Bakgrunnsbruken til Plezy er begrenset. Sett batteribruk eller bakgrunnsbruk til «Ubegrenset».';
	@override String get reasonStandbyRestricted => 'Android har satt Plezy i begrenset hvilemodus. Sett batteribruken til «Ubegrenset».';
	@override String get reasonDownloadChannelBlocked => 'Varsler om nedlastinger er slått av, så fremdrift og kontroller kan være utilgjengelige.';
	@override String get reasonNotificationsDisabled => 'Varsler er slått av. På Android 13 eller nyere kreves de for lange bakgrunnsnedlastinger.';
	@override String get reasonDataSaver => 'Datasparing er slått på og blokkerer bakgrunnsnedlastinger via mobildata. Nedlastinger skal fortsatt fungere på Wi-Fi.';
	@override String get reasonOemUnknown => 'Nedlastinger har stoppet gjentatte ganger mens Plezy var i bakgrunnen. Sjekk innstillingene for batteribruk eller bakgrunnsbruk for Plezy.';
	@override String get openSettings => 'Åpne innstillinger';
	@override String get stillNotWorking => 'Enhetsspesifikk hjelp';
	@override String get stillNotWorkingDescription => 'Se fremgangsmåten for enheten din, eller send en logg fra Innstillinger › Vis logger hvis problemet vedvarer.';
	@override String get dialogTitle => 'Nedlastinger blir kanskje ikke fullført';
	@override String get dialogDownloadAnyway => 'Last ned likevel';
	@override String get dialogFixFirst => 'Løs dette først';
	@override String get statusTile => 'Bakgrunnsnedlastinger';
	@override String get statusOk => 'Kan kjøre i bakgrunnen';
	@override String get statusBlocked => 'Blokkert av systeminnstillinger';
	@override String get statusDegraded => 'Begrenset av systeminnstillinger';
	@override String get statusUnknown => 'Ikke sjekket ennå';
	@override String get settingsUnavailable => 'Kunne ikke åpne systeminnstillingene på denne enheten';
	@override String get linkUnavailable => 'Kunne ikke åpne dontkillmyapp.com på denne enheten';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$nb extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Starter fjernserver...';
	@override String get hostAddress => 'Vertsadresse';
	@override String get connected => 'Tilkoblet';
	@override String get serverRunning => 'Fjernserver aktiv';
	@override String get serverStopped => 'Fjernserver stoppet';
	@override String get serverRunningDescription => 'Mobilenheter på nettverket ditt kan koble til denne appen';
	@override String get serverStoppedDescription => 'Start serveren for å la mobilenheter koble til';
	@override String get usePhoneToControl => 'Bruk mobilenheten din til å styre denne appen';
	@override String get startServer => 'Start server';
	@override String get stopServer => 'Stopp server';
	@override String get minimize => 'Minimer';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$nb extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Plezy-enheter med samme Plex-konto vises her';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Kobler til...';
	@override String get searchingForDevices => 'Søker etter enheter...';
	@override String get noDevicesFound => 'Ingen enheter funnet på nettverket ditt';
	@override String get noDevicesHint => 'Åpne Plezy på datamaskinen, og bruk samme Wi-Fi';
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
class _Translations$companionRemote$remote$nb extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
	@override String get searchHint => 'Søk på datamaskinen...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$nb extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$services$names$nb extends Translations$services$names$en {
	_Translations$services$names$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$nb extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$nb._(TranslationsNb root) : this._root = root, super.internal(root);

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
class _Translations$services$oauthProxy$nb extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Logg inn på ${service}';
	@override String get body => 'Skann denne QR-koden eller åpne URL-en på en enhet.';
	@override String openToSignIn({required Object service}) => 'Åpne ${service} for å logge inn';
	@override String get copyUrl => 'Kopier URL for pålogging';
	@override String get urlCopied => 'URL kopiert';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$nb extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$nb._(TranslationsNb root) : this._root = root, super.internal(root);

	final TranslationsNb _root; // ignore: unused_field

	// Translations
	@override String get title => 'Biblioteksfilter';
	@override String get subtitleAllSyncing => 'Synkroniserer alle biblioteker';
	@override String get subtitleNoneSyncing => 'Ingenting synkroniseres';
	@override String subtitleBlocked({required Object count}) => '${count} blokkert';
	@override String subtitleAllowed({required Object count}) => '${count} tillatt';
	@override String get mode => 'Filtermodus';
	@override String get modeBlacklist => 'Blokkeringsliste';
	@override String get modeWhitelist => 'Tillatelsesliste';
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
			'auth.authenticationTimeout' => 'Autentiseringen tok for lang tid. Prøv igjen.',
			'auth.scanQRToSignIn' => 'Skann denne QR-koden for å logge inn',
			'auth.waitingForAuth' => 'Venter på autentisering...\nLogg inn fra nettleseren.',
			'auth.useBrowser' => 'Bruk nettleser',
			'auth.or' => 'eller',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Koble til ${product}',
			'auth.useQuickConnect' => 'Bruk Quick Connect',
			'auth.quickConnectInstructions' => 'Åpne Quick Connect i Jellyfin og skriv inn denne koden.',
			'auth.quickConnectWaiting' => 'Venter på godkjenning…',
			'auth.quickConnectCancel' => 'Avbryt',
			'auth.quickConnectExpired' => 'Quick Connect er utløpt. Prøv igjen.',
			'auth.localDataRecoveryRequired' => 'Plezy kunne ikke gjenopprette lokale innloggingsdata og ventende avspillingsdata på en sikker måte. Logg inn på nytt.',
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
			'common.pressBackAgainToExit' => 'Trykk på Tilbake en gang til for å avslutte',
			'common.ratingSource.critic' => 'Kritikere',
			'common.ratingSource.audience' => 'Publikum',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Rotten Tomatoes-kritikere',
			'common.ratingSource.rottenTomatoesAudience' => 'Rotten Tomatoes-publikum',
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
			'settings.videoPlaybackDescription' => 'Tilpass avspillingen',
			'settings.advanced' => 'Avansert',
			'settings.episodePosterMode' => 'Type episodeplakat',
			'settings.seriesPoster' => 'Serieplakat',
			'settings.seasonPoster' => 'Sesongplakat',
			'settings.episodeThumbnail' => 'Miniatyrbilde',
			'settings.showHeroSectionDescription' => 'Vis en karusell med fremhevet innhold på startskjermen',
			'settings.secondsLabel' => 'Sekunder',
			'settings.minutesLabel' => 'Minutter',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Angi varighet (${min}-${max})',
			'settings.systemTheme' => 'System',
			'settings.lightTheme' => 'Lyst',
			'settings.darkTheme' => 'Mørkt',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Innholdstetthet i biblioteket',
			'settings.displayScale' => 'Skalering',
			'settings.compact' => 'Kompakt',
			'settings.comfortable' => 'Komfortabel',
			'settings.tvCornerSpotlightBackdrop' => 'Fremhevet bakgrunn i hjørnet',
			'settings.tvCornerSpotlightBackdropDescription' => 'Vis fremhevet grafikk øverst til høyre i stedet for å fylle skjermen',
			'settings.viewMode' => 'Visningsmodus',
			'settings.gridView' => 'Rutenett',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Vis fremhevet seksjon',
			'settings.continueWatchingAction' => 'Handling for «Fortsett å se»',
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
			'settings.tvFullCardLayout' => 'Heldekkende TV-kort',
			'settings.tvFullCardLayoutDescription' => 'Bruk TV-kort med bare bilder og skuespillernavn lagt over',
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
			'settings.playerBackend' => 'Avspillingsmotor',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Maskinvaredekoding',
			'settings.hardwareDecodingDescription' => 'Bruk maskinvareakselerasjon når tilgjengelig',
			'settings.bufferSize' => 'Bufferstørrelse',
			'settings.bufferSizeMB' => ({required Object size}) => '${size} MB',
			'settings.bufferSizeAuto' => 'Automatisk (anbefalt)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap} MB minne tilgjengelig. En buffer på ${size} MB kan påvirke avspillingen.',
			'settings.playbackBuffer' => 'Avspillingsbuffer',
			'settings.playbackBufferAuto' => 'Auto (anbefalt)',
			'settings.playbackBufferLarge' => 'Stor',
			'settings.playbackBufferExtraLarge' => 'Ekstra stor',
			'settings.playbackBufferDescription' => 'Bufrer mer mot ustabile tilkoblinger. Begrenses også av bufferstørrelsen.',
			'settings.defaultQualityTitle' => 'Standardkvalitet',
			'settings.musicQualityTitle' => 'Musikkvalitet',
			'settings.subtitleStyling' => 'Undertekststil',
			'settings.subtitleStylingDescription' => 'Tilpass utseendet på undertekster',
			'settings.smallSkipDuration' => 'Kort hoppvarighet',
			'settings.largeSkipDuration' => 'Lang hoppvarighet',
			'settings.rewindOnResume' => 'Spol tilbake ved gjenopptakelse',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} sekunder',
			'settings.defaultSleepTimer' => 'Standard innsovningstimer',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutter',
			'settings.rememberTrackSelections' => 'Husk sporvalg per serie/film',
			'settings.rememberTrackSelectionsDescription' => 'Husk lyd- og undertekstvalg per tittel',
			'settings.followServerTrackSelections' => 'Bruk serverens sporvalg per episode',
			'settings.followServerTrackSelectionsDescription' => 'Ved episodebytte brukes lyden og undertekstene som er valgt på serveren, i stedet for å videreføre gjeldende valg',
			'settings.showChapterMarkersOnTimeline' => 'Vis kapittelmarkører på tidslinjen',
			'settings.showChapterMarkersOnTimelineDescription' => 'Del tidslinjen ved kapittelgrenser',
			'settings.clickVideoTogglesPlayback' => 'Klikk på video for å veksle avspilling',
			'settings.clickVideoTogglesPlaybackDescription' => 'Klikk på video for å spille av/pause i stedet for å vise kontroller.',
			'settings.videoPlayerControls' => 'Videospillerkontroller',
			'settings.keyboardShortcuts' => 'Tastatursnarveier',
			'settings.keyboardShortcutsDescription' => 'Tilpass tastatursnarveier',
			'settings.videoPlayerNavigation' => 'Videospillernavigering',
			'settings.videoPlayerNavigationDescription' => 'Bruk piltaster for å navigere videospillerkontroller',
			'settings.watchTogetherRelay' => 'Reléserver for Se sammen',
			'settings.watchTogetherRelayDescription' => 'Angi en egendefinert reléserver. Alle må bruke samme server.',
			'settings.watchTogetherRelayHint' => 'https://min-relay.eksempel.no',
			'settings.watchTogetherRelayInvalid' => 'Angi en gyldig HTTP- eller HTTPS-adresse til reléserveren.',
			'settings.crashReporting' => 'Krasjrapportering',
			'settings.crashReportingDescription' => 'Send krasjrapporter for å hjelpe med å forbedre appen',
			'settings.debugLogging' => 'Feilsøkingslogging',
			'settings.debugLoggingDescription' => 'Aktiver detaljert logging for feilsøking',
			'settings.viewLogs' => 'Vis logger',
			'settings.viewLogsDescription' => 'Vis applikasjonslogger',
			'settings.clearImageCache' => 'Tøm bildebufferen',
			'settings.clearImageCacheDescription' => 'Tømmer bufret kunstverk og miniatyrbilder. Bilder kan lastes langsommere til de er lastet ned på nytt.',
			'settings.clearImageCacheSuccess' => 'Bildebufferen ble tømt',
			'settings.resetSettings' => 'Tilbakestill innstillinger',
			'settings.resetSettingsDescription' => 'Gjenopprett standardinnstillinger. Dette kan ikke angres.',
			'settings.resetSettingsSuccess' => 'Innstillinger tilbakestilt',
			'settings.backup' => 'Sikkerhetskopi',
			'settings.exportSettings' => 'Eksporter innstillinger',
			'settings.exportSettingsDescription' => 'Lagre innstillingene i en fil',
			'settings.exportSettingsSuccess' => 'Innstillinger eksportert',
			'settings.importSettings' => 'Importer innstillinger',
			'settings.importSettingsDescription' => 'Gjenopprett innstillinger fra en fil',
			'settings.importSettingsConfirm' => 'Dette vil erstatte nåværende innstillinger. Fortsette?',
			'settings.importSettingsSuccess' => 'Innstillinger importert',
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
			'settings.saveFailed' => 'Kunne ikke lagre endringene. Prøv igjen.',
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
			'settings.downloadLocationPickerUnavailable' => 'Mappevalg er ikke tilgjengelig på denne enheten',
			'settings.downloadOnWifiOnly' => 'Last bare ned via Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Forhindre nedlasting via mobildata',
			'settings.autoRemoveWatchedDownloads' => 'Fjern avspilte nedlastinger automatisk',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Slett avspilte nedlastinger automatisk',
			'settings.cellularDownloadBlocked' => 'Nedlastinger er blokkert på mobilnett. Bruk Wi-Fi eller endre innstillingen.',
			'settings.maxVolume' => 'Maksvolum',
			'settings.maxVolumeDescription' => 'Tillat volumforsterkning over 100 % for medier med lavt lydnivå',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent} %',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Vis hva du ser på Discord',
			'settings.services' => 'Tjenester',
			'settings.servicesDescription' => 'Koble til Trakt, MyAnimeList, Seerr og mer',
			'settings.manageLibrariesDescription' => 'Omorganiser og skjul biblioteker',
			'settings.companionRemoteServer' => 'Fjernkontrollserver',
			'settings.companionRemoteServerDescription' => 'La mobilenheter på nettverket styre denne appen',
			'settings.autoPip' => 'Automatisk bilde-i-bilde',
			'settings.autoPipDescription' => 'Åpne bilde-i-bilde når du forlater appen under avspilling',
			'settings.matchContentFrameRate' => 'Tilpass innholdets bildefrekvens',
			'settings.matchContentFrameRateDescription' => 'Tilpass skjermens oppdateringsfrekvens til videoinnhold',
			'settings.matchRefreshRate' => 'Tilpass oppdateringsfrekvens',
			'settings.matchRefreshRateDescription' => 'Tilpass skjermens oppdateringsfrekvens i fullskjerm',
			'settings.matchDynamicRange' => 'Tilpass dynamikkområde',
			'settings.matchDynamicRangeDescription' => 'Slå på HDR for HDR-innhold, og deretter tilbake til SDR',
			'settings.displaySwitchDelay' => 'Forsinkelse ved skjermbytte',
			'settings.tunneledPlayback' => 'Tunnelert avspilling',
			'settings.tunneledPlaybackDescription' => 'Bruk videotunneling. Slå av hvis HDR-avspilling viser svart video.',
			'settings.audioPassthrough' => 'Direkte lydutgang',
			'settings.audioPassthroughDescription' => 'Send Dolby/DTS-lyd til mottakeren eller TV-en uten omkoding, slik at surroundlyd bevares. Slå av hvis du ikke har lyd.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Bruk Apples innebygde Dolby-dekoder for Dolby Digital Plus, inkludert Atmos. DTS og TrueHD spilles fortsatt av som flerkanals PCM. Slå av hvis du ikke har lyd.',
			'settings.audioDownmix' => 'Nedmiks til stereo',
			'settings.audioDownmixDescription' => 'Miks surroundlyd ned til to kanaler for stereohøyttalere eller hodetelefoner',
			'settings.downmixCenterBoost' => 'Forsterkning av senterkanal',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Forsterkning (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normaliser lydstyrke ved nedmiks',
			'settings.audioDownmixNormalizeDescription' => 'Senker miksen for å unngå klipping. Slå av for å beholde originalvolumet (høye scener kan forvrenges).',
			'settings.dvConversionMode' => 'Dolby Vision-konvertering',
			'settings.dvConversionModeDescription' => 'Velg hvordan ExoPlayer håndterer filer med Dolby Vision-profil 7.',
			'settings.dvConversionAuto' => 'Automatisk',
			'settings.dvConversionNative' => 'Nativ / deaktivert',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Oppdag enhetens egenskaper og bruk vanlig reserveoppførsel',
			'settings.dvConversionNativeDescription' => 'Tving opprinnelig DV7-avspilling og ikke prøv DV-konvertering på nytt',
			'settings.dvConversionDv81Description' => 'Tving direkte RPU-konvertering til Dolby Vision-profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Fjern Dolby Vision RPU/EL-lag og lever som vanlig HEVC',
			'settings.requireProfileSelectionOnOpen' => 'Spør om profil ved appåpning',
			'settings.requireProfileSelectionOnOpenDescription' => 'Vis profilvalg hver gang appen åpnes',
			'settings.forceTvMode' => 'Tving TV-modus',
			'settings.forceTvModeDescription' => 'Tving TV-oppsett. For enheter som ikke oppdages automatisk. Krever omstart.',
			'settings.startInFullscreen' => 'Start i fullskjerm',
			'settings.startInFullscreenDescription' => 'Åpne Plezy i fullskjermmodus ved oppstart',
			'settings.exitFullscreenOnPlayerClose' => 'Avslutt fullskjerm ved lukking av avspiller',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Avslutt fullskjerm automatisk når videospilleren lukkes',
			'settings.autoHidePerformanceOverlay' => 'Skjul ytelsesoverlegg automatisk',
			'settings.autoHidePerformanceOverlayDescription' => 'Ton ytelsesoverlegget ut sammen med avspillingskontrollene',
			'settings.showNavBarLabels' => 'Vis etiketter i navigasjonsfeltet',
			'settings.showNavBarLabelsDescription' => 'Vis tekstetiketter under ikonene i navigasjonsfeltet',
			'settings.startupSection' => 'Startseksjon',
			'settings.liveTvDefaultFavorites' => 'Vis favorittkanaler som standard',
			'settings.liveTvDefaultFavoritesDescription' => 'Vis bare favorittkanaler når du åpner Direkte-TV',
			'settings.display' => 'Skjerm',
			'settings.homeScreen' => 'Hjemmeskjerm',
			'settings.navigation' => 'Navigering',
			'settings.window' => 'Vindu',
			'settings.content' => 'Innhold',
			'settings.player' => 'Spiller',
			'settings.subtitlesAndConfig' => 'Undertekster og konfigurasjon',
			'settings.seekAndTiming' => 'Spoling og tidsinnstillinger',
			'settings.behavior' => 'Oppførsel',
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
			'hotkeys.actions.fullscreenToggle' => 'Slå fullskjerm av/på',
			'hotkeys.actions.muteToggle' => 'Slå lyddemping av/på',
			'hotkeys.actions.subtitleToggle' => 'Slå undertekster av/på',
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
			'hotkeys.actions.shaderToggle' => 'Slå shadere av/på',
			'hotkeys.actions.skipMarker' => 'Hopp over intro/rulletekst',
			'hotkeys.actions.screenshot' => 'Ta skjermbilde',
			'fileInfo.title' => 'Filinformasjon',
			'fileInfo.overview' => 'Oversikt',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Lyd',
			'fileInfo.subtitles' => 'Undertekster',
			'fileInfo.images' => 'Innebygde bilder',
			'fileInfo.dataStreams' => 'Datastrømmer',
			'fileInfo.lyrics' => 'Sangtekster',
			'fileInfo.file' => 'Fil',
			'fileInfo.attachments' => 'Vedlegg',
			'fileInfo.delivery' => 'Levering',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versjon ${index} av ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Fil ${index} av ${count}',
			'fileInfo.noStreams' => 'Serveren rapporterte ingen strømmer for denne filen.',
			'fileInfo.copyPath' => 'Kopier bane',
			'fileInfo.pathCopied' => 'Filbane kopiert',
			'fileInfo.codec' => 'Kodek',
			'fileInfo.codecTag' => 'Codec-tagg',
			'fileInfo.resolution' => 'Oppløsning',
			'fileInfo.codedResolution' => 'Kodet oppløsning',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Bildefrekvens',
			'fileInfo.rotation' => 'Rotasjon',
			'fileInfo.comment' => 'Kommentar',
			'fileInfo.audioDescription' => 'Lydbeskrivelse',
			'fileInfo.headerCompression' => 'Overskriftkomprimering',
			'fileInfo.sidecarFile' => 'Sidecar-fil',
			'fileInfo.transportTimestamp' => 'Transporttidsstempel',
			'fileInfo.displayOffset' => 'Visningsforskyvning',
			'fileInfo.previewFailureCode' => 'Forhåndsvisningsfeilkode',
			'fileInfo.previewRetries' => 'Nye forhåndsvisningsforsøk',
			'fileInfo.aspectRatio' => 'Sideforhold',
			'fileInfo.pixelAspectRatio' => 'Piksel-aspektforhold',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Nivå',
			'fileInfo.bitDepth' => 'Bitdybde',
			'fileInfo.pixelFormat' => 'Pikselformat',
			'fileInfo.colorSpace' => 'Fargerom',
			'fileInfo.colorRange' => 'Fargeområde',
			'fileInfo.colorPrimaries' => 'Fargeprimærer',
			'fileInfo.colorTransfer' => 'Fargeoverføring',
			'fileInfo.chromaSubsampling' => 'Krominansnedsampling',
			'fileInfo.chromaLocation' => 'Kroma-plassering',
			'fileInfo.scanType' => 'Skanningstype',
			'fileInfo.interlaced' => 'Interlaced',
			'fileInfo.anamorphic' => 'Anamorfisk',
			'fileInfo.referenceFrames' => 'Referanserammer',
			'fileInfo.dynamicRange' => 'Dynamisk omfang',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Dolby Vision-nivå',
			'fileInfo.dolbyVisionVersion' => 'Dolby Vision-versjon',
			'fileInfo.dolbyVisionLayers' => 'Dolby Vision-lag',
			'fileInfo.baseLayerCompatibility' => 'Kompatibilitet for basislag',
			'fileInfo.avcBitstream' => 'AVC-bitstrøm',
			'fileInfo.nalLengthSize' => 'NAL-lengdestørrelse',
			'fileInfo.scalingMatrix' => 'Egendefinert skaleringsmatrise',
			'fileInfo.streamIdentifier' => 'Strømidentifikator',
			'fileInfo.streamIndex' => 'Strømindeks',
			'fileInfo.streamId' => 'Strøm-ID',
			'fileInfo.language' => 'Språk',
			'fileInfo.languageCode' => 'Språkkode',
			'fileInfo.streamTitle' => 'Spor-tittel',
			'fileInfo.channels' => 'Kanaler',
			'fileInfo.sampleRate' => 'Samplingsfrekvens',
			'fileInfo.spatialAudio' => 'Romlig lyd',
			'fileInfo.textBased' => 'Tekstbasert',
			'fileInfo.subtitleFormat' => 'Sidecar-format',
			'fileInfo.provider' => 'Tilbyder',
			'fileInfo.matchScore' => 'Match-poengsum',
			'fileInfo.externalDelivery' => 'Kan leveres separat',
			'fileInfo.sidecarPath' => 'Sidecar-bane',
			'fileInfo.sourceStream' => 'Kopiert fra',
			'fileInfo.temporary' => 'Midlertidig',
			'fileInfo.timeBase' => 'Tidsbase',
			'fileInfo.overallBitrate' => 'Total bitrate',
			'fileInfo.path' => 'Sti',
			'fileInfo.fileName' => 'Filnavn',
			'fileInfo.size' => 'Størrelse',
			'fileInfo.totalSize' => 'Total størrelse',
			'fileInfo.container' => 'Format',
			'fileInfo.duration' => 'Varighet',
			'fileInfo.previewThumbnails' => 'Forhåndsvisningsminiatyrer',
			'fileInfo.previewIndex' => 'Forhåndsvisningsindeks',
			'fileInfo.packetLength' => 'Pakkelengde',
			'fileInfo.filePresent' => 'Fil til stede',
			'fileInfo.fileReadable' => 'Lesbar for serveren',
			'fileInfo.streamPath' => 'Strømbane',
			'fileInfo.optimizedForStreaming' => 'Optimalisert for strømming',
			'fileInfo.has64bitOffsets' => '64-biters forskyvninger',
			'fileInfo.protocol' => 'Protokoll',
			'fileInfo.mediaType' => 'Mediatype',
			'fileInfo.sourceKind' => 'Kildetype',
			'fileInfo.optimizedVersion' => 'Optimalisert versjon',
			'fileInfo.optimizationTarget' => 'Optimaliseringsmål',
			'fileInfo.deletedAt' => 'Slettet',
			'fileInfo.remoteSource' => 'Ekstern kilde',
			'fileInfo.infiniteStream' => 'Uendelig strøm',
			'fileInfo.directPlay' => 'Direct Play',
			'fileInfo.directStream' => 'Direct Stream',
			'fileInfo.transcoding' => 'Transkoding',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'Versjons-ID',
			'fileInfo.fileId' => 'Fil-ID',
			'fileInfo.defaultAudioTrack' => 'Standard lydspor',
			'fileInfo.defaultSubtitleTrack' => 'Standard tekstspor',
			'fileInfo.subtitlesOff' => 'Av',
			'fileInfo.flagDefault' => 'Standard',
			'fileInfo.flagForced' => 'Tvunget',
			'fileInfo.flagSelected' => 'Valgt',
			'fileInfo.flagExternal' => 'Ekstern',
			'fileInfo.flagHearingImpaired' => 'Hørselshemmet',
			'fileInfo.flagDub' => 'Dub',
			'fileInfo.flagOriginal' => 'Original',
			'mediaMenu.markAsWatched' => 'Merk som sett',
			'mediaMenu.markAsUnwatched' => 'Merk som usett',
			'mediaMenu.removeFromContinueWatching' => 'Fjern fra Fortsett å se',
			'mediaMenu.viewDetails' => 'Vis detaljer',
			'mediaMenu.goToSeries' => 'Gå til serie',
			'mediaMenu.shufflePlay' => 'Tilfeldig avspilling',
			'mediaMenu.shuffleNotAvailableOffline' => 'Tilfeldig avspilling er ikke tilgjengelig uten nett',
			'mediaMenu.fileInfo' => 'Filinformasjon',
			'mediaMenu.deleteEpisodeFromServer' => 'Slett episode fra serveren',
			'mediaMenu.deleteSeasonFromServer' => 'Slett sesong fra serveren',
			'mediaMenu.deleteShowFromServer' => 'Slett serie fra serveren',
			'mediaMenu.deleteMovieFromServer' => 'Slett film fra serveren',
			'mediaMenu.deleteEpisodeTitle' => 'Slette denne episoden?',
			'mediaMenu.deleteSeasonTitle' => 'Slette denne sesongen?',
			'mediaMenu.deleteShowTitle' => 'Slette denne serien?',
			'mediaMenu.deleteMovieTitle' => 'Slette denne filmen?',
			'mediaMenu.deleteEpisodeConfirm' => 'Slett episode',
			'mediaMenu.deleteSeasonConfirm' => 'Slett sesong',
			'mediaMenu.deleteShowConfirm' => 'Slett serie',
			'mediaMenu.deleteMovieConfirm' => 'Slett film',
			'mediaMenu.deleteAnyway' => 'Slett likevel',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Slette ${title} permanent fra serveren din?',
			'mediaMenu.deleteMultipleWarning' => 'Dette inkluderer alle episoder og deres filer.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Dette sletter ${n} episode i den, og filen.', other: 'Dette sletter alle ${n} episodene i den, og filene deres.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Dette elementet er lagret som ${n} fil, som vil bli slettet.', other: 'Dette elementet er lagret på tvers av ${n} filer, og alle vil bli slettet.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${n} annen episode er lagret i samme fil og vil også bli slettet:', other: '${n} andre episoder er lagret i samme fil og vil også bli slettet:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'Plezy kunne ikke sjekke hvilke filer dette vil fjerne, så det kan slette mer enn elementet som er nevnt ovenfor. Avbryt og prøv igjen, eller slett likevel.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Serveren din ga ikke fildetaljer for dette elementet, så Plezy kan ikke sjekke hvilke filer dette vil fjerne. Det kan slette mer enn elementet som er nevnt ovenfor.',
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
			_ => null,
		} ?? switch (path) {
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
			'accessibility.alphabetNavigation' => 'Alfabetisk navigasjon',
			'accessibility.alphabetScrollHint' => 'Sveip opp eller ned for å gå én bokstav om gangen',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Rad ${row} av ${rowCount}, kolonne ${column} av ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Rad ${row} av ${rowCount}',
			'tooltips.shufflePlay' => 'Tilfeldig avspilling',
			'tooltips.playTrailer' => 'Spill trailer',
			'tooltips.markAsWatched' => 'Merk som sett',
			'tooltips.markAsUnwatched' => 'Merk som usett',
			'audioTracks.track' => ({required Object n}) => 'Lydspor ${n}',
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
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'Avspillingen settes på pause om ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Slutten av gjeldende video',
			'videoControls.sleepTimerStopAtHeader' => 'Stopp ved',
			'videoControls.sleepTimerDurationHeader' => 'Timer',
			'videoControls.playbackWillPauseAtEnd' => 'Avspilling vil pause på slutten av denne videoen',
			'videoControls.stillWatching' => 'Ser du fortsatt?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pauser om ${seconds}s',
			'videoControls.continueWatching' => 'Fortsett',
			'videoControls.autoPlayNext' => 'Spill av neste automatisk',
			'videoControls.playNext' => 'Spill neste',
			'videoControls.playButton' => 'Spill av',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.playbackPaused' => 'Pauset',
			'videoControls.playbackResumed' => 'Spiller',
			'videoControls.loadingVideo' => 'Laster video',
			'videoControls.showPlaybackControls' => 'Vis avspillingskontroller',
			'videoControls.hidePlaybackControls' => 'Skjul avspillingskontroller',
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
			'videoControls.subtitleUnavailableFallback' => 'De valgte undertekstene kunne ikke lastes inn — avspillingen fortsetter uten undertekster',
			'videoControls.pipButton' => 'Bilde-i-bilde-modus',
			'videoControls.aspectRatioButton' => 'Sideforhold',
			'videoControls.ambientLighting' => 'Omgivelseslys',
			'videoControls.fullscreenButton' => 'Gå til fullskjerm',
			'videoControls.exitFullscreenButton' => 'Avslutt fullskjerm',
			'videoControls.alwaysOnTopButton' => 'Alltid øverst',
			'videoControls.rotationLockButton' => 'Rotasjonslås',
			'videoControls.lockScreen' => 'Lås skjerm',
			'videoControls.screenLockButton' => 'Skjermlås',
			'videoControls.longPressToUnlock' => 'Trykk og hold for å låse opp',
			'videoControls.timelineSlider' => 'Videotidslinje',
			'videoControls.volumeSlider' => 'Volumnivå',
			'videoControls.endsAt' => ({required Object time}) => 'Slutter kl. ${time}',
			'videoControls.pipActive' => 'Spiller i bilde-i-bilde',
			'videoControls.pipFailed' => 'Bilde-i-bilde kunne ikke starte',
			'videoControls.screenshotSaved' => 'Skjermbilde lagret',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent} %',
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
			'videoControls.noAudioDevicesAvailable' => 'Ingen lydenheter tilgjengelig',
			'videoControls.searchSubtitles' => 'Søk etter undertekster',
			'videoControls.language' => 'Språk',
			'videoControls.noSubtitlesFound' => 'Ingen undertekster funnet',
			'videoControls.subtitleDownloaded' => 'Undertekst lastet ned',
			'videoControls.subtitleDownloadedNotApplied' => 'Underteksten ble lastet ned, men kunne ikke velges',
			'videoControls.subtitleDownloadFailed' => 'Kunne ikke laste ned undertekst',
			'videoControls.searchLanguages' => 'Søk etter språk...',
			'messages.markedAsWatched' => 'Merket som sett',
			'messages.markedAsUnwatched' => 'Merket som usett',
			'messages.markedAsWatchedOffline' => 'Merket som sett (synkroniseres når tilkoblet)',
			'messages.markedAsUnwatchedOffline' => 'Merket som usett (synkroniseres når tilkoblet)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Automatisk fjernet: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Fjernet automatisk ${n} avspilt nedlasting', other: 'Fjernet automatisk ${n} avspilte nedlastinger', ), 
			'messages.removedFromContinueWatching' => 'Fjernet fra Fortsett å se',
			'messages.errorLoading' => ({required Object error}) => 'Feil: ${error}',
			'messages.searchPartialResults' => 'Noen medieservere kunne ikke søkes i. Viser tilgjengelige resultater.',
			'messages.streamInterrupted' => 'Avspillingen ble avbrutt. Trykk på Spill av eller spol for å prøve på nytt.',
			'messages.liveStreamInterrupted' => 'Direktesendingen ble avbrutt. Trykk på Spill av for å prøve på nytt.',
			'messages.fileInfoNotAvailable' => 'Filinformasjon ikke tilgjengelig',
			'messages.playbackAuthenticationRequired' => 'Logg inn på medieserveren på nytt for å spille av dette elementet.',
			'messages.playbackServerUnavailable' => 'Medieserveren er utilgjengelig. Prøv igjen senere.',
			'messages.playbackDataInvalid' => 'Serveren returnerte ugyldig avspillingsinformasjon.',
			'messages.playbackCancelled' => 'Avspillingen ble avbrutt.',
			'messages.playbackFailed' => 'Kunne ikke starte avspillingen.',
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
			'messages.sleepTimerSet' => ({required Object label}) => 'Innsovningstimer satt til ${label}',
			'messages.noItemsAvailable' => 'Ingen elementer tilgjengelig',
			'messages.failedToCreatePlayQueueNoItems' => 'Kunne ikke opprette avspillingskø – ingen elementer',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Kunne ikke ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Bytter til kompatibel spiller...',
			'messages.serverLimitTitle' => 'Avspilling mislyktes',
			'messages.serverLimitBody' => 'Serverfeil (HTTP 500). En båndbredde-/transkodingsgrense avviste trolig økten. Be eieren justere den.',
			'messages.mediaUnreadableTitle' => 'Fil utilgjengelig',
			'messages.mediaUnreadableBody' => 'Serveren fant dette elementet, men kunne ikke lese filen (HTTP 404). Filen er sannsynligvis flyttet, slettet, eller lagringen er frakoblet. Be serverens eier om å sjekke filen og skanne biblioteket på nytt.',
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
			'profiles.plexAccountChip' => ({required Object account}) => 'Plex-konto: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Standard',
			'profiles.connectionAs' => ({required Object displayName}) => 'som ${displayName}',
			'profiles.makeDefault' => 'Gjør til standard',
			'profiles.removeConnection' => 'Fjern',
			'profiles.profileRenamed' => 'Profilen er omdøpt.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Legg til ${displayName}',
			'profiles.borrowExplain' => 'Lån en annen profils tilkobling. PIN-beskyttede profiler krever PIN.',
			'profiles.borrowEmpty' => 'Ingenting å låne enda.',
			'profiles.borrowEmptySubtitle' => 'Koble Plex eller Jellyfin til en annen profil først.',
			'profiles.borrowLoadFailed' => 'Kunne ikke laste inn tilgjengelige tilkoblinger. Prøv igjen.',
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
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Rediger ${product}-tilkobling',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Legg til eller fjern URL-er for ${serverName}. Plezy vil bruke den nåbare URL-en med lavest ventetid.',
			'discover.title' => 'Oppdag',
			'discover.noContentAvailable' => 'Ikke noe innhold tilgjengelig',
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
			'discover.extras' => 'Trailere og ekstramateriale',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Vurdering',
			'discover.director' => 'Regissør',
			'discover.directors' => 'Regissører',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'TV-serie',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min igjen',
			'discover.moreLikeThis' => 'Mer som dette',
			'errors.searchFailed' => ({required Object error}) => 'Søk mislyktes: ${error}',
			'errors.searchUnavailable' => 'Søket kunne ikke nå noen medieserver.',
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
			'libraries.sortLabels.dateAdded' => 'Dato lagt til',
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
			'about.openSourceLicenses' => 'Lisenser for åpen kildekode',
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
			'startup.failedTitle' => 'Plezy kunne ikke starte',
			'startup.failedBody' => 'Noe gikk galt under oppstart. Detaljene nedenfor viser hva som feilet.',
			'startup.failedBodyRepairable' => 'Plezy\'s lagrede innstillingsfil er skadet og må bygges på nytt før Plezy kan starte. Å prøve igjen hjelper ikke – velg Reparer lagring.',
			'startup.phaseLabel' => 'Trinn',
			'startup.showDetails' => 'Vis detaljer',
			'startup.hideDetails' => 'Skjul detaljer',
			'startup.copyDetails' => 'Kopier detaljer',
			'startup.detailsCopied' => 'Detaljer kopiert til utklippstavlen',
			'startup.uploadDetails' => 'Last opp detaljer',
			'startup.repairStorage' => 'Reparer lagring',
			'startup.repairTitle' => 'Reparere lagrede data?',
			'startup.repairBodyCommon' => 'Plezy\'s innstillingsfil er skadet og kan ikke leses. Reparasjon tilbakestiller alle innstillinger til standard.',
			'startup.repairBodyOneCredential' => 'Én lagret pålogging er skadet og kan ikke leses. Reparasjon fjerner bare den; de andre innstillingene dine blir urørt.',
			'startup.repairBodySignInsKept' => 'Serverne og profilene dine skal forbli pålogget.',
			'startup.repairBodySignInsLost' => 'Nøkkelen som beskytter de lagrede påloggingene dine kan ikke gjenvinnes fra denne filen, så du må logge på alle servere og profiler på nytt. Ingenting på medieserveren din påvirkes.',
			'startup.repairBodySessionsUncertain' => 'Trackere (MAL, AniList, Simkl, Trakt) og Seerr lagres separat og kan overleve eller ikke. Plezy vil fortelle deg nøyaktig hva det beholdt.',
			'startup.repairConfirm' => 'Reparer',
			'startup.repairSucceeded' => 'Lagring reparert',
			'startup.repairNeedsRestart' => 'Lagring reparert – omstart kreves',
			'startup.restartRequiredBody' => 'Dataene dine ble reparert, men Plezy må starte på nytt før det kan bruke dem. Lukk Plezy og åpne det igjen.',
			'startup.quitPlezy' => 'Avslutt Plezy',
			'startup.repairFailed' => 'Reparasjon mislyktes',
			'startup.repairKeptSignIns' => 'Serverne og profilene dine er fortsatt pålogget.',
			'startup.repairLostSignIns' => 'Nøkkelen som beskytter de lagrede påloggingene dine kunne ikke gjenvinnes. Du må logge på alle servere og profiler på nytt.',
			'startup.repairLostSessions' => 'Minst én tracker- eller Seerr-tilkobling gikk tapt og må kobles til på nytt.',
			'startup.backupTitle' => 'En kopi av den skadede filen ble beholdt',
			'startup.backupWarning' => 'Den inneholder påloggingsinformasjonen din. Ikke last den opp eller del den.',
			'startup.deleteBackup' => 'Slett kopi',
			'startup.backupDeleted' => 'Kopi slettet.',
			'startup.previousFailureTitle' => 'Plezy mislyktes i å starte forrige gang',
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
			'explore.rows.trendingMovies' => 'Populære filmer nå',
			'explore.rows.trendingShows' => 'Populære serier nå',
			'explore.rows.popularMovies' => 'Populære filmer',
			'explore.rows.popularShows' => 'Populære serier',
			'explore.rows.trendingAnime' => 'Populær anime nå',
			'explore.rows.suggestedAnime' => 'Foreslått anime',
			'explore.rows.airingAnime' => 'Topp pågående anime',
			'explore.rows.popularAnime' => 'Mest populær anime',
			'explore.rows.trending' => 'Populært nå',
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
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} populær',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} på lufta',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} vurdert',
			'explore.badge.rankFavorited' => ({required Object n}) => '#${n} favorisert',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} trendende',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} i ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} ser på',
			'explore.badge.available' => 'Tilgjengelig',
			'explore.badge.partiallyAvailable' => 'Delvis tilgjengelig',
			'explore.badge.availableIn4k' => '4K tilgjengelig',
			'explore.badge.requested' => 'Forespurt',
			'explore.badge.pendingApproval' => 'Venter på godkjenning',
			'explore.badge.processing' => 'Behandler',
			'explore.badge.declined' => 'Avslått',
			'explore.badge.requestFailed' => 'Forespørsel mislyktes',
			'explore.badge.requested4k' => '4K forespurt',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} sesonger',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} om ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Neste om ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} ep.',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} oppført',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} så på i dag',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} så på denne uken',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} så på denne måneden',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} så på i år',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} seere',
			'explore.stats.planning' => ({required Object n}) => '${n} planlegger å se',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoritter',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} droppet den',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${n} kommentar', other: '${n} kommentarer', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} stemmer',
			'explore.stats.watching' => ({required Object n}) => '${n} ser på den',
			'explore.stats.completed' => ({required Object n}) => '${n} fullførte',
			'explore.stats.onHold' => ({required Object n}) => '${n} på pause',
			'explore.stats.dropped' => ({required Object n}) => '${n} droppet',
			_ => null,
		} ?? switch (path) {
			'explore.season.winter' => 'Vinter',
			'explore.season.spring' => 'Vår',
			'explore.season.summer' => 'Sommer',
			'explore.season.fall' => 'Høst',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'TV-kort',
			'explore.format.movie' => 'Film',
			'explore.format.special' => 'Spesial',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Musikk',
			'explore.format.other' => 'Annet',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Spill',
			'explore.sourceMaterial.webComic' => 'Nettserie',
			'explore.sourceMaterial.musicRelease' => 'Musikk',
			'explore.sourceMaterial.otherMedia' => 'Annet',
			'explore.creditRole.director' => 'Regissør',
			'explore.creditRole.writer' => 'Forfatter',
			'explore.creditRole.producer' => 'Produsent',
			'explore.creditRole.creator' => 'Skaper',
			'explore.creditRole.composer' => 'Komponist',
			'explore.relation.prequel' => 'Prequel',
			'explore.relation.sequel' => 'Sequel',
			'explore.relation.sideStory' => 'Bihistorie',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Alternativ versjon',
			'explore.relation.summary' => 'Sammendrag',
			'explore.relation.parentStory' => 'Hovedhistorie',
			'explore.relation.adaptation' => 'Adaptasjon',
			'explore.relation.other' => 'Relatert',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Sendes ${day} kl. ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Sendes ${day} kl. ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Originaltittel',
			'explore.detail.alsoKnownAs' => 'Også kjent som',
			'explore.detail.studios' => 'Studioer',
			'explore.detail.country' => 'Land',
			'explore.detail.language' => 'Språk',
			'explore.detail.released' => 'Utgitt',
			'explore.detail.physicalRelease' => 'På disk',
			'explore.detail.ended' => 'Avsluttet',
			'explore.detail.addedOn' => ({required Object date}) => 'Lagt til ${date}',
			'explore.detail.yourRating' => 'Din vurdering',
			'explore.detail.budget' => 'Budsjett',
			'explore.detail.revenue' => 'Billettinntekter',
			'explore.detail.contentAdvisory' => 'Aldersveiledning',
			'explore.detail.tags' => 'Tagger',
			'explore.detail.revealSpoilerTags' => 'Vis spoilertagger',
			'explore.detail.links' => 'Lenker',
			'explore.detail.watchOn' => 'Se på',
			'explore.detail.watchTrailer' => 'Se trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Åpne på ${site}',
			'explore.detail.crew' => 'Mannskap',
			'explore.detail.ratings' => 'Vurderinger',
			'explore.detail.schedule' => 'Sendeskjema',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: 'Anbefalt av ${n} bruker', other: 'Anbefalt av ${n} brukere', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Anbefalt av ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favorisert av ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} har ikke blitt sendt ennå',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Anbefalt av ${percent} av seerne',
			'explore.detail.relatedTitles' => 'Relaterte titler',
			'explore.detail.background' => 'Bakgrunn',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('nb'))(n, one: '${n} resultat', other: '${n} resultater', ), 
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
			'liveTv.whatsOn' => 'På TV nå',
			'liveTv.watchChannel' => 'Se kanal',
			'liveTv.favorites' => 'Favoritter',
			'liveTv.reorderFavorites' => 'Endre rekkefølge på favoritter',
			'liveTv.favoritesLoadFailed' => 'Kunne ikke laste inn favoritter. Kontroller tilkoblingen og prøv på nytt.',
			'liveTv.favoritesUpdateFailed' => 'Kunne ikke oppdatere favorittene. Kontroller tilkoblingen og prøv på nytt.',
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
			'liveTv.guideReloadRequested' => 'Oppdatering av programguiden er forespurt',
			'liveTv.rulesProcessRequested' => 'Ny vurdering av reglene er forespurt',
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
			'watchTogether.relayUnreachable' => 'Reléserveren kan ikke nås. Blokkering hos internettleverandøren kan hindre Se sammen.',
			'watchTogether.reconnectingToHost' => 'Kobler til verten på nytt...',
			'watchTogether.currentPlayback' => 'Gjeldende avspilling',
			'watchTogether.joinCurrentPlayback' => 'Bli med i gjeldende avspilling',
			'watchTogether.joinCurrentPlaybackDescription' => 'Hopp tilbake til det verten ser på nå',
			'watchTogether.failedToOpenCurrentPlayback' => 'Kunne ikke åpne gjeldende avspilling',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} ble med',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} forlot',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} satte avspillingen på pause',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} startet avspillingen igjen',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} endret avspillingsposisjonen',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} buffrer',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} bruker en eldre appversjon — synkronisering er ikke tilgjengelig',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Fortsetter uten ${name}',
			'watchTogether.waitingForParticipants' => 'Venter på at de andre skal laste inn...',
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
			'downloads.storageFull' => 'Nedlastingene ble stoppet fordi lagringsplassen på enheten er full. Frigjør plass, og prøv igjen.',
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
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Slutte å synkronisere «${title}»?',
			'downloads.deleteSyncRuleDownloads' => 'Slett også tilknyttede nedlastinger',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Nedlastinger som brukes av en annen synkroniseringsregel eller profil, beholdes.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Synkroniseringsregel opprettet — beholder ${count} usette episoder',
			'downloads.syncRuleUpdated' => 'Synkroniseringsregel oppdatert',
			'downloads.syncRuleRemoved' => 'Synkroniseringsregel fjernet',
			'downloads.syncRuleAndDownloadsRemoved' => 'Synkroniseringsregel og tilknyttede nedlastinger fjernet',
			'downloads.syncRuleCleanupBusy' => 'Synkroniseringsreglene oppdateres for øyeblikket. Prøv igjen om et øyeblikk.',
			'downloads.syncRuleCleanupUnavailable' => 'Tilknyttede nedlastinger kunne ikke identifiseres på en trygg måte. Koble til serveren på nytt og prøv igjen, eller fjern regelen uten å slette nedlastingene.',
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
			'downloads.backgroundWarning.bannerBlocked' => 'Nedlastinger stopper når du forlater appen',
			'downloads.backgroundWarning.bannerDegraded' => 'Bakgrunnsnedlastinger kan være begrenset',
			'downloads.backgroundWarning.bannerAction' => 'Detaljer',
			'downloads.backgroundWarning.sheetTitle' => 'Bakgrunnsnedlastinger er blokkert',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Bakgrunnsnedlastinger kan være begrenset',
			'downloads.backgroundWarning.sheetIntro' => 'Android hindrer Plezy i å laste ned pålitelig i bakgrunnen.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Enheten din begrenser når Plezy kan laste ned i bakgrunnen.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'Bakgrunnsbruken til Plezy er begrenset. Sett batteribruk eller bakgrunnsbruk til «Ubegrenset».',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android har satt Plezy i begrenset hvilemodus. Sett batteribruken til «Ubegrenset».',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Varsler om nedlastinger er slått av, så fremdrift og kontroller kan være utilgjengelige.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Varsler er slått av. På Android 13 eller nyere kreves de for lange bakgrunnsnedlastinger.',
			'downloads.backgroundWarning.reasonDataSaver' => 'Datasparing er slått på og blokkerer bakgrunnsnedlastinger via mobildata. Nedlastinger skal fortsatt fungere på Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Nedlastinger har stoppet gjentatte ganger mens Plezy var i bakgrunnen. Sjekk innstillingene for batteribruk eller bakgrunnsbruk for Plezy.',
			'downloads.backgroundWarning.openSettings' => 'Åpne innstillinger',
			'downloads.backgroundWarning.stillNotWorking' => 'Enhetsspesifikk hjelp',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Se fremgangsmåten for enheten din, eller send en logg fra Innstillinger › Vis logger hvis problemet vedvarer.',
			'downloads.backgroundWarning.dialogTitle' => 'Nedlastinger blir kanskje ikke fullført',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Last ned likevel',
			'downloads.backgroundWarning.dialogFixFirst' => 'Løs dette først',
			'downloads.backgroundWarning.statusTile' => 'Bakgrunnsnedlastinger',
			'downloads.backgroundWarning.statusOk' => 'Kan kjøre i bakgrunnen',
			'downloads.backgroundWarning.statusBlocked' => 'Blokkert av systeminnstillinger',
			'downloads.backgroundWarning.statusDegraded' => 'Begrenset av systeminnstillinger',
			'downloads.backgroundWarning.statusUnknown' => 'Ikke sjekket ennå',
			'downloads.backgroundWarning.settingsUnavailable' => 'Kunne ikke åpne systeminnstillingene på denne enheten',
			'downloads.backgroundWarning.linkUnavailable' => 'Kunne ikke åpne dontkillmyapp.com på denne enheten',
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
			'companionRemote.title' => 'Fjernkontroll',
			'companionRemote.connectedTo' => ({required Object name}) => 'Tilkoblet ${name}',
			'companionRemote.unknownDevice' => 'Ukjent enhet',
			'companionRemote.session.startingServer' => 'Starter fjernserver...',
			'companionRemote.session.hostAddress' => 'Vertsadresse',
			'companionRemote.session.connected' => 'Tilkoblet',
			'companionRemote.session.serverRunning' => 'Fjernserver aktiv',
			'companionRemote.session.serverStopped' => 'Fjernserver stoppet',
			'companionRemote.session.serverRunningDescription' => 'Mobilenheter på nettverket ditt kan koble til denne appen',
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
			'companionRemote.pairing.noDevicesHint' => 'Åpne Plezy på datamaskinen, og bruk samme Wi-Fi',
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
			'companionRemote.remote.searchHint' => 'Søk på datamaskinen...',
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
			'videoSettings.sleepTimer' => 'Innsovningstimer',
			'videoSettings.audioSync' => 'Lydsynkronisering',
			'videoSettings.subtitleSync' => 'Undertekstsynkronisering',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Lydutgang',
			'videoSettings.performanceOverlay' => 'Ytelsesoverlegg',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Romlig lyd',
			'videoSettings.audioOutputStereo' => 'Stereo',
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
			'performanceOverlay.renderFps' => 'Gjengivelses-FPS',
			'performanceOverlay.displayFps' => 'Skjerm-FPS',
			'performanceOverlay.avSync' => 'A/V-synk',
			'performanceOverlay.dropped' => 'Tapte',
			'performanceOverlay.dvRpus' => 'DV RPU-er',
			'performanceOverlay.dvRpuAverage' => 'DV RPU snitt',
			'performanceOverlay.dvSampleAverage' => 'DV-sample snitt',
			'performanceOverlay.maxLuma' => 'Maks luma',
			'performanceOverlay.minLuma' => 'Min luma',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Brukt hurtigbuffer',
			'performanceOverlay.cacheLimit' => 'Grense for hurtigbuffer',
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
			_ => null,
		} ?? switch (path) {
			'externalPlayer.launchFailed' => 'Kunne ikke åpne ekstern spiller',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} er ikke installert',
			'externalPlayer.playInExternalPlayer' => 'Spill av i ekstern spiller',
			'metadataEdit.editMetadata' => 'Rediger...',
			'metadataEdit.screenTitle' => 'Rediger metadata',
			'metadataEdit.basicInfo' => 'Grunnleggende informasjon',
			'metadataEdit.artwork' => 'Grafikk',
			'metadataEdit.advancedSettings' => 'Avanserte innstillinger',
			'metadataEdit.title' => 'Tittel',
			'metadataEdit.sortTitle' => 'Sorteringstittel',
			'metadataEdit.originalTitle' => 'Originaltittel',
			'metadataEdit.releaseDate' => 'Utgivelsesdato',
			'metadataEdit.contentRating' => 'Aldersgrense',
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
			'metadataEdit.artworkUpdated' => 'Grafikk oppdatert',
			'metadataEdit.artworkUpdateFailed' => 'Kunne ikke oppdatere grafikken',
			'metadataEdit.noArtworkAvailable' => 'Ingen grafikk tilgjengelig',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Grafikkalternativ ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Grafikkalternativ ${index}, valgt',
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
			'matchScreen.match' => 'Finn treff...',
			'matchScreen.fixMatch' => 'Korriger treff...',
			'matchScreen.unmatch' => 'Fjern treff',
			'matchScreen.unmatchConfirm' => 'Fjerne dette treffet? Plex behandler elementet som uten treff til det matches på nytt.',
			'matchScreen.unmatchSuccess' => 'Treff fjernet',
			'matchScreen.unmatchFailed' => 'Kunne ikke fjerne treff',
			'matchScreen.matchApplied' => 'Treff valgt',
			'matchScreen.matchFailed' => 'Kunne ikke velge treff',
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
			'trakt.watchedSync' => 'Synkroniser settstatus',
			'trakt.watchedSyncDescription' => 'Når du markerer elementer som sett i Plezy, markeres de også som sett på Trakt.',
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
			'seerr.request' => 'Be om',
			'seerr.request4k' => 'Be om i 4K',
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
			'services.names.mdblist' => 'MDBList',
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
			'services.libraryFilter.modeBlacklist' => 'Blokkeringsliste',
			'services.libraryFilter.modeWhitelist' => 'Tillatelsesliste',
			'services.libraryFilter.modeHintBlacklist' => 'Synkroniser alle biblioteker bortsett fra dem du markerer nedenfor.',
			'services.libraryFilter.modeHintWhitelist' => 'Synkroniser kun bibliotekene du markerer nedenfor.',
			'services.libraryFilter.libraries' => 'Biblioteker',
			'services.libraryFilter.noLibraries' => 'Ingen biblioteker tilgjengelige',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Legg til ${product}-server',
			'addServer.serverUrls' => 'Server-URL-er',
			'addServer.serverUrlsHelper' => 'Flere URL-er er tillatt, atskilt med komma.',
			'addServer.findServer' => 'Finn server',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Leter etter lokale ${product}-servere...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Lokale ${product}-servere',
			'addServer.username' => 'Brukernavn',
			'addServer.password' => 'Passord',
			'addServer.signIn' => 'Logg inn',
			'addServer.change' => 'Endre',
			'addServer.required' => 'Påkrevd',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Kunne ikke nå serveren: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Innlogging mislyktes: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect mislyktes: ${error}',
			'addServer.addPlexTitle' => 'Logg inn med Plex',
			'addServer.pinExpired' => 'PIN-koden utløp før innloggingen var fullført. Prøv igjen.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Kunne ikke registrere kontoen: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Skriv inn URL-en til ${product}-serveren din',
			'addServer.addConnectionTitle' => 'Legg til tilkobling',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Legg til for ${name}',
			'addServer.signInWithPlexCard' => 'Logg inn med Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriser denne enheten. Delte servere legges til.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriser en Plex-konto. Home-brukere blir profiler.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Koble til ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Skriv inn server-URL-en, brukernavnet og passordet ditt.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Logg på ${product}-serveren din. Knyttes til ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Lån fra en annen profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Gjenbruk en annen profils tilkobling. PIN-beskyttede profiler krever PIN.',
			_ => null,
		};
	}
}
